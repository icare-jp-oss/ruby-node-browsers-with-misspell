# syntax=docker/dockerfile:1
FROM cimg/ruby:3.2.3

ENV NODE_VERSION=18.20.2
ENV NVM_VERSION=0.40.0
ENV NVM_DIR="/root/.nvm"
ENV TZ='Asia/Tokyo'

LABEL maintainer="dev@icare.jpn.com"

USER root

WORKDIR /home/circleci

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

RUN <<EOF
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash
  mkdir -p ${NVM_DIR}
  . ${NVM_DIR}/nvm.sh
  nvm install ${NODE_VERSION}
  node -v
  npm -v
  npm i -g yarn@1 corepack
  yarn -v
  corepack -v
EOF

COPY <<-"EOT" /docker-entrypoint.sh
  set -e

  [ -s "${NVM_DIR}/nvm.sh" ] && . ${NVM_DIR}/nvm.sh
  [ -s "${NVM_DIR}/bash_completion" ] && . ${NVM_DIR}/bash_completion

  exec "$@"
EOT

ENTRYPOINT ["bash", "/docker-entrypoint.sh"]
