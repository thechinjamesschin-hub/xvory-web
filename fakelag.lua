-- Xvory Ultimate Velocity Desync (No Body Detachment)
-- Uses NaN/Infinity velocity replication breaking instead of CFrame teleporting.
-- This guarantees your visual body stays perfectly with you, and your camera never bugs out.

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
local realVel = nil
local realRotVel = nil
local hrp = nil

local function Cleanup()
    for _, c in ipairs(conns) do
        if c.Connected then c:Disconnect() end
    end
    table.clear(conns)
    
    if hrp and realVel then
        hrp.AssemblyLinearVelocity = realVel
        hrp.AssemblyAngularVelocity = realRotVel
    end
    hrp = nil
end

local function Start()
    Cleanup()

    -- 1. Heartbeat: Right before the client sends its position to the server.
    -- We set our velocity to Infinity. The Roblox server's anti-sanity checks
    -- will completely reject our network packets, freezing our server-side hitbox
    -- at the exact spot we enabled it.
    table.insert(conns, RunService.Heartbeat:Connect(function()
        if not Config.Enabled then return end
        
        local char = LocalPlayer.Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Save our actual local physics velocity
        realVel = hrp.AssemblyLinearVelocity
        realRotVel = hrp.AssemblyAngularVelocity

        -- Send astronomical velocity to break server replication
        hrp.AssemblyLinearVelocity = Vector3.new(9e9, 9e9, 9e9)
        hrp.AssemblyAngularVelocity = Vector3.new(9e9, 9e9, 9e9)
    end))

    -- 2. Stepped: Right before local physics are simulated.
    -- We restore our real velocity so our local character walks perfectly normally.
    -- Because we NEVER touch CFrame, your visual body will NEVER detach from you!
    table.insert(conns, RunService.Stepped:Connect(function()
        if not Config.Enabled then return end
        
        if hrp and realVel then
            hrp.AssemblyLinearVelocity = realVel
            hrp.AssemblyAngularVelocity = realRotVel
        end
    end))

    -- Toggle key
    if Config.ToggleKey then
        table.insert(conns, UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Config.ToggleKey then
                Config.Enabled = not Config.Enabled
                if not Config.Enabled then
                    if hrp and realVel then 
                        hrp.AssemblyLinearVelocity = realVel 
                        hrp.AssemblyAngularVelocity = realRotVel
                    end
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
            if hrp and realVel then 
                hrp.AssemblyLinearVelocity = realVel 
                hrp.AssemblyAngularVelocity = realRotVel
            end
        end
    end,
    Unload = Cleanup
}

Start()
print("[Xvory] Velocity Desync Loaded | Press K to toggle")
