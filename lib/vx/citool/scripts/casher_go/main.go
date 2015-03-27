package main

import (
	"code.google.com/p/gcfg"
	"fmt"
	"github.com/codegangsta/cli"
	"gopkg.in/yaml.v2"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
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

func tar(errCallback func(), flag string, tarFileName string, args ...string) {
	flags := fmt.Sprintf("-Pz%sf", flag)
	args = append([]string{flags, tarFileName}, args...)
	cmd := exec.Command("tar", args...)
	out, err := cmd.CombinedOutput()
	if err != nil {
		if errCallback != nil {
			errCallback()
		} else {
			log.Printf("FAILED: %s => %s", cmd.Args, out)
		}
	}
}

func (cfg *Config) build(c *cli.Context) {
	err := gcfg.ReadFileInto(cfg, c.String("config"))
	check(err)

	cfg.CasherDir, err = filepath.Abs(c.String("casher_dir"))

	cfg.MtimeFile, err = filepath.Abs(filepath.Join(cfg.CasherDir, cfg.Files.MtimeFile))
	cfg.Md5File, err = filepath.Abs(filepath.Join(cfg.CasherDir, cfg.Files.Md5File))
	cfg.FetchTar, err = filepath.Abs(filepath.Join(cfg.CasherDir, cfg.Files.FetchTar))
	cfg.PushTar, err = filepath.Abs(filepath.Join(cfg.CasherDir, cfg.Files.PushTar))

	check(err)
}

func doAdd(c *cli.Context) {
	log.Println("adding: started")

	paths := c.Args()

	for _, path := range paths {
		path, err := filepath.Abs(path)
		if err != nil {
			log.Println("Error", path, "is impossible on this system")
			continue
		}

		log.Printf("adding %s to cache\n", path)
		mtimes[path] = time.Now().Unix()
		os.MkdirAll(path, 0755)

		warner := func() {
			log.Println(path, "is not yet cached")
		}
		tar(warner, "x", cfg.FetchTar, path)
	}

	yml, _ := yaml.Marshal(mtimes)

	err := ioutil.WriteFile(cfg.MtimeFile, yml, 0644)
	check(err)

	log.Println("adding: finished")
}

func prepareApp(c *cli.Context) (err error) {
	cfg.build(c)
	err = os.MkdirAll(cfg.CasherDir, 0755)
	check(err)

	yml, err := ioutil.ReadFile(cfg.MtimeFile)
	check(err)

	err = yaml.Unmarshal(yml, &mtimes)
	check(err)
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
			Value:  fmt.Sprintf("%s/.casher", os.Getenv("HOME")),
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
