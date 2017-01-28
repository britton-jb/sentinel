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

config :guardian, Guardian,
  issuer: "Sentinel",
  secret_key: "guardian_sekret",
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  ttl: { 30, :days },
  verify_issuer: true, # optional
  serializer: Sentinel.GuardianSerializer,
  hooks: GuardianDb, # optional - only needed if using guardian db
  permissions: Application.get_env(:sentinel, :permissions)

# Only relevant to test ^^

config :sentinel,
  app_name: "Test App",
  user_model: Sentinel.User, #FIXME should be your generated model
  send_address: "test@example.com",
  crypto_provider: Comeonin.Bcrypt,
  repo: Sentinel.TestRepo, #FIXME should be your repo
  ecto_repos: [Sentinel.TestRepo],
  auth_handler: Sentinel.AuthHandler,
  user_view: Sentinel.UserView,
  error_view: Sentinel.ErrorView,
  router: Sentinel.TestRouter, #FIXME your router
  endpoint: Sentinel.Endpoint, #FIXME your endpoint
  invitable: true,
  invitation_registration_url: "http://localhost:4000", # for api usage only
  confirmable: :optional,
  confirmable_redirect_url: "http://localhost:4000", # for api usage only
  password_reset_url: "http://localhost:4000", # for api usage only
  send_emails: true

config :guardian_db, GuardianDb,
  repo: Sentinel.TestRepo #FIXME your repo

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
