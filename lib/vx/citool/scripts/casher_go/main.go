package main

import (
	"fmt"
	"github.com/codegangsta/cli"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// Sets up application's configuration
func prepareApp(c *cli.Context) (err error) {
	cfg.build(c)
	err = os.MkdirAll(cfg.CasherDir, 0755)
	check(err)
	mtimes.restore()
	return
}

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

func main() {
	app := cli.NewApp()
	app.Name = "casher"
	app.Usage = "Caches the specified files"

	app.Flags = []cli.Flag{
		cli.StringFlag{
			Name:  "config, f",
			Value: "casher.cfg",
			Usage: "config file",
		},

		cli.StringFlag{
			Name:   "casher_dir, d",
			Usage:  "casher working directory",
			Value:  filepath.Join(os.Getenv("HOME"), ".casher"),
			EnvVar: "CASHER_DIR",
		},
	}

	app.Before = prepareApp

	app.Commands = []cli.Command{
		{
			Name:    "add",
			Aliases: []string{"a"},
			Usage:   "adds paths to cache",
			Action:  doAdd,
		},
		{
			Name:    "fetch",
			Aliases: []string{"f"},
			Usage:   "TODO: WRITEME",
			Action: func(c *cli.Context) {
				fmt.Println("fetching")
			},
		},
		{
			Name:    "push",
			Aliases: []string{"p"},
			Usage:   "TODO: WRITEME",
			Action: func(c *cli.Context) {
				fmt.Println("pushing")
			},
		},
	}

	app.Run(os.Args)
}
