//
//  MQTTConnection.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public struct MQTTClientParams {
    public var clientID: String
    public var cleanSession: Bool = true
    public var keepAlive: UInt16 = 15
	
    public var username: String? = nil
    public var password: String? = nil
    //TODO: public var lastWill: String? = nil
	
    public init(clientID: String) {
		self.clientID = clientID
    }
}

public enum MQTTConnectionDisconnect: String {
	case shutdown
	case socket
	case timeout
	case handshake
	case failedRead
	case failedWrite
	case brokerNotAlive
}

public protocol MQTTConnectionDelegate: class {
	func mqttDiscconnected(_ connection: MQTTConnection, reason: MQTTConnectionDisconnect, error: Error?)
	func mqttConnected(_ connection: MQTTConnection)
	func mqttPinged(_ connection: MQTTConnection, dropped: Bool)
	func mqttPingAcknowledged(_ connection: MQTTConnection)
}

public extension Date {
	static func NowInSeconds() -> Int64 {
		return Int64(Date().timeIntervalSince1970.rounded())
	}
}

public class MQTTConnection {
	private let clientPrams: MQTTClientParams
    private let factory: MQTTPacketFactory
    private var stream: MQTTSessionStream? = nil
    private var keepAliveTimer: DispatchSourceTimer?
	
    public weak var delegate: MQTTConnectionDelegate?
	
	// TODO: threadsafety
    private var isConnected: Bool = false
    private var lastControlPacketSent: Int64 = 0
    private var lastPingSent: Int64 = 0
    private var lastPingAck: Int64 = 0
	
    public init(hostParams: MQTTHostParams, clientPrams: MQTTClientParams) {
		self.clientPrams = clientPrams
		self.factory = MQTTPacketFactory()
		self.stream = MQTTSessionStream(hostParams: hostParams, delegate: self)
		
		if hostParams.timeout > 0 {
			DispatchQueue.global().asyncAfter(deadline: .now() +  hostParams.timeout) { [weak self] in
				self?.fullConnectionTimeout()
			}
		}
    }
	
    deinit {
		if isConnected {
			send(packet: MQTTDisconnectPacket())
			// TODO: Do we have to wait to verify packet has left the building?
			didDisconnect(reason: .shutdown, error: nil)
		}
	}
	
    private func didDisconnect(reason: MQTTConnectionDisconnect, error: Error?) {
        keepAliveTimer?.cancel()
		delegate?.mqttDiscconnected(self, reason: reason, error: error)
		isConnected = false
		self.stream = nil
    }
	
	@discardableResult
    private func send(packet: MQTTPacket) -> Bool {
		if let writer = stream?.writer {
			var data = Data(capacity: 1024)
			packet.writeTo(data: &data)
			if data.write(to: writer) {
				lastControlPacketSent = Date.NowInSeconds()
				return true
			}
			else {
				didDisconnect(reason: .failedWrite, error: nil)
			}
        }
        return false
    }
}

extension MQTTConnection {
    private func startConnectionHandshake() -> Bool {
		let packet = MQTTConnectPacket(
			clientID: clientPrams.clientID,
			cleanSession: clientPrams.cleanSession,
			keepAlive: clientPrams.keepAlive)
		packet.username = clientPrams.username
		packet.password = clientPrams.password
		//TODO: connectPacket.lastWillMessage = clientPrams.lastWill
		return self.send(packet: packet)
    }
	
    private func handshakeFinished(packet: MQTTConnAckPacket) {
		let success = (packet.response == .connectionAccepted)
		if success {
			isConnected = true
			delegate?.mqttConnected(self)
			startPing()
		}
		else {
			self.didDisconnect(reason: .handshake, error: packet.response)
		}
    }
	
	private func fullConnectionTimeout() {
		if isConnected == false {
			self.didDisconnect(reason: .timeout, error: nil)
		}
	}
}

extension MQTTConnection {
    private func startPing() {
		if clientPrams.keepAlive > 0 {
			let keepAliveTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
			keepAliveTimer.schedule(deadline: .now() + .seconds(Int(clientPrams.keepAlive)), repeating: .seconds(Int(clientPrams.keepAlive)), leeway: .milliseconds(250))
			keepAliveTimer.setEventHandler { [weak self] in
				self?.pingFired()
			}
			self.keepAliveTimer = keepAliveTimer
			keepAliveTimer.resume()
		}
	}
	
    private func pingFired() {
		if isConnected == true {
			let now = Date.NowInSeconds()
			if lastPingAck == 0 {
				lastPingAck = now
			}
			if serverAliveTest() {
				if (now - lastControlPacketSent >= UInt64(clientPrams.keepAlive)) {
					if send(packet: MQTTPingPacket()) {
						lastPingSent = Date.NowInSeconds()
						delegate?.mqttPinged(self, dropped: false)
					}
				}
				else {
					delegate?.mqttPinged(self, dropped: true)
				}
			}
		}
    }
	
    private func serverAliveTest() -> Bool {
		return true
		// TODO: The spec says we should receive a a ping ack after a "reasonable amount of time"
		// The mosquitto logs states that it is sending immediately and every time.
		// Reception is ony once and after keep alive period
		let timePassed = Date.NowInSeconds() - lastPingAck
		// The keep alive range on server is 1.5 * keepAlive
		let limit = UInt64(clientPrams.keepAlive + (clientPrams.keepAlive / 2))
		if timePassed > limit {
			self.didDisconnect(reason: .brokerNotAlive, error: nil)
			return false
		}
		return true
    }
	
    private func pingResponseReceived(packet: MQTTPingAckPacket) {
		lastPingAck = Date.NowInSeconds()
		delegate?.mqttPingAcknowledged(self)
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
				case let packet as MQTTConnAckPacket:
					self.handshakeFinished(packet: packet)
					break
				case let packet as MQTTPingAckPacket:
					self.pingResponseReceived(packet: packet)
					break
				default:
					break
			}
        }
        else {
			self.didDisconnect(reason: .failedRead, error: nil)
        }
	}
}
