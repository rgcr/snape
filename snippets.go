package main

import (
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type Snippet struct {
	Name        string
	DisplayName string
	Content     string
	Path        string
}

type SnippetManager struct {
	snippetsDir string
	snippets    []Snippet
}

func NewSnippetManager() *SnippetManager {
	sm := &SnippetManager{}
	sm.snippetsDir = sm.getSnippetsDirectory()
	return sm
}

func (sm *SnippetManager) getSnippetsDirectory() string {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return ""
	}

	snapeDir := filepath.Join(homeDir, ".snape")
	os.MkdirAll(snapeDir, 0755)
	return snapeDir
}

func (sm *SnippetManager) LoadSnippets() error {
	sm.snippets = []Snippet{}

	if sm.snippetsDir == "" {
		return nil
	}

	err := filepath.WalkDir(sm.snippetsDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if d.IsDir() {
			return nil
		}

		// Skip hidden files (files starting with a dot)
		if strings.HasPrefix(d.Name(), ".") {
			return nil
		}

		content, err := os.ReadFile(path)
		if err != nil {
			return err
		}

		name := strings.TrimSuffix(d.Name(), filepath.Ext(d.Name()))
		snippet := Snippet{
			Name:        name,
			DisplayName: name,
			Content:     string(content),
			Path:        path,
		}

		sm.snippets = append(sm.snippets, snippet)
		return nil
	})

	if err != nil {
		return err
	}

	sort.Slice(sm.snippets, func(i, j int) bool {
		return strings.ToLower(sm.snippets[i].Name) < strings.ToLower(sm.snippets[j].Name)
	})

	sm.resolveDuplicateNames()

	return nil
}

func (sm *SnippetManager) GetSnippets() []Snippet {
	return sm.snippets
}

func (sm *SnippetManager) GetSnippetsDirectory() string {
	return sm.snippetsDir
}

func (sm *SnippetManager) CreateSampleSnippets() error {
	if len(sm.snippets) > 0 {
		return nil
	}

	samples := map[string]string{
		"hello.txt":        "Hello, World!",
		"greeting.txt":     "Hi there!\n\nHope you're having a great day!",
		"hello-world.go":   "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"Hello, World!\")\n}",
	}

	for filename, content := range samples {
		path := filepath.Join(sm.snippetsDir, filename)
		if _, err := os.Stat(path); os.IsNotExist(err) {
			err := os.WriteFile(path, []byte(content), 0644)
			if err != nil {
				return err
			}
		}
	}

	return sm.LoadSnippets()
}

func (sm *SnippetManager) resolveDuplicateNames() {
	nameCount := make(map[string]int)
	
	for _, snippet := range sm.snippets {
		nameCount[snippet.Name]++
	}
	
	for i, snippet := range sm.snippets {
		if nameCount[snippet.Name] > 1 {
			ext := filepath.Ext(snippet.Path)
			sm.snippets[i].DisplayName = snippet.Name + ext
		}
	}
}