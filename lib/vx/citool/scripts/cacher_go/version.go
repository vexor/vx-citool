package main

import (
	"github.com/codegangsta/cli"
)

const (
	VERSION = "v0.0.1"
)

var (
	AUTHORS = []cli.Author{
		cli.Author{
			Name:  "argent_smith",
			Email: "argentoff@evrone.ru",
		},
	}
)

func version() string {
	return VERSION
}

func authors() []cli.Author {
	return AUTHORS
}
