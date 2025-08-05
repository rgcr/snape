package main

import (
	"net/url"
	"strings"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/storage"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"
)

type UI struct {
	app            fyne.App
	window         fyne.Window
	snippetManager *SnippetManager
	onSnippetSelected func(snippet Snippet)
	currentList    *widget.List
	currentSnippets []Snippet
	allSnippets    []Snippet
	selectedIndex   int
	programmaticSelection bool
	indexMap       map[rune]int
	filterLabel    *widget.RichText
	filterText     string
	isFilterMode   bool
	mainContent    *fyne.Container
}


func NewUI(snippetManager *SnippetManager, width, height float32) *UI {
	ui := &UI{
		snippetManager: snippetManager,
	}

	ui.app = app.NewWithID("com.snape.snippetmanager")
	ui.app.SetIcon(theme.DocumentIcon())

	ui.window = ui.app.NewWindow("Snape - Snippet Manager")
	ui.setupWindow(width, height)
	ui.setupMenu()

	return ui
}

func (ui *UI) setupWindow(width, height float32) {
	ui.window.Resize(fyne.NewSize(width, height))
	ui.window.SetFixedSize(false)
	ui.window.CenterOnScreen()

	ui.window.SetOnClosed(func() {
		ui.app.Quit()
	})
}

func (ui *UI) ShowSnippetSelector() {
	err := ui.snippetManager.LoadSnippets()
	if err != nil {
		ui.showError("Failed to load snippets: " + err.Error())
		return
	}

	snippets := ui.snippetManager.GetSnippets()
	if len(snippets) == 0 {
		ui.snippetManager.CreateSampleSnippets()
		snippets = ui.snippetManager.GetSnippets()
	}

	ui.createSnippetList(snippets)
	ui.window.Show()
	ui.window.RequestFocus()
}

func (ui *UI) createSnippetList(snippets []Snippet) {
	if len(snippets) == 0 {
		label := widget.NewLabel("No snippets found")
		label.Alignment = fyne.TextAlignCenter
		ui.window.SetContent(container.NewVBox(label))
		return
	}

	ui.allSnippets = snippets
	ui.currentSnippets = snippets
	ui.selectedIndex = 0
	ui.isFilterMode = false
	ui.filterText = ""
	ui.buildIndexMap()

	// Create filter label (initially hidden)
	ui.filterLabel = widget.NewRichTextFromMarkdown("")
	ui.filterLabel.Wrapping = fyne.TextWrapOff

	list := widget.NewList(
		func() int {
			return len(ui.currentSnippets)
		},
		func() fyne.CanvasObject {
			return container.NewHBox(
				widget.NewIcon(theme.DocumentIcon()),
				widget.NewLabel("Template"),
			)
		},
		func(id widget.ListItemID, obj fyne.CanvasObject) {
			hbox := obj.(*fyne.Container)
			label := hbox.Objects[1].(*widget.Label)
			indexChar := ui.getIndexChar(id)
			displayText := "[" + string(indexChar) + "]    " + ui.currentSnippets[id].DisplayName
			label.SetText(displayText)
		},
	)

	ui.currentList = list

	// Handle mouse clicks and track selection changes
	list.OnSelected = func(id widget.ListItemID) {
		ui.selectedIndex = id
		// Only trigger selection if it's not a programmatic change
		if !ui.programmaticSelection {
			ui.selectSnippet()
		}
	}

	if len(ui.currentSnippets) > 0 {
		ui.programmaticSelection = true
		list.Select(0)
		ui.programmaticSelection = false
	}

	// Create grayed out help label
	helpLabel := widget.NewRichText(
		&widget.TextSegment{
			Text: "↑↓ Enter or [index]  |  '/' to filter  |  '?' for help",
			Style: widget.RichTextStyle{
				ColorName: theme.ColorNameDisabled,
				TextStyle: fyne.TextStyle{},
			},
		},
	)

	// Create open folder button
	openFolderBtn := widget.NewButtonWithIcon("Open Snippets Folder", theme.FolderOpenIcon(), func() {
		ui.openSnippetsFolder()
	})
	openFolderBtn.Importance = widget.MediumImportance

	ui.mainContent = container.NewBorder(
		helpLabel,
		openFolderBtn,
		nil, nil,
		list,
	)

	ui.window.SetContent(ui.mainContent)
	ui.setupKeyboardShortcuts()
}

func (ui *UI) selectSnippet() {
	if ui.selectedIndex >= 0 && ui.selectedIndex < len(ui.currentSnippets) {
		if ui.onSnippetSelected != nil {
			ui.onSnippetSelected(ui.currentSnippets[ui.selectedIndex])
		}
		ui.app.Quit()
	}
}

func (ui *UI) setupKeyboardShortcuts() {
	ui.window.Canvas().SetOnTypedKey(func(key *fyne.KeyEvent) {
		if ui.isFilterMode {
			// In filter mode, handle special keys
			switch key.Name {
			case fyne.KeyUp, fyne.KeyDown:
				ui.handleNavigation(key)
			case fyne.KeyReturn, fyne.KeyEnter:
				ui.selectSnippet()
			case fyne.KeyEscape:
				ui.exitFilterMode()
			case fyne.KeyBackspace:
				ui.handleBackspace()
			}
			return
		}

		// Normal mode
		switch key.Name {
		case fyne.KeyUp, fyne.KeyDown:
			ui.handleNavigation(key)
		case fyne.KeyReturn, fyne.KeyEnter:
			ui.selectSnippet()
		case fyne.KeyEscape:
			ui.app.Quit()
		}
	})

	ui.window.Canvas().SetOnTypedRune(func(r rune) {
		if ui.isFilterMode {
			// In filter mode, add character to filter
			ui.addToFilter(r)
			return
		}

		if r == '/' {
			ui.enterFilterMode()
			return
		}

		if r == '?' {
			ui.showAbout()
			return
		}

		// Handle letter index shortcuts only when not in filter mode
		if index, exists := ui.indexMap[r]; exists {
			ui.selectedIndex = index
			ui.selectSnippet()
		}
	})
}

func (ui *UI) handleNavigation(key *fyne.KeyEvent) {
	switch key.Name {
	case fyne.KeyUp:
		if ui.selectedIndex > 0 {
			ui.selectedIndex--
			ui.programmaticSelection = true
			ui.currentList.Select(ui.selectedIndex)
			ui.programmaticSelection = false
		}
	case fyne.KeyDown:
		if ui.selectedIndex < len(ui.currentSnippets)-1 {
			ui.selectedIndex++
			ui.programmaticSelection = true
			ui.currentList.Select(ui.selectedIndex)
			ui.programmaticSelection = false
		}
	}
}

func (ui *UI) enterFilterMode() {
	ui.isFilterMode = true
	ui.filterText = ""
	ui.updateFilterLabel()

	// Create grayed out filter help label
	filterHelpLabel := widget.NewRichText(
		&widget.TextSegment{
			Text: "Filter mode - ESC to quit | ↑↓ Enter to select",
			Style: widget.RichTextStyle{
				ColorName: theme.ColorNameDisabled,
				TextStyle: fyne.TextStyle{},
			},
		},
	)

	filterContent := container.NewBorder(
		container.NewVBox(
			filterHelpLabel,
			ui.filterLabel,
		),
		nil, nil, nil,
		ui.currentList,
	)

	ui.window.SetContent(filterContent)
}

func (ui *UI) exitFilterMode() {
	ui.isFilterMode = false
	ui.filterText = ""
	ui.currentSnippets = ui.allSnippets
	ui.selectedIndex = 0
	ui.buildIndexMap()
	ui.currentList.Refresh()

	if len(ui.currentSnippets) > 0 {
		ui.programmaticSelection = true
		ui.currentList.Select(0)
		ui.programmaticSelection = false
	}

	ui.window.SetContent(ui.mainContent)
}

func (ui *UI) addToFilter(r rune) {
	ui.filterText += string(r)
	ui.updateFilterLabel()
	ui.applyFilter()
}

func (ui *UI) handleBackspace() {
	if len(ui.filterText) > 0 {
		ui.filterText = ui.filterText[:len(ui.filterText)-1]
		ui.updateFilterLabel()
		ui.applyFilter()
	}
}

func (ui *UI) updateFilterLabel() {
	var text string
	if ui.filterText == "" {
		text = "Search: ▌"
	} else {
		text = "Search: " + ui.filterText + "▌"
	}

	ui.filterLabel.Segments = []widget.RichTextSegment{
		&widget.TextSegment{
			Text: text,
			Style: widget.RichTextStyle{
				ColorName: theme.ColorNameWarning, // Orange/warning color
				TextStyle: fyne.TextStyle{Bold: true},
			},
		},
	}
	ui.filterLabel.Refresh()
}

func (ui *UI) applyFilter() {
	if ui.filterText == "" {
		ui.currentSnippets = ui.allSnippets
	} else {
		ui.currentSnippets = []Snippet{}
		filterLower := strings.ToLower(ui.filterText)

		for _, snippet := range ui.allSnippets {
			if strings.Contains(strings.ToLower(snippet.DisplayName), filterLower) ||
			   strings.Contains(strings.ToLower(snippet.Content), filterLower) {
				ui.currentSnippets = append(ui.currentSnippets, snippet)
			}
		}
	}

	ui.selectedIndex = 0
	ui.buildIndexMap()
	ui.currentList.Refresh()

	if len(ui.currentSnippets) > 0 {
		ui.programmaticSelection = true
		ui.currentList.Select(0)
		ui.programmaticSelection = false
	}
}

func (ui *UI) showError(message string) {
	content := container.NewVBox(
		widget.NewIcon(theme.ErrorIcon()),
		widget.NewLabel(message),
		widget.NewButton("OK", func() {
			ui.app.Quit()
		}),
	)
	ui.window.SetContent(content)
	ui.window.Show()
}

func (ui *UI) SetOnSnippetSelected(callback func(snippet Snippet)) {
	ui.onSnippetSelected = callback
}

func (ui *UI) Hide() {
	ui.window.Hide()
}

func (ui *UI) Run() {
	ui.app.Run()
}

func (ui *UI) Quit() {
	ui.app.Quit()
}

func (ui *UI) GetApp() fyne.App {
	return ui.app
}

func (ui *UI) getIndexChar(index int) rune {
	if index < 26 {
		return rune('a' + index)
	} else if index < 52 {
		return rune('A' + (index - 26))
	}
	// For more than 52 items, cycle back to 'a'
	return rune('a' + (index % 26))
}

func (ui *UI) setupMenu() {
	// Create empty main menu - only native macOS About will appear
	mainMenu := fyne.NewMainMenu()
	ui.window.SetMainMenu(mainMenu)
}

func (ui *UI) showAbout() {
	aboutText := `🧙 Snape - A Severus Snippet Manager

Handle your snippets with Severus precision.

Version: 1.0.0

Keyboard Shortcuts:
• ↑↓ Arrow keys: Navigate snippets
• Enter: Select snippet and copy to clipboard
• Letters (a-z, A-Z): Quick selection by index
• '/': Enter filter mode
• '?': Show this about page
• Escape: Quit (or exit filter mode)

Features:
• Quick snippet access by index
• Fuzzy filtering of snippets
• Arrow key navigation
• Mouse click selection
• Cross-platform clipboard integration

File Locations:
• Snippets: ~/.snape/

Each file in the snippets directory becomes a snippet,
with the filename as the snippet name.

`

	aboutDialog := widget.NewCard("About:", "", widget.NewLabel(aboutText))

	aboutWindow := ui.app.NewWindow("About Snape")
	aboutWindow.SetContent(aboutDialog)
	aboutWindow.Resize(fyne.NewSize(450, 420))
	aboutWindow.SetFixedSize(true)
	aboutWindow.CenterOnScreen()
	aboutWindow.Show()
}

func (ui *UI) openSnippetsFolder() {
	snippetsDir := ui.snippetManager.GetSnippetsDirectory()

	// Create storage URI and convert to URL
	uri := storage.NewFileURI(snippetsDir)
	if parsedURL, err := url.Parse(uri.String()); err == nil {
		ui.app.OpenURL(parsedURL)
	}
}

func (ui *UI) buildIndexMap() {
	ui.indexMap = make(map[rune]int)
	for i := 0; i < len(ui.currentSnippets); i++ {
		char := ui.getIndexChar(i)
		ui.indexMap[char] = i
	}
}
