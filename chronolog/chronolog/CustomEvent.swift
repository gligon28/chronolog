//
//  CustomEvent.swift
//  chronolog
//
//  Created by Janie Giron on 10/12/24.
//

import Foundation

struct CustomEvent {
    var title: String
    var date: Date?
    var startTime: Date?
    var endTime: Date?
    var duration: Int
    var description: [String]
    var isRecurring: Bool
    var daysOfWeek: [String: Bool]?
    var isAllDay: Bool
}
