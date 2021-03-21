# multipaxos - cr618

*make clean:* remove compiled code

*make compile:* compile

*make run:* same as make run SERVERS=5 CLIENTS=5 CONFIG=default DEBUG=0 MAX_TIME=15000

*make clear_log:* deletes the log files

The DEBUG_MODULES variable in the Makefile can be used to chose which modules to debug.
When specifying a module in this variable, that module will write to its log file
messages using the Debug.module_info/3 function.

When running the system under load, it is advised not to include commander and scouts
there since they are spawned dynamically, resulting in complicated IO and often
throwing IO errors that can be seen on the console.
