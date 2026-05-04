-- Xvory Stand-Still Desync
-- Others see you STUCK at one spot. You walk freely on your screen.
-- Server never gets your real position.

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
local realCF = nil

local function Cleanup()
    for _, c in ipairs(conns) do
        if c.Connected then c:Disconnect() end
    end
    table.clear(conns)
    frozenCF = nil
    realCF = nil
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

    -- Stepped = BEFORE physics (server reads position here)
    -- We put character at frozen spot so server thinks we're there
    table.insert(conns, RunService.Stepped:Connect(function()
        if not Config.Enabled then
            frozenCF = nil
            realCF = nil
            return
        end

        local hrp = GetHRP()
        local hum = GetHum()
        if not hrp or not hum or hum.Health <= 0 then
            frozenCF = nil
            realCF = nil
            return
        end

        -- Save where we really are right now
        realCF = hrp.CFrame

        -- Lock the frozen position once
        if not frozenCF then
            frozenCF = hrp.CFrame
        end

        -- Move to frozen spot for the physics/network step
        hrp.CFrame = frozenCF
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end))

    -- Heartbeat = AFTER physics (client renders here)
    -- We restore our real position so we see smooth movement
    table.insert(conns, RunService.Heartbeat:Connect(function()
        if not Config.Enabled or not realCF then return end

        local hrp = GetHRP()
        local hum = GetHum()
        if not hrp or not hum or hum.Health <= 0 then return end

        -- Figure out how much the humanoid tried to move us
        -- During physics, character moved FROM frozenCF by some delta
        -- We apply that same delta to our real position
        if frozenCF then
            local movedCF = hrp.CFrame
            local delta = frozenCF:ToObjectSpace(movedCF)
            realCF = realCF * delta
        end

        -- Snap to real position
        hrp.CFrame = realCF
    end))

    -- On respawn, reset frozen position
    table.insert(conns, LocalPlayer.CharacterAdded:Connect(function()
        frozenCF = nil
        realCF = nil
    end))

    -- Toggle key
    if Config.ToggleKey then
        table.insert(conns, UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Config.ToggleKey then
                Config.Enabled = not Config.Enabled
                if not Config.Enabled then
                    frozenCF = nil
                    realCF = nil
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
            realCF = nil
        end
    end,
    Unload = Cleanup
}

Start()
print("[Xvory] Stand-Still Desync Loaded | Press K to toggle")
