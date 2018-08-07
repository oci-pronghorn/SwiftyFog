//
//  Billboard.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit
#if os(iOS)
import SwiftyFog_iOS
#elseif os(watchOS)
import SwiftFog_watch
#endif

public protocol BillboardDelegate: class, SubscriptionLogging {
    func billboard(text: String, _ asserted: Bool)
}

public class Billboard: FogFeedbackModel {
    private var broadcaster: MQTTBroadcaster?
    private var text: FogFeedbackValue<String>
	
	public weak var delegate: BillboardDelegate?
	
    public var mqtt: MQTTBridge? {
		didSet {
			broadcaster.assign(mqtt?.broadcast(to: self, queue: DispatchQueue.main, topics: [
                ("text/feedback", .atMostOnce, Billboard.feedbackText)
			]) {[weak self] (_, status) in self?.delegate?.onSubscriptionAck(status: status)})
		}
    }
	
	public init() {
        self.text = FogFeedbackValue("")
	}
	
	public var hasFeedback: Bool {
		return /*bitmap != nil &&*/ text.hasFeedback
	}
	
	public func reset() {
        text.reset()
	}
	
	public func assertValues() {
        delegate?.billboard(text: text.value, true)
	}
    
    public func control(text: String) {
        var payload = Data();
        payload.fogAppend(text);
        mqtt?.publish(MQTTMessage(topic: "text/control", payload: payload))
    }
    
    private func feedbackText(msg: MQTTMessage) {
        self.text.receive(msg.payload.fogExtract()) { value, asserted in
            delegate?.billboard(text: value.trimmingCharacters(in: .whitespacesAndNewlines), asserted)
        }
    }
}
