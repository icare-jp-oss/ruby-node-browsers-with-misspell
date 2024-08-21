# syntax=docker/dockerfile:1
FROM node:18.20.2-bullseye AS node

RUN npm update -g corepack

FROM cimg/ruby:3.2.3 AS ruby

ENV TZ='Asia/Tokyo'

USER root

RUN curl -sSL https://git.io/misspell | bash \
    && sudo ln -s /home/circleci/bin/misspell /usr/local/bin/misspell

# prepare to debian version of chromium
RUN <<EOF
  echo "deb http://deb.debian.org/debian buster main" >> /etc/apt/sources.list
  echo "deb http://deb.debian.org/debian buster-updates main" >> /etc/apt/sources.list
  echo "deb http://deb.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DCC9EFBF77E11517
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 112695A0E562B32A
EOF

ADD chromium.pref /etc/apt/preferences.d

RUN <<EOF
  wget https://noto-website-2.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip
  mkdir -p ~/.fonts/noto
  unzip NotoSansCJKjp-hinted.zip NotoSansCJKjp-Regular.otf NotoSansCJKjp-Bold.otf -d ~/.fonts/noto/
  fc-cache -v
EOF

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qq \
    && apt-get install -y --no-install-recommends \
          chromium \
          chromium-driver \
          fonts-ipafont \
          fonts-liberation \
          libgbm-dev

FROM ruby

LABEL maintainer="dev@icare.jpn.com"

WORKDIR /home/circleci

COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules/ /usr/local/lib/node_modules/
COPY --from=node /opt /opt/

RUN <<EOF
  ln -s /usr/local/bin/node /usr/local/bin/nodejs
  ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
  ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx
  ln -s /usr/local/lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack
  yarn_version=$(ls /opt | grep yarn-v | cut -d "-" -f 2)
  ln -s /opt/yarn-${yarn_version}/bin/yarn /usr/local/bin/yarn
  ln -s /opt/yarn-${yarn_version}/bin/yarnpkg /usr/local/bin/yarnpkg
  # smoke tests
  node --version
  npm --version
  yarn --version
  corepack --version
EOF

COPY <<-"EOT" /docker-entrypoint.sh
  set -e

  corepack enable

  exec "$@"
EOT

ENTRYPOINT ["bash", "/docker-entrypoint.sh"]
