package main

import (
	"code.google.com/p/gcfg"
	"fmt"
	"github.com/codegangsta/cli"
	"gopkg.in/yaml.v2"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"time"
)

type Mtimes map[string]int64

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
}

var (
	cfg    Config
	mtimes Mtimes
)

func check(e error) {
	if e != nil {
		log.Fatal(e)
	}
}

func tar(flag string, tarFileName string, paths ...string) (err error) {
	// TODO: implement
	return
}

func (cfg *Config) build(c *cli.Context) {
	err := gcfg.ReadFileInto(cfg, c.String("config"))
	check(err)

	cfg.CasherDir, err = filepath.Abs(c.String("casher_dir"))
	// TODO: решить на filepath целиком
	cfg.MtimeFile, err = filepath.Abs(fmt.Sprintf("%s/%s", cfg.CasherDir, cfg.Files.MtimeFile))
	cfg.Md5File, err = filepath.Abs(fmt.Sprintf("%s/%s", cfg.CasherDir, cfg.Files.Md5File))
	cfg.FetchTar, err = filepath.Abs(fmt.Sprintf("%s/%s", cfg.CasherDir, cfg.Files.FetchTar))
	cfg.PushTar, err = filepath.Abs(fmt.Sprintf("%s/%s", cfg.CasherDir, cfg.Files.PushTar))
	check(err)
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
			Value:  fmt.Sprintf("%s/.casher", os.Getenv("HOME")),
			EnvVar: "CASHER_DIR",
		},
	}

	app.Before = func(c *cli.Context) (err error) {
		// TODO: extract function
		cfg.build(c)
		err = os.MkdirAll(cfg.CasherDir, 0755)
		check(err)

		yml, err := ioutil.ReadFile(cfg.MtimeFile)
		check(err)

		err = yaml.Unmarshal(yml, &mtimes)
		check(err)
		return
	}

	app.Commands = []cli.Command{
		{
			Name:    "add",
			Aliases: []string{"a"},
			Usage:   "adds paths to cache",
			Action: func(c *cli.Context) {
				// TODO: extract function
				log.Println("adding: started")

				paths := c.Args()

				for _, path := range paths {
					path, _ = filepath.Abs(path)
					log.Printf("adding %s to cache\n", path)
					os.MkdirAll(path, 0755)

					err := tar("x", cfg.FetchTar, path)
					if err != nil {
						log.Println(path, "is not yet cached")
					}

					mtimes[path] = time.Now().Unix()
				}
				yml, _ := yaml.Marshal(mtimes)

				err := ioutil.WriteFile(cfg.MtimeFile, yml, 0644)
				check(err)
				log.Println("adding: finished")
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
