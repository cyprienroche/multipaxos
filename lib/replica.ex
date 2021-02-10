
# cyprienroche 12 feb 2021

defmodule ReplicaState do
  @enforce_keys [ :config, :database, :leaders ]
  defstruct(
    config: Map.new,
    database: nil,
    leaders: MapSet.new,
    slot_in: 1,
    slot_out: 1,
    requests: [],
    proposals: Map.new,
    decisions: Map.new)

	def new(config, database, leaders) do
		%ReplicaState{
      config: config,
      database: database,
      leaders: leaders }
	end # new

  def add_request(state, cmd) do
    %{ state | requests: [ cmd | state.requests ] }
  end # add_request

  def add_decision(state, slot, cmd) do
    %{ state | decisions: Map.put(state.decisions, slot, cmd) }
  end # add_request

  def has_no_pending_requests?(state) do
    Enum.empty?(state.requests)
  end # has_no_pending_requests?

  def has_already_made_decision_for_slot?(state, slot) do
    Map.has_key?(state.decisions, slot)
  end # has_already_made_decision_for_slot?

  def increment_slot_in(state) do
    %{ state | slot_in: state.slot_in + 1 }
  end # increment_slot_in

  def pop_request(state) do
    [ cmd | requests ] = state.requests
    { cmd, %{ state | requests: requests } }
  end # pop_request

  def add_proposal(state, slot, cmd) do
    %{ state | proposals: Map.put(state.proposals, slot, cmd) }
  end # add_proposal

  def has_no_decisions_to_perform?(state) do
    not Map.has_key?(state.decisions, state.slot_out)
  end # has_no_decisions_to_perform

  def is_not_proposal?(state, slot) do
    not Map.has_key?(state.proposals, slot)
  end # is_proposal

  def remove_proposal(state, slot) do
    %{ state | proposals: Map.delete(state.proposals, slot) }
  end # remove_proposal

  def increment_slot_out(state) do
    %{ state | slot_out: state.slot_out + 1 }
  end # increment_slot_out

  def has_not_yet_performed_cmd?(state, slot, cmd) do
    Enum.empty?(Enum.filter(state.decisions,
      fn { s, cmd2 } -> s < slot and cmd == cmd2 end))
  end # has_not_yet_performed_cmd?

end # ReplicaState

defmodule Replica do

def start config, database do
  config = Configuration.start_module(config, :replica)
  receive do
      { :BIND, leaders } ->
        next ReplicaState.new(config, database, leaders)
    end
end # start

defp next state do
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

defp propose state do
  if ReplicaState.has_no_pending_requests?(state) do
    Debug.module_info(state.config, "No more proposals to propose to leaders")
    state
  else
    if ReplicaState.has_already_made_decision_for_slot?(state, state.slot_in) do
      Debug.module_info(state.config, "Already received a decision for slot #{state.slot_in}")
      state = ReplicaState.increment_slot_in(state)
      propose state
    else
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
    # then slot_out is not a key inside the decisions map
    Debug.module_info(state.config, "No more decisions to perform")
    state
  else
    slot = state.slot_out
    cmd = state.decisions[slot]
    if ReplicaState.is_not_proposal?(state, slot) do
      Debug.module_info(state.config, "We never proposed a command for slot #{slot}")
      state = perform state, slot, cmd
      decide state
    else
      cmd_proposed = state.proposals[slot]
      state = ReplicaState.remove_proposal(state, slot)
      state = case cmd do
        ^cmd_proposed ->
          Debug.module_info(state.config, "Our proposal #{inspect cmd_proposed} for slot #{slot} was accepted")
          state
        _otherwise    ->
          Debug.module_info(state.config, "Our proposal #{inspect cmd_proposed} for slot #{slot} was not accepted, will propose again")
          ReplicaState.add_request(state, cmd_proposed)
      end # case
      state = perform state, slot, cmd
      decide state
    end # if
  end # if
end # decide

defp perform state, slot, cmd do
  if ReplicaState.has_not_yet_performed_cmd?(state, slot, cmd) do
    Debug.module_info(state.config, "Performing #{inspect cmd} for slot #{slot} and sending :ok to client")
    { client, id, transaction } = cmd
    send state.database, { :EXECUTE,  transaction }
    send client, { :CLIENT_REPLY, id, :ok }
  end # if
  ReplicaState.increment_slot_out(state)
end # perform

end # Replica
