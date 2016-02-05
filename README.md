# Sentinel
Things I wish [Guardian](https://github.com/ueberauth/guardian) included
out of the box. Routing, confirmation emails, password reset emails.
It's really just a thin wrapper on Guardian, and some ground work, but
really, everybody shouldn't have to repeat this themselves when they
build stuff.

Shamelessly borrows from
[Devise](https://github.com/plataformatec/devise) and
[PhoenixTokenAuth](https://github.com/manukall/phoenix_token_auth).

If there are any ways that you feel that this library isn't "functional"
or the code isn't written in "idiomatic Elixir" or whatever see the
`Contributing/Want something new?` section.

## Installation
Here's how to add it to your phoenix project, and things you need to
setup:

```
# mix.exs
{:sentinel, "~> 0.0.3"},

# Add mailman as a peer dependency
#{:mailman, "~> 0.2.1"}
# OR
#{:mailman, github: "Joe-noh/mailman"}
```

### The User Model
Your user model must have at least the following fields, email needs to
be included.

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
  confirmable: :required, # possible options {:false, :required, :optional},optional config
  endpoint: MyApp.Endpoint,
  router: MyApp.Router
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
POST | /api/session | login, will return a token as JSON
DELETE |  /api/session | logout, invalidated the users current authentication token
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

### Custom Routes
If you want to customize the routes, or use your own controller
endpoints you can do that by overriding the individual routes shown
below:

```elixir
post  "users",                 Sentinel.Controllers.Users, :create
post  "users/:id/confirm",     Sentinel.Controllers.Users, :confirm
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
Ueberauth integration

Add a mix tasks that does all the configuration? and one that includes
the user model and router stuff for a fresh, fresh project.

Status 201 instead of 200 in created?

Username based confirmation issue?

Mailer subject I18n

## Still on the Roadmap
Session/View vs JWT/API configuration

Multiple Model types (user, admin)

[Devise lockable](http://rubydoc.info/github/plataformatec/devise/master/Devise/Models/Lockable) equivalent

[Devise
trackable](http://rubydoc.info/github/plataformatec/devise/master/Devise/Models/Trackable) equivalent

[Devise
timeout-able](http://rubydoc.info/github/plataformatec/devise/master/Devise/Models/Timeoutable) equivalent
