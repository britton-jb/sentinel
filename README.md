#### FIXME don't push notes
- README DOCUMENT :sentinel, :send_emails, ecto 2 syntax changes,
  overriding Sentinel.EmailView and Sentinel.EmailLayoutView, other old
  stuff/general doc update, applying custom layouts via the router plug
- creedo
- update changelog

## done
- lots of general codebase cleanup
- instances of rendering pure json for user render
- 403 to 401 specs update
- Make email handling case insensitive on login

# Sentinel
[![Build
Status](https://travis-ci.org/britton-jb/sentinel.svg?branch=master)](https://travis-ci.org/britton-jb/sentinel)

Things I wish [Guardian](https://github.com/ueberauth/guardian) included
out of the box. Routing, confirmation emails, password reset emails.
It's just a thin wrapper on Guardian buteverybody shouldn't have to repeat
this themselves when they build stuff.

Suggestions? See the `Contributing/Want something new?` section.

## Installation
Here's how to add it to your phoenix project, and things you need to
setup:

```
# mix.exs
{:sentinel, "~> 0.1.0"},

# If you'd like to database back your tokens, and prevent replayability
{:guardian_db, "~> 0.4.0"},

# Add mailman as a peer dependency
#{:mailman, "~> 0.2.1"}
# OR
#{:mailman, github: "Joe-noh/mailman"}
```

### The User Model
Your user model must have at least the following fields, and the
`permissions/1` function must be defined, in order to encode permissions
into your token, currently even if the function is empty, and you don't
plan on using [Guardian
permissions](https://github.com/ueberauth/guardian/#permissions).

```elixir
defmodule MyApp.User do
  use Ecto.Model

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

  def changeset(model, params \\ :empty) do
    model
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

### Configure Mailman
```
# Local server example
config :mailman,
  port: 1234

# Mailgun Example
config :mailman,
  port: 587,
  address: "smtp.mailgun.org",
  user_name: System.get_env("MAILGUN_USERNAME"),
  password: System.get_env("MAILGUN_PASSWORD")

# Mandrill Example
config :mailman,
  port: 587,
  address: "smtp.mandrillapp.com",
  user_name: System.get_env("MANDRILL_USERNAME"),
  password: System.get_env("MANDRILL_PASSWORD")
```

[More info](https://github.com/kamilc/mailman/)

### Routes
Add the following to your routes file to add default routes, complete
with protection

```elixir
defmodule MyApp.Router do
  use MyApp.Web, :router
  require Sentinel

  scope "/api" do
    pipe_through :api

    Sentinel.mount
  end
end
```

The generated routes are:

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

### Mailer Customization/I18n
You setup your own email templates to send out by configuring the
`mailman` `html_email_tempaltes` and `text_email_templates` config
variables to point to your own email template directories.

Internationalization is easy. Just make a folder for each langauge under
your email template directory. Pass in the language to your mailer
config

### Auth Error Handler
If you'd like to write your own custom authorization or authentication
handler change the `auth_handler` Sentinel configuration option
to the module name of your handler.

It must define two functions, `unauthorized/2`, and `unauthenticated/2`,
where the first parameter is the connection, and the second is
information about the session.

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

## TODO
- HTML Views
- README DOCUMENT :sentinel, :send_emails, ecto 2 syntax changes,
  overriding Sentinel.EmailView and Sentinel.EmailLayoutView, other old
  stuff/general doc update, applying custom layouts via the router plug
