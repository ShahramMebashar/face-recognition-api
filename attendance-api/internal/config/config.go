package config

import (
	"fmt"
	"time"

	"github.com/joho/godotenv"
	"github.com/spf13/viper"
)

type Config struct {
	Server     ServerConfig
	FaceAPI    FaceAPIConfig
	Upload     UploadConfig
	Attendance AttendanceConfig
}

type ServerConfig struct {
	Port string
	Host string
}

type FaceAPIConfig struct {
	URL     string
	Timeout time.Duration
}

type UploadConfig struct {
	MaxUploadSize int64
	MaxMemory     int64
}

type AttendanceConfig struct {
	DBPath string
}

func Load() (*Config, error) {
	// Try to load .env file (ignore error if not exists)
	_ = godotenv.Load()

	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./configs")

	// Bind environment variables
	viper.AutomaticEnv()

	// Set defaults
	viper.SetDefault("server.port", "8080")
	viper.SetDefault("server.host", "0.0.0.0")
	viper.SetDefault("faceapi.url", "http://localhost:5001")
	viper.SetDefault("faceapi.timeout", "30s")
	viper.SetDefault("upload.maxuploadsize", 5242880) // 5MB
	viper.SetDefault("upload.maxmemory", 10485760)    // 10MB
	viper.SetDefault("attendance.dbpath", "./data/attendance.db")

	// Read config file (optional)
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("failed to read config file: %w", err)
		}
	}

	// Parse timeout
	timeout, err := time.ParseDuration(viper.GetString("faceapi.timeout"))
	if err != nil {
		timeout = 30 * time.Second
	}

	config := &Config{
		Server: ServerConfig{
			Port: viper.GetString("server.port"),
			Host: viper.GetString("server.host"),
		},
		FaceAPI: FaceAPIConfig{
			URL:     viper.GetString("faceapi.url"),
			Timeout: timeout,
		},
		Upload: UploadConfig{
			MaxUploadSize: viper.GetInt64("upload.maxuploadsize"),
			MaxMemory:     viper.GetInt64("upload.maxmemory"),
		},
		Attendance: AttendanceConfig{
			DBPath: viper.GetString("attendance.dbpath"),
		},
	}

	return config, nil
}
