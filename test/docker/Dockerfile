# Disposable Redmine 6.1 test harness for the Contracted plugin.
# The plugin itself is bind-mounted at /redmine/plugins/contracted at run time;
# only the core Redmine app + gems + core test DB are baked into the image.
FROM ruby:3.3-slim

ENV DEBIAN_FRONTEND=noninteractive
# Rails 7.2 wants a secret for some rake tasks; a fixed dummy is fine for test/CI.
ENV SECRET_KEY_BASE=ci_dummy_secret_key_base_0123456789_0123456789_0123456789

RUN apt-get update && apt-get install -y --no-install-recommends \
      git build-essential pkg-config \
      libsqlite3-dev sqlite3 \
      libyaml-dev zlib1g-dev \
      tzdata \
    && rm -rf /var/lib/apt/lists/*

ARG REDMINE_REF=6.1-stable
RUN git clone --depth 1 -b ${REDMINE_REF} https://github.com/redmine/redmine.git /redmine
WORKDIR /redmine

# sqlite3 for every env (no external DB needed)
COPY database.yml config/database.yml

RUN bundle config set --local without 'rmagick' \
 && bundle install --jobs 4 --retry 3

# Bake the core test schema + default data so test runs start fast.
RUN RAILS_ENV=test bin/rails db:create db:migrate \
 && RAILS_ENV=test REDMINE_LANG=en bin/rails redmine:load_default_data

CMD ["tail", "-f", "/dev/null"]
