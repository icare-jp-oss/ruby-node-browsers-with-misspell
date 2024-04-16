FROM cimg/ruby:3.2.3

ENV NODE_VERSION=18.20.2
ENV NVM_VERSION=0.39.7
ENV TZ='Asia/Tokyo'

LABEL maintainer="dev@icare.jpn.com"

USER root

WORKDIR /home/circleci

RUN curl -sSL https://git.io/misspell | bash \
    && sudo ln -s /home/circleci/bin/misspell /usr/local/bin/misspell

# prepare to debian version of chromium
RUN sudo echo "deb http://deb.debian.org/debian buster main" >> /etc/apt/sources.list \
    && sudo echo "deb http://deb.debian.org/debian buster-updates main" >> /etc/apt/sources.list \
    && sudo echo "deb http://deb.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list \
    && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DCC9EFBF77E11517 \
    && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138 \
    && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50 \
    && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 112695A0E562B32A

ADD chromium.pref /etc/apt/preferences.d

RUN wget https://noto-website-2.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip \
    && mkdir -p ~/.fonts/noto \
    && unzip NotoSansCJKjp-hinted.zip NotoSansCJKjp-Regular.otf NotoSansCJKjp-Bold.otf -d ~/.fonts/noto/ \
    && fc-cache -v

RUN sudo apt update -qq \
    && sudo apt-get install -y --no-install-recommends \
          libgbm-dev \
          fonts-ipafont \
          fonts-liberation \
          chromium \
          chromium-driver \
    && rm -rf /var/lib/apt/lists/*

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash \
    && echo 'export NVM_DIR="$HOME/.nvm"'                                       >> "$HOME/.bashrc" \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> "$HOME/.bashrc" \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion" # This loads nvm bash_completion' >> "$HOME/.bashrc" \
    && source $HOME/.nvm/nvm.sh \
    && nvm install ${NODE_VERSION} \
    && node -v \
    && npm -v
