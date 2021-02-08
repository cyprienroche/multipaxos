
# cyprienroche 12 feb 2021

defmodule ScoutState do
  @enforce_keys [ :config, :leader, :acceptors, :ballot_num ]
  defstruct(
    config: Map.new,
    leader: nil,
    acceptors: MapSet.new,
    ballot_num: nil,
    wait_for: MapSet.new,
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
    %{ state | acceptors: MapSet.delete(state.wait_for, acceptor) }
  end # received_from

  def has_received_from_majority?(state) do
    MapSet.size(state.wait_for) < MapSet.size(state.acceptors) / 2
  end # has_received_from_majority

end # ScoutState

defmodule Scout do

def start config, leader, acceptors, ballot_num do
  send config.monitor, { :SCOUT_SPAWNED, config.node_num }
  for acceptor <- acceptors, do: send acceptor, { :P1A, self(), ballot_num }
  next ScoutState.new(config, leader, acceptors, ballot_num)
end # start

defp next state do
  receive do
    { :P1B, acceptor, ballot_num, pvalues } ->
      if ballot_num == state.ballot_num do
        state = ScoutState.add_pvalues(state, pvalues)
        state = ScoutState.stop_waiting_for(state, acceptor)
        if ScoutState.has_received_from_majority?(state) do
          send_adopted_to_leader(state)
          scout_exit(state)
        end # if
        next(state)
      else
        send state.leader, { :PREEMPTED, ballot_num }
        scout_exit(state)
      end # if
  end # receive
end # next

defp send_adopted_to_leader state do
  send state.leader, { :ADOPTED, state.ballot_num, state.pvalues }
end # send_adopted_to_leader

defp scout_exit state do
  send state.config.monitor,  { :SCOUT_FINISHED, state.config.node_num }
  Process.exit(self(), :normal)
end # scout_exit

end # Scout
