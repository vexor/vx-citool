package main

import (
	"log"
)

// TODO: extract into file
func check(e error) {
	if e != nil {
		log.Fatal(e)
	}
}
