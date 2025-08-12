-- Change these
local targetName = "gardenkoyaneh" -- target player name
local fruitName = "Carrot"       -- name of the fruit/item

-- Get target player object
local targetPlayer = game.Players:FindFirstChild(targetName)
if not targetPlayer then
    warn("Player not found: " .. targetName)
    return
end

-- Fire the gift remote
game:GetService("ReplicatedStorage").GameEvents.FriendGiftEvent:FireServer(targetPlayer, fruitName)

print("Sent fruit gift to " .. targetName)
