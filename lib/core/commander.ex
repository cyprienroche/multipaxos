
# cyprienroche 12 feb 2021

defmodule Commander do

def start config, leader, acceptors, replicas, pvalue do
  config = Configuration.start_module(config, :commander)
  Debug.module_info(config, "**** New Commander for pvalue #{inspect pvalue}")
  send config.monitor, { :COMMANDER_SPAWNED, config.node_num }
  Debug.module_info(config, "Send pvalue #{inspect pvalue} to acceptors")
  for acceptor <- acceptors, do: send acceptor, { :P2A, self(), pvalue }
  next CommanderState.new(config, leader, acceptors, replicas, pvalue)
end # start

defp next state do
  receive do
    { :P2B, acceptor, ballot_num } ->
      Debug.module_info(state.config, "Received ballot_num #{inspect ballot_num} from acceptors")
      { our_ballot_num, _slot, _cmd } = state.pvalue
      if ballot_num == our_ballot_num do
        Debug.module_info(state.config, "Received ballot_num was ours")
        state = CommanderState.stop_waiting_for(state, acceptor)
        if CommanderState.has_received_from_majority?(state) do
          Debug.module_info(state.config, "Received ballot_num #{inspect ballot_num} from a majority, send to leader")
          send_decision_to_repiclas(state)
          commander_exit(state)
        end # if
        next(state)
      else
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
  Debug.module_info(state.config, "**** Commander exit")
  send state.config.monitor,  { :COMMANDER_FINISHED, state.config.node_num }
  Process.exit(self(), :normal)
end # commander_exit

end # Commander
