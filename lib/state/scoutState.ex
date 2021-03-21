
defmodule ScoutState do
  @enforce_keys [ :config, :leader, :acceptors, :ballot_num ]
  defstruct(
    config: Map.new,
    leader: nil,
    acceptors: MapSet.new,
    wait_for: MapSet.new,
    ballot_num: nil,
    pvalues: MapSet.new)

	def new(config, leader, acceptors, ballot_num) do
		%ScoutState{
      config: config,
      leader: leader,
      acceptors: acceptors,
      ballot_num: ballot_num,
      wait_for: MapSet.new(acceptors) }
	end # new

  def add_pvalues(state, pvalues) do
    %{ state | pvalues: MapSet.union(state.pvalues, pvalues) }
  end # add_pvalue

  def stop_waiting_for(state, acceptor) do
    %{ state | wait_for: MapSet.delete(state.wait_for, acceptor) }
  end # received_from

  def has_received_from_majority?(state) do
    MapSet.size(state.wait_for) < MapSet.size(state.acceptors) / 2
  end # has_received_from_majority

end # ScoutState
