package api

import (
	"log"
	"net/http"

	"github.com/zenazn/goji/web"
)

func postEventHandler(c web.C, w http.ResponseWriter, r *http.Request) {
	user, err := getCurrentUser(r)
	if err != nil {
		log.Println("Error: ", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	log.Printf("%#v", user)
	log.Printf("%#v", r.Body)
}
