package api

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/zenazn/goji/web"
)

func postEventHandler(c web.C, w http.ResponseWriter, r *http.Request) {
	user, ok := c.Env["user"].(User)
	if !ok {
		http.Error(w, "The user isn't a user!?", http.StatusInternalServerError)
		return
	}

	if r.Body == nil {
		http.Error(w, "You must supply a body", http.StatusBadRequest)
		return
	}

	if r.Header["Content-Type"][0] != "application/json" {
		http.Error(w, "Content-Type must be application/json", http.StatusBadRequest)
		return
	}

	var event Event
	dcd := json.NewDecoder(r.Body)
	if err := dcd.Decode(&event); err != nil {
		http.Error(w, "Could not decode JSON: "+err.Error(), http.StatusBadRequest)
		return
	}

	event.User = &user

	newEv, err := CreateEvent(event)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	sendJSON(w, newEv)
}

func CreateEvent(event Event) (Event, error) {
	if event.Id != 0 {
		return Event{}, fmt.Errorf("A new event cannot have an ID")
	}
	if event.Type == "" {
		return Event{}, fmt.Errorf("Event must have a type")
	}
	if event.Version == "" {
		return Event{}, fmt.Errorf("Event must have app version.")
	}
	if event.Parent != nil {
		event.ParentId = event.Parent.Id
	}
	if event.User != nil {
		event.UserId = event.User.Id
	}
	if event.UserId == 0 {
		return Event{}, fmt.Errorf("Event must have userId")
	}

	var parent interface{}
	if event.ParentId == 0 {
		parent = event.ParentId
	} else {
		parent = nil
	}

	dataBytes, err := json.Marshal(event.Data)
	if err != nil {
		return Event{}, err
	}

	st := time.Now()
	row := queries.createEvent.QueryRow(
		event.UserId,
		parent,
		event.Type,
		event.Version,
		string(dataBytes),
	)
	defer log.Println("Created event in", time.Since(st))

	return readEvent(row)
}

func readEvent(row *sql.Row) (Event, error) {
	var ne Event
	var duration interface{}
	var data string

	err := row.Scan(&ne.Id, &ne.UserId, &ne.ParentId, &ne.Type,
		&ne.Version, &ne.Start, &duration, &data)
	if err != nil {
		return ne, err
	}

	if duration != nil {
		str, ok := duration.(string)
		if ok {
			f, err := strconv.ParseFloat(str, 64)
			if err != nil {
				return ne, fmt.Errorf("Cannot parse duration: %s", str)
			}
			ne.Duration = f
		} else {
			return ne, fmt.Errorf("Bad duration from db: %#v [%T]", duration, duration)
		}
	}

	if data != "null" {
		var eData map[string]interface{}
		if err := json.Unmarshal([]byte(data), &eData); err != nil {
			return ne, fmt.Errorf("Error parsing event data: %v", err)
		}

		ne.Data = eData
	}

	return ne, nil
}
