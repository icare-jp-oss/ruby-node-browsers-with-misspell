# ruby install
# FROM cimg/ruby:3.0.5
# TODO: cimg-ruby の配布イメージが jemalloc に対応されたらそのイメージから構築する
#       新しい Dockerfile.template では jemalloc となっているので今後のバージョンはそうなるはず

# 以下からのコピーです
# https://github.com/CircleCI-Public/cimg-ruby/blob/46fb83d41876206604891a6367f98674c284725a/Dockerfile.template
FROM cimg/base:2023.07

ENV RUBY_VERSION=3.0.5 \
	RUBY_MAJOR=3.0

RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
		autoconf \
		bison \
		dpkg-dev \
		# Rails dep
		ffmpeg \
		# until the base image has it
		libcurl4-openssl-dev \
		libffi-dev \
		libgdbm6 \
		libgdbm-dev \
		# Rails dep
		libmysqlclient-dev \
		libncurses5-dev \
		# Rails dep
		libpq-dev \
		libreadline6-dev \
		# install libsqlite3-dev until the base image has it
		# Rails dep
		libsqlite3-dev \
		libssl-dev \
		# Rails dep
		libxml2-dev \
		libyaml-dev \
		# Rails dep
		memcached \
		# Rails dep
		mupdf \
		# Rails dep
		mupdf-tools \
		# Rails dep
		imagemagick \
		# Rails dep
		sqlite3 \
		zlib1g-dev \
		# YJIT dep
		rustc \
		# Jemalloc
		libjemalloc-dev \
                # Build gems with Rust extensions dep
		clang-14 && \
	# For Ruby 3.0 install OpenSSL 1.1.1 to make it work on Ubuntu 20.04
	if [ "${RUBY_MAJOR}" == "3.0" ]; then \
		if [[ $(uname -m) == "x86_64" ]]; then \
			wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/openssl_1.1.1f-1ubuntu2_amd64.deb; \
			wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl-dev_1.1.1f-1ubuntu2_amd64.deb; \
			wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb; \
		else \
			wget http://ports.ubuntu.com/pool/main/o/openssl/openssl_1.1.1f-1ubuntu2_arm64.deb; \
			wget http://ports.ubuntu.com/pool/main/o/openssl/libssl-dev_1.1.1f-1ubuntu2_arm64.deb; \
			wget http://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_arm64.deb; \
		fi && \
		sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2*.deb; \
		sudo dpkg -i libssl-dev_1.1.1f-1ubuntu2*.deb; \
		sudo dpkg -i openssl_1.1.1f-1ubuntu2*.deb; \
		rm -f *.deb; \
	fi && \
	# Skip installing gem docs
	echo "gem: --no-document" > ~/.gemrc && \
	mkdir -p ~/ruby && \
	downloadURL="https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR}/ruby-$RUBY_VERSION.tar.gz" && \
	curl -sSL $downloadURL | tar -xz -C ~/ruby --strip-components=1 && \
	cd ~/ruby && \
	autoconf && \
	./configure --with-jemalloc --enable-yjit --enable-shared --disable-install-doc && \
	make -j "$(nproc)" && \
	sudo make install && \
	mkdir ~/.rubygems && \
	sudo rm -rf ~/ruby /var/lib/apt/lists/* && \
	cd && \

	ruby --version && \
	gem --version && \
	MAKEFLAGS=-j"$(nproc)" sudo gem update --system && \
	gem --version && \
	bundle --version && \

	# Cleanup YJIT install deps
	sudo apt-get remove rustc libstd-rust* libjemalloc-dev

ENV GEM_HOME /home/circleci/.rubygems
ENV PATH $GEM_HOME/bin:$BUNDLE_PATH/gems/bin:$PATH

# cimg-ruby の Dockerfile.template のコピーここまで

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
