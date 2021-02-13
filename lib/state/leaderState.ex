
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
    timeout: 0,
    max_timeout: 0)

	def new(config, acceptors, replicas, ballot_num) do
		%LeaderState{
      config: config,
      acceptors: acceptors,
      replicas: replicas,
      ballot_num: ballot_num,
      timeout: config.init_timeout,
      max_timeout: config.init_timeout }
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
    max_timeout = round(state.max_timeout * state.config.timeout_factor)
    %{ state | max_timeout: max_timeout } |> set_next_timeout
  end # increase_timeout

  def decrease_timeout(state) do
    max_timeout = max state.config.min_timeout,
                      round(state.max_timeout - state.config.timeout_constant)
    %{ state | max_timeout: max_timeout } |> set_next_timeout
  end # decrease_timeout

  defp set_next_timeout(state) do
    t = Enum.random(state.config.min_timeout..state.max_timeout)
    # t = max state.config.min_timeout, state.max_timeout + (Enum.random(-10..10) * 10)
    %{ state | timeout: t }
  end


end # LeaderState
