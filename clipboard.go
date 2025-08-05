package main

import (
	"fyne.io/fyne/v2"
)

type Clipboard struct {
	app fyne.App
}

func NewClipboard(app fyne.App) *Clipboard {
	return &Clipboard{app: app}
}

func (c *Clipboard) SetText(text string) error {
	c.app.Driver().AllWindows()[0].Clipboard().SetContent(text)
	return nil
}

func (c *Clipboard) TypeText(text string) error {
	return c.SetText(text)
}