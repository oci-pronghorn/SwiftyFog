//
//  SubscriptionLogging.swift
//  TrainControl
//
//  Created by David Giovannini on 7/20/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import SwiftyFog_iOS
#elseif os(watchOS)
import SwiftFog_watch
#endif

public protocol SubscriptionLogging {
	func onSubscriptionAck(status: MQTTSubscriptionStatus)
}
