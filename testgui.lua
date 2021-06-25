--[[
    Jackpot should be working!
        - Accurately searches for combined item prices closest to the jackpot cap (may freeze if you have many items, will fix issue in future)
    
    Made by fireztron @ v3rmillion :)

    Hope you enjoyed the script!
]]

--// Join discord
local function copyDiscord()
    setclipboard("https://discord.gg/3HymEaePFT")
end

local StarterGui = game:GetService("StarterGui")
local bindable = Instance.new("BindableFunction")

local function sendNotification(titleText, descText)
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
        sendNotification("discord link copied", "welcome aboard :)")
    else
        sendNotification("bitch fuck u", "why dont u wanna join ?? >:(")
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
local AuctionFunctions = require(game:GetService("Players").LocalPlayer.PlayerGui.AuctionBoard.AuctionFunctions)

--// Variables
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local List = LocalPlayer.PlayerGui.Gui.Frames.Inventory.SubInventory.Holder.List

local ClickRemote; do 
    local Clicker = LocalPlayer.PlayerGui.Gui.Hotbar.Clicker.Button
    if Clicker.Visible then
        for i,v in pairs(getconnections(Clicker.MouseButton1Click)) do
            ClickRemote = debug.getupvalue(v.Function,1)
        end
    end
end

local UpgradeClickRemote; local InventoryActionsRemote; local GamesActionsRemote; do 
    for i,v in pairs(getgc()) do 
        --// Upgrade Click Remote Grabber
        if type(v) == "function" and islclosure(v) and getfenv(v).script == game:GetService("Players").LocalPlayer.PlayerGui.Gui.GuiModules.Store then 
            local x = debug.getconstants(v)
            if table.find(x, "Upgrade") then
                UpgradeClickRemote = debug.getupvalue(v,1)
            end

        --// Inventory Actions Remote Grabber
        elseif type(v) == "function" and islclosure(v) and getfenv(v).script == game:GetService("Players").irvindee.PlayerGui.Gui.GuiModules.Inventory and not first then 
            local x = debug.getconstants(v)
            if table.find(x, "Equip") then
                InventoryActionsRemote = debug.getupvalue(v,2)
                first = true
            end

        --// Games Actions Remote Grabber
        elseif type(v) == "function" and islclosure(v) and getfenv(v).script == game:GetService("Players").irvindee.PlayerGui.AuctionBoard.Handler then 
            local x = debug.getconstants(v)
            if table.find(x, "AuctionBid") then
                GamesActionsRemote = debug.getupvalue(v,2)
            end
        end
    end
end

local OpenCaseRemote; do 
    local OpenCaseButton = game:GetService("Players").LocalPlayer.PlayerGui.Gui.Frames.Cases.Main.Display.Open
    if OpenCaseButton.Visible then
        for i,v in pairs(getconnections(OpenCaseButton.MouseButton1Click)) do
            OpenCaseRemote = debug.getupvalue(v.Function, 3)
        end
    end
end

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
local quicksearch = false
local minAutomarketSell = 50000
local maxAutomarketSell = 9e9
local percentToMarketSell = 104/100
local maxPercentOfValueToBid = 70/100
local autoAuctionWaitTime = .9

local buyingCase = false

--// Remove every item u own from the marketplace
local function removeAllFromMarketPlace()
    for _, frame in pairs(LocalPlayer.PlayerGui.Gui.Frames.Market.SubMarket.Holder.List:GetChildren()) do
        if frame:IsA("Frame") and frame.Name == LocalPlayer.Name then
            local itemName = frame:WaitForChild("ItemName").Text
            spawn(function()
                local args = {
                    [1] = "Marketplace",
                    [2] = itemName
                }

                InventoryActionsRemote:InvokeServer(unpack(args))
            end)
        end
    end
    marketItemsLPInfo = {}
end

--// Quick sell
local function sellItem(itemName, amount)
    spawn(function()
	pcall(function()
       		List[itemName]:Destroy()
	end)
        local args = {
            [1] = "QuickSell",
            [2] = itemName,
            [3] = amount
        }
        InventoryActionsRemote:InvokeServer(unpack(args))
    end)
end

--// Market sell
local function marketSellItem(itemName, amount, value)
    print(value)
    spawn(function()
        local args = {
            [1] = "Marketplace",
            [2] = itemName,
            [3] = value,
            [4] = amount
        }

        InventoryActionsRemote:InvokeServer(unpack(args))
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
    local RAP = getItemPrice(name, "recentAveragePrice")
    local value = getItemPrice(name, "rolimonsValue")
    print(automarketplace, value >= minAutomarketSell, value <= maxAutomarketSell)
    if automarketplace and (value >= minAutomarketSell and value <= maxAutomarketSell) then
        return true, "marketsell", value * percentToMarketSell
    elseif (autosell and RAP <= maxPrice) and (not pureraponly or RAP == value) then
        return true, "sell"
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
        local valid, sellType, value = isValidItem(itemName, maxPrice)
        if valid then
            if sellType == "sell" then
                sellItem(itemName, amount)
            elseif sellType == "marketsell" then
                marketSellItem(itemName, amount, value)
            end
        end
    end
end

--// Sell items being added
List.ChildAdded:Connect(function(item)
    if item:IsA("Frame") then
        local valid, sellType, value = isValidItem(item.Name, maxPrice)
        if valid then
            if sellType == "sell" then
                sellItem(item.Name, amount)
            elseif sellType == "marketsell" then
                marketSellItem(item.Name, amount, value)
            end
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

--// Jackpot Variables
local Countdown = LocalPlayer.PlayerGui.Gui.Frames.Jackpot.SubJackpot.Countdown
local jackpotLPInfo = {
    [1] = {
        ["total"] = 0,
        ["itemsAlreadyIn"] = 0
    },
    [2] = {
        ["total"] = 0,
        ["itemsAlreadyIn"] = 0
    },
    [3] = {
        ["total"] = 0,
        ["itemsAlreadyIn"] = 0
    }
}

local function resetJackpotLPInfo()
    for _, tier in ipairs(jackpotLPInfo) do
        for index, value in pairs(tier) do
            tier[index] = 0
        end
    end
end

Countdown:GetPropertyChangedSignal("Text"):Connect(function()
    local countdownText = Countdown.Text
    local resetted = (string.match(countdownText:lower(), "win") == "win" or string.match(countdownText:lower(), "won") == "won")
    if resetted then
        resetJackpotLPInfo()
        --print("reset")
    end
end)

ReplicatedStorage:WaitForChild("Events"):WaitForChild("DataSend").OnClientEvent:Connect(function(signature, name, value, tier)
    if signature == "JackpotItem" and name == LocalPlayer.Name then
        jackpotLPInfo[tier]["total"] += value
        jackpotLPInfo[tier]["itemsAlreadyIn"] += 1
        --print("total now:", jackpotLPInfo[tier]["total"], "itemsAlreadyIn now:", jackpotLPInfo[tier]["itemsAlreadyIn"])
    end
end)

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
    local sol
    if quicksearch then
        sol = NSumClosestLib.QuickNSumClosest(sortedItems, n, maxJackpotPrice)
    else
        sol = NSumClosestLib.NSumClosest(sortedItems, n, maxJackpotPrice)
    end
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
        if totalInv then
            local diff = math.abs(maxJackpotPrice - totalInv)
            if diff <= math.abs(closestSum - totalInv) then
                closestSum = totalInv
                targetItemsForJackpot = itemsForJackpot
            end
        end
        n = n - 1
    until
        n < 1
    return closestSum + jackpotLPInfo[jackpotTier]["total"], targetItemsForJackpot
end


--// Auto jackpot
Countdown:GetPropertyChangedSignal("Text"):Connect(function()
    local countdownText = Countdown.Text
    local timeLeft = string.match(countdownText:lower(), "win") ~= "win" and string.gsub(countdownText, "%D", "")
    if autojackpot and timeLeft == "1" then
        wait(waitTime)
        local tierMax = (jackpotTier == 1 and 250000) or (jackpotTier == 2 and 5000000) or (jackpotTier == 3 and math.huge)
        local sortedItems = getSortedItems()
        local itemsAlreadyIn = jackpotLPInfo[jackpotTier]["itemsAlreadyIn"]
        local LPTotalAlreadyIn = jackpotLPInfo[jackpotTier]["total"]
        local n = (#sortedItems + itemsAlreadyIn >= 10 and 10 - itemsAlreadyIn) or (#sortedItems + itemsAlreadyIn < 10 and #sortedItems)
        local totalInv, itemsForJackpot = getMaxAmountAbleToPutIn(sortedItems, n, tierMax - LPTotalAlreadyIn)
        local totalJackpot = getTotalJackpot()

        if totalInv then
            print(totalInv, totalInv / totalJackpot + totalInv)
        end
        if totalInv and totalInv / (totalJackpot + totalInv) >= (minJackpotChance / 100) and totalJackpot - LPTotalAlreadyIn > 0 then
            for _, itemInfo in pairs(itemsForJackpot) do
                local args = {
                    [1] = "Jackpot",
                    [2] = itemInfo.name,
                    [3] = 1, --amount
                    [4] = jackpotTier
                }
                print(itemInfo.name, jackpotTier)
                spawn(function()
                    GamesActionsRemote:InvokeServer(unpack(args))
                    pcall(function()
                        LocalPlayer.PlayerGui.Gui.Frames.Jackpot.SubJackpot.LocalInventory.List[itemInfo.name]:Destroy()
                    end)
                end)
                --:InvokeServer("Jackpot", itemName, amount, jackpotTier)
            end
            sendNotification("Jackpot", "Attempted to joined jackpot.")
        elseif not totalInv then
            sendNotification("Jackpot", "Failed to join jackpot! You need items to join.")
        elseif totalJackpot <= 0 then
            sendNotification("Jackpot", "Did not join since there were no participants.")
        elseif totalInv / (totalJackpot + totalInv) < (minJackpotChance / 100) then
            sendNotification("Jackpot", "% not high enough: " .. totalInv / (totalJackpot + totalInv) * 100 .. "% | " .. minJackpotChance .. "%")
        elseif totalJackpot - LPTotalAlreadyIn <= 0 then
            sendNotification("Jackpot", "You were the only one participating! Did not join.")
        end
    end
end)

--// Auction Variables
local auctionBoard = LocalPlayer.PlayerGui.AuctionBoard
local auctionCountdown = auctionBoard.Status
local auctionHeader = auctionBoard.Header
local auctionBidders = auctionBoard.Bidders

local function bidAuction(num)
    local args = {
        [1] = "AuctionBid",
        [2] = num
    }
    GamesActionsRemote:InvokeServer(unpack(args))
end

--// Get top bidder
local function getTopAuctionBid()
    local last
    for playerName, bid in pairs(AuctionFunctions.BidTable) do
        last = bid
        if playerName == LocalPlayer.Name then
            last = nil
        end
    end
    return bid
end

--// Auto auctionbid
auctionCountdown:GetPropertyChangedSignal("Text"):Connect(function()
    local countdownText = auctionCountdown.Text
    local timeLeft = string.match(countdownText:lower(), "win") ~= "win" and string.gsub(countdownText, "%D", "")
    if autobidtoauction and timeLeft == "1" then
        wait(autoAuctionWaitTime)
        local itemName = string.match(auctionHeader.Text, "%(.*%)"):gsub("[%(%)]","")
        local value = getItemPrice(itemName, "rolimonsValue")
        local topBid = getTopAuctionBid()
        if not topBid then
            bidAuction(value * .6)
        elseif topBid/value <= maxPercentOfValueToBid then
            bidAuction(topBid + 1e-307) --smallest fucking number lmao
        end
    end
end)

--// Auto click
spawn(function()
    while true do
        if autoclick then --and not buyingCase then
            ClickRemote:FireServer()
        end
        wait()
    end
end)

--// Auto upgrade
spawn(function()
    while true do
        if autoupgrade then --and not buyingCase then
            spawn(function()
                UpgradeClickRemote:InvokeServer("Upgrade")
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
            if autobuy then --and caseName then
                --print(caseName)
                OpenCaseRemote:InvokeServer(caseName)
            end
        end)
        --if autobuy then
        --    buyingCase = true
        --end
        wait()
        --wait(4.65)
        --buyingCase = false
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
window:AddLabel({text = "features possibly detected?"})

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
autoselloptions:AddToggle({text = 'pure rap only', state = pureraponly, callback = function(v) 
    pureraponly = v;
    sellCurrentItems()
end})
autoselloptions:AddLabel({text = "quicksells if rap = value"})

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
    sendNotification("discord link copied", "welcome aboard :)")
end})


local window2 = lib:CreateWindow('AUTOJACKPOT')
window2:AddLabel({text = "AUTOJP AT YOUR OWN RISK."})

--// auto jackpot UI
window2:AddToggle({text = 'Auto jackpot', state = autojackpot, callback = function(v) 
    autojackpot = v; 
end})

--// auto jackpot options UI
local autojackpotoptions = window2:AddFolder("auto jackpot options")
autojackpotoptions:AddToggle({text = 'Quick search', state = quicksearch, callback = function(v) 
    quicksearch = v; 
end})
autojackpotoptions:AddLabel({text = "quick s. may not be accurate"})
autojackpotoptions:AddList({text = 'jackpot tier', state = jackpotTierString, value = "1 (250k Cap)", values = {"1 (250k Cap)", "2 (5M Cap)", "3 (INF Cap)"}, callback = function(jackpotTierString)
    jackpotTier = tonumber(jackpotTierString:sub(1, 1))
end})
autojackpotoptions:AddSlider({text = 'min jackpot chance', value = 95, min = 1, max = 100, callback = function(v)
    minJackpotChance = v
end})

--// Wait time UI
autojackpotoptions:AddSlider({text = 'waitTime', value = .9, min = 0, max = 1, float = .01, callback = function(v)
    waitTime = v
end})
autojackpotoptions:AddLabel({text = "Waits x sec. from 1 sec"})


local window3 = lib:CreateWindow('AUTOMARKETPLACE')
window3:AddLabel({text = "AUTOMP AT YOUR OWN RISK."})
window3:AddLabel({text = "AUTOMP MAY BE BUGGY."})

--// auto marketplace UI
window3:AddToggle({text = 'Auto add to marketplace', state = automarketplace, callback = function(v) 
    automarketplace = v;
    sellCurrentItems()
end})

--// auto marketplace options UI
local automarketplaceoptions = window3:AddFolder("auto marketplace options")
automarketplaceoptions:AddSlider({text = 'min value to put up', value = 50000, min = 0, max = 9e9, float = 1000, callback = function(v)
    minAutomarketSell = v
    sellCurrentItems()
end})
automarketplaceoptions:AddSlider({text = 'max value to put up', value = 9e9, min = 0, max = 9e9, float = 1000, callback = function(v)
    maxAutomarketSell = v
    sellCurrentItems()
end})
automarketplaceoptions:AddSlider({text = 'percent of value to sell', value = 104, min = 10, max = 500, float = 1, callback = function(v)
    percentToMarketSell = v/100
end})
automarketplaceoptions:AddLabel({text = "warning: it will do value of ur item"})
automarketplaceoptions:AddLabel({text = "multiplied by percentage/100"})

--// remove items from market UI
window3:AddButton({text = 'remove ur items from market', callback = function()
    removeAllFromMarketPlace()
end})


local window4 = lib:CreateWindow('Auto auctionbid')
window4:AddLabel({text = "AUTOBID IS STILL IN TESTING"})
window4:AddLabel({text = "Min. % of value is 60%"})

--// auto auctionbid UI
window4:AddToggle({text = 'Auto bid to auction', state = autobidtoauction, callback = function(v) 
    autobidtoauction = v;
end})

--// auto auctionbid options UI
local autoauctionbid = window4:AddFolder("auto auctionbid options")
autoauctionbid:AddSlider({text = 'max % of value to bid', value = 70, min = 60, max = 200, float = 1, callback = function(v)
    maxPercentOfValueToBid = v/100
end})
--// Wait time UI
autoauctionbid:AddSlider({text = 'waitTime', value = .9, min = 0, max = 1, float = .01, callback = function(v)
    autoAuctionWaitTime = v
end})
autoauctionbid:AddLabel({text = "Waits x sec. from 1 sec"})

--// Init library
lib:Init()

warn("my butthole is wet daddy")
