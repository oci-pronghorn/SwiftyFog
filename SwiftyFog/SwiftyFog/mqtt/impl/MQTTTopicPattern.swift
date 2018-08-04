//
//  MQTTTopicPattern.swift
//  SwiftyFog_iOS
//
//  Created by David Giovannini on 8/3/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import Foundation

enum MQTTTopicPattern {
	case invalid(String)
	case fixed(String)
	case trailing(String, String)
	case topicLevel(String, [(String.Index, Bool)])
	case topicLevelAndTrailing(String, String, [(String.Index, Bool)])
	
	init(path: String) {
		// If enpty
		if path.isEmpty {
			self = .invalid(path)
			return
		}
		var hasWildTrailing = false
		var hasWildLevel = false
		var indices = [(String.Index, Bool)]()
		var simple = path
		var start = path.startIndex
		var end = path.index(before: path.endIndex)
		if let index = path.firstIndex(of: "#") {
			hasWildTrailing = true
			// If not at end or not preceded by '/'
			if index != end || (index != start && path[path.index(before: index)] != "/") {
				self = .invalid(path)
				return
			}
			if index != path.startIndex {
				simple = String(path.prefix(upTo: path.index(before:index)))
			}
			else {
				simple = ""
			}
		}
		if simple.isEmpty == false {
			start = simple.startIndex
			end = simple.index(before: simple.endIndex)
			var needFirstTopic = true
			for index in simple.indices {
				if simple[index] == "+" {
					// If not start and is not prefexed by a '/'
					if index != start && simple[simple.index(before: index)] != "/" {
						self = .invalid(path)
						return
					}
					// If not end and is not suffixed by a '/'
					if index != end && simple[simple.index(after: index)] != "/" {
						self = .invalid(path)
						return
					}
					hasWildLevel = true
					if needFirstTopic {
						needFirstTopic = false
						indices.append((index, true))
					}
					else {
						if indices.count == 1 { // first index is an empty segment
							indices.append((index, true))
						}
						else {
							indices[indices.count-1].1 = true
						}
					}
				}
				else if simple[index] == "/" {
					needFirstTopic = false
					indices.append((simple.index(after: index), false))
				}
				else if needFirstTopic {
					needFirstTopic = false
					indices.append((index, false))
				}
			}
		}
		indices.append((simple.endIndex, false)) // TODO: try to remove. Everything works now but try to remove
		
		if hasWildTrailing  {
			if hasWildLevel {
				self = .topicLevelAndTrailing(path, simple, indices)
			}
			else {
				self = .trailing(path, simple)
			}
		}
		else if hasWildLevel {
			self = .topicLevel(path, indices)
		}
		else {
			self = .fixed(path)
		}
	}
	
	var isValid: Bool {
		switch self {
		case .invalid(_):
			return false
		default:
			return true
		}
	}
	
	enum MatchResult {
		case success
		case invalid
		case segmentMismatch
		case tooFewSegments
		case tooManySegments
	}
	
	func matches(full topic: String) -> MatchResult {
		if topic.isEmpty {
			return .invalid
		}
		switch self {
		case .invalid(_):
			return .invalid
		case .fixed(let path):
			return parseFixed(topic, path)
		case .trailing( _, let simple):
			return parseWildTrailing(topic, simple)
		case .topicLevel(let path, let indices):
			return parseWildLevels(topic, path, indices)
		case .topicLevelAndTrailing(_, let simple, let indices):
			return parseTotallyWild(topic, simple, indices)
		}
	}
	
	private func parseFixed(_ topic: String, _ path: String) -> MatchResult {
		return topic == path ? .success : .segmentMismatch
	}
	
	private func parseWildTrailing(_ topic: String, _ path: String) -> MatchResult {
		if (path.isEmpty) {
			return .success
		}
		if topic.hasPrefix(path) {
			let prefexEnd = path.endIndex
			if prefexEnd == topic.endIndex || topic[prefexEnd] == "/" {
				return .success
			}
		}
		return .segmentMismatch
	}
	
	private func parseTotallyWild(_ topic: String, _ path: String, _ indices: [(String.Index, Bool)]) -> MatchResult {
		let r = parseWildLevels(topic, path, indices)
		if r == .tooManySegments {
			return .success
		}
		return r
	}
	
	private func parseWildLevels(_ topic: String, _ path: String, _ indices: [(String.Index, Bool)])  -> MatchResult {
		var segmentNumber = 0
		let endTopicIndex = topic.endIndex
		let notSingularCharTopic = topic.count != 1
		let expectedSegmentCount = indices.count - 1
		let endPathIndex = path.endIndex
		var lowerTopicIndex = topic.startIndex
		var upperTopicIndex = topic.startIndex
	
		while true {
			var verifySegment = false
			var hasAnotherTopicSegment = false
			if upperTopicIndex == endTopicIndex {
				verifySegment = true
			}
			else if topic[upperTopicIndex] == "/" {
				verifySegment = true
				hasAnotherTopicSegment = notSingularCharTopic
			}
			if verifySegment {
				if segmentNumber >= expectedSegmentCount {
					return .tooManySegments
				}
				let currentWild = indices[segmentNumber]
				if currentWild.1 == false {
					let topicRange = Range(uncheckedBounds: (lower: lowerTopicIndex, upper: upperTopicIndex))
					let nextWild = indices[segmentNumber+1]
					let wildUpperIndex: String.Index
					if segmentNumber == expectedSegmentCount-1 {
						wildUpperIndex = endPathIndex
					}
					else if nextWild.0 == currentWild.0 {
						wildUpperIndex = nextWild.0
					}
					else {
						wildUpperIndex = path.index(before: nextWild.0)
					}
					let wildRange = Range(uncheckedBounds: (lower: currentWild.0, upper: wildUpperIndex))
					let segment = path[wildRange]
					let r = topic.compare(segment, options: String.CompareOptions(), range: topicRange, locale: nil)
					if r != .orderedSame {
						return .segmentMismatch
					}
				}
				if hasAnotherTopicSegment {
					lowerTopicIndex = topic.index(after: upperTopicIndex)
				}
				segmentNumber += 1
			}
			if verifySegment == true && hasAnotherTopicSegment == false {
				return segmentNumber == expectedSegmentCount ? .success : .tooFewSegments
			}
			upperTopicIndex = topic.index(after: upperTopicIndex)
		}
	}
}
