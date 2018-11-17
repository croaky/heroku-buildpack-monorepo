# Heroku Buildpack: Monorepo

This buildpack has the following interface:

* A `BUILD_SUBDIR` Heroku config variable containing a relative path
  to the subdirectory of the app in the repo.
* A Bash script containing build commands,
  located at `$BUILD_SUBDIR/heroku.sh`.
* A manifest containing runtime commands,
  located at `$BUILD_SUBDIR/Procfile`.

In a [monorepo](https://www.statusok.com/monorepo),
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

Write a build script, `project2/heroku.sh`.
See the [React with Rails API](examples/react-with-rails-api/heroku.sh) example.

These [Heroku Buildpack API][api] environment variables
are available to the `heroku.sh` script:

* `BUILD_DIR`
* `CACHE_DIR`
* `ENV_DIR`

[api]: https://devcenter.heroku.com/articles/buildpack-api#bin-compile

Deploy:

```
git push heroku master
...
-----> Heroku receiving push
-----> Fetching custom buildpack
-----> Monorepo app detected
```
