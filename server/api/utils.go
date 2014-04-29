package api

import (
	"encoding/json"
	"log"
	"net/http"
)

func sendJSON(w http.ResponseWriter, js interface{}) {
	w.Header().Set("Content-Type", "application/json")
	b, err := json.Marshal(js)
	if err != nil {
		log.Println("JSON error: ", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	w.Write(b)
}
