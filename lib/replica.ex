
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

  def has_performed_cmd_before?(state, slot, cmd) do
    Enum.empty?(Enum.filter(state.decisions,
      fn { s, cmd2 } -> s < slot and cmd == cmd2 end))
  end # has_performed_cmd_before?

  def has_not_yet_performed_cmd?(state, slot, cmd) do
    not has_performed_cmd_before?(state, slot, cmd)
  end # has_not_yet_performed_cmd?

end # ReplicaState

defmodule Replica do

def start config, database do
  receive do
      { :BIND, leaders } ->
        next ReplicaState.new(config, database, leaders)
    end
end # start

defp next state do
  receive do
    { :CLIENT_REQUEST, cmd } ->
      send state.config.monitor, { :CLIENT_REQUEST, state.config.node_num }
      ReplicaState.add_request(state, cmd) |>
      propose |> next

    { :DECISION, slot, cmd } ->
      ReplicaState.add_decidison(state, slot, cmd) |>
      decide |> propose |> next
  end # receive
end # next

defp propose state do
  if ReplicaState.has_no_pending_requests?(state) do
    Debug.module_info(state.config, "Replica #{state.config.node_num} has no proposals", :replica)
    state
  else
    if ReplicaState.has_already_made_decision_for_slot?(state, state.slot_in) do
      Debug.module_info(state.config, "Replica #{state.config.node_num} already received a decision for #{state.slot_in}", :replica)
      state = ReplicaState.increment_slot_in(state)
      propose state
    end # if
    { cmd, state } = ReplicaState.pop_request(state)
    state = ReplicaState.add_proposal(state, state.slot_in, cmd)
    Debug.module_info(state.config, "Replica #{state.config.node_num} proposing #{inspect cmd} at slot #{state.slot_in}", :replica)
    for leader <- state.leaders do
      send leader, { :PROPOSE, state.slot_in, cmd }
    end # for
    state = ReplicaState.increment_slot_in(state)
    propose state
  end # if
end # propose

defp decide state do
  if ReplicaState.has_no_decisions_to_perform?(state) do
    # then slot_out is not a key inside the decisions map
    Debug.module_info(state.config, "Replica #{state.config.node_num} has no decision to perform", :replica)
    decide state
  else
    slot = state.slot_out
    cmd = state.decisions[slot]
    if ReplicaState.is_not_proposal?(state, slot) do
      state = perform state, slot, cmd
      decide state
    else
      cmd_proposed = state.proposals[slot]
      state = ReplicaState.remove_proposal(state, slot)
      state = case cmd do
        ^cmd_proposed -> state
        _otherwise    -> ReplicaState.add_request(state, cmd_proposed)
      end # case
      state = perform state, slot, cmd
      decide state
    end # if
  end # if
end # decide

defp perform state, slot, cmd do
  if ReplicaState.has_not_yet_performed_cmd?(state, slot, cmd) do
    Debug.module_info(state.config, "Replica #{state.config.node_num} performs #{inspect cmd} at slot #{slot}", :replica)
    { client, id, transaction } = cmd
    send state.database, { :EXECUTE,  transaction }
    send client, { :CLIENT_REPLY, id, :ok }
  end # if
  ReplicaState.increment_slot_out(state)
end # perform

end # Replica
