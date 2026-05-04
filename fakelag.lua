-- Xvory Ghost Mode (Clone Desync)
-- Your real character stays frozen at the start position (taking no damage where you walk).
-- You control a local clone that can walk around freely.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

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

local clone = nil
local realCharacter = nil
local conns = {}

local function Cleanup()
    for _, c in ipairs(conns) do
        if c.Connected then c:Disconnect() end
    end
    table.clear(conns)
    
    if clone then
        clone:Destroy()
        clone = nil
    end

    if realCharacter and realCharacter.Parent then
        -- Restore camera
        Camera.CameraSubject = realCharacter:FindFirstChildOfClass("Humanoid")
        
        -- Un-anchor real character
        local hrp = realCharacter:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = false
        end
        
        -- Make real character visible again
        for _, part in pairs(realCharacter:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.Transparency = part:GetAttribute("RealTransparency") or part.Transparency
            end
        end
    end
end

local function EnableGhostMode()
    realCharacter = LocalPlayer.Character
    if not realCharacter then return end
    
    local hrp = realCharacter:FindFirstChild("HumanoidRootPart")
    local hum = realCharacter:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- 1. Anchor real character at current position
    hrp.Anchored = true
    hrp.Velocity = Vector3.new(0, 0, 0)

    -- 2. Create the clone
    realCharacter.Archivable = true
    clone = realCharacter:Clone()
    clone.Name = "Xvory_Ghost"
    clone.Parent = Workspace
    
    -- 3. Make real character invisible so we only see clone
    for _, part in pairs(realCharacter:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            if not part:GetAttribute("RealTransparency") then
                part:SetAttribute("RealTransparency", part.Transparency)
            end
            part.Transparency = 1
        end
    end

    -- 4. Set up clone physics
    for _, part in pairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Prevent clone from colliding with real character
            part.CollisionGroup = "Default"
        end
    end

    local cloneHum = clone:FindFirstChildOfClass("Humanoid")
    
    -- 5. Give control to clone
    LocalPlayer.Character = clone
    Camera.CameraSubject = cloneHum
    
    print("[Xvory] Ghost Mode ON")
end

local function DisableGhostMode()
    if clone then
        -- Teleport real character to where clone was?
        -- No, user wants real character to stay where it started so they don't take damage where they walked
        clone:Destroy()
        clone = nil
    end

    if realCharacter and realCharacter.Parent then
        LocalPlayer.Character = realCharacter
        Camera.CameraSubject = realCharacter:FindFirstChildOfClass("Humanoid")
        
        local hrp = realCharacter:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false end
        
        -- Restore visibility
        for _, part in pairs(realCharacter:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                local realTrans = part:GetAttribute("RealTransparency")
                if realTrans then
                    part.Transparency = realTrans
                end
            end
        end
    end
    print("[Xvory] Ghost Mode OFF")
end

local function Start()
    Cleanup()

    if Config.ToggleKey then
        table.insert(conns, UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Config.ToggleKey then
                Config.Enabled = not Config.Enabled
                if Config.Enabled then
                    EnableGhostMode()
                else
                    DisableGhostMode()
                end
            end
        end))
    end
end

getgenv().XvoryFakeLag = {
    Config = Config,
    Toggle = function(state)
        if state ~= Config.Enabled then
            Config.Enabled = state
            if state then EnableGhostMode() else DisableGhostMode() end
        end
    end,
    Unload = Cleanup
}

Start()
print("[Xvory] Ghost Mode (Clone Desync) Loaded | Press K to toggle")
