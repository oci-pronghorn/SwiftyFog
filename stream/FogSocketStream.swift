//
//  FogSocketStream.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/24/17.
//

import Foundation

public protocol FogSocketStreamDelegate: class {
    func fog(streamReady: FogSocketStream)
    func fog(stream: FogSocketStream, errored: Error?)
	func fog(stream: FogSocketStream, received: StreamReader)
}

public typealias FogSocketStreamWrite = ((StreamWriter)->())->()

public final class FogSocketStream: NSObject, StreamDelegate {
	private let mutex = ReadWriteMutex()
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    private let label: String
    private let qos: DispatchQoS
    private weak var delegate: FogSocketStreamDelegate?
	
	private static let runloop =  RunLoopPool(resuseMode: false)
	
    private var isReady = false
	
	public init?(hostName: String, port: Int, qos: DispatchQoS) {
        var inputStreamHandle: InputStream?
        var outputStreamHandle: OutputStream?
        Stream.getStreamsToHost(withName: hostName, port: port, inputStream: &inputStreamHandle, outputStream: &outputStreamHandle)
		
        guard let hasInput = inputStreamHandle, let hasOutput = outputStreamHandle else { return nil }
		
        var parts = hostName.components(separatedBy: ".")
        parts.insert("stream\(port)", at: 0)
        self.label = parts.reversed().joined(separator: ".")
		self.qos = qos
		self.inputStream = hasInput
		self.outputStream = hasOutput
		super.init()
        self.inputStream?.delegate = self
        self.outputStream?.delegate = self
	}
	
    deinit {
		closeStreams()
    }
	
    private func closeStreams() {
		// We are told streams will be unscheduled from runloop on close
		// Make certain no more callbacks happen
		if let input = inputStream {
			inputStream = nil
			input.delegate = nil
			input.close()
		}
		if let output = outputStream {
			outputStream = nil
			output.delegate = nil
			output.close()
		}
    }
	
    private func endStream(_ aStream: Stream) {
		aStream.close()
		aStream.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
		aStream.delegate = nil
		if aStream === outputStream {
			outputStream = nil
		}
		else if aStream === inputStream {
			inputStream = nil
		}
    }
	
	public func writer(writer: (StreamWriter)->()) {
		let hasOutput = outputStream!
		mutex.writing {
			writer(hasOutput.write)
		}
    }
	
    public func start(isSSL: StreamSocketSecurityLevel?, delegate: FogSocketStreamDelegate?) {
		self.delegate = delegate
		let hasInput = inputStream!
		let hasOutput = outputStream!
		
		if let raw = isSSL?.rawValue {
			let _ = hasInput.setProperty(raw, forKey: Stream.PropertyKey.socketSecurityLevelKey)
			let _ = hasOutput.setProperty(raw, forKey: Stream.PropertyKey.socketSecurityLevelKey)
		}
		
		FogSocketStream.runloop.runLoop(label: label + ".in", qos: qos) {
			hasInput.schedule(in: $0, forMode: .defaultRunLoopMode)
			hasInput.open()
		}
		
		FogSocketStream.runloop.runLoop(label: label + ".out", qos: qos) {
			hasOutput.schedule(in: $0, forMode: .defaultRunLoopMode)
			hasOutput.open()
		}
    }
	
    private func checkForReady() {
		mutex.writing {
			if isReady == false {
				if inputStream?.streamStatus == Stream.Status.open &&
				   outputStream?.streamStatus == Stream.Status.open &&
				   outputStream?.hasSpaceAvailable == true {
					isReady = true
					delegate?.fog(streamReady: self)
				}
			}
		}
	}
	
    @objc
	public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
			case Stream.Event.openCompleted:
				checkForReady()
				break
			case Stream.Event.hasBytesAvailable:
				if let input = inputStream, aStream == input {
					delegate?.fog(stream: self, received: input.read)
				}
				break
			case Stream.Event.errorOccurred:
				delegate?.fog(stream: self, errored: aStream.streamError)
				break
			case Stream.Event.endEncountered:
				endStream(aStream)
				if aStream.streamError != nil {
					delegate?.fog(stream: self, errored: aStream.streamError)
				}
				break
			case Stream.Event.hasSpaceAvailable:
				checkForReady()
				break
			default:
				break
        }
    }
}
