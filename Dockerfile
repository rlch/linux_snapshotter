FROM --platform=amd64 ubuntu:latest

WORKDIR /app

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  ca-certificates \
  clang cmake git \
  ninja-build pkg-config \
  libgtk-3-dev liblzma-dev \
  x11-apps imagemagick \
  libstdc++-12-dev
RUN apt-get install -y --no-install-recommends \
  curl git unzip xz-utils zip libglu1-mesa

RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:${PATH}"
RUN flutter channel stable
RUN flutter config --enable-linux-desktop

COPY . .
RUN flutter clean
RUN flutter pub get
RUN flutter build linux --target-platform=linux-x64 --release
RUN mv /app/build/linux/x64/release/bundle /app

WORKDIR /app
ENV DISPLAY=xvfb:99
CMD [ "/app/bundle/linux_snapshotter" ]
