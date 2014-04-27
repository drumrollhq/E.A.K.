package main

import (
  "log"
  "net/http"

  "github.com/zenazn/goji"
)

func main() {
  goji.Get("/*", static("../public"))



  goji.Serve()
  log.Println("Finished")
}

func NotFound (w http.ResponseWriter, r *http.Request) {
    http.Error(w, "404 :(", http.StatusNotFound)
}
