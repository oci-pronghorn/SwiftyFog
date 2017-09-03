//
//  FogStreamReadable.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public typealias StreamReader = (_ buffer: UnsafeMutablePointer<UInt8>, _ len: Int) -> Int

public protocol FogStreamReadable {
    init?(len: Int, from read: StreamReader)
}

extension Data: FogStreamReadable {
    public init?(len: Int, from read: StreamReader) {
        self.init(count: len)
        if self.read(from: read) == false {
            return nil
        }
    }
	
    private mutating func read(from read: StreamReader) -> Bool {
        let totalLength = self.count
        if totalLength == 0 {
			return true
        }
        var readLength: Int = 0
        self.withUnsafeBytes { (buffer: UnsafePointer<UInt8>) in
            repeat {
                let b = UnsafeMutablePointer(mutating: buffer) + readLength
                let bytesRead = read(b, totalLength - readLength)
                if bytesRead < 0 {
                    break
                }
                readLength += bytesRead
            } while readLength < totalLength
        }
        return readLength == totalLength
    }
}
