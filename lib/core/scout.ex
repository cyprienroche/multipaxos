
# cyprienroche 12 feb 2021

defmodule Scout do

def start config, leader, acceptors, ballot_num do
  { count, _from } = ballot_num
  config = Configuration.start_module(config, :scout, "_ballot#{count}")
  Debug.module_info(config, "New Scout for ballot_num #{inspect ballot_num}")
  send config.monitor, { :SCOUT_SPAWNED, config.node_num }
  Debug.module_info(config, "Send ballot_num #{inspect ballot_num} to acceptors")
  # try to be the leader for this ballot_num . equivalent to 'prepare' in Paxos
  for acceptor <- acceptors, do: send acceptor, { :P1A, self(), ballot_num }
  next ScoutState.new(config, leader, acceptors, ballot_num)
end # start

defp next state do
  Debug.module_info(state.config, "")
  receive do
    { :P1B, acceptor, ballot_num, pvalues } ->
      Debug.module_info(state.config, "Received ballot_num #{inspect ballot_num} from acceptor")
      if ballot_num == state.ballot_num do
        # we have been acknowledged as the leader by acceptor . equivalent to 'promise' in Paxos
        state = ScoutState.add_pvalues(state, pvalues)
        state = ScoutState.stop_waiting_for(state, acceptor)
        if ScoutState.has_received_from_majority?(state) do
          # if we received from a majority of acceptors, we can move on . we won
          Debug.module_info(state.config, "Received ballot_num #{inspect ballot_num} from a majority of acceptors, send to leader")
          send_adopted_to_leader(state)
          scout_exit(state)
        end # if
        # else, wait until we get majority
        next(state)
      else
        # one acceptor did not allow us to be the leader for this round . There is another leader already
        Debug.module_info(state.config, "Received ballot_num was not ours, send preempted to leader")
        send state.leader, { :PREEMPTED, ballot_num }
        scout_exit(state)
      end # if
  end # receive
end # next


# -------------- helper functions --------------


defp send_adopted_to_leader state do
  send state.leader, { :ADOPTED, state.ballot_num, state.pvalues }
end # send_adopted_to_leader

defp scout_exit state do
  Debug.module_info(state.config, "Scout exit")
  send state.config.monitor,  { :SCOUT_FINISHED, state.config.node_num }
  Process.exit(self(), :normal)
end # scout_exit

end # Scout
