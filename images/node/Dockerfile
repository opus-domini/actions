# syntax=docker/dockerfile:1.12

ARG NODE_CI_IMAGE=node:26.10.0-bookworm@sha256:2aaae6d91f99fee84cfc92da9b52c22a185752d247746052bbc3f961e44478c6

FROM ${NODE_CI_IMAGE}
ARG NPM_CI_VERSION=12.2.1
ARG VITE_PLUS_VERSION=1.4.0
ARG REVISION=unknown
ARG BUILD_DATE=1970-01-01T00:00:00Z
ARG SOURCE_DATE_EPOCH=0
ARG VERSION=dev

RUN npm install --global "npm@${NPM_CI_VERSION}" "vite-plus@${VITE_PLUS_VERSION}" \
    && npm cache clean --force

LABEL org.opencontainers.image.title="Opus Domini Node CI runtime" \
      org.opencontainers.image.description="Pinned Node and Vite+ CI toolchain for trusted Ductor workloads" \
      org.opencontainers.image.source="https://github.com/opus-domini/actions" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      io.opus-domini.source-date-epoch="${SOURCE_DATE_EPOCH}"

ENV CI=true \
    npm_config_cache=/cache/npm \
    HOME=/home/ductor

WORKDIR /workspace
ENTRYPOINT []
CMD ["node", "--version"]
