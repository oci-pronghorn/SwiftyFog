//
//  FogExternalizable.swift
//  TrainControl
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public protocol FogExternalizable {
	init(data: Data, cursor: inout Int)
	func writeTo(data: inout Data)
}
