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
	"sync"
	"time"
)

// TODO: extract into file
type Mtimes map[string]int64

func (mtimes *Mtimes) restore() {
	*mtimes = make(Mtimes)
	yml, _ := ioutil.ReadFile(cfg.MtimeFile)
	yaml.Unmarshal(yml, mtimes)
}

func (mtimes Mtimes) store() {
	yml, _ := yaml.Marshal(mtimes)
	ioutil.WriteFile(cfg.MtimeFile, yml, 0644)
}

// TODO: extract into file
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

// Builds the global configuration structure
func (cfg *Config) build(c *cli.Context) {
	err := gcfg.ReadFileInto(cfg, c.String("config"))
	check(err)

	cfg.CasherDir, _ = filepath.Abs(c.String("casher_dir"))

	cfg.MtimeFile, _ = filepath.Abs(filepath.Join(cfg.CasherDir, cfg.Files.MtimeFile))
	cfg.Md5File, _ = filepath.Abs(filepath.Join(cfg.CasherDir, cfg.Files.Md5File))
	cfg.FetchTar, _ = filepath.Abs(filepath.Join(cfg.CasherDir, cfg.Files.FetchTar))
	cfg.PushTar, _ = filepath.Abs(filepath.Join(cfg.CasherDir, cfg.Files.PushTar))
}

// TODO: extract into file
func check(e error) {
	if e != nil {
		log.Fatal(e)
	}
}

// External command execution wrapper for tar WITH OPTIONAL CALLBACK TO HANDLE ERROR
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
