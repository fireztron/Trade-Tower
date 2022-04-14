warn("USE THIS: https://raw.githubusercontent.com/fireztron/Trade-Tower/main/testguiv2.lua")

local function sendNotification(titleText, descText)
    StarterGui:SetCore("SendNotification",{
        Title = titleText;
        Text = descText;
        Icon = "";
        Duration = 5;
    })
end

sendNotification("PPHAX", "OUTDATED, USE NEW SCRIPT")
sendNotification("USE THIS", "https://raw.githubusercontent.com/fireztron/Trade-Tower/main/testguiv2.lua")
