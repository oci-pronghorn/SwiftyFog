//
//  MQTTStreamWritable.swift
//  SwiftFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

typealias StreamWriter = (_ buffer: UnsafePointer<UInt8>, _ len: Int) -> Int

protocol MQTTStreamWritable {
    func write(to write: StreamWriter) -> Bool
}

extension Data : MQTTStreamWritable {
    func write(to write: StreamWriter) -> Bool {
        let totalLength = self.count
        guard totalLength <= 128*128*128 else { return false }
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
