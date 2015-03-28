package main

import (
	"fmt"
	"github.com/codegangsta/cli"
	"os"
	"path/filepath"
)

// Sets up application's configuration
func prepareApp(c *cli.Context) (err error) {
	cfg.build(c)
	err = os.MkdirAll(cfg.CasherDir, 0755)
	check(err)
	mtimes.restore()
	return
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
