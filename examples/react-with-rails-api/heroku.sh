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

# Build Node client
(
  cd client
  export NODEJS_CHECK_SIGNATURES=no
  asdf_plugin_update nodejs https://github.com/asdf-vm/asdf-nodejs.git
  asdf install nodejs 11.10.0

  if [ -d "$cache/node_modules" ]; then
    mv "$cache/node_modules" .
  fi

  npm install --scripts-prepend-node-path
  npm run build --scripts-prepend-node-path
  cp -R dist/ ../server/public/
  mv node_modules "$cache"
)

# Build Ruby server
(
  cd server
  asdf_plugin_update ruby https://github.com/asdf-vm/asdf-ruby.git
  asdf install ruby 2.6.1

  gem install bundler:2.0.1 --no-document --conservative
  gem update --system --no-document
  asdf reshim ruby

  bundle config --delete frozen
  bundle install --without development:test --path="$(gem env gemdir)"
)

# Copy dependencies to the build
mkdir -p "$BUILD_DIR/tmp/cache"
cp -R "$ASDF_DATA_DIR" "$BUILD_DIR/tmp/cache/.asdf"

# Create script to load dependencies at runtime
mkdir -p "$BUILD_DIR/.profile.d"
touch "$BUILD_DIR/.profile.d/startup.sh"

cat >"$BUILD_DIR/.profile.d/startup.sh" <<EOL
  export ASDF_DATA_DIR="$HOME/tmp/cache/.asdf"
  export PATH="$ASDF_DATA_DIR/bin:$PATH:$ASDF_DATA_DIR/shims:$PATH"
  asdf global ruby 2.6.1
EOL
