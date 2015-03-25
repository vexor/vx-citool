package main

import (
	"code.google.com/p/gcfg"
	"fmt"
	"github.com/codegangsta/cli"
	"os"
)

type Mtimes struct {
	// TODO: implement
}

type Config struct {
	Files struct {
		MtimeFile string
		Md5File   string
		FetchTar  string
		PushTar   string
	}

	CasherDir string
	MtimeFile string
	Md5File   string
	FetchTar  string
	PushTar   string
	Mtimes    Mtimes
}

var (
	cfg    Config
	mtimes Mtimes
)

func (cfg *Config) build(c *cli.Context) {
	err := gcfg.ReadFileInto(cfg, c.String("config"))
	if err != nil {
		fmt.Println("Bad config:", err)
		os.Exit(1)
	}
	cfg.CasherDir = c.String("casher_dir")
	cfg.MtimeFile = fmt.Sprintf("%s/%s", cfg.CasherDir, cfg.Files.MtimeFile)
	cfg.Md5File = fmt.Sprintf("%s/%s", cfg.CasherDir, cfg.Files.Md5File)
	cfg.FetchTar = fmt.Sprintf("%s/%s", cfg.CasherDir, cfg.Files.FetchTar)
	cfg.PushTar = fmt.Sprintf("%s/%s", cfg.CasherDir, cfg.Files.PushTar)
}

func main() {
	app := cli.NewApp()
	app.Name = "casher"
	app.Usage = "TODO: WRITEME"

	app.Flags = []cli.Flag{
		cli.StringFlag{
			Name:  "config, f",
			Value: "casher.cfg",
			Usage: "config file",
		},

		cli.StringFlag{
			Name:   "casher_dir, d",
			Usage:  "casher working directory",
			Value:  fmt.Sprintf("%s/.casher", os.Getenv("HOME")),
			EnvVar: "CASHER_DIR",
		},
	}

	app.Before = func(c *cli.Context) (err error) {
		fmt.Println("====>>>>")

		cfg.build(c)
		err = os.MkdirAll(cfg.CasherDir, 0755)
		if err != nil {
			fmt.Println(err.Error())
			return
		}
		return
	}

	app.Commands = []cli.Command{
		{
			Name:    "add",
			Aliases: []string{"a"},
			Usage:   "TODO: WRITEME",
			Action: func(c *cli.Context) {
				fmt.Println("adding")
			},
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
