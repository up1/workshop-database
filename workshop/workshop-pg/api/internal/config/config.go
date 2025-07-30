package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	DatabaseURL     string
	Port            string
	MaxConns        int32
	MinConns        int32
	MaxConnLifetime time.Duration
	MaxConnIdleTime time.Duration
}

func LoadConfig() *Config {
	config := &Config{
		DatabaseURL: getEnv("DATABASE_URL", "postgres://postgres:password@localhost:5432/workshop_db?sslmode=disable"),
		Port:        getEnv("PORT", "8080"),
	}

	// Connection pool tuning for best performance
	config.MaxConns = int32(getEnvAsInt("DB_MAX_CONNS", 25))                                         // Maximum number of connections
	config.MinConns = int32(getEnvAsInt("DB_MIN_CONNS", 5))                                          // Minimum number of connections
	config.MaxConnLifetime = time.Duration(getEnvAsInt("DB_MAX_CONN_LIFETIME", 3600)) * time.Second  // 1 hour
	config.MaxConnIdleTime = time.Duration(getEnvAsInt("DB_MAX_CONN_IDLE_TIME", 1800)) * time.Second // 30 minutes

	return config
}

func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

func getEnvAsInt(name string, defaultVal int) int {
	valueStr := getEnv(name, "")
	if value, err := strconv.Atoi(valueStr); err == nil {
		return value
	}
	return defaultVal
}
