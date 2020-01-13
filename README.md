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

<p align="center"><img src="https://github.com/aj-foster/overseer/blob/master/docs/display-output.png" width="400" alt="Display Screenshot"></p>

<p align="center"><img src="https://github.com/aj-foster/overseer/blob/master/docs/console-output.png" width="400" alt="Console Screenshot"></p>

## Setup

This project requires specialized hardware. Following is a broad outline of the setup process.

### Raspberry Pi

This software was tested using a Raspberry Pi 3 B+. I recommend avoiding the Raspberry Pi 4 due to
potential wireless interference by the USB 3.0 ports. Equivalent Pi units with four USB ports can
work with a modified firmware image.

See the **Software** section below for more information about the firmware to use on the Pi.

### Wireless Adapters

This project will use up to four wireless adapters, assigning one adapter to each team currently
playing in a match. Each adapter should have the following specs:

- Dual-band, in case a team uses 5 Ghz wireless
- Monitor mode, for looking at traffic not sent directly to the adapter

In testing, I used four Cisco/Linksys WUSB600N v2 adapters. Note that other versions may not have
monitor mode capability. **Note**: other adapters may require a modification of the firmware to
include additional drivers.

Because of the size of most adapters, you will likely want several short USB extension cables or a
USB hub with sufficient space between ports.

### Software

This software is written in the Elixir language and utilizes the Nerves library to create a
bootable firmware for the Raspberry Pi. Firmware images can be downloaded from the GitHub releases
page. Burn it directly to an SD card using `dd` or a similar utility (instructions omitted — be
careful when writing to block devices!).

## Usage

**Startup**: The application will automatically boot when the Raspberry Pi is powered up. A standard
keyboard and monitor can be used to interact with an interactive Elixir console. (Press enter to see
the prompt if log messages are obscuring it.)

**Network**: The application will start the Pi's ethernet interface with DHCP enabled.

**Adapters**: The application will utilize any wireless adapters available during startup.

**Scoring API**: After application startup, we can configure the location (host) of the scoring API
and the current event code using the following in the interactive Elixir console:

```elixir
FTC.Overseer.Scorekeeper.set_api_host("http://10.0.0.2:8080")  # Scoring host address
FTC.Overseer.Scorekeeper.set_event_code("2019flm4")  # Scoring event code
```

**Web interface**: Access the web interface of the application by going to port 4000 of the Pi's
IP address, i.e. `http://10.0.0.3:4000`.
