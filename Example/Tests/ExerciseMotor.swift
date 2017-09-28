//
//  ExerciseMotor.swift
//  SwiftyFog_Tests
//
//  Created by David Giovannini on 9/27/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest

class ExerciseMotor: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
		//UIApplication.shared.keyWindow?.layer.speed = 0.5
		let enginecontrolElement = XCUIApplication().otherElements["engineControl"]
		
		for _ in 0..<10000 {
			let p1 = enginecontrolElement.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
			let p2 = enginecontrolElement.coordinate(withNormalizedOffset: CGVector(dx: 1.0, dy: 0.5))
			p1.press(forDuration: 0, thenDragTo: p2)
			let p3 = enginecontrolElement.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
			p2.press(forDuration: 0, thenDragTo: p3)
			let p4 = enginecontrolElement.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
			p3.press(forDuration: 0, thenDragTo: p4)
		}
		
		
		//XCUIApplication().otherElements["engineControl"]
		
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
