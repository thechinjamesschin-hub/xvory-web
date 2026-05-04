-- Xvory Stand Still Desync (Network Freeze)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local DesyncConfig = {
    Enabled = true -- Simple toggle as requested
}

-- If connected to shared dashboard state
if shared.xvory and shared.xvory["Desync"] then
    DesyncConfig.Enabled = shared.xvory["Desync"].Enabled
end

local realCFrame = nil
local frozenCFrame = nil
local connections = {}

local function Cleanup()
    for _, conn in ipairs(connections) do
        if conn.Connected then conn:Disconnect() end
    end
    table.clear(connections)
    realCFrame = nil
    frozenCFrame = nil
end

-- Ensure old instances are cleaned up if re-executed
if getgenv().XvoryDesync then
    pcall(function() getgenv().XvoryDesync.Unload() end)
end

local function GetRoot()
    if LocalPlayer.Character then
        return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function InitDesync()
    Cleanup()
    
    -- 1. On Stepped (Runs BEFORE physics simulation)
    -- We switch our position to the frozen position so the server physics engine sees us there.
    table.insert(connections, RunService.Stepped:Connect(function()
        if not DesyncConfig.Enabled then 
            frozenCFrame = nil
            return 
        end
        
        local hrp = GetRoot()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        
        if hrp and hum and hum.Health > 0 then
            -- Save where we actually are locally
            realCFrame = hrp.CFrame
            
            -- If we haven't frozen a position yet, freeze where we are right now
            if not frozenCFrame then
                frozenCFrame = hrp.CFrame
            end
            
            -- Temporarily move to the frozen position for the physics step
            hrp.CFrame = frozenCFrame
        end
    end))
    
    -- 2. On Heartbeat (Runs AFTER physics simulation)
    -- We switch back to our real position so our local camera and rendering is perfectly smooth.
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not DesyncConfig.Enabled then return end
        
        local hrp = GetRoot()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        
        if hrp and realCFrame and hum and hum.Health > 0 then
            -- Restore our local movement so we don't feel any lag
            hrp.CFrame = realCFrame
            
            -- Optional: Apply extreme velocity to break server prediction/extrapolation
            -- hrp.AssemblyLinearVelocity = Vector3.new(1e5, 1e5, 1e5) 
        end
    end))
    
    table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
        frozenCFrame = nil
    end))
end

-- Expose global control
getgenv().XvoryDesync = {
    Toggle = function(state)
        DesyncConfig.Enabled = state
        if not state then
            frozenCFrame = nil
        end
    end,
    Unload = Cleanup
}

InitDesync()
print("[Xvory] Stand-Still Desync Module Loaded!")
