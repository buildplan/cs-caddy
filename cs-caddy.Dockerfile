FROM golang:1.24-alpine AS builder

WORKDIR /app

RUN go mod init custom-caddy

RUN go install \
    github.com/caddyserver/caddy/v2/cmd/caddy@latest \
    github.com/hslatman/caddy-crowdsec-bouncer/http@latest \
    github.com/hslatman/caddy-crowdsec-bouncer/layer4@latest \
    github.com/hslatman/caddy-crowdsec-bouncer/appsec@latest


FROM caddy:latest

COPY --from=builder /go/bin/caddy /usr/bin/caddy
