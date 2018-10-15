# esx_carthief
## Description
Car thief script for ESX FiveM servers. Players can steal a car that they will have to deliver to a location in order to obtain some dirty money. Police will be alerted and updated with their location as long as they sit in the stolen vehicle.

Note: This is NOT a job. This is an illegal activity anyone can do.
## Dependencies
* [es_extended](https://github.com/ESX-Org/es_extended)
* [esx_policejob](https://github.com/ESX-Org/esx_policejob)
## Setup
* Install into resources/[esx]
* Add the following line to your server.cfg
```
start esx_carthief
```

* If you want to change the stolen vehicle location update time, you have to set `Config.BlipUpdateTime` to whatever time you would like in milliseconds in `config.lua`.
* If you want to change the number of cops online required to steal a car, you have to set `Config.CopsRequired` to the amount of cops you would like in `config.lua`.
## Screenshots
### In front of the marker
![screenshot](https://i.imgur.com/BoqYPHj.jpg)
##
### Little explanation
![screenshot](https://i.imgur.com/maaWc4i.jpg)
