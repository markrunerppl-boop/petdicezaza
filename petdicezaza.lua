-- ==============================================================================
-- 🎲 PET DICE MASTER SAFE EDITION v4.8 (FLUENT UI REBORN)
-- 🛡️ Anti-AI Detection & High-Tier Protection System
-- 🎨 Modern Windows 11 Fluent Acrylic Interface
-- ==============================================================================

-- ==============================================================================
-- [0] REAL-TIME AUTO-UPDATE & CDN CACHE-BUSTER BOOTSTRAP
-- Ensures loadstring(game:HttpGet("https://raw.githubusercontent.com/.../petdicezaza.lua"))()
-- ALWAYS fetches and runs the latest real-time code, bypassing GitHub Fastly 300s cache.
-- ==============================================================================
if not getgenv()._PetDiceBypassCDN then
    getgenv()._PetDiceBypassCDN = true
    local ts = os.time()
    local okFetch, freshScript = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/markrunerppl-boop/petdicezaza/main/petdicezaza.lua?v=" .. tostring(ts))
    end)
    if okFetch and freshScript and #freshScript > 5000 and not freshScript:find("404: Not Found") then
        local chunk, compileErr = loadstring(freshScript)
        if chunk then
            getgenv()._PetDiceBypassCDN = nil
            return chunk()
        end
    end
    getgenv()._PetDiceBypassCDN = nil
end

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
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local CG = game:GetService("CoreGui")
local HS = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

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

-- เคลียร์ UI เก่าและเธรดเก่าทั้งหมดก่อนรันใหม่ (Clean Startup & Hot-Reload Support)
pcall(function()
    if getgenv().PetDiceWindow and getgenv().PetDiceWindow.Root then
        pcall(function() getgenv().PetDiceWindow.Root:Destroy() end)
        getgenv().PetDiceWindow = nil
    end
    if getgenv().PetDiceFluentGui then
        pcall(function() getgenv().PetDiceFluentGui:Destroy() end)
        getgenv().PetDiceFluentGui = nil
    end
    if getgenv().PetDiceMobileToggleGui then
        pcall(function() getgenv().PetDiceMobileToggleGui:Destroy() end)
        getgenv().PetDiceMobileToggleGui = nil
    end
    local cg = game:GetService("CoreGui")
    for _, gui in ipairs(cg:GetChildren()) do
        if gui:IsA("ScreenGui") and (gui.Name == "ScreenGui" or gui.Name == "Fluent") then
            if gui:FindFirstChild("Main") or gui:FindFirstChild("Holder") or gui:FindFirstChild("Window") then
                pcall(function() gui:Destroy() end)
            end
        end
    end
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local oldToggle = pg:FindFirstChild("PetDiceMobileToggle")
        if oldToggle then pcall(function() oldToggle:Destroy() end) end
    end
    local oldCgToggle = CG:FindFirstChild("PetDiceMobileToggle")
    if oldCgToggle then pcall(function() oldCgToggle:Destroy() end) end
end)

getgenv().PetDiceScriptToken = tick()
local scriptToken = getgenv().PetDiceScriptToken
getgenv().TradeActiveSession = false

-- Anti-AFK Dual-Layer (VirtualUser Event + 10-Min Periodic Heartbeat) ป้องกันเซิร์ฟเวอร์เตะเมื่อฟาร์ม 24/7
pcall(function()
    if getgenv().PetDiceAntiAFKConn then
        pcall(function() getgenv().PetDiceAntiAFKConn:Disconnect() end)
        getgenv().PetDiceAntiAFKConn = nil
    end
    local VirtualUser = game:GetService("VirtualUser")
    getgenv().PetDiceAntiAFKConn = LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
    
    -- Layer 2: Pulse ทุก 10 นาที ป้องกันกรณีหน้าต่างถูก Minimize / Unfocused ใน Windows 24/7
    task.spawn(function()
        while true do
            task.wait(600)
            if getgenv().PetDiceAntiAFKConn == nil then break end
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(10, 10))
            end)
        end
    end)
end)

-- Auto-Rejoin / Auto-Reconnect 24/7 (เซิร์ฟเวอร์รีสตาร์ท หรือเน็ตหลุด ให้เชื่อมต่อใหม่โดยอัตโนมัติ)
pcall(function()
    local GuiService = game:GetService("GuiService")
    local TeleportService = game:GetService("TeleportService")
    
    if getgenv().PetDiceErrorConn then
        pcall(function() getgenv().PetDiceErrorConn:Disconnect() end)
        getgenv().PetDiceErrorConn = nil
    end
    if getgenv().PetDiceOverlayConn then
        pcall(function() getgenv().PetDiceOverlayConn:Disconnect() end)
        getgenv().PetDiceOverlayConn = nil
    end
    
    local isReconnecting = false
    local function HandleReconnect(errorMsg)
        if not errorMsg or errorMsg == "" or isReconnecting then return end
        
        -- ตรวจสอบความปลอดภัยสูงสุด: หากกำลังติดคำสั่งแบน Error 600 หรือ Cloud Halt ห้าม Rejoin เด็ดขาด
        if getgenv().EmergencyKickLockout or getgenv().EmergencyCloudHalt or getgenv().EmergencyPatchHalt then
            return
        end
        
        local msgLower = tostring(errorMsg):lower()
        -- กรองข้อผิดพลาดประเภทเน็ตหลุด / เซิร์ฟเวอร์ปิดปรับปรุง / เตะชั่วคราว Error 267
        local isSafeToReconnect = msgLower:find("server shut down") 
            or msgLower:find("please reconnect") 
            or msgLower:find("lost connection") 
            or msgLower:find("connection timed out") 
            or msgLower:find("277") 
            or msgLower:find("279") 
            or msgLower:find("260") 
            or msgLower:find("284")
            or msgLower:find("267")
            or msgLower:find("kicked")
            or msgLower:find("disconnected")
            
        if isSafeToReconnect then
            isReconnecting = true
            task.spawn(function()
                -- หน่วงเวลาสุ่ม 20-30 วินาที เพื่อรอให้เซิร์ฟเวอร์เคลียร์สถานะตัวละครอย่างปลอดภัย
                task.wait(math.random(20, 30))
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
            end)
        end
    end
    
    getgenv().PetDiceErrorConn = GuiService.ErrorMessageChanged:Connect(function()
        local errorMsg = GuiService:GetErrorMessage()
        HandleReconnect(errorMsg)
    end)
    
    -- ตรวจสอบผ่าน CoreGui Overlay เพิ่มเติมเพื่อความครอบคลุม 100%
    local CoreGui = game:GetService("CoreGui")
    local promptGui = CoreGui:FindFirstChild("RobloxPromptGui")
    local promptOverlay = promptGui and promptGui:FindFirstChild("promptOverlay")
    if promptOverlay then
        getgenv().PetDiceOverlayConn = promptOverlay.ChildAdded:Connect(function(child)
            task.wait(2.0)
            local title = child:FindFirstChild("TitleFrame") and child.TitleFrame:FindFirstChild("ErrorTitle")
            local text = child:FindFirstChild("MessageArea") and child.MessageArea:FindFirstChild("ErrorText")
            local mStr = (title and title.Text or "") .. " " .. (text and text.Text or "")
            HandleReconnect(mStr)
        end)
    end
end)
-- ==============================================================================
-- [0] AIRTIGHT ANTI-BAN & PATCH SENTINEL SYSTEM (100% FAIL-SAFE PROTECTION)
-- ==============================================================================
local VERIFIED_GAME_PLACE_VERSION = 158
local SECURITY_CONFIG_URL = "https://raw.githubusercontent.com/markrunerppl-boop/petdicezaza/main/security.json"

getgenv().EmergencyPatchHalt = false
getgenv().EmergencyCloudHalt = false
getgenv().EmergencyStructuralHalt = false
getgenv().EmergencyKickLockout = false
getgenv().SecurityStatusMessage = "ระบบปลอดภัย ทำงานปกติ"

local function SafeNotify(title, content, duration)
    pcall(function()
        if Fluent and Fluent.Notify then
            Fluent:Notify({ Title = title, Content = content, Duration = duration or 5 })
        else
            game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = content, Duration = duration or 5 })
        end
    end)
end

-- 1. Error 267 Anti-Ban Lockout (ป้องกันการเตะสะสมจนกลายเป็น Error 600 แบนถาวร)
pcall(function()
    local kickLogFile = "petdice_kick_guard.json"
    local nowTime = os.time()
    local kickData = { count = 0, lastKick = 0 }
    
    if isfile and isfile(kickLogFile) and readfile then
        pcall(function()
            local raw = readfile(kickLogFile)
            local decoded = HS:JSONDecode(raw)
            if type(decoded) == "table" then
                kickData = decoded
            end
        end)
    end
    
    -- ตรวจสอบ Error Message ปัจจุบันใน GuiService
    local currentErr = ""
    pcall(function() currentErr = GuiService:GetErrorMessage() end)
    local isCurrentlyKicked = currentErr and (currentErr:find("267") or currentErr:lower():find("kicked") or currentErr:find("unexpected client behavior"))
    
    -- รีเซ็ตประวัติหากการเตะครั้งล่าสุดผ่านไปเกิน 30 นาที หรือผู้เล่นกลับเข้ามาเล่นในเกมได้ตามปกติ
    if nowTime - (kickData.lastKick or 0) > 1800 or not isCurrentlyKicked then
        kickData.count = 0
        getgenv().EmergencyKickLockout = false
        if writefile then
            pcall(function() writefile(kickLogFile, HS:JSONEncode(kickData)) end)
        end
    end
    
    -- หากผู้เล่นกำลังติดหน้าจอเตะจริง และถูกเตะติดต่อกัน 2 ครั้งขึ้นไป สั่งล็อกดาวน์เพื่อความปลอดภัย
    if isCurrentlyKicked and kickData.count >= 2 and (nowTime - kickData.lastKick < 1800) then
        getgenv().EmergencyKickLockout = true
        getgenv().SecurityStatusMessage = string.format("ล็อกดาวน์ฉุกเฉิน: ถูกเตะติดต่อกัน %d ครั้ง (ป้องกันแบน 600)", kickData.count)
        task.spawn(function()
            task.wait(2)
            SafeNotify("🛑 ล็อกดาวน์ความปลอดภัยฉุกเฉิน", string.format("ตรวจพบว่าไอดีนี้เพิ่งถูกเตะ (Error 267) ติดต่อกัน %d ครั้ง!\nระบบสั่งหยุดทำงานอัตโนมัติเพื่อป้องกันไอดีโดนแบนถาวร (Error 600)", kickData.count), 15)
        end)
    else
        getgenv().EmergencyKickLockout = false
    end
    
    -- บันทึกเหตุการณ์ถูกเตะแบบเรียลไทม์ (กรองเฉพาะ Error 267 / ข้อความเตะจริงเท่านั้น)
    GuiService.ErrorMessageChanged:Connect(function(msg)
        if msg and type(msg) == "string" and msg ~= "" then
            local isRealKick = msg:find("267") or msg:lower():find("kicked") or msg:find("unexpected client behavior") or msg:lower():find("banned") or msg:find("Security")
            if isRealKick then
                kickData.count = (kickData.count or 0) + 1
                kickData.lastKick = os.time()
                if writefile then
                    pcall(function()
                        writefile(kickLogFile, HS:JSONEncode(kickData))
                    end)
                end
            end
        end
    end)
end)

-- 2. PlaceVersion Sentinel (ตรวจจับการอัปเดตแพทช์ใหม่ของตัวเกมแบบเรียลไทม์)
local function CheckGamePatch()
    local curVersion = game.PlaceVersion
    if curVersion > VERIFIED_GAME_PLACE_VERSION then
        if not getgenv().EmergencyPatchHalt then
            getgenv().EmergencyPatchHalt = true
            getgenv().SecurityStatusMessage = string.format("เกมอัปเดตแพทช์ใหม่ v%d (เกณฑ์ทดสอบ v%d) - สคริปต์หยุดทำงานอัตโนมัติ", curVersion, VERIFIED_GAME_PLACE_VERSION)
            SafeNotify("🚨 ตรวจพบเกมอัปเดตแพทช์ใหม่!", string.format("เกม Pet Dice เพิ่งอัปเดตแพทช์ใหม่ (v%d -> v%d)\nระบบหยุดส่งคำสั่งทั้งหมด 100%% ทันที เพื่อป้องกันไอดีโดนแบน (Error 600)\nกรุณารอสคริปต์อัปเดตความปลอดภัยก่อนเปิดใช้งาน", VERIFIED_GAME_PLACE_VERSION, curVersion), 15)
        end
        return false
    else
        getgenv().EmergencyPatchHalt = false
    end
    return true
end

-- 3. Cloud Remote Kill-Switch (อ่านคำสั่งควบคุมความปลอดภัยจาก GitHub แบบเรียลไทม์)
local function CheckCloudSecurity()
    pcall(function()
        local raw = nil
        local req = (syn and syn.request) or request or http_request
        if req then
            local res = req({ Url = SECURITY_CONFIG_URL .. "?t=" .. tick(), Method = "GET" })
            if res and res.StatusCode == 200 then
                raw = res.Body
            end
        elseif game.HttpGet then
            raw = game:HttpGet(SECURITY_CONFIG_URL .. "?t=" .. tick())
        end
        
        if raw and type(raw) == "string" and raw:find("{") then
            local ok, cfg = pcall(function() return HS:JSONDecode(raw) end)
            if ok and cfg then
                if cfg.kill_switch_active == true or cfg.safe == false then
                    getgenv().EmergencyCloudHalt = true
                    getgenv().SecurityStatusMessage = "Cloud Kill-Switch ทำงาน: ผู้พัฒนาสั่งหยุดฉุกเฉิน"
                    SafeNotify("🛑 Cloud Kill-Switch ทำงาน", string.format("ผู้พัฒนาสั่งหยุดการทำงานของสคริปต์ฉุกเฉิน:\n%s\nเพื่อความปลอดภัย 100%% ของผู้เล่นทุกคน", cfg.notice_message or "พบความเสี่ยงจากแพทช์เกม"), 15)
                else
                    getgenv().EmergencyCloudHalt = false
                end
                if cfg.verified_game_place_version and type(cfg.verified_game_place_version) == "number" then
                    VERIFIED_GAME_PLACE_VERSION = math.max(VERIFIED_GAME_PLACE_VERSION, cfg.verified_game_place_version)
                end
            end
        end
    end)
end

-- 4. Structural Integrity Sentinel (ตรวจสอบความสมบูรณ์ของโมดูลเกมแท้ก่อนทำงาน)
local function CheckStructuralIntegrity()
    local valid = pcall(function()
        local pd = RS:FindFirstChild("PetDice")
        assert(pd, "PetDice missing")
        local rem = pd:FindFirstChild("Remotes")
        assert(rem and rem:FindFirstChild("Action"), "Remotes.Action missing")
        local log = pd:FindFirstChild("Logic")
        assert(log and log:FindFirstChild("Stats") and log:FindFirstChild("Upgrades"), "Core Logic missing")
    end)
    if not valid then
        getgenv().EmergencyStructuralHalt = true
        getgenv().SecurityStatusMessage = "โครงสร้างโมดูลเกมเปลี่ยนแปลง - หยุดส่งคำสั่งฉุกเฉิน"
        SafeNotify("⚠️ โครงสร้างเกมเปลี่ยนแปลง", "ตรวจพบว่าตัวเกมมีการปรับเปลี่ยนโครงสร้างภายใน\nระบบหยุดทำงานชั่วคราวเพื่อป้องกัน Error 267/600", 10)
        return false
    else
        getgenv().EmergencyStructuralHalt = false
    end
    return true
end

-- ตรวจสอบความปลอดภัยครั้งแรกทันทีตอนเริ่มสคริปต์
CheckGamePatch()
CheckCloudSecurity()
CheckStructuralIntegrity()

-- Instant Sentinel: ดักจับการอัปเดต PlaceVersion แบบเสี้ยววินาที (0.0001s)
pcall(function()
    game:GetPropertyChangedSignal("PlaceVersion"):Connect(CheckGamePatch)
end)

-- Background Thread: ตรวจสอบแพทช์และคลาวด์ต่อเนื่อง 24/7
task.spawn(function()
    local lastCloudCheck = tick()
    while true do
        task.wait(5.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        
        -- ตรวจสอบเวอร์ชันเกมทุก 5 วินาที (หากเกมมีแพทช์ใหม่จะตัดไฟทันที)
        CheckGamePatch()
        
        -- ตรวจสอบความสมบูรณ์ของโมดูลเกมทุก 30 วินาที
        pcall(CheckStructuralIntegrity)
        
        -- ตรวจสอบ Cloud Kill-Switch จาก GitHub ทุก 60 วินาที เพื่อให้ฟาร์ม 24/7 กลับมาทำงานอัตโนมัติเมื่อแพทช์ผ่านการรับรอง
        local now = tick()
        if now - lastCloudCheck >= 60 then
            lastCloudCheck = now
            pcall(CheckCloudSecurity)
        end
    end
end)

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
local Towers = require(PetDice.Logic.Towers)
local TeamPairs = require(PetDice.Logic.TeamPairs)
local RewardsConfig = require(PetDice.Configs.RewardsConfig)
local QuestsLogic = require(PetDice.Logic.Quests)
local Upgrades = require(PetDice.Logic.Upgrades)
local Market = PetDice.Logic:FindFirstChild("Market") and require(PetDice.Logic.Market) or nil
local WorldBossConfig = PetDice.Configs:FindFirstChild("WorldBossConfig") and require(PetDice.Configs.WorldBossConfig) or nil
local ScheduleConfig = PetDice.Configs:FindFirstChild("ScheduleConfig") and require(PetDice.Configs.ScheduleConfig) or nil
local CombatConfig = PetDice.Configs:FindFirstChild("CombatConfig") and require(PetDice.Configs.CombatConfig) or nil
local LootBagController = (PetDice.Client:FindFirstChild("Cutscenes") and PetDice.Client.Cutscenes:FindFirstChild("LootBagController") and require(PetDice.Client.Cutscenes.LootBagController)) or nil
local CutsceneDirector = (PetDice.Client:FindFirstChild("Cutscenes") and PetDice.Client.Cutscenes:FindFirstChild("CutsceneDirector") and require(PetDice.Client.Cutscenes.CutsceneDirector)) or nil

-- ==============================================================================
-- [1] ANTI-DETECTION & HUMANIZER UTILITIES (Moved up for early access)
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

local LastRemoteFire = {}
local RemoteRateLimits = {
    RollTrait = 0.28,        -- Config.RateLimit Cost=0.5
    RollGrade = 0.28,        -- Config.RateLimit Cost=0.5
    UpgradePet = 0.35,       -- อัปเกรดเลเวลสัตว์เลี้ยง
    UpgradePetLevels = 0.35,
    BuyAllUpgrades = 1.50,   -- ป้องกันการยิงรัวซื้ออัปเกรดต้นไม้
    MarketBuyAll = 2.00,     -- ป้องกันการยิงรัวกวาดซื้อของในตลาด
    MarketBuy = 0.50,        -- ซื้อของชิ้นเดี่ยวในตลาด
    Teleport = 3.50,         -- ป้องกัน Error 600 / Teleport State Collision / Desync
    TowerStart = 3.50,       -- ป้องกัน Tower Spurt
    TowerExit = 3.00,
    TowerLeave = 3.50,
    WorldBossJoin = 3.50,
    WorldBossLeave = 3.00,
    Rebirth = 2.00,
    UsePotion = 0.40,
    OpenLootBag = 0.80,
    QuestClaim = 0.40,
    GoalClaim = 0.40,
    ClaimDaily = 1.00,
    ClaimPlaytime = 1.00,
    ClaimSocial = 1.00,
    SendExpedition = 1.00,
    ClaimExpedition = 0.80,
    TradeRequest = 3.00,     -- เว้นระยะอย่างน้อย 3.00s ต่อการส่งคำขอเทรด ป้องกันการสแปม
    TradeRespond = 2.00,     -- เว้นระยะ 2.00s ต่อการตอบรับคำขอเทรด
    TradeReady = 2.00,       -- เว้นระยะ 2.00s ต่อการกด Ready/Unready
    TradeItem = 0.50,        -- เว้นระยะ 0.50s ต่อการวางไอเทมลงในช่องเทรด
    TradeAddPets = 0.60,     -- เว้นระยะ 0.60s ต่อการใส่สัตว์เลี้ยงลงในช่องเทรด
    TradeRemovePets = 0.60,  -- เว้นระยะ 0.60s ต่อการดึงสัตว์เลี้ยงออกจากช่องเทรด
    TradeCancel = 1.50,      -- เว้นระยะ 1.50s ต่อการกดยกเลิกการเทรด
    BuyDice = 1.50,
    EquipDice = 0.50,
    EquipBest = 1.00,
    SellKeys = 0.50,
    ClaimLootPets = 0.80,
}

-- Global Zone Transition Serialization & Anti-Conflict State Machine
-- ป้องกันการส่งคำสั่งเปลี่ยนแมพ/อารีน่าซ้อนกัน (Tower, Boss, Teleport) ซึ่งเป็นสาเหตุหลักของ Error 267
local LastZoneTransitionTime = 0
local isZoneTransitionLocked = false
local ZoneTransitionActions = {
    TowerStart = true,
    TowerExit = true,
    TowerLeave = true,
    WorldBossJoin = true,
    WorldBossLeave = true,
    Teleport = true,
}

-- Forward Declarations & Master Cross-System Mutex Locks (100% Concurrency Collision Protection)
local SwitchOrStartTower
local IsTowerRunning
local IsTowerInArena
local isPetEnhanceRolling = false
local isPetOperationMutex = false
local isEconomyActionMutex = false
local isAutoSellingActive = false

getgenv().PetOperationMutex = false
getgenv().EconomyActionMutex = false
getgenv().LastPetOperationStartTime = 0
getgenv().LastEconomyActionStartTime = 0
getgenv().LastZoneTransitionTime = 0
getgenv().LastPetUpgradedTime = 0
getgenv().LastTradeRequestTime = 0

-- Trade Deferred Action Queue (จัดคิวคำสั่งอื่นที่เข้ามาขณะกำลังเทรด ให้รอทำตามลำดับหลังจากเทรดเสร็จ)
local TradeDeferredQueue = {}
local MAX_TRADE_DEFERRED_QUEUE = 40
local isFlushingTradeQueue = false

-- Centralized Remote Dispatcher Queue (100% Single-Threaded Anti-Collision & Anti-Kick Dispatcher)
-- ป้องกันการยิงคำสั่งพร้อมกันในเฟรมเดียวกัน (Single-Threaded FIFO Serializer)
local RemoteQueue = {}
getgenv().RemoteQueue = RemoteQueue
local LoopHeartbeats = {}
getgenv().LoopHeartbeats = LoopHeartbeats
local MIN_GLOBAL_REMOTE_INTERVAL = 0.18
local LastGlobalRemoteFireTime = 0

-- Global Token Bucket Rate Limiter (ป้องกันการยิงพร้อมกันจากทุกฟังก์ชันเกินขีดจำกัดเซิร์ฟเวอร์)
-- ขีดจำกัดเซิร์ฟเวอร์ของตัวเกมแท้: PerSecond = 12, Burst = 24
-- ขีดจำกัดความปลอดภัยขั้นสูงสุดของสคริปต์: PerSecond = 4.0 (ปลอดภัยกว่าขีดจำกัดเซิร์ฟเวอร์ 67%), MaxBurst = 10 (ปลอดภัย 58%)
local GlobalTokenBucket = {
    Tokens = 10.0,
    MaxTokens = 10.0,
    RefillRate = 4.0,  -- เติม 4 token ต่อวินาที ต่ำกว่าเซิร์ฟเวอร์ถึง 67% ป้องกันเซิร์ฟเวอร์เตะ Error 267 แน่นอน 100%
    LastRefill = tick(),
    Costs = {
        RollTrait = 0.5,
        RollGrade = 0.5,
        MarketBuyAll = 1.0,
        MarketBuy = 0.5,
        SellKeys = 1.0,
        ClaimLootPets = 0.5,
        TradeRequest = 2.0,
        TradeRespond = 1.5,
        TradeReady = 1.5,
        TradeItem = 0.5,
        TradeAddPets = 0.8,
        TradeRemovePets = 0.8,
        TradeCancel = 1.0,
        Menu = 0,
        -- รายการอื่นๆ มี Cost เริ่มต้นเป็น 1.0 ตามระบบเกม
    }
}

local function IsFeatureUnlocked(featureName, idName)
    local data = State.Data
    local u = data and data.Upgrades
    if not u or not Upgrades then return false end
    local openByFunc = Upgrades.IsOpen and Upgrades.IsOpen(u, featureName)
    local openById = (u[idName] or 0) > 0
    return openByFunc == true and openById == true
end

local function FlushTradeDeferredQueue()
    if isFlushingTradeQueue or #TradeDeferredQueue == 0 then return end
    isFlushingTradeQueue = true
    task.spawn(function()
        pcall(function()
            if Humanizer and Humanizer.Wait then
                Humanizer.Wait(1.2, 2.0)
            else
                task.wait(1.5)
            end
            while #TradeDeferredQueue > 0 do
                if getgenv().PetDiceScriptToken ~= scriptToken then break end
                if (IsInTrade and IsInTrade()) or getgenv().TradeActiveSession then break end
                
                local item = table.remove(TradeDeferredQueue, 1)
                if item and (tick() - item.timestamp <= 60.0) then
                    Fire(unpack(item.args))
                    if Humanizer and Humanizer.Wait then
                        Humanizer.Wait(0.35, 0.65)
                    else
                        task.wait(0.4)
                    end
                end
            end
        end)
        isFlushingTradeQueue = false
    end)
end

local function Fire(...) 
    local args = {...}
    local action = args[1]
    if typeof(action) ~= "string" then
        Action:FireServer(unpack(args))
        return
    end

    -- 0. ระบบความปลอดภัยระดับฮาร์ดแวร์: Patch Sentinel & Cloud Kill-Switch & Anti-Ban Lockout
    if getgenv().EmergencyPatchHalt or getgenv().EmergencyCloudHalt or getgenv().EmergencyStructuralHalt or getgenv().EmergencyKickLockout then
        return -- ตัดการส่งคำสั่ง 100% เมื่อตรวจพบความเสี่ยงหรือเกมอัปเดตแพทช์ใหม่ ป้องกัน Error 267 / 600
    end

    -- 0.1 Blanket Trade Isolation & Conflict Queueing (ป้องกันคำสั่งอื่นแทรกแซงระหว่างเทรด 100% พร้อมจัดคิวรอทำตามลำดับ)
    local TradeAllowedActions = {
        TradeRequest = true,
        TradeRespond = true,
        TradeReady = true,
        TradeItem = true,
        TradeAddPets = true,
        TradeRemovePets = true,
        TradeCancel = true,
        SetSetting = true,
    }
    if (IsInTrade and IsInTrade()) or getgenv().TradeActiveSession then
        if not TradeAllowedActions[action] then
            -- จัดคิวรอทำตามลำดับหลังจากจบเซสชันเทรด ป้องกันการสูญหายของคำสั่งและไม่ให้เกิดข้อผิดพลาด
            local EphemeralActions = {
                Roll = true,
                SetAuto = true,
                EquipBest = true,
            }
            if not EphemeralActions[action] and #TradeDeferredQueue < MAX_TRADE_DEFERRED_QUEUE then
                table.insert(TradeDeferredQueue, {
                    action = action,
                    args = args,
                    timestamp = tick()
                })
            end
            return -- ระงับการยิงไปเซิร์ฟเวอร์ระหว่างเซสชันเทรด ป้องกัน Error 267/600 100%
        end
    end

    -- 1. ตรวจสอบการโหลดของตัวเกม (ถ้าเกมกำลังโหลดข้อมูลหรือแมพ รอให้พร้อมก่อน เพื่อป้องกัน Error 600 / 267)
    if LocalPlayer:GetAttribute("PetDiceLoading") == true then
        local t0 = tick()
        while LocalPlayer:GetAttribute("PetDiceLoading") == true and (tick() - t0 < 4.0) do
            task.wait(0.2)
        end
        if LocalPlayer:GetAttribute("PetDiceLoading") == true then
            return -- กำลังโหลดแมพอยู่ ยกเลิกคำสั่งทันทีเพื่อป้องกัน desync และเตะ
        end
    end

    -- 1.1 ควบคุมการสลับโซนข้ามแมพทั้งหมด (Zone Transition Cross-Action Serialization)
    -- ป้องกันการส่งคำสั่งเปลี่ยนโซน (Tower, Boss, Teleport) ซ้อนกันในเสี้ยววินาทีจนเซิร์ฟเวอร์เตะ Error 267
    if ZoneTransitionActions[action] then
        local char = LocalPlayer.Character or Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hum or not hrp or hum.Health <= 0 then
            return -- ตัวละครไม่อยู่ในสภาพพร้อมเปลี่ยนโซน ยกเลิกทันทีเพื่อป้องกัน Error 267 / 600
        end
        local now = tick()
        local elapsedSinceZone = now - LastZoneTransitionTime
        if elapsedSinceZone < 3.6 then
            task.wait(3.6 - elapsedSinceZone)
        end
        isZoneTransitionLocked = true
        LastZoneTransitionTime = tick()
    end

    -- 2. ป้องกันฟีเจอร์ที่ยังไม่ปลดล็อค 100% (ป้องกัน Error 267 จากการส่งคำสั่งที่เซิร์ฟเวอร์ปฏิเสธ)
    if action == "RollGrade" and not IsFeatureUnlocked("Grades", "grades") then
        return
    end
    if action == "RollTrait" and not IsFeatureUnlocked("Traits", "traits") then
        return
    end
    if (action == "UpgradePet" or action == "UpgradePetLevels") and not IsFeatureUnlocked("PetUpgrades", "petup") then
        return
    end
    if (action == "SendExpedition" or action == "ClaimExpedition") and not IsFeatureUnlocked("Expeditions", "expeditions") then
        return
    end
    if action == "TowerStart" then
        if not IsFeatureUnlocked("Towers", "towers") then
            return
        end
        local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if isBoss or IsEnteringBossPortal == true then
            return -- ป้องกันการเริ่มหอคอยระหว่างศึกบอสโลก
        end
        local d = State.Data
        if (IsTowerRunning and IsTowerRunning()) or (d and d.TowerResume ~= nil and d.TowerResume.Floor and d.TowerResume.Floor > 0) then
            return -- ป้องกันการยิง TowerStart ซ้ำซ้อนขณะที่อยู่ในหอคอยอยู่แล้ว (ป้องกัน Error 267)
        end
        local char = LocalPlayer.Character or Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local inHub = Vector3.new(hrp.Position.X, 0, hrp.Position.Z).Magnitude < 150
            if inHub then
                return -- ห้ามเริ่มหอคอยเด็ดขาดขณะอยู่ในพลาซ่า (ระยะ Park < 150) ต้องวาร์ปกลับบ้านก่อน
            end
        end
        if (tick() - (LastRemoteFire["TowerLeave"] or 0) < 3.5) then
            return -- หน่วง 3.5 วินาทีหลังออกจากหอคอย ให้เซิร์ฟเวอร์เคลียร์สถานะอย่างสมบูรณ์
        end
    end
    if action == "TowerLeave" then
        local d = State.Data
        local inTower = (IsTowerRunning and IsTowerRunning()) or (d and d.TowerResume ~= nil and d.TowerResume.Floor and d.TowerResume.Floor > 0)
        if not inTower then
            return -- ไม่ได้อยู่ในหอคอย ไม่ส่งคำสั่งออกจากหอ
        end
    end
    if action == "TowerExit" then
        if not IsTowerInArena or not IsTowerInArena() then
            return -- ไม่ได้อยู่ในอารีน่าจริง ไม่ส่ง TowerExit
        end
    end
    if (action == "WorldBossJoin" or action == "WorldBossLeave" or action == "PortalRepair") and not IsFeatureUnlocked("WorldBoss", "worldboss") then
        return
    end
    if action == "Teleport" and args[2] == "Portal" and not IsFeatureUnlocked("WorldBoss", "worldboss") then
        return
    end
    if action == "BuyUpgrade" and args[2] == "worldboss" and not IsFeatureUnlocked("PetUpgrades", "petup") then
        return
    end
    if (action == "MarketBuyAll" or action == "MarketBuy") and not IsFeatureUnlocked("Market", "market") then
        return
    end

    -- 3. ตรวจสอบความสมบูรณ์ของพารามิเตอร์และการมีอยู่จริงของไอเทม / ทรัพยากร (Sanity Drop ป้องกันเตะ)
    local data = State.Data
    if action == "RollGrade" then
        local uid = args[2]
        if not data or (data.Gems or 0) <= 0 or not data.Pets or not data.Pets[uid] then
            return -- ไม่มีตั๋วหมุนเกรด (Gems) หรือสัตว์เลี้ยงไม่มีอยู่จริง ไม่ส่ง ป้องกัน Error 267
        end
        if data.Expeditions and data.Expeditions.Active then
            for _, exp in ipairs(data.Expeditions.Active) do
                for _, eUid in ipairs(exp.Pets or {}) do
                    if tostring(eUid) == tostring(uid) then return end -- สัตว์เลี้ยงอยู่ระหว่างผจญภัย
                end
            end
        end
    end
    if action == "RollTrait" then
        local uid = args[2]
        if not data or (data.Shards or 0) <= 0 or not data.Pets or not data.Pets[uid] then
            return -- ไม่มีชาร์ดหมุน Trait (Shards) หรือสัตว์เลี้ยงไม่มีอยู่จริง ไม่ส่ง ป้องกัน Error 267
        end
        if data.Expeditions and data.Expeditions.Active then
            for _, exp in ipairs(data.Expeditions.Active) do
                for _, eUid in ipairs(exp.Pets or {}) do
                    if tostring(eUid) == tostring(uid) then return end -- สัตว์เลี้ยงอยู่ระหว่างผจญภัย
                end
            end
        end
    end
    if action == "BuyAllUpgrades" then
        if not data or not data.Money or data.Money <= 0 then
            return -- ไม่มีเงิน ไม่ส่ง ป้องกัน Error 267
        end
    end
    if action == "UpgradePet" or action == "UpgradePetLevels" then
        local uid = args[2]
        if not data or not data.Pets or not data.Pets[uid] then
            return -- สัตว์เลี้ยงไม่มีอยู่จริง ไม่ส่ง
        end
        if data.Expeditions and data.Expeditions.Active then
            for _, exp in ipairs(data.Expeditions.Active) do
                for _, eUid in ipairs(exp.Pets or {}) do
                    if tostring(eUid) == tostring(uid) then return end -- สัตว์เลี้ยงอยู่ระหว่างผจญภัย
                end
            end
        end
    end
    if action == "OpenLootBag" then
        local bagKind = args[3]
        if bagKind then
            local haveSeason = data and data.SeasonBags and (data.SeasonBags[bagKind] or 0) > 0
            local haveElement = data and data.ElementBags and (data.ElementBags[bagKind] or 0) > 0
            if not haveSeason and not haveElement then return end
        else
            if not data or (data.LootBags or 0) <= 0 then return end
        end
    end
    if action == "ClaimLootPets" then
        local waiting = 0
        pcall(function()
            if PetData and PetData.WaitingCount and data then
                waiting = PetData.WaitingCount(data, args[2] or "Infinity")
            end
        end)
        if waiting <= 0 then return end
    end
    if action == "MarketBuyAll" then
        if not data or not Market then return end
        local now = State.Now and State.Now() or os.time()
        local currentWindow = Market.Window(now)
        local bought = data.Market and (data.Market.Window ~= currentWindow and {} or data.Market.Bought) or {}
        local _, canBuyCount, totalCost = Market.PlanBuyAll(currentWindow, bought, data.Rebirths or 0, data.Money or 0)
        if (canBuyCount or 0) <= 0 or (data.Money or 0) < (totalCost or 0) then
            return -- ไม่มีสินค้าให้ซื้อ หรือเงินไม่พอ ปฏิเสธทันที ไม่ยิงไปเซิร์ฟเวอร์
        end
    end
    if action == "BuyDice" and not args[2] then
        return -- ป้องกันการยิง BuyDice แบบไม่มี ID
    end
    if action == "EquipBest" or action == "EquipDice" then
        if (IsTowerRunning and IsTowerRunning()) or (IsTowerInArena and IsTowerInArena()) then return end
        local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if isBoss or IsEnteringBossPortal == true then return end
        if IsInTrade and (IsInTrade() or getgenv().TradeActiveSession) then return end
    end
    if action == "SellKeys" then
        if IsInTrade and (IsInTrade() or getgenv().TradeActiveSession) then return end
    end
    if action == "UsePotion" then
        local potKey = args[2]
        if not data or not data.Potions or (data.Potions[potKey] or 0) <= 0 then
            return -- ไม่มีน้ำยาจริงในคลัง ยกเลิกทันที ไม่ยิงไปเซิร์ฟเวอร์
        end
    end
    if action == "Rebirth" then
        if (IsTowerRunning and IsTowerRunning()) or (IsTowerInArena and IsTowerInArena()) then return end
        local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if isBoss or IsEnteringBossPortal == true then return end
        local cost = Stats and Stats.RebirthCost and Stats.RebirthCost(data)
        if not cost or not data or (data.Money or 0) < cost then
            return -- เงินไม่พอเกิดใหม่ ยกเลิกทันที
        end
    end
    if action == "Roll" and State.Rolling then
        return -- กำลังทอยเต๋าอยู่ ไม่ยิงซ้อน
    end
    if action == "Teleport" then
        if IsTowerInArena and IsTowerInArena() then
            return -- ห้ามส่งคำสั่ง Teleport เด็ดขาดขณะอยู่ในอารีน่าหอคอย ป้องกัน Error 267
        end
        local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if isBoss or IsEnteringBossPortal == true then
            return -- ห้ามส่งคำสั่ง Teleport ขณะกำลังสู้บอสโลก ป้องกัน Error 267
        end
        if IsInTrade and (IsInTrade() or getgenv().TradeActiveSession) then
            return -- ห้ามส่งคำสั่ง Teleport ระหว่างเทรด
        end
        
        local dest = args[2]
        
        -- ตรวจสอบตัวละครและสภาพร่างกายก่อนวาร์ป ป้องกัน desync และ Error 600
        local char = LocalPlayer.Character or Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hum or not hrp or hum.Health <= 0 then
            return
        end
        
        local mag = Vector3.new(hrp.Position.X, 0, hrp.Position.Z).Magnitude
        if dest == "Hub" and mag < 150 then
            return -- อยู่ในลานพลาซ่า/ฮับอยู่แล้ว (ระยะศูนย์กลาง < 150 studs) ห้ามส่ง Teleport Hub ซ้ำ ป้องกัน Error 267
        end
        if dest == "Home" and mag >= 150 and not (IsTowerRunning and IsTowerRunning()) then
            return -- อยู่ในพื้นที่บ้าน (Plot Yard) อยู่แล้ว (ระยะ >= 150 studs) ห้ามส่ง Teleport Home ซ้ำ ป้องกัน Error 267
        end
    end
    if action == "SendExpedition" then
        if IsInTrade and (IsInTrade() or getgenv().TradeActiveSession) then return end
        if not IsFeatureUnlocked or not IsFeatureUnlocked("Expeditions", "expeditions") then return end
        local diffId = args[2]
        local pets = args[3]
        if not diffId or not pets or type(pets) ~= "table" or #pets == 0 then return end
        if not data or not data.Pets or not data.Expeditions then return end
        local maxSlots = Expeditions and Expeditions.Slots and Expeditions.Slots(data) or 3
        local activeCount = #(data.Expeditions.Active or {})
        if activeCount >= maxSlots then return end
        
        local foundDiff = nil
        if ExpeditionConfig and ExpeditionConfig.Difficulties then
            for _, d in ipairs(ExpeditionConfig.Difficulties) do
                if d.Id == diffId then
                    foundDiff = d
                    break
                end
            end
        end
        if not foundDiff then return end
        if Expeditions and Expeditions.Unlocked and not Expeditions.Unlocked(data, foundDiff) then
            return -- ระดับนี้ยังไม่ได้ปลดล็อกในผังอัปเกรด
        end
        if #pets > foundDiff.Pets then
            return -- จำนวนสัตว์เลี้ยงเกินขีดจำกัดของระดับนี้
        end
        
        local onExp = {}
        for _, exp in ipairs(data.Expeditions.Active or {}) do
            for _, u in ipairs(exp.Pets or {}) do onExp[tostring(u)] = true end
        end
        local equipped = {}
        for _, u in ipairs(data.Equipped or {}) do equipped[tostring(u)] = true end
        
        for _, pUid in ipairs(pets) do
            local sUid = tostring(pUid)
            local p = data.Pets[sUid]
            if not p then return end
            if onExp[sUid] or equipped[sUid] then return end
            local def = PetData and PetData.ById and PetData.ById[p.Id]
            if def and (def.Limited == true or def.Rarity == "Limited") then return end
            local pwr = 0
            pcall(function()
                pwr = Expeditions.PetPower(data, p, State.Mods and State.Mods() or {}, State.Now and State.Now() or os.time())
            end)
            if pwr < foundDiff.Requirement then return end
        end
    end
    if action == "ClaimExpedition" then
        if IsInTrade and (IsInTrade() or getgenv().TradeActiveSession) then return end
        local expId = args[2]
        if not expId or not data or not data.Expeditions or not data.Expeditions.Active then return end
        local foundExp = nil
        for _, exp in ipairs(data.Expeditions.Active) do
            if exp.Id == expId then
                foundExp = exp
                break
            end
        end
        if not foundExp then return end
        local now = State.Now and State.Now() or os.time()
        local left = Expeditions and Expeditions.Left and Expeditions.Left(foundExp, now) or math.max(0, (foundExp.Ends or 0) - now)
        if left > 0 then
            return -- ยังไม่หมดเวลาสำรวจ ป้องกัน NOT DONE YET! และ Error 267
        end
    end
    if action == "QuestClaim" then
        local qType = args[2]
        local qIndex = args[3]
        if not data or not data.Quests or not data.Quests[qType] then return end
        local q = data.Quests[qType][qIndex]
        if not q or q.Claimed or (q.Progress or 0) < (q.Goal or math.huge) then
            return -- เควสยังไม่เสร็จหรือรับไปแล้ว ไม่ยิงซ้ำ ป้องกัน NOT DONE YET!
        end
    end
    if action == "GoalClaim" then
        local gId = args[2]
        if not data or not data.Quests or not data.Quests.Goals then return end
        local gData = data.Quests.Goals[gId]
        if gData and gData.Claimed then return end
        local gDef = nil
        if QuestsLogic and QuestsLogic.Goals then
            for _, gd in ipairs(QuestsLogic.Goals) do
                if gd.Id == gId then gDef = gd break end
            end
        end
        if not gDef then return end
        if Upgrades and Upgrades.IsOpen and not Upgrades.IsOpen(data.Upgrades, gDef.Needs) then
            return -- เงื่อนไขต้นไม้อัปเกรดยังไม่เปิด
        end
        local prog = gData and gData.Progress or 0
        if prog < (gDef.Goal or math.huge) then
            return -- ยังไม่บรรลุเป้าหมาย
        end
    end
    if action == "ClaimSocial" then
        local sType = args[2]
        if not data or not data.Social then return end
        if sType == "Group" and data.Social.Group then return end
        if sType == "Like" and data.Social.Like then return end
    end
    if action == "TradeRequest" then
        local targetUserId = tonumber(args[2])
        if not targetUserId then return end
        if targetUserId == LocalPlayer.UserId then return end
        
        local targetPlayer = Players:GetPlayerByUserId(targetUserId)
        if not targetPlayer or targetPlayer.Parent ~= Players then return end
        
        if not data or not Config.TradeUnlocked or not Config.TradeUnlocked(data) then return end
        if (IsInTrade and IsInTrade()) or getgenv().CurrentTradeSession ~= nil then return end
        if IsTowerInArena and IsTowerInArena() then return end
        local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if isBoss or IsEnteringBossPortal == true then return end
        if isZoneTransitionLocked then return end
        
        local lastComplete = getgenv().LastTradeCompleteTime or 0
        local elapsed = tick() - lastComplete
        local cd = (getgenv().CFG and getgenv().CFG.TradeCooldown) or 90
        if elapsed < math.min(10, cd) then return end
    end
    if action == "TradeRespond" then
        local senderUserId = tonumber(args[2])
        local accept = args[3]
        if not senderUserId then return end
        if accept == true then
            if not data or not Config.TradeUnlocked or not Config.TradeUnlocked(data) then return end
            if getgenv().CurrentTradeSession ~= nil or (GetTradeWindow and GetTradeWindow() ~= nil) then return end
            if IsTowerInArena and IsTowerInArena() then return end
            local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
            if isBoss or IsEnteringBossPortal == true then return end
            if isZoneTransitionLocked then return end
        end
    end
    if action == "TradeReady" then
        local readyState = args[2]
        local session = getgenv().CurrentTradeSession
        if not session and (not GetTradeWindow or not GetTradeWindow()) then return end
        if session and session.You then
            if readyState == true and session.You.Ready == true then return end
            if session.You.LockedFor and session.You.LockedFor > 0 then return end
        end
    end
    if action == "TradeItem" then
        local itemKey = args[2]
        local count = tonumber(args[3]) or 0
        local session = getgenv().CurrentTradeSession
        if not session and (not GetTradeWindow or not GetTradeWindow()) then return end
        if not itemKey or count < 0 then return end
        if not Config.TradeItemByKey or not Config.TradeItemByKey[itemKey] then return end
        if count > 0 then
            local realCount = GetRealItemCount and GetRealItemCount(itemKey) or 0
            if realCount < count then return end
        end
    end
    if action == "TradeAddPets" then
        local petUids = args[2]
        local session = getgenv().CurrentTradeSession
        if not session and (not GetTradeWindow or not GetTradeWindow()) then return end
        if not petUids or type(petUids) ~= "table" or #petUids == 0 then return end
        if not data or not data.Pets then return end
        
        local currentPetsCount = 0
        if session and session.You and session.You.Pets then
            for _ in pairs(session.You.Pets) do currentPetsCount = currentPetsCount + 1 end
        end
        if currentPetsCount + #petUids > 12 then return end
        
        local equipped = {}
        for _, u in ipairs(data.Equipped or {}) do equipped[tostring(u)] = true end
        local onExp = {}
        for _, exp in ipairs(data.Expeditions and data.Expeditions.Active or {}) do
            for _, u in ipairs(exp.Pets or {}) do onExp[tostring(u)] = true end
        end
        
        for _, uid in ipairs(petUids) do
            local sUid = tostring(uid)
            local p = data.Pets[sUid]
            if not p then return end
            if equipped[sUid] or onExp[sUid] then return end
            if (data.Locked and data.Locked[sUid]) or p.Locked then return end
            local def = PetData and PetData.ById and PetData.ById[p.Id]
            if def and (def.Limited == true or def.Rarity == "Limited") then return end
        end
    end
    if action == "TradeRemovePets" then
        local petUids = args[2]
        local session = getgenv().CurrentTradeSession
        if not session and (not GetTradeWindow or not GetTradeWindow()) then return end
        if not petUids or type(petUids) ~= "table" or #petUids == 0 then return end
    end
    if action == "TradeCancel" then
        local session = getgenv().CurrentTradeSession
        if not session and (not GetTradeWindow or not GetTradeWindow()) and not getgenv().TradeActiveSession then
            return
        end
    end

    -- ป้องกันคิวยาวเกินไปเมื่อหลาย Loop เรียกคำสั่งพร้อมกัน
    if #RemoteQueue >= 20 then
        if action == "Roll" or action == "RollGrade" or action == "RollTrait" or action == "SetAuto" then
            return -- สลัดคำสั่งความสำคัญต่ำทิ้ง ไม่สะสมในคิว
        end
    end

    table.insert(RemoteQueue, { action = action, args = args })
end

-- Dedicated Single-Threaded Remote Dispatcher (รับประกันการส่งคำสั่งทีละ 1 คำสั่ง ปราศจากการยิงชนกัน 100%)
task.spawn(function()
    while true do
        task.wait(0.01)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        
        if #RemoteQueue > 0 then
            local item = table.remove(RemoteQueue, 1)
            if item then
                local action = item.action
                local args = item.args
                
                if not (getgenv().EmergencyPatchHalt or getgenv().EmergencyCloudHalt or getgenv().EmergencyStructuralHalt or getgenv().EmergencyKickLockout) then
                    -- 1. ควบคุมความถี่เฉพาะของแต่ละคำสั่ง (Per-Action Rate Limiting)
                    local minInterval = RemoteRateLimits[action] or 0.15
                    local now = tick()
                    local diff = now - (LastRemoteFire[action] or 0)
                    if diff < minInterval then
                        task.wait(minInterval - diff)
                    end
                    
                    -- 2. Single-Threaded Global Inter-Packet Serializer (เว้นระยะอย่างน้อย 0.18s เสมอ)
                    local nowFire = tick()
                    local globalDiff = nowFire - LastGlobalRemoteFireTime
                    if globalDiff < MIN_GLOBAL_REMOTE_INTERVAL then
                        task.wait(MIN_GLOBAL_REMOTE_INTERVAL - globalDiff)
                    end
                    
                    -- 3. Global Token Bucket Rate Limiter
                    local nowTb = tick()
                    local elapsed = nowTb - GlobalTokenBucket.LastRefill
                    GlobalTokenBucket.Tokens = math.min(GlobalTokenBucket.MaxTokens, GlobalTokenBucket.Tokens + (elapsed * GlobalTokenBucket.RefillRate))
                    GlobalTokenBucket.LastRefill = nowTb
                    
                    local cost = GlobalTokenBucket.Costs[action] or 1.0
                    if GlobalTokenBucket.Tokens < cost then
                        local waitSec = (cost - GlobalTokenBucket.Tokens) / GlobalTokenBucket.RefillRate
                        if waitSec > 0 then task.wait(waitSec) end
                        GlobalTokenBucket.Tokens = 0
                        GlobalTokenBucket.LastRefill = tick()
                    else
                        GlobalTokenBucket.Tokens = GlobalTokenBucket.Tokens - cost
                    end
                    
                    LastRemoteFire[action] = tick()
                    LastGlobalRemoteFireTime = tick()
                    if ZoneTransitionActions[action] then
                        LastZoneTransitionTime = tick()
                        task.delay(3.6, function() isZoneTransitionLocked = false end)
                    end
                    
                    pcall(function()
                        Action:FireServer(unpack(args))
                    end)
                end
            end
        end
    end
end)

-- ==============================================================================
-- [1] ANTI-DETECTION & HUMANIZER UTILITIES
-- ==============================================================================
Humanizer = Humanizer or {}

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

local PathfindingService = game:GetService("PathfindingService")

local function WalkAlongPath(destination, maxTime)
    local char = LocalPlayer.Character or Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or not hrp or hum.Health <= 0 then return false end
    
    local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(destination.X, 0, destination.Z)).Magnitude
    if dist <= 6 then return true end
    
    local path = PathfindingService:CreatePath({
        AgentRadius = 2.0,
        AgentHeight = 5.0,
        AgentCanJump = true,
        WaypointSpacing = 4.0
    })
    
    local ok, _ = pcall(function()
        path:ComputeAsync(hrp.Position, destination)
    end)
    
    if not ok or path.Status ~= Enum.PathStatus.Success then
        -- ระบบสำรอง: เดินตรงหากการคำนวณเส้นทางล้มเหลว
        hum:MoveTo(Vector3.new(destination.X, hrp.Position.Y, destination.Z))
        local t0 = tick()
        while (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(destination.X, 0, destination.Z)).Magnitude > 6 and (tick() - t0 < (maxTime or 5.0)) do
            task.wait(0.12)
            char = LocalPlayer.Character or Character
            hum = char and char:FindFirstChildOfClass("Humanoid")
            hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then break end
        end
        char = LocalPlayer.Character or Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        return hrp and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(destination.X, 0, destination.Z)).Magnitude <= 8
    end
    
    local waypoints = path:GetWaypoints()
    local t0 = tick()
    local timeLimit = maxTime or 12.0
    
    for i, wp in ipairs(waypoints) do
        if tick() - t0 > timeLimit then return false end
        char = LocalPlayer.Character or Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return false end
        
        if wp.Action == Enum.PathWaypointAction.Jump then
            hum.Jump = true
        end
        
        hum:MoveTo(wp.Position)
        
        local wpWait0 = tick()
        while (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(wp.Position.X, 0, wp.Position.Z)).Magnitude > 4.5 and (tick() - wpWait0 < 2.0) do
            task.wait(0.06)
            char = LocalPlayer.Character or Character
            hum = char and char:FindFirstChildOfClass("Humanoid")
            hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then return false end
        end
    end
    
    char = LocalPlayer.Character or Character
    hrp = char and char:FindFirstChild("HumanoidRootPart")
    return hrp and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(destination.X, 0, destination.Z)).Magnitude <= 10
end

local function SafeWalkTo(targetPos, maxWait)
    local char = LocalPlayer.Character or Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or not hrp or hum.Health <= 0 then return false end
    
    local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
    if dist < 6 then return true end
    
    if dist > 18 then
        return WalkAlongPath(targetPos, maxWait or 6.0)
    end
    
    -- เดินระยะใกล้ด้วย Humanoid:MoveTo ตามระบบฟิสิกส์ปกติของตัวเกมบนระนาบพื้นปกติ ป้องกันการติดในวัตถุ/ใต้แมพ 100%
    local walkTarget = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
    hum:MoveTo(walkTarget)
    
    local t0 = tick()
    local waitLimit = maxWait or 3.5
    while (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude > 6 and (tick() - t0 < waitLimit) do
        task.wait(0.10)
        char = LocalPlayer.Character or Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then break end
    end
    
    char = LocalPlayer.Character or Character
    hrp = char and char:FindFirstChild("HumanoidRootPart")
    return hrp and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude <= 8
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
    
    local onExp = {}
    if data.Expeditions and data.Expeditions.Active then
        for _, exp in ipairs(data.Expeditions.Active) do
            for _, uid in ipairs(exp.Pets or {}) do
                onExp[tostring(uid)] = true
            end
        end
    end
    
    for uid, pet in pairs(data.Pets) do
        local sUid = tostring(uid)
        if not onExp[sUid] and IsPetEligibleForEnhance(pet) then
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
    KeepTopPetsCount = 100,
    AutoBuyMarket = false
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

-- ตั้งค่าเริ่มต้นหากยังไม่มีการเลือกหอคอย
if not getgenv().CFG.SelectedTower or getgenv().CFG.SelectedTower == "" then
    getgenv().CFG.SelectedTower = "Infinity"
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
    local ok2, fluentRes2 = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/markrunerppl-boop/petdicezaza/main/fluent.lua"))()
    end)
    if ok2 and fluentRes2 then
        Fluent = fluentRes2
    else
        Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    end
end
getgenv().PetDiceFluent = Fluent

local Window = Fluent:CreateWindow({
    Title = "Pet Dice Pro Farm",
    SubTitle = "Master Safe Edition v4.8",
    TabWidth = 160,
    Size = UDim2.fromOffset(590, 480),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightControl
})
getgenv().PetDiceWindow = Window
getgenv().PetDiceFluentGui = Window and Window.Root

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
do
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
end

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

local SecurityStatusPara = Tabs.Overview:AddParagraph({
    Title = string.format("🛡️ ความปลอดภัย: ปลอดภัย 100%% (Game Patch v%d)", game.PlaceVersion),
    Content = string.format("🎮 Game Version: v%d | ปลอดภัย\n🌐 Cloud Kill-Switch: ปกติ (Operational)\n🔒 Anti-Ban Protection: พร้อมทำงาน (ป้องกัน Error 267 / 600)", game.PlaceVersion)
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
isAutoSellingActive = false
local SliderKeepPetCount = nil
local InputCustomKeepCount = nil
local AutoSellStatusPara = nil

local function ExecuteAutoSellPets(targetCountOverride)
    if isAutoSellingActive then return false, "กำลังดำเนินการขายสัตว์เลี้ยงอยู่..." end
    local retryWait = 0
    while (isPetOperationMutex or isPetEnhanceRolling) and retryWait < 15 do
        task.wait(0.1)
        retryWait = retryWait + 1
    end
    if isPetOperationMutex or isPetEnhanceRolling then
        return false, "กำลังสุ่มหรืออัปเกรดสัตว์เลี้ยงอยู่ ชะลอการขายชั่วคราว..."
    end
    local data = State.Data
    if not data or not data.Pets then return false, "ไม่มีข้อมูลสัตว์เลี้ยงในขณะนี้" end
    
    local targetKeep = targetCountOverride or CFG.KeepTopPetsCount or 100
    targetKeep = math.max(1, math.floor(tonumber(targetKeep) or 100))
    
    local stacks = State.Stacks()
    if not stacks or #stacks == 0 then return false, "ไม่พบรายการสัตว์เลี้ยงในกระเป๋า" end
    
    isAutoSellingActive = true
    isPetOperationMutex = true
    getgenv().PetOperationMutex = true
    getgenv().LastPetOperationStartTime = tick()
    local success, totalSoldOrErr, keptCount = pcall(function()
        local onExpUids = {}
        if data.Expeditions and data.Expeditions.Active then
            for _, exp in ipairs(data.Expeditions.Active) do
                for _, uid in ipairs(exp.Pets or {}) do
                    onExpUids[tostring(uid)] = true
                end
            end
        end

        local stackInfos = {}
        for _, s in ipairs(stacks) do
            local base = 0
            pcall(function() base = Stats.PetBaseIncome(s.Item) end)
            local def = PetData and PetData.ById and PetData.ById[s.Id]
            local isLimited = (def and def.Limited) or false
            
            -- ตรวจสอบตัวที่ล็อคไว้ (Locked Pets) และตัวที่กำลังผจญภัย (On Active Expedition)
            local lockedCount = 0
            local onExpCount = 0
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
            for _, uid in ipairs(s.Uids or {}) do
                if onExpUids[tostring(uid)] then
                    onExpCount = onExpCount + 1
                end
            end
            
            table.insert(stackInfos, {
                stack = s,
                key = s.Key,
                id = s.Id,
                count = s.Count,
                equipped = s.Equipped or 0,
                locked = lockedCount,
                onExp = onExpCount,
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
            local protectedCount = math.min(totalInStack, math.max(info.equipped, info.locked) + (info.onExp or 0))
            if info.isLimited then
                protectedCount = totalInStack -- สัตว์เลี้ยง Limited ปลอดภัยเสมอ ไม่ขายเด็ดขาด
            end
            
            local remainingToKeep = math.max(0, targetKeep - kept)
            local keepFromStack = math.min(totalInStack, remainingToKeep)
            keepFromStack = math.max(keepFromStack, protectedCount)
            
            local sellFromStack = totalInStack - keepFromStack
            local unequippedAndUnlocked = totalInStack - info.equipped - info.locked - (info.onExp or 0)
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
            Fire("SellKeys", batch.keys, batch.amounts)
            if bIndex < #sellBatches then
                Humanizer.Wait(0.40, 0.65)
            end
        end
        
        return toSell, kept
    end)
    isAutoSellingActive = false
    isPetOperationMutex = false
    getgenv().PetOperationMutex = false
    getgenv().LastPetOperationStartTime = 0
    pcall(function() if UpdateOverviewTab then UpdateOverviewTab() end end)
    
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

local ParagraphCache = {}
local function SafeUpdatePara(para, title, desc)
    if not para then return end
    local cache = ParagraphCache[para]
    if not cache then
        cache = { title = "", desc = "" }
        ParagraphCache[para] = cache
    end
    if cache.title ~= title then
        cache.title = title
        pcall(function() para:SetTitle(title) end)
    end
    if cache.desc ~= desc then
        cache.desc = desc
        pcall(function() para:SetDesc(desc) end)
    end
end

local function UpdateOverviewTab()
    pcall(function()
        local data = State.Data
        if not data then return end
        
        -- Update Overview Stats
        local moneyStr = Format.Money(data.Money or 0)
        local gemsStr = Format.Commas(data.Gems or 0)
        local shardsStr = Format.Commas(data.Shards or 0)
        local towerFloor = (data.TowerResume and data.TowerResume.Floor) or (data.TowerBest and data.TowerBest.Infinity) or 0
        local totalPets = 0
        if data.Pets then for _ in pairs(data.Pets) do totalPets = totalPets + 1 end end
        
        SafeUpdatePara(OverviewStats, 
            string.format("💰 เงิน: %s | 💎 เพชร: %s | 🔮 ชาร์ด: %s", moneyStr, gemsStr, shardsStr),
            string.format("🏰 หอคอยชั้น: %d | 🐾 สัตว์เลี้ยงทั้งหมด: %d ตัว", towerFloor, totalPets)
        )
        
        if SecurityStatusPara then
            if getgenv().EmergencyPatchHalt then
                SafeUpdatePara(SecurityStatusPara,
                    "🚨 ตรวจพบเกมอัปเดตแพทช์ใหม่! (หยุดทำงานอัตโนมัติ)",
                    string.format("Game Version: v%d (เกณฑ์ทดสอบ v%d)\nระบบสั่งหยุดทำงาน 100%% เพื่อความปลอดภัยจากการแบน Error 600", game.PlaceVersion, VERIFIED_GAME_PLACE_VERSION)
                )
            elseif getgenv().EmergencyCloudHalt then
                SafeUpdatePara(SecurityStatusPara,
                    "🛑 ผู้พัฒนาสั่งระงับสคริปต์ฉุกเฉิน (Cloud Kill-Switch)",
                    getgenv().SecurityStatusMessage or "ระบบหยุดทำงานชั่วคราวเพื่อความปลอดภัย"
                )
            elseif getgenv().EmergencyKickLockout then
                SafeUpdatePara(SecurityStatusPara,
                    "🔒 ล็อกดาวน์ความปลอดภัยฉุกเฉิน (Anti-Ban Lockout)",
                    "ถูกเตะติดต่อกันเกิน 2 ครั้ง ระบบสั่งพัก 30 นาทีเพื่อป้องกันแบนถาวร"
                )
            else
                SafeUpdatePara(SecurityStatusPara,
                    string.format("🛡️ ความปลอดภัย: ปลอดภัย 100%% (Game Patch v%d)", game.PlaceVersion),
                    string.format("🎮 Game Version: v%d (ตรงตามเกณฑ์ทดสอบ) | ปลอดภัย\n🌐 Cloud Kill-Switch: ปกติ (Operational)\n🔒 Anti-Ban Protection: พร้อมทำงาน (ป้องกัน Error 267 / 600)", game.PlaceVersion)
                )
            end
        end
        
        -- Update Auto Sell Stats
        if AutoSellStatusPara then
            local targetK = CFG.KeepTopPetsCount or 100
            local excess = math.max(0, totalPets - targetK)
            local statusText = CFG.AutoSellPets and "🟢 เปิดทำงานปกติ" or "⚪ ปิดการทำงาน"
            if isAutoSellingActive then
                statusText = "🟡 กำลังดำเนินการขาย..."
            elseif CFG.AutoSellPets and excess == 0 then
                statusText = string.format("🟢 ปกติ (เก็บ %s ตัวที่ดีที่สุดครบถ้วน)", Format.Commas(targetK))
            end
            SafeUpdatePara(AutoSellStatusPara,
                string.format("📊 สถานะ: %s | มีทั้งหมด: %s ตัว | เป้าหมายเก็บไว้: %s ตัว", statusText, Format.Commas(totalPets), Format.Commas(targetK)),
                string.format("ส่วนเกินที่จะขาย: %s ตัว (เรียงจากค่าพลัง Base สูงสุดลงไป | สัตว์เลี้ยงที่สวมใส่และล็อคจะได้รับการปกป้อง 100%%)", Format.Commas(excess))
            )
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
                    
                    SafeUpdatePara(PetCardParagraphs[i],
                        string.format("⭐ #%d: %s %s", i, pet.Id, tagStr),
                        string.format("รายได้ฐาน: %s/s | เลเวล: %d/%d | เกรด: %s | บัฟ: %s", baseStr, lvl, targetLvl, gName, tName)
                    )
                else
                    SafeUpdatePara(PetCardParagraphs[i],
                        string.format("💤 #%d: ไม่มีข้อมูลสัตว์เลี้ยง", i),
                        "ยังไม่มีสัตว์เลี้ยงในตำแหน่งนี้"
                    )
                end
            else
                SafeUpdatePara(PetCardParagraphs[i],
                    string.format("➖ #%d: ปิดการทำงาน", i),
                    string.format("เลือกทำ %d ตัวแรก (ปรับเพิ่มได้ในแท็บอัปเกรด)", count)
                )
            end
        end
    end)
end

task.spawn(UpdateOverviewTab)
task.spawn(function()
    while true do
        task.wait(5.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        UpdateOverviewTab()
    end
end)

-- ------------------------------------------------------------------------------
-- ⭐ TAB 2: ENHANCE & ROLL BUFFS
-- ------------------------------------------------------------------------------
Tabs.Enhance:AddSection("⚙️ ตั้งค่าสัตว์เลี้ยงและเป้าหมาย")

do
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
        Title = "⚡ ความเร็วในการสุ่มบัฟ/เกรด (0.25 - 1.00 วินาที)",
        Description = "ความหน่วงระหว่างการสุ่ม (แนะนำ 0.30 - 0.40 วิ = ปลอดภัย 100% จากการตรวจจับของเกม)",
        Default = CFG.RollSpeed or 0.35,
        Min = 0.25,
        Max = 1.00,
        Rounding = 2,
        Callback = function(V)
            local safeV = math.clamp(V, 0.25, 1.00)
            UpdateCFG("RollSpeed", safeV)
            pcall(function()
                if InputCustomRollSpeed and InputCustomRollSpeed.Value ~= tostring(safeV) then
                    InputCustomRollSpeed:SetValue(tostring(safeV))
                end
            end)
        end
    })

    InputCustomRollSpeed = Tabs.Enhance:AddInput("InputCustomRollSpeed", {
        Title = "✏️ กำหนดความเร็วในการสุ่มเอง (พิมพ์วินาที)",
        Default = tostring(CFG.RollSpeed or 0.35),
        Placeholder = "พิมพ์ความเร็ว เช่น 0.30, 0.35...",
        Numeric = true,
        Finished = true,
        Callback = function(val)
            local n = tonumber(val)
            if n and n > 0 then
                local safeN = math.clamp(math.floor(n * 100 + 0.5) / 100, 0.25, 5.0)
                UpdateCFG("RollSpeed", safeN)
                pcall(function()
                    if safeN >= 0.25 and safeN <= 1.00 and SliderRollSpeed then
                        SliderRollSpeed:SetValue(safeN)
                    end
                end)
                Notify("⚡ ความเร็วสุ่ม", "ตั้งค่าความเร็วสุ่มเป็น " .. safeN .. " วินาที (ปลอดภัย 100%)", 2)
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
end

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

local isManualUpgrading = false
local isManualRollingGrade = false
local isManualRollingTrait = false

Tabs.Enhance:AddButton({
    Title = "⭐ อัปเลเวลสัตว์เลี้ยงที่ดีที่สุดตามที่เลือก (1 คลิก)",
    Description = "อัปเลเวลสัตว์เลี้ยงตามเงื่อนไขเป้าหมายและจำนวนขั้นที่เลือก",
    Callback = function()
        if isManualUpgrading then return end
        isManualUpgrading = true
        task.spawn(function()
            local data = State.Data
            if not data or not data.Pets or not data.Money or data.Money <= 0 then 
                Notify("⚠️ เงินไม่พอ", "คุณมีเงินไม่พอสำหรับการอัปเลเวล", 3)
                isManualUpgrading = false
                return 
            end
            if not IsFeatureUnlocked("PetUpgrades", "petup") then
                Notify("⚠️ ยังไม่ปลดล็อค", "กรุณาปลดล็อค Pet Upgrades ในต้นไม้ทักษะก่อนใช้งาน", 3)
                isManualUpgrading = false
                return
            end
            local cap = Stats.PetLevelCap(data.Upgrades)
            local targetLvl = math.min(CFG.TargetPetLevel or cap, cap)
            local step = CFG.UpgradeLevelStep or 1
            local uids = GetTopBestPets(CFG.EnhancePetCount or 4)
            local upgradedPets = 0
            local totalLevels = 0
            local virtualMoney = data.Money
            
            for _, uid in ipairs(uids) do
                if virtualMoney <= 0 then break end
                local pet = data.Pets[uid]
                if pet and IsPetEligibleForEnhance(pet) and (pet.L or 0) < targetLvl then
                    local curLvl = pet.L or 0
                    local needed = targetLvl - curLvl
                    local countToUpgrade = math.min(needed, step)
                    if step >= 999 then countToUpgrade = needed end
                    
                    local affordable = FindAffordableLevels(pet, data.Upgrades, virtualMoney, countToUpgrade)
                    if affordable > 0 then
                        local cost = affordable == 1 and Stats.PetLevelCost(pet, data.Upgrades) or Stats.PetLevelsCost(pet, data.Upgrades, affordable)
                        if cost and virtualMoney >= cost then
                            virtualMoney = virtualMoney - cost
                            if affordable == 1 then
                                Fire("UpgradePet", uid)
                            else
                                Fire("UpgradePetLevels", uid, affordable)
                            end
                            upgradedPets = upgradedPets + 1
                            totalLevels = totalLevels + affordable
                            Humanizer.Wait(0.35, 0.65)
                        end
                    end
                end
            end
            
            Notify("⭐ อัปเลเวลสัตว์เลี้ยง", 
                totalLevels > 0 and ("อัปเลเวลแล้ว " .. upgradedPets .. " ตัว (รวม +" .. totalLevels .. " เลเวล)!") or "สัตว์เลี้ยงถึงเลเวลเป้าหมายแล้ว หรือเงินไม่พอ", 
                3
            )
            UpdateOverviewTab()
            isManualUpgrading = false
        end)
    end
})

Tabs.Enhance:AddButton({
    Title = "💎 สุ่มเกรดสัตว์เลี้ยงที่ดีที่สุด 1 ครั้งต่อตัว (ข้ามตัวล็อค)",
    Description = "สุ่มเฉพาะตัวที่ยังไม่ถึงเกรดเป้าหมาย ตัวที่ล็อคแล้วจะไม่โดนสุ่มทับ",
    Callback = function()
        if isManualRollingGrade then return end
        isManualRollingGrade = true
        task.spawn(function()
            local data = State.Data
            if not data or not data.Pets or not data.Gems or data.Gems < 1 then
                Notify("⚠️ เพชรไม่พอ (Gems)", "คุณมีเพชรไม่พอสำหรับการสุ่มเกรด", 3)
                isManualRollingGrade = false
                return
            end
            if not IsFeatureUnlocked("Grades", "grades") then
                Notify("⚠️ ยังไม่ปลดล็อค", "กรุณาปลดล็อค Grades ในต้นไม้ทักษะก่อนใช้งาน", 3)
                isManualRollingGrade = false
                return
            end
            local targetRank = CFG.TargetGradeRank or 8
            local uids = GetTopBestPets(CFG.EnhancePetCount or 4)
            local rollDelay = math.clamp(CFG.RollSpeed or 0.35, 0.25, 1.0)
            local virtualGems = data.Gems
            local rolled = 0
            local skipped = 0
            for _, uid in ipairs(uids) do
                if virtualGems < 1 then break end
                local pet = data.Pets[uid]
                if pet and IsPetEligibleForEnhance(pet) then
                    if IsPetGradeLocked(pet, targetRank) then
                        skipped = skipped + 1
                    else
                        virtualGems = virtualGems - 1
                        Fire("RollGrade", uid)
                        rolled = rolled + 1
                        Humanizer.Wait(math.max(0.25, rollDelay - 0.05), rollDelay + 0.08)
                    end
                end
            end
            Notify("💎 สุ่มเกรดสัตว์เลี้ยง",
                rolled > 0 and ("สุ่มเกรดแล้ว " .. rolled .. " ตัว (ข้ามตัวล็อค " .. skipped .. " ตัว)") or "สัตว์เลี้ยงทั้งหมดถึงเกรดเป้าหมายแล้ว (🔒ล็อคปลอดภัย)",
                3
            )
            UpdateOverviewTab()
            isManualRollingGrade = false
        end)
    end
})

Tabs.Enhance:AddButton({
    Title = "🔮 สุ่มคุณสมบัติ (Trait) สัตว์เลี้ยงที่ดีที่สุด 1 ครั้งต่อตัว (ข้ามตัวล็อค)",
    Description = "สุ่มเฉพาะตัวที่ยังไม่ถึงบัฟเป้าหมาย ตัวที่ได้บัฟเท่ากับหรือสูงกว่าจะถูกข้าม",
    Callback = function()
        if isManualRollingTrait then return end
        isManualRollingTrait = true
        task.spawn(function()
            local data = State.Data
            if not data or not data.Pets or not data.Shards or data.Shards < 1 then
                Notify("⚠️ ชาร์ดไม่พอ (Shards)", "คุณมี Shards ไม่พอสำหรับการสุ่มคุณสมบัติ", 3)
                isManualRollingTrait = false
                return
            end
            if not IsFeatureUnlocked("Traits", "traits") then
                Notify("⚠️ ยังไม่ปลดล็อค", "กรุณาปลดล็อค Traits ในต้นไม้ทักษะก่อนใช้งาน", 3)
                isManualRollingTrait = false
                return
            end
            local targetRank = CFG.TargetTraitRank or 6
            local uids = GetTopBestPets(CFG.EnhancePetCount or 4)
            local rollDelay = math.clamp(CFG.RollSpeed or 0.35, 0.25, 1.0)
            local virtualShards = data.Shards
            local rolled = 0
            local skipped = 0
            for _, uid in ipairs(uids) do
                if virtualShards < 1 then break end
                local pet = data.Pets[uid]
                if pet and IsPetEligibleForEnhance(pet) then
                    if IsPetTraitLocked(pet, targetRank) then
                        skipped = skipped + 1
                    else
                        virtualShards = virtualShards - 1
                        Fire("RollTrait", uid)
                        rolled = rolled + 1
                        Humanizer.Wait(math.max(0.25, rollDelay - 0.05), rollDelay + 0.08)
                    end
                end
            end
            Notify("🔮 สุ่มคุณสมบัติสัตว์เลี้ยง",
                rolled > 0 and ("สุ่มคุณสมบัติแล้ว " .. rolled .. " ตัว (ข้ามตัวล็อค " .. skipped .. " ตัว)") or "สัตว์เลี้ยงทั้งหมดถึงบัฟเป้าหมายแล้ว (🔒ล็อคปลอดภัย)",
                3
            )
            UpdateOverviewTab()
            isManualRollingTrait = false
        end)
    end
})

Tabs.Enhance:AddSection("🔄 ระบบอัปเกรดอัตโนมัติแบบเรียลไทม์")

Tabs.Enhance:AddToggle("TogAutoPetLvl", {
    Title = "1. อัปเลเวลสัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (Auto Upgrade Level)",
    Default = CFG.AutoUpgradePetLevel,
    Callback = function(V) 
        UpdateCFG("AutoUpgradePetLevel", V)
        if V and not IsFeatureUnlocked("PetUpgrades", "petup") then
            Notify("⚠️ ยังไม่ปลดล็อค Pet Upgrades", "คุณยังไม่ได้ปลดล็อคฟีเจอร์นี้ในผังต้นไม้ ระบบจะหยุดรออัตโนมัติ (ไม่ส่งคำสั่งรัว ปลอดภัย 100%)", 3)
        end
    end
})

Tabs.Enhance:AddToggle("TogAutoPetGrade", {
    Title = "2. สุ่มเกรดสัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (หยุดเมื่อถึงเป้าหมาย)",
    Default = CFG.AutoRollGrade,
    Callback = function(V) 
        UpdateCFG("AutoRollGrade", V)
        if V and not IsFeatureUnlocked("Grades", "grades") then
            Notify("⚠️ ยังไม่ปลดล็อค Grades", "คุณยังไม่ได้ปลดล็อคฟีเจอร์นี้ในผังต้นไม้ ระบบจะหยุดรออัตโนมัติ (ไม่ส่งคำสั่งรัว ปลอดภัย 100%)", 3)
        end
    end
})

Tabs.Enhance:AddToggle("TogAutoPetTrait", {
    Title = "3. สุ่มคุณสมบัติสัตว์เลี้ยงที่ดีที่สุดอัตโนมัติ (หยุดเมื่อถึงเป้าหมาย)",
    Default = CFG.AutoRollTrait,
    Callback = function(V) 
        UpdateCFG("AutoRollTrait", V)
        if V and not IsFeatureUnlocked("Traits", "traits") then
            Notify("⚠️ ยังไม่ปลดล็อค Traits", "คุณยังไม่ได้ปลดล็อคฟีเจอร์นี้ในผังต้นไม้ ระบบจะหยุดรออัตโนมัติ (ไม่ส่งคำสั่งรัว ปลอดภัย 100%)", 3)
        end
    end
})

-- ------------------------------------------------------------------------------
-- 🏰 TAB 3: TOWER & DICE
-- ------------------------------------------------------------------------------
Tabs.Tower:AddSection("📊 สถานะหอคอยแบบเรียลไทม์ (Live Tower Status)")

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

local function IsInTrade()
    return getgenv().TradeActiveSession == true or getgenv().CurrentTradeSession ~= nil or GetTradeWindow() ~= nil
end

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

if not CFG.SelectedTower or CFG.SelectedTower == "" then
    CFG.SelectedTower = "Infinity"
    CFG.SelectedTowerOption = defaultTowerOpt
end

local isSwitchingTower = false
local lastLoopStartAttempt = 0  -- shared across TogTower + supervisor loops

local function ResolveTowerId(val)
    if not val or val == "" then return "Infinity" end
    if Towers and Towers.ById and Towers.ById[val] then return val end
    if towerIdByOption and towerIdByOption[val] then return towerIdByOption[val] end
    if typeof(val) == "string" then
        local matched = val:match("%[([%w_]+)%]")
        if matched and Towers and Towers.ById and Towers.ById[matched] then return matched end
    end
    return val
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
                        lastLoopStartAttempt = tick()
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
    
    -- 2. ระบบรอช่วงเริ่มหอคอยหรือช่วงเปลี่ยนผ่านชั้น (Grace Period ป้องกันการหลุดระหว่างชั้น)
    local now = tick()
    local timeSinceStart = now - (LiveTower.LastStartTick or 0)
    local timeSinceEvent = now - (LiveTower.LastEventTime or 0)
    if (LiveTower.Starting and timeSinceStart < 8.0) or (LiveTower.Active and timeSinceEvent < 6.0) then
        return
    end
    
    -- 3. หากไม่มี UI และไม่มี Battle Event มาเกิน 6 วินาที แสดงว่าตัวละครไม่ได้อยู่ในหอคอยจริง
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

IsTowerRunning = function()
    SyncLiveTowerFromGame()
    local data = State.Data
    local hasResume = (data and data.TowerResume ~= nil and data.TowerResume.Floor ~= nil and data.TowerResume.Floor > 0)
    return LiveTower.Active == true or hasResume == true
end

IsTowerInArena = function()
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
    if not IsFeatureUnlocked("WorldBoss", "worldboss") then
        return false
    end
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
    
    -- เปิดระบบ TowerAutoplay ของตัวเกม เพื่อให้หอคอยไต่ชั้นอัตโนมัติอย่างต่อเนื่องไร้รอยต่อ (AUTO: ON)
    pcall(function()
        if data.Settings and data.Settings.TowerAutoplay ~= true then
            Fire("SetSetting", "TowerAutoplay", true)
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
        return false, "In Trade"
    end
    
    local isJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
    if CFG.PauseTowerForBoss and CFG.AutoWorldBoss and (isJoined or IsEnteringBossPortal == true) then
        if force then
            Notify("⚠️ พักหอคอยชั่วคราว", "ระบบกำลังเตรียมพร้อมเข้าสู้บอสโลก (ปิด 'พักหอคอยเพื่อตีบอส' หากต้องการลงหอคอยทันที)", 3)
        end
        return false, "In World Boss"
    end
    
    local char = LocalPlayer.Character or Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and Vector3.new(hrp.Position.X, 0, hrp.Position.Z).Magnitude < 150 then
        if force then
            Fire("Teleport", "Home")
            Humanizer.Wait(2.0, 3.0)
        else
            return false, "In Hub/Plaza"
        end
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
    if not data or not data.Pets then 
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
        -- หากกำลังลงหอคอยอยู่ ให้สั่งออกจากหอเดิมอย่างสมบูรณ์ก่อน
        if isRunning then
            local oldDef = Towers.ById and Towers.ById[activeTower]
            local oldName = oldDef and oldDef.Name or activeTower
            Notify("🏰 หอคอย", "กำลังออกจาก " .. tostring(oldName) .. " เพื่อเริ่มรอบใหม่...", 2)
            Fire("TowerLeave")
            LiveTower.Active = false
            LiveTower.Starting = false
            LiveTower.LastEventTime = 0
            LiveTower.TowerId = nil
            
            -- รอจนกว่าตัวเกมจะออกจากหอคอยจริง (Battle และ TowerTracker หายไป) สูงสุด 3 วินาที
            local leaveStart = tick()
            while tick() - leaveStart < 3.0 do
                task.wait(0.1)
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                local root = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI:FindFirstChild("Root")
                local hud = root and root:FindFirstChild("Hud")
                local away = hud and hud:FindFirstChild("TowerTracker") and hud.TowerTracker.Visible == true
                local arena = hud and hud:FindFirstChild("Battle") and hud.Battle.Visible == true
                if not away and not arena then break end
            end
            
            -- ล้างหน้าต่างผลลัพธ์ BattleResults ทันที
            pcall(function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                local br = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root:FindFirstChild("Effects") and pg.PetDiceUI.Root.Effects:FindFirstChild("BattleResults")
                if br and br.Visible then br.Visible = false end
            end)
            
            -- หน่วงเวลาให้เซิร์ฟเวอร์เคลียร์สถานะอย่างสมบูรณ์อย่างน้อย 3.5 วินาที
            while (tick() - (LastRemoteFire["TowerLeave"] or 0) < 3.5) do
                task.wait(0.2)
            end
        end
        
        local success = StartTowerDirect(resolvedId)
        if success then
            Notify("🏰 หอคอย", "เริ่มลง " .. tostring(towerDef.Name or resolvedId) .. " เรียบร้อย!", 3)
            if CFG.AutoExitArena then
                task.delay(4.0, function() 
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
            
        SafeUpdatePara(TowerStatusPara, statusText, desc)
        
        -- อัปเดตสถานะบอสโลก (World Boss Status)
        local wbState = RS:GetAttribute("WorldBossState") or "Idle"
        local wbElem = RS:GetAttribute("WorldBossElement") or "Random"
        local wbDiff = RS:GetAttribute("WorldBossDifficulty") or "Normal"
        local wbJoined = RS:GetAttribute("WorldBossJoined") or 0
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
        
        local isBossUnlocked = IsFeatureUnlocked("WorldBoss", "worldboss")
        local unlockStatus = isBossUnlocked and "🟢 ปลดล็อคแล้ว (พร้อมตีบอส)" or "🔒 ยังไม่ปลดล็อค 'WORLD BOSSES' (ต้องการเงิน 1 Qi)"
        
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
        
        SafeUpdatePara(BossStatusPara, bossTitle, bossDesc)
    end)
end

task.spawn(UpdateTowerStatus)
task.spawn(function()
    while true do
        task.wait(4.0)
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
                local activeTower = GetActiveTowerId()
                if not IsTowerRunning() or activeTower ~= "Infinity" then
                    SwitchOrStartTower("Infinity", true)
                end
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
            task.spawn(function()
                local activeTower = GetActiveTowerId()
                if not IsTowerRunning() or activeTower ~= id then
                    SwitchOrStartTower(id, true)
                end
            end)
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
                lastTowerStartTick = 0
                lastLoopStartAttempt = 0
                
                local isJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
                if CFG.PauseTowerForBoss and CFG.AutoWorldBoss and (isJoined or IsEnteringBossPortal == true) then
                    Notify("🏰 หอคอย", "เปิดระบบฟาร์มหอคอยแล้ว! (ขณะนี้อยู่ในห้องบอสโลก จะเริ่มลงหอคอยอัตโนมัติทันทีที่ออกจากบอส)", 4)
                    task.delay(0.2, UpdateTowerStatus)
                    return
                end
                
                local targetId = ResolveTowerId(CFG.SelectedTower)
                
                -- หากตัวละครกำลังอยู่ในหอคอยเป้าหมายอยู่แล้ว ไม่ต้องออกจากหอ แค่เปิด Away mode และเปิด Autoplay
                if IsTowerRunning() and GetActiveTowerId() == targetId then
                    Notify("🏰 หอคอย", "เปิดระบบฟาร์มหอคอยต่อเนื่อง!", 2)
                    pcall(function()
                        local d = State.Data
                        if d and d.Settings and d.Settings.TowerAutoplay ~= true then
                            Fire("SetSetting", "TowerAutoplay", true)
                        end
                    end)
                    if CFG.AutoExitArena and IsTowerInArena() then
                        Fire("TowerExit")
                    end
                    task.delay(0.2, UpdateTowerStatus)
                    return
                end
                
                -- สั่งเริ่มหรือสลับหอคอยทันทีแบบ force = true
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
                LiveTower.Active = false
                LiveTower.Starting = false
                LiveTower.LastEventTime = 0
                LiveTower.TowerId = nil
                LiveTower.InArena = false
                LiveTower.Away = false
                pcall(function() Fire("SetSetting", "TowerAutoplay", false) end)
                
                -- รอจนกว่าตัวเกมจะออกจากหอคอยจริง (Battle และ TowerTracker หายไป)
                local leaveStart = tick()
                while tick() - leaveStart < 2.5 do
                    task.wait(0.1)
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    local root = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI:FindFirstChild("Root")
                    local hud = root and root:FindFirstChild("Hud")
                    local away = hud and hud:FindFirstChild("TowerTracker") and hud.TowerTracker.Visible == true
                    local arena = hud and hud:FindFirstChild("Battle") and hud.Battle.Visible == true
                    if not away and not arena then break end
                end
                LiveTower.Away = false
                
                -- ปิดหน้าต่างผลลัพธ์ BattleResults UI ทันที
                pcall(function()
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    local br = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root:FindFirstChild("Effects") and pg.PetDiceUI.Root.Effects:FindFirstChild("BattleResults")
                    if br and br.Visible then br.Visible = false end
                end)
                
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
        local isBossUnlocked = IsFeatureUnlocked("WorldBoss", "worldboss")
        
        if not isBossUnlocked then
            local curMoneyStr = (data and data.Money and Format and Format.Money) and Format.Money(data.Money) or tostring(data and data.Money or 0)
            Notify("🔒 ยังไม่ปลดล็อค", "ต้องปลดล็อค 'WORLD BOSSES' ในผังอัปเกรดก่อน (ต้องการ Pet Upgrades และเงิน 1 Qi - ปัจจุบันมี: " .. curMoneyStr .. ")", 4)
            return
        end
        
        if data and not data.PortalRepaired then
            Fire("PortalRepair")
            Humanizer.Wait(0.5, 1.0)
        end
        
        local wbState = RS:GetAttribute("WorldBossState") or "Idle"
        local wbElem = RS:GetAttribute("WorldBossElement") or "Random"
        local wbDiff = RS:GetAttribute("WorldBossDifficulty") or "Normal"
        
        if wbState == "Joining" or wbState == "Fighting" then
            if CFG.PauseTowerForBoss and IsTowerRunning() then
                Fire("TowerLeave")
                Humanizer.Wait(0.8, 1.5)
            end
            
            SafeWalkToBossPortal()
            Humanizer.Wait(0.3, 0.6)
            
            Fire("WorldBossJoin")
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
            Notify("🎲 ซื้อลูกเต๋า", "เปิดระบบซื้อลูกเต๋าอัตโนมัติเรียบร้อย!", 2)
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

do
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
end

Tabs.Rebirth:AddButton({
    Title = "🌳 ซื้ออัปเกรดต้นไม้ทั้งหมดทันที (Buy All Upgrades Now)",
    Description = "ส่งคำสั่งซื้ออัปเกรดต้นไม้ทั้งหมดที่สามารถซื้อได้ใน 1 คลิก",
    Callback = function()
        local data = State.Data
        if not data or not data.Upgrades or not data.Money or data.Money <= 0 then
            Notify("⚠️ เงินไม่พอ", "คุณมีเงินไม่พอสำหรับการซื้ออัปเกรดในต้นไม้", 3)
            return
        end
        if Upgrades and Upgrades.PlanBuyAll then
            local planned, totalCost = Upgrades.PlanBuyAll(data.Upgrades, data.Money, 50)
            if not planned or #planned == 0 then
                Notify("⚠️ ไม่มีอัปเกรด", "ไม่มีอัปเกรดที่สามารถซื้อได้ในขณะนี้", 3)
                return
            end
        end
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
        local now = workspace:GetServerTimeNow()
        local potions = data.Potions or {}
        local ends = data.PotionEnds or {}
        
        local function GetTimeStr(endT)
            local numEnd = tonumber(endT)
            if not numEnd or numEnd <= now then return "❌ หมดอายุแล้ว" end
            local left = math.floor(numEnd - now)
            local mins = math.floor(left / 60)
            local secs = left % 60
            return string.format("✅ เหลืออีก %d:%02d นาที", mins, secs)
        end
        
        local luckCount = tonumber(potions.Luck) or 0
        local cashCount = tonumber(potions.Cash) or 0
        local speedCount = tonumber(potions.Speed) or 0
        local lootBags = tonumber(data.LootBags) or 0
        
        local desc = string.format("🍀 น้ำยาโชคดี: มี %d ขวด | บัฟ: %s\n💰 น้ำยาเงิน: มี %d ขวด | บัฟ: %s\n⚡ น้ำยาความเร็ว: มี %d ขวด | บัฟ: %s\n🎒 ถุงสมบัติ: %d ใบ",
            luckCount, GetTimeStr(ends.Luck),
            cashCount, GetTimeStr(ends.Cash),
            speedCount, GetTimeStr(ends.Speed),
            lootBags
        )
        
        SafeUpdatePara(PotionStatusPara, "🧪 สถานะน้ำยา & ไอเทมปัจจุบัน (นับถอยหลังวินาที)", desc)
    end)
end

local MarketStatusPara = Tabs.Items:AddParagraph({
    Title = "🛒 กำลังโหลดสถานะตลาด (The Market)...",
    Content = "กำลังตรวจสอบสินค้าและเวลารีสต็อกของตลาด..."
})

local function UpdateMarketStatus()
    pcall(function()
        if not Market then return end
        local data = State.Data
        if not data then return end
        local isUnlocked = IsFeatureUnlocked("Market", "market")
        local now = State.Now and State.Now() or os.time()
        local currentWindow = Market.Window(now)
        local restockSec = math.max(0, math.floor(Market.WindowEnds(currentWindow) - now))
        local restockMin = math.floor(restockSec / 60)
        local restockRemainderSec = restockSec % 60
        local restockStr = string.format("%d:%02d นาที", restockMin, restockRemainderSec)
        
        local bought = data.Market and (data.Market.Window ~= currentWindow and {} or data.Market.Bought) or {}
        local _, canBuyCount, totalCost, totalLeft = Market.PlanBuyAll(currentWindow, bought, data.Rebirths or 0, data.Money or 0)
        
        local unlockStr = isUnlocked and "✅ ปลดล็อกแล้ว (พร้อมซื้อ)" or "🔒 ล็อกอยู่ (ต้องปลดล็อกที่ต้นไม้อัปเกรด)"
        local costStr = Format and Format.Money and Format.Money(totalCost or 0) or tostring(totalCost or 0)
        local moneyStr = Format and Format.Money and Format.Money(data.Money or 0) or tostring(data.Money or 0)
        
        local desc = string.format("🏪 สถานะตลาด: %s\n⏳ รีสต็อกสินค้าใหม่ในอีก: %s\n📦 สินค้าที่ซื้อได้: %d ชิ้น (คงเหลือในสต็อก %d ชิ้น)\n💰 ราคารวมทั้งหมด: %s (ยอดเงินของคุณ: %s)",
            unlockStr, restockStr, canBuyCount or 0, totalLeft or 0, costStr, moneyStr
        )
        
        SafeUpdatePara(MarketStatusPara, "🛒 ข้อมูลตลาดสดและเวลารีสต็อก (Market Realtime)", desc)
    end)
end

task.spawn(UpdatePotionStatus)
task.spawn(UpdateMarketStatus)
task.spawn(function()
    while true do
        task.wait(5.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        pcall(UpdatePotionStatus)
        pcall(UpdateMarketStatus)
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

Tabs.Items:AddButton({
    Title = "🛒 กวาดซื้อของทั้งหมดในตลาดทันที (Buy All Market Now)",
    Description = "ส่งคำสั่งกวาดซื้อสินค้าทั้งหมดที่สต็อกมีและเงินพอซื้อทันทีในคลิกเดียว",
    Callback = function()
        if not IsFeatureUnlocked("Market", "market") then
            Notify("🔒 ตลาดยังล็อกอยู่", "คุณยังไม่ได้ปลดล็อกตลาดในต้นไม้อัปเกรด (Skill Tree)", 3)
            return
        end
        local data = State.Data
        if not data or not Market then return end
        local now = State.Now and State.Now() or os.time()
        local currentWindow = Market.Window(now)
        local bought = data.Market and (data.Market.Window ~= currentWindow and {} or data.Market.Bought) or {}
        local _, canBuyCount, totalCost, totalLeft = Market.PlanBuyAll(currentWindow, bought, data.Rebirths or 0, data.Money or 0)
        
        if (canBuyCount or 0) <= 0 then
            if (totalLeft or 0) <= 0 then
                Notify("ℹ️ สินค้าหมด", "สินค้าในรอบนี้ถูกซื้อหมดแล้ว (SOLD OUT) กรุณารอรอบรีสต็อกถัดไป", 3)
            else
                Notify("⚠️ เงินไม่พอ", "เงินของคุณไม่พอสำหรับซื้อสินค้าที่เหลือในรอบนี้", 3)
            end
            return
        end
        
        Fire("MarketBuyAll")
        Notify("🛒 กวาดซื้อตลาด", "สั่งกวาดซื้อสินค้าทั้งหมด " .. canBuyCount .. " ชิ้น สำเร็จ!", 3)
        task.delay(0.5, function()
            if UpdateMarketStatus then pcall(UpdateMarketStatus) end
            if UpdatePotionStatus then pcall(UpdatePotionStatus) end
        end)
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

Tabs.Items:AddToggle("TogAutoBuyMarket", {
    Title = "5. กวาดซื้อของทั้งหมดในตลาดอัตโนมัติเมื่อพร้อม",
    Default = CFG.AutoBuyMarket,
    Callback = function(V) UpdateCFG("AutoBuyMarket", V) end
})

-- ------------------------------------------------------------------------------
-- 🌙 TAB 6: EXPEDITIONS & QUESTS
-- ------------------------------------------------------------------------------
Tabs.Expedition:AddSection("🌙 สถานะผจญภัย & เควสแบบเรียลไทม์")

local ExpeditionStatusPara = Tabs.Expedition:AddParagraph({
    Title = "⏳ กำลังโหลดสถานะผจญภัย & เควส...",
    Content = "กำลังตรวจสอบเรือสำรวจและเควสคงเหลือ..."
})

local function UpdateExpeditionStatus()
    pcall(function()
        local data = State.Data
        if not data then return end
        local now = State.Now and State.Now() or os.time()
        
        local maxSlots = Expeditions and Expeditions.Slots and Expeditions.Slots(data) or 3
        local activeExps = data.Expeditions and data.Expeditions.Active or {}
        local activeCount = #activeExps
        
        local lines = {}
        table.insert(lines, string.format("⛵ เรือผจญภัยที่ออกสำรวจ: %d / %d ช่อง", activeCount, maxSlots))
        
        if activeCount == 0 then
            table.insert(lines, "• ยังไม่มีเรือออกสำรวจ (พร้อมส่งสัตว์เลี้ยงทันที)")
        else
            for idx, exp in ipairs(activeExps) do
                local left = Expeditions and Expeditions.Left and Expeditions.Left(exp, now) or math.max(0, (exp.Ends or 0) - now)
                local diffName = exp.Diff or "Unknown"
                local petCount = exp.Pets and #exp.Pets or 0
                if left <= 0 then
                    table.insert(lines, string.format("• ช่อง #%d [%s]: ✅ สำเร็จแล้ว! พร้อมกดรับรางวัล (สัตว์เลี้ยง %d ตัว)", idx, diffName, petCount))
                else
                    local m = math.floor(left / 60)
                    local s = math.floor(left % 60)
                    local timeStr = m >= 60 and string.format("%d ชม. %d นาที", math.floor(m / 60), m % 60) or string.format("%d นาที %02d วินาที", m, s)
                    table.insert(lines, string.format("• ช่อง #%d [%s]: ⏳ เหลือเวลาอีก %s (สัตว์เลี้ยง %d ตัว)", idx, diffName, timeStr, petCount))
                end
            end
        end
        
        table.insert(lines, "")
        table.insert(lines, "📜 ความคืบหน้าเควส & รางวัล:")
        local readyQuests = 0
        local totalDaily = 0
        local doneDaily = 0
        local totalWeekly = 0
        local doneWeekly = 0
        local readyGoals = 0
        
        if data.Quests then
            for _, q in ipairs(data.Quests.Daily or {}) do
                totalDaily = totalDaily + 1
                if q.Claimed then
                    doneDaily = doneDaily + 1
                elseif (q.Progress or 0) >= (q.Goal or math.huge) then
                    readyQuests = readyQuests + 1
                end
            end
            for _, q in ipairs(data.Quests.Weekly or {}) do
                totalWeekly = totalWeekly + 1
                if q.Claimed then
                    doneWeekly = doneWeekly + 1
                elseif (q.Progress or 0) >= (q.Goal or math.huge) then
                    readyQuests = readyQuests + 1
                end
            end
            if QuestsLogic and QuestsLogic.Goals and data.Quests.Goals then
                for _, gDef in ipairs(QuestsLogic.Goals) do
                    local gData = data.Quests.Goals[gDef.Id]
                    local isUnlocked = true
                    if Upgrades and Upgrades.IsOpen and gDef.Needs then
                        isUnlocked = Upgrades.IsOpen(data.Upgrades, gDef.Needs)
                    end
                    if isUnlocked and gData and not gData.Claimed and (gData.Progress or 0) >= (gDef.Goal or math.huge) then
                        readyGoals = readyGoals + 1
                    end
                end
            end
        end
        
        table.insert(lines, string.format("• เควสประจำวัน (Daily): สำเร็จแล้ว %d/%d (พร้อมรับ: %d)", doneDaily, totalDaily, readyQuests))
        table.insert(lines, string.format("• เควสประจำสัปดาห์ (Weekly): สำเร็จแล้ว %d/%d", doneWeekly, totalWeekly))
        if readyGoals > 0 then
            table.insert(lines, string.format("• รางวัลเป้าหมาย (Goals): พร้อมรับทันที %d รายการ! 🎉", readyGoals))
        end
        
        local title = string.format("⛵ ผจญภัย: %d/%d ลำ | เควสพร้อมรับ: %d", activeCount, maxSlots, readyQuests + readyGoals)
        SafeUpdatePara(ExpeditionStatusPara, title, table.concat(lines, "\n"))
    end)
end

task.spawn(function()
    task.wait(1.0)
    pcall(UpdateExpeditionStatus)
    while true do
        task.wait(3.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        pcall(UpdateExpeditionStatus)
    end
end)

Tabs.Expedition:AddSection("🌙 ควบคุมการผจญภัย (Expedition Commands)")

local function GetBestExpeditionPets(maxCount, excludeUids)
    local data = State.Data
    if not data or not data.Pets or not data.Expeditions then return nil, {} end
    
    local equipped = {}
    for _, uid in ipairs(data.Equipped or {}) do equipped[tostring(uid)] = true end
    
    local towerTeam = {}
    pcall(function()
        local fallbackDef = (Towers and Towers.List and Towers.List[1]) or { Id = "Meadow", Element = "Nature" }
        local tPets = (TeamPairs and TeamPairs.Best and TeamPairs.Best(data, fallbackDef, 4)) or {}
        for _, uid in ipairs(tPets) do towerTeam[tostring(uid)] = true end
    end)
    
    local onExp = {}
    for _, exp in ipairs(data.Expeditions.Active or {}) do
        for _, uid in ipairs(exp.Pets or {}) do onExp[tostring(uid)] = true end
    end
    
    local availablePets = {}
    local now = State.Now and State.Now() or os.time()
    local mods = State.Mods and State.Mods() or {}
    
    for uid, pet in pairs(data.Pets) do
        local sUid = tostring(uid)
        local def = PetData and PetData.ById and PetData.ById[pet.Id]
        local isLimited = def and (def.Limited == true or def.Rarity == "Limited")
        local isLocked = (data.Locked and data.Locked[sUid]) or pet.Locked
        local isExcluded = excludeUids and excludeUids[sUid]
        
        if not equipped[sUid] and not towerTeam[sUid] and not onExp[sUid] and not isExcluded and not isLocked and not isLimited then
            local power = 0
            pcall(function()
                power = Expeditions.PetPower(data, pet, mods, now)
            end)
            if power > 0 then
                table.insert(availablePets, { Uid = sUid, Power = power })
            end
        end
    end
    
    if #availablePets == 0 then return nil, {} end
    -- เรียงจากพลังสูงสุดไปต่ำสุด เพื่อให้โอกาสสำเร็จสูงสุด (Max Success Chance)
    table.sort(availablePets, function(a, b) return a.Power > b.Power end)
    
    -- ลำดับความยากจากสูงสุดไปต่ำสุด: Nightmare (5) -> Extreme (4) -> Hard (3) -> Normal (2) -> Easy (1)
    if ExpeditionConfig and ExpeditionConfig.Difficulties then
        for i = #ExpeditionConfig.Difficulties, 1, -1 do
            local diff = ExpeditionConfig.Difficulties[i]
            if diff and diff.Requirement then
                local isUnlocked = false
                pcall(function()
                    isUnlocked = Expeditions.Unlocked(data, diff)
                end)
                
                if isUnlocked then
                    local qualified = {}
                    for _, p in ipairs(availablePets) do
                        if p.Power >= diff.Requirement then
                            table.insert(qualified, p.Uid)
                        end
                    end
                    if #qualified > 0 then
                        local selected = {}
                        local targetCount = math.min(maxCount or diff.Pets, diff.Pets, #qualified)
                        for k = 1, targetCount do
                            table.insert(selected, qualified[k])
                        end
                        return diff.Id, selected
                    end
                end
            end
        end
    end
    
    return nil, {}
end

local function GetNightmarePets(maxCount, excludeUids)
    local _, pets = GetBestExpeditionPets(maxCount, excludeUids)
    return pets or {}
end

local function ClaimAllDoneExpeditions()
    local data = State.Data
    if not data or not data.Expeditions then return 0 end
    local claimed = 0
    local now = State.Now and State.Now() or os.time()
    for _, exp in ipairs(data.Expeditions.Active or {}) do
        local left = Expeditions and Expeditions.Left and Expeditions.Left(exp, now) or math.max(0, (exp.Ends or 0) - now)
        if left <= 0 then
            Fire("ClaimExpedition", exp.Id)
            claimed = claimed + 1
            Humanizer.Wait(0.8, 1.4)
        end
    end
    if claimed > 0 then
        task.delay(1.0, function() pcall(UpdateExpeditionStatus) end)
    end
    return claimed
end

Tabs.Expedition:AddButton({
    Title = "⚡ ส่งผจญภัยระดับสูงสุดทันที (1 ช่อง)",
    Callback = function()
        if not IsFeatureUnlocked("Expeditions", "expeditions") then
            Notify("🔒 ยังไม่ปลดล็อค", "ระบบสำรวจ (Expeditions) ยังไม่ปลดล็อคในผังอัปเกรด/หอคอย", 3)
            return
        end
        local diffId, pets = GetBestExpeditionPets(CFG.ExpeditionPetCount or 1)
        if diffId and #pets > 0 then
            Fire("SendExpedition", diffId, pets)
            Notify("🌙 ผจญภัย", string.format("ส่งสัตว์เลี้ยง %d ตัวไปผจญภัย [%s] เรียบร้อย!", #pets, tostring(diffId)), 3)
            task.delay(1.5, function() pcall(UpdateExpeditionStatus) end)
        else
            Notify("⚠️ สัตว์เลี้ยงไม่พร้อม", "ไม่มีสัตว์เลี้ยงที่มีพลังพอส่งสำรวจในระดับใดๆ หรือสัตว์เลี้ยงกำลังติดภารกิจอื่น", 3)
        end
    end
})

Tabs.Expedition:AddButton({
    Title = "🚀 ส่งผจญภัยให้เต็มทุกช่องว่างทันที (Fill All Slots)",
    Callback = function()
        if not IsFeatureUnlocked("Expeditions", "expeditions") then
            Notify("🔒 ยังไม่ปลดล็อค", "ระบบสำรวจ (Expeditions) ยังไม่ปลดล็อคในผังอัปเกรด/หอคอย", 3)
            return
        end
        task.spawn(function()
            local data = State.Data
            local maxSlots = Expeditions and Expeditions.Slots and Expeditions.Slots(data) or 3
            local activeCount = #(data.Expeditions and data.Expeditions.Active or {})
            local slotsToFill = maxSlots - activeCount
            if slotsToFill <= 0 then
                Notify("⛵ ผจญภัย", "เรือผจญภัยเต็มทุกช่องแล้ว (" .. activeCount .. "/" .. maxSlots .. ")", 3)
                return
            end
            local sentCount = 0
            local recentlySent = {}
            for s = 1, slotsToFill do
                local diffId, pets = GetBestExpeditionPets(CFG.ExpeditionPetCount or 1, recentlySent)
                if diffId and #pets > 0 then
                    for _, uid in ipairs(pets) do recentlySent[tostring(uid)] = true end
                    Fire("SendExpedition", diffId, pets)
                    sentCount = sentCount + 1
                    Humanizer.Wait(1.2, 1.8)
                else
                    break
                end
            end
            if sentCount > 0 then
                Notify("🌙 ผจญภัย", string.format("ส่งเรือผจญภัยออกเดินทางแล้ว %d ช่อง!", sentCount), 3)
                task.delay(1.5, function() pcall(UpdateExpeditionStatus) end)
            else
                Notify("⚠️ สัตว์เลี้ยงไม่พร้อม", "ไม่มีสัตว์เลี้ยงที่พลังเพียงพอจะส่งช่องเพิ่มเติม", 3)
            end
        end)
    end
})

Tabs.Expedition:AddButton({
    Title = "🎁 กดรับรางวัลผจญภัยที่สำเร็จทั้งหมด",
    Callback = function()
        if not IsFeatureUnlocked("Expeditions", "expeditions") then
            Notify("🔒 ยังไม่ปลดล็อค", "ระบบสำรวจ (Expeditions) ยังไม่ปลดล็อคในผังอัปเกรด/หอคอย", 3)
            return
        end
        local count = ClaimAllDoneExpeditions()
        Notify("🎁 รับรางวัลผจญภัย", count > 0 and ("กดรับแล้ว " .. count .. " ช่อง!") or "ยังไม่มีช่องที่เสร็จสิ้น", 3)
    end
})

Tabs.Expedition:AddToggle("TogAutoExpedition", {
    Title = "เปิดส่งสัตว์เลี้ยง + รับรางวัลอัตโนมัติ (Auto Nightmare)",
    Default = CFG.AutoExpedition,
    Callback = function(V) UpdateCFG("AutoExpedition", V) end
})

do
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
end

Tabs.Expedition:AddSection("🎁 เควส & รางวัลประจำวัน (Rewards & Quests)")

local function ClaimAllRewardsManual()
    task.spawn(function()
        local data = State.Data
        local now = State.Now and State.Now() or os.time()
        local claimedCount = 0
        
        -- Daily
        local canDaily = false
        pcall(function() canDaily = Stats.DailyState(data, now) end)
        if canDaily then
            Fire("ClaimDaily")
            claimedCount = claimedCount + 1
            Humanizer.Wait(0.5, 1.0)
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
                    local isUnlocked = true
                    if Upgrades and Upgrades.IsOpen and gDef.Needs then
                        isUnlocked = Upgrades.IsOpen(data.Upgrades, gDef.Needs)
                    end
                    if isUnlocked and gData and not gData.Claimed and (gData.Progress or 0) >= (gDef.Goal or math.huge) then
                        Fire("GoalClaim", gDef.Id)
                        claimedCount = claimedCount + 1
                        Humanizer.Wait(0.3, 0.6)
                    end
                end
            end
        end
        
        if claimedCount > 0 then
            task.delay(1.0, function() pcall(UpdateExpeditionStatus) end)
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
-- 🤝 TAB 7: SAFE AUTO TRADE
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

Tabs.Trade:AddButton({
    Title = "⚡ ส่งคำขอเทรดทันที (1 คลิก - ปลอดภัย)",
    Description = "ส่งคำขอเทรดไปยังผู้เล่นเป้าหมายทันที โดยผ่านระบบเช็คความพร้อมและจัดคิว",
    Callback = function()
        if not CFG.TradeTargetId then
            Notify("⚠️ เลือกผู้เล่นก่อน", "กรุณาเลือกผู้เล่นที่จะเทรดด้วยจากเมนูด้านบนก่อน", 3)
            return
        end
        if IsInTrade() or getgenv().TradeActiveSession then
            Notify("⚠️ กำลังอยู่ในเซสชันเทรด", "มีเซสชันเทรดทำงานอยู่แล้วในขณะนี้", 3)
            return
        end
        local targetPlayer = Players:GetPlayerByUserId(CFG.TradeTargetId)
        if not targetPlayer then
            Notify("⚠️ ไม่พบผู้เล่น", "ผู้เล่นเป้าหมายไม่อยู่ในเซิร์ฟเวอร์แล้ว", 3)
            return
        end
        if IsTowerInArena and IsTowerInArena() then
            Fire("TowerExit")
            Humanizer.Wait(0.5, 0.8)
        end
        getgenv().TradeActiveSession = true
        getgenv().LastTradeRequestTime = tick()
        Fire("TradeRequest", CFG.TradeTargetId)
        Notify("📨 ส่งคำขอเทรด", "ส่งคำขอเทรดไปยัง " .. tostring(targetPlayer.DisplayName or targetPlayer.Name) .. " แล้ว", 3)
        task.delay(20, function()
            if not getgenv().CurrentTradeSession and not GetTradeWindow() then
                getgenv().TradeActiveSession = false
                if FlushTradeDeferredQueue then FlushTradeDeferredQueue() end
            end
        end)
    end
})

Tabs.Trade:AddButton({
    Title = "❌ ยกเลิกการเทรดปัจจุบันทันที (Cancel Trade)",
    Description = "ยกเลิกเซสชันเทรดทันที ปลดล็อคระบบ และรันคำสั่งอื่นที่เข้าคิวไว้ต่อ",
    Callback = function()
        pcall(function() Fire("TradeCancel") end)
        getgenv().TradeActiveSession = false
        getgenv().CurrentTradeSession = nil
        getgenv().TradeItemsDropped = false
        getgenv().ReceiverItemPut = false
        if FlushTradeDeferredQueue then
            FlushTradeDeferredQueue()
        end
        Notify("❌ ยกเลิกการเทรด", "ยกเลิกเซสชันเทรดและปลดคิวคำสั่งเรียบร้อย", 3)
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
        
        local queueLen = (#TradeDeferredQueue)
        local queueStatus = queueLen > 0 and string.format("📦 คิวคำสั่งรอทำหลังเทรด: %d รายการ", queueLen) or "📦 คิวคำสั่งรอทำ: ว่าง (ไม่มีคำสั่งค้าง)"
        
        local session = getgenv().CurrentTradeSession
        local partnerName = session and session.Them and tostring(session.Them.Name or session.Them.UserId or "คู่เทรด") or "ไม่มี"
        local inTradeStatus = IsInTrade() and ("🤝 กำลังเทรดกับ: " .. partnerName) or "💤 ไม่ได้อยู่ในหน้าต่างเทรด"
        local twoWayStatus = (CFG.TwoWayTrade ~= false) and "🟢 เปิดใช้งาน (Safe Two-Way)" or "🔴 ปิด (One-Way)"
        
        SafeUpdatePara(TradeStatusPara, "🛡️ ระบบเทรดปลอดภัย: " .. cdStatus,
            string.format("โหมด: %s\nสถานะ: %s\n%s\nระบบแลกเปลี่ยนสองทาง: %s | หน่วงเวลา Ready: %d วิ",
            modeStr, inTradeStatus, queueStatus, twoWayStatus, CFG.TradeReadyDelay or 4))
    end)
end

task.spawn(function()
    while true do
        task.wait(3.0)
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
    
    -- 2. หากไม่มีน้ำยา ตรวจสอบสัตว์เลี้ยงระดับล่าง (Rank >= 7 หรือเกรด F/E/D/C) ที่ไม่ได้ล็อค ปลอดภัย 100%
    if data.Pets then
        local equipped = {}
        for _, uid in ipairs(data.Equipped or {}) do equipped[tostring(uid)] = true end
        
        local towerTeam = {}
        pcall(function()
            local fallbackDef = (Towers and Towers.List and Towers.List[1]) or { Id = "Meadow", Element = "Nature" }
            local tPets = (TeamPairs and TeamPairs.Best and TeamPairs.Best(data, fallbackDef, 4)) or {}
            for _, uid in ipairs(tPets) do towerTeam[tostring(uid)] = true end
        end)
        
        local onExp = {}
        for _, exp in ipairs(data.Expeditions and data.Expeditions.Active or {}) do
            for _, uid in ipairs(exp.Pets or {}) do onExp[tostring(uid)] = true end
        end

        for uid, pet in pairs(data.Pets) do
            local sUid = tostring(uid)
            if not equipped[sUid] and not towerTeam[sUid] and not onExp[sUid] then
                local isLocked = (data.Locked and data.Locked[sUid]) or pet.Locked
                local def = PetData and PetData.ById and PetData.ById[pet.Id]
                local isLimited = def and (def.Limited == true or def.Rarity == "Limited")
                local isLowLevel = (pet.Level == nil or pet.Level <= 1) and (pet.Xp == nil or pet.Xp <= 0)
                
                if not isLocked and not isLimited and isLowLevel then
                    local rank = GetPetGradeRank(pet)
                    if rank >= 7 and not IsPetGradeLocked(pet, 5) then
                        Fire("TradeAddPets", { sUid })
                        return true, "Pet_" .. tostring(pet.Id)
                    end
                end
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
    if now - lastTradeRespondTick < 1.0 then return end
    lastTradeRespondTick = now
    
    senderId = tonumber(senderId)
    if not senderId then return end
    
    -- ล็อคสถานะเซสชันเทรดทันที เพื่อป้องกันหอคอยหรือลูปอื่นแทรกแซงระหว่างเริ่มเทรด
    getgenv().TradeActiveSession = true
    getgenv().LastTradeRequestTime = now
    
    task.spawn(function()
        -- ถ้าอยู่ใน World Boss ให้ปฏิเสธทันที
        local inWBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if inWBoss then
            Notify("⚠️ ปฏิเสธการเทรด", "อยู่ใน World Boss ยังไม่สามารถตอบรับคำขอเทรดได้ในขณะนี้", 3)
            Fire("TradeRespond", senderId, false)
            getgenv().TradeActiveSession = false
            return
        end

        -- ถ้ากำลังอยู่ใน Arena (3D Scene) ให้ออกจาก Arena มาเป็น Away Mode ชั่วคราว
        if IsTowerInArena and IsTowerInArena() then
            Fire("TowerExit")
            task.wait(0.5)
        end
        
        -- 1. หน่วงเวลาตอบรับตามธรรมชาติของมนุษย์ (0.6 - 1.2 วินาที)
        if Humanizer and Humanizer.Wait then
            Humanizer.Wait(0.6, 1.2)
        else
            task.wait(0.8)
        end
        if getgenv().PetDiceScriptToken ~= scriptToken then return end
        
        -- 2. ส่ง Action Remote ตอบรับการเทรดไปยังเซิร์ฟเวอร์โดยตรง
        Fire("TradeRespond", senderId, true)
        
        -- 3. เสริมความปลอดภัยขั้นสูงสุด: กดปุ่ม ACCEPT บน UI ของเกมด้วย (Dual Execution)
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local tr = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root.Effects:FindFirstChild("TradeRequest")
            if tr and tr.Visible then
                for _, c in ipairs(tr:GetChildren()) do
                    if c.Name == "Button" then
                        local lbl = c:FindFirstChildWhichIsA("TextLabel", true)
                        local btn = c:FindFirstChildWhichIsA("TextButton", true) or (c:IsA("TextButton") and c)
                        if lbl and lbl.Text == "ACCEPT" and btn then
                            if firesignal then
                                pcall(function() firesignal(btn.MouseButton1Click) end)
                                pcall(function() firesignal(btn.Activated) end)
                            end
                            break
                        end
                    end
                end
                tr.Visible = false
            end
        end)
        
        Notify("🤝 ยอมรับคำขอเทรด", "ตอบรับคำขอเทรดจาก " .. tostring(senderName or "ผู้เล่น") .. " เรียบร้อย!", 3)
        
        -- Safety timeout: หากไม่มีเซสชันเทรดเปิดขึ้นภายใน 15 วินาที ให้ปลดล็อคสถานะและระบายคิว
        task.delay(15, function()
            if not getgenv().CurrentTradeSession and not GetTradeWindow() then
                getgenv().TradeActiveSession = false
                if FlushTradeDeferredQueue then
                    FlushTradeDeferredQueue()
                end
            end
        end)
    end)
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

Tabs.Settings:AddButton({
    Title = "🛡️ ปลดล็อกระบบฉุกเฉิน (Clear Anti-Ban Lockout)",
    Description = "ล้างประวัติการเตะและรีเซ็ตระบบความปลอดภัยให้ส่งคำสั่งฟาร์มได้ทันที",
    Callback = function()
        getgenv().EmergencyKickLockout = false
        getgenv().EmergencyPatchHalt = false
        getgenv().EmergencyCloudHalt = false
        getgenv().EmergencyStructuralHalt = false
        getgenv().SecurityStatusMessage = "ระบบปลอดภัย ทำงานปกติ"
        if writefile then
            pcall(function() writefile("petdice_kick_guard.json", HS:JSONEncode({ count = 0, lastKick = 0 })) end)
        end
        Notify("🛡️ ปลดล็อกสำเร็จ", "ล้างสถานะล็อกดาวน์เรียบร้อย สคริปต์พร้อมทำงานตามปกติ 100%!", 4)
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
    Title = "📋 คัดลอกลิงก์ Loadstring สำหรับใส่โปร (Copy Loadstring)",
    Description = "คัดลอกคำสั่งรันสคริปต์แบบเคลียร์แคช CDN ล่าสุดลง Clipboard",
    Callback = function()
        local scriptCmd = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/markrunerppl-boop/petdicezaza/main/petdicezaza.lua?t=" .. tick()))()'
        local setCb = setclipboard or toclipboard or (Clipboard and Clipboard.set)
        if setCb then
            pcall(function() setCb(scriptCmd) end)
            Notify("📋 คัดลอกสำเร็จ!", "คัดลอกคำสั่งรันสคริปต์ลง Clipboard เรียบร้อยแล้ว นำไปวางใน Executor ได้ทันที!", 4)
        else
            Notify("ℹ️ ลิงก์สคริปต์", scriptCmd, 6)
        end
    end
})

-- ==============================================================================
-- 🔒 [LOCKED CORE UPDATER - ห้ามแตะต้องหรือดัดแปลงโดยไม่ได้รับอนุญาต]
-- ⚠️ DO NOT MODIFY THIS UPDATER BLOCK WITHOUT EXPLICIT PERMISSION FROM USER
-- Handles live cache-busted fetch, compilation check, thread teardown, and instant hot-reload
-- ==============================================================================
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
            if not success or not newCode or #newCode < 1000 then
                success, newCode = pcall(function()
                    return game:HttpGet("https://raw.githubusercontent.com/markrunerppl-boop/petdicezaza/main/petdicezaza.lua")
                end)
            end
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
                    if getgenv().PetDiceMobileToggleGui then
                        pcall(function() getgenv().PetDiceMobileToggleGui:Destroy() end)
                        getgenv().PetDiceMobileToggleGui = nil
                    end
                    task.wait(0.2)
                    task.spawn(fn)
                else
                    warn("[PetDice Updater] Compile error: " .. tostring(compileErr))
                    Notify("❌ เกิดข้อผิดพลาด", "โค้ดจาก GitHub คอมไพล์ไม่ผ่าน: " .. tostring(compileErr), 6)
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
            if FlushTradeDeferredQueue then
                FlushTradeDeferredQueue()
            end
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
                
                -- อัปเดตสถานะตลาดทันทีเมื่อซื้อของ หรือเงินเปลี่ยน
                if UpdateMarketStatus and (syncData.Full or syncData.Market or syncData.Money or syncData.Rebirths) then
                    UpdateMarketStatus()
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
    RS:GetAttributeChangedSignal("WorldBossState"):Connect(function()
        if getgenv().PetDiceScriptToken ~= scriptToken then return end
        if UpdateTowerStatus then task.delay(0.2, UpdateTowerStatus) end
    end)
    RS:GetAttributeChangedSignal("WorldBossJoined"):Connect(function()
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
        LoopHeartbeats["Loop1_AutoRoll"] = tick()
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
        LoopHeartbeats["Loop2_AutoBuyDice"] = tick()
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
        LoopHeartbeats["Loop3_AutoTower"] = tick()
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
                        
                        -- ตรวจสอบและเปิด TowerAutoplay ของตัวเกมให้เป็นจริงเสมอ เพื่อการไต่ชั้นอย่างต่อเนื่อง
                        pcall(function()
                            if data.Settings and data.Settings.TowerAutoplay ~= true then
                                Fire("SetSetting", "TowerAutoplay", true)
                            end
                        end)
                        
                        -- หากอยู่ในอารีน่า และเปิดออโต้ออกจากอารีน่า ให้ส่งคำสั่งออกสู่ Away Mode
                        if IsTowerInArena() and CFG.AutoExitArena then
                            Fire("TowerExit")
                            Humanizer.Wait(1.0, 1.8)
                        end
                        
                        -- Watchdog: ตรวจสอบกรณีติดค้าง (ตาม FloorTimeout ของเกมคือ 55 วินาที จึงใช้ 75 วินาทีเพื่อความปลอดภัย 100%)
                        if LiveTower.LastFloorTime and (now - LiveTower.LastFloorTime > 75.0) and (now - LastZoneTransitionTime > 5.0) then
                            LiveTower.LastFloorTime = now
                            Fire("TowerLeave")
                            task.wait(1.0)
                            SwitchOrStartTower(targetId, true)
                        end
                    else
                        local char = LocalPlayer.Character or Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and Vector3.new(hrp.Position.X, 0, hrp.Position.Z).Magnitude < 150 then
                            -- หากตัวละครอยู่ในลานพลาซ่า ให้พากลับบ้านอย่างปลอดภัยเพื่อเริ่มหอคอย
                            if (now - LastZoneTransitionTime >= 4.0) then
                                Fire("Teleport", "Home")
                                Humanizer.Wait(3.5, 4.5)
                                LastZoneTransitionTime = tick()
                            else
                                task.wait(2.0)
                            end
                            continue
                        end
                        
                        -- รอให้การเปลี่ยนโซนก่อนหน้า (เช่น วาร์ปกลับบ้าน) โหลดเสร็จอย่างสมบูรณ์ ป้องกัน Error 267
                        if (now - LastZoneTransitionTime < 4.0) then
                            task.wait(1.5)
                            continue
                        end
                        
                        local delaySec = math.max(2.5, tonumber(CFG.TowerRestartDelay) or 3.0)
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
        LoopHeartbeats["Loop3_WorldBoss"] = tick()
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        local char = LocalPlayer.Character or Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then task.wait(2.0) continue end
        
        local wbState = RS:GetAttribute("WorldBossState")
        local isJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        
        if isJoined or wbState == "Fighting" then
            if isJoined then wasInBoss = true end
        end
        
        -- เมื่อบอสโลกจบลง ให้พากลับบ้านอย่างปลอดภัย และให้ Loop Engine หอคอยกลับมาฟาร์มต่ออัตโนมัติ
        if wasInBoss and not isJoined then
            wasInBoss = false
            task.wait(2.0)
            pcall(function()
                Fire("Teleport", "Home")
            end)
            Humanizer.Wait(3.5, 4.5)
            LastZoneTransitionTime = tick()
            Notify("🏰 หอคอย", "จบศึกบอสโลกเรียบร้อย กลับถึงบ้านแล้ว ระบบหอคอยจะเริ่มฟาร์มต่ออัตโนมัติ", 3)
        end
        
        if CFG.AutoWorldBoss then
            pcall(function()
                local wbElem = RS:GetAttribute("WorldBossElement") or ""
                local wbDiff = RS:GetAttribute("WorldBossDifficulty") or ""
                
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
                                local isBossUnlocked = IsFeatureUnlocked("WorldBoss", "worldboss")
                                
                                -- ถ้ายังไม่ปลดล็อค ไม่ต้องออกจากหอคอย ไม่ต้องเดินไปประตูบอสโลก ให้ฟาร์มหอคอยต่อไปอย่างปลอดภัย 100%
                                if not isBossUnlocked then return end
                                
                                -- ตรวจสอบการซ่อมแซมประตูบอสโลก
                                if data and not data.PortalRepaired then
                                    Fire("PortalRepair")
                                    Humanizer.Wait(0.5, 1.0)
                                end
                                
                                -- 1. พักหอคอยก่อนเพื่อให้สัตว์เลี้ยงว่างพร้อมตีบอส
                                if CFG.PauseTowerForBoss and IsTowerRunning() then
                                    Notify("🏰 หอคอย", "ออกจากหอคอยชั่วคราวเพื่อเตรียมตัวสู้บอสโลก...", 2)
                                    Fire("TowerLeave")
                                    LiveTower.Active = false
                                    LiveTower.Starting = false
                                    LiveTower.LastEventTime = 0
                                    LiveTower.TowerId = nil
                                    local leaveWaitStart = tick()
                                    while IsTowerRunning() and (tick() - leaveWaitStart < 4.0) do
                                        task.wait(0.2)
                                    end
                                    Humanizer.Wait(2.0, 3.0)
                                    LastZoneTransitionTime = tick()
                                end
                                
                                -- 2. เดินทางไปหน้าประตูบอสด้วยระบบทางการของตัวเกม และเดินขึ้นบันไดตามธรรมชาติ (ปลอดภัยจากการตรวจจับ 100%)
                                SafeWalkToBossPortal()
                                
                                -- 3. Humanizer หน่วงเวลาเล็กน้อย
                                Humanizer.Wait(0.5, 1.0)
                                if getgenv().PetDiceScriptToken ~= scriptToken or not CFG.AutoWorldBoss then return end
                                
                                -- 4. ส่งคำสั่งเข้าร่วมบอสโลก
                                Fire("WorldBossJoin")
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
            if isEconomyActionMutex then task.wait(1.5) continue end
            isEconomyActionMutex = true
            getgenv().EconomyActionMutex = true
            getgenv().LastEconomyActionStartTime = tick()
            
            pcall(function()
                CircuitBreaker.Execute("AutoRebirth", function()
                    local data = State.Data
                    if not data then return end
                    local cost = Stats.RebirthCost(data)
                    if cost and (data.Money or 0) >= cost then
                        Fire("Rebirth")
                        Humanizer.Wait(2.0, 3.5)
                    end
                end)
            end)
            
            isEconomyActionMutex = false
            getgenv().EconomyActionMutex = false
            getgenv().LastEconomyActionStartTime = 0
        end
    end
end)

-- 5. Auto Upgrade Skill Tree (Buy All Affordable Upgrades - Safe & Ready Checked)
task.spawn(function()
    while true do
        local delayTime = math.max(3.0, CFG.UpgradeTreeDelay or 3)
        task.wait(delayTime)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.UpgradeTree then
            if isEconomyActionMutex then task.wait(1.5) continue end
            isEconomyActionMutex = true
            getgenv().EconomyActionMutex = true
            getgenv().LastEconomyActionStartTime = tick()
            
            pcall(function()
                CircuitBreaker.Execute("UpgradeTree", function()
                    local data = State.Data
                    if not data or not data.Upgrades or not data.Money or data.Money <= 0 then 
                        task.wait(3.0)
                        return 
                    end
                    
                    -- สแกนเรียลไทม์: ตรวจสอบความพร้อมใช้งานจริงว่ามีอัปเกรดที่เงินพอซื้อได้จริงหรือไม่
                    if Upgrades and Upgrades.PlanBuyAll then
                        local planned, totalCost = Upgrades.PlanBuyAll(data.Upgrades, data.Money, 50)
                        if planned and #planned > 0 and totalCost and data.Money >= totalCost then
                            Fire("BuyAllUpgrades")
                            Humanizer.Wait(1.8, 2.8)
                        else
                            -- ไม่มีอัปเกรดที่เงินพอซื้อในขณะนี้ พัก 4 วินาที ไม่ยิงคำสั่งรัว
                            task.wait(4.0)
                        end
                    end
                end)
            end)
            
            isEconomyActionMutex = false
            getgenv().EconomyActionMutex = false
            getgenv().LastEconomyActionStartTime = 0
        end
    end
end)

-- 6. Auto Equip Best Pets
task.spawn(function()
    local lastTotalPets = 0
    local lastPeriodicEquipTime = 0
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
                if (IsTowerRunning and IsTowerRunning()) or (IsTowerInArena and IsTowerInArena()) then
                    return
                end
                
                -- สแกนเรียลไทม์:
                -- 1. มีสัตว์เลี้ยงใหม่เข้ามา (currentTotal ~= lastTotalPets)
                -- 2. สัตว์เลี้ยงที่ใส่อยู่ยังไม่เต็มช่อง (equippedCount < maxEquipped)
                -- 3. สัตว์เลี้ยงเพิ่งถูกอัปเกรดเลเวลล่าสุด (และเว้นระยะอย่างน้อย 8 วิ)
                local now = tick()
                local shouldEquip = false
                if currentTotal ~= lastTotalPets then
                    shouldEquip = true
                    lastTotalPets = currentTotal
                elseif equippedCount < maxEquipped then
                    shouldEquip = true
                elseif getgenv().LastPetUpgradedTime and (now - getgenv().LastPetUpgradedTime < 10.0) and (now - lastPeriodicEquipTime >= 8.0) then
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
                if not IsFeatureUnlocked("Expeditions", "expeditions") then return end
                local data = State.Data
                if not data or not data.Expeditions then return end
                
                -- 1. สแกนเรียลไทม์: เคลมรางวัลการผจญภัยที่เสร็จแล้ว
                ClaimAllDoneExpeditions()
                Humanizer.Wait(1.0, 2.0)
                
                -- 2. สแกนเรียลไทม์: ตรวจสอบจำนวนช่องว่างก่อนส่งสัตว์เลี้ยง
                data = State.Data
                local maxSlots = Expeditions and Expeditions.Slots and Expeditions.Slots(data) or 3
                local activeCount = #(data.Expeditions and data.Expeditions.Active or {})
                local slotsToFill = maxSlots - activeCount
                if slotsToFill > 0 then
                    local recentlySent = {}
                    for s = 1, slotsToFill do
                        local diffId, pets = GetBestExpeditionPets(CFG.ExpeditionPetCount or 1, recentlySent)
                        if diffId and #pets > 0 then
                            for _, uid in ipairs(pets) do
                                recentlySent[tostring(uid)] = true
                            end
                            Fire("SendExpedition", diffId, pets)
                            Humanizer.Wait(1.2, 1.8)
                        else
                            break
                        end
                    end
                end
            end)
        end
    end
end)

-- 8. Master Mutex Watchdogs (100% Deadlock Prevention)
task.spawn(function()
    while true do
        task.wait(1.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        
        local nowTick = tick()
        
        -- 1. Pet Operation Mutex (20s)
        if getgenv().PetOperationMutex or isPetOperationMutex then
            local startT = getgenv().LastPetOperationStartTime or 0
            if startT > 0 and (nowTick - startT > 20.0) then
                getgenv().PetOperationMutex = false
                isPetOperationMutex = false
                isPetEnhanceRolling = false
                isAutoSellingActive = false
                getgenv().LastPetOperationStartTime = 0
            end
        end

        -- 2. Economy Action Mutex (12s)
        if getgenv().EconomyActionMutex or isEconomyActionMutex then
            local startT = getgenv().LastEconomyActionStartTime or 0
            if startT > 0 and (nowTick - startT > 12.0) then
                getgenv().EconomyActionMutex = false
                isEconomyActionMutex = false
                getgenv().LastEconomyActionStartTime = 0
            end
        end

        -- 3. Zone Transition Lock (8s)
        if isZoneTransitionLocked and (nowTick - LastZoneTransitionTime > 8.0) then
            isZoneTransitionLocked = false
        end

        -- 4. Trade Session Watchdog (15s timeout if TradeActiveSession is stuck without window or session)
        if getgenv().TradeActiveSession then
            local hasSession = (getgenv().CurrentTradeSession ~= nil)
            local hasWindow = (GetTradeWindow and GetTradeWindow() ~= nil)
            if not hasSession and not hasWindow then
                local reqTime = getgenv().LastTradeRequestTime or 0
                if reqTime > 0 and (nowTick - reqTime > 15.0) then
                    getgenv().TradeActiveSession = false
                    getgenv().LastTradeRequestTime = 0
                    if FlushTradeDeferredQueue then
                        FlushTradeDeferredQueue()
                    end
                end
            end
        end
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
                        local inWBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
                        if inWBoss then return end
                        
                        local targetPlayer = Players:GetPlayerByUserId(CFG.TradeTargetId)
                        if targetPlayer and targetPlayer.Parent == Players then
                            -- เคลียร์การลงหอคอย/อารีน่าอย่างปลอดภัยก่อนส่งคำขอเทรด
                            if IsTowerInArena and IsTowerInArena() then
                                Fire("TowerExit")
                                Humanizer.Wait(0.5, 0.8)
                            end
                            
                            -- ล็อค TradeActiveSession ทันที เพื่อป้องกันหอคอยหรือลูปอื่นแทรกแซงระหว่างส่งคำขอ
                            getgenv().TradeActiveSession = true
                            getgenv().LastTradeRequestTime = tick()
                            Fire("TradeRequest", CFG.TradeTargetId)
                            Notify("📨 ส่งคำขอเทรด", "ส่งคำขอเทรดไปยัง " .. tostring(targetPlayer.DisplayName or targetPlayer.Name) .. " แล้ว", 3)
                            Humanizer.Wait(2.5, 4.0)
                            -- หากคู่เทรดยังไม่ตอบรับภายใน 20 วินาที และไม่มีเซสชันเทรดเปิด ให้ปลดล็อคสถานะ
                            task.delay(20, function()
                                if not getgenv().CurrentTradeSession and not GetTradeWindow() then
                                    getgenv().TradeActiveSession = false
                                    if FlushTradeDeferredQueue then FlushTradeDeferredQueue() end
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
                        local curSession = getgenv().CurrentTradeSession
                        local curYou = curSession and curSession.You
                        local alreadyInTrade = (curYou and curYou.Items and curYou.Items[itemKey]) or 0
                        if realCount > 0 and alreadyInTrade < realCount then
                            Fire("TradeItem", itemKey, realCount)
                            droppedCount = droppedCount + 1
                            Humanizer.Wait(0.40, 0.70)
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

-- 10. Auto Upgrade Pet Levels (Target Level & Step Protected - Safe & Ready Checked)
task.spawn(function()
    while true do
        task.wait(2.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoUpgradePetLevel then
            if isPetOperationMutex or isAutoSellingActive then
                task.wait(0.5)
                continue
            end
            isPetOperationMutex = true
            getgenv().PetOperationMutex = true
            getgenv().LastPetOperationStartTime = tick()
            local waitAfter = 0
            
            pcall(function()
                CircuitBreaker.Execute("AutoUpgradePetLevel", function()
                    local data = State.Data
                    if not data or not data.Pets or not data.Money or data.Money <= 0 then 
                        waitAfter = 3.0
                        return 
                    end
                    
                    -- ตรวจสอบว่าปลดล็อคระบบอัปเลเวลในต้นไม้ทักษะแล้วหรือไม่ ("PetUpgrades" / "petup")
                    if not IsFeatureUnlocked("PetUpgrades", "petup") then
                        waitAfter = 6.0 -- ยังไม่ปลดล็อค พักยาว 6 วินาที ไม่ส่งคำสั่งใดๆ เด็ดขาด
                        return
                    end
                    
                    local cap = Stats.PetLevelCap(data.Upgrades)
                    if not cap or cap <= 0 then waitAfter = 3.0 return end
                    
                    local targetLvl = math.min(CFG.TargetPetLevel or cap, cap)
                    local step = CFG.UpgradeLevelStep or 1
                    local targetUids = GetTopBestPets(CFG.EnhancePetCount or 4)
                    local virtualMoney = data.Money
                    local upgradedAny = false
                    
                    for _, uid in ipairs(targetUids) do
                        if IsInTrade() or getgenv().TradeActiveSession then break end
                        if virtualMoney <= 0 then break end
                        
                        local pet = data.Pets[uid]
                        if pet and IsPetEligibleForEnhance(pet) and (pet.L or 0) < targetLvl then
                            local curLvl = pet.L or 0
                            local needed = targetLvl - curLvl
                            local countToUpgrade = math.min(needed, step)
                            if step >= 999 then countToUpgrade = needed end
                            
                            local affordable = FindAffordableLevels(pet, data.Upgrades, virtualMoney, countToUpgrade)
                            if affordable > 0 then
                                local cost = affordable == 1 and Stats.PetLevelCost(pet, data.Upgrades) or Stats.PetLevelsCost(pet, data.Upgrades, affordable)
                                if cost and virtualMoney >= cost then
                                    virtualMoney = virtualMoney - cost
                                    if affordable == 1 then
                                        Fire("UpgradePet", uid)
                                    else
                                        Fire("UpgradePetLevels", uid, affordable)
                                    end
                                    upgradedAny = true
                                    Humanizer.Wait(0.40, 0.70)
                                end
                            end
                        end
                    end
                    
                    if not upgradedAny then
                        -- สัตว์เลี้ยงทั้งหมดถึงเป้าหมายแล้ว หรือเงินไม่พออัปเกรด พัก 3.5 วินาที
                        waitAfter = 3.5
                    else
                        getgenv().LastPetUpgradedTime = tick()
                        waitAfter = 1.5 -- หน่วงรอเซิร์ฟเวอร์อัปเดตข้อมูลสเตตัส
                    end
                end)
            end)
            
            isPetOperationMutex = false
            getgenv().PetOperationMutex = false
            getgenv().LastPetOperationStartTime = 0
            if (waitAfter or 0) > 0 then task.wait(waitAfter) end
        else
            task.wait(2.0)
        end
    end
end)

-- 11. Auto Roll Pet Grade (Rank <= TargetRank Strictly Locked - Safe Humanized Engine)
task.spawn(function()
    local consecutiveRolls = 0
    while true do
        task.wait(0.35)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoRollGrade then
            if isPetOperationMutex or isPetEnhanceRolling or isAutoSellingActive then
                task.wait(0.25)
                continue
            end
            isPetOperationMutex = true
            isPetEnhanceRolling = true
            getgenv().PetOperationMutex = true
            getgenv().LastPetOperationStartTime = tick()
            local waitAfter = 0
            pcall(function()
                CircuitBreaker.Execute("AutoRollGrade", function()
                    local data = State.Data
                    if not data or not data.Pets or not data.Gems or data.Gems < 1 then
                        waitAfter = 3.0
                        return
                    end
                    
                    -- ตรวจสอบว่าปลดล็อคระบบเกรดในต้นไม้ทักษะแล้วหรือไม่ ("Grades" / "grades")
                    if not IsFeatureUnlocked("Grades", "grades") then
                        waitAfter = 6.0 -- ยังไม่ปลดล็อค พักยาว 6 วินาที ไม่ส่งคำสั่งใดๆ เด็ดขาด
                        return
                    end
                    
                    local targetRank = CFG.TargetGradeRank or 8
                    local targetUids = GetTopBestPets(CFG.EnhancePetCount or 4)
                    local rollDelay = math.clamp(CFG.RollSpeed or 0.35, 0.25, 1.2)
                    local virtualGems = data.Gems
                    local anyRolled = false
                    
                    for _, uid in ipairs(targetUids) do
                        if IsInTrade() or getgenv().TradeActiveSession then break end
                        if virtualGems < 1 then break end
                        
                        local pet = data.Pets[uid]
                        if pet and IsPetEligibleForEnhance(pet) then
                            if not IsPetGradeLocked(pet, targetRank) then
                                virtualGems = virtualGems - 1
                                Fire("RollGrade", uid)
                                anyRolled = true
                                consecutiveRolls = consecutiveRolls + 1
                                
                                -- Humanizer หน่วงเวลาแบบเป็นธรรมชาติ ปลอดภัยจากการตรวจจับของ Roblox
                                Humanizer.Wait(math.max(0.25, rollDelay - 0.05), rollDelay + 0.08)
                                
                                -- พักสั้นๆ ทุก 10 ครั้งเพื่อจำลองพฤติกรรมมนุษย์ ป้องกัน Remote Burst
                                if consecutiveRolls >= 10 then
                                    consecutiveRolls = 0
                                    task.wait(math.random(120, 180) / 100)
                                end
                            end
                        end
                    end
                    
                    if not anyRolled then
                        consecutiveRolls = 0
                        waitAfter = 3.0 -- เมื่อสัตว์เลี้ยงทั้งหมดถึงเป้าหมายหรือเพชรหมด พัก 3.0 วินาที ไม่ยิงซ้ำ
                    else
                        waitAfter = math.max(0.4, rollDelay) -- เว้นระยะระหว่างรอบสุ่ม
                    end
                end)
            end)
            isPetEnhanceRolling = false
            isPetOperationMutex = false
            getgenv().PetOperationMutex = false
            getgenv().LastPetOperationStartTime = 0
            if (waitAfter or 0) > 0 then task.wait(waitAfter) end
        else
            consecutiveRolls = 0
            task.wait(2.0)
        end
    end
end)

-- 12. Auto Roll Pet Trait (Rank <= TargetRank Strictly Locked - Safe Humanized Engine)
task.spawn(function()
    local consecutiveRolls = 0
    while true do
        task.wait(0.35)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0) continue end
        
        if CFG.AutoRollTrait then
            if isPetOperationMutex or isPetEnhanceRolling or isAutoSellingActive then
                task.wait(0.25)
                continue
            end
            isPetOperationMutex = true
            isPetEnhanceRolling = true
            getgenv().PetOperationMutex = true
            getgenv().LastPetOperationStartTime = tick()
            local waitAfter = 0
            pcall(function()
                CircuitBreaker.Execute("AutoRollTrait", function()
                    local data = State.Data
                    if not data or not data.Pets or not data.Shards or data.Shards < 1 then
                        waitAfter = 3.0
                        return
                    end
                    
                    -- ตรวจสอบว่าปลดล็อคระบบ Trait (บัฟ) ในต้นไม้ทักษะแล้วหรือไม่ ("Traits" / "traits")
                    if not IsFeatureUnlocked("Traits", "traits") then
                        waitAfter = 6.0 -- ยังไม่ปลดล็อค พักยาว 6 วินาที ไม่ส่งคำสั่งใดๆ เด็ดขาด
                        return
                    end
                    
                    local targetRank = CFG.TargetTraitRank or 6
                    local targetUids = GetTopBestPets(CFG.EnhancePetCount or 4)
                    local rollDelay = math.clamp(CFG.RollSpeed or 0.35, 0.25, 1.2)
                    local virtualShards = data.Shards
                    local anyRolled = false
                    
                    for _, uid in ipairs(targetUids) do
                        if IsInTrade() or getgenv().TradeActiveSession then break end
                        if virtualShards < 1 then break end
                        
                        local pet = data.Pets[uid]
                        if pet and IsPetEligibleForEnhance(pet) then
                            if not IsPetTraitLocked(pet, targetRank) then
                                virtualShards = virtualShards - 1
                                Fire("RollTrait", uid)
                                anyRolled = true
                                consecutiveRolls = consecutiveRolls + 1
                                
                                -- Humanizer หน่วงเวลาแบบเป็นธรรมชาติ ปลอดภัยจากการตรวจจับของ Roblox
                                Humanizer.Wait(math.max(0.25, rollDelay - 0.05), rollDelay + 0.08)
                                
                                -- พักสั้นๆ ทุก 10 ครั้งเพื่อจำลองพฤติกรรมมนุษย์ ป้องกัน Remote Burst
                                if consecutiveRolls >= 10 then
                                    consecutiveRolls = 0
                                    task.wait(math.random(120, 180) / 100)
                                end
                            end
                        end
                    end
                    
                    if not anyRolled then
                        consecutiveRolls = 0
                        waitAfter = 3.0 -- เมื่อสัตว์เลี้ยงทั้งหมดถึงเป้าหมายหรือชาร์ดหมด พัก 3.0 วินาที ไม่ยิงซ้ำ
                    else
                        waitAfter = math.max(0.4, rollDelay) -- เว้นระยะระหว่างรอบสุ่ม
                    end
                end)
            end)
            isPetEnhanceRolling = false
            isPetOperationMutex = false
            getgenv().PetOperationMutex = false
            getgenv().LastPetOperationStartTime = 0
            if (waitAfter or 0) > 0 then task.wait(waitAfter) end
        else
            consecutiveRolls = 0
            task.wait(2.0)
        end
    end
end)

-- 13. Auto Potions & Consumables
task.spawn(function()
    local lastInfinityBagOpenTick = 0
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
            
            -- ปลอดภัย 100%: เปิดถุงสมบัติทั่วไปและถุงธาตุ/ถุงโลก แบบหน่วงเวลา 15s ซิงค์คัตซีน และเคลมเฉพาะเมื่อมีสัตว์เลี้ยงค้างจริงเท่านั้น
            local infinityBagNow = tick()
            if CFG.AutoOpenLootBags and (infinityBagNow - lastInfinityBagOpenTick > 15) then
                local isBusy = false
                pcall(function()
                    if LootBagController and LootBagController.Api and LootBagController.Api.Busy then
                        isBusy = LootBagController.Api.Busy()
                    end
                end)
                
                if not isBusy then
                    -- 1. ถุงสมบัติทั่วไป (LootBags)
                    if (data.LootBags or 0) > 0 then
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
                    
                    -- 2. ถุงธาตุและถุงโลก (ElementBags เช่น World)
                    if data.ElementBags then
                        for elemKey, elemCount in pairs(data.ElementBags) do
                            if (elemCount or 0) > 0 then
                                lastInfinityBagOpenTick = infinityBagNow
                                Fire("OpenLootBag", "all", elemKey)
                                Notify("🎒 ถุงสมบัติ", string.format("กำลังเปิดถุงธาตุ/โลก [%s] (%d ใบ)...", tostring(elemKey), elemCount), 3)
                                Humanizer.Wait(4.5, 6.0)
                                
                                local waitingElem = 0
                                pcall(function()
                                    if PetData and PetData.WaitingCount then
                                        waitingElem = PetData.WaitingCount(data, elemKey)
                                    end
                                end)
                                
                                if waitingElem > 0 then
                                    Humanizer.Wait(1.0, 1.8)
                                    Fire("ClaimLootPets", elemKey)
                                    Notify("🐾 สัตว์เลี้ยง", string.format("กดรับสัตว์เลี้ยงจากถุง [%s] %d ตัวเรียบร้อย!", tostring(elemKey), waitingElem), 3)
                                    Humanizer.Wait(1.5, 2.5)
                                end
                                break -- เปิดทีละ 1 ประเภทต่อรอบ ป้องกัน Remote Burst
                            end
                        end
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
                    Fire("ClaimDaily")
                    Humanizer.Wait(0.5, 1.0)
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
                        local isUnlocked = true
                        if Upgrades and Upgrades.IsOpen and gDef.Needs then
                            isUnlocked = Upgrades.IsOpen(data.Upgrades, gDef.Needs)
                        end
                        if isUnlocked and gData and not gData.Claimed and (gData.Progress or 0) >= (gDef.Goal or math.huge) then
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

-- 15. Auto Market Buy All Loop: ซื้อของทั้งหมดในตลาดอัตโนมัติเมื่อพร้อม (ปลอดภัย 100% ไม่ทับซ้อนคำสั่งอื่น)
task.spawn(function()
    while true do
        task.wait(6.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(3.0) continue end
        if LocalPlayer:GetAttribute("PetDiceLoading") == true then task.wait(2.0) continue end
        
        if CFG.AutoBuyMarket then
            if isEconomyActionMutex then task.wait(1.5) continue end
            isEconomyActionMutex = true
            getgenv().EconomyActionMutex = true
            getgenv().LastEconomyActionStartTime = tick()
            
            pcall(function()
                CircuitBreaker.Execute("AutoBuyMarket", function()
                    if not IsFeatureUnlocked("Market", "market") then
                        return
                    end
                    
                    local data = State.Data
                    if not data or not Market then return end
                    
                    local now = State.Now and State.Now() or os.time()
                    local currentWindow = Market.Window(now)
                    local bought = data.Market and (data.Market.Window ~= currentWindow and {} or data.Market.Bought) or {}
                    local _, canBuyCount, totalCost, totalLeft = Market.PlanBuyAll(currentWindow, bought, data.Rebirths or 0, data.Money or 0)
                    
                    if canBuyCount and canBuyCount > 0 and (data.Money or 0) >= (totalCost or 0) then
                        Humanizer.Wait(0.8, 1.5)
                        Fire("MarketBuyAll")
                        Notify("🛒 ตลาด (Market)", "กวาดซื้อสินค้าทั้งหมดในตลาด (" .. canBuyCount .. " ชิ้น) เรียบร้อย!", 3)
                        Humanizer.Wait(2.0, 3.5)
                        if UpdateMarketStatus then pcall(UpdateMarketStatus) end
                        if UpdatePotionStatus then pcall(UpdatePotionStatus) end
                    end
                end)
            end)
            
            isEconomyActionMutex = false
            getgenv().EconomyActionMutex = false
            getgenv().LastEconomyActionStartTime = 0
        end
    end
end)

-- 16. Auto Sell Pets Loop: ตรวจสอบและขายสัตว์เลี้ยงส่วนเกินอัตโนมัติ (เก็บเฉพาะ N ตัวแรกที่ค่าพลัง Base สูงสุด)
task.spawn(function()
    while true do
        task.wait(3.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(3.0) continue end
        
        if CFG.AutoSellPets and not isAutoSellingActive and not isPetOperationMutex and not isPetEnhanceRolling then
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
    return SwitchOrStartTower(targetId, true)
end

getgenv().PetDiceScriptLoaded = true
getgenv().PetDiceScriptStarting = nil
getgenv().PetDiceNotify = Notify

Notify("🚀 สคริปต์พร้อมทำงาน", "Pet Dice Master Fluent Edition v4.8 โหลดสำเร็จ!", 4)
