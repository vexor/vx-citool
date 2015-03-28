package main

import (
	"github.com/codegangsta/cli"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// Implements 'add' subcommand
func doAdd(c *cli.Context) {
	log.Println("adding: started")

	var wg sync.WaitGroup
	paths := c.Args()

	for _, path := range paths {
		path, err := filepath.Abs(path)
		if err != nil {
			log.Println("Error", path, "is impossible on this system")
			continue
		}

		log.Printf("adding %s to cache\n", path)
		os.MkdirAll(path, 0755)
		mtimes[path] = time.Now().Unix()

		wg.Add(1)
		go func() {
			defer wg.Done()
			warner := func() {
				log.Println(path, "is not yet cached")
			}
			tar(warner, "x", cfg.FetchTar, path)
		}()
	}
	wg.Wait()

	mtimes.store()

	log.Println("adding: finished")
}
