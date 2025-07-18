package main

import (
	"github.com/jmoiron/sqlx"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var dsn = "root:root@admin@tcp(127.0.0.1:3306)/gorm?charset=utf8&parseTime=True&loc=Local"

func getGorm() *gorm.DB {
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		panic(err)
	}
	return db
}

func getSqlx() *sqlx.DB {
	db, err := sqlx.Open("mysql", dsn)
	if err != nil {
		panic(err)
	}
	return db
}
