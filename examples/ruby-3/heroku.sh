#!/bin/bash

set -eo pipefail

# Prepare dependencies
cache=${CACHE_DIR:-$HOME}
export ASDF_DATA_DIR="$cache/.asdf"
export PATH="$ASDF_DATA_DIR/bin:$ASDF_DATA_DIR/shims:$PATH"

if [ ! -d "$ASDF_DATA_DIR" ]; then
  git clone https://github.com/asdf-vm/asdf.git "$ASDF_DATA_DIR"
fi

asdf_plugin_update() {
  if ! asdf plugin-list | grep -Fq "$1"; then
    asdf plugin-add "$1" "$2"
  fi

  asdf plugin-update "$1"
}

# Ruby 3
asdf_plugin_update "ruby" "https://github.com/asdf-vm/asdf-ruby"
# https://github.com/asdf-vm/asdf-ruby/pull/192
ASDF_RUBY_BUILD_VERSION=v20201225 asdf install ruby 3.0.0

gem install bundler:2.2.3 --no-document --conservative
gem update --system --no-document
asdf reshim ruby

bundle config --delete frozen
bundle install --without development:test --path="$(gem env gemdir)"

# Copy dependencies to the build
mkdir -p "$BUILD_DIR/tmp/cache"
cp -R "$ASDF_DATA_DIR" "$BUILD_DIR/tmp/cache/.asdf"

# Create script to load dependencies at runtime
mkdir -p "$BUILD_DIR/.profile.d"
touch "$BUILD_DIR/.profile.d/startup.sh"

cat >"$BUILD_DIR/.profile.d/startup.sh" <<EOL
  export ASDF_DATA_DIR="$HOME/tmp/cache/.asdf"
  export PATH="$ASDF_DATA_DIR/bin:$PATH:$ASDF_DATA_DIR/shims:$PATH"
  asdf global ruby 3.0.0
EOL
