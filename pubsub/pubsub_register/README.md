# Implementing Register-based solution

## Introduction

The objective of this basic solution is to show that by using the
internal registers of the ingress pipeline one can deploy the
PUBLISH/SUBSCRIBE scheme to be used by different applications.

To keep things simple, we just used IPv4 forwarding for some basic
data transfer and some registers to do the main part related to the
forwarding the published data based on the registrations made on them.

With IPv4 forwarding, the switch must perform the following actions
for every normal packet which is not one of our special kinds:

(i) update the source and destination MAC addresses.
(ii) decrement the time-to-live (TTL) in the IP header.
(iii) forward the packet out the appropriate port.

With `subIndxPort` registers, the switch must perform the following
actions for every `PubSub` packet:

(i) If it is a registration request, the switch will write a positional
    map of the input port to the proper register with the index equal to
    the `id` of the requested `variable`, or the reverse actions, if it was
    a remove request.  
(ii) Forwards the request to other P4-switches, if any, through the
    virtual spanning tree that is already prepared by the main controller
    in the switch.
(iii) If it is a publish packet, the switch will checks the the internal
    register with index equal to the `id` of the published `variable`, and
    will `multicast` the packet to the ports which are written in that
    mentioned register, otherwise drops the packet.

The switch have a single IPv4 forwarding table, which the control plane
will populate it with static rules for each topology. Each rule will map
an IP address to the MAC address and output port for the next hop.
Four registers for handling four variables, and a multicast table with one
entry for the spanning tree, which the control plane will populate it with
static rules for each topology.

We can use the following topologies for this design.

1. A single switch topology which is referred to as single-topo:
   ![single-topo](./single-topo/single-topo.png)

2. A linear topology with two switches, which is referred to as
   linear-topo:
   ![linear-topo](./linear-topo/linear-topo.png)

3. A triangular topology with three switches, which is referred
   to as triangular-topo:
   ![triangular-topo](./triangular-topo/triangular-topo.png)

To use any of them, one should replace the topology address mentioned
in the `MakeFile` with the desired topology.

Our P4 program is written for the V1Model architecture implemented
on P4.org's bmv2 software switch. The architecture file for the V1Model
can be found at:[Here](/usr/local/share/p4c/p4include/v1model.p4). This file
describes the interfaces of the P4 programmable elements in the architecture,
the supported externs, as well as the architecture's standard metadata
fields. We encourage you to take a look at it.

## Step 1: Start the environment with the desired topology

The REPLICA controller should be started in the H
The directory with this README also contains a skeleton P4 program,
`basic.p4`, which initially drops all packets. Your job will be to
extend this skeleton program to properly forward IPv4 packets.

Start by bringing up our structure in the Mininet to test its behavior.

1. In your shell, run:
   ```bash
   make clean && make all
   ```
   This will:
   * compile `pubsub.p4`, and
   * start the single-topo in Mininet and configure the switch with
   the appropriate P4 program + table entries, registers, and
   * configure all hosts with the commands listed in
   `single-topo/topology.json`

2. You should now see a Mininet command prompt. Start with opening
   one terminal for each host in the topology:
   ```bash
   mininet> xterm h1 h2 h3 h4
   ```

3. Start the REPLICA controller in `h4` by running the
   `./REPLICA_controller.py`, and start one MIDDLE-WARE in every
   other hosts`(h1, h2 and h3)` by running `./pubsub_MW.py` in each of
   them. now you have a ready system for start the main goal.

4. Except for the `h4`, open one terminal in each other hosts`(h1, h2
   and h3)` by doing in the Mininet prompt:
   ```bash
   mininet> xterm h1 h2 h3
   ```

5. For simplicity, in each of the three new terminals, start the
   PUBSUB-NF by running `./pubsub_NF.py --n X`, which `X` is `(0, 1 and 2)`
   for each host respectively.
   e.g. `./pubsub_NF.py --n 0` in `h1`, `./pubsub_NF.py --n 1` in `h2` and
   `./pubsub_NF.py --n 2` in `h3`. You will see ID assignments for the
   NFs and their PUBLISH variables, wait until all of the three NFs
   start to PUBLISH.

6. From the Mininet prompt start only one terminal in one of the
   hosts from `(h1, h2 and h3)` by your choice, you should have 8 terminals by now.
   ```bash
   mininet> xterm hx
   ```
   Where `x` is one of the `(1, 2 and 3)`. Start another NF by running `./pubsub_NF.py --n 3` inside this terminal. You will see the same procedure for this NF too. But after starting to PUBLISH on its variable, it starts to ask for the id of the some other variables, and eventually subscribing on them in the switches. You will see that this NF is receiving the other NF publishes for the variables it requested.

7. In another terminal outside the Mininet(a regular terminal of the
   system) run this command:
   ```bash
   bm_CLI --thrift-port 9090 --json build/pub_sub.json --pre SimpleSwitchLAG
   ```
   You will see another command line, enter the bellow command and see
   the results:
   ```bash
   register_read subIndxPort
   ```
   you can see the registers with the number inside them, which the
   number is showing the multicast group related to the variable related
   to that register. The relation between the variable and the register
   is the index of the register which is equal to the id of the variable
   that is assigned by the REPLICA controller.

8. In the Mininet command line type `exit` to close all the xterminals.
   Then, to stop mininet:
   ```bash
   make stop
   ```
   And to delete all pcaps, build files, and logs:
   ```bash
   make clean
   ```

### A note about the control plane and the logs

A P4 program defines a packet-processing pipeline, but the rules
within each table are inserted by the control plane. When a rule
matches a packet, its action is invoked with parameters supplied by
the control plane as a part of the rule.

Here, we have already implemented the control plane logic for you.
As part of bringing up the Mininet instance, the `make all` command
will install packet-processing rules in the tables of each switch.
These are defined in the `sX-runtime.json` files, where `X` corresponds
to the switch number.

**Important:** We use P4Runtime to install the control plane rules. The
content of files `sX-runtime.json` refer to specific names of tables, keys, and
actions, as defined in the P4Info file produced by the compiler (look for the
file `build/basic.p4.p4info.txt` after executing `make all`). Any changes in the P4
program that add or rename tables, keys, or actions will need to be reflected in
these `sX-runtime.json` files.

By starting the REPLICA controller, MIDDLE-WAREs and the NFs, they build
a log file containing a simplified details about what is happening inside
them. An external copy of the data for each published variable and for
each received publish can be found there to trace the correctness of the
algorithm.


### Troubleshooting

There are several problems that might manifest as you develop your program:

1. `pub_sub.p4` might fail to compile. In this case, `make all` will
report the error emitted from the compiler and halt.

2. `pub_sub.p4` might compile but fail to support the control plane
rules in the `sX-runtime.json` files that `make all` tries to install
using P4Runtime. In this case, `make all` will report errors if control
plane rules cannot be installed. Use these error messages to fix your
`pub_sub.p4` implementation.

3. `pub_sub.p4` might compile, and the control plane rules might be
installed, but the switch might not process packets in the desired
way. The `logs/sX.log` files contain detailed logs
that describing how each switch processes each packet. The output is
detailed and can help pinpoint logic errors in your implementation.

#### Cleaning up Mininet

In the latter two cases above, `make all` may leave a Mininet instance
running in the background. Use the following command to clean up
these instances:

```bash
make stop
```