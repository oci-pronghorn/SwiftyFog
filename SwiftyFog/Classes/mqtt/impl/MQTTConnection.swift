//
//  MQTTConnection.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

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
	case stopped // by client
	case socket // by connection
	case handshake(MQTTConnAckResponse) // by connection
	case brokerNotAlive // by connection
	case failedRead // from stream
	case failedWrite // from stream
	case serverDisconnectedUs // from stream
}

protocol MQTTConnectionDelegate: class {
	func mqtt(connection: MQTTConnection, disconnected: MQTTConnectionDisconnect, error: Error?)
	func mqtt(connection: MQTTConnection, connectedAsPresent: Bool)
	func mqtt(connection: MQTTConnection, pinged: MQTTPingStatus)
	func mqtt(connection: MQTTConnection, received: MQTTPacket)
}

final class MQTTConnection {
	private let hostParams: MQTTHostParams
	private let clientPrams: MQTTClientParams
	private let authPrams: MQTTAuthentication
    private let factory: MQTTPacketFactory
	private let metrics: MQTTMetrics?
    private var stream: FogSocketStream?
	
    private var keepAliveTimer: DispatchSourceTimer?
    private weak var delegate: MQTTConnectionDelegate?
	
	private let mutex = ReadWriteMutex()
    private(set) var isFullConnected: Bool = false
    private var lastControlPacketSent: Int64 = 0
    private var lastPingAck: Int64 = 0
	
    init(
			hostParams: MQTTHostParams,
			clientPrams: MQTTClientParams,
			authPrams: MQTTAuthentication,
			socketQoS: DispatchQoS,
			metrics: MQTTMetrics?) {
		self.hostParams = hostParams
		self.clientPrams = clientPrams
		self.authPrams = authPrams
		self.metrics = metrics
		self.factory = MQTTPacketFactory(metrics: metrics)
		
		self.stream = FogSocketStream(hostName: hostParams.host, port: Int(hostParams.port), qos: socketQoS)
    }
	
    func start(delegate: MQTTConnectionDelegate?) {
		self.delegate = delegate
		if let stream = stream {
			stream.start(isSSL: hostParams.ssl, delegate: self)
		}
		else {
			didDisconnect(reason: .socket, error: nil)
		}
    }
	
    deinit {
		if mutex.reading({isFullConnected}) {
			send(packet: MQTTDisconnectPacket())
			self.delegate = nil // do not expose self in deinit
			didDisconnect(reason: .socket, error: nil)
		}
	}
	
    private func didDisconnect(reason: MQTTConnectionDisconnect, error: Error?) {
		if self.stream != nil {
			self.stream = nil
			keepAliveTimer?.cancel()
			delegate?.mqtt(connection: self, disconnected: reason, error: error)
			mutex.writing {
				isFullConnected = false
			}
		}
    }
	
	@discardableResult
    func send(packet: MQTTPacket) -> Bool {
		if let writer = stream?.writer {
			if factory.send(packet, writer) {
				if clientPrams.treatControlPacketsAsPings {
					mutex.writing {
						lastControlPacketSent = Date.nowInSeconds()
					}
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
		packet.username = authPrams.username?.utf8
		packet.password = authPrams.password?.utf8
		packet.lastWillMessage = clientPrams.lastWill
		return self.send(packet: packet)
    }
	
    private func handshakeFinished(packet: MQTTConnAckPacket) {
		let success = (packet.response == .connectionAccepted)
		if success {
			mutex.writing {
				isFullConnected = true
			}
			delegate?.mqtt(connection: self, connectedAsPresent: packet.sessionPresent)
			startPing()
		}
		else {
			self.didDisconnect(reason: .handshake(packet.response), error: packet.response)
		}
    }
	
	private func fullConnectionTimeout() {
		if mutex.reading({isFullConnected}) == false {
			//self.didDisconnect(reason: .handshake(.timeout), error: nil)
		}
		// else we are already connected!
	}
}

extension MQTTConnection {
    private func startPing() {
		if clientPrams.keepAlive > 0 {
			let keepAliveTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
			keepAliveTimer.schedule(deadline: .now() + .seconds(Int(clientPrams.keepAlive)), repeating: .seconds(Int(clientPrams.keepAlive)), leeway: .seconds(1))
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
				if clientPrams.detectServerDeath {
					// The spec says we should receive a a ping ack after a "reasonable amount of time"
					// The mosquitto logs states that it is sending immediately and every time.
					// Actual send is usually ony once and after keep alive period
					let timePassed = now - lastPingAck
					// The keep alive range on server is 1.5 * keepAlive
					let limit = UInt64(clientPrams.keepAlive + (clientPrams.keepAlive / 2))
					if timePassed > limit {
						status = .serverDied
					}
				}
				if status != .serverDied {
					let secondsSinceLastPacket = now - lastControlPacketSent
					if (clientPrams.treatControlPacketsAsPings == false || secondsSinceLastPacket >= UInt64(clientPrams.keepAlive)) {
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
		if status == .serverDied || status == .notConnected {
			self.didDisconnect(reason: .brokerNotAlive, error: nil)
		}
		delegate?.mqtt(connection: self, pinged: status)
    }
	
    private func pingResponseReceived(packet: MQTTPingAckPacket) {
		mutex.writing {
			lastPingAck = Date.nowInSeconds()
		}
		delegate?.mqtt(connection: self, pinged: .ack)
    }
}

extension MQTTConnection: FogSocketStreamDelegate {
	func fog(streamReady: FogSocketStream) {
		if startConnectionHandshake() == false {
			self.didDisconnect(reason: .socket, error: nil)
		}
		else {
			// TODO: I don't think this is required
			if 10 > 0 {
				DispatchQueue.global().asyncAfter(deadline: .now() +  10) { [weak self] in
					self?.fullConnectionTimeout()
				}
			}
		}
	}

	func fog(stream: FogSocketStream, errored: Error?) {
		self.didDisconnect(reason: .socket, error: errored)
	}

	func fog(stream: FogSocketStream, received: StreamReader) {
		let parsed = factory.receive(received)
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
					delegate?.mqtt(connection: self, received: packet)
					break
			}
        }
        else {
			self.didDisconnect(reason: .failedRead, error: nil)
        }
	}
}
