use Mix.Config

config :logger, level: :warn

config :sentinel, Sentinel.Mailer,
  adapter: Bamboo.TestAdapter,
  html_email_templates: "lib/sentinel/templates/",
  text_email_templates: "lib/sentinel/templates/"

config :sentinel, Sentinel.Guardian,
  issuer: "Sentinel",
  secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"

config :sentinel, Sentinel.Pipeline,
  module: Sentinel.Guardian,
  error_handler: Sentinel.AuthHandler

config :guardian_db, GuardianDb,
  repo: Sentinel.TestRepo,
  schema_name: "guardian_tokens", # default
  sweep_interval: 60 # default: 60 minutes

config :sentinel,
  otp_app: :sentinel, # should be your otp_app
  app_name: "Test App",
  user_model: Sentinel.User, # should be your generated model
  send_address: "test@example.com",
  crypto_provider: Comeonin.Bcrypt,
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
