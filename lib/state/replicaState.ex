
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

  # -- requests functions --

  def add_request(state, cmd) do
    %{ state | requests: [ cmd | state.requests ] }
  end # add_request

  def pop_request(state) do
    [ cmd | requests ] = state.requests
    { cmd, %{ state | requests: requests } }
  end # pop_request

  def has_pending_requests?(state) do
    not Enum.empty?(state.requests)
  end # has_pending_requests?

  def has_no_pending_requests?(state) do
    not has_pending_requests?(state)
  end # has_no_pending_requests?

  # -- proposals functions --

  def add_proposal(state, slot, cmd) do
    %{ state | proposals: Map.put(state.proposals, slot, cmd) }
  end # add_proposal

  def remove_proposal(state, slot) do
    %{ state | proposals: Map.delete(state.proposals, slot) }
  end # remove_proposal

  def is_proposal?(state, slot) do
    Map.has_key?(state.proposals, slot)
  end # is_proposal

  def is_not_proposal?(state, slot) do
    not is_proposal?(state, slot)
  end # is_not_proposal

  # -- decisions functions --

  def add_decision(state, slot, cmd) do
    %{ state | decisions: Map.put(state.decisions, slot, cmd) }
  end # add_decision

  def has_already_made_decision_for_slot?(state, slot) do
    Map.has_key?(state.decisions, slot)
  end # has_already_made_decision_for_slot?

  def has_decisions_to_perform?(state) do
    Map.has_key?(state.decisions, state.slot_out)
  end # has_decisions_to_perform

  def has_no_decisions_to_perform?(state) do
    not has_decisions_to_perform?(state)
  end # has_no_decisions_to_perform

  def has_performed_cmd?(state, cmd) do
    performed_cmds =
      Enum.filter(state.decisions, fn { s, _c } -> s < state.slot_out end) |>
      Enum.map(fn { _s, c } -> c end)

    cmd in performed_cmds
  end # has_performed_cmd?

  def has_not_performed_cmd?(state, cmd) do
    not has_performed_cmd?(state, cmd)
  end # has_not_yet_performed_cmd?

  # -- slot in/out functions --

  def increment_slot_in(state) do
    %{ state | slot_in: state.slot_in + 1 }
  end # increment_slot_in

  def increment_slot_out(state) do
    %{ state | slot_out: state.slot_out + 1 }
  end # increment_slot_out


end # ReplicaState
