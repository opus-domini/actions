# syntax=docker/dockerfile:1.12

ARG POSTGIS_IMAGE=postgis/postgis:18-3.6-alpine@sha256:4f8df0958dd321f520f917be5d0b338802928e4e1ebc4720f774168f4bbc2836
FROM ${POSTGIS_IMAGE}
ARG REVISION=unknown
ARG BUILD_DATE=1970-01-01T00:00:00Z
ARG SOURCE_DATE_EPOCH=0
ARG VERSION=dev
LABEL org.opencontainers.image.title="Opus Domini PostGIS CI service" \
      org.opencontainers.image.source="https://github.com/opus-domini/actions" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      io.opus-domini.source-date-epoch="${SOURCE_DATE_EPOCH}"
