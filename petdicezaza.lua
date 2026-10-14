-- ==============================================================================
-- 🎲 Pet Dice Pro Farm (Master Edition v4.0 - Auto Equip Best Pets & Safe System)
-- เพิ่มระบบสวมใส่สัตว์เลี้ยงที่ดีที่สุด (Equip Best Pets), จัดทีมหอคอย DPS สูงสุด,
-- ระบบข่ายนิรภัยตกแมพ (Anti-Void Guardian 100%), ล็อคแรงโน้มถ่วง และออกจากอารีน่าปลอดภัย
-- ==============================================================================

-- [1] CLIENT & GAME INITIALIZATION
if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local HS = game:GetService("HttpService")
local CG = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local VIM = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:WaitForChild("HumanoidRootPart")
    Humanoid = newChar:WaitForChild("Humanoid")
end)

-- Token ฆ่าลูปสคริปต์เวอร์ชันก่อนหน้าทันที 100%
getgenv().PetDiceScriptToken = (getgenv().PetDiceScriptToken or 0) + 1
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
-- [2] ANTI-DETECTION & HUMANIZER UTILITIES
-- ==============================================================================
local Humanizer = {}

function Humanizer.Wait(minSec, maxSec)
    local minMs = math.floor((minSec or 1.0) * 1000)
    local maxMs = math.floor((maxSec or 2.0) * 1000)
    local randomMs = math.random(minMs, maxMs) / 1000
    task.wait(randomMs)
end

function Humanizer.GetJitter(radius)
    local r = radius or 2.0
    local offsetX = (math.random() * 2 - 1) * r
    local offsetZ = (math.random() * 2 - 1) * r
    return Vector3.new(offsetX, 0, offsetZ)
end

LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

-- ==============================================================================
-- ==============================================================================
-- [3] SAFE TWEENING, ANTI-VOID & AUTO-NOCLIP ENGINE
-- ==============================================================================
local Movement = {}
local noclipConnection = nil

function Movement.SetNoclip(enabled)
    if enabled then
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
                if Character then
                    for _, part in ipairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        if Character and RootPart then
            RootPart.AssemblyLinearVelocity = Vector3.zero
            RootPart.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

function Movement.SafeTween(targetCFrame, speedParam)
    if not RootPart or not Character or not Humanoid or Humanoid.Health <= 0 then 
        return false 
    end

    local distance = (RootPart.Position - targetCFrame.Position).Magnitude
    if distance <= 12 then
        return true
    end

    local speed = speedParam or 240
    local duration = math.clamp(distance / speed, 0.2, 4.0)

    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    -- คำนวณพิกัดเป้าหมาย ป้องกันไม่ให้ต่ำกว่าพื้นหลัก (Floor Mat Standing Y = 5.65)
    local targetPos = targetCFrame.Position + Humanizer.GetJitter(1.0)
    if targetPos.Y < 5.65 then
        targetPos = Vector3.new(targetPos.X, 5.65, targetPos.Z)
    end
    local finalCFrame = CFrame.new(targetPos, targetPos + targetCFrame.LookVector)

    Movement.SetNoclip(true)

    -- ล็อคแรงโน้มถ่วงระหว่างบิน ป้องกันไม่ให้ตกทะลุพื้นเข้า Void ขณะที่ CanCollide = false
    local antiGrav = Instance.new("BodyVelocity")
    antiGrav.Name = "SafeTweenAntiGrav"
    antiGrav.MaxForce = Vector3.new(100000, 100000, 100000)
    antiGrav.Velocity = Vector3.zero
    antiGrav.Parent = RootPart

    local tween = TweenService:Create(RootPart, tweenInfo, {CFrame = finalCFrame})
    local completed = false
    local conn
    conn = tween.Completed:Connect(function()
        completed = true
        if conn then conn:Disconnect() end
    end)

    tween:Play()

    while not completed and (getgenv().PetDiceScriptToken == scriptToken) do
        if not RootPart or not Humanoid or Humanoid.Health <= 0 then
            tween:Cancel()
            break
        end
        task.wait(0.05)
    end

    if antiGrav and antiGrav.Parent then
        antiGrav:Destroy()
    end
    Movement.SetNoclip(false)
    if RootPart then
        RootPart.AssemblyLinearVelocity = Vector3.zero
        RootPart.AssemblyAngularVelocity = Vector3.zero
    end
    Humanizer.Wait(0.3, 0.6)
    return completed
end

local function GetStallCFrame(stallName)
    local stalls = workspace:FindFirstChild("Stalls")
    if stalls then
        local stall = stalls:FindFirstChild(stallName)
        if stall then
            local mat = stall:FindFirstChild("Mat")
            if mat then
                -- ยืนบนพรมหน้าซุ้มอย่างปลอดภัย (Mat Y = 2.65, Character Standing Y = 5.65) หันหน้าเข้าซุ้ม
                local standPos = mat.Position + Vector3.new(0, 3.0, 0)
                local stallCenter = stall:GetPivot().Position
                return CFrame.lookAt(standPos, Vector3.new(stallCenter.X, standPos.Y, stallCenter.Z))
            end
            local pivot = stall:GetPivot()
            return CFrame.lookAt(pivot.Position + Vector3.new(0, 3.5, 0), pivot.Position + pivot.LookVector * 10)
        end
    end
    -- พิกัดสำรองที่วัดจากหน้าพรม Mat จริงทุกจุดบนพลาซ่า
    local safeStallMats = {
        Towers    = CFrame.lookAt(Vector3.new(26.22, 5.65, -64.90), Vector3.new(35.21, 5.65, -87.15)),
        Rebirth   = CFrame.lookAt(Vector3.new(-64.90, 5.65, 26.22), Vector3.new(-87.15, 5.65, 35.21)),
        Quests    = CFrame.lookAt(Vector3.new(-64.90, 5.65, -26.22), Vector3.new(-87.15, 5.65, -35.21)),
        Upgrades  = CFrame.lookAt(Vector3.new(-26.22, 5.65, 64.90), Vector3.new(-35.21, 5.65, 87.15)),
        Treats    = CFrame.lookAt(Vector3.new(27.55, 5.65, 64.24), Vector3.new(36.73, 5.65, 86.42)),
        Grades    = CFrame.lookAt(Vector3.new(64.90, 5.65, -26.22), Vector3.new(87.15, 5.65, -35.21)),
        Ascension = CFrame.lookAt(Vector3.new(64.67, 5.65, 26.79), Vector3.new(86.84, 5.65, 35.97)),
        Traits    = CFrame.lookAt(Vector3.new(-26.22, 5.65, -64.90), Vector3.new(-35.21, 5.65, -87.15))
    }
    if safeStallMats[stallName] then
        return safeStallMats[stallName]
    end
    return CFrame.new(0, 5.65, 0)
end

-- ==============================================================================
-- [ANTI-VOID & MAP BOUNDARY GUARDIAN]
-- ป้องกันการตกแมพ วาปหลุดออกนอกโลก หรือโดนฟิสิกส์ดีดออกนอกเกาะ 100%
-- ==============================================================================
task.spawn(function()
    while true do
        task.wait(0.2)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        pcall(function()
            if RootPart and Character and Humanoid and Humanoid.Health > 0 then
                local pos = RootPart.Position
                -- ถ้าตำแหน่งต่ำกว่า Y=2.0 (ตกใต้แผ่นดิน) หรือหลุดออกจากเกาะพลาซ่า (|X|>130 หรือ |Z|>130)
                local isUnderMap = pos.Y < 2.0
                local isOutOfIsland = math.abs(pos.X) > 130 or math.abs(pos.Z) > 130
                local isInsaneVelocity = RootPart.AssemblyLinearVelocity.Magnitude > 300
                
                if isUnderMap or isOutOfIsland or isInsaneVelocity then
                    RootPart.AssemblyLinearVelocity = Vector3.zero
                    RootPart.AssemblyAngularVelocity = Vector3.zero
                    -- ดึงกลับมายืนบนพรมหน้าซุ้มหอคอยบนพื้นพลาซ่าทันที
                    RootPart.CFrame = CFrame.lookAt(Vector3.new(26.22, 5.65, -64.90), Vector3.new(35.21, 5.65, -87.15))
                end
            end
        end)
    end
end)

-- ==============================================================================
-- [4] FAILSAFE & CIRCUIT BREAKER ENGINE
-- ==============================================================================
local CircuitBreaker = {
    Errors = {}
}

function CircuitBreaker.Execute(featureName, taskFunc)
    if (CircuitBreaker.Errors[featureName] or 0) >= 6 then
        return false
    end

    local success, err = pcall(taskFunc)
    if not success then
        CircuitBreaker.Errors[featureName] = (CircuitBreaker.Errors[featureName] or 0) + 1
        warn(string.format("[CircuitBreaker] ข้อผิดพลาดใน '%s' (%d/6): %s", featureName, CircuitBreaker.Errors[featureName], tostring(err)))
        
        if CircuitBreaker.Errors[featureName] >= 6 then
            warn(string.format("[CircuitBreaker] ⚠️ ตัดการทำงานของระบบ '%s' ชั่วคราวเพื่อความปลอดภัย!", featureName))
            if getgenv().CFG and getgenv().CFG[featureName] ~= nil then
                getgenv().CFG[featureName] = false
            end
        end
        return false
    else
        CircuitBreaker.Errors[featureName] = 0
        return true
    end
end

-- ==============================================================================
-- [5] GAME HUD & TOWER / ARENA HELPERS
-- ==============================================================================
local function GetHud()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local petDiceUI = pg and pg:FindFirstChild("PetDiceUI")
    return petDiceUI and petDiceUI:FindFirstChild("Root") and petDiceUI.Root:FindFirstChild("Hud")
end

local function IsTowerRunning()
    local hud = GetHud()
    if hud then
        local tracker = hud:FindFirstChild("TowerTracker")
        if tracker and tracker.Visible then return true end
        local battle = hud:FindFirstChild("Battle")
        if battle and battle.Visible then return true end
    end
    return false
end

local function IsInBattleArena()
    local hud = GetHud()
    if hud then
        local battle = hud:FindFirstChild("Battle")
        if battle and battle.Visible then return true end
    end
    return false
end

local function SafeLeaveArena()
    pcall(function()
        if RootPart then
            RootPart.AssemblyLinearVelocity = Vector3.zero
            RootPart.AssemblyAngularVelocity = Vector3.zero
        end
        Fire("TowerExit")
        task.wait(0.4)
        if RootPart and Character and Humanoid and Humanoid.Health > 0 then
            local pos = RootPart.Position
            -- ตรวจสอบว่าตัวละครยังอยู่บนเกาะอย่างปลอดภัยหรือไม่ ถ้าตกแมพให้ดึงกลับมาบนพรมหน้าหอคอย
            if pos.Y < 3.0 or math.abs(pos.X) > 100 or math.abs(pos.Z) > 100 then
                RootPart.AssemblyLinearVelocity = Vector3.zero
                RootPart.AssemblyAngularVelocity = Vector3.zero
                RootPart.CFrame = CFrame.lookAt(Vector3.new(26.22, 5.65, -64.90), Vector3.new(35.21, 5.65, -87.15))
            else
                RootPart.AssemblyLinearVelocity = Vector3.zero
                RootPart.AssemblyAngularVelocity = Vector3.zero
            end
        end
        local camera = workspace.CurrentCamera
        if camera and Humanoid then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = Humanoid
        end
    end)
end

local function EquipBestPets()
    pcall(function()
        Fire("EquipBest")
        Humanizer.Wait(0.4, 0.8)
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({
                Title = "⭐ ใส่สัตว์เลี้ยงที่ดีที่สุด",
                Content = "สวมใส่สัตว์เลี้ยงที่ดีที่สุดในกระเป๋าเรียบร้อยแล้ว!",
                Duration = 3
            })
        end
    end)
    return true
end

local function GetEquippedTeam(towerId)
    local data = State.Data
    if not data then return {"1"} end
    local teamSize = 8
    pcall(function()
        teamSize = Towers.TeamSizeFor(data)
        local best = TeamPairs.Best(data, {Id = towerId or "Infinity"}, teamSize)
        if best and #best > 0 then
            return best
        end
    end)
    local team = {}
    if data.Equipped and #data.Equipped > 0 then
        for i = 1, math.min(teamSize, #data.Equipped) do
            table.insert(team, tostring(data.Equipped[i]))
        end
        return team
    end
    return {"1"}
end

-- ==============================================================================
-- [6] 🎲 DICE SYSTEM HELPERS (ระบบจัดการลูกเต๋า)
-- ==============================================================================
local function GetBestOwnedDie()
    local data = State.Data
    if not data or not data.OwnedDice then return nil end
    for i = #Config.Dice, 1, -1 do
        local d = Config.Dice[i]
        if data.OwnedDice[d.Id] then
            return d
        end
    end
    return nil
end

local function GetNextUnownedDie()
    local data = State.Data
    if not data or not data.OwnedDice then return nil end
    for _, d in ipairs(Config.Dice) do
        if not data.OwnedDice[d.Id] then
            return d
        end
    end
    return nil
end

local function BuyNextDie()
    local data = State.Data
    if not data or not data.Money then return false end
    local nextD = GetNextUnownedDie()
    if not nextD then return false end
    if data.Money < nextD.Cost then return false end
    
    Fire("Funnel", "Dice", 1, nextD.Id)
    Humanizer.Wait(0.3, 0.6)
    Fire("Funnel", "Dice", 2, nextD.Id)
    Humanizer.Wait(0.3, 0.6)
    Fire("BuyDice", nextD.Id)
    Humanizer.Wait(1.0, 1.8)
    Fire("EquipDice", nextD.Id)
    Humanizer.Wait(0.5, 1.0)
    return true
end

-- ==============================================================================
-- [7] 💾 CONFIGURATION MANAGER แยกโปรไฟล์รายไอดี
-- ==============================================================================
local myName = LocalPlayer.Name
local isMarker1c1 = myName:lower():find("1c1") ~= nil
local ConfigFile = "PetDice_Config_" .. myName .. ".json"

local function GetTopBestPets(count)
    local data = State.Data
    if not data or not data.Pets then return {} end
    local teamSize = math.clamp(count or 1, 1, 8)
    local candidates = {}
    
    for uid, pet in pairs(data.Pets) do
        local sUid = tostring(uid)
        local baseInc = 0
        local fullInc = 0
        pcall(function() baseInc = Stats.PetBaseIncome(pet) end)
        pcall(function() fullInc = Stats.PetIncome(pet) end)
        local rawBase = (PetData.ById[pet.Id] and PetData.ById[pet.Id].Income) or 0
        
        table.insert(candidates, {
            uid = sUid,
            pet = pet,
            baseIncome = baseInc,
            fullIncome = fullInc,
            rawBase = rawBase,
            lvl = pet.L or 0
        })
    end

    -- เรียงลำดับความเก่งจากรายได้พื้นฐาน (Base Income) สูงที่สุดเป็นอันดับ 1
    table.sort(candidates, function(a, b)
        if a.baseIncome ~= b.baseIncome then
            return a.baseIncome > b.baseIncome
        elseif a.fullIncome ~= b.fullIncome then
            return a.fullIncome > b.fullIncome
        elseif a.rawBase ~= b.rawBase then
            return a.rawBase > b.rawBase
        elseif a.lvl ~= b.lvl then
            return a.lvl > b.lvl
        else
            return (tonumber(a.uid) or 0) > (tonumber(b.uid) or 0)
        end
    end)

    local res = {}
    for i = 1, math.min(teamSize, #candidates) do
        table.insert(res, candidates[i].uid)
    end
    return res
end

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

local defaultCFG = {
    Tower = false, AutoPlay = false, AutoExitArena = true,
    AutoRebirth = false, AutoBuyDice = false, AutoEquipBest = true,
    Reward = false, Quest = false, Cutscene = false,
    UpgradeTree = false, UpgradeTreeDelay = 3,
    AutoExpedition = false, ExpeditionPetCount = 1,
    HalloweenAutoClaim = false,
    HalloweenAutoBuyBags = false,
    HalloweenAutoBuySingleBags = false,
    HalloweenAutoBuyLimitedPull = false,
    HalloweenAutoOpenBags = false,
    HalloweenAutoTrickOrTreat = false,
    AutoDropItems = false, AutoReady = true,
    SenderMode = not isMarker1c1, ReceiverMode = isMarker1c1, 
    TradeTarget = isMarker1c1 and "[ เลือกทุกคนในห้อง ]" or "marker1c1", 
    TradeTargetId = isMarker1c1 and nil or 11251813437,
    AutoUpgradePetLevel = false,
    AutoRollGrade = false,
    AutoRollTrait = false,
    EnhancePetCount = 4,
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
-- [8] 🎨 RAYFIELD UI & MOBILE TOGGLE
-- ==============================================================================
local hui = (gethui and gethui()) or CG
local robloxGui = CG:FindFirstChild("RobloxGui")

local function CleanOldGuis(container)
    if not container then return end
    for _, child in ipairs(container:GetChildren()) do
        if child.Name:find("Rayfield") then
            pcall(function() child:Destroy() end)
        end
    end
end

CleanOldGuis(hui)
CleanOldGuis(CG)
CleanOldGuis(robloxGui)
CleanOldGuis(LocalPlayer:FindFirstChild("PlayerGui"))

if CG:FindFirstChild("PetDiceMobileToggle") then 
    pcall(function() CG.PetDiceMobileToggle:Destroy() end) 
end

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "PetDiceMobileToggle"
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = CG

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.fromOffset(48, 48)
ToggleBtn.Position = UDim2.new(0, 15, 0.35, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
ToggleBtn.TextColor3 = Color3.fromRGB(80, 210, 255)
ToggleBtn.Text = "🎲"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 22
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
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local rayfieldGui = (pg and pg:FindFirstChild("Rayfield"))
                     or CG:FindFirstChild("Rayfield")
                     or (robloxGui and robloxGui:FindFirstChild("Rayfield"))
    if rayfieldGui and rayfieldGui:FindFirstChild("Main") then
        rayfieldGui.Main.Visible = not rayfieldGui.Main.Visible
    else
        VIM:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
    end
end)

-- บังคับให้ Rayfield เก็บ UI ไว้ที่ PlayerGui โดยตรง ไม่เข้า CoreGui/RobloxGui (แก้บั๊ก lacking capability Plugin 100%)
getgenv().gethui = function()
    return LocalPlayer:WaitForChild("PlayerGui")
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🎲 Pet Dice Pro Farm",
    LoadingTitle = "⚡ Pet Dice Pro Farm",
    LoadingSubtitle = "Master Edition v4.5 (Real-Time Pet Upgrade & Items Update)",
    Theme = "DarkBlue",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local TabTower      = Window:CreateTab("🏰 หอคอย & อารีน่า", 4483362458)
local TabDice       = Window:CreateTab("🎲 ลูกเต๋า (Dice)", 4483362458)
local TabRebirth    = Window:CreateTab("🌟 เกิดใหม่ (Rebirth)", 4483362458)
local TabEnhance    = Window:CreateTab("⭐ อัปเกรดสัตว์เลี้ยง", 4483362458)
local TabItems      = Window:CreateTab("🧪 ไอเทม & บัฟขวด", 4483362458)
local TabTree       = Window:CreateTab("🌳 ต้นไม้", 4483362458)
local TabExpedition = Window:CreateTab("🌙 ผจญภัยฝันร้าย", 4483362458)
local TabHalloween  = Window:CreateTab("🎃 อีเวนต์ฮาโลวีน", 4483362458)
local TabTrade      = Window:CreateTab("🤝 เทรดออโต้", 4483362458)
local TabReward     = Window:CreateTab("🎁 เควส & รางวัล", 4483362458)
local TabSet        = Window:CreateTab("⚙️ ตั้งค่า & บูสต์", 4483362458)

-- ==============================================================================
-- 🏰 แท็บ 1: หอคอย & ออกจากอารีน่า
-- ==============================================================================
TabTower:CreateSection("📊 สถานะหอคอยปัจจุบัน")

local LabelTowerStatus = TabTower:CreateLabel("กำลังตรวจสอบสถานะหอคอย...")

task.spawn(function()
    while task.wait(2.0) do
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        pcall(function()
            local hud = GetHud()
            local tracker = hud and hud:FindFirstChild("TowerTracker")
            local battle = hud and hud:FindFirstChild("Battle")
            if tracker and tracker.Visible then
                local floorText = "กำลังไต่หอคอย (Away Mode)"
                for _, d in ipairs(tracker:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text:find("FLOOR") then
                        floorText = d.Text
                        break
                    end
                end
                LabelTowerStatus:Set("⚔️ สถานะ: " .. floorText .. " (สัตว์เลี้ยงสู้อยู่เบื้องหลัง)")
            elseif battle and battle.Visible then
                LabelTowerStatus:Set("🥊 สถานะ: ตัวละครกำลังอยู่ในสนามประลอง (In Arena)")
            else
                LabelTowerStatus:Set("💤 สถานะ: หอคอยว่าง (พร้อมเริ่มรอบใหม่)")
            end
        end)
    end
end)

TabTower:CreateSection("⚡ สั่งการด่วน (Quick Actions)")

TabTower:CreateButton({
    Name = "⭐ สวมใส่สัตว์เลี้ยงที่ดีที่สุดทันที (EQUIP BEST PETS)",
    Callback = function()
        EquipBestPets()
    end
})

TabTower:CreateButton({
    Name = "🚪 ออกจากอารีน่าทันที (LEAVE ARENA - ปลอดภัย ไม่หลุดแมพ)",
    Callback = function()
        SafeLeaveArena()
        Rayfield:Notify({
            Title = "🚪 ออกจากอารีน่า",
            Content = "ออกจากอารีน่าสำเร็จ ยืนบนพรมหน้าหอคอยอย่างปลอดภัย 100%!",
            Duration = 3
        })
    end
})

TabTower:CreateButton({
    Name = "🛑 หยุดการลงหอคอยทั้งหมด (STOP TOWER RUN)",
    Callback = function()
        Fire("TowerLeave")
        Rayfield:Notify({
            Title = "🛑 หยุดการลงหอคอย",
            Content = "ยกเลิกการต่อสู้ในหอคอยทั้งหมดเรียบร้อย!",
            Duration = 3
        })
    end
})

TabTower:CreateButton({
    Name = "🏰 บินไปเริ่มลงหอคอย Infinity ทันที (Safe Tween)",
    Callback = function()
        task.spawn(function()
            if IsTowerRunning() then
                Rayfield:Notify({
                    Title = "⚠️ หอคอยกำลังทำงานอยู่",
                    Content = "สัตว์เลี้ยงกำลังต่อสู้อยู่ในหอคอยแล้ว ไม่จำเป็นต้องเริ่มใหม่",
                    Duration = 3
                })
                return
            end
            if CFG.AutoEquipBest then
                EquipBestPets()
            end
            local stallPivot = GetStallCFrame("Towers")
            if stallPivot then
                Movement.SafeTween(stallPivot)
                Humanizer.Wait(0.8, 1.4)
            end
            Fire("Funnel", "Towers", 1)
            Humanizer.Wait(0.4, 0.8)
            Fire("TowerStart", "Infinity", GetEquippedTeam("Infinity"))
        end)
    end
})

TabTower:CreateSection("🔄 ระบบหอคอยอัตโนมัติ (Safe Automation)")

TabTower:CreateToggle({
    Name = "1. ลงหอคอย Infinity อัตโนมัติ (บินหน้าซุ้มเมื่อหอว่างเท่านั้น)",
    CurrentValue = CFG.Tower,
    Flag = "TogTower",
    Callback = function(V) UpdateCFG("Tower", V) end
})

TabTower:CreateToggle({
    Name = "2. ออกจากอารีน่าอัตโนมัติเมื่อเข้าไปตี (Auto Leave Arena)",
    CurrentValue = CFG.AutoExitArena,
    Flag = "TogAutoExitArena",
    Callback = function(V) UpdateCFG("AutoExitArena", V) end
})

TabTower:CreateToggle({
    Name = "3. สวมใส่สัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (Auto Equip Best)",
    CurrentValue = CFG.AutoEquipBest,
    Flag = "TogAutoEquipBest",
    Callback = function(V) UpdateCFG("AutoEquipBest", V) end
})

-- ==============================================================================
-- 🎲 แท็บ 2: ซื้อและใส่ลูกเต๋าอัตโนมัติ (Dice Shop)
-- ==============================================================================
TabDice:CreateSection("📊 ข้อมูลลูกเต๋าปัจจุบัน")

local LabelDiceInfo = TabDice:CreateLabel("กำลังโหลดข้อมูลลูกเต๋า...")

local function UpdateDiceLabel()
    pcall(function()
        local data = State.Data
        if not data then return end
        local currentDieName = data.Dice or "Basic"
        local nextD = GetNextUnownedDie()
        local money = data.Money or 0
        if nextD then
            local canBuy = money >= nextD.Cost
            LabelDiceInfo:Set(string.format("ใส่อยู่: %s | ขั้นถัดไป: %s (%s) [%s]",
                currentDieName, nextD.Name, Format.Money(nextD.Cost), canBuy and "✅ เงินพอซื้อแล้ว" or "❌ ยังไม่พอ"
            ))
        else
            LabelDiceInfo:Set(string.format("ใส่อยู่: %s | คุณเป็นเจ้าของลูกเต๋าทุกชิ้นแล้ว! 👑", currentDieName))
        end
    end)
end

task.spawn(function()
    while task.wait(3.0) do
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        UpdateDiceLabel()
    end
end)

TabDice:CreateSection("⚡ สั่งการลูกเต๋า (Dice Actions)")

TabDice:CreateButton({
    Name = "🎲 ซื้อและใส่ลูกเต๋าขั้นถัดไปตอนนี้ (1 คลิก)",
    Callback = function()
        task.spawn(function()
            local nextD = GetNextUnownedDie()
            if not nextD then
                Rayfield:Notify({
                    Title = "👑 ลูกเต๋าครบแล้ว",
                    Content = "คุณเป็นเจ้าของลูกเต๋าทั้งหมดในเกมแล้ว!",
                    Duration = 3
                })
                return
            end
            local data = State.Data
            if (data.Money or 0) < nextD.Cost then
                Rayfield:Notify({
                    Title = "⚠️ เงินไม่พอซื้อลูกเต๋า",
                    Content = "ต้องการ " .. Format.Money(nextD.Cost) .. " (คุณมี " .. Format.Money(data.Money or 0) .. ")",
                    Duration = 3
                })
                return
            end
            local ok = BuyNextDie()
            if ok then
                Rayfield:Notify({
                    Title = "🎲 ซื้อลูกเต๋าสำเร็จ!",
                    Content = "ซื้อและสวมใส่ลูกเต๋า " .. nextD.Name .. " เรียบร้อยแล้ว!",
                    Duration = 3
                })
                UpdateDiceLabel()
            end
        end)
    end
})

TabDice:CreateButton({
    Name = "✨ สวมใส่ลูกเต๋าที่ดีที่สุดในตัวทันที (Equip Best)",
    Callback = function()
        local best = GetBestOwnedDie()
        if best then
            Fire("EquipDice", best.Id)
            Rayfield:Notify({
                Title = "✨ สวมใส่สำเร็จ",
                Content = "สวมใส่ลูกเต๋า " .. best.Name .. " เรียบร้อยแล้ว!",
                Duration = 3
            })
            UpdateDiceLabel()
        end
    end
})

TabDice:CreateSection("🔄 ระบบซื้อลูกเต๋าอัตโนมัติ")

TabDice:CreateToggle({
    Name = "เปิดระบบซื้อและใส่ลูกเต๋าที่ดีที่สุดอัตโนมัติ (Auto Buy Dice)",
    CurrentValue = CFG.AutoBuyDice,
    Flag = "TogAutoBuyDice",
    Callback = function(V) UpdateCFG("AutoBuyDice", V) end
})

-- ==============================================================================
-- 🌟 แท็บ 3: ระบบเกิดใหม่ (Rebirth System)
-- ==============================================================================
TabRebirth:CreateSection("📊 สถานะการเกิดใหม่ (Rebirth Status)")

local LabelRebirthInfo = TabRebirth:CreateLabel("กำลังโหลดข้อมูลการเกิดใหม่...")

local function UpdateRebirthLabel()
    pcall(function()
        local data = State.Data
        if not data then return end
        local cost = Stats.RebirthCost(data)
        local money = data.Money or 0
        local currentR = data.Rebirths or 0
        local canR = money >= cost
        LabelRebirthInfo:Set(string.format("เกิดใหม่: %d ครั้ง | เงิน: %s / %s (%s)",
            currentR, Format.Money(money), Format.Money(cost), canR and "✅ เงินครบแล้ว" or "❌ ยังไม่พอ"
        ))
    end)
end

task.spawn(function()
    while task.wait(3.0) do
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        UpdateRebirthLabel()
    end
end)

TabRebirth:CreateSection("⚡ สั่งการเกิดใหม่ (Rebirth Action)")

local function ExecuteRebirth()
    local data = State.Data
    if not data then return false end
    if IsInTrade() or getgenv().TradeActiveSession then return false end
    if IsInBattleArena() then return false end
    if not Character or not Humanoid or Humanoid.Health <= 0 or not RootPart then return false end
    
    local cost = Stats.RebirthCost(data)
    if (data.Money or 0) < cost then
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({
                Title = "⚠️ เงินไม่พอเกิดใหม่",
                Content = "ต้องการ " .. Format.Money(cost) .. " (คุณมี " .. Format.Money(data.Money or 0) .. ")",
                Duration = 3
            })
        end
        return false
    end
    
    local stallPivot = GetStallCFrame("Rebirth")
    if stallPivot then
        local moved = Movement.SafeTween(stallPivot)
        if not moved then return false end
        Humanizer.Wait(0.8, 1.4)
    end
    
    data = State.Data
    if not data or (data.Money or 0) < cost then return false end
    
    Fire("Funnel", "Rebirth", 1)
    Humanizer.Wait(0.3, 0.6)
    Fire("Funnel", "Rebirth", 2)
    Humanizer.Wait(0.3, 0.6)
    Fire("Rebirth")
    Humanizer.Wait(2.0, 3.0)
    
    if Rayfield and Rayfield.Notify then
        Rayfield:Notify({
            Title = "🌟 เกิดใหม่สำเร็จ!",
            Content = "คุณได้เลื่อนขั้น Rebirth เรียบร้อยแล้ว โบนัสเงินและดวงเพิ่มขึ้น!",
            Duration = 3
        })
    end
    UpdateRebirthLabel()
    return true
end

TabRebirth:CreateButton({
    Name = "🌟 บินไปเกิดใหม่ทันที (1 คลิก - ปลอดภัย)",
    Callback = function()
        task.spawn(function()
            ExecuteRebirth()
        end)
    end
})

TabRebirth:CreateToggle({
    Name = "เปิดระบบเกิดใหม่อัตโนมัติเมื่อเงินครบ (Auto Rebirth)",
    CurrentValue = CFG.AutoRebirth,
    Flag = "TogAutoRebirth",
    Callback = function(V) UpdateCFG("AutoRebirth", V) end
})

-- ==============================================================================
-- ⭐ แท็บ 4: อัปเกรด & บัฟสัตว์เลี้ยงที่ดีที่สุด (Real-Time Pet Enhancer)
-- ==============================================================================
TabEnhance:CreateSection("📊 ข้อมูลสัตว์เลี้ยงที่ดีที่สุดแบบเรียลไทม์")

local LabelBestPetSlots = {}
for i = 1, 8 do
    LabelBestPetSlots[i] = TabEnhance:CreateLabel(string.format("🐾 อันดับ #%d: กำลังโหลดข้อมูล...", i))
end

local function UpdateBestPetLabel()
    pcall(function()
        local data = State.Data
        if not data or not data.Pets then return end
        local count = CFG.EnhancePetCount or 4
        local uids = GetTopBestPets(count)
        local cap = Stats.PetLevelCap(data.Upgrades)
        
        for i = 1, 8 do
            if i <= count and uids[i] then
                local pet = data.Pets[uids[i]]
                if pet then
                    local grade = pet.G or "None"
                    local trait = pet.T or "None"
                    local lvl = pet.L or 0
                    local baseInc = 0
                    pcall(function() baseInc = Stats.PetBaseIncome(pet) end)
                    local baseStr = Format.Money(baseInc)
                    LabelBestPetSlots[i]:Set(string.format("⭐ #%d: %s | ฐาน: %s/s | LV %d/%d | เกรด: %s | บัฟ: %s", i, pet.Id, baseStr, lvl, cap, grade, trait))
                else
                    LabelBestPetSlots[i]:Set(string.format("💤 #%d: ไม่มีข้อมูลสัตว์เลี้ยง", i))
                end
            else
                LabelBestPetSlots[i]:Set(string.format("➖ #%d: ปิดการทำงาน (เลือกทำ %d ตัว)", i, count))
            end
        end
    end)
end

task.spawn(function()
    UpdateBestPetLabel()
    while true do
        task.wait(2.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        UpdateBestPetLabel()
    end
end)

TabEnhance:CreateSection("⚙️ ตั้งค่าจำนวนสัตว์เลี้ยงและเป้าหมาย")

TabEnhance:CreateSlider({
    Name = "จำนวนสัตว์เลี้ยงที่ดีที่สุดที่จะอัปเกรด (1 - 8 ตัว)",
    Range = {1, 8},
    Increment = 1,
    Suffix = "ตัว",
    CurrentValue = CFG.EnhancePetCount or 4,
    Flag = "SliderEnhancePetCount",
    Callback = function(V)
        UpdateCFG("EnhancePetCount", V)
        UpdateBestPetLabel()
    end
})

TabEnhance:CreateDropdown({
    Name = "🎯 เกรดเป้าหมายขั้นต่ำ (หยุดสุ่มเมื่อถึงเกรดนี้ขึ้นไป)",
    Options = GradeOptions,
    CurrentOption = {CFG.TargetGradeName or "S (Rank 8)"},
    MultipleOptions = false,
    Flag = "DropTargetGrade",
    Callback = function(O)
        local sel = O[1]
        UpdateCFG("TargetGradeName", sel)
        UpdateCFG("TargetGradeRank", GradeRankMap[sel] or 8)
    end
})

TabEnhance:CreateDropdown({
    Name = "🎯 คุณสมบัติเป้าหมายขั้นต่ำ (หยุดสุ่มเมื่อถึงขั้นนี้ขึ้นไป)",
    Options = TraitOptions,
    CurrentOption = {CFG.TargetTraitName or "VALIANT (Rank 6)"},
    MultipleOptions = false,
    Flag = "DropTargetTrait",
    Callback = function(O)
        local sel = O[1]
        UpdateCFG("TargetTraitName", sel)
        UpdateCFG("TargetTraitRank", TraitRankMap[sel] or 6)
    end
})

TabEnhance:CreateSection("⚡ สั่งการด่วน (1 คลิก - ปลอดภัย)")

TabEnhance:CreateButton({
    Name = "⭐ อัปเลเวลสัตว์เลี้ยงที่ดีที่สุดทั้งหมดทันที (1 คลิก)",
    Callback = function()
        task.spawn(function()
            local data = State.Data
            if not data or not data.Pets or not data.Money then return end
            local cap = Stats.PetLevelCap(data.Upgrades)
            local uids = GetTopBestPets(CFG.EnhancePetCount or 4)
            local upgraded = 0
            for _, uid in ipairs(uids) do
                local pet = data.Pets[uid]
                if pet and (pet.L or 0) < cap then
                    local cost = Stats.PetLevelCost(pet, data.Upgrades)
                    if cost and data.Money >= cost then
                        Fire("UpgradePet", uid)
                        upgraded = upgraded + 1
                        Humanizer.Wait(0.4, 0.7)
                        data = State.Data
                        if not data or not data.Money then break end
                    end
                end
            end
            Rayfield:Notify({
                Title = "⭐ อัปเลเวลสัตว์เลี้ยง",
                Content = upgraded > 0 and ("อัปเลเวลสัตว์เลี้ยงแล้ว " .. upgraded .. " ตัว!") or "เงินไม่พอหรือเลเวลตันแล้ว",
                Duration = 3
            })
            UpdateBestPetLabel()
        end)
    end
})

TabEnhance:CreateButton({
    Name = "💎 สุ่มเกรดสัตว์เลี้ยงที่ดีที่สุด 1 ครั้งต่อตัว",
    Callback = function()
        task.spawn(function()
            local data = State.Data
            if not data or not data.Pets or not data.Gems or data.Gems < 1 then
                Rayfield:Notify({
                    Title = "⚠️ เพชรไม่พอ (Gems)",
                    Content = "คุณมีเพชรไม่พอสำหรับการสุ่มเกรด",
                    Duration = 3
                })
                return
            end
            local uids = GetTopBestPets(CFG.EnhancePetCount or 4)
            local rolled = 0
            for _, uid in ipairs(uids) do
                if not data or not data.Gems or data.Gems < 1 then break end
                Fire("RollGrade", uid)
                rolled = rolled + 1
                Humanizer.Wait(0.6, 1.0)
                data = State.Data
            end
            Rayfield:Notify({
                Title = "💎 สุ่มเกรดสำเร็จ",
                Content = "สุ่มเกรดสัตว์เลี้ยงแล้ว " .. rolled .. " ตัว!",
                Duration = 3
            })
            UpdateBestPetLabel()
        end)
    end
})

TabEnhance:CreateButton({
    Name = "🔮 สุ่มคุณสมบัติ (Trait) สัตว์เลี้ยงที่ดีที่สุด 1 ครั้งต่อตัว",
    Callback = function()
        task.spawn(function()
            local data = State.Data
            if not data or not data.Pets or not data.Shards or data.Shards < 1 then
                Rayfield:Notify({
                    Title = "⚠️ เศษคริสตัลไม่พอ (Shards)",
                    Content = "คุณมี Shards ไม่พอสำหรับการสุ่มคุณสมบัติ",
                    Duration = 3
                })
                return
            end
            local uids = GetTopBestPets(CFG.EnhancePetCount or 4)
            local rolled = 0
            for _, uid in ipairs(uids) do
                if not data or not data.Shards or data.Shards < 1 then break end
                Fire("RollTrait", uid)
                rolled = rolled + 1
                Humanizer.Wait(0.6, 1.0)
                data = State.Data
            end
            Rayfield:Notify({
                Title = "🔮 สุ่มคุณสมบัติสำเร็จ",
                Content = "สุ่มคุณสมบัติสัตว์เลี้ยงแล้ว " .. rolled .. " ตัว!",
                Duration = 3
            })
            UpdateBestPetLabel()
        end)
    end
})

TabEnhance:CreateSection("🔄 ระบบอัปเกรดอัตโนมัติแบบเรียลไทม์")

TabEnhance:CreateToggle({
    Name = "1. อัปเลเวลสัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (อัปทันทีเมื่อเงินพอ)",
    CurrentValue = CFG.AutoUpgradePetLevel,
    Flag = "TogAutoPetLvl",
    Callback = function(V) UpdateCFG("AutoUpgradePetLevel", V) end
})

TabEnhance:CreateToggle({
    Name = "2. สุ่มเกรดสัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (หยุดเมื่อถึงเกรดเป้าหมาย)",
    CurrentValue = CFG.AutoRollGrade,
    Flag = "TogAutoPetGrade",
    Callback = function(V) UpdateCFG("AutoRollGrade", V) end
})

TabEnhance:CreateToggle({
    Name = "3. สุ่มคุณสมบัติสัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (หยุดเมื่อถึงขั้นเป้าหมาย)",
    CurrentValue = CFG.AutoRollTrait,
    Flag = "TogAutoPetTrait",
    Callback = function(V) UpdateCFG("AutoRollTrait", V) end
})

-- ==============================================================================
-- 🧪 แท็บ 5: การใช้งานไอเทม & บัฟขวดแบบเลือกได้ (Selectable Consumables)
-- ==============================================================================
TabItems:CreateSection("📊 สถานะน้ำยาและไอเทมแบบเรียลไทม์ (นับถอยหลังวินาที)")

local LabelLuckStatus  = TabItems:CreateLabel("🍀 โชคดี (Luck): กำลังโหลดข้อมูล...")
local LabelCashStatus  = TabItems:CreateLabel("💰 เงิน (Cash): กำลังโหลดข้อมูล...")
local LabelSpeedStatus = TabItems:CreateLabel("⚡ ความเร็ว (Speed): กำลังโหลดข้อมูล...")
local LabelBagsStatus  = TabItems:CreateLabel("🎒 กระเป๋าสมบัติ: กำลังโหลดข้อมูล...")

local function UpdatePotionLabel()
    pcall(function()
        local data = State.Data
        if not data then return end
        local now = State.Now and State.Now() or os.time()
        local potions = data.Potions or {}
        local ends = data.PotionEnds or {}
        
        local function GetTimeStr(endT)
            if not endT or endT <= now then 
                return "❌ หมดอายุแล้ว" 
            end
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
        
        local luckStr = string.format("🍀 น้ำยาโชคดี: มี %d ขวด | บัฟ: %s", luckCount, GetTimeStr(ends.Luck))
        local cashStr = string.format("💰 น้ำยาเงิน: มี %d ขวด | บัฟ: %s", cashCount, GetTimeStr(ends.Cash))
        local speedStr = string.format("⚡ น้ำยาความเร็ว: มี %d ขวด | บัฟ: %s", speedCount, GetTimeStr(ends.Speed))
        local bagsStr = string.format("🎒 ถุงสมบัติ: มี %d ใบ | 🎃 ถุงฮาโลวีน: มี %d ใบ", lootBags, halloweenBags)
        
        if LabelLuckStatus and LabelLuckStatus.Set then
            LabelLuckStatus:Set(luckStr)
        end
        if LabelCashStatus and LabelCashStatus.Set then
            LabelCashStatus:Set(cashStr)
        end
        if LabelSpeedStatus and LabelSpeedStatus.Set then
            LabelSpeedStatus:Set(speedStr)
        end
        if LabelBagsStatus and LabelBagsStatus.Set then
            LabelBagsStatus:Set(bagsStr)
        end
    end)
end

task.spawn(function()
    UpdatePotionLabel()
    while true do
        task.wait(1.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        UpdatePotionLabel()
    end
end)

TabItems:CreateSection("⚡ สั่งใช้งานไอเทมด่วน (1 คลิก)")

TabItems:CreateButton({
    Name = "🍀 ใช้น้ำยาโชคดีทันที (Potion Luck)",
    Callback = function()
        local data = State.Data
        if data and data.Potions and (data.Potions.Luck or 0) > 0 then
            Fire("UsePotion", "Luck")
            Rayfield:Notify({ Title = "🍀 ใช้น้ำยาโชคดี", Content = "เปิดใช้งานน้ำยาโชคดีเรียบร้อย (+50% Luck)!", Duration = 3 })
            UpdatePotionLabel()
        else
            Rayfield:Notify({ Title = "⚠️ ไม่มีน้ำยา", Content = "คุณไม่มีน้ำยาโชคดีเหลือในกระเป๋า", Duration = 3 })
        end
    end
})

TabItems:CreateButton({
    Name = "💰 ใช้น้ำยาเงินทันที (Potion Cash)",
    Callback = function()
        local data = State.Data
        if data and data.Potions and (data.Potions.Cash or 0) > 0 then
            Fire("UsePotion", "Cash")
            Rayfield:Notify({ Title = "💰 ใช้น้ำยาเงิน", Content = "เปิดใช้งานน้ำยาเงินเรียบร้อย (+50% Cash)!", Duration = 3 })
            UpdatePotionLabel()
        else
            Rayfield:Notify({ Title = "⚠️ ไม่มีน้ำยา", Content = "คุณไม่มีน้ำยาเงินเหลือในกระเป๋า", Duration = 3 })
        end
    end
})

TabItems:CreateButton({
    Name = "⚡ ใช้น้ำยาความเร็วทันที (Potion Speed)",
    Callback = function()
        local data = State.Data
        if data and data.Potions and (data.Potions.Speed or 0) > 0 then
            Fire("UsePotion", "Speed")
            Rayfield:Notify({ Title = "⚡ ใช้น้ำยาความเร็ว", Content = "เปิดใช้งานน้ำยาความเร็วเรียบร้อย (+25% Speed)!", Duration = 3 })
            UpdatePotionLabel()
        else
            Rayfield:Notify({ Title = "⚠️ ไม่มีน้ำยา", Content = "คุณไม่มีน้ำยาความเร็วเหลือในกระเป๋า", Duration = 3 })
        end
    end
})

TabItems:CreateButton({
    Name = "🎒 เปิดถุงสมบัติทั่วไปทั้งหมดทันที (Open Loot Bags)",
    Callback = function()
        local data = State.Data
        if data and (data.LootBags or 0) > 0 then
            Fire("OpenLootBag", "all")
            Humanizer.Wait(1.5, 2.5)
            Fire("LootBagDone")
            Rayfield:Notify({ Title = "🎒 เปิดถุงสมบัติ", Content = "เปิดถุงสมบัติทั้งหมดเรียบร้อย!", Duration = 3 })
            UpdatePotionLabel()
        else
            Rayfield:Notify({ Title = "⚠️ ไม่มีถุงสมบัติ", Content = "คุณไม่มีถุงสมบัติทั่วไปในกระเป๋า", Duration = 3 })
        end
    end
})

TabItems:CreateSection("🔄 ระบบใช้ไอเทมอัตโนมัติ (เมื่อบัพหมดและมีของในตัว)")

TabItems:CreateToggle({
    Name = "1. ดื่มน้ำยาโชคดีอัตโนมัติ (Auto Potion Luck)",
    CurrentValue = CFG.AutoUsePotionLuck,
    Flag = "TogAutoPotionLuck",
    Callback = function(V) UpdateCFG("AutoUsePotionLuck", V) end
})

TabItems:CreateToggle({
    Name = "2. ดื่มน้ำยาเงินอัตโนมัติ (Auto Potion Cash)",
    CurrentValue = CFG.AutoUsePotionCash,
    Flag = "TogAutoPotionCash",
    Callback = function(V) UpdateCFG("AutoUsePotionCash", V) end
})

TabItems:CreateToggle({
    Name = "3. ดื่มน้ำยาความเร็วอัตโนมัติ (Auto Potion Speed)",
    CurrentValue = CFG.AutoUsePotionSpeed,
    Flag = "TogAutoPotionSpeed",
    Callback = function(V) UpdateCFG("AutoUsePotionSpeed", V) end
})

TabItems:CreateToggle({
    Name = "4. เปิดถุงสมบัติทั่วไปอัตโนมัติ (Auto Open Loot Bags)",
    CurrentValue = CFG.AutoOpenLootBags,
    Flag = "TogAutoOpenLootBags",
    Callback = function(V) UpdateCFG("AutoOpenLootBags", V) end
})

-- ==============================================================================
-- 🌳 แท็บ 6: ซื้ออัปเกรดต้นไม้
-- ==============================================================================
TabTree:CreateSection("อัปเกรดต้นไม้ผลผลิต (Tree Upgrades)")

TabTree:CreateToggle({
    Name = "วนซื้ออัปเกรดต้นไม้ทั้งหมดอัตโนมัติ",
    CurrentValue = CFG.UpgradeTree,
    Flag = "TogTree",
    Callback = function(V) UpdateCFG("UpgradeTree", V) end
})

TabTree:CreateSlider({
    Name = "ระยะเวลาหน่วงในการวนซื้อ (วินาที)",
    Range = {2, 10},
    Increment = 1,
    Suffix = "วิ",
    CurrentValue = CFG.UpgradeTreeDelay or 3,
    Flag = "SliderTreeDelay",
    Callback = function(V) UpdateCFG("UpgradeTreeDelay", V) end
})

-- ==============================================================================
-- 🌙 แท็บ 5: ส่งสัตว์เลี้ยงไปผจญภัยระดับฝันร้าย (Nightmare)
-- ==============================================================================
TabExpedition:CreateSection("⚡ ผจญภัยระดับฝันร้าย")

local function GetNightmarePets(maxCount)
    local data = State.Data
    if not data or not data.Pets then return {} end
    
    local nightmare = ExpeditionConfig.ById and ExpeditionConfig.ById.Nightmare or ExpeditionConfig.Difficulties["5"]
    local req = nightmare and nightmare.Requirement or 1e14
    
    local equipped = {}
    for _, uid in ipairs(data.Equipped or {}) do
        equipped[tostring(uid)] = true
    end
    
    local onExp = {}
    for _, exp in ipairs(data.Expeditions and data.Expeditions.Active or {}) do
        for _, uid in ipairs(exp.Pets or {}) do
            onExp[tostring(uid)] = true
        end
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

TabExpedition:CreateButton({
    Name = "⚡ ส่งผจญภัยฝันร้ายทันที (1 ช่อง)",
    Callback = function()
        local pets = GetNightmarePets(CFG.ExpeditionPetCount or 1)
        if #pets > 0 then
            Fire("SendExpedition", "Nightmare", pets)
            Rayfield:Notify({
                Title = "🌙 ผจญภัยฝันร้าย",
                Content = "ส่งสัตว์เลี้ยง " .. #pets .. " ตัวเรียบร้อย!",
                Duration = 3
            })
        end
    end
})

TabExpedition:CreateButton({
    Name = "🎁 กดรับรางวัลผจญภัยที่สำเร็จทั้งหมด",
    Callback = function()
        local count = ClaimAllDoneExpeditions()
        Rayfield:Notify({
            Title = "🎁 รับรางวัลผจญภัย",
            Content = count > 0 and ("กดรับแล้ว " .. count .. " ช่อง!") or "ยังไม่มีช่องที่เสร็จสิ้น",
            Duration = 3
        })
    end
})

TabExpedition:CreateToggle({
    Name = "เปิดส่งสัตว์เลี้ยง + รับรางวัลอัตโนมัติ (Auto Nightmare)",
    CurrentValue = CFG.AutoExpedition,
    Flag = "TogAutoExpedition",
    Callback = function(V) UpdateCFG("AutoExpedition", V) end
})

TabExpedition:CreateSlider({
    Name = "จำนวนสัตว์เลี้ยงต่อ 1 ช่อง",
    Range = {1, 5},
    Increment = 1,
    Suffix = "ตัว",
    CurrentValue = CFG.ExpeditionPetCount or 1,
    Flag = "SliderExpPetCount",
    Callback = function(V) UpdateCFG("ExpeditionPetCount", V) end
})

-- ==============================================================================
-- 🎃 แท็บ 6: อีเวนต์ฮาโลวีน (Halloween Event - Humanized Verification)
-- ==============================================================================
local function GetHalloweenEntry()
    local seasonInfo = Season.Halloween()
    if not seasonInfo or not State.Data then return nil end
    return Season.Entry(State.Data, seasonInfo.Id), seasonInfo
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

TabHalloween:CreateSection("⚡ สั่งการด่วน (Safe Action)")

TabHalloween:CreateButton({
    Name = "🎁 กดรับรางวัลเป้าหมายทั้งหมด (1 คลิก)",
    Callback = function()
        local entry = GetHalloweenEntry()
        if not entry then return end
        for _, g in ipairs(HalloweenConfig.Goals) do
            local tierIdx = (entry.Goals[g.Id] or 0) + 1
            local tier = g.Tiers[tierIdx]
            local stat = entry.Stats[g.Stat] or 0
            if tier ~= nil and stat >= tier.Goal then
                Fire("HalloweenGoalClaim", g.Id)
                Humanizer.Wait(0.6, 1.2)
            end
        end
    end
})

TabHalloween:CreateButton({
    Name = "🛍️ ซื้อแพ็คกระเป๋า 10 ใบ (270 ลูกอม)",
    Callback = function()
        local entry = GetHalloweenEntry()
        if entry and (entry.Candy or 0) >= 270 then
            Fire("SpookyBuy", "HalloweenBag10")
        end
    end
})

TabHalloween:CreateButton({
    Name = "🍬 บินไปขอขนมฮาโลวีน (Trick or Treat With Safe Tween)",
    Callback = function()
        task.spawn(function()
            local npc, pivot = FindPawculaNPC()
            if pivot then
                Movement.SafeTween(pivot)
                Humanizer.Wait(0.8, 1.5)
            end
            Fire("TrickOrTreat")
        end)
    end
})

TabHalloween:CreateSection("🔄 ระบบอัตโนมัติ (Auto Halloween)")

TabHalloween:CreateToggle({
    Name = "1. รับรางวัลเป้าหมายอัตโนมัติ (Auto Claim Goals)",
    CurrentValue = CFG.HalloweenAutoClaim,
    Flag = "TogHalClaim",
    Callback = function(V) UpdateCFG("HalloweenAutoClaim", V) end
})

TabHalloween:CreateToggle({
    Name = "2. ซื้อแพ็ค 10 กระเป๋าอัตโนมัติ (270 ลูกอม)",
    CurrentValue = CFG.HalloweenAutoBuyBags,
    Flag = "TogHalBuyBags",
    Callback = function(V) UpdateCFG("HalloweenAutoBuyBags", V) end
})

TabHalloween:CreateToggle({
    Name = "3. เปิดกระเป๋าฮาโลวีนอัตโนมัติ (Auto Open Bags)",
    CurrentValue = CFG.HalloweenAutoOpenBags,
    Flag = "TogHalOpenBags",
    Callback = function(V) UpdateCFG("HalloweenAutoOpenBags", V) end
})

TabHalloween:CreateToggle({
    Name = "4. ซื้อตั๋ว Limited Pull อัตโนมัติ (800 ลูกอม)",
    CurrentValue = CFG.HalloweenAutoBuyLimitedPull,
    Flag = "TogHalLimitedPull",
    Callback = function(V) UpdateCFG("HalloweenAutoBuyLimitedPull", V) end
})

TabHalloween:CreateToggle({
    Name = "5. เดินไปขอขนมฟรีอัตโนมัติ (Auto Trick or Treat)",
    CurrentValue = CFG.HalloweenAutoTrickOrTreat,
    Flag = "TogHalTrick",
    Callback = function(V) UpdateCFG("HalloweenAutoTrickOrTreat", V) end
})

-- ==============================================================================
-- 🤝 แท็บ 7: ระบบเทรดออโต้ (Smart Item Detection - ป้องกันการแบน 100%)
-- ==============================================================================
TabTrade:CreateSection("🎯 เป้าหมายการเทรด")

local function GetPlayerNames() 
    local n = {"[ เลือกทุกคนในห้อง ]"} 
    for _, p in ipairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer then table.insert(n, p.Name) end 
    end 
    return n 
end

local DropdownTrade = TabTrade:CreateDropdown({
    Name = "เลือกผู้เล่นที่จะเทรดด้วย",
    Options = GetPlayerNames(),
    CurrentOption = {CFG.TradeTarget},
    MultipleOptions = false,
    Flag = "DropTrade",
    Callback = function(O) 
        local selection = O[1]
        UpdateCFG("TradeTarget", selection)
        if selection == "[ เลือกทุกคนในห้อง ]" then
            UpdateCFG("TradeTargetId", nil)
        else
            local t = Players:FindFirstChild(selection) 
            if t then UpdateCFG("TradeTargetId", t.UserId) end 
        end
    end
})

TabTrade:CreateButton({
    Name = "🔄 รีเฟรชรายชื่อผู้เล่น",
    Callback = function() DropdownTrade:Refresh(GetPlayerNames()) end
})

TabTrade:CreateSection("⚙️ การส่งไอเทมอัจฉริยะ (ส่งตามจำนวนจริงในกระเป๋า)")

local function GetRealItemCount(itemName)
    local data = State.Data
    if not data then return 0 end
    local itemCfg = Config.TradeItemByKey and Config.TradeItemByKey[itemName]
    if itemCfg and Stats and Stats.TradeItemCount then
        local count = Stats.TradeItemCount(data, itemCfg)
        if itemName == "SuperRolls" then
            count = count - (State.SuperQueued or 0)
        elseif itemName == "JackpotRolls" then
            count = count - (State.JackpotQueued or 0)
        end
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
for _, item in ipairs(Config.TradeItems or {}) do
    table.insert(tradeItemList, item.Key)
end
if #tradeItemList == 0 then
    tradeItemList = {
        "PotionLuck", "PotionCash", "PotionSpeed", "Gems", "Shards", 
        "SuperRolls", "JackpotRolls", "LootBags"
    }
end

TabTrade:CreateToggle({
    Name = "🎁 ส่งไอเทมทั้งหมดอัตโนมัติ (เช็คจำนวนจริง)",
    CurrentValue = CFG.AutoDropItems,
    Flag = "TogAutoDropItems",
    Callback = function(V) UpdateCFG("AutoDropItems", V) end
})

TabTrade:CreateToggle({
    Name = "✅ กดพร้อม (Ready) อัตโนมัติ",
    CurrentValue = CFG.AutoReady,
    Flag = "TogAutoReady",
    Callback = function(V) UpdateCFG("AutoReady", V) end
})

TabTrade:CreateToggle({
    Name = "🚀 โหมดไอดีหลัก (ส่งคำขอเทรด)",
    CurrentValue = CFG.SenderMode,
    Flag = "TogSender",
    Callback = function(V) UpdateCFG("SenderMode", V) end
})

TabTrade:CreateToggle({
    Name = "🛒 โหมดไอดีไก่ (รับคำขอเทรด)",
    CurrentValue = CFG.ReceiverMode,
    Flag = "TogReceiver",
    Callback = function(V) UpdateCFG("ReceiverMode", V) end
})

local function GetTradeWindow()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local root = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI:FindFirstChild("Root")
    local panels = root and root:FindFirstChild("Panels")
    local tp = panels and panels:FindFirstChild("TradingPanel")
    if tp and tp.Visible then
        return tp
    end
    return nil
end

local function IsInTrade()
    return getgenv().TradeActiveSession == true or GetTradeWindow() ~= nil
end

-- ==============================================================================
-- 🎁 แท็บ 8: เควส & รางวัล (Rewards & Quests - All Remotes Working)
-- ==============================================================================
TabReward:CreateSection("⚡ สั่งรับรางวัลทั้งหมดทันที (1 คลิก)")

local function ClaimAllRewardsManual()
    task.spawn(function()
        local qStall = GetStallCFrame("Quests")
        if qStall then
            Movement.SafeTween(qStall)
            Humanizer.Wait(0.6, 1.2)
        end
        
        Fire("Funnel", "Daily", 1)
        local data = State.Data
        local now = State.Now and State.Now() or os.time()
        local claimedCount = 0
        
        -- 1. Daily Reward (เช็คความพร้อมจริง)
        local canDaily = false
        pcall(function() canDaily = Stats.DailyState(data, now) end)
        if canDaily then
            Fire("Funnel", "Daily", 1)
            Fire("ClaimDaily")
            claimedCount = claimedCount + 1
            Humanizer.Wait(0.4, 0.8)
        end
        
        -- 2. Playtime Rewards (เช็คว่ามีกล่องพร้อมรับจริง)
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
        
        -- 3. Social Rewards (เช็คว่ายังไม่ได้รับ)
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
        
        -- 4. Daily & Weekly Quests & Goals (เช็ค Progress >= Goal และยังไม่ได้รับจริง)
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
        
        if claimedCount > 0 then
            Rayfield:Notify({
                Title = "🎁 รับรางวัลสำเร็จ",
                Content = "รับรางวัลที่พร้อมแล้วจำนวน " .. claimedCount .. " รายการเรียบร้อย!",
                Duration = 3
            })
        else
            Rayfield:Notify({
                Title = "ℹ️ ยังไม่มีรางวัลที่พร้อมรับ",
                Content = "รางวัลทั้งหมดถูกรับไปแล้ว หรือยังทำเควสไม่สำเร็จ (ป้องกัน NOT DONE YET!)",
                Duration = 3
            })
        end
    end)
end

TabReward:CreateButton({
    Name = "🎁 กดรับรางวัลและเควสทั้งหมดตอนนี้ (1 คลิก)",
    Callback = function()
        ClaimAllRewardsManual()
    end
})

TabReward:CreateSection("🔄 ระบบรับรางวัลอัตโนมัติ (Auto Claim)")

TabReward:CreateToggle({
    Name = "1. รับรางวัลรายวัน + ออนไลน์ (Daily + Playtime)",
    CurrentValue = CFG.Reward,
    Flag = "TogReward",
    Callback = function(V) UpdateCFG("Reward", V) end
})

TabReward:CreateToggle({
    Name = "2. รับรางวัลเควสทั้งหมด (Daily + Weekly Quests + Goals)",
    CurrentValue = CFG.Quest,
    Flag = "TogQuest",
    Callback = function(V) UpdateCFG("Quest", V) end
})

-- ==============================================================================
-- ⚙️ แท็บ 9: ตั้งค่า & บูสต์ FPS
-- ==============================================================================
TabSet:CreateSection("🚀 บูสต์ FPS & ลดภาระเครื่อง")

TabSet:CreateButton({
    Name = "🚀 เปิดโหมดภาพกากขั้นสุด (ลบเอฟเฟค & ปิดเงา)",
    Callback = function()
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 0
            
            for _, v in pairs(Lighting:GetChildren()) do 
                if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then 
                    v:Destroy() 
                end 
            end
            
            workspace.Terrain.WaterWaveSize = 0
            workspace.Terrain.Decoration = false
            
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then 
                    v.Material = Enum.Material.SmoothPlastic 
                    v.Reflectance = 0 
                    v.CastShadow = false
                end
            end
        end)
    end
})

-- ==============================================================================
-- ⚙️ WORKER LOOPS (ควบคุมผ่าน CircuitBreaker & Safe Tween)
-- ==============================================================================

-- 1. วนหอคอย Infinity (จะทวีนไปเริ่มรอบใหม่ เมื่อหอคอยว่างลงแล้วเท่านั้น!)
task.spawn(function()
    while true do
        task.wait(4.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.Tower then
            local data = State.Data
            -- เช็คความพร้อมของข้อมูลและตัวละคร
            if not data or not Character or not Humanoid or Humanoid.Health <= 0 or not RootPart then
                task.wait(2.0)
                continue
            end
            
            -- ถ้าหอคอยกำลังทำงานอยู่แล้ว ให้รอจนกว่าจะจบ
            if IsTowerRunning() then
                task.wait(3.0)
                continue
            end
            
            CircuitBreaker.Execute("Tower", function()
                if CFG.AutoEquipBest then
                    Fire("EquipBest")
                    Humanizer.Wait(0.4, 0.8)
                end
                
                local stallPivot = GetStallCFrame("Towers")
                if not stallPivot then return end
                
                local moved = Movement.SafeTween(stallPivot)
                if not moved then return end
                Humanizer.Wait(0.8, 1.4)
                
                local team = GetEquippedTeam("Infinity")
                if not team or #team == 0 then return end
                
                Fire("Funnel", "Towers", 1)
                Humanizer.Wait(0.5, 1.0)
                Fire("TowerStart", "Infinity", team)
                
                -- ตรวจสอบก่อนออกจากอารีน่า: ต้องรอให้ตัวละครถูกส่งเข้าสู่สนามประลองจริงก่อน จึงจะกดออก
                if CFG.AutoExitArena then
                    local enteredArena = false
                    for _ = 1, 10 do
                        task.wait(0.5)
                        if IsInBattleArena() then
                            enteredArena = true
                            break
                        end
                    end
                    if enteredArena then
                        Humanizer.Wait(1.2, 2.0)
                        SafeLeaveArena()
                        Humanizer.Wait(1.0, 1.8)
                    end
                end
            end)
        end
    end
end)

-- 2. ออกจากอารีน่าอัตโนมัติเมื่อเข้าไปในฉากต่อสู้ (Auto Leave Arena)
task.spawn(function()
    while true do
        task.wait(2.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if CFG.AutoExitArena then
            pcall(function()
                -- ต้องยืนยันว่าอยู่ในฉากสนามประลองจริง และตัวละครยังมีชีวิต
                if IsInBattleArena() and Character and Humanoid and Humanoid.Health > 0 and RootPart then
                    Humanizer.Wait(1.5, 2.5)
                    SafeLeaveArena()
                    Humanizer.Wait(2.0, 3.0)
                end
            end)
        end
    end
end)

-- 2.1 วนใส่สัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (Auto Equip Best Pets Loop - เช็คเมื่อจำนวนสัตว์เลี้ยงเปลี่ยน)
task.spawn(function()
    local lastPetCount = -1
    while true do
        task.wait(8.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoEquipBest then
            CircuitBreaker.Execute("AutoEquipBest", function()
                local data = State.Data
                if data and data.Pets then
                    local count = 0
                    for _ in pairs(data.Pets) do count = count + 1 end
                    if count > 0 and count ~= lastPetCount then
                        Fire("EquipBest")
                        lastPetCount = count
                    end
                end
            end)
        end
    end
end)

-- 3. วนซื้อและใส่ลูกเต๋าที่ดีที่สุดอัตโนมัติ (Auto Buy & Equip Dice)
task.spawn(function()
    while true do
        task.wait(5.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoBuyDice then
            CircuitBreaker.Execute("AutoBuyDice", function()
                local data = State.Data
                if data and data.OwnedDice and data.Money then
                    local nextD = GetNextUnownedDie()
                    -- ต้องพร้อมทั้ง: มีลูกเต๋าขั้นถัดไปให้ซื้อ และ เงินในตัวมีเพียงพอจริง
                    if nextD and (data.Money or 0) >= nextD.Cost then
                        local ok = BuyNextDie()
                        if ok and Rayfield and Rayfield.Notify then
                            Rayfield:Notify({
                                Title = "🎲 ซื้อลูกเต๋าสำเร็จ!",
                                Content = "ซื้อและสวมใส่ลูกเต๋า " .. nextD.Name .. " เรียบร้อยแล้ว!",
                                Duration = 3
                            })
                        end
                    end
                end
            end)
        end
    end
end)

-- 4. วนเกิดใหม่อัตโนมัติเมื่อเงินครบ (Auto Rebirth)
task.spawn(function()
    while true do
        task.wait(5.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoRebirth then
            CircuitBreaker.Execute("AutoRebirth", function()
                local data = State.Data
                if data and data.Money and not IsInBattleArena() then
                    local cost = Stats.RebirthCost(data)
                    if (data.Money or 0) >= cost then
                        ExecuteRebirth()
                    end
                end
            end)
        end
    end
end)

-- 5. วนรับของรางวัลและเควสทั้งหมด (Auto Claim Rewards & Quests - Safe Readiness Verification)
task.spawn(function()
    while true do
        task.wait(12.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        local data = State.Data
        local now = State.Now and State.Now() or os.time()
        
        if CFG.Reward and data then
            CircuitBreaker.Execute("Reward", function()
                -- 1. เคลม Daily เฉพาะเมื่อระบบยืนยันว่าพร้อมรับจริง
                local canDaily = false
                pcall(function() canDaily = Stats.DailyState(data, now) end)
                if canDaily then
                    Fire("Funnel", "Daily", 1)
                    Fire("ClaimDaily")
                    Humanizer.Wait(0.4, 0.8)
                end
                
                -- 2. เคลม Playtime เฉพาะเมื่อมีเป้าหมายที่ครบเวลาและยังไม่ได้รับ
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
                    Humanizer.Wait(0.4, 0.8)
                end
                
                -- 3. เคลม Social เฉพาะที่ยังไม่ได้รับ
                if data.Social then
                    if not data.Social.Group then
                        Fire("ClaimSocial", "Group")
                        Humanizer.Wait(0.3, 0.6)
                    end
                    if not data.Social.Like then
                        Fire("ClaimSocial", "Like")
                        Humanizer.Wait(0.3, 0.6)
                    end
                end
            end)
        end
        
        if CFG.Quest and data and data.Quests then
            CircuitBreaker.Execute("Quest", function()
                local hasClaimable = false
                
                -- Daily Quests (เช็ค Progress >= Goal และยังไม่ได้รับ)
                for i, q in ipairs(data.Quests.Daily or {}) do
                    if not q.Claimed and (q.Progress or 0) >= (q.Goal or math.huge) then
                        hasClaimable = true
                        Fire("QuestClaim", "Daily", i)
                        Humanizer.Wait(0.3, 0.6)
                    end
                end
                
                -- Weekly Quests (เช็ค Progress >= Goal และยังไม่ได้รับ)
                for i, q in ipairs(data.Quests.Weekly or {}) do
                    if not q.Claimed and (q.Progress or 0) >= (q.Goal or math.huge) then
                        hasClaimable = true
                        Fire("QuestClaim", "Weekly", i)
                        Humanizer.Wait(0.3, 0.6)
                    end
                end
                
                -- Goals (เช็ค Progress >= Goal จาก QuestsLogic.Goals)
                if QuestsLogic and QuestsLogic.Goals and data.Quests.Goals then
                    for _, gDef in ipairs(QuestsLogic.Goals) do
                        local gData = data.Quests.Goals[gDef.Id]
                        if gData and not gData.Claimed and (gData.Progress or 0) >= (gDef.Goal or math.huge) then
                            hasClaimable = true
                            Fire("GoalClaim", gDef.Id)
                            Humanizer.Wait(0.3, 0.6)
                        end
                    end
                end
                
                if hasClaimable then
                    Fire("Funnel", "Quests", 1)
                end
            end)
        end
    end
end)

-- 6. อัปเกรดต้นไม้ (Tree Upgrade - เช็คแผนการซื้อก่อนยิงรีโมทจริง)
task.spawn(function()
    while true do
        local delayTime = CFG.UpgradeTreeDelay or 3
        task.wait(delayTime)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(1.5) continue end
        
        if CFG.UpgradeTree then
            CircuitBreaker.Execute("UpgradeTree", function()
                local data = State.Data
                if data and data.Upgrades and data.Money and Upgrades and Upgrades.PlanBuyAll then
                    local plan = nil
                    pcall(function()
                        plan = Upgrades.PlanBuyAll(data.Upgrades, data.Money)
                    end)
                    if plan and #plan > 0 then
                        Fire("BuyAllUpgrades")
                    end
                end
            end)
        end
    end
end)

-- 7. ผจญภัยระดับฝันร้าย (Nightmare Expeditions)
task.spawn(function()
    while true do
        task.wait(6.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(1.5) continue end
        
        if CFG.AutoExpedition then
            CircuitBreaker.Execute("AutoExpedition", function()
                ClaimAllDoneExpeditions()
                Humanizer.Wait(1.0, 1.5)
                
                local data = State.Data
                local active = data and data.Expeditions and data.Expeditions.Active or {}
                local maxSlots = Expeditions.Slots(data)
                
                if #active < maxSlots then
                    local pets = GetNightmarePets(CFG.ExpeditionPetCount or 1)
                    if #pets > 0 then
                        Fire("SendExpedition", "Nightmare", pets)
                        Humanizer.Wait(1.2, 2.0)
                    end
                end
            end)
        end
    end
end)

-- 8. อีเวนต์ฮาโลวีน (Halloween Event With Safe Intervals)
task.spawn(function()
    while true do
        task.wait(5.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(1.5) continue end
        
        CircuitBreaker.Execute("Halloween", function()
            local entry = GetHalloweenEntry()
            if not entry then return end
            
            if CFG.HalloweenAutoClaim then
                for _, g in ipairs(HalloweenConfig.Goals) do
                    local tierIdx = (entry.Goals[g.Id] or 0) + 1
                    local tier = g.Tiers[tierIdx]
                    local stat = entry.Stats[g.Stat] or 0
                    if tier ~= nil and stat >= tier.Goal then
                        Fire("HalloweenGoalClaim", g.Id)
                        Humanizer.Wait(0.8, 1.5)
                    end
                end
            end
            
            local candy = entry.Candy or 0
            if CFG.HalloweenAutoBuyBags and candy >= 270 then
                Fire("SpookyBuy", "HalloweenBag10")
                Humanizer.Wait(1.5, 2.5)
            end
            
            if CFG.HalloweenAutoOpenBags then
                local data = State.Data
                local bags = data and data.SeasonBags and data.SeasonBags.Halloween or 0
                if bags > 0 then
                    Fire("OpenLootBag", "all", "Halloween")
                    Humanizer.Wait(2.0, 3.0)
                    Fire("LootBagDone")
                    Humanizer.Wait(1.0, 1.5)
                end
            end
            
            if CFG.HalloweenAutoTrickOrTreat then
                local canTreat = false
                pcall(function()
                    local seasonInfo = Season.Halloween()
                    if seasonInfo and State.Data then
                        local entry = Season.Entry(State.Data, seasonInfo.Id)
                        local treatDay = entry and entry.TreatDay or 0
                        local now = State.Now and State.Now() or os.time()
                        local curDay = Season.TreatDay and Season.TreatDay(now) or 0
                        if treatDay < curDay then
                            canTreat = true
                        end
                    end
                end)
                
                if canTreat then
                    local npc, pivot = FindPawculaNPC()
                    if pivot then
                        Movement.SafeTween(pivot)
                        Humanizer.Wait(1.0, 1.8)
                    end
                    Fire("TrickOrTreat")
                    Humanizer.Wait(2.0, 3.0)
                end
            end
        end)
    end
end)

-- ดักฟังเหตุการณ์การเทรดโดยตรงจากเซิร์ฟเวอร์ (Server-authoritative Trade Event Listener)
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
                if Rayfield and Rayfield.Notify then
                    Rayfield:Notify({
                        Title = "🤝 ยอมรับคำขอเทรด",
                        Content = "ตอบรับคำขอเทรดจาก " .. senderName .. " เรียบร้อย!",
                        Duration = 3
                    })
                end
            end)
        end
    elseif event == "Open" or event == "Update" then
        getgenv().TradeActiveSession = true
    elseif event == "Closed" then
        task.spawn(function()
            Humanizer.Wait(3.0, 5.0)
            getgenv().TradeActiveSession = false
        end)
    end
end)

-- 9. ระบบเทรดอัจฉริยะ (Human-like Trade Runner)
task.spawn(function()
    while true do
        task.wait(1.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        
        local win = GetTradeWindow()
        if not win and not getgenv().TradeActiveSession then
            if CFG.SenderMode then
                CircuitBreaker.Execute("TradeSender", function()
                    if CFG.TradeTargetId then
                        local targetPlayer = Players:GetPlayerByUserId(CFG.TradeTargetId)
                        if targetPlayer and targetPlayer.Parent == Players then
                            Fire("TradeRequest", CFG.TradeTargetId)
                            Humanizer.Wait(3.0, 5.0)
                        end
                    end
                end)
            end
        else
            if not getgenv().TradeActiveSession then
                getgenv().TradeActiveSession = true
                
                task.spawn(function()
                    local dropped = false
                    while IsInTrade() do
                        if getgenv().PetDiceScriptToken ~= scriptToken then break end
                        
                        if CFG.AutoDropItems and not dropped then
                            Humanizer.Wait(1.5, 2.5)
                            for _, item in ipairs(tradeItemList) do
                                if not IsInTrade() then break end
                                local realCount = GetRealItemCount(item)
                                if realCount > 0 then
                                    Fire("TradeItem", item, realCount)
                                    Humanizer.Wait(0.4, 0.7)
                                end
                            end
                            dropped = true
                            Humanizer.Wait(1.0, 2.0)
                            continue
                        end
                        
                        if CFG.ReceiverMode then
                            Humanizer.Wait(1.2, 2.0)
                        end
                        
                        if CFG.AutoReady then
                            Humanizer.Wait(0.8, 1.5)
                            Fire("TradeReady", true)
                            Humanizer.Wait(3.0, 4.0)
                        end
                        
                        task.wait(1.0)
                    end
                    
                    Humanizer.Wait(3.0, 5.0)
                    getgenv().TradeActiveSession = false
                end)
            end
        end
    end
end)

-- 10. วนอัปเลเวลสัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (Auto Upgrade Pet Levels - Real-Time)
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
                local targetUids = GetTopBestPets(CFG.EnhancePetCount or 4)
                
                for _, uid in ipairs(targetUids) do
                    if IsInTrade() or getgenv().TradeActiveSession then break end
                    local pet = data.Pets[uid]
                    if pet and (pet.L or 0) < cap then
                        local cost = Stats.PetLevelCost(pet, data.Upgrades)
                        if cost and data.Money >= cost then
                            Fire("UpgradePet", uid)
                            Humanizer.Wait(0.35, 0.65)
                            data = State.Data
                            if not data or not data.Money then break end
                        end
                    end
                end
            end)
        end
    end
end)

-- 11. วนสุ่มเกรดสัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (Auto Roll Pet Grade - Real-Time)
task.spawn(function()
    while true do
        task.wait(3.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoRollGrade then
            CircuitBreaker.Execute("AutoRollGrade", function()
                local data = State.Data
                if not data or not data.Pets or not data.Gems or data.Gems < 1 then return end
                local targetRank = CFG.TargetGradeRank or 8
                local targetUids = GetTopBestPets(CFG.EnhancePetCount or 4)
                
                for _, uid in ipairs(targetUids) do
                    if IsInTrade() or getgenv().TradeActiveSession then break end
                    if not data or not data.Gems or data.Gems < 1 then break end
                    
                    local pet = data.Pets[uid]
                    if pet then
                        local currentRank = Modifiers.GradeRank(pet)
                        if currentRank > targetRank then
                            Fire("RollGrade", uid)
                            Humanizer.Wait(0.6, 1.1)
                            data = State.Data
                        end
                    end
                end
            end)
        end
    end
end)

-- 12. วนสุ่มคุณสมบัติสัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (Auto Roll Pet Trait - Real-Time)
task.spawn(function()
    while true do
        task.wait(3.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoRollTrait then
            CircuitBreaker.Execute("AutoRollTrait", function()
                local data = State.Data
                if not data or not data.Pets or not data.Shards or data.Shards < 1 then return end
                local targetRank = CFG.TargetTraitRank or 6
                local targetUids = GetTopBestPets(CFG.EnhancePetCount or 4)
                
                for _, uid in ipairs(targetUids) do
                    if IsInTrade() or getgenv().TradeActiveSession then break end
                    if not data or not data.Shards or data.Shards < 1 then break end
                    
                    local pet = data.Pets[uid]
                    if pet then
                        local currentRank = Modifiers.TraitRank(pet)
                        if currentRank > targetRank then
                            Fire("RollTrait", uid)
                            Humanizer.Wait(0.6, 1.1)
                            data = State.Data
                        end
                    end
                end
            end)
        end
    end
end)

-- 13. วนใช้งานน้ำยาและไอเทมกดใช้อัตโนมัติ (Auto Use Potions & Consumables - Safe & Real-Time)
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
            local usedAny = false
            
            -- 1. Potion Luck
            if CFG.AutoUsePotionLuck and (potions.Luck or 0) > 0 then
                if (ends.Luck or 0) <= now then
                    Fire("UsePotion", "Luck")
                    usedAny = true
                    Humanizer.Wait(0.6, 1.0)
                    data = State.Data
                    ends = data and data.PotionEnds or {}
                end
            end
            
            -- 2. Potion Cash
            if CFG.AutoUsePotionCash and (potions.Cash or 0) > 0 then
                if (ends.Cash or 0) <= now then
                    Fire("UsePotion", "Cash")
                    usedAny = true
                    Humanizer.Wait(0.6, 1.0)
                    data = State.Data
                    ends = data and data.PotionEnds or {}
                end
            end
            
            -- 3. Potion Speed
            if CFG.AutoUsePotionSpeed and (potions.Speed or 0) > 0 then
                if (ends.Speed or 0) <= now then
                    Fire("UsePotion", "Speed")
                    usedAny = true
                    Humanizer.Wait(0.6, 1.0)
                    data = State.Data
                end
            end
            
            -- 4. Open Loot Bags
            if CFG.AutoOpenLootBags and (data and data.LootBags or 0) > 0 then
                Fire("OpenLootBag", "all")
                Humanizer.Wait(2.0, 3.0)
                Fire("LootBagDone")
                usedAny = true
                Humanizer.Wait(1.0, 1.5)
            end
            
            if usedAny and UpdatePotionLabel then
                UpdatePotionLabel()
            end
        end)
    end
end)

print("✅ [Pet Dice Pro Farm v4.5] ติดตั้งระบบอัปเกรดสัตว์เลี้ยงและไอเทมเรียบร้อยแล้ว!")
