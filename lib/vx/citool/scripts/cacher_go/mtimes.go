package main

import (
	"gopkg.in/yaml.v2"
	"io/ioutil"
)

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
