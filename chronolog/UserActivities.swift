import Foundation

enum InputType {
    case text
    case multipleSelection(options: [String])
}

struct Question {
    let text: String
    let inputType: InputType
}

struct Activity {
    let name: String
    var isSelected: Bool
    let questions: [Question]
}
