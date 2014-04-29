package api

import (
	"database/sql"
	"log"
)

var queries struct {
	getAndUpdateUser *sql.Stmt
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
}
