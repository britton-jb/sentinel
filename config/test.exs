use Mix.Config

config :logger, level: :warn
config :sentinel, Sentinel.Endpoint,
  secret_key_base: "DOInS/rFmVWzmcHaoYAXX8moniIGldPCvtGcYv+GY5XE5xS8aQKRH4Aw6gDUmncd"

config :sentinel, Sentinel.TestRepo,
  username: "postgres",
  password: "postgres",
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: "ecto://localhost/sentinel_test",
  size: 1,
  max_overflow: 0,
  priv: "test/support"

config :bcrypt_elixir, :log_rounds, 4
# Only relevant to test ^^

config :sentinel, Sentinel.Guardian,
  issuer: "Sentinel",
  secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"

config :sentinel, Sentinel.Pipeline,
  module: Sentinel.Guardian,
  error_handler: Sentinel.AuthHandler

config :guardian_db, GuardianDb,
  repo: Sentinel.TestRepo

config :sentinel,
  otp_app: :sentinel, # should be your otp_app
  app_name: "Test App",
  user_model: Sentinel.User, # should be your generated model
  send_address: "test@example.com",
  repo: Sentinel.TestRepo, # should be your repo
  ecto_repos: [Sentinel.TestRepo],
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
  send_emails: true

config :sentinel, Sentinel.Mailer,
  adapter: Bamboo.TestAdapter

config :ueberauth, Ueberauth,
  providers: [
    identity: {
      Ueberauth.Strategy.Identity,
      [
        param_nesting: "user",
        callback_methods: ["POST"],
      ]
    },
    github: {
      Ueberauth.Strategy.Github,
      []
    }
  ]
