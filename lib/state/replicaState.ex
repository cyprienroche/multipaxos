
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
