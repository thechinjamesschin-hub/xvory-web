shared.xvory = {
    ["Settings"] = {
        ["Method"] = "Web",
        ["General"] = {
            ["Keybind"] = {
                ["Target"] = "Q",
                ["Camlock"] = "Q",
                ["2Tap"] = "Q",
                ["Triggerbot"] = "Q",
                ["Inventory Sorter"] = "N",
                ["ESP"] = "B"
            }
        }
    },
    ["Silent"] = {
        ["Enabled"] = true,
        ["Mode"] = "Target",
        ["Max Dist"] = 250,
        ["Hit Part"] = "Closest Point",
        ["Closest Point"] = {
            ["Mode"] = "Advanced",
            ["Scale"] = 0.2
        },
        ["Prediction"] = {
            ["Enabled"] = true,
            ["Mode"] = "Regular",
            ["x"] = 0,
            ["y"] = 0,
            ["z"] = 0
        },
        ["Client Mode"] = {
            ["Enabled"] = false,
            ["weapons"] = { "[Revolver]", "[Silencer]", "[Glock]" }
        },
        ["Fov"] = {
            ["Enabled"] = true,
            ["Visible"] = false,
            ["Circle"] = 45,
            ["Hit Scan"] = 45,
            ["Weapon Configuration"] = {
                ["Enabled"] = true,
                ["Shotguns"] = { circle = 60 },
                ["Pistol"] = { circle = 50 },
                ["Others"] = { circle = 45 }
            }
        },
        ["Conditions"] = {
            ["Visible"] = false,
            ["Grabbed"] = true,
            ["knocked"] = true,
            ["Self Knocked"] = false,
            ["Chat"] = true
        }
    },
    ["Camlock"] = {
        ["Enabled"] = false,
        ["HitPart"] = "Head",
        ["Closest Point"] = {
            ["Mode"] = "Advanced",
            ["Scale"] = 0.15
        },
        ["Sticky"] = 0.55,
        ["EasingMode"] = "Circular",
        ["EasingDirection"] = "Out",
        ["Pred"] = {
            ["Enabled"] = true,
            ["X"] = 0.06,
            ["Y"] = 0.04,
            ["Z"] = 0.06
        },
        ["Fov"] = {
            ["Enabled"] = true,
            ["Visible"] = false,
            ["Size"] = 90
        },
        ["Conditions"] = {
            ["Visible"] = true,
            ["Grabbed"] = true,
            ["knocked"] = true,
            ["Self Knocked"] = false,
            ["Chat"] = true
        }
    },
    ["Triggerbot"] = {
        ["Enabled"] = true,
        ["Mode"] = "Target",
        ["Max Dist"] = 200,
        ["Radius"] = 12,
        ["Cooldown"] = 0.12,
        ["Works"] = {
            ["Mode"] = "Keybind",
            ["Type"] = "Hold"
        },
        ["Prediction"] = {
            ["Enabled"] = false,
            ["Value"] = 0
        },
        ["Fov"] = {
            ["Visible"] = false,
            ["X"] = 3.5,
            ["Y"] = 6,
            ["Z"] = 3.5,
            ["Scale"] = 1.2
        },
        ["Conditions"] = {
            ["Visible"] = false,
            ["Grabbed"] = true,
            ["knocked"] = true,
            ["Self Knocked"] = false,
            ["Chat"] = true
        }
    },
    ["Weapon"] = {
        ["2Tap"] = {
            ["Enabled"] = false,
            ["Weapons"] = { "[Revolver]", "[Silencer]" }
        },
        ["Bullet Spread"] = {
            ["Enabled"] = false,
            ["Value"] = 0.0,
            ["Randomizer"] = {
                ["Enabled"] = true,
                ["Value"] = 0.0
            }
        },
        ["Delays Changer"] = {
            ["Enabled"] = false,
            ["[Revolver]"] = 0.00,
            ["[Double-Barrel SG]"] = 0.40,
            ["[TacticalShotgun]"] = 0.30,
            ["Others"] = 2.3
        }
    },
    ["Player Modifications"] = {
        ["Anti Fall"] = true,
        ["Avatar Changer"] = {
            ["Enabled"] = false,
            ["Username"] = "zlovcys",
            ["Misc"] = {
                ["Headless"] = false,
                ["Korblox"] = true
            }
        }
    },
    ["Local Game"] = {
        ["Inventory Sorter"] = {
            ["Enabled"] = false,
            ["Order"] = {
                "[Double-Barrel SG]",
                "[Revolver]",
                "[TacticalShotgun]",
                "[Knife]"
            }
        }
    },
    ["ESP"] = {
        ["Enabled"] = true,
        ["Color"] = Color3.fromRGB(255, 255, 255),
        ["TargetColor"] = Color3.fromRGB(0, 255, 0),
        ["UseDisplayName"] = true,
        ["Position"] = "Bottom",
        ["Size"] = 14
    }
}






if not LPH_NO_VIRTUALIZE then LPH_NO_VIRTUALIZE = function(f) return f end end
if not LPH_OBFUSCATED then LPH_OBFUSCATED = false end
if not LPH_ENCSTR then LPH_ENCSTR = function(s) return s end end
local plrs = game:FindFirstChildOfClass("Players")
local plr = plrs and plrs.LocalPlayer

if getgenv().XvoryConnections then
    for _, conn in ipairs(getgenv().XvoryConnections) do
        pcall(function() conn:Disconnect() end)
    end
end
getgenv().XvoryConnections = {}
local function ApplyGunDelay(tool)
    if not tool then return end
    local delaysConfig = shared.xvory.Weapon["Delays Changer"]
    if not delaysConfig.Enabled then return end
    local newDelay = delaysConfig[tool.Name] or delaysConfig["Others"]
    if not newDelay then return end
    local shootCD = tool:FindFirstChild("ShootingCooldown")
    local tolCD = tool:FindFirstChild("ToleranceCooldown")
    if shootCD and shootCD:IsA("NumberValue") then
        shootCD.Value = newDelay
    end
    if tolCD and tolCD:IsA("NumberValue") then
        tolCD.Value = newDelay
    end
    if tool:GetAttribute("Cooldown") then
        tool:SetAttribute("Cooldown", newDelay)
    end
end
local function ApplyToAllTools()
    if plr and plr.Character then
        for _, tool in ipairs(plr.Character:GetChildren()) do
            if tool:IsA("Tool") then ApplyGunDelay(tool) end
        end
    end
    if plr and plr.Backpack then
        for _, tool in ipairs(plr.Backpack:GetChildren()) do
            if tool:IsA("Tool") then ApplyGunDelay(tool) end
        end
    end
end
local currentCharacterConnection = nil
local function SetupCharacter(character)
    if currentCharacterConnection then
        currentCharacterConnection:Disconnect()
        currentCharacterConnection = nil
    end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then ApplyGunDelay(tool) end
    end
    currentCharacterConnection = character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then ApplyGunDelay(child) end
    end)
    table.insert(getgenv().XvoryConnections, currentCharacterConnection)
end
if plr and plr.Character then
    SetupCharacter(plr.Character)
end
local charConn = plr.CharacterAdded:Connect(function(newCharacter)
    SetupCharacter(newCharacter)
    ApplyToAllTools()
end)
table.insert(getgenv().XvoryConnections, charConn)
getgenv().ApplyGunDelays = ApplyToAllTools
ApplyToAllTools()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Self = Players.LocalPlayer
local Mouse = Self:GetMouse()
local Camera = game.Workspace.CurrentCamera
local GuiInsetOffsetY = game:GetService("GuiService"):GetGuiInset().Y
local CanTriggerbotShoot = true
local Script = {
    RBXConnections = {},
    Locals = {},
    Visuals = {}
}
local WeaponMap = {}
local Velocity_Data = {
    Tick = tick(),
    Sample = nil,
    State = Enum.HumanoidStateType.Running,
    Y = nil,
    Recorded = {
        Alpha = nil,
        B_0 = nil,
        V_T = nil,
        V_B = nil
    }
}
local function getTime()
    return os.date("%H:%M:%S")
end
local function progressBar(current, total, width)
    width = width or 20
    local filled = math.floor((current / total) * width)
    local bar = string.rep("#", filled) .. string.rep(" ", width - filled)
    local percent = math.floor((current / total) * 100)
    return string.format("[%s] (%d%%)", bar, percent)
end
local function atomicLog(message)
    print(string.format("[%s] [INFO] %s", getTime(), message))
end
local function atomicError(taskLabel, err)
    print(string.format("[%s] [ERROR] Task failed: %s", getTime(), taskLabel))
    print(string.format("[%s] [ERROR] Details: %s", getTime(), tostring(err)))
end
local tasks = {
    {
        label = "Loading config...",
        run = function()
            local config = {}
            config.version = "1.0.0"
            config.debug = false
            return config
        end
    },
    {
        label = "Checking dependencies...",
        run = function()
            assert(game:GetService("Players"), "Missing: Players")
            assert(game:GetService("HttpService"), "Missing: HttpService")
            assert(game:GetService("RunService"), "Missing: RunService")
            assert(game:GetService("TweenService"), "Missing: TweenService")
        end
    },
    {
        label = "Setting up modules...",
        run = function()
            assert(game:GetService("ReplicatedStorage"), "Missing: ReplicatedStorage")
        end
    },
    {
        label = "Allocating memory...",
        run = function()
            local buffer = {}
            for i = 1, 1000 do buffer[i] = i * 2 end
        end
    },
    {
        label = "Verifying integrity...",
        run = function()
            assert(type(print) == "function", "Core functions missing")
            assert(type(math.random) == "function", "Math lib missing")
            assert(type(task.wait) == "function", "Task lib missing")
        end
    },
}
local total = #tasks
local startTime = os.clock()
local results = {}
local failed = false
atomicLog("Initializing...")
for i, t in ipairs(tasks) do
    atomicLog(string.format("%s -  - %s", progressBar(i - 1, total), t.label))
    local ok, err = pcall(function()
        results[t.label] = t.run()
    end)
    if not ok then
        atomicError(t.label, err)
        failed = true
        break
    end
end
if not failed then
    local elapsed = os.clock() - startTime
    atomicLog(string.format("[xvory]: [SUCCESS] - Authenticated in %.12fs", elapsed))
end
local BASE_URL = "https://test-production-8fbf.up.railway.app"
local function extractConfigTable(source)
    local marker = source:find("shared%.xvory%s*=%s*{")
    if not marker then
        marker = source:find("local%s+DEFAULT_CONFIG%s*=%s*{")
    end
    if not marker then return nil end
    local braceStart = source:find("{", marker)
    if not braceStart then return nil end
    local depth = 0
    for i = braceStart, #source do
        local c = source:sub(i, i)
        if c == "{" then depth = depth + 1 end
        if c == "}" then
            depth = depth - 1
            if depth == 0 then
                return source:sub(braceStart, i)
            end
        end
    end
    return nil
end

local function parseWebConfig(tableStr)
    local code = "local Color3 = Color3; local Enum = Enum; local Vector3 = Vector3; return " .. tableStr
    local fn, err = loadstring(code)
    if not fn then return nil end
    local ok, result = pcall(fn)
    if ok and type(result) == "table" then return result end
    return nil
end

local function deepMerge(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            deepMerge(target[k], v)
        else
            target[k] = v
        end
    end
end

local function runXvory()
    local method = (shared.xvory and shared.xvory.Settings and shared.xvory.Settings.Method) or "Table"
    if method ~= "Web" and method ~= "Website" and method ~= "Cloud-Web" and method ~= "Cloud-Website" and method ~= "Cloud Website" then
        return true
    end

    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local function fetchAndApply()
        local url = BASE_URL .. "/api/active-config?t=" .. tostring(tick())
        local raw = game:HttpGet(url)
        if not raw or raw == "" or raw:find("No active configuration") then
            error("No Config Were Selected on the website config")
        end
        local tableStr = extractConfigTable(raw)
        if not tableStr then error("could not find config table in web config") end
        local newConfig = parseWebConfig(tableStr)
        if not newConfig then error("config parse failed") end
        deepMerge(shared.xvory, newConfig)
        shared.xvory.Settings = shared.xvory.Settings or {}
        shared.xvory.Settings.Method = "Web"
        return raw
    end

    local success, initialRaw = pcall(fetchAndApply)
    if not success then
        warn("No active config found on website. Using default local configuration instead.")
    end

    task.spawn(function()
        local lastRaw = initialRaw
        while true do
            task.wait(5)
            pcall(function()
                local url = BASE_URL .. "/api/active-config?t=" .. tostring(tick())
                local raw = game:HttpGet(url)
                if raw and raw ~= "" and not raw:find("No active configuration") and raw ~= lastRaw then
                    lastRaw = raw
                    local tableStr = extractConfigTable(raw)
                    if tableStr then
                        local newConfig = parseWebConfig(tableStr)
                        if newConfig then
                            deepMerge(shared.xvory, newConfig)
                            shared.xvory.Settings = shared.xvory.Settings or {}
                            shared.xvory.Settings.Method = "Web"
                            if getgenv().ApplyGunDelays then
                                getgenv().ApplyGunDelays()
                            end
                            if getgenv().ApplyAvatarChanger then
                                getgenv().ApplyAvatarChanger()
                            end
                        end
                    end
                end
            end)
        end
    end)
    return true
end
runXvory()
local aliases = {
    ["[Double-Barrel SG]"] = {"db", "double barrel", "double-barrel", "dbl sg", "double sg", "db sg"},
    ["[TacticalShotgun]"] = {"tac", "tac sg", "tactical shotgun", "tactical sg", "tacshot", "tactical"},
    ["[Drum-Shotgun]"] = {"drum sg", "drum shotgun", "auto sg", "drum auto", "drum"},
    ["[Shotgun]"] = {"sg", "shotgun", "pump", "pump sg", "pump shotgun", "buckshot"},
    ["[Revolver]"] = {"rev", "revolver", "six shooter", "wheel gun", "colt", "magnum"},
    ["[Silencer]"] = {"silencer", "suppressed", "supp pistol", "silenced pistol", "quiet gun"},
    ["[Glock]"] = {"glock", "g17", "glock 17", "pistol", "semi", "9mm"},
    ["[Rifle]"] = {"rifle", "ar", "assault rifle", "m4", "m4a1", "m16"},
    ["[AUG]"] = {"aug", "steyr aug", "bullpup", "aug rifle"},
    ["[AR]"] = {"ar", "assault rifle", "m4", "m4a1", "rifle"},
    ["[SMG]"] = {"smg", "submachine gun", "uzi", "mp5", "mp7", "vector"},
    ["[LMG]"] = {"lmg", "light machine gun", "m249", "saw", "negev"},
    ["[P90]"] = {"p90", "fn p90", "pdw", "personal defense weapon"},
    ["[AK47]"] = {"ak", "ak47", "kalashnikov", "akm", "russian rifle"},
    ["[SilencerAR]"] = {"silencer ar", "suppressed ar", "silenced rifle", "quiet ar"},
    ["[DrumGun]"] = {"drum gun", "tommy gun", "thompson", "drum ar", "drum rifle"}
}
for weapon, names in pairs(aliases) do
    for _, alias in ipairs(names) do
        WeaponMap[alias] = weapon
    end
end
local Modules = { Cache = {} }
function Modules.Get(Id)
    if not Modules.Cache[Id] then
        Modules.Cache[Id] = {
            c = Modules[Id](),
        }
    end
    return Modules.Cache[Id].c
end
local function InitializeLocals()
    local defaults = {
        LPH_ENCSTR("GunScriptDisabled"), LPH_ENCSTR("IsTriggerBotting"), LPH_ENCSTR("TriggerbotTarget"), LPH_ENCSTR("IsDoubleTapping"), LPH_ENCSTR("SilentAimTarget"),
        LPH_ENCSTR("AimAssistTarget"), LPH_ENCSTR("IsWalkSpeeding"), LPH_ENCSTR("DoubleTapState"), LPH_ENCSTR("CurrentWeapon"),
        LPH_ENCSTR("IsBoxFocused"), LPH_ENCSTR("TriggerState"), LPH_ENCSTR("HitPosition"), LPH_ENCSTR("HitTrigger"), LPH_ENCSTR("MoveVector"), LPH_ENCSTR("LastShot"),
        LPH_ENCSTR("IsAimed"), LPH_ENCSTR("HitPart"), LPH_ENCSTR("CodeRegion"), LPH_ENCSTR("FieldOfViewOne"), LPH_ENCSTR("FieldOfViewTwo"), LPH_ENCSTR("IsOverriding")
    }
    for _, v in ipairs(defaults) do Script.Locals[v] = nil end
    Script.Locals.LastShot = 0
    Script.Locals.CodeRegion = "Initialization"
    Script.Locals.HitPosition = Vector3.new()
end
InitializeLocals()
local function SetRegion(Region)
    Script.Locals.CodeRegion = Region
end
local function GetRegion()
    return Script.Locals.CodeRegion
end
local WeaponInfo = {
    Shotguns = {"[TacticalShotgun]", "[Shotgun]", "[Double-Barrel SG]"},
    AutoShotguns = {"[Drum-Shotgun]"},
    Pistols = {"[Revolver]", "[Silencer]", "[Glock]"},
    Rifles = {"[AR]", "[SilencerAR]", "[AK47]", "[LMG]", "[DrumGun]"},
    Bursts = {"[AUG]"},
    SMG = {"[SMG]", "[P90]"},
    Snipers = {"[Rifle]"},
    Offsets = {
        ["[Double-Barrel SG]"] = CFrame.new(0, 0.35, -2.2),
        ["[TacticalShotgun]"] = CFrame.new(0, 0.25, -2.5),
        ["[Drum-Shotgun]"] = CFrame.new(-0.1, 0.5, -2.5),
        ["[Shotgun]"] = CFrame.new(0, 0.25, -2.5),
        ["[Revolver]"] = CFrame.new(-1, 0.4, 0),
        ["[Silencer]"] = CFrame.new(0, 0.4, 1.3),
        ["[Glock]"] = CFrame.new(0.6, 0.25, 0),
        ["[Rifle]"] = CFrame.new(0, 0.25, 2.5),
        ["[AUG]"] = CFrame.new(-0.1, 0.4, 1.8),
        ["[AR]"] = CFrame.new(2, 0.35, 0),
        ["[SMG]"] = CFrame.new(0, 1, 0.5),
        ["[LMG]"] = CFrame.new(0, 0.7, -3.8),
        ["[P90]"] = CFrame.new(0, 0.2, -1.7),
        ["[AK47]"] = CFrame.new(-0.1, 0.5, -2.5),
        ["[SilencerAR]"] = CFrame.new(2.5, 0.35, 0),
        ["[DrumGun]"] = CFrame.new(0, 0.4, 2.4)
    },
    Delays = {
        ["[Double-Barrel SG]"] = 0.0, ["[TacticalShotgun]"] = 0.0, ["[Drum-Shotgun]"] = 0.415,
        ["[Shotgun]"] = 1.2, ["[Revolver]"] = 0.0, ["[Silencer]"] = 0.0095, ["[Glock]"] = 0.0095,
        ["[Rifle]"] = 1.3095, ["[AUG]"] = 0.0095, ["[AR]"] = 0.15, ["[SMG]"] = 0.6,
        ["[LMG]"] = 0.62, ["[P90]"] = 0.6, ["[AK47]"] = 0.15, ["[SilencerAR]"] = 0.02
    }
}
local SilentFOVRadius = 100
local CamlockFOVCircle = nil
local TriggerPart = Instance.new("Part")
TriggerPart.Name = math.random(1, 99999999)
local SilentAimPart = Instance.new("Part")
SilentAimPart.Name = math.random(1, 99999999)
local function GameFunctions()
    SetRegion("Game Functions")
    return {
        IsKnocked = function(Player)
            return Player and Player:FindFirstChild("BodyEffects") and Player.BodyEffects["K.O"].Value or false
        end,
        IsGrabbed = function(Player)
            return Player and Player.Character and Player.Character:FindFirstChild("GRABBING_CONSTRAINT") ~= nil
        end,
    }
end
local Games = {
    [LPH_ENCSTR("Da Hood")] = { HoodGame = true, Functions = GameFunctions() },
    [LPH_ENCSTR("Dee Hood")] = { HoodGame = true, Updater = (""), Functions = GameFunctions(),
                      RemotePath = function() return ReplicatedStorage:FindFirstChild("MainEvent") end },
    [LPH_ENCSTR("Der Hood")] = { HoodGame = true, Updater = LPH_ENCSTR("DERHOODMOUSEPOS666^"), Functions = GameFunctions(),
                      RemotePath = function() return ReplicatedStorage:FindFirstChild("MainRemotes") and ReplicatedStorage.MainRemotes:FindFirstChild("MainRemoteEvent") end },
    [LPH_ENCSTR("Dea Hood")] = { HoodGame = true, Updater = LPH_ENCSTR("DEAHOODMOUSEPOSx3^3"), Functions = GameFunctions(),
                      RemotePath = function() return ReplicatedStorage:FindFirstChild("MainRemotes") and ReplicatedStorage.MainRemotes:FindFirstChild("MainRemoteEvent") end },
    [LPH_ENCSTR("a literal baseplate.")] = { HoodGame = false, Functions = GameFunctions() },
    [LPH_ENCSTR("Universal")] = { HoodGame = false, Functions = GameFunctions() }
}
local MarketplaceService = game:GetService("MarketplaceService")
local Success, Info = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)
local GameName = Success and Info.Name or "Universal"
local Match
for Index in pairs(Games) do
    if string.match(GameName, Index) then
        Match = Index
        break
    end
end
local CurrentGame = Games[Match] or Games.Universal
SetRegion("Threading")
local function ThreadLoop(Wait, Func)
    task.spawn(function()
        while true do
            local Delta = task.wait(Wait)
            local Success, Result = pcall(Func, Delta)
            if not Success then
                warn("Thread error:", Result)
            elseif Result == "break" then
                break
            end
        end
    end)
end
local function ThreadFunction(Func, Name, ...)
    local WrappedFunc = Name and function()
        local Passed, Statement = pcall(Func)
        if not Passed then
            warn("ThreadFunction Error:\n" .. "              " .. Name .. ":" .. Statement)
        end
    end or Func
    local Thread = coroutine.create(WrappedFunc)
    coroutine.resume(Thread, ...)
    return Thread
end
local function RBXConnection(Signal, Callback)
    local connection = Signal:Connect(Callback)
    table.insert(getgenv().XvoryConnections, connection)
    Script.RBXConnections[#Script.RBXConnections + 1] = connection
    return connection
end
do
    SetRegion("Drawing")
    local CustomLibIndex = 0
    local coreGui = game:GetService("CoreGui")
    local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    local targetGui = coreGui or playerGui or Instance.new("ScreenGui")
    for _, child in ipairs(targetGui:GetChildren()) do
        if child.Name == "XvoryUI" then
            pcall(function() child:Destroy() end)
        end
    end
    local UtilityUI = Instance.new("ScreenGui")
    UtilityUI.Name = "XvoryUI"
    UtilityUI.IgnoreGuiInset = true
    UtilityUI.Parent = targetGui
    if not UtilityUI.Parent then
        UtilityUI.Parent = game.Players.LocalPlayer
    end
    local Clamp = math.clamp
    local Atan2 = math.atan2
    local Deg = math.deg
    local LibraryMeta = setmetatable({
        Visible = true,
        ZIndex = 0,
        Transparency = 1,
        Color = Color3.new(),
        Remove = function(self) setmetatable(self, nil) end,
        Destroy = function(self) setmetatable(self, nil) end
    }, {
        __add = function(t1, t2)
            local result = table.clone(t1)
            for index, value in pairs(t2) do
                result[index] = value
            end
            return result
        end
    })
    local function ClampTransparency(number)
        return Clamp(1 - number, 0, 1)
    end
    Script.Visuals = Script.Visuals or {}
    Script.Visuals.new = function(ClassType)
        CustomLibIndex = CustomLibIndex + 1
        if ClassType == "Line" then
            local LineObject = ({
                From = Vector2.zero,
                To = Vector2.zero,
                Thickness = 1
            } + LibraryMeta)
            local Line = Instance.new("Frame")
            Line.Name = tostring(CustomLibIndex)
            Line.AnchorPoint = Vector2.new(0.5, 0.5)
            Line.BorderSizePixel = 0
            Line.BackgroundColor3 = LineObject.Color
            Line.Visible = LineObject.Visible
            Line.ZIndex = LineObject.ZIndex
            Line.BackgroundTransparency = ClampTransparency(LineObject.Transparency)
            Line.Size = UDim2.new()
            Line.Parent = UtilityUI
            return setmetatable({}, {
                __newindex = function(_, Property, Value)
                    if Property == "From" then
                        local Direction = (LineObject.To - Value)
                        local Center = (LineObject.To + Value) / 2
                        local Magnitude = Direction.Magnitude
                        local Theta = Deg(Atan2(Direction.Y, Direction.X))
                        Line.Position = UDim2.fromOffset(Center.X, Center.Y)
                        Line.Rotation = Theta
                        Line.Size = UDim2.fromOffset(Magnitude, LineObject.Thickness)
                    elseif Property == "To" then
                        local Direction = (Value - LineObject.From)
                        local Center = (Value + LineObject.From) / 2
                        local Magnitude = Direction.Magnitude
                        local Theta = Deg(Atan2(Direction.Y, Direction.X))
                        Line.Position = UDim2.fromOffset(Center.X, Center.Y)
                        Line.Rotation = Theta
                        Line.Size = UDim2.fromOffset(Magnitude, LineObject.Thickness)
                    elseif Property == "Thickness" then
                        local Thickness = (LineObject.To - LineObject.From).Magnitude
                        Line.Size = UDim2.fromOffset(Thickness, Value)
                    elseif Property == "Visible" then
                        Line.Visible = Value
                    elseif Property == "ZIndex" then
                        Line.ZIndex = Value
                    elseif Property == "Transparency" then
                        Line.BackgroundTransparency = ClampTransparency(Value)
                    elseif Property == "Color" then
                        Line.BackgroundColor3 = Value
                    end
                    LineObject[Property] = Value
                end,
                __index = function(self, index)
                    if index == "Remove" or index == "Destroy" then
                        return function()
                            Line:Destroy()
                            LineObject.Remove(self)
                        end
                    end
                    return LineObject[index]
                end
            })
        elseif ClassType == "Circle" then
            local circleObj = ({
                Radius = 150,
                Position = Vector2.zero,
                Thickness = 0.7,
                Filled = false
            } + LibraryMeta)
            local circleFrame = Instance.new("Frame")
            local uiCorner = Instance.new("UICorner")
            local uiStroke = Instance.new("UIStroke")
            circleFrame.Name = tostring(CustomLibIndex)
            circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            circleFrame.BorderSizePixel = 0
            circleFrame.BackgroundTransparency = (circleObj.Filled and ClampTransparency(circleObj.Transparency) or 1)
            circleFrame.BackgroundColor3 = circleObj.Color
            circleFrame.Visible = circleObj.Visible
            circleFrame.ZIndex = circleObj.ZIndex
            uiCorner.CornerRadius = UDim.new(1, 0)
            circleFrame.Size = UDim2.fromOffset(circleObj.Radius, circleObj.Radius)
            uiStroke.Thickness = circleObj.Thickness
            uiStroke.Enabled = not circleObj.Filled
            uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            circleFrame.Parent = UtilityUI
            uiCorner.Parent = circleFrame
            uiStroke.Parent = circleFrame
            return setmetatable({}, {
                __newindex = function(_, index, value)
                    if circleObj[index] == nil then return end
                    if index == "Radius" then
                        local radius = value * 2
                        circleFrame.Size = UDim2.fromOffset(radius, radius)
                    elseif index == "Position" then
                        circleFrame.Position = UDim2.fromOffset(value.X, value.Y)
                    elseif index == "Thickness" then
                        value = Clamp(value, 0.6, 0x7fffffff)
                        uiStroke.Thickness = value
                    elseif index == "Filled" then
                        circleFrame.BackgroundTransparency = (value and ClampTransparency(circleObj.Transparency) or 1)
                        uiStroke.Enabled = not value
                    elseif index == "Visible" then
                        circleFrame.Visible = value
                    elseif index == "ZIndex" then
                        circleFrame.ZIndex = value
                    elseif index == "Transparency" then
                        local transparency = ClampTransparency(value)
                        circleFrame.BackgroundTransparency = (circleObj.Filled and transparency or 1)
                        uiStroke.Transparency = transparency
                    elseif index == "Color" then
                        circleFrame.BackgroundColor3 = value
                        uiStroke.Color = value
                    end
                    circleObj[index] = value
                end,
                __index = function(self, index)
                    if index == "Remove" or index == "Destroy" then
                        return function()
                            circleFrame:Destroy()
                            circleObj.Remove(self)
                        end
                    end
                    return circleObj[index]
                end
            })
        elseif ClassType == "Square" then
            local squareObj = ({
                Size = Vector2.zero,
                Position = Vector2.zero,
                Thickness = 0.7,
                Filled = false,
                Drag = false,
            } + LibraryMeta)
            local squareFrame = Instance.new("Frame")
            local uiStroke = Instance.new("UIStroke")
            squareFrame.Name = tostring(CustomLibIndex)
            squareFrame.BorderSizePixel = 0
            local transparency
            if squareObj.Filled then
                transparency = ClampTransparency(squareObj.Transparency)
            else
                transparency = 1
            end
            squareFrame.BackgroundTransparency = transparency
            squareFrame.ZIndex = squareObj.ZIndex
            squareFrame.BackgroundColor3 = squareObj.Color
            squareFrame.Visible = squareObj.Visible
            uiStroke.Thickness = squareObj.Thickness
            uiStroke.Enabled = not squareObj.Filled
            uiStroke.LineJoinMode = Enum.LineJoinMode.Miter
            squareFrame.Parent = UtilityUI
            uiStroke.Parent = squareFrame
            local dragging = false
            local dragStart = nil
            local startPos = nil
            squareFrame.MouseEnter:Connect(function()
                if squareObj.Drag then
                    local inputConnection
                    inputConnection = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                            dragStart = input.Position
                            startPos = squareFrame.Position
                        end
                    end)
                    local leaveConnection
                    leaveConnection = squareFrame.MouseLeave:Connect(function()
                        inputConnection:Disconnect()
                        leaveConnection:Disconnect()
                    end)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if squareObj.Drag and dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = input.Position - dragStart
                    local newX = startPos.X.Offset + delta.X
                    local newY = startPos.Y.Offset + delta.Y
                    squareFrame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if squareObj.Drag and input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            return setmetatable({}, {
                __newindex = function(_, index, value)
                    if squareObj[index] == nil then return end
                    if index == "Size" then
                        squareFrame.Size = UDim2.fromOffset(value.X, value.Y)
                    elseif index == "Position" then
                        squareFrame.Position = UDim2.fromOffset(value.X, value.Y)
                    elseif index == "Thickness" then
                        value = Clamp(value, 0.6, 0x7fffffff)
                        uiStroke.Thickness = value
                    elseif index == "Visible" then
                        squareFrame.Visible = value
                    elseif index == "Transparency" then
                        local transparency = ClampTransparency(value)
                        squareFrame.BackgroundTransparency = 1
                        uiStroke.Transparency = transparency
                    elseif index == "Color" then
                        uiStroke.Color = value
                        squareFrame.BackgroundColor3 = value
                    end
                    squareObj[index] = value
                end,
                __index = function(self, index)
                    if index == "Remove" or index == "Destroy" then
                        return function()
                            squareFrame:Destroy()
                            squareObj.Remove(self)
                        end
                    end
                    return squareObj[index]
                end
            })
        elseif ClassType == "Text" then
            local textObj = ({
                Text = "",
                Font = Enum.Font.SourceSansBold,
                Size = 0,
                Position = Vector2.zero,
                Center = false,
                Outline = false,
                OutlineColor = Color3.new()
            } + LibraryMeta)
            local textLabel = Instance.new("TextLabel")
            local uiStroke = Instance.new("UIStroke")
            textLabel.Name = tostring(CustomLibIndex)
            textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            textLabel.BorderSizePixel = 0
            textLabel.BackgroundTransparency = 1
            textLabel.RichText = true
            textLabel.Visible = textObj.Visible
            textLabel.TextColor3 = textObj.Color
            textLabel.TextTransparency = ClampTransparency(textObj.Transparency)
            textLabel.ZIndex = textObj.ZIndex
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.TextSize = textObj.Size
            textLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
                local textBounds = textLabel.TextBounds
                local offset = textBounds / 2
                local offsetX = textObj.Center and 0 or offset.X
                textLabel.Position = UDim2.fromOffset(textObj.Position.X + offsetX, textObj.Position.Y + offset.Y)
            end)
            uiStroke.Thickness = 1
            uiStroke.Enabled = textObj.Outline
            uiStroke.Color = textObj.Color
            textLabel.Parent = UtilityUI
            uiStroke.Parent = textLabel
            return setmetatable({}, {
                __newindex = function(_, index, value)
                    if textObj[index] == nil then return end
                    if index == "Text" then
                        textLabel.Text = value
                    elseif index == "Size" then
                        textLabel.TextSize = value
                    elseif index == "Position" then
                        local offset = textLabel.TextBounds / 2
                        local offsetX = textObj.Center and 0 or offset.X
                        textLabel.Position = UDim2.fromOffset(textObj.Position.X + offsetX, textObj.Position.Y + offset.Y)
                    elseif index == "Center" then
                        local pos = value and (game:GetService("Workspace").CurrentCamera.ViewportSize / 2) or textObj.Position
                        textLabel.Position = UDim2.fromOffset(pos.X, pos.Y)
                    elseif index == "Outline" then
                        uiStroke.Enabled = value
                    elseif index == "OutlineColor" then
                        uiStroke.Color = value
                    elseif index == "Visible" then
                        textLabel.Visible = value
                    elseif index == "ZIndex" then
                        textLabel.ZIndex = value
                    elseif index == "Transparency" then
                        local transparency = ClampTransparency(value)
                        textLabel.TextTransparency = transparency
                        uiStroke.Transparency = transparency
                    elseif index == "Color" then
                        textLabel.TextColor3 = value
                    end
                    textObj[index] = value
                end,
                __index = function(self, index)
                    if index == "Remove" or index == "Destroy" then
                        return function()
                            textLabel:Destroy()
                            textObj.Remove(self)
                        end
                    elseif index == "TextBounds" then
                        return textLabel.TextBounds
                    end
                    return textObj[index]
                end
            })
        end
    end
end
do
    SetRegion("Game")
    function Script:RayCast(Part, Origin, Ignore, Distance)
        Ignore = Ignore or {}
        Distance = Distance or 2000
        local Direction = (Part.Position - Origin).Unit * Distance
        local Cast = Ray.new(Origin, Direction)
        local Hit = Workspace:FindPartOnRayWithIgnoreList(Cast, Ignore)
        return Hit and Hit:IsDescendantOf(Part.Parent), Hit
    end
    function Script:ValidateClient(Player)
        local Object = Player.Character
        local Humanoid = (Object and Object:FindFirstChild("Humanoid")) or false
        local RootPart = (Humanoid and Humanoid.RootPart) or false
        return Object, Humanoid, RootPart
    end
    function Script:GetOrigin(Origin)
        local Object, Humanoid, RootPart = Script:ValidateClient(Self)
        if Origin == "Head" then
            local Head = Object:FindFirstChild("Head")
            if Head and Head:IsA("BasePart") then
                return Head.CFrame.Position
            end
        elseif Origin == "Torso" and RootPart then
            return RootPart.CFrame.Position
        end
        return Workspace.CurrentCamera.CFrame.Position
    end
    function Script:GetClosestPlayerToCursor(Max, FOV, ignoreWallCheckForTargeting)
        local CurrentCamera = game.Workspace.CurrentCamera
        local MousePosition = UserInputService:GetMouseLocation()
        local Closest        local Distance = Max or math.huge
        FOV = FOV or math.huge
        for _, Player in ipairs(Players:GetPlayers()) do
            if (Player == Self) then
                continue
            end
            local Character = Player.Character
            if Player and Player.Character then
                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                if (not HumanoidRootPart) then
                    continue
                end
                local Position, OnScreen = CurrentCamera:WorldToViewportPoint(HumanoidRootPart.Position)
                if not OnScreen then
                    continue
                end
                local cond = shared.xvory.Silent.Conditions
                if cond.knocked and Player.Character and CurrentGame.Functions.IsKnocked(Player.Character) then
                    continue
                end
                if cond["Self Knocked"] and CurrentGame.Functions.IsKnocked(Self.Character) then
                    continue
                end
                if cond.Grabbed and CurrentGame.Functions.IsGrabbed(Player) then
                    continue
                end
                local Magnitude = (Vector2.new(Position.X, Position.Y) - MousePosition).Magnitude
                if (Magnitude < Distance and Magnitude < FOV) then
                    Closest = Player
                    Distance = Magnitude
                end
            end
        end
        return Closest
    end
end
do
    SetRegion("Gun System")
    function Modules.DaHood()
        if string.find(GameName, "Da Hood") then
            local IsClient = RunService:IsClient()
            local PlaceIDCheck = game.PlaceId == 88976059384565
            local function CanShoot(Character)
                if Character then
                    local Humanoid = Character:FindFirstChild("Humanoid")
                    if Humanoid and (Humanoid.Health > 0 and Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) then
                        local BodyEffects = Character:FindFirstChild("BodyEffects")
                        if BodyEffects then
                            local Tool = Character:FindFirstChildWhichIsA("Tool")
                            if Tool and (Tool:FindFirstChild("Handle") and Tool:FindFirstChild("Ammo")) then
                                if not PlaceIDCheck and IsClient then
                                    if BodyEffects:FindFirstChild("Block") then
                                        shared.playerShot(Tool.Handle)
                                        Tool.Handle.NoAmmo:Play()
                                        return
                                    end
                                    if Tool.Ammo.Value == 0 then
                                        Tool.Handle.NoAmmo:Play()
                                        return
                                    end
                                end
                                if Character:FindFirstChild("FULLY_LOADED_CHAR") == nil then
                                    return
                                elseif Character:FindFirstChild("FORCEFIELD") then
                                    return
                                elseif Character:FindFirstChild("GRABBING_CONSTRAINT") then
                                    return
                                elseif Character:FindFirstChild("Christmas_Sock") then
                                    return
                                elseif BodyEffects.Cuff.Value == true then
                                    return
                                elseif BodyEffects.Attacking.Value == true then
                                    return
                                elseif BodyEffects["K.O"].Value == true then
                                    return
                                elseif BodyEffects.Grabbed.Value then
                                    return
                                elseif BodyEffects.Reload.Value == true then
                                    return
                                elseif BodyEffects.Dead.Value == true then
                                    return
                                elseif not Tool:GetAttribute("Cooldown") then
                                    local LastShot = Character:GetAttribute("LastGunShot")
                                    Character:SetAttribute("LastGunShot", Tool.Name)
                                    if not IsClient or (LastShot == Tool.Name or not Character:GetAttribute("ShotgunDebounce")) then
                                        if not IsClient and (not Character:GetAttribute("ShotgunDebounce") and (Tool.Name == "[Shotgun]" or (Tool.Name == "[Double-Barrel SG]" or (Tool.Name == "TacticalShotgun" or Tool.Name == "Drum-Shotgun")))) then
                                            Character:SetAttribute("ShotgunDebounce", true)
                                            task.delay(0.65, function()
                                                Character:SetAttribute("ShotgunDebounce", nil)
                                            end)
                                        end
                                        return true
                                    end
                                end
                            else
                                return
                            end
                        else
                            return
                        end
                    else
                        return
                    end
                else
                    return
                end
            end
            local function ColorTransform(p14, p15)
                if p15 == 0 then
                    return p14.Keypoints[1].Value
                end
                if p15 == 1 then
                    return p14.Keypoints[#p14.Keypoints].Value
                end
                for v16 = 1, #p14.Keypoints - 1 do
                    local v17 = p14.Keypoints[v16]
                    local v18 = p14.Keypoints[v16 + 1]
                    if v17.Time <= p15 and p15 < v18.Time then
                        local v19 = (p15 - v17.Time) / (v18.Time - v17.Time)
                        return Color3.new((v18.Value.R - v17.Value.R) * v19 + v17.Value.R, (v18.Value.G - v17.Value.G) * v19 + v17.Value.G, (v18.Value.B - v17.Value.B) * v19 + v17.Value.B)
                    end
                end
            end
            local weaponNames = {
                "[Shotgun]",
                "[Drum-Shotgun]",
                "[Rifle]",
                "[TacticalShotgun]",
                "[AR]",
                "[AUG]",
                "[AK47]",
                "[LMG]",
                "[SilencerAR]",
            }
            local replicatedStorage = game:GetService("ReplicatedStorage")
            local playersService = game:GetService("Players")
            local localPlayer = playersService.LocalPlayer
            local playerCharacter = Self.Character or Self.CharacterAdded:Wait()
            local shootAnimation = playerCharacter.Humanoid.Animator:LoadAnimation(
                replicatedStorage:WaitForChild("Animations"):WaitForChild("GunCombat"):WaitForChild("Shoot")
            )
            local aimShootAnimation = playerCharacter.Humanoid.Animator:LoadAnimation(
                replicatedStorage:WaitForChild("Animations"):WaitForChild("GunCombat"):WaitForChild("AimShoot")
            )
            local v_u_14 = {}
            local function changefunc()
                local v_u_38 = {
                    ["functions"] = {},
                }
                function v_u_38.connect(_, p36)
                    local v37 = v_u_38.functions
                    table.insert(v37, p36)
                end
                local v_u_39 = nil
                function v_u_38.updatechanges(_, p_u_40)
                    for _, v_u_41 in pairs(v_u_38.functions) do
                        spawn(function()
                            v_u_41(p_u_40.Press, p_u_40.Time, v_u_39)
                        end)
                    end
                    v_u_39 = p_u_40.Time
                end
                return v_u_38
            end
            setmetatable(v_u_14, {
                ["__index"] = function(_, p42)
                    local v43 = v_u_14
                    if getmetatable(v43)[p42] == nil then
                        v_u_14[p42] = {}
                    end
                    local v44 = v_u_14
                    return getmetatable(v44)[p42]
                end,
                ["__newindex"] = function(_, p45, p46)
                    local v47 = v_u_14
                    if getmetatable(v47)[p45] == nil then
                        local v48 = v_u_14
                        getmetatable(v48)[p45] = {
                            ["val"] = p46,
                            ["changed"] = changefunc()
                        }
                    else
                        local v49 = v_u_14
                        getmetatable(v49)[p45].val = p46
                        local v50 = v_u_14
                        getmetatable(v50)[p45].changed:updatechanges(p46)
                    end
                end
            })
            UserInputService.InputBegan:connect(function(p51, p52)
                if not p52 or p51.UserInputType == Enum.UserInputType.Keyboard and p51.KeyCode == Enum.KeyCode.LeftShift or p51.UserInputType == Enum.UserInputType.Gamepad1 and p51.KeyCode == Enum.KeyCode.ButtonL2 then
                    if p51.UserInputType == Enum.UserInputType.Keyboard or p51.UserInputType == Enum.UserInputType.Gamepad1 then
                        v_u_14[p51.KeyCode.Name] = {
                            ["Press"] = true,
                            ["Time"] = tick()
                        }
                        return
                    end
                    if p51.UserInputType == Enum.UserInputType.MouseButton2 then
                        v_u_14[Enum.UserInputType.MouseButton2.Name] = {
                            ["Press"] = true,
                            ["Time"] = tick()
                        }
                    end
                end
            end)
            UserInputService.InputEnded:connect(function(p53, p54)
                if not p54 or p53.UserInputType == Enum.UserInputType.Keyboard and p53.KeyCode == Enum.KeyCode.LeftShift or p53.UserInputType == Enum.UserInputType.Gamepad1 and p53.KeyCode == Enum.KeyCode.ButtonL2 then
                    if p53.UserInputType == Enum.UserInputType.Keyboard or p53.UserInputType == Enum.UserInputType.Gamepad1 then
                        v_u_14[p53.KeyCode.Name] = {
                            ["Press"] = false,
                            ["Time"] = tick()
                        }
                        return
                    end
                    if p53.UserInputType == Enum.UserInputType.MouseButton2 then
                        v_u_14[Enum.UserInputType.MouseButton2.Name] = {
                            ["Press"] = false,
                            ["Time"] = tick()
                        }
                    end
                end
            end)
            local v_u_70 = true
            v_u_14.MouseButton2.changed:connect(function(p71, _, _)
                if v_u_70 ~= false then
                    Script.Locals.IsAimed = p71
                    if Script.Locals.IsAimed == false then
                        v_u_70 = false
                        wait(0.1)
                        v_u_70 = true
                    end
                end
            end)
            local function Animate(target)
                playerCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                if playerCharacter and playerCharacter:FindFirstChild("Humanoid") and playerCharacter.Humanoid:FindFirstChild("Animator") then
                    shootAnimation = playerCharacter.Humanoid.Animator:LoadAnimation(replicatedStorage.Animations.GunCombat.Shoot)
                    aimShootAnimation = playerCharacter.Humanoid.Animator:LoadAnimation(replicatedStorage.Animations.GunCombat.AimShoot)
                    if Script.Locals.IsAimed or table.find(weaponNames, target.Parent.Name) then
                        aimShootAnimation:Play()
                    else
                        shootAnimation:Play()
                    end
                end
            end
            shared.playerShot = Animate
            local v3 = game:GetService("Players")
            local v_u_5 = game:GetService("TweenService")
            local v_u_7 = v3.LocalPlayer
            local v_u_9 = replicatedStorage.SkinAssets
            local v_u_13 = game.Workspace:GetServerTimeNow()
            local _ = game.PlaceId == 88976059384565
            local SoundsPlaying = {}
            local function GetAim(Position)
                if _G.MobileShiftLock then
                    return (Camera.CFrame.p + Camera.CFrame.LookVector * 60 - Position).unit
                end
                local v24
                if Mouse.Target then
                    v24 = Mouse.Hit.p
                else
                    local v25 = Camera.CFrame
                    local v26 = v25.p + v25.LookVector * 60
                    local v27 = v25.LookVector
                    local v28 = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
                    local v29 = v28.Direction
                    local v30 = v28.Origin
                    v24 = v30 + v29 * ((v26 - v30):Dot(v27) / v29:Dot(v27))
                end
                return (v24 - Position).Unit, (v24 - Position).Magnitude
            end
            local function ShootGun(p34)
                local v35 = p34.Shooter
                local v_u_36 = p34.Handle
                local v37 = p34.AimPosition
                local v38 = p34.BeamColor
                local v39 = p34.isReflecting
                local v40 = p34.Hit
                local v41 = p34.Range or 200
                local LegitPosition = p34.LegitPosition
                local v_u_42
                if v_u_36 then
                    v_u_42 = v_u_36:GetAttribute("SkinName")
                else
                    v_u_42 = v_u_36
                end
                local _, v43 = GetAim(v_u_36.Position)
                local v_u_44 = p34.ForcedOrigin or v_u_36.Muzzle.WorldPosition
                local v45 = (v37 - v_u_44).Unit
                local v46 = RaycastParams.new()
                local v47 = {}
                local function set_list(targetTable, index, values)
                    for i, v in ipairs(values) do
                        targetTable[index + i - 1] = v
                    end
                end
                local v48 = { game.Workspace:WaitForChild("Bush"), game.Workspace:WaitForChild("Ignored"), TriggerPart, SilentAimPart }
                set_list(v47, 1, {v35, unpack(v48)})
                v46.FilterDescendantsInstances = v47
                v46.FilterType = Enum.RaycastFilterType.Exclude
                v46.IgnoreWater = true
                local v_u_49, v_u_50, v_u_51
                if v40 then
                    v_u_49 = p34.Hit
                    v_u_50 = p34.AimPosition
                    v_u_51 = p34.Normal
                else
                    local v52 = game.Workspace:Raycast(v_u_44, v45 * v41, v46)
                    if v52 then
                        v_u_49 = v52.Instance
                        v_u_50 = v52.Position
                        v_u_51 = v52.Normal
                    else
                        v_u_50 = v_u_44 + v45 * math.min(v43, v41)
                        v_u_51 = nil
                        v_u_49 = nil
                    end
                end
                local v_u_53 = Instance.new("Part")
                v_u_53:SetAttribute("OwnerCharacter", v35.Name)
                v_u_53.Name = "BULLET_RAYS"
                v_u_53.Anchored = true
                v_u_53.CanCollide = false
                v_u_53.Size = Vector3.new(0, 0, 0)
                v_u_53.Transparency = 1
                game.Debris:AddItem(v_u_53, 1)
                local Tool = Self.Character:FindFirstChildWhichIsA("Tool")
                if shared.xvory.Silent["Client Mode"].Enabled and table.find(shared.xvory.Silent["Client Mode"].weapons, Tool.Name) then
                    v_u_53.CFrame = CFrame.new(v_u_44, LegitPosition)
                else
                    v_u_53.CFrame = CFrame.new(v_u_44, v_u_50)
                end
                v_u_53.Material = Enum.Material.SmoothPlastic
                v_u_53.Parent = game.Workspace.Ignored.Siren.Radius
                local v54 = Instance.new("Attachment")
                v54.Position = Vector3.new(0, 0, 0)
                v54.Parent = v_u_53
                local v55 = Instance.new("Attachment")
                local v56 = -(v_u_50 - v_u_44).magnitude
                v55.Position = Vector3.new(0, 0, v56)
                v55.Parent = v_u_53
                local v_u_57 = false
                local v_u_58 = nil
                local v59
                if v_u_36 then
                    local v60 = v_u_36.Parent.Name
                    if v_u_42 and v_u_42 ~= "" then
                        if v_u_9.GunSkinMuzzleParticle:FindFirstChild(v_u_42) then
                            if not v39 then
                                if v_u_9.GunSkinMuzzleParticle[v_u_42]:FindFirstChild("Muzzle") then
                                    if v_u_36.Parent:FindFirstChild("Default") and (v_u_36.Parent.Default:FindFirstChild("Mesh") and v_u_36.Parent.Default.Mesh:FindFirstChild("Muzzle")) then
                                        local v61
                                        if v_u_9.GunSkinMuzzleParticle[v_u_42].Muzzle:FindFirstChild("Different_GunMuzzle") then
                                            v61 = v_u_9.GunSkinMuzzleParticle[v_u_42].Muzzle.Different_GunMuzzle[v60]
                                        else
                                            v61 = v_u_9.GunSkinMuzzleParticle[v_u_42].Muzzle
                                        end
                                        for _, v62 in pairs(v61:GetChildren()) do
                                            local v63 = v62:GetAttribute("EmitCount") or 1
                                            local v_u_64 = v62:Clone()
                                            v_u_64.Parent = v_u_36.Parent.Default.Mesh.Muzzle
                                            v_u_64:Emit(v63)
                                            task.delay(v_u_64.Lifetime.Max, function()
                                                v_u_64:Destroy()
                                            end)
                                        end
                                    end
                                else
                                    local v65 = v_u_9.GunSkinMuzzleParticle[v_u_42]:GetChildren()
                                    local v66 = v65[math.random(#v65)]:Clone()
                                    v66.Parent = v54
                                    v66:Emit(v66.Rate)
                                end
                            end
                            v_u_57 = true
                        end
                        if v_u_9.GunBeam:FindFirstChild(v_u_42) then
                            if v_u_9.GunBeam[v_u_42].GunBeam:IsA("BasePart") then
                                v59 = {
                                    ["Parent"] = nil,
                                    ["Attachment0"] = nil,
                                    ["Attachment1"] = nil
                                }
                                if v_u_9.GunBeam[v_u_42].GunBeam:FindFirstChild("Different_GunBeam") then
                                    if v_u_9.GunBeam[v_u_42].GunBeam.Different_GunBeam[v60].GunBeam:IsA("BasePart") then
                                        v_u_58 = v_u_9.GunBeam[v_u_42].GunBeam.Different_GunBeam[v60].GunBeam:Clone()
                                    else
                                        v59 = v_u_9.GunBeam[v_u_42].GunBeam.Different_GunBeam[v60].GunBeam:Clone()
                                    end
                                else
                                    v_u_58 = v_u_9.GunBeam[v_u_42].GunBeam:Clone()
                                end
                            else
                                v59 = v_u_9.GunBeam[v_u_42].GunBeam:Clone()
                            end
                        else
                            v59 = game.ReplicatedStorage.GunBeam:Clone()
                            v59.Color = v38 and ColorSequence.new(v38) or v59.Color
                        end
                    else
                        v59 = game.ReplicatedStorage.GunBeam:Clone()
                        v59.Color = v38 and ColorSequence.new(v38) or v59.Color
                    end
                else
                    v59 = nil
                end
                task.spawn(function()
                    if v_u_58 then
                        local v67 = (v_u_50 - v_u_44).magnitude
                        local v68 = v67 / 725
                        v_u_58.Anchored = true
                        v_u_58.CanCollide = false
                        v_u_58.CanQuery = false
                        v_u_58.CFrame = CFrame.new(v_u_44, v_u_50)
                        local v69 = v_u_58.CFrame * CFrame.new(0, 0, -v67)
                        v_u_58.Parent = game.Workspace.Ignored.Siren.Radius
                        task.delay(v68 + 5, function()
                            v_u_58:Destroy()
                            v_u_58 = nil
                        end)
                        if v_u_58:GetAttribute("SpecialEffects") then
                            for _, v70 in pairs(v_u_58:GetDescendants()) do
                                if v70:IsA("Trail") and v70:GetAttribute("ColorRandom") then
                                    local v71 = v70:GetAttribute("ColorRandom")
                                    v70.Color = ColorSequence.new(ColorTransform(v71, math.random()))
                                end
                            end
                        end
                        local v72 = game:GetService("TweenService"):Create(v_u_58, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {
                            ["CFrame"] = v_u_58.CFrame * CFrame.new(0, 0, -0.1)
                        })
                        v72:Play()
                        task.wait(0.05)
                        if v72.PlaybackState ~= Enum.PlaybackState.Completed then
                            v72:Pause()
                        end
                        local v73 = nil
                        if _G.Reduce_Lag and not v_u_58:GetAttribute("NoSlow") or v_u_58:GetAttribute("LOWGFX") then
                            v_u_58.CFrame = v69
                        else
                            v73 = game:GetService("TweenService"):Create(v_u_58, TweenInfo.new(v68, Enum.EasingStyle.Linear), {
                                ["CFrame"] = v69
                            })
                            v73:Play()
                            task.wait(v68)
                        end
                        if v_u_58:FindFirstChild("Impact") and (v_u_49 and (v_u_51 and not v_u_49.Parent:FindFirstChild("Humanoid"))) then
                            if v73 and v73.PlaybackState ~= Enum.PlaybackState.Completed then
                                task.wait(0.05)
                            end
                            if not v_u_58:FindFirstChild("NoNormal") then
                                v_u_58.CFrame = CFrame.new(v_u_50, v_u_50 - v_u_51)
                            end
                            for _, v74 in pairs(v_u_58.Impact:GetChildren()) do
                                if v74:IsA("ParticleEmitter") then
                                    v74:Emit(v74:GetAttribute("EmitCount") or 1)
                                end
                            end
                        else
                            for _, v75 in pairs(v_u_58:GetChildren()) do
                                if v75:IsA("BasePart") then
                                    v75.Transparency = 1
                                end
                            end
                        end
                        if v_u_58 then
                            for _, v76 in pairs(v_u_58:GetDescendants()) do
                                if v76:IsA("ParticleEmitter") then
                                    v76.Enabled = false
                                end
                            end
                        end
                    elseif v_u_49 and (v_u_49:IsDescendantOf(game.Workspace.MAP) and (v_u_42 and (v_u_9.GunBeam:FindFirstChild(v_u_42) and v_u_9.GunBeam[v_u_42]:FindFirstChild("Impact")))) then
                        local v_u_77 = v_u_9.GunBeam[v_u_42].Impact:Clone()
                        v_u_77.Parent = game.Workspace.Ignored
                        v_u_77:PivotTo(CFrame.new(v_u_50, v_u_50 + v_u_51 * 5) * CFrame.Angles(-1.5707963267948966, 0, 0))
                        for _, v78 in pairs(v_u_77:GetDescendants()) do
                            if v78:IsA("ParticleEmitter") then
                                v78:Emit(v78:GetAttribute("EmitCount") or 1)
                            end
                        end
                        task.delay(1.5, function()
                            v_u_77:Destroy()
                            v_u_77 = nil
                        end)
                    end
                    local v79 = Instance.new("PointLight")
                    v79.Brightness = 0.5
                    v79.Range = 15
                    v79.Shadows = true
                    v79.Color = Color3.new(1, 1, 1)
                    v79.Parent = v_u_53
                    local v80 = v_u_36:FindFirstChild("ShootBBGUI")
                    local v81 = v80 and (not v_u_57 and v80:FindFirstChild("Shoot"))
                    if v81 then
                        v81.Size = UDim2.new(0, 0, 0, 0)
                        v81.ImageTransparency = 1
                        v81.Visible = true
                        v_u_5:Create(v81, TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.In, 0, false, 0), {
                            ["Size"] = UDim2.new(1, 0, 1, 0),
                            ["ImageTransparency"] = 0.4
                        }):Play()
                        v_u_5:Create(v79, TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.In, 0, false, 0), {
                            ["Range"] = 0
                        }):Play()
                        wait(0.4)
                        v_u_53:Destroy()
                        v_u_5:Create(v81, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.In, 0, false, 0), {
                            ["Size"] = UDim2.new(1, 0, 1, 0),
                            ["ImageTransparency"] = 1
                        }):Play()
                        wait(0.2)
                        v81.Visible = false
                    end
                end)
                v59.Attachment0 = v54
                v59.Attachment1 = v55
                v59.Name = "NewGunBeam"
                v59.Parent = v_u_53
                if v35 == v_u_7.Character and game.Workspace:GetServerTimeNow() - v_u_13 > 0.95 then
                    Animate(v_u_36)
                end
                local playsound = function(p1, p2)
                    local v3 = p1.ShootSound:GetAttribute("SequenceSFX")
                    if v3 then
                        if p1.ShootSound:GetAttribute("CurrentSequence") == nil then
                            p1.ShootSound:SetAttribute("CurrentSequence", 1)
                        else
                            p1.ShootSound:SetAttribute("CurrentSequence", p1.ShootSound:GetAttribute("CurrentSequence") + 1)
                        end
                        local v4 = p1.ShootSound:GetAttribute("CurrentSequence")
                        local v5 = {}
                        for v6 in string.gmatch(v3, "%d+") do
                            table.insert(v5, v6)
                        end
                        p1.ShootSound.SoundId = "rbxassetid://" .. v5[v4 % #v5 + 1]
                    end
                    if p2 then
                        local v_u_7 = p1.ShootSound:Clone()
                        v_u_7.Name = "MG"
                        v_u_7.Parent = p1
                        v_u_7:Play()
                        delay(1, function()
                            v_u_7:Destroy()
                        end)
                    else
                        p1.ShootSound:Play()
                    end
                end
                if not SoundsPlaying[v_u_36] then
                    task.spawn(playsound, v_u_36, true)
                    SoundsPlaying[v_u_36] = true
                    task.delay(0.021, function()
                        SoundsPlaying[v_u_36] = nil
                    end)
                end
                if game.Lighting:GetAttribute("printhits") then
                    local v82 = print
                    local v83 = v_u_49
                    if v83 then
                        v83 = v_u_49:GetFullName()
                    end
                    v82(v83)
                end
                return v_u_50, v_u_49, v_u_51
            end
            return {
                CanShoot = CanShoot,
                Animate = Animate,
                GetAim = GetAim,
                ColorTransform = ColorTransform,
                ShootGun = ShootGun,
            }
        else
            return {}
        end
    end
end
do
    SetRegion("Main")
    local DaHood = Modules.Get("DaHood")
    function Script:GetClosestPointOnScreen(Character)
        local mousePos = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local raycastParams = RaycastParams.new()
        local ignoreList = {Self.Character, TriggerPart, SilentAimPart}
        raycastParams.FilterDescendantsInstances = ignoreList
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
        if result and result.Instance and result.Instance:IsDescendantOf(Character) then
            return result.Position
        end
        return nil
    end
    function Script:GetClosestPointOnPart(Part, Scale)
        local PartCFrame = Part.CFrame
        local PartSize = Part.Size
        local PartSizeTransformed = PartSize * (Scale / 2)
        local MousePosition = UserInputService:GetMouseLocation()
        local CurrentCamera = Workspace.CurrentCamera
        local MouseRay = CurrentCamera:ViewportPointToRay(MousePosition.X, MousePosition.Y)
        local Transformed = PartCFrame:PointToObjectSpace(MouseRay.Origin + (MouseRay.Direction * MouseRay.Direction:Dot(PartCFrame.Position - MouseRay.Origin)))
        if (Mouse.Target == Part) then
            return Vector3.new(Mouse.Hit.X, Mouse.Hit.Y, Mouse.Hit.Z)
        end
        return PartCFrame * Vector3.new(
            math.clamp(Transformed.X, -PartSizeTransformed.X, PartSizeTransformed.X),
            math.clamp(Transformed.Y, -PartSizeTransformed.Y, PartSizeTransformed.Y),
            math.clamp(Transformed.Z, -PartSizeTransformed.Z, PartSizeTransformed.Z)
        )
    end
    function Script:GetClosestPointOnPartBasic(Part)
        if Part then
            local MouseRay = Mouse.UnitRay
            MouseRay = MouseRay.Origin + (MouseRay.Direction * (Part.Position - MouseRay.Origin).Magnitude)
            local Point = (MouseRay.Y >= (Part.Position - Part.Size / 2).Y and MouseRay.Y <= (Part.Position + Part.Size / 2).Y) and (Part.Position + Vector3.new(0, -Part.Position.Y + MouseRay.Y, 0)) or Part.Position
            local Check = RaycastParams.new()
            Check.FilterType = Enum.RaycastFilterType.Whitelist
            Check.FilterDescendantsInstances = {Part}
            local Ray = Workspace:Raycast(MouseRay, (Point - MouseRay), Check)
            if Mouse.Target == Part then
                return Mouse.Hit.Position
            end
            if Ray then
                return Ray.Position
            else
                return Mouse.Hit.Position
            end
        end
    end
    function Script:GetClosestPartToCursor(Character)
        local CurrentCamera = Workspace.CurrentCamera
        local Closest
        local Distance = 1/0
        for _, Part in ipairs(Character:GetChildren()) do
            if (not Part:IsA("BasePart")) then
                continue
            end
            local Position = CurrentCamera:WorldToViewportPoint(Part.Position)
            Position = Vector2.new(Position.X, Position.Y)
            local Magnitude = (UserInputService:GetMouseLocation() - Position).Magnitude
            if (Magnitude < Distance) then
                Closest = Part
                Distance = Magnitude
            end
        end
        return Closest
    end
    function Script:GetClosestPartToCursorFilter(Character, PartsToCheck)
        local CurrentCamera = Workspace.CurrentCamera
        local Closest
        local Distance = 1/0
        for _, Part in ipairs(Character:GetChildren()) do
            if not Part:IsA("BasePart") or (PartsToCheck and not table.find(PartsToCheck, Part.Name)) then
                continue
            end
            local Position = CurrentCamera:WorldToViewportPoint(Part.Position)
            Position = Vector2.new(Position.X, Position.Y)
            local Magnitude = (UserInputService:GetMouseLocation() - Position).Magnitude
            if Magnitude < Distance then
                Closest = Part
                Distance = Magnitude
            end
        end
        return Closest
    end
    function Script:ApplyNormalPredictionFormula(Humanoid, Position, Velocity)
        local IsInAir = Humanoid:GetState() == Enum.HumanoidStateType.Freefall or Humanoid:GetState() == Enum.HumanoidStateType.Jumping
        local TargetVelocity = Velocity
        local PredictionVelocity = Vector3.new(TargetVelocity.X, 0, TargetVelocity.Z) * Vector3.new(shared.xvory.Silent.Prediction.x, shared.xvory.Silent.Prediction.y, shared.xvory.Silent.Prediction.z)
        local Gravity = Workspace.Gravity
        if IsInAir then
            local TimeToHit = 2 * PredictionVelocity.Y / Gravity
            local GravityAdjustment = Vector3.new(0, -0.5 * Gravity * TimeToHit * TimeToHit, 0)
            PredictionVelocity = PredictionVelocity + GravityAdjustment
        end
        local ClosestPoint = Position
        local PredictedCFrame = ClosestPoint + PredictionVelocity
        return Vector3.new(PredictedCFrame.X, PredictedCFrame.Y, PredictedCFrame.Z)
    end
    function Script:ApplyRecalculatedPredictionFormula(RootPart, Position)
        local PredictionVelocity = Script:GetResolvedVelocity(RootPart) * Vector3.new(shared.xvory.Silent.Prediction.x, shared.xvory.Silent.Prediction.y, shared.xvory.Silent.Prediction.z)
        local PredictedCFrame = Position + PredictionVelocity
        return PredictedCFrame
    end
    function Script:GetResolvedVelocity(Part)
        local LastPosition = Part.Position
        task.wait(0.085)
        local CurrentPosition = Part.Position
        local Velocity = (CurrentPosition - LastPosition) / 0.085
        return Velocity
    end
    local smoothedVelocity = Vector3.new(0, 0, 0)
    local function getDynamicSmoothingFactor(velocityMagnitude)
        if velocityMagnitude < 5 then
            return 0.05
        elseif velocityMagnitude < 20 then
            return 0.1
        else
            return 0.2
        end
    end
    local function GetResolvedVelocity(Part)
        local LastPosition = Part.Position
        task.wait(0.085)
        local CurrentPosition = Part.Position
        local Velocity = (CurrentPosition - LastPosition) / 0.085
        local velocityMagnitude = Velocity.Magnitude
        local dynamicSmoothing = getDynamicSmoothingFactor(velocityMagnitude)
        smoothedVelocity = smoothedVelocity * (1 - dynamicSmoothing) + Velocity * dynamicSmoothing
        return smoothedVelocity * Vector3.new(1, 0, 1)
    end
    function Script:GetHitPosition(Mode)
        if Mode == "Silent" then
            local Config = shared.xvory.Silent
            local Object = Script.Locals.SilentAimTarget.Character
            if not Object then return end
            local Humanoid = Object:FindFirstChild("Humanoid")
            if not Humanoid then return end
            local HitPosition
            local HitPart = Config["Hit Part"]
            if HitPart == "Closest Point" then
                local screenHit = Script:GetClosestPointOnScreen(Object)
                if screenHit then
                    HitPosition = screenHit
                else
                    local NearestPart = Script:GetClosestPartToCursor(Object)
                    if Config["Closest Point"].Mode == "Advanced" then
                        HitPosition = Script:GetClosestPointOnPart(NearestPart, Config["Closest Point"].Scale)
                    else
                        HitPosition = Script:GetClosestPointOnPartBasic(NearestPart)
                    end
                end
            elseif HitPart == "Closest Part" then
                local NearestPart = Script:GetClosestPartToCursor(Object)
                HitPosition = NearestPart.Position
            elseif type(HitPart) == "table" then
                local NearestPart = Script:GetClosestPartToCursorFilter(Object, HitPart)
                HitPosition = NearestPart.Position
            else
                HitPosition = Object[HitPart].Position
            end
            if Config.Prediction.Enabled then
                if Config.Prediction.Mode == "HitScan" then
                    local RootPart = Object.HumanoidRootPart
                    return HitPosition + GetResolvedVelocity(RootPart) * Vector3.new(Config.Prediction.x, Config.Prediction.y, Config.Prediction.x)
                else
                    return Script:ApplyNormalPredictionFormula(Humanoid, HitPosition, Object.HumanoidRootPart.Velocity)
                end
            else
                return HitPosition
            end
        end
        return nil
    end
    function Script:ShouldShoot(Target)
        if not Target then
            SilentAimPart.Position = Vector3.zero
            return false
        end
        if not Target.Character then
            SilentAimPart.Position = Vector3.zero
            return false
        end
        local allConditionsPassed = true
        local silentConfig = shared.xvory.Silent
        if not silentConfig.Enabled then
            allConditionsPassed = false
            SilentAimPart.Position = Vector3.zero
        end
        local cond = silentConfig.Conditions
        if cond.Visible then
            if not Script:RayCast(Target.Character.HumanoidRootPart, Script:GetOrigin("Camera"), {Self.Character, TriggerPart, SilentAimPart}) then
                allConditionsPassed = false
                SilentAimPart.Position = Vector3.zero
            end
        end
        if cond.knocked and CurrentGame.Functions.IsKnocked(Target.Character) then
            allConditionsPassed = false
            SilentAimPart.Position = Vector3.zero
        end
        if cond["Self Knocked"] and CurrentGame.Functions.IsKnocked(Self.Character) then
            allConditionsPassed = false
            SilentAimPart.Position = Vector3.zero
        end
        if cond.Grabbed and CurrentGame.Functions.IsGrabbed(Target) then
            allConditionsPassed = false
            SilentAimPart.Position = Vector3.zero
        end
        local screen, _ = Camera:WorldToViewportPoint(Script.Locals.HitPosition)
        local DistanceX = math.abs(screen.X - Mouse.X)
        local DistanceY = math.abs(screen.Y - Mouse.Y)
        if silentConfig.Fov.Enabled and (DistanceX^2 + DistanceY^2) > (SilentFOVRadius)^2 then
            allConditionsPassed = false
        end
        return allConditionsPassed
    end
    local Ticks = {}
    local SGTick = tick()
    function Script:GetGunCategory()
        if Self and Self.Character then
            local Tool = Self.Character:FindFirstChildWhichIsA("Tool")
            if Tool then
                if table.find(WeaponInfo.Shotguns, Tool.Name) then
                    return "Shotgun"
                end
                if table.find(WeaponInfo.Pistols, Tool.Name) then
                    return "Pistol"
                end
                if table.find(WeaponInfo.Rifles, Tool.Name) then
                    return "Rifle"
                end
                if table.find(WeaponInfo.Bursts, Tool.Name) then
                    return "Burst"
                end
                if table.find(WeaponInfo.SMG, Tool.Name) then
                    return "SMG"
                end
                if table.find(WeaponInfo.Snipers, Tool.Name) then
                    return "Sniper"
                end
                if table.find(WeaponInfo.AutoShotguns, Tool.Name) then
                    return "Auto"
                end
            end
        end
        return nil
    end
    function Script:silentFunc(Tool)
        if string.find(GameName, "Dee Hood") or string.find(GameName, "Der Hood") and shared.xvory.Silent.Enabled then
            if Script.Locals.SilentAimTarget and Script.Locals.SilentAimTarget.Character then
                local Player = Script.Locals.SilentAimTarget
                local Character = Player.Character
                local Position, OnScreen = Camera:WorldToViewportPoint(Script.Locals.HitPosition)
                if not OnScreen then
                    return
                end
                if Script:ShouldShoot(Script.Locals.SilentAimTarget) then
                    local Remote = CurrentGame.RemotePath()
                    if Remote then
                        local Arguments = {
                            [1] = CurrentGame.Updater,
                            [2] = Script.Locals.HitPosition
                        }
                        Remote:FireServer(unpack(Arguments))
                    end
                else
                    SilentAimPart.Position = Vector3.zero
                end
            end
        else
            if string.find(GameName, "Da Hood") then
                if not Ticks[Tool.Name] then
                    Ticks[Tool.Name] = 0
                end
                local WeaponOffset = WeaponInfo.Offsets[Tool.Name]
                local Gun = Script:GetGunCategory()
                local ToolHandle = Tool:WaitForChild("Handle")
                local LocalCharacter = Self.Character or Self.CharacterAdded:Wait()
                local Cooldown = Tool:WaitForChild("ShootingCooldown").Value
                local NoClueWhatThisIs = game.PlaceId == 88976059384565 and { ["Value"] = 5 } or Tool.Ammo
                local Time = game.Workspace:GetServerTimeNow()
                local Check = tick() - Ticks[Tool.Name] >= Cooldown
                local ToolEvent = Tool:WaitForChild("RemoteEvent", 2) or { ["FireServer"] = function(_, _) end }
                local DoubleTap = shared.xvory.Weapon["2Tap"].Enabled and Script.Locals.IsDoubleTapping
                local BeamCol = Color3.new(1, 0.545098, 0.14902)
                local function ShootFunc(GunType, SilentAim)
                    if GunType == "Shotgun" then
                        if Check and (NoClueWhatThisIs.Value >= 1 and (not _G.GUN_COMBAT_TOGGLE and DaHood.CanShoot(Self.Character))) then
                            Ticks[Tool.Name] = tick()
                            ToolEvent:FireServer("Shoot")
                            for _ = 1, 5 do
                                local HitPosition = Script.Locals.HitPosition
                                local SpreadX, SpreadY, SpreadZ
                                if shared.xvory.Weapon["Bullet Spread"].Enabled then
                                    local spreadReduction = shared.xvory.Weapon["Bullet Spread"].Value or 1
                                    local randomizer = shared.xvory.Weapon["Bullet Spread"].Randomizer
                                    spreadReduction = math.clamp(spreadReduction, 0, 1)
                                    local spreadFactor = spreadReduction
                                    if randomizer.Enabled then
                                        spreadFactor = spreadFactor * (1 - math.random() * randomizer.Value)
                                    end
                                    SpreadX = math.random() > 0.5 and math.random() * 0.05 * spreadFactor or -math.random() * 0.05 * spreadFactor
                                    SpreadY = math.random() > 0.5 and math.random() * 0.1 * spreadFactor or -math.random() * 0.1 * spreadFactor
                                    SpreadZ = math.random() > 0.5 and math.random() * 0.05 * spreadFactor or -math.random() * 0.05 * spreadFactor
                                else
                                    SpreadX = math.random() > 0.5 and math.random() * 0.05 or -math.random() * 0.05
                                    SpreadY = math.random() > 0.5 and math.random() * 0.1 or -math.random() * 0.1
                                    SpreadZ = math.random() > 0.5 and math.random() * 0.05 or -math.random() * 0.05
                                end
                                local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or { ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position }
                                local TotalSpread = Vector3.new(SpreadX, SpreadY, SpreadZ)
                                local AimPosition
                                local WeaponRange = Tool:FindFirstChild("Range")
                                local effectiveRange = WeaponRange and WeaponRange.Value or 200
                                if SilentAim then
                                    AimPosition = ForcedOrigin.WorldPosition + ((HitPosition - ForcedOrigin.WorldPosition).Unit + TotalSpread) * 10000
                                else
                                    AimPosition = ForcedOrigin.WorldPosition + (DaHood.GetAim(ForcedOrigin.WorldPosition) + TotalSpread) * 10000
                                end
                                local Arg0, Arg1, Arg2 = DaHood.ShootGun({
                                    ["Shooter"] = LocalCharacter,
                                    ["Handle"] = ToolHandle,
                                    ["AimPosition"] = AimPosition,
                                    ["BeamColor"] = BeamCol,
                                    ["ForcedOrigin"] = ForcedOrigin.WorldPosition,
                                    ["LegitPosition"] = ForcedOrigin.WorldPosition + (DaHood.GetAim(ForcedOrigin.WorldPosition) + TotalSpread) * effectiveRange,
                                    ["Range"] = effectiveRange
                                })
                                ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, Arg0, Arg1, Arg2, Time)
                            end
                            ToolEvent:FireServer()
                        end
                    elseif Gun == "Pistol" then
                        if Check and (NoClueWhatThisIs.Value >= 1 and (not _G.GUN_COMBAT_TOGGLE and DaHood.CanShoot(Self.Character))) then
                            Ticks[Tool.Name] = tick()
                            local HitPosition = Script.Locals.HitPosition
                            if DoubleTap then
                                ToolEvent:FireServer("Shoot")
                                Script.Locals.DoubleTapState = true
                                local AimPosition
                                local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or { ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position }
                                local WeaponRange = Tool:WaitForChild("Range")
                                local effectiveRange = WeaponRange.Value
                                if SilentAim and (Self.Character.HumanoidRootPart.Position - Script.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < effectiveRange then
                                    AimPosition = HitPosition
                                else
                                    AimPosition = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200
                                end
                                local Arg0, Arg1, Arg2 = DaHood.ShootGun({
                                    ["Shooter"] = LocalCharacter,
                                    ["Handle"] = ToolHandle,
                                    ["ForcedOrigin"] = ForcedOrigin.WorldPosition or (ToolHandle.CFrame * WeaponOffset).Position,
                                    ["AimPosition"] = AimPosition,
                                    ["BeamColor"] = BeamCol,
                                    ["LegitPosition"] = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200,
                                    ["Range"] = effectiveRange
                                })
                                ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, Arg0, Arg1, Arg2)
                                ToolEvent:FireServer()
                                Script.Locals.DoubleTapState = false
                            end
                            ToolEvent:FireServer("Shoot")
                            local AimPosition
                            local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or { ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position }
                            local WeaponRange = Tool:WaitForChild("Range")
                            local effectiveRange = WeaponRange.Value
                            if SilentAim and (Self.Character.HumanoidRootPart.Position - Script.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < effectiveRange then
                                AimPosition = HitPosition
                            else
                                AimPosition = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200
                            end
                            local Arg0, Arg1, Arg2 = DaHood.ShootGun({
                                ["Shooter"] = LocalCharacter,
                                ["Handle"] = ToolHandle,
                                ["ForcedOrigin"] = ForcedOrigin.WorldPosition or (ToolHandle.CFrame * WeaponOffset).Position,
                                ["AimPosition"] = AimPosition,
                                ["BeamColor"] = BeamCol,
                                ["LegitPosition"] = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200,
                                ["Range"] = effectiveRange
                            })
                            ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, Arg0, Arg1, Arg2)
                            ToolEvent:FireServer()
                        end
                    elseif Gun == "Auto" then
                        if Check and (not _G.GUN_COMBAT_TOGGLE and DaHood.CanShoot(LocalCharacter)) then
                            Ticks[Tool.Name] = tick()
                            ToolEvent:FireServer("Shoot")
                            local Flag = true
                            task.spawn(function()
                                while Flag and (Tool.Parent == LocalCharacter and (NoClueWhatThisIs.Value > 0 and DaHood.CanShoot(LocalCharacter))) do
                                    local HitPosition = Script.Locals.HitPosition
                                    local CurrentTime = game.Workspace:GetServerTimeNow()
                                    for _ = 1, 5 do
                                        local SpreadX, SpreadY, SpreadZ
                                        if shared.xvory.Weapon["Bullet Spread"].Enabled then
                                            local spreadReduction = shared.xvory.Weapon["Bullet Spread"].Value or 1
                                            local randomizer = shared.xvory.Weapon["Bullet Spread"].Randomizer
                                            spreadReduction = math.clamp(spreadReduction, 0, 1)
                                            local spreadFactor = spreadReduction
                                            if randomizer.Enabled then
                                                spreadFactor = spreadFactor * (1 - math.random() * randomizer.Value)
                                            end
                                            SpreadX = math.random() > 0.5 and math.random() * 0.05 * spreadFactor or -math.random() * 0.05 * spreadFactor
                                            SpreadY = math.random() > 0.5 and math.random() * 0.1 * spreadFactor or -math.random() * 0.1 * spreadFactor
                                            SpreadZ = math.random() > 0.5 and math.random() * 0.05 * spreadFactor or -math.random() * 0.05 * spreadFactor
                                        else
                                            SpreadX = math.random() > 0.5 and math.random() * 0.05 or -math.random() * 0.05
                                            SpreadY = math.random() > 0.5 and math.random() * 0.1 or -math.random() * 0.1
                                            SpreadZ = math.random() > 0.5 and math.random() * 0.05 or -math.random() * 0.05
                                        end
                                        local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or { ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position }
                                        local TotalSpread = Vector3.new(SpreadX, SpreadY, SpreadZ)
                                        local AimPosition
                                        local WeaponRange = Tool:WaitForChild("Range")
                                        local effectiveRange = WeaponRange.Value
                                        if SilentAim and (Self.Character.HumanoidRootPart.Position - Script.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < effectiveRange then
                                            AimPosition = ForcedOrigin.WorldPosition + ((HitPosition - ForcedOrigin.WorldPosition).Unit + TotalSpread) * effectiveRange
                                        else
                                            AimPosition = ForcedOrigin.WorldPosition + (DaHood.GetAim(ForcedOrigin.WorldPosition) + TotalSpread) * effectiveRange
                                        end
                                        local Arg0, Arg1, Arg2 = DaHood.ShootGun({
                                            ["Shooter"] = LocalCharacter,
                                            ["Handle"] = ToolHandle,
                                            ["AimPosition"] = AimPosition,
                                            ["BeamColor"] = BeamCol,
                                            ["ForcedOrigin"] = ForcedOrigin.WorldPosition,
                                            ["LegitPosition"] = ForcedOrigin.WorldPosition + (DaHood.GetAim(ForcedOrigin.WorldPosition) + TotalSpread) * effectiveRange,
                                            ["Range"] = effectiveRange
                                        })
                                        ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, Arg0, Arg1, Arg2, CurrentTime)
                                    end
                                    local waitTime = Cooldown
                                    task.wait(waitTime)
                                    Ticks[Tool.Name] = tick()
                                end
                                ToolEvent:FireServer()
                            end)
                            Tool.Deactivated:Wait()
                            Flag = false
                        end
                    elseif Gun == "Burst" then
                        local Tolerance = Tool:WaitForChild("ToleranceCooldown").Value
                        local ShootingCool = Tool:WaitForChild("ShootingCooldown").Value
                        if tick() - Ticks[Tool.Name] >= Tolerance and (not _G.GUN_COMBAT_TOGGLE and DaHood.CanShoot(LocalCharacter)) then
                            Ticks[Tool.Name] = tick()
                            ToolEvent:FireServer("Shoot")
                            game.Workspace:GetServerTimeNow()
                            task.spawn(function()
                                for _ = 1, NoClueWhatThisIs.Value > 3 and 3 or NoClueWhatThisIs.Value do
                                    local HitPosition = Script.Locals.HitPosition
                                    local v17
                                    local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or { ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position }
                                    local WeaponRange = Tool:WaitForChild("Range")
                                    local effectiveRange = WeaponRange.Value
                                    if SilentAim and (Self.Character.HumanoidRootPart.Position - Script.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < effectiveRange then
                                        v17 = ForcedOrigin.WorldPosition + ((HitPosition - ForcedOrigin.WorldPosition).Unit) * 200
                                    else
                                        v17 = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200
                                    end
                                    local v18, v19, v20 = DaHood.ShootGun({
                                        ["Shooter"] = LocalCharacter,
                                        ["Handle"] = ToolHandle,
                                        ["ForcedOrigin"] = ForcedOrigin.WorldPosition,
                                        ["AimPosition"] = v17,
                                        ["LegitPosition"] = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200,
                                        ["BeamColor"] = BeamCol,
                                        ["Range"] = effectiveRange
                                    })
                                    ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, v18, v19, v20)
                                    task.wait(ShootingCool + 0.0095)
                                end
                                ToolEvent:FireServer()
                            end)
                        end
                    elseif Gun == "Rifle" or GunType == "SMG" then
                        local ShootingCool = Tool:WaitForChild("ShootingCooldown").Value
                        if Check and (not _G.GUN_COMBAT_TOGGLE and DaHood.CanShoot(LocalCharacter)) then
                            Ticks[Tool.Name] = tick()
                            ToolEvent:FireServer("Shoot")
                            local Flag = true
                            task.spawn(function()
                                while task.wait(ShootingCool + 0.0095) and (Flag and (Tool.Parent == LocalCharacter and (NoClueWhatThisIs.Value > 0 and DaHood.CanShoot(LocalCharacter)))) do
                                    local HitPosition = Script.Locals.HitPosition
                                    local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or { ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position }
                                    local AimPosition
                                    local WeaponRange = Tool:WaitForChild("Range")
                                    local effectiveRange = WeaponRange.Value
                                    if SilentAim and (Self.Character.HumanoidRootPart.Position - Script.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < effectiveRange then
                                        AimPosition = ForcedOrigin.WorldPosition + ((HitPosition - ForcedOrigin.WorldPosition).Unit) * 200
                                    else
                                        AimPosition = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200
                                    end
                                    local v18, v19, v20 = DaHood.ShootGun({
                                        ["Shooter"] = LocalCharacter,
                                        ["Handle"] = ToolHandle,
                                        ["ForcedOrigin"] = ForcedOrigin.WorldPosition,
                                        ["AimPosition"] = AimPosition,
                                        ["LegitPosition"] = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 200,
                                        ["BeamColor"] = BeamCol,
                                        ["Range"] = effectiveRange
                                    })
                                    ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, v18, v19, v20)
                                    Ticks[Tool.Name] = tick()
                                end
                                ToolEvent:FireServer()
                            end)
                            Tool.Deactivated:Wait()
                            Flag = false
                        end
                    elseif Gun == "Sniper" then
                        if Check and (not _G.GUN_COMBAT_TOGGLE and DaHood.CanShoot(LocalCharacter)) then
                            Ticks[Tool.Name] = tick()
                            ToolEvent:FireServer("Shoot")
                            local HitPosition = Script.Locals.HitPosition
                            local ForcedOrigin = Tool:FindFirstChild("Default") and (Tool.Default:FindFirstChild("Mesh") and Tool.Default.Mesh:FindFirstChild("Muzzle")) or { ["WorldPosition"] = (ToolHandle.CFrame * WeaponOffset).Position }
                            local AimPosition
                            local WeaponRange = Tool:WaitForChild("Range")
                            local effectiveRange = WeaponRange.Value
                            if SilentAim and (Self.Character.HumanoidRootPart.Position - Script.Locals.SilentAimTarget.Character.HumanoidRootPart.Position).Magnitude < effectiveRange then
                                AimPosition = ForcedOrigin.WorldPosition + ((HitPosition - ForcedOrigin.WorldPosition).Unit) * 50
                            else
                                AimPosition = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 50
                            end
                            local v16, v17, v18 = DaHood.ShootGun({
                                ["Shooter"] = LocalCharacter,
                                ["Handle"] = ToolHandle,
                                ["ForcedOrigin"] = ForcedOrigin.WorldPosition,
                                ["AimPosition"] = AimPosition,
                                ["LegitPosition"] = ForcedOrigin.WorldPosition + DaHood.GetAim(ForcedOrigin.WorldPosition) * 50,
                                ["BeamColor"] = BeamCol,
                                ["Range"] = effectiveRange
                            })
                            ReplicatedStorage.MainEvent:FireServer("ShootGun", ToolHandle, ForcedOrigin.WorldPosition, v16, v17, v18)
                            ToolEvent:FireServer()
                        end
                    end
                end
                local isSelectMode = shared.xvory.Silent.Mode == "Target"
                if shared.xvory.Silent.Enabled and Script.Locals.SilentAimTarget and Script.Locals.SilentAimTarget.Character then
                    local target = Script.Locals.SilentAimTarget
                    local shouldShoot = (isSelectMode and shared.xvory.forceTrigger) or Script:ShouldShoot(target)
                    ShootFunc(Gun, shouldShoot)
                else
                    ShootFunc(Gun, false)
                end
            end
        end
    end
    function Script:Camlock()
        local camlockConfig = shared.xvory.Camlock
        if not camlockConfig.Enabled then return end
        local targetPlayer = Script.Locals.SilentAimTarget
        if not targetPlayer then return end
        local target = targetPlayer.Character
        if not target then return end
        local cond = camlockConfig.Conditions
        if cond.Visible then
            if not Script:RayCast(target.HumanoidRootPart, Script:GetOrigin("Camera"), {Self.Character, TriggerPart, SilentAimPart}) then
                return
            end
        end
        if cond.knocked and CurrentGame.Functions.IsKnocked(targetPlayer.Character) then
            return
        end
        if cond["Self Knocked"] and CurrentGame.Functions.IsKnocked(Self.Character) then
            return
        end
        if cond.Grabbed and CurrentGame.Functions.IsGrabbed(targetPlayer) then
            return
        end
        local hitPart = target:FindFirstChild(camlockConfig.HitPart)
        if not hitPart then hitPart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head") end
        if not hitPart then return end
        if camlockConfig.Fov.Enabled then
            local camFovSize = camlockConfig.Fov.Size
            local targetScreenPos, onScreen = Camera:WorldToViewportPoint(hitPart.Position)
            if not onScreen then return end
            local mousePos = UserInputService:GetMouseLocation()
            local dist = (Vector2.new(targetScreenPos.X, targetScreenPos.Y) - mousePos).Magnitude
            if dist > camFovSize then return end
        end
        local targetPos = hitPart.Position
        if camlockConfig.Pred.Enabled then
            local root = target:FindFirstChild("HumanoidRootPart")
            if root then
                local vel = root.Velocity
                targetPos = targetPos + Vector3.new(vel.X * camlockConfig.Pred.X, vel.Y * camlockConfig.Pred.Y, vel.Z * camlockConfig.Pred.Z)
            end
        end
        local currentCF = Camera.CFrame
        local newCF = CFrame.new(currentCF.Position, targetPos)
        local easing = camlockConfig.EasingMode
        local easingDir = camlockConfig.EasingDirection
        local smooth = TweenService:GetValue(camlockConfig.Sticky, Enum.EasingStyle[easing], Enum.EasingDirection[easingDir])
        Camera.CFrame = currentCF:Lerp(newCF, smooth)
    end
    local function ActivateTool()
        local Tool = Self.Character:FindFirstChildOfClass("Tool")
        if Tool ~= nil and Tool:IsDescendantOf(Self.Character) and Tool.Name ~= "[Knife]" then
            Tool:Activate()
        end
    end
    local function raycast(origin, direction, raycastParams)
        local result = workspace:Raycast(origin, direction, raycastParams)
        if result and result.Instance then
            if result.Instance ~= TriggerPart then
                origin = result.Position + direction.Unit * 0.1
                return raycast(origin, direction, raycastParams)
            else
                return result
            end
        end
        return nil
    end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
    raycastParams.FilterDescendantsInstances = {TriggerPart}
    function Script:triggerFunc()
        local triggerBotConfig = shared.xvory.Triggerbot
        local locals = Script.Locals
        local target = locals.TriggerbotTarget and locals.TriggerbotTarget.Character
        local scale = triggerBotConfig.Fov.Scale or 1.0
        local fovX = triggerBotConfig.Fov.X * scale
        local fovY = triggerBotConfig.Fov.Y * scale
        local fovZ = triggerBotConfig.Fov.Z * scale
        TriggerPart.Size = Vector3.new(fovX, fovY, fovZ)
        TriggerPart.Parent = game.Workspace
        TriggerPart.Anchored = true
        TriggerPart.CanCollide = false
        TriggerPart.Transparency = triggerBotConfig.Fov.Visible and 0.7 or 1
        TriggerPart.Color = Color3.new(1, 0, 0)
        local weaponAllowed = true
        if shared.xvory.Silent["Client Mode"].Enabled then
            local tool = Self.Character and Self.Character:FindFirstChildOfClass("Tool")
            if tool and not table.find(shared.xvory.Silent["Client Mode"].weapons, tool.Name) then
                weaponAllowed = false
            end
        end
        if not weaponAllowed then
            TriggerPart.Position = Vector3.zero
            return
        end
        local isSelectMode = triggerBotConfig.Mode == "Target"
        if target then
            local selfCharacter = Self.Character
            local tool = selfCharacter:FindFirstChildOfClass("Tool")
            if not tool or not tool:FindFirstChild("Ammo") or tool.Name == "[Knife]" then
                TriggerPart.Position = Vector3.zero
                return
            end
            if not (triggerBotConfig.Enabled and locals.TriggerState and target) then
                TriggerPart.Position = Vector3.zero
                return
            end
            if not CanTriggerbotShoot then
                TriggerPart.Position = Vector3.zero
                return
            end
            local cond = triggerBotConfig.Conditions
            local Player = locals.TriggerbotTarget
            if cond.Visible then
                if not Script:RayCast(TriggerPart, Script:GetOrigin("Camera"), {Self.Character, TriggerPart, SilentAimPart}) then
                    TriggerPart.Position = Vector3.zero
                    return
                end
            end
            if cond.knocked and CurrentGame.Functions.IsKnocked(Player.Character) then
                TriggerPart.Position = Vector3.zero
                return
            end
            if cond["Self Knocked"] and CurrentGame.Functions.IsKnocked(Self.Character) then
                TriggerPart.Position = Vector3.zero
                return
            end
            if cond.Grabbed and CurrentGame.Functions.IsGrabbed(Player) then
                TriggerPart.Position = Vector3.zero
                return
            end
            if cond.Chat and UserInputService:GetFocusedTextBox() then
                TriggerPart.Position = Vector3.zero
                return
            end
            local targetDistance = (selfCharacter.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude
            if targetDistance > triggerBotConfig["Max Dist"] then TriggerPart.Position = Vector3.zero return end
            local velocity = GetResolvedVelocity(target.HumanoidRootPart)
            local prediction = triggerBotConfig.Prediction
            if prediction.Enabled then
                TriggerPart.Position = target.HumanoidRootPart.Position + Vector3.new(velocity.X * prediction.Value, 0, velocity.Z * prediction.Value)
            else
                TriggerPart.Position = target.HumanoidRootPart.Position
            end
            local mouseLocation = UserInputService:GetMouseLocation()
            local ray = Camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
            local result = raycast(ray.Origin, ray.Direction * 1000, raycastParams)
            local currentTime = tick()
            if ((isSelectMode and shared.xvory.forceTrigger) or (result and result.Instance == TriggerPart)) and tool.Name ~= "[Knife]" then
                Script:TriggerShot(triggerBotConfig.Cooldown)
                LastTriggerTime = currentTime
                TriggerPart.Color = Color3.new(0, 1, 0)
            else
                TriggerPart.Color = Color3.new(1, 0, 0)
            end
        else
            TriggerPart.Position = Vector3.zero
        end
    end
    function Script:TriggerShot(interval)
        local locals = Script.Locals
        local currentTime = tick()
        if currentTime - locals.LastShot >= interval then
            locals.LastShot = currentTime
            ActivateTool()
        end
    end
    function Script:playerFunc()
        if not Self.Character then return end
        if shared.xvory["Player Modifications"]["Anti Fall"] then
            if Self.Character.Humanoid.Health > 1 and Self.Character.Humanoid:GetState() == Enum.HumanoidStateType.FallingDown then
                Self.Character.Humanoid:ChangeState("GettingUp")
            end
        end
    end
end
do
    local FieldOfViewCircle = Script.Visuals.new("Circle")
    FieldOfViewCircle.Color = Color3.fromRGB(255, 255, 255)
    FieldOfViewCircle.Thickness = 1
    FieldOfViewCircle.Transparency = 1
    Script.Locals.FieldOfViewTwo = FieldOfViewCircle
    local CamlockFOVCircle = Script.Visuals.new("Circle")
    CamlockFOVCircle.Color = Color3.fromRGB(0, 255, 0)
    CamlockFOVCircle.Thickness = 1
    CamlockFOVCircle.Transparency = 0.5
    local function UpdateDrawings()
        local Character = Self.Character
        if not Character then return end
        local Tool = Character:FindFirstChildWhichIsA("Tool")
        local silentFovConfig = shared.xvory.Silent.Fov
        local weaponConfigs = silentFovConfig["Weapon Configuration"]
        if weaponConfigs.Enabled and Tool then
            if table.find(WeaponInfo.Shotguns, Tool.Name) then
                SilentFOVRadius = weaponConfigs.Shotguns.circle
            elseif table.find(WeaponInfo.Pistols, Tool.Name) then
                SilentFOVRadius = weaponConfigs.Pistol.circle
            else
                SilentFOVRadius = weaponConfigs.Others.circle
            end
        else
            SilentFOVRadius = silentFovConfig.Circle
        end
        Script.Locals.FieldOfViewTwo.Visible = silentFovConfig.Enabled and silentFovConfig.Visible
        Script.Locals.FieldOfViewTwo.Radius = SilentFOVRadius
        Script.Locals.FieldOfViewTwo.Position = Vector2.new(Mouse.X, Mouse.Y + GuiInsetOffsetY)
        local camlockConfig = shared.xvory.Camlock
        CamlockFOVCircle.Visible = camlockConfig.Enabled and camlockConfig.Fov.Enabled and camlockConfig.Fov.Visible
        CamlockFOVCircle.Radius = camlockConfig.Fov.Size
        CamlockFOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiInsetOffsetY)
    end
    local Activated
    local function OnLocalCharacterAdded(Character)
        if (not Character) then
            return
        end
        Character.ChildAdded:Connect(function(Tool)
            if (not Tool:IsA("Tool")) then
                return
            end
            Activated = Tool.Activated:Connect(function()
                Script:silentFunc(Tool)
            end)
        end)
        Character.ChildRemoved:Connect(function(Tool)
            if (not Tool:IsA("Tool")) then
                return
            end
            if Activated then
                Activated:Disconnect()
            end
        end)
    end
    OnLocalCharacterAdded(Self.Character)
    Self.CharacterAdded:Connect(OnLocalCharacterAdded)
    ThreadLoop(0.0001, function()
        if string.find(GameName, "Da Hood") then
            local GunType = Script:GetGunCategory()
            local Tool = Self.Character:FindFirstChildWhichIsA("Tool")
            if Tool then
                if GunType == "Pistol" or GunType == "Sniper" then
                    for I, v in pairs(Tool:GetChildren()) do
                        if v.Name == "GunClient" then
                            v:Destroy()
                        end
                    end
                elseif GunType == "Shotgun" then
                    for I, v in pairs(Tool:GetChildren()) do
                        if v.Name == "GunClientShotgun" then
                            v:Destroy()
                        end
                    end
                elseif GunType == "Auto" then
                    for I, v in pairs(Tool:GetChildren()) do
                        if v.Name == "GunClientAutomaticShotgun" then
                            v:Destroy()
                        end
                    end
                elseif GunType == "Burst" then
                    for I, v in pairs(Tool:GetChildren()) do
                        if v.Name == "GunClientBurst" then
                            v:Destroy()
                        end
                    end
                elseif GunType == "Rifle" or GunType == "SMG" then
                    for I, v in pairs(Tool:GetChildren()) do
                        if v.Name == "GunClientAutomatic" then
                            v:Destroy()
                        end
                    end
                end
            end
        end
    end)
    local SP = false
    local SP2 = false
    local SP3 = false
    RBXConnection(UserInputService.InputBegan, function(Input, Processed)
        if shared.xvory.Silent.Conditions.Chat and UserInputService:GetFocusedTextBox() then return end
        local TargetKey = Enum.KeyCode[shared.xvory.Settings.General.Keybind["Target"]]
        local CamlockKey = Enum.KeyCode[shared.xvory.Settings.General.Keybind["Camlock"]]
        local DoubleTapKey = Enum.KeyCode[shared.xvory.Settings.General.Keybind["2Tap"]]
        local TriggerbotKey = Enum.KeyCode[shared.xvory.Settings.General.Keybind["Triggerbot"]]
        local ESPToggle = Enum.KeyCode[shared.xvory.Settings.General.Keybind["ESP"]]
        if Input.KeyCode == ESPToggle then
            shared.xvory.ESP.Enabled = not shared.xvory.ESP.Enabled
        end
        if Input.KeyCode == CamlockKey and CamlockKey ~= TargetKey then
            shared.xvory.Camlock.Enabled = not shared.xvory.Camlock.Enabled
        end
        if Input.KeyCode == TargetKey then
            SP = not SP
            SP2 = SP
            if SP then
                Script.Locals.SilentAimTarget = Script:GetClosestPlayerToCursor(
                    shared.xvory.Silent["Max Dist"],
                    shared.xvory.Silent.Fov.Enabled and SilentFOVRadius or math.huge,
                    true
                )
                Script.Locals.TriggerbotTarget = Script.Locals.SilentAimTarget
            else
                if Script.Locals.SilentAimTarget then
                    Script.Locals.SilentAimTarget = nil
                end
                if Script.Locals.TriggerbotTarget then
                    Script.Locals.TriggerbotTarget = nil
                end
            end
        end
        if Input.KeyCode == DoubleTapKey then
            Script.Locals.IsDoubleTapping = not Script.Locals.IsDoubleTapping
        end
        local triggerConfig = shared.xvory.Triggerbot.Works
        local isMouseInput = triggerConfig.Mode == "Mouse"
        local isKeyboardInput = triggerConfig.Mode == "Keybind"
        local toggleKey = shared.xvory.Settings.General.Keybind["Triggerbot"]
        local success, keyCode = pcall(function()
            return Enum.KeyCode[toggleKey]
        end)
        if isMouseInput and table.find({"MouseButton1", "MouseButton2"}, toggleKey) and Input.UserInputType == Enum.UserInputType[toggleKey] then
            if triggerConfig.Type == "Toggle" then
                Script.Locals.TriggerState = not Script.Locals.TriggerState
            elseif triggerConfig.Type == "Hold" then
                Script.Locals.TriggerState = true
            end
        elseif isKeyboardInput and success and table.find(Enum.KeyCode:GetEnumItems(), keyCode) and Input.KeyCode == keyCode then
            if triggerConfig.Type == "Toggle" then
                Script.Locals.TriggerState = not Script.Locals.TriggerState
            elseif triggerConfig.Type == "Hold" then
                Script.Locals.TriggerState = true
            end
        end
        if Input.KeyCode == Enum.KeyCode.LeftControl then
            CanTriggerbotShoot = false
        end
        if shared.xvory["Local Game"]["Inventory Sorter"].Enabled and Input.KeyCode == Enum.KeyCode[shared.xvory.Settings.General.Keybind["Inventory Sorter"]] then
            local GunOrder = shared.xvory["Local Game"]["Inventory Sorter"].Order
            local BackPack = Self:FindFirstChildOfClass("Backpack")
            if not BackPack then
                return
            end
            local CurrentTime = tick()
            local Order_V = 10 - #GunOrder
            local Cooldown = true
            if Cooldown then
                local FakeFolder = Instance.new("Folder")
                FakeFolder.Name = "FakeFolder"
                FakeFolder.Parent = Workspace
                local FakeFolderID = Workspace.FakeFolder
                for _, v in pairs(BackPack:GetChildren()) do
                    if v:IsA("Tool") then
                        v.Parent = Workspace.FakeFolder
                    end
                end
                for _, v in pairs(GunOrder) do
                    local Gun = FakeFolderID:FindFirstChild(v)
                    if Gun then
                        Gun.Parent = BackPack
                        wait(0.05)
                    else
                        Order_V = Order_V + 1
                    end
                end
                for _, v in pairs(FakeFolderID:GetChildren()) do
                    if v:FindFirstChild("Drink") or v:FindFirstChild("Eat") then
                        v.Parent = BackPack
                        Order_V = Order_V - 1
                    end
                end
                if Order_V > 0 then
                    for i = 1, Order_V do
                        local Tool = Instance.new("Tool")
                        Tool.Name = ""
                        Tool.ToolTip = "PlaceHolder"
                        Tool.GripPos = Vector3.new(0, 1, 0)
                        Tool.RequiresHandle = false
                        Tool.Parent = BackPack
                    end
                end
                for _, v in pairs(FakeFolderID:GetChildren()) do
                    if v:IsA("Tool") then
                        v.Parent = BackPack
                    end
                end
                for _, v in pairs(BackPack:GetChildren()) do
                    if v.Name == "" then
                        v:Destroy()
                    end
                end
                FakeFolder:Destroy()
            end
        end
    end)
    RBXConnection(UserInputService.InputEnded, function(Input, Processed)
        if shared.xvory.Silent.Conditions.Chat and UserInputService:GetFocusedTextBox() then return end
        local triggerConfig = shared.xvory.Triggerbot.Works
        local isMouseInput = triggerConfig.Mode == "Mouse"
        local isKeyboardInput = triggerConfig.Mode == "Keybind"
        local toggleKey = shared.xvory.Settings.General.Keybind["Triggerbot"]
        local success, keyCode = pcall(function()
            return Enum.KeyCode[toggleKey]
        end)
        if triggerConfig.Type == "Hold" then
            if isMouseInput and table.find({"MouseButton1", "MouseButton2"}, toggleKey) and Input.UserInputType == Enum.UserInputType[toggleKey] then
                Script.Locals.TriggerState = false
            elseif isKeyboardInput and success and table.find(Enum.KeyCode:GetEnumItems(), keyCode) and Input.KeyCode == keyCode then
                Script.Locals.TriggerState = false
            end
        end
        if Input.KeyCode == Enum.KeyCode.LeftControl then
            CanTriggerbotShoot = true
        end
    end)
    RBXConnection(RunService.RenderStepped, LPH_NO_VIRTUALIZE(function()
        local silentAimConfig = shared.xvory.Silent
        local triggerBotConfig = shared.xvory.Triggerbot
        if silentAimConfig.Mode == "Automatic" then
            Script.Locals.SilentAimTarget = Script:GetClosestPlayerToCursor(
                silentAimConfig["Max Dist"],
                silentAimConfig.Fov["Hit Scan"],
                true
            )
        end
        if triggerBotConfig.Mode == "Automatic" then
            Script.Locals.TriggerbotTarget = Script:GetClosestPlayerToCursor(
                triggerBotConfig["Max Dist"],
                triggerBotConfig.Radius * 5,
                false
            )
        end
        if Script.Locals.SilentAimTarget and Script.Locals.SilentAimTarget.Character then
            Script.Locals.HitPosition = Script:GetHitPosition("Silent")
        end
        Script:ShouldShoot(Script.Locals.SilentAimTarget)
        if Script.Locals.TriggerbotTarget and Script.Locals.TriggerbotTarget.Character then
            Script.Locals.HitTrigger = Script:GetClosestPartToCursor(Script.Locals.TriggerbotTarget.Character)
        end
        Script:Camlock()
        ThreadFunction(Script.triggerFunc)
        ThreadFunction(Script.playerFunc)
        UpdateDrawings()
    end))
    if getgenv().XvoryESP and getgenv().XvoryESP.TextLabels then
        for plr, data in pairs(getgenv().XvoryESP.TextLabels) do
            if data.gui then pcall(function() data.gui:Destroy() end) end
        end
    end
    local ESP = {
        TextLabels = {}
    }
    getgenv().XvoryESP = ESP
    local function IsPlayerAlive(plr)
        local char = plr.Character
        local humanoid = char and char:FindFirstChild("Humanoid")
        return humanoid and humanoid.Health > 0
    end
    local function IsPlayerKnocked(plr)
        local char = plr.Character
        if not char then return false end
        return CurrentGame.Functions.IsKnocked(char)
    end
    local function GetESPStudsOffset()
        if shared.xvory.ESP.Position == "Top" then
            return Vector3.new(0, 3, 0)
        else
            return Vector3.new(0, -3, 0)
        end
    end
    local function ClearDeadTargets()
        if Script.Locals then
            if Script.Locals.SilentAimTarget and not IsPlayerAlive(Script.Locals.SilentAimTarget) then
                Script.Locals.SilentAimTarget = nil
            end
            if Script.Locals.TriggerbotTarget and not IsPlayerAlive(Script.Locals.TriggerbotTarget) then
                Script.Locals.TriggerbotTarget = nil
            end
        end
    end
    local function CreateESPForPlayer(plr)
        if plr == Self then return end
        if ESP.TextLabels[plr] then return end
        local textLabel = Instance.new("BillboardGui")
        textLabel.Name = "ESP_" .. plr.Name
        textLabel.AlwaysOnTop = true
        textLabel.Size = UDim2.new(0, 80, 0, 20)
        textLabel.StudsOffset = GetESPStudsOffset()
        textLabel.ResetOnSpawn = false
        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.TextColor3 = shared.xvory.ESP.Color
        text.TextStrokeTransparency = 0.3
        text.TextSize = shared.xvory.ESP.Size or 10
        text.Font = Enum.Font.SourceSans
        text.Size = UDim2.new(1, 0, 1, 0)
        if shared.xvory.ESP.UseDisplayName then
            text.Text = plr.DisplayName
        else
            text.Text = plr.Name
        end
        text.Parent = textLabel
        ESP.TextLabels[plr] = {
            gui = textLabel,
            label = text
        }
    end
    local function UpdateESP()
        local espConfig = shared.xvory.ESP
        if not espConfig.Enabled then
            for plr, data in pairs(ESP.TextLabels) do
                data.gui.Enabled = false
            end
            return
        end
        ClearDeadTargets()
        for plr, data in pairs(ESP.TextLabels) do
            local char = plr.Character
            local rootPart = char and char:FindFirstChild("HumanoidRootPart")
            local isAlive = IsPlayerAlive(plr)
            local isKnocked = IsPlayerKnocked(plr)
            if rootPart and isAlive then
                data.gui.Adornee = rootPart
                data.gui.Parent = rootPart
                data.gui.Enabled = true
                data.gui.StudsOffset = GetESPStudsOffset()
                data.label.TextSize = espConfig.Size or 10
                if espConfig.UseDisplayName then
                    data.label.Text = plr.DisplayName
                else
                    data.label.Text = plr.Name
                end
                if isKnocked then
                    data.label.TextColor3 = espConfig.Color
                elseif Script.Locals and Script.Locals.SilentAimTarget and Script.Locals.SilentAimTarget == plr then
                    data.label.TextColor3 = espConfig.TargetColor
                else
                    data.label.TextColor3 = espConfig.Color
                end
            else
                data.gui.Enabled = false
            end
        end
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Self then
            CreateESPForPlayer(plr)
        end
    end
    RBXConnection(Players.PlayerAdded, function(plr)
        if plr == Self then return end
        CreateESPForPlayer(plr)
    end)
    RBXConnection(Players.PlayerRemoving, function(plr)
        if ESP.TextLabels[plr] and ESP.TextLabels[plr].gui then
            ESP.TextLabels[plr].gui:Destroy()
            ESP.TextLabels[plr] = nil
        end
    end)
    RBXConnection(RunService.RenderStepped, UpdateESP)
end
do
    local PlayersService = game:GetService("Players")
    local LocalPlayer = PlayersService.LocalPlayer
    if not LPH_NO_VIRTUALIZE then
        LPH_NO_VIRTUALIZE = function(func) return func end
    end


    local hasApplied = false
    local initialApplyDone = false


    local function ReloadAnimate(character)
        local animate = character:FindFirstChild("Animate")
        if animate then
            animate.Disabled = true
            task.wait()
            animate.Disabled = false
        end
    end


    local function ForceStand(humanoid)
        if not humanoid then return end

        humanoid.Sit = false

        local character = humanoid.Parent
        if character then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                for _, weld in ipairs(root:GetChildren()) do
                    if weld:IsA("Weld") and weld.Name == "SeatWeld" then
                        weld:Destroy()
                    end
                end
            end
        end
    end

    local function ChangeAvatar()
        if hasApplied then return end

        local cfg = shared.xvory and shared.xvory["Player Modifications"] and shared.xvory["Player Modifications"]["Avatar Changer"]
        if not cfg or not cfg["Enabled"] or not cfg["Username"] then return end

        local character = LocalPlayer.Character
        if not character then return end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        hasApplied = true

        LPH_NO_VIRTUALIZE(function()

            local success, userId = pcall(function()
                return PlayersService:GetUserIdFromNameAsync(cfg["Username"])
            end)
            if not success or not userId then
                hasApplied = false
                return
            end

            local descSuccess, desc = pcall(function()
                return PlayersService:GetHumanoidDescriptionFromUserId(userId)
            end)
            if not descSuccess or not desc then
                hasApplied = false
                return
            end

            ForceStand(humanoid)

            for _, obj in ipairs(character:GetChildren()) do
                if obj:IsA("Shirt")
                or obj:IsA("Pants")
                or obj:IsA("ShirtGraphic")
                or obj:IsA("Accessory") then
                    obj:Destroy()
                end
            end

            desc.WidthScale = 0.502
            desc.DepthScale = 0.502
            desc.HeadScale = humanoid:FindFirstChild("HeadScale") and humanoid.HeadScale.Value or desc.HeadScale
            desc.HeightScale = humanoid:FindFirstChild("BodyHeightScale") and humanoid.BodyHeightScale.Value or desc.HeightScale
            desc.ProportionScale = humanoid:FindFirstChild("BodyProportionScale") and humanoid.BodyProportionScale.Value or desc.ProportionScale
            desc.BodyTypeScale = humanoid:FindFirstChild("BodyTypeScale") and humanoid.BodyTypeScale.Value or desc.BodyTypeScale

            local targetEmotes = {}
            local targetEquipped = {}

            local emotesSuccess, emotes = pcall(function()
                return desc:GetEmotes()
            end)

            local equippedSuccess, equipped = pcall(function()
                return desc:GetEquippedEmotes()
            end)

            if emotesSuccess and type(emotes) == "table" then
                targetEmotes = emotes
            end

            if equippedSuccess and type(equipped) == "table" then
                targetEquipped = equipped
            end

            if next(targetEmotes) then
                for name, ids in pairs(targetEmotes) do
                    pcall(function()
                        desc:SetEmotes(name, ids)
                    end)
                end
            end

            if next(targetEquipped) then
                pcall(function()
                    desc:SetEquippedEmotes(targetEquipped)
                end)
            end

            humanoid:ApplyDescriptionClientServer(desc)

            task.wait(0.15)

            if cfg["Misc"] and cfg["Misc"]["Headless"] then
                local head = character:FindFirstChild("Head")
                if head then
                    head.Transparency = 1
                    local face = head:FindFirstChild("face")
                    if face then
                        face.Transparency = 1
                    end
                end
            end

            if cfg["Misc"] and cfg["Misc"]["Korblox"] then
                local rightLowerLeg = character:FindFirstChild("RightLowerLeg")
                local rightUpperLeg = character:FindFirstChild("RightUpperLeg")
                local rightFoot = character:FindFirstChild("RightFoot")

                if rightLowerLeg then
                    rightLowerLeg.MeshId = "902942093"
                    rightLowerLeg.Transparency = 1
                end

                if rightUpperLeg then
                    rightUpperLeg.MeshId = "http://www.roblox.com/asset/?id=902942096"
                    rightUpperLeg.TextureID = "http://roblox.com/asset/?id=902843398"
                    rightUpperLeg.Size = rightUpperLeg.Size * Vector3.new(1.2, 1, 1.2)
                end

                if rightFoot then
                    rightFoot.MeshId = "902942089"
                    rightFoot.Transparency = 1
                end
            end

            ForceStand(humanoid)
            ReloadAnimate(character)

            initialApplyDone = true
        end)()
    end

    local function HookCharacter(character)
        hasApplied = false
        initialApplyDone = false
        task.wait(0.1)
        ChangeAvatar()
    end

    if getgenv().AvatarChangerConnection then
        getgenv().AvatarChangerConnection:Disconnect()
    end

    getgenv().AvatarChangerConnection = LocalPlayer.CharacterAdded:Connect(HookCharacter)

    getgenv().ApplyAvatarChanger = function()
        local avatarConfig = shared.xvory and shared.xvory["Player Modifications"] and shared.xvory["Player Modifications"]["Avatar Changer"]
        if not avatarConfig or not avatarConfig.Enabled or not avatarConfig.Username or avatarConfig.Username == "" then return end
        
        hasApplied = false
        ChangeAvatar()
    end

    if LocalPlayer.Character then
        ChangeAvatar()
    end
end
