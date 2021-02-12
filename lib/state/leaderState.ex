
# cyprienroche 12 feb 2021

defmodule LeaderState do
  @enforce_keys [ :config, :acceptors, :replicas, :ballot_num ]
  defstruct(
    config: Map.new,
    acceptors: MapSet.new,
    replicas: MapSet.new,
    ballot_num: nil,
    active: false,
    proposals: Map.new,
    timeout: 0)

	def new(config, acceptors, replicas, ballot_num) do
		%LeaderState{
      config: config,
      acceptors: acceptors,
      replicas: replicas,
      ballot_num: ballot_num,
      timeout: config.initial_timeout }
	end # new

  # -- proposals functions --

  def add_proposal(state, slot, cmd) do
    %{ state | proposals: Map.put(state.proposals, slot, cmd) }
  end # add_proposal

  def update_proposals(state, proposals) do
    %{ state | proposals: proposals }
  end # update_proposals

  # -- active functions --

  def become_active(state) do
    %{ state | active: true }
  end # become_active

  def become_passive(state) do
    %{ state | active: false }
  end # become_passive

  # -- ballot_num functions --

  def increase_ballot_num(state) do
    { count, _id } = state.ballot_num
    %{ state | ballot_num: { count + 1, self() } }
  end # increase_ballot_num

  # -- timeout functions --

  def increase_timeout(state) do
    t = round(state.timeout * state.config.timeout_factor)
    %{ state | timeout: t }
  end # increase_timeout

  def decrease_timeout(state) do
    t = max 0, round(state.timeout - state.config.timeout_constant)
    %{ state | timeout: t }
  end # decrease_timeout


end # LeaderState
