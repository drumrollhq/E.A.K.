package api

import (
	"database/sql"
	"log"
)

var queries struct {
	getAndUpdateUser *sql.Stmt
	createEvent      *sql.Stmt
}

func prepareQueries() {
	q, err := db.Prepare(`
		UPDATE users
		SET last_seen = NOW()
		WHERE id = $1
		RETURNING id, state, created, last_seen
	`)
	if err != nil {
		log.Fatal(err)
	}
	queries.getAndUpdateUser = q

	q, err = db.Prepare(`
		INSERT INTO events (user_id, parent_id, type, version, start_time, duration, event_data)
		VALUES ($1, $2, $3, $4, NOW(), NULL, $5)
		RETURNING id, user_id, parent_id, type, version, start_time, duration, event_data
	`)
	if err != nil {
		log.Fatal(err)
	}
	queries.createEvent = q
}
