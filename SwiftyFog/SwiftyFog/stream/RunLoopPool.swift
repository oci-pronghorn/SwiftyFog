//
//  RunLoopPool.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/25/17.
//

import Foundation // Runloop

/*
We are trying to solve several issues
- We don't want to be creating and deleting Queue-Thread-RunLoop on every connection attempt.
-- But reusing DispatchQueue's will cause subsequent connections to start failing
-- But closing the sockets does not dismiss the runloop
-- But there is no way to determine what is keeping the runloop alive
-- But there is no high level quit method on the runloop
-- But the need for unscheduling is not consistently documented, exampled, or easily done

 Today we are not reusing DispatchQueue per host and aborting old DispatchQueue's
*/
public final class RunLoopPool {
	private let resuseMode: Bool
	private let mutex = ReadWriteMutex()
	private var runloops : [String : (DispatchGroup, DispatchQueue, RunLoop?)] = [:]
	
	init(resuseMode: Bool) {
		self.resuseMode = resuseMode
	}

	public func runLoop(label: String, qos: DispatchQoS, with: @escaping (RunLoop)->()) {
		let element: (DispatchGroup, DispatchQueue?) = mutex.writing {
			if let element = runloops[label] {
				if resuseMode == true {
					return (element.0, nil)
				}
				else if let foundation = element.2?.getCFRunLoop() {
					CFRunLoopStop(foundation)
				}
			}
			let signal = DispatchGroup()
			let thread = DispatchQueue(label: label, qos: qos)
			runloops[label] = (signal, thread, nil)
			signal.enter()
			return (signal, thread)
		}
		if let thread = element.1 {
			thread.async { [weak self] in
				self?.run(label, element.0, with)
			}
		}
		else {
			let _ = element.0.wait(timeout: DispatchTime.distantFuture)
			with(mutex.reading{runloops[label]!.2!})
		}
	}
	
	private func run(_ label: String, _ signal: DispatchGroup, _ with: @escaping (RunLoop)->()) {
		let currentRunLoop = RunLoop.current
		self.mutex.writing {
			self.runloops[label]!.2 = currentRunLoop
		}
		signal.leave()
		with(currentRunLoop)
		currentRunLoop.run()
	}
}
