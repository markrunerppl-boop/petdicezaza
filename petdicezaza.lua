-- ==============================================================================
-- 🎲 PET DICE MASTER SAFE EDITION v4.5 (FLUENT UI REBORN)
-- 🛡️ Anti-AI Detection & High-Tier Protection System
-- 🎨 Modern Windows 11 Fluent Acrylic Interface
-- ==============================================================================

-- ==============================================================================
-- [0] CLEAN STARTUP & HOT-RELOAD GATEKEEPER
-- ==============================================================================
local executionTime = tick()

-- ป้องกันการยิงสคริปต์ 2 เธรดพร้อมกันในเสี้ยววินาทีเดียวกัน (Debounce 1.5 วินาที)
if getgenv().PetDiceScriptStarting and (executionTime - getgenv().PetDiceScriptStarting < 1.5) then
    warn("[PetDice Safe] Duplicate execution within 1.5s blocked.")
    return
end
getgenv().PetDiceScriptStarting = executionTime

if not game:IsLoaded() then 
    pcall(function() game.Loaded:Wait() end)
    getgenv().PetDiceScriptStarting = tick() -- อัปเดตเวลาหลังโหลดแมพเสร็จ
end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ReplicatedStorage = RS
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local CG = game:GetService("CoreGui")
local HS = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 15)
local HRP = Character:WaitForChild("HumanoidRootPart", 15)

LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    Humanoid = c:WaitForChild("Humanoid", 15)
    HRP = c:WaitForChild("HumanoidRootPart", 15)
end)

-- ป้องกันรันสคริปต์ซ้ำซ้อน และเคลียร์ UI เก่าก่อนรันใหม่ (Clean Startup & Hot-Reload Support)
if getgenv().PetDiceOldFluent then
    pcall(function() getgenv().PetDiceOldFluent:Destroy() end)
    getgenv().PetDiceOldFluent = nil
end
if getgenv().PetDiceFluent then
    pcall(function() getgenv().PetDiceFluent:Destroy() end)
    getgenv().PetDiceFluent = nil
end
if getgenv().PetDiceMobileToggleGui then
    pcall(function() getgenv().PetDiceMobileToggleGui:Destroy() end)
    getgenv().PetDiceMobileToggleGui = nil
end
pcall(function()
    local pg = LocalPlayer:WaitForChild("PlayerGui", 3)
    if pg then
        local oldToggle = pg:FindFirstChild("PetDiceMobileToggle")
        if oldToggle then oldToggle:Destroy() end
    end
    local oldCgToggle = CG:FindFirstChild("PetDiceMobileToggle")
    if oldCgToggle then oldCgToggle:Destroy() end
end)

getgenv().PetDiceScriptToken = tick()
local scriptToken = getgenv().PetDiceScriptToken
getgenv().TradeActiveSession = false

-- โหลดโมดูลภายในของเกม Pet Dice
local PetDice = RS:WaitForChild("PetDice")
local Action = PetDice:WaitForChild("Remotes"):WaitForChild("Action")
local TradeRemote = PetDice:WaitForChild("Remotes"):WaitForChild("Trade")

local State = require(PetDice.Client.Core.State)
local Stats = require(PetDice.Logic.Stats)
local Modifiers = require(PetDice.Logic.Modifiers)
local Format = require(PetDice.Logic.Format)
local Config = require(PetDice.Configs.Config)
local Expeditions = require(PetDice.Logic.Expeditions)
local ExpeditionConfig = require(PetDice.Configs.ExpeditionConfig)
local PetData = require(PetDice.Configs.PetData)
local Season = PetDice.Logic:FindFirstChild("Season") and require(PetDice.Logic.Season) or nil
local HalloweenConfig = (PetDice.Configs:FindFirstChild("HalloweenConfig") and require(PetDice.Configs.HalloweenConfig)) or { Goals = {}, Items = {} }
local HalloweenShopConfig = (PetDice.Configs:FindFirstChild("HalloweenShopConfig") and require(PetDice.Configs.HalloweenShopConfig)) or {}
local Towers = require(PetDice.Logic.Towers)
local TeamPairs = require(PetDice.Logic.TeamPairs)
local RewardsConfig = require(PetDice.Configs.RewardsConfig)
local QuestsLogic = require(PetDice.Logic.Quests)
local Upgrades = require(PetDice.Logic.Upgrades)
local WorldBossConfig = PetDice.Configs:FindFirstChild("WorldBossConfig") and require(PetDice.Configs.WorldBossConfig) or nil
local ScheduleConfig = PetDice.Configs:FindFirstChild("ScheduleConfig") and require(PetDice.Configs.ScheduleConfig) or nil
local CombatConfig = PetDice.Configs:FindFirstChild("CombatConfig") and require(PetDice.Configs.CombatConfig) or nil
local LootBagController = (PetDice.Client:FindFirstChild("Cutscenes") and PetDice.Client.Cutscenes:FindFirstChild("LootBagController") and require(PetDice.Client.Cutscenes.LootBagController)) or nil

local function Fire(...) 
    Action:FireServer(unpack({...})) 
end

-- ==============================================================================
-- [1] ANTI-DETECTION & HUMANIZER UTILITIES
-- ==============================================================================
local Humanizer = {}

function Humanizer.Wait(min, max)
    local mean = (min + max) / 2
    local std = (max - min) / 6
    local u1, u2 = math.random(), math.random()
    local z0 = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)
    local delay = mean + (z0 * std)
    task.wait(math.clamp(delay, min, max))
end

function Humanizer.Jitter(val, pct)
    pct = pct or 0.15
    local diff = val * pct
    return val + (math.random() * (diff * 2) - diff)
end

local CircuitBreaker = {
    Failures = {},
    LastAttempt = {},
    Cooldowns = {},
    MaxConsecutiveFails = 4
}

function CircuitBreaker.Execute(actionName, fn)
    local now = tick()
    local cd = CircuitBreaker.Cooldowns[actionName] or 0
    local last = CircuitBreaker.LastAttempt[actionName] or 0
    
    if (now - last) < cd then return false, "Cooldown" end
    
    CircuitBreaker.LastAttempt[actionName] = now
    local ok, res = pcall(fn)
    
    if not ok then
        local fails = (CircuitBreaker.Failures[actionName] or 0) + 1
        CircuitBreaker.Failures[actionName] = fails
        if fails >= CircuitBreaker.MaxConsecutiveFails then
            local penalty = math.min(60, 5 * (2 ^ (fails - CircuitBreaker.MaxConsecutiveFails)))
            CircuitBreaker.Cooldowns[actionName] = penalty
        end
        return false, res
    else
        CircuitBreaker.Failures[actionName] = 0
        CircuitBreaker.Cooldowns[actionName] = 0
        return true, res
    end
end

local function WalkToPawcula()
    local char = LocalPlayer.Character or Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or not hrp or hum.Health <= 0 then return false end
    
    local targetStand = Vector3.new(35.5, 2.25, -35.5)
    
    -- หากตัวละครอยู่ไกลเกิน 60 studs ให้ใช้ระบบวาร์ปทางการของตัวเกมกลับบ้านก่อน เพื่อความปลอดภัย
    if (hrp.Position - targetStand).Magnitude > 60 then
        Fire("Teleport", "Home")
        Humanizer.Wait(0.8, 1.5)
        char = LocalPlayer.Character or Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return false end
    end
    
    -- เดินด้วย Humanoid:MoveTo ตามระบบฟิสิกส์ปกติของตัวเกม ไม่ใช้ Tween หรือ CFrame
    hum:MoveTo(targetStand)
    local t0 = tick()
    while (hrp.Position - targetStand).Magnitude > 5 and tick() - t0 < 6.0 do
        task.wait(0.15)
        char = LocalPlayer.Character or Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then break end
    end
    
    Humanizer.Wait(0.5, 1.0)
    return (hrp.Position - targetStand).Magnitude <= 12
end

local function GetStallCFrame(stallName)
    local stalls = workspace:FindFirstChild("Stalls")
    if not stalls then return nil end
    local s = stalls:FindFirstChild(stallName)
    if not s then return nil end
    if s:IsA("Model") then return s:GetPivot() end
    if s:IsA("BasePart") then return s.CFrame end
    return nil
end

-- ==============================================================================
-- [2] RANK & LEVEL ENHANCER HELPERS
-- ==============================================================================
local GradeOptions = {
    "ZZZ (Rank 1)", "ZZ (Rank 2)", "Z+ (Rank 3)", "Z (Rank 4)",
    "SSS (Rank 5)", "SS (Rank 6)", "S+ (Rank 7)", "S (Rank 8)",
    "A+ (Rank 9)", "A (Rank 10)", "B (Rank 11)", "C (Rank 12)"
}

local GradeRankMap = {
    ["ZZZ (Rank 1)"] = 1, ["ZZ (Rank 2)"] = 2, ["Z+ (Rank 3)"] = 3, ["Z (Rank 4)"] = 4,
    ["SSS (Rank 5)"] = 5, ["SS (Rank 6)"] = 6, ["S+ (Rank 7)"] = 7, ["S (Rank 8)"] = 8,
    ["A+ (Rank 9)"] = 9, ["A (Rank 10)"] = 10, ["B (Rank 11)"] = 11, ["C (Rank 12)"] = 12
}

local TraitOptions = {
    "OMNIPOTENT (Rank 1)", "IMMORTAL (Rank 2)", "ALPHA (Rank 3)", "ROYAL (Rank 4)",
    "HEROIC (Rank 5)", "VALIANT (Rank 6)", "SPIRITED (Rank 7)",
    "GREEDY II (Rank 8)", "FIERCE II (Rank 9)", "STURDY II (Rank 10)"
}

local TraitRankMap = {
    ["OMNIPOTENT (Rank 1)"] = 1, ["IMMORTAL (Rank 2)"] = 2, ["ALPHA (Rank 3)"] = 3, ["ROYAL (Rank 4)"] = 4,
    ["HEROIC (Rank 5)"] = 5, ["VALIANT (Rank 6)"] = 6, ["SPIRITED (Rank 7)"] = 7,
    ["GREEDY II (Rank 8)"] = 8, ["FIERCE II (Rank 9)"] = 9, ["STURDY II (Rank 10)"] = 10
}

local GradeNameById = {}
for _, g in ipairs(Modifiers.Grades) do
    GradeNameById[g.Id] = g.Name
end

local TraitNameById = {}
for _, t in ipairs(Modifiers.Traits) do
    TraitNameById[t.Id] = t.Name
end

local function IsPetEligibleForEnhance(pet)
    if not pet then return false end
    local petId = pet.Id or pet.PetId
    if not petId then return false end
    local def = PetData and PetData.ById and PetData.ById[petId]
    if not def then return false end
    
    -- กรองสัตว์เลี้ยงประเภท Limited / Copy / Exclusive ทั้งหมด
    -- (เซิร์ฟเวอร์ปฏิเสธการอัปเลเวล / สุ่มเกรด / สุ่มเทรตสัตว์เลี้ยงเหล่านี้เด็ดขาด)
    if def.Limited == true or def.Rarity == "Limited" then
        return false
    end
    if def.Copy == true or def.Copies == true then
        return false
    end
    -- สัตว์เลี้ยงที่เป็นตัวก๊อปปี้สเตตัส (มีฟิลด์ R อ้างอิงตัวอื่น และไม่มีฟิลด์เลเวล/เกรดแท้จริง)
    if pet.R and typeof(pet.R) == "string" and not pet.G and not pet.L then
        return false
    end
    return true
end

local function GetPetGradeRank(pet)
    if not pet or not pet.G then return #Modifiers.Grades + 1 end
    return Modifiers.GradeRank(pet.G) or (#Modifiers.Grades + 1)
end

local function GetPetTraitRank(pet)
    if not pet or not pet.T then return #Modifiers.Traits + 1 end
    return Modifiers.TraitRank(pet.T) or (#Modifiers.Traits + 1)
end

local function IsPetGradeLocked(pet, targetRank)
    if not IsPetEligibleForEnhance(pet) then return true end -- สัตว์เลี้ยงประเภทพิเศษไม่สามารถสุ่มเกรดได้ ให้ถือว่าล็อคข้ามเสมอ
    targetRank = targetRank or (getgenv().CFG and getgenv().CFG.TargetGradeRank) or 8
    return GetPetGradeRank(pet) <= targetRank
end

local function IsPetTraitLocked(pet, targetRank)
    if not IsPetEligibleForEnhance(pet) then return true end -- สัตว์เลี้ยงประเภทพิเศษไม่สามารถสุ่มเทรตได้ ให้ถือว่าล็อคข้ามเสมอ
    targetRank = targetRank or (getgenv().CFG and getgenv().CFG.TargetTraitRank) or 6
    return GetPetTraitRank(pet) <= targetRank
end

local function FindAffordableLevels(pet, upgrades, money, maxCount)
    if not pet or not money or money <= 0 or maxCount <= 0 then return 0 end
    local low = 1
    local high = maxCount
    local best = 0
    while low <= high do
        local mid = math.floor((low + high) / 2)
        local cost = mid == 1 and Stats.PetLevelCost(pet, upgrades) or Stats.PetLevelsCost(pet, upgrades, mid)
        if cost and money >= cost then
            best = mid
            low = mid + 1
        else
            high = mid - 1
        end
    end
    return best
end

local UpgradeStepOptions = {
    "+1 เลเวล (ทีละ 1 ขั้น - ปลอดภัยสูงสุด)",
    "+5 เลเวล (ทีละ 5 เลเวล)",
    "+10 เลเวล (ทีละ 10 เลเวล)",
    "+25 เลเวล (ทีละ 25 เลเวล)",
    "อัปจนถึงเป้าหมายสูงสุด (Max เท่าที่เงินพอ)"
}

local UpgradeStepMap = {
    ["+1 เลเวล (ทีละ 1 ขั้น - ปลอดภัยสูงสุด)"] = 1,
    ["+5 เลเวล (ทีละ 5 เลเวล)"] = 5,
    ["+10 เลเวล (ทีละ 10 เลเวล)"] = 10,
    ["+25 เลเวล (ทีละ 25 เลเวล)"] = 25,
    ["อัปจนถึงเป้าหมายสูงสุด (Max เท่าที่เงินพอ)"] = 999
}

local function GetTopBestPets(count)
    local data = State.Data
    if not data or not data.Pets then return {} end
    
    local teamSize = count or 4
    local candidates = {}
    
    for uid, pet in pairs(data.Pets) do
        if IsPetEligibleForEnhance(pet) then
            local sUid = tostring(uid)
            local baseIncome = 0
            pcall(function() baseIncome = Stats.PetBaseIncome(pet) end)
            table.insert(candidates, { uid = sUid, base = baseIncome })
        end
    end
    
    table.sort(candidates, function(a, b)
        return a.base > b.base
    end)
    
    local res = {}
    for i = 1, math.min(teamSize, #candidates) do
        table.insert(res, candidates[i].uid)
    end
    return res
end

-- ==============================================================================
-- [3] CONFIGURATION MANAGEMENT
-- ==============================================================================
local ConfigFile = "PetDice_Master_v4_Config.json"

local defaultCFG = {
    Tower = false, AutoPlay = false, AutoExitArena = true,
    SelectedTower = "Infinity",
    SelectedTowerOption = "ด่าน 7: INFINITY TOWER (ไร้สิ้นสุด) [Infinity]",
    TowerRestartDelay = 3,
    AutoWorldBoss = false,
    WorldBossElementFilter = "[ ตีทุกธาตุ (All Elements) ]",
    WorldBossDifficultyFilter = "[ ตีทุกระดับ (All Difficulties) ]",
    PauseTowerForBoss = true,
    AutoRebirth = false, AutoBuyDice = false, AutoEquipBest = true,
    Reward = false, Quest = false, Cutscene = false,
    UpgradeTree = false, UpgradeTreeDelay = 3,
    AutoExpedition = false, ExpeditionPetCount = 1,
    HalloweenAutoClaim = false,
    HalloweenAutoBuyBags = false,
    HalloweenAutoBuyLimitedPull = false,
    HalloweenAutoOpenBags = false,
    HalloweenAutoTrickOrTreat = false,
    AutoDropItems = true, AutoReady = true,
    SenderMode = false, ReceiverMode = false, 
    TradeTarget = "[ เลือกทุกคนในห้อง ]", 
    TradeTargetId = nil,
    TradeCooldown = 90,
    TwoWayTrade = true,
    TradeReadyDelay = 4,
    AutoUpgradePetLevel = false,
    TargetPetLevel = 100,
    UpgradeLevelStep = 1,
    UpgradeLevelStepName = "+1 เลเวล (ทีละ 1 ขั้น - ปลอดภัยสูงสุด)",
    AutoRollGrade = false,
    AutoRollTrait = false,
    EnhancePetCount = 4,
    RollSpeed = 0.25,
    TargetGradeRank = 8,
    TargetGradeName = "S (Rank 8)",
    TargetTraitRank = 6,
    TargetTraitName = "VALIANT (Rank 6)",
    AutoUsePotionLuck = false,
    AutoUsePotionCash = false,
    AutoUsePotionSpeed = false,
    AutoOpenLootBags = false,
    AutoSellPets = false,
    KeepTopPetsCount = 100
}

getgenv().CFG = getgenv().CFG or {}
for k, v in pairs(defaultCFG) do
    if getgenv().CFG[k] == nil then
        getgenv().CFG[k] = v
    end
end

if readfile and isfile and isfile(ConfigFile) then
    pcall(function()
        local saved = HS:JSONDecode(readfile(ConfigFile))
        for k, v in pairs(saved) do getgenv().CFG[k] = v end
    end)
end

-- ป้องกันข้อผิดพลาดจากคอนฟิกเก่า: หอคอยด่าน 1-6 (Meadow ฯลฯ) ไม่สามารถรีเซ็ตเป็น 0 ได้ตามระบบเกม
-- หากคอนฟิกในเครื่องบันทึกหอคอยด่าน 1-6 หรือว่างเปล่า ให้ปรับเป็น Infinity ด่าน 7 อัตโนมัติ เพื่อให้ฟาร์มชั้น 1 ต่อเนื่องได้ 100%
if not getgenv().CFG.SelectedTower or getgenv().CFG.SelectedTower == "Meadow" or getgenv().CFG.SelectedTower == "" then
    getgenv().CFG.SelectedTower = "Infinity"
    getgenv().CFG.SelectedTowerOption = "ด่าน 7: INFINITY TOWER (ไร้สิ้นสุด) [Infinity]"
end
if not getgenv().CFG.SelectedTowerOption or getgenv().CFG.SelectedTowerOption:find("Meadow") then
    getgenv().CFG.SelectedTowerOption = "ด่าน 7: INFINITY TOWER (ไร้สิ้นสุด) [Infinity]"
end

if getgenv().CFG.TradeTarget == "[ เลือกทุกคนในห้อง ]" then
    getgenv().CFG.TradeTargetId = nil
end

local CFG = getgenv().CFG

local function UpdateCFG(key, val)
    getgenv().CFG[key] = val
    if writefile then 
        pcall(function() writefile(ConfigFile, HS:JSONEncode(getgenv().CFG)) end) 
    end
end

-- ==============================================================================
-- [4] CLEAN OLD GUIS
-- ==============================================================================
local function CleanOldGuis(parent)
    if not parent then return end
    for _, c in ipairs(parent:GetChildren()) do
        if c.Name:find("Rayfield") or c.Name:find("Fluent") or c.Name == "PetDiceMobileToggle" then
            pcall(function() c:Destroy() end)
        end
    end
end

pcall(function() CleanOldGuis(CG) end)
pcall(function() CleanOldGuis(LocalPlayer:FindFirstChild("PlayerGui")) end)

-- Clean previous Fluent instances before loading
if getgenv().PetDiceFluent then
    pcall(function() getgenv().PetDiceFluent:Destroy() end)
end
for _, c in ipairs(CG:GetChildren()) do
    if c:IsA("ScreenGui") and c.Name == "ScreenGui" then
        pcall(function() c:Destroy() end)
    end
end

-- ==============================================================================
-- [5] LOAD FLUENT UI & SETUP WINDOW
-- ==============================================================================
local Fluent
local okFluent, fluentRes = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if okFluent and fluentRes then
    Fluent = fluentRes
else
    Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/main/main.lua"))()
end
getgenv().PetDiceFluent = Fluent

local Window = Fluent:CreateWindow({
    Title = "Pet Dice Pro Farm",
    SubTitle = "Master Safe Edition v4.5",
    TabWidth = 160,
    Size = UDim2.fromOffset(590, 480),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightControl
})
getgenv().PetDiceWindow = Window

-- Fix transparency: Make background 100% solid dark and high contrast for crystal clear readability
local function ApplySolidWindowStyle(win)
    pcall(function()
        if win.AcrylicPaint and win.AcrylicPaint.Frame then
            win.AcrylicPaint.Frame.BackgroundTransparency = 0
            win.AcrylicPaint.Frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
        end
        if win.Root then
            win.Root.BackgroundTransparency = 0
            win.Root.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
        end
        if win.TabHolder then
            win.TabHolder.BackgroundTransparency = 0
            win.TabHolder.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
        end
    end)
end
ApplySolidWindowStyle(Window)
getgenv().PetDiceOldFluent = Fluent

-- ป้องกันหน้าต่างหลุดออกนอกจอ (Auto-Clamp Window to Viewport)
local function EnsureWindowInViewport(win)
    pcall(function()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
        local frame = win and (win.Frame or (win.Root and win.Root.Parent))
        if frame and frame:IsA("GuiObject") then
            local w = frame.AbsoluteSize.X > 100 and frame.AbsoluteSize.X or 590
            local h = frame.AbsoluteSize.Y > 100 and frame.AbsoluteSize.Y or 480
            local curX = frame.Position.X.Offset
            local curY = frame.Position.Y.Offset
            if curX < 0 or curX > (vp.X - 100) or curY < 0 or curY > (vp.Y - 100) then
                local posX = math.max(20, math.floor((vp.X - w) / 2))
                local posY = math.max(20, math.floor((vp.Y - h) / 2))
                frame.Position = UDim2.fromOffset(posX, posY)
            end
        end
    end)
end
task.spawn(function()
    task.wait(0.3)
    EnsureWindowInViewport(Window)
end)

local function Notify(title, content, duration)
    pcall(function()
        Fluent:Notify({
            Title = title,
            Content = content,
            Duration = duration or 3
        })
    end)
end

-- Floating Mobile Toggle Button (🎲) in PlayerGui
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "PetDiceMobileToggle"
ToggleGui.ResetOnSpawn = false
ToggleGui.DisplayOrder = 999999
ToggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
getgenv().PetDiceMobileToggleGui = ToggleGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.fromOffset(50, 50)
ToggleBtn.Position = UDim2.new(0, 15, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
ToggleBtn.TextColor3 = Color3.fromRGB(80, 210, 255)
ToggleBtn.Text = "🎲"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 24
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Parent = ToggleGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 12)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Thickness = 2
ToggleStroke.Color = Color3.fromRGB(0, 170, 255)
ToggleStroke.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    Window:Minimize()
end)

-- ==============================================================================
-- [6] TABS DEFINITION
-- ==============================================================================
local Tabs = {
    Overview   = Window:AddTab({ Title = "หน้าหลัก & สัตว์เลี้ยง", Icon = "home" }),
    Enhance    = Window:AddTab({ Title = "อัปเกรด & สุ่มบัฟ", Icon = "sparkles" }),
    Tower      = Window:AddTab({ Title = "หอคอย & ทอยเต๋า", Icon = "sword" }),
    Rebirth    = Window:AddTab({ Title = "เกิดใหม่ & สกิลทรี", Icon = "refresh-cw" }),
    Items      = Window:AddTab({ Title = "ไอเทม & บัฟขวด", Icon = "flask-conical" }),
    Expedition = Window:AddTab({ Title = "ผจญภัย & เควส", Icon = "compass" }),
    Halloween  = Window:AddTab({ Title = "อีเวนต์ฮาโลวีน", Icon = "ghost" }),
    Trade      = Window:AddTab({ Title = "ระบบเทรดปลอดภัย", Icon = "arrow-left-right" }),
    Settings   = Window:AddTab({ Title = "ความปลอดภัย & ตั้งค่า", Icon = "shield" })
}

-- ------------------------------------------------------------------------------
-- 🏠 TAB 1: OVERVIEW & BEST PETS REAL-TIME
-- ------------------------------------------------------------------------------
Tabs.Overview:AddSection("📊 ภาพรวมบัญชีและสถานะเรียลไทม์")

local OverviewStats = Tabs.Overview:AddParagraph({
    Title = "⏳ กำลังโหลดข้อมูลบัญชี...",
    Content = "กำลังดึงข้อมูลเงิน, เพชร, ชาร์ด และสถานะหอคอย..."
})

Tabs.Overview:AddSection("🐾 สัตว์เลี้ยงที่ดีที่สุด 8 อันดับ (เรียงตามรายได้พื้นฐาน)")

local PetCardParagraphs = {}
for i = 1, 8 do
    PetCardParagraphs[i] = Tabs.Overview:AddParagraph({
        Title = string.format("⭐ อันดับ #%d: กำลังโหลด...", i),
        Content = "รอข้อมูลสัตว์เลี้ยง..."
    })
end
local TogOverviewEquipBest, TogTowerEquipBest
local isSyncingEquipToggle = false

local function HandleAutoEquipBestToggle(V)
    UpdateCFG("AutoEquipBest", V)
    if not isSyncingEquipToggle then
        isSyncingEquipToggle = true
        pcall(function()
            if TogOverviewEquipBest and TogOverviewEquipBest.Value ~= V then
                TogOverviewEquipBest:SetValue(V)
            end
            if TogTowerEquipBest and TogTowerEquipBest.Value ~= V then
                TogTowerEquipBest:SetValue(V)
            end
        end)
        isSyncingEquipToggle = false
    end
    if V then
        task.spawn(function()
            Fire("EquipBest")
            Notify("🐾 สัตว์เลี้ยง", "เปิดระบบและสวมใส่ทีมที่ดีที่สุดเรียบร้อย!", 2)
        end)
    end
end

TogOverviewEquipBest = Tabs.Overview:AddToggle("TogAutoEquipBestOverview", {
    Title = "🐾 สวมใส่สัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (Auto Equip Best)",
    Default = CFG.AutoEquipBest,
    Callback = HandleAutoEquipBestToggle
})

Tabs.Overview:AddButton({
    Title = "⭐ สวมใส่สัตว์เลี้ยงที่ดีที่สุดทันที (Equip Best Pets)",
    Description = "คำนวณและสวมใส่ทีมที่ดีที่สุดโดยอัตโนมัติ",
    Callback = function()
        Fire("EquipBest")
        Notify("⭐ สวมใส่สำเร็จ", "สวมใส่ทีมสัตว์เลี้ยงที่ดีที่สุดเรียบร้อย!", 3)
    end
})

-- ==============================================================================
-- 💰 AUTO SELL PETS ENGINE (ขายสัตว์เลี้ยงอัตโนมัติ เก็บเฉพาะ N ตัวที่ดีที่สุด)
-- ==============================================================================
local isAutoSellingActive = false
local SliderKeepPetCount = nil
local InputCustomKeepCount = nil
local AutoSellStatusPara = nil

local function ExecuteAutoSellPets(targetCountOverride)
    if isAutoSellingActive then return false, "กำลังดำเนินการขายสัตว์เลี้ยงอยู่..." end
    local data = State.Data
    if not data or not data.Pets then return false, "ไม่มีข้อมูลสัตว์เลี้ยงในขณะนี้" end
    
    local targetKeep = targetCountOverride or CFG.KeepTopPetsCount or 100
    targetKeep = math.max(1, math.floor(tonumber(targetKeep) or 100))
    
    local stacks = State.Stacks()
    if not stacks or #stacks == 0 then return false, "ไม่พบรายการสัตว์เลี้ยงในกระเป๋า" end
    
    isAutoSellingActive = true
    local success, totalSoldOrErr, keptCount = pcall(function()
        local stackInfos = {}
        for _, s in ipairs(stacks) do
            local base = 0
            pcall(function() base = Stats.PetBaseIncome(s.Item) end)
            local def = PetData and PetData.ById and PetData.ById[s.Id]
            local isLimited = (def and def.Limited) or false
            
            -- ตรวจสอบตัวที่ล็อคไว้ (Locked Pets)
            local lockedCount = 0
            if data.Locked then
                if data.Locked[s.Key] then
                    lockedCount = s.Count
                else
                    for _, uid in ipairs(s.Uids or {}) do
                        if data.Locked[uid] then
                            lockedCount = lockedCount + 1
                        end
                    end
                end
            end
            
            table.insert(stackInfos, {
                stack = s,
                key = s.Key,
                id = s.Id,
                count = s.Count,
                equipped = s.Equipped or 0,
                locked = lockedCount,
                base = base,
                isLimited = isLimited,
                level = (s.Item and s.Item.L) or 1
            })
        end
        
        -- เรียงลำดับจากค่าพลัง Base มากที่สุดไปน้อยที่สุด (ตัวที่เก่งที่สุดจะถูกเก็บไว้)
        table.sort(stackInfos, function(a, b)
            if a.base ~= b.base then
                return a.base > b.base
            end
            if a.level ~= b.level then
                return a.level > b.level
            end
            return a.count > b.count
        end)
        
        local kept = 0
        local toSell = 0
        local sellBatches = {}
        local currentBatchKeys = {}
        local currentBatchAmounts = {}
        local batchCount = 0
        
        for _, info in ipairs(stackInfos) do
            local s = info.stack
            local totalInStack = info.count
            local protectedCount = math.max(info.equipped, info.locked)
            if info.isLimited then
                protectedCount = totalInStack -- สัตว์เลี้ยง Limited ปลอดภัยเสมอ ไม่ขายเด็ดขาด
            end
            
            local remainingToKeep = math.max(0, targetKeep - kept)
            local keepFromStack = math.min(totalInStack, remainingToKeep)
            keepFromStack = math.max(keepFromStack, protectedCount)
            
            local sellFromStack = totalInStack - keepFromStack
            local unequippedAndUnlocked = totalInStack - info.equipped - info.locked
            sellFromStack = math.clamp(sellFromStack, 0, math.max(0, unequippedAndUnlocked))
            
            kept = kept + (totalInStack - sellFromStack)
            
            if sellFromStack > 0 then
                toSell = toSell + sellFromStack
                table.insert(currentBatchKeys, s.Key)
                if sellFromStack < (totalInStack - info.equipped) then
                    currentBatchAmounts[s.Key] = sellFromStack
                end
                batchCount = batchCount + 1
                if batchCount >= 25 then
                    table.insert(sellBatches, { keys = currentBatchKeys, amounts = currentBatchAmounts })
                    currentBatchKeys = {}
                    currentBatchAmounts = {}
                    batchCount = 0
                end
            end
        end
        
        if #currentBatchKeys > 0 then
            table.insert(sellBatches, { keys = currentBatchKeys, amounts = currentBatchAmounts })
        end
        
        if toSell == 0 or #sellBatches == 0 then
            return 0, kept
        end
        
        -- ส่งคำสั่งขายแบบ Humanized Batch (ป้องกัน Anti-Cheat / Rate Limit 100%)
        for bIndex, batch in ipairs(sellBatches) do
            if getgenv().PetDiceScriptToken ~= scriptToken then break end
            State.Send("SellKeys", batch.keys, batch.amounts)
            if bIndex < #sellBatches then
                Humanizer.Wait(0.18, 0.28)
            end
        end
        
        return toSell, kept
    end)
    isAutoSellingActive = false
    
    if not success then
        return false, totalSoldOrErr
    end
    return true, totalSoldOrErr, keptCount
end

Tabs.Overview:AddSection("💰 ระบบขายสัตว์เลี้ยงอัตโนมัติ (Auto Sell Pets)")

AutoSellStatusPara = Tabs.Overview:AddParagraph({
    Title = "📊 สถานะระบบขายสัตว์เลี้ยง: กำลังคำนวณ...",
    Content = "กำลังตรวจสอบจำนวนสัตว์เลี้ยงและค่าพลัง Base..."
})

local TogAutoSell = Tabs.Overview:AddToggle("TogAutoSellPets", {
    Title = "💰 เปิดระบบขายสัตว์เลี้ยงอัตโนมัติ (Auto Sell Pets)",
    Default = CFG.AutoSellPets or false,
    Callback = function(v)
        UpdateCFG("AutoSellPets", v)
        if v then
            Notify("💰 ขายสัตว์เลี้ยง", "เปิดระบบขายสัตว์เลี้ยงอัตโนมัติแล้ว! จะเก็บเฉพาะ " .. (CFG.KeepTopPetsCount or 100) .. " ตัวที่เก่งที่สุด", 3)
            task.spawn(function()
                ExecuteAutoSellPets()
            end)
        else
            Notify("💰 ขายสัตว์เลี้ยง", "ปิดระบบขายสัตว์เลี้ยงอัตโนมัติเรียบร้อย", 2)
        end
    end
})

SliderKeepPetCount = Tabs.Overview:AddSlider("SliderKeepPetCount", {
    Title = "🎯 จำนวนสัตว์เลี้ยงที่ต้องการเก็บไว้ (Keep Top Pets)",
    Description = "เก็บเฉพาะตัวที่เก่งที่สุด เรียงจากค่าพลัง Base ส่วนที่เกินจะถูกขายอัตโนมัติ",
    Default = CFG.KeepTopPetsCount or 100,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(val)
        local n = math.floor(tonumber(val) or 100)
        UpdateCFG("KeepTopPetsCount", n)
    end
})

InputCustomKeepCount = Tabs.Overview:AddInput("InputCustomKeepCount", {
    Title = "🔢 พิมพ์จำนวนที่ต้องการเก็บเอง (Custom Count)",
    Default = tostring(CFG.KeepTopPetsCount or 100),
    Placeholder = "เช่น 50, 100, 150, 200, 300",
    Numeric = true,
    Finished = true,
    Callback = function(val)
        local num = tonumber(val)
        if num and num >= 1 then
            num = math.floor(num)
            UpdateCFG("KeepTopPetsCount", num)
            pcall(function()
                if SliderKeepPetCount then
                    SliderKeepPetCount:SetValue(math.clamp(num, 10, 500))
                end
            end)
            Notify("🎯 ตั้งค่าสำเร็จ", "ตั้งค่าเก็บสัตว์เลี้ยงที่ดีที่สุด " .. num .. " ตัวเรียบร้อย!", 2)
        end
    end
})

Tabs.Overview:AddButton({
    Title = "⚡ สั่งขายส่วนเกินทันที (Sell Excess Pets Now)",
    Description = "คัดแยกและขายสัตว์เลี้ยงที่เกินจากเป้าหมายทันทีตามค่าพลัง Base",
    Callback = function()
        task.spawn(function()
            Notify("💰 กำลังคำนวณ", "กำลังตรวจสอบและคัดกรองสัตว์เลี้ยงตามค่าพลัง Base...", 2)
            local ok, sold, kept = ExecuteAutoSellPets()
            if ok then
                if sold and sold > 0 then
                    Notify("✅ ขายสำเร็จ", string.format("ขายสัตว์เลี้ยงส่วนเกินเรียบร้อย! ขายไป %s ตัว (คงเหลือ %s ตัวที่ดีที่สุด)", Format.Commas(sold), Format.Commas(kept)), 4)
                else
                    Notify("ℹ️ ไม่มีส่วนเกิน", "จำนวนสัตว์เลี้ยงปัจจุบันไม่เกินเป้าหมายที่ตั้งไว้ (" .. (CFG.KeepTopPetsCount or 100) .. " ตัว)", 3)
                end
            else
                Notify("❌ เกิดข้อผิดพลาด", tostring(sold or "ไม่สามารถขายได้"), 3)
            end
        end)
    end
})

local function UpdateOverviewTab()
    pcall(function()
        local data = State.Data
        if not data then return end
        
        -- Update Overview Stats
        local moneyStr = Format.Money(data.Money or 0)
        local gemsStr = Format.Commas(data.Gems or 0)
        local shardsStr = Format.Commas(data.Shards or 0)
        local candyStr = Format.Commas((data.Season and data.Season.Candy) or 0)
        local towerFloor = (data.TowerResume and data.TowerResume.Floor) or (data.TowerBest and data.TowerBest.Infinity) or 0
        local totalPets = 0
        if data.Pets then for _ in pairs(data.Pets) do totalPets = totalPets + 1 end end
        
        OverviewStats:SetTitle(string.format("💰 เงิน: %s | 💎 เพชร: %s | 🔮 ชาร์ด: %s", moneyStr, gemsStr, shardsStr))
        OverviewStats:SetDesc(string.format("🏰 หอคอยชั้น: %d | 🐾 สัตว์เลี้ยงทั้งหมด: %d ตัว | 🍬 ลูกอม: %s", towerFloor, totalPets, candyStr))
        
        -- Update Auto Sell Stats
        if AutoSellStatusPara then
            local targetK = CFG.KeepTopPetsCount or 100
            local excess = math.max(0, totalPets - targetK)
            local statusText = CFG.AutoSellPets and "🟢 เปิดทำงานอัตโนมัติ" or "⚪ ปิดการทำงาน"
            if isAutoSellingActive then
                statusText = "🟡 กำลังดำเนินการขาย..."
            end
            AutoSellStatusPara:SetTitle(string.format("📊 สถานะ: %s | มีทั้งหมด: %s ตัว | เป้าหมายเก็บไว้: %s ตัว", statusText, Format.Commas(totalPets), Format.Commas(targetK)))
            AutoSellStatusPara:SetDesc(string.format("ส่วนเกินที่จะขาย: %s ตัว (เรียงจากค่าพลัง Base สูงสุดลงไป | สัตว์เลี้ยงที่สวมใส่และล็อคจะได้รับการปกป้อง 100%%)", Format.Commas(excess)))
        end
        
        -- Update Best Pets
        local count = CFG.EnhancePetCount or 4
        local uids = GetTopBestPets(count)
        local cap = Stats.PetLevelCap(data.Upgrades)
        local targetLvl = math.min(CFG.TargetPetLevel or cap, cap)
        local targetGradeRank = CFG.TargetGradeRank or 8
        local targetTraitRank = CFG.TargetTraitRank or 6
        
        for i = 1, 8 do
            if i <= count and uids[i] then
                local pet = data.Pets[uids[i]]
                if pet then
                    local gId = pet.G
                    local tId = pet.T
                    local gName = gId and (GradeNameById[gId] or gId) or "None"
                    local tName = tId and (TraitNameById[tId] or tId) or "None"
                    local lvl = pet.L or 0
                    local baseInc = 0
                    pcall(function() baseInc = Stats.PetBaseIncome(pet) end)
                    local baseStr = Format.Money(baseInc)
                    
                    local gLocked = IsPetGradeLocked(pet, targetGradeRank)
                    local tLocked = IsPetTraitLocked(pet, targetTraitRank)
                    local lDone = lvl >= targetLvl
                    
                    local statusTags = {}
                    if lDone then table.insert(statusTags, "LVเป้าหมาย") end
                    if gLocked and tLocked then
                        table.insert(statusTags, "🔒ล็อคครบ")
                    else
                        if gLocked then table.insert(statusTags, "🔒เกรดล็อค") end
                        if tLocked then table.insert(statusTags, "🔒บัฟล็อค") end
                    end
                    local tagStr = #statusTags > 0 and (" [" .. table.concat(statusTags, ", ") .. "]") or ""
                    
                    PetCardParagraphs[i]:SetTitle(string.format("⭐ #%d: %s %s", i, pet.Id, tagStr))
                    PetCardParagraphs[i]:SetDesc(string.format("รายได้ฐาน: %s/s | เลเวล: %d/%d | เกรด: %s | บัฟ: %s", baseStr, lvl, targetLvl, gName, tName))
                else
                    PetCardParagraphs[i]:SetTitle(string.format("💤 #%d: ไม่มีข้อมูลสัตว์เลี้ยง", i))
                    PetCardParagraphs[i]:SetDesc("ยังไม่มีสัตว์เลี้ยงในตำแหน่งนี้")
                end
            else
                PetCardParagraphs[i]:SetTitle(string.format("➖ #%d: ปิดการทำงาน", i))
                PetCardParagraphs[i]:SetDesc(string.format("เลือกทำ %d ตัวแรก (ปรับเพิ่มได้ในแท็บอัปเกรด)", count))
            end
        end
    end)
end

task.spawn(UpdateOverviewTab)
task.spawn(function()
    while true do
        task.wait(2.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        UpdateOverviewTab()
    end
end)

-- ------------------------------------------------------------------------------
-- ⭐ TAB 2: ENHANCE & ROLL BUFFS
-- ------------------------------------------------------------------------------
Tabs.Enhance:AddSection("⚙️ ตั้งค่าสัตว์เลี้ยงและเป้าหมาย")

local SliderEnhancePetCount, InputCustomEnhancePetCount
local SliderRollSpeed, InputCustomRollSpeed
local SliderTargetPetLevel, InputCustomTargetPetLevel
local DropUpgradeLevelStep, InputCustomUpgradeStep

SliderEnhancePetCount = Tabs.Enhance:AddSlider("SliderEnhancePetCount", {
    Title = "จำนวนสัตว์เลี้ยงที่จะอัปเกรด (1 - 8 ตัว)",
    Description = "เลือกจำนวนสัตว์เลี้ยงที่ดีที่สุดที่จะสั่งอัปเลเวลและสุ่มบัฟ",
    Default = CFG.EnhancePetCount or 4,
    Min = 1,
    Max = 8,
    Rounding = 0,
    Callback = function(V)
        UpdateCFG("EnhancePetCount", V)
        pcall(function()
            if InputCustomEnhancePetCount and InputCustomEnhancePetCount.Value ~= tostring(V) then
                InputCustomEnhancePetCount:SetValue(tostring(V))
            end
        end)
        UpdateOverviewTab()
    end
})

InputCustomEnhancePetCount = Tabs.Enhance:AddInput("InputCustomEnhancePetCount", {
    Title = "✏️ กำหนดจำนวนสัตว์เลี้ยงเอง (พิมพ์ตัวเลข 1 - 8)",
    Default = tostring(CFG.EnhancePetCount or 4),
    Placeholder = "พิมพ์จำนวน เช่น 1 - 8...",
    Numeric = true,
    Finished = true,
    Callback = function(val)
        local n = tonumber(val)
        if n and n >= 1 then
            n = math.clamp(math.floor(n), 1, 8)
            UpdateCFG("EnhancePetCount", n)
            pcall(function()
                if SliderEnhancePetCount and SliderEnhancePetCount.Value ~= n then
                    SliderEnhancePetCount:SetValue(n)
                end
            end)
            UpdateOverviewTab()
            Notify("🐾 อัปเกรด", "ตั้งค่าจำนวนสัตว์เลี้ยงเป็น " .. n .. " ตัว", 2)
        end
    end
})

SliderRollSpeed = Tabs.Enhance:AddSlider("SliderRollSpeed", {
    Title = "⚡ ความเร็วในการสุ่มบัฟ/เกรด (0.15 - 1.00 วินาที)",
    Description = "ความหน่วงระหว่างการสุ่ม (แนะนำ 0.20 - 0.30 วิ = เร็วสุดและปลอดภัยจากระบบตรวจจับ 100%)",
    Default = CFG.RollSpeed or 0.25,
    Min = 0.15,
    Max = 1.00,
    Rounding = 2,
    Callback = function(V)
        UpdateCFG("RollSpeed", V)
        pcall(function()
            if InputCustomRollSpeed and InputCustomRollSpeed.Value ~= tostring(V) then
                InputCustomRollSpeed:SetValue(tostring(V))
            end
        end)
    end
})

InputCustomRollSpeed = Tabs.Enhance:AddInput("InputCustomRollSpeed", {
    Title = "✏️ กำหนดความเร็วในการสุ่มเอง (พิมพ์วินาที)",
    Default = tostring(CFG.RollSpeed or 0.25),
    Placeholder = "พิมพ์ความเร็ว เช่น 0.20, 0.25...",
    Numeric = true,
    Finished = true,
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then
            local safeN = math.max(0.12, math.floor(n * 100 + 0.5) / 100)
            UpdateCFG("RollSpeed", safeN)
            pcall(function()
                if safeN >= 0.15 and safeN <= 1.00 and SliderRollSpeed then
                    SliderRollSpeed:SetValue(safeN)
                end
            end)
            Notify("⚡ ความเร็วสุ่ม", "ตั้งค่าความเร็วสุ่มเป็น " .. safeN .. " วินาที", 2)
        end
    end
})

SliderTargetPetLevel = Tabs.Enhance:AddSlider("SliderTargetPetLevel", {
    Title = "🎯 เลเวลเป้าหมายสูงสุดที่ต้องการ (1 - 100)",
    Description = "สัตว์เลี้ยงที่เลเวลถึงเป้าหมายนี้แล้ว จะหยุดอัปทันที",
    Default = CFG.TargetPetLevel or 100,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(V)
        UpdateCFG("TargetPetLevel", V)
        pcall(function()
            if InputCustomTargetPetLevel and InputCustomTargetPetLevel.Value ~= tostring(V) then
                InputCustomTargetPetLevel:SetValue(tostring(V))
            end
        end)
        UpdateOverviewTab()
    end
})

InputCustomTargetPetLevel = Tabs.Enhance:AddInput("InputCustomTargetPetLevel", {
    Title = "✏️ กำหนดเลเวลเป้าหมายเอง (พิมพ์ตัวเลข)",
    Default = tostring(CFG.TargetPetLevel or 100),
    Placeholder = "พิมพ์เลเวล เช่น 50, 100, 200...",
    Numeric = true,
    Finished = true,
    Callback = function(val)
        local n = tonumber(val)
        if n and n >= 1 then
            local lvl = math.floor(n)
            UpdateCFG("TargetPetLevel", lvl)
            pcall(function()
                if lvl >= 1 and lvl <= 100 and SliderTargetPetLevel then
                    SliderTargetPetLevel:SetValue(lvl)
                end
            end)
            UpdateOverviewTab()
            Notify("🎯 เลเวลเป้าหมาย", "ตั้งค่าเลเวลเป้าหมายเป็น " .. lvl, 2)
        end
    end
})

DropUpgradeLevelStep = Tabs.Enhance:AddDropdown("DropUpgradeLevelStep", {
    Title = "⚡ รูปแบบ / จำนวนเลเวลที่จะอัปต่อรอบ",
    Description = "เลือกจำนวนขั้นเลเวลที่จะส่งคำสั่งอัปเกรด",
    Values = UpgradeStepOptions,
    Default = CFG.UpgradeLevelStepName or "+1 เลเวล (ทีละ 1 ขั้น - ปลอดภัยสูงสุด)",
    Multi = false,
    Callback = function(val)
        UpdateCFG("UpgradeLevelStepName", val)
        local step = UpgradeStepMap[val] or 1
        UpdateCFG("UpgradeLevelStep", step)
        pcall(function()
            if InputCustomUpgradeStep and InputCustomUpgradeStep.Value ~= tostring(step) then
                InputCustomUpgradeStep:SetValue(tostring(step))
            end
        end)
    end
})

InputCustomUpgradeStep = Tabs.Enhance:AddInput("InputCustomUpgradeStep", {
    Title = "✏️ กำหนดจำนวนเลเวลที่จะอัปเองต่อรอบ (พิมพ์ตัวเลข)",
    Default = tostring(CFG.UpgradeLevelStep or 1),
    Placeholder = "พิมพ์จำนวนเลเวล เช่น 1, 5, 10, 25...",
    Numeric = true,
    Finished = true,
    Callback = function(val)
        local n = tonumber(val)
        if n and n >= 1 then
            local step = math.floor(n)
            UpdateCFG("UpgradeLevelStep", step)
            UpdateCFG("UpgradeLevelStepName", "กำหนดเอง: +" .. step .. " เลเวล")
            Notify("⚡ อัปเลเวล", "ตั้งค่าการอัปเกรดเป็นครั้งละ " .. step .. " เลเวล", 2)
        end
    end
})

Tabs.Enhance:AddDropdown("DropTargetGrade", {
    Title = "🎯 เกรดเป้าหมายขั้นต่ำ",
    Description = "ระบบจะหยุดสุ่มเกรดทันทีเมื่อได้เกรดนี้หรือสูงกว่า",
    Values = GradeOptions,
    Default = CFG.TargetGradeName or "S (Rank 8)",
    Multi = false,
    Callback = function(val)
        UpdateCFG("TargetGradeName", val)
        UpdateCFG("TargetGradeRank", GradeRankMap[val] or 8)
        UpdateOverviewTab()
    end
})

Tabs.Enhance:AddDropdown("DropTargetTrait", {
    Title = "🎯 คุณสมบัติบัฟเป้าหมายขั้นต่ำ",
    Description = "ระบบจะหยุดสุ่มบัฟทันทีเมื่อได้บัฟนี้หรือสูงกว่า",
    Values = TraitOptions,
    Default = CFG.TargetTraitName or "VALIANT (Rank 6)",
    Multi = false,
    Callback = function(val)
        UpdateCFG("TargetTraitName", val)
        UpdateCFG("TargetTraitRank", TraitRankMap[val] or 6)
        UpdateOverviewTab()
    end
})

Tabs.Enhance:AddSection("⚡ สั่งการด่วน (1 คลิก - ปลอดภัย ไม่สุ่มทับตัวล็อค)")

Tabs.Enhance:AddButton({
    Title = "⭐ อัปเลเวลสัตว์เลี้ยงที่ดีที่สุดตามที่เลือก (1 คลิก)",
    Description = "อัปเลเวลสัตว์เลี้ยงตามเงื่อนไขเป้าหมายและจำนวนขั้นที่เลือก",
    Callback = function()
        task.spawn(function()
            local data = State.Data
            if not data or not data.Pets or not data.Money then return end
            local cap = Stats.PetLevelCap(data.Upgrades)
            local targetLvl = math.min(CFG.TargetPetLevel or cap, cap)
            local step = CFG.UpgradeLevelStep or 1
            local uids = GetTopBestPets(CFG.EnhancePetCount or 4)
            local upgradedPets = 0
            local totalLevels = 0
            
            for _, uid in ipairs(uids) do
                local pet = data.Pets[uid]
                if pet and (pet.L or 0) < targetLvl then
                    local curLvl = pet.L or 0
                    local needed = targetLvl - curLvl
                    local countToUpgrade = math.min(needed, step)
                    if step >= 999 then countToUpgrade = needed end
                    
                    local affordable = FindAffordableLevels(pet, data.Upgrades, data.Money, countToUpgrade)
                    if affordable > 0 then
                        if affordable == 1 then
                            Fire("UpgradePet", uid)
                        else
                            Fire("UpgradePetLevels", uid, affordable)
                        end
                        upgradedPets = upgradedPets + 1
                        totalLevels = totalLevels + affordable
                        Humanizer.Wait(0.4, 0.7)
                        data = State.Data
                        if not data or not data.Money or data.Money <= 0 then break end
                    end
                end
            end
            
            Notify("⭐ อัปเลเวลสัตว์เลี้ยง", 
                totalLevels > 0 and ("อัปเลเวลแล้ว " .. upgradedPets .. " ตัว (รวม +" .. totalLevels .. " เลเวล)!") or "สัตว์เลี้ยงถึงเลเวลเป้าหมายแล้ว หรือเงินไม่พอ", 
                3
            )
            UpdateOverviewTab()
        end)
    end
})

Tabs.Enhance:AddButton({
    Title = "💎 สุ่มเกรดสัตว์เลี้ยงที่ดีที่สุด 1 ครั้งต่อตัว (ข้ามตัวล็อค)",
    Description = "สุ่มเฉพาะตัวที่ยังไม่ถึงเกรดเป้าหมาย ตัวที่ล็อคแล้วจะไม่โดนสุ่มทับ",
    Callback = function()
        task.spawn(function()
            local data = State.Data
            if not data or not data.Pets or not data.Gems or data.Gems < 1 then
                Notify("⚠️ เพชรไม่พอ (Gems)", "คุณมีเพชรไม่พอสำหรับการสุ่มเกรด", 3)
                return
            end
            local targetRank = CFG.TargetGradeRank or 8
            local uids = GetTopBestPets(CFG.EnhancePetCount or 4)
            local rollDelay = math.clamp(CFG.RollSpeed or 0.25, 0.15, 1.0)
            local rolled = 0
            local skipped = 0
            for _, uid in ipairs(uids) do
                if not data or not data.Gems or data.Gems < 1 then break end
                local pet = data.Pets[uid]
                if pet then
                    if IsPetGradeLocked(pet, targetRank) then
                        skipped = skipped + 1
                    else
                        Fire("RollGrade", uid)
                        rolled = rolled + 1
                        Humanizer.Wait(math.max(0.12, rollDelay - 0.04), rollDelay + 0.04)
                        data = State.Data
                    end
                end
            end
            Notify("💎 สุ่มเกรดสัตว์เลี้ยง",
                rolled > 0 and ("สุ่มเกรดแล้ว " .. rolled .. " ตัว (ข้ามตัวล็อค " .. skipped .. " ตัว)") or "สัตว์เลี้ยงทั้งหมดถึงเกรดเป้าหมายแล้ว (🔒ล็อคปลอดภัย)",
                3
            )
            UpdateOverviewTab()
        end)
    end
})

Tabs.Enhance:AddButton({
    Title = "🔮 สุ่มคุณสมบัติ (Trait) สัตว์เลี้ยงที่ดีที่สุด 1 ครั้งต่อตัว (ข้ามตัวล็อค)",
    Description = "สุ่มเฉพาะตัวที่ยังไม่ถึงบัฟเป้าหมาย ตัวที่ได้บัฟเท่ากับหรือสูงกว่าจะถูกข้าม",
    Callback = function()
        task.spawn(function()
            local data = State.Data
            if not data or not data.Pets or not data.Shards or data.Shards < 1 then
                Notify("⚠️ ชาร์ดไม่พอ (Shards)", "คุณมี Shards ไม่พอสำหรับการสุ่มคุณสมบัติ", 3)
                return
            end
            local targetRank = CFG.TargetTraitRank or 6
            local uids = GetTopBestPets(CFG.EnhancePetCount or 4)
            local rollDelay = math.clamp(CFG.RollSpeed or 0.25, 0.15, 1.0)
            local rolled = 0
            local skipped = 0
            for _, uid in ipairs(uids) do
                if not data or not data.Shards or data.Shards < 1 then break end
                local pet = data.Pets[uid]
                if pet then
                    if IsPetTraitLocked(pet, targetRank) then
                        skipped = skipped + 1
                    else
                        Fire("RollTrait", uid)
                        rolled = rolled + 1
                        Humanizer.Wait(math.max(0.12, rollDelay - 0.04), rollDelay + 0.04)
                        data = State.Data
                    end
                end
            end
            Notify("🔮 สุ่มคุณสมบัติสัตว์เลี้ยง",
                rolled > 0 and ("สุ่มคุณสมบัติแล้ว " .. rolled .. " ตัว (ข้ามตัวล็อค " .. skipped .. " ตัว)") or "สัตว์เลี้ยงทั้งหมดถึงบัฟเป้าหมายแล้ว (🔒ล็อคปลอดภัย)",
                3
            )
            UpdateOverviewTab()
        end)
    end
})

Tabs.Enhance:AddSection("🔄 ระบบอัปเกรดอัตโนมัติแบบเรียลไทม์")

Tabs.Enhance:AddToggle("TogAutoPetLvl", {
    Title = "1. อัปเลเวลสัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (Auto Upgrade Level)",
    Default = CFG.AutoUpgradePetLevel,
    Callback = function(V) UpdateCFG("AutoUpgradePetLevel", V) end
})

Tabs.Enhance:AddToggle("TogAutoPetGrade", {
    Title = "2. สุ่มเกรดสัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (หยุดเมื่อถึงเป้าหมาย)",
    Default = CFG.AutoRollGrade,
    Callback = function(V) UpdateCFG("AutoRollGrade", V) end
})

Tabs.Enhance:AddToggle("TogAutoPetTrait", {
    Title = "3. สุ่มคุณสมบัติสัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (หยุดเมื่อถึงเป้าหมาย)",
    Default = CFG.AutoRollTrait,
    Callback = function(V) UpdateCFG("AutoRollTrait", V) end
})

-- ------------------------------------------------------------------------------
-- 🏰 TAB 3: TOWER & DICE
-- ------------------------------------------------------------------------------
Tabs.Tower:AddSection("📊 สถานะหอคอยแบบเรียลไทม์ (Live Tower Status)")

-- ==============================================================================
-- [REAL-TIME LIVE TOWER TRACKER & DEEP GAME SYNC]
-- ==============================================================================
local LiveTower = {
    Active = false,
    Starting = false,
    TowerId = nil,
    Floor = 0,
    InArena = false,
    Away = false,
    LastResult = nil,
    LastFloor = 0,
    LastFinishedId = nil,
    LastEventTime = 0,
    LastStartTick = 0,
    SwitchingTick = 0,
    JustEnded = false,
    EndedTick = 0
}

local IsEnteringBossPortal = false

-- ดึงรายชื่อหอคอยทั้งหมด 1-7 จากตัวเกมจริง
local elemThai = {
    Nature = "พืช/ธรรมชาติ",
    Fire = "ไฟ",
    Water = "น้ำ",
    Ice = "น้ำแข็ง",
    Electric = "สายฟ้า",
    Cosmic = "คอสมิก"
}
local dynamicTowerOptions = {}
local towerIdByOption = {}
local defaultTowerOpt = "ด่าน 7: INFINITY TOWER (ไร้สิ้นสุด) [Infinity]"

if Towers and Towers.List then
    for i, t in ipairs(Towers.List) do
        local elemName = t.Element and (elemThai[t.Element] or tostring(t.Element)) or "ไร้สิ้นสุด"
        local optName = string.format("ด่าน %d: %s (%s) [%s]", t.Index or i, t.Name, elemName, t.Id)
        table.insert(dynamicTowerOptions, optName)
        towerIdByOption[optName] = t.Id
        if t.Id == "Infinity" then
            defaultTowerOpt = optName
        end
    end
end
if #dynamicTowerOptions == 0 then
    defaultTowerOpt = "ด่าน 7: INFINITY TOWER (ไร้สิ้นสุด) [Infinity]"
    dynamicTowerOptions = { defaultTowerOpt }
    towerIdByOption[defaultTowerOpt] = "Infinity"
end

if not CFG.SelectedTower or CFG.SelectedTower == "Meadow" or CFG.SelectedTower == "" then
    CFG.SelectedTower = "Infinity"
    CFG.SelectedTowerOption = defaultTowerOpt
elseif not CFG.SelectedTowerOption or CFG.SelectedTowerOption:find("Meadow") then
    CFG.SelectedTowerOption = defaultTowerOpt
end

local SwitchOrStartTower
local isSwitchingTower = false
local lastLoopStartAttempt = 0  -- shared across TogTower + supervisor loops

local function ResolveTowerId(val)
    if not val or val == "" or val == "Meadow" then return "Infinity" end
    if Towers and Towers.ById and Towers.ById[val] then return val end
    if towerIdByOption and towerIdByOption[val] then return towerIdByOption[val] end
    if typeof(val) == "string" then
        local matched = val:match("%[([%w_]+)%]")
        if matched and Towers and Towers.ById and Towers.ById[matched] then return matched end
    end
    return "Infinity"
end

local function GetSelectedTowerId()
    return ResolveTowerId(CFG.SelectedTower)
end

local function GetCurrentOrNextTowerId(advance)
    return GetSelectedTowerId()
end

pcall(function()
    if getgenv().PetDiceBattleConn then
        pcall(function() getgenv().PetDiceBattleConn:Disconnect() end)
        getgenv().PetDiceBattleConn = nil
    end
    local BattleRemote = PetDice:WaitForChild("Remotes"):WaitForChild("Battle")
    getgenv().PetDiceBattleConn = BattleRemote.OnClientEvent:Connect(function(action, payload)
        if getgenv().PetDiceScriptToken ~= scriptToken then return end
        local now = tick()
        if (action == "Floor" or action == "Start" or action == "Enter" or action == "Init") and typeof(payload) == "table" then
            LiveTower.Active = true
            LiveTower.Starting = false
            LiveTower.JustEnded = false
            LiveTower.EndAutoCountdown = nil
            LiveTower.TowerId = payload.Tower or LiveTower.TowerId
            LiveTower.Floor = tonumber(payload.Floor) or LiveTower.Floor
            LiveTower.LastFloorTime = now
            if payload.Away ~= nil then
                LiveTower.Away = payload.Away == true
                LiveTower.InArena = not payload.Away
            end
            LiveTower.LastEventTime = now
        elseif action == "Away" and typeof(payload) == "table" then
            if payload.Away then
                LiveTower.Away = true
                LiveTower.InArena = false
            else
                LiveTower.InArena = true
                LiveTower.Away = false
            end
            LiveTower.LastEventTime = now
        elseif action == "Clear" and typeof(payload) == "table" then
            LiveTower.Active = true
            LiveTower.Floor = tonumber(payload.Floor) or LiveTower.Floor
            LiveTower.LastFloorTime = now
            LiveTower.LastEventTime = now
        elseif action == "End" and typeof(payload) == "table" then
            LiveTower.Active = false
            LiveTower.Starting = false
            LiveTower.JustEnded = true
            LiveTower.EndedTick = now
            LiveTower.LastResult = payload.Result
            LiveTower.LastFinishedId = payload.Tower or LiveTower.TowerId
            LiveTower.LastFloor = tonumber(payload.Floor) or LiveTower.Floor
            
            LiveTower.TowerId = nil
            LiveTower.Floor = 0
            LiveTower.InArena = false
            LiveTower.Away = false
            LiveTower.LastEventTime = now
            
            -- ปิด BattleResults UI ทันทีเพื่อไม่ให้หน้าต่างผลลัพธ์บังหน้าจอ
            pcall(function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                local br = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root:FindFirstChild("Effects") and pg.PetDiceUI.Root.Effects:FindFirstChild("BattleResults")
                if br then br.Visible = false end
            end)
            
            -- [AUTO-LOOP RESTART]: เมื่อหอคอยจบรอบ ให้เริ่มรอบใหม่ทันทีอย่างต่อเนื่อง
            if CFG.Tower and getgenv().PetDiceScriptToken == scriptToken then
                task.spawn(function()
                    local delaySec = math.max(1.5, tonumber(CFG.TowerRestartDelay) or 2.5)
                    task.wait(delaySec)
                    if CFG.Tower and getgenv().PetDiceScriptToken == scriptToken and not IsTowerRunning() then
                        local targetId = ResolveTowerId(CFG.SelectedTower)
                        SwitchOrStartTower(targetId, true)
                    end
                end)
            end
        elseif action == "Stopped" or action == "Paused" then
            LiveTower.Active = false
            LiveTower.Starting = false
            LiveTower.TowerId = nil
            LiveTower.Floor = 0
            LiveTower.InArena = false
            LiveTower.Away = false
            LiveTower.LastEventTime = now
        end
    end)
end)

local function SyncLiveTowerFromGame()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local root = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI:FindFirstChild("Root")
    
    -- หากมีหน้าต่าง BattleResults แสดงอยู่ แสดงว่าการลงหอคอยจบรอบแล้ว ให้ปิดป๊อปอัปและรีเซ็ตสถานะ
    local br = root and root:FindFirstChild("Effects") and root.Effects:FindFirstChild("BattleResults")
    if br and br.Visible == true then
        br.Visible = false
        LiveTower.Active = false
        LiveTower.Starting = false
        LiveTower.TowerId = nil
        LiveTower.InArena = false
        LiveTower.Away = false
        return
    end
    
    local hud = root and root:FindFirstChild("Hud")
    local tracker = hud and hud:FindFirstChild("TowerTracker")
    local battle = hud and hud:FindFirstChild("Battle")
    
    local isAway = tracker and tracker.Visible == true
    local isArena = battle and battle.Visible == true
    
    -- ตรวจสอบว่า UI กำลังแสดงผลช่วงจบหรือนับถอยหลังรอบใหม่หรือไม่
    local isCountdown = false
    local isClearStuck = false
    local now = tick()
    
    if isAway and tracker then
        for _, lbl in ipairs(tracker:GetDescendants()) do
            if lbl:IsA("TextLabel") and lbl.Text ~= "" then
                local txt = lbl.Text:upper()
                if txt:find("NEXT RUN IN") or txt:find("STARTING...") or txt:find("VICTORY") or txt:find("DEFEAT") or txt:find("TIME'S UP") or txt:find("LEFT TOWER") or txt:find("แพ้") or txt:find("หมดเวลา") then
                    isCountdown = true
                    break
                elseif (txt:find("CLEAR") or txt:find("เคลียร์")) and LiveTower.LastFloorTime and (now - LiveTower.LastFloorTime > 12.0) then
                    isClearStuck = true
                    break
                end
            end
        end
    end
    if isArena and battle then
        for _, lbl in ipairs(battle:GetDescendants()) do
            if lbl:IsA("TextLabel") and lbl.Text ~= "" then
                local txt = lbl.Text:upper()
                if txt:find("NEXT RUN IN") or txt:find("STARTING...") or txt:find("VICTORY") or txt:find("DEFEAT") or txt:find("TIME'S UP") or txt:find("LEFT TOWER") or txt:find("แพ้") or txt:find("หมดเวลา") then
                    isCountdown = true
                    break
                elseif (txt:find("CLEAR") or txt:find("เคลียร์")) and LiveTower.LastFloorTime and (now - LiveTower.LastFloorTime > 12.0) then
                    isClearStuck = true
                    break
                end
            end
        end
    end
    
    if isCountdown or isClearStuck then
        LiveTower.Active = false
        LiveTower.Starting = false
        LiveTower.TowerId = nil
        LiveTower.InArena = false
        LiveTower.Away = false
        return
    end
    
    -- 1. ดึงข้อมูลจาก UI จริงของตัวเกม (TowerTracker บน HUD หรือ Battle ในอารีน่า)
    if isAway or isArena then
        LiveTower.Active = true
        LiveTower.Starting = false
        LiveTower.JustEnded = false
        LiveTower.InArena = isArena
        LiveTower.Away = isAway
        
        local container = (isArena and battle) or tracker
        for _, lbl in ipairs(container:GetDescendants()) do
            if lbl:IsA("TextLabel") and lbl.Text ~= "" then
                local txt = lbl.Text:upper()
                for _, t in ipairs(Towers.List or {}) do
                    if txt:find(t.Name:upper(), 1, true) or (t.Id and txt:find(t.Id:upper(), 1, true)) then
                        LiveTower.TowerId = t.Id
                        break
                    end
                end
                local f = txt:match("FLOOR%s+(%d+)") or txt:match("STAGE%s+(%d+)") or txt:match("ชั้น%s*(%d+)")
                if f then
                    LiveTower.Floor = tonumber(f) or LiveTower.Floor
                end
            end
        end
        if not LiveTower.TowerId then
            LiveTower.TowerId = GetSelectedTowerId() or "Infinity"
        end
        LiveTower.LastEventTime = tick()
        return
    end
    
    -- 2. ระบบรอช่วงเริ่มหอคอย (Grace Period ป้องกันความเข้าใจผิดระหว่างวาร์ป / โหลดเข้าหอ)
    local now = tick()
    local timeSinceStart = now - (LiveTower.LastStartTick or 0)
    if LiveTower.Starting and timeSinceStart < 8.0 then
        return
    end
    
    -- 3. หากไม่มี UI แสดงว่าตัวละครไม่ได้อยู่ในหอคอยจริง
    LiveTower.Active = false
    LiveTower.Starting = false
    LiveTower.TowerId = nil
    LiveTower.InArena = false
    LiveTower.Away = false
end

local function GetActiveTowerId()
    SyncLiveTowerFromGame()
    if LiveTower.Active then
        return LiveTower.TowerId or GetCurrentOrNextTowerId(false) or "Infinity"
    end
    return nil
end

local function IsTowerRunning()
    SyncLiveTowerFromGame()
    return LiveTower.Active == true
end

local function IsTowerInArena()
    SyncLiveTowerFromGame()
    return LiveTower.Active == true and LiveTower.InArena == true
end

local function GetCurrentTowerFloor()
    SyncLiveTowerFromGame()
    if LiveTower.Active and LiveTower.Floor and LiveTower.Floor > 0 then
        return LiveTower.Floor
    end
    return 0
end

local TowerStatusPara = Tabs.Tower:AddParagraph({
    Title = "⏳ กำลังโหลดสถานะหอคอย...",
    Content = "กำลังตรวจสอบชั้นและสถานะการลงหอคอย..."
})

local BossStatusPara = Tabs.Tower:AddParagraph({
    Title = "⏳ กำลังโหลดสถานะบอสโลก...",
    Content = "กำลังตรวจสอบกำหนดการและระดับของบอสโลก..."
})

local function SafeWalkToBossPortal()
    IsEnteringBossPortal = true
    local ok, res = pcall(function()
        local char = LocalPlayer.Character or Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hum or not hrp or hum.Health <= 0 then return false end
        
        local portalModel = workspace:FindFirstChild("Market") and workspace.Market:FindFirstChild("WorldBossPortal")
        local promptSpot = portalModel and portalModel:FindFirstChild("PromptSpot")
        local targetPos = promptSpot and promptSpot.Position or Vector3.new(0, 20.43, -298)
        
        -- หากตัวละครอยู่ไกลเกิน 45 studs ใช้ระบบการเดินทางอย่างเป็นทางการของตัวเกม (Teleport: Portal)
        -- ซึ่งเซิร์ฟเวอร์ตัวเกมจะนำพาตัวละครมาส่งที่หน้าบันไดพิกัด (0, 5.35, -254) อย่างถูกต้อง 100% ไร้การปรับแต่ง CFrame
        if (hrp.Position - targetPos).Magnitude > 45 then
            Humanizer.Wait(0.5, 1.0)
            Fire("Teleport", "Portal")
            
            local t0 = tick()
            while tick() - t0 < 3.5 do
                task.wait(0.1)
                char = LocalPlayer.Character or Character
                hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - Vector3.new(0, 5.35, -254)).Magnitude < 15 then
                    break
                end
            end
            -- หน่วงเวลาพักหลังลงจอด เลียนแบบผู้เล่นจริง
            Humanizer.Wait(0.5, 0.9)
        end
        
        char = LocalPlayer.Character or Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return false end
        
        -- เดินก้าวขึ้นบันไดตามความชันจริงด้วย Humanoid:MoveTo ไปยังแท่นชานชาลา TopTile (0, 20.43, -288)
        if (hrp.Position - Vector3.new(0, 20.43, -288)).Magnitude > 6 then
            hum:MoveTo(Vector3.new(0, 20.43, -288))
            local walkStart = tick()
            while tick() - walkStart < 3.0 do
                task.wait(0.05)
                if not hum or not hrp then break end
                if (hrp.Position - Vector3.new(0, 20.43, -288)).Magnitude <= 5 then
                    break
                end
            end
        end
        
        -- เดินก้าวเท้าเข้าสู่โซนประตู JoinZone / Prompt (0, 20.43, -298) อย่างเป็นธรรมชาติ
        if hum and hrp then
            hum:MoveTo(targetPos)
            local walkStart = tick()
            while tick() - walkStart < 2.0 do
                task.wait(0.05)
                if not hum or not hrp then break end
                if (hrp.Position - targetPos).Magnitude <= 5 then
                    break
                end
            end
        end
        
        return true
    end)
    IsEnteringBossPortal = false
    return ok and res
end

local lastTowerStartTick = 0

local function GetTowerTeam(towerDef, teamSize)
    local data = State.Data
    if not data or not data.Pets then return {} end
    
    local targetSize = teamSize or 4
    pcall(function()
        if Towers and Towers.TeamSizeFor then
            targetSize = Towers.TeamSizeFor(data) or targetSize
        end
    end)
    
    local team = {}
    
    -- 1. คัดเลือกสัตว์เลี้ยงที่ดีที่สุดตามธาตุหอคอยผ่าน TeamPairs.Best
    if towerDef and towerDef.Element and TeamPairs and TeamPairs.Best then
        pcall(function()
            local res = TeamPairs.Best(data, towerDef, targetSize)
            if res and #res > 0 then team = res end
        end)
    end
    
    -- 2. กรณีไม่มีธาตุหรือเป็นหอ Infinity ให้ใช้ธาตุเริ่มต้นเพื่อป้องกันข้อผิดพลาด
    if #team == 0 and TeamPairs and TeamPairs.Best then
        pcall(function()
            local fallbackDef = (Towers and Towers.List and Towers.List[1]) or { Id = "Meadow", Element = "Nature" }
            local res = TeamPairs.Best(data, fallbackDef, targetSize)
            if res and #res > 0 then team = res end
        end)
    end
    
    -- 3. หากยังไม่ได้ทีม ให้ใช้ระบบคัดเลือกจากค่าพลังสัตว์เลี้ยงสูงสุด (Damage * Health)
    if #team == 0 then
        pcall(function()
            local res = GetTopBestPets(targetSize)
            if res and #res > 0 then team = res end
        end)
    end
    
    -- 4. กรณีฉุกเฉิน: ดึงสัตว์เลี้ยงตัวใดก็ได้ที่มีในกระเป๋า
    if #team == 0 and data.Pets then
        for uid in pairs(data.Pets) do
            table.insert(team, tostring(uid))
            if #team >= targetSize then break end
        end
    end
    
    return team
end

local function StartTowerDirect(targetTowerId)
    if IsInTrade() or getgenv().TradeActiveSession then return false, "In Trade" end
    
    local isJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
    if CFG.PauseTowerForBoss and CFG.AutoWorldBoss and (isJoined or IsEnteringBossPortal == true) then
        return false, "In World Boss"
    end
    
    local data = State.Data
    if not data or not data.Pets then return false, "No player data" end
    
    local resolvedId = ResolveTowerId(targetTowerId or CFG.SelectedTower)
    local towerDef = (Towers.ById and Towers.ById[resolvedId]) or (Towers.List and Towers.List[1]) or { Id = resolvedId, Name = resolvedId }
    
    local team = GetTowerTeam(towerDef)
    if not team or #team == 0 then
        Notify("⚠️ ไม่มีสัตว์เลี้ยง", "กรุณาสุ่มสัตว์เลี้ยงก่อนลงหอคอย", 3)
        return false, "No pets"
    end
    
    -- ยกเลิกการเปิด TowerAutoplay (ช่องขวาสุด) ป้องกันไม่ให้ระบบเซิร์ฟเวอร์เปิดโหมดออโต้ค้าง
    pcall(function()
        if data.Settings and data.Settings.TowerAutoplay == true then
            Fire("SetSetting", "TowerAutoplay", false)
        end
    end)
    
    -- สั่งเริ่มหอคอยผ่าน Remote Action ของเกมทันที
    Fire("TowerStart", towerDef.Id, team)
    
    LiveTower.Active = true
    LiveTower.Starting = true
    LiveTower.LastStartTick = tick()
    LiveTower.TowerId = towerDef.Id
    LiveTower.LastEventTime = tick()
    
    -- ปิดหน้าต่าง BattleResults UI ถ้ามีค้างอยู่
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local br = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root:FindFirstChild("Effects") and pg.PetDiceUI.Root.Effects:FindFirstChild("BattleResults")
        if br and br.Visible then br.Visible = false end
    end)
    
    return true
end

SwitchOrStartTower = function(targetTowerId, force)
    if IsInTrade() or getgenv().TradeActiveSession then
        return false
    end
    
    local nowTick = tick()
    if isSwitchingTower then
        if (nowTick - (LiveTower.SwitchingTick or 0) > 4.0) then
            isSwitchingTower = false
        elseif not force then
            return false
        end
    end
    
    local data = State.Data
    if not data then 
        Notify("⚠️ ข้อผิดพลาด", "ไม่พบข้อมูลผู้เล่น กำลังรอข้อมูล...", 3)
        return false 
    end
    
    local resolvedId = ResolveTowerId(targetTowerId or CFG.SelectedTower)
    local towerDef = (Towers.ById and Towers.ById[resolvedId]) or (Towers.List and Towers.List[1]) or { Id = resolvedId, Name = resolvedId }
    
    local isRunning = IsTowerRunning()
    local activeTower = GetActiveTowerId()
    
    -- หากกำลังลงหอคอยนี้อยู่แล้ว และไม่ได้สั่งบังคับ (force) ให้ข้ามคำสั่ง
    if not force and isRunning and activeTower == resolvedId then
        if CFG.AutoExitArena and IsTowerInArena() then
            Fire("TowerExit")
        end
        task.delay(0.2, UpdateTowerStatus)
        return true
    end
    
    isSwitchingTower = true
    LiveTower.SwitchingTick = nowTick
    lastTowerStartTick = nowTick
    
    local ok, res = pcall(function()
        -- หากกำลังลงหอคอยอื่นอยู่ ให้สั่งออกจากหอคอยเดิมก่อน
        if isRunning and activeTower and activeTower ~= resolvedId then
            local oldDef = Towers.ById and Towers.ById[activeTower]
            local oldName = oldDef and oldDef.Name or activeTower
            Notify("🏰 หอคอย", "กำลังเปลี่ยนจากหอคอย " .. tostring(oldName) .. " เป็น " .. tostring(towerDef.Name or resolvedId) .. "...", 2)
            Fire("TowerLeave")
            task.wait(0.3)
        end
        
        local success = StartTowerDirect(resolvedId)
        if success then
            Notify("🏰 หอคอย", "เริ่มลง " .. tostring(towerDef.Name or resolvedId) .. " เรียบร้อย!", 3)
            if CFG.AutoExitArena then
                task.delay(2.5, function() 
                    if getgenv().PetDiceScriptToken == scriptToken and IsTowerInArena() then
                        Fire("TowerExit") 
                    end
                end)
                task.delay(4.5, function() 
                    if getgenv().PetDiceScriptToken == scriptToken and IsTowerInArena() then
                        Fire("TowerExit") 
                    end
                end)
            end
            task.delay(0.4, UpdateTowerStatus)
            return true
        end
        return false
    end)
    isSwitchingTower = false
    return ok and res
end

local function StartSelectedTower()
    local targetId = GetSelectedTowerId()
    SwitchOrStartTower(targetId, true)
end

local function UpdateTowerStatus()
    pcall(function()
        local data = State.Data
        if not data then return end
        
        local activeTowerId = GetActiveTowerId()
        local targetId = GetSelectedTowerId()
        local displayTowerId = activeTowerId or targetId
        local towerDef = (Towers.ById and Towers.ById[displayTowerId]) or (Towers.List and Towers.List[1])
        local tName = towerDef and towerDef.Name or displayTowerId
        
        local isRunning = IsTowerRunning()
        local inArena = IsTowerInArena()
        local curFloor = GetCurrentTowerFloor() or (isRunning and data.TowerResume and data.TowerResume.Floor) or 0
        local bestFloor = (data.TowerBest and (data.TowerBest[displayTowerId] or data.TowerBest.Infinity)) or (data.TowerStage and data.TowerStage[displayTowerId]) or 0
        
        local autoTower = CFG.Tower and "🟢 เปิด (Active)" or "🔴 ปิด (Off)"
        local autoExit = CFG.AutoExitArena and "🟢 เปิด (Away Mode)" or "🔴 ปิด (Arena)"
        local autoDice = CFG.AutoPlay and "🟢 เปิด" or "🔴 ปิด"
        
        local statusText
        local isPlayerIn = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if CFG.PauseTowerForBoss and CFG.AutoWorldBoss and (isPlayerIn or IsEnteringBossPortal == true) then
            statusText = "⏸️ พักหอคอยชั่วคราว (กำลังร่วมศึกบอสโลก — จะลงต่อทันทีที่บอสจบ)"
        elseif isRunning then
            local modeStr = inArena and "ในอารีน่า (Arena)" or "โหมดเบื้องหลัง (Away)"
            statusText = string.format("⚔️ กำลังฟาร์ม [%s] ชั้น: %d (%s)", tName, curFloor, modeStr)
        else
            statusText = "💤 หอคอยหยุดพัก (พร้อมเริ่ม)"
        end
        
        local desc = string.format("🏰 หอคอยเป้าหมาย: [%s]\n🏆 สถิติสูงสุด (%s): ชั้น %d\n⚙️ ออโต้หอคอย: %s | 🚪 ออกอารีน่า: %s | 🎲 ทอยเต๋า: %s",
            tName, tName, bestFloor, autoTower, autoExit, autoDice)
            
        TowerStatusPara:SetTitle(statusText)
        TowerStatusPara:SetDesc(desc)
        
        -- อัปเดตสถานะบอสโลก (World Boss Status)
        local wbState = ReplicatedStorage:GetAttribute("WorldBossState") or "Idle"
        local wbElem = ReplicatedStorage:GetAttribute("WorldBossElement") or "Random"
        local wbDiff = ReplicatedStorage:GetAttribute("WorldBossDifficulty") or "Normal"
        local wbJoined = ReplicatedStorage:GetAttribute("WorldBossJoined") or 0
        local isPlayerIn = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        
        local timeStr = "0:00"
        local timeToJoinStr = "0:00"
        if ScheduleConfig and ScheduleConfig.WorldBoss then
            local now = workspace:GetServerTimeNow()
            local wb = ScheduleConfig.WorldBoss
            local nextIdx = ScheduleConfig.Index(wb, now) + 1
            local nextStart = ScheduleConfig.StartOf(wb, nextIdx)
            local joinSec = WorldBossConfig and WorldBossConfig.JoinSeconds or 45
            local leftStart = math.max(0, math.floor(nextStart - now))
            local leftJoin = math.max(0, math.floor(nextStart - joinSec - now))
            timeStr = string.format("%d:%02d", leftStart // 60, leftStart % 60)
            timeToJoinStr = string.format("%d:%02d", leftJoin // 60, leftJoin % 60)
        end
        
        local bossTitle
        if wbState == "Joining" then
            bossTitle = string.format("⏳ บอสโลกเปิดรับสมัครแล้ว! [%s %s] (เริ่มสู้ใน %s)", wbDiff, wbElem, timeStr)
        elseif wbState == "Fighting" then
            bossTitle = string.format("⚔️ กำลังต่อสู้กับบอสโลก! [%s %s]", wbDiff, wbElem)
        elseif wbState == "Result" then
            bossTitle = "🏆 บอสโลกจบลงแล้ว (กำลังแจกรางวัล)"
        else
            bossTitle = string.format("💤 บอสโลกรอบถัดไปจะเปิดรับสมัครใน: %s (เริ่มสู้ %s)", timeToJoinStr, timeStr)
        end
        
        local isBossUnlocked = false
        if Upgrades and Upgrades.IsOpen and data and data.Upgrades then
            isBossUnlocked = Upgrades.IsOpen(data.Upgrades, "WorldBoss")
        end
        local unlockStatus = isBossUnlocked and "🟢 ปลดล็อคแล้ว" or "🔒 ยังไม่ปลดล็อค (ต้องการ 1 Qi)"
        
        local playerStatus = isPlayerIn and "🟢 คุณเข้าร่วมแล้ว" or "⚪ ยังไม่ได้เข้าร่วม"
        local autoJoinStatus = CFG.AutoWorldBoss and "🟢 เปิดออโต้" or "🔴 ปิด"
        local pauseStatus = CFG.PauseTowerForBoss and "🟢 พักหอคอยเพื่อตีบอส" or "⚪ ฟาร์มปกติ"
        
        local bossDesc = string.format("เป้าหมาย: ธาตุ %s | ระดับ %s\nความพร้อม: %s | สถานะ: %s (%d คน)\nระบบบอส: %s | %s",
            CFG.WorldBossElementFilter or "ทุกธาตุ",
            CFG.WorldBossDifficultyFilter or "ทุกระดับ",
            unlockStatus,
            playerStatus,
            wbJoined,
            autoJoinStatus,
            pauseStatus
        )
        
        BossStatusPara:SetTitle(bossTitle)
        BossStatusPara:SetDesc(bossDesc)
    end)
end

task.spawn(UpdateTowerStatus)
task.spawn(function()
    while true do
        task.wait(1.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        UpdateTowerStatus()
    end
end)

Tabs.Tower:AddSection("🏰 ระบบฟาร์มหอคอย (Tower Progression & Auto Farm)")

Tabs.Tower:AddParagraph({
    Title = "💡 คำแนะนำระบบหอคอย Pet Dice",
    Content = "• 🌟 ด่าน 7 (Infinity Tower): [แนะนำที่สุดสำหรับการ AFK 24 ชม.] จะเริ่มจากชั้น 1 ใหม่ทุกรอบ และดรอปกล่อง Infinity Bags, น้ำยา, ตั๋วสุ่มตลอดทาง\n" ..
              "• 🏰 ด่าน 1-6 (Meadow - Cosmic): เป็นหอคอยเนื้อเรื่องเซฟชั้นถาวร (Checkpoint) จะเริ่มต่อจากชั้นสูงสุดที่เคยผ่านเสมอ ไม่สามารถรีเซ็ตเป็น 0 ได้"
})

local DropdownTower

Tabs.Tower:AddButton({
    Title = "🎯 ฟาร์มหอคอย Infinity ด่าน 7 (แนะนำที่สุด 24 ชม.)",
    Description = "เลือกหอคอย Infinity ด่าน 7 ทันที เริ่มต้นชั้น 1 ทุกรอบ ฟาร์มกล่อง Infinity Bags และรางวัลไม่จำกัด",
    Callback = function()
        if DropdownTower and DropdownTower.SetValue then
            pcall(function() DropdownTower:SetValue(defaultTowerOpt) end)
        end
        UpdateCFG("SelectedTower", "Infinity")
        UpdateCFG("SelectedTowerOption", defaultTowerOpt)
        Notify("🎯 หอคอย", "เลือกหอคอย Infinity ด่าน 7 เรียบร้อย!", 3)
        task.delay(0.2, UpdateTowerStatus)
        if CFG.Tower then
            task.spawn(function()
                SwitchOrStartTower("Infinity", true)
            end)
        end
    end
})

DropdownTower = Tabs.Tower:AddDropdown("DropSelectTower", {
    Title = "เลือกหอคอยที่ต้องการลง (Select Tower)",
    Description = "เลือกหอคอยเดี่ยวที่ต้องการให้บอทลงฟาร์ม (แนะนำ Infinity ด่าน 7 สำหรับการฟาร์มต่อเนื่อง)",
    Values = dynamicTowerOptions,
    Default = CFG.SelectedTowerOption or defaultTowerOpt,
    Multi = false,
    Callback = function(selection)
        local id = towerIdByOption[selection] or selection:match("%[([%w_]+)%]") or "Infinity"
        UpdateCFG("SelectedTower", id)
        UpdateCFG("SelectedTowerOption", selection)
        Notify("🏰 หอคอย", "เลือกหอคอย: " .. tostring(id), 2)
        task.delay(0.2, UpdateTowerStatus)
        if CFG.Tower then
            local activeTower = GetActiveTowerId()
            if not IsTowerRunning() or activeTower ~= id then
                task.spawn(function()
                    SwitchOrStartTower(id, true)
                end)
            end
        end
    end
})

Tabs.Tower:AddToggle("TogTower", {
    Title = "1. ฟาร์มหอคอยอัตโนมัติ (Auto Tower)",
    Default = CFG.Tower,
    Callback = function(V)
        UpdateCFG("Tower", V)
        if V then
            task.spawn(function()
                -- ล้างค่าสถานะค้างทั้งหมด ให้พร้อมเริ่มทันที
                isSwitchingTower = false
                LiveTower.Starting = false
                LiveTower.Active = false
                lastTowerStartTick = 0
                lastLoopStartAttempt = 0
                
                local isJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
                if CFG.PauseTowerForBoss and CFG.AutoWorldBoss and (isJoined or IsEnteringBossPortal == true) then
                    Notify("🏰 หอคอย", "เปิดระบบฟาร์มหอคอยแล้ว! (ขณะนี้อยู่ในห้องบอสโลก จะเริ่มลงหอคอยอัตโนมัติทันทีที่ออกจากบอส)", 4)
                    task.delay(0.2, UpdateTowerStatus)
                    return
                end
                
                local targetId = ResolveTowerId(CFG.SelectedTower)
                -- สั่งเริ่มหอคอยทันทีแบบ force = true ไม่มีการข้ามเงื่อนไข
                local started = SwitchOrStartTower(targetId, true)
                if not started then
                    StartTowerDirect(targetId)
                end
                task.delay(0.2, UpdateTowerStatus)
            end)
        else
            task.spawn(function()
                isSwitchingTower = false
                Fire("TowerLeave")
                pcall(function() Fire("SetSetting", "TowerAutoplay", false) end)
                Notify("🏰 หอคอย", "ปิดระบบฟาร์มหอคอยอัตโนมัติแล้ว", 2)
                task.delay(0.2, UpdateTowerStatus)
            end)
        end
    end
})

local SliderTowerDelay = Tabs.Tower:AddSlider("SlideTowerDelay", {
    Title = "ระยะเวลาหน่วงก่อนเริ่มรอบใหม่ (วินาที)",
    Description = "ปรับเวลารอก่อนเริ่มหอคอยรอบใหม่เพื่อความปลอดภัยและสมจริง",
    Default = CFG.TowerRestartDelay or 3,
    Min = 1,
    Max = 15,
    Rounding = 0,
    Callback = function(val)
        UpdateCFG("TowerRestartDelay", val)
    end
})

Tabs.Tower:AddInput("InputTowerDelay", {
    Title = "⌨️ กำหนดระยะเวลาหน่วงเอง (พิมพ์วินาที)",
    Default = tostring(CFG.TowerRestartDelay or 3),
    Numeric = true,
    Finished = true,
    Callback = function(val)
        local num = tonumber(val)
        if num and num >= 0 then
            local clamped = math.clamp(num, 0, 60)
            SliderTowerDelay:SetValue(clamped)
            UpdateCFG("TowerRestartDelay", clamped)
            Notify("⏱️ ตั้งค่าเวลา", "กำหนดเวลารีสตาร์ทหอคอยเป็น: " .. clamped .. " วินาที", 2)
        end
    end
})

Tabs.Tower:AddToggle("TogAutoExitArena", {
    Title = "2. ออกจากอารีน่าอัตโนมัติเมื่อเริ่มชั้น (Auto Exit Arena)",
    Default = CFG.AutoExitArena,
    Callback = function(V)
        UpdateCFG("AutoExitArena", V)
        if V then
            task.spawn(function()
                if IsTowerInArena() then
                    Fire("TowerExit")
                    Notify("🚪 หอคอย", "ออกจากอารีน่ามาทำงานเบื้องหลังเรียบร้อย!", 2)
                else
                    Notify("🚪 หอคอย", "เปิดระบบออกจากอารีน่าอัตโนมัติแล้ว", 2)
                end
                task.delay(0.2, UpdateTowerStatus)
            end)
        else
            Notify("🚪 หอคอย", "ปิดระบบออกจากอารีน่าอัตโนมัติแล้ว", 2)
            task.delay(0.2, UpdateTowerStatus)
        end
    end
})

TogTowerEquipBest = Tabs.Tower:AddToggle("TogAutoEquipBest", {
    Title = "3. สวมใส่สัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (Auto Equip Best)",
    Default = CFG.AutoEquipBest,
    Callback = HandleAutoEquipBestToggle
})

Tabs.Tower:AddButton({
    Title = "▶️ เริ่มลงหอคอยที่เลือกทันที (Start Selected Tower Now)",
    Description = "จัดทีมสัตว์เลี้ยงที่ดีที่สุดตรงตามธาตุและส่งคำสั่งเริ่มลงหอคอย",
    Callback = StartSelectedTower
})

Tabs.Tower:AddButton({
    Title = "🚪 ออกจากอารีน่าทันที (Exit Arena to Background)",
    Description = "ส่งคำสั่งออกจากอารีน่าเพื่อเดินเล่นในแมพได้อิสระ (หอคอยยังคงฟาร์มต่อ)",
    Callback = function()
        Fire("TowerExit")
        Notify("🚪 หอคอย", "ส่งคำสั่งออกจากอารีน่าเรียบร้อย!", 2)
        task.delay(0.2, UpdateTowerStatus)
    end
})

Tabs.Tower:AddButton({
    Title = "🛑 สั่งหยุดลงหอคอย (Stop Tower Run)",
    Description = "ส่งคำสั่งหยุดการลงหอคอยรอบปัจจุบันทันที",
    Callback = function()
        Fire("TowerLeave")
        LiveTower.Active = false
        LiveTower.Starting = false
        LiveTower.TowerId = nil
        LiveTower.Floor = 0
        LiveTower.InArena = false
        LiveTower.Away = false
        Notify("🛑 หอคอย", "ส่งคำสั่งหยุดการลงหอคอยเรียบร้อย!", 2)
        task.delay(0.2, UpdateTowerStatus)
    end
})

-- ดึงข้อมูลธาตุและระดับความยากของบอสโลกจากตัวเกมจริง
local dynamicBossElemOptions = {"[ ตีทุกธาตุ (All Elements) ]"}
if WorldBossConfig and WorldBossConfig.Elements then
    for _, e in ipairs(WorldBossConfig.Elements) do
        table.insert(dynamicBossElemOptions, e.Id)
    end
end

local dynamicBossDiffOptions = {"[ ตีทุกระดับ (All Difficulties) ]"}
if WorldBossConfig and WorldBossConfig.Difficulties then
    for _, d in ipairs(WorldBossConfig.Difficulties) do
        table.insert(dynamicBossDiffOptions, d.Id)
    end
end

Tabs.Tower:AddSection("⚔️ ระบบตีบอสโลกอัตโนมัติ (World Boss Battles)")

Tabs.Tower:AddDropdown("DropBossElement", {
    Title = "เลือกธาตุของบอสที่ต้องการตี (ดึงจากตัวเกมจริง)",
    Values = dynamicBossElemOptions,
    Default = CFG.WorldBossElementFilter or "[ ตีทุกธาตุ (All Elements) ]",
    Multi = false,
    Callback = function(selection)
        UpdateCFG("WorldBossElementFilter", selection)
        Notify("⚔️ บอสโลก", "เลือกเป้าหมายธาตุ: " .. selection, 2)
        task.delay(0.2, UpdateTowerStatus)
    end
})

Tabs.Tower:AddDropdown("DropBossDifficulty", {
    Title = "เลือกระดับความยากของบอส (ดึงจากตัวเกมจริง)",
    Values = dynamicBossDiffOptions,
    Default = CFG.WorldBossDifficultyFilter or "[ ตีทุกระดับ (All Difficulties) ]",
    Multi = false,
    Callback = function(selection)
        UpdateCFG("WorldBossDifficultyFilter", selection)
        Notify("⚔️ บอสโลก", "เลือกเป้าหมายความยาก: " .. selection, 2)
        task.delay(0.2, UpdateTowerStatus)
    end
})

Tabs.Tower:AddToggle("TogAutoWorldBoss", {
    Title = "4. เข้าร่วมตีบอสโลกอัตโนมัติ (Auto Join World Boss)",
    Default = CFG.AutoWorldBoss,
    Callback = function(V)
        UpdateCFG("AutoWorldBoss", V)
        if V then
            Notify("⚔️ บอสโลก", "เปิดระบบเข้าร่วมตีบอสโลกอัตโนมัติแล้ว!", 3)
        else
            Notify("⚔️ บอสโลก", "ปิดระบบเข้าร่วมตีบอสโลกอัตโนมัติแล้ว", 2)
        end
        task.delay(0.2, UpdateTowerStatus)
    end
})

Tabs.Tower:AddToggle("TogPauseTowerForBoss", {
    Title = "5. หยุดฟาร์มหอคอยชั่วคราวเมื่อมีบอส (Pause Tower For Boss)",
    Default = CFG.PauseTowerForBoss,
    Callback = function(V)
        UpdateCFG("PauseTowerForBoss", V)
        task.delay(0.2, UpdateTowerStatus)
    end
})

Tabs.Tower:AddButton({
    Title = "⚔️ กดเข้าร่วมตีบอสโลกทันที (Join World Boss Now)",
    Description = "เดินขึ้นบันไดตามธรรมชาติอย่างปลอดภัย และส่งคำสั่งเข้าร่วมบอสโลก",
    Callback = function()
        local data = State.Data
        local isBossUnlocked = false
        if Upgrades and Upgrades.IsOpen and data and data.Upgrades then
            isBossUnlocked = Upgrades.IsOpen(data.Upgrades, "WorldBoss")
        end
        
        -- ตรวจสอบหากยังไม่ปลดล็อค แต่มีเงินพอซื้อ 1 Qi
        if not isBossUnlocked and data and (data.Money or 0) >= 1e18 then
            Notify("⚔️ บอสโลก", "กำลังปลดล็อค 'WORLD BOSSES' ในผังอัปเกรดให้อัตโนมัติ...", 3)
            Fire("BuyUpgrade", "worldboss")
            Humanizer.Wait(1.0, 1.5)
            data = State.Data
            if Upgrades and Upgrades.IsOpen and data and data.Upgrades then
                isBossUnlocked = Upgrades.IsOpen(data.Upgrades, "WorldBoss")
            end
        end
        
        if not isBossUnlocked then
            local curMoneyStr = (data and data.Money and Format and Format.Money) and Format.Money(data.Money) or tostring(data and data.Money or 0)
            Notify("🔒 ยังไม่ปลดล็อค", "ต้องปลดล็อค 'WORLD BOSSES' ในผังอัปเกรดก่อน (ต้องการ 1 Qi - ปัจจุบันมี: " .. curMoneyStr .. ")", 4)
            return
        end
        
        if data and not data.PortalRepaired then
            Fire("PortalRepair")
            Humanizer.Wait(0.5, 1.0)
        end
        
        local wbState = ReplicatedStorage:GetAttribute("WorldBossState") or "Idle"
        local wbElem = ReplicatedStorage:GetAttribute("WorldBossElement") or "Random"
        local wbDiff = ReplicatedStorage:GetAttribute("WorldBossDifficulty") or "Normal"
        
        if wbState == "Joining" or wbState == "Fighting" then
            if CFG.PauseTowerForBoss and IsTowerRunning() then
                Fire("TowerLeave")
                Humanizer.Wait(0.8, 1.5)
            end
            
            SafeWalkToBossPortal()
            Humanizer.Wait(0.3, 0.6)
            
            Fire("WorldBossJoin")
            local portalModel = workspace:FindFirstChild("Market") and workspace.Market:FindFirstChild("WorldBossPortal")
            local promptSpot = portalModel and portalModel:FindFirstChild("PromptSpot")
            if promptSpot then
                local prompt = promptSpot:FindFirstChild("JoinPrompt")
                if prompt and typeof(fireproximityprompt) == "function" and prompt.Enabled then
                    pcall(fireproximityprompt, prompt)
                end
            end
            Notify("⚔️ บอสโลก", string.format("ส่งคำสั่งเข้าร่วมบอสโลก [%s %s] สำเร็จ!", wbDiff, wbElem), 3)
        else
            -- คำนวณเวลานับถอยหลังที่เหลืออยู่จริงจนกว่าจะเปิดรับสมัคร
            local timeToJoin = 0
            if ScheduleConfig and ScheduleConfig.WorldBoss then
                local now = workspace:GetServerTimeNow()
                local wb = ScheduleConfig.WorldBoss
                local nextIdx = ScheduleConfig.Index(wb, now) + 1
                local nextStart = ScheduleConfig.StartOf(wb, nextIdx)
                local joinSec = WorldBossConfig and WorldBossConfig.JoinSeconds or 45
                timeToJoin = math.max(0, math.floor(nextStart - joinSec - now))
            end
            
            local m = math.floor(timeToJoin / 60)
            local s = math.floor(timeToJoin % 60)
            Notify("⏳ ยังไม่ถึงเวลา", string.format("บอสโลกจะเปิดรับสมัครในอีก %d นาที %d วินาที (สถานะ: %s)", m, s, wbState), 4)
        end
        task.delay(0.2, UpdateTowerStatus)
    end
})

Tabs.Tower:AddButton({
    Title = "🚪 ออกจากการตีบอสทันที (Leave World Boss)",
    Description = "ส่งคำสั่งถอนตัวจากการตีบอสโลก และวาร์ปกลับบ้าน",
    Callback = function()
        Fire("WorldBossLeave")
        task.wait(0.5)
        Fire("Teleport", "Home")
        Notify("🚪 บอสโลก", "ส่งคำสั่งออกจากบอสโลกและกลับบ้านเรียบร้อย!", 2)
        task.delay(0.2, UpdateTowerStatus)
    end
})

Tabs.Tower:AddSection("🎲 กลิ้งลูกเต๋า (Auto Dice)")

Tabs.Tower:AddToggle("TogAutoPlay", {
    Title = "4. กลิ้งลูกเต๋าอัตโนมัติ (Auto Roll Dice)",
    Default = CFG.AutoPlay,
    Callback = function(V)
        UpdateCFG("AutoPlay", V)
        if V then
            task.spawn(function()
                local data = State.Data
                if data and Stats and Stats.HasAuto and Stats.HasAuto(data, State.Mods and State.Mods() or {}) then
                    Fire("SetAuto", true)
                    Notify("🎲 กลิ้งลูกเต๋า", "เปิดระบบ Auto Roll ในเกมเรียบร้อย!", 2)
                else
                    Notify("🎲 กลิ้งลูกเต๋า", "เปิดระบบทอยลูกเต๋าอัตโนมัติเรียบร้อย!", 2)
                end
                task.delay(0.2, UpdateTowerStatus)
            end)
        else
            task.spawn(function()
                Fire("SetAuto", false)
                Notify("🎲 กลิ้งลูกเต๋า", "ปิดระบบทอยลูกเต๋าอัตโนมัติแล้ว", 2)
                task.delay(0.2, UpdateTowerStatus)
            end)
        end
    end
})

Tabs.Tower:AddToggle("TogAutoBuyDice", {
    Title = "5. ซื้อลูกเต๋าอัตโนมัติเมื่อเงินพอ (Auto Buy Dice)",
    Default = CFG.AutoBuyDice,
    Callback = function(V)
        UpdateCFG("AutoBuyDice", V)
        if V then
            task.spawn(function()
                Fire("BuyDice")
                Notify("🎲 ซื้อลูกเต๋า", "เปิดระบบซื้อลูกเต๋าอัตโนมัติเรียบร้อย!", 2)
            end)
        else
            Notify("🎲 ซื้อลูกเต๋า", "ปิดระบบซื้อลูกเต๋าอัตโนมัติแล้ว", 2)
        end
    end
})

-- ------------------------------------------------------------------------------
-- 🔄 TAB 4: REBIRTH & SKILL TREE
-- ------------------------------------------------------------------------------
Tabs.Rebirth:AddSection("🌟 เกิดใหม่อัตโนมัติ (Auto Rebirth)")

Tabs.Rebirth:AddToggle("TogAutoRebirth", {
    Title = "เปิดระบบเกิดใหม่อัตโนมัติเมื่อเงินครบ (Auto Rebirth)",
    Default = CFG.AutoRebirth,
    Callback = function(V) UpdateCFG("AutoRebirth", V) end
})

Tabs.Rebirth:AddButton({
    Title = "⚡ กดเกิดใหม่ทันที (Rebirth Now)",
    Description = "เช็คความพร้อมของเงินและส่งคำสั่งเกิดใหม่",
    Callback = function()
        local data = State.Data
        if not data then return end
        local cost = Stats.RebirthCost(data)
        if cost and (data.Money or 0) >= cost then
            Fire("Rebirth")
            Notify("🌟 เกิดใหม่", "ส่งคำสั่งเกิดใหม่สำเร็จ!", 3)
        else
            Notify("⚠️ เงินไม่พอ", "เงินของคุณยังไม่พอสำหรับการเกิดใหม่", 3)
        end
    end
})

Tabs.Rebirth:AddSection("🌳 อัปเกรดต้นไม้ทักษะ (Skill Tree)")

Tabs.Rebirth:AddToggle("TogTree", {
    Title = "วนซื้ออัปเกรดต้นไม้ทั้งหมดอัตโนมัติ",
    Default = CFG.UpgradeTree,
    Callback = function(V) UpdateCFG("UpgradeTree", V) end
})

local SliderTreeDelay, InputCustomTreeDelay
SliderTreeDelay = Tabs.Rebirth:AddSlider("SliderTreeDelay", {
    Title = "ระยะเวลาหน่วงในการวนซื้อ (วินาที)",
    Default = CFG.UpgradeTreeDelay or 3,
    Min = 2,
    Max = 10,
    Rounding = 0,
    Callback = function(V)
        UpdateCFG("UpgradeTreeDelay", V)
        pcall(function()
            if InputCustomTreeDelay and InputCustomTreeDelay.Value ~= tostring(V) then
                InputCustomTreeDelay:SetValue(tostring(V))
            end
        end)
    end
})

InputCustomTreeDelay = Tabs.Rebirth:AddInput("InputCustomTreeDelay", {
    Title = "✏️ กำหนดระยะเวลาหน่วงเอง (พิมพ์วินาที)",
    Default = tostring(CFG.UpgradeTreeDelay or 3),
    Placeholder = "พิมพ์วินาที เช่น 2, 3, 5...",
    Numeric = true,
    Finished = true,
    Callback = function(val)
        local n = tonumber(val)
        if n and n >= 1 then
            local sec = math.floor(n)
            UpdateCFG("UpgradeTreeDelay", sec)
            pcall(function()
                if sec >= 2 and sec <= 10 and SliderTreeDelay then
                    SliderTreeDelay:SetValue(sec)
                end
            end)
            Notify("🌳 ต้นไม้ทักษะ", "ตั้งค่าความหน่วงเป็น " .. sec .. " วินาที", 2)
        end
    end
})

Tabs.Rebirth:AddButton({
    Title = "🌳 ซื้ออัปเกรดต้นไม้ทั้งหมดทันที (Buy All Upgrades Now)",
    Description = "ส่งคำสั่งซื้ออัปเกรดต้นไม้ทั้งหมดที่สามารถซื้อได้ใน 1 คลิก",
    Callback = function()
        Fire("BuyAllUpgrades")
        Notify("🌳 อัปเกรด", "ส่งคำสั่งซื้ออัปเกรดต้นไม้ทั้งหมดสำเร็จ!", 2)
    end
})

-- ------------------------------------------------------------------------------
-- 🧪 TAB 5: POTIONS & CONSUMABLES
-- ------------------------------------------------------------------------------
Tabs.Items:AddSection("📊 สถานะน้ำยาและไอเทมแบบเรียลไทม์ (นับถอยหลังวินาที)")

local PotionStatusPara = Tabs.Items:AddParagraph({
    Title = "⏳ กำลังโหลดสถานะน้ำยา...",
    Content = "กำลังตรวจสอบเวลานับถอยหลังของน้ำยาแต่ละชนิด..."
})

local function UpdatePotionStatus()
    pcall(function()
        local data = State.Data
        if not data then return end
        local now = State.Now and State.Now() or os.time()
        local potions = data.Potions or {}
        local ends = data.PotionEnds or {}
        
        local function GetTimeStr(endT)
            if not endT or endT <= now then return "❌ หมดอายุแล้ว" end
            local left = math.floor(endT - now)
            local mins = math.floor(left / 60)
            local secs = left % 60
            return string.format("✅ เหลืออีก %d:%02d นาที", mins, secs)
        end
        
        local luckCount = potions.Luck or 0
        local cashCount = potions.Cash or 0
        local speedCount = potions.Speed or 0
        local lootBags = data.LootBags or 0
        local halloweenBags = (data.SeasonBags and data.SeasonBags.Halloween) or 0
        
        local desc = string.format("🍀 น้ำยาโชคดี: มี %d ขวด | บัฟ: %s\n💰 น้ำยาเงิน: มี %d ขวด | บัฟ: %s\n⚡ น้ำยาความเร็ว: มี %d ขวด | บัฟ: %s\n🎒 ถุงสมบัติ: %d ใบ | 🎃 ถุงฮาโลวีน: %d ใบ",
            luckCount, GetTimeStr(ends.Luck),
            cashCount, GetTimeStr(ends.Cash),
            speedCount, GetTimeStr(ends.Speed),
            lootBags, halloweenBags
        )
        
        PotionStatusPara:SetTitle("🧪 สถานะน้ำยา & ไอเทมปัจจุบัน")
        PotionStatusPara:SetDesc(desc)
    end)
end

task.spawn(UpdatePotionStatus)
task.spawn(function()
    while true do
        task.wait(1.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        UpdatePotionStatus()
    end
end)

Tabs.Items:AddSection("⚡ สั่งใช้งานไอเทมด่วน (1 คลิก)")

Tabs.Items:AddButton({
    Title = "🍀 ดื่มน้ำยาโชคดีทันที (Potion Luck +1 ขวด)",
    Callback = function()
        local data = State.Data
        if data and data.Potions and (data.Potions.Luck or 0) > 0 then
            Fire("UsePotion", "Luck", 1)
            Notify("🍀 น้ำยาโชคดี", "ดื่มน้ำยาโชคดี (+15 นาที) เรียบร้อย!", 2)
            task.delay(0.4, UpdatePotionStatus)
        else
            Notify("⚠️ ไม่มีน้ำยา", "คุณไม่มีน้ำยาโชคดีในกระเป๋า", 2)
        end
    end
})

Tabs.Items:AddButton({
    Title = "💰 ดื่มน้ำยาเงินทันที (Potion Cash +1 ขวด)",
    Callback = function()
        local data = State.Data
        if data and data.Potions and (data.Potions.Cash or 0) > 0 then
            Fire("UsePotion", "Cash", 1)
            Notify("💰 น้ำยาเงิน", "ดื่มน้ำยาเงิน (+15 นาที) เรียบร้อย!", 2)
            task.delay(0.4, UpdatePotionStatus)
        else
            Notify("⚠️ ไม่มีน้ำยา", "คุณไม่มีน้ำยาเงินในกระเป๋า", 2)
        end
    end
})

Tabs.Items:AddButton({
    Title = "⚡ ดื่มน้ำยาความเร็วทันที (Potion Speed +1 ขวด)",
    Callback = function()
        local data = State.Data
        if data and data.Potions and (data.Potions.Speed or 0) > 0 then
            Fire("UsePotion", "Speed", 1)
            Notify("⚡ น้ำยาความเร็ว", "ดื่มน้ำยาความเร็ว (+15 นาที) เรียบร้อย!", 2)
            task.delay(0.4, UpdatePotionStatus)
        else
            Notify("⚠️ ไม่มีน้ำยา", "คุณไม่มีน้ำยาความเร็วในกระเป๋า", 2)
        end
    end
})

Tabs.Items:AddButton({
    Title = "🎒 เปิดถุงสมบัติทั่วไปทั้งหมด (Open All Bags)",
    Callback = function()
        local data = State.Data
        if data and (data.LootBags or 0) > 0 then
            Fire("OpenLootBag", "all")
            Notify("🎒 ถุงสมบัติ", "กำลังเปิดถุงสมบัติทั้งหมด กรุณารอแอนิเมชัน...", 4)
            task.delay(4.5, function()
                local waiting = 0
                pcall(function()
                    if PetData and PetData.WaitingCount and State.Data then
                        waiting = PetData.WaitingCount(State.Data, "Infinity")
                    end
                end)
                if waiting > 0 then
                    Fire("ClaimLootPets", "Infinity")
                    Notify("🐾 สัตว์เลี้ยง", "รับสัตว์เลี้ยงจากถุงสมบัติ " .. waiting .. " ตัวเรียบร้อย!", 3)
                end
                UpdatePotionStatus()
            end)
        else
            Notify("ℹ️ ไม่มีถุงสมบัติ", "ไม่มีถุงสมบัติในกระเป๋า", 2)
        end
    end
})

Tabs.Items:AddButton({
    Title = "🐾 เคลมสัตว์เลี้ยงจากถุงสมบัติ (Claim Loot Pets)",
    Callback = function()
        local waiting = 0
        pcall(function()
            if PetData and PetData.WaitingCount and State.Data then
                waiting = PetData.WaitingCount(State.Data, "Infinity")
            end
        end)
        if waiting > 0 then
            Fire("ClaimLootPets", "Infinity")
            Notify("🐾 สัตว์เลี้ยง", "กดรับสัตว์เลี้ยงจากถุงสมบัติ " .. waiting .. " ตัวเรียบร้อย!", 3)
        else
            Notify("ℹ️ ไม่มีสัตว์เลี้ยงค้าง", "ไม่มีสัตว์เลี้ยงรอรับในระบบ", 2)
        end
    end
})

Tabs.Items:AddSection("🔄 ดื่มน้ำยาและเปิดไอเทมอัตโนมัติ")

Tabs.Items:AddToggle("TogAutoPotionLuck", {
    Title = "1. ดื่มน้ำยาโชคอัตโนมัติเมื่อบัฟหมด",
    Default = CFG.AutoUsePotionLuck,
    Callback = function(V) UpdateCFG("AutoUsePotionLuck", V) end
})

Tabs.Items:AddToggle("TogAutoPotionCash", {
    Title = "2. ดื่มน้ำยาเงินอัตโนมัติเมื่อบัฟหมด",
    Default = CFG.AutoUsePotionCash,
    Callback = function(V) UpdateCFG("AutoUsePotionCash", V) end
})

Tabs.Items:AddToggle("TogAutoPotionSpeed", {
    Title = "3. ดื่มน้ำยาความเร็วอัตโนมัติเมื่อบัฟหมด",
    Default = CFG.AutoUsePotionSpeed,
    Callback = function(V) UpdateCFG("AutoUsePotionSpeed", V) end
})

Tabs.Items:AddToggle("TogAutoOpenLootBags", {
    Title = "4. เปิดถุงสมบัติทั่วไปอัตโนมัติ",
    Default = CFG.AutoOpenLootBags,
    Callback = function(V) UpdateCFG("AutoOpenLootBags", V) end
})

-- ------------------------------------------------------------------------------
-- 🌙 TAB 6: EXPEDITIONS & QUESTS
-- ------------------------------------------------------------------------------
Tabs.Expedition:AddSection("🌙 ผจญภัยระดับฝันร้าย (Nightmare Expedition)")

local function GetNightmarePets(maxCount)
    local data = State.Data
    if not data or not data.Pets then return {} end
    
    local nightmare = ExpeditionConfig.ById and ExpeditionConfig.ById.Nightmare or ExpeditionConfig.Difficulties["5"]
    local req = nightmare and nightmare.Requirement or 1e14
    
    local equipped = {}
    for _, uid in ipairs(data.Equipped or {}) do equipped[tostring(uid)] = true end
    
    local onExp = {}
    for _, exp in ipairs(data.Expeditions and data.Expeditions.Active or {}) do
        for _, uid in ipairs(exp.Pets or {}) do onExp[tostring(uid)] = true end
    end
    
    local candidates = {}
    for uid, pet in pairs(data.Pets) do
        local sUid = tostring(uid)
        if not equipped[sUid] and not onExp[sUid] and not pet.Locked then
            local power = Expeditions.PetPower(data, pet, State.Mods(), State.Now())
            if power >= req then
                table.insert(candidates, { Uid = sUid, Power = power })
            end
        end
    end
    
    table.sort(candidates, function(a, b) return a.Power < b.Power end)
    local selected = {}
    for i = 1, math.min(maxCount or 1, #candidates) do
        table.insert(selected, candidates[i].Uid)
    end
    return selected
end

local function ClaimAllDoneExpeditions()
    local data = State.Data
    if not data or not data.Expeditions then return 0 end
    local claimed = 0
    local now = State.Now()
    for _, exp in ipairs(data.Expeditions.Active or {}) do
        if Expeditions.Left(exp, now) <= 0 or (exp.Ends and exp.Ends <= now) then
            Fire("ClaimExpedition", exp.Id)
            claimed = claimed + 1
            Humanizer.Wait(0.8, 1.4)
        end
    end
    return claimed
end

Tabs.Expedition:AddButton({
    Title = "⚡ ส่งผจญภัยฝันร้ายทันที (1 ช่อง)",
    Callback = function()
        local pets = GetNightmarePets(CFG.ExpeditionPetCount or 1)
        if #pets > 0 then
            Fire("SendExpedition", "Nightmare", pets)
            Notify("🌙 ผจญภัยฝันร้าย", "ส่งสัตว์เลี้ยง " .. #pets .. " ตัวเรียบร้อย!", 3)
        else
            Notify("⚠️ สัตว์เลี้ยงไม่พร้อม", "ไม่มีสัตว์เลี้ยงที่มีพลังพอส่งช่องฝันร้าย", 3)
        end
    end
})

Tabs.Expedition:AddButton({
    Title = "🎁 กดรับรางวัลผจญภัยที่สำเร็จทั้งหมด",
    Callback = function()
        local count = ClaimAllDoneExpeditions()
        Notify("🎁 รับรางวัลผจญภัย", count > 0 and ("กดรับแล้ว " .. count .. " ช่อง!") or "ยังไม่มีช่องที่เสร็จสิ้น", 3)
    end
})

Tabs.Expedition:AddToggle("TogAutoExpedition", {
    Title = "เปิดส่งสัตว์เลี้ยง + รับรางวัลอัตโนมัติ (Auto Nightmare)",
    Default = CFG.AutoExpedition,
    Callback = function(V) UpdateCFG("AutoExpedition", V) end
})

local SliderExpPetCount, InputCustomExpPetCount
SliderExpPetCount = Tabs.Expedition:AddSlider("SliderExpPetCount", {
    Title = "จำนวนสัตว์เลี้ยงต่อ 1 ช่อง",
    Default = CFG.ExpeditionPetCount or 1,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Callback = function(V)
        UpdateCFG("ExpeditionPetCount", V)
        pcall(function()
            if InputCustomExpPetCount and InputCustomExpPetCount.Value ~= tostring(V) then
                InputCustomExpPetCount:SetValue(tostring(V))
            end
        end)
    end
})

InputCustomExpPetCount = Tabs.Expedition:AddInput("InputCustomExpPetCount", {
    Title = "✏️ กำหนดจำนวนสัตว์เลี้ยงต่อช่องเอง (พิมพ์ตัวเลข 1 - 5)",
    Default = tostring(CFG.ExpeditionPetCount or 1),
    Placeholder = "พิมพ์จำนวน เช่น 1 - 5...",
    Numeric = true,
    Finished = true,
    Callback = function(val)
        local n = tonumber(val)
        if n and n >= 1 then
            local count = math.clamp(math.floor(n), 1, 5)
            UpdateCFG("ExpeditionPetCount", count)
            pcall(function()
                if SliderExpPetCount and SliderExpPetCount.Value ~= count then
                    SliderExpPetCount:SetValue(count)
                end
            end)
            Notify("🌙 ผจญภัย", "ตั้งค่าจำนวนสัตว์เลี้ยงเป็น " .. count .. " ตัว", 2)
        end
    end
})

Tabs.Expedition:AddSection("🎁 เควส & รางวัลประจำวัน (Rewards & Quests)")

local function ClaimAllRewardsManual()
    task.spawn(function()
        Fire("Funnel", "Daily", 1)
        local data = State.Data
        local now = State.Now and State.Now() or os.time()
        local claimedCount = 0
        
        -- Daily
        local canDaily = false
        pcall(function() canDaily = Stats.DailyState(data, now) end)
        if canDaily then
            Fire("Funnel", "Daily", 1)
            Fire("ClaimDaily")
            claimedCount = claimedCount + 1
            Humanizer.Wait(0.4, 0.8)
        end
        
        -- Playtime
        local canPlaytime = false
        pcall(function()
            if RewardsConfig and RewardsConfig.Playtime and data.Playtime then
                local played = RewardsConfig.PlayedToday(data.Playtime, Stats.Day(now), now)
                for i, v in ipairs(RewardsConfig.Playtime) do
                    local claimed = (data.Playtime.Claimed or {})[tostring(i)] == true
                    local reached = (v.Minutes * 60) <= played
                    if not claimed and reached then
                        canPlaytime = true
                        break
                    end
                end
            end
        end)
        if canPlaytime then
            Fire("ClaimPlaytime", "all")
            claimedCount = claimedCount + 1
            Humanizer.Wait(0.4, 0.8)
        end
        
        -- Social
        if data and data.Social then
            if not data.Social.Group then
                Fire("ClaimSocial", "Group")
                claimedCount = claimedCount + 1
                Humanizer.Wait(0.3, 0.6)
            end
            if not data.Social.Like then
                Fire("ClaimSocial", "Like")
                claimedCount = claimedCount + 1
                Humanizer.Wait(0.3, 0.6)
            end
        end
        
        -- Quests
        if data and data.Quests then
            for i, q in ipairs(data.Quests.Daily or {}) do
                if not q.Claimed and (q.Progress or 0) >= (q.Goal or math.huge) then
                    Fire("QuestClaim", "Daily", i)
                    claimedCount = claimedCount + 1
                    Humanizer.Wait(0.3, 0.6)
                end
            end
            for i, q in ipairs(data.Quests.Weekly or {}) do
                if not q.Claimed and (q.Progress or 0) >= (q.Goal or math.huge) then
                    Fire("QuestClaim", "Weekly", i)
                    claimedCount = claimedCount + 1
                    Humanizer.Wait(0.3, 0.6)
                end
            end
            if QuestsLogic and QuestsLogic.Goals and data.Quests.Goals then
                for _, gDef in ipairs(QuestsLogic.Goals) do
                    local gData = data.Quests.Goals[gDef.Id]
                    if gData and not gData.Claimed and (gData.Progress or 0) >= (gDef.Goal or math.huge) then
                        Fire("GoalClaim", gDef.Id)
                        claimedCount = claimedCount + 1
                        Humanizer.Wait(0.3, 0.6)
                    end
                end
            end
        end
        
        Notify("🎁 รับรางวัล", 
            claimedCount > 0 and ("รับรางวัลที่พร้อมแล้ว " .. claimedCount .. " รายการ!") or "ไม่มีรางวัลที่พร้อมรับ (ป้องกัน NOT DONE YET!)", 
            3
        )
    end)
end

Tabs.Expedition:AddButton({
    Title = "⚡ สั่งรับรางวัลทั้งหมดทันที (1 คลิก - ปลอดภัย)",
    Callback = ClaimAllRewardsManual
})

Tabs.Expedition:AddToggle("TogReward", {
    Title = "1. รับรางวัลประจำวัน & เวลาเล่นอัตโนมัติ (Auto Rewards)",
    Default = CFG.Reward,
    Callback = function(V) UpdateCFG("Reward", V) end
})

Tabs.Expedition:AddToggle("TogQuest", {
    Title = "2. รับและส่งเควสอัตโนมัติ (Auto Quests)",
    Default = CFG.Quest,
    Callback = function(V) UpdateCFG("Quest", V) end
})

Tabs.Expedition:AddToggle("TogCutscene", {
    Title = "3. ข้ามฉากคัตซีนอัตโนมัติ (Auto Skip Cutscene)",
    Default = CFG.Cutscene,
    Callback = function(V) UpdateCFG("Cutscene", V) end
})

-- ------------------------------------------------------------------------------
-- 🎃 TAB 7: HALLOWEEN EVENT
-- ------------------------------------------------------------------------------
Tabs.Halloween:AddSection("🎃 กิจกรรมฮาโลวีน (Halloween Event)")

local function GetHalloweenEntry()
    local seasonInfo = Season.Halloween()
    if not seasonInfo or not State.Data then return nil end
    return Season.Entry(State.Data, seasonInfo.Id), seasonInfo
end

local function CanTrickOrTreat()
    local s = Season.Halloween and Season.Halloween()
    if not s or not State.Data then return false end
    local entry = Season.Entry and Season.Entry(State.Data, s.Id)
    if not entry then return false end
    local nowDay = Season.TreatDay and Season.TreatDay(State.Now and State.Now() or os.time())
    if not nowDay then return false end
    if entry.TreatDay and entry.TreatDay >= nowDay then
        return false
    end
    return true
end

Tabs.Halloween:AddButton({
    Title = "🎁 กดรับรางวัลเป้าหมายฮาโลวีนทั้งหมด (1 คลิก)",
    Callback = function()
        local entry = GetHalloweenEntry()
        if not entry then 
            Notify("⚠️ ข้อมูลฮาโลวีน", "ไม่พบข้อมูลกิจกรรมฮาโลวีน", 2)
            return 
        end
        local claimed = 0
        for _, g in ipairs(HalloweenConfig.Goals or {}) do
            local currentTier = entry.Goals and entry.Goals[g.Id] or 0
            local nextTierIdx = currentTier + 1
            local nextTier = g.Tiers and g.Tiers[nextTierIdx]
            local stat = entry.Stats and entry.Stats[g.Stat] or 0
            if nextTier ~= nil and stat >= nextTier.Goal then
                Fire("HalloweenGoalClaim", g.Id)
                claimed = claimed + 1
                Humanizer.Wait(1.0, 1.8)
            end
        end
        Notify("🎃 ฮาโลวีน", claimed > 0 and ("รับรางวัลเป้าหมาย " .. claimed .. " รายการเรียบร้อย!") or "ไม่มีเป้าหมายที่สำเร็จพร้อมรับในขณะนี้", 3)
    end
})

Tabs.Halloween:AddButton({
    Title = "🛍️ ซื้อแพ็คกระเป๋า 10 ใบ (270 ลูกอม)",
    Callback = function()
        if IsTowerRunning() or IsInTrade() or getgenv().TradeActiveSession then
            Notify("⚠️ กำลังทำกิจกรรมอื่น", "กรุณาจบหอคอยหรือการเทรดก่อนซื้อไอเทม", 3)
            return
        end
        local entry = GetHalloweenEntry()
        if entry and (entry.Candy or 0) >= 270 then
            Fire("SpookyBuy", "HalloweenBag10")
            Notify("🛍️ ซื้อกระเป๋า", "ซื้อแพ็คกระเป๋าฮาโลวีน 10 ใบสำเร็จ!", 3)
        else
            Notify("⚠️ ลูกอมไม่พอ", "ต้องใช้ 270 ลูกอม (คุณมี: " .. tostring(entry and entry.Candy or 0) .. ")", 2)
        end
    end
})

Tabs.Halloween:AddButton({
    Title = "🍬 เดินไปขอขนมฮาโลวีน (Safe Legitimate Walking)",
    Callback = function()
        task.spawn(function()
            if not CanTrickOrTreat() then
                Notify("⚠️ ขอขนมแล้ว", "คุณขอขนมประจำวันนี้ไปแล้ว กรุณารอรอบวันถัดไป", 3)
                return
            end
            if IsTowerRunning() or IsInTrade() or getgenv().TradeActiveSession then
                Notify("⚠️ กำลังทำกิจกรรมอื่น", "กรุณาจบหอคอยหรือการเทรดก่อนเดินไปขอขนม", 3)
                return
            end
            Notify("🚶 กำลังเดิน", "กำลังเดินไปยังเคานต์พาวคูลาอย่างปลอดภัย...", 2)
            local arrived = WalkToPawcula()
            if arrived then
                Humanizer.Wait(0.8, 1.4)
                if CanTrickOrTreat() then
                    Fire("TrickOrTreat")
                    Notify("🍬 Trick or Treat", "ส่งคำขอขนมเรียบร้อย!", 3)
                    Humanizer.Wait(2.5, 4.0)
                    Fire("Teleport", "Home")
                end
            else
                Notify("⚠️ เดินไม่ถึงจุด", "ไม่สามารถเดินถึงเคานต์พาวคูลาได้", 2)
            end
        end)
    end
})

Tabs.Halloween:AddSection("🔄 ระบบฮาโลวีนอัตโนมัติ")

Tabs.Halloween:AddToggle("TogHalClaim", {
    Title = "1. รับรางวัลเป้าหมายอัตโนมัติ (Auto Claim Goals)",
    Default = CFG.HalloweenAutoClaim,
    Callback = function(V) UpdateCFG("HalloweenAutoClaim", V) end
})

Tabs.Halloween:AddToggle("TogHalBuyBags", {
    Title = "2. ซื้อแพ็ค 10 กระเป๋าอัตโนมัติ (270 ลูกอม)",
    Default = CFG.HalloweenAutoBuyBags,
    Callback = function(V) UpdateCFG("HalloweenAutoBuyBags", V) end
})

Tabs.Halloween:AddToggle("TogHalOpenBags", {
    Title = "3. เปิดกระเป๋าฮาโลวีนอัตโนมัติ (Auto Open Bags)",
    Default = CFG.HalloweenAutoOpenBags,
    Callback = function(V) UpdateCFG("HalloweenAutoOpenBags", V) end
})

Tabs.Halloween:AddToggle("TogHalLimitedPull", {
    Title = "4. ซื้อตั๋ว Limited Pull อัตโนมัติ (800 ลูกอม)",
    Default = CFG.HalloweenAutoBuyLimitedPull,
    Callback = function(V) UpdateCFG("HalloweenAutoBuyLimitedPull", V) end
})

Tabs.Halloween:AddToggle("TogHalTrick", {
    Title = "5. เดินไปขอขนมฟรีอัตโนมัติ (Auto Trick or Treat)",
    Default = CFG.HalloweenAutoTrickOrTreat,
    Callback = function(V) UpdateCFG("HalloweenAutoTrickOrTreat", V) end
})

-- ------------------------------------------------------------------------------
-- 🤝 TAB 8: SAFE AUTO TRADE
-- ------------------------------------------------------------------------------
Tabs.Trade:AddSection("🎯 เป้าหมายการเทรด")

local function GetPlayerNames() 
    local n = {"[ เลือกทุกคนในห้อง ]"} 
    for _, p in ipairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer then table.insert(n, p.Name) end 
    end 
    return n 
end

local DropdownTrade = Tabs.Trade:AddDropdown("DropTradeTarget", {
    Title = "เลือกผู้เล่นที่จะเทรดด้วย",
    Values = GetPlayerNames(),
    Default = CFG.TradeTarget or "[ เลือกทุกคนในห้อง ]",
    Multi = false,
    Callback = function(selection)
        UpdateCFG("TradeTarget", selection)
        if selection == "[ เลือกทุกคนในห้อง ]" then
            UpdateCFG("TradeTargetId", nil)
        else
            local t = Players:FindFirstChild(selection) 
            if t then UpdateCFG("TradeTargetId", t.UserId) end 
        end
    end
})

Tabs.Trade:AddButton({
    Title = "🔄 รีเฟรชรายชื่อผู้เล่น",
    Callback = function()
        DropdownTrade:SetValues(GetPlayerNames())
        Notify("🤝 ผู้เล่น", "รีเฟรชรายชื่อผู้เล่นในห้องเรียบร้อย", 2)
    end
})

Tabs.Trade:AddSection("⚙️ การส่งไอเทม & โหมดการทำงาน")

local function GetRealItemCount(itemName)
    local data = State.Data
    if not data then return 0 end
    local itemCfg = Config.TradeItemByKey and Config.TradeItemByKey[itemName]
    if itemCfg and Stats and Stats.TradeItemCount then
        local count = Stats.TradeItemCount(data, itemCfg)
        if itemName == "SuperRolls" then count = count - (State.SuperQueued or 0)
        elseif itemName == "JackpotRolls" then count = count - (State.JackpotQueued or 0) end
        return math.max(0, count)
    end
    if type(data[itemName]) == "number" then return data[itemName] end
    if data.Inventory and type(data.Inventory[itemName]) == "number" then return data.Inventory[itemName] end
    if data.Potions and type(data.Potions[itemName]) == "number" then return data.Potions[itemName] end
    if data.Items and type(data.Items[itemName]) == "number" then return data.Items[itemName] end
    if data.Currencies and type(data.Currencies[itemName]) == "number" then return data.Currencies[itemName] end
    return 0
end

local tradeItemList = {}
for _, item in ipairs(Config.TradeItems or {}) do table.insert(tradeItemList, item.Key) end
if #tradeItemList == 0 then
    tradeItemList = {"PotionLuck", "PotionCash", "PotionSpeed", "Gems", "Shards", "SuperRolls", "JackpotRolls", "LootBags"}
end

Tabs.Trade:AddToggle("TogAutoDropItems", {
    Title = "🎁 ส่งไอเทมทั้งหมดอัตโนมัติ (เช็คจำนวนจริงในกระเป๋า)",
    Default = CFG.AutoDropItems,
    Callback = function(V) UpdateCFG("AutoDropItems", V) end
})

Tabs.Trade:AddToggle("TogAutoReady", {
    Title = "✅ กดพร้อม (Ready) อัตโนมัติ",
    Default = CFG.AutoReady,
    Callback = function(V) UpdateCFG("AutoReady", V) end
})

Tabs.Trade:AddToggle("TogSender", {
    Title = "🚀 โหมดไอดีหลัก (ส่งคำขอเทรด)",
    Default = CFG.SenderMode,
    Callback = function(V) 
        UpdateCFG("SenderMode", V) 
        if V and not CFG.AutoDropItems then
            UpdateCFG("AutoDropItems", true)
        end
    end
})

Tabs.Trade:AddToggle("TogReceiver", {
    Title = "🛒 โหมดไอดีไก่ (รับคำขอเทรด)",
    Default = CFG.ReceiverMode,
    Callback = function(V) UpdateCFG("ReceiverMode", V) end
})

Tabs.Trade:AddToggle("TogTwoWayTrade", {
    Title = "🛡️ ระบบแลกเปลี่ยนสองทาง (Safe Two-Way Trade - ป้องกัน Mule Ban)",
    Description = "ฝั่งรับจะใส่ไอเทมพื้นฐานหรือสัตว์เลี้ยงระดับต่ำตอบแทนกลับไป ป้องกันการถูกเซิร์ฟเวอร์ตรวจจับบัญชีคลัง/Mule แบน 100%",
    Default = CFG.TwoWayTrade ~= false,
    Callback = function(V) UpdateCFG("TwoWayTrade", V) end
})

local SliderTradeCooldown = Tabs.Trade:AddSlider("SlideTradeCooldown", {
    Title = "⏱️ ระยะเวลาพักคูลดาวน์ระหว่างรอบเทรด (วินาที)",
    Description = "หน่วงเวลาพักหลังจากจบเทรดแต่ละรอบ เพื่อความปลอดภัยจากการตรวจจับบอท (แนะนำ 60-120 วิ)",
    Default = CFG.TradeCooldown or 90,
    Min = 15,
    Max = 300,
    Rounding = 0,
    Callback = function(val)
        UpdateCFG("TradeCooldown", val)
    end
})

Tabs.Trade:AddInput("InputTradeCooldown", {
    Title = "⌨️ กำหนดระยะเวลาพักคูลดาวน์เอง (พิมพ์วินาที)",
    Default = tostring(CFG.TradeCooldown or 90),
    Numeric = true,
    Finished = true,
    Callback = function(val)
        local num = tonumber(val)
        if num and num >= 10 then
            local clamped = math.clamp(num, 10, 600)
            SliderTradeCooldown:SetValue(clamped)
            UpdateCFG("TradeCooldown", clamped)
            Notify("⏱️ ตั้งค่าเวลา", "กำหนดเวลาพักระหว่างรอบเทรดเป็น: " .. clamped .. " วินาที", 2)
        end
    end
})

local SliderTradeReadyDelay = Tabs.Trade:AddSlider("SlideTradeReadyDelay", {
    Title = "⏱️ เวลาหน่วงก่อนกด Ready ในหน้าต่างเทรด (วินาที)",
    Description = "เลียนแบบมนุษย์จริงที่ต้องใช้เวลาดูไอเทมในหน้าต่างเทรด 3-5 วินาทีก่อนกด Ready",
    Default = CFG.TradeReadyDelay or 4,
    Min = 2,
    Max = 10,
    Rounding = 0,
    Callback = function(val)
        UpdateCFG("TradeReadyDelay", val)
    end
})

local TradeStatusPara = Tabs.Trade:AddParagraph({
    Title = "⏳ สถานะระบบเทรดความปลอดภัย...",
    Content = "กำลังตรวจสอบสถานะการเทรด..."
})

local function UpdateTradeStatus()
    pcall(function()
        local modeStr = "⚪ ปิดระบบเทรด"
        if CFG.SenderMode then
            modeStr = "🚀 โหมดไอดีส่งของ (Sender) ➔ เป้าหมาย: " .. tostring(CFG.TradeTarget or "ทุกคน")
        elseif CFG.ReceiverMode then
            modeStr = "🛒 โหมดไอดีรับของ (Receiver) ➔ รับจาก: " .. tostring(CFG.TradeTarget or "ทุกคน")
        end
        
        local lastTime = getgenv().LastTradeCompleteTime or 0
        local elapsed = tick() - lastTime
        local cd = CFG.TradeCooldown or 90
        local left = math.max(0, math.floor(cd - elapsed))
        
        local cdStatus
        if left > 0 then
            cdStatus = string.format("⏳ พักคูลดาวน์: เหลืออีก %d วินาที (ป้องกัน Mule Flag)", left)
        else
            cdStatus = "🟢 พร้อมเทรดรอบถัดไป"
        end
        
        local twoWayStatus = (CFG.TwoWayTrade ~= false) and "🟢 เปิดใช้งาน (Safe Two-Way)" or "🔴 ปิด (One-Way)"
        local inTradeStatus = IsInTrade() and "🤝 กำลังอยู่ในหน้าต่างเทรด" or "💤 ไม่ได้อยู่ในหน้าต่างเทรด"
        
        TradeStatusPara:SetTitle("🛡️ ระบบเทรดปลอดภัย: " .. cdStatus)
        TradeStatusPara:SetDesc(string.format("โหมด: %s\nสถานะ: %s\nระบบแลกเปลี่ยนสองทาง: %s | หน่วงเวลา Ready: %d วิ",
            modeStr, inTradeStatus, twoWayStatus, CFG.TradeReadyDelay or 4))
    end)
end

task.spawn(function()
    while true do
        task.wait(1.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        UpdateTradeStatus()
    end
end)

local function PutSafeTwoWayTradeItem()
    local data = State.Data
    if not data then return false end
    
    -- 1. ค้นหาน้ำยาหรือไอเทมพื้นฐานที่มีในตัวมากกว่า 0
    local safeCandidates = {
        "PotionSpeed", "PotionLuck", "PotionCash", 
        "Speed15", "Speed30", "Gems", "Shards"
    }
    for _, itemKey in ipairs(safeCandidates) do
        local count = GetRealItemCount(itemKey)
        if count and count >= 1 then
            Fire("TradeItem", itemKey, 1)
            return true, itemKey
        end
    end
    
    -- 2. หากไม่มีน้ำยา ตรวจสอบสัตว์เลี้ยงระดับล่าง (Rank >= 7 หรือเกรด F/E/D/C) ที่ไม่ได้ล็อค
    if data.Pets then
        for uid, pet in pairs(data.Pets) do
            local sUid = tostring(uid)
            local rank = GetPetGradeRank(pet)
            if rank >= 7 and not IsPetGradeLocked(pet, 5) then
                Fire("TradeAddPets", { sUid })
                return true, "Pet_" .. tostring(pet.Id)
            end
        end
    end
    
    return false
end

local function IsAllowedTradeSender(senderId, senderName)
    if not senderId and not senderName then return false end
    -- หากเป็นค่าเริ่มต้น หรือเลือกทุกคนในห้อง หรือไม่มีการล็อคไอดี -> ยอมรับทุกคน
    if not CFG.TradeTarget or CFG.TradeTarget == "[ เลือกทุกคนในห้อง ]" or CFG.TradeTargetId == nil then
        return true
    end
    -- เช็คความตรงกันของ UserId (แปลงเป็นตัวเลขป้องกัน type mismatch)
    if CFG.TradeTargetId and senderId and tonumber(senderId) == tonumber(CFG.TradeTargetId) then
        return true
    end
    -- เช็คความตรงกันของชื่อผู้เล่น (แปลงพิมพ์เล็กป้องกัน case sensitive mismatch)
    if senderName and CFG.TradeTarget and tostring(senderName):lower() == tostring(CFG.TradeTarget):lower() then
        return true
    end
    return false
end

local lastTradeRespondTick = 0

local function RespondAcceptTrade(senderId, senderName)
    local now = tick()
    if now - lastTradeRespondTick < 3.0 then return end
    lastTradeRespondTick = now
    
    -- ล็อคสถานะเซสชันเทรดทันที เพื่อป้องกันหอคอยหรือลูปอื่นแทรกแซงระหว่างเริ่มเทรด
    getgenv().TradeActiveSession = true
    
    task.spawn(function()
        -- ตรวจสอบคูลดาวน์ความปลอดภัย หากเพิ่งจบการเทรดไปไม่นาน ให้รออย่างน้อย 5-10 วินาทีก่อนรับคำขอใหม่
        local lastComplete = getgenv().LastTradeCompleteTime or 0
        local elapsed = now - lastComplete
        local minWait = math.min(10, (CFG.TradeCooldown or 90) / 6)
        if elapsed < minWait then
            local waitMore = minWait - elapsed
            Notify("⏱️ คูลดาวน์เทรด", string.format("รอความปลอดภัย %d วินาทีก่อนตอบรับคำขอเทรด...", math.ceil(waitMore)), 2)
            task.wait(waitMore)
        end
        
        -- 1. หน่วงเวลาด้วย Humanizer (1.5 - 2.5 วินาที) สอดคล้องกับพฤติกรรมมนุษย์และระบบความปลอดภัย
        Humanizer.Wait(1.5, 2.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then return end
        
        -- 2. ส่ง Action Remote ตอบรับการเทรดไปยังเซิร์ฟเวอร์โดยตรงครั้งเดียว (ไม่กดปุ่มซ้ำซ้อนเพื่อป้องกันคำสั่งเบิ้ล)
        if senderId then
            Fire("TradeRespond", senderId, true)
        end
        
        -- 3. ซ่อน UI TradeRequest ของเกมเพื่อความเรียบร้อย
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local tr = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root.Effects:FindFirstChild("TradeRequest")
            if tr then tr.Visible = false end
        end)
        
        Notify("🤝 ยอมรับคำขอเทรด", "ตอบรับคำขอเทรดจาก " .. tostring(senderName or "ผู้เล่น") .. " เรียบร้อย!", 3)
        
        -- Safety timeout: หากไม่มีเซสชันเทรดเปิดขึ้นภายใน 10 วินาที ให้ปลดล็อคสถานะ
        task.delay(10, function()
            if not getgenv().CurrentTradeSession and not GetTradeWindow() then
                getgenv().TradeActiveSession = false
            end
        end)
    end)
end

local function GetTradeWindow()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local root = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI:FindFirstChild("Root")
    local panels = root and root:FindFirstChild("Panels")
    local tp = panels and panels:FindFirstChild("TradingPanel")
    if tp and tp.Visible then
        local win = tp:FindFirstChild("Window", true)
        if win and win.Visible then
            return tp
        end
    end
    return nil
end

local function GetTradeReadyButton()
    local tp = GetTradeWindow()
    if not tp then return nil, "" end
    local readyFrame = tp:FindFirstChild("Ready", true)
    if not readyFrame then return nil, "" end
    local face = readyFrame:FindFirstChild("Face") or readyFrame:FindFirstChildWhichIsA("TextButton", true)
    local lbl = readyFrame:FindFirstChildWhichIsA("TextLabel", true)
    return face, (lbl and lbl.Text or "")
end

local function IsInTrade()
    return getgenv().TradeActiveSession == true or getgenv().CurrentTradeSession ~= nil or GetTradeWindow() ~= nil
end

-- ------------------------------------------------------------------------------
-- 🛡️ TAB 9: SAFETY & SETTINGS
-- ------------------------------------------------------------------------------
Tabs.Settings:AddSection("🛡️ ข้อมูลระบบความปลอดภัย (Security Dashboard)")

Tabs.Settings:AddParagraph({
    Title = "🛡️ การป้องกันการตรวจจับ (Anti-AI & Safe Engine)",
    Content = "• Humanizer: หน่วงเวลาด้วยการสุ่มแบบ Gaussian Randomization เลียนแบบพฤติกรรมมนุษย์\\n" ..
              "• Pre-condition Checker: เช็คความพร้อมของเงิน, บัฟ, และเควสก่อนยิงคำสั่ง ป้องกัน error รัว\\n" ..
              "• Rate Limit & Circuit Breaker: พักการทำงานอัตโนมัติเมื่อเกิดข้อผิดพลาด ป้องกันการตรวจจับ\\n" ..
              "• Trade Isolation: ระงับการฟาร์มทั้งหมดระหว่างเทรด ป้องกันบั๊กและถูกตรวจจับ 100%\\n" ..
              "• Pet Buff Lock: ล็อคบัฟและเกรดเทพทันที ไม่มีการสุ่มทับตัวที่ถึงหรือเกินเป้าหมาย"
})

Tabs.Settings:AddSection("⚙️ การตั้งค่าและปุ่มลัด")

Tabs.Settings:AddKeybind("KeybindToggleUI", {
    Title = "คีย์ลัดเปิด/ปิดหน้าต่าง UI",
    Mode = "Toggle",
    Default = "RightControl",
    Callback = function()
        Window:Minimize()
    end
})

Tabs.Settings:AddButton({
    Title = "💾 บันทึกการตั้งค่าลงไฟล์ (Save Config)",
    Callback = function()
        if writefile then
            pcall(function()
                writefile(ConfigFile, HS:JSONEncode(getgenv().CFG))
                Notify("💾 บันทึกสำเร็จ", "บันทึกการตั้งค่าลงไฟล์ " .. ConfigFile .. " เรียบร้อย!", 3)
            end)
        end
    end
})

Tabs.Settings:AddButton({
    Title = "🔄 คืนค่าเริ่มต้น (Reset Default Config)",
    Callback = function()
        for k, v in pairs(defaultCFG) do
            getgenv().CFG[k] = v
        end
        if writefile then
            pcall(function() writefile(ConfigFile, HS:JSONEncode(defaultCFG)) end)
        end
        Notify("🔄 รีเซ็ตสำเร็จ", "คืนค่าเริ่มต้นเรียบร้อยแล้ว!", 3)
    end
})

Tabs.Settings:AddSection("🚀 อัปเดตสคริปต์เรียลไทม์ (Live GitHub Auto-Update)")

Tabs.Settings:AddParagraph({
    Title = "📡 แหล่งที่มาทางการ (Official GitHub Repository)",
    Content = "URL: raw.githubusercontent.com/markrunerppl-boop/petdicezaza/main/petdicezaza.lua\n" ..
              "• ซิงค์เกมเรียลไทม์: เชื่อมต่อ State.OnChanged รับการเปลี่ยนแปลงของตัวเกมทันทีทุกเฟรม\n" ..
              "• อัปเดตสคริปต์สด: กดปุ่มด้านล่างเพื่อดึงโค้ดล่าสุดจาก GitHub และเริ่มทำงานใหม่ได้ทันทีโดยไม่ต้องเข้าเกมใหม่"
})

Tabs.Settings:AddButton({
    Title = "🔄 อัปเดตสคริปต์จาก GitHub ทันที (Live Hot-Reload)",
    Description = "ดาวน์โหลดโค้ดล่าสุดจาก GitHub และเริ่มทำงานใหม่ทันที",
    Callback = function()
        Notify("🔄 กำลังตรวจสอบอัปเดต...", "กำลังดาวน์โหลดโค้ดล่าสุดจาก GitHub...", 4)
        task.spawn(function()
            local success, newCode = pcall(function()
                local url = "https://raw.githubusercontent.com/markrunerppl-boop/petdicezaza/main/petdicezaza.lua?t=" .. tostring(tick())
                return game:HttpGet(url)
            end)
            if success and newCode and #newCode > 1000 then
                local fn, compileErr = loadstring(newCode)
                if fn then
                    Notify("✅ อัปเดตสำเร็จ!", "กำลังรันสคริปต์เวอร์ชันใหม่ล่าสุด...", 3)
                    task.wait(0.5)
                    getgenv().PetDiceForceReload = true
                    getgenv().PetDiceScriptLoaded = false
                    getgenv().PetDiceScriptStarting = nil
                    getgenv().PetDiceScriptToken = tick()
                    if Fluent and Fluent.Destroy then
                        pcall(function() Fluent:Destroy() end)
                    end
                    task.wait(0.3)
                    task.spawn(fn)
                else
                    Notify("❌ เกิดข้อผิดพลาด", "โค้ดจาก GitHub คอมไพล์ไม่ผ่าน: " .. tostring(compileErr), 5)
                end
            else
                Notify("❌ ดาวน์โหลดไม่สำเร็จ", "ไม่สามารถดึงข้อมูลจาก GitHub ได้ กรุณาลองใหม่อีกครั้ง", 4)
            end
        end)
    end
})

Window:SelectTab(1)

-- ==============================================================================
-- [7] TRADE EVENT LISTENER
-- ==============================================================================
TradeRemote.OnClientEvent:Connect(function(event, payload)
    if getgenv().PetDiceScriptToken ~= scriptToken then return end
    
    if event == "Request" and CFG.ReceiverMode then
        local senderId = payload and payload.UserId
        local senderName = payload and payload.Name or "Unknown"
        if IsAllowedTradeSender(senderId, senderName) then
            RespondAcceptTrade(senderId, senderName)
        end
    elseif event == "Open" or event == "Update" then
        getgenv().TradeActiveSession = true
        getgenv().CurrentTradeSession = payload
    elseif event == "Closed" then
        getgenv().CurrentTradeSession = nil
        getgenv().TradeItemsDropped = false
        getgenv().ReceiverItemPut = false
        getgenv().LastTradeCompleteTime = tick()
        task.spawn(function()
            Humanizer.Wait(2.0, 3.5)
            getgenv().TradeActiveSession = false
        end)
        local statusMsg = (payload == "TRADE COMPLETE!" or payload == true) and "เทรดสำเร็จเรียบร้อย!" or ("เซสชันเทรดสิ้นสุด (" .. tostring(payload or "Closed") .. ")")
        Notify("🤝 ระบบเทรด", statusMsg .. string.format(" | เริ่มพักคูลดาวน์ความปลอดภัย %d วินาที (ป้องกัน Mule Flag)", CFG.TradeCooldown or 90), 4)
    end
end)

-- ==============================================================================
-- [7.1] REAL-TIME GAME STATE SYNC (State.OnChanged)
-- ==============================================================================
pcall(function()
    if State and State.OnChanged then
        local lastEquipBestTick = 0
        State.OnChanged(function(syncData)
            if getgenv().PetDiceScriptToken ~= scriptToken then return end
            pcall(function()
                if not syncData then return end
                
                -- อัปเดตข้อมูลสถิติหน้าแรกทันทีเมื่อตัวเลข เงิน เพชร ชาร์ด สัตว์เลี้ยง หรือซีซั่นเปลี่ยน
                UpdateOverviewTab()
                
                -- อัปเดตสถานะหอคอยทันทีเมื่อชั้นเปลี่ยน หรือเริ่ม/จบหอคอย
                if UpdateTowerStatus and (syncData.Full or syncData.TowerResume or syncData.TowerBest) then
                    UpdateTowerStatus()
                end
                
                -- อัปเดตสถานะน้ำยาทันทีเมื่อกดใช้ หรือเวลาน้ำยาเปลี่ยน
                if UpdatePotionStatus and (syncData.Full or syncData.Potions or syncData.PotionEnds or syncData.LootBags or syncData.SeasonBags) then
                    UpdatePotionStatus()
                end
                
                -- สวมใส่สัตว์เลี้ยงที่ดีที่สุดทันทีแบบเรียลไทม์ เมื่อได้รับสัตว์เลี้ยงใหม่หรือสัตว์เลี้ยงเปลี่ยน
                if CFG.AutoEquipBest and (syncData.Full or syncData.Pets or syncData.PetAdds or syncData.PetDels) then
                    local now = tick()
                    if now - lastEquipBestTick >= 1.0 then
                        lastEquipBestTick = now
                        task.spawn(function()
                            Humanizer.Wait(0.2, 0.4)
                            if getgenv().PetDiceScriptToken == scriptToken and not IsInTrade() and not getgenv().TradeActiveSession then
                                Fire("EquipBest")
                            end
                        end)
                    end
                end
            end)
        end)
    end
end)

pcall(function()
    ReplicatedStorage:GetAttributeChangedSignal("WorldBossState"):Connect(function()
        if getgenv().PetDiceScriptToken ~= scriptToken then return end
        if UpdateTowerStatus then task.delay(0.2, UpdateTowerStatus) end
    end)
    ReplicatedStorage:GetAttributeChangedSignal("WorldBossJoined"):Connect(function()
        if getgenv().PetDiceScriptToken ~= scriptToken then return end
        if UpdateTowerStatus then task.delay(0.2, UpdateTowerStatus) end
    end)
end)

-- ==============================================================================
-- [8] BACKGROUND WORKER LOOPS (14 SAFE ENGINE LOOPS)
-- ==============================================================================

-- 1. Auto Roll Dice
task.spawn(function()
    while true do
        task.wait(1.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        if not Character or not Humanoid or Humanoid.Health <= 0 then task.wait(2.0) continue end
        
        if CFG.AutoPlay then
            CircuitBreaker.Execute("AutoPlay", function()
                local data = State.Data
                if not data then return end
                
                -- สแกนเรียลไทม์: หากปลดล็อค Auto Roll ในเกมแล้ว ให้เปิดการทำงาน Native ของเกม
                if Stats and Stats.HasAuto and Stats.HasAuto(data, State.Mods and State.Mods() or {}) then
                    if not State.Auto then
                        Fire("SetAuto", true)
                        Humanizer.Wait(1.0, 1.8)
                    end
                elseif not State.Rolling then
                    Fire("Roll")
                    Humanizer.Wait(1.2, 2.0)
                end
            end)
        end
    end
end)

-- 2. Auto Buy & Equip Best Dice
task.spawn(function()
    while true do
        task.wait(3.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoBuyDice then
            CircuitBreaker.Execute("AutoBuyDice", function()
                local data = State.Data
                if not data or not data.Money or not data.OwnedDice or not Config.Dice then return end
                
                -- สแกนเรียลไทม์: ซื้อลูกเต๋าที่ดีที่สุดที่ยังไม่มีและเงินพอ
                for i = #Config.Dice, 1, -1 do
                    local d = Config.Dice[i]
                    if not data.OwnedDice[d.Id] and (data.Money or 0) >= (d.Cost or 0) then
                        Fire("BuyDice", d.Id)
                        Humanizer.Wait(1.5, 2.5)
                        break
                    end
                end
                
                -- สแกนเรียลไทม์: สวมใส่ลูกเต๋าที่ดีที่สุดที่มีในครอบครองอัตโนมัติ
                data = State.Data
                if data and data.OwnedDice and Config.Dice then
                    for i = #Config.Dice, 1, -1 do
                        local d = Config.Dice[i]
                        if data.OwnedDice[d.Id] then
                            if data.Dice ~= d.Id then
                                Fire("EquipDice", d.Id)
                                Humanizer.Wait(1.0, 1.8)
                            end
                            break
                        end
                    end
                end
            end)
        end
    end
end)

-- 3. Auto Tower Progression & Auto Farm (Loop Engine)
task.spawn(function()
    local wasTowerRunning = false
    local lastTowerId = nil
    local towerStartFloor = 0
    local consecutiveFailCount = 0
    
    while true do
        task.wait(1.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        local char = LocalPlayer.Character or Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then task.wait(1.5) continue end
        
        -- ตรวจสอบเงื่อนไข World Boss: พักหอคอยเฉพาะตอนที่ตัวละครอยู่ในบอสโลกจริง หรือกำลังเดินทางเข้าประตูบอส
        local isJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if CFG.PauseTowerForBoss and CFG.AutoWorldBoss and (isJoined or IsEnteringBossPortal == true) then
            if IsTowerRunning() then
                Fire("TowerLeave")
                Humanizer.Wait(1.0, 1.5)
            end
            task.wait(2.0)
            continue
        end
        
        if CFG.Tower then
            local data = State.Data
            if data then
                -- ตรวจสอบและปิดป๊อปอัป BattleResults หากมีค้างอยู่
                pcall(function()
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    local br = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root:FindFirstChild("Effects") and pg.PetDiceUI.Root.Effects:FindFirstChild("BattleResults")
                    if br and br.Visible then br.Visible = false end
                end)
                
                -- ปลดล็อค isSwitchingTower อัตโนมัติหากค้างเกิน 5 วินาที
                local now = tick()
                if isSwitchingTower and (now - (LiveTower.SwitchingTick or 0) > 5.0) then
                    isSwitchingTower = false
                end
                
                local isRunning = IsTowerRunning()
                local activeId = GetActiveTowerId()
                local targetId = ResolveTowerId(CFG.SelectedTower)
                
                -- ตรวจสอบเงื่อนไขการพักหอคอยเมื่อกำลังต่อสู้กับบอสโลก
                local isBossJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
                if not (CFG.PauseTowerForBoss and CFG.AutoWorldBoss and (isBossJoined or IsEnteringBossPortal == true)) then
                    if isRunning then
                        -- หากกำลังลงหอคอยอื่นที่ไม่ตรงกับเป้าหมาย ให้เปลี่ยนมาลงหอคอยเป้าหมาย
                        if activeId and activeId ~= targetId and not isSwitchingTower then
                            SwitchOrStartTower(targetId, true)
                        end
                        
                        -- หากอยู่ในอารีน่า และเปิดออโต้ออกจากอารีน่า ให้ส่งคำสั่งออกสู่ Away Mode
                        if IsTowerInArena() and CFG.AutoExitArena then
                            Fire("TowerExit")
                            Humanizer.Wait(1.0, 1.8)
                        end
                        
                        -- Watchdog: ตรวจสอบกรณีติดค้าง (หากชั้นไม่เดินเกิน 20 วินาที ให้รีสตาร์ทหอคอยใหม่ทันที)
                        if LiveTower.LastFloorTime and (now - LiveTower.LastFloorTime > 20.0) then
                            LiveTower.LastFloorTime = now
                            Fire("TowerLeave")
                            task.wait(0.5)
                            SwitchOrStartTower(targetId, true)
                        end
                    else
                        -- หอคอยไม่ได้ทำงานอยู่: ให้เริ่มลงหอคอยเป้าหมายทันทีอย่างปลอดภัย
                        local delaySec = math.max(1.5, tonumber(CFG.TowerRestartDelay) or 2.5)
                        if not isSwitchingTower and (now - lastLoopStartAttempt >= delaySec) then
                            lastLoopStartAttempt = now
                            SwitchOrStartTower(targetId, true)
                        end
                    end
                end
            end
        end
    end
end)

-- 3.1. Auto World Boss Runner (Safe Real-Time Engine)
task.spawn(function()
    local lastBossJoinAttempt = 0
    local wasInBoss = false
    while true do
        task.wait(1.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        local char = LocalPlayer.Character or Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then task.wait(2.0) continue end
        
        local wbState = ReplicatedStorage:GetAttribute("WorldBossState")
        local isJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        
        if isJoined or wbState == "Fighting" then
            if isJoined then wasInBoss = true end
        end
        
        -- เมื่อบอสโลกจบลง ให้พากลับบ้านอย่างปลอดภัย และให้ Loop Engine หอคอยกลับมาฟาร์มต่ออัตโนมัติ
        if wasInBoss and not isJoined then
            wasInBoss = false
            task.wait(1.5)
            pcall(function()
                Fire("Teleport", "Home")
            end)
            Humanizer.Wait(1.5, 2.5)
            Notify("🏰 หอคอย", "จบศึกบอสโลกเรียบร้อย กลับถึงบ้านแล้ว ระบบหอคอยจะเริ่มฟาร์มต่ออัตโนมัติ", 3)
        end
        
        if CFG.AutoWorldBoss then
            pcall(function()
                local wbElem = ReplicatedStorage:GetAttribute("WorldBossElement") or ""
                local wbDiff = ReplicatedStorage:GetAttribute("WorldBossDifficulty") or ""
                
                if wbState == "Joining" and not isJoined then
                    -- กรองธาตุ
                    local elemMatch = (not CFG.WorldBossElementFilter) or 
                                     (CFG.WorldBossElementFilter == "[ ตีทุกธาตุ (All Elements) ]") or 
                                     (wbElem:lower() == tostring(CFG.WorldBossElementFilter):lower()) or
                                     (tostring(CFG.WorldBossElementFilter):find(wbElem))
                    
                    -- กรองระดับความยาก
                    local diffMatch = (not CFG.WorldBossDifficultyFilter) or 
                                     (CFG.WorldBossDifficultyFilter == "[ ตีทุกระดับ (All Difficulties) ]") or
                                     (wbDiff:lower() == tostring(CFG.WorldBossDifficultyFilter):lower()) or
                                     (tostring(CFG.WorldBossDifficultyFilter):find(wbDiff))
                    
                    if elemMatch and diffMatch then
                        local now = tick()
                        if now - lastBossJoinAttempt >= 5.0 then
                            lastBossJoinAttempt = now
                            CircuitBreaker.Execute("WorldBossJoin", function()
                                local data = State.Data
                                local isBossUnlocked = false
                                if Upgrades and Upgrades.IsOpen and data and data.Upgrades then
                                    isBossUnlocked = Upgrades.IsOpen(data.Upgrades, "WorldBoss")
                                end
                                
                                -- ตรวจสอบหากยังไม่ปลดล็อค แต่มีเงินพอซื้อ 1 Qi
                                if not isBossUnlocked and data and (data.Money or 0) >= 1e18 then
                                    Notify("⚔️ บอสโลก", "กำลังปลดล็อค 'WORLD BOSSES' ในผังอัปเกรดให้อัตโนมัติ...", 3)
                                    Fire("BuyUpgrade", "worldboss")
                                    Humanizer.Wait(1.0, 1.5)
                                    data = State.Data
                                    if Upgrades and Upgrades.IsOpen and data and data.Upgrades then
                                        isBossUnlocked = Upgrades.IsOpen(data.Upgrades, "WorldBoss")
                                    end
                                end
                                
                                -- ถ้ายังไม่ปลดล็อค ไม่ต้องออกจากหอคอย ไม่ต้องเดินไปประตูบอสโลก ให้ฟาร์มหอคอยต่อไปอย่างปลอดภัย 100%
                                if not isBossUnlocked then return end
                                
                                -- ตรวจสอบการซ่อมแซมประตูบอสโลก
                                if data and not data.PortalRepaired then
                                    Fire("PortalRepair")
                                    Humanizer.Wait(0.5, 1.0)
                                end
                                
                                -- 1. พักหอคอยก่อนเพื่อให้สัตว์เลี้ยงว่างพร้อมตีบอส
                                if CFG.PauseTowerForBoss and IsTowerRunning() then
                                    Fire("TowerLeave")
                                    Humanizer.Wait(0.8, 1.5)
                                end
                                
                                -- 2. เดินทางไปหน้าประตูบอสด้วยระบบทางการของตัวเกม และเดินขึ้นบันไดตามธรรมชาติ (ปลอดภัยจากการตรวจจับ 100%)
                                SafeWalkToBossPortal()
                                
                                -- 3. Humanizer หน่วงเวลาเล็กน้อย
                                Humanizer.Wait(0.5, 1.0)
                                if getgenv().PetDiceScriptToken ~= scriptToken or not CFG.AutoWorldBoss then return end
                                
                                -- 4. ส่งคำสั่งเข้าร่วมบอสโลก
                                Fire("WorldBossJoin")
                                
                                local portalModel = workspace:FindFirstChild("Market") and workspace.Market:FindFirstChild("WorldBossPortal")
                                local promptSpot = portalModel and portalModel:FindFirstChild("PromptSpot")
                                if promptSpot then
                                    local prompt = promptSpot:FindFirstChild("JoinPrompt")
                                    if prompt and typeof(fireproximityprompt) == "function" and prompt.Enabled then
                                        pcall(fireproximityprompt, prompt)
                                    end
                                end
                                
                                Notify("⚔️ บอสโลก", string.format("เข้าร่วมการตีบอสโลก [%s %s] สำเร็จ!", wbDiff, wbElem), 4)
                            end)
                        end
                    end
                end
            end)
        end
    end
end)

-- 4. Auto Rebirth
task.spawn(function()
    while true do
        task.wait(4.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoRebirth then
            CircuitBreaker.Execute("AutoRebirth", function()
                local data = State.Data
                if not data then return end
                local cost = Stats.RebirthCost(data)
                if cost and (data.Money or 0) >= cost then
                    Fire("Rebirth")
                    Humanizer.Wait(2.0, 3.5)
                end
            end)
        end
    end
end)

-- 5. Auto Upgrade Skill Tree (Buy All Affordable Upgrades)
task.spawn(function()
    while true do
        local delayTime = CFG.UpgradeTreeDelay or 3
        task.wait(delayTime)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.UpgradeTree then
            CircuitBreaker.Execute("UpgradeTree", function()
                local data = State.Data
                if not data or not data.Upgrades or not data.Money then return end
                
                -- สแกนเรียลไทม์: ตรวจสอบว่ามีอัปเกรดที่เงินพอซื้อได้จริงหรือไม่
                if Upgrades and Upgrades.PlanBuyAll then
                    local planned, totalCost = Upgrades.PlanBuyAll(data.Upgrades, data.Money, 50)
                    if planned and #planned > 0 then
                        Fire("BuyAllUpgrades")
                        Humanizer.Wait(1.5, 2.5)
                    end
                else
                    Fire("BuyAllUpgrades")
                    Humanizer.Wait(2.0, 3.0)
                end
            end)
        end
    end
end)

-- 6. Auto Equip Best Pets
local lastTotalPets = 0
local lastPeriodicEquipTime = 0
task.spawn(function()
    while true do
        task.wait(2.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoEquipBest then
            CircuitBreaker.Execute("AutoEquipBest", function()
                local data = State.Data
                if not data or not data.Pets then return end
                
                local currentTotal = 0
                for _ in pairs(data.Pets) do currentTotal = currentTotal + 1 end
                
                local equippedCount = (data.Equipped and #data.Equipped) or 0
                local maxEquipped = 1
                pcall(function()
                    if Stats and Stats.MaxEquipped then
                        maxEquipped = Stats.MaxEquipped(data) or 1
                    end
                end)
                local now = tick()
                
                -- สแกนเรียลไทม์:
                -- 1. มีสัตว์เลี้ยงใหม่เข้ามา (currentTotal ~= lastTotalPets)
                -- 2. สัตว์เลี้ยงที่ใส่อยู่ยังไม่เต็มช่อง (equippedCount < maxEquipped)
                -- 3. ตรวจสอบเป็นระยะทุกๆ 8 วินาที เพื่ออัปเดตทีมที่ดีที่สุดเสมอเมื่อสัตว์เลี้ยงเลเวลอัป
                local shouldEquip = false
                if currentTotal ~= lastTotalPets then
                    shouldEquip = true
                    lastTotalPets = currentTotal
                elseif equippedCount < maxEquipped then
                    shouldEquip = true
                elseif (now - lastPeriodicEquipTime) >= 8.0 then
                    shouldEquip = true
                end
                
                if shouldEquip then
                    lastPeriodicEquipTime = now
                    Fire("EquipBest")
                    Humanizer.Wait(1.5, 2.5)
                end
            end)
        end
    end
end)

-- 7. Auto Expedition
task.spawn(function()
    while true do
        task.wait(8.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoExpedition then
            CircuitBreaker.Execute("AutoExpedition", function()
                local data = State.Data
                if not data or not data.Expeditions then return end
                
                -- 1. สแกนเรียลไทม์: เคลมรางวัลการผจญภัยที่เสร็จแล้ว
                ClaimAllDoneExpeditions()
                Humanizer.Wait(1.0, 2.0)
                
                -- 2. สแกนเรียลไทม์: ตรวจสอบจำนวนช่องว่างก่อนส่งสัตว์เลี้ยง
                data = State.Data
                local maxSlots = Expeditions and Expeditions.Slots and Expeditions.Slots(data) or 3
                local activeCount = #(data.Expeditions and data.Expeditions.Active or {})
                if activeCount < maxSlots then
                    local pets = GetNightmarePets(CFG.ExpeditionPetCount or 1)
                    if #pets > 0 then
                        Fire("SendExpedition", "Nightmare", pets)
                        Humanizer.Wait(1.5, 2.5)
                    end
                end
            end)
        end
    end
end)

-- 8. Auto Halloween (100% Anti-Ban, Real-Time & Safe Execution)
local claimedGoalsCache = {}
local lastHalloweenBuyTick = 0
local lastHalloweenBagOpenTick = 0

task.spawn(function()
    while true do
        task.wait(6.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        
        -- ป้องกันการทำงานแทรกแซงระหว่างลงหอคอย เทรด หรือสู้บอสโลก
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(3.0) continue end
        if IsTowerRunning() or IsTowerInArena() then task.wait(3.0) continue end
        local isJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if isJoined then task.wait(3.0) continue end
        if not Character or not Humanoid or Humanoid.Health <= 0 then task.wait(3.0) continue end
        
        CircuitBreaker.Execute("AutoHalloween", function()
            local entry, seasonInfo = GetHalloweenEntry()
            if not entry or not seasonInfo then return end
            
            -- 1. Auto Claim Goals: เคลมเป้าหมายทีละ 1 รายการ และมีแคชป้องกันการยิงซ้ำซ้อนเด็ดขาด
            if CFG.HalloweenAutoClaim and HalloweenConfig.Goals then
                for _, g in ipairs(HalloweenConfig.Goals) do
                    local currentTier = entry.Goals and entry.Goals[g.Id] or 0
                    local nextTierIdx = currentTier + 1
                    local nextTier = g.Tiers and g.Tiers[nextTierIdx]
                    local stat = entry.Stats and entry.Stats[g.Stat] or 0
                    
                    if nextTier and stat >= nextTier.Goal then
                        local cacheKey = g.Id .. "_" .. tostring(nextTierIdx)
                        local lastClaim = claimedGoalsCache[cacheKey] or 0
                        if tick() - lastClaim > 60 then
                            claimedGoalsCache[cacheKey] = tick()
                            Fire("HalloweenGoalClaim", g.Id)
                            Notify("🎁 เป้าหมายฮาโลวีน", "รับรางวัลเป้าหมาย " .. tostring(g.Id) .. " (ขั้นที่ " .. nextTierIdx .. ") เรียบร้อย!", 2)
                            Humanizer.Wait(1.5, 2.5)
                            break -- เคลมเพียง 1 รายการต่อรอบลูป ป้องกัน server rate limit / dupe flag
                        end
                    end
                end
            end
            
            -- 2. Auto Buy Bags (270 Candy): หน่วงเวลาพักระหว่างซื้ออย่างปลอดภัย
            local nowTick = tick()
            if CFG.HalloweenAutoBuyBags and (entry.Candy or 0) >= 270 and (nowTick - lastHalloweenBuyTick > 15) then
                lastHalloweenBuyTick = nowTick
                Fire("SpookyBuy", "HalloweenBag10")
                Notify("🛍️ ฮาโลวีน", "ซื้อแพ็ค 10 กระเป๋าฮาโลวีนเรียบร้อย!", 2)
                Humanizer.Wait(1.5, 2.5)
            end
            
            -- 3. Auto Buy Limited Pull (800 Candy): ตรวจสอบจำนวนสต็อกจริงที่เหลือ ไม่ซื้อเกินโควต้า 5 ครั้งเด็ดขาด
            if CFG.HalloweenAutoBuyLimitedPull and (entry.Candy or 0) >= 800 and (nowTick - lastHalloweenBuyTick > 15) then
                local boughtPulls = entry.Bought and entry.Bought.LimitedPull or 0
                if boughtPulls < 5 then
                    lastHalloweenBuyTick = nowTick
                    Fire("SpookyBuy", "LimitedPull")
                    Notify("🎟️ ฮาโลวีน", "ซื้อ Limited Pull สำเร็จ! (" .. (boughtPulls + 1) .. "/5)", 3)
                    Humanizer.Wait(1.5, 2.5)
                end
            end
            
            -- 4. Auto Open Bags: ปลอดภัย 100% ซิงค์กับระบบคัตซีน ไม่สแปมรีโมท และเคลมเฉพาะเมื่อมีสัตว์เลี้ยงค้างในระบบจริงเท่านั้น
            local bagNowTick = tick()
            if CFG.HalloweenAutoOpenBags and (bagNowTick - lastHalloweenBagOpenTick > 15) then
                local isLootBagBusy = false
                pcall(function()
                    if LootBagController and LootBagController.Api and LootBagController.Api.Busy then
                        isLootBagBusy = LootBagController.Api.Busy()
                    end
                end)
                
                if not isLootBagBusy then
                    local bagCount = State.Data and State.Data.SeasonBags and State.Data.SeasonBags.Halloween or 0
                    if bagCount > 0 then
                        lastHalloweenBagOpenTick = bagNowTick
                        Fire("OpenLootBag", "all", "Halloween")
                        Notify("🎒 ฮาโลวีน", "กำลังเปิดกระเป๋าฮาโลวีน (" .. bagCount .. " ใบ)...", 3)
                        Humanizer.Wait(4.5, 6.0) -- รอให้เซิร์ฟเวอร์คำนวณและเล่นแอนิเมชันให้จบอย่างปลอดภัย
                    end
                    
                    -- ตรวจสอบว่ามีสัตว์เลี้ยงค้างรอรับจริงหรือไม่ (ดึงข้อมูลแบบ Real-time จาก PetData.WaitingCount)
                    local waitingPets = 0
                    pcall(function()
                        if State.Data and PetData and PetData.WaitingCount then
                            waitingPets = PetData.WaitingCount(State.Data, "Season")
                        end
                    end)
                    
                    -- เคลมเฉพาะเมื่อมีสัตว์เลี้ยงรอรับจริง ๆ เท่านั้น ป้องกันการยิงแพ็กเก็ตเคลมเปล่าที่ทำให้โดนแบนเด็ดขาด
                    if waitingPets > 0 then
                        Humanizer.Wait(1.0, 1.8)
                        Fire("ClaimLootPets", "Season")
                        Notify("🐾 รับสัตว์เลี้ยง", "รับสัตว์เลี้ยงฮาโลวีน " .. waitingPets .. " ตัวเรียบร้อย!", 3)
                        Humanizer.Wait(1.5, 2.5)
                    end
                end
            end
            
            -- 5. Auto Trick or Treat: ตรวจสอบสิทธิ์ประจำวัน และเดินด้วย Humanoid:MoveTo ปลอดภัย 100% ไร้การ Tween/CFrame
            if CFG.HalloweenAutoTrickOrTreat and CanTrickOrTreat() then
                Notify("🍬 ขอขนมฮาโลวีน", "กำลังเดินไปหาเคานต์พาวคูลาเพื่อขอขนมประจำวัน...", 2)
                local arrived = WalkToPawcula()
                if arrived and CanTrickOrTreat() then
                    Humanizer.Wait(0.8, 1.5)
                    Fire("TrickOrTreat")
                    Notify("🍬 Trick or Treat", "ขอขนมฮาโลวีนสำเร็จ!", 3)
                    Humanizer.Wait(2.5, 4.0)
                    Fire("Teleport", "Home")
                    Humanizer.Wait(1.0, 2.0)
                end
            end
        end)
    end
end)

-- 9. Auto Trade Runner (Safe Real-Time Engine)
task.spawn(function()
    while true do
        task.wait(1.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        
        -- สแกนเรียลไทม์: ตรวจสอบเงื่อนไขว่าปลดล็อคการเทรดในเกมหรือยัง (10 Rebirths & 10,000 Rolls)
        local data = State.Data
        local canTrade = data and Config.TradeUnlocked and Config.TradeUnlocked(data)
        if not canTrade then
            task.wait(5.0)
            continue
        end
        
        -- ตรวจสอบการตั้งค่าเปิดรับคำขอเทรดในเกม (TradeRequests Setting)
        if CFG.ReceiverMode and data and data.Settings then
            if data.Settings.TradeRequests == false then
                Fire("SetSetting", "TradeRequests", true)
            end
        end
        
        local inTrade = IsInTrade()
        if not inTrade then
            -- 1. ฝั่งส่ง (Sender): ส่งคำขอเทรดไปยังเป้าหมาย (ตรวจสอบคูลดาวน์ความปลอดภัยเสมอ)
            if CFG.SenderMode and CFG.TradeTargetId then
                local lastComplete = getgenv().LastTradeCompleteTime or 0
                local elapsed = tick() - lastComplete
                local cd = CFG.TradeCooldown or 90
                
                if elapsed >= cd then
                    CircuitBreaker.Execute("TradeSender", function()
                        local targetPlayer = Players:GetPlayerByUserId(CFG.TradeTargetId)
                        if targetPlayer and targetPlayer.Parent == Players then
                            -- ล็อค TradeActiveSession ทันที เพื่อป้องกันหอคอยหรือลูปอื่นแทรกแซงระหว่างส่งคำขอ
                            getgenv().TradeActiveSession = true
                            Fire("TradeRequest", CFG.TradeTargetId)
                            Notify("📨 ส่งคำขอเทรด", "ส่งคำขอเทรดไปยัง " .. tostring(targetPlayer.DisplayName or targetPlayer.Name) .. " แล้ว", 3)
                            Humanizer.Wait(3.5, 5.0)
                            -- หากคู่เทรดยังไม่ตอบรับภายใน 10 วินาที และไม่มีเซสชันเทรดเปิด ให้ปลดล็อคสถานะ
                            task.delay(10, function()
                                if not getgenv().CurrentTradeSession and not GetTradeWindow() then
                                    getgenv().TradeActiveSession = false
                                end
                            end)
                        end
                    end)
                end
            end
            
            -- 2. ฝั่งรับ (Receiver): ระบบตรวจจับคำขอเทรดชั้นที่ 2 (UI Detection Fallback)
            if CFG.ReceiverMode then
                pcall(function()
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    local tr = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root.Effects:FindFirstChild("TradeRequest")
                    if tr and tr.Visible then
                        local txtLbl = tr:FindFirstChildWhichIsA("TextLabel", true)
                        local msg = txtLbl and txtLbl.Text or ""
                        local reqSenderName = msg:match("^(.-)%s+WANTS TO TRADE")
                        local reqSenderPlayer = nil
                        if reqSenderName then
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p.Name:upper() == reqSenderName:upper() or (p.DisplayName and p.DisplayName:upper() == reqSenderName:upper()) then
                                    reqSenderPlayer = p
                                    break
                                end
                            end
                        end
                        local reqSenderId = reqSenderPlayer and reqSenderPlayer.UserId
                        if not reqSenderId and CFG.TradeTargetId then reqSenderId = CFG.TradeTargetId end
                        
                        if IsAllowedTradeSender(reqSenderId, reqSenderName) then
                            RespondAcceptTrade(reqSenderId, reqSenderName or "ผู้เล่น")
                        end
                    end
                end)
            end
        else
            -- กำลังอยู่ในเซสชันเทรด (In active trade session)
            local session = getgenv().CurrentTradeSession
            local you = session and session.You
            local them = session and session.Them
            
            -- 1. โหมดดรอปไอเทมอัตโนมัติ (Sender: Auto Drop Items)
            -- รองรับทั้งเมื่อเปิด SenderMode หรือ AutoDropItems ทำการสแกนไอเทมจริงจาก State.Data แบบเรียลไทม์
            if (CFG.SenderMode or CFG.AutoDropItems) and not getgenv().TradeItemsDropped then
                Humanizer.Wait(1.5, 2.2)
                if IsInTrade() then
                    local data = State.Data
                    local itemsToDrop = {
                        "PotionLuck", "PotionCash", "PotionSpeed",
                        "Gems", "Shards", "SuperRolls", "JackpotRolls",
                        "LootBags", "BagWorld", "Speed15", "Speed30", "Speed60"
                    }
                    if Config.TradeItems then
                        for _, it in ipairs(Config.TradeItems) do
                            if it.Rune and not table.find(itemsToDrop, it.Key) then
                                table.insert(itemsToDrop, it.Key)
                            end
                        end
                    end
                    
                    local droppedCount = 0
                    for _, itemKey in ipairs(itemsToDrop) do
                        if not IsInTrade() then break end
                        local realCount = GetRealItemCount(itemKey)
                        if realCount > 0 then
                            Fire("TradeItem", itemKey, realCount)
                            droppedCount = droppedCount + 1
                            Humanizer.Wait(0.35, 0.65)
                        end
                    end
                    getgenv().TradeItemsDropped = true
                    if droppedCount > 0 then
                        Notify("🎁 ส่งไอเทม", string.format("ใส่ไอเทมลงในหน้าต่างเทรดแล้ว %d รายการ", droppedCount), 3)
                    end
                    Humanizer.Wait(1.5, 2.5)
                end
            end
            
            -- 2. โหมดแลกเปลี่ยนสองทาง (Receiver: Safe Two-Way Trade)
            -- ฝั่งรับใส่ไอเทมพื้นฐาน 1 ชิ้นตอบแทนกลับไป ป้องกันการถูกเซิร์ฟเวอร์ตรวจจับบัญชี Mule
            if CFG.ReceiverMode and (CFG.TwoWayTrade ~= false) and not getgenv().ReceiverItemPut then
                Humanizer.Wait(1.5, 2.2)
                if IsInTrade() then
                    local okPut, putItem = PutSafeTwoWayTradeItem()
                    if okPut then
                        Notify("🛡️ เทรดสองทาง", "ใส่ไอเทมตอบแทนกลับเรียบร้อย (" .. tostring(putItem) .. ") ป้องกัน Mule Flag", 3)
                    end
                    getgenv().ReceiverItemPut = true
                end
                Humanizer.Wait(1.5, 2.5)
            end
            
            -- 3. โหมดกด Ready อัตโนมัติอย่างปลอดภัย (Safe Auto Ready & Real-Time Sync)
            if CFG.AutoReady then
                session = getgenv().CurrentTradeSession
                you = session and session.You
                them = session and session.Them
                
                -- ตรวจสอบสถานะปุ่ม Ready จริงของเกม
                local readyBtnFace, readyStatusText = GetTradeReadyButton()
                
                -- ถ้าปุ่มอยู่ในสถานะรอคูลดาวน์ (เช่น "WAIT 3", "WAIT 2", "WAIT 1") ให้รอจนกว่าคูลดาวน์หมด
                if readyStatusText:find("WAIT") or (you and you.LockedFor and you.LockedFor > 0) then
                    task.wait(0.5)
                elseif readyStatusText == "UNREADY" or (you and you.Ready) then
                    -- ฝั่งเรากดพร้อมเรียบร้อยแล้ว ไม่ต้องกดซ้ำ (ป้องกันการกดยกเลิก)
                elseif readyStatusText == "READY" and (not you or not you.Ready) then
                    -- ฝั่งเรายังไม่ได้กดพร้อม และปุ่มปลดล็อคให้กดได้
                    local canPressReady = true
                    
                    -- ตรวจสอบเงื่อนไขฝั่งส่ง: ต้องใส่ไอเทมเสร็จสิ้นแล้ว
                    if (CFG.SenderMode or CFG.AutoDropItems) and not getgenv().TradeItemsDropped then
                        canPressReady = false
                    end
                    
                    -- ตรวจสอบเงื่อนไขฝั่งรับ: ต้องใส่ไอเทมสองทางแล้ว และรอให้อีกฝ่ายพร้อมหรือใส่ของแล้ว
                    if CFG.ReceiverMode then
                        if (CFG.TwoWayTrade ~= false) and not getgenv().ReceiverItemPut then
                            canPressReady = false
                        elseif them and not them.Ready then
                            local themHasItems = (them.Items and next(them.Items) ~= nil) or (them.Pets and next(them.Pets) ~= nil)
                            if not themHasItems then
                                canPressReady = false
                            end
                        end
                    end
                    
                    if canPressReady and IsInTrade() then
                        -- หน่วงเวลาก่อนกด Ready เพื่อจำลองมนุษย์ตรวจสอบไอเทม (3-5 วินาที)
                        local readyDelay = CFG.TradeReadyDelay or 4
                        Humanizer.Wait(readyDelay * 0.8, readyDelay * 1.2)
                        
                        -- Re-check confirmation before sending
                        if IsInTrade() then
                            local _, textNow = GetTradeReadyButton()
                            local curSession = getgenv().CurrentTradeSession
                            local curYou = curSession and curSession.You
                            if textNow == "READY" and (not curYou or not curYou.Ready) then
                                Fire("TradeReady", true)
                                Notify("✅ พร้อมเทรด", "กดยืนยัน Ready เรียบร้อย!", 2)
                                Humanizer.Wait(2.0, 3.0)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 10. Auto Upgrade Pet Levels (Target Level & Step Protected)
task.spawn(function()
    while true do
        task.wait(2.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoUpgradePetLevel then
            CircuitBreaker.Execute("AutoUpgradePetLevel", function()
                local data = State.Data
                if not data or not data.Pets or not data.Money then return end
                local cap = Stats.PetLevelCap(data.Upgrades)
                local targetLvl = math.min(CFG.TargetPetLevel or cap, cap)
                local step = CFG.UpgradeLevelStep or 1
                local targetUids = GetTopBestPets(CFG.EnhancePetCount or 4)
                
                for _, uid in ipairs(targetUids) do
                    if IsInTrade() or getgenv().TradeActiveSession then break end
                    local pet = data.Pets[uid]
                    if pet and (pet.L or 0) < targetLvl then
                        local curLvl = pet.L or 0
                        local needed = targetLvl - curLvl
                        local countToUpgrade = math.min(needed, step)
                        if step >= 999 then countToUpgrade = needed end
                        
                        local affordable = FindAffordableLevels(pet, data.Upgrades, data.Money, countToUpgrade)
                        if affordable > 0 then
                            if affordable == 1 then
                                Fire("UpgradePet", uid)
                            else
                                Fire("UpgradePetLevels", uid, affordable)
                            end
                            Humanizer.Wait(0.35, 0.65)
                            data = State.Data
                            if not data or not data.Money or data.Money <= 0 then break end
                        end
                    end
                end
            end)
        end
    end
end)

-- 11. Auto Roll Pet Grade (Rank <= TargetRank Strictly Locked - Safe Humanized Engine)
task.spawn(function()
    local consecutiveRolls = 0
    while true do
        task.wait(0.20)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoRollGrade then
            CircuitBreaker.Execute("AutoRollGrade", function()
                local data = State.Data
                if not data or not data.Pets or not data.Gems or data.Gems < 1 then
                    task.wait(2.0)
                    return
                end
                local targetRank = CFG.TargetGradeRank or 8
                local targetUids = GetTopBestPets(CFG.EnhancePetCount or 4)
                local rollDelay = math.clamp(CFG.RollSpeed or 0.35, 0.25, 1.2)
                local anyRolled = false
                
                for _, uid in ipairs(targetUids) do
                    if IsInTrade() or getgenv().TradeActiveSession then break end
                    if not data or not data.Gems or data.Gems < 1 then break end
                    
                    local pet = data.Pets[uid]
                    if pet and IsPetEligibleForEnhance(pet) then
                        if not IsPetGradeLocked(pet, targetRank) then
                            Fire("RollGrade", uid)
                            anyRolled = true
                            consecutiveRolls = consecutiveRolls + 1
                            
                            -- Humanizer หน่วงเวลาแบบเป็นธรรมชาติ ปลอดภัยจากการตรวจจับของ Roblox
                            Humanizer.Wait(math.max(0.25, rollDelay - 0.05), rollDelay + 0.08)
                            
                            -- พักสั้นๆ ทุก 12 ครั้งเพื่อจำลองพฤติกรรมมนุษย์ ป้องกัน Remote Burst
                            if consecutiveRolls >= 12 then
                                consecutiveRolls = 0
                                task.wait(math.random(60, 100) / 100)
                            end
                            data = State.Data
                        end
                    end
                end
                
                if not anyRolled then
                    consecutiveRolls = 0
                    task.wait(2.5) -- เมื่อสัตว์เลี้ยงทั้งหมดถึงเป้าหมายหรือไม่มีตัวให้สุ่ม พัก 2.5 วินาที ไม่ยิงซ้ำ
                end
            end)
        else
            consecutiveRolls = 0
            task.wait(1.5)
        end
    end
end)

-- 12. Auto Roll Pet Trait (Rank <= TargetRank Strictly Locked - Safe Humanized Engine)
task.spawn(function()
    local consecutiveRolls = 0
    while true do
        task.wait(0.20)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoRollTrait then
            CircuitBreaker.Execute("AutoRollTrait", function()
                local data = State.Data
                if not data or not data.Pets or not data.Shards or data.Shards < 1 then
                    task.wait(2.0)
                    return
                end
                local targetRank = CFG.TargetTraitRank or 6
                local targetUids = GetTopBestPets(CFG.EnhancePetCount or 4)
                local rollDelay = math.clamp(CFG.RollSpeed or 0.35, 0.25, 1.2)
                local anyRolled = false
                
                for _, uid in ipairs(targetUids) do
                    if IsInTrade() or getgenv().TradeActiveSession then break end
                    if not data or not data.Shards or data.Shards < 1 then break end
                    
                    local pet = data.Pets[uid]
                    if pet and IsPetEligibleForEnhance(pet) then
                        if not IsPetTraitLocked(pet, targetRank) then
                            Fire("RollTrait", uid)
                            anyRolled = true
                            consecutiveRolls = consecutiveRolls + 1
                            
                            -- Humanizer หน่วงเวลาแบบเป็นธรรมชาติ ปลอดภัยจากการตรวจจับของ Roblox
                            Humanizer.Wait(math.max(0.25, rollDelay - 0.05), rollDelay + 0.08)
                            
                            -- พักสั้นๆ ทุก 12 ครั้งเพื่อจำลองพฤติกรรมมนุษย์ ป้องกัน Remote Burst
                            if consecutiveRolls >= 12 then
                                consecutiveRolls = 0
                                task.wait(math.random(60, 100) / 100)
                            end
                            data = State.Data
                        end
                    end
                end
                
                if not anyRolled then
                    consecutiveRolls = 0
                    task.wait(2.5) -- เมื่อสัตว์เลี้ยงทั้งหมดถึงเป้าหมายหรือไม่มีตัวให้สุ่ม พัก 2.5 วินาที ไม่ยิงซ้ำ
                end
            end)
        else
            consecutiveRolls = 0
            task.wait(1.5)
        end
    end
end)

-- 13. Auto Potions & Consumables
local lastInfinityBagOpenTick = 0

task.spawn(function()
    while true do
        task.wait(2.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        if not Character or not Humanoid or Humanoid.Health <= 0 then task.wait(2.0) continue end
        
        CircuitBreaker.Execute("AutoConsumables", function()
            local data = State.Data
            if not data then return end
            local now = State.Now and State.Now() or os.time()
            local potions = data.Potions or {}
            local ends = data.PotionEnds or {}
            
            if CFG.AutoUsePotionLuck and (potions.Luck or 0) > 0 and (not ends.Luck or ends.Luck <= now) then
                Fire("UsePotion", "Luck", 1)
                Humanizer.Wait(0.5, 1.0)
            end
            if CFG.AutoUsePotionCash and (potions.Cash or 0) > 0 and (not ends.Cash or ends.Cash <= now) then
                Fire("UsePotion", "Cash", 1)
                Humanizer.Wait(0.5, 1.0)
            end
            if CFG.AutoUsePotionSpeed and (potions.Speed or 0) > 0 and (not ends.Speed or ends.Speed <= now) then
                Fire("UsePotion", "Speed", 1)
                Humanizer.Wait(0.5, 1.0)
            end
            
            -- ปลอดภัย 100%: เปิดถุงสมบัติทั่วไปแบบหน่วงเวลา 15s ซิงค์คัตซีน และเคลมเฉพาะเมื่อมีสัตว์เลี้ยงค้างจริงเท่านั้น
            local infinityBagNow = tick()
            if CFG.AutoOpenLootBags and (data.LootBags or 0) > 0 and (infinityBagNow - lastInfinityBagOpenTick > 15) then
                local isBusy = false
                pcall(function()
                    if LootBagController and LootBagController.Api and LootBagController.Api.Busy then
                        isBusy = LootBagController.Api.Busy()
                    end
                end)
                
                if not isBusy then
                    lastInfinityBagOpenTick = infinityBagNow
                    Fire("OpenLootBag", "all")
                    Notify("🎒 ถุงสมบัติ", "กำลังเปิดถุงสมบัติทั่วไป (" .. (data.LootBags or 0) .. " ใบ)...", 3)
                    Humanizer.Wait(4.5, 6.0)
                    
                    local waitingInfinity = 0
                    pcall(function()
                        if PetData and PetData.WaitingCount then
                            waitingInfinity = PetData.WaitingCount(data, "Infinity")
                        end
                    end)
                    
                    if waitingInfinity > 0 then
                        Humanizer.Wait(1.0, 1.8)
                        Fire("ClaimLootPets", "Infinity")
                        Notify("🐾 สัตว์เลี้ยง", "กดรับสัตว์เลี้ยงจากถุงสมบัติ " .. waitingInfinity .. " ตัวเรียบร้อย!", 3)
                        Humanizer.Wait(1.5, 2.5)
                    end
                end
            end
        end)
    end
end)

-- 14. Auto Rewards, Quests, & Cutscene Skip
task.spawn(function()
    while true do
        task.wait(6.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        CircuitBreaker.Execute("AutoRewardsAndQuests", function()
            local data = State.Data
            if not data then return end
            local now = State.Now and State.Now() or os.time()
            
            if CFG.Reward then
                local canDaily = false
                pcall(function() canDaily = Stats.DailyState(data, now) end)
                if canDaily then
                    Fire("Funnel", "Daily", 1)
                    Fire("ClaimDaily")
                    Humanizer.Wait(0.4, 0.8)
                end
                
                local canPlaytime = false
                pcall(function()
                    if RewardsConfig and RewardsConfig.Playtime and data.Playtime then
                        local played = RewardsConfig.PlayedToday(data.Playtime, Stats.Day(now), now)
                        for i, v in ipairs(RewardsConfig.Playtime) do
                            local claimed = (data.Playtime.Claimed or {})[tostring(i)] == true
                            local reached = (v.Minutes * 60) <= played
                            if not claimed and reached then canPlaytime = true break end
                        end
                    end
                end)
                if canPlaytime then
                    Fire("ClaimPlaytime", "all")
                    Humanizer.Wait(0.5, 1.0)
                end
            end
            
            if CFG.Quest and data.Quests then
                for i, q in ipairs(data.Quests.Daily or {}) do
                    if not q.Claimed and (q.Progress or 0) >= (q.Goal or math.huge) then
                        Fire("QuestClaim", "Daily", i)
                        Humanizer.Wait(0.3, 0.6)
                    end
                end
                for i, q in ipairs(data.Quests.Weekly or {}) do
                    if not q.Claimed and (q.Progress or 0) >= (q.Goal or math.huge) then
                        Fire("QuestClaim", "Weekly", i)
                        Humanizer.Wait(0.3, 0.6)
                    end
                end
                if QuestsLogic and QuestsLogic.Goals and data.Quests.Goals then
                    for _, gDef in ipairs(QuestsLogic.Goals) do
                        local gData = data.Quests.Goals[gDef.Id]
                        if gData and not gData.Claimed and (gData.Progress or 0) >= (gDef.Goal or math.huge) then
                            Fire("GoalClaim", gDef.Id)
                            Humanizer.Wait(0.3, 0.6)
                        end
                    end
                end
            end
            
            if CFG.Cutscene then
                pcall(function()
                    local cutsceneGui = LocalPlayer.PlayerGui:FindFirstChild("PetDiceModifierCutscene")
                    if cutsceneGui and cutsceneGui.Enabled then
                        cutsceneGui.Enabled = false
                    end
                end)
            end
        end)
    end
end)

-- 15. Continuous Tower Auto-Farm Engine & Supervisor Loop (Backup / Secondary Check)
task.spawn(function()
    task.wait(2.0)
    
    while true do
        task.wait(2.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.Tower then
            local isJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
            if CFG.PauseTowerForBoss and CFG.AutoWorldBoss and (isJoined or IsEnteringBossPortal == true) then
                task.wait(3.0)
                continue
            end
            
            local now = tick()
            
            -- ปลดล็อค isSwitchingTower อัตโนมัติหากค้างเกิน 6 วินาที
            if isSwitchingTower and (now - (LiveTower.SwitchingTick or 0) > 6.0) then
                isSwitchingTower = false
            end
            
            local isRunning = IsTowerRunning()
            local inArena = IsTowerInArena()
            
            -- ปิดหน้าต่าง BattleResults ถ้ามีค้างอยู่
            pcall(function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                local br = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root:FindFirstChild("Effects") and pg.PetDiceUI.Root.Effects:FindFirstChild("BattleResults")
                if br and br.Visible then br.Visible = false end
            end)
            
            -- ตรวจสอบการเปิดโหมดเบื้องหลัง (Away Mode) หากผู้ใช้เปิด AutoExitArena ไว้
            if isRunning and inArena and CFG.AutoExitArena then
                Fire("TowerExit")
                task.wait(0.5)
            end
            
            -- หากไม่ได้อยู่ในหอคอยจริง ให้เริ่มรอบใหม่ทันที (ใช้ shared lastLoopStartAttempt)
            if not isRunning then
                local restartDelay = math.max(1.5, tonumber(CFG.TowerRestartDelay) or 2.5)
                local sinceLastAttempt = now - lastLoopStartAttempt
                local sinceEnded = LiveTower.EndedTick and (now - LiveTower.EndedTick) or math.huge
                
                if sinceLastAttempt >= restartDelay and sinceEnded >= restartDelay then
                    lastLoopStartAttempt = now
                    local targetId = ResolveTowerId(CFG.SelectedTower)
                    SwitchOrStartTower(targetId, true)
                end
            else
                -- Anti-Stuck Watchdog: หากติดค้างนานเกิน 25 วินาทีในชั้นเดิม ให้รีเซ็ตและเริ่มใหม่
                if LiveTower.LastFloorTime and (now - LiveTower.LastFloorTime > 25.0) then
                    LiveTower.LastFloorTime = now
                    Fire("TowerLeave")
                    task.wait(1.0)
                    LiveTower.Active = false
                    LiveTower.Starting = false
                    local targetId = ResolveTowerId(CFG.SelectedTower)
                    lastLoopStartAttempt = 0
                    SwitchOrStartTower(targetId, true)
                end
            end
        end
    end
end)

-- 16. Auto Sell Pets Loop: ตรวจสอบและขายสัตว์เลี้ยงส่วนเกินอัตโนมัติ (เก็บเฉพาะ N ตัวแรกที่ค่าพลัง Base สูงสุด)
task.spawn(function()
    while true do
        task.wait(10.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(3.0) continue end
        
        if CFG.AutoSellPets and not isAutoSellingActive then
            pcall(function()
                local data = State.Data
                if not data or not data.Pets then return end
                local totalPets = 0
                for _ in pairs(data.Pets) do totalPets = totalPets + 1 end
                
                local targetK = CFG.KeepTopPetsCount or 100
                if totalPets > targetK then
                    ExecuteAutoSellPets(targetK)
                end
            end)
        end
    end
end)

-- Expose core tower functions to global environment for external access and re-entry
getgenv().PetDiceStartTower = function(towerId)
    local targetId = ResolveTowerId(towerId or CFG.SelectedTower)
    local towerDef = (Towers.ById and Towers.ById[targetId]) or Towers.List[1] or {Id=targetId, Name=targetId}
    local team = GetTowerTeam(towerDef)
    if not team or #team == 0 then
        Notify("⚠️ ไม่มีสัตว์เลี้ยง", "กรุณาสุ่มสัตว์เลี้ยงก่อนลงหอคอย", 3)
        return false
    end
    pcall(function()
        if State.Data and State.Data.Settings and State.Data.Settings.TowerAutoplay then
            Fire("SetSetting", "TowerAutoplay", false)
        end
    end)
    Fire("TowerStart", towerDef.Id, team)
    LiveTower.Active = true
    LiveTower.Starting = true
    LiveTower.LastStartTick = tick()
    LiveTower.TowerId = towerDef.Id
    LiveTower.LastEventTime = tick()
    return true
end

getgenv().PetDiceScriptLoaded = true
getgenv().PetDiceScriptStarting = nil
getgenv().PetDiceNotify = Notify

Notify("🚀 สคริปต์พร้อมทำงาน", "Pet Dice Master Fluent Edition v4.5 โหลดสำเร็จ!", 4)