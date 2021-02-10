
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
    %{ state | wait_for: MapSet.delete(state.wait_for, acceptor) }
  end # received_from

  def has_received_from_majority?(state) do
    MapSet.size(state.wait_for) < MapSet.size(state.acceptors) / 2
  end # has_received_from_majority

end # ScoutState

defmodule Scout do

def start config, leader, acceptors, ballot_num do
  config = Configuration.start_module(config, :scout)
  Debug.module_info(config, "**** New Scout for ballot_num #{inspect ballot_num}")
  send config.monitor, { :SCOUT_SPAWNED, config.node_num }
  Debug.module_info(config, "Send ballot_num #{inspect ballot_num} to acceptors")
  for acceptor <- acceptors, do: send acceptor, { :P1A, self(), ballot_num }
  next ScoutState.new(config, leader, acceptors, ballot_num)
end # start

defp next state do
  receive do
    { :P1B, acceptor, ballot_num, pvalues } ->
      Debug.module_info(state.config, "Received ballot_num #{inspect ballot_num} from acceptor #{inspect acceptor}")
      if ballot_num == state.ballot_num do
        Debug.module_info(state.config, "Received ballot_num was ours")
        state = ScoutState.add_pvalues(state, pvalues)
        state = ScoutState.stop_waiting_for(state, acceptor)
        if ScoutState.has_received_from_majority?(state) do
          Debug.module_info(state.config, "Received ballot_num #{inspect ballot_num} from a majority of acceptors, send to leader")
          send_adopted_to_leader(state)
          scout_exit(state)
        else
          Debug.module_info(state.config, "Did not receive ballot_num #{inspect ballot_num} from a majority of acceptors yet")
          Debug.module_info(state.config, "Waiting for #{MapSet.size(state.wait_for)} out of #{MapSet.size(state.acceptors)} acceptors")
        end # if
        next(state)
      else
        Debug.module_info(state.config, "Received ballot_num was not ours, send preempted to leader")
        send state.leader, { :PREEMPTED, ballot_num }
        scout_exit(state)
      end # if
  end # receive
end # next

defp send_adopted_to_leader state do
  send state.leader, { :ADOPTED, state.ballot_num, state.pvalues }
end # send_adopted_to_leader

defp scout_exit state do
  Debug.module_info(state.config, "**** Scout exit")
  send state.config.monitor,  { :SCOUT_FINISHED, state.config.node_num }
  Process.exit(self(), :normal)
end # scout_exit

end # Scout
