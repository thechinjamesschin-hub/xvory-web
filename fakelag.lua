--[[
    Xvory Fake Lag Module
    Makes other players see you as lagging/teleporting
    while your local experience remains perfectly smooth.
    
    Keybind: V (toggle on/off)
    
    Modes:
      "Spike"    - periodic hard teleport spikes (most aggressive)
      "Stutter"  - constant micro-stutters (looks like bad wifi)
      "Desync"   - position desync with rubber-banding
]]

if not LPH_NO_VIRTUALIZE then LPH_NO_VIRTUALIZE = function(f) return f end end
if not LPH_OBFUSCATED then LPH_OBFUSCATED = false end
if not LPH_ENCSTR then LPH_ENCSTR = function(s) return s end end

-- ═══════════════════════════════════════════════
--  CONFIGURATION
-- ═══════════════════════════════════════════════

local FakeLagConfig = {
    Enabled = false,
    Keybind = Enum.KeyCode.V,
    Mode = "Spike",         -- "Spike" | "Stutter" | "Desync"
    
    -- Spike mode settings
    Spike = {
        Interval = 0.35,     -- seconds between spikes (lower = more frequent)
        HoldTime = 0.18,     -- how long to hold the fake position
        Magnitude = 8,       -- how far the fake offset goes (studs)
    },
    
    -- Stutter mode settings
    Stutter = {
        Frequency = 0.06,    -- how often to micro-freeze (seconds)
        Duration = 0.04,     -- freeze duration per stutter tick
        Jitter = 3.5,        -- position jitter magnitude
    },
    
    -- Desync mode settings
    Desync = {
        Offset = Vector3.new(6, 0, 6),  -- constant offset from real position
        SnapBack = 0.5,                   -- seconds between snap-backs
        Lerp = 0.15,                      -- smoothing factor for desync drift
    },
    
    -- Anti-detection
    AntiDetection = {
        RandomizeTimings = true,  -- adds randomness to intervals
        VaryMagnitude = true,     -- slightly randomizes offset distances
        MaxVariance = 0.12,       -- ±12% timing variance
    }
}

-- ═══════════════════════════════════════════════
--  SERVICES & REFERENCES
-- ═══════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════
--  CLEANUP PREVIOUS INSTANCE
-- ═══════════════════════════════════════════════

if getgenv().XvoryFakeLagCleanup then
    pcall(getgenv().XvoryFakeLagCleanup)
end

local connections = {}
local running = true

local function RegisterConnection(conn)
    table.insert(connections, conn)
    return conn
end

getgenv().XvoryFakeLagCleanup = function()
    running = false
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
    
    -- Restore network ownership
    pcall(function()
        local character = LocalPlayer.Character
        if character then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                root.Velocity = Vector3.new(0, 0, 0)
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════
--  UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════

local function GetVariance()
    if not FakeLagConfig.AntiDetection.RandomizeTimings then
        return 1
    end
    local v = FakeLagConfig.AntiDetection.MaxVariance
    return 1 + (math.random() * 2 - 1) * v
end

local function GetMagnitudeMultiplier()
    if not FakeLagConfig.AntiDetection.VaryMagnitude then
        return 1
    end
    return 0.7 + math.random() * 0.6  -- 0.7x to 1.3x
end

local function RandomDirection()
    local angle = math.random() * math.pi * 2
    return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

local function GetRoot()
    local character = LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local character = LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

local function IsAlive()
    local hum = GetHumanoid()
    return hum and hum.Health > 0
end

-- ═══════════════════════════════════════════════
--  CORE FAKE LAG ENGINES
-- ═══════════════════════════════════════════════

-- Cache for storing real position while faking
local realCFrame = nil
local isFaking = false

--[[ 
    SPIKE MODE
    Periodically teleports the replicated CFrame to a random offset,
    holds it briefly, then snaps back. Other players see hard teleport spikes.
]]
local function RunSpikeMode()
    local cfg = FakeLagConfig.Spike
    
    while running and FakeLagConfig.Enabled and FakeLagConfig.Mode == "Spike" do
        local root = GetRoot()
        if root and IsAlive() then
            -- Store real position
            realCFrame = root.CFrame
            
            -- Calculate fake offset
            local dir = RandomDirection()
            local mag = cfg.Magnitude * GetMagnitudeMultiplier()
            local fakeOffset = dir * mag
            
            -- Apply velocity spike to desync replication
            isFaking = true
            root.Velocity = fakeOffset * (1 / cfg.HoldTime) * 0.5
            root.AssemblyLinearVelocity = Vector3.new(
                fakeOffset.X * 45 * GetMagnitudeMultiplier(),
                0,
                fakeOffset.Z * 45 * GetMagnitudeMultiplier()
            )
            
            -- Hold the fake state
            local holdTime = cfg.HoldTime * GetVariance()
            task.wait(holdTime)
            
            -- Snap back to real position
            if root and root.Parent then
                root.CFrame = realCFrame
                root.Velocity = Vector3.new(0, 0, 0)
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
            isFaking = false
        end
        
        local interval = cfg.Interval * GetVariance()
        task.wait(interval)
    end
end

--[[
    STUTTER MODE
    Rapid micro-freezes with tiny position jitters.
    Looks like constant packet loss / bad connection.
]]
local function RunStutterMode()
    local cfg = FakeLagConfig.Stutter
    local accum = 0
    local frozenCFrame = nil
    local freezing = false
    local freezeTimer = 0
    
    while running and FakeLagConfig.Enabled and FakeLagConfig.Mode == "Stutter" do
        local root = GetRoot()
        if root and IsAlive() then
            -- Start a micro-freeze
            frozenCFrame = root.CFrame
            freezing = true
            
            -- Apply jitter velocity
            local jitterDir = RandomDirection()
            local jitterMag = cfg.Jitter * GetMagnitudeMultiplier()
            
            root.AssemblyLinearVelocity = jitterDir * jitterMag * 60
            
            -- Hold the freeze
            local dur = cfg.Duration * GetVariance()
            task.wait(dur)
            
            -- Restore
            if root and root.Parent and frozenCFrame then
                root.CFrame = frozenCFrame
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.Velocity = Vector3.new(0, 0, 0)
            end
            freezing = false
        end
        
        local freq = cfg.Frequency * GetVariance()
        task.wait(freq)
    end
end

--[[
    DESYNC MODE
    Maintains a constant position offset from the real position.
    The server/others see you at a shifted location. Periodically
    rubber-bands back creating a "ghost" effect.
]]
local function RunDesyncMode()
    local cfg = FakeLagConfig.Desync
    local lastSnap = tick()
    local desyncActive = true
    
    while running and FakeLagConfig.Enabled and FakeLagConfig.Mode == "Desync" do
        local root = GetRoot()
        if root and IsAlive() then
            local now = tick()
            
            if desyncActive then
                -- Apply offset velocity to drift the replicated position
                local offset = cfg.Offset * GetMagnitudeMultiplier()
                local driftVelocity = Vector3.new(
                    offset.X * 30,
                    0,
                    offset.Z * 30
                )
                
                root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + driftVelocity * cfg.Lerp
                
                -- Check if it's time to snap back
                if now - lastSnap >= cfg.SnapBack * GetVariance() then
                    -- Rubber-band: kill all drift velocity
                    root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                    root.Velocity = Vector3.new(0, root.Velocity.Y, 0)
                    lastSnap = now
                    desyncActive = false
                    task.wait(0.08)
                    desyncActive = true
                end
            end
        end
        
        task.wait(0.016) 
    end
end

local function StartLocalCorrection()
    local lastGoodCFrame = nil
    local correctionActive = false
    
    RegisterConnection(RunService.RenderStepped:Connect(function(dt)
        if not FakeLagConfig.Enabled then return end
        if not running then return end
        
        local root = GetRoot()
        if not root or not IsAlive() then return end
        
        -- During spike mode, force our local render to the real position
        if FakeLagConfig.Mode == "Spike" and isFaking and realCFrame then
            -- We already handle this in the spike loop
            return
        end
        
        -- For stutter/desync, do subtle local smoothing
        if FakeLagConfig.Mode ~= "Spike" then
            local hum = GetHumanoid()
            if hum and hum.MoveDirection.Magnitude > 0 then
                -- Player is actively moving; let the local physics handle it
                lastGoodCFrame = root.CFrame
            end
        end
    end))
end

-- ═══════════════════════════════════════════════
--  MODE DISPATCHER
-- ═══════════════════════════════════════════════

local activeModeThread = nil

local function StopActiveMode()
    if activeModeThread then
        pcall(function()
            task.cancel(activeModeThread)
        end)
        activeModeThread = nil
    end
    
    -- Clean up velocities
    local root = GetRoot()
    if root then
        pcall(function()
            root.Velocity = Vector3.new(0, 0, 0)
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
    end
    isFaking = false
    realCFrame = nil
end

local function StartActiveMode()
    StopActiveMode()
    
    if not FakeLagConfig.Enabled then return end
    
    local mode = FakeLagConfig.Mode
    
    if mode == "Spike" then
        activeModeThread = task.spawn(RunSpikeMode)
    elseif mode == "Stutter" then
        activeModeThread = task.spawn(RunStutterMode)
    elseif mode == "Desync" then
        activeModeThread = task.spawn(RunDesyncMode)
    end
end

-- ═══════════════════════════════════════════════
--  TOGGLE & KEYBIND
-- ═══════════════════════════════════════════════

local function Toggle()
    FakeLagConfig.Enabled = not FakeLagConfig.Enabled
    
    if FakeLagConfig.Enabled then
        StartActiveMode()
        
        -- Visual feedback
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Xvory",
                Text = "Fake Lag ON [" .. FakeLagConfig.Mode .. "]",
                Duration = 1.5
            })
        end)
    else
        StopActiveMode()
        
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Xvory",
                Text = "Fake Lag OFF",
                Duration = 1.5
            })
        end)
    end
end

-- Keybind listener
RegisterConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == FakeLagConfig.Keybind then
        Toggle()
    end
end))

-- ═══════════════════════════════════════════════
--  CHARACTER RESPAWN HANDLER
-- ═══════════════════════════════════════════════

RegisterConnection(LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    if FakeLagConfig.Enabled then
        -- Restart the active mode for the new character
        StartActiveMode()
    end
end))

-- ═══════════════════════════════════════════════
--  ANTI-AFK (keeps the fake lag running)
-- ═══════════════════════════════════════════════

RegisterConnection(LocalPlayer.Idled:Connect(function()
    pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.5)
        vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end))

-- ═══════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════

StartLocalCorrection()

-- Expose config to shared for web dashboard integration
if shared.xvory then
    shared.xvory["Fake Lag"] = FakeLagConfig
end

-- Store global reference for external control
getgenv().XvoryFakeLag = FakeLagConfig
getgenv().XvoryFakeLagToggle = Toggle

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Xvory",
        Text = "Fake Lag loaded. Press V to toggle.",
        Duration = 3
    })
end)
