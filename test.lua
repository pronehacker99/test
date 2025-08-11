--// Grow a Garden - Carrot Gift Script
--// Made for executors (Synapse, Fluxus, etc.)

-- SETTINGS
local carrotToolId = "Tool_4" -- Change this to the actual carrot Tool_# after testing

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- REMOTES
local FavoriteToolRemote = ReplicatedStorage:WaitForChild("FavoriteToolRemote_upvr")
local SendGiftRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Gift"):WaitForChild("SendGiftTo")

-- LOCAL PLAYER
local lp = Players.LocalPlayer

-- FUNCTION: Teleport to target
local function teleportToPlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character:PivotTo(targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3))
    end
end

-- FUNCTION: Equip carrot
local function equipCarrot()
    FavoriteToolRemote:InvokeServer(carrotToolId)
end

-- FUNCTION: Send carrot as gift
local function sendCarrot(targetPlayer)
    SendGiftRemote:FireServer({
        Target = targetPlayer,
        Tool = carrotToolId
    })
end

-- FUNCTION: Main process
local function giftCarrotTo(targetPlayer)
    teleportToPlayer(targetPlayer)
    task.wait(0.5)
    equipCarrot()
    task.wait(0.5)
    sendCarrot(targetPlayer)
end

-- SIMPLE GUI
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local PlayerList = Instance.new("ScrollingFrame")

ScreenGui.Parent = game.CoreGui

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
