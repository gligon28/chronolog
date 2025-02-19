//
//  AIConflictResolver.swift
//  chronolog
//
//  Created by Janie Giron on 12/3/24.
//

import Foundation

struct Config {
    static var openAIToken: String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) else { return nil }
        return dict["OpenAIAPIKey"] as? String
    }
}

// MARK: - OpenAI Response Structures
struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

// MARK: - Schedule Optimizer
class ScheduleOptimizer {
    private let openAIClient: OpenAIClient
    
    init(openAIClient: OpenAIClient) {
        self.openAIClient = openAIClient
    }
    
    func resolveConflicts(existingEvents: [CustomEvent], newEvent: CustomEvent) async throws -> [[CustomEvent]] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let existingEventsData = try encoder.encode(existingEvents)
        let newEventData = try encoder.encode(newEvent)
        
        guard let existingEventsString = String(data: existingEventsData, encoding: .utf8),
              let newEventString = String(data: newEventData, encoding: .utf8) else {
            throw ScheduleError.encodingError
        }
        
        let response = try await openAIClient.getCompletion(
            existingEvents: existingEventsString,
            newEvent: newEventString
        )
        
        print("\nRaw response from model:")
        print(response)
        
        // Extract JSON from response content
        guard let jsonData = response.data(using: .utf8) else {
            throw ScheduleError.decodingError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: jsonData)
            // Assume openAIResponse is already decoded into your OpenAIResponse struct.
            guard let content = openAIResponse.choices.first?.message.content else {
                throw ScheduleError.decodingError
            }

            // Extract all JSON blocks.
            let jsonBlocks = extractAllJSONBlocks(from: content)
            if jsonBlocks.isEmpty {
                print("No JSON block found in response: \(content)")
                throw ScheduleError.decodingError
            }

            var candidateSolutions: [[CustomEvent]] = []
            for block in jsonBlocks {
                if let data = block.data(using: .utf8) {
                    do {
                        let candidate = try decoder.decode([CustomEvent].self, from: data)
                        candidateSolutions.append(candidate)
                    } catch {
                        print("Decoding error for a candidate block: \(error)")
                        // You may choose to continue or throw an error.
                    }
                }
            }

            if candidateSolutions.isEmpty {
                throw ScheduleError.decodingError
            }

            // At this point, candidateSolutions is an array where each element is an array of CustomEvent
            // (each candidate solution from the model).
            return candidateSolutions
        }
    }
}

func extractAllJSONBlocks(from content: String) -> [String] {
    var jsonBlocks = [String]()
    // Split the content by the code fence delimiter.
    let parts = content.components(separatedBy: "```")
    for part in parts {
        // Trim whitespace and newlines.
        var trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
        // If the trimmed part starts with "json" (case-sensitive), remove it.
        if trimmed.lowercased().hasPrefix("json") {
            trimmed = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // If the trimmed part now starts with "[" and ends with "]", assume it’s a valid JSON array.
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            jsonBlocks.append(trimmed)
        }
    }
    return jsonBlocks
}


// MARK: - OpenAI Client Protocol and Implementation
protocol OpenAIClient {
    func getCompletion(existingEvents: String, newEvent: String) async throws -> String
}

class OpenAIAPIClient: OpenAIClient {
    private let apiKey: String?
    
    init(apiKey: String?) {
        self.apiKey = apiKey
    }
    
    func getCompletion(existingEvents: String, newEvent: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = """
            You are an expert event scheduler. Given the events above. Return ONLY a JSON array containing all events after resolving conflicts. Give three distinct solutions.
                        Follow these rules in order of importance:
                        1. Schedule events as early as possible while respecting:
                            - Event priorities (Higher priority events take precedence)
                            - All event deadlines must be met
                            - Existing recurring event patterns must be maintained
                        2. Handle conflicts according to these rules:
                            - Only events with allowOverlap=true can overlap
                            - Events marked as splitable can be broken into smaller segments if needed
                                
                        Important: Always try to schedule new events at the earliest possible time slot that satisfies all constraints.
                        Return ONLY valid JSON array with the optimized schedule.
            """
                
            let userPrompt = """
            Existing events: \(existingEvents)
            New event to add: \(newEvent)
            Return a single JSON array containing ALL events with conflicts resolved.
            """
                
            let messages: [[String: Any]] = [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ]
                
            let payload: [String: Any] = [
                "model": "gpt-4o",
                "messages": messages,
                "temperature": 0.3,
                "max_tokens": 5428
            ]
        
        // Debug printing of the full prompt
            print("\n=== FULL PROMPT TO GPT-4o ===")
            print("\nSystem Message:")
            print(systemPrompt)
            print("\nUser Message:")
            print(userPrompt)
            print("\nFull Payload:")
            if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
                let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
            print("\n$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw ScheduleError.decodingError
        }
        
        return responseString
    }
}

// MARK: - Error Handling
enum ScheduleError: Error {
    case encodingError
    case decodingError
    case openAIError
}

/* AI CONFLICT RESOLVER USAGE EX.
 
 class ViewController: UIViewController {
     
     @IBAction func apiCallButton(_ sender: UIButton) {
         // test events
         let event1 = CustomEvent(
             title: "Team Meeting",
             date: Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date()),
             startTime: Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date()),
             endTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()),
             duration: 60,
             description: ["Discuss project updates", "Assign new tasks"],
             isRecurring: true,
             daysOfWeek: ["Monday": true, "Wednesday": true, "Friday": true],
             isAllDay: false,
             allowSplit: false,
             deadline: nil,
             priority: "High",
             allowOverlap: false
         )
         
         let event2 = CustomEvent(
             title: "Lunch Break",
             date: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()),
             startTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()),
             endTime: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date()),
             duration: 60,
             description: ["Take a break for lunch"],
             isRecurring: false,
             daysOfWeek: nil,
             isAllDay: false,
             allowSplit: true,
             deadline: nil,
             priority: "Low",
             allowOverlap: true
         )
         
         let event3 = CustomEvent(
             title: "Yoga Class",
             date: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()),
             startTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()),
             endTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()),
             duration: 60,
             description: ["Evening relaxation session"],
             isRecurring: true,
             daysOfWeek: ["Tuesday": true, "Thursday": true],
             isAllDay: false,
             allowSplit: false,
             deadline: nil,
             priority: "Low",
             allowOverlap: false
         )
         
         var component = DateComponents()
         component.year = 2024
         component.month = 12
         component.day = 7
         component.hour = 16
         component.minute = 30
         
         let deadline = Calendar.current.date(from: component)
         
         let event4 = CustomEvent(
             title: "Work on homework",
             date: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date()),
             startTime: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date()),
             endTime: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()),
             duration: 120,
             description: ["finish homework"],
             isRecurring: false,
             daysOfWeek: nil,
             isAllDay: false,
             allowSplit: true,
             deadline: deadline,
             priority: "Low",
             allowOverlap: false
         )
         
         var components = DateComponents()
         components.year = 2024
         components.month = 12
         components.day = 2
         components.hour = 16
         components.minute = 30
         
         let specificDate = Calendar.current.date(from: components)
         
         let newEvent = CustomEvent(
             title: "Emergency meeting",
             date: nil,
             startTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()),
             endTime: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()),
             duration: 60,
             description: ["be there"],
             isRecurring: false,
             daysOfWeek: nil,
             isAllDay: false,
             allowSplit: false,
             deadline: specificDate,
             priority: "High", //high
             allowOverlap: false
         )
         
         let existingEvents = [event1, event2, event3, event4]
         
         let openAIClient = OpenAIAPIClient(apiKey: Config.openAIToken)
         let optimizer = ScheduleOptimizer(openAIClient: openAIClient)
         
         Task {
             do {
                 let optimizedSchedule = try await optimizer.resolveConflicts(
                     existingEvents: existingEvents,
                     newEvent: newEvent
                 )
                 
                 await MainActor.run {
                     printScheduleInCST(optimizedSchedule)
                 }
             } catch {
                 await MainActor.run {
                     print("Error optimizing schedule:", error)
                 }
             }
         }
     }
 }
 
 // prints out events in CST
 extension ViewController {
     func printScheduleInCST(_ events: [CustomEvent]) {
         let formatter = DateFormatter()
         formatter.timeZone = TimeZone(identifier: "America/Chicago")  // CST timezone
         formatter.dateFormat = "MMM d, yyyy h:mm a zzz"
         
         print("\nOptimized schedule in CST:")
         events.forEach { event in
             print("Event: \(event.title)")
             if let start = event.startTime {
                 print("Start Time: \(formatter.string(from: start))")
             } else {
                 print("Start Time: Not set")
             }
             
             if let end = event.endTime {
                 print("End Time: \(formatter.string(from: end))")
             } else {
                 print("End Time: Not set")
             }
             print("---")
         }
     }
 }
 
 
 
 */
