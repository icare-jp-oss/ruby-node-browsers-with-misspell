FROM cimg/ruby:3.0.5

LABEL maintainer="dev@icare.jpn.com"

USER root

WORKDIR /home/circleci
RUN curl -sSL https://git.io/misspell | bash \
    && sudo ln -s /home/circleci/bin/misspell /usr/local/bin/misspell

# prepare to debian version of chromium
RUN sudo echo "deb http://deb.debian.org/debian buster main" >> /etc/apt/sources.list \
    && sudo echo "deb http://deb.debian.org/debian buster-updates main" >> /etc/apt/sources.list \
    && sudo echo "deb http://deb.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list

RUN sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DCC9EFBF77E11517 \
    && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138 \
    && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50 \
    && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 112695A0E562B32A

ADD chromium.pref /etc/apt/preferences.d

# install node newer version for eslint
RUN wget https://nodejs.org/download/release/v16.20.2/node-v16.20.2-linux-x64.tar.xz \
    && tar Jxfv node-v16.20.2-linux-x64.tar.xz \
    && sudo cp node-v16.20.2-linux-x64/bin/node /usr/local/bin/ \
    && rm -rf node-v16.20.2-linux-x64 node-v16.20.2-linux-x64.tar.xz

RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
    && sudo apt update && sudo apt install yarn

RUN wget https://noto-website-2.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip \
    && mkdir -p ~/.fonts/noto \
    && unzip NotoSansCJKjp-hinted.zip NotoSansCJKjp-Regular.otf NotoSansCJKjp-Bold.otf -d ~/.fonts/noto/ \
    && fc-cache -v

RUN sudo apt-get update -qq --allow-releaseinfo-change \
    && sudo apt-get install -y \
    libgbm-dev \
    fonts-ipafont \
    fonts-liberation \
    chromium \
    chromium-driver

ENV TZ='Asia/Tokyo'
