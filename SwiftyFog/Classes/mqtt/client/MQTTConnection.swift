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
    public var cleanSession: Bool
    public var keepAlive: UInt16
	
    public var username: String? = nil
    public var password: String? = nil
    public var lastWill: MQTTPubMsg? = nil
	
    public var resendPulseInterval: TimeInterval = 5.0
    public var qos2Mode: Qos2Mode = .lowLatency
	
    public init(clientID: String, cleanSession: Bool = true, keepAlive: UInt16 = 60) {
		self.clientID = clientID
		self.cleanSession = cleanSession
		self.keepAlive = keepAlive
    }
}

// The following are the ping activities
public enum MQTTPingStatus: String {
	case notConnected
	case sent
	case skipped
	case ack
	case serverDied
}

// The following are reasons for disconnection from broker
public enum MQTTConnectionDisconnect {
	case manual
	case socket
	case timeout
	case handshake(MQTTConnAckResponse)
	case failedRead
	case failedWrite
	case brokerNotAlive
	case serverDisconnectedUs // cause by client sending bad data to server
}

protocol MQTTConnectionDelegate: class {
	func mqttDisconnected(_ connection: MQTTConnection, reason: MQTTConnectionDisconnect, error: Error?)
	func mqttConnected(_ connection: MQTTConnection, present: Bool)
	func mqttPinged(_ connection: MQTTConnection, status: MQTTPingStatus)
	func mqttReceived(_ connection: MQTTConnection, packet: MQTTPacket)
}

final class MQTTConnection {
	private let clientPrams: MQTTClientParams
	private let supportsServerAliveCheck = false
    private var factory: MQTTPacketFactory
    private var stream: MQTTSessionStream? = nil
    private var keepAliveTimer: DispatchSourceTimer?
	
    weak var delegate: MQTTConnectionDelegate?
	
    public var debugOut : ((String)->())? = nil {
		didSet {
			factory.debugOut = debugOut
		}
    }
	
	private let mutex = ReadWriteMutex()
    private var isFullConnected: Bool = false
    private var lastControlPacketSent: Int64 = 0
    private var lastPingAck: Int64 = 0
	
    init(hostParams: MQTTHostParams, clientPrams: MQTTClientParams) {
		self.clientPrams = clientPrams
		self.factory = MQTTPacketFactory()
		
		// May return nil if streams cannot be open
		self.stream = MQTTSessionStream(hostParams: hostParams, delegate: self)
		
		if hostParams.timeout > 0 {
			DispatchQueue.global().asyncAfter(deadline: .now() +  hostParams.timeout) { [weak self] in
				self?.fullConnectionTimeout()
			}
		}
    }
	
    var cleanSession: Bool {
		return clientPrams.cleanSession
    }
	
    deinit {
		if mutex.reading({isFullConnected}) {
			send(packet: MQTTDisconnectPacket())
			self.delegate = nil // do not expose self in deinit
			didDisconnect(reason: .manual, error: nil)
		}
	}
	
    private func didDisconnect(reason: MQTTConnectionDisconnect, error: Error?) {
        keepAliveTimer?.cancel()
		delegate?.mqttDisconnected(self, reason: reason, error: error)
		mutex.writing {
			isFullConnected = false
		}
		self.stream = nil
    }
	
	@discardableResult
    func send(packet: MQTTPacket) -> Bool {
		if let writer = stream?.writer {
			if factory.send(packet, writer) {
				mutex.writing {
					lastControlPacketSent = Date.nowInSeconds()
				}
				return true
			}
			else {
				didDisconnect(reason: .failedWrite, error: nil)
			}
        }
        // else not connected
        return false
    }
}

extension MQTTConnection {
    private func startConnectionHandshake() -> Bool {
		let packet = MQTTConnectPacket(
			clientID: clientPrams.clientID,
			cleanSession: clientPrams.cleanSession,
			keepAlive: clientPrams.keepAlive)
		packet.username = clientPrams.username?.utf8
		packet.password = clientPrams.password?.utf8
		packet.lastWillMessage = clientPrams.lastWill
		return self.send(packet: packet)
    }
	
    private func handshakeFinished(packet: MQTTConnAckPacket) {
		let success = (packet.response == .connectionAccepted)
		if success {
			mutex.writing {
				isFullConnected = true
			}
			delegate?.mqttConnected(self, present: packet.sessionPresent)
			startPing()
		}
		else {
			self.didDisconnect(reason: .handshake(packet.response), error: packet.response)
		}
    }
	
	private func fullConnectionTimeout() {
		if mutex.reading({isFullConnected}) == false {
			self.didDisconnect(reason: .timeout, error: nil)
		}
		// else we are already connected!
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
		var status: MQTTPingStatus = .skipped
		mutex.writing {
			if isFullConnected == false {
				status = .notConnected
			}
			else {
				let now = Date.nowInSeconds()
				if lastPingAck == 0 {
					lastPingAck = now
				}
				if supportsServerAliveCheck {
					// TODO: The spec says we should receive a a ping ack after a "reasonable amount of time"
					// The mosquitto logs states that it is sending immediately and every time.
					// Reception is ony once and after keep alive period
					let timePassed = now - lastPingAck
					// The keep alive range on server is 1.5 * keepAlive
					let limit = UInt64(clientPrams.keepAlive + (clientPrams.keepAlive / 2))
					if timePassed > limit {
						status = .serverDied
					}
				}
				if status != .serverDied {
					if (now - lastControlPacketSent >= UInt64(clientPrams.keepAlive)) {
						status = .sent
					}
				}
			}
		}
		if status == .sent {
			if send(packet: MQTTPingPacket()) == false {
				status = .notConnected
			}
		}
		if status == .serverDied {
			self.didDisconnect(reason: .brokerNotAlive, error: nil)
		}
		delegate?.mqttPinged(self, status: status)
    }
	
    private func pingResponseReceived(packet: MQTTPingAckPacket) {
		mutex.writing {
			lastPingAck = Date.nowInSeconds()
		}
		delegate?.mqttPinged(self, status: .ack)
    }
}

extension MQTTConnection: MQTTSessionStreamDelegate {
	func mqttStreamConnected(_ ready: Bool, in stream: MQTTSessionStream) {
		if ready {
			if startConnectionHandshake() == false {
				self.didDisconnect(reason: .socket, error: nil)
			}
			// else wait for ack
		}
		else {
			self.didDisconnect(reason: .timeout, error: nil)
		}
	}
	
	func mqttStreamErrorOccurred(in stream: MQTTSessionStream, error: Error?) {
		self.didDisconnect(reason: .socket, error: error)
	}
	
	func mqttStreamReceived(in stream: MQTTSessionStream, _ read: (UnsafeMutablePointer<UInt8>, Int) -> Int) {
		let parsed = factory.parse(read)
		if parsed.0 {
			self.didDisconnect(reason: .serverDisconnectedUs, error: nil)
			return
		}
        if let packet = parsed.1 {
			switch packet {
				case let packet as MQTTConnAckPacket:
					self.handshakeFinished(packet: packet)
					break
				case let packet as MQTTPingAckPacket:
					self.pingResponseReceived(packet: packet)
					break
				default:
					delegate?.mqttReceived(self, packet: packet)
					break
			}
        }
        else {
			self.didDisconnect(reason: .failedRead, error: nil)
        }
	}
}
