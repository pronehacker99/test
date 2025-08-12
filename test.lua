-- Auto-send "Carrot" fruit as a gift to a target player

-- Drop into your executor and run. Works in many decompiled games; prints status so you can tune.



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

    if seconds and seconds > 0 then

        local t = 0

        while t < seconds do

            local dt = RunService.Heartbeat:Wait()

            t = t + dt

        end

    else

        RunService.Heartbeat:Wait()

    end

end



-- Return tool instance or nil

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



    -- 5) Fallback: find by display name or string prop "Name" in descendants

    for _,cont in ipairs(containers) do

        if cont then

            for _,v in ipairs(cont:GetDescendants()) do

                -- sometimes fruits are Model instances with a child Tool or values

                if v.Name and type(v.Name) == "string" and string.find(v.Name:lower(), nameToFind:lower()) then

                    -- try to locate a Tool inside

                    for _,child in ipairs(v:GetChildren()) do

                        if child:IsA("Tool") then

                            log("Found candidate by container name:", child:GetFullName())

                            return child

                        end

                    end

                end

            end

        end

    end



    log("Carrot not found in usual locations.")

    return nil

end



local function getProductIdFromTool(tool)

    if not tool then return nil end

    -- check IntValues / StringValues

    for _,v in ipairs(tool:GetChildren()) do

        if v:IsA("IntValue") and (v.Name == "ProductId" or v.Name:lower():find("product") or v.Name:lower():find("item") or v.Name:lower():find("id")) then

            return v.Value

        end

        if v:IsA("StringValue") and (v.Name == "ProductId" or v.Name:lower():find("product") or v.Name:lower():find("item") or v.Name:lower():find("id")) then

            local n = tonumber(v.Value)

            if n then return n end

        end

    end

    -- Try Attributes (Roblox Attributes)

    local ok, attr = pcall(function() return tool:GetAttribute("ProductId") end)

    if ok and attr then

        return tonumber(attr)

    end

    ok, attr = pcall(function() return tool:GetAttribute("ItemId") end)

    if ok and attr then

        return tonumber(attr)

    end

    -- Some tools store id in a string in their name (e.g. "Carrot_12345")

    local s = tool.Name

    local digits = s:match("(%d+)")

    if digits then return tonumber(digits) end

    return nil

end



local function equipTool(tool)

    if not tool then return false end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if humanoid and typeof(humanoid.EquipTool) == "function" then

        -- humanoid:EquipTool works when tool is in backpack or character

        local ok, err = pcall(function() humanoid:EquipTool(tool) end)

        if ok then

            log("Equipped tool via Humanoid:EquipTool")

            return true

        else

            log("EquipTool failed:", tostring(err))

        end

    end



    -- fallback: parent to character

    local ok, err = pcall(function()

        tool.Parent = char

    end)

    if ok then

        log("Forced tool parent to character.")

        return true

    else

        log("Could not parent tool to character:", tostring(err))

    end



    return false

end



local function teleportToPlayer(targetPlayer)

    if not targetPlayer or not targetPlayer.Character then

        return false, "target missing"

    end

    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart") or targetPlayer.Character:FindFirstChild("Torso") or targetPlayer.Character:FindFirstChild("UpperTorso")

    local myChar = LocalPlayer.Character

    if not myChar then return false, "no character" end

    local myHRP = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")

    if not myHRP then return false, "no HRP" end

    local offset = Vector3.new(0, 3, 0) -- slight offset to avoid collisions

    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 3, 2)

    safeWait(0.1)

    return true

end



-- Try multiple remote call patterns

local commonRemoteNames = {

    "SendGift", "Gift", "GiveItem", "GiveFruit", "Give", "PurchaseGift", "PurchaseItem",

    "Remotes", "RemoteEvent_Gift", "GiftFruit", "GivePlayerItem", "ItemService", "ServerRemote"

}



local function findRemoteByNames()

    local found = {}

    local function scan(container)

        for _,v in ipairs(container:GetDescendants()) do

            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then

                local nm = v.Name

                for _,cn in ipairs(commonRemoteNames) do

                    if nm:lower():find(cn:lower()) then

                        table.insert(found, v)

                    end

                end

            end

        end

    end

    pcall(function() scan(ReplicatedStorage) end)

    pcall(function() scan(workspace) end)

    pcall(function() scan(LocalPlayer) end)

    return found

end



local function tryCallRemote(remote, targetPlayer, productId, tool)

    -- Try several likely argument combinations, return true if some call didn't error

    local patterns = {

        function() remote:FireServer(targetPlayer) end,

        function() remote:FireServer(targetPlayer, productId) end,

        function() remote:FireServer(targetPlayer.UserId) end,

        function() remote:FireServer(targetPlayer.UserId, productId) end,

        function() remote:FireServer(productId, targetPlayer) end,

        function() remote:FireServer(tool) end,

        function() remote:FireServer(tool, targetPlayer) end,

        function() remote:FireServer({player = targetPlayer, id = productId}) end,

        function() remote:FireServer({Target = targetPlayer, ProductId = productId}) end,

    }



    for _,fn in ipairs(patterns) do

        local ok,err = pcall(fn)

        if ok then

            log("Remote call succeeded with pattern on remote:", remote:GetFullName())

            return true

        else

            -- keep trying other patterns

            --print("pattern failed:", err)

        end

    end

    return false

end



local function attemptGift(tool, targetPlayer)

    if not tool or not targetPlayer then return false end

    -- 1) Activate tool (common mechanic: use tool near player to gift)

    local ok, err = pcall(function() tool:Activate() end)

    if ok then

        log("Activated tool (tool:Activate()). Wait a bit for server to process.")

        safeWait(0.8)

        -- some games expect a click or proximity; attempt clickDetector or remote after teleport. Continue trying remotes as well.

    else

        log("tool:Activate() failed or nil:", tostring(err))

    end



    -- 2) Try to find a productId on the tool

    local productId = getProductIdFromTool(tool)

    if productId then

        log("Inferred productId:", productId)

    else

        log("No productId inferred from tool.")

    end



    -- 3) Try remotes with common names

    local remotes = findRemoteByNames()

    if #remotes > 0 then

        log("Found candidate remotes:", #remotes)

        for _,r in ipairs(remotes) do

            local succ = tryCallRemote(r, targetPlayer, productId, tool)

            if succ then return true end

        end

    else

        log("No obvious remotes found by name scan. Scanning all ReplicatedStorage remotes (may be many)...")

        -- Bruteforce a short scan of all remotes in ReplicatedStorage

        for _,v in ipairs(ReplicatedStorage:GetDescendants()) do

            if v:IsA("RemoteEvent") then

                local succ = tryCallRemote(v, targetPlayer, productId, tool)

                if succ then return true end

            end

        end

        -- also check workspace

        for _,v in ipairs(workspace:GetDescendants()) do

            if v:IsA("RemoteEvent") then

                local succ = tryCallRemote(v, targetPlayer, productId, tool)

                if succ then return true end

            end

        end

    end



    -- 4) Fallback: if productId exists, try firing a very common remote name using ReplicatedStorage.Default or "Remote"

    local fallbackNames = {"GiveItem", "SendGift", "GiftItem", "PurchaseItem"}

    for _,nm in ipairs(fallbackNames) do

        local r = ReplicatedStorage:FindFirstChild(nm, true)

        if r and r:IsA("RemoteEvent") then

            local succ = tryCallRemote(r, targetPlayer, productId, tool)

            if succ then return true end

        end

    end



    log("All gifting attempts finished (no confirmed success). You may need to inspection the game's remotes or share the remote name here.")

    return false

end



-- ---------------------

-- Minimal UI to pick target and run

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

        local eq = equipTool(tool)

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

            status.Text = "Status: attempt succeeded (check server)"

        else

            status.Text = "Status: attempt finished (no success confirmed). See console for details."

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
