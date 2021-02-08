
# cyprienroche 12 feb 2021

defmodule LeaderState do
  @enforce_keys [ :config, :acceptors, :replicas, :ballot_num ]
  defstruct(
    config: Map.new,
    acceptors: MapSet.new,
    replicas: MapSet.new,
    ballot_num: nil,
    active: false,
    proposals: MapSet.new)

	def new(config, acceptors, replicas, ballot_num) do
		%LeaderState{
      config: config,
      acceptors: acceptors,
      replicas: replicas,
      ballot_num: ballot_num }
	end # new

end # LeaderState

defmodule Leader do

def start config do
  receive do
      { :BIND, acceptors, replicas } ->
        # spawn a Scout
        initial_ballot_num = { 0, self() }
        next LeaderState.new(config, acceptors, replicas, initial_ballot_num)
    end
end # start

defp next state do
  receive do
    { :PROPOSE, _slot, cmd } ->
      cmd

    { :ADOPTED, _ballot_num, pvals } ->
      pvals

    { :PREEMPTED, { _count, _from } = ballot_num } ->
      ballot_num
  end # receive
  next state
end # next

end # Leader
