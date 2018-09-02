//
//  FogStreamWritable.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // Data

public typealias StreamWriter = (_ buffer: UnsafePointer<UInt8>, _ len: Int) -> Int

public protocol FogStreamWritable {
    func write(to write: StreamWriter) -> Bool
}

extension Data : FogStreamWritable {
    public func write(to write: StreamWriter) -> Bool {
        let totalLength = self.count
        var writeLength: Int = 0
        self.withUnsafeBytes { (buffer: UnsafePointer<UInt8>) in
            repeat {
                let b = UnsafeMutablePointer(mutating: buffer) + writeLength
                let byteWritten = write(b, totalLength - writeLength)
                if byteWritten < 0 {
                    break
                }
                writeLength += byteWritten
            } while writeLength < totalLength
        }
        return writeLength == totalLength
    }
}
