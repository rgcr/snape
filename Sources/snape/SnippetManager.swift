import Foundation

struct SnippetGroup {
    let name: String           // Original folder name (e.g., "01-work")
    let displayName: String    // Display name (e.g., "work")
    var snippets: [Snippet]
}

class SnippetManager: ObservableObject {
    @Published var snippets: [Snippet] = []
    @Published var items: [SnippetItem] = []
    
    let snippetsDirectory: URL
    let verbose: Bool
    
    init(verbose: Bool = false) {
        self.verbose = verbose
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.snippetsDirectory = homeDir.appendingPathComponent(".config/snape")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: snippetsDirectory, withIntermediateDirectories: true)
    }
    
    func loadSnippets() {
        let fileManager = FileManager.default
        
        var ungroupedSnippets: [Snippet] = []
        var groups: [SnippetGroup] = []
        
        // Get contents of snippets directory
        guard let contents = try? fileManager.contentsOfDirectory(at: snippetsDirectory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            if verbose {
                print("Failed to read snippets directory")
            }
            return
        }
        
        for itemURL in contents {
            let resourceValues = try? itemURL.resourceValues(forKeys: [.isDirectoryKey])
            let isDirectory = resourceValues?.isDirectory ?? false
            
            if isDirectory {
                // Load snippets from folder
                let folderName = itemURL.lastPathComponent
                let displayName = stripNumericPrefix(folderName)
                var folderSnippets: [Snippet] = []
                
                if let folderContents = try? fileManager.contentsOfDirectory(at: itemURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                    for fileURL in folderContents {
                        if let snippet = loadSnippet(from: fileURL, group: displayName) {
                            folderSnippets.append(snippet)
                        }
                    }
                }
                
                // Sort snippets within group
                folderSnippets.sort { $0.name.lowercased() < $1.name.lowercased() }
                
                if !folderSnippets.isEmpty {
                    groups.append(SnippetGroup(name: folderName, displayName: displayName, snippets: folderSnippets))
                }
            } else {
                // Load ungrouped snippet
                if let snippet = loadSnippet(from: itemURL, group: nil) {
                    ungroupedSnippets.append(snippet)
                }
            }
        }
        
        // Sort ungrouped snippets
        ungroupedSnippets.sort { $0.name.lowercased() < $1.name.lowercased() }
        
        // Sort groups by folder name (preserves numeric prefix ordering)
        groups.sort { $0.name.lowercased() < $1.name.lowercased() }
        
        // Resolve duplicate names
        var allSnippets = ungroupedSnippets
        for group in groups {
            allSnippets.append(contentsOf: group.snippets)
        }
        resolveDuplicateNames(&allSnippets)
        
        // Build items list with separators
        var resultItems: [SnippetItem] = []
        var snippetIndex = 0
        
        // Add ungrouped snippets first
        for _ in 0..<ungroupedSnippets.count {
            resultItems.append(.snippet(allSnippets[snippetIndex]))
            snippetIndex += 1
        }
        
        // Add grouped snippets with separators
        for group in groups {
            resultItems.append(.separator(group.displayName))
            for _ in group.snippets {
                resultItems.append(.snippet(allSnippets[snippetIndex]))
                snippetIndex += 1
            }
        }
        
        // Create sample snippets if none exist
        if resultItems.isEmpty {
            createSampleSnippets()
            loadSnippets()
            return
        }
        
        self.items = resultItems
        self.snippets = allSnippets
    }
    
    private func loadSnippet(from fileURL: URL, group: String?) -> Snippet? {
        let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
        guard resourceValues?.isRegularFile == true else { return nil }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            
            if verbose {
                print("Loaded snippet: \(fileName)" + (group != nil ? " (group: \(group!))" : ""))
            }
            
            return Snippet(name: fileName, content: content, path: fileURL, group: group)
        } catch {
            if verbose {
                print("Failed to load \(fileURL.lastPathComponent): \(error)")
            }
            return nil
        }
    }
    
    private func stripNumericPrefix(_ name: String) -> String {
        // Match pattern like "01-", "02-", "99-" at the start
        let pattern = #"^\d+-"#
        if let range = name.range(of: pattern, options: .regularExpression) {
            return String(name[range.upperBound...])
        }
        return name
    }
    
    private func resolveDuplicateNames(_ snippets: inout [Snippet]) {
        var nameCount: [String: Int] = [:]
        
        for snippet in snippets {
            nameCount[snippet.name, default: 0] += 1
        }
        
        for i in snippets.indices {
            if nameCount[snippets[i].name, default: 0] > 1 {
                let ext = snippets[i].path.pathExtension
                snippets[i].displayName = "\(snippets[i].name).\(ext)"
            }
        }
    }
    
    func createSampleSnippets() {
        let samples: [(String, String)] = [
            ("hello.txt", "Hello, World!"),
            ("greeting.txt", "Hi there!\n\nHope you're having a great day!"),
            ("hello-world.go", "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"Hello, World!\")\n}")
        ]
        
        for (filename, content) in samples {
            let fileURL = snippetsDirectory.appendingPathComponent(filename)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                try? content.write(to: fileURL, atomically: true, encoding: .utf8)
                if verbose {
                    print("Created sample snippet: \(filename)")
                }
            }
        }
    }
    
    func getIndexChar(for index: Int) -> Character {
        if index < 26 {
            return Character(UnicodeScalar(Int(Character("a").asciiValue!) + index)!)
        } else if index < 52 {
            return Character(UnicodeScalar(Int(Character("A").asciiValue!) + (index - 26))!)
        }
        // For more than 52 items, cycle back to 'a'
        return Character(UnicodeScalar(Int(Character("a").asciiValue!) + (index % 26))!)
    }
    
    func indexForChar(_ char: Character) -> Int? {
        if char >= "a" && char <= "z" {
            return Int(char.asciiValue! - Character("a").asciiValue!)
        } else if char >= "A" && char <= "Z" {
            return 26 + Int(char.asciiValue! - Character("A").asciiValue!)
        }
        return nil
    }
    
    // Get only actual snippets (no separators) for filtering/selection
    func getSnippetsOnly() -> [Snippet] {
        return items.compactMap { item in
            if case .snippet(let snippet) = item {
                return snippet
            }
            return nil
        }
    }
}
