import Foundation

enum SnippetItem: Identifiable, Hashable {
    case snippet(Snippet)
    case separator(String)
    
    var id: String {
        switch self {
        case .snippet(let snippet):
            return snippet.id.uuidString
        case .separator(let name):
            return "separator-\(name)"
        }
    }
}

struct Snippet: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var displayName: String
    let content: String
    let path: URL
    let group: String?  // nil for ungrouped
    
    init(name: String, content: String, path: URL, group: String? = nil) {
        self.name = name
        self.displayName = name
        self.content = content
        self.path = path
        self.group = group
    }
}
