//
//  FogSocketStream.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/24/17.
//

import Foundation // Streams

public protocol FogSocketStreamDelegate: class {
    func fog(streamReady: FogSocketStream)
    func fog(stream: FogSocketStream, errored: Error?)
	func fog(stream: FogSocketStream, received: StreamReader)
}

public typealias FogSocketStreamWrite = ((StreamWriter)->())->()

/*
	Important Note:
		A disconnect is not reported until approximately 30 seconds
		after a failed write that is actually reported as success.

		There appears to be no way to change this behavior in the stream
		objects. You business logic will have to assume this responsibility
		with pings and acks.

	See RunLoopPool for further issues with iOS Streams
*/
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
    #if os(iOS) || os(OSX)
        Stream.getStreamsToHost(withName: hostName, port: port, inputStream: &inputStreamHandle, outputStream: &outputStreamHandle)
	#else
		var readStream: Unmanaged<CFReadStream>?
		var writeStream: Unmanaged<CFWriteStream>?
		CFStreamCreatePairWithSocketToHost(nil, hostName as CFString, UInt32(port), &readStream, &writeStream)
		inputStreamHandle = readStream?.takeRetainedValue()
		outputStreamHandle = writeStream?.takeRetainedValue()
	#endif
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
	
    public override var description: String {
		return "\(self.inputStream?.streamStatus.rawValue ?? 99) \(self.outputStream?.streamStatus.rawValue ?? 99)"
    }
	
    private func closeStreams() {
		// We are told streams will be unscheduled from runloop on close
		// Make certain no more callbacks happen
		if let input = inputStream {
			inputStream = nil
			input.delegate = nil // unowned unsafe
			input.close()
		}
		if let output = outputStream {
			outputStream = nil
			output.delegate = nil // unowned unsafe
			output.close()
		}
    }
	
    private func endStream(_ aStream: Stream) {
		aStream.close()
		aStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
		aStream.delegate = nil
		if aStream === outputStream {
			outputStream = nil
		}
		else if aStream === inputStream {
			inputStream = nil
		}
    }
	
	public func writer(writer: (StreamWriter)->()) {
		if let hasOutput = outputStream/*, let hasInput = inputStream,
			hasOutput.streamStatus.canBeUsed,
			hasInput.streamStatus.canBeUsed */{
			mutex.writing {
				writer(hasOutput.write)
			}
			return
		}
		writer { (_, _) -> Int in return -1 }
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
			hasInput.schedule(in: $0, forMode: RunLoop.Mode.default)
			hasInput.open()
		}
		
		FogSocketStream.runloop.runLoop(label: label + ".out", qos: qos) {
			hasOutput.schedule(in: $0, forMode: RunLoop.Mode.default)
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
				//delegate?.fog(stream: self, errored: aStream.streamError)
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
