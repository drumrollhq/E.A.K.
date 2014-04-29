package main

import (
	"./api"

	"bytes"
	"log"
	"net/http"
	"os/exec"
	"runtime"
	"strings"

	"github.com/zenazn/goji"
	"github.com/zenazn/goji/web"
)

var APP_VERSION string

func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())
	APP_VERSION = getVersion()
	log.Println("Version:", APP_VERSION)

	conf := loadConfig()
	if conf.ApiEnabled {
		apiHandler := web.New()
		goji.Handle("/api/*", apiHandler)
		api.Attach(apiHandler, APP_VERSION, conf)
	}

	goji.Get("/*", static("../public"))

	goji.Serve()
	log.Println("Finished")
}

func NotFound(w http.ResponseWriter, r *http.Request) {
	http.Error(w, "404 :(", http.StatusNotFound)
}

func getVersion() string {
	v := run("git", "rev-parse", "HEAD")
	if run("git", "status", "--porcelain") != "" {
		v += "_DEV"
	}
	return v
}

func run(name string, args ...string) string {
	cmd := exec.Command(name, args...)
	var out bytes.Buffer
	cmd.Stdout = &out
	if err := cmd.Run(); err != nil {
		log.Fatal(err)
	}
	return strings.Trim(out.String(), " \t\n\r")
}
