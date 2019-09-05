use Mix.Config

config :ex_aws,
  access_key_id: [
    {:system, "AWS_ACCESS_KEY_ID"},
    {:awscli, "default", 30}
  ],
  secret_access_key: [
    {:system, "AWS_SECRET_ACCESS_KEY"},
    {:awscli, "default", 30}
  ]

# config :dawdle,
#   backend: Dawdle.Backend.SQS

config :dawdle, Dawdle.Backend.SQS,
  region: "us-west-2",
  queue_url:
    "https://sqs.us-west-2.amazonaws.com/XXXXXXXXXXXX/hippware-dawdle-test"

config :logger, level: :info
