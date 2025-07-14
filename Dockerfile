# syntax=docker/dockerfile:1
FROM node:22.13.1-bullseye AS node

FROM cimg/ruby:3.3.5 AS ruby

ENV TZ='Asia/Tokyo'

USER root

RUN <<EOF
  curl -L -o ./install-misspell.sh https://git.io/misspell
  sh ./install-misspell.sh -b /usr/local/bin
  rm ./install-misspell.sh
EOF

# prepare to debian version of chromium
RUN <<EOF
  echo "deb http://deb.debian.org/debian bullseye main" >> /etc/apt/sources.list
  echo "deb http://deb.debian.org/debian bullseye-updates main" >> /etc/apt/sources.list
  echo "deb http://deb.debian.org/debian-security bullseye-security main" >> /etc/apt/sources.list
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DCC9EFBF77E11517
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 112695A0E562B32A
EOF

ADD chromium.pref /etc/apt/preferences.d

RUN <<EOF
  wget -q https://noto-website-2.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip
  mkdir -p ~/.fonts/noto
  unzip NotoSansCJKjp-hinted.zip NotoSansCJKjp-Regular.otf NotoSansCJKjp-Bold.otf -d ~/.fonts/noto/
  fc-cache -v
EOF

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qq \
    && apt-get install -y --no-install-recommends \
          fonts-ipafont \
          fonts-liberation \
          libgbm-dev \
          fonts-freefont-ttf \
          fonts-noto-color-emoji \
          fonts-tlwg-loma-otf \
          fonts-unifont \
          fonts-wqy-zenhei \
          libatk-bridge2.0-0 \
          libatk1.0-0 \
          libatk1.0-data \
          libatspi2.0-0 \
          libavahi-client3 \
          libavahi-common-data \
          libavahi-common3 \
          libcups2 \
          libfontenc1 \
          libice6 \
          libnspr4 \
          libnss3 \
          libsm6 \
          libxaw7 \
          libxcomposite1 \
          libxdamage1 \
          libxfont2 \
          libxkbfile1 \
          libxmu6 \
          libxmuu1 \
          libxpm4 \
          libxt6 \
          x11-xkb-utils \
          xauth \
          xfonts-cyrillic \
          xfonts-encodings \
          xfonts-scalable \
          xfonts-utils \
          xserver-common \
          xvfb \
    && apt-get autoremove -y

FROM ruby

LABEL maintainer="dev@icare-carely.co.jp"

WORKDIR /home/circleci

COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules/ /usr/local/lib/node_modules/
COPY --from=node /opt /opt/

RUN <<EOF
  ln -s /usr/local/bin/node /usr/local/bin/nodejs
  ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
  ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

  # smoke tests
  node --version
  npm --version

  # install pnpm
  npm i -g pnpm@10
  pnpm --version
EOF

COPY <<-"EOT" /docker-entrypoint.sh
  set -e

  exec "$@"
EOT

ENTRYPOINT ["bash", "/docker-entrypoint.sh"]
