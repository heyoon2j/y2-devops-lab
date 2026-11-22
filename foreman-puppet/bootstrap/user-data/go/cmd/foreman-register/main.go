package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	registration "github.com/heyoon2j/y2-devops-lab/foreman-puppet/bootstrap/user-data/go"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	file := flag.String("config", "", "registration JSON input")
	apply := flag.Bool("apply", false, "create-only Foreman API registration (default: offline plan)")
	flag.Parse()
	if *file == "" || flag.NArg() != 0 {
		fmt.Fprintln(os.Stderr, "Usage: foreman-register --config FILE [--apply]")
		os.Exit(2)
	}
	f, err := os.Open(*file)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Could not read registration input")
		os.Exit(1)
	}
	c, err := registration.LoadConfig(f)
	f.Close()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	if *apply && os.Geteuid() != 0 {
		fmt.Fprintln(os.Stderr, "--apply requires root")
		os.Exit(1)
	}
	signalCtx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	ctx, cancel := context.WithTimeout(signalCtx, 10*time.Minute)
	defer cancel()
	result, err := registration.RegisterForeman(ctx, c, *apply)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	if encoder.Encode(result) != nil {
		os.Exit(1)
	}
}
