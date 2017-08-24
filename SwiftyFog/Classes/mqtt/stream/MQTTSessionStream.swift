//
//  MQTTSessionStream.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public enum MQTTPort {
	case standard
	case ssl
	case other(UInt16)
	
	public var number: UInt16 {
		switch self {
			case .standard:
				return 1883
			case .ssl:
				return 8883
			case .other(let number):
				return number
		}
	}
}

public struct MQTTHostParams {
    public var host: String
    public var port: UInt16
    public var ssl: Bool
    public var timeout: TimeInterval
	
    public init(host: String = "localhost", port: MQTTPort = .standard, ssl: Bool = false, timeout: TimeInterval = 10.0) {
		self.host = host
		self.port = port.number
		self.ssl = ssl
		self.timeout = timeout
    }
}

protocol MQTTSessionStreamDelegate: class {
    func mqttStreamConnected(_ ready: Bool, in stream: MQTTSessionStream)
    func mqttStreamErrorOccurred(in stream: MQTTSessionStream, error: Error?)
	func mqttStreamReceived(in stream: MQTTSessionStream, _ read: StreamReader)
}

class MQTTSessionStream {
	private var sessionQueue: DispatchQueue
	private var handler: MQTTStreamHandler!
	
    fileprivate let inputStream: InputStream
    fileprivate let outputStream: OutputStream
    fileprivate weak var delegate: MQTTSessionStreamDelegate?
	
    init?(hostParams: MQTTHostParams, delegate: MQTTSessionStreamDelegate?) {
        var inputStreamHandle: InputStream?
        var outputStreamHandle: OutputStream?
        Stream.getStreamsToHost(withName: hostParams.host, port: Int(hostParams.port), inputStream: &inputStreamHandle, outputStream: &outputStreamHandle)
		
        guard let hasInput = inputStreamHandle, let hasOutput = outputStreamHandle else { return nil }
        
        var parts = hostParams.host.components(separatedBy: ".")
        parts.insert("stream\(hostParams.port)", at: 0)
        let label = parts.reversed().joined(separator: ".")
        
        self.sessionQueue = DispatchQueue(label: label, qos: .background, target: nil)
        self.inputStream = hasInput
        self.outputStream = hasOutput
        self.delegate = delegate
		
		self.handler = MQTTStreamHandler(session: self)
        
        self.inputStream.delegate = handler
        self.outputStream.delegate = handler
        
        sessionQueue.async {
			MQTTSessionStream.run(hostParams, hasInput, hasOutput)
        }
		if hostParams.timeout > 0 {
			sessionQueue.asyncAfter(deadline: .now() +  hostParams.timeout) { [weak handler] in
				handler?.connectTimeout()
			}
		}
    }
	
    private static func run(_ hostParams: MQTTHostParams, _ inputStream: InputStream, _ outputStream: OutputStream) {
		let currentRunLoop = RunLoop.current
		inputStream.schedule(in: currentRunLoop, forMode: .defaultRunLoopMode)
		outputStream.schedule(in: currentRunLoop, forMode: .defaultRunLoopMode)
		inputStream.open()
		outputStream.open()
		if hostParams.ssl {
			let securityLevel = StreamSocketSecurityLevel.negotiatedSSL.rawValue
			inputStream.setProperty(securityLevel, forKey: Stream.PropertyKey.socketSecurityLevelKey)
			outputStream.setProperty(securityLevel, forKey: Stream.PropertyKey.socketSecurityLevelKey)
		}
		currentRunLoop.run()
    }
    
    deinit {
        inputStream.close()
        inputStream.delegate = nil
        outputStream.close()
        outputStream.delegate = nil
    }
    
    var writer: StreamWriter {
		return outputStream.write
    }
}

private class MQTTStreamHandler: NSObject, StreamDelegate {
	private var inputReady = false
	private var outputReady = false
	private weak var session: MQTTSessionStream?
	
	fileprivate init(session: MQTTSessionStream) {
		self.session = session
	}
	
	fileprivate func connectTimeout() {
		if inputReady == false || outputReady == false {
			if let session = session {
				session.delegate?.mqttStreamConnected(false, in: session)
			}
		}
	}
	
    @objc
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
			case Stream.Event.openCompleted:
				let wasReady = inputReady && outputReady
				if aStream == session?.inputStream {
					inputReady = true
				}
				else if aStream == session?.outputStream {
					// output almost ready
				}
				if !wasReady && inputReady && outputReady {
					if let session = session {
						session.delegate?.mqttStreamConnected(true, in: session)
					}
				}
				break
			case Stream.Event.hasBytesAvailable:
				if aStream == session?.inputStream {
					if let session = session {
						session.delegate?.mqttStreamReceived(in: session, session.inputStream.read)
					}
				}
				break
			case Stream.Event.errorOccurred:
				if let session = session {
					session.delegate?.mqttStreamErrorOccurred(in: session, error: aStream.streamError)
				}
				break
			case Stream.Event.endEncountered:
				if aStream.streamError != nil {
					if let session = session {
						session.delegate?.mqttStreamErrorOccurred(in: session, error: aStream.streamError)
					}
				}
				break
			case Stream.Event.hasSpaceAvailable:
				let wasReady = inputReady && outputReady
				if aStream == session?.outputStream {
					outputReady = true
				}
				if !wasReady && inputReady && outputReady {
					if let session = session {
						session.delegate?.mqttStreamConnected(true, in: session)
					}
				}
				break
			default:
				break
        }
    }
}
