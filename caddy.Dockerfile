# caddy.Dockerfile

# Stage 1: The Go builder environment
# Use a Go version that satisfies Caddy's requirements
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Create a main.go file that imports Caddy and all the desired plugins.
# The blank imports ( _ "..." ) are what register the plugins with Caddy.
# Using a multi-line RUN command with 'tee' to create the file.
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

# Initialize a Go module and download all the necessary dependencies.
RUN go mod init custom-caddy
RUN go mod tidy

# Build the custom Caddy binary.
# The -ldflags strip debug info, making the binary smaller.
RUN CGO_ENABLED=0 GOOS=linux go build \
    -o /usr/bin/caddy \
    -ldflags "-w -s" .

# ---

# Stage 2: The final, production-ready image
FROM caddy:latest

# Copy our custom-built Caddy binary from the builder stage,
# replacing the standard one.
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
