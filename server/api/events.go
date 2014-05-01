package api

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/zenazn/goji/web"
)

const maxCheckinInterval float64 = 120 // seconds

func postEventHandler(c web.C, w http.ResponseWriter, r *http.Request) {
	user, ok := c.Env["user"].(User)
	if !ok {
		http.Error(w, "The user isn't a user!?", http.StatusInternalServerError)
		return
	}

	var event Event
	err, status := parseReqJSON(r, &event)
	if err != nil {
		http.Error(w, err.Error(), status)
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

func getEventHandler(c web.C, w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(c.URLParams["id"], 10, 64)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	event, err, bad := GetEvent(id)
	if err != nil {
		if bad {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		} else {
			http.Error(w, err.Error(), http.StatusNotFound)
		}
		return
	}

	sendJSON(w, event)
}

func postCheckinHandler(c web.C, w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(c.URLParams["id"], 10, 64)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	var checkin struct {
		DT float64 `json:"dt"`
	}
	err, status := parseReqJSON(r, &checkin)
	if err != nil {
		http.Error(w, err.Error(), status)
		return
	}

	if checkin.DT == 0 {
		http.Error(w, "Event checkin must have a DT", http.StatusBadRequest)
		return
	}

	event, err, bad := GetEvent(id)
	if err != nil {
		if bad {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		} else {
			http.Error(w, err.Error(), http.StatusNotFound)
		}
		return
	}

	dt := time.Since(event.Start.Add(time.Duration(event.Duration) * time.Second)).Seconds()
	if dt > maxCheckinInterval {
		eStr := fmt.Sprintf("Cannot checkin after %fs of event inactivity (%fs)",
			maxCheckinInterval, dt)
		http.Error(w, eStr, http.StatusBadRequest)
		return
	}

	dur := time.Since(event.Start).Seconds() + checkin.DT/2
	st := time.Now()
	row := queries.checkin.QueryRow(id, dur)
	newEvent, err := readEvent(row)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	log.Println("Updated duration (checkin) for event in", time.Since(st))

	sendJSON(w, newEvent)
}

func GetEvent(id int64) (Event, error, bool) {
	st := time.Now()
	rows, err := queries.getEvent.Query(id)
	defer rows.Close()
	if err != nil {
		return Event{}, err, true
	}

	if rows.Next() {
		event, err := readEvent(rows)
		if err != nil {
			return event, err, true
		}
		log.Println("Got event in", time.Since(st))
		return event, err, false
	}

	// 404
	return Event{}, fmt.Errorf("Event not found"), false
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

	var parent int
	if event.ParentId != 0 {
		parent = event.ParentId
	} else {
		parent = 0
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

func readEvent(row dbScanner) (Event, error) {
	var ne Event
	var duration interface{}
	var data string

	err := row.Scan(&ne.Id, &ne.UserId, &ne.ParentId, &ne.Type,
		&ne.Version, &ne.Start, &duration, &data)
	if err != nil {
		log.Printf("%#v", ne)
		return ne, err
	}

	if duration != nil {
		switch dur := duration.(type) {
		case string:
			f, err := strconv.ParseFloat(dur, 64)
			if err != nil {
				return ne, fmt.Errorf("Cannot parse duration: %s", dur)
			}
			ne.Duration = f

		case float64:
			ne.Duration = dur

		default:
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
