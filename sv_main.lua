ESX = nil

local usersRadios = {}


TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterCommand("mdt", function(source)
    local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
    local rank = xPlayer.getJob().grade_label
    if xPlayer.job.name == "police" or xPlayer.job.name == "ambulance" then
        TriggerClientEvent('np-mdt:open', src, rank, xPlayer.variables.firstName, xPlayer.variables.lastName)
    end
end)

local CallSigns = {}
function GetCallsign(identifier)
	local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT `callsign` FROM `users` WHERE identifier = @identifier', { ["@identifier"] = identifier })
    if result[1] ~= nil and result[1].callsign ~= nil then
        return result[1].callsign
    elseif CallSigns[identifier] then
        return CallSigns[identifier]
    else
        return 0
    end
end

RegisterServerEvent('np-mdt:setRadio')
AddEventHandler("np-mdt:setRadio", function(radio)
    local src = source
    local user = exports["np-base"]:getModule("Player"):GetUser(src)
    local char = user:getCurrentCharacter()
    if not user then
        return
    end
    usersRadios[tonumber(char.id)] = radio
end)

RegisterServerEvent('police:setCallSign')
AddEventHandler("police:setCallSign", function(callsign)
    local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
    local char = xPlayer.getJob().grade_salary
    if not xPlayer then
        return
    end
    CallSigns[tonumber(char)] = callsign
end)

RegisterServerEvent("np-mdt:opendashboard")
AddEventHandler("np-mdt:opendashboard", function()
    local src = source
    UpdateWarrants(src)
    Updatebulletin(src)
    UpdateDispatch(src)
    UpdateUnits(src)
    getVehicles(src)
    getProfiles(src)
    UpdateReports(src)
end)

function UpdateWarrants(src)
    local firsttime = true
    local result = MysqlConverter(Config.Mysql,'fetchAll', 'SELECT * FROM ___mdw_incidents', {})
    local warrnts = {}

    for k, v in pairs(result) do
        for k2, v2 in ipairs(json.decode(v.associated)) do
            if v2.warrant == true then
                TriggerClientEvent("np-mdt:dashboardWarrants", src, {
                    firsttime = firsttime,
                    time = v.time,
                    linkedincident = v.id,
                    reporttitle = v.title,
                    name = v2.name,
                    cid = v2.cid
                })
                firsttime = false
            end
        end
    end
end

function UpdateReports(src)
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ____mdw_reports', {})
    TriggerClientEvent("np-mdt:dashboardReports", src, result)
end

function Updatebulletin(src)
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ___mdw_bulletin', {})
    TriggerClientEvent("np-mdt:dashboardbulletin", src, result)
end

function UpdateUnits(src)
    local lspd, bcso, sahp, sasp, doc, sapr, pa, ems = {}, {}, {}, {}, {}, {}, {}, {}
	
    for k, v in pairs(ESX.GetPlayers()) do
	local xPlayer = ESX.GetPlayerFromId(tonumber(v))
        if xPlayer then
		    local xPlayerjob = xPlayer.getJob()
            if xPlayerjob.name == "police" or xPlayerjob.name == "ambulance" then
                local character = xPlayer.getIdentifier()
                local rank = xPlayerjob.grade and xPlayerjob.grade or 0
                local name = xPlayer.getName()
                local callSign = GetCallsign(character)
                if xPlayerjob.name == "police" then
                    lspds = #lspd + 1
                    lspd[lspds] = {}
                    lspd[lspds].duty = 1
                    lspd[lspds].cid = character
                    lspd[lspds].radio = usersRadios[character] or nil
                    lspd[lspds].callsign = callSign
                    lspd[lspds].name = name
                elseif xPlayerjob.name == "ambulance" then
                    emss = #ems + 1
                    ems[emss] = {}
                    ems[emss].duty = 1
                    ems[emss].cid = character
                    ems[emss].radio = usersRadios[character] or nil
                    ems[emss].callsign = callSign
                    ems[emss].name = name
                end
            end
        end
    end
    TriggerClientEvent("np-mdt:getActiveUnits", src, lspd, bcso, sahp, sasp, doc, sapr, pa, ems)
end

function getVehicles(src)
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM owned_vehicles aa LEFT JOIN vehicle_mdt a ON a.license_plate = aa.plate LEFT JOIN ____mdw_bolos at ON at.license_plate = aa.plate ORDER BY time ASC', {})
    for k, v in pairs(result) do
        if v.image and v.image ~= nil and v.image ~= "" then
            result[k].image = v.image
        else
            result[k].image =
                "https://cdn.discordapp.com/attachments/832371566859124821/881624386317201498/Screenshot_1607.png"
        end

        local owner = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT owner FROM owned_vehicles WHERE plate = @plate', {['@plate'] = v.plate })
        result[k].owner = owner[1].owner

        if v.stolen and v.stolen ~= nil then
            result[k].stolen = v.stolen
        else
            result[k].stolen = false
        end
        if v.code and v.code ~= nil then
            result[k].code = v.code
        else
            result[k].code = false
        end
        if v.author and v.author ~= nil and v.title ~= nil then
            result[k].bolo = true
        else
            result[k].bolo = false
        end
    end
    TriggerClientEvent("np-mdt:searchVehicles", src, result, true)
end

RegisterServerEvent("np-mdt:getProfileData")
AddEventHandler("np-mdt:getProfileData", function(identifier)
    local src = source	
    local data = getProfile(identifier)
    TriggerClientEvent("np-mdt:getProfileData", src, data, false)
end)

RegisterServerEvent("np-mdt:getVehicleData")
AddEventHandler("np-mdt:getVehicleData", function(plate)
    local src = source
	local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM owned_vehicles aa LEFT JOIN vehicle_mdt a ON a.license_plate = aa.plate LEFT JOIN ____mdw_bolos at ON at.license_plate = aa.plate WHERE aa.plate = @plate LIMIT 1', {['@plate'] = plate })
    for k, v in pairs(result) do
        if v.image and v.image ~= nil and v.image ~= "" then
            result[k].image = v.image
        else
            result[k].image =
                "https://cdn.discordapp.com/attachments/832371566859124821/881624386317201498/Screenshot_1607.png"
        end
        local owner = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT owner FROM owned_vehicles WHERE plate = @plate', {['@plate'] = v.plate })
        result[k].owner = owner[1].owner

        if v.stolen and v.stolen ~= nil then
            result[k].stolen = v.stolen
        else
            result[k].stolen = false
        end
        if v.code and v.code ~= nil then
            result[k].code = v.code
        else
            result[k].code = false
        end
        if v.notes and v.notes ~= nil then
            result[k].information = v.notes
        else
            result[k].information = ""
        end

        if v.author and v.author ~= nil and v.title ~= nil then
            result[k].bolo = true
        else
            result[k].bolo = false
        end
    end
    TriggerClientEvent("np-mdt:updateVehicleDbId", src, result[1].id)
    TriggerClientEvent("np-mdt:getVehicleData", src, result)
end)

RegisterServerEvent("np-mdt:knownInformation")
AddEventHandler("np-mdt:knownInformation", function(dbid, type, status, plate)
	local saveData = {type = type, status = status}
    local result = MysqlConverter(Config.Mysql,'SELECT * FROM `vehicle_mdt` WHERE `license_plate` = @plate', { ['@plate'] = plate })
		if result[1] then
			if type == "stolen" then
				MysqlConverter(Config.Mysql, 'execute', 'UPDATE `vehicle_mdt` SET `stolen` = @stolen WHERE `license_plate` = @plate AND `dbid` = @dbid', {
				    ['@stolen'] = status,
					['@dbid'] = dbid,
					['@plate'] = plate,
				})
			elseif type == "code5" then
			    MysqlConverter(Config.Mysql, 'execute', 'UPDATE `vehicle_mdt` SET `code` = @code WHERE `license_plate` = @plate AND `dbid` = @dbid', {
				    ['@code'] = status,
					['@dbid'] = dbid,
					['@plate'] = plate,
				})
			end
		else
			if type == "stolen" then
			    MysqlConverter(Config.Mysql, 'execute', 'INSERT INTO `vehicle_mdt` (`license_plate`, `stolen`, `dbid`) VALUES (@plate, @stolen, @dbid)', {
			        ['@dbid'] = dbid,
			    	['@plate'] = plate,
			        ['@stolen'] = status
			    })
			elseif type == "code5" then
			    MysqlConverter(Config.Mysql, 'execute', 'INSERT INTO `vehicle_mdt` (`license_plate`, `code`, `dbid`) VALUES (@plate, @code, @dbid)', {
			        ['@dbid'] = dbid,
				    ['@plate'] = plate,
			        ['@code'] = status
			    })
			end
		end
end)

RegisterServerEvent("np-mdt:searchVehicles")
AddEventHandler("np-mdt:searchVehicles", function(plate)
    local src = source
    local lowerplate = string.lower('%'..plate..'%')
	local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM owned_vehicles aa LEFT JOIN vehicle_mdt a ON a.license_plate = aa.plate LEFT JOIN ____mdw_bolos at ON at.license_plate = aa.plate WHERE LOWER(plate) LIKE @plate ORDER BY plate ASC', { ['@plate'] = lowerplate })
    for k, v in pairs(result) do
        if v.image and v.image ~= nil and v.image ~= "" then
            result[k].image = v.image
        else
            result[k].image = "https://cdn.discordapp.com/attachments/832371566859124821/881624386317201498/Screenshot_1607.png"
        end
        
        local owner = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT owner FROM owned_vehicles WHERE plate = @plate', {['@plate'] = v.plate })
        result[k].owner = owner[1].owner

        if v.stolen and v.stolen ~= nil then
            result[k].stolen = v.stolen
        else
            result[k].stolen = false
        end
        if v.code and v.code ~= nil then
            result[k].code = v.code
        else
            result[k].code = false
        end
        if v.author and v.author ~= nil and v.title ~= nil then
            result[k].bolo = true
        else
            result[k].bolo = false
        end
    end
    TriggerClientEvent("np-mdt:searchVehicles", src, result)
end)

RegisterServerEvent("np-mdt:saveVehicleInfo")
AddEventHandler("np-mdt:saveVehicleInfo", function(dbid, plate,imageurl, notes)
	if imageurl == "" or not imageurl then imageurl = "" end
	if notes == "" or not notes then notes = "" end
	if dbid == 0 then return end
	if plate == "" then return end
	
	local usource = source
    local result = 	MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM `vehicle_mdt` WHERE `license_plate` = @license_plate', {['@license_plate'] = plate})
		if result[1] then
			MysqlConverter(Config.Mysql, 'execute', 'UPDATE `vehicle_mdt` SET `image` = @image, `notes` = @notes WHERE `license_plate` = @license_plate AND `dbid` = @dbid', {
			    ['@image'] = imageurl,
				['@dbid'] = dbid,
				['@license_plate'] = plate,
				['@notes'] = notes
			})
		else
			MysqlConverter(Config.Mysql, 'execute', 'INSERT INTO `vehicle_mdt` (`license_plate`, `stolen`, `notes`, `image`, `dbid`) VALUES (@license_plate, @stolen, @notes, @image, @dbid)', {
			    ['@dbid'] = dbid,
				['@license_plate'] = plate,
				['@stolen'] = 0,
				['@image'] = imageurl,				
				['@notes'] = notes
			})
		end
end)

RegisterServerEvent("np-mdt:saveProfile")
AddEventHandler("np-mdt:saveProfile", function(profilepic, information, identifier, fName, sName)
	if imageurl == "" or not imageurl then imageurl = "" end
	if notes == "" or not notes then notes = "" end
	if dbid == 0 then return end
	if plate == "" then return end
	
	local usource = source
	local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM `___mdw_profiles` WHERE `cid` = @cid', {['@cid'] = identifier})
		if result[1] then
			MysqlConverter(Config.Mysql, 'execute', 'UPDATE `___mdw_profiles` SET `image` = @image, `description` = @description, `name` = @name WHERE `cid` = @cid', {['@image'] = profilepic,	['@description'] = information,	['@name'] = fName .. " " .. sName, ['@cid'] = identifier})
		else
			MysqlConverter(Config.Mysql, 'execute', 'INSERT INTO `___mdw_profiles` (`cid`, `image`, `description`, `name`) VALUES (@cid, @image, @description, @name)', {['@cid'] = identifier,	['@image'] = profilepic, ['@description'] = information, ['@name'] = fName .. " " .. sName})
		end
end)

RegisterServerEvent("np-mdt:addGalleryImg")
AddEventHandler("np-mdt:addGalleryImg", function(identifier, url)
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM `___mdw_profiles` WHERE cid = @identifier', {["@identifier"] = identifier})
    if result and result[1] then
        result[1].gallery = json.decode(result[1].gallery)
        table.insert(result[1].gallery, url)
        MysqlConverter(Config.Mysql, 'execute', 'UPDATE `___mdw_profiles` SET `gallery` = @gallery WHERE `cid` = @identifier', {['@identifier'] = identifier, ['@gallery'] = json.encode(result[1].gallery)})
        end
end)

RegisterServerEvent("np-mdt:removeGalleryImg")
AddEventHandler("np-mdt:removeGalleryImg", function(identifier, url)
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM `___mdw_profiles` WHERE cid = @identifier', {["@identifier"] = identifier})
    if result and result[1] then
        result[1].gallery = json.decode(result[1].gallery)
        for k, v in ipairs(result[1].gallery) do
            if v == url then
                table.remove(result[1].gallery, k)
            end
        end
        MysqlConverter(Config.Mysql, 'execute', 'UPDATE `___mdw_profiles` SET `gallery` = @gallery WHERE `cid` = @identifier', {['@identifier'] = identifier, ['@gallery'] = json.encode(result[1].gallery)})
       end
end)

RegisterServerEvent("np-mdt:searchProfile")
AddEventHandler("np-mdt:searchProfile", function(query)
    local src = source
    local queryData = string.lower('%'..query..'%')
    local result = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM `users` WHERE LOWER(`firstname`) LIKE @var1 OR LOWER(`identifier`) LIKE @var2 OR LOWER(`lastname`) LIKE @var3 OR CONCAT(LOWER(`firstname`), ' ', LOWER(`lastname`), ' ', LOWER(`identifier`)) LIKE @var4 ORDER BY firstname DESC", {
         	         ['@var1'] = queryData,
         			 ['@var2'] = queryData,
         			 ['@var3'] = queryData,
         			 ['@var4'] = queryData
                    
         	})
	local licenses = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM user_licenses', {}) 	
	local mdw_profiles = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ___mdw_profiles', {}) 	

	for k, v in pairs(result) do	
        result[k].firstname = v.firstname
        result[k].lastname  = v.lastname
		
		local weapon2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @identifier AND type = @lictype', { ["@identifier"] = v.identifier, ["@lictype"] = 'Weapon'}) 		
		if weapon2 and weapon2[1] then
        if weapon2[1].status == 1 then 
			result[k].Weapon = true
		end
    end

		local drivers2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @identifier AND type = @lictype', { ["@identifier"] = v.identifier, ["@lictype"] = 'Drivers'}) 
		if drivers2 and drivers2[1] then
        if drivers2[1].status == 1 then 
			result[k].Drivers = true
		end
    end

		local hunting2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @identifier AND type = @lictype', { ["@identifier"] = v.identifier, ["@lictype"] = 'Hunting'})  
		if hunting2 and hunting2[1] then
        if hunting2[1].status == 1 then 
			result[k].Hunting = true
		end
    end

		local fishing2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @identifier AND type = @lictype', { ["@identifier"] = v.identifier, ["@lictype"] = 'Fishing'}) 
		if fishing2 and fishing2[1] then
        if fishing2[1].status == 1 then 
			result[k].Fishing = true
		end
    end

		local pilot2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @identifier AND type = @lictype', { ["@identifier"] = v.identifier, ["@lictype"] = 'Pilot'}) 
		if pilot2 and pilot2[1] then
        if pilot2[1].status == 1 then 
			result[k].Pilot = true
		end
    end
		
		local bar2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @identifier AND type = @lictype', { ["@identifier"] = v.identifier, ["@lictype"] = 'Bar'}) 
		if bar2 and bar2[1] then
        if bar2[1].status == 1 then 
			result[k].Bar = true
		end
    end

		local business2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @identifier AND type = @lictype', { ["@identifier"] = v.identifier, ["@lictype"] = 'Business'}) 
		if business2 and business2[1] then
        if business2[1].status == 1 then 
			result[k].Business = true
		end
    end
		
		result[k].policemdtinfo = ""
		result[k].pp = "https://media.discordapp.net/attachments/832371566859124821/872590513646239804/Screenshot_1522.png"
		for i=1, #mdw_profiles do
			if mdw_profiles[i].cid == v.idenitifer then
				if mdw_profiles[i].image and mdw_profiles[i].image ~= nil then
					result[k].pp = mdw_profiles[i].image		
				end
				if mdw_profiles[i].description and mdw_profiles[i].description ~= nil then
					result[k].policemdtinfo = mdw_profiles[i].description
				end
				result[k].policemdtinfo = mdw_profiles[i].description
			end
		end	
        result[k].warrant = false
        result[k].convictions = 0
        result[k].cid = v.idenitifer
	end
	
	TriggerClientEvent("np-mdt:searchProfile", src, result, true)
end)

function getProfile(identifier)
    local result = MysqlConverter(Config.Mysql,'fetchAll','SELECT * FROM users WHERE identifier = @identifier', {['@identifier'] = identifier})
    local resultI = MysqlConverter(Config.Mysql,'fetchAll','SELECT * FROM ___mdw_incidents', {})
	
    for k, v in pairs(resultI) do
        for k2, v2 in ipairs(json.decode(v.associated)) do
            if v2.cid == result[1].identifier then
                result[1].convictions = v2.charges
            end
        end
    end
    local vehresult = MysqlConverter(Config.Mysql,'fetchAll','SELECT * FROM owned_vehicles WHERE owner = @owner', {['@owner'] = identifier})
    result[1].vehicles = vehresult
    result[1].firstname = result[1].firstname
    result[1].lastname = result[1].lastname

    local weapon2 = MysqlConverter(Config.Mysql, 'fetchAll','SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = identifier, ['@lictype'] = 'Weapon'})
    if weapon2 and weapon2[1] then
    if weapon2[1].status == 1 then
        result[1].Weapon = true
    end
end

    local drivers2 = MysqlConverter(Config.Mysql, 'fetchAll','SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = identifier, ['@lictype'] = 'Drivers'})
    if drivers2 and drivers2[1] then   
    if drivers2[1].status == 1 then 
        result[1].Drivers = true
    end
end
    local hunting2 = MysqlConverter(Config.Mysql, 'fetchAll','SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = identifier, ['@lictype'] = 'Hunting'})
    if hunting2 and hunting2[1] then
    if hunting2[1].status == 1 then 
        result[1].Hunting = true
    end
end

    local fishing2 = MysqlConverter(Config.Mysql, 'fetchAll','SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = identifier, ['@lictype'] = 'Fishing'})
    if fishing2 and fishing2[1] then
    if fishing2[1].status == 1 then 
        result[1].Fishing = true
    end
end

    local pilot2 = MysqlConverter(Config.Mysql, 'fetchAll','SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = identifier, ['@lictype'] = 'Pilot'})
    if pilot2 and pilot2[1] then
    if pilot2[1].status == 1 then 
        result[1].Pilot = true
    end
end
    
    local bar2 = MysqlConverter(Config.Mysql, 'fetchAll','SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = identifier, ['@lictype'] = 'Bar'})
    if bar2 and bar2[1] then
    if bar2[1].status == 1 then 
        result[1].Bar = true
    end
end

    local business2 = MysqlConverter(Config.Mysql, 'fetchAll','SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = identifier, ['@lictype'] = 'Business'}) 
    if business2 and business2[1] then
    if business2[1].status == 1 then 
        result[1].Business = true
    end
end
	
    result[1].warrant = false
    result[1].identifier = result[1].identifier
    result[1].job = result[1].job

	local proresult = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ___mdw_profiles WHERE cid = @identifier LIMIT 1', {['@identifier'] = identifier})
    if proresult and proresult[1] ~= nil then
        result[1].profilepic = proresult[1].image
        result[1].tags = json.decode(proresult[1].tags)
        result[1].gallery = json.decode(proresult[1].gallery)
        result[1].policemdtinfo = proresult[1].description
    else
        result[1].tags = {}
        result[1].gallery = {}
        result[1].pp =
            "https://media.discordapp.net/attachments/832371566859124821/872590513646239804/Screenshot_1522.png"
    end
    return result[1]
end

function getProfiles(src)

    local result =  MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM users aa LEFT JOIN ___mdw_profiles at ON at.cid = aa.identifier ORDER BY firstname DESC', {})
	for k, v in pairs(result) do
        result[k].firstname = v.firstname
        result[k].lastname  = v.lastname


		local weapon = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = v.identifier, ['@lictype'] = 'Weapon'})
    if weapon and weapon[1] then
		if weapon[1].status == 1 then 
			result[k].Weapon = true
		end
    end
		
		local drivers2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = v.identifier, ['@lictype'] = 'Drivers'})
    if drivers2 and drivers2[1] then
		if drivers2[1].status == 1 then 
			result[k].Drivers = true
	    end
    end

		local hunting2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = v.identifier, ['@lictype'] = 'Hunting'}) 
        if hunting2 and hunting2[1] then
		if hunting2[1].status == 1 then 
			result[k].Hunting = true
		end
    end

		local fishing2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = v.identifier, ['@lictype'] = 'Fishing'})
		if fishing2 and fishing2[1] then
        if fishing2[1].status == 1 then 
			result[k].Fishing = true
		end
    end

		local bar2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = v.identifier, ['@lictype'] = 'Bar'}) 
		if bar2 and bar2[1] then
        if bar2[1].status == 1 then 
			result[k].Bar = true
		end
    end

		local business2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = v.identifier, ['@lictype'] = 'Business'})
		if business2 and business2[1] then
        if business2[1].status == 1 then 
			result[k].Business = true
		end
    end

		local pilot2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT status FROM user_licenses WHERE owner = @owner AND type = @lictype', {['@owner'] = v.identifier, ['@lictype'] = 'Pilot'})
		if pilot2 and pilot2[1] then
        if pilot2[1].status == 1 then 
			result[k].Pilot = true
		end
    end

        result[k].warrant = false
        result[k].convictions = 0
        result[k].cid = v.id
		
		if v.image and v.image ~= nil and v.image ~= "" then 
		    result[k].pp = v.image  
		else
		    result[k].pp = "https://media.discordapp.net/attachments/832371566859124821/872590513646239804/Screenshot_1522.png"
		end
	   	local proresult = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM `___mdw_profiles` WHERE `cid` = @identifier', { ['@identifier'] = v.identifier})
            if proresult and proresult[1] ~= nil then
	
        	result[k].pp = proresult[1].image		
       	    result[k].policemdtinfo = proresult[1].description
			end
    end
	TriggerClientEvent("np-mdt:searchProfile", src, result, true)
end



RegisterServerEvent("np-mdt:updateLicense")
AddEventHandler("np-mdt:updateLicense", function(identifier, type, status)
    local src = source
	local xPlayer = ESX.GetPlayerFromId(source)
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local time = os.date()
    if status == "revoke" then
        action = "Revoked"
    else
        action = "Given"
    end

    TriggerEvent("np-mdt:newLog",
        name .. " " .. action .. " licenses type: " .. firstToUpper(type) .. " Edited Citizen Id: " .. identifier, time)

    if status == "revoke" then
        MysqlConverter(Config.Mysql, 'execute', 'DELETE FROM user_licenses WHERE owner = @identifier AND type = @type', {['@identifier'] = identifier, ['@type'] = type})
    else
        MysqlConverter(Config.Mysql, 'execute', 'INSERT INTO user_licenses (type, owner, status) VALUES(@type, @owner, @status)', {['@type'] = type, ['@owner'] = identifier, ['@status'] = 1})
    end
end)

RegisterServerEvent("np-mdt:newBulletin")
AddEventHandler("np-mdt:newBulletin", function(title, info, time, id)
    local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local Bulletin = {
        title = title,
        id = id,
        info = info,
        time = time,
        src = src,
        author = name
    }
	MysqlConverter(Config.Mysql, 'execute', 'INSERT INTO ___mdw_bulletin (title, info, time, src, author, id) VALUES(@title, @info, @time, @src, @author, @id)', {
	    
		["@title"] = title,
		["@info"] = info,
		["@time"] = time,
		["@src"] = src,
		["@author"] = name,
		["@id"] = id	
	})
    TriggerEvent("np-mdt:newLog", name .. " Opened a new Bulletin: Title " .. title .. ", Info " .. info, time)
    TriggerClientEvent("np-mdt:newBulletin", -1, src, Bulletin, "police")
end)

RegisterServerEvent("np-mdt:deleteBulletin")
AddEventHandler("np-mdt:deleteBulletin", function(id)
    local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
	MysqlConverter(Config.Mysql, 'execute', 'DELETE FROM ___mdw_bulletin WHERE id = @id', {
            
        ["@id"] = id			
	})
    TriggerClientEvent("np-mdt:deleteBulletin", -1, src, id, "police")
end)

RegisterServerEvent("np-mdt:newLog")
AddEventHandler("np-mdt:newLog", function(text, time)

	MysqlConverter(Config.Mysql,'execute', 'INSERT INTO ___mdw_logs (text, time) VALUES(@text, @time)', {
	
	    ["@text"] = text,
		["@time"] = time
	})
end)

RegisterServerEvent("np-mdt:getAllLogs")
AddEventHandler("np-mdt:getAllLogs", function()
    local src = source
	local result = MysqlConverter(Config.Mysql,'fetchAll','SELECT * FROM ___mdw_logs LIMIT 120', {})
    TriggerClientEvent("np-mdt:getAllLogs", src, result)
end)

RegisterServerEvent("np-mdt:getAllIncidents")
AddEventHandler("np-mdt:getAllIncidents", function()
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ___mdw_incidents', {})
    TriggerClientEvent("np-mdt:getAllIncidents", src, result)
end)

RegisterServerEvent("np-mdt:getIncidentData")
AddEventHandler("np-mdt:getIncidentData", function(id)
    local src = source
    local result = MysqlConverter(Config.Mysql,'fetchAll', 'SELECT * FROM ___mdw_incidents WHERE id = @id', { ["@id"] = id })
    result[1].tags = json.decode(result[1].tags)
    result[1].officersinvolved = json.decode(result[1].officers)
    result[1].civsinvolved = json.decode(result[1].civilians)
    result[1].evidence = json.decode(result[1].evidence)
    result[1].convictions = json.decode(result[1].associated)
    result[1].charges = json.decode(result[1].associated.charges)
    TriggerClientEvent("np-mdt:updateIncidentDbId", src, result[1].id)
    TriggerClientEvent("np-mdt:getIncidentData", src, result[1], json.decode(result[1].associated))
end)

RegisterServerEvent("np-mdt:incidentSearchPerson")
AddEventHandler("np-mdt:incidentSearchPerson", function(query1)
    local src = source
    local queryData = string.lower('%' .. query1 .. '%')
	local result = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT firstname, lastname, identifier FROM `users`  WHERE LOWER(`firstname`) LIKE @var1 OR LOWER(`identifier`) LIKE @var2 OR LOWER(`lastname`) LIKE @var3 OR CONCAT(LOWER(`firstname`), ' ', LOWER(`lastname`), ' ', LOWER(`identifier`)) LIKE @var4", {
	    
		["@var1"] = queryData,
		["@var2"] = queryData,
		["@var3"] = queryData,
		["@var4"] = queryData,
		
	})
    local mdw_profiles = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ___mdw_profiles', {})
    for k, v in pairs(result) do
        result[k].firstname = v.firstname
        result[k].lastname = v.lastname
        result[k].profilepic = "https://media.discordapp.net/attachments/832371566859124821/872590513646239804/Screenshot_1522.png"
        for i = 1, #mdw_profiles do
            if mdw_profiles[i].cid == v.identifier then
                if mdw_profiles[i].image and mdw_profiles[i].image ~= nil then
                    result[k].profilepic = mdw_profiles[i].image
                end
            end
        end
    end
    TriggerClientEvent('np-mdt:incidentSearchPerson', src, result)
end)

RegisterServerEvent("np-mdt:removeIncidentCriminal")
AddEventHandler("np-mdt:removeIncidentCriminal", function(cid, icId)

    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local time = os.time()
    local action = "Removed a criminal from an incident, incident ID: " .. icId
    local Cname = ""
    local result = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM ___mdw_incidents WHERE id = @id", {["@id"] = icId})
    for k, v in pairs(result) do
        for k2, v2 in ipairs(json.decode(v.associated)) do
            if v2.cid == cid then
                table.remove(v2, k)
                Cname = v2.name
            end
        end
    end
    TriggerEvent("np-mdt:newLog",
        name .. ", " .. action .. ", Criminal Citizen Id: " .. cid .. ", Name: " .. Cname .. "", time)
    MysqlConverter(Config.Mysql, 'execute', 'UPDATE ___mdw_incidents SET tags = @tags WHERE id = @id', {["@tags"] = json.encode(result[1].associated), ["@id"] = icId})
end)

RegisterServerEvent("np-mdt:searchIncidents")
AddEventHandler("np-mdt:searchIncidents", function(query)
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM `___mdw_incidents` WHERE id = @query", {['@query'] = tonumber(query)})

    TriggerClientEvent('np-mdt:getIncidents', src, result)
end)

RegisterServerEvent("np-mdt:saveIncident")
AddEventHandler("np-mdt:saveIncident", function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
  
    for i = 1, #data.associated do
        local result2 = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM users WHERE identifier = @identifier', { ["@identifier"] = data.associated[i].cid})
        if result2 and result2[1] then
        data.associated[i].name = result2[1].firstname .. " " .. result2[1].lastname
       end
    end
    if data.ID ~= 0 then
        MysqlConverter(Config.Mysql, 'execute', 'UPDATE `___mdw_incidents` SET `title` = @title, `author` = @author, `time` = @time, `details` = @details, `tags` = @tags, `officers` = @officers, `civilians` = @civilians, `evidence` = @evidence, `associated` = @associated WHERE `id` = @id',
            {
                ['@id'] = data.ID,
                ['@title'] = data.title,
                ['@author'] = name,
                ['@time'] = data.time,
                ['@details'] = data.information,
                ['@tags'] = json.encode(data.tags),
                ['@officers'] = json.encode(data.officers),
                ['@civilians'] = json.encode(data.civilians),
                ['@evidence'] = json.encode(data.evidence),
                ['@associated'] = json.encode(data.associated)
            })
    else
        MysqlConverter(Config.Mysql, 'execute', 'INSERT INTO `___mdw_incidents` (`title`, `author`, `time`, `details`, `tags`, `officers`, `civilians`, `evidence`, `associated`) VALUES (@title, @author, @time, @details, @tags, @officers, @civilians, @evidence, @associated)',
            {
                ['@title'] = data.title,
                ['@author'] = name,
                ['@time'] = data.time,
                ['@details'] = data.information,
                ['@tags'] = json.encode(data.tags),
                ['@officers'] = json.encode(data.officers),
                ['@civilians'] = json.encode(data.civilians),
                ['@evidence'] = json.encode(data.evidence),
                ['@associated'] = json.encode(data.associated)
            })
    end
end)

RegisterServerEvent("np-mdt:newTag")
AddEventHandler("np-mdt:newTag", function(cid, tag)
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ___mdw_profiles WHERE cid = @identifier', {['@identifier'] = cid})
    local newTags = {}
    if result and result[1] then

        result[1].tags = json.decode(result[1].tags)
        table.insert(result[1].tags, tag)
        MysqlConverter(Config.Mysql, 'execute', 'UPDATE `___mdw_profiles` SET `tags` = @tags WHERE `cid` = @cid', {
            ['@cid'] = cid,
            ['@tags'] = json.encode(result[1].tags)
        })
    else
        newTags[1] = tag
        MysqlConverter(Config.Mysql, 'execute','INSERT INTO `___mdw_profiles` (`cid`, `image`, `description`, `name`) VALUES (@cid, @image, @description, @name)',
            {
                ['@cid'] = cid,
                ['@image'] = "",
                ['@description'] = "",
                ['@tags'] = json.encode(newTags),
                ['@name'] = ""
            })
    end
end)

RegisterServerEvent("np-mdt:removeProfileTag")
AddEventHandler("np-mdt:removeProfileTag", function(cid, tag)
    local query = "SELECT * FROM ___mdw_profiles WHERE cid = ?"
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ___mdw_profiles WHERE cid = @identifier', {['@identifier'] = cid})
    if result and result[1] then
        result[1].tags = json.decode(result[1].tags)
        for k, v in ipairs(result[1].tags) do
            if v == tag then
                table.remove(result[1].tags, k)
            end
        end
        MysqlConverter(Config.Mysql, 'execute', 'UPDATE ___mdw_profiles SET tags = @tags WHERE cid = @identifier', {['@tags'] = json.encode(result[1].tags), ['@identifier'] = cid })
    end
end)

RegisterServerEvent("np-mdt:getPenalCode")
AddEventHandler("np-mdt:getPenalCode", function()
    local src = source
    local titles = {}
    local penalcode = {}
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM fine_types ORDER BY category ASC', {})
    for i = 1, #result do
        local id = result[i].id
        local res = result[i]
        titles[id] = result[i].label
        penalcode[id] = {}
        local color = "green"
        class = "Infraction"
        if res.category == 1 then
            color = "orange"
            class = "Misdemeanor"
        elseif res.category == 2 or res.category == 3 then
            color = "red"
            class = "Felony"
        end
        penalcode[id].color = color

        penalcode[id].title = res.label
        penalcode[id].id = res.id
        penalcode[id].class = class
        penalcode[id].months = res.jailtime
        penalcode[id].fine = res.jailtime
    end
    TriggerClientEvent('np-mdt:getPenalCode', src, titles, penalcode)
end)

RegisterServerEvent("np-mdt:getAllBolos")
AddEventHandler("np-mdt:getAllBolos", function()
    local src = source
	local result =  MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ____mdw_bolos', {})
    TriggerClientEvent("np-mdt:getBolos", src, result)
end)

RegisterServerEvent("np-mdt:getBoloData")
AddEventHandler("np-mdt:getBoloData", function(id)
    local src = source
	local result = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM ____mdw_bolos WHERE dbid = @id", {["@id"] = id})
    result[1].tags = json.decode(result[1].tags)
    result[1].gallery = json.decode(result[1].gallery)
    result[1].officersinvolved = json.decode(result[1].officers)
    result[1].officers = json.decode(result[1].officers)
    TriggerClientEvent("np-mdt:getBoloData", src, result[1])
end)

RegisterServerEvent("np-mdt:searchBolos")
AddEventHandler("np-mdt:searchBolos", function(query)
    local src = source
    local result = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM `____mdw_bolos` WHERE LOWER(`license_plate`) LIKE @query OR LOWER(`title`) LIKE @query OR CONCAT(LOWER(`license_plate`), ' ', LOWER(`title`)) LIKE @query",
        {
            ['@query'] = string.lower('%' .. query .. '%') -- % wildcard, needed to search for all alike results
        })
        TriggerClientEvent("np-mdt:getBolos", src, result)
end)

RegisterServerEvent("np-mdt:newBolo")
AddEventHandler("np-mdt:newBolo", function(data)
    if data.title == "" then return end
    local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
    local char = xPlayer.getIdentifier()
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM `____mdw_bolos` WHERE `dbid` = @id', {['@id'] = data.id})
        if data.id ~= nil and data.id ~= 0 then
            MysqlConverter(Config.Mysql, 'execute', 'UPDATE `____mdw_bolos` SET `title` = @title, `license_plate` = @plate, `owner` = @owner, `individual` = @individual, `detail` = @detail, `tags` = @tags, `gallery` = @gallery, `officers` = @officers, `time` = @time, `author` = @author WHERE `dbid` = @id',
                {
                    ['@title'] = data.title,
                    ['@plate'] = data.plate,
                    ['@owner'] = data.owner,
                    ['@individual'] = data.individual,
                    ['@detail'] = data.detail,
                    ['@tags'] = json.encode(data.tags),
                    ['@gallery'] = json.encode(data.gallery),
                    ['@officers'] = json.encode(data.officers),
                    ['@time'] = data.time,
                    ['@author'] = name,
                    ['@id'] = data.id
                })
        else
            MysqlConverter(Config.Mysql, 'execute', 'INSERT INTO `____mdw_bolos` (`title`, `license_plate`, `owner`, `individual`, `detail`, `tags`, `gallery`, `officers`, `time`, `author`) VALUES (@title, @plate, @owner, @individual, @detail, @tags, @gallery, @officers, @time, @author)',
                {
                    ['@title'] = data.title,
                    ['@plate'] = data.plate,
                    ['@owner'] = data.owner,
                    ['@individual'] = data.individual,
                    ['@detail'] = data.detail,
                    ['@tags'] = json.encode(data.tags),
                    ['@gallery'] = json.encode(data.gallery),
                    ['@officers'] = json.encode(data.officers),
                    ['@time'] = data.time,
                    ['@author'] = name

                })
			local result2 = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM ____mdw_bolos ORDER BY dbid DESC LIMIT 1", {})
            TriggerClientEvent("np-mdt:boloComplete", src, result2[1].dbid)
        end
end)

RegisterServerEvent("np-mdt:deleteBolo")
AddEventHandler("np-mdt:deleteBolo", function(id)
    local src = source
	MysqlConverter(Config.Mysql, 'execute', "DELETE FROM ____mdw_bolos WHERE dbid = @id", {
	    ["@id"] = id
	})
end)

local attachedUnits = {}
RegisterServerEvent("np-mdt:attachedUnits")
AddEventHandler("np-mdt:attachedUnits", function(callid)
    local src = source
    if not attachedUnits[callid] then
        local id = #attachedUnits + 1
        attachedUnits[callid] = {}
    end
    TriggerClientEvent("np-mdt:attachedUnits", src, attachedUnits[callid], callid)
end)

RegisterServerEvent("np-mdt:callDragAttach")
AddEventHandler("np-mdt:callDragAttach", function(callid, cid)
    local src = source

    local targetPlayer = ESX.GetPlayerFromIdentifier(cid)
    if targetPlayer == false then
        return
    end
    local name = targetPlayer.variables.firstName .. " " .. targetPlayer.variables.lastName
    local userjob = targetPlayer.getJob().name

    local id = callid

    attachedUnits[id] = {}
    attachedUnits[id][cid] = {}

    local units = 0
    for k, v in ipairs(attachedUnits[id]) do
        units = units + 1
    end

    attachedUnits[id][cid].job = userjob
    attachedUnits[id][cid].callsign = GetCallsign(cid)
    attachedUnits[id][cid].fullname = name
    attachedUnits[id][cid].cid = cid
    attachedUnits[id][cid].callid = callid
    attachedUnits[id][cid].radio = units
    TriggerClientEvent("np-mdt:callAttach", -1, callid, units)
end)

RegisterServerEvent("np-mdt:callAttach")
AddEventHandler("np-mdt:callAttach", function(callid)
    local src = source

    --local user = exports["np-base"]:getModule("Player"):GetUser(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local userjob = xPlayer.getJob().name
    local id = callid
    local cid = xPlayer.getIdentifier()
    attachedUnits[id] = {}
    attachedUnits[id][cid] = {}

    local units = 0
    for k, v in pairs(attachedUnits[id]) do
        units = units + 1
    end
    attachedUnits[id][cid].job = userjob
    attachedUnits[id][cid].callsign = GetCallsign(cid)
    attachedUnits[id][cid].fullname = name
    attachedUnits[id][cid].cid = cid
    attachedUnits[id][cid].callid = callid
    attachedUnits[id][cid].radio = units

    TriggerClientEvent("np-mdt:callAttach", -1, callid, units)
end)

RegisterServerEvent("np-mdt:callDetach")
AddEventHandler("np-mdt:callDetach", function(callid)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local charid = xPlayer.getIdentifier()
    local id = callid
    attachedUnits[id][charid] = nil
    local units = 0
    for k, v in ipairs(attachedUnits[id]) do
        units = units + 1
    end
    TriggerClientEvent("np-mdt:callDetach", -1, callid, units)
end)

RegisterServerEvent("np-mdt:callDispatchDetach")
AddEventHandler("np-mdt:callDispatchDetach", function(callid, cid)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local id = callid

    attachedUnits[id][cid] = nil

    local units = 0
    for k, v in ipairs(attachedUnits[id]) do
        units = units + 1
    end
    TriggerClientEvent("np-mdt:callDetach", -1, callid, units)
end)

RegisterServerEvent("np-mdt:setWaypoint:unit")
AddEventHandler("np-mdt:setWaypoint:unit", function(cid)
    local src = source

    local targetPlayer = ESX.GetPlayerFromIdentifier(cid)
    if targetPlayer == false then
        return
    end
    local coords = targetPlayer.getCoords(true)
    TriggerClientEvent("np-mdt:setWaypoint:unit", src, coords)
end)

RegisterServerEvent("np-mdt:setDispatchWaypoint")
AddEventHandler("np-mdt:setDispatchWaypoint", function(callid, cid)
    local src = source
    local targetPlayer = ESX.GetPlayerFromIdentifier(cid)
    if targetPlayer == false then
        return
    end
    local coords = targetPlayer.getCoords(true)
    TriggerClientEvent("np-mdt:setWaypoint:unit", src, coords)
end)

local CallResponses = {}

RegisterServerEvent("np-mdt:getCallResponses")
AddEventHandler("np-mdt:getCallResponses", function(callid)
    local src = source
    if not CallResponses[callid] then
        CallResponses[callid] = {}
    end
    TriggerClientEvent("np-mdt:getCallResponses", src, CallResponses[callid], callid)
end)

RegisterServerEvent("np-mdt:sendCallResponse")
AddEventHandler("np-mdt:sendCallResponse", function(message, time, callid, name)
    local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
    local char = xPlayer.getIdentifier()
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    if not CallResponses[callid] then
        CallResponses[callid] = {}
    end
    local id = #CallResponses[callid] + 1
    CallResponses[callid][id] = {}

    CallResponses[callid][id].name = name
    CallResponses[callid][id].message = message
    CallResponses[callid][id].time = time

    TriggerClientEvent("np-mdt:sendCallResponse", src, message, time, callid, name)
end)

RegisterServerEvent("np-mdt:getAllReports")
AddEventHandler("np-mdt:getAllReports", function()
    local src = source
	local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ____mdw_reports', {})
    TriggerClientEvent("np-mdt:getAllReports", src, result)
end)

RegisterServerEvent("np-mdt:getReportData")
AddEventHandler("np-mdt:getReportData", function(id)
    local src = source
	local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ____mdw_reports WHERE dbid = @id', {
	["@id"] = id
	})
    result[1].tags = json.decode(result[1].tags)
    result[1].gallery = json.decode(result[1].gallery)
    result[1].officersinvolved = json.decode(result[1].officers)
    result[1].officers = json.decode(result[1].officers)
    result[1].civsinvolved = json.decode(result[1].civsinvolved)
    TriggerClientEvent("np-mdt:getReportData", src, result[1])
end)

RegisterServerEvent("np-mdt:searchReports")
AddEventHandler("np-mdt:searchReports", function(querydata)
    local src = source
    local string = string.lower('%' .. querydata .. '%')
	local result = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM ____mdw_reports aa WHERE LOWER(`type`) LIKE @var1 OR LOWER(`title`) LIKE @var2 OR LOWER(`dbid`) LIKE @var3 OR CONCAT(LOWER(`type`), ' ', LOWER(`title`), ' ', LOWER(`dbid`)) LIKE @var4", {
	     ["@var1"] = string,
		 ["@var2"] = string,
		 ["@var3"] = string,
		 ["@var4"] = string	
	})
    TriggerClientEvent("np-mdt:getAllReports", src, result)
end)

RegisterServerEvent("np-mdt:newReport")
AddEventHandler("np-mdt:newReport", function(data)
    if data.title == "" then
        return
    end
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local time = os.date()

    local result = MysqlConverter(Config.Mysql, 'fetchAll' ,'SELECT * FROM `____mdw_reports` WHERE `dbid` = @id', {
        ['@id'] = data.id
    })
        if data.id ~= nil and data.id ~= 0 then

            local action = "Edit A Report, Profile ID: " .. data.id
            TriggerEvent("np-mdt:newLog", name .. ", " .. action .. ", Changes: " .. json.encode(data), time)

            MysqlConverter(Config.Mysql, 'execute', 'UPDATE `____mdw_reports` SET `title` = @title, `type` = @type, `detail` = @detail, `tags` = @tags, `gallery` = @gallery, `officers` = @officers, `civsinvolved` = @civsinvolved, `time` = @time, `author` = @author WHERE `dbid` = @id',
                {
                    ['@title'] = data.title,
                    ['@type'] = data.type,
                    ['@detail'] = data.detail,
                    ['@tags'] = json.encode(data.tags),
                    ['@gallery'] = json.encode(data.gallery),
                    ['@officers'] = json.encode(data.officers),
                    ['@civsinvolved'] = json.encode(data.civilians),
                    ['@time'] = data.time,
                    ['@author'] = name,
                    ['@id'] = data.id
                })
        else
            MysqlConverter(Config.Mysql, 'execute', 'INSERT INTO `____mdw_reports` (`title`, `type`, `detail`, `tags`, `gallery`, `officers`, `civsinvolved`, `time`, `author`) VALUES (@title, @type, @detail, @tags, @gallery, @officers, @civsinvolved, @time, @author)',
                {
                    ['@title'] = data.title,
                    ['@type'] = data.type,
                    ['@detail'] = data.detail,
                    ['@tags'] = json.encode(data.tags),
                    ['@gallery'] = json.encode(data.gallery),
                    ['@officers'] = json.encode(data.officers),
                    ['@civsinvolved'] = json.encode(data.civilians),
                    ['@time'] = data.time,
                    ['@author'] = name
                })
            Wait(500)
			local result2 = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM ____mdw_reports ORDER BY dbid DESC LIMIT 1", {})
            TriggerClientEvent("np-mdt:reportComplete", src, result2[1].dbid)
        end
end)

function UpdateDispatch(src)
	local result = MysqlConverter(Config.Mysql, 'fetchAll', "SELECT * FROM ___mdw_messages LIMIT 200", {})
    TriggerClientEvent("np-mdt:dashboardMessages", src, result)
end

RegisterServerEvent("np-mdt:sendMessage")
AddEventHandler("np-mdt:sendMessage", function(message, time)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local char = xPlayer.getIdentifier()
    local name = xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
    local pic = "https://media.discordapp.net/attachments/832371566859124821/872590513646239804/Screenshot_1522.png"
	
	local result = MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ___mdw_profiles WHERE cid = @identifier', { ["@identifier"] = char })
    if result and result[1] ~= nil then
        if result[1].image and result[1].image ~= nil and result[1].image ~= "" then
            pic = result[1].image
        end
    end
	MysqlConverter(Config.Mysql, 'execute', 'INSERT INTO ___mdw_messages (name, message, time, profilepic, job) VALUES(@name, @message, @time, @pic, @job)', {
	   ["@name"] = name,
	   ["@message"] = message,
	   ["@time"] = time,
	   ["@pic"] = pic,
	   ["@job"] = 'police'	
	})
    local lastMsg = {
        name = name,
        message = message,
        time = time,
        profilepic = pic,
        job = "police"
    }
    TriggerClientEvent("np-mdt:dashboardMessage", -1, lastMsg)
end)

RegisterServerEvent("np-mdt:refreshDispatchMsgs")
AddEventHandler("np-mdt:refreshDispatchMsgs", function()
    local src = source
	MysqlConverter(Config.Mysql, 'fetchAll', 'SELECT * FROM ___mdw_messages LIMIT 200', {})
    TriggerClientEvent("np-mdt:dashboardMessages", src, result)
end)

-- RegisterNetEvent('np-mdt:dashboardMessage')
-- AddEventHandler('np-mdt:dashboardMessage', function(sentData)
--     local job = exports["isPed"]:isChar("myjob")
--     if job == "police" or job.name == 'ambulance' then
--         SendNUIMessage({ type = "dispatchmessage", data = sentData })
--     end
-- end)

RegisterServerEvent("np-mdt:setCallsign")
AddEventHandler("np-mdt:setCallsign", function(identifier, callsign)
    MysqlConverter(Config.Mysql, 'execute', "UPDATE users SET `callsign` = @callsign WHERE identifier = @identifier", {
        ['@callsign'] = callsign,
        ['@identifier'] = identifier
    })
end)

function tprint(t, s)
    for k, v in pairs(t) do
        local kfmt = '["' .. tostring(k) .. '"]'
        if type(k) ~= 'string' then
            kfmt = '[' .. k .. ']'
        end
        local vfmt = '"' .. tostring(v) .. '"'
        if type(v) == 'table' then
            tprint(v, (s or '') .. kfmt)
        else
            if type(v) ~= 'string' then
                vfmt = tostring(v)
            end
            print(type(t) .. (s or '') .. kfmt .. ' = ' .. vfmt)
        end
    end
end

function getUserFromCid(cid)
    local users = exports["np-base"]:getModule("Player"):GetUsers()
    for k, v in pairs(users) do
        local user = exports["np-base"]:getModule("Player"):GetUser(v)
        if user then
            local char = user:getCurrentCharacter()
            if char.id == cid then
                return user
            end
        end
    end
    return false
end

function MysqlConverter(plugin,type,query,var)
	local wait = promise.new()
    if type == 'fetchAll' and plugin == 'mysql-async' then
		MySQL.Async.fetchAll(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'execute' and plugin == 'mysql-async' then
        MySQL.Async.execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'execute' and plugin == 'ghmattisql' then
        exports['ghmattimysql']:execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'fetchAll' and plugin == 'ghmattisql' then
        exports.ghmattimysql:execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'execute' and plugin == 'oxmysql' then
        exports.oxmysql:execute(query, var, function(result)
            wait:resolve(result)
        end)
    end
    if type == 'fetchAll' and plugin == 'oxmysql' then
		exports['oxmysql']:fetch(query, var, function(result)
			wait:resolve(result)
		end)
    end
	return Citizen.Await(wait)
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
