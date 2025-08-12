-- Auto-send "Carrot" fruit as a gift to a target player
-- MERGED SCRIPT: Combines the working findCarrot with the correct gift remote call.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    return warn("[AutoGift] No LocalPlayer (run from a local env / executor)")
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

-- Return tool instance or nil (USER'S ORIGINAL, WORKING FUNCTION)
local function findCarrot()
    -- search order: Character -> Backpack -> StarterGear -> ReplicatedStorage (common containers)
    local nameToFind = "Carrot"
    -- 1) Character
    local char = LocalPlayer.Character
    if char then
        for _,v in ipairs(char:GetDescendants()) do
            if v:IsA("Tool") and (v.Name == nameToFind or string.find(v.Name:lower(), nameToFind:lower())) then
                log("Found Carrot in Character:", v:GetFullName())
                return v
            end
        end
    end

    -- 2) Backpack
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _,v in ipairs(backpack:GetChildren()) do
            if v:IsA("Tool") and (v.Name == nameToFind or string.find(v.Name:lower(), nameToFind:lower())) then
                log("Found Carrot in Backpack:", v:GetFullName())
                return v
            end
        end
    end

    -- 3) StarterGear
    local sg = LocalPlayer:FindFirstChild("StarterGear")
    if sg then
        for _,v in ipairs(sg:GetChildren()) do
            if v:IsA("Tool") and (v.Name == nameToFind or string.find(v.Name:lower(), nameToFind:lower())) then
                log("Found Carrot in StarterGear:", v:GetFullName())
                return v
            end
        end
    end

    -- 4) ReplicatedStorage and other common containers
    local containers = {ReplicatedStorage, workspace}
    for _,cont in ipairs(containers) do
        if cont then
            for _,v in ipairs(cont:GetDescendants()) do
                if v:IsA("Tool") and (v.Name == nameToFind or string.find(v.Name:lower(), nameToFind:lower())) then
                    log("Found Carrot in", cont:GetFullName() .. " -> " .. v:GetFullName())
                    return v
                end
            end
        end
    end
    log("Carrot not found in usual locations.")
    return nil
end

local function equipTool(tool)
    if not tool then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function() humanoid:EquipTool(tool) end)
        log("Equipped tool via Humanoid:EquipTool")
        return true
    end
    return false
end

local function teleportToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false, "target missing" end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myChar = LocalPlayer.Character
    if not myChar then return false, "no character" end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return false, "no HRP" end
    
    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 3, 2)
    safeWait(0.1)
    return true
end

-- ---------------------
-- Main Gifting Logic (CORRECTED for "Grow a Garden")
-- ---------------------
local function attemptGift(tool, targetPlayer)
    if not tool or not targetPlayer then return false end

    -- This game uses a specific remote: ReplicatedStorage.Main.Action
    local giftRemote = ReplicatedStorage:FindFirstChild("Main", true) and ReplicatedStorage.Main:FindFirstChild("Action")

    if not (giftRemote and giftRemote:IsA("RemoteEvent")) then
        log("ERROR: Could not find the required remote event at ReplicatedStorage.Main.Action")
        return false
    end

    -- The server expects three arguments: "Gift", targetPlayer, tool.Name
    log("Firing remote ReplicatedStorage.Main.Action with args: 'Gift',", targetPlayer.Name, ",", tool.Name)
    
    local ok, err = pcall(function()
        giftRemote:FireServer("Gift", targetPlayer, tool.Name)
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
-- Minimal UI to pick target and run (USER'S ORIGINAL)
-- ---------------------
local function buildGui()
    local CoreGui = game:GetService("CoreGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoGiftGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,300,0,140)
    frame.Position = UDim2.new(0,10,0,10)
    frame.BackgroundTransparency = 0.35
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,28)
    title.Position = UDim2.new(0,0,0,0)
    title.Text = "AutoGift - Carrot Sender"
    title.Parent = frame

    local playerDrop = Instance.new("TextBox")
    playerDrop.PlaceholderText = "Target player name (exact)"
    playerDrop.Size = UDim2.new(1,-20,0,28)
    playerDrop.Position = UDim2.new(0,10,0,36)
    playerDrop.Parent = frame

    local sendBtn = Instance.new("TextButton")
    sendBtn.Size = UDim2.new(1,-20,0,34)
    sendBtn.Position = UDim2.new(0,10,0,72)
    sendBtn.Text = "Send Carrot"
    sendBtn.Parent = frame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1,-20,0,18)
    status.Position = UDim2.new(0,10,0,112)
    status.Text = "Status: idle"
    status.FontSize = Enum.FontSize.Size14
    status.Parent = frame

    sendBtn.MouseButton1Click:Connect(function()
        local targetName = playerDrop.Text
        if targetName == "" then
            status.Text = "Status: enter a player name"
            return
        end
        local targetPlayer = Players:FindFirstChild(targetName)
        if not targetPlayer then
            status.Text = "Status: player not found"
            return
        end
        status.Text = "Status: looking for Carrot..."
        log("User started send to", targetName)

        local tool = findCarrot()
        if not tool then
            status.Text = "Status: Carrot not found"
            return
        end
        status.Text = "Status: equipping..."
        equipTool(tool)
        safeWait(0.2)
        status.Text = "Status: teleporting..."
        local ok,err = teleportToPlayer(targetPlayer)
        if not ok then
            status.Text = "Status: teleport failed: "..tostring(err)
            return
        end
        status.Text = "Status: attempting gift..."
        local gifted = attemptGift(tool, targetPlayer)
        if gifted then
            status.Text = "Status: Gift attempt sent to server!"
        else
            status.Text = "Status: Gift attempt failed. See console."
        end
    end)

    return screenGui
end

-- Cleanup old gui first
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("AutoGiftGui")
    if old then old:Destroy() end
end)

buildGui()

log("AutoGift loaded. Enter exact target player name and press Send Carrot.")
