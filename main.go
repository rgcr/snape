package main

import (
	"flag"
	"fmt"
)

var (
	verbose    = flag.Bool("verbose", false, "Enable verbose output")
	help       = flag.Bool("help", false, "Show help message")
	widthSize  = flag.Int("width-size", 280, "Window width (200-600)")
	heightSize = flag.Int("height-size", 400, "Window height (200-600)")
)

func main() {
	flag.Parse()

	if *help {
		showHelp()
		return
	}

	// Validate window size parameters
	if *widthSize < 200 || *widthSize > 600 {
		fmt.Printf("Error: width-size must be between 200 and 600 (got %d)\n", *widthSize)
		return
	}
	if *heightSize < 200 || *heightSize > 600 {
		fmt.Printf("Error: height-size must be between 200 and 600 (got %d)\n", *heightSize)
		return
	}

	if *verbose {
		fmt.Printf("Starting Snape snippet manager (size: %dx%d)...\n", *widthSize, *heightSize)
	}


	snippetManager := NewSnippetManager()
	if *verbose {
		fmt.Printf("Snippets directory: %s\n", snippetManager.GetSnippetsDirectory())
	}

	ui := NewUI(snippetManager, float32(*widthSize), float32(*heightSize))
	clipboard := NewClipboard(ui.GetApp())

	ui.SetOnSnippetSelected(func(snippet Snippet) {
		if *verbose {
			fmt.Printf("Selected snippet: %s\n", snippet.DisplayName)
			fmt.Println("Copying snippet to clipboard...")
		}
		clipboard.SetText(snippet.Content)
	})

	ui.ShowSnippetSelector()
	ui.Run()
}

func showHelp() {
	fmt.Printf(`Snape - A Severus Snippet Manager

Handle your snippets with Severus precision.

Usage:
  snape [options]

Options:
  --help                   Show this help message
  --verbose                Enable verbose output messages
  --width-size WIDTH       Set window width (200-600, default: 280)
  --height-size HEIGHT     Set window height (200-600, default: 400)

Configuration:
  Snippets directory: ~/.snape/

The application will show a popup window with your available snippets.
Select a snippet to copy it to the clipboard.

Examples:
  snape                               # Show snippet selector (default size)
  snape --verbose                     # Show snippet selector with verbose output
  snape --width-size 300 --height-size 500  # Show with custom window size
  snape --help                        # Show this help message
`)
}
