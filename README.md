# CPE client (TR-064) for the command line

## Intro
"CPE" is the short form for "Customer Premises Equipment". The CPE is located in the area local network of a subscriber (or user) and can be a combined device that the user uses to access the Internet (e.g. a DSL modem), to manage his telephones (e.g. a DECT station), to connect devices in the local network, etc. The manufacturer often provides software with which the user can retrieve information about the state of the various services on the CPE or change settings. The application communicates with the CPE through a particular protocol, e.g. "TR-064".

## What is this about?
A command line application to read and execute functions that a CPE provides. The prerequisite is that the CPE is TR-064 capable.

## Terms of use
#### Components

- `cpe scan`
Scan and list TR-064 capable devices in LAN

- `cpe list`
List functions (Service, Action, Parameter), that the cpe provides

- `cpe call`
Calling a function (or service action) provided by the CPE

- `cpe profile` 
Management of profiles. Profiles are a construct of this application to simplify operation and to speed up execution.
A profile includes the address of the CPE, possibly credentials, and buffers a list of the known functions (services, actions, parameters) of a CPE.
	- `cpe profile add`
	Adds a profile
	
	- `cpe profile list`
	Lists known profiles
	
Note, that all components do provide the --help parameter
## Applicationexample
#### Scan of compatible devices in the LAN
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
- The following command will print out a complete list:
```sh
❯ cpe list --profile demoprofile
```

- To make the browsing of the functions more comfortable, `cpe list` can be filtered
	
List of available services:
```sh
❯ cpe list --profile demoprofile -q
serviceType: urn:dslforum-org:service:DeviceInfo:1
serviceType: urn:dslforum-org:service:DeviceConfig:1
serviceType: urn:dslforum-org:service:Layer3Forwarding:1
serviceType: urn:dslforum-org:service:LANConfigSecurity:1
serviceType: urn:dslforum-org:service:ManagementServer:1
serviceType: urn:dslforum-org:service:Time:1
serviceType: urn:dslforum-org:service:UserInterface:1
serviceType: urn:dslforum-org:service:X_VoIP:1
serviceType: urn:dslforum-org:service:X_AVM-DE_Storage:1
serviceType: urn:dslforum-org:service:X_AVM-DE_OnTel:1
serviceType: urn:dslforum-org:service:X_AVM-DE_WebDAVClient:1
serviceType: urn:dslforum-org:service:X_AVM-DE_UPnP:1
serviceType: urn:dslforum-org:service:X_AVM-DE_Speedtest:1
serviceType: urn:dslforum-org:service:X_AVM-DE_RemoteAccess:1
serviceType: urn:dslforum-org:service:X_AVM-DE_MyFritz:1
serviceType: urn:dslforum-org:service:X_AVM-DE_TAM:1
serviceType: urn:dslforum-org:service:X_AVM-DE_AppSetup:1
serviceType: urn:dslforum-org:service:X_AVM-DE_Homeauto:1
serviceType: urn:dslforum-org:service:X_AVM-DE_Homeplug:1
serviceType: urn:dslforum-org:service:X_AVM-DE_Dect:1
serviceType: urn:dslforum-org:service:X_AVM-DE_Filelinks:1
serviceType: urn:dslforum-org:service:WLANConfiguration:1
serviceType: urn:dslforum-org:service:WLANConfiguration:2
serviceType: urn:dslforum-org:service:Hosts:1
serviceType: urn:dslforum-org:service:LANEthernetInterfaceConfig:1
serviceType: urn:dslforum-org:service:LANHostConfigManagement:1
serviceType: urn:dslforum-org:service:WANCommonInterfaceConfig:1
serviceType: urn:dslforum-org:service:WANDSLInterfaceConfig:1
serviceType: urn:dslforum-org:service:WANDSLLinkConfig:1
serviceType: urn:dslforum-org:service:WANEthernetLinkConfig:1
serviceType: urn:dslforum-org:service:WANPPPConnection:1
serviceType: urn:dslforum-org:service:WANIPConnection:1
```

List of the available actions of a given service
```sh
❯ cpe list --profile demoprofile -S "urn:dslforum-org:service:WLANConfiguration:1" -n
serviceType: urn:dslforum-org:service:WLANConfiguration:1
	Action: SetEnable
	Action: GetInfo
	Action: SetConfig
	Action: SetSecurityKeys
	Action: GetSecurityKeys
	Action: SetDefaultWEPKeyIndex
	Action: GetDefaultWEPKeyIndex
	Action: SetBasBeaconSecurityProperties
	Action: GetBasBeaconSecurityProperties
	Action: GetStatistics
	Action: GetPacketStatistics
	Action: GetBSSID
	Action: GetSSID
	Action: SetSSID
	Action: GetBeaconType
	Action: SetBeaconType
	Action: GetChannelInfo
	Action: SetChannel
	Action: GetBeaconAdvertisement
	Action: SetBeaconAdvertisement
	Action: GetTotalAssociations
	Action: GetGenericAssociatedDeviceInfo
	Action: GetSpecificAssociatedDeviceInfo
	Action: X_SetHighFrequencyBand
	Action: X_AVM-DE_SetStickSurfEnable
	Action: X_AVM-DE_GetIPTVOptimized
	Action: X_AVM-DE_SetIPTVOptimized
	Action: X_AVM-DE_GetNightControl
	Action: X_AVM-DE_GetWLANHybridMode
	Action: X_AVM-DE_SetWLANHybridMode
	Action: X_AVM-DE_GetWLANExtInfo
	Action: X_AVM-DE_GetWPSInfo
	Action: X_AVM-DE_SetWPSConfig
```

#### Call a given action
```sh
❯ cpe call --profile demoprofile -S "urn:dslforum-org:service:WLANConfiguration:1" -A GetSSID
relatedStateVariable:	SSID
value:	Brezel
name:	NewSSID
direction:	out
```

#### Call a given action with input parameter definition
first the input parameters "in" have to be known:
```sh
❯ cpe list --profile demoprofile -S "urn:dslforum-org:service:WLANConfiguration:1" -A SetSSID 
serviceType: urn:dslforum-org:service:WLANConfiguration:1
	Action: SetSSID
	Params:
	in string SSID
```
... and the call:
```sh
❯ cpe call --profile demoprofile -S "urn:dslforum-org:service:WLANConfiguration:1" -A SetSSID -i "SSID=MyWifi"
``` 

Note, that `cpe call` provides the parameter -o|--output which can be setted to "json".

	
