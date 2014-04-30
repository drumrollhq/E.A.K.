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
	Id       int                    `json:"id"`
	ParentId int                    `json:"parentId"`
	Parent   *Event                 `json:"parent"`
	UserId   int                    `json:"userId"`
	User     *User                  `json:"user"`
	Type     string                 `json:"type"`
	Version  string                 `json:"appVersion"`
	Start    time.Time              `json:"startTime"`
	Duration float64                `json:"duration"`
	Data     map[string]interface{} `json:"data"`
}
