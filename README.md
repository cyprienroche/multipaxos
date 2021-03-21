# multipaxos

## Aim
The aim of this project is to *implement and evaluate* a **simple replicated banking service** that uses the version of Multi-Paxos described in the paper: Paxos Made Moderately Complex by Robbert van Renesse and Deniz Altınbüken. ACM Computing Surveys. Vol. 47. No. 3. February 2015. Please see http://paxos.systems for more information.


## Design and implementation

The algorithm is implemented in Elixir. Please see https://elixir-lang.org for more information.

In terms of the banking service, the only banking command implemented is the **move** command, which moves a given amount from one bank account to another. This was done for simplicity.

There are 5 key modules in this implementation of the multi-paxos algorithm: **Replica**, **Leader**, **Commander**, **Scout** and **Acceptor**. Please refer to the paper Paxos Made Moderately Complex by Robbert van Renesse and Deniz Altınbüken for a detailed explanation of the purpose and responsibilities of the 7 modules mentioned above. Note that this implementation *does not handle* reconfiguration commands nor recovery from process crash failures.

To better understand the implementation, please look at the files inside the *resources folder*.

The **Multipaxos** module is a top-level system node and is used as the entry point to run the multi-paxos algorithm. It initialises all the modules and prepares the environment in order to run the algorithm. The **Server** module simply spawns 1 **Replica**, 1 **Leader**, 1 **Acceptor**, and 1 **Database** module. The **Database** module is responsible for recording transactions and does so using a Map in this implementation, for simplicity. The **Monitor** module keeps track of events and after an arbitrary period of time, prints to the console a summary of the events that occurred so far. Finally, the **Client** module repeatedly sends requests to an arbitrary number of **Replica** after a certain time.

There are 5 **Server** and 5 **Client** in this implementation, which can be changed in the **Makefile**. The implementation will work for any given number of **Server** or **Client**. All requests from **Client** are move requests, which involves moving a quantity from one account to another, for simplicity. **Client** can send requests in 3 different ways: they can send a request to a different **Replica** each time as in a *round robin*, so send a request only to one **Replica** each time; they can send their request to a majority of **Replica** as in a *quorum*; or they can send their request to all **Replica** as in a *broadcast*.

In this implementation, if there are N **Server**, there are N **Acceptor**, N **Replica**, and N **Leader** in the whole system. Therefore, there is no need to pick a **Leader** since everyone is a **Leader**. Similarly, for **Acceptor**, there is no need to select a few nodes to be Acceptors since every node is an **Acceptor**. This means that even if some **Server** nodes crash, we do not need to elect another **Leader** since there will be at most **f** failures and at least **2f + 1** nodes. Therefore, there will always be at least 1 **Leader**, at least 1 **Replica**, and at least **f + 1** **Acceptor**. There will always be a majority of **Acceptor**.

Each of the core modules from the algorithm maintain a *state*. All updates to their states are performed through specific functions to simplify the logic in the core modules and to obtain a clear logical distinction between the state and the algorithm. This also makes it easier to maintain and extend a state or to modify a state without having to change the main code of the algorithm. Each state is instantiated by calling a function named new, in reference to Object-Oriented Programming. Each state is implemented as an elixir struct.

Every module starts by calling the **Configuration.start_module/2** function, which creates a unique log file for the module and can be easily extended if desired.

To reduce Livelock scenarios, this implementation uses what was proposed in *section 3* of the **Paxos Made Moderately Complex** paper. Upon receiving a preempted message, a **Leader** *sleeps* for a certain time before spawning its next **Scout**. The maximum length of time the **Leader** sleeps for is updated with every preempted and adopted messages it receives. Upon receiving a preempted message, the maximum timeout length is multiplied by a factor slightly greater than 1 which is set in the configuration file. Upon receiving an adopted message, the maximum timeout length is decreased by a constant which is also set in the configuration file.

Furthermore, to ensure the **Leader** never sleeps for a negative value and to give the system more flexibility, the timeout length will never be lower than the **min_timeout** again specified inside the configuration file. The **Leader** always sleeps for a value randomly chosen between **min_timeout** and **max_timeout**. As can be seen later in the report, this does not ensure livelocks never happen. In fact, with more **Server** running the probability of a livelock greatly increases with this implementation. Should I have more time, I would have liked to explore a leadership-based solution or implement a leased-based solution.

Parameter, such as the time each client sleeps before sending its next request, the number of servers, or the number of clients can be changed in the Makefile and in the Configuration file.

## Debugging and testing methodology

All the debugging is made using the **Debug** module. It contains useful functions that are triggered only at certain debugging levels. It also contains the **module_info/3** function, which is heavily used throughout the implementation. Whether a module writes to its log can be turned on and off using the Makefile, by changing the DEBUG_MODULES variable and only including modules that should write to their log file there.

The **Server** and **Client** use the **create_log_folder/2** function to create a log folder for the subsequent modules to then add their log files to using the **Configuration.start_module/2** function. Note that the Scout files have an extension to their name, which is the ballot number they were spawned for. Similarly, the **Commander** file names are extended with the ballot number as well as the slot for which they were spawned. This makes it possible for multiple **Commander** to run concurrently without having to implement any locking mechanism for writing to their log since they each have their unique file.

The log can be removed using the **make clean_log** command. The log is deleted every time the system is run.

## Example outputs
```
1 **Server**, 5 **Client**, round_robin, 1 request max per **Client**
time = 15000 db updates done = [{1, 5}] time = 15000 client requests seen = [{1, 5}]
```
In this run, there is 1 server and 5 client, so there is only 1 database.
Client requests seen is a map from a server id to the number of requests seen by that server's replica.
Here, we see server 1's replica has seen 5 client requests.
Db updates done is a map from a server id to the number of database updates done by that server's database.
Here, we see server 1's database has done 5 client requests.

```
5 **Server**, 5 **Client**, round_robin, 1 request max per **Client**
time = 15000 db updates done = [{1, 5}, {2, 5}, {3, 5}, {4, 5}, {5, 5}] time = 15000 client requests seen = [{3, 5}]
```
In this run, we now have 5 servers and 5 clients.
Each client only sends 1 request to one server, server 3 in this case.
This can be seen in the above output since client requests seen = [{3,5}].
Db updates done shows us that every server was notified of the client requests and updated their database accordingly.

```
5 **Server**, 5 **Client**, broadcast, 5 request max per **Client**
time = 15000 db updates done = [{1, 25}, {2, 25}, {3, 25}, {4, 25}, {5, 25}] time = 15000 client requests seen = [{1, 25}, {2, 25}, {3, 25}, {4, 25}, {5, 25}]
```
Here is a last example, with 5 servers and 5 clients.
Each client sends 5 requests. Therefore, **5*5 = 25** requests are sent in total.
This time, clients broadcast their requests. That means it sends the same request to all the servers at once.
Thanks to the Multi-paxos algorithm, each servers performs 25 updates, as 25 different requests were sent.

## Useful commands

***make clean:*** remove compiled code

***make compile:*** compile

***make run:*** same as make run SERVERS=5 CLIENTS=5 CONFIG=default DEBUG=0 MAX_TIME=15000

***make clear_log:*** deletes the log files

## Additional instructions on how to run the system

The **DEBUG_MODULES** variable in the **Makefile** can be used to chose which modules to debug.
When specifying a module in this variable, that module will write to its log file
messages using the **Debug.module_info/3** function.

When running the system under load, it is advised not to include **Commander** and **Scout**
there since they are spawned dynamically, resulting in complicated IO and often
throwing IO errors that can be seen on the console.
