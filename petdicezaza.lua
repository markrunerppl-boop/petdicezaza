-- ==============================================================================
-- 🎲 PET DICE MASTER SAFE EDITION v4.5 (FLUENT UI REBORN)
-- 🛡️ Anti-AI Detection & High-Tier Protection System
-- 🎨 Modern Windows 11 Fluent Acrylic Interface
-- ==============================================================================

if not game:IsLoaded() then 
    pcall(function() game.Loaded:Wait() end)
end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
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

-- ป้องกันรันสคริปต์ซ้ำซ้อน
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
local Season = require(PetDice.Logic.Season)
local HalloweenConfig = require(PetDice.Configs.HalloweenConfig)
local HalloweenShopConfig = require(PetDice.Configs.HalloweenShopConfig)
local Towers = require(PetDice.Logic.Towers)
local TeamPairs = require(PetDice.Logic.TeamPairs)
local RewardsConfig = require(PetDice.Configs.RewardsConfig)
local QuestsLogic = require(PetDice.Logic.Quests)
local Upgrades = require(PetDice.Logic.Upgrades)

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

local Movement = {}
function Movement.SafeTween(targetCFrame, speed)
    if not HRP or not Humanoid or Humanoid.Health <= 0 then return end
    speed = speed or 60
    local dist = (HRP.Position - targetCFrame.Position).Magnitude
    local duration = math.clamp(dist / speed, 0.4, 4.0)
    
    local tween = TweenService:Create(HRP, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        CFrame = targetCFrame + Vector3.new(0, 2.5, 0)
    })
    tween:Play()
    tween.Completed:Wait()
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

local function GetPetGradeRank(pet)
    if not pet or not pet.G then return #Modifiers.Grades + 1 end
    return Modifiers.GradeRank(pet.G) or (#Modifiers.Grades + 1)
end

local function GetPetTraitRank(pet)
    if not pet or not pet.T then return #Modifiers.Traits + 1 end
    return Modifiers.TraitRank(pet.T) or (#Modifiers.Traits + 1)
end

local function IsPetGradeLocked(pet, targetRank)
    targetRank = targetRank or (getgenv().CFG and getgenv().CFG.TargetGradeRank) or 8
    return GetPetGradeRank(pet) <= targetRank
end

local function IsPetTraitLocked(pet, targetRank)
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
        local sUid = tostring(uid)
        local baseIncome = 0
        pcall(function() baseIncome = Stats.PetBaseIncome(pet) end)
        table.insert(candidates, { uid = sUid, base = baseIncome })
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
local isMarker1c1 = (LocalPlayer.UserId == 11251813437)

local defaultCFG = {
    Tower = false, AutoPlay = false, AutoExitArena = true,
    AutoRebirth = false, AutoBuyDice = false, AutoEquipBest = true,
    Reward = false, Quest = false, Cutscene = false,
    UpgradeTree = false, UpgradeTreeDelay = 3,
    AutoExpedition = false, ExpeditionPetCount = 1,
    HalloweenAutoClaim = false,
    HalloweenAutoBuyBags = false,
    HalloweenAutoBuyLimitedPull = false,
    HalloweenAutoOpenBags = false,
    HalloweenAutoTrickOrTreat = false,
    AutoDropItems = false, AutoReady = true,
    SenderMode = not isMarker1c1, ReceiverMode = isMarker1c1, 
    TradeTarget = isMarker1c1 and "[ เลือกทุกคนในห้อง ]" or "marker1c1", 
    TradeTargetId = isMarker1c1 and nil or 11251813437,
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
    AutoOpenLootBags = false
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
Tabs.Tower:AddSection("🏰 หอคอยอินฟินิตี้ (Infinity Tower)")

Tabs.Tower:AddToggle("TogTower", {
    Title = "1. ฟาร์มหอคอยอัตโนมัติ (Auto Tower)",
    Default = CFG.Tower,
    Callback = function(V) UpdateCFG("Tower", V) end
})

Tabs.Tower:AddToggle("TogAutoExitArena", {
    Title = "2. ออกจากอารีน่าอัตโนมัติเมื่อจบชั้น (Auto Exit Arena)",
    Default = CFG.AutoExitArena,
    Callback = function(V) UpdateCFG("AutoExitArena", V) end
})

TogTowerEquipBest = Tabs.Tower:AddToggle("TogAutoEquipBest", {
    Title = "3. สวมใส่สัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (Auto Equip Best)",
    Default = CFG.AutoEquipBest,
    Callback = HandleAutoEquipBestToggle
})

Tabs.Tower:AddButton({
    Title = "▶️ เริ่มลงหอคอยทันที (Start Infinity Tower Now)",
    Description = "จัดทีมสัตว์เลี้ยงที่ดีที่สุดและส่งคำสั่งเริ่มลงหอคอย",
    Callback = function()
        local data = State.Data
        if not data then return end
        local towerDef = Towers.ById["Infinity"] or Towers.List[#Towers.List]
        local teamSize = Towers.TeamSizeFor(data)
        local team = TeamPairs.Best(data, towerDef, teamSize)
        if #team > 0 then
            Fire("SetSetting", "TowerAutoplay", true)
            Fire("TowerStart", towerDef.Id, team)
            Notify("🏰 หอคอย", "เริ่มลง Infinity Tower เรียบร้อย!", 3)
            if CFG.AutoExitArena then
                task.delay(1.5, function() Fire("TowerExit") end)
            end
        else
            Notify("⚠️ ไม่มีสัตว์เลี้ยง", "กรุณาสุ่มสัตว์เลี้ยงก่อนลงหอคอย", 3)
        end
    end
})

Tabs.Tower:AddButton({
    Title = "🚪 ออกจากอารีน่าทันที (Exit Arena to Background)",
    Description = "ส่งคำสั่งออกจากอารีน่าเพื่อเดินเล่นในแมพได้อิสระ (หอคอยยังคงฟาร์มต่อ)",
    Callback = function()
        Fire("TowerExit")
        Notify("🚪 หอคอย", "ส่งคำสั่งออกจากอารีน่าเรียบร้อย!", 2)
    end
})

Tabs.Tower:AddButton({
    Title = "🛑 สั่งหยุดลงหอคอย (Stop Tower Run)",
    Description = "ส่งคำสั่งหยุดการลงหอคอยรอบปัจจุบันทันที",
    Callback = function()
        Fire("TowerLeave")
        Notify("🛑 หอคอย", "ส่งคำสั่งหยุดการลงหอคอยเรียบร้อย!", 2)
    end
})

Tabs.Tower:AddSection("🎲 กลิ้งลูกเต๋า (Auto Dice)")

Tabs.Tower:AddToggle("TogAutoPlay", {
    Title = "4. กลิ้งลูกเต๋าอัตโนมัติ (Auto Roll Dice)",
    Default = CFG.AutoPlay,
    Callback = function(V) UpdateCFG("AutoPlay", V) end
})

Tabs.Tower:AddToggle("TogAutoBuyDice", {
    Title = "5. ซื้อลูกเต๋าอัตโนมัติเมื่อเงินพอ (Auto Buy Dice)",
    Default = CFG.AutoBuyDice,
    Callback = function(V) UpdateCFG("AutoBuyDice", V) end
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
            Notify("🎒 ถุงสมบัติ", "ส่งคำสั่งเปิดถุงสมบัติทั้งหมดเรียบร้อย!", 3)
            task.delay(1.0, function()
                Fire("ClaimLootPets", "Infinity")
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
        Fire("ClaimLootPets", "Infinity")
        Notify("🐾 สัตว์เลี้ยง", "กดรับสัตว์เลี้ยงจากถุงสมบัติเรียบร้อย!", 3)
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
    local now = State.Now and State.Now() or os.time()
    if not entry or not entry.TreatDay then return true end
    return entry.TreatDay < Season.TreatDay(now)
end

local function FindPawculaNPC()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("pawcula") then
            local pivot = obj:GetPivot()
            local standPos = Vector3.new(pivot.X - 3.5, 5.65, pivot.Z + 3.5)
            return obj, CFrame.lookAt(standPos, Vector3.new(pivot.X, 5.65, pivot.Z))
        end
    end
    return nil, nil
end

Tabs.Halloween:AddButton({
    Title = "🎁 กดรับรางวัลเป้าหมายฮาโลวีนทั้งหมด (1 คลิก)",
    Callback = function()
        local entry = GetHalloweenEntry()
        if not entry then return end
        local claimed = 0
        for _, g in ipairs(HalloweenConfig.Goals) do
            local tierIdx = (entry.Goals[g.Id] or 0) + 1
            local tier = g.Tiers[tierIdx]
            local stat = entry.Stats[g.Stat] or 0
            if tier ~= nil and stat >= tier.Goal then
                Fire("HalloweenGoalClaim", g.Id)
                claimed = claimed + 1
                Humanizer.Wait(0.6, 1.2)
            end
        end
        Notify("🎃 ฮาโลวีน", claimed > 0 and ("รับรางวัลเป้าหมาย " .. claimed .. " รายการ!") or "ยังไม่มีเป้าหมายที่สำเร็จ", 3)
    end
})

Tabs.Halloween:AddButton({
    Title = "🛍️ ซื้อแพ็คกระเป๋า 10 ใบ (270 ลูกอม)",
    Callback = function()
        local entry = GetHalloweenEntry()
        if entry and (entry.Candy or 0) >= 270 then
            Fire("SpookyBuy", "HalloweenBag10")
            Notify("🛍️ ซื้อกระเป๋า", "ซื้อแพ็คกระเป๋าฮาโลวีน 10 ใบสำเร็จ!", 3)
        else
            Notify("⚠️ ลูกอมไม่พอ", "ต้องใช้ 270 ลูกอม", 2)
        end
    end
})

Tabs.Halloween:AddButton({
    Title = "🍬 เดินไปขอขนมฮาโลวีน (Trick or Treat With Safe Tween)",
    Callback = function()
        task.spawn(function()
            local npc, pivot = FindPawculaNPC()
            if pivot then
                Movement.SafeTween(pivot)
                Humanizer.Wait(0.8, 1.5)
            end
            Fire("TrickOrTreat")
            Notify("🍬 Trick or Treat", "ส่งคำขอขนมเรียบร้อย!", 2)
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
    Callback = function(V) UpdateCFG("SenderMode", V) end
})

Tabs.Trade:AddToggle("TogReceiver", {
    Title = "🛒 โหมดไอดีไก่ (รับคำขอเทรด)",
    Default = CFG.ReceiverMode,
    Callback = function(V) UpdateCFG("ReceiverMode", V) end
})

local function GetTradeWindow()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local root = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI:FindFirstChild("Root")
    local panels = root and root:FindFirstChild("Panels")
    local tp = panels and panels:FindFirstChild("TradingPanel")
    if tp and tp.Visible then return tp end
    return nil
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

Window:SelectTab(1)

-- ==============================================================================
-- [7] TRADE EVENT LISTENER
-- ==============================================================================
TradeRemote.OnClientEvent:Connect(function(event, payload)
    if getgenv().PetDiceScriptToken ~= scriptToken then return end
    
    if event == "Request" and CFG.ReceiverMode then
        local senderId = payload and payload.UserId
        local senderName = payload and payload.Name or "Unknown"
        local allowed = (CFG.TradeTargetId == nil) or (senderId == CFG.TradeTargetId)
        if allowed and senderId then
            task.spawn(function()
                Humanizer.Wait(1.5, 2.5)
                Fire("TradeRespond", senderId, true)
                Notify("🤝 ยอมรับคำขอเทรด", "ตอบรับคำขอเทรดจาก " .. senderName .. " เรียบร้อย!", 3)
            end)
        end
    elseif event == "Open" or event == "Update" then
        getgenv().TradeActiveSession = true
        getgenv().CurrentTradeSession = payload
    elseif event == "Closed" then
        getgenv().CurrentTradeSession = nil
        getgenv().TradeItemsDropped = false
        task.spawn(function()
            Humanizer.Wait(2.0, 3.5)
            getgenv().TradeActiveSession = false
        end)
    end
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

-- 3. Auto Tower (Infinity Tower - Safe Background Runner)
task.spawn(function()
    while true do
        task.wait(2.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        if not Character or not Humanoid or Humanoid.Health <= 0 then task.wait(2.0) continue end
        
        if CFG.Tower then
            CircuitBreaker.Execute("Tower", function()
                local data = State.Data
                if not data then return end
                
                -- ตรวจสอบและเปิดการตั้งค่า Auto Tower ในตัวเกมเพื่อให้ระบบปีนชั้นเอง
                if data.Settings and not data.Settings.TowerAutoplay then
                    Fire("SetSetting", "TowerAutoplay", true)
                end
                
                -- หากยังไม่ได้ลงหอคอย ให้เริ่มต้นลง Infinity Tower ด้วยทีมสัตว์เลี้ยงที่ดีที่สุด
                if not data.TowerResume then
                    local towerDef = Towers.ById["Infinity"] or Towers.List[#Towers.List]
                    local teamSize = Towers.TeamSizeFor(data)
                    local team = TeamPairs.Best(data, towerDef, teamSize)
                    if #team > 0 then
                        Fire("TowerStart", towerDef.Id, team)
                        Humanizer.Wait(2.0, 3.5)
                        if CFG.AutoExitArena then
                            Fire("TowerExit")
                            Humanizer.Wait(1.5, 2.5)
                        end
                    end
                elseif not data.TowerResume.Away and CFG.AutoExitArena then
                    -- หากตัวละครอยู่ในอารีน่า ส่งคำสั่งออกมาให้อยู่ในโหมด Away เพื่อเดินสำรวจแมพได้อิสระ
                    Fire("TowerExit")
                    Humanizer.Wait(2.0, 3.0)
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

-- 8. Auto Halloween
task.spawn(function()
    while true do
        task.wait(5.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        CircuitBreaker.Execute("AutoHalloween", function()
            local entry = GetHalloweenEntry()
            if not entry then return end
            
            if CFG.HalloweenAutoClaim then
                for _, g in ipairs(HalloweenConfig.Goals) do
                    local tierIdx = (entry.Goals[g.Id] or 0) + 1
                    local tier = g.Tiers[tierIdx]
                    local stat = entry.Stats[g.Stat] or 0
                    if tier ~= nil and stat >= tier.Goal then
                        Fire("HalloweenGoalClaim", g.Id)
                        Humanizer.Wait(0.5, 1.0)
                    end
                end
            end
            
            if CFG.HalloweenAutoBuyBags and (entry.Candy or 0) >= 270 then
                Fire("SpookyBuy", "HalloweenBag10")
                Humanizer.Wait(1.0, 2.0)
            end
            
            if CFG.HalloweenAutoBuyLimitedPull and (entry.Candy or 0) >= 800 then
                Fire("SpookyBuy", "LimitedPull")
                Humanizer.Wait(1.0, 2.0)
            end
            
            if CFG.HalloweenAutoOpenBags then
                local bagCount = State.Data and State.Data.SeasonBags and State.Data.SeasonBags.Halloween or 0
                if bagCount > 0 then
                    Fire("OpenLootBag", "all", "Halloween")
                    Humanizer.Wait(1.5, 2.5)
                    Fire("ClaimLootPets", "Season")
                    Humanizer.Wait(1.0, 1.8)
                end
            end
            
            if CFG.HalloweenAutoTrickOrTreat and CanTrickOrTreat() then
                local npc, pivot = FindPawculaNPC()
                if pivot then
                    Movement.SafeTween(pivot)
                    Humanizer.Wait(0.8, 1.5)
                end
                Fire("TrickOrTreat")
                Humanizer.Wait(2.0, 3.0)
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
        
        local inTrade = IsInTrade()
        if not inTrade then
            if CFG.SenderMode and CFG.TradeTargetId then
                CircuitBreaker.Execute("TradeSender", function()
                    local targetPlayer = Players:GetPlayerByUserId(CFG.TradeTargetId)
                    if targetPlayer and targetPlayer.Parent == Players then
                        Fire("TradeRequest", CFG.TradeTargetId)
                        Humanizer.Wait(4.0, 6.0)
                    end
                end)
            end
        else
            -- กำลังอยู่ในเซสชันเทรด (In active trade session)
            -- 1. โหมดดรอปไอเทมอัตโนมัติ (Sender: Auto Drop Items)
            if CFG.AutoDropItems and not getgenv().TradeItemsDropped then
                Humanizer.Wait(1.2, 2.0)
                for _, item in ipairs(tradeItemList) do
                    if not IsInTrade() then break end
                    local realCount = GetRealItemCount(item)
                    if realCount > 0 then
                        Fire("TradeItem", item, realCount)
                        Humanizer.Wait(0.35, 0.65)
                    end
                end
                getgenv().TradeItemsDropped = true
                Humanizer.Wait(1.5, 2.5)
            end
            
            -- 2. โหมดกด Ready อัตโนมัติอย่างปลอดภัย (Safe Auto Ready)
            if CFG.AutoReady then
                local session = getgenv().CurrentTradeSession
                local you = session and session.You
                local them = session and session.Them
                
                -- ตรวจสอบว่าฝั่งเรายังไม่ได้กด Ready
                if you and not you.Ready then
                    -- สแกน LockedFor (คูลดาวน์ป้องกันของเกมหลังวางไอเทม ห้ามกดยืนยันทับ)
                    local lockedFor = you.LockedFor or 0
                    if lockedFor > 0 then
                        task.wait(lockedFor + 0.5)
                    end
                    
                    -- หากเป็นฝั่งรับ (Receiver) รอให้อีกฝ่ายใส่ของหรือกด Ready ก่อน
                    if CFG.ReceiverMode and them and not them.Ready then
                        Humanizer.Wait(1.5, 2.5)
                    end
                    
                    if IsInTrade() and not (getgenv().CurrentTradeSession and getgenv().CurrentTradeSession.You and getgenv().CurrentTradeSession.You.Ready) then
                        Fire("TradeReady", true)
                        Humanizer.Wait(2.0, 3.5)
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

-- 11. Auto Roll Pet Grade (Rank <= TargetRank Strictly Locked - High Speed Safe)
task.spawn(function()
    while true do
        task.wait(0.15)
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
                local rollDelay = math.clamp(CFG.RollSpeed or 0.25, 0.15, 1.0)
                local anyRolled = false
                
                for _, uid in ipairs(targetUids) do
                    if IsInTrade() or getgenv().TradeActiveSession then break end
                    if not data or not data.Gems or data.Gems < 1 then break end
                    
                    local pet = data.Pets[uid]
                    if pet then
                        if not IsPetGradeLocked(pet, targetRank) then
                            Fire("RollGrade", uid)
                            anyRolled = true
                            Humanizer.Wait(math.max(0.12, rollDelay - 0.04), rollDelay + 0.04)
                            data = State.Data
                        end
                    end
                end
                
                if not anyRolled then
                    task.wait(2.0)
                end
            end)
        else
            task.wait(1.5)
        end
    end
end)

-- 12. Auto Roll Pet Trait (Rank <= TargetRank Strictly Locked - High Speed Safe)
task.spawn(function()
    while true do
        task.wait(0.15)
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
                local rollDelay = math.clamp(CFG.RollSpeed or 0.25, 0.15, 1.0)
                local anyRolled = false
                
                for _, uid in ipairs(targetUids) do
                    if IsInTrade() or getgenv().TradeActiveSession then break end
                    if not data or not data.Shards or data.Shards < 1 then break end
                    
                    local pet = data.Pets[uid]
                    if pet then
                        if not IsPetTraitLocked(pet, targetRank) then
                            Fire("RollTrait", uid)
                            anyRolled = true
                            Humanizer.Wait(math.max(0.12, rollDelay - 0.04), rollDelay + 0.04)
                            data = State.Data
                        end
                    end
                end
                
                if not anyRolled then
                    task.wait(2.0)
                end
            end)
        else
            task.wait(1.5)
        end
    end
end)

-- 13. Auto Potions & Consumables
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
            if CFG.AutoOpenLootBags and (data.LootBags or 0) > 0 then
                Fire("OpenLootBag", "all")
                Humanizer.Wait(1.0, 2.0)
                Fire("ClaimLootPets", "Infinity")
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

Notify("🚀 สคริปต์พร้อมทำงาน", "Pet Dice Master Fluent Edition v4.5 โหลดสำเร็จ!", 4)
