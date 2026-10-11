package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Port           string
	Environment    string
	LogLevel       string
	AllowedOrigins []string

	DBHost            string
	DBPort            string
	DBUser            string
	DBPassword        string
	DBName            string
	DBSSLMode         string
	DBMaxConns        int32
	DBMinConns        int32
	DBMaxConnLifetime time.Duration

	FirebaseProjectID string
	AllowMockAuth     bool

	RateLimitRPS   float64
	RateLimitBurst int

	LocationRetentionHours int
}

func Load() (*Config, error) {
	cfg := &Config{
		Port:           getEnv("PORT", "8080"),
		Environment:    getEnv("ENV", "development"),
		LogLevel:       getEnv("LOG_LEVEL", "debug"),
		AllowedOrigins: strings.Split(getEnv("ALLOWED_ORIGINS", "*"), ","),

		DBHost:            getEnv("DB_HOST", "localhost"),
		DBPort:            getEnv("DB_PORT", "5432"),
		DBUser:            getEnv("DB_USER", "guardvarx_user"),
		DBPassword:        getEnv("DB_PASSWORD", "guardvarx_secure_pass"),
		DBName:            getEnv("DB_NAME", "guardvarx_db"),
		DBSSLMode:         getEnv("DB_SSLMODE", "disable"),
		DBMaxConns:        int32(getEnvInt("DB_MAX_CONNS", 25)),
		DBMinConns:        int32(getEnvInt("DB_MIN_CONNS", 5)),
		DBMaxConnLifetime: time.Hour,

		FirebaseProjectID: getEnv("FIREBASE_PROJECT_ID", "guardvarx-safety"),
		AllowMockAuth:     getEnvBool("ALLOW_MOCK_AUTH", true),

		RateLimitRPS:   getEnvFloat("RATE_LIMIT_RPS", 20.0),
		RateLimitBurst: getEnvInt("RATE_LIMIT_BURST", 40),

		LocationRetentionHours: getEnvInt("LOCATION_RETENTION_HOURS", 24),
	}

	if cfg.Port == "" {
		return nil, fmt.Errorf("PORT environment variable must not be empty")
	}

	return cfg, nil
}

func (c *Config) DatabaseURL() string {
	return fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s",
		c.DBUser, c.DBPassword, c.DBHost, c.DBPort, c.DBName, c.DBSSLMode)
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}

func getEnvInt(key string, defaultVal int) int {
	if val := os.Getenv(key); val != "" {
		if intVal, err := strconv.Atoi(val); err == nil {
			return intVal
		}
	}
	return defaultVal
}

func getEnvFloat(key string, defaultVal float64) float64 {
	if val := os.Getenv(key); val != "" {
		if floatVal, err := strconv.ParseFloat(val, 64); err == nil {
			return floatVal
		}
	}
	return defaultVal
}

func getEnvBool(key string, defaultVal bool) bool {
	if val := os.Getenv(key); val != "" {
		return strings.ToLower(val) == "true" || val == "1"
	}
	return defaultVal
}
