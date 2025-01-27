
defmodule Database do

def start config do
  config = Configuration.start_module(config, :database)
  next config, Map.new, 0
end # start

defp next config, balances, db_seqnum do
  Debug.letter(config, "D")
  Debug.module_info(config, "")
  receive do
  { :EXECUTE, transaction } ->
    { :MOVE, amount, account1, account2 } = transaction
    Debug.module_info(config, "Received transaction #{inspect transaction}")

    balance1 = Map.get balances, account1, 0
    balances = Map.put balances, account1, balance1 + amount
    balance2 = Map.get balances, account2, 0
    balances = Map.put balances, account2, balance2 - amount

    send config.monitor, { :DB_UPDATE, config.node_num, db_seqnum+1, transaction }
    Debug.module_info(config, "Performed transaction #{inspect transaction}")
    next config, balances, db_seqnum+1

  unexpected ->
    Util.halt "Database: unexpected message #{inspect unexpected}"
  end # receive
end # next

end # Database
