--// Grow a Garden - Carrot Gift Script (Fixed for your game)
--// Change this to the actual carrot Tool_# once you find it
local carrotToolId = "Tool_4"

-- Safe parent for GUI (bypasses CoreGui restrictions in some executors)
local function getSafeParent()
    local success, ui = pcall(gethui)
    if success and ui then
        return ui
    else
        return game:GetService("CoreGui")
    end
end

-- Services
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

-- Remotes (exact from your file)
local FavoriteToolRemote = RS:WaitForChild("ReplicatedStorage_upvr"):WaitForChild("FavoriteToolRemote_upvr")
local SendGiftRemote = RS:WaitForChild("ReplicatedStorage_upvr")
    :WaitForChild("GameEvents"):WaitForChild("Gift"):WaitForChild("SendGiftTo")

-- Teleport to target player
local function teleportToPlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character:PivotTo(targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3))
    end
end

-- Equip carrot
local function equipCarrot()
    FavoriteToolRemote:InvokeServer(carrotToolId)
end

-- Send carrot gift
local function sendCarrot(targetPlayer)
    SendGiftRemote:FireServer({
        Target = targetPlayer,
        Tool = carrotToolId
    })
end

-- Main function
local function giftCarrotTo(targetPlayer)
    teleportToPlayer(targetPlayer)
    task.wait(0.5)
    equipCarrot()
    task.wait(0.5)
    sendCarrot(targetPlayer)
end

-- Simple player selector GUI
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local PlayerList = Instance.new("ScrollingFrame")

ScreenGui.Parent = getSafeParent()

Frame.Size = UDim2.new(0, 200, 0, 300)
Frame.Position = UDim2.new(0.5, -100, 0.5, -150)
Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Frame.Parent = ScreenGui

PlayerList.Size = UDim2.new(1, 0, 1, 0)
PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerList.ScrollBarThickness = 6
PlayerList.Parent = Frame

local function refreshPlayerList()
    PlayerList:ClearAllChildren()
    local y = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Position = UDim2.new(0, 0, 0, y)
            btn.Text = player.Name
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Parent = PlayerList
            btn.MouseButton1Click:Connect(function()
                giftCarrotTo(player)
            end)
            y = y + 30
        end
    end
    PlayerList.CanvasSize = UDim2.new(0, 0, 0, y)
end

refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)
