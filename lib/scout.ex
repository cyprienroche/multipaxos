
# cyprienroche 12 feb 2021

defmodule ScoutState do
  @enforce_keys [ :config, :leader, :acceptors, :ballot_num ]
  defstruct(
    config: Map.new,
    leader: nil,
    acceptors: MapSet.new,
    ballot_num: nil,
    waitfor: MapSet.new,
    pvals: MapSet.new)

	def new(config, leader, acceptors, ballot_num) do
		%ScoutState{
      config: config,
      leader: leader,
      acceptors: acceptors,
      ballot_num: ballot_num,
      waitfor: MapSet.new(acceptors) }
	end # new

end # ScoutState

defmodule Scout do

def start config, leader, acceptors, ballot_num do
  send config.monitor, { :SCOUT_SPAWNED, config.node_num }
  # send p1a request to acceptors
  next ScoutState.new(config, leader, acceptors, ballot_num)
end # start

defp next state do
  receive do
    { :P1B, _from, _ballot_num, pvalue } ->
      pvalue
  end # receive

  next state
end # next

end # Scout
