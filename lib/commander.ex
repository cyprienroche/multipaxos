
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
    %{ state | acceptors: MapSet.delete(state.wait_for, acceptor) }
  end # received_from

  def has_received_from_majority?(state) do
    MapSet.size(state.wait_for) < MapSet.size(state.acceptors) / 2
  end # has_received_from_majority

end # CommanderState

defmodule Commander do

def start config, leader, acceptors, replicas, pvalue do
  config = Configuration.start_module(config, :commander)
  send config.monitor, { :COMMANDER_SPAWNED, config.node_num }
  for acceptor <- acceptors, do: send acceptor, { :P2A, self(), pvalue }
  next CommanderState.new(config, leader, acceptors, replicas, pvalue)
end # start

defp next state do
  receive do
    { :P2B, acceptor, ballot_num } ->
      if ballot_num == state.ballot_num do
        state = CommanderState.stop_waiting_for(state, acceptor)
        if CommanderState.has_received_from_majority?(state) do
          send_decision_to_repiclas(state)
        end # if
        next(state)
      else
        send state.leader, { :PREEMPTED, ballot_num }
        commander_exit(state)
      end # if
  end # receive
end # next

defp send_decision_to_repiclas state do
  { _ballot_num, slot, cmd } = state.pvalue
  for replica <- state.replicas do
    send replica, { :DECISION, slot, cmd }
  end # for
  commander_exit(state)
end # send_decision_to_repiclas

defp commander_exit state do
  send state.config.monitor,  { :COMMANDER_FINISHED, state.config.node_num }
  Process.exit(self(), :normal)
end # commander_exit

end # Commander
