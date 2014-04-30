package api

import (
	"encoding/json"
	"fmt"
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

func parseReqJSON(r *http.Request, d interface{}) (error, int) {
	if r.Body == nil {
		return fmt.Errorf("You must supply a body"), http.StatusBadRequest
	}

	if r.Header["Content-Type"][0] != "application/json" {
		return fmt.Errorf("Content-Type must be application/json"), http.StatusBadRequest
	}

	dcd := json.NewDecoder(r.Body)
	if err := dcd.Decode(d); err != nil {
		return fmt.Errorf("Could not decode JSON: %v", err), http.StatusBadRequest
	}

	return nil, http.StatusOK
}
