FROM ruby:3.3-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    imagemagick webp \
    build-essential \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY . .

CMD ["ruby", "bin/loop"]
