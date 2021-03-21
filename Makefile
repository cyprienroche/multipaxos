
SERVERS  = 5 # 5
CLIENTS  = 5 # 5
CONFIG   = default # default
DEBUG    = 0 # 0
MAX_TIME = 15000 # 15000
DEBUG_MODULES = client-replica-database-acceptor-leader-scout-commander
# client-replica-database-acceptor-leader-scout-commander

START    = Multipaxos.start
HOST    := 127.0.0.1

# --------------------------------------------------------------------

TIME    := $(shell date +%H:%M:%S)
SECS    := $(shell date +%S)
COOKIE  := $(shell echo $$PPID)

NODE_SUFFIX := ${SECS}_${LOGNAME}@${HOST}

ELIXIR  := elixir --no-halt --cookie ${COOKIE} --name
MIX 	:= -S mix run -e ${START} \
	${NODE_SUFFIX} ${MAX_TIME} ${DEBUG} ${SERVERS} ${CLIENTS} ${CONFIG} \
	${DEBUG_MODULES}

# --------------------------------------------------------------------

run cluster: clear_log compile
	@ ${ELIXIR} server1_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} server2_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} server3_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} server4_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} server5_${NODE_SUFFIX} ${MIX} cluster_wait &

	@ ${ELIXIR} client1_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} client2_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} client3_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} client4_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} client5_${NODE_SUFFIX} ${MIX} cluster_wait &
	@sleep 3
	@ ${ELIXIR} multipaxos_${NODE_SUFFIX} ${MIX} cluster_start

compile:
	mix compile

clean: clear_log
	mix clean
	@rm -f erl_crash.dump

clear_log:
	@echo 'removing log' &
	@rm -rf log/

ps:
	@echo ------------------------------------------------------------
	epmd -names
