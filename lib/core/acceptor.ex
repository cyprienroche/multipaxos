
# cyprienroche 12 feb 2021

defmodule Acceptor do

def start config do
  config = Configuration.start_module(config, :acceptor)
  next AcceptorState.new(config)
end # start

defp next state do
  Debug.module_info(state.config, "")
  receive do
    { :P1A, scout, ballot_num } ->
      # scout is trying to be the leader for this round . equivalent to 'prepare' in Paxos
      Debug.module_info(state.config, "Received ballot_num #{inspect ballot_num} from a scout")
      Debug.module_info(state.config, "Current ballot_num is #{inspect state.ballot_num}")
      state =
        if ballot_num > state.ballot_num do
          # adopt this new, higher ballot_num . equivalent to 'promise' in Paxos
          Debug.module_info(state.config, "Adopt new ballot_num from scout")
          AcceptorState.adopt(state, ballot_num)
        else
          # don't adopt it
          Debug.module_info(state.config, "Don't Adopt new ballot_num from scout")
          state
        end # if
      Debug.module_info(state.config, "Current ballot_num is now #{inspect state.ballot_num}")
      Debug.module_info(state.config, "Send ballot_num #{inspect state.ballot_num} to scout")
      send scout, { :P1B, self(), state.ballot_num, state.accepted }
      next(state)

    { :P2A, commander, { ballot_num, _slot, _cmd } = pvalue } ->
      # commander is giving its decision for this round . equivalent to 'accept' in Paxos
      Debug.module_info(state.config, "Received pvalue #{inspect pvalue} from a commander with ballot_num #{inspect ballot_num}")
      Debug.module_info(state.config, "Current ballot_num is #{inspect state.ballot_num}")
      state =
        if ballot_num == state.ballot_num do
          # accept this ballot_num . equivalent to 'accepted' in Paxos
          Debug.module_info(state.config, "Accept pvalue from commander")
          AcceptorState.accept(state, pvalue)
        else
          # reject this ballot_num
          Debug.module_info(state.config, "Don't accept pvalue from commander")
          state
        end # if
      Debug.module_info(state.config, "Send ballot_num #{inspect state.ballot_num} to commander")
      send commander, { :P2B, self(), state.ballot_num }
      next(state)
  end # receive
end # next

end # Acceptor
