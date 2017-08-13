//
//  MQTTPublisher.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

public protocol MQTTPublisherDelegate: class {
	func send(packet: MQTTPacket) -> Bool
}

public class MQTTPublisher {
	private let idSource: MQTTMessageIdSource
	
	// TODO: threadsafety
	// TODO: completion timeouts
	// TODO: we are *permitted* to resend with new message ids until full handshake is done
	//	- make that configurable
	private var unacknowledgedQos1Ack = [UInt16:(MQTTPublishPacket,((Bool)->())?)]()
	private var unacknowledgedQos2Rec = [UInt16:(MQTTPublishPacket,((Bool)->())?)]()
	private var unacknowledgedQos2Comp = [UInt16:(MQTTPublishPacket,((Bool)->())?)]()
	
	public weak var delegate: MQTTPublisherDelegate?
	
	public init(idSource: MQTTMessageIdSource) {
		self.idSource = idSource
	}
	
	public func connected(cleanSession: Bool) {
	/*
	When a Client reconnects with CleanSession set to 0, both the Client and Server MUST re-send any unacknowledged PUBLISH Packets (where QoS > 0) and PUBREL Packets using their original Packet Identifiers [MQTT-4.4.0-1]. This is the only circumstance where a Client or Server is REQUIRED to redeliver messages.
	*/
	/*
	A Client MUST follow these rules when implementing the protocol flows defined elsewhere in this chapter:
When it re-sends any PUBLISH packets, it MUST re-send them in the order in which the original PUBLISH packets were sent (this applies to QoS 1 and QoS 2 messages) [MQTT-4.6.0-1]
It MUST send PUBACK packets in the order in which the corresponding PUBLISH packets were received (QoS 1 messages) [MQTT-4.6.0-2]
It MUST send PUBREC packets in the order in which the corresponding PUBLISH packets were received (QoS 2 messages) [MQTT-4.6.0-3]
It MUST send PUBREL packets in the order in which the corresponding PUBREC packets were received (QoS 2 messages)
*/
	}
	
	public func disconnected(cleanSession: Bool, final: Bool) {
		let unacknowledgedQos1Ack = self.unacknowledgedQos1Ack
		let unacknowledgedQos2Rec = self.unacknowledgedQos2Rec
		let unacknowledgedQos2Comp = self.unacknowledgedQos2Comp
		if cleanSession {
			self.unacknowledgedQos1Ack.keys.forEach(idSource.release)
			self.unacknowledgedQos1Ack.removeAll()
			self.unacknowledgedQos2Rec.keys.forEach(idSource.release)
			self.unacknowledgedQos2Rec.removeAll()
			self.unacknowledgedQos2Comp.keys.forEach(idSource.release)
			self.unacknowledgedQos2Comp.removeAll()
		}
		if cleanSession || final {
			for element in unacknowledgedQos1Ack {
				idSource.release(id: element.0)
				element.1.1?(false)
			}
			for element in unacknowledgedQos2Rec {
				idSource.release(id: element.0)
				element.1.1?(false)
			}
			for element in unacknowledgedQos2Comp {
				idSource.release(id: element.0)
				element.1.1?(false)
			}
		}
	}

	public func publish(topic: String, payload: Data, retain: Bool = false, qos: MQTTQoS = .atMostOnce, completion: ((Bool)->())?) {
		let model = MQTTPubMsg(topic: topic, payload: payload, retain: retain, QoS: qos)
		let messageId = idSource.fetch()
		let packet = MQTTPublishPacket(messageID: messageId, message: model, isRedelivery: false)
		
		if delegate?.send(packet: packet) ?? false == false {
			completion?(false)
		}
		switch qos {
			case .atMostOnce:
				idSource.release(id: messageId)
				completion?(true)
				return
			case .atLeastOnce:
				unacknowledgedQos1Ack[messageId] = (packet, completion)
				return
			case .exactlyOnce:
				unacknowledgedQos2Rec[messageId] = (packet, completion)
				return
		}
	}
	
	public func receive(packet: MQTTPacket) -> Bool {
		switch packet {
			case let packet as MQTTPublishAckPacket: // received for Qos 1
				if let element = unacknowledgedQos1Ack.removeValue(forKey:packet.messageID) {
					idSource.release(id: element.0.messageID)
					element.1?(true)
				}
				return true
			case let packet as MQTTPublishRecPacket: // received for Qos 2.a
				if let element = unacknowledgedQos2Rec.removeValue(forKey:packet.messageID) {
					let rel = MQTTPublishRelPacket(messageID: packet.messageID)
					if let success = delegate?.send(packet: rel), success == true {
						unacknowledgedQos2Comp[packet.messageID] = element
					}
				}
				return true
			case let packet as MQTTPublishCompPacket: // received for Qos 2.b
				if let element = unacknowledgedQos2Comp.removeValue(forKey:packet.messageID) {
					idSource.release(id: element.0.messageID)
					element.1?(true)
				}
				return true
			default:
				return false
		}
	}
}
