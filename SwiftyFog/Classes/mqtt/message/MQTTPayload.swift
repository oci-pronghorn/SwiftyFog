//
//  MQTTPayload.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public enum MQTTPayload: CustomStringConvertible {
    case data(Data)
    // TODO: do large payloads via file
    //case file(FileHandle)
	
    public var stringRep: String? {
        if case .data(let data) = self {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
	
    public var description: String {
        if let str = stringRep {
            return "'\(str)'"
        }
        if case .data(let data) = self {
            return "#\(data.count) \(data.hexDescription)"
        }
        return "##"
    }
}
