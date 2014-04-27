package main

import (
  "bytes"
  "log"
  "net/http"
  "os/exec"
  "strings"

  "github.com/zenazn/goji"
)

var APP_VERSION string

func main() {
  APP_VERSION = getVersion()

  goji.Get("/*", static("../public"))

  log.Println("Version:", APP_VERSION)
  goji.Serve()
  log.Println("Finished")
}

func NotFound (w http.ResponseWriter, r *http.Request) {
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
