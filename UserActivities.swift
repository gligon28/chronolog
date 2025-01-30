import Foundation

enum InputType {
    case text
    case multipleSelection(options: [String])
}

struct Activity {
    var name: String
    var isSelected: Bool
}
