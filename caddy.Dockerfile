# Stage 1: Build custom Caddy with CrowdSec bouncer
ARG GO_VERSION=1.26
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS builder
ARG TARGETOS
ARG TARGETARCH

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

# Initialize the Go module
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod init custom-caddy

# Update the vulnerable GO modules flagged by Trivy/Dependabot scans
RUN --mount=type=cache,target=/go/pkg/mod \
    go get google.golang.org/grpc@latest \
    github.com/jackc/pgx/v5@latest \
    github.com/smallstep/certificates@latest \
    github.com/go-jose/go-jose/v3@latest \
    github.com/go-jose/go-jose/v4@latest \
    go.opentelemetry.io/otel@latest \
    go.opentelemetry.io/otel/sdk@latest \
    go.opentelemetry.io/otel/exporters/otlp/otlplog/otlploghttp@latest \
    go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp@latest \
    go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp@latest

RUN --mount=type=cache,target=/go/pkg/mod \
    go mod tidy

# Build CS-Caddy binary
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build \
    -o /usr/bin/caddy \
    -ldflags "-w -s" .

# Final stage: Use upstream Caddy base image
FROM caddy:latest

# Copy CS-Caddy binary from the builder stage
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

LABEL org.opencontainers.image.title="cs-caddy" \
      org.opencontainers.image.description="Custom Caddy build with CrowdSec bouncer modules" \
      org.opencontainers.image.source="https://github.com/buildplan/cs-caddy"
