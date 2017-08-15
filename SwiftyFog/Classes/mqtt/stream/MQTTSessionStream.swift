//
//  MQTTSessionStream.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public struct MQTTHostParams {
    public var host: String
    public var port: UInt16
    public var ssl: Bool
    public var timeout: TimeInterval
	
    public init(host: String = "localhost", port: UInt16 = 1883, ssl: Bool = false, timeout: TimeInterval = 10.0) {
		self.host = host
		self.port = port
		self.ssl = ssl
		self.timeout = timeout
    }
}

protocol MQTTSessionStreamDelegate: class {
    func mqttStreamConnected(_ ready: Bool, in stream: MQTTSessionStream)
    func mqttStreamErrorOccurred(in stream: MQTTSessionStream, error: Error?)
	func mqttStreamReceived(in stream: MQTTSessionStream, _ read: StreamReader)
}

class MQTTSessionStream: NSObject {
    private let inputStream: InputStream
    private let outputStream: OutputStream
    private weak var delegate: MQTTSessionStreamDelegate?
	private var sessionQueue: DispatchQueue
	
	private var inputReady = false
	private var outputReady = false
    
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
		
        super.init()
        
        self.inputStream.delegate = self
        self.outputStream.delegate = self
        
        sessionQueue.async { [weak self] in
			self?.run(hostParams: hostParams)
        }
    }
	
    private func run(hostParams: MQTTHostParams) {
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
		if hostParams.timeout > 0 {
			DispatchQueue.global().asyncAfter(deadline: .now() +  hostParams.timeout) { [weak self] in
				self?.connectTimeout()
			}
		}
		currentRunLoop.run()
    }
	
	// TODO: a strong reference to self is kept in the streams
    func close() {
        inputStream.close()
        inputStream.remove(from: .current, forMode: .defaultRunLoopMode)
        inputStream.delegate = nil
        outputStream.close()
        outputStream.remove(from: .current, forMode: .defaultRunLoopMode)
        outputStream.delegate = nil
    }
    
    deinit {
		close()
    }
    
    var writer: StreamWriter {
		return outputStream.write
    }
	
	internal func connectTimeout() {
		if inputReady == false || outputReady == false {
			delegate?.mqttStreamConnected(false, in: self)
		}
	}
}

extension MQTTSessionStream: StreamDelegate {
    @objc
    internal func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
			case Stream.Event.openCompleted:
				let wasReady = inputReady && outputReady
				if aStream == inputStream {
					inputReady = true
				}
				else if aStream == outputStream {
					// output almost ready
				}
				if !wasReady && inputReady && outputReady {
					delegate?.mqttStreamConnected(true, in: self)
				}
				break
			case Stream.Event.hasBytesAvailable:
				if aStream == inputStream {
					delegate?.mqttStreamReceived(in: self, inputStream.read)
				}
				break
			case Stream.Event.errorOccurred:
				delegate?.mqttStreamErrorOccurred(in: self, error: aStream.streamError)
				break
			case Stream.Event.endEncountered:
				if aStream.streamError != nil {
					delegate?.mqttStreamErrorOccurred(in: self, error: aStream.streamError)
				}
				break
			case Stream.Event.hasSpaceAvailable:
				let wasReady = inputReady && outputReady
				if aStream == outputStream {
					outputReady = true
				}
				if !wasReady && inputReady && outputReady {
					delegate?.mqttStreamConnected(true, in: self)
				}
				break
			default:
				break
        }
    }
}
