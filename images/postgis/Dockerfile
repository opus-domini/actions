# syntax=docker/dockerfile:1.12

ARG POSTGIS_IMAGE=postgis/postgis:16-3.5-alpine@sha256:40f6188236bda3c2a0d2365d415872fde2ccf6bc8b70ae481e093a845bb07b5d
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
