# Sentinel
[![Build Status][travis-img]][travis] [![Hex Version][hex-img]][hex]
[![License][license-img]][license]
[travis-img]: https://travis-ci.org/britton-jb/sentinel.svg?branch=master
[travis]: https://travis-ci.org/britton-jb/sentinel
[hex-img]: https://img.shields.io/hexpm/v/sentinel.svg
[hex]: https://hex.pm/packages/sentinel
[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

#### FIXME vv
- add view for password edit html

- manually test
- add specs for html stuff that fails

- update the README
#### END FIXME ^^

Things I wish [Guardian](https://github.com/ueberauth/guardian) included
out of the box. Routing, confirmation emails, password reset emails.
It's just a thin wrapper on Guardian buteverybody shouldn't have to repeat
this themselves when they build stuff.

I do my best to follow [semantic versioning](http://semver.org/) with this
repo.

This will likely be going through some serious changes, and was likley
incremented to 1.0.0 prematurely. Part of why the semantic versioning is
important. I currently utilize Sentinel, but
would say that you should handle it with care, especially the
HTML section, as noted below.

Suggestions? See the `Contributing/Want something new?` section.

## Installation
Here's how to add it to your Phoenix project, and things you need to
setup:

```
# mix.exs
{:sentinel, "~> 2.0"},

# If you'd like to database back your tokens, and prevent replayability
{:guardian_db, "~> 0.7.0"},
```

### The User Model
Your user model must have at least the following fields, and the
`permissions/1` function must be defined, in order to encode permissions
into your token, currently even if the function is empty, and you don't
plan on using [Guardian
permissions](https://github.com/ueberauth/guardian/#permissions).

# FIXME make this into the generated user model
```
t.string :email,              null: false, default: ""
t.string :encrypted_password, null: false, default: ""

## Recoverable
t.string   :reset_password_token
t.datetime :reset_password_sent_at

## Rememberable
t.datetime :remember_created_at

## Trackable
t.integer  :sign_in_count, default: 0, null: false
t.datetime :current_sign_in_at
t.datetime :last_sign_in_at
t.inet     :current_sign_in_ip
t.inet     :last_sign_in_ip

## Confirmable
t.string   :confirmation_token
t.datetime :confirmed_at
t.datetime :confirmation_sent_at
t.string   :unconfirmed_email # Only if using reconfirmable
t.datetime :confirmation_reminder_sent_at

## Lockable
t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
t.string   :unlock_token # Only if unlock strategy is :email or :both
t.datetime :locked_at

## Invitable
t.string :invitation_token
t.datetime :invitation_sent_at

t.timestamps null: false
```

```elixir
defmodule MyApp.User do
  use Ecto.Schema

  schema "users" do
    field  :email,                       :string     # or :username
    field  :role,                        :string
    field  :hashed_password,             :string
    field  :hashed_confirmation_token,   :string
    field  :confirmed_at,                Ecto.DateTime
    field  :hashed_password_reset_token, :string
    field  :unconfirmed_email,           :string
  end

  @required_fields ~w(email)
  @optional_fields ~w()

  def changeset(struct, params \\ :empty) do
    struct
    |> cast(params, @required_fields, @optional_fields)
  end

  def permissions(role) do
  end
end
```

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
  hooks: GuardianDb
```

[More info](https://github.com/ueberauth/guardian#installation)

### Configure GuardianDb
```
config :guardian_db, GuardianDb,
  repo: MyApp.Repo
```

The database backing for your tokens:

```elixir
defmodule MyApp.Repo.Migrations.GuardianDb do
  use Ecto.Migration

  def up do
    create table(:guardian_tokens, primary_key: false) do
      add :jti, :string, primary_key: true
      add :typ, :string
      add :aud, :string
      add :iss, :string
      add :sub, :string
      add :exp, :bigint
      add :jwt, :text
      add :claims, :map
      timestamps
    end
  end

  def down do
    drop table(:guardian_tokens)
  end
end
```

[More info](https://github.com/hassox/guardian_db)

### Configure Sentinel
```
config :sentinel,
  app_name: "Test App",
  user_model: MyApp.User,
  email_sender: "test@example.com",
  crypto_provider: Comeonin.Bcrypt,
  auth_handler: Sentinel.AuthHandler, #optional
  repo: MyApp.Repo,
  confirmable: :required, # possible options {:false, :required, :optional}, optional config, defaulting to :optional
  invitable: :required, # possible options {:false, :true}, optional config, defaulting to false
  endpoint: MyApp.Endpoint,
  router: MyApp.Router,
  user_view: MyApp.UserModel.View,
  environment: :development
```

See `config/test.exs` for more current examples of configuring Sentinel

### Configure Bamboo
[More info](https://github.com/thoughtbot/bamboo/)

### Routes
Add the following to your routes file to add default routes, complete
with protection

```elixir
defmodule MyApp.Router do
  use MyApp.Web, :router
  require Sentinel

  scope "/" do
    pipe_through :browser

    Sentinel.mount_html
  end

  scope "/api" do
    pipe_through :api

    Sentinel.mount_api
  end
end
```

The generated routes are shown in `/lib/sentinel.ex`:

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

You may run into an issue here if you set the scope to `scope "/api",
MyApp.Router do`. Something to be aware of.

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

Note that the `invitable` module requires you to provide your own setup
your password form at `GET UserController :invited`. In the future when
Sentinel ships with views it's something I'd like to include. I would
gladly take PRs for some basic server rendered html forms.

### Custom Routes
If you want to customize the routes, or use your own controller
endpoints you can do that by overriding the individual routes shown
below:

```elixir
post  "users",                 Sentinel.Controllers.Users, :create
post  "users/:id/confirm",     Sentinel.Controllers.Users, :confirm
post  "users/:id/invited",     Sentinel.Controllers.Users, :invited
post  "sessions", Sentinel.Controllers.Sessions, :create
delete  "sessions", Sentinel.Controllers.Sessions, :delete
post  "password_resets", Sentinel.Controllers.PasswordResets, :create
post  "password_resets/reset", Sentinel.Controllers.PasswordResets, :reset
get   "account",               Sentinel.Controllers.Account, :show
put   "account",               Sentinel.Controllers.Account, :update
```

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

Currently the HTML portion needs some serious TLC. I jumped the gun
trying to release it one weekend. Use it, as with the rest of the
library at your own risk. Any PRs to help shape it up are appreciated.
In the meantime if you need a strong Elixir auth library that provides
great HTML take a look at
[Coherence](https://github.com/smpallen99/coherence).

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
