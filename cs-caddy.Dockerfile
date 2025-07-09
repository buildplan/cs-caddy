# The Go builder environment
FROM golang:1.24-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Create a Go module to manage dependencies
RUN go mod init custom-caddy

# Download Caddy and the required CrowdSec bouncer plugins using 'go get'
RUN go get \
    github.com/caddyserver/caddy/v2/cmd/caddy \
    github.com/hslatman/caddy-crowdsec-bouncer/http \
    github.com/hslatman/caddy-crowdsec-bouncer/layer4 \
    github.com/hslatman/caddy-crowdsec-bouncer/appsec

# Build the custom Caddy binary.
RUN CGO_ENABLED=0 GOOS=linux go build \
    -o /usr/bin/caddy \
    -ldflags "-w -s" \
    github.com/caddyserver/caddy/v2/cmd/caddy

# The final, production-ready image
FROM caddy:latest

# Copy the custom-built Caddy binary from the builder stage
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
