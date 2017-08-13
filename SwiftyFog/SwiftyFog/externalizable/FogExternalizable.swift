//
//  FogExternalizable.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public protocol FogWritingExternalizable {
	func writeTo(data: inout Data)
}

public protocol FogExternalizable: FogWritingExternalizable {
	init(data: Data, cursor: inout Int)
}
