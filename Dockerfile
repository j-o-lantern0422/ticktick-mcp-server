# syntax=docker/dockerfile:1
FROM ruby:3.4-alpine

RUN apk add --no-cache \
      build-base \
      ca-certificates \
      tzdata

RUN addgroup -S mcp && adduser -S mcp -G mcp

RUN gem install ticktick-mcp-server --no-document

USER mcp

CMD ["ticktick-mcp-server"]
