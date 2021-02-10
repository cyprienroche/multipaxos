
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

  def add_pvalues(state, pvalues) do
    %{ state | pvalues: MapSet.union(state.pvalues, pvalues) }
  end # add_pvalue

  def stop_waiting_for(state, acceptor) do
    %{ state | wait_for: MapSet.delete(state.wait_for, acceptor) }
  end # received_from

  def has_received_from_majority?(state) do
    MapSet.size(state.wait_for) < MapSet.size(state.acceptors) / 2
  end # has_received_from_majority

end # CommanderState
