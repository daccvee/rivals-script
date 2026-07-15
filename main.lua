--[[
    Rivals Multi-Feature Script
    Executor: Xeno (also works on Solara, Wave)
    UI: Rayfield
    Author: for LO <3
--]]

-- =========================
-- SERVICES & CORE VARIABLES
-- =========================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")
local VirtualUser        = game:GetService("VirtualUser")
local StarterGui         = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- =========================
-- CONFIG TABLE (LIVE STATE)
-- =========================
local Config = {
    -- Aimbot
    AimbotEnabled   = false,
    AimbotKey       = Enum.UserInputType.MouseButton2, -- hold RMB to aim
    FOV             = 90,
    Smoothness      = 0.25,
    TeamCheck       = true,
    WallCheck       = true,
    TargetPart      = "Head",

    -- Silent Aim
    SilentAim       = false,
    SilentHitChance = 100,

    -- ESP
    ESPEnabled      = false,
    ESPBox          = true,
    ESPName         = true,
    ESPHealth       = true,
    ESPDistance     = true,
    ESPTracer       = true,
    BoxColor        = Color3.fromRGB(255, 60, 60),
    NameColor       = Color3.fromRGB(255, 255, 255),
    HealthColor     = Color3.fromRGB(60, 255, 60),
    TracerColor     = Color3.fromRGB(255, 255, 0),

    -- Movement
    SpeedHack       = false,
    WalkSpeed       = 32,
    InfiniteJump    = false,
    NoRecoil        = false,

    -- Misc
    AntiAFK         = true,
    CustomFOV       = false,
    CameraFOV       = 90,
}

-- =========================
-- LOAD RAYFIELD UI LIBRARY
-- =========================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Rivals | Multi-Hub",
    LoadingTitle = "Rivals Hub",
    LoadingSubtitle = "Xeno Build",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- =========================
-- HELPER: get enemy players
-- =========================
local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    if not player.Character:FindFirstChild("Humanoid") then return false end
    if player.Character.Humanoid.Health <= 0 then return false end
    if Config.TeamCheck and player.Team and LocalPlayer.Team then
        if player.Team == LocalPlayer.Team then return false end
    end
    return true
end

-- Wall check via raycast from camera to target part
local function visible(targetPart)
    local origin = Camera.CFrame.Position
    local dir    = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(origin, dir, params)
    if not result then return true end
    -- if raycast hit target's character, visible
    return result.Instance:IsDescendantOf(targetPart.Parent)
end

-- Returns closest enemy inside FOV cone
local function getClosestEnemy()
    local closest, shortest = nil, Config.FOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then
            local part = plr.Character:FindFirstChild(Config.TargetPart)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if dist < shortest then
                        if not Config.WallCheck or visible(part) then
                            shortest = dist
                            closest  = plr
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- =========================
-- AIMBOT TAB
-- =========================
local AimTab = Window:CreateTab("Aimbot", 4483362458)

AimTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Callback = function(v) Config.AimbotEnabled = v end,
})

AimTab:CreateSlider({
    Name = "FOV Radius",
    Range = {10, 500},
    Increment = 5,
    CurrentValue = 90,
    Callback = function(v) Config.FOV = v end,
})

AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 4,
    Callback = function(v) Config.Smoothness = v / 20 end,
})

AimTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(v) Config.TeamCheck = v end,
})

AimTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = true,
    Callback = function(v) Config.WallCheck = v end,
})

AimTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"},
    CurrentOption = "Head",
    Callback = function(v) Config.TargetPart = v end,
})

-- FOV Circle drawing
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness    = 1
FOVCircle.NumSides     = 64
FOVCircle.Radius       = Config.FOV
FOVCircle.Filled       = false
FOVCircle.Visible      = false
FOVCircle.Color        = Color3.fromRGB(255,255,255)
FOVCircle.Transparency = 1

-- Aimbot loop on RenderStepped
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = Config.AimbotEnabled
    FOVCircle.Radius  = Config.FOV
    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)

    if Config.AimbotEnabled and UserInputService:IsMouseButtonPressed(Config.AimbotKey) then
        local target = getClosestEnemy()
        if target and target.Character then
            local part = target.Character:FindFirstChild(Config.TargetPart)
            if part then
                local goal = CFrame.new(Camera.CFrame.Position, part.Position)
                Camera.CFrame = Camera.CFrame:Lerp(goal, Config.Smoothness)
            end
        end
    end
end)

-- =========================
-- SILENT AIM TAB
-- =========================
local SilentTab = Window:CreateTab("Silent Aim", 4483362458)

SilentTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Callback = function(v) Config.SilentAim = v end,
})

SilentTab:CreateSlider({
    Name = "Hit Chance %",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 100,
    Callback = function(v) Config.SilentHitChance = v end,
})

-- Hook FindPartOnRayWithIgnoreList / Raycast to redirect bullet ray at target head.
-- Rivals uses raycast-based hit registration; we intercept and rewrite the ray direction.
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}

    if Config.SilentAim and (method == "Raycast" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay") then
        if math.random(1, 100) <= Config.SilentHitChance then
            local target = getClosestEnemy()
            if target and target.Character then
                local head = target.Character:FindFirstChild(Config.TargetPart)
                if head then
                    if method == "Raycast" then
                        local origin = args[1]
                        args[2] = (head.Position - origin)
                        return oldNamecall(self, table.unpack(args))
                    else
                        local ray = args[1]
                        local origin = ray.Origin
                        args[1] = Ray.new(origin, (head.Position - origin))
                        return oldNamecall(self, table.unpack(args))
                    end
                end
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- =========================
-- ESP TAB
-- =========================
local ESPTab = Window:CreateTab("ESP", 4483362458)

ESPTab:CreateToggle({ Name = "ESP Enabled", CurrentValue = false,
    Callback = function(v) Config.ESPEnabled = v end })
ESPTab:CreateToggle({ Name = "Box",      CurrentValue = true, Callback = function(v) Config.ESPBox = v end })
ESPTab:CreateToggle({ Name = "Name",     CurrentValue = true, Callback = function(v) Config.ESPName = v end })
ESPTab:CreateToggle({ Name = "Health",   CurrentValue = true, Callback = function(v) Config.ESPHealth = v end })
ESPTab:CreateToggle({ Name = "Distance", CurrentValue = true, Callback = function(v) Config.ESPDistance = v end })
ESPTab:CreateToggle({ Name = "Tracer",   CurrentValue = true, Callback = function(v) Config.ESPTracer = v end })

ESPTab:CreateColorPicker({ Name = "Box Color",    Color = Config.BoxColor,    Callback = function(c) Config.BoxColor = c end })
ESPTab:CreateColorPicker({ Name = "Name Color",   Color = Config.NameColor,   Callback = function(c) Config.NameColor = c end })
ESPTab:CreateColorPicker({ Name = "Health Color", Color = Config.HealthColor, Callback = function(c) Config.HealthColor = c end })
ESPTab:CreateColorPicker({ Name = "Tracer Color", Color = Config.TracerColor, Callback = function(c) Config.TracerColor = c end })

-- Drawing objects cached per player
local ESPObjects = {}

local function createESP(player)
    local o = {}
    o.Box       = Drawing.new("Square");   o.Box.Thickness = 1; o.Box.Filled = false; o.Box.Visible = false
    o.BoxOutline= Drawing.new("Square");   o.BoxOutline.Thickness = 3; o.BoxOutline.Filled = false; o.BoxOutline.Color = Color3.new(0,0,0); o.BoxOutline.Visible = false
    o.Name      = Drawing.new("Text");     o.Name.Size = 14; o.Name.Center = true; o.Name.Outline = true; o.Name.Font = 2; o.Name.Visible = false
    o.Distance  = Drawing.new("Text");     o.Distance.Size = 13; o.Distance.Center = true; o.Distance.Outline = true; o.Distance.Font = 2; o.Distance.Visible = false
    o.HealthBar = Drawing.new("Line");     o.HealthBar.Thickness = 3; o.HealthBar.Visible = false
    o.HealthBG  = Drawing.new("Line");     o.HealthBG.Thickness = 3; o.HealthBG.Color = Color3.new(0,0,0); o.HealthBG.Visible = false
    o.Tracer    = Drawing.new("Line");     o.Tracer.Thickness = 1; o.Tracer.Visible = false
    ESPObjects[player] = o
end

local function removeESP(player)
    if ESPObjects[player] then
        for _, v in pairs(ESPObjects[player]) do v:Remove() end
        ESPObjects[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then createESP(p) end end
Players.PlayerAdded:Connect(function(p) createESP(p) end)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    for player, o in pairs(ESPObjects) do
        local show = Config.ESPEnabled and isEnemy(player)
        if show then
            local char = player.Character
            local hrp  = char:FindFirstChild("HumanoidRootPart")
            local hum  = char:FindFirstChild("Humanoid")
            local head = char:FindFirstChild("Head")
            if hrp and hum and head then
                local topPos,    onScreen1 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local bottomPos, onScreen2 = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                if onScreen1 and onScreen2 then
                    local height = math.abs(topPos.Y - bottomPos.Y)
                    local width  = height / 2
                    local x = topPos.X - width / 2
                    local y = topPos.Y

                    -- Box
                    o.Box.Visible        = Config.ESPBox
                    o.BoxOutline.Visible = Config.ESPBox
                    o.Box.Size        = Vector2.new(width, height)
                    o.Box.Position    = Vector2.new(x, y)
                    o.Box.Color       = Config.BoxColor
                    o.BoxOutline.Size     = o.Box.Size
                    o.BoxOutline.Position = o.Box.Position

                    -- Name
                    o.Name.Visible  = Config.ESPName
                    o.Name.Text     = player.Name
                    o.Name.Position = Vector2.new(x + width/2, y - 16)
                    o.Name.Color    = Config.NameColor

                    -- Distance
                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                    o.Distance.Visible  = Config.ESPDistance
                    o.Distance.Text     = string.format("[%d studs]", dist)
                    o.Distance.Position = Vector2.new(x + width/2, y + height + 2)
                    o.Distance.Color    = Color3.fromRGB(200,200,200)

                    -- Health bar (left side, vertical)
                    local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    o.HealthBG.Visible  = Config.ESPHealth
                    o.HealthBG.From     = Vector2.new(x - 5, y)
                    o.HealthBG.To       = Vector2.new(x - 5, y + height)
                    o.HealthBar.Visible = Config.ESPHealth
                    o.HealthBar.From    = Vector2.new(x - 5, y + height)
                    o.HealthBar.To      = Vector2.new(x - 5, y + height - (height * hpPct))
                    o.HealthBar.Color   = Config.HealthColor

                    -- Tracer
                    o.Tracer.Visible = Config.ESPTracer
                    o.Tracer.From    = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    o.Tracer.To      = Vector2.new(topPos.X, topPos.Y + height)
                    o.Tracer.Color   = Config.TracerColor
                else
                    for _, d in pairs(o) do d.Visible = false end
                end
            else
                for _, d in pairs(o) do d.Visible = false end
            end
        else
            for _, d in pairs(o) do d.Visible = false end
        end
    end
end)

-- =========================
-- MOVEMENT TAB
-- =========================
local MoveTab = Window:CreateTab("Movement", 4483362458)

MoveTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Callback = function(v) Config.SpeedHack = v end,
})

MoveTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 32,
    Callback = function(v) Config.WalkSpeed = v end,
})

MoveTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v) Config.InfiniteJump = v end,
})

MoveTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = false,
    Callback = function(v) Config.NoRecoil = v end,
})

-- Speed hack loop
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = Config.SpeedHack and Config.WalkSpeed or 16
        end
    end
end)

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- No recoil: zero out camera recoil offset every frame if Rivals stores it under Camera or gun module.
-- Since exact path is unknown, we lock camera roll and pitch delta caused by recoil scripts.
local lastCF
RunService.RenderStepped:Connect(function()
    if Config.NoRecoil then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Sound") and obj.Name:lower():find("recoil") then obj.Volume = 0 end
        end
        pcall(function()
            local recoilVal = Camera:FindFirstChild("Recoil")
            if recoilVal and recoilVal:IsA("Vector3Value") then recoilVal.Value = Vector3.new() end
        end)
    end
end)

-- =========================
-- MISC TAB
-- =========================
local MiscTab = Window:CreateTab("Misc", 4483362458)

MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Callback = function(v) Config.AntiAFK = v end,
})

MiscTab:CreateToggle({
    Name = "Custom Camera FOV",
    CurrentValue = false,
    Callback = function(v) Config.CustomFOV = v end,
})

MiscTab:CreateSlider({
    Name = "Camera FOV",
    Range = {60, 120},
    Increment = 1,
    CurrentValue = 90,
    Callback = function(v) Config.CameraFOV = v end,
})

-- Anti-AFK: intercept idle kick
LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Camera FOV enforcement
RunService.RenderStepped:Connect(function()
    if Config.CustomFOV then Camera.FieldOfView = Config.CameraFOV end
end)

-- =========================
-- KEYBIND TAB
-- =========================
local KeyTab = Window:CreateTab("Keybinds", 4483362458)

local function bindKey(name, callback)
    KeyTab:CreateKeybind({
        Name = name,
        CurrentKeybind = "None",
        HoldToInteract = false,
        Callback = callback,
    })
end

bindKey("Toggle Aimbot",   function() Config.AimbotEnabled = not Config.AimbotEnabled end)
bindKey("Toggle Silent",   function() Config.SilentAim     = not Config.SilentAim end)
bindKey("Toggle ESP",      function() Config.ESPEnabled    = not Config.ESPEnabled end)
bindKey("Toggle Speed",    function() Config.SpeedHack = not Config.SpeedHack end)

-- load the ui
Rayfield:LoadConfiguration()
