//
//  MQTTPacketDurability.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/17/17.
//

import Foundation

protocol MQTTPacketDurabilityDelegate: class {
	func mqtt(send: MQTTPacket, completion: @escaping (Bool)->())
}

protocol MQTTPacketIssuer {
	func send<T: MQTTPacket>(packet: T, sent: ((T, Bool)->())?)
	func send<T: MQTTPacket & MQTTIdentifiedPacket>(packet: T, expecting: MQTTPacketType?, sent: ((T, Bool)->())?)
	func send<T: MQTTPacket & MQTTIdentifiedPacket>(packet: @escaping (UInt16)->T, expecting: MQTTPacketType?, sent: ((T, Bool)->())?)
	func received<T: MQTTPacket & MQTTIdentifiedPacket>(acknolwedgment: T, releaseId: Bool)
}

final class MQTTPacketDurability: MQTTPacketIssuer {
	private let idSource: MQTTMessageIdSource
	private let queuePubOnDisconnect: MQTTQoS?
	private let mutex = ReadWriteMutex()
    private let resendTimer: DispatchSourceTimer
    private let resendInterval: TimeInterval
	
	private var retryRequestPackets = [(Bool)->()]()
	private var unacknowledgedPackets = [UInt16:(TimeInterval, MQTTPacket, MQTTPacketType)]()
	
	weak var delegate: MQTTPacketDurabilityDelegate?
	
	init(idSource: MQTTMessageIdSource, queuePubOnDisconnect: MQTTQoS?, resendInterval: TimeInterval) {
		self.idSource = idSource
		self.queuePubOnDisconnect = queuePubOnDisconnect
		self.resendInterval = resendInterval
		resendTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
		resendTimer.setEventHandler { [weak self] in
			self?.resendPulse()
		}
	}

	// TODO: spec says retry must be on reconnect but not necessarely timer while connected
	func connected(cleanSession: Bool, present: Bool, initial: Bool) {
		resendTimer.schedule(deadline: .now() + resendInterval, repeating: resendInterval, leeway: .milliseconds(250))
		resendTimer.resume()
	}
	
	public func send<T: MQTTPacket>(packet: T, sent: ((T, Bool)->())?) {
		// TODO: use private send method
		if let delegate = delegate {
			delegate.mqtt(send: packet) { success in
				sent?(packet, success)
			}
		}
		else {
			sent?(packet, false)
		}
	}
	
	public func send<T: MQTTPacket & MQTTIdentifiedPacket>(packet: T, expecting: MQTTPacketType?, sent: ((T, Bool)->())?) {
		self.send(ownership: .theirs(packet), expecting: expecting, sent: sent)
	}
	
	public func send<T: MQTTPacket & MQTTIdentifiedPacket>(packet: @escaping (UInt16)->T, expecting: MQTTPacketType?, sent: ((T, Bool)->())?) {
		self.send(ownership: .ours(packet), expecting: expecting, sent: sent)
	}
	
	private enum IdOwnerShip<T: MQTTPacket & MQTTIdentifiedPacket> {
		case ours((UInt16)->T)
		case theirs(T)
	}
	
	private func send<T>(ownership: IdOwnerShip<T>, expecting: MQTTPacketType?, sent: ((T, Bool)->())?) {
		let messageId: UInt16
		let instance: T
		switch ownership {
			case .ours(let factory):
				messageId = idSource.fetch()
				instance = factory(messageId)
				break
			case .theirs(let packet):
				instance = packet
				messageId = packet.messageID
				break
		}
		if let expecting = expecting {
			let dup = instance.dupForResend()
			mutex.writing {
				unacknowledgedPackets[messageId] = (Date().timeIntervalSince1970, dup, expecting)
			}
		}
		if let delegate = delegate {
			delegate.mqtt(send: instance) { [weak self] success in
				if success == false {
					self?.didFailToSend(instance, ownership, messageId, expecting, sent)
				}
				else {
					sent?(instance, true)
				}
			}
		}
		else {
			sent?(instance, false)
		}
	}
	
	private func didFailToSend<T>(_ instance: T, _ ownership: IdOwnerShip<T>, _ messageId: UInt16, _ expecting: MQTTPacketType?, _ sent: ((T, Bool)->())?) {
		if case .ours(_) = ownership {
			idSource.free(id: messageId)
		}
		mutex.writing {
			unacknowledgedPackets.removeValue(forKey: messageId)
			// TODO: use queuePubOnDisconnect on retry
			retryRequestPackets.append({ [weak self] goForth in
				if let me = self, goForth {
					me.send(ownership: ownership, expecting: expecting, sent: sent)
				}
				else {
					sent?(instance, false)
				}
			})
		}
	}
	
	public func received<T: MQTTPacket & MQTTIdentifiedPacket>(acknolwedgment: T, releaseId: Bool) {
		if releaseId {
			idSource.free(id: acknolwedgment.messageID)
		}
		mutex.writing {
			unacknowledgedPackets[acknolwedgment.messageID] = nil
		}
	}
	
	private func resendPulse() {
		mutex.writing {
			let all = retryRequestPackets
			retryRequestPackets.removeAll(keepingCapacity: true)
			for retry in all {
				retry(true) // will reappend
			}
			for element in unacknowledgedPackets.sorted(by: {$0.1.0 < $1.1.0}) {
				let packet = element.value.1
				delegate?.mqtt(send: packet, completion: {_ in})
			}
		}
	}
	
	func disconnected(cleanSession: Bool, stopped: Bool) {
		resendTimer.suspend()
		mutex.writing {
			for request in retryRequestPackets {
				request(false)
			}
			retryRequestPackets.removeAll()
			if cleanSession == true {
				unacknowledgedPackets.removeAll()
			}
		}
	}
}
