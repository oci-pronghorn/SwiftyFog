//
//  MQTTRetryConnection.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/15/17.
//

import Foundation

class MQTTRetryConnection {
	private let spec: MQTTReconnectParams
	private let makeConnection: (Int, Int)->()
	
	var connected: Bool = false {
		didSet {
			if oldValue == true && connected == false {
				// If disconnected abruptly start not immediately
				retryConnect(resusc: 0, attempt: 1)
			}
		}
	}
	
	init(spec: MQTTReconnectParams, makeConnection: @escaping (Int, Int)->()) {
		self.spec = spec
		self.makeConnection = makeConnection
	}
	
	func start() {
		attemptConnection(resusc: 0, attempt: 1)
	}
	
	private func attemptConnection(resusc: Int, attempt: Int) {
		if connected == false {
			self.makeConnection(resusc, attempt)
			self.retryConnect(resusc: resusc, attempt: attempt + 1)
		}
	}

	private func retryConnect(resusc: Int, attempt: Int) {
		if attempt <= spec.attemptCount {
			DispatchQueue.main.asyncAfter(deadline: .now() +  spec.retryTimeInterval) { [weak self] in
				self?.attemptConnection(resusc: resusc, attempt: attempt)
			}
		}
		else {
			if spec.resuscitateTimeInterval > 0.0 {
				DispatchQueue.main.asyncAfter(deadline: .now() +  spec.resuscitateTimeInterval) { [weak self] in
					self?.attemptConnection(resusc: resusc + 1, attempt: 1)
				}
			}
		}
	}
}
