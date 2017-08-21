# Sentinel
[![Build Status](https://travis-ci.org/britton-jb/sentinel.svg?branch=master)](https://travis-ci.org/britton-jb/sentinel)

## Note
Currently master (this readme) and the latest hex release have diverged due
to poor planning on my part while working on the next version of
Sentinel. It also currently interacts poorly with the new directory
structure of Phoenix 1.3. I'm currently working on an update to remedy
this, but cannot promise it will be released soon.

If you'd like to assist in developing the latest version of Sentinel
please reach out to me.

Things I wish [Guardian](https://github.com/ueberauth/guardian) included
out of the box, like [Ueberauth](
https://github.com/ueberauth/ueberauth) integration, routing,
invitation flow, confirmation emails, and, password reset emails.
It's just a thin wrapper on Guardian but everybody shouldn't have to roll
this themselves when they build stuff.

I do my best to follow [semantic versioning](http://semver.org/) with this
repo.

Suggestions? See the [Contributing/Want something new?](#contributingwant-something-new)
section.

Want an example app? Checkout [Sentinel
Example](https://github.com/britton-jb/sentinel_example).

## Installation

Here's how to add it to your Phoenix project, and things you need to
setup:

``` elixir
# mix.exs

# Requires Elixir ~> 1.3

defp deps do
  # ...
  {:sentinel, "~> 2.0"},
  {:guardian_db, "~> 0.8.0"}, # If you'd like to database back your tokens, and prevent replayability
  # ...
end
```

### Configure Guardian
Example config:

``` elixir
# config/config.exs

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
``` elixir
config :guardian_db, GuardianDb,
  repo: MyApp.Repo
```

The install task which ships with Sentinel, which you will run later in
this walkthrough, creates the migration for the GuardianDb tokens.

### Configure Sentinel
``` elixir
# config/config.exs

config :sentinel,
  app_name: "Test App",
  user_model: Sentinel.User, # should be your generated model
  send_address: "test@example.com",
  crypto_provider: Comeonin.Bcrypt,
  repo: Sentinel.TestRepo,
  ecto_repos: [Sentinel.TestRepo],
  auth_handler: Sentinel.AuthHandler,
  layout_view: MyApp.Layout, # your layout
  layout: :app,
  views: %{
    email: Sentinel.EmailView, # your email view (optional)
    error: Sentinel.ErrorView, # your error view (optional)
    password: Sentinel.PasswordView, # your password view (optional)
    session: Sentinel.SessionView, # your session view (optional)
    shared: Sentinel.SharedView, # your shared view (optional)
    user: Sentinel.UserView # your user view (optional)
  },
  router: Sentinel.TestRouter, # your router
  endpoint: Sentinel.Endpoint, # your endpoint
  invitable: true,
  invitation_registration_url: "http://localhost:4000", # for api usage only
  confirmable: :optional,
  confirmable_redirect_url: "http://localhost:4000", # for api usage only
  password_reset_url: "http://localhost:4000", # for api usage only
  send_emails: true,
  user_model_validator: {MyApp.Accounts, :custom_changeset}, # your custom validator
  registrator_callback: {MyApp.Accounts, :setup} # your callback function (optional)
```

See `config/test.exs` for an example of configuring Sentinel

`invitation_registration_url`, `confirmable_redirect_url`, and
`password_reset_url` are three configuration settings that must be set
if using the API routing in order to have some place to be directed to
after completing the relevant server action. In most cases I'd
anticipate this being a page of a SPA, Mobile App, or other client
interface.

### Configure Ueberauth
``` elixir
# config/config.exs

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

Currently Sentinel is designed in such a way that the Identity Strategy
must set `params_nesting` as `"user"`. This is something that I would
like to modify in future versions.

You'd also want to add other Ueberauth provider configurations at this
point, as described in the respective provider documentation.

### Configure Bamboo Mailer
``` elixir
# config/config.exs

config :sentinel, Sentinel.Mailer,
  adapter: Bamboo.TestAdapter
```

[More info](https://github.com/thoughtbot/bamboo/)


### Run the install Mix task
Create the database using Ecto if it doesn't yet exist.

``` elixir
mix sentinel.install
```

This will create a user model if it doesn't already exist, add a
migration for GuardianDb migration, and add a migration for Ueberauth
provider credentials.

You will want to delete the GuardianDb migration if you're choosing not
to use it.

Currently the install task outputs the following warning:

```
warning: the :datetime type in migrations is deprecated, please use
:utc_datetime or :naive_datetime instead
```

This is due to the fact that Phoenix's generators don't appear to
support `utc_datetime` being passed in. Please modify the generated
migration accordingly. Phoenix's generators also appear to not support
setting `null: false` with the migration generator, so you will want
to set that in the migration for the user email as well.

### Mount the desired routes
```elixir
defmodule MyApp.Router do
  use MyApp.Web, :router
  require Sentinel

  # ...
  # ...

  scope "/" do
    # pipe_through, browser, api, or your own pipeline depending on your needs
    # pipe_through :browser
    # pipe_through :api
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

Be aware that the routes mounted by the macro `Sentinel.mount_ueberauth`
must be mounted on the root of your URL, due to the way Ueberauth
matches against routes.
To illustrate, the route for requesting a given provider must be
`example.com/auth/:provider`. If it is `example.com/api/auth/:provider`
Ueberauth will not properly register requests.

**NOTE:** You will run into an issue here if you set the scope to
`scope "/", MyApp.Router do`.

The generated routes are shown in `/lib/sentinel.ex`:

#### Sentinel.mount_ueberauth

method | path | description
-------|------|------------
GET | /login | Login page
GET | /logout | Request logout
GET | /auth/session/new | Login page
POST | /auth/session | Request authentication
DELETE | /auth/session | Request logout
GET | /auth/:provider | Request specific Ueberauth provider login page
GET | /auth/:provider/callback | Callback URL for Ueberauth provider
POST | /auth/:provider/callback | Callback URL for Ueberauth provider

#### Sentinel.mount_html

method | path | description
-------|------|------------
GET | /user/new | New user page
POST | /user | Create new user
GET | /user/:id/invited | Invited user registration form
PUT | /user/:id/invited | Complete user invitation flow
GET | /user/confirmation_instructions | Request resending confirmation instructions page
POST | /user/confirmation_instructions | Request confirmation instructions email
GET | /user/confirmation | Confirm user email address from email
GET | /password/new | Forgot password page
POST | /password/new | Request password reset email
GET | /password/edit | Password reset page
PUT | /password | Reset password
GET | /account | Basic user edit page
PUT | /account | Update user information

#### Sentinel.mount_api

method | path | description
-------|------|------------
GET | /user/:id/invited | Redirect user from email link to invited user registration form
PUT | /user/:id/invited | Complete user invitation flow
GET | /user/confirmation_instructions | Request resending confirmation instructions
GET | /user/confirmation | Confirm user email address from email
GET | /password/new | Request password reset email
GET | /password/edit | Request password reset page from email
PUT | /password | Reset password
GET | /account | Requests user account
PUT | /account | Update user information
PUT | /account/password | Update user password separately

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

``` json
{
  "confirmation_token": "confirmation_token_from_email_provided_as_url_param",
  "password_reset_token": "password_reset_token_from_email_provided_as_url_param",
  "password": "newly_defined_user_password"
}
```

### Custom Routes
If you want to customize the routes, or use your own controller
endpoints you can do that by overriding the individual routes listed.

### Generate custom views
If you want to use custom views, you'll need copy over the views and templates
to your application. Sentinel provides a mix task make this a one-liner:

```shell
mix sentinel.gen.views
```

This mix task accepts a single argument of the specific context. This value can
be "email", "error", "password", "session", "shared", or "user". Once you copy
over a context's view and templates, you must update the config to point to
your application's local files:

```json
config :sentinel, views: %{user: MyApp.Web.UserView}
```

The keys for this views config map correspond with the list of contexts above.

### Auth Error Handler
If you'd like to write your own custom authorization or authentication
handler change the `auth_handler` Sentinel configuration option
to the module name of your handler.

It must define two functions, `unauthorized/2`, and `unauthenticated/2`,
where the first parameter is the connection, and the second is
information about the session.

### Custom model validator
If you want to add custom changeset validations to the user model, you can do
that by specifying a user model validator: 

```elixir
config :sentinel, user_model_validator: {MyApp.Accounts, :custom_changeset}
```
This function must accept 2 arguments consisting of a changeset and a map of
params and *must* return a changeset. The params in the second argument will be
the raw params from the original request (not the ueberauth callback params).

```elixir
def custom_changeset(changeset, attrs \\ %{}) do
  changeset
  |> cast(attrs, [:my_attr])
  |> validate_required([:my_attr])
  |> validate_inclusion(:my_attr, ["foo", "bar"])
end
```

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
