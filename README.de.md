# CPE Client (TR-064) für die Kommandozeile

## Intro
"CPE" ist die Kurzform für "Customer Premises Equipment", bzw. Teilnehmernetzgerät.
Das CPE befindet sich im lokalen Netzwerk des Teilnehmers (bzw. Anwenders) und ist z.B. ein kombiniertes Gerät, das der Anwender benutzt um ins Internet zu gehen (z.B. DSL Modem), seine Telefone zu verwalten (z.B. DECT Station), Gereäte im lokalen Netzwerk zu Verbinden usw.. 
Oft stellt der Hersteller eines CPE Software bereit, mit dessen Hilfe der Anwender Informationen zum Zustand der diversen Dienste auf dem CPE abrufen oder Einstellungen durchzuführen kann. Dabei komuniziert die Anwendung (z.B. auf einem Smartphone) über ein bestimmtes Protokoll mit dem CPE - z.B. "TR-064". 

## Was ist das hier?
Eine Komandozeilen Anwendung um Funktionen, die ein CPE bereitstellt, auszulesen und auszuführen. Voraussetzung ist, dass das CPE TR-064 fähig ist.

## Nutzungshinweise
#### Komponenten

- cpe scan 
Scan und Auflistung der TR-064 fähigen Geräte im LAN

- cpe list
Ausgabe/Durchsuchung der vom CPE bereitgestellten Funktionen (Service, Action, Parameter)

- cpe call
Aufruf einer vom CPE bertgestellten Funktion (bzw. Service-Action)

- cpe profile
Verwaltung von Profilen. Profile sind ein Konstrukt dieser Anwendung um die Bedienung zu vereinfachen und die Ausführung zu beschleunigen. 
Ein Profil umfasst die Adresse des CPE, evtl. Zugangsdaten und puffert eine Liste mit den bekannten Funktionen (Services , Actions , Parameter) eines CPE.
	- cpe profile add
	Hinzufügen von Profilen
	
	- cpe profile list
	Auflisten von bekannten Profilen
	
## Anwendungsbeispiel
#### Scan von kompatiblen Geräten im LAN
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
#### Anlegen eines Profils
```sh
❯ cpe profile add --cpe http://192.168.178.1:49000/tr64desc.xml --name demoprofile --user admin --password gurkensalat
```
#### Auflisten der verfügbaren Funktionen (Services, Actions, Parameter)
- Komplette Liste:
```sh
❯ cpe list --profile demoprofile
```

- Oder Schritt für Schritt
	
Ausgabe der verfügbaren Services
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

Ausgabe der verfügbaren Actions eines ausgewählten Services
```sh
❯ cpe list --profile home -S "urn:dslforum-org:service:WLANConfiguration:1" -n
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

#### Aufruf einer ausgewählten Action
```sh
❯ cpe call --profile home -S "urn:dslforum-org:service:WLANConfiguration:1" -A GetSSID
relatedStateVariable:	SSID
value:	Brezel
name:	NewSSID
direction:	out
```

#### Aufruf einer ausgewählten Action mit Definition von Input Parameter
zuerst müssen die input parameter "in" in Erfahrung gebracht werden:
```sh
❯ cpe list --profile home -S "urn:dslforum-org:service:WLANConfiguration:1" -A SetSSID 
serviceType: urn:dslforum-org:service:WLANConfiguration:1
	Action: SetSSID
	Params:
	in string SSID
```
 Anschließend Aufruf
```sh
❯ cpe call --profile home -S "urn:dslforum-org:service:WLANConfiguration:1" -A SetSSID -i "SSID=MyWifi"
``` 

	
