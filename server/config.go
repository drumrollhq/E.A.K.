package main

import (
	"encoding/json"
	"flag"
	"io/ioutil"
	"log"

	"./api"
)

var configFile = flag.String("config", "conf.default.json", "path to the server config file")

func loadConfig() api.Config {
	flag.Parse()
	log.Println("Loading config", *configFile)
	f, err := ioutil.ReadFile(*configFile)
	if err != nil {
		log.Fatal(err)
	}

	var conf api.Config
	err = json.Unmarshal(f, &conf)
	if err != nil {
		log.Fatal(err)
	}

	return conf
}
