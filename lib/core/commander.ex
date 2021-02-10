
# cyprienroche 12 feb 2021

defmodule Commander do

def start config, leader, acceptors, replicas, pvalue do
  config = Configuration.start_module(config, :commander)
  Debug.module_info(config, "\n--\nNew Commander for pvalue #{inspect pvalue}")
  send config.monitor, { :COMMANDER_SPAWNED, config.node_num }
  Debug.module_info(config, "Send pvalue #{inspect pvalue} to acceptors")
  # try to get our pvalue accepted . equivalent to 'accept' in Paxos
  for acceptor <- acceptors, do: send acceptor, { :P2A, self(), pvalue }
  next CommanderState.new(config, leader, acceptors, replicas, pvalue)
end # start

defp next state do
  Debug.module_info(state.config, "")
  receive do
    { :P2B, acceptor, ballot_num } ->
      Debug.module_info(state.config, "Received ballot_num #{inspect ballot_num} from acceptors")
      { our_ballot_num, _slot, _cmd } = state.pvalue
      if ballot_num == our_ballot_num do
        # our pvalue has been acknowledged by acceptor . equivalent to 'accepted' in Paxos
        state = CommanderState.stop_waiting_for(state, acceptor)
        if CommanderState.has_received_from_majority?(state) do
          # if we received from a majority of acceptors, we can move on . we won
          Debug.module_info(state.config, "Received ballot_num #{inspect ballot_num} from a majority of acceptors, send to replicas")
          send_decision_to_repiclas(state)
          commander_exit(state)
        end # if
        # else, wait until we get majority
        next(state)
      else
        # one acceptor did not allow our pvalue to be chosen for this round . Another leader was faster than us
        Debug.module_info(state.config, "Received ballot_num was not ours, send preempted to leader")
        send state.leader, { :PREEMPTED, ballot_num }
        commander_exit(state)
      end # if
  end # receive
end # next


# -------------- helper functions --------------


defp send_decision_to_repiclas state do
  { _ballot_num, slot, cmd } = state.pvalue
  for replica <- state.replicas do
    send replica, { :DECISION, slot, cmd }
  end # for
end # send_decision_to_repiclas

defp commander_exit state do
  Debug.module_info(state.config, "Commander exit\n--\n")
  send state.config.monitor,  { :COMMANDER_FINISHED, state.config.node_num }
  Process.exit(self(), :normal)
end # commander_exit

end # Commander
