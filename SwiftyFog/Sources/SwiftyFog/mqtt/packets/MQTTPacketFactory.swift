//
//  MQTTPacketFactory.swift
//  SwiftyFog
//
//  Created by David Giovannini on 5/20/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation // Data

public enum UnmarshalState {
	case failedReadHeader
	case failedReadLength
	case failedReadPayload(Int)
	case unknownPacketType(UInt8)
	case cannotConstruct(MQTTPacketType)
	case success(MQTTPacket)
	
	var isClosedStream: Bool {
		if case .failedReadHeader = self {
			return true
		}
		return false
	}
	
	var isPartialFailure: Bool {
		switch self {
			case .success(_):
				return false
			case .failedReadHeader:
				return false
			case .failedReadLength:
				return true
			case .failedReadPayload:
				return true
			case .cannotConstruct(_):
				return true
			case .unknownPacketType:
				return true
		}
	}
}

// Converts Streams to/From MQTTPackets
public protocol PacketMarshaller {
	func send(_ packet: MQTTPacket, _ writer: FogSocketStreamWrite) -> Bool
	func receive(_ read: StreamReader) -> UnmarshalState
}

public struct MQTTPacketFactory: PacketMarshaller {
    private let constructors: [MQTTPacketType : (MQTTPacketFixedHeader, Data)->MQTTPacket?] = [
        .connAck : MQTTConnAckPacket.init,
        .pingAck : MQTTPingAckPacket.init,
        .publish : MQTTPublishPacket.init,
        .pubAck : MQTTPublishAckPacket.init,
        .pubRec : MQTTPublishRecPacket.init,
        .pubRel : MQTTPublishRelPacket.init,
        .pubComp : MQTTPublishCompPacket.init,
        .subAck : MQTTSubAckPacket.init,
        .unSubAck : MQTTUnsubAckPacket.init,
    ]
	
	private let metrics: MQTTWireMetrics?
	
	public init(metrics: MQTTWireMetrics? = nil) {
		self.metrics = metrics
	}
	
	public func send(_ packet: MQTTPacket, _ writer: FogSocketStreamWrite) -> Bool {
		let data = marshal(packet)
		var success = false
		metrics?.writingPacket()
		writer({ w in
			success = data.write(to: w)
			if success == false {
				metrics?.failedToWitePcket()
			}
		})
		return success
    }
	
    public func receive(_ read: StreamReader) -> UnmarshalState {
		metrics?.receivedMessage()
		let result = unmarshal(read)
		if result.isPartialFailure {
			metrics?.failedToCreatePacket()
		}
		return result
    }
	
    private static let filler = [UInt8](repeating: 0, count: MQTTPacket.fixedHeaderLength + MQTTPackedLength.maxLen)
	
    public func marshal(_ packet: MQTTPacket) -> Data {
		let fcl = MQTTPacketFactory.filler.count
		let fhl = MQTTPacket.fixedHeaderLength
		let fsl = fcl - fhl
		let fbl = fhl + fsl
		let capacity = fbl + packet.estimatedVariableHeaderLength + packet.estimatedPayLoadLength
		var data = Data(capacity: capacity)
		data.append(contentsOf: MQTTPacketFactory.filler)
		packet.appendVariableHeader(&data)
		packet.appendPayload(&data)
		let variableSize = data.count - fbl
		let lengthSize = MQTTPackedLength.bytesRquired(for: variableSize)
		MQTTPackedLength.replace(in: &data, at: fcl - lengthSize, length: variableSize)
		let remainder = fsl - lengthSize
		data[remainder] = packet.header.memento
		data = data.subdata(in: remainder..<data.count)
		if let metrics = metrics, metrics.printWireData {
			let realCapacity = capacity - remainder
			if realCapacity < data.count {
				metrics.debug("Underallocated: \(type(of:packet)) \(data.count) > \(realCapacity)")
			}
			else if realCapacity > data.count {
				metrics.debug("Overallocated: \(type(of:packet)) \(data.count) < \(realCapacity)")
			}
			metrics.debug("Wire -> \(packet.header.packetType) [\(data.count)] \(data.fogHexDescription)")
		}
		return data
    }
	
	// TODO: metrics is treated differently between marshal and unmarshal
	public func unmarshal(_ data: Data) -> UnmarshalState {
		var cursor = 0
		var result = UnmarshalState.failedReadHeader
		data.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
			result = self.receive { ptr, l in
				let pos = u8Ptr.advanced(by: cursor)
				memcpy(ptr, pos, l)
				cursor += l
				return l
			}
		}
		return result
	}

    private func unmarshal(_ read: StreamReader) -> UnmarshalState {
        var headerByte: UInt8 = 0
        let headerReadLen = read(&headerByte, MQTTPacket.fixedHeaderLength)
        if headerReadLen > 0 {
			if let len = MQTTPackedLength.read(from: read) {
				if let data = Data(len: len, from: read) {
					let constructResult: UnmarshalState
					if let header = MQTTPacketFixedHeader(memento: headerByte) {
						if let packet = constructors[header.packetType]?(header, data) {
							constructResult = .success(packet)
						}
						else {
							constructResult = .cannotConstruct(header.packetType)
						}
					}
					else {
						constructResult = .unknownPacketType(headerByte & 0xF0)
					}
					if let metrics = metrics, metrics.printWireData {
						let constructed: String
						switch constructResult {
						case .success(let packet):
							constructed = "\(packet.header.packetType)"
							break
						case .unknownPacketType(let packetTypeByte):
							constructed = "unknown:\(packetTypeByte)"
							break
						case .cannotConstruct(let packetType):
							constructed = "init?(\(packetType))"
							break
						case .failedReadHeader:
							fallthrough
						case .failedReadPayload:
							fallthrough
						case .failedReadLength:
							constructed = "failed"
							break
						}
						let headerStr = String(format: "%02x.", headerByte)
						let lenSize = MQTTPackedLength.bytesRquired(for: len)
						var lenStr = (0..<lenSize).reduce("", { r, _ in return r + "##." })
						lenStr.removeLast()
						let len = data.count
						let fullLen = MQTTPacket.fixedHeaderLength + lenSize + len
						metrics.debug("Wire <- \(constructed) [\(fullLen)]\n\t\(headerStr)\(lenStr) [\(len)]\(data.fogHexDescription)")
					}
					return constructResult
				}
				metrics?.debug("Wire <- Failed to read data of length [\(len)]")
				return .failedReadPayload(len)
			}
			metrics?.debug("Wire <- Invalid length field")
			return .failedReadLength
		}
		metrics?.debug("Wire <- End of stream")
		return .failedReadHeader
	}
}
