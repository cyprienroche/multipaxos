
# cyprienroche 12 feb 2021

defmodule CommanderState do
  @enforce_keys [ :config, :leader, :acceptors, :replicas, :pvalue ]
  defstruct(
    config: Map.new,
    leader: nil,
    acceptors: MapSet.new,
    replicas: MapSet.new,
    pvalue: nil,
    wait_for: MapSet.new)

	def new(config, leader, acceptors, replicas, pvalue) do
		%CommanderState{
      config: config,
      leader: leader,
      acceptors: acceptors,
      replicas: replicas,
      pvalue: pvalue,
      wait_for: MapSet.new(acceptors) }
	end # new

end # CommanderState

defmodule Commander do

def start config, leader, acceptors, replicas, pvalue do
  send config.monitor, { :COMMANDER_SPAWNED, config.node_num }
  
  next CommanderState.new(config, leader, acceptors, replicas, pvalue)
end # start

defp next state do
  receive do
    { :P2B, _from, ballot_num } ->
      ballot_num
  end # receive

  next state
end # next

end # Commander
