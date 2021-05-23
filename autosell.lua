local maxPrice = 50000 --// You can't sell items worth more than 50k

--// Modules
local InfoModule = require(game.ReplicatedStorage.Modules.Info)

--// Variables
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local List = LocalPlayer.PlayerGui.Gui.Frames.Inventory.SubInventory.Holder.List

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

--// Checks if item is under max price
_G.autosell = true
local function isValidItem(name, maxprice)
   if _G.autosell then
       local RAP = InfoModule:ReturnItemFromModule(name).recentAveragePrice
       return RAP <= maxprice
   end
   return false
end

--// Gets all items into a table
local items = {}
for i,v in pairs(List:GetChildren()) do
   if v:IsA("Frame") then
       if not items[v.Name] then
           items[v.Name] = 1
       else
           items[v.Name] = items[v.Name] + 1
       end
   end
end

--// Sell current items
for itemName, amount in pairs(items) do
   if isValidItem(itemName, maxPrice) then
       sellItem(itemName)
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
