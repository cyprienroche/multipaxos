
# cyprienroche 12 feb 2021

defmodule Replica do

def start config, database do
  config = Configuration.start_module(config, :replica)
  receive do
      { :BIND, leaders } ->
        next ReplicaState.new(config, database, leaders)
    end
end # start

defp next state do
  Debug.module_info(state.config, "")
  receive do
    { :CLIENT_REQUEST, cmd } ->
      Debug.module_info(state.config, "Received cmd #{inspect cmd}")
      send state.config.monitor, { :CLIENT_REQUEST, state.config.node_num }
      ReplicaState.add_request(state, cmd) |>
      propose |> next

    { :DECISION, slot, cmd } ->
      Debug.module_info(state.config, "Received decision #{inspect cmd} for slot #{slot}")
      ReplicaState.add_decision(state, slot, cmd) |>
      decide |> propose |> next
  end # receive
end # next


# -------------- helper functions --------------


defp propose state do
  if ReplicaState.has_no_pending_requests?(state) do
    Debug.module_info(state.config, "No more proposals to propose to leaders")
    state
  else
    # have pending requests to propose
    if ReplicaState.has_already_made_decision_for_slot?(state, state.slot_in) do
      # decision already made for index slot_in, cannot propose for that slot
      Debug.module_info(state.config, "Decision already made for #{state.slot_in}, cannot propose for that slot")
      state = ReplicaState.increment_slot_in(state)
      propose state
    else
      # no decisions made for index slot_in, propose for that slot
      { cmd, state } = ReplicaState.pop_request(state)
      state = ReplicaState.add_proposal(state, state.slot_in, cmd)
      Debug.module_info(state.config, "Proposing #{inspect cmd} for slot #{state.slot_in}")
      for leader <- state.leaders do
        send leader, { :PROPOSE, state.slot_in, cmd }
      end # for
      state = ReplicaState.increment_slot_in(state)
      propose state
    end # if
  end # if
end # propose

defp decide state do
  if ReplicaState.has_no_decisions_to_perform?(state) do
    # no decisions to perform at index slot_out
    Debug.module_info(state.config, "No more decisions to perform")
    state
  else
    # perform decision at index slot_out
    slot = state.slot_out
    cmd = state.decisions[slot]
    if ReplicaState.is_not_proposal?(state, slot) do
      # never proposed a command for this slot, simply perform
      Debug.module_info(state.config, "We never proposed a command for slot #{slot}")
      state = perform state, cmd
      decide state
    else
      # proposed for this slot in the past
      cmd_proposed = state.proposals[slot]
      state = ReplicaState.remove_proposal(state, slot)
      # check if our proposal for this slot was accepted
      state = case cmd do
        ^cmd_proposed ->
          Debug.module_info(state.config, "Our proposal #{inspect cmd_proposed} for slot #{slot} was accepted")
          state
        _otherwise    ->
          Debug.module_info(state.config, "Our proposal #{inspect cmd_proposed} for slot #{slot} was not accepted, will propose again")
          ReplicaState.add_request(state, cmd_proposed)
      end # case
      # perform the decision
      state = perform state, cmd
      decide state
    end # if
  end # if
end # decide

defp perform state, cmd do
  if ReplicaState.has_not_performed_cmd?(state, cmd) do
    # update the database/state machine and send response to client
    Debug.module_info(state.config, "Performing #{inspect cmd} for slot #{state.slot_out} and sending :ok to client")
    { client, id, transaction } = cmd
    send state.database, { :EXECUTE,  transaction }
    send client, { :CLIENT_REPLY, id, :ok }
  end # if
  ReplicaState.increment_slot_out(state)
end # perform

end # Replica
