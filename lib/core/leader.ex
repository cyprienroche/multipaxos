
# cyprienroche 12 feb 2021

defmodule Leader do

def start config do
  config = Configuration.start_module(config, :leader)
  receive do
      { :BIND, acceptors, replicas } ->
        initial_ballot_num = { 0, self() }
        Debug.module_info(config, "Spawn scout for ballot_num #{inspect initial_ballot_num}")
        # propose to be the leader for the next decision to be made
        spawn Scout, :start, [ config, self(), acceptors, initial_ballot_num ]
        next LeaderState.new(config, acceptors, replicas, initial_ballot_num)
    end
end # start

defp next state do
  Debug.module_info(state.config, "")
  receive do
    { :PROPOSE, slot, cmd } ->
      Debug.module_info(state.config, "Received proposal #{inspect {slot, cmd}} from a replica")
      if Map.has_key?(state.proposals, slot) do
        # already have a proposal for this slot, ignore this proposal
        Debug.module_info(state.config, "Already have a proposal for slot #{slot}, ignoring proposal #{inspect cmd}")
        next state
      else
        # accept the proposal for that slot
        Debug.module_info(state.config, "Accept proposal #{inspect cmd} for slot #{slot}")
        state = LeaderState.add_proposal(state, slot, cmd)
        Debug.module_info(state.config, "We are #{ if state.active do
            "active with ballot_num #{inspect state.ballot_num} adopted by scouts"
          else
            "not active, waiting to hear from Scouts for our current ballot_num #{inspect state.ballot_num}"
          end }")
        if state.active do
          # have been elected to be the leader for a ballot_num and we can now decide the command for this slot
          pvalue = { state.ballot_num, slot, cmd }
          Debug.module_info(state.config, "Spawn one Commander for #{inspect {slot, cmd}}")
          spawn Commander, :start,
            [ state.config, self(), state.acceptors, state.replicas, pvalue ]
        end # if
        next state
      end # if

    { :ADOPTED, ballot_num, pvalues } ->
      Debug.module_info(state.config, "Received ballot_num #{inspect ballot_num} adopted by our scout")
      if ballot_num != state.ballot_num do
        # ignore this ballot_num, we moved on to another one and spawned another Scout
        Debug.module_info(state.config, "Ignore ballot_num #{inspect ballot_num} since we moved on to ballot_num #{inspect state.ballot_num}")
        next state
      else
        # we have been elected leader for this ballot_num
        Debug.module_info(state.config, "Received ballot_num #{inspect ballot_num} is the same as our ballot_num #{inspect state.ballot_num}")
        proposals = merge state.proposals, Map.new(pmax(pvalues))
        state = LeaderState.update_proposals(state, proposals)
        for { s, c } <- proposals do
          # try to get all the proposals we have to be accepted
          pvalue = { ballot_num, s, c }
          Debug.module_info(state.config, "Spawn Commanders for pvalue #{inspect pvalue}")
          spawn Commander, :start,
            [ state.config, self(), state.acceptors, state.replicas, pvalue ]
        end # for
        state = LeaderState.become_active(state)
        Debug.module_info(state.config, "We are now active")
        state = LeaderState.decrease_timeout(state)
        Debug.module_info(state.config, "Timeout is now #{state.timeout}")
        next state
      end # if

    { :PREEMPTED, { _count, _from } = ballot_num } ->
      Debug.module_info(state.config, "Received preemted message for ballot_num #{inspect ballot_num}")
      if ballot_num <= state.ballot_num do
        # we moved on to another ballot_num
        Debug.module_info(state.config, "Ignore ballot_num #{inspect ballot_num} since we moved on to ballot_num #{inspect state.ballot_num}")
        next state
      else
        # something went wrong, we did not get the majority of votes
        Debug.module_info(state.config, "Become passive")
        state = LeaderState.become_passive(state)
        Debug.module_info(state.config, "Timeout for #{state.timeout}")
        Process.sleep(state.timeout)
        state = LeaderState.increase_ballot_num(state)
        Debug.module_info(state.config, "Spawn new Scout for new ballot_num #{inspect state.ballot_num}")
        # try to be the leader again
        spawn Scout, :start,
          [ state.config, self(), state.acceptors, state.ballot_num ]
        state = LeaderState.increase_timeout(state)
        Debug.module_info(state.config, "Timeout is now #{state.timeout}")
        next state
      end # if
  end # receive
end # next


# -------------- helper functions --------------

defp spawn_commander(state, pvalue) do
  Debug.module_info(state.config, "Spawn Commanders for pvalue #{inspect pvalue}")
  spawn Commander, :start,
    [ state.config, self(), state.acceptors, state.replicas, pvalue ]
  state
end # spawn_commander

defp spawn_scout(state) do
  Debug.module_info(state.config, "Spawn new Scout for new ballot_num #{inspect state.ballot_num}")
  # try to be the leader again
  spawn Scout, :start,
    [ state.config, self(), state.acceptors, state.ballot_num ]
  state
end # spawn_scout

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
