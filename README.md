# Heroku Buildpack: Monorepo

This buildpack has the following interface:

* A `BUILD_SUBDIR` Heroku config variable containing a relative path
  to the subdirectory of the app in the repo.
* A Bash script containing build commands,
  located at `$BUILD_SUBDIR/heroku.sh`.
* A manifest containing runtime commands,
  located at `$BUILD_SUBDIR/Procfile`.

In a monorepo,
you might have multiple projects in subdirectories
that each could be deployed to Heroku:

```
.
├── project1
└── project2
    ├── Procfile
    └── client
        └── package.json
    ├── heroku.sh
    └── server
        └── Gemfile
```

Set a config var to tell Heroku which subdirectory the project is in:

```
heroku config:add BUILD_SUBDIR="project2"
```

Add this buildpack:

```
heroku buildpacks:add https://github.com/croaky/heroku-buildpack-monorepo.git
```

Write a build script, `project2/heroku.sh`:

```bash
#!/bin/bash

set -e

cache=${CACHE_DIR:-$HOME}

# ASDF
export ASDF_DATA_DIR="$cache/.asdf"
export PATH="$ASDF_DATA_DIR/bin:$ASDF_DATA_DIR/shims:$PATH"

if [ ! -d "$ASDF_DATA_DIR" ]; then
  git clone https://github.com/asdf-vm/asdf.git "$ASDF_DATA_DIR" --branch v0.6.0
fi

asdf_plugin_update() {
  if ! asdf plugin-list | grep -Fq "$1"; then
    asdf plugin-add "$1" "$2"
  fi

  asdf plugin-update "$1"
}

asdf_install() {
  asdf install "$1" "$2"
  asdf global "$1" "$2"
  asdf local "$1" "$2"
}

# Build Node client
export NODEJS_CHECK_SIGNATURES=no
asdf_plugin_update node https://github.com/asdf-vm/asdf-nodejs.git
asdf_install node 8.9.0

(
  cd client

  if [ -d "$cache/node_modules" ]; then
    mv "$cache/node_modules" .
  fi

  npm install --scripts-prepend-node-path
  npm run build --scripts-prepend-node-path
  cp -R public/ ../server/public/

  mv node_modules "$cache"
)

# Build  Ruby server
asdf_plugin_update ruby https://github.com/asdf-vm/asdf-ruby.git
asdf_install ruby 2.5.1
gem install bundler --no-document
asdf reshim ruby

(
  cd server
  bundle install --without development:test --path="$(gem env gemdir)"
)

# Copy dependencies
mkdir -p "$BUILD_DIR/tmp/cache"
cp -R "$ASDF_DATA_DIR" "$BUILD_DIR/tmp/cache/.asdf"

# Create startup script to load dependencies
mkdir -p "$BUILD_DIR/.profile.d"
touch "$BUILD_DIR/.profile.d/startup.sh"

cat >"$BUILD_DIR/.profile.d/startup.sh" <<EOL
  export ASDF_DATA_DIR="$HOME/tmp/cache/.asdf"
  export PATH="$ASDF_DATA_DIR/bin:$PATH:$ASDF_DATA_DIR/shims:$PATH"
  asdf global 2.5.1
  asdf reshim ruby
EOL
```

These environment variables are available to the script:

* `BUILD_DIR`
* `CACHE_DIR`
* `ENV_DIR`

See [Heroku Buildpack API](https://devcenter.heroku.com/articles/buildpack-api)
for more details on those variables.

In this example,
a React front-end is built and copied to
a Rails API `public/` directory,
to be served as static assets.

Deploy:

```
git push heroku master
...
-----> Heroku receiving push
-----> Fetching custom buildpack
-----> Monorepo app detected
```
