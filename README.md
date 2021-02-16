# CPE client (TR-064) for the command line

[1]: https://dlang.org/download.html
[2]: https://dlang.org/

## Intro
"CPE" - "Customer Premises Equipment". 
The CPE is located in the local area network of its owner. It can be a combined device that is used to access the Internet (e.g. a DSL modem), to manage telephones (e.g. a DECT station) etc. The manufacturer often provides software with which a user can retrieve information about the state of the various services on the CPE and change its settings. Such software communicates with the CPE by using a particular protocol, e.g. "TR-064".

## What is this about?
This repository provides a client for TR-064 capable devices(CPEs), to read & write settings and execute functions.
it contains:
- A library for the programming language [D][2]
- A command line application


## How to use

#### Installation
Use a [D Compiler][1] for building a executable.


#### Components

- `cpe scan`
Scans and lists TR-064 capable devices in the LAN.

- `cpe list`
Lists functions (Service, Action, Parameter) privided by the CPE.

- `cpe call`
Calls a function (or service action) provided by the CPE.

- `cpe profile`
Management of profiles. Profiles are a construct of the command line application to simplify operation and to speed up execution.
	- `cpe profile add`
	Adds a profile

	- `cpe profile list`
	Lists known profiles

## Application example
#### Scan for compatible devices in the LAN
```sh
❯ cpe scan
HTTP/1.1 200 OK
LOCATION: http://192.168.178.1:49000/tr64desc.xml
SERVER: FRITZ!Box 6360 Cable (um) UPnP/1.0 AVM FRITZ!Box 6360 Cable (um) 85.06.52
CACHE-CONTROL: max-age=1800
EXT:
ST: urn:dslforum-org:device:InternetGatewayDevice:1
USN: uuid:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX::urn:dslforum-org:device:InternetGatewayDevice:1
```

#### Create a profile
```sh
❯ cpe profile add --cpe http://192.168.178.1:49000/tr64desc.xml --name demoprofile --user admin --password gurkensalat
```

#### List the available functions (Services, Actions, Parameters)
```sh
❯ cpe list --profile demoprofile
```

#### Call a Action
```sh
❯ cpe call --profile demoprofile -S "urn:dslforum-org:service:WLANConfiguration:1" -A GetSSID
relatedStateVariable:	SSID
value:	Brezel
name:	NewSSID
direction:	out
```

#### Call a Action with input parameters
```sh
❯ cpe call --profile demoprofile -S "urn:dslforum-org:service:WLANConfiguration:1" -A SetSSID -i "SSID=MyWifi"
```

If the parameters are unknown, look it up like this:
```sh
❯ cpe list --profile demoprofile -S "urn:dslforum-org:service:WLANConfiguration:1" -A SetSSID
serviceType: urn:dslforum-org:service:WLANConfiguration:1
	Action: SetSSID
	Params:
	in string SSID
```
