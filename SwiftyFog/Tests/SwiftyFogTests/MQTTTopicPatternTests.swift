//
//  MQTTTopicPatternTests.swift
//  SwiftyFog_iOSTests
//
//  Created by David Giovannini on 8/3/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import XCTest
@testable import SwiftyFog_iOS

class MQTTTopicPatternTests: XCTestCase {

    func testInvalidEmpty() {
		let t = MQTTTopicPattern(path: "")
		XCTAssertFalse(t.isValid)
		XCTAssertEqual(MQTTTopicPattern.MatchResult.invalid, t.matches(full: ""))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.invalid, t.matches(full: "test"))
    }

    func testBasic() {
		let t = MQTTTopicPattern(path: "the")
		XCTAssertTrue(t.isValid)
		XCTAssertEqual(MQTTTopicPattern.MatchResult.invalid, t.matches(full: ""))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.segmentMismatch, t.matches(full: "the/train"))
    }

    func testMany() {
		let t = MQTTTopicPattern(path: "the/train/arrived")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the/train/arrived"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.segmentMismatch, t.matches(full: "the/train"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.segmentMismatch, t.matches(full: "the"))
    }

    func testEmptyTopic() {
		var t = MQTTTopicPattern(path: "/")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "/"))
		t = MQTTTopicPattern(path: "the/")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the/"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.segmentMismatch, t.matches(full: "the"))
		t = MQTTTopicPattern(path: "the//train")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the//train"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.segmentMismatch, t.matches(full: "the/train"))
    }
	
    func testInvalidTrailingWild() {
		var t = MQTTTopicPattern(path: "the/train#")
		XCTAssertFalse(t.isValid)
		t = MQTTTopicPattern(path: "the/#/train")
		XCTAssertFalse(t.isValid)
		t = MQTTTopicPattern(path: "the#/train")
		XCTAssertFalse(t.isValid)
		t = MQTTTopicPattern(path: "#the/train")
		XCTAssertFalse(t.isValid)
		t = MQTTTopicPattern(path: "##")
		XCTAssertFalse(t.isValid)
    }
	
    func testTrailingWild() {
		var t = MQTTTopicPattern(path: "#")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "/"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the/train"))
		t = MQTTTopicPattern(path: "the/train/#")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the/train"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the/train/arrived"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.segmentMismatch, t.matches(full: "the/train2/arrived"))
    }
	
    func testLevelWildInvalid() {
		var t = MQTTTopicPattern(path: "the/train/+#")
		XCTAssertFalse(t.isValid)
		t = MQTTTopicPattern(path: "the/train+")
		XCTAssertFalse(t.isValid)
		t = MQTTTopicPattern(path: "the+/train")
		XCTAssertFalse(t.isValid)
		t = MQTTTopicPattern(path: "the/+train")
		XCTAssertFalse(t.isValid)
		t = MQTTTopicPattern(path: "+the/train")
		XCTAssertFalse(t.isValid)
		t = MQTTTopicPattern(path: "++")
		XCTAssertFalse(t.isValid)
    }
	
    func testLevelWildSingular() {
		let t = MQTTTopicPattern(path: "+")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "/"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.tooManySegments, t.matches(full: "/the"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.tooManySegments, t.matches(full: "the/"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.tooManySegments, t.matches(full: "the/train"))
    }
	
    func testLevelWildWithMore() {
		var t = MQTTTopicPattern(path: "+/")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the/"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.tooFewSegments, t.matches(full: "the"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.segmentMismatch, t.matches(full: "the/train"))
		t = MQTTTopicPattern(path: "+//arrived")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the//arrived"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.segmentMismatch, t.matches(full: "the/train/arrived"))
    }
	
    func testLevelWildInside() {
		let t = MQTTTopicPattern(path: "the/+/arrived")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the/train/arrived"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the//arrived"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.tooFewSegments, t.matches(full: "the/"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.segmentMismatch, t.matches(full: "the//"))
	}
	
    func testLevelWildEnd() {
		var t = MQTTTopicPattern(path: "+/+")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "/the"))
		t = MQTTTopicPattern(path: "the/+")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the/train"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the/"))
		t = MQTTTopicPattern(path: "/+")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "/the"))
    }
	
    func testLevelAndTrailingWid() {
		let t = MQTTTopicPattern(path: "+/train/#")
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "/train"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the/train/arrived/today"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.success, t.matches(full: "the/train/"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.segmentMismatch, t.matches(full: "/trai"))
		XCTAssertEqual(MQTTTopicPattern.MatchResult.segmentMismatch, t.matches(full: "/train2"))
    }
}
