//
//  MQTTConnection.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

enum MQTTConnectionDisconnect {
	case socket
	case timeout
	case handshake
	case shutdown
}

struct MQTTClientParams {
    public var clientID: String
    public var cleanSession: Bool = true
    public var keepAlive: UInt16 = 10
	
    public var username: String?
    public var password: String?
    public var lastWill: String?
}

struct MQTTHostParams {
    public var host: String
    public var port: UInt16
    public var ssl: Bool
    public var timeout: TimeInterval
}

protocol MQTTConnectionDelegate: class {
	func mqttDiscconnected(_ connection: MQTTConnection, reason: MQTTConnectionDisconnect, error: Error?)
	func mqttConnected(_ connection: MQTTConnection)
}

class MQTTConnection {
	private let clientPrams: MQTTClientParams
    private let factory: MQTTPacketFactory
    private var stream: MQTTSessionStream? = nil
    private var keepAliveTimer: DispatchSourceTimer?
	
    public weak var delegate: MQTTConnectionDelegate?
	
	// TODO: threadsafe?
    private var isConnected: Bool = false
    private var lastControlPacketSent: TimeInterval = 0.0
	
    init(clientPrams: MQTTClientParams, host: MQTTHostParams) {
		self.clientPrams = clientPrams
		self.factory = MQTTPacketFactory()
		self.stream = MQTTSessionStream(host: host.host, port: host.port, ssl: host.ssl, timeout: host.timeout, delegate: self)
		if host.timeout > 0 {
			DispatchQueue.global().asyncAfter(deadline: .now() +  host.timeout) { [weak self] in
				self?.handshakeTimeout()
			}
		}
    }
	
    deinit {
		if isConnected {
			send(packet: MQTTDisconnectPacket())
			// TODO: Do we have to wait?
			didDisconnect(reason: .shutdown, error: nil)
		}
	}
	
    private func didDisconnect(reason: MQTTConnectionDisconnect, error: Error?) {
        keepAliveTimer?.cancel()
		delegate?.mqttDiscconnected(self, reason: reason, error: error)
    }
	
    private func streamConnected() {
		let keepAliveTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
		keepAliveTimer.schedule(deadline: .now() + .seconds(Int(clientPrams.keepAlive)), repeating: .seconds(Int(clientPrams.keepAlive)), leeway: .milliseconds(500))
		keepAliveTimer.setEventHandler { [weak self] in
			self?.keepAliveTimerFired()
		}
		self.keepAliveTimer = keepAliveTimer
		keepAliveTimer.resume()
    }
	
    private func startConnectionHandshake() -> Bool {
		let packet = MQTTConnectPacket(
			clientID: clientPrams.clientID,
			cleanSession: clientPrams.cleanSession,
			keepAlive: clientPrams.keepAlive)
		packet.username = clientPrams.username
		packet.password = clientPrams.password
		//connectPacket.lastWillMessage = clientPrams.lastWill
		
		return self.send(packet: packet)
    }
	
    private func handshakeFinished(packet: MQTTConnAckPacket) {
		let success = (packet.response == .connectionAccepted)
		if success {
			isConnected = true
			delegate?.mqttConnected(self)
		}
		else {
			self.didDisconnect(reason: .handshake, error: packet.response)
		}
    }
	
	private func handshakeTimeout() {
		if isConnected == false {
			self.didDisconnect(reason: .timeout, error: nil)
		}
	}
	
	@discardableResult
    private func send(packet: MQTTPacket) -> Bool {
		if let writer = stream?.writer {
			var data = Data(capacity: 1024)
			packet.writeTo(data: &data)
			lastControlPacketSent = Date().timeIntervalSince1970
			return data.write(to: writer)
        }
        return false
    }
	
    fileprivate func keepAliveTimerFired() {
		let now = Date().timeIntervalSince1970
		if isConnected == true && (now - lastControlPacketSent >= TimeInterval(clientPrams.keepAlive)) {
			send(packet: MQTTPingPacket())
		}
    }
}

extension MQTTConnection: MQTTSessionStreamDelegate {
	func mqttStreamConnected(_ ready: Bool, in stream: MQTTSessionStream) {
		if ready {
			if startConnectionHandshake() == false {
				self.didDisconnect(reason: .handshake, error: nil)
			}
		}
		else {
			self.didDisconnect(reason: .timeout, error: nil)
		}
	}
	
	func mqttStreamErrorOccurred(in stream: MQTTSessionStream, error: Error?) {
		self.didDisconnect(reason: .socket, error: error)
	}
	
	func mqttStreamReceived(in stream: MQTTSessionStream, _ read: (UnsafeMutablePointer<UInt8>, Int) -> Int) {
        if let packet = factory.parse(read) {
			switch packet {
				case let connAckPacket as MQTTConnAckPacket:
					self.handshakeFinished(packet: connAckPacket)
					break
				case _ as MQTTPingResp:
					break
				default:
					break
			}
        }
	}
}
