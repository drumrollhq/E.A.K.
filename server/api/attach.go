package api

import (
	"log"

	"github.com/zenazn/goji/web"
)

type Config struct {
	ApiEnabled bool `json:"api"`
}

func Attach(app *web.Mux, version string, conf Config) {
	log.Println("Attaching API")
}
