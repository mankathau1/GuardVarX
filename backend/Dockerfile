# Multi-stage Dockerfile for GuardVarX Go Backend
FROM golang:1.24-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git ca-certificates tzdata

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /guardvarx-api cmd/api/main.go

# Production minimal scratch image
FROM alpine:3.20

RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/

COPY --from=builder /guardvarx-api .
COPY --from=builder /app/migrations ./migrations

EXPOSE 8080

CMD ["./guardvarx-api"]
