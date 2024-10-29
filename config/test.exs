import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ai_course, AiCourseWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "thE5+DW11fV1seD6QsvWJP9ZK6sD0ojiZ9Y2VMb2YqY0Lq/wg+f7chTwsj21AK8/",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
