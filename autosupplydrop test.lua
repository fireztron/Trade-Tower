local LP = game:GetService("Players").LocalPlayer
workspace.ChildAdded:Connect(function(SupplyDrop)
    if SupplyDrop.Name == "SupplyDrop" then
        local partToTouch = SupplyDrop:WaitForChild("Touch")
        local LPHead = LP.Character.Head
        firetouchinterest(LPHead, partToTouch)
        print("touched")
    end
end)
warn("lez go.")

--[[
local LP = game:GetService("Players").LocalPlayer
local partToTouch = workspace.SupplyDrop:WaitForChild("Touch")
local LPHead = LP.Character.Head
firetouchinterest(LPHead, partToTouch)
]]
