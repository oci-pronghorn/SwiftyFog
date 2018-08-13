//
//  MQTTConnection.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // Date Dispatch...

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
    private let factory: PacketMarshaller
	private let metrics: MQTTMetrics?
    private var stream: FogSocketStream?
	
    private var keepAliveTimer: DispatchSourceTimer?
    private weak var delegate: MQTTConnectionDelegate?
	
	private let mutex = ReadWriteMutex()
	// The spec says we can send packets before the ack - but that gets ugly if failed
    private(set) var isFullConnected: Bool = false
    private var lastPingPacketSent: Int64 = 0
    private var expectPingPacketStart: Int64 = Int64.max
	
    init(
    		factory: PacketMarshaller,
			hostParams: MQTTHostParams,
			clientPrams: MQTTClientParams,
			authPrams: MQTTAuthentication,
			socketQoS: DispatchQoS,
			metrics: MQTTMetrics?) {
		self.factory = factory
		self.hostParams = hostParams
		self.clientPrams = clientPrams
		self.authPrams = authPrams
		self.metrics = metrics
		
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
			if clientPrams.lastWill == nil || clientPrams.alwaysSendLastWill == false {
				send(packet: MQTTDisconnectPacket())
			}
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
			if let metrics = metrics, metrics.printSendPackets {
				metrics.debug("Send: \(packet)")
			}
			if factory.send(packet, writer) {
				let now = Date.nowInSeconds()
				mutex.writing {
					if clientPrams.treatControlPacketsAsPings || packet.header.packetType == .pingReq {
						lastPingPacketSent = now
					}
					if clientPrams.detectServerDeath > 0 && packet.expectsAcknowledgement {
						expectPingPacketStart = now
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
}

extension MQTTConnection {
    private func startPing() {
		var interval = 0
		if clientPrams.keepAlive > 0 {
			interval = Int(clientPrams.keepAlive) / 3
		}
		if clientPrams.detectServerDeath > 0 && clientPrams.detectServerDeath < interval {
			interval = Int(clientPrams.detectServerDeath)
		}
	
		if interval > 0 {
			let keepAliveTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
			keepAliveTimer.schedule(deadline: .now() + .seconds(interval), repeating: .seconds(interval), leeway: .seconds(1))
			keepAliveTimer.setEventHandler { [weak self] in
				self?.pingFired()
			}
			self.keepAliveTimer = keepAliveTimer
			keepAliveTimer.resume()
		}
	}
	
    private func pingFired() {
		var status: MQTTPingStatus = .skipped
		let now = Date.nowInSeconds()
		mutex.writing {
			if isFullConnected == false {
				status = .notConnected
			}
			else {
				if clientPrams.detectServerDeath > 0 && expectPingPacketStart != Int64.max {
					let secondsSinceLastPingExpectation = now - expectPingPacketStart
					let limit = UInt64(clientPrams.detectServerDeath)
					if secondsSinceLastPingExpectation > limit {
						status = .serverDied
					}
				}
				if status != .serverDied {
					let secondsSinceLastPing = now - lastPingPacketSent
					let limit = UInt64(clientPrams.keepAlive)
					if secondsSinceLastPing >= limit {
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
		else if status == .skipped {
			let secondsSinceLastPing = now - lastPingPacketSent
			if secondsSinceLastPing <= UInt64(clientPrams.keepAlive * 2 / 3) {
				return
			}
		}
		delegate?.mqtt(connection: self, pinged: status)
    }
	
    private func pingResponseReceived(packet: MQTTPingAckPacket) {
		delegate?.mqtt(connection: self, pinged: .ack)
    }
}

extension MQTTConnection: FogSocketStreamDelegate {
	func fog(streamReady: FogSocketStream) {
		if startConnectionHandshake() == false {
			self.didDisconnect(reason: .socket, error: nil)
		}
		// else wait for ack
	}

	func fog(stream: FogSocketStream, errored: Error?) {
		self.didDisconnect(reason: .socket, error: errored)
	}

	func fog(stream: FogSocketStream, received: StreamReader) {
		let parsed = factory.receive(received)
        if case .success(let packet) = parsed {
			if clientPrams.detectServerDeath > 0 {
				mutex.writing {
					expectPingPacketStart = Int64.max
				}
			}
			if let metrics = metrics, metrics.printReceivePackets {
				metrics.debug("Receive: \(packet)")
			}
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
		else if parsed.isClosedStream {
			self.didDisconnect(reason: .serverDisconnectedUs, error: nil)
		}
        else {
			self.didDisconnect(reason: .failedRead, error: nil)
        }
	}
}
