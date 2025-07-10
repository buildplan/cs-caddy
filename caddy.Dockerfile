# Stage 1: The Go builder environment
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Create a main.go file that imports Caddy and all the desired plugins
RUN tee main.go <<EOF
package main

import (
	caddycmd "github.com/caddyserver/caddy/v2/cmd"

	// Standard Caddy modules
	_ "github.com/caddyserver/caddy/v2/modules/standard"

	// CrowdSec Bouncer modules
	_ "github.com/hslatman/caddy-crowdsec-bouncer/appsec"
	_ "github.com/hslatman/caddy-crowdsec-bouncer/http"
	_ "github.com/hslatman/caddy-crowdsec-bouncer/layer4"
)

func main() {
	// This runs the Caddy command with our custom plugins.
	caddycmd.Main()
}
EOF

# Initialize a Go module and download all the necessary dependencies
RUN go mod init custom-caddy
RUN go mod tidy

# Build CS-Caddy binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -o /usr/bin/caddy \
    -ldflags "-w -s" .


# Stage 2: The final image
FROM caddy:latest

# Copy CS-Caddy binary from the builder stage,
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# Add Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 CMD caddy admin health
