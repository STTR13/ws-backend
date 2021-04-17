RUN = docker run --rm --user $$(id -u):$$(id -g)
PROTOC = $(RUN) -v "$$PWD:$$PWD" -w "$$PWD" namely/protoc
PROTOLOCK = $(RUN) -v $$PWD:/protolock -w /protolock nilslice/protolock

EXE = ./ws-backend
GRAPHQL_FILES = graph/schema.resolvers.go
SRC_FILES = $(wildcard *.go) \
            $(wildcard */*.go)
# PROTO_FILES = $(wildcard proto/*.proto)
PB_FILES = $(patsubst proto/%.proto,proto/%.pb.go,$(wildcard proto/*.proto))

# SSL Certificate info
SSL_INFO = "/CN=localhost"
#SSL_INFO = "/C=FR/ST=./L=Paris/O=42ai/CN=localhost"

FLAG ?= ""

all: $(GRAPHQL_FILES) $(PB_FILES) lint $(EXE)

$(EXE): $(SRC_FILES)
	go build -o $(EXE)

$(GRAPHQL_FILES): graph/schema.graphqls
	go run github.com/99designs/gqlgen generate

proto/%.pb.go: proto.lock proto/%.proto
	$(PROTOLOCK) commit
	$(PROTOC) -I=./proto --go_out=plugins=grpc:. proto/$*.proto

proto.lock:
	$(PROTOLOCK) init

.PHONY: lint
lint:
	go fmt ./...
	go vet ./...

.PHONY: gql
gql: all
	$(EXE) run gql $(FLAG)

.PHONY: grpc
grpc: all
	$(EXE) run grpc $(FLAG)

.PHONY: elastic
elastic:
	docker-compose config -q
	docker-compose rm -svf
	docker-compose up -d

.PHONY: down
down:
	docker-compose down
	docker-compose rm -svf

.PHONY: ssl
ssl:
	openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
		-subj $(SSL_INFO) \
		-addext "subjectAltName = DNS:localhost" \
		-keyout server.key  -out server.cert
	openssl req -new -sha256 -key server.key -out server.csr \
		-addext "subjectAltName = DNS:localhost" \
		-subj $(SSL_INFO)
	openssl x509 -req -sha256 -in server.csr -signkey server.key \
				   -out server.crt -days 365