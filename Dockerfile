FROM circleci/ruby:2.6.8-node-browsers

LABEL maintainer="dev@icare.jpn.com"

WORKDIR /home/circleci
RUN curl -sSL https://git.io/misspell | bash \
    && sudo ln -s /home/circleci/bin/misspell /usr/local/bin/misspell

# install node newer version for eslint
RUN wget https://nodejs.org/download/release/v12.18.2/node-v12.18.2-linux-x64.tar.xz \
    && tar Jxfv node-v12.18.2-linux-x64.tar.xz \
    && sudo cp node-v12.18.2-linux-x64/bin/node /usr/local/bin/ \
    && rm -rf node-v12.18.2-linux-x64 node-v12.18.2-linux-x64.tar.xz

RUN wget https://noto-website-2.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip \
    && mkdir -p ~/.fonts/noto \
    && unzip NotoSansCJKjp-hinted.zip NotoSansCJKjp-Regular.otf NotoSansCJKjp-Bold.otf -d ~/.fonts/noto/ \
    && fc-cache -v

RUN sudo apt-get update -qq && sudo apt-get install -y libgbm-dev fonts-ipafont fonts-liberation

ENV TZ='Asia/Tokyo'
