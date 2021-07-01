warn("DO NOT USE")

--[[
  DO NOT USE
]]
--[[
--// Modules
local InfoModule = require(game.ReplicatedStorage.Modules.Info)
local MainFunctions = require(game:GetService("Players").LocalPlayer.PlayerGui.Gui.GuiModules.MainFunctions)

--// Variables
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local List = LocalPlayer.PlayerGui.Gui.Frames.Inventory.SubInventory.Holder.List

        --// Get case prices caseInfo = {
        --      ["properties"] = {
        --          ["Price"]
        --      }
        --   }
local caseTypes = {}
for caseName, caseInfo in pairs(InfoModule.Cases) do
 -- InfoModule:returnCaseBounds("name") to get bounds
    if caseInfo["Currency"] == "Robux" then
        caseTypes[caseName] = caseInfo
    end 
end

--// Sorted cases prices
local caseNames = {}
for _, caseInfo in ipairs(MainFunctions:ReturnSortedDictionary(caseTypes, "Price", true)) do
    caseTypes[caseInfo.name] = caseInfo

    local price = caseInfo.properties.Price
    local name = caseInfo.name
    table.insert(caseNames, string.format("%s ($%d)", name, price))
end

local lowestCaseToAutoBuy = caseNames[1]
local highestCaseToAutoBuy = caseNames[#caseNames]
local maxPrice = 50000

--// Quick sell
local function sellItem(itemName, amount)
    spawn(function()
        local args = {
            [1] = "QuickSell",
            [2] = itemName,
            [3] = amount
        }
        game:GetService("ReplicatedStorage").Events.InventoryActions:InvokeServer(unpack(args))
    end)
end

local function getItemPrice(name)
    return InfoModule:ReturnItemFromModule(name).recentAveragePrice
end

--// Checks if item is under max price
local function isValidItem(name, maxprice)
    if autosell then
        local RAP = getItemPrice(name)
        return RAP <= maxPrice
    end
    return false
end

--// Gets all items into a table
local items = {}
local function updateCurrentItems()
    items = {}
    for i,v in pairs(List:GetChildren()) do
        if v:IsA("Frame") then
            if not items[v.Name] then
                items[v.Name] = 1
            else
                items[v.Name] = items[v.Name] + 1
            end
        end
    end
end
updateCurrentItems()

--// Sell current items
local function sellCurrentItems()
    for itemName, amount in pairs(items) do
        if isValidItem(itemName, maxPrice) then
            sellItem(itemName)
        end
    end
end

--// Sell items being added
List.ChildAdded:Connect(function(item)
    if item:IsA("Frame") then
        if isValidItem(item.Name, maxPrice) then
            sellItem(item.Name)
        end
    end
end)

--// CREDITS TO BEREZAA FOR MONEY LIB !
local MoneyLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/fireztron/Money-lib/main/trade%20tower%20abbv.lua'))()

--// Get amount of robux
local function getRobux()
    local shortValue = game:GetService("Players").LocalPlayer.PlayerGui.Gui.Hotbar.Stats.Robux.Amount.Text
    local longValue = MoneyLib.ShortToLong(shortValue)
    return tonumber(longValue) or tonumber(shortValue)
end

--// Get highest value buyable case (under 20k robux)
local function getHighestValueBuyableCase()
    local currentRobux = getRobux()
    local buyableCases = {}
    for caseName, caseInfo in pairs(caseTypes) do
        local price = caseInfo.properties.Price
        local minPriceOfCaseToBuy = tonumber(string.match(lowestCaseToAutoBuy, "$(%d*)"))
        local maxPriceOfCaseToBuy = tonumber(string.match(highestCaseToAutoBuy, "$(%d*)"))
        if currentRobux >= price and price <= maxPriceOfCaseToBuy and price >= minPriceOfCaseToBuy then
            buyableCases[caseName] = price
        end
    end

    local highestnumber = 0
    local targetCaseName
    for caseName, price in pairs(buyableCases) do
        if price > highestnumber then
            targetCaseName = caseName
            highestnumber = price
        end
    end
    return targetCaseName
end

--// Auto click
spawn(function()
    while true do
        if autoclick then
            game:GetService("ReplicatedStorage").Events.Click:FireServer()
        end
        wait()
    end
end)

--// Auto upgrade
spawn(function()
    while true do
        if autoupgrade then
            spawn(function()
                game:GetService("ReplicatedStorage").Events.StoreActions:InvokeServer("Upgrade")
            end)
        end
        wait()
    end
end)

--// Buy loop
spawn(function()
    while true do
        spawn(function()
            local caseName = getHighestValueBuyableCase()
            if autobuy and caseName then
                --print(caseName)
                game:GetService("ReplicatedStorage").Events.OpenCase:InvokeServer(caseName)
            end
        end)
        wait()
    end
end)

--// Anti afk
local VirtualUser=game:GetService('VirtualUser')
game:GetService('Players').LocalPlayer.Idled:connect(function()
    if antiafk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

--// For Non-Synapse Users (credits to egg salad)
if not pcall(function() return syn.protect_gui end) then
    syn = {}
    syn.protect_gui = function(egg)
        egg.Parent = game.CoreGui
    end
end

--// lib stuff uwuware i think
local lib = loadstring(game:HttpGet('https://raw.githubusercontent.com/fireztron/uwuware-ui-library/main/ui.lua', true))()
local window = lib:CreateWindow('Trade Tower GUI')
window:AddLabel({text = "fireztron @ v3rmillion"})

--// auto buy UI
window:AddToggle({text = 'Auto buy', state = autobuy, callback = function(v) 
    autobuy = v; 
end})

--// auto buy options ui
local autobuyoptions = window:AddFolder("auto buy options")
autobuyoptions:AddList({text = 'lowest cost case to autobuy', state = lowestCaseToAutoBuy, value = caseNames[1], values = caseNames, callback = function(v) lowestCaseToAutoBuy = v end})
autobuyoptions:AddList({text = 'highest cost case to autobuy', state = highestCaseToAutoBuy, value = caseNames[#caseNames], values = caseNames, callback = function(v) highestCaseToAutoBuy = v end})

--// auto sell UI
window:AddToggle({text = 'Auto sell', state = autosell, callback = function(v) 
    autosell = v;
    updateCurrentItems()
    sellCurrentItems()
end})

--// auto sell options UI
local autoselloptions = window:AddFolder("auto sell options")

autoselloptions:AddSlider({text = 'Max price to autosell', value = 50000, min = 0, max = 50000, float = 1000, dual = true, callback = function(v)
    maxPrice = v
    updateCurrentItems()
    sellCurrentItems()
end})

--// auto click UI
window:AddToggle({text = 'Auto click', state = autoclick, callback = function(v) 
    autoclick = v; 
end})

--// auto upgrade clicks UI
window:AddToggle({text = 'Auto upgrade clicks', state = autoupgrade, callback = function(v) 
    autoupgrade = v; 
end})

--// Anti afk UI
window:AddToggle({text = 'Anti Afk', state = antiafk, callback = function(v) 
    antiafk = v; 
end})

--// Init library
lib:Init()

warn("my butthole is wet daddy")
]]
