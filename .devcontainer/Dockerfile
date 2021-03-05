FROM isabtra/rails-repo:v2

ARG BUNDLER_VERSION=2.1.4
ARG RAILS_VERSION=6.1.3

# Configure bundler
ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3

# Install required Bundler version
RUN gem install bundler:$BUNDLER_VERSION rails:$RAILS_VERSION webdrivers
