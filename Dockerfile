# syntax=docker/dockerfile:1
FROM node:22.22.2-bullseye AS node

FROM cimg/ruby:3.3.5 AS ruby

ENV TZ='Asia/Tokyo'

USER root

RUN <<EOF
  curl -L -o /tmp/misspell.tar.gz https://github.com/client9/misspell/releases/download/v0.3.4/misspell_0.3.4_linux_64bit.tar.gz
  tar -xzf /tmp/misspell.tar.gz -C /usr/local/bin misspell
  rm /tmp/misspell.tar.gz
  misspell -v
EOF

# Debian 11 の Chromium 関連パッケージを入れる。
# Debian 11 LTS は 2026-08-31 に終了し、bullseye-security の InRelease は
# 以降更新されない。ビルド中だけ Valid-Until を無視し、インストール後に
# Debian 11 ソースを削除する。実行時の apt-get update
# (Playwright --with-deps) は Ubuntu jammy だけを見る。
RUN <<EOF
  echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until
  cat > /etc/apt/sources.list.d/debian-bullseye.list <<'SRC'
deb http://deb.debian.org/debian bullseye main
deb http://deb.debian.org/debian bullseye-updates main
deb http://deb.debian.org/debian-security bullseye-security main
SRC
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6ED0E7B82643E131
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 605C66F00D6C9793
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 54404762BBB6E853
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BDE6D2B9216EC7A8
EOF

ADD chromium.pref /etc/apt/preferences.d

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

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

# 実行時の apt-get update が期限切れ InRelease で失敗しないよう、
# EOL になった Debian 11 ソースを取り除く。
# sources.list へ追記した古いレイヤが残る場合も消す。
RUN <<EOF
  rm -f /etc/apt/sources.list.d/debian-bullseye.list \
        /etc/apt/apt.conf.d/99no-check-valid-until
  sed -i '/deb.debian.org/d' /etc/apt/sources.list
EOF

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
