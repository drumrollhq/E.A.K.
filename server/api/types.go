package api

import (
	"time"
)

type Config struct {
	ApiEnabled bool `json:"api"`
	Postgres   PgConfig
}

type PgConfig struct {
	Host     string
	Port     int
	Database string
	User     string
	Password string
	SSL      string
}

type User struct {
	Id      int       `json:"id"`
	State   string    `json:"state"`
	Created time.Time `json:"created"`
	Seen    time.Time `json:"lastSeen"`
}
