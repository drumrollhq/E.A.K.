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

type Event struct {
	Id       int                    `json:"id,omitempty"`
	ParentId int                    `json:"parentId,omitempty"`
	Parent   *Event                 `json:"parent,omitempty"`
	UserId   int                    `json:"userId,omitempty"`
	User     *User                  `json:"user,omitempty"`
	Type     string                 `json:"type,omitempty"`
	Version  string                 `json:"version,omitempty"`
	Start    time.Time              `json:"startTime,omitempty"`
	Duration float64                `json:"duration,omitempty"`
	Data     map[string]interface{} `json:"data,omitempty"`
}

type dbScanner interface {
	Scan(...interface{}) error
}
