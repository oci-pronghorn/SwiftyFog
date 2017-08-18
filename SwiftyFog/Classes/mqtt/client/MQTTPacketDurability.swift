//
//  MQTTPacketDurability.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/17/17.
//

import Foundation

// TODO
// persist stuff when clean == false
// restore state when clean == false
// need to be aware of first-reconnect for file persistence
// recreate subscriptions on first time startup if clean is false
// svae/restore id source state

protocol MQTTPacketDurabilityDelegate: class {
	func send(packet: MQTTPacket) -> Bool
}

class MQTTPacketDurability {
	private let idSource: MQTTMessageIdSource
	private let mutex = ReadWriteMutex()
    private let resendTimer: DispatchSourceTimer
	
	private var retryRequestPackets = [(Bool)->()]()
	private var unacknowledgedPackets = [UInt16:(TimeInterval, MQTTPacket, MQTTPacketType)]()
	
	weak var delegate: MQTTPacketDurabilityDelegate?
	
	init(idSource: MQTTMessageIdSource, resendInterval: TimeInterval) {
		self.idSource = idSource
		resendTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
		resendTimer.schedule(deadline: .now() + resendInterval, repeating: resendInterval, leeway: .milliseconds(250))
		resendTimer.setEventHandler { [weak self] in
			self?.resendPulse()
		}
	}

	func connected(cleanSession: Bool, present: Bool, initial: Bool) {
		resendTimer.resume()
	}
	
	@discardableResult
	public func send<T: MQTTPacket>(packet: T) -> Bool {
		return delegate?.send(packet: packet) ?? false
	}
	
	public func send<T: MQTTPacket & MQTTIdentifiedPacket>(packet: T, expecting: MQTTPacketType?, sent: ((T, Bool)->())?) {
		DispatchQueue.global().async {
			self.send(ownership: .theirs(packet), expecting: expecting, sent: sent)
		}
	}
	
	public func send<T: MQTTPacket & MQTTIdentifiedPacket>(packet: @escaping (UInt16)->T, expecting: MQTTPacketType?, sent: ((T, Bool)->())?) {
		DispatchQueue.global().async {
			self.send(ownership: .ours(packet), expecting: expecting, sent: sent)
		}
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
		if delegate?.send(packet: instance) ?? false == false {
			if case .ours(_) = ownership {
				idSource.free(id: messageId)
			}
			mutex.writing {
				unacknowledgedPackets.removeValue(forKey: messageId)
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
		else {
			sent?(instance, true)
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
				let _ = delegate?.send(packet: packet)
			}
		}
	}
	
	func disconnected(cleanSession: Bool, manual: Bool) {
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
