
# cyprienroche 12 feb 2021

defmodule LeaderState do
  @enforce_keys [ :config, :acceptors, :replicas, :ballot_num ]
  defstruct(
    config: Map.new,
    acceptors: MapSet.new,
    replicas: MapSet.new,
    ballot_num: nil,
    active: false,
    proposals: Map.new)

	def new(config, acceptors, replicas, ballot_num) do
		%LeaderState{
      config: config,
      acceptors: acceptors,
      replicas: replicas,
      ballot_num: ballot_num }
	end # new

  def add_proposal(state, slot, cmd) do
    %{ state | proposals: Map.put(state, slot, cmd) }
  end # add_proposal

  def update_proposals(state, proposals) do
    %{ state | proposals: proposals }
  end # update_proposals

  def become_active(state) do
    %{ state | active: true }
  end # become_active

  def become_passive(state) do
    %{ state | active: false }
  end # become_passive

  def increase_ballot_num(state) do
    { count, _id } = state.ballot_num
    %{ state | ballot_num: { count + 1, self() } }
  end # increase_ballot_num

end # LeaderState

defmodule Leader do

def start config do
  receive do
      { :BIND, acceptors, replicas } ->
        initial_ballot_num = { 0, self() }
        spawn Scout, :start, [ config, self(), acceptors, initial_ballot_num ]
        next LeaderState.new(config, acceptors, replicas, initial_ballot_num)
    end
end # start

defp next state do
  receive do
    { :PROPOSE, slot, cmd } ->
      if Map.has_key?(state.proposals, slot) do
        next state
      else
        state = LeaderState.add_proposal(state, slot, cmd)
        if state.active do
          pvalue = { state.ballot_num, slot, cmd }
          spawn Commander, :start,
            [ state.config, self(), state.acceptors, state.replicas, pvalue ]
        end # if
        next state
      end # if

    { :ADOPTED, ballot_num, pvalues } ->
      if ballot_num != state.ballot_num do
        next state
      else
        proposals = merge state.proposals, pmax(pvalues)
        state = LeaderState.update_proposals(state, proposals)
        for { s, c } <- proposals do
          pvalue = { ballot_num, s, c }
          spawn Commander, :start,
            [ state.config, self(), state.acceptors, state.replicas, pvalue ]
        end # for
        state = LeaderState.become_active(state)
        next state
      end # if

    { :PREEMPTED, { _count, _from } = ballot_num } ->
      if ballot_num <= state.ballot_num do
        next state
      else
        state = LeaderState.become_passive(state)
        state = LeaderState.increase_ballot_num(state)
        # should wait before trying again?
        spawn Scout, :start,
          [ state.config, self(), state.acceptors, state.ballot_num ]
        next state
      end # if
  end # receive
end # next

defp pmax pvalues do
  # determines for each slot the command corresponding to
  # the maximum ballot number in pvalues
  Enum.group_by(pvalues, fn { _b, s, _c } -> s end) |>
  Enum.map(fn { _s, values } ->
    { _b, s, c } = Enum.max_by values, fn { b, _s, _c } -> b end
    { s, c }
  end)
end # pmax

defp merge x, y do
  # returns the elements of y as well as the elements of x that are not in y
  Map.merge x, y, fn _common_key, _value_x, value_y -> value_y end
end # merge

end # Leader
