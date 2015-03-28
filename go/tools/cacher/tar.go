package main

import (
	"fmt"
	"log"
	"os/exec"
)

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
