# Stage 1: Build custom Caddy with CrowdSec bouncer
ARG GO_VERSION=1.25
FROM golang:${GO_VERSION}-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

# Create a main.go file that imports Caddy and all the desired plugins
RUN tee main.go <<EOF
package main

import (
	caddycmd "github.com/caddyserver/caddy/v2/cmd"

	_ "github.com/caddyserver/caddy/v2/modules/standard"
	_ "github.com/hslatman/caddy-crowdsec-bouncer/appsec"
	_ "github.com/hslatman/caddy-crowdsec-bouncer/http"
	_ "github.com/hslatman/caddy-crowdsec-bouncer/layer4"
)

func main() {
	caddycmd.Main()
}
EOF

# Initialize a Go module and download all the necessary dependencies
RUN go mod init custom-caddy && go mod tidy

# Build CS-Caddy binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -o /usr/bin/caddy \
    -ldflags "-w -s" .

# Final stage: Use upstream Caddy base image
FROM caddy:latest

# Copy CS-Caddy binary from the builder stage
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

LABEL org.opencontainers.image.title="cs-caddy" \
      org.opencontainers.image.description="Custom Caddy build with CrowdSec bouncer modules" \
      org.opencontainers.image.source="https://github.com/buildplan/cs-caddy"
