//
//  CustomEvent.swift
//  chronolog
//
//  Created by Janie Giron on 10/12/24.
//

import Foundation

struct CustomEvent {
    enum Priority: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
    
    var title: String
    var date: Date?
    var startTime: Date?
    var endTime: Date?
    var duration: Int
    var description: [String]
    var isRecurring: Bool
    var daysOfWeek: [String: Bool]?
    var isAllDay: Bool
    var allowSplit: Bool
    var allowOverlap: Bool
    var priority: Priority
    
}

// Add an extension for JSON encoding/decoding
extension CustomEvent: Codable {
    enum CodingKeys: String, CodingKey {
        case title
        case date
        case startTime
        case endTime
        case duration
        case description
        case isRecurring
        case daysOfWeek
        case isAllDay
        case allowSplit = "isSplitable"
        case allowOverlap
        case priority
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(duration, forKey: .duration)
        try container.encode(description, forKey: .description)
        try container.encode(isRecurring, forKey: .isRecurring)
        try container.encodeIfPresent(daysOfWeek, forKey: .daysOfWeek)
        try container.encode(isAllDay, forKey: .isAllDay)
        try container.encode(allowSplit, forKey: .allowSplit)
        try container.encode(allowOverlap, forKey: .allowOverlap)
        try container.encode(priority.rawValue, forKey: .priority)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try container.decode(String.self, forKey: .title)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        duration = try container.decode(Int.self, forKey: .duration)
        description = try container.decode([String].self, forKey: .description)
        isRecurring = try container.decode(Bool.self, forKey: .isRecurring)
        daysOfWeek = try container.decodeIfPresent([String: Bool].self, forKey: .daysOfWeek)
        isAllDay = try container.decode(Bool.self, forKey: .isAllDay)
        allowSplit = try container.decode(Bool.self, forKey: .allowSplit)
        allowOverlap = try container.decode(Bool.self, forKey: .allowOverlap)
        
        let priorityString = try container.decode(String.self, forKey: .priority)
        priority = Priority(rawValue: priorityString) ?? .low
    }
}
