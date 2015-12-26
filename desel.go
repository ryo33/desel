package main

import (
	"github.com/codegangsta/cli"
	"github.com/ryo33/desel/commands"
	"os"
)

var (
	flags = []cli.Flag{}
)

func main() {
	app := cli.NewApp()
	app.Name = "desel"
	app.Usage = "handle Desel"
	app.Commands = commands.Commands
	app.Flags = flags
	app.Action = action
	app.Run(os.Args)
}

func action(c *cli.Context) {
}
