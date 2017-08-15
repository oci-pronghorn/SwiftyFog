//
//  MQTTMessageIdSource.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/13/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

// todo: read from file if reboot
final class MQTTMessageIdSource {
	private let mutex = ReadWriteMutex()
	private var chart = [UInt8](repeating: 0xFF, count: Int(UInt16.max / 8))
	private var hint = UInt16(0)
	
	func fetch() -> UInt16 {
		return mutex.writing {
			for i in hint...UInt16.max {
				if isAvailable(i) {
					retain(i)
					progressHint()
					return i
				}
			}
			for i in 0..<hint {
				if isAvailable(i) {
					retain(i)
					progressHint()
					return i
				}
			}
			return 0
		}
	}
	
	func free(id: UInt16) {
		mutex.writing {
			release(id)
		}
	}
	
	private func progressHint() {
		for i in (hint+1)...UInt16.max {
			if isAvailable(i) {
				hint = i
				return
			}
		}
		for i in 0..<hint {
			if isAvailable(i) {
				hint = i
				return
			}
		}
	}
	
	private func isAvailable(_ id: UInt16) -> Bool {
		let idx = Int(id) / 8
		let offset = (id + 8) % 8
		return (chart[idx] & (0x01 << offset)) != 0
	}
	
	private func retain(_ id: UInt16) {
		let idx = Int(id) / 8
		let offset = (id + 8) % 8
		chart[idx] &= ~(0x01 << offset)
	}
	
	private func release(_ id: UInt16) {
		let idx = Int(id) / 8
		let offset = (id + 8) % 8
		chart[idx] |= (0x01 << offset)
	}
}
