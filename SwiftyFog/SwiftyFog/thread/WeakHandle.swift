//
//  MQTTClient.swift
//  SwiftyFog
//
//  Created by David Giovannini on 8/12/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import Foundation

/**
 *	An WeakHandle is a value type that stores a single
 *	weak pointer to a class-type instance.
 *
 *	Collections can use this when the collection needs not
 *	to have a strong reference to  what it contains. It 
 *	cannot be `unowned` due to a race condition on deinit 
 *	and collection operations.
 *
 *	An instance can be used as a dictionary key. Use init(key) 
 *	convenience init for searches.
 */

public struct WeakHandle<T>: Hashable {
	public typealias Element = T
	private weak var obj : AnyObject! // Currently in Swift we have to erase the type
	private let identifier : ObjectIdentifier
	
	public init(object: Element) {
		self.obj = object as AnyObject
		self.identifier = ObjectIdentifier(self.obj)
	}
	
	public init(key: Element) {
		self.identifier = ObjectIdentifier(key as AnyObject)
	}
	
	public var hashValue: Int {
		return identifier.hashValue
	}

    public static func == <T> (lhs: WeakHandle<T>, rhs: WeakHandle<T>) -> Bool {
        return UInt(bitPattern: lhs.identifier) == UInt(bitPattern: rhs.identifier)
    }
    
    public var value: T? {
        return self.obj as? T
    }
}


