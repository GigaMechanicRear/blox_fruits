-- Blox Fruits Hub | Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- state
local flags = {
    AutoFarm = false,
    FruitESP = false,
    AutoHaki = false,
    AutoChest = false,
}
local espCache = {}

-- helpers
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end
local function getHRP()
    local ch = getChar()
    return ch and ch:FindFirstChild("HumanoidRootPart")
end

-- find nearest enemy in workspace.Enemies
local function getNearestEnemy(maxDist)
    local hrp = getHRP()
    if not hrp then return nil end
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    local closest, closestDist = nil, maxDist or math.huge
    for _, mob in ipairs(enemies:GetChildren()) do
        local hum = mob:FindFirstChildOfClass("Humanoid")
        local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
        if hum and root and hum.Health > 0 then
            local d = (root.Position - hrp.Position).Magnitude
            if d < closestDist then
                closest, closestDist = mob, d
            end
        end
    end
    return closest
end

local Window = Rayfield:CreateWindow({
    Name = "Blox Fruits Hub",
    LoadingTitle = "Blox Fruits Hub",
    LoadingSubtitle = "Enjoy!",
    ConfigurationSaving = { Enabled = true, FolderName = "BFHub", FileName = "BFHub" },
})

-- ========== FARM TAB ==========
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)

FarmTab:CreateToggle({
    Name = "Auto Farm Nearest Mob",
    CurrentValue = false,
    Callback = function(v) flags.AutoFarm = v end,
})

FarmTab:CreateToggle({
    Name = "Auto Buso Haki",
    CurrentValue = false,
    Callback = function(v) flags.AutoHaki = v end,
})

FarmTab:CreateToggle({
    Name = "Auto Collect Chests",
    CurrentValue = false,
    Callback = function(v) flags.AutoChest = v end,
})

-- ========== ESP TAB ==========
local ESPTab = Window:CreateTab("ESP", 4483362458)

ESPTab:CreateToggle({
    Name = "Fruit ESP",
    CurrentValue = false,
    Callback = function(v)
        flags.FruitESP = v
        if not v then
            for k, hl in pairs(espCache) do
                if hl and hl.Parent then hl:Destroy() end
                espCache[k] = nil
            end
        end
    end,
})

-- ========== TELEPORT TAB ==========
local TPTab = Window:CreateTab("Teleport", 4483362458)

local islands = {
    ["Starter Island"]      = Vector3.new(1071, 16, 1426),
    ["Marine Fortress"]     = Vector3.new(-2450, 73, -3050),
    ["Skypiea"]             = Vector3.new(-4721, 845, -1954),
    ["Fountain City"]       = Vector3.new(5127, 4, 4105),
    ["Kingdom of Rose"]     = Vector3.new(-386, 71, 5810),
    ["Cafe (Spawn)"]        = Vector3.new(-380, 77, 320),
    ["Hydra Island"]        = Vector3.new(5228, 604, 345),
    ["Great Tree"]          = Vector3.new(2431, 400, -6975),
}

TPTab:CreateDropdown({
    Name = "Islands",
    Options = (function()
        local t = {}
        for name in pairs(islands) do table.insert(t, name) end
        table.sort(t)
        return t
    end)(),
    CurrentOption = {"Starter Island"},
    Callback = function(opt)
        local name = type(opt) == "table" and opt[1] or opt
        local pos = islands[name]
        local hrp = getHRP()
        if pos and hrp then
            hrp.CFrame = CFrame.new(pos)
            Rayfield:Notify({Title="Teleport", Content="-> "..name, Duration=3})
        end
    end,
})

-- ========== ANTI-AFK ==========
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ========== MAIN LOOPS ==========
-- Farm loop
task.spawn(function()
    while true do
        task.wait()
        if flags.AutoFarm then
            local mob = getNearestEnemy()
            local hrp = getHRP()
            local char = getChar()
            if mob and hrp then
                local mroot = mob:FindFirstChild("HumanoidRootPart")
                if mroot then
                    hrp.CFrame = mroot.CFrame * CFrame.new(0, 0, 3)
                    -- damage via tool activate
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    end
                    -- fallback: sword/gun remote if present
                    pcall(function()
                        local combat = mob:FindFirstChildOfClass("Humanoid")
                        if combat then combat.Health = combat.Health end
                    end)
                end
            end
        end
    end
end)

-- Haki loop
task.spawn(function()
    while true do
        task.wait(1)
        if flags.AutoHaki then
            local char = LocalPlayer.Character
            if char and not char:FindFirstChild("HasBusoawakened") then
                pcall(function()
                    local args = {"Buso"}
                    game:GetService("ReplicatedStorage")
                        :FindFirstChild("Remotes")
                        and game.ReplicatedStorage.Remotes:FindFirstChild("CommF_")
                        and game.ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
                end)
            end
        end
    end
end)

-- Chest loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if flags.AutoChest then
            local hrp = getHRP()
            if hrp then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj.Name:find("Chest") then
                        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                        if part then
                            hrp.CFrame = part.CFrame
                            task.wait(0.15)
                        end
                    end
                end
            end
        end
    end
end)

-- ESP loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if flags.FruitESP then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj.Name == "Fruit" or obj.Name:find("Fruit") then
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                    if part and not espCache[obj] then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255, 200, 0)
                        hl.OutlineColor = Color3.fromRGB(255,255,255)
                        hl.Adornee = part
                        hl.Parent = part
                        espCache[obj] = hl
                    end
                end
            end
            -- cleanup gone fruits
            for obj, hl in pairs(espCache) do
                if not obj.Parent then
                    if hl and hl.Parent then hl:Destroy() end
                    espCache[obj] = nil
                end
            end
        end
    end
end)

Rayfield:Notify({Title="Blox Fruits Hub", Content="Loaded successfully!", Duration=4})
