FROM circleci/ruby:2.6.5-node-browsers

LABEL maintainer="dev@icare.jpn.com"

WORKDIR /home/circleci
RUN curl -sSL https://git.io/misspell | bash \
    && sudo ln -s /home/circleci/bin/misspell /usr/local/bin/misspell

# install node newer version for eslint
RUN wget https://nodejs.org/download/release/v12.18.2/node-v12.18.2-linux-x64.tar.xz \
    && tar Jxfv node-v12.18.2-linux-x64.tar.xz \
    && sudo cp node-v12.18.2-linux-x64/bin/node /usr/local/bin/ \
    && rm -rf node-v12.18.2-linux-x64 node-v12.18.2-linux-x64.tar.xz
