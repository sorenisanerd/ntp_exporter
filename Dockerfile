FROM golang:1.21.4-alpine3.18 as builder

RUN apk add --no-cache --no-progress gcc git make musl-dev

COPY . /src
ARG BININFO_BUILD_DATE BININFO_COMMIT_HASH BININFO_VERSION # provided to 'make install'
RUN make -C /src install PREFIX=/pkg GOTOOLCHAIN=local GO_BUILDFLAGS='-mod vendor'

################################################################################

FROM alpine:3.18

RUN addgroup -g 4200 appgroup \
  && adduser -h /home/appuser -s /sbin/nologin -G appgroup -D -u 4200 appuser

# upgrade all installed packages to fix potential CVEs in advance
RUN apk upgrade --no-cache --no-progress \
  && apk add --no-cache --no-progress ca-certificates

COPY --from=builder /pkg/ /usr/

ARG BININFO_BUILD_DATE BININFO_COMMIT_HASH BININFO_VERSION
LABEL source_repository="https://github.com/sapcc/ntp_exporter" \
  org.opencontainers.image.url="https://github.com/sapcc/ntp_exporter" \
  org.opencontainers.image.created=${BININFO_BUILD_DATE} \
  org.opencontainers.image.revision=${BININFO_COMMIT_HASH} \
  org.opencontainers.image.version=${BININFO_VERSION}

USER 4200:4200
WORKDIR /home/appuser
ENTRYPOINT [ "/usr/bin/ntp_exporter" ]
