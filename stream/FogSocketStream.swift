//
//  FogSocketStream.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/24/17.
//

import Foundation

public protocol FogSocketStreamDelegate: class {
    func fog(stream: FogSocketStream, ready: Bool)
    func fog(stream: FogSocketStream, errored: Error?)
	func fog(stream: FogSocketStream, received: StreamReader)
}

public typealias FogSocketStreamWrite = ((StreamWriter)->())->()

public class FogSocketStream: NSObject, StreamDelegate {
	private let mutex = ReadWriteMutex()
	private var sessionQueue: DispatchQueue
    private let inputStream: InputStream
    private let outputStream: OutputStream
    private weak var delegate: FogSocketStreamDelegate?
	
	private var inputReady = false
	private var outputReady = false
	
	public init?(hostName: String, port: Int, qos: DispatchQoS) {
        var inputStreamHandle: InputStream?
        var outputStreamHandle: OutputStream?
        Stream.getStreamsToHost(withName: hostName, port: port, inputStream: &inputStreamHandle, outputStream: &outputStreamHandle)
		
        guard let hasInput = inputStreamHandle, let hasOutput = outputStreamHandle else { return nil }
		
        var parts = hostName.components(separatedBy: ".")
        parts.insert("stream\(port)", at: 0)
        let label = parts.reversed().joined(separator: ".")
		
        self.sessionQueue = DispatchQueue(label: label, qos: qos, target: nil)
		self.inputStream = hasInput
		self.outputStream = hasOutput
		super.init()
        self.inputStream.delegate = self
        self.outputStream.delegate = self
	}
	
    deinit {
        inputStream.close()
        inputStream.delegate = nil
        outputStream.close()
        outputStream.delegate = nil
    }
	
	public func writer(writer: (StreamWriter)->()) {
		let hasOutput = outputStream
		mutex.writing {
			writer(hasOutput.write)
		}
    }
	
    public func start(isSSL: Bool, timeout: TimeInterval, delegate: FogSocketStreamDelegate?) {
		self.delegate = delegate
		let hasInput = inputStream
		let hasOutput = outputStream
		sessionQueue.async {
			FogSocketStream.run(isSSL, hasInput, hasOutput)
        }
		if timeout > 0.0 {
			sessionQueue.asyncAfter(deadline: .now() +  timeout) { [weak self] in
				self?.connectTimeout()
			}
		}
    }
	
    private static func run(_ isSSL: Bool, _ inputStream: InputStream, _ outputStream: OutputStream) {
		let currentRunLoop = RunLoop.current
		inputStream.schedule(in: currentRunLoop, forMode: .defaultRunLoopMode)
		outputStream.schedule(in: currentRunLoop, forMode: .defaultRunLoopMode)
		inputStream.open()
		outputStream.open()
		if isSSL {
			let securityLevel = StreamSocketSecurityLevel.negotiatedSSL.rawValue
			inputStream.setProperty(securityLevel, forKey: Stream.PropertyKey.socketSecurityLevelKey)
			outputStream.setProperty(securityLevel, forKey: Stream.PropertyKey.socketSecurityLevelKey)
		}
		currentRunLoop.run()
    }
	
	private func connectTimeout() {
		if inputReady == false || outputReady == false {
			delegate?.fog(stream: self, ready: false)
		}
	}
	
    @objc
	public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
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
					delegate?.fog(stream: self, ready: true)
				}
				break
			case Stream.Event.hasBytesAvailable:
				if aStream == inputStream {
					delegate?.fog(stream: self, received: inputStream.read)
				}
				break
			case Stream.Event.errorOccurred:
				delegate?.fog(stream: self, errored: aStream.streamError)
				break
			case Stream.Event.endEncountered:
				if aStream.streamError != nil {
					delegate?.fog(stream: self, errored: aStream.streamError)
				}
				break
			case Stream.Event.hasSpaceAvailable:
				let wasReady = inputReady && outputReady
				if aStream == outputStream {
					outputReady = true
				}
				if !wasReady && inputReady && outputReady {
					delegate?.fog(stream: self, ready: true)
				}
				break
			default:
				break
        }
    }
}
