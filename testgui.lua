--[[
    Jackpot should be working!
        - Accurately searches for combined item prices closest to the jackpot cap
    
    Made by fireztron @ v3rmillion :)

    Hope you enjoyed the script!
]]

--// Join discord
local function copyDiscord()
    setclipboard("https://discord.gg/3HymEaePFT")
end

local StarterGui = game:GetService("StarterGui")
local bindable = Instance.new("BindableFunction")

local function sendNotifcation(titleText, descText)
    StarterGui:SetCore("SendNotification",{
        Title = titleText;
        Text = descText;
        Icon = "";
        Duration = 5;
    })
end

function bindable.OnInvoke(response)
    if response == "Yes" then
        copyDiscord()
        sendNotifcation("discord link copied", "welcome aboard :)")
    else
        sendNotifcation("bitch fuck u", "why dont u wanna join ?? >:(")
    end
end

StarterGui:SetCore("SendNotification", {
	Title = "PPHAX Discord",
	Text = "Copy to clipboard?",
	Duration = 5,
	Callback = bindable,
	Button1 = "Yes",
	Button2 = "No"
})

--// Modules
local InfoModule = require(game.ReplicatedStorage.Modules.Info)
local MainFunctions = require(game:GetService("Players").LocalPlayer.PlayerGui.Gui.GuiModules.MainFunctions)
local inv = require(game:GetService("Players").LocalPlayer.PlayerGui.Gui.GuiModules.Inventory)

--// Variables
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local List = LocalPlayer.PlayerGui.Gui.Frames.Inventory.SubInventory.Holder.List

        --// Get case prices caseInfo = {
        --      ["properties"] = {
        --          ["Price"]
        --      }
        --   }

--// Get casetypes info
local caseTypes = {}; do
    for caseName, caseInfo in pairs(InfoModule.Cases) do
     -- InfoModule:returnCaseBounds("name") to get bounds
        if caseInfo["Currency"] == "Robux" then
            caseTypes[caseName] = caseInfo
        end 
    end
end

--// Sorted cases prices
local caseNames = {}; do
    for _, caseInfo in ipairs(MainFunctions:ReturnSortedDictionary(caseTypes, "Price", true)) do
        caseTypes[caseInfo.name] = caseInfo

        local price = caseInfo.properties.Price
        local name = caseInfo.name
        table.insert(caseNames, string.format("%s ($%d)", name, price))
    end
end

--// Default values set beforehand
local lowestCaseToAutoBuy = caseNames[1]
local highestCaseToAutoBuy = caseNames[#caseNames]
local maxPrice = 50000
local jackpotTier = 1
local minJackpotChance = 95
local waitTime = .9

--// Quick sell
local function sellItem(itemName, amount)
    spawn(function()
        List[itemName]:Destroy()
        local args = {
            [1] = "QuickSell",
            [2] = itemName,
            [3] = amount
        }
        game:GetService("ReplicatedStorage").Events.InventoryActions:InvokeServer(unpack(args))
    end)
end

--// Item price
local function getItemPrice(name, rolimonsVal)
    if rolimonsVal == "rolimonsValue" then
        return InfoModule:ReturnItemFromModule(name).rolimonsValue
    elseif rolimonsVal == "recentAveragePrice" then
        return InfoModule:ReturnItemFromModule(name).recentAveragePrice
    end
end

--// Checks if item is under max price
local function isValidItem(name, maxprice)
    if autosell then
        local RAP = getItemPrice(name, "recentAveragePrice")
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
    updateCurrentItems()
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

--// Custom nsumclosest lib made by fireztron
local NSumClosestLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/fireztron/Trade-Tower/main/NSumClosest.lua'))()

--// Get amount of robux
local function convertRobux(num)
    local shortValue = num
    local longValue = MoneyLib.ShortToLong(shortValue)
    return tonumber(longValue) or tonumber(shortValue) 
end

--// Get highest value buyable case (under 20k robux)
local function getHighestValueBuyableCase()
    local currentRobux = convertRobux(LocalPlayer.PlayerGui.Gui.Hotbar.Stats.Robux.Amount.Text)
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

--// Get sorted items for jackpot
local function getSortedItems()
    local items = {}
    local inventory = inv.PlayersLocalInv
    for itemName, itemInfo in pairs(inv.PlayersLocalInv) do
        for amount = 1, itemInfo.amount do
            items[#items + 1] = {
                ["rolimonsValue"] = (getItemPrice(itemName, "rolimonsValue")),
                ["name"] = itemName
            }
        end
    end
    return MainFunctions:ReturnSortedDictionary(items, "rolimonsValue", true, true) --first boolean is which order (lowest to highest), second boolean is to determine if the table returned has itemInfo or not
end


--// Total jackpot RAP
local function getTotalJackpot()
    local total = 0
    for _, plrInfo in pairs(LocalPlayer.PlayerGui.Gui.Frames.Jackpot.SubJackpot.Pools[jackpotTier].List:GetChildren()) do
        if plrInfo.Name ~= "UIGridLayout" then
            for _, RAP in pairs(plrInfo:GetChildren()) do
                if RAP.Name == "RAP" then
                    local num = string.gsub(RAP.text, "%$", "")
                    total = total + convertRobux(num)
                end
            end 
        end
    end
    return total
end

--// Total available RAP to put in jackpot
local function getTotalAmountAbleToPutIn(sortedItems, n, maxJackpotPrice)
    local sol = NSumClosestLib.NSumClosest(sortedItems, n, maxJackpotPrice)
    if sol.Success then
        local totalInv = sol.Result
        local itemsForJackpot = sol.MadeWith
        return totalInv, itemsForJackpot
    else
        return false
    end
end

--// Caculates max value to put in jackpot
local function getMaxAmountAbleToPutIn(sortedItems, n, maxJackpotPrice)
    local closestSum = math.huge
    local targetItemsForJackpot

    repeat
        local totalInv, itemsForJackpot = getTotalAmountAbleToPutIn(sortedItems, n, maxJackpotPrice)
        if totalInv.Success then
            local diff = math.abs(maxJackpotPrice - totalInv)
            if diff <= math.abs(closestSum - totalInv) then
                closestSum = totalInv
                targetItemsForJackpot = itemsForJackpot
            end
        end
        n = n - 1
    until
        n < 1
    return closestSum, targetItemsForJackpot
end


--// Auto jackpot
local Countdown = LocalPlayer.PlayerGui.Gui.Frames.Jackpot.SubJackpot.Countdown
Countdown:GetPropertyChangedSignal("Text"):Connect(function()
    local countdownText = Countdown.Text
    local timeLeft = string.match(countdownText:lower(), "win") ~= "win" and string.gsub(countdownText, "%D", "")
    if autojackpot and timeLeft == "1" then
        wait(waitTime)
        local tierMax = (jackpotTier == 1 and 250000) or (jackpotTier == 2 and 5000000) or (jackpotTier == 3 and math.huge)
        local sortedItems = getSortedItems()
        local n = (#sortedItems >= 10 and 10) or (#sortedItems < 10 and #sortedItems)
        local totalInv, itemsForJackpot = getMaxAmountAbleToPutIn(sortedItems, n, tierMax)
        local totalJackpot = getTotalJackpot()
        if totalInv then
            print(totalInv, totalInv / totalJackpot + totalInv)
        end
        if totalInv and totalInv / (totalJackpot + totalInv) >= (minJackpotChance / 100) and totalJackpot > 0 then
            for _, itemInfo in pairs(itemsForJackpot) do
                local args = {
                    [1] = "Jackpot",
                    [2] = itemInfo.name,
                    [3] = 1, --amount
                    [4] = jackpotTier
                }
                print(itemInfo.name, jackpotTier)
                spawn(function()
                    game:GetService("ReplicatedStorage").Events.GamesActions:InvokeServer(unpack(args))
                    pcall(function()
                        LocalPlayer.PlayerGui.Gui.Frames.Jackpot.SubJackpot.LocalInventory.List[itemInfo.name]:Destroy()
                    end)
                end)
                --:InvokeServer("Jackpot", itemName, amount, jackpotTier)
            end
            sendNotifcation("Jackpot", "attempted to join jackpot")
        end
    end
end)

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
local window = lib:CreateWindow('PPHAX GUI - Trade Tower')
window:AddLabel({text = "fireztron @ v3rmillion"})

--// auto buy UI
window:AddToggle({text = 'Auto buy', state = autobuy, callback = function(v) 
    autobuy = v; 
end})

--// auto buy options ui
local autobuyoptions = window:AddFolder("auto buy options")
autobuyoptions:AddList({text = 'lowest cost case to autobuy', value = caseNames[1], values = caseNames, callback = function(v) lowestCaseToAutoBuy = v end})
autobuyoptions:AddList({text = 'highest cost case to autobuy', value = caseNames[#caseNames], values = caseNames, callback = function(v) highestCaseToAutoBuy = v end})

--// auto sell UI
window:AddToggle({text = 'Auto sell', state = autosell, callback = function(v) 
    autosell = v;
    sellCurrentItems()
end})

--// auto sell options UI
local autoselloptions = window:AddFolder("auto sell options")

autoselloptions:AddSlider({text = 'Max price to autosell', value = 50000, min = 0, max = 50000, float = 1000, dual = true, callback = function(v)
    maxPrice = v
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

--// join discord ui
window:AddButton({text = 'copy discord link', callback = function()
    copyDiscord()
    sendNotifcation("discord link copied", "welcome aboard :)")
    --[[local totalInv, itemsForJackpot = getTotalAmountAbleToPutIn(250000)
    if totalInv then
        print(totalInv, totalInv / (getTotalJackpot() + totalInv))
        for _, itemInfo in pairs(itemsForJackpot) do
            print(itemInfo.name, itemInfo.rolimonsValue)
        end
    end]]
end})


local window2 = lib:CreateWindow('AUTOJACKPOT')
window2:AddLabel({text = "AUTOJP AT YOUR OWN RISK."})

--// auto jackpot UI
window2:AddToggle({text = 'Auto jackpot', state = autojackpot, callback = function(v) 
    autojackpot = v; 
end})

--// auto jackpot options UI
local autojackpotoptions = window2:AddFolder("auto jackpot options")
autojackpotoptions:AddList({text = 'jackpot tier', state = jackpotTierString, value = "1 (250k Cap)", values = {"1 (250k Cap)", "2 (5M Cap)", "3 (INF Cap)"}, callback = function(jackpotTierString)
    jackpotTier = tonumber(jackpotTierString:sub(1, 1))
end})
autojackpotoptions:AddSlider({text = 'min jackpot chance', value = 95, min = 1, max = 100, callback = function(v)
    minJackpotChance = v
end})

--// Wait time UI
window2:AddLabel({text = "Waits x sec. from 1 sec"})
autojackpotoptions:AddSlider({text = 'waitTime', value = .9, min = 0, max = 1, float = .01, callback = function(v)
    waitTime = v
end})

--// Init library
lib:Init()

warn("my butthole is wet daddy")
