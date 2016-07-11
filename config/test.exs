use Mix.Config

config :logger, level: :warn

config :guardian, Guardian,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "Sentinel",
  ttl: { 30, :days },
  verify_issuer: true, # optional
  secret_key: "guardian_sekret",
  serializer: Sentinel.GuardianSerializer,
  hooks: GuardianDb,
  permissions: Application.get_env(:sentinel, :permissions)

config :guardian_db, GuardianDb,
  repo: Sentinel.TestRepo

config :sentinel,
  app_name: "Test App",
  user_model: Sentinel.User,
  email_sender: "test@example.com",
  crypto_provider: Comeonin.Bcrypt,
  repo: Sentinel.TestRepo,
  ecto_repos: [Sentinel.TestRepo],
  auth_handler: Sentinel.AuthHandler,
  user_view: Sentinel.UserView,
  error_view: SentinelTester.ErrorView,
  router: Sentinel.TestRouter,
  endpoint: Sentinel.Endpoint,
  send_emails: true

config :sentinel, Sentinel.Endpoint,
  secret_key_base: "sentinel_sekret"

config :sentinel, Sentinel.TestRepo,
  username: "postgres",
  password: "postgres",
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: "ecto://localhost/sentinel_test",
  size: 1,
  max_overflow: 0,
  priv: "test/support"

config :sentinel, Sentinel.Mailer,
  adapter: Bamboo.TestAdapter

config :bamboo, :refute_timeout, 10
