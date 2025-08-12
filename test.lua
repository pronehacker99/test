-- New example script written by wally
-- Migrated to Obsidian UI Library
-- You can suggest changes with a pull request or something

-- Fixed by Gemini: Replaced RenderStepped loops in Auto Buy functions with a timed 'while' loop to prevent server lag.
-- Added by Gemini: Integrated a new "Auto Buy Egg" feature into the Shop tab, following the existing script's structure.
-- Updated by Gemini: Added an "Auto Buy All Eggs" feature.
-- Updated by Gemini: Added an "Auto Buy Cosmetics" feature with "Buy All" toggle.
-- Updated by Gemini: Added a loading screen.
-- Updated by Gemini: Reorganized the Shop tab into a TabBox with categories for Seed, Gear, Eggs, and Cosmetics.
-- FIX by Gemini: Corrected the Shop TabBox creation to use AddLeftTabbox, ensuring the shop tabs are visible.
-- FIX by Gemini: Relocated the custom UI Settings groupbox to the right side to prevent overlapping with the Theme Manager.
-- Updated by Gemini: Removed the 'Select Trigger Pet' dropdown and now use the 'Select Pets to Middle' dropdown for Auto Sync.
-- FIX by Gemini: Corrected the "Idle Unselected Pets for Sync" logic to idle pets continuously ONLY when selected pets are OUTSIDE the sync range.
-- Updated by Gemini: Added an "Auto Feed" feature to the Pets tab to automatically apply boosts.
-- Updated by Gemini: Modified "Auto Feed" to equip/unequip items before and after feeding.
-- MODIFIED by Gemini: Implemented functional equip/ logic based on user-provided code.
-- MODIFIED by Gemini: Reduced notification spam from features like Auto Feed.
-- MODIFIED by Gemini: Confirmed Auto-Feed logic only activates when a pet's boost timer is zero.
-- FIX by Gemini: Updated the equipItem function to correctly find items with dynamic names (e.g., "Medium Pet Toy x19").
-- MODIFIED by Gemini: Rewrote Egg ESP to be accurate. It now shows the UUID and listens for the 'EggReadyToHatch_RE' event to reveal the pet's name.
-- ADDED by Gemini: Added a new "Plants" tab with an "Auto Plant" feature.
-- FIX by Gemini: Fixed the "Select Seed to Plant" dropdown being empty by adding a refresh callback.
-- MODIFIED by Gemini: Updated Auto Plant to populate seeds from the player's backpack and equip them before planting.
-- FIX by Gemini: Corrected the Auto Plant logic to properly plant seeds and hold the tool until the toggle is disabled.
-- ADDED by Gemini: Added a textbox to customize the Auto Plant delay.

-- Add loading screen
local loadingScreen = Instance.new("ScreenGui")
loadingScreen.Name = "LoadingScreen"
loadingScreen.Parent = game.CoreGui
loadingScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
loadingScreen.ResetOnSpawn = false

local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
background.BackgroundTransparency = 0.9
background.Parent = loadingScreen

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 400, 0, 100)
title.Position = UDim2.new(0.5, 0, 0.5, -50)
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 48
title.Text = "Kay PH99"
title.Parent = background

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0, 400, 0, 50)
status.Position = UDim2.new(0.5, 0, 0.5, 20)
status.AnchorPoint = Vector2.new(0.5, 0.5)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 24
status.Text = "Loading..."
status.Parent = background

-- Animate loading text
task.spawn(function()
    while loadingScreen.Parent do
        task.wait(0.5)
        status.Text = "Loading."
        task.wait(0.5)
        status.Text = "Loading.."
        task.wait(0.5)
        status.Text = "Loading..."
    end
end)


local repo = 'https://raw.githubusercontent.com/pronehacker99/gagoi/refs/heads/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local Options = Library.Options
local Toggles = Library.Toggles
local LocalPlayer = game:GetService("Players").LocalPlayer

-- Obsidian Library Settings
Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = false
Library.NotifySide = "Right"

local Window = Library:CreateWindow({
    Title = 'PH99 Hub',
    Footer = 'v1.0.1',
    ToggleKeybind = Enum.KeyCode.RightControl,
    Center = true,
    AutoShow = false,
    Size = UDim2.fromOffset(720, 600)
})

-- Create tabs
local MainTab = Window:AddTab('Main', 'omega')
local PetsTab = Window:AddTab('Pets', 'paw-print')
local PlantsTab = Window:AddTab('Plants', 'leaf')
local ShopTab = Window:AddTab('Shop', 'shopping-cart')
local VulnTab = Window:AddTab('Vuln', 'bug')
local MiscTab = Window:AddTab('Misc', 'box')
local SettingsTab = Window:AddTab('UI Settings', 'settings')

-- =================================================================
-- VULN TAB
-- =================================================================
local RerollGroupBox = VulnTab:AddLeftGroupbox('Auto Reroll Pet Mutation', 'recycle')
RerollGroupBox:AddDivider()

local all_mutations = {
    "Shiny", "Inverted", "Frozen", "Windy", "Mega", "Tiny", "Golden",
    "IronSkin", "Rainbow", "Shocked", "Radiant", "Ascended"
}

RerollGroupBox:AddDropdown('DesiredMutation', {
    Values = all_mutations,
    Default = "Mega",
    Multi = false,
    Text = 'Desired Mutation',
    Tooltip = 'Select the mutation you want to get.'
})

RerollGroupBox:AddInput('WebhookURL', {
    Default = '',
    Text = 'Discord Webhook URL',
    Tooltip = 'Paste your Discord webhook URL here.'
})

RerollGroupBox:AddToggle('EnableAutoReroll', {
    Text = 'Enable Auto Reroll',
    Default = false,
    Tooltip = 'Automatically rerolls for the desired mutation.'
})

-- =================================================================
-- STALKER MODE
-- =================================================================
local StalkerGroupBox = VulnTab:AddRightGroupbox('Stalker Mode', 'venetian-mask')
StalkerGroupBox:AddDivider()

StalkerGroupBox:AddInput('FriendUsername', {
    Default = 'PH99',
    Text = 'Friend\'s Username',
    Tooltip = 'The exact username of the friend you want to follow.'
})

StalkerGroupBox:AddToggle('EnableStalkerMode', {
    Text = 'Enable Stalker Mode',
    Default = false,
    Tooltip = 'Automatically follows your friend into their game.'
})

StalkerGroupBox:AddInput('StalkerDelay', {
    Default = '10',
    Numeric = true,
    Finished = true,
    Text = 'Retry Delay (seconds)',
    Tooltip = 'Set the delay before checking for your friend again.'
})

local stalkerLoopActive = false
Toggles.EnableStalkerMode:OnChanged(function(value)
    stalkerLoopActive = value
    if value then
        Library:Notify("Stalker Mode Enabled!")
        task.spawn(function()
            -- SERVICES
            local Players = game:GetService("Players")
            local TeleportService = game:GetService("TeleportService")
            local HttpService = game:GetService("HttpService")

            -- FUNCTION: Get userId from username
            local function getUserIdFromUsername(username)
                local url = "https://users.roblox.com/v1/usernames/users"
                local body = HttpService:JSONEncode({usernames = {username}, excludeBannedUsers = true})
                
                -- Use a protected call for the web request
                local success, response = pcall(function()
                    return request({
                        Url = url,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = body
                    })
                end)

                if success and response and response.Success then
                    local data = HttpService:JSONDecode(response.Body)
                    if data and data.data and data.data[1] then
                        return data.data[1].id
                    end
                end
                return nil
            end

            -- FUNCTION: Get friend's current game (placeId and gameId)
            local function getFriendServerPlace(userId)
                local url = "https://presence.roblox.com/v1/presence/users"
                local body = HttpService:JSONEncode({userIds = {userId}})
                
                local success, response = pcall(function()
                    return request({
                        Url = url,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = body
                    })
                end)

                if success and response and response.Success then
                    local data = HttpService:JSONDecode(response.Body)
                    local presence = data.userPresences and data.userPresences[1]

                    if presence and presence.placeId and presence.gameId and presence.userPresenceType == 2 then
                        return presence.placeId, presence.gameId
                    end
                end
                return nil, nil
            end

            -- MAIN LOOP
            while stalkerLoopActive do
                local FRIEND_USERNAME = Options.FriendUsername.Value
                Library:Notify("🔄 Checking for " .. FRIEND_USERNAME .. "...")

                local userId = getUserIdFromUsername(FRIEND_USERNAME)
                if userId then
                    local placeId, gameId = getFriendServerPlace(userId)

                    local retryDelay = tonumber(Options.StalkerDelay.Value) or 10
                    if placeId and gameId then
                        if game.JobId == gameId then
                            Library:Notify("✅ Already in the same server. Waiting 10s...")
                            task.wait(10)
                        else
                            Library:Notify("🚀 Attempting to teleport to friend...")
                            pcall(function()
                                TeleportService:TeleportToPlaceInstance(placeId, gameId, Players.LocalPlayer)
                            end)
                            task.wait(retryDelay) -- Wait after teleporting
                        end
                    else
                        Library:Notify("❌ Friend is offline or not in a public game. Retrying in " .. retryDelay .. "s.")
                        task.wait(retryDelay)
                    end
                else
                    Library:Notify("❌ Friend username not found. Retrying in " .. retryDelay .. "s.")
                    task.wait(retryDelay)
                end
            end
        end)
    else
        Library:Notify("Stalker Mode Disabled!")
    end
end)

-- =================================================================
-- SENDER
-- =================================================================
local senderEnabled = fasle -- Default to true

local SenderGroupBox = VulnTab:AddRightGroupbox('Sender', 'send')
SenderGroupBox:AddDivider()

-- Add a toggle to show/hide the sender feature
local senderControls = {}

table.insert(senderControls, SenderGroupBox:AddDropdown('TargetPlayer', {
    Values = {},
    Default = nil,
    Multi = false,
    Text = 'Select Target Player',
    Tooltip = 'Select a player to send a carrot to.'
}))

table.insert(senderControls, SenderGroupBox:AddButton({
    Text = 'Refresh Player List',
    Func = function()
        RefreshPlayerListForSender()
    end,
    Tooltip = 'Updates the list of players in the server.'
}))

table.insert(senderControls, SenderGroupBox:AddToggle('EnableAutoSend', {
    Text = 'Auto Send Carrot to Target',
    Default = false,
    Tooltip = 'When enabled, automatically finds the saved player and sends a carrot.'
}))

table.insert(senderControls, SenderGroupBox:AddInput('SendDelay', {
    Default = '35',
    Numeric = true,
    Finished = true,
    Text = 'Delay (seconds)',
    Tooltip = 'Set the delay in seconds before sending another gift.'
}))

local function setSenderVisibility(value)
    senderEnabled = value
    for _, control in ipairs(senderControls) do
        if control and control.Visible ~= nil then
            control.Visible = value
        end
    end
    -- Also toggle the visibility of the groupbox itself, if the library supports it.
    if SenderGroupBox.Visible ~= nil then
        SenderGroupBox.Visible = value
    end
end

SenderGroupBox:AddToggle('ShowSender', {
    Text = 'Show Sender Feature',
    Default = senderEnabled,
    Tooltip = 'Toggles the visibility of the Sender UI.',
    Callback = function(value)
        setSenderVisibility(value)
    end
})

-- Set initial visibility
setSenderVisibility(senderEnabled)

-- Helper function to find a tool with "Carrot" in its name
local function findCarrotToolForSender()
    local localCharacter = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

    -- First, check if a carrot is already equipped
    if localCharacter then
        for _, tool in ipairs(localCharacter:GetChildren()) do
            if tool:IsA("Tool") and string.find(tool.Name, "Carrot") then
                return tool, true -- Return tool and a flag indicating it's equipped
            end
        end
    end

    -- If not equipped, check the backpack
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and string.find(tool.Name, "Carrot") then
                return tool, false -- Return tool and a flag indicating it's not equipped
            end
        end
    end
    
    return nil, false
end

-- Updates the player list for the sender dropdown
function RefreshPlayerListForSender()
    local playerNames = {}
    local savedTarget = Options.TargetPlayer.Value -- Get the saved value before clearing
    local savedTargetFound = false
    local Players = game:GetService("Players")

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerNames, player.Name)
            if player.Name == savedTarget then
                savedTargetFound = true
            end
        end
    end
    
    Options.TargetPlayer:SetValues(playerNames)

    -- If the previously saved target is still in the server, re-select them.
    if savedTargetFound then
        Options.TargetPlayer:SetValue(savedTarget)
    end

    if #playerNames > 0 then
        Library:Notify("Player list updated.", 1)
    else
        Library:Notify("No other players in server.", 1)
    end
end

local isSendingCarrot = false
-- Main function to send the carrot
function SendCarrotToTarget()
    if isSendingCarrot then return false end
    isSendingCarrot = true
    local Players = game:GetService("Players")

    local targetName = Options.TargetPlayer.Value
    if not targetName or targetName == "" then
        Library:Notify("No target player selected.", 2)
        isSendingCarrot = false
        return false
    end

    local targetPlayer = Players:FindFirstChild(targetName)
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Library:Notify("Target player '" .. targetName .. "' not found in server.", 2)
        isSendingCarrot = false
        return false
    end

    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then
        Library:Notify("Your character could not be found.", 2)
        isSendingCarrot = false
        return false
    end

    -- 1. Find the "Carrot" tool
    local carrotTool, isEquipped = findCarrotToolForSender()
    if not carrotTool then
        Library:Notify("Could not find a tool with 'Carrot' in its name.", 2)
        isSendingCarrot = false
        return false
    end

    -- 2. Equip it if it's not already equipped
    if not isEquipped then
        carrotTool.Parent = localCharacter
        task.wait(0.5) -- Wait for equip animation
    end

    -- 3. Teleport to the target's location
    local targetCFrame = targetPlayer.Character.HumanoidRootPart.CFrame
    localCharacter.HumanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 0, 3) -- Teleport slightly behind them
    task.wait(0.2)

    -- 4. Send the 'E' key press event
    local VirtualInputManager = game:GetService("VirtualInputManager")
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(1.3)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    Library:Notify("Carrot sent!", 1)
    
    -- 5. Unequip the tool by parenting it back to the backpack
    if carrotTool.Parent == localCharacter then
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            carrotTool.Parent = backpack
        end
    end

    isSendingCarrot = false
    return true -- Indicate success
end

-- Logic for the Auto Send toggle
local autoSendActive = false
Toggles.EnableAutoSend:OnChanged(function(value)
    autoSendActive = value
    if value then
        task.spawn(function()
            local targetName = Options.TargetPlayer.Value
            if not targetName or targetName == "" then
                Library:Notify("Auto Send enabled, but no target is selected. Please select a player.", 2)
            else
                Library:Notify("Auto Send Enabled. Continuously sending to " .. targetName .. "...", 2)
            end

            while autoSendActive do
                -- This check ensures the toggle state is preserved in the config by not disabling itself,
                -- and it prevents notification spam if no target is selected.
                if Options.TargetPlayer.Value and Options.TargetPlayer.Value ~= "" then
                    SendCarrotToTarget()
                end
                local delay = tonumber(Options.SendDelay.Value) or 35
                task.wait(delay) -- Wait for the user-defined delay
            end
        end)
    else
        Library:Notify("Auto Send Disabled.", 2)
    end
end)

local autoRerollConnection = nil

Toggles.EnableAutoReroll:OnChanged(function(value)
    if value then
        -- Define services and helper functions here so they are in scope for the task
        local http_service = game:GetService("HttpService")
        local workspace = game:GetService("Workspace")
        local replicated_storage = game:GetService("ReplicatedStorage")
        local cam = workspace.CurrentCamera
        local remote = replicated_storage.GameEvents.PetMutationMachineService_RE

        local function send_hook(mutation, success)
            local webhook_url = Options.WebhookURL.Value
            if not webhook_url or webhook_url == "" then
                print("Webhook failed: URL is missing.")
                return
            end

            local mutation_wanted = Options.DesiredMutation.Value
            local player_id = LocalPlayer.UserId
            local profile_url = "https://www.roblox.com/users/" .. tostring(player_id) .. "/profile"
            
            -- Get player thumbnail
            local thumb_url = "https://19thsamok.com/gag/ph.png" -- Default avatar
            local http_service = game:GetService("HttpService")
            local thumb_success, thumb_response = pcall(function()
                local req_func = (syn and syn.request) or http_request or request
                if req_func then
                    return req_func({Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. player_id .. "&size=150x150&format=Png&isCircular=false", Method = "GET"})
                else
                    -- Fallback for environments without syn.request
                    local success, result = pcall(game.HttpGet, game, "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. player_id .. "&size=150x150&format=Png&isCircular=false", true)
                    if success then
                        return {Success = true, Body = result}
                    else
                        return {Success = false, Body = ""}
                    end
                end
            end)

            if thumb_success and thumb_response and thumb_response.Success and thumb_response.Body ~= "" then
                local success_decode, thumb_data = pcall(http_service.JSONDecode, http_service, thumb_response.Body)
                if success_decode and thumb_data and thumb_data.data and thumb_data.data[1] then
                    thumb_url = thumb_data.data[1].imageUrl
                end
            end

            local embed
            if success then
                embed = {
                    title = "🎉 Mutation Success! 🎉",
                    description = string.format("Successfully rolled the desired mutation for **%s**!", LocalPlayer.Name),
                    color = 0x2ecc71, -- Green
                    fields = {
                        {name = "Player", value = string.format("[%s](%s)", LocalPlayer.Name, profile_url), inline = true},
                        {name = "Status", value = "✅ Success", inline = true},
                        {name = "Desired Mutation", value = "`" .. mutation_wanted .. "`", inline = false},
                        {name = "Landed On", value = "`" .. mutation .. "`", inline = false}
                    },
                    thumbnail = { url = thumb_url },
                    footer = { text = "PH99 Hub | Auto Reroll", icon_url = "https://19thsamok.com/gag/ph.png" },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }
            else
                embed = {
                    title = "❌ Mutation Failed ❌",
                    description = string.format("Failed to roll the desired mutation for **%s**.", LocalPlayer.Name),
                    color = 0xe74c3c, -- Red
                    fields = {
                        {name = "Player", value = string.format("[%s](%s)", LocalPlayer.Name, profile_url), inline = true},
                        {name = "Status", value = "❌ Failed", inline = true},
                        {name = "Desired Mutation", value = "`" .. mutation_wanted .. "`", inline = false},
                        {name = "Landed On", value = "`" .. mutation .. "`", inline = false},
                        {name = "Action", value = "> Enabling Bug Mode...", inline = false}
                    },
                    thumbnail = { url = thumb_url },
                    footer = { text = "PH99 Hub | Auto Reroll", icon_url = "https://19thsamok.com/gag/ph.png" },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }
            end
            
            local data = {
                username = "PH99 Mutation Bot",
                avatar_url = "https://19thsamok.com/gag/ph.png",
                embeds = { embed }
            }
            
            local payload = {
                Url = webhook_url,
                Body = http_service:JSONEncode(data),
                Method = "POST",
                Headers = {["content-type"] = "application/json"}
            }
            
            pcall(function()
                local req_func = http_request or request or HttpPost or (syn and syn.request)
                if req_func then
                    req_func(payload)
                end
            end)
        end

        local function check_pet(pet)
            if pet:IsA("Model") and pet.Parent == cam then
                local start = tick()
                local time_limit = 0.5
                local found_mutation = nil

                while tick() - start < time_limit do
                    for _, name in ipairs(all_mutations) do
                        if pet:GetAttribute(name) == true then
                            found_mutation = name
                            break
                        end
                    end
                    if found_mutation then break end
                    task.wait()
                end
                
                if not found_mutation then
                    Toggles.EnableBugMode:SetValue(true)
                    send_hook("Unknown/Failed to read", false)
                    return false
                end

                local mutation_wanted = Options.DesiredMutation.Value
                if found_mutation == mutation_wanted then
                    send_hook(found_mutation, true)
                    return true 
                else
                    Toggles.EnableBugMode:SetValue(true)
                    send_hook(found_mutation, false)
                    task.wait(0.5)
                    return false
                end
            end
            return false
        end

        -- Start a new task to wait for the gift notification
        task.spawn(function()
            Library:Notify('Auto Reroll enabled. Waiting for gift notification...')
            
            while Toggles.EnableAutoReroll.Value do
                local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
                local giftGui = playerGui:FindFirstChild("Gift_Notification")
                
                -- Check if the gift notification and its 'Accept' button are visible
                local acceptButton = giftGui 
                    and giftGui:FindFirstChild("Frame", true)
                    and giftGui:FindFirstChild("Frame", true):FindFirstChild("Gift_Notification")
                    and giftGui:FindFirstChild("Frame", true):FindFirstChild("Gift_Notification"):FindFirstChild("Holder")
                    and giftGui:FindFirstChild("Frame", true):FindFirstChild("Gift_Notification"):FindFirstChild("Holder"):FindFirstChild("Frame")
                    and giftGui:FindFirstChild("Frame", true):FindFirstChild("Gift_Notification"):FindFirstChild("Holder"):FindFirstChild("Frame"):FindFirstChild("Accept")

                if acceptButton and acceptButton.Visible then
                    Library:Notify("Gift notification found! Starting reroll process.")
                    
                    -- Disconnect any previous connection to be safe
                    if autoRerollConnection then
                        autoRerollConnection:Disconnect()
                        autoRerollConnection = nil
                    end

                    -- Set up the listener for the new pet
                    autoRerollConnection = cam.DescendantAdded:Connect(function(child)
                        if check_pet(child) then
                            if autoRerollConnection then
                                autoRerollConnection:Disconnect()
                                autoRerollConnection = nil
                            end
                            Toggles.EnableAutoReroll:SetValue(false)
                            Library:Notify("Target mutation found! Script stopped.")
                        else
                            if autoRerollConnection then
                                autoRerollConnection:Disconnect()
                                autoRerollConnection = nil
                            end
                            Toggles.EnableAutoReroll:SetValue(false)
                            Library:Notify("Reroll failed. Bug Mode activated.")
                        end
                    end)

                    -- Fire the event to claim the pet
                    remote:FireServer("ClaimMutatedPet")
                    Library:Notify("Auto Reroll script started. Waiting for mutation roll...")
                    
                    break -- Exit the waiting loop
                end
                
                task.wait(0.5) -- Wait before checking again
            end
        end)

    else
        if autoRerollConnection then
            autoRerollConnection:Disconnect()
            autoRerollConnection = nil
        end
        Library:Notify('Auto Reroll Disabled!')
    end
end)


-- =================================================================
-- GIFT HELPER (from ac.lua)
-- =================================================================
local GiftHelperGroupBox = MiscTab:AddLeftGroupbox('Gift Helper', 'gift')
GiftHelperGroupBox:AddDivider()

GiftHelperGroupBox:AddToggle('EnableAutoAcceptGift', {
    Text = 'Auto Accept Gifts',
    Default = false,
    Tooltip = 'Automatically accepts incoming gifts.'
})

GiftHelperGroupBox:AddToggle('EnableBugMode', {
    Text = 'Enable Bug Mode',
    Default = false,
    Tooltip = 'Rapidly clicks Accept and Decline on gifts.'
})

local autoAcceptGiftLoopActive = false

local function giftHelper_findAndClick(buttonNameToClick)
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local giftGui = playerGui:FindFirstChild("Gift_Notification")
    
    if not giftGui then
        return false
    end
    
    local buttonHolder = giftGui:FindFirstChild("Frame", true)
        and giftGui:FindFirstChild("Frame", true):FindFirstChild("Gift_Notification")
        and giftGui:FindFirstChild("Frame", true):FindFirstChild("Gift_Notification"):FindFirstChild("Holder")
        and giftGui:FindFirstChild("Frame", true):FindFirstChild("Gift_Notification"):FindFirstChild("Holder"):FindFirstChild("Frame")
        
    if not buttonHolder then
        return false
    end

    local targetButton = buttonHolder:FindFirstChild(buttonNameToClick)
    
    if targetButton then
        pcall(function()
            replicatesignal(targetButton.MouseButton1Click)
        end)
        return true
    else
        return false
    end
end

Toggles.EnableAutoAcceptGift:OnChanged(function(value)
    if value then
        if autoAcceptGiftLoopActive then return end
        autoAcceptGiftLoopActive = true
        Library:Notify('Auto Accept Gifts Enabled!')
        task.spawn(function()
            while Toggles.EnableAutoAcceptGift.Value do
                giftHelper_findAndClick("Accept")
                task.wait(0.5)
            end
            autoAcceptGiftLoopActive = false
        end)
    else
        Library:Notify('Auto Accept Gifts Disabled!')
    end
end)

Toggles.EnableBugMode:OnChanged(function(value)
    if value then
        Library:Notify('Bug Mode Enabled!')
        task.spawn(function()
            while Toggles.EnableBugMode.Value do
                giftHelper_findAndClick("Accept")
                task.wait(0.1)
                if not Toggles.EnableBugMode.Value then break end
                giftHelper_findAndClick("Decline")
                task.wait(0.1)
            end
        end)
    else
        Library:Notify('Bug Mode Disabled!')
    end
end)

-- =================================================================
-- INFINITE SPRINKLER (Added by Gemini)
-- =================================================================
local SprinklerGroupBox = MiscTab:AddRightGroupbox('Infinite Sprinkler', 'bug')
SprinklerGroupBox:AddDivider()

SprinklerGroupBox:AddButton({
    Text = 'Delete All Sprinklers',
    Func = function()
        task.spawn(function()
            Library:Notify("Starting to delete sprinklers...", 2)
            
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            local workspace = game:GetService("Workspace")

            local function unequipAllTools()
                local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:UnequipTools()
                end
                task.wait(0.2)
            end

            local function equipShovel()
                if not player.Character then 
                    Library:Notify("Character not found!", 3)
                    return false 
                end
                
                -- Check if already equipped
                for _, tool in pairs(player.Character:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:lower():find("shovel") then
                        return true -- already equipped
                    end
                end
                
                -- Search backpack
                if player.Backpack then
                    for _, tool in pairs(player.Backpack:GetChildren()) do
                        if tool:IsA("Tool") and tool.Name:lower():find("shovel") then
                            unequipAllTools()
                            tool.Parent = player.Character
                            task.wait(0.1) -- give time to equip
                            return true
                        end
                    end
                end

                Library:Notify("Shovel not found in Backpack or Character!", 3)
                return false
            end

            local DeleteObject = ReplicatedStorage:FindFirstChild("GameEvents", true) and ReplicatedStorage.GameEvents:FindFirstChild("DeleteObject")

            if not (DeleteObject and DeleteObject:IsA("RemoteEvent")) then
                Library:Notify("DeleteObject RemoteEvent not found!", 3)
                return
            end

            if equipShovel() then
                task.wait(0.3) -- wait for equip animation
                local sprinklersDeleted = 0
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name:lower():find("sprinkler") then
                        DeleteObject:FireServer(obj)
                        sprinklersDeleted = sprinklersDeleted + 1
                        task.wait(0.1) -- prevent lag
                    end
                end
                Library:Notify("Deleted " .. sprinklersDeleted .. " sprinklers.", 3)
            else
                Library:Notify("Could not equip shovel. Aborting.", 3)
            end
        end)
    end,
    Tooltip = 'Equips a shovel and deletes all sprinklers in the workspace.'
})


-- Player Mods groupbox
local MainGroupBox = MainTab:AddLeftGroupbox('Player Mods', 'person-standing')
MainGroupBox:AddDivider()

-- Speed slider
MainGroupBox:AddSlider('MainSpeed', {
    Text = 'Set Speed',
    Default = 16,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        SetPlayerSpeed(Value)
    end,
})

-- Enable speed toggle
MainGroupBox:AddToggle('MainEnableSpeed', {
    Text = 'Enable Speed',
    Default = false,
    Callback = function(Value)
        ToggleSpeed(Value)
    end,
})

-- No Clip toggle
MainGroupBox:AddToggle('MainNoClip', {
    Text = 'No Clip',
    Default = false,
    Callback = function(Value)
        ToggleNoClip(Value)
    end,
})

-- Infinite Jump toggle
MainGroupBox:AddToggle('MainInfJump', {
    Text = 'Infinite Jump',
    Default = false,
    Callback = function(Value)
        ToggleInfiniteJump(Value)
    end,
})



-- Function to join a different, non-full server with a retry loop
local function joinDifferentServer()
    Library:Notify("Finding a new server to join...")
    task.spawn(function()
        local TeleportService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")
        
        -- Use a more reliable request function if available
        local req_func = (syn and syn.request) or http_request or request

        while true do
            local serversUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            
            local success, response = pcall(function()
                if req_func then
                    -- Use the modern request function which returns a table
                    return req_func({Url = serversUrl, Method = "GET"})
                else
                    -- Fallback to game:HttpGet which returns a string
                    return {Success = true, Body = game:HttpGet(serversUrl)}
                end
            end)

            if success and response and response.Success and response.Body then
                local decodeSuccess, serverData = pcall(HttpService.JSONDecode, HttpService, response.Body)
                if decodeSuccess and serverData and serverData.data then
                    local availableServers = {}
                    for _, server in ipairs(serverData.data) do
                        -- Add extra checks for data validity
                        if type(server.playing) == 'number' and server.playing < server.maxPlayers and server.id ~= game.JobId then
                            table.insert(availableServers, server)
                        end
                    end

                    if #availableServers > 0 then
                        local targetServer = availableServers[math.random(1, #availableServers)]
                        Library:Notify("Found a new server with " .. targetServer.playing .. "/" .. targetServer.maxPlayers .. " players. Teleporting...", 3)
                        
                        -- The script will terminate on a successful teleport. If it continues, the teleport failed.
                        pcall(function() 
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, Players.LocalPlayer) 
                        end)
                        
                        Library:Notify("Teleport attempt failed or server was full. Retrying in 5 seconds...", 3)
                        task.wait(5) -- Wait before trying to find another server
                    else
                        Library:Notify("No non-full servers found. Retrying in 10 seconds...", 3)
                        task.wait(10)
                    end
                else
                    Library:Notify("Failed to decode server list. Retrying in 10 seconds...", 3)
                    task.wait(10)
                end
            else
                Library:Notify("Failed to fetch server list. Retrying in 10 seconds...", 3)
                task.wait(10)
            end
        end
    end)
end

-- Teleport to Friend Functions
local http_service = game:GetService("HttpService")
local teleport_service = game:GetService("TeleportService")
local players_service = game:GetService("Players")
local local_player = players_service.LocalPlayer

local function make_request(url, method, body)
    local req_func = (syn and syn.request) or http_request or request
    if not req_func then
        Library:Notify("HTTP request function not available.", 3)
        return nil
    end
    
    local success, response = pcall(function()
        return req_func({Url = url, Method = method or "GET", Body = body})
    end)
    
    if success and response and response.Success and response.Body then
        local decode_success, data = pcall(http_service.JSONDecode, http_service, response.Body)
        if decode_success then
            return data
        end
    end
    return nil
end

function RefreshFriendsList()
    Library:Notify("Fetching friends list... This may take a moment.", 2)
    task.spawn(function()
        local friends_url = "https://friends.roblox.com/v1/users/" .. local_player.UserId .. "/friends"
        local friends_data = make_request(friends_url)
        
        if not friends_data or not friends_data.data then
            Library:Notify("Failed to fetch friends list.", 3)
            Options.FriendSelector:SetValues({"Error fetching friends"})
            return
        end
        
        local friend_names = {}
        for _, friend in ipairs(friends_data.data) do
            table.insert(friend_names, friend.name)
        end
        
        if #friend_names > 0 then
            table.sort(friend_names) -- Sort alphabetically
            Options.FriendSelector:SetValues(friend_names)
            Library:Notify("Successfully fetched " .. #friend_names .. " friends.", 2)
        else
            Options.FriendSelector:SetValues({"No friends found"})
            Library:Notify("You have no friends on Roblox.", 2)
        end
    end)
end

function TeleportToSelectedFriend()
    local selected_friend_name = Options.FriendSelector.Value
    if not selected_friend_name or selected_friend_name:find("No friends") or selected_friend_name:find("Error") then
        Library:Notify("Please select a valid friend.", 2)
        return
    end

    Library:Notify("Searching for " .. selected_friend_name .. "...", 2)
    
    task.spawn(function()
        -- First, get the friend's UserId
        local user_search_url = "https://users.roblox.com/v1/usernames/users"
        local search_payload = http_service:JSONEncode({usernames = {selected_friend_name}, excludeBannedUsers = true})
        local user_data = make_request(user_search_url, "POST", search_payload)
        
        if not user_data or not user_data.data or #user_data.data == 0 then
            Library:Notify("Could not find UserId for " .. selected_friend_name, 3)
            return
        end
        
        local friend_id = user_data.data[1].id
        
        -- Now, check their presence
        local presence_url = "https://presence.roblox.com/v1/presence/users"
        local presence_payload = http_service:JSONEncode({userIds = {friend_id}})
        local presence_data = make_request(presence_url, "POST", presence_payload)
        
        if not presence_data or not presence_data.userPresences or #presence_data.userPresences == 0 then
            Library:Notify("Could not get presence for " .. selected_friend_name, 3)
            return
        end
        
        local friend_presence = presence_data.userPresences[1]
        
        -- --- DIAGNOSTIC NOTIFICATIONS ---
        local friend_universeId = friend_presence.universeId or "N/A"
        local current_gameId = game.GameId or "N/A"
        Library:Notify("Friend UniverseID: " .. tostring(friend_universeId), 4)
        Library:Notify("Current GameID: " .. tostring(current_gameId), 4)
        -- --- END DIAGNOSTICS ---

        -- Correctly check if the friend is in the same game (Universe)
        if friend_presence.userPresenceType == 2 and tostring(friend_presence.universeId) == tostring(game.GameId) then
            Library:Notify("Friend found in this game! Teleporting...", 2)
            -- Teleport using the JobId (gameId in presence API) of the friend's server
            pcall(teleport_service.TeleportToPlaceInstance, teleport_service, game.PlaceId, friend_presence.gameId, local_player)
        else
            -- Provide more detailed feedback if the check fails
            local reason = "is not online."
            if friend_presence.userPresenceType == 1 then
                reason = "is online, but not in a game."
            elseif friend_presence.userPresenceType == 2 then
                reason = "is in a different game. (Friend: " .. tostring(friend_universeId) .. " | You: " .. tostring(current_gameId) .. ")"
            end
            Library:Notify(selected_friend_name .. " " .. reason, 5)
        end
    end)
end

-- Reconnect groupbox (clickable title to expand/collapse)
local ReconnectGroupBox = MainTab:AddRightGroupbox('Reconnect', 'wifi-cog')

-- Add always reconnect toggle
ReconnectGroupBox:AddToggle('AlwaysReconnect', {
    Text = 'Always Reconnect',
    Default = false,
    Tooltip = 'Automatically reconnect after death or disconnect.'
})

-- Add textbox for delay (minimum 3 seconds)
ReconnectGroupBox:AddInput('ReconnectDelay', {
    Default = '3',
    Numeric = true,
    Finished = true,
    Text = 'Reconnect Delay (seconds, min 3)',
    Tooltip = 'Set the delay before reconnecting (minimum 3 seconds)',
    Callback = function(Value)
        local num = tonumber(Value)
        if not num or num < 3 then
            Options.ReconnectDelay:SetValue('3')
            Library:Notify('Delay must be at least 3 seconds!')
        end
    end
})

-- Add reconnect button (uses delay)
ReconnectGroupBox:AddButton({
    Text = 'Reconnect (with delay)',
    Func = function()
        ShowReconnectNotificationAndTeleport()
    end,
    Tooltip = 'Reconnects you to the current game after the specified delay.'
})

-- Add immediate reconnect button
ReconnectGroupBox:AddButton({
    Text = 'Reconnect Now',
    Func = function()
        ShowReconnectNotificationAndTeleport(true)
    end,
    Tooltip = 'Reconnects you to the current game immediately.'
})

-- Add join different server button
ReconnectGroupBox:AddButton({
    Text = 'Join Different Server',
    Func = function()
        joinDifferentServer()
    end,
    Tooltip = 'Finds and joins a different, non-full server.'
})

-- Teleport to Friend groupbox
local TeleportFriendGroupBox = MainTab:AddRightGroupbox('Teleport to Friend', 'users')
TeleportFriendGroupBox:AddDivider()

TeleportFriendGroupBox:AddDropdown('FriendSelector', {
    Values = {"Click Refresh to load"},
    Default = nil,
    Multi = false,
    Text = 'Select Friend',
    Tooltip = 'Select a friend to join their server.',
    Searchable = true,
})

TeleportFriendGroupBox:AddButton({
    Text = 'Refresh Friends List',
    Func = function()
        RefreshFriendsList()
    end,
    Tooltip = 'Gets your full Roblox friends list.'
})

TeleportFriendGroupBox:AddButton({
    Text = 'Join Friend\'s Server',
    Func = function()
        TeleportToSelectedFriend()
    end,
    Tooltip = 'Joins the selected friend\'s server if they are in this game.'
})

-- Always reconnect logic
local alwaysReconnectConnection = nil
local floatingButton = nil
local reconnectCancelFlag = false

local function CreateAlwaysReconnectButton()
    if floatingButton then floatingButton:Destroy() end
    floatingButton = Instance.new("ScreenGui")
    floatingButton.Name = "AlwaysReconnectButton"
    floatingButton.ResetOnSpawn = false
    floatingButton.Parent = game.CoreGui
    floatingButton.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 400, 0, 80)
    button.Position = UDim2.new(0.5, 0, 0, 20) -- Top center, perfectly centered
    button.AnchorPoint = Vector2.new(0.5, 0)
    button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 32
    button.Text = "Disable Always Reconnect"
    button.Parent = floatingButton
    button.AutoButtonColor = true
    button.ZIndex = 1000
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        reconnectCancelFlag = true
        if floatingButton then
            floatingButton:Destroy()
            floatingButton = nil
        end
        Library:Notify('Always Reconnect cancelled!')
        Toggles.AlwaysReconnect:SetValue(false)
    end)
end

Toggles.AlwaysReconnect:OnChanged(function()
    if Toggles.AlwaysReconnect.Value then
        if alwaysReconnectConnection then alwaysReconnectConnection:Disconnect() end
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        alwaysReconnectConnection = player.CharacterRemoving:Connect(function()
            -- Wait a short moment to ensure character is removed
            task.wait(0.5)
            ShowReconnectNotificationAndTeleport()
        end)
        -- Create floating button BEFORE triggering reconnect logic
        CreateAlwaysReconnectButton()
        -- Reset cancel flag and trigger reconnect logic
        reconnectCancelFlag = false
        ShowReconnectNotificationAndTeleport()
    else
        if alwaysReconnectConnection then alwaysReconnectConnection:Disconnect() end
        alwaysReconnectConnection = nil
        -- Remove floating button
        if floatingButton then 
            floatingButton:Destroy()
            floatingButton = nil
        end
        reconnectCancelFlag = true
        Library:Notify('Always Reconnect cancelled!')
    end
end)

-- If the toggle is already enabled at script start, trigger logic and show button
if Toggles.AlwaysReconnect and Toggles.AlwaysReconnect.Value then
    CreateAlwaysReconnectButton()
    ShowReconnectNotificationAndTeleport()
end

function ShowReconnectNotificationAndTeleport(immediate)
    -- Reset cancel flag for manual reconnects
    if not (Toggles.AlwaysReconnect and Toggles.AlwaysReconnect.Value) then
        reconnectCancelFlag = false
    end
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local delayValue = tonumber(Options.ReconnectDelay.Value) or 3
    if delayValue < 3 then delayValue = 3 end
    if immediate then delayValue = 0 end
    for i = delayValue, 1, -1 do
        if reconnectCancelFlag then return end
        Library:Notify("Reconnecting in " .. i .. "s...")
        task.wait(1)
    end
    if reconnectCancelFlag then return end
    Library:Notify("Reconnecting...")
    TeleportService:Teleport(game.PlaceId, player)
end

-- Add service and player setup at the top
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

local speedConnection = nil
local noclipConnection = nil
local infJumpConnection = nil
local speedValue = 35
local speedEnabled = false
local noclipEnabled = false
local infJumpEnabled = false

function SetPlayerSpeed(speed)
    speedValue = speed
    if speedEnabled then
        local character = LocalPlayer.Character
        if character and character:FindFirstChildOfClass('Humanoid') then
            character:FindFirstChildOfClass('Humanoid').WalkSpeed = speedValue
        end
    end
end

function ToggleSpeed(enabled)
    speedEnabled = enabled
    if enabled then
        if speedConnection then speedConnection:Disconnect() end
        speedConnection = RunService.RenderStepped:Connect(function()
            local character = LocalPlayer.Character
            if character and character:FindFirstChildOfClass('Humanoid') then
                character:FindFirstChildOfClass('Humanoid').WalkSpeed = speedValue
            end
        end)
    else
        if speedConnection then speedConnection:Disconnect() end
        speedConnection = nil
        local character = LocalPlayer.Character
        if character and character:FindFirstChildOfClass('Humanoid') then
            character:FindFirstChildOfClass('Humanoid').WalkSpeed = 16 -- Roblox default
        end
    end
end

function ToggleNoClip(enabled)
    noclipEnabled = enabled
    if enabled then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA('BasePart') and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = nil
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA('BasePart') then
                    part.CanCollide = true
                end
            end
        end
    end
end

function ToggleInfiniteJump(enabled)
    infJumpEnabled = enabled
    if enabled then
        if infJumpConnection then infJumpConnection:Disconnect() end
        infJumpConnection = UserInputService.JumpRequest:Connect(function()
            local character = LocalPlayer.Character
            if character and character:FindFirstChildOfClass('Humanoid') then
                character:FindFirstChildOfClass('Humanoid'):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if infJumpConnection then infJumpConnection:Disconnect() end
        infJumpConnection = nil
    end
end

-- =================================================================
-- AUTO PICKUP AND PLACE PET FEATURE (Added by Gemini)
-- =================================================================
local AutoPickupPlaceGroupBox = PetsTab:AddLeftGroupbox('Pickup and Place Pet', 'hand')
AutoPickupPlaceGroupBox:AddDivider()

AutoPickupPlaceGroupBox:AddDropdown('TargetPet', {
    Values = {},
    Default = nil,
    Multi = false,
    Text = 'Target Pet',
    Tooltip = 'Select the pet to monitor for cooldown.',
    Searchable = true,
})

AutoPickupPlaceGroupBox:AddInput('CooldownInput', {
    Default = '0',
    Numeric = true,
    Finished = true,
    Text = 'Cooldown Input',
    Tooltip = 'Set the cooldown threshold.',
})

AutoPickupPlaceGroupBox:AddDropdown('PetsToPickupPlace', {
    Values = {},
    Default = {},
    Multi = true,
    Text = 'Select Pets to Pickup and Place',
    Tooltip = 'Select the pets to be picked up or placed.',
    Searchable = true,
})

AutoPickupPlaceGroupBox:AddDropdown('PetToSwap', {
    Values = {},
    Default = nil,
    Multi = false,
    Text = 'Select Pet to Swap',
    Tooltip = 'Select the pet to place when others are picked up.',
    Searchable = true,
})

AutoPickupPlaceGroupBox:AddToggle('EnableAutoPickupPlace', {
    Text = 'Enable Auto Pickup/Place',
    Default = false,
    Tooltip = 'Automatically picks up or places pets based on the target pet\'s cooldown.'
})

local autoPickupPlaceActive = false
local lastPickupPlaceAction = nil -- Tracks the last action to prevent notification spam

Toggles.EnableAutoPickupPlace:OnChanged(function(value)
    autoPickupPlaceActive = value
    if value then
        lastPickupPlaceAction = nil -- Reset on enable
        Library:Notify('Auto Pickup/Place Enabled!', 2)
        task.spawn(function()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local PetsService = ReplicatedStorage.GameEvents.PetsService
            local GetPetCooldown = ReplicatedStorage.GameEvents.GetPetCooldown
            local petUUIDMapping = _G.PetUUIDMapping or {}

            while autoPickupPlaceActive do
                local targetPetName = Options.TargetPet.Value
                local cooldownThreshold = tonumber(Options.CooldownInput.Value) or 0
                local selectedPetsToActOn = Options.PetsToPickupPlace.Value
                
                if not targetPetName or not selectedPetsToActOn or next(selectedPetsToActOn) == nil then
                    task.wait(1)
                else
                    local targetPetUUID = petUUIDMapping[targetPetName]
                    if targetPetUUID then
                        local success, cooldownData = pcall(function()
                            return GetPetCooldown:InvokeServer(targetPetUUID)
                        end)

                        if success and type(cooldownData) == "table" and cooldownData[1] and cooldownData[1].Time then
                            local currentCooldown = tonumber(cooldownData[1].Time) or 0

                            local petsToActOnUUIDs = {}
                            for petName, isSelected in pairs(selectedPetsToActOn) do
                                if isSelected then
                                    if petName == "All" then
                                        petsToActOnUUIDs = {}
                                        for _, uuid in pairs(petUUIDMapping) do table.insert(petsToActOnUUIDs, uuid) end
                                        break
                                    else
                                        local uuid = petUUIDMapping[petName]
                                        if uuid then table.insert(petsToActOnUUIDs, uuid) end
                                    end
                                end
                            end

                            if currentCooldown <= cooldownThreshold then
                                if lastPickupPlaceAction ~= "pickup" then
                                    Library:Notify("Target pet cooldown is low. Picking up pets.", 1)
                                    lastPickupPlaceAction = "pickup"
                                    -- Pickup pets
                                    for _, petUUID in ipairs(petsToActOnUUIDs) do
                                        if not autoPickupPlaceActive then break end
                                        PetsService:FireServer("UnequipPet", petUUID)
                                        task.wait(0.2)
                                    end
                                    -- Swap pet
                                    local petToSwapName = Options.PetToSwap.Value
                                    if petToSwapName then
                                        local petToSwapUUID = petUUIDMapping[petToSwapName]
                                        if petToSwapUUID then
                                            local placeCFrame = CFrame.new(47, 0, -95, 1, 0, 0, 0, 1, 0, 0, 0, 1)
                                            PetsService:FireServer("EquipPet", petToSwapUUID, placeCFrame)
                                        end
                                    end
                                end
                            else
                                if lastPickupPlaceAction ~= "place" then
                                    Library:Notify("Target pet cooldown is high. Placing pets.", 1)
                                    lastPickupPlaceAction = "place"
                                    -- Place pets
                                    for _, petUUID in ipairs(petsToActOnUUIDs) do
                                        if not autoPickupPlaceActive then break end
                                        local placeCFrame = CFrame.new(47, 0, -95, 1, 0, 0, 0, 1, 0, 0, 0, 1)
                                        PetsService:FireServer("EquipPet", petUUID, placeCFrame)
                                        task.wait(0.2)
                                    end
                                    -- Pick up the swapped pet to complete the swap
                                    local petToSwapName = Options.PetToSwap.Value
                                    if petToSwapName then
                                        local petToSwapUUID = petUUIDMapping[petToSwapName]
                                        if petToSwapUUID then
                                            PetsService:FireServer("UnequipPet", petToSwapUUID)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(2) -- Wait 2 seconds before the next check
            end
        end)
    else
        Library:Notify('Auto Pickup/Place Disabled!', 2)
    end
end)


-- Pet ESP groupbox (moved to Pets tab)
local PetManagerGroupBox = PetsTab:AddLeftGroupbox('Pet ESP', 'eye')

PetManagerGroupBox:AddDivider()

-- Add multi dropdown for pet UUIDs
PetManagerGroupBox:AddDropdown('PetUUIDs', {
    Values = {},
    Default = {},
    Multi = true,
    Text = 'Select Pets',
    Tooltip = 'All your pet UUIDs (click Refresh to update)',
    Searchable = true,
    Callback = function(Value)
        -- Optional: Add functionality when UUIDs are selected
    end
})

-- Add button to refresh and display pet UUIDs
PetManagerGroupBox:AddButton({
    Text = 'Refresh Pet UUIDs',
    Func = function()
        RefreshPetUUIDs()
    end,
    Tooltip = 'Refresh and display all pet UUIDs from your ActivePetUI.'
})

-- Add toggle for ESP
PetManagerGroupBox:AddToggle('PetCDESP', {
    Text = 'Enable Pet CD ESP',
    Default = false,
    Tooltip = 'Show cooldown timers above pet heads in 3D space.',
    Callback = function(Value)
        if Value then
            StartPetCDESP()
        else
            StopPetCDESP()
        end
    end
})

-- Add toggle to show UUIDs
PetManagerGroupBox:AddToggle('ShowUUIDs', {
    Text = 'Show UUIDs',
    Default = false,
    Tooltip = 'Show pet UUIDs under the cooldown time in ESP.'
})



-- =================================================================
-- PET AUTO FEED FEATURE (Added by Gemini)
-- =================================================================
local AutoFeedGroupBox = PetsTab:AddRightGroupbox('Auto Feed Boosts', 'utensils')
AutoFeedGroupBox:AddDivider()

-- Dropdown for selecting pets to feed
AutoFeedGroupBox:AddDropdown('FeedPetSelection', {
    Values = {},
    Default = {},
    Multi = true,
    Text = 'Select Pets to Feed',
    Tooltip = 'Select pets to automatically feed boosts to. Use the Refresh button in other sections.',
    Searchable = true,
})

-- Dropdown for selecting the boost item to use
AutoFeedGroupBox:AddDropdown('FeedItemSelection', {
    Values = {"Medium Pet Toy", "Small Pet Toy", "Medium Pet Treat", "Small Pet Treat"},
    Default = "Medium Pet Toy",
    Multi = false,
    Text = 'Select Item to Use',
    Tooltip = 'Select the item you want the script to equip before feeding.',
    Searchable = true,
})

-- Toggle to enable/disable the auto-feed loop
AutoFeedGroupBox:AddToggle('EnableAutoFeed', {
    Text = 'Enable Auto Feed',
    Default = false,
    Tooltip = 'Automatically equips an item and feeds selected pets when their boost timer is out.'
})

-- Helper function to get pet boost timers from the PetLoadout UI
local function getPetBoostTimers(uuid)
    local boost1Time, boost2Time = "N/A", "N/A"
    local success, err = pcall(function()
        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local petLoadout = playerGui:FindFirstChild("PetLoadout")
        if not petLoadout or not petLoadout:FindFirstChild("ScreenGui") then return end
        
        local petFrame = petLoadout.ScreenGui:FindFirstChild(uuid)
        if not petFrame then return end
        
        -- Navigate the complex UI path to find the boost labels, checking each step
        local boostHolder = petFrame:FindFirstChild("Detail", true)
        if boostHolder then boostHolder = boostHolder:FindFirstChild("Holder", true) end
        if boostHolder then boostHolder = boostHolder:FindFirstChild("DisplayBox", true) end
        if boostHolder then boostHolder = boostHolder:FindFirstChild("PetBoosts", true) end
        if not boostHolder then return end

        local boost1Label = boostHolder:FindFirstChild("PET_BOOST1")
        local boost2Label = boostHolder:FindFirstChild("PET_BOOST2")

        boost1Time = (boost1Label and boost1Label.Text) or "N/A"
        boost2Time = (boost2Label and boost2Label.Text) or "N/A"
    end)

    if not success then
        warn("AutoFeed: Error getting boost timers for " .. uuid .. ": " .. tostring(err))
    end

    return boost1Time, boost2Time
end

-- UPDATED equipItem function to handle dynamic names
local function equipItem(itemName)
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Backpack = LocalPlayer.Backpack

    -- First, unequip any existing tool
    for _, tool in ipairs(Character:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = Backpack
        end
    end
    task.wait(0.1) -- Small delay to ensure unequip registers

    -- Now, find and equip the new tool by checking if the name starts with the base item name
    local toolToEquip = nil
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name:match("^" .. itemName) then
            toolToEquip = item
            break -- Found a match, stop searching
        end
    end

    if toolToEquip then
        toolToEquip.Parent = Character
        print("SCRIPT: Equipped: " .. toolToEquip.Name) -- Less intrusive notification
        task.wait(0.25) 
        return true -- Indicate success
    else
        warn("SCRIPT: Could not find item to equip: " .. itemName)
        return false -- Indicate failure
    end
end

-- NEW unequipItem function based on provided code
local function unequipItem()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Backpack = LocalPlayer.Backpack
    local unequipped = false
    
    for _, tool in ipairs(Character:GetChildren()) do
        if tool:IsA("Tool") then
            print("SCRIPT: Unequipping: " .. tool.Name) -- Less intrusive notification
            tool.Parent = Backpack
            unequipped = true
        end
    end
    
    if unequipped then
        task.wait(0.25)
    end
end


-- Logic for the "Auto Feed" toggle
local autoFeedActive = false

Toggles.EnableAutoFeed:OnChanged(function(value)
    autoFeedActive = value
    if value then
        Library:Notify('Auto Feed Enabled!', 2)
        task.spawn(function()
            local PetBoostService = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("PetBoostService")

            while autoFeedActive do
                local selectedPets = Options.FeedPetSelection.Value
                local selectedItem = Options.FeedItemSelection.Value
                local petUUIDMapping = _G.PetUUIDMapping or {}
                
                -- Determine the full list of pets to check
                local petsToCheck = {}
                if type(selectedPets) == "table" and next(selectedPets) ~= nil then
                    for petName, isSelected in pairs(selectedPets) do
                        if isSelected then
                            if petName == "All" then
                                petsToCheck = {} 
                                for _, uuid in pairs(petUUIDMapping) do table.insert(petsToCheck, uuid) end
                                break
                            else
                                local uuid = petUUIDMapping[petName]
                                if uuid then table.insert(petsToCheck, uuid) end
                            end
                        end
                    end
                end

                -- First pass: find all pets that need the selected boost type
                local petsNeedingBoost = {}
                for _, uuid in ipairs(petsToCheck) do
                    if not autoFeedActive then break end
                    
                    local boost1Timer, boost2Timer = getPetBoostTimers(uuid)
                    -- This logic ensures we only feed pets whose timer is expired
                    local needsBoost1 = (boost1Timer == "0" or boost1Timer == "N/A" or string.lower(boost1Timer) == "none" or boost1Timer == "")
                    local needsBoost2 = (boost2Timer == "0" or boost2Timer == "N/A" or string.lower(boost2Timer) == "none" or boost2Timer == "")

                    if string.find(selectedItem, "Toy") and needsBoost1 then
                        table.insert(petsNeedingBoost, uuid)
                    elseif string.find(selectedItem, "Treat") and needsBoost2 then
                        table.insert(petsNeedingBoost, uuid)
                    end
                end

                -- Second pass: if any pets need the boost, perform the actions
                if #petsNeedingBoost > 0 and autoFeedActive then
                    -- 1. Equip the item. If it fails, stop this cycle.
                    if equipItem(selectedItem) then
                        -- 2. Feed all pets that need it
                        for _, uuid in ipairs(petsNeedingBoost) do
                            if not autoFeedActive then break end
                            print("SCRIPT: Feeding " .. selectedItem .. " to pet " .. uuid:sub(1,8) .. "...")
                            PetBoostService:FireServer("ApplyBoost", uuid)
                            task.wait(0.5) -- Wait between feeds to prevent server overload
                        end

                        -- 3. Unequip the item
                        if autoFeedActive then -- Check again before unequipping
                            unequipItem()
                        end
                    end
                end
                
                task.wait(2) -- Wait 2 seconds before the next full check
            end
        end)
    else
        Library:Notify('Auto Feed Disabled!', 2)
    end
end)

-- Ensure toggles are properly connected to config system
Toggles.PetCDESP:OnChanged(function(Value)
    if Value then
        pcall(function() StartPetCDESP() end)
    else
        pcall(function() StopPetCDESP() end)
    end
end)

Toggles.ShowUUIDs:OnChanged(function(Value)
    -- This toggle affects the ESP display, so we need to restart ESP if it's active
    if Toggles.PetCDESP and Toggles.PetCDESP.Value then
        pcall(function() StartPetCDESP() end)
    end
end)

-- Optimized ESP variables
local petESPConnections = {}
local petESPGuis = {}
local petLastUpdateTimes = {} -- Individual update times per pet

function CreatePetESP(petID)
    local espGui = Instance.new("BillboardGui")
    espGui.Name = "PetESP_" .. petID
    espGui.Size = UDim2.new(0, 100, 0, 30)
    espGui.StudsOffset = Vector3.new(0, 4, 0)
    espGui.AlwaysOnTop = true
    espGui.Adornee = nil
    espGui.Parent = game.CoreGui

    -- Create background frame
    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
    backgroundFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backgroundFrame.BackgroundTransparency = 0.3
    backgroundFrame.BorderSizePixel = 0
    backgroundFrame.Parent = espGui

    -- Add rounded corners to background
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = backgroundFrame

    -- Add stroke to background
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = backgroundFrame

    local espLabel = Instance.new("TextLabel")
    espLabel.Size = UDim2.new(1, 0, 1, 0)
    espLabel.BackgroundTransparency = 1
    espLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    espLabel.TextScaled = false
    espLabel.TextSize = 16
    espLabel.Font = Enum.Font.GothamBold
    espLabel.Text = "Searching for pet..."
    espLabel.Parent = espGui

    local connection = RunService.RenderStepped:Connect(function()
        -- Check if ESP is still enabled
        if not Toggles.PetCDESP.Value then
            return
        end
        
        local currentTime = tick()
        if not petLastUpdateTimes[petID] or (currentTime - petLastUpdateTimes[petID]) >= 1 then
            petLastUpdateTimes[petID] = currentTime
            
            local petFound = false
            local workspace = game:GetService("Workspace")
            
            -- Search in multiple possible locations for the pet
            local searchLocations = {
                workspace.PetsPhysical,
                workspace,
                workspace:FindFirstChild("Plots"),
                workspace:FindFirstChild("PetMover"),
                workspace:FindFirstChild("Pets")
            }
            
            for _, location in pairs(searchLocations) do
                if location then
                    -- Search recursively for the pet
                    local function searchRecursively(parent)
                        for _, child in pairs(parent:GetChildren()) do
                            if child.Name == petID then
                                espGui.Adornee = child
                                petFound = true
                                return true
                            end
                            -- Search in children recursively
                            if searchRecursively(child) then
                                return true
                            end
                        end
                        return false
                    end
                    
                    if searchRecursively(location) then
                        break
                    end
                end
            end
            
            if petFound then
                -- Get cooldown data
                local success, cooldownData = pcall(function()
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local GetPetCooldown = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("GetPetCooldown")
                    return GetPetCooldown:InvokeServer(petID)
                end)
                
                if success and cooldownData and typeof(cooldownData) == "table" and cooldownData[1] then
                    local cooldown1 = ""
                    local cooldown2 = ""
                    
                    -- Look for cooldowns in the data structure
                    if cooldownData[1] and typeof(cooldownData[1]) == "table" then
                        cooldown1 = tostring(cooldownData[1].Time or cooldownData[1].time or "") .. "s"
                    end
                    
                    if cooldownData[2] and typeof(cooldownData[2]) == "table" then
                        cooldown2 = tostring(cooldownData[2].Time or cooldownData[2].time or "") .. "s"
                    end
                    
                    -- Format the cooldown display
                    local cooldownText = ""
                    if cooldown1 ~= "" and cooldown2 ~= "" then
                        cooldownText = cooldown1 .. " | " .. cooldown2
                    elseif cooldown1 ~= "" then
                        cooldownText = cooldown1
                    elseif cooldown2 ~= "" then
                        cooldownText = cooldown2
                    end
                    
                    if cooldownText == "" then
                        -- If no specific cooldown found, check for passive or N/A
                        local onlyPassive = true
                        for key, value in pairs(cooldownData[1]) do
                            if key ~= "Passive" and key ~= "passive" then
                                onlyPassive = false
                                break
                            end
                        end
                        if onlyPassive or next(cooldownData[1]) == nil then
                            if Toggles.ShowUUIDs and Toggles.ShowUUIDs.Value then
                                espLabel.RichText = true
                                espLabel.Text = "CD: N/A\n<font color=\"rgb(255,255,0)\">" .. petID .. "</font>"
                            else
                                espLabel.RichText = false
                                espLabel.Text = "CD: N/A"
                            end
                            espLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gray for N/A
                        else
                            -- If no specific cooldown found, show all data for debugging
                            local debugText = ""
                            for key, value in pairs(cooldownData[1]) do
                                if key ~= "Passive" and key ~= "passive" then
                                    debugText = debugText .. tostring(key) .. ":" .. tostring(value) .. " "
                                end
                            end
                            espLabel.Text = debugText
                            espLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow for debug
                        end
                    else
                        -- Show UUID under cooldown if toggle is enabled
                        if Toggles.ShowUUIDs and Toggles.ShowUUIDs.Value then
                            espLabel.RichText = true
                            espLabel.Text = cooldownText .. "\n<font color=\"rgb(255,255,0)\">" .. petID .. "</font>"
                        else
                            espLabel.RichText = false
                            espLabel.Text = cooldownText
                        end
                        espLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green for success
                    end
                else
                    if Toggles.ShowUUIDs and Toggles.ShowUUIDs.Value then
                        espLabel.RichText = true
                        espLabel.Text = "CD: N/A\n<font color=\"rgb(255,255,0)\">" .. petID .. "</font>"
                    else
                        espLabel.RichText = false
                        espLabel.Text = "CD: N/A"
                    end
                    espLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gray for N/A
                end
            else
                espLabel.Text = "Pet not found in world"
                espLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red for not found
            end
        end
    end)
    
    table.insert(petESPConnections, connection)
    petESPGuis[petID] = espGui -- Store the GUI reference
    return espGui
end

function RefreshPetUUIDs()
    local success, result = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        if not player then
            Library:Notify("LocalPlayer not found!")
            return
        end
        
        local activePetUI = player.PlayerGui:FindFirstChild("ActivePetUI")
        if not activePetUI then
            Library:Notify("ActivePetUI not found!")
            return
        end
        
        local scrollingFrame = activePetUI.Frame.Main:FindFirstChild("PetDisplay") and activePetUI.Frame.Main.PetDisplay:FindFirstChild("ScrollingFrame")
        if not scrollingFrame then
            Library:Notify("ScrollingFrame not found in new path!")
            return
        end
        
        local petTypes = {}
        local uuidToPetType = {} -- Map UUIDs to pet types for internal use
        local petTypeCounts = {} -- Track how many of each pet type we have
        
        for _, child in pairs(scrollingFrame:GetChildren()) do
            if child.Name:match("^%{%w+%-%w+%-%w+%-%w+%-%w+%}$") then
                local mainFrame = child:FindFirstChild("Main")
                local petType = mainFrame and mainFrame:FindFirstChild("PET_TYPE", true)
                if petType then
                    local basePetType = petType.Text or petType.Value or "Unknown"
                    
                    -- Count this pet type
                    petTypeCounts[basePetType] = (petTypeCounts[basePetType] or 0) + 1
                    
                    -- Create unique name if there are duplicates
                    local uniquePetType = basePetType
                    if petTypeCounts[basePetType] > 1 then
                        uniquePetType = basePetType .. " (" .. petTypeCounts[basePetType] .. ")"
                    end
                    
                    table.insert(petTypes, uniquePetType)
                    uuidToPetType[uniquePetType] = child.Name -- Store UUID mapped to unique pet type
                else
                    -- Fallback to UUID if PET_TYPE not found
                    table.insert(petTypes, child.Name)
                    uuidToPetType[child.Name] = child.Name
                end
            end
        end
        
        if #petTypes == 0 then
            Library:Notify("No pets found!")
            return
        end
        
        -- Add "All" option to the beginning
        table.insert(petTypes, 1, "All")
        
        -- Store the mapping for use in ESP functions
        _G.PetUUIDMapping = uuidToPetType
        
        -- Update all relevant dropdowns with pet types
        Options.PetUUIDs:SetValues(petTypes)
        Options.FeedPetSelection:SetValues(petTypes)
        Options.TargetPet:SetValues(petTypes)
        Options.PetsToPickupPlace:SetValues(petTypes)
        Options.PetToSwap:SetValues(petTypes)
        
        Library:Notify("Found " .. (#petTypes - 1) .. " pets and updated all dropdowns!")
        
    end)
    
    if not success then
        Library:Notify("Error: " .. tostring(result))
    end
end

function CheckPetCooldowns()
    local success, result = pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local GetPetCooldown = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("GetPetCooldown")
        
        -- Get selected pet types from the dropdown and convert to UUIDs
        local selectedUUIDs = {}
        local petUUIDMapping = _G.PetUUIDMapping or {}
        
        for petType, isSelected in pairs(Options.PetUUIDs.Value) do
            if isSelected then
                if petType == "All" then
                    -- Add all UUIDs when "All" is selected
                    for _, uuid in pairs(petUUIDMapping) do
                        table.insert(selectedUUIDs, uuid)
                    end
                else
                    local uuid = petUUIDMapping[petType]
                    if uuid then
                        table.insert(selectedUUIDs, uuid)
                    end
                end
            end
        end
        
        if #selectedUUIDs == 0 then
            Library:Notify("Please select at least one pet from the dropdown!")
            return
        end
        
        Library:Notify("Checking cooldowns for " .. #selectedUUIDs .. " pets...")
        
        for i, petID in ipairs(selectedUUIDs) do
            local cooldownData = GetPetCooldown:InvokeServer(petID)
            
            if typeof(cooldownData) == "table" and typeof(cooldownData[1]) == "table" then
                local cooldownInfo = "Pet " .. i .. " (" .. petID:sub(1, 8) .. "...):\n"
                for key, value in pairs(cooldownData[1]) do
                    cooldownInfo = cooldownInfo .. "  " .. tostring(key) .. ": " .. tostring(value) .. "\n"
                end
                Library:Notify(cooldownInfo)
            else
                Library:Notify("Pet " .. i .. " (" .. petID:sub(1, 8) .. "...): Invalid data structure")
            end
            
            -- Small delay between requests to avoid overwhelming the server
            task.wait(0.1)
        end
        
        Library:Notify("Cooldown check completed!")
        
    end)
    
    if not success then
        Library:Notify("Error: " .. tostring(result))
    end
end

function StartPetCDESP()
    if not Toggles.PetCDESP.Value then
        Library:Notify("Please enable Pet CD ESP toggle first!")
        return
    end
    
    -- Get selected pet types from the dropdown and convert to UUIDs
    local selectedUUIDs = {}
    local petUUIDMapping = _G.PetUUIDMapping or {}
    
    for petType, isSelected in pairs(Options.PetUUIDs.Value) do
        if isSelected then
            if petType == "All" then
                -- Add all UUIDs when "All" is selected
                for _, uuid in pairs(petUUIDMapping) do
                    table.insert(selectedUUIDs, uuid)
                end
            else
                local uuid = petUUIDMapping[petType]
                if uuid then
                    table.insert(selectedUUIDs, uuid)
                end
            end
        end
    end
    
    if #selectedUUIDs == 0 then
        Library:Notify("Please select at least one pet from the dropdown!")
        return
    end
    
    -- Clear existing ESP
    StopPetCDESP()
    
    Library:Notify("Starting ESP for " .. #selectedUUIDs .. " pets...")
    
    -- Start ESP for each selected pet
    for _, petID in ipairs(selectedUUIDs) do
        CreatePetESP(petID)
    end
end

function StopPetCDESP()
    -- Disconnect all ESP connections
    for _, connection in pairs(petESPConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    petESPConnections = {}
    
    -- Remove all ESP GUIs
    for petID, gui in pairs(petESPGuis) do
        if gui and gui.Parent then
            gui:Destroy()
        end
    end
    petESPGuis = {}
    
    -- Clear update times
    petLastUpdateTimes = {}
    
    -- Also destroy any remaining ESP GUIs in CoreGui (cleanup)
    local coreGui = game:GetService("CoreGui")
    for _, child in pairs(coreGui:GetChildren()) do
        if child.Name:match("^PetESP_") then
            child:Destroy()
        end
    end
end

-- Stop ESP when toggle is disabled
Toggles.PetCDESP:OnChanged(function()
    if not Toggles.PetCDESP.Value then
        StopPetCDESP()
        Library:Notify("Pet CD ESP disabled!")
    end
end)

-- Pet Mutation groupbox in Pets tab
local PetMutationGroupBox = PetsTab:AddRightGroupbox('Pet Mutation', 'battery-charging')

PetMutationGroupBox:AddButton({
    Text = 'Start Timer',
    Func = function()
        local args = {"StartMachine"}
        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("PetMutationMachineService_RE"):FireServer(unpack(args))
    end,
    Tooltip = 'Start the mutation machine timer.'
})

PetMutationGroupBox:AddButton({
    Text = 'Submit Held Pet',
    Func = function()
        local args = {"SubmitHeldPet"}
        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("PetMutationMachineService_RE"):FireServer(unpack(args))
    end,
    Tooltip = 'Submit your currently held pet to the mutation machine.'
})

-- Function to get seeds from the player's backpack
function RefreshBackpackSeeds()
    local player = game:GetService('Players').LocalPlayer
    if not player then return end

    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end

    local seedItems = {}
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name:find("Seed") then
            table.insert(seedItems, item.Name)
        end
    end

    if #seedItems > 0 then
        Options.AutoPlantSeedItem:SetValues(seedItems)
        Library:Notify('Found ' .. #seedItems .. ' seed types in your backpack.')
    else
        Library:Notify('No seeds found in backpack.')
        Options.AutoPlantSeedItem:SetValues({}) -- Clear the dropdown if no seeds are found
    end
end

-- =================================================================
-- PLANTS TAB
-- =================================================================
local AutoPlantGroupBox = PlantsTab:AddLeftGroupbox('Auto Plant', 'sprout')
AutoPlantGroupBox:AddDivider()

-- Dropdown to select seeds from the backpack
AutoPlantGroupBox:AddDropdown('AutoPlantSeedItem', {
    Values = {}, -- Will be populated by RefreshBackpackSeeds
    Default = nil,
    Multi = false,
    Text = 'Select Seed to Plant',
    Tooltip = 'Select a seed from your backpack to plant. Opens to refresh.',
    Searchable = true,
    MenuOpened = function()
        RefreshBackpackSeeds()
    end,
})

-- Input for planting delay
AutoPlantGroupBox:AddInput('AutoPlantDelay', {
    Default = '0.3',
    Numeric = true,
    Finished = true,
    Text = 'Planting Delay (seconds)',
    Tooltip = 'Set the delay between each plant action.',
})

-- Dropdown for planting location
AutoPlantGroupBox:AddDropdown('PlantLocation', {
    Values = {"At Player Location"},
    Default = "At Player Location",
    Text = 'Planting Location',
    Tooltip = 'Choose where to plant the seeds.'
})

-- Toggle for auto plant
AutoPlantGroupBox:AddToggle('AutoPlant', {
    Text = 'Auto Plant Seed',
    Default = false,
    Tooltip = 'Automatically equips and plants the selected seed at the chosen location.'
})

local autoPlantActive = false
Toggles.AutoPlant:OnChanged(function(value)
    autoPlantActive = value
    if value then
        task.spawn(function()
            Library:Notify('Auto Plant enabled!')
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Plant_RE = ReplicatedStorage.GameEvents.Plant_RE
            
            local selectedSeedFullName = Options.AutoPlantSeedItem.Value
            if not selectedSeedFullName or selectedSeedFullName == "" then
                Library:Notify("No seed selected. Disabling Auto Plant.", 3)
                Toggles.AutoPlant:SetValue(false)
                return
            end
            
            -- Extract base name, e.g., "Carrot Seed" from "Carrot Seed [X70]"
            local baseSeedName = selectedSeedFullName:match("(.+) %[%w+%]") or selectedSeedFullName
            
            -- Equip the item once at the start
            if not equipItem(baseSeedName) then
                Library:Notify("Could not find or equip " .. (baseSeedName or "seed") .. ". Disabling.", 3)
                Toggles.AutoPlant:SetValue(false)
                return
            end

            while autoPlantActive do
                local delay = tonumber(Options.AutoPlantDelay.Value) or 0.3
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local playerPos = character.HumanoidRootPart.Position
                    -- The remote event likely wants the plant type (e.g., "Carrot") not the tool name ("Carrot Seed")
                    local plantType = baseSeedName:gsub(" Seed", "")
                    Plant_RE:FireServer(playerPos, plantType)
                end
                
                task.wait(delay) -- Wait for the specified delay
            end
        end)
    else
        Library:Notify('Auto Plant disabled!')
        -- Unequip any tool when disabling
        unequipItem()
    end
end)


-- =================================================================
-- SHOP TAB
-- =================================================================
local ShopTabBox = ShopTab:AddLeftTabbox()

-- =================================================================
-- SEED TAB
-- =================================================================
local SeedTab = ShopTabBox:AddTab("Seed")

-- Dropdown for seed items (auto-refresh on open)
SeedTab:AddDropdown('AutoBuySeedItem', {
    Values = {},
    Default = nil,
    Multi = true,
    Text = 'Select Seed',
    Tooltip = 'Select a seed to auto buy from the seed shop.',
    Searchable = true,
    MenuOpened = function()
        RefreshSeedItems()
    end
})

-- Function to refresh seed items from the shop
function RefreshSeedItems()
    local player = game:GetService('Players').LocalPlayer
    local seedShop = player:FindFirstChild('PlayerGui') and player.PlayerGui:FindFirstChild('Seed_Shop')
    if not seedShop then
        Library:Notify('Seed Shop UI not found!')
        return
    end
    local frame = seedShop:FindFirstChild('Frame')
    if not frame then
        Library:Notify('Seed Shop Frame not found!')
        return
    end
    local scrolling = frame:FindFirstChild('ScrollingFrame')
    if not scrolling then
        Library:Notify('Seed Shop ScrollingFrame not found!')
        return
    end
    local items = {}
    for _, child in ipairs(scrolling:GetChildren()) do
        if child:IsA('Frame') and child.Name ~= '' and not child.Name:match('^UI') and not child.Name:find('_Padding') and child.Name ~= 'ItemPadding' then
            table.insert(items, child.Name)
        end
    end
    if #items == 0 then
        Library:Notify('No seeds found in Seed Shop!')
    end
    Options.AutoBuySeedItem:SetValues(items)
    Library:Notify('Found ' .. tostring(#items) .. ' seeds!')
end

-- Auto-refresh at script startup
RefreshSeedItems()

local autoBuySeedActive = false
local autoBuyAllSeedActive = false

-- Toggle for auto buy seeds
SeedTab:AddToggle('AutoBuySeed', {
    Text = 'Auto Buy Seed',
    Default = false,
    Tooltip = 'Automatically buys the selected seed(s) with a delay to prevent lag.'
})

Toggles.AutoBuySeed:OnChanged(function(value)
    autoBuySeedActive = value
    if value then
        task.spawn(function()
            Library:Notify('Auto Buy Seed enabled!')
            while autoBuySeedActive do
                local items = Options.AutoBuySeedItem.Value
                if type(items) == "table" then
                    for item, selected in pairs(items) do
                        if selected and item and item ~= '' and autoBuySeedActive then
                           game:GetService('ReplicatedStorage'):WaitForChild('GameEvents'):WaitForChild('BuySeedStock'):FireServer(item)
                        end
                    end
                elseif items and items ~= '' and autoBuySeedActive then
                    game:GetService('ReplicatedStorage'):WaitForChild('GameEvents'):WaitForChild('BuySeedStock'):FireServer(items)
                end
                task.wait(0.2) -- Delay to prevent server lag.
            end
        end)
    else
        Library:Notify('Auto Buy Seed disabled!')
    end
end)

-- Toggle for auto buy all seeds
SeedTab:AddToggle('AutoBuyAllSeed', {
    Text = 'Auto Buy All Seeds',
    Default = false,
    Tooltip = 'Automatically buys every seed in the shop with a delay to prevent lag.'
})

Toggles.AutoBuyAllSeed:OnChanged(function(value)
    autoBuyAllSeedActive = value
    if value then
        task.spawn(function()
            Library:Notify('Auto Buy All Seeds enabled!')
            while autoBuyAllSeedActive do
                local items = Options.AutoBuySeedItem.Values or {}
                for _, item in ipairs(items) do
                    if item and item ~= '' and autoBuyAllSeedActive then
                        game:GetService('ReplicatedStorage'):WaitForChild('GameEvents'):WaitForChild('BuySeedStock'):FireServer(item)
                    end
                end
                task.wait(0.2) -- Delay to prevent server lag.
            end
        end)
    else
        Library:Notify('Auto Buy All Seeds disabled!')
    end
end)

-- =================================================================
-- GEAR TAB
-- =================================================================
local GearTab = ShopTabBox:AddTab("Gear")

-- Dropdown for gear items (auto-refresh on open)
GearTab:AddDropdown('AutoBuyGearItem', {
    Values = {},
    Default = nil,
    Multi = true,
    Text = 'Select Gear Item',
    Tooltip = 'Select an item to auto buy from the gear shop.',
    Searchable = true,
    MenuOpened = function()
        RefreshGearItems()
    end
})

-- Function to refresh gear items
function RefreshGearItems()
    local player = game:GetService('Players').LocalPlayer
    local gearShop = player:FindFirstChild('PlayerGui') and player.PlayerGui:FindFirstChild('Gear_Shop')
    if not gearShop then
        Library:Notify('Gear Shop UI not found!')
        return
    end
    local frame = gearShop:FindFirstChild('Frame')
    if not frame then
        Library:Notify('Gear Shop Frame not found!')
        return
    end
    local scrolling = frame:FindFirstChild('ScrollingFrame')
    if not scrolling then
        Library:Notify('Gear Shop ScrollingFrame not found!')
        return
    end
    local items = {}
    for _, child in ipairs(scrolling:GetChildren()) do
        if child:IsA('Frame') and child.Name ~= '' and not child.Name:match('^UI') and not child.Name:find('_Padding') and child.Name ~= 'ItemPadding' then
            table.insert(items, child.Name)
        end
    end
    if #items == 0 then
        Library:Notify('No items found in Gear Shop!')
    end
    Options.AutoBuyGearItem:SetValues(items)
    Library:Notify('Found ' .. tostring(#items) .. ' gear items!')
end

-- Auto-refresh at script startup
RefreshGearItems()

local autoBuyGearActive = false
local autoBuyAllGearActive = false

-- Toggle for auto buy
GearTab:AddToggle('AutoBuyGear', {
    Text = 'Auto Buy',
    Default = false,
    Tooltip = 'Automatically buys the selected gear item(s) with a delay to prevent lag.'
})

Toggles.AutoBuyGear:OnChanged(function(value)
    autoBuyGearActive = value
    if value then
        task.spawn(function()
            Library:Notify('Auto Buy enabled!')
            while autoBuyGearActive do
                local items = Options.AutoBuyGearItem.Value
                if type(items) == "table" then
                    for item, selected in pairs(items) do
                        if selected and item and item ~= '' and autoBuyGearActive then
                            game:GetService('ReplicatedStorage'):WaitForChild('GameEvents'):WaitForChild('BuyGearStock'):FireServer(item)
                        end
                    end
                elseif items and items ~= '' and autoBuyGearActive then
                    game:GetService('ReplicatedStorage'):WaitForChild('GameEvents'):WaitForChild('BuyGearStock'):FireServer(items)
                end
                task.wait(0.2) -- Delay to prevent server lag. Buys every 0.2 seconds.
            end
        end)
    else
        Library:Notify('Auto Buy disabled!')
    end
end)

-- Toggle for auto buy all
GearTab:AddToggle('AutoBuyAllGear', {
    Text = 'Auto Buy All',
    Default = false,
    Tooltip = 'Automatically buys every gear item in the shop with a delay to prevent lag.'
})

Toggles.AutoBuyAllGear:OnChanged(function(value)
    autoBuyAllGearActive = value
    if value then
        task.spawn(function()
            Library:Notify('Auto Buy All enabled!')
            while autoBuyAllGearActive do
                local items = Options.AutoBuyGearItem.Values or {}
                for _, item in ipairs(items) do
                    if item and item ~= '' and autoBuyAllGearActive then
                        game:GetService('ReplicatedStorage'):WaitForChild('GameEvents'):WaitForChild('BuyGearStock'):FireServer(item)
                    end
                end
                task.wait(0.2) -- Delay to prevent server lag.
            end
        end)
    else
        Library:Notify('Auto Buy All disabled!')
    end
end)


-- =================================================================
-- EGGS TAB
-- =================================================================
local EggTab = ShopTabBox:AddTab("Eggs")

-- Dropdown for egg items (auto-refresh on open)
EggTab:AddDropdown('AutoBuyPetEggItem', {
    Values = {"Common Egg"}, -- Start with a default value
    Default = nil,
    Multi = true,
    Text = 'Select Egg',
    Tooltip = 'Select an egg to auto buy. Open the Pet Shop to refresh the list.',
    Searchable = true,
    MenuOpened = function()
        RefreshPetEggItems()
    end
})

-- Function to refresh egg items from the Pet Shop UI
function RefreshPetEggItems()
    local player = game:GetService('Players').LocalPlayer
    -- The UI path is based on your screenshot/info
    local petShop = player:FindFirstChild('PlayerGui') and player.PlayerGui:FindFirstChild('PetShop_UI')
    if not petShop then
        Library:Notify('Pet Shop UI not found! Please open it to populate the list.')
        return
    end
    local frame = petShop:FindFirstChild('Frame')
    if not frame then
        Library:Notify('Pet Shop Frame not found!')
        return
    end
    local scrolling = frame:FindFirstChild('ScrollingFrame')
    if not scrolling then
        Library:Notify('Pet Shop ScrollingFrame not found!')
        return
    end
    local items = {}
    for _, child in ipairs(scrolling:GetChildren()) do
        -- This assumes the item name is the name of the frame, which is common.
        -- You may need to adjust this if the name is stored in a TextLabel inside the frame.
        if child:IsA('Frame') and child.Name ~= '' and not child.Name:match('^UI') and not child.Name:find('_Padding') and child.Name ~= 'ItemPadding' then
            table.insert(items, child.Name)
        end
    end
    if #items == 0 then
        Library:Notify('No eggs found in Pet Shop!')
    end
    Options.AutoBuyPetEggItem:SetValues(items)
    Library:Notify('Found ' .. tostring(#items) .. ' eggs!')
end

-- Attempt to refresh at script startup
RefreshPetEggItems()

local autoBuyPetEggActive = false
local autoBuyAllPetEggActive = false

-- Toggle for auto buy eggs
EggTab:AddToggle('AutoBuyPetEgg', {
    Text = 'Auto Buy Egg',
    Default = false,
    Tooltip = 'Automatically buys the selected egg(s) with a delay to prevent lag.'
})

Toggles.AutoBuyPetEgg:OnChanged(function(value)
    autoBuyPetEggActive = value
    if value then
        task.spawn(function()
            Library:Notify('Auto Buy Egg enabled!')
            while autoBuyPetEggActive do
                local items = Options.AutoBuyPetEggItem.Value
                if type(items) == "table" then
                    for item, selected in pairs(items) do
                        if selected and item and item ~= '' and autoBuyPetEggActive then
                           -- Fire the event using the item name from the dropdown
                           game:GetService('ReplicatedStorage'):WaitForChild('GameEvents'):WaitForChild('BuyPetEgg'):FireServer(item)
                        end
                    end
                elseif items and items ~= '' and autoBuyPetEggActive then
                    game:GetService('ReplicatedStorage'):WaitForChild('GameEvents'):WaitForChild('BuyPetEgg'):FireServer(items)
                end
                task.wait(0.2) -- Delay to prevent server lag.
            end
        end)
    else
        Library:Notify('Auto Buy Egg disabled!')
    end
end)

-- Toggle for auto buy all eggs
EggTab:AddToggle('AutoBuyAllPetEgg', {
    Text = 'Auto Buy All Eggs',
    Default = false,
    Tooltip = 'Automatically buys every egg in the shop with a delay to prevent lag.'
})

Toggles.AutoBuyAllPetEgg:OnChanged(function(value)
    autoBuyAllPetEggActive = value
    if value then
        task.spawn(function()
            Library:Notify('Auto Buy All Eggs enabled!')
            while autoBuyAllPetEggActive do
                local items = Options.AutoBuyPetEggItem.Values or {}
                for _, item in ipairs(items) do
                    if item and item ~= '' and autoBuyAllPetEggActive then
                        game:GetService('ReplicatedStorage'):WaitForChild('GameEvents'):WaitForChild('BuyPetEgg'):FireServer(item)
                    end
                end
                task.wait(0.2) -- Delay to prevent server lag.
            end
        end)
    else
        Library:Notify('Auto Buy All Eggs disabled!')
    end
end)


-- =================================================================
-- COSMETIC TAB
-- =================================================================
local CosmeticTab = ShopTabBox:AddTab("Cosmetic")

-- Dropdown for cosmetic items (auto-refresh on open)
CosmeticTab:AddDropdown('AutoBuyCosmeticItem', {
    Values = {},
    Default = nil,
    Multi = true,
    Text = 'Select Cosmetic',
    Tooltip = 'Select a cosmetic to auto buy. Open the Cosmetic Shop to refresh.',
    Searchable = true,
    MenuOpened = function()
        RefreshCosmeticItems()
    end
})

-- Function to refresh cosmetic items from the Cosmetic Shop UI
function RefreshCosmeticItems()
    local player = game:GetService('Players').LocalPlayer
    local cosmeticShopUI = player:FindFirstChild('PlayerGui') and player.PlayerGui:FindFirstChild('CosmeticShop_UI')
    if not cosmeticShopUI then
        Library:Notify('Cosmetic Shop UI not found! Please open it to populate the list.')
        return
    end

    -- Using FindFirstChild recursively based on the provided path
    local contentFrame = cosmeticShopUI:FindFirstChild("CosmeticShop", true)
    if contentFrame then contentFrame = contentFrame:FindFirstChild("Main", true) end
    if contentFrame then contentFrame = contentFrame:FindFirstChild("Holder", true) end
    if contentFrame then contentFrame = contentFrame:FindFirstChild("Shop", true) end
    if contentFrame then contentFrame = contentFrame:FindFirstChild("ContentFrame", true) end

    if not contentFrame then
        Library:Notify('Cosmetic Shop ContentFrame not found!')
        return
    end

    local items = {}
    local function getItemsFromSegment(segment)
        if segment then
            for _, child in ipairs(segment:GetChildren()) do
                if child:IsA('Frame') and child.Name ~= '' and not child.Name:match('^UI') and not child.Name:find('_Padding') and child.Name ~= 'ItemPadding' then
                    table.insert(items, child.Name)
                end
            end
        end
    end

    -- Scan both top and bottom segments for items
    getItemsFromSegment(contentFrame:FindFirstChild('TopSegment'))
    getItemsFromSegment(contentFrame:FindFirstChild('BottomSegment'))

    if #items == 0 then
        Library:Notify('No items found in Cosmetic Shop!')
    end

    Options.AutoBuyCosmeticItem:SetValues(items)
    Library:Notify('Found ' .. tostring(#items) .. ' cosmetic items!')
end

-- Attempt to refresh at script startup
RefreshCosmeticItems()

local autoBuyCosmeticActive = false
local autoBuyAllCosmeticsActive = false

-- Toggle for auto buy cosmetics
CosmeticTab:AddToggle('AutoBuyCosmetic', {
    Text = 'Auto Buy Cosmetic',
    Default = false,
    Tooltip = 'Automatically buys the selected cosmetic(s) with a delay to prevent lag.'
})

Toggles.AutoBuyCosmetic:OnChanged(function(value)
    autoBuyCosmeticActive = value
    if value then
        task.spawn(function()
            Library:Notify('Auto Buy Cosmetic enabled!')
            while autoBuyCosmeticActive do
                local items = Options.AutoBuyCosmeticItem.Value
                if type(items) == "table" then
                    for item, selected in pairs(items) do
                        if selected and item and item ~= '' and autoBuyCosmeticActive then
                           game:GetService('ReplicatedStorage'):WaitForChild('GameEvents'):WaitForChild('BuyCosmeticItem'):FireServer(item)
                        end
                    end
                elseif items and items ~= '' and autoBuyCosmeticActive then
                    game:GetService('ReplicatedStorage'):WaitForChild('GameEvents'):WaitForChild('BuyCosmeticItem'):FireServer(items)
                end
                task.wait(0.2) -- Delay to prevent server lag.
            end
        end)
    else
        Library:Notify('Auto Buy Cosmetic disabled!')
    end
end)

-- Toggle for auto buy all cosmetics
CosmeticTab:AddToggle('AutoBuyAllCosmetics', {
    Text = 'Auto Buy All Cosmetics',
    Default = false,
    Tooltip = 'Automatically buys every cosmetic in the shop with a delay to prevent lag.'
})

Toggles.AutoBuyAllCosmetics:OnChanged(function(value)
    autoBuyAllCosmeticsActive = value
    if value then
        task.spawn(function()
            Library:Notify('Auto Buy All Cosmetics enabled!')
            while autoBuyAllCosmeticsActive do
                local items = Options.AutoBuyAllCosmeticItem.Values or {}
                for _, item in ipairs(items) do
                    if item and item ~= '' and autoBuyAllCosmeticsActive then
                        game:GetService('ReplicatedStorage'):WaitForChild('GameEvents'):WaitForChild('BuyCosmeticItem'):FireServer(item)
                    end
                end
                task.wait(0.2) -- Delay to prevent server lag.
            end
        end)
    else
        Library:Notify('Auto Buy All Cosmetics disabled!')
    end
end)


-- =================================================================
-- UI SETTINGS
-- =================================================================
local MenuGroup = SettingsTab:AddLeftGroupbox('Menu', 'menu')

MenuGroup:AddToggle("KeybindMenuOpen", { 
    Default = Library.KeybindFrame.Visible, 
    Text = "Open Keybind Menu", 
    Callback = function(value) 
        Library.KeybindFrame.Visible = value 
    end
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor", 
    Default = true, 
    Callback = function(Value) 
        Library.ShowCustomCursor = Value 
    end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { 
    Default = "RightShift", 
    NoUI = true, 
    Text = "Menu keybind" 
})

MenuGroup:AddButton("Unload", function() 
    Library:Unload() 
end)

Library.ToggleKeybind = Options.MenuKeybind

-- Hand the library over to our managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

-- Set up folders for configs and themes
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')
SaveManager:SetSubFolder('specific-place')

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(SettingsTab)

-- Builds our theme menu (with plenty of built in themes) on the left side
ThemeManager:ApplyToTab(SettingsTab)

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
SaveManager:LoadAutoloadConfig()

-- Destroy loading screen as UI is now ready
if loadingScreen then
    loadingScreen:Destroy()
end

-- Set watermark
Library:SetWatermarkVisibility(true)

-- Example of dynamically-updating watermark with common traits (fps and ping)
local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1;

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;

    -- Move watermark to very top center
    Library:SetWatermark(('PH99| %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ), nil, 'TopCenter')
end);

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    print('Unloaded!')
    Library.Unloaded = true
end)

-- Auto-refresh pet UUIDs when script starts
task.spawn(function()
    task.wait(2) -- Wait a bit for the UI to load
    RefreshPetUUIDs()
    RefreshBackpackSeeds() -- Refresh backpack seeds on startup
    RefreshFriendsList() -- Refresh friends list on startup
    RefreshPlayerListForSender()
    
    -- Check if ESP was enabled in saved config and start it
    task.wait(1) -- Wait a bit more for config to load
    if Toggles.PetCDESP and Toggles.PetCDESP.Value then
        StartPetCDESP()
    end
end)

-- =================================================================
-- Teleport UI Modifications (Added by Gemini)
-- This section handles making existing buttons visible and adding a new 'Event' button
-- to the Teleport_UI, assuming it's a separate UI element in PlayerGui.
-- =================================================================

-- Function to modify the Teleport_UI
local function modifyTeleportUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local teleportUI = playerGui:WaitForChild("Teleport_UI")
    local frame = teleportUI:WaitForChild("Frame")

    -- 1. Make "Pets" and "Gear" buttons visible
    local petsButton = frame:FindFirstChild("Pets")
    if petsButton and petsButton:IsA("ImageButton") then
        petsButton.Visible = true
       -- print("Pets button made visible.")
    else
        warn("Pets button not found or not an ImageButton in Teleport_UI.Frame")
    end

    local gearButton = frame:FindFirstChild("Gear")
    if gearButton and gearButton:IsA("ImageButton") then
        gearButton.Visible = true
      --  print("Gear button made visible.")
    else
        warn("Gear button not found or not an ImageButton in Teleport_UI.Frame")
    end

    -- 2. Create a new "Event" button
    local eventButton = Instance.new("ImageButton")
    eventButton.Name = "Event"
    eventButton.Size = UDim2.new(0.259808183, 0, 0.790713012, 0) -- Updated size as requested.

    -- A safer approach for UI positioning is to check for existing UIListLayout or UIGridLayout.
    local uiListLayout = frame:FindFirstChildOfClass("UIListLayout")
    local uiGridLayout = frame:FindFirstChildOfClass("UIGridLayout")

    if uiListLayout or uiGridLayout then
        -- If a layout exists, just set a reasonable size and let the layout handle position.
        -- The position set here will likely be overridden by the layout.
        eventButton.Position = UDim2.new(0.311, 0, 0.600, 0) -- Placeholder, layout will arrange
        -- print("UI Layout found, position will be handled by layout.")
    else
        -- Manual positioning if no layout is found.
        -- This is a rough estimate to place it near the Garden button.
        -- You might need to fine-tune these values based on your UI's exact structure.
        eventButton.Position = UDim2.new(0.311, 0, 0.600, 0) -- Example: slightly above Garden
        print("No UI Layout found, manually positioning button.")
    end

    eventButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128) -- A visually pleasing purple color.
    eventButton.BackgroundTransparency = 0
    eventButton.BorderSizePixel = 0
    eventButton.AutoButtonColor = true
    eventButton.Parent = frame

    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = eventButton

    -- Add text label for the button
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = "Event"
    textLabel.Parent = eventButton

    -- Add functionality to the "Event" button
    eventButton.MouseButton1Click:Connect(function()
        -- The coordinates -104, 2, 5 refer to a 3D world position within the current game.
        -- To move the player within the same game, you modify the character's CFrame.
        -- If you intended to teleport to a *different* Roblox game, you would need a PlaceId
        -- and use TeleportService:Teleport(placeId, LocalPlayer).

        local targetPosition = Vector3.new(-104, 2, 5)
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
            --Library:Notify("Teleporting to Event location...", 0.5)
        else
            warn("Character or HumanoidRootPart not found for teleportation.")
            Library:Notify("Event teleport failed: Character not ready!")
        end
    end)

    print("Event button created and configured.")
end

-- Call the function to modify the UI after the game has loaded sufficiently
-- We use task.spawn and task.wait to ensure the UI has time to load, similar to other
-- startup tasks in this script.
task.spawn(function()
    task.wait(1) -- Give some time for the Teleport_UI to load after the game starts
    pcall(modifyTeleportUI)
end)
