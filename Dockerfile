FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    systemd systemd-sysv \
    ruby ruby-bundler \
    imagemagick webp \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Strip out unnecessary systemd units
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY . .

# Install systemd units
COPY systemd/ukho-tides.service /etc/systemd/system/
COPY systemd/ukho-tides.timer /etc/systemd/system/
RUN systemctl enable ukho-tides.timer

# Script to write env vars into the systemd environment file on startup
RUN mkdir -p /etc/ukho-tides && \
    printf '#!/bin/bash\n\
env | grep -E "^(ADMIRALTY_API_KEY|TIDBYT_DEVICE_ID|TIDBYT_API_TOKEN|STATION_ID|PUSH_INTERVAL)=" > /etc/ukho-tides/env\n\
if [ -n "$PUSH_INTERVAL" ]; then\n\
  mkdir -p /etc/systemd/system/ukho-tides.timer.d\n\
  printf "[Timer]\\nOnUnitActiveSec=%s\\n" "$PUSH_INTERVAL" > /etc/systemd/system/ukho-tides.timer.d/override.conf\n\
fi\n\
exec /lib/systemd/systemd\n' > /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/app/entrypoint.sh"]
