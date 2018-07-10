//
//  MotionFaults.swift
//  TrainControl
//
//  Created by David Giovannini on 1/18/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import SwiftyFog_iOS
#elseif os(watchOS)
import SwiftFog_watch
#endif

public struct MotionFaults: FogExternalizable, Equatable {
    public var derailed: Bool
    public var tipped: Bool
    public var lifted: Bool
    public var falling: Bool
    
    public var hasFault: Bool {
        return derailed || tipped || lifted || falling
    }
	
    public init(withFault: Bool) {
        self.derailed = withFault
        self.tipped = false
        self.lifted = false
        self.falling = false
    }
    
    public init() {
        self.derailed = false
        self.tipped = false
        self.lifted = false
        self.falling = false
    }
    
    public init?(data: Data, cursor: inout Int) {
        self.derailed = data.fogExtract(&cursor)
        self.tipped = data.fogExtract(&cursor)
        self.lifted = data.fogExtract(&cursor)
        self.falling = data.fogExtract(&cursor)
    }
    
    public func writeTo(data: inout Data) {
        data.fogAppend(derailed)
        data.fogAppend(tipped)
        data.fogAppend(lifted)
        data.fogAppend(falling)
    }
    
    public static func ==(lhs: MotionFaults, rhs: MotionFaults) -> Bool {
        return lhs.derailed == rhs.derailed && lhs.tipped == rhs.tipped && lhs.lifted == rhs.lifted && lhs.falling == rhs.falling
    }
}
