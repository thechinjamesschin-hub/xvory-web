-- Xvory True Network Desync
-- Flawless implementation: No camera stutter, no yielding, full smooth movement.
-- Freezes your server-side position and velocity so you take no damage where you walk.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Config = {
    Enabled = false,
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
local realVel = nil
local realRotVel = nil
local hrp = nil

local function Cleanup()
    for _, c in ipairs(conns) do
        if c.Connected then c:Disconnect() end
    end
    table.clear(conns)
    
    pcall(function()
        RunService:UnbindFromRenderStep("XvoryDesyncRestore")
    end)

    if hrp and realCF then
        hrp.CFrame = realCF
    end

    frozenCF = nil
    hrp = nil
end

local function Start()
    Cleanup()

    -- 1. Heartbeat fires AFTER physics, right before Network Replication.
    -- We trick the server by sending the frozen CFrame and zero velocity.
    table.insert(conns, RunService.Heartbeat:Connect(function()
        if not Config.Enabled then 
            frozenCF = nil 
            return 
        end
        
        local char = LocalPlayer.Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if not frozenCF then 
            frozenCF = hrp.CFrame 
        end

        -- Save our actual local physics state
        realCF = hrp.CFrame
        realVel = hrp.AssemblyLinearVelocity
        realRotVel = hrp.AssemblyAngularVelocity

        -- Trick the server
        hrp.CFrame = frozenCF
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end))

    -- 2. Bind to RenderStep BEFORE the Camera updates.
    -- This restores our real position so our local screen and camera stay 100% smooth.
    -- Because we don't use Wait(), the game threads never stutter!
    RunService:BindToRenderStep("XvoryDesyncRestore", Enum.RenderPriority.Camera.Value - 10, function()
        if Config.Enabled and hrp and realCF then
            hrp.CFrame = realCF
            hrp.AssemblyLinearVelocity = realVel
            hrp.AssemblyAngularVelocity = realRotVel
        end
    end)

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
                    if hrp and realCF then hrp.CFrame = realCF end
                    frozenCF = nil
                end
                print("[Xvory] True Network Desync " .. (Config.Enabled and "ON" or "OFF"))
            end
        end))
    end
end

getgenv().XvoryFakeLag = {
    Config = Config,
    Toggle = function(state)
        Config.Enabled = state
        if not state then
            if hrp and realCF then hrp.CFrame = realCF end
            frozenCF = nil
        end
    end,
    Unload = Cleanup
}

Start()
print("[Xvory] True Network Desync Loaded | Press K to toggle")
