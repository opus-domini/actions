# syntax=docker/dockerfile:1.12

ARG RUSTFS_IMAGE=rustfs/rustfs:latest@sha256:60f4f2f41ce95216f8cac676e69f9d90c0bfec458a3bc7fd7fb9b7c2452ac57a
FROM ${RUSTFS_IMAGE}
ARG REVISION=unknown
ARG BUILD_DATE=1970-01-01T00:00:00Z
ARG SOURCE_DATE_EPOCH=0
ARG VERSION=dev
LABEL org.opencontainers.image.title="Opus Domini RustFS CI service" \
      org.opencontainers.image.source="https://github.com/opus-domini/actions" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      io.opus-domini.source-date-epoch="${SOURCE_DATE_EPOCH}"
