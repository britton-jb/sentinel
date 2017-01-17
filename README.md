# Sentinel
[![Build Status][travis-img]][travis] [![Hex Version][hex-img]][hex]
[![License][license-img]][license]
[travis-img]: https://travis-ci.org/britton-jb/sentinel.svg?branch=master
[travis]: https://travis-ci.org/britton-jb/sentinel
[hex-img]: https://img.shields.io/hexpm/v/sentinel.svg
[hex]: https://hex.pm/packages/sentinel
[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

Things I wish [Guardian](https://github.com/ueberauth/guardian) included
out of the box. Routing, confirmation emails, password reset emails.
It's just a thin wrapper on Guardian buteverybody shouldn't have to repeat
this themselves when they build stuff.

I do my best to follow [semantic versioning](http://semver.org/) with this
repo.

Suggestions? See the `Contributing/Want something new?` section.

## Installation
Here's how to add it to your Phoenix project, and things you need to
setup:

```
def application do
  [mod: {MyApp, []},
   applications: [
     # ...
     :ueberauth]]
end

# mix.exs
{:sentinel, "~> 2.0"},

# If you'd like to database back your tokens, and prevent replayability
{:guardian_db, "~> 0.7.0"},
```

[FIXME](do i need to add sentinel and ueberauth etc to applications mix file?)

### Configure Guardian
Example config:

```
config :guardian, Guardian,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "MyApp",
  ttl: { 30, :days },
  verify_issuer: true, # optional
  secret_key: "guardian_sekret",
  serializer: Sentinel.GuardianSerializer,
  hooks: GuardianDb # optional if using guardiandb
```

[More info](https://github.com/ueberauth/guardian#installation)

#### Optionally Configure GuardianDb
```
config :guardian_db, GuardianDb,
  repo: MyApp.Repo
```

The install task which ships with Sentinel, which you will run later in
this walkthrough, creates the migration for the guardianDb tokens.

### Configure Sentinel
```
config :sentinel,
  app_name: "Test App",
  user_model: Sentinel.User, # should be your generated model
  send_address: "test@example.com",
  crypto_provider: Comeonin.Bcrypt,
  repo: Sentinel.TestRepo,
  ecto_repos: [Sentinel.TestRepo],
  auth_handler: Sentinel.AuthHandler,
  user_view: Sentinel.UserView,
  error_view: Sentinel.ErrorView,
  router: Sentinel.TestRouter, # your router
  endpoint: Sentinel.Endpoint, # your endpoint
  invitable: true,
  invitation_registration_url: "http://localhost:4000", # for api usage only
  confirmable: :optional,
  confirmable_redirect_url: "http://localhost:4000", # for api usage only
  password_reset_url: "http://localhost:4000", # for api usage only
  send_emails: true
```

See `config/test.exs` for an example of configuring Sentinel

### Configure Ueberauth
```
config :ueberauth, Ueberauth,
  providers: [
    identity: {
      Ueberauth.Strategy.Identity,
      [
        param_nesting: "user",
        callback_methods: ["POST"]
      ]
    },
  ]
```

### Configure Bamboo Mailer
```
config :sentinel, Sentinel.Mailer,
  adapter: Bamboo.TestAdapter
```

[More info](https://github.com/thoughtbot/bamboo/)


### Run the install Mix task

`mix sentinel.install`

This will create a user model if it doesn't already exist, add a
migration for GuardianDb migration, and add a migration for Ueberauth
provider credentials.

You may want to delete the GuardianDb migration if you're choosing not
to use it.

### Mount the desired routes
```elixir
defmodule MyApp.Router do
  use MyApp.Web, :router
  require Sentinel

  # ...
  # ...

  scope "/" do
    pipe_through :ueberauth
    Sentinel.mount_ueberauth
  end

  scope "/" do
    pipe_through :browser
    Sentinel.mount_html
  end

  scope "/api", as: :api do
    pipe_through :api
    Sentinel.mount_api
  end
end
```

You may run into an issue here if you set the scope to `scope "/",
MyApp.Router do`. Something to be aware of.

The generated routes are shown in `/lib/sentinel.ex`:

[######FIXME######](update routes)
method | path | description
-------|------|------------
POST | /api/users | register
POST | /api/users/:id/confirm | confirm account
POST | /api/users/:id/invited | set password on invited account
POST | /api/sessions | login, will return a token as JSON
DELETE |  /api/sessions | logout, invalidated the users current authentication token
POST | /api/password_resets | request a reset-password-email
POST | /api/password_resets/reset | reset a password
GET  | /api/account               | get information about the current user. at the moment this includes only the email address
PUT  | /api/account               | update the current users email or password

## Overriding the Defaults

### Confirmable
By default users are not required to confirm their account to login. If
you'd like to require confirmation set the `confirmable` configuration
field to `:required`. If you don't want confirmation emails sent, set
the field to `:false`. The default is `:optional`.

### Invitable
By default, users are required to have a password upon creation. If
you'd like to enable users to create accounts on behalf of other users
without a password you can set the `invitable` configuration field to
`true`. This will result in the user being sent an email with a link to
`GET users/:id/invited`, which you can complete by posting to the same
URL, with the following params:

json
```
{
  confirmation_token: confirmation_token_from_email_provided_as_url_param,
  password_reset_token: password_reset_token_from_email_provided_as_url_param,
  password: newly_defined_user_password
}
```

### Custom Routes
If you want to customize the routes, or use your own controller
endpoints you can do that by overriding the individual routes shown
below:

### Auth Error Handler
If you'd like to write your own custom authorization or authentication
handler change the `auth_handler` Sentinel configuration option
to the module name of your handler.

It must define two functions, `unauthorized/2`, and `unauthenticated/2`,
where the first parameter is the connection, and the second is
information about the session.

## Notes
2.0.0 attempted to utilize the semantic versioning tradition of
increasing the major version on breaking changes. There are many
breaking changes in this update.

## Contributing/Want something new?
Create an issue. Preferably with a PR. If you're super awesome
include tests.

As you recall from the license, this is provided as is. I don't make any
money on this, so I do support when I feel like it. That said, I want to
do my best to contribute to the Elixir/Phoenix community, so I'll do
what I can.

Having said that if you bother to put up a PR I'll take a look, and
either merge it, or let you know what needs to change before I do.
Having experienced sending in PRs and never hearing anything about
them, I know it sucks.
