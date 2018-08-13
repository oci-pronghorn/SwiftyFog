//
//  MQTTMessageIdSource.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

final class MQTTMessageIdSource {
	private let mutex = ReadWriteMutex()
	private let metrics: MQTTIdMetrics?
	private var chart = [UInt8](repeating: 0xFF, count: Int(UInt16.max / 8))
	private var hint = UInt16(0)
	
	private(set) var inuse: Int = 0
	
	init(metrics: MQTTIdMetrics?) {
		self.metrics = metrics
	}
	
	func connected(cleanSession: Bool, present: Bool, initial: Bool) {
	}
	
	func disconnected(cleanSession: Bool, stopped: Bool) {
		if cleanSession {
			mutex.writing {
				chart = [UInt8](repeating: 0xFF, count: Int(UInt16.max / 8))
				hint = UInt16(0)
			}
		}
	}
	
	func fetch() -> UInt16 {
		return mutex.writing {
			for i in hint...UInt16.max {
				if progressHint(found: i) {
					return i
				}
			}
			for i in 0..<hint {
				if progressHint(found: i) {
					return i
				}
			}
			return 0
		}
	}
	
	func free(id: UInt16) {
		mutex.writing {
			if !isAvailable(id) {
				release(id)
			}
			else {
				//re-released
			}
		}
	}
	
	private func progressHint(found: UInt16) -> Bool {
		if isAvailable(found) {
			retain(found)
			for i in (hint+1)...UInt16.max {
				if isAvailable(i) {
					hint = i
					return true
				}
			}
			for i in 0..<hint {
				if isAvailable(i) {
					hint = i
					return true
				}
			}
			return true
		}
		return false
	}
	
	private func isAvailable(_ id: UInt16) -> Bool {
		let idx = Int(id) / 8
		let offset = (id + 8) % 8
		return (chart[idx] & (0x01 << offset)) != 0
	}
	
	private func retain(_ id: UInt16) {
		inuse += 1
		if let metrics = metrics {
			metrics.setIdsInUse(idsInUse: inuse)
			if metrics.printIdRetains {
				metrics.debug("Retain \(id) used: \(inuse)")
			}
		}
		let idx = Int(id) / 8
		let offset = (id + 8) % 8
		chart[idx] &= ~(0x01 << offset)
	}
	
	private func release(_ id: UInt16) {
		inuse -= 1
		if let metrics = metrics {
			metrics.setIdsInUse(idsInUse: inuse)
			if metrics.printIdRetains {
				metrics.debug("Release \(id) used: \(inuse)")
			}
		}
		let idx = Int(id) / 8
		let offset = (id + 8) % 8
		chart[idx] |= (0x01 << offset)
	}
}
