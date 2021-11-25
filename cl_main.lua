local isOpen = false
local callSign = ""

ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

function EnableGUI(enable)
    print("MDT Enable GUI", enable)
    if enable then TriggerServerEvent('np-mdt:opendashboard') end
    SetNuiFocus(enable, enable)
    SendNUIMessage({ type = "show", enable = enable, job = ESX.GetPlayerData().job.name })

    isOpen = enable
    TriggerEvent('np-mdt:animation')
end

function RefreshGUI()
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "show", enable = false, job = ESX.GetPlayerData().job.name })
    isOpen = false
end

RegisterCommand("forcemdt", function(source, args, rawCommand)
	EnableGUI(true)
end, false)

RegisterCommand("restartmdt", function(source, args, rawCommand)
	RefreshGUI()
end, false)


local tablet = 0
local tabletDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
local tabletAnim = "base"
local tabletProp = `prop_cs_tablet`
local tabletBone = 60309
local tabletOffset = vector3(0.03, 0.002, -0.0)
local tabletRot = vector3(10.0, 160.0, 0.0)

AddEventHandler('np-mdt:animation', function()
    if not isOpen then return end;
    -- Animation
    RequestAnimDict(tabletDict)
    while not HasAnimDictLoaded(tabletDict) do Citizen.Wait(100) end
    -- Model
    RequestModel(tabletProp)
    while not HasModelLoaded(tabletProp) do Citizen.Wait(100) end

    local plyPed = PlayerPedId()
    local tabletObj = CreateObject(tabletProp, 0.0, 0.0, 0.0, true, true, false)
    local tabletBoneIndex = GetPedBoneIndex(plyPed, tabletBone)

    TriggerEvent('actionbar:setEmptyHanded')
    AttachEntityToEntity(tabletObj, plyPed, tabletBoneIndex, tabletOffset.x, tabletOffset.y, tabletOffset.z, tabletRot.x, tabletRot.y, tabletRot.z, true, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(tabletProp)

    CreateThread(function()
        while isOpen do
            Wait(0)
            if not IsEntityPlayingAnim(plyPed, tabletDict, tabletAnim, 3) then
                TaskPlayAnim(plyPed, tabletDict, tabletAnim, 3.0, 3.0, -1, 49, 0, 0, 0, 0)
            end
        end
        ClearPedSecondaryTask(plyPed)
        Citizen.Wait(250)
        DetachEntity(tabletObj, true, false)
        DeleteEntity(tabletObj)
        return
    end)
end)

local function CurrentDuty(duty)
    if duty == 1 then
        return "10-41"
    end
    return "10-42"
end

RegisterNetEvent('np-mdt:dashboardbulletin')
AddEventHandler('np-mdt:dashboardbulletin', function(sentData)
    SendNUIMessage({ type = "bulletin", data = sentData })
end)

RegisterNetEvent('np-mdt:dashboardWarrants')
AddEventHandler('np-mdt:dashboardWarrants', function(sentData)
    SendNUIMessage({ type = "warrants", data = sentData })
end)

RegisterNetEvent('np-mdt:dashboardReports')
AddEventHandler('np-mdt:dashboardReports', function(sentData)
    SendNUIMessage({ type = "reports", data = sentData })
end)

RegisterNetEvent('np-mdt:dashboardCalls')
AddEventHandler('np-mdt:dashboardCalls', function(sentData)
    SendNUIMessage({ type = "calls", data = sentData })
end)

RegisterNUICallback("deleteBulletin", function(data, cb)
    local id = data.id
    TriggerServerEvent('np-mdt:deleteBulletin', id)
    cb(true)
end)

RegisterNUICallback("newBulletin", function(data, cb)
    local title = data.title
    local info = data.info
    local time = data.time
    TriggerServerEvent('np-mdt:newBulletin', title, info, time, data.id)
    cb(true)
end)

RegisterNetEvent('np-mdt:newBulletin')
AddEventHandler('np-mdt:newBulletin', function(ignoreId, sentData, job)
    if ignoreId == GetPlayerServerId(PlayerId()) then return end;
    if job == 'police' and ESX.GetPlayerData().job.name == "police" then
        SendNUIMessage({ type = "newBulletin", data = sentData })
    elseif job == ESX.GetPlayerData().job.name then
        SendNUIMessage({ type = "newBulletin", data = sentData })
    end
end)

RegisterNetEvent('np-mdt:deleteBulletin')
AddEventHandler('np-mdt:deleteBulletin', function(ignoreId, sentData, job)
    if ignoreId == GetPlayerServerId(PlayerId()) then return end;
    if job == 'police' and ESX.GetPlayerData().job.name == "police" then
        SendNUIMessage({ type = "deleteBulletin", data = sentData })
    elseif job == ESX.GetPlayerData().job.name then
        SendNUIMessage({ type = "deleteBulletin", data = sentData })
    end
end)

RegisterNetEvent('np-mdt:open')
AddEventHandler('np-mdt:open', function(jobLabel, lastname, firstname)
    open = true
    EnableGUI(open)
    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))

    local currentStreetHash, intersectStreetHash = GetStreetNameAtCoord(x, y, z)
    local currentStreetName = GetStreetNameFromHashKey(currentStreetHash)
    local intersectStreetName = GetStreetNameFromHashKey(intersectStreetHash)
    local zone = tostring(GetNameOfZone(x, y, z))
    local area = GetLabelText(zone)
    local playerStreetsLocation = area

    if not zone then zone = "UNKNOWN" end;

    if intersectStreetName ~= nil and intersectStreetName ~= "" then playerStreetsLocation = currentStreetName .. ", " .. intersectStreetName .. ", " .. area
    elseif currentStreetName ~= nil and currentStreetName ~= "" then playerStreetsLocation = currentStreetName .. ", " .. area
    else playerStreetsLocation = area end

    SendNUIMessage({ type = "data", name = "Welcome, " ..jobLabel..' '..lastname, location = playerStreetsLocation, fullname = firstname..' '..lastname })
end)

RegisterNUICallback('escape', function(data, cb)
    open = false
    EnableGUI(open)
    cb(true)
end)

RegisterNUICallback("searchProfiles", function(data, cb)
    local name = data.name
    TriggerServerEvent('np-mdt:searchProfile', name)
    cb(true)
end)

RegisterNetEvent('np-mdt:exitMDT')
AddEventHandler('np-mdt:exitMDT', function()
    open = false
    EnableGUI(open)
end)

-- (Start) Requesting profile information

RegisterNetEvent('np-mdt:searchProfile')
AddEventHandler('np-mdt:searchProfile', function(sentData, isLimited)
    SendNUIMessage({ type = "profiles", data = sentData, isLimited = isLimited })
end)

RegisterNUICallback("saveProfile", function(data, cb)
    local profilepic = data.pfp
    local information = data.description
    local cid = data.id
    local fName = data.fName
    local sName = data.sName
    TriggerServerEvent("np-mdt:saveProfile", profilepic, information, cid, fName, sName)
    cb(true)
end)

RegisterNUICallback("getProfileData", function(data, cb)
    local id = data.id
    TriggerServerEvent('np-mdt:getProfileData', id)
    cb(true)
end)

RegisterNUICallback("newTag", function(data, cb)
    if data.id ~= "" and data.tag ~= "" then
        TriggerServerEvent('np-mdt:newTag', data.id, data.tag)
    end
    cb(true)
end)

RegisterNUICallback("removeProfileTag", function(data, cb)
    local cid = data.cid
    local tagtext = data.text
    TriggerServerEvent('np-mdt:removeProfileTag', cid, tagtext)
    cb(removeProfileTag)
end)

-- RegisterNetEvent('np-mdt:getProfileData')
-- AddEventHandler('np-mdt:getProfileData', function(sentData, isLimited)
--     if not isLimited then
--         local vehicles = sentData['vehicles']
--         for i=1, #vehicles do
--             sentData['vehicles'][i]['plate'] = string.upper(sentData['vehicles'][i]['plate'])
--             sentData['vehicles'][i]['model'] = sentData['vehicles'][i]['name']
--         end
--     end
	
--     SendNUIMessage({ type = "profileData", data = sentData, isLimited = isLimited })
-- end)

RegisterNetEvent('np-mdt:getProfileData')
AddEventHandler('np-mdt:getProfileData', function(sentData)
    local vehicles = sentData['vehicles']
    for i = 1, #vehicles do
        sentData['vehicles'][i]['plate'] = string.upper(sentData['vehicles'][i]['plate'])
        local tempModel = vehicles[i]['model']
        if tempModel and tempModel ~= "Unknown" then
            local DisplayNameModel = GetDisplayNameFromVehicleModel(tempModel)
            local LabelText = GetLabelText(DisplayNameModel)
            if LabelText == "NULL" then LabelText = DisplayNameModel end
            sentData['vehicles'][i]['model'] = LabelText
        end
    end
    SendNUIMessage({ type = "profileData", data = sentData})
end)

RegisterNUICallback("updateLicence", function(data, cb)
    local type = data.type
    local status = data.status
    local cid = data.cid
    TriggerServerEvent('np-mdt:updateLicense', cid, type, status)
    cb(true)
end)

RegisterNUICallback("addGalleryImg", function(data, cb)
    local cid = data.cid
    local url = data.URL
    TriggerServerEvent('np-mdt:addGalleryImg', cid, url)
    cb(true)
end)

RegisterNUICallback("removeGalleryImg", function(data, cb)
    local cid = data.cid
    local url = data.URL
    TriggerServerEvent('np-mdt:removeGalleryImg', cid, url)
    cb(true)
end)

RegisterNUICallback("searchIncidents", function(data, cb)
    local incident = data.incident
    TriggerServerEvent('np-mdt:searchIncidents', incident)
    cb(true)
end)


RegisterNetEvent('np-mdt:getIncidents')
AddEventHandler('np-mdt:getIncidents', function(sentData)
    SendNUIMessage({ type = "incidents", data = sentData })
end)

RegisterNUICallback("getIncidentData", function(data, cb)
    local id = data.id
    TriggerServerEvent('np-mdt:getIncidentData', id)
    cb(true)
end)

RegisterNetEvent('np-mdt:getIncidentData')
AddEventHandler('np-mdt:getIncidentData', function(sentData, sentConvictions)
    SendNUIMessage({ type = "incidentData", data = sentData, convictions = sentConvictions })
end)

RegisterNUICallback("incidentSearchPerson", function(data, cb)
    local name = data.name
    TriggerServerEvent('np-mdt:incidentSearchPerson', name)
    cb(true)
end)

RegisterNetEvent('np-mdt:incidentSearchPerson')
AddEventHandler('np-mdt:incidentSearchPerson', function(sentData)
    SendNUIMessage({ type = "incidentSearchPerson", data = sentData })
end)

-- BOlO

RegisterNUICallback("searchBolos", function(data, cb)
    local searchVal = data.searchVal
    TriggerServerEvent('np-mdt:searchBolos', searchVal)
    cb(true)
end)

RegisterNetEvent('np-mdt:getBolos')
AddEventHandler('np-mdt:getBolos', function(sentData)
    SendNUIMessage({ type = "bolos", data = sentData })
end)

RegisterNUICallback("getAllBolos", function(data, cb)
    TriggerServerEvent('np-mdt:getAllBolos')
    cb(true)
end)

RegisterNetEvent('np-mdt:getAllIncidents')
AddEventHandler('np-mdt:getAllIncidents', function(sentData)
    SendNUIMessage({ type = "incidents", data = sentData })
end)

RegisterNUICallback("getAllIncidents", function(data, cb)
    TriggerServerEvent('np-mdt:getAllIncidents')
    cb(true)
end)

RegisterNetEvent('np-mdt:getAllBolos')
AddEventHandler('np-mdt:getAllBolos', function(sentData)
    SendNUIMessage({ type = "bolos", data = sentData })
end)

RegisterNUICallback("getBoloData", function(data, cb)
    local id = data.id
    TriggerServerEvent('np-mdt:getBoloData', id)
    cb(true)
end)

RegisterNetEvent('np-mdt:getBoloData')
AddEventHandler('np-mdt:getBoloData', function(sentData)
    SendNUIMessage({ type = "boloData", data = sentData })
end)

RegisterNUICallback("newBolo", function(data, cb)
    local existing = data.existing
    local id = data.id
    local title = data.title
    local plate = data.plate
    local owner = data.owner
    local individual = data.individual
    local detail = data.detail
    local tags = data.tags
    local gallery = data.gallery
    local officers = data.officers
    local time = data.time
    TriggerServerEvent('np-mdt:newBolo', data)
    cb(true)
end)

RegisterNetEvent('np-mdt:boloComplete')
AddEventHandler('np-mdt:boloComplete', function(sentData)
    SendNUIMessage({ type = "boloComplete", data = sentData })
end)

RegisterNUICallback("deleteBolo", function(data, cb)
    local id = data.id
    TriggerServerEvent('np-mdt:deleteBolo', id)
    cb(true)
end)

RegisterNUICallback("deleteICU", function(data, cb)
    local id = data.id
    TriggerServerEvent('np-mdt:deleteICU', id)
    cb(true)
end)

-- Reports

RegisterNUICallback("getAllReports", function(data, cb)
    TriggerServerEvent('np-mdt:getAllReports')
    cb(true)
end)

RegisterNetEvent('np-mdt:getAllReports')
AddEventHandler('np-mdt:getAllReports', function(sentData)
    SendNUIMessage({ type = "reports", data = sentData })
end)

RegisterNUICallback("getReportData", function(data, cb)
    local id = data.id
    TriggerServerEvent('np-mdt:getReportData', id)
    cb(true)
end)

RegisterNetEvent('np-mdt:getReportData')
AddEventHandler('np-mdt:getReportData', function(sentData)
    SendNUIMessage({ type = "reportData", data = sentData })
end)

RegisterNUICallback("searchReports", function(data, cb)
    local name = data.name
    TriggerServerEvent('np-mdt:searchReports', name)
    cb(true)
end)

RegisterNUICallback("newReport", function(data, cb)
    TriggerServerEvent('np-mdt:newReport', data)
    cb(true)
end)

RegisterNetEvent('np-mdt:reportComplete')
AddEventHandler('np-mdt:reportComplete', function(sentData)
    SendNUIMessage({ type = "reportComplete", data = sentData })
end)

-- DMV Page

RegisterNUICallback("searchVehicles", function(data, cb)
    local name = data.name
    TriggerServerEvent('np-mdt:searchVehicles', name)
    cb(true)
end)

local ColorNames = {
    [0] = "Metallic Black",
    [1] = "Metallic Graphite Black",
    [2] = "Metallic Black Steel",
    [3] = "Metallic Dark Silver",
    [4] = "Metallic Silver",
    [5] = "Metallic Blue Silver",
    [6] = "Metallic Steel Gray",
    [7] = "Metallic Shadow Silver",
    [8] = "Metallic Stone Silver",
    [9] = "Metallic Midnight Silver",
    [10] = "Metallic Gun Metal",
    [11] = "Metallic Anthracite Grey",
    [12] = "Matte Black",
    [13] = "Matte Gray",
    [14] = "Matte Light Grey",
    [15] = "Util Black",
    [16] = "Util Black Poly",
    [17] = "Util Dark silver",
    [18] = "Util Silver",
    [19] = "Util Gun Metal",
    [20] = "Util Shadow Silver",
    [21] = "Worn Black",
    [22] = "Worn Graphite",
    [23] = "Worn Silver Grey",
    [24] = "Worn Silver",
    [25] = "Worn Blue Silver",
    [26] = "Worn Shadow Silver",
    [27] = "Metallic Red",
    [28] = "Metallic Torino Red",
    [29] = "Metallic Formula Red",
    [30] = "Metallic Blaze Red",
    [31] = "Metallic Graceful Red",
    [32] = "Metallic Garnet Red",
    [33] = "Metallic Desert Red",
    [34] = "Metallic Cabernet Red",
    [35] = "Metallic Candy Red",
    [36] = "Metallic Sunrise Orange",
    [37] = "Metallic Classic Gold",
    [38] = "Metallic Orange",
    [39] = "Matte Red",
    [40] = "Matte Dark Red",
    [41] = "Matte Orange",
    [42] = "Matte Yellow",
    [43] = "Util Red",
    [44] = "Util Bright Red",
    [45] = "Util Garnet Red",
    [46] = "Worn Red",
    [47] = "Worn Golden Red",
    [48] = "Worn Dark Red",
    [49] = "Metallic Dark Green",
    [50] = "Metallic Racing Green",
    [51] = "Metallic Sea Green",
    [52] = "Metallic Olive Green",
    [53] = "Metallic Green",
    [54] = "Metallic Gasoline Blue Green",
    [55] = "Matte Lime Green",
    [56] = "Util Dark Green",
    [57] = "Util Green",
    [58] = "Worn Dark Green",
    [59] = "Worn Green",
    [60] = "Worn Sea Wash",
    [61] = "Metallic Midnight Blue",
    [62] = "Metallic Dark Blue",
    [63] = "Metallic Saxony Blue",
    [64] = "Metallic Blue",
    [65] = "Metallic Mariner Blue",
    [66] = "Metallic Harbor Blue",
    [67] = "Metallic Diamond Blue",
    [68] = "Metallic Surf Blue",
    [69] = "Metallic Nautical Blue",
    [70] = "Metallic Bright Blue",
    [71] = "Metallic Purple Blue",
    [72] = "Metallic Spinnaker Blue",
    [73] = "Metallic Ultra Blue",
    [74] = "Metallic Bright Blue",
    [75] = "Util Dark Blue",
    [76] = "Util Midnight Blue",
    [77] = "Util Blue",
    [78] = "Util Sea Foam Blue",
    [79] = "Uil Lightning blue",
    [80] = "Util Maui Blue Poly",
    [81] = "Util Bright Blue",
    [82] = "Matte Dark Blue",
    [83] = "Matte Blue",
    [84] = "Matte Midnight Blue",
    [85] = "Worn Dark blue",
    [86] = "Worn Blue",
    [87] = "Worn Light blue",
    [88] = "Metallic Taxi Yellow",
    [89] = "Metallic Race Yellow",
    [90] = "Metallic Bronze",
    [91] = "Metallic Yellow Bird",
    [92] = "Metallic Lime",
    [93] = "Metallic Champagne",
    [94] = "Metallic Pueblo Beige",
    [95] = "Metallic Dark Ivory",
    [96] = "Metallic Choco Brown",
    [97] = "Metallic Golden Brown",
    [98] = "Metallic Light Brown",
    [99] = "Metallic Straw Beige",
    [100] = "Metallic Moss Brown",
    [101] = "Metallic Biston Brown",
    [102] = "Metallic Beechwood",
    [103] = "Metallic Dark Beechwood",
    [104] = "Metallic Choco Orange",
    [105] = "Metallic Beach Sand",
    [106] = "Metallic Sun Bleeched Sand",
    [107] = "Metallic Cream",
    [108] = "Util Brown",
    [109] = "Util Medium Brown",
    [110] = "Util Light Brown",
    [111] = "Metallic White",
    [112] = "Metallic Frost White",
    [113] = "Worn Honey Beige",
    [114] = "Worn Brown",
    [115] = "Worn Dark Brown",
    [116] = "Worn straw beige",
    [117] = "Brushed Steel",
    [118] = "Brushed Black steel",
    [119] = "Brushed Aluminium",
    [120] = "Chrome",
    [121] = "Worn Off White",
    [122] = "Util Off White",
    [123] = "Worn Orange",
    [124] = "Worn Light Orange",
    [125] = "Metallic Securicor Green",
    [126] = "Worn Taxi Yellow",
    [127] = "police car blue",
    [128] = "Matte Green",
    [129] = "Matte Brown",
    [130] = "Worn Orange",
    [131] = "Matte White",
    [132] = "Worn White",
    [133] = "Worn Olive Army Green",
    [134] = "Pure White",
    [135] = "Hot Pink",
    [136] = "Salmon pink",
    [137] = "Metallic Vermillion Pink",
    [138] = "Orange",
    [139] = "Green",
    [140] = "Blue",
    [141] = "Mettalic Black Blue",
    [142] = "Metallic Black Purple",
    [143] = "Metallic Black Red",
    [144] = "hunter green",
    [145] = "Metallic Purple",
    [146] = "Metaillic V Dark Blue",
    [147] = "MODSHOP BLACK1",
    [148] = "Matte Purple",
    [149] = "Matte Dark Purple",
    [150] = "Metallic Lava Red",
    [151] = "Matte Forest Green",
    [152] = "Matte Olive Drab",
    [153] = "Matte Desert Brown",
    [154] = "Matte Desert Tan",
    [155] = "Matte Foilage Green",
    [156] = "DEFAULT ALLOY COLOR",
    [157] = "Epsilon Blue",
    [158] = "Unknown",
}

local ColorInformation = {
    [0] = "black",
    [1] = "black",
    [2] = "black",
    [3] = "darksilver",
    [4] = "silver",
    [5] = "bluesilver",
    [6] = "silver",
    [7] = "darksilver",
    [8] = "silver",
    [9] = "bluesilver",
    [10] = "darksilver",
    [11] = "darksilver",
    [12] = "matteblack",
    [13] = "gray",
    [14] = "lightgray",
    [15] = "black",
    [16] = "black",
    [17] = "darksilver",
    [18] = "silver",
    [19] = "utilgunmetal",
    [20] = "silver",
    [21] = "black",
    [22] = "black",
    [23] = "darksilver",
    [24] = "silver",
    [25] = "bluesilver",
    [26] = "darksilver",
    [27] = "red",
    [28] = "torinored",
    [29] = "formulared",
    [30] = "blazered",
    [31] = "gracefulred",
    [32] = "garnetred",
    [33] = "desertred",
    [34] = "cabernetred",
    [35] = "candyred",
    [36] = "orange",
    [37] = "gold",
    [38] = "orange",
    [39] = "red",
    [40] = "mattedarkred",
    [41] = "orange",
    [42] = "matteyellow",
    [43] = "red",
    [44] = "brightred",
    [45] = "garnetred",
    [46] = "red",
    [47] = "red",
    [48] = "darkred",
    [49] = "darkgreen",
    [50] = "racingreen",
    [51] = "seagreen",
    [52] = "olivegreen",
    [53] = "green",
    [54] = "gasolinebluegreen",
    [55] = "mattelimegreen",
    [56] = "darkgreen",
    [57] = "green",
    [58] = "darkgreen",
    [59] = "green",
    [60] = "seawash",
    [61] = "midnightblue",
    [62] = "darkblue",
    [63] = "saxonyblue",
    [64] = "blue",
    [65] = "blue",
    [66] = "blue",
    [67] = "diamondblue",
    [68] = "blue",
    [69] = "blue",
    [70] = "brightblue",
    [71] = "purpleblue",
    [72] = "blue",
    [73] = "ultrablue",
    [74] = "brightblue",
    [75] = "darkblue",
    [76] = "midnightblue",
    [77] = "blue",
    [78] = "blue",
    [79] = "lightningblue",
    [80] = "blue",
    [81] = "brightblue",
    [82] = "mattedarkblue",
    [83] = "matteblue",
    [84] = "matteblue",
    [85] = "darkblue",
    [86] = "blue",
    [87] = "lightningblue",
    [88] = "yellow",
    [89] = "yellow",
    [90] = "bronze",
    [91] = "yellow",
    [92] = "lime",
    [93] = "champagne",
    [94] = "beige",
    [95] = "darkivory",
    [96] = "brown",
    [97] = "brown",
    [98] = "lightbrown",
    [99] = "beige",
    [100] = "brown",
    [101] = "brown",
    [102] = "beechwood",
    [103] = "beechwood",
    [104] = "chocoorange",
    [105] = "yellow",
    [106] = "yellow",
    [107] = "cream",
    [108] = "brown",
    [109] = "brown",
    [110] = "brown",
    [111] = "white",
    [112] = "white",
    [113] = "beige",
    [114] = "brown",
    [115] = "brown",
    [116] = "beige",
    [117] = "steel",
    [118] = "blacksteel",
    [119] = "aluminium",
    [120] = "chrome",
    [121] = "wornwhite",
    [122] = "offwhite",
    [123] = "orange",
    [124] = "lightorange",
    [125] = "green",
    [126] = "yellow",
    [127] = "blue",
    [128] = "green",
    [129] = "brown",
    [130] = "orange",
    [131] = "white",
    [132] = "white",
    [133] = "darkgreen",
    [134] = "white",
    [135] = "pink",
    [136] = "pink",
    [137] = "pink",
    [138] = "orange",
    [139] = "green",
    [140] = "blue",
    [141] = "blackblue",
    [142] = "blackpurple",
    [143] = "blackred",
    [144] = "darkgreen",
    [145] = "purple",
    [146] = "darkblue",
    [147] = "black",
    [148] = "purple",
    [149] = "darkpurple",
    [150] = "red",
    [151] = "darkgreen",
    [152] = "olivedrab",
    [153] = "brown",
    [154] = "tan",
    [155] = "green",
    [156] = "silver",
    [157] = "blue",
    [158] = "black",
}

RegisterNetEvent('np-mdt:searchVehicles')
AddEventHandler('np-mdt:searchVehicles', function(sentData)
    for i=1, #sentData do
        local vehicle = json.decode(sentData[i]['vehicle'])
        sentData[i]["owner"] = sentData[i].owner
        sentData[i]['plate'] = string.upper(sentData[i]['plate'])
        sentData[i]['color'] = ColorInformation[vehicle['color1']]
        sentData[i]['colorName'] = ColorNames[vehicle['color1']]
        sentData[i]['model'] = GetLabelText(GetDisplayNameFromVehicleModel(vehicle['model']))
    end
    SendNUIMessage({ type = "searchedVehicles", data = sentData })
end)

RegisterNUICallback("getVehicleData", function(data, cb)
    local plate = data.plate
    TriggerServerEvent('np-mdt:getVehicleData', plate)
    cb(true)
end)

local classlist = {
    [0] = "Compact",
    [1] = "Sedan",
    [2] = "SUV",
    [3] = "Coupe",
    [4] = "Muscle",
    [5] = "Sport Classic",
    [6] = "Sport",
    [7] = "Super",
    [8] = "Motorbike",
    [9] = "Off-Road",
    [10] = "Industrial",
    [11] = "Utility",
    [12] = "Van",
    [13] = "Bike",
    [14] = "Boat",
    [15] = "Helicopter",
    [16] = "Plane",
    [17] = "Service",
    [18] = "Emergency",
    [19] = "Military",
    [20] = "Commercial",
    [21] = "Train"
}

-- RegisterNetEvent('np-mdt:getVehicleData')
-- AddEventHandler('np-mdt:getVehicleData', function(sentData)
--     print(ESX.DumpTable(sentData))
--     if sentData and sentData[1] then
--         local vehicle = sentData[1]
-- 		vehicle["dbid"] = vehicle["id"]
--         vehicle['color'] = ColorInformation[vehicle['primarycolor']]
--         vehicle['colorName'] = ColorNames[vehicle['secondarycolor']]
--         vehicle['model'] = vehicle['name']
--         vehicle['class'] = classlist[GetVehicleClassFromName(vehicle['model'])]
--         vehicle['vehicle'] = nil
--         SendNUIMessage({ type = "getVehicleData", data = vehicle })
--     end
-- end)

RegisterNetEvent('np-mdt:getVehicleData')
AddEventHandler('np-mdt:getVehicleData', function(sentData)
    if sentData and sentData[1] then
        local vehicle = sentData[1]
        local vehData = json.decode(vehicle['vehicle'])
        vehicle["dbid"] = vehicle["id"]
        vehicle["owner"] = sentData[1].owner
        vehicle['color'] = ColorInformation[vehData['color1']]
        vehicle['colorName'] = ColorNames[vehData['color1']]
        vehicle['model'] = GetLabelText(GetDisplayNameFromVehicleModel(vehData['model']))
        vehicle['class'] = classlist[GetVehicleClassFromName(vehData['model'])]
        vehicle['vehicle'] = nil
        SendNUIMessage({ type = "getVehicleData", data = vehicle })
    end
end)

RegisterNUICallback("saveVehicleInfo", function(data, cb)
    local dbid = data.dbid
    local plate = data.plate
    local imageurl = data.imageurl
    local notes = data.notes
    TriggerServerEvent('np-mdt:saveVehicleInfo', dbid, plate, imageurl, notes)
    cb(true)
end)

RegisterNetEvent('np-mdt:updateVehicleDbId')
AddEventHandler('np-mdt:updateVehicleDbId', function(sentData)
    SendNUIMessage({ type = "updateVehicleDbId", data = tonumber(sentData) })
end)

RegisterNUICallback("knownInformation", function(data, cb)
    local dbid = data.dbid
    local type = data.type
    local status = data.status
    local plate = data.plate
    TriggerServerEvent('np-mdt:knownInformation', dbid, type, status, plate)
    cb(true)
end)

RegisterNUICallback("getAllLogs", function(data, cb)
    TriggerServerEvent('np-mdt:getAllLogs')
    cb(true)
end)

RegisterNetEvent('np-mdt:getAllLogs')
AddEventHandler('np-mdt:getAllLogs', function(sentData)
    SendNUIMessage({ type = "getAllLogs", data = sentData })
end)

RegisterNUICallback("getPenalCode", function(data, cb)
    TriggerServerEvent('np-mdt:getPenalCode')
    cb(true)
end)

RegisterNetEvent('np-mdt:getPenalCode')
AddEventHandler('np-mdt:getPenalCode', function(titles, penalcode)
    SendNUIMessage({ type = "getPenalCode", titles = titles, penalcode = penalcode })
end)

RegisterNetEvent('np-mdt:getActiveUnits')
AddEventHandler('np-mdt:getActiveUnits', function(lspd, bcso, sahp, sasp, doc, sapr, pa, ems)
    SendNUIMessage({ type = "getActiveUnits", lspd = lspd, bcso = bcso, sahp = sahp, doc = doc, sasp = sasp, sapr = sapr, pa = pa, ems = ems })
end)

RegisterNUICallback("toggleDuty", function(data, cb)
    TriggerServerEvent('np-mdt:toggleDuty', data.cid, data.status)
    cb(true)
end)

RegisterNUICallback("setCallsign", function(data, cb)
    TriggerServerEvent('np-mdt:setCallsign', data.cid, data.newcallsign)
    cb(true)
end)

RegisterNetEvent('np-mdt:updateCallsign')
AddEventHandler('np-mdt:updateCallsign', function(callsign)
    callSign = tostring(callsign)
end)

RegisterNUICallback("saveIncident", function(data, cb)
    TriggerServerEvent('np-mdt:saveIncident', data)
    cb(true)
end)

RegisterNetEvent('np-mdt:updateIncidentDbId')
AddEventHandler('np-mdt:updateIncidentDbId', function(sentData)
    SendNUIMessage({ type = "updateIncidentDbId", data = tonumber(sentData) })
end)

RegisterNUICallback("removeIncidentCriminal", function(data, cb)
    TriggerServerEvent('np-mdt:removeIncidentCriminal', data.cid, data.incidentId)
    cb(true)
end)

-- Dispatch

RegisterNUICallback('setWaypoint', function(data, cb)
    TriggerEvent('DoLongHudText', "GPS marked!", 1)
    SetNewWaypoint(tonumber(data.x), tonumber(data.y))
end)


RegisterNUICallback("callDetach", function(data, cb)
    TriggerServerEvent('np-mdt:callDetach', data.callid)
    cb(true)
end)

RegisterNetEvent('np-mdt:callDetach')
AddEventHandler('np-mdt:callDetach', function(callid, sentData)
    local job = ESX.GetPlayerData().job
    if job.name == "police" or job.name == 'ambulance' then SendNUIMessage({ type = "callDetach", callid = callid, data = tonumber(sentData) }) end
end)

RegisterNUICallback("callAttach", function(data, cb)
    TriggerServerEvent('np-mdt:callAttach', data.callid)
    cb(true)
end)

RegisterNetEvent('np-mdt:callAttach')
AddEventHandler('np-mdt:callAttach', function(callid, sentData)
    local job = ESX.GetPlayerData().job
    if job.name == "police" or job.name == 'ambulance' then
        SendNUIMessage({ type = "callAttach", callid = callid, data = tonumber(sentData) })
    end
end)

RegisterNetEvent('dispatch:clNotify')
AddEventHandler('dispatch:clNotify', function(sNotificationData, sNotificationId)
    --print(ESX.DumpTable(sNotificationData))
    --print(sNotificationId)
    sNotificationData.callId = sNotificationId
    SendNUIMessage({ type = "call", data = sNotificationData })
end)

RegisterNUICallback("attachedUnits", function(data, cb)
    TriggerServerEvent('np-mdt:attachedUnits', data.callid)
    cb(true)
end)

RegisterNetEvent('np-mdt:attachedUnits')
AddEventHandler('np-mdt:attachedUnits', function(sentData, callid)
    SendNUIMessage({ type = "attachedUnits", data = sentData, callid = callid })
end)

RegisterNUICallback("callDispatchDetach", function(data, cb)
    TriggerServerEvent('np-mdt:callDispatchDetach', data.callid, data.cid)
    cb(true)
end)

RegisterNUICallback("setDispatchWaypoint", function(data, cb)
    TriggerServerEvent('np-mdt:setDispatchWaypoint', data.callid, data.cid)
    cb(true)
end)

RegisterNUICallback("callDragAttach", function(data, cb)
    TriggerServerEvent('np-mdt:callDragAttach', data.callid, data.cid)
    cb(true)
end)

RegisterNUICallback("setWaypointU", function(data, cb)
    TriggerServerEvent('np-mdt:setWaypoint:unit', data.cid)
    cb(true)
end)

RegisterNetEvent('np-mdt:setWaypoint:unit')
AddEventHandler('np-mdt:setWaypoint:unit', function(sentData) 
    SetNewWaypoint(sentData.x, sentData.y) 
end)

-- Dispatch

RegisterNUICallback("dispatchMessage", function(data, cb)
    TriggerServerEvent('np-mdt:sendMessage', data.message, data.time)
    cb(true)
end)

RegisterNetEvent('np-mdt:dashboardMessage')
AddEventHandler('np-mdt:dashboardMessage', function(sentData)
    local job = ESX.GetPlayerData().job
    if job.name == "police" or job.name == 'ambulance' then
        SendNUIMessage({ type = "dispatchmessage", data = sentData })
    end
end)

RegisterNetEvent('np-mdt:dashboardMessages')
AddEventHandler('np-mdt:dashboardMessages', function(sentData)
    SendNUIMessage({ type = "dispatchmessages", data = sentData })
end)

RegisterNUICallback("refreshDispatchMsgs", function(data, cb)
    TriggerServerEvent('np-mdt:refreshDispatchMsgs')
    cb(true)
end)

RegisterNUICallback("dispatchNotif", function(data, cb)
    local info = data['data']
    local mentioned = false
    if callSign ~= "" then if string.find(info['message'],callSign) then mentioned = true end end
    if mentioned then
        TriggerEvent('np-phone:sendNotification', {img = info['profilepic'], title = "Dispatch (Mention)", content = info['message'], time = 7500, customPic = true })
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0)
    else
        TriggerEvent('np-phone:sendNotification', {img = info['profilepic'], title = "Dispatch ("..info['name']..")", content = info['message'], time = 5000, customPic = true })
    end
    cb(true)
end)

RegisterNUICallback("getCallResponses", function(data, cb)
    TriggerServerEvent('np-mdt:getCallResponses', data.callid)
    cb(true)
end)

RegisterNetEvent('np-mdt:getCallResponses')
AddEventHandler('np-mdt:getCallResponses', function(sentData, sentCallId)
    SendNUIMessage({ type = "getCallResponses", data = sentData, callid = sentCallId })
end)

RegisterNUICallback("sendCallResponse", function(data, cb)
    TriggerServerEvent('np-mdt:sendCallResponse', data.message, data.time, data.callid)
    cb(true)
end)

RegisterNetEvent('np-mdt:sendCallResponse')
AddEventHandler('np-mdt:sendCallResponse', function(message, time, callid, name)
    SendNUIMessage({ type = "sendCallResponse", message = message, time = time, callid = callid, name = name })
end)

function tprint (t, s)
    for k, v in pairs(t) do
        local kfmt = '["' .. tostring(k) ..'"]'
        if type(k) ~= 'string' then
            kfmt = '[' .. k .. ']'
        end
        local vfmt = '"'.. tostring(v) ..'"'
        if type(v) == 'table' then
            tprint(v, (s or '')..kfmt)
        else
            if type(v) ~= 'string' then
                vfmt = tostring(v)
            end
            print(type(t)..(s or '')..kfmt..' = '..vfmt)
        end
    end
end
