-- Auto-send "Carrot" fruit to a target player for "Grow a Garden"
-- CORRECTED SCRIPT by Gemini

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    return warn("[AutoGift] No LocalPlayer found.")
end

-- ---------------------
-- Utility helpers
-- ---------------------
local function log(...)
    print("[AutoGift]", ...)
end

local function safeWait(seconds)
    task.wait(seconds or 0.1)
end

-- Return tool instance from Backpack or Character
local function findCarrot()
    local nameToFind = "Carrot"
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character

    -- 1) Check Backpack first
    if backpack and backpack:FindFirstChild(nameToFind) then
        local tool = backpack[nameToFind]
        log("Found Carrot in Backpack:", tool:GetFullName())
        return tool
    end

    -- 2) Check Character
    if character and character:FindFirstChild(nameToFind) then
        local tool = character[nameToFind]
        log("Found Carrot in Character:", tool:GetFullName())
        return tool
    end

    log("Carrot not found in Backpack or Character.")
    return nil
end

local function equipTool(tool)
    if not tool then return false end
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid:EquipTool(tool)
        log("Equipped tool via Humanoid:EquipTool.")
        return true
    end

    return false
end

local function teleportToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false, "Target has no character" end
    
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")

    if not myHRP then return false, "Could not find your HumanoidRootPart" end
    if not targetHRP then return false, "Could not find target's HumanoidRootPart" end
    
    -- Teleport near the target player
    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 3, 2)
    log("Teleported to", targetPlayer.Name)
    return true
end

-- ---------------------
-- Main Gifting Logic (Corrected for "Grow a Garden")
-- ---------------------
local function attemptGift(targetPlayer, itemName)
    -- This game uses a specific remote: ReplicatedStorage.Main.Action
    local giftRemote = ReplicatedStorage:FindFirstChild("Main", true) and ReplicatedStorage.Main:FindFirstChild("Action")

    if not (giftRemote and giftRemote:IsA("RemoteEvent")) then
        log("ERROR: Could not find the required remote event at ReplicatedStorage.Main.Action")
        return false
    end

    -- The server expects three arguments: "Gift", targetPlayer, itemName
    log("Firing remote ReplicatedStorage.Main.Action with args: 'Gift',", targetPlayer.Name, ",", itemName)
    
    local ok, err = pcall(function()
        giftRemote:FireServer("Gift", targetPlayer, itemName)
    end)

    if ok then
        log("Successfully fired the gift remote. Check if the gift was sent.")
        return true
    else
        log("An error occurred while firing the remote:", tostring(err))
        return false
    end
end


-- ---------------------
-- UI to pick target and run
-- ---------------------
local function buildGui()
    -- Cleanup old GUI first
    local oldGui = CoreGui:FindFirstChild("AutoGiftGui")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoGiftGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 140)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 28)
    title.Text = "AutoGift - Grow a Garden"
    title.BackgroundColor3 = Color3.new(0.3, 0.5, 0.9)
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame

    local playerDrop = Instance.new("TextBox")
    playerDrop.PlaceholderText = "Target player name (exact)"
    playerDrop.Size = UDim2.new(1, -20, 0, 28)
    playerDrop.Position = UDim2.new(0, 10, 0, 36)
    playerDrop.Parent = frame

    local sendBtn = Instance.new("TextButton")
    sendBtn.Size = UDim2.new(1, -20, 0, 34)
    sendBtn.Position = UDim2.new(0, 10, 0, 72)
    sendBtn.Text = "Send Carrot Gift"
    sendBtn.BackgroundColor3 = Color3.new(0.2, 0.7, 0.3)
    sendBtn.Font = Enum.Font.SourceSansBold
    sendBtn.TextColor3 = Color3.new(1, 1, 1)
    sendBtn.Parent = frame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 18)
    status.Position = UDim2.new(0, 10, 0, 112)
    status.Text = "Status: Idle"
    status.Font = Enum.Font.SourceSans
    status.TextColor3 = Color3.new(1, 1, 1)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame

    sendBtn.MouseButton1Click:Connect(function()
        local targetName = playerDrop.Text
        if targetName == "" then
            status.Text = "Status: Enter a player name."
            return
        end
        
        local targetPlayer = Players:FindFirstChild(targetName)
        if not targetPlayer then
            status.Text = "Status: Player not found."
            return
        end
        
        if targetPlayer == LocalPlayer then
            status.Text = "Status: Cannot gift to yourself."
            return
        end

        status.Text = "Status: Running..."
        log("--- Initiating gift to", targetName, "---")

        local carrotTool = findCarrot()
        if not carrotTool then
            status.Text = "Status: 'Carrot' tool not found!"
            return
        end

        equipTool(carrotTool)
        safeWait(0.2)
        
        local tpSuccess, tpError = teleportToPlayer(targetPlayer)
        if not tpSuccess then
            status.Text = "Status: Teleport failed: " .. tpError
            return
        end
        safeWait(0.3)

        local giftSuccess = attemptGift(targetPlayer, carrotTool.Name)
        if giftSuccess then
            status.Text = "Status: Gift attempt sent successfully."
        else
            status.Text = "Status: Gift failed. See console."
        end
    end)
end

buildGui()
log("AutoGift for 'Grow a Garden' loaded. Enter a player name and click send.")
