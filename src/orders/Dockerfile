FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./  
# copying the dependencies
RUN go mod download  
# download the dependencies
COPY . .  
# copying the source code as it needs internal files which have dependencies
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/server ./cmd/server/main.go 
# compile everything into single binary file into the provided output by taking the main.go as input. Also those binaries can run on linux as we are generating the binaries from MAC.
FROM gcr.io/distroless/static-debian12 
# distroless image for the final stage which will not have any shell for running anything.
# important note:
#   When the Order Service connects to RDS in production over TLS, it needs CA certificates to verify the database server's identity. 
#   In distroless, these are actually included by default in static-debian12, so this works out of the box. 
#   But if you ever use scratch (completely empty) as the base, you'd need:
#   COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/server /server  
# copying the binary which will run without the GO runtime.
USER nonroot:nonroot  
# it is default nonroot user distroless has.
EXPOSE 8081
CMD ["/server"]