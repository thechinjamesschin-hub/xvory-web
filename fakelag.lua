-- Xvory Stand-Still Desync
-- Server sees you STUCK at one spot. You walk smoothly on your screen.
-- Uses Heartbeat + RenderStepped technique to fool network replication while keeping local physics intact.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Config = {
    Enabled = true,
    ToggleKey = Enum.KeyCode.K
}

if shared.xvory and shared.xvory["Desync"] then
    local c = shared.xvory["Desync"]
    if c.Enabled ~= nil then Config.Enabled = c.Enabled end
end

if getgenv().XvoryFakeLag then
    pcall(function() getgenv().XvoryFakeLag.Unload() end)
end

local conns = {}
local frozenCF = nil

local function Cleanup()
    for _, c in ipairs(conns) do
        if c.Connected then c:Disconnect() end
    end
    table.clear(conns)
    frozenCF = nil
end

local function GetHRP()
    local ch = LocalPlayer.Character
    return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local ch = LocalPlayer.Character
    return ch and ch:FindFirstChildOfClass("Humanoid")
end

local function Start()
    Cleanup()

    -- Heartbeat runs AFTER physics, right when network replication happens.
    table.insert(conns, RunService.Heartbeat:Connect(function()
        if not Config.Enabled then
            frozenCF = nil
            return
        end

        local hrp = GetHRP()
        local hum = GetHum()
        if not hrp or not hum or hum.Health <= 0 then
            frozenCF = nil
            return
        end

        -- Initialize the frozen spot
        if not frozenCF then
            frozenCF = hrp.CFrame
        end

        -- Save our REAL position that physics just calculated
        local realCF = hrp.CFrame

        -- Teleport to the frozen spot for the network step
        hrp.CFrame = frozenCF
        
        -- Yield the thread until RenderStepped (which runs before the frame is drawn on your screen)
        RunService.RenderStepped:Wait()

        -- Restore our real position so our camera and character render smoothly
        hrp.CFrame = realCF
    end))

    -- Reset on respawn
    table.insert(conns, LocalPlayer.CharacterAdded:Connect(function()
        frozenCF = nil
    end))

    -- Toggle key
    if Config.ToggleKey then
        table.insert(conns, UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Config.ToggleKey then
                Config.Enabled = not Config.Enabled
                if not Config.Enabled then
                    frozenCF = nil
                end
                print("[Xvory] Desync " .. (Config.Enabled and "ON" or "OFF"))
            end
        end))
    end
end

getgenv().XvoryFakeLag = {
    Config = Config,
    Toggle = function(state)
        Config.Enabled = state
        if not state then
            frozenCF = nil
        end
    end,
    Unload = Cleanup
}

Start()
print("[Xvory] Stand-Still Desync Loaded | Press K to toggle")
