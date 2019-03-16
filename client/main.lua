ESX = nil
local PlayerData              	= {}
local currentZone               = ''
local LastZone                  = ''
local CurrentAction             = nil
local CurrentActionMsg          = ''
local CurrentActionData         = {}

local alldeliveries             = {}
local allvehicles             	= {}

local randomdelivery            = 1
local randomvehicle            	= 1

local isTaken                   = 0
local isDelivered               = 0
local car						= 0
local copblip
local deliveryblip


Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)

Citizen.CreateThread(function()
	--Add all deliveries to the table
	local deliveryids = 1
	for k,v in pairs(Config.Delivery) do
		table.insert(alldeliveries, {
				id = deliveryids,
				posx = v.Pos.x,
				posy = v.Pos.y,
				posz = v.Pos.z,
		})
		deliveryids = deliveryids + 1  
	end
	--Add all vehicles to the table
	local vehicleids = 1
	for k,v in pairs(Config.Vehicles) do
		table.insert(allvehicles, {
				id = vehicleids,
				posx = v.Pos.x,
				posy = v.Pos.y,
				posz = v.Pos.z,
				payment = v.Payment,
				car = v.Cars,
		})
		vehicleids = vehicleids + 1  
	end
end)

function SpawnCar()
	ESX.TriggerServerCallback('esx_carthief:isActive', function(isActive)
		if isActive == 0 then
			ESX.TriggerServerCallback('esx_carthief:anycops', function(anycops)
				if anycops >= Config.CopsRequired then

					--Get a random vehicle point
					randomvehicle = math.random(1,#allvehicles)
					
					--Delete vehicles around the area (not sure if it works)
					ClearAreaOfVehicles(allvehicles[randomvehicle].posx, allvehicles[randomvehicle].posy, allvehicles[randomvehicle].posz, 10.0, false, false, false, false, false)
					
					--Delete old vehicle and remove the old blip (or nothing if there's no old delivery)
					SetEntityAsNoLongerNeeded(car)
					DeleteVehicle(car)
					RemoveBlip(deliveryblip)
					
					--Get random car
					randomcar = math.random(1,#allvehicles[randomvehicle].car)

					--Spawn Car
					local vehiclehash = GetHashKey(allvehicles[randomvehicle].car[randomcar])
					RequestModel(vehiclehash)
					while not HasModelLoaded(vehiclehash) do
						RequestModel(vehiclehash)
						Citizen.Wait(1)
					end
					car = CreateVehicle(vehiclehash, allvehicles[randomvehicle].posx, allvehicles[randomvehicle].posy, allvehicles[randomvehicle].posz, 0.0, true, false)
					SetEntityAsMissionEntity(car, true, true)
					
					--Teleport player in car
					TaskWarpPedIntoVehicle(GetPlayerPed(-1), car, -1)

					--Get a random delivery point
					randomdelivery = math.random(1,#alldeliveries)

					--Set delivery blip
					deliveryblip = AddBlipForCoord(alldeliveries[randomdelivery].posx, alldeliveries[randomdelivery].posy, alldeliveries[randomdelivery].posz)
					SetBlipSprite(deliveryblip, 1)
					SetBlipDisplay(deliveryblip, 4)
					SetBlipScale(deliveryblip, 1.0)
					SetBlipColour(deliveryblip, Config.DeliveryBlipColour)
					SetBlipAsShortRange(deliveryblip, true)
					BeginTextCommandSetBlipName("STRING")
					AddTextComponentString("Delivery point")
					EndTextCommandSetBlipName(deliveryblip)
					
					SetBlipRoute(deliveryblip, true)

					--Register acitivity for server
					TriggerServerEvent('esx_carthief:registerActivity', 1)
					
					--For delivery blip
					isTaken = 1
					
					--For delivery blip
					isDelivered = 0
				else
					ESX.ShowNotification(_U('not_enough_cops'))
				end
			end)
		else
			ESX.ShowNotification(_U('already_robbery'))
		end
	end)
end

function FinishDelivery()
  	if(GetVehiclePedIsIn(GetPlayerPed(-1), false) == car) and GetEntitySpeed(car) < 3 then
		--Delete Car
		SetEntityAsNoLongerNeeded(car)
		DeleteEntity(car)

	    --Remove delivery zone
	    RemoveBlip(deliveryblip)

	    --Pay the poor fella
		TriggerServerEvent('esx_carthief:pay', allvehicles[randomvehicle].payment)

		--Register Activity
		TriggerServerEvent('esx_carthief:registerActivity', 0)

	    --For delivery blip
	    isTaken = 0
	    isDelivered = 1

		--Remove Last Cop Blips
	    TriggerServerEvent('esx_carthief:stopalertcops')
	else
		TriggerEvent('esx:showNotification', _U('car_provided_rule'))
  	end
end

function AbortDelivery()
	--Delete Car
	SetEntityAsNoLongerNeeded(car)
	DeleteEntity(car)

	--Remove delivery zone
	RemoveBlip(deliveryblip)

	--Register Activity
	TriggerServerEvent('esx_carthief:registerActivity', 0)

	--For delivery blip
	isTaken = 0

	--For delivery blip
	isDelivered = 1

	--Remove Last Cop Blips
	TriggerServerEvent('esx_carthief:stopalertcops')
end

--Check if player left car
Citizen.CreateThread(function()
  while true do
    Wait(1000)
		if isTaken == 1 and isDelivered == 0 and not (GetVehiclePedIsIn(GetPlayerPed(-1), false) == car) then
			TriggerEvent('esx:showNotification', _U('get_back_car_1m'))
			Wait(50000)
			if isTaken == 1 and isDelivered == 0 and not (GetVehiclePedIsIn(GetPlayerPed(-1), false) == car) then
				TriggerEvent('esx:showNotification', _U('get_back_car_10s'))
				Wait(10000)
				TriggerEvent('esx:showNotification', _U('mission_failed'))
				AbortDelivery()
			end
		end
	end
end)

-- Send location
Citizen.CreateThread(function()
  	while true do
	    Citizen.Wait(Config.BlipUpdateTime)
	    if isTaken == 1 and IsPedInAnyVehicle(GetPlayerPed(-1)) then
			local coords = GetEntityCoords(GetPlayerPed(-1))
	  		TriggerServerEvent('esx_carthief:alertcops', coords.x, coords.y, coords.z)
		elseif isTaken == 1 and not IsPedInAnyVehicle(GetPlayerPed(-1)) then
			TriggerServerEvent('esx_carthief:stopalertcops')
	    end
  	end
end)

RegisterNetEvent('esx_carthief:removecopblip')
AddEventHandler('esx_carthief:removecopblip', function()
	RemoveBlip(copblip)
end)

RegisterNetEvent('esx_carthief:setcopblip')
AddEventHandler('esx_carthief:setcopblip', function(cx,cy,cz)
	RemoveBlip(copblip)
    copblip = AddBlipForCoord(cx,cy,cz)
    SetBlipSprite(copblip , 161)
    SetBlipScale(copblipy , 2.0)
	SetBlipColour(copblip, Config.CopBlipColour)
	PulseBlip(copblip)
end)

RegisterNetEvent('esx_carthief:setcopnotification')
AddEventHandler('esx_carthief:setcopnotification', function()
	ESX.ShowNotification(_U('car_stealing_in_progress'))
end)

AddEventHandler('esx_carthief:hasEnteredMarker', function(zone)
  	if LastZone == 'menucarthief' then
	    CurrentAction     = 'carthief_menu'
	    CurrentActionMsg  = _U('steal_a_car')
	    CurrentActionData = {zone = zone}
  	elseif LastZone == 'cardelivered' then
	    CurrentAction     = 'cardelivered_menu'
	    CurrentActionMsg  = _U('drop_car_off')
	    CurrentActionData = {zone = zone}
  	end
end)

AddEventHandler('esx_carthief:hasExitedMarker', function(zone)
	CurrentAction = nil
	ESX.UI.Menu.CloseAll()
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
  	while true do
		Wait(0)
		local coords      = GetEntityCoords(GetPlayerPed(-1))
		local isInMarker  = false
		local currentZone = nil
      
		if(GetDistanceBetweenCoords(coords, Config.Zones.VehicleSpawner.Pos.x, Config.Zones.VehicleSpawner.Pos.y, Config.Zones.VehicleSpawner.Pos.z, true) < 3) then
			isInMarker  = true
			currentZone = 'menucarthief'
			LastZone    = 'menucarthief'
		end
      
		if isTaken == 1 and (GetDistanceBetweenCoords(coords, alldeliveries[randomdelivery].posx, alldeliveries[randomdelivery].posy, alldeliveries[randomdelivery].posz, true) < 3) then
			isInMarker  = true
			currentZone = 'cardelivered'
			LastZone    = 'cardelivered'
		end
      
		if isInMarker and not HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = true
			TriggerEvent('esx_carthief:hasEnteredMarker', currentZone)
		end

		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('esx_carthief:hasExitedMarker', LastZone)
		end
	end
end)

-- Key Controls
Citizen.CreateThread(function()
  	while true do
	    Citizen.Wait(0)
	    if CurrentAction ~= nil then
	      	SetTextComponentFormat('STRING')
	      	AddTextComponentString(CurrentActionMsg)
	      	DisplayHelpTextFromStringLabel(0, 0, 1, -1)

	      	if IsControlJustReleased(0, 38) then
		        if CurrentAction == 'carthief_menu' then
		          	SpawnCar()
	        	elseif CurrentAction == 'cardelivered_menu' then
	          		FinishDelivery()
	        	end
	        CurrentAction = nil
	      	end
	    end
  	end
end)

-- Display markers for Zones
Citizen.CreateThread(function()
  	while true do
	    Wait(0)
	    local coords = GetEntityCoords(GetPlayerPed(-1))
	    for k,v in pairs(Config.Zones) do
			if (v.MarkerType ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
				DrawMarker(v.MarkerType, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.MarkerColour.r, v.MarkerColour.g, v.MarkerColour.b, 100, false, true, 2, false, false, false, false)
			end
		end
  	end
end)

-- Display markers for delivery place
Citizen.CreateThread(function()
  	while true do
    	Wait(0)
	    if isTaken == 1 and isDelivered == 0 then
	    	local coords = GetEntityCoords(GetPlayerPed(-1))
	      	v = alldeliveries[randomdelivery]
			if (Config.DeliveryMarkerType ~= -1 and GetDistanceBetweenCoords(coords, v.posx, v.posy, v.posz, true) < Config.DrawDistance) then
				DrawMarker(Config.DeliveryMarkerType, v.posx, v.posy, v.posz, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 5.0, 5.0, 1.0, Config.DeliveryMarkerColour.r, Config.DeliveryMarkerColour.g, Config.DeliveryMarkerColour.b, 100, false, false, 2, false, false, false, false)
			end
	    end
  	end
end)

-- Create Blips for Car Spawner
Citizen.CreateThread(function()
    info = Config.Zones.VehicleSpawner
    info.blip = AddBlipForCoord(info.Pos.x, info.Pos.y, info.Pos.z)
    SetBlipSprite(info.blip, info.Sprite)
    SetBlipDisplay(info.blip, 4)
    SetBlipScale(info.blip, 1.0)
    SetBlipColour(info.blip, info.BlipColour)
    SetBlipAsShortRange(info.blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(info.Title)
    EndTextCommandSetBlipName(info.blip)
end)
