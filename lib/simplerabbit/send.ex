defmodule SimpleRabbit.Send do
  def send(message, queue_name, exchange_name \\ "", publish_ops \\ []) do
    # dbg()

    with {:ok, connection} <- AMQP.Connection.open(),
         {:ok, channel} <- setToConfirm(connection),
         true <- checkNr(channel),
         {:ok, _queue} <- AMQP.Queue.declare(channel, queue_name),
         :ok <- AMQP.Basic.publish(channel, exchange_name, queue_name, message, publish_ops),
         true <- checkNr(channel),
         true <- confirmAll(channel),
         :ok <- AMQP.Connection.close(connection) do
      :ok
    else
      something -> {:miroError, something}
    end
  end

  defp setToConfirm(connection) do
    case AMQP.Channel.open(connection) do
      {:ok, channel} ->
        r = AMQP.Confirm.register_handler(channel, self())
        dbg(["setToConfirm register_handler", r])
        res = AMQP.Confirm.select(channel)
        dbg(["setToConfirm res", res])
        {:ok, channel}

      er ->
        er
    end
  end

  # def handle_info({:basic_ack, _channel, _tag, _multiple}, state) do
  def handle_info(a, b) do
    dbg(["handle_info basic_ack", a, b])
    {:noreply, b}
  end

  defp confirmAll(channel) do
    res = AMQP.Confirm.wait_for_confirms(channel, 5000)
    dbg(["confirmAll res", res])
    res
  end

  defp checkNr(channel) do
    res = AMQP.Confirm.next_publish_seqno(channel)
    dbg(["checkNr res", res])
    true
  end
end
