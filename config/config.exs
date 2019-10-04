use Mix.Config

# config :ex_aws,
#   access_key_id: [
#     {:system, "AWS_ACCESS_KEY_ID"},
#     {:awscli, "default", 30}
#   ],
#   secret_access_key: [
#     {:system, "AWS_SECRET_ACCESS_KEY"},
#     {:awscli, "default", 30}
#   ]

config :ex_aws, :sqs,
  access_key_id: "foo",
  secret_access_key: "bar",
  scheme: "http://",
  host: System.get_env("SQS_HOST", "localhost"),
  port: 9324,
  region: "elasticmq"

# config :dawdle,
#   backend: Dawdle.Backend.SQS

config :dawdle, Dawdle.Backend.SQS,
  region: "elasticmq",
  queue_url: "http://localhost:9324/queue/hippware-dawdle-test"

config :logger, level: :info
