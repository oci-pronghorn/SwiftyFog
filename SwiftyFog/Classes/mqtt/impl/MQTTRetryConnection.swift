//
//  MQTTRetryConnection.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/15/17.
//

import Foundation

class MQTTRetryConnection {
	private let spec: MQTTReconnectParams
	private let attemptConnect: ()->()
	
	var connected: Bool = false {
		didSet {
			if oldValue == true && connected == false {
				self.retryConnect(attempt: 0)
			}
		}
	}
	
	init(spec: MQTTReconnectParams, attemptConnect: @escaping ()->()) {
		self.spec = spec
		self.attemptConnect = attemptConnect
	}
	
	func start() {
		self.attemptConnect()
		retryConnect(attempt: 0)
	}

	private func retryConnect(attempt: Int) {
		if attempt < spec.retryCount {
			DispatchQueue.main.asyncAfter(deadline: .now() +  spec.retryTimeInterval) { [weak self] in
				self?.nextAttempt(attempt: attempt)
			}
		}
		else {
			if spec.resuscitateTimeInterval > 0.0 {
				DispatchQueue.main.asyncAfter(deadline: .now() +  spec.resuscitateTimeInterval) { [weak self] in
					self?.nextAttempt(attempt: 0)
				}
			}
		}
	}
	
	private func nextAttempt(attempt: Int) {
		if connected == false {
			self.attemptConnect()
			self.retryConnect(attempt: attempt + 1)
		}
	}
}
