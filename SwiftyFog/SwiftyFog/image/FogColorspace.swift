//
//  FogColorspace.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/8/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public enum FogColorSpace: UInt32 {
	case gray = 0
	case rgb = 1
	case rgba = 2
	
	public var componentCount: UInt32 {
		switch self {
			case .gray:
				return 1
			case .rgb:
				return 3
			case .rgba:
				return 4
		}
	}
}
