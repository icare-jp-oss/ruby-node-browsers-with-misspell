FROM circleci/ruby:2.6.5-node-browsers

WORKDIR /home/circleci
RUN curl -L -o ./install-misspell.sh https://git.io/misspell
RUN bash install-misspell.sh
RUN sudo ln -s /home/circleci/bin/misspell /usr/local/bin/misspell

# install node newer version for eslint
RUN wget https://nodejs.org/download/release/v13.9.0/node-v13.9.0-linux-x64.tar.xz
RUN tar Jxfv node-v13.9.0-linux-x64.tar.xz
RUN sudo cp node-v13.9.0-linux-x64/bin/node /usr/local/bin/
