//
//  MQTTPacketDurability.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/17/17.
//

import Foundation

// TODO
// Move all resendPulse impls into here
// Remove timer from client
// persist stuff when clean == false
// restore state when clean == false
// need to be aware of first-reconnect for file persistence

class MQTTPacketDurability {
	private let mutex = ReadWriteMutex()
	private let idSource: MQTTMessageIdSource
    private let resendTimer: DispatchSourceTimer
	/*
		Take over resendPulse responsibility
	*/
	
	init(idSource: MQTTMessageIdSource, resendInterval: TimeInterval) {
		self.idSource = idSource
		resendTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
		resendTimer.schedule(deadline: .now() + resendInterval, repeating: resendInterval, leeway: .milliseconds(250))
		resendTimer.setEventHandler { [weak self] in
			self?.resendPulse()
		}
	}
	
	func connected(cleanSession: Bool, present: Bool) {
	}
	
	func addFailedSentPacket() {
	}

	func addUnacknowledgedPacket() {
	}
	
	func acknowledgePacket() {
	}
	
	private func resendPulse() {
	}
	
	func disconnected(cleanSession: Bool, manual: Bool) {
	}
}
