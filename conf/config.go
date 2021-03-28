package conf

import (
	"github.com/spf13/viper"
)

type Configuration struct {
	// ElasticSearch
	ES_USER_MAPPING string
	ES_TASK_MAPPING string
	BOOTSTRAP_FILE  string

	// WorkStation
	WS_API_PORT  string
	WS_GRPC_HOST string
	WS_GRPC_PORT string

	// WorkStation_ElasticSearch
	WS_ES_HOST string
	WS_ES_PORT string

	// JWT
	JWT_SIGNIN_KEY       string
	TOKEN_DURATION_HOURS int

	Dev bool `json:"dev"`
}

func GetConfig() (Configuration, error) {
	cf := Configuration{}
	err := viper.Unmarshal(&cf)
	if err != nil {
		return cf, err
	}
	return cf, nil
}
