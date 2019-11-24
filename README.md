# FTC Overseer

Observe wireless activity during FTC matches.

## Motivation

Certain wireless activities can disrupt the performance of robots participating in a FIRST Tech
Challenge match. This project, when paired with a Raspberry Pi and four USB wireless adapters with
certain abilities, observes wireless traffic related to teams currently playing a match to detect
undesired activity. By leveraging the FTC Live Scoring software, we can provide active alerts for
teams we know are currently playing rather than passively observing set frequencies.

## What it Does

In broad strokes, this application does the following:

- Connects to the FTC Live Scoring software running on the local network
- Establishes a websocket connection to the `/api/v2/stream` endpoint
- Listens for `MATCH_START` messages
- Queries for the teams playing in the current match
- Assigns each team to a wireless adapter
  - Each adapter performs a scan to find the channel upon which a team is operating
  - In case a team has multiple pairs of phones, the network with highest signal strength is used
- Runs `tshark` to observe the wireless traffic related to the Robot Controller MAC address
- Actively alerts if problematic traffic is detected
- Stops all scans and `tshark` when the match ends

In the future, we can experiment with different ways of alerting and displaying information.

<p align="center"><img src="https://github.com/aj-foster/overseer/blob/master/docs/console-output.png" width="400" alt="Console Screenshot"></p>

## Setup

This project requires specialized hardware. Following is a broad outline of the setup process.

### Raspberry Pi

This software was tested using a Raspberry Pi 3 B+. I recommend avoiding the Raspberry Pi 4 due to
potential wireless interference by the USB 3.0 ports. Equivalent Pi units with four USB ports will
also work.

Because this project relies upon `tshark`, a natural choice for the Pi's operating system might be
[Kali Linux](https://docs.kali.org/kali-on-arm/install-kali-linux-arm-raspberry-pi). This is not
strictly necessary, however. Other Debian-based operating systems are likely to work once `tshark`
is installed. Ensure that `tshark`, `ifconfig`, and `iwconfig` binaries are available.

Once an operating system has been flashed to the Pi's SD card, see `bin/setup` for additional setup.

### Wireless Adapters

This project will use up to four wireless adapters, assigning one adapter to each team currently
playing in a match. Each adapter should have the following specs:

- Dual-band, in case a team uses 5 Ghz wireless
- Monitor mode, for looking at traffic not sent directly to the adapter

In testing, I used four Cisco/Linksys WUSB600N v2 adapters. Note that other versions may not have
monitor mode capability.

Because of the size of most adapters, you will likely want several short USB extension cables.

### Software

This project is written in the Elixir language. As part of the Raspberry Pi setup, you should have
selected versions of Elixir and Erlang installed. This will allow you to build the project and run
it on the Pi. (Note that the project must be built on the same OS/arch as it will be run.)

After cloning the project onto the Pi, it can be built using:

```shell
./bin/build
```

## Configuration

The application uses several environment variables to instruct its operation. These can be specified
in a `.env` file at the base of the project. Below is an example, annotated file:

```shell
# Event-specific configuration

# Location of the scoring computer
SCORING_HOST="http://10.0.0.2:8080"
# Event code for the current event
SCORING_EVENT="test_01"

# Set these values if you plan to connect to the application from another Erlang node

# Shared secret for node-to-node connections
ERLANG_COOKIE="replace-me"
# Enabling connections from the outside world
RELEASE_DISTRIBUTION="name"
# Name of the current node (replace IP address as appropriate)
RELEASE_NODE="overseer@10.0.0.3"
```

Allowing specification of the scoring host and event code after application startup is a future
goal.

## Run

Once configured, run the application using:

```shell
./bin/start
```

The application likely requires root privileges for `iwconfig` and `ifconfig` if not for `tshark`.
