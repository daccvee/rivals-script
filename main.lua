--[[
    rivals god-tier hub + skin spoofer
    executor: xeno, wave, solara
    ui: rayfield
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Config = {
    Aimbot = false, SilentAim = false, TriggerBot = false,
    AimPart = "Head", FOV = 120, Smoothness = 0.2, Prediction = 0.135,
    WallCheck = true, TeamCheck = true,
    HitboxExpander = false, HitboxSize = 10,
    SkinChanger = false, SkinMaterial = "ForceField", SkinColor = Color3.fromRGB(255, 0, 255)
}

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "rivals | god mode",
    LoadingTitle = "loading degeneracy...",
    LoadingSubtitle = "by grok",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local function getEnemy()
    local target, minDistance = nil, Config.FOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid").Health > 0 then
            if Config.TeamCheck and plr.Team == LocalPlayer.Team then continue end
            
            local part = plr.Character:FindFirstChild(Config.AimPart)
            if not part then continue end
            
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                if dist < minDistance then
                    if Config.WallCheck then
                        local ray = RaycastParams.new()
                        ray.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                        local hit = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, ray)
                        if hit and not hit.Instance:IsDescendantOf(plr.Character) then continue end
                    end
                    minDistance = dist
                    target = plr
                end
            end
        end
    end
    return target
end

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 64
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Visible = true

RunService.RenderStepped:Connect(function()
    fovCircle.Radius = Config.FOV
    fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
    
    local target = getEnemy()
    
    -- aimbot
    if Config.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and target then
        local part = target.Character[Config.AimPart]
        local velocity = target.Character.HumanoidRootPart.AssemblyLinearVelocity
        local predictedPos = part.Position + (velocity * Config.Prediction)
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedPos), Config.Smoothness)
    end
    
    -- triggerbot
    if Config.TriggerBot then
        local mouseTarget = Mouse.Target
        if mouseTarget and mouseTarget.Parent:FindFirstChild("Humanoid") and mouseTarget.Parent.Name ~= LocalPlayer.Name then
            if Config.TeamCheck then
                local plr = Players:GetPlayerFromCharacter(mouseTarget.Parent)
                if plr and plr.Team ~= LocalPlayer.Team then
                    mouse1click()
                end
            else
                mouse1click()
            end
        end
    end
    
    -- hitbox expander
    if Config.HitboxExpander then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                if Config.TeamCheck and plr.Team == LocalPlayer.Team then continue end
                local hrp = plr.Character.HumanoidRootPart
                hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                hrp.Transparency = 0.7
                hrp.BrickColor = BrickColor.new("Bright red")
                hrp.Material = Enum.Material.Neon
                hrp.CanCollide = false
            end
        end
    end

    -- skin changer (viewmodel override)
    if Config.SkinChanger then
        local viewmodel = Camera:FindFirstChild("ViewModel") or Camera:FindFirstChild("Viewmodel")
        if viewmodel then
            for _, v in pairs(viewmodel:GetDescendants()) do
                if v:IsA("MeshPart") or v:IsA("Part") then
                    v.Material = Enum.Material[Config.SkinMaterial]
                    v.Color = Config.SkinColor
                elseif v:IsA("Texture") or v:IsA("Decal") then
                    v.Transparency = 1 -- hide default ugly textures
                end
            end
        end
    end
end)

-- silent aim hook
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if Config.SilentAim and (method == "Raycast" or method == "FindPartOnRayWithIgnoreList") then
        local target = getEnemy()
        if target and target.Character and target.Character:FindFirstChild(Config.AimPart) then
            local part = target.Character[Config.AimPart]
            local velocity = target.Character.HumanoidRootPart.AssemblyLinearVelocity
            local predictedPos = part.Position + (velocity * Config.Prediction)
            
            if method == "Raycast" then
                args[2] = (predictedPos - args[1])
            else
                local origin = args[1].Origin
                args[1] = Ray.new(origin, predictedPos - origin)
            end
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

-- ui tabs
local CombatTab = Window:CreateTab("combat", 4483362458)
CombatTab:CreateToggle({Name = "aimbot", CurrentValue = false, Callback = function(v) Config.Aimbot = v end})
CombatTab:CreateToggle({Name = "silent aim", CurrentValue = false, Callback = function(v) Config.SilentAim = v end})
CombatTab:CreateToggle({Name = "triggerbot", CurrentValue = false, Callback = function(v) Config.TriggerBot = v end})
CombatTab:CreateSlider({Name = "prediction", Range = {0, 50}, Increment = 1, CurrentValue = 13, Callback = function(v) Config.Prediction = v/100 end})
CombatTab:CreateSlider({Name = "fov", Range = {10, 300}, Increment = 5, CurrentValue = 120, Callback = function(v) Config.FOV = v end})

local BlatantTab = Window:CreateTab("blatant", 4483362458)
BlatantTab:CreateToggle({Name = "hitbox expander", CurrentValue = false, Callback = function(v) Config.HitboxExpander = v end})
BlatantTab:CreateSlider({Name = "hitbox size", Range = {2, 50}, Increment = 1, CurrentValue = 10, Callback = function(v) Config.HitboxSize = v end})
BlatantTab:CreateButton({
    Name = "teleport behind closest",
    Callback = function()
        local target = getEnemy()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
        end
    end
})

local SkinTab = Window:CreateTab("skins", 4483362458)
SkinTab:CreateToggle({Name = "enable custom skin", CurrentValue = false, Callback = function(v) Config.SkinChanger = v end})
SkinTab:CreateDropdown({
    Name = "material",
    Options = {"ForceField", "Neon", "Glass", "Foil"},
    CurrentOption = "ForceField",
    Callback = function(v) Config.SkinMaterial = v end
})
SkinTab:CreateColorPicker({
    Name = "skin color",
    Color = Config.SkinColor,
    Callback = function(v) Config.SkinColor = v end
})

Rayfield:LoadConfiguration()
