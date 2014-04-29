package api

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/zenazn/goji/web"
)

func getCurrentUserHandler(c web.C, w http.ResponseWriter, r *http.Request) {
	user, err := getCurrentUser(r)
	if err != nil {
		log.Println("Error: ", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	sendJSON(w, user)
}

func getCurrentUser(r *http.Request) (User, error) {
	// TODO: use a query that selects the user on some proper metric rather than a default id:
	st := time.Now()
	rows, err := queries.getAndUpdateUser.Query(defaultUser)
	if err != nil {
		return User{}, err
	}
	log.Println("Got & updated user in", time.Since(st))

	for rows.Next() {
		var user User
		if err := rows.Scan(&user.Id, &user.State, &user.Created, &user.Seen); err != nil {
			return user, err
		} else {
			return user, nil
		}
	}

	return User{}, fmt.Errorf("Could not find current user :(")
}
