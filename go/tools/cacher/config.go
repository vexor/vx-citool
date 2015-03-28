package main

import (
	"code.google.com/p/gcfg"
	"github.com/codegangsta/cli"
	"path/filepath"
)

// TODO: extract into file
type Config struct {
	Files struct {
		MtimeFile string
		Md5File   string
		FetchTar  string
		PushTar   string
	}

	CacherDir string
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

	cfg.CacherDir, _ = filepath.Abs(c.String("cacher_dir"))

	cfg.MtimeFile, _ = filepath.Abs(filepath.Join(cfg.CacherDir, cfg.Files.MtimeFile))
	cfg.Md5File, _ = filepath.Abs(filepath.Join(cfg.CacherDir, cfg.Files.Md5File))
	cfg.FetchTar, _ = filepath.Abs(filepath.Join(cfg.CacherDir, cfg.Files.FetchTar))
	cfg.PushTar, _ = filepath.Abs(filepath.Join(cfg.CacherDir, cfg.Files.PushTar))
}
