defmodule Dawdle.Backend.SQSTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Mock

  alias Dawdle.Backend.SQS
  alias ExAws.Operation.Query
  alias Faker.Lorem

  setup_all do
    Dawdle.stop_pollers()
  end

  setup do
    {:ok, queue: SQS.queue()}
  end

  describe "send/1" do
    test "sending a single message" do
      message = Lorem.sentence()

      with_mock ExAws,
        request: fn %Query{
                      action: :send_message,
                      service: :sqs,
                      params: %{
                        "Action" => "SendMessage",
                        "MessageBody" => ^message
                      }
                    },
                    _ ->
          {:ok, "testing"}
        end do
        assert :ok = SQS.send(message)
      end
    end

    test "sending a single message when there is an error" do
      with_mock ExAws, request: fn _, _ -> {:error, :testing} end do
        assert capture_log(fn ->
                 assert {:error, :testing} = SQS.send(Lorem.sentence())
               end) =~ "{:error, :testing}"
      end
    end
  end

  describe "send_after/1" do
    test "sending a delayed message" do
      message = Lorem.sentence()

      with_mock ExAws,
        request: fn %Query{
                      action: :send_message,
                      service: :sqs,
                      params: %{
                        "Action" => "SendMessage",
                        "DelaySeconds" => 10,
                        "MessageBody" => ^message
                      }
                    },
                    _ ->
          {:ok, "testing"}
        end do
        assert :ok = SQS.send_after(message, 10)
      end
    end

    test "sending a delayed message when there is an error" do
      with_mock ExAws, request: fn _, _ -> {:error, :testing} end do
        assert capture_log(fn ->
                 assert {:error, :testing} =
                          SQS.send_after(Lorem.sentence(), 10)
               end) =~ "{:error, :testing}"
      end
    end
  end

  describe "recv/1" do
    test "receiving messages" do
      messages = [Lorem.sentence()]

      with_mock ExAws,
        request: fn %Query{
                      action: :receive_message,
                      service: :sqs,
                      params: %{
                        "Action" => "ReceiveMessage",
                        "MaxNumberOfMessages" => 10
                      }
                    },
                    _ ->
          {:ok, %{body: %{messages: messages}}}
        end do
        assert {:ok, messages} = SQS.recv()
      end
    end

    test "empty receives" do
      messages = [Lorem.sentence()]
      {:ok, agent} = Agent.start_link(fn -> true end)

      with_mock ExAws,
        request: fn %Query{
                      action: :receive_message,
                      service: :sqs,
                      params: %{
                        "Action" => "ReceiveMessage",
                        "MaxNumberOfMessages" => 10
                      }
                    },
                    _ ->
          if Agent.get(agent, & &1) do
            Agent.update(agent, fn _ -> false end)
            {:ok, %{body: %{messages: []}}}
          else
            {:ok, %{body: %{messages: messages}}}
          end
        end do
        assert {:ok, messages} = SQS.recv()
      end
    end

    test "receiving messages when there is an error" do
      with_mock ExAws, request: fn _, _ -> {:error, :testing} end do
        assert capture_log(fn ->
                 assert {:error, :testing} = SQS.recv()
               end) =~ "{:error, :testing}"
      end
    end
  end

  describe "delete/2" do
    test "deleting a message" do
      message = %{receipt_handle: 1}

      with_mock ExAws,
        request: fn %Query{
                      action: :delete_message,
                      service: :sqs,
                      params: %{
                        "Action" => "DeleteMessage",
                        "ReceiptHandle" => 1
                      }
                    },
                    _ ->
          {:ok, :testing}
        end do
        assert :ok = SQS.delete(message)
      end
    end

    test "deleting messages when there is an error" do
      message = %{receipt_handle: 1}

      with_mock ExAws, request: fn _, _ -> {:error, :testing} end do
        assert capture_log(fn ->
                 assert {:error, :testing} = SQS.delete(message)
               end) =~ "{:error, :testing}"
      end
    end
  end
end
