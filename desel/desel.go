package desel

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strings"
)

type deselFile struct {
	desc     string
	contents []string
}

func ReadDeselFiles(files []string) []deselFile {
	r := make([]deselFile, len(files))
	for i, name := range files {
		f, err := os.Open(name)
		if err != nil {
			panic(err)
		}
		r[i] = ReadDesel(name, f)
		if err = f.Close(); err != nil {
			panic(err)
		}
	}
	return r
}

func ReadDesel(desc string, r io.Reader) deselFile {
	buf, err := ioutil.ReadAll(r)
	if err != nil {
		fmt.Fprintln(os.Stderr, "reading \""+desc+"\":", err)
		os.Exit(1)
	}
	c := strings.Split(string(buf), "\n")
	return deselFile{desc, c}
}
