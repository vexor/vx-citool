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
	err = os.MkdirAll(cfg.CacherDir, 0755)
	check(err)
	mtimes.restore()
	return
}

func main() {
	app := cli.NewApp()
	app.Name = "cacher"
	app.Version = version()
	app.Authors = authors()
	app.Usage = "Vexor(tm) cache management tool"

	app.Flags = []cli.Flag{
		cli.StringFlag{
			Name:  "config, f",
			Value: "cacher.cfg",
			Usage: "config file",
		},

		cli.StringFlag{
			Name:   "cacher_dir, d",
			Usage:  "cacher working directory",
			Value:  filepath.Join(os.Getenv("HOME"), ".cacher"),
			EnvVar: "CACHER_DIR",
		},
	}

	app.Before = prepareApp

	app.Commands = []cli.Command{
		{
			Name:    "add",
			Aliases: []string{"a"},
			Usage:   "adds listed paths to cache",
			Action:  doAdd,
		},
		{
			Name:    "fetch",
			Aliases: []string{"f"},
			Usage:   "fetching an archive from a specified url",
			Action:  doFetch,
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
