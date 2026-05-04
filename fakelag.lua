-- Xvory Velocity Desync
-- Server sees you STUCK at one spot because we zero out velocity and lock CFrame.
-- Client runs perfectly smooth and retains animations.

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

        if not frozenCF then
            frozenCF = hrp.CFrame
        end

        -- Save real physics state
        local realCF = hrp.CFrame
        local realVel = hrp.AssemblyLinearVelocity
        local realRotVel = hrp.AssemblyAngularVelocity

        -- Lock to frozen position AND zero out velocity for the network step
        -- If velocity isn't zero, the server will try to predict where you are walking!
        hrp.CFrame = frozenCF
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        -- Yield until just before rendering
        RunService.RenderStepped:Wait()

        -- Restore real physics state so you walk normally
        hrp.CFrame = realCF
        hrp.AssemblyLinearVelocity = realVel
        hrp.AssemblyAngularVelocity = realRotVel
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
                print("[Xvory] Velocity Desync " .. (Config.Enabled and "ON" or "OFF"))
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
print("[Xvory] Velocity Desync Loaded | Press K to toggle")
