-- ==============================================================================
-- 🎲 PET DICE MASTER SAFE EDITION v4.8 (FLUENT UI REBORN)
-- 🛡️ Anti-AI Detection & High-Tier Protection System
-- 🎨 Modern Windows 11 Fluent Acrylic Interface
-- ==============================================================================

-- ==============================================================================
-- [0] CLEAN STARTUP & HOT-RELOAD GATEKEEPER
-- ==============================================================================
-- ป้องกันการยิงสคริปต์ 2 เธรดพร้อมกันในเสี้ยววินาทีเดียวกัน (Debounce 1.5 วินาที)
if getgenv().PetDiceScriptStarting and (tick() - getgenv().PetDiceScriptStarting < 1.5) then
    warn("[PetDice Safe] Duplicate execution within 1.5s blocked.")
    return
end
getgenv().PetDiceScriptStarting = tick()

-- 1. ป้องกันการรันบนหน้า Desktop App Lobby / Home Screen (PlaceId == 0) หรือเกมอื่น
if not game.PlaceId or game.PlaceId == 0 then return
end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PET_DICE_PLACE_IDS = {
    [139815684286865] = true,
}
if not PET_DICE_PLACE_IDS[game.PlaceId] and not RS:FindFirstChild("PetDice") then
    -- ไม่ใช่เกม Pet Dice ข้ามการทำงานอัตโนมัติทันที ป้องกัน Infinite Yield และการรบกวนเกมอื่น
    return
end

-- 2. รอโหลดแมพแบบมี Safety Timeout สูงสุด 20 วินาที (ป้องกันการค้างถาวร)
if not game:IsLoaded() then 
    local waitStart = tick()
    while not game:IsLoaded() and (tick() - waitStart < 20) do
        task.wait(0.2)
    end
    getgenv().PetDiceScriptStarting = tick() -- อัปเดตเวลาหลังโหลดแมพเสร็จ
end

local CG = game:GetService("CoreGui")
local HS = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

-- Forward declarations for script-wide state & config
local CFG = getgenv().CFG or {}
getgenv().CFG = CFG
local State
local Fire
local VERIFIED_GAME_PLACE_VERSION = 172

-- 3. รอ LocalPlayer แบบมี Safety Timeout (สูงสุด 15 วินาที)
local LocalPlayer = Players.LocalPlayer
local lpWait = tick()
while not LocalPlayer and (tick() - lpWait < 15) do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end
if not LocalPlayer then
    warn("[PetDice] LocalPlayer not found within 15s timeout.")
    return
end

local Character = LocalPlayer.Character
local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
task.spawn(function()
    if not Character then
        Character = LocalPlayer.CharacterAdded:Wait()
    end
    Humanoid = Character:WaitForChild("Humanoid", 10)
end)

LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    Humanoid = c:WaitForChild("Humanoid", 10)
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
        if gui:IsA("ScreenGui") and (gui.Name == "PetDiceFluentGui" or gui.Name:find("Fluent") or gui.Name:find("Rayfield")) then
            pcall(function() gui:Destroy() end)
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
getgenv().IsCandyStormActiveRunning = false
getgenv().CandyStormMutex = false
getgenv().LastCandyStormStartTime = 0
getgenv().IsTrickOrTreatActiveRunning = false
getgenv().TrickOrTreatMutex = false
getgenv().LastTrickOrTreatStartTime = 0

-- Anti-AFK Dual-Layer (VirtualUser Event + Jittered Periodic Heartbeat with Natural Viewport Coordinates)
pcall(function()
    if getgenv().PetDiceAntiAFKConn then
        pcall(function() getgenv().PetDiceAntiAFKConn:Disconnect() end)
        getgenv().PetDiceAntiAFKConn = nil
    end
    local VirtualUser = game:GetService("VirtualUser")
    local function GetNaturalViewportClickPos()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
        local rx = math.clamp(math.random(math.floor(vp.X * 0.15), math.floor(vp.X * 0.45)), 20, 600)
        local ry = math.clamp(math.random(math.floor(vp.Y * 0.15), math.floor(vp.Y * 0.45)), 20, 400); return Vector2.new(rx, ry)
    end
    getgenv().PetDiceAntiAFKConn = LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(GetNaturalViewportClickPos())
        end)
    end)
    
    -- Layer 2: Pulse สุ่มระยะเวลา 480 - 720 วินาที พร้อมตำแหน่งคลิกธรรมชาติ ป้องกันการตรวจจับบน UGPhone / Cloud 24/7
    task.spawn(function()
        while true do
            task.wait(math.random(480, 720))
            if getgenv().PetDiceAntiAFKConn == nil then break end
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(GetNaturalViewportClickPos())
            end)
        end
    end)
end)

-- Clean up any legacy Auto-Rejoin listeners (ความปลอดภัยสูงสุด: ปิดการรีจอยอัตโนมัติ 100% ป้องกันโดนแบน Error 600)
pcall(function()
    if getgenv().PetDiceErrorConn then
        pcall(function() getgenv().PetDiceErrorConn:Disconnect() end)
        getgenv().PetDiceErrorConn = nil
    end
    if getgenv().PetDiceOverlayConn then
        pcall(function() getgenv().PetDiceOverlayConn:Disconnect() end)
        getgenv().PetDiceOverlayConn = nil
    end
end)
-- ==============================================================================
-- [0] AIRTIGHT ANTI-BAN & PATCH SENTINEL SYSTEM (100% FAIL-SAFE PROTECTION)
-- ==============================================================================
VERIFIED_GAME_PLACE_VERSION = 172
local SECURITY_CONFIG_URL = "https://raw.githubusercontent.com/markrunerppl-boop/petdicezaza/main/security.json"

getgenv().EmergencyPatchHalt = false
getgenv().EmergencyCloudHalt = false
getgenv().EmergencyStructuralHalt = false
getgenv().EmergencyKickLockout = false
getgenv().EmergencyBanLockout = false
getgenv().SecurityStatusMessage = "ระบบปลอดภัย ทำงานปกติ (Game Patch v172)"

local function SafeNotify(title, content, duration)
    pcall(function()
        if Fluent and Fluent.Notify then
            Fluent:Notify({ Title = title, Content = content, Duration = duration or 5 })
        else
            game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = content, Duration = duration or 5 })
        end
    end)
end

-- 1. Error 600 & Error 267 Anti-Ban Lockout Sentinel (ป้องกันการแบนถาวรและแบนลูกโซ่บน UGPhone / Cloud)
pcall(function()
    local userUidStr = tostring(LocalPlayer and LocalPlayer.UserId or "0")
    local kickLogFile = string.format("petdice_kick_guard_%s.json", userUidStr)
    local banLogFile = string.format("petdice_ban_guard_%s.json", userUidStr)
    local nowTime = os.time()
    local kickData = { count = 0, lastKick = 0 }
    local banData = { banned = false, banTime = 0, code = 0 }
    
    -- ตรวจสอบประวัติการโดนแบน Error 600 ล่วงหน้า (ป้องกันการรันซ้ำบนเครื่อง UGPhone ที่อาจลามแบนไอดีอื่น)
    if isfile and isfile(banLogFile) and readfile then
        pcall(function()
            local raw = readfile(banLogFile)
            local decoded = HS:JSONDecode(raw)
            if type(decoded) == "table" and decoded.banned == true then
                banData = decoded
            end
        end)
    end
    
    if banData.banned == true and (nowTime - (banData.banTime or 0) < 604800) then
        getgenv().EmergencyBanLockout = true
        getgenv().EmergencyKickLockout = true
        getgenv().SecurityStatusMessage = "🚨 บัญชีนี้ติดสถานะแบน Error 600 (ระบบตัดไฟ 100% ป้องกันแบนลาม)"
        task.spawn(function()
            task.wait(2)
            SafeNotify("🛑 ระบบล็อกดาวน์ Error 600", "ตรวจพบว่าบัญชีนี้เคยถูกระงับ (Error 600)!\nระบบสั่งตัดการทำงาน 100% เพื่อป้องกันไม่ให้ไอดีอื่นใน UGPhone/IP เดียวกันถูกแบนตาม", 20)
        end)
        
        -- Auto-Recovery Sentinel: หากตัวละครอยู่ในเกมและเกมโหลดข้อมูลสำเร็จจริงเกิน 15 วินาที แปลว่าพ้นโทษแบนแล้ว!
        task.spawn(function()
            task.wait(15)
            if LocalPlayer and (LocalPlayer:GetAttribute("DataLoaded") == true or (State and State.Data ~= nil)) and getgenv().EmergencyBanLockout then
                getgenv().EmergencyBanLockout = false
                getgenv().EmergencyKickLockout = false
                getgenv().SecurityStatusMessage = string.format("ระบบปลอดภัย Game Patch v%d (ปลดล็อคปกติ)", game.PlaceVersion)
                if delfile and isfile and isfile(banLogFile) then
                    pcall(function() delfile(banLogFile) end)
                elseif writefile then
                    pcall(function() writefile(banLogFile, HS:JSONEncode({ banned = false })) end)
                end
                SafeNotify("🎉 บัญชีปลดแบนแล้ว!", "ตรวจพบว่าตัวละครสามารถเข้าเล่นและโหลดข้อมูลได้ตามปกติ\nระบบปลดล็อคการทำงานของสคริปต์ให้เรียบร้อยแล้วครับ", 8)
                pcall(function() if UpdateOverviewTab then UpdateOverviewTab() end end)
            end
        end)
    end
    
    if isfile and isfile(kickLogFile) and readfile then
        pcall(function()
            local raw = readfile(kickLogFile)
            local decoded = HS:JSONDecode(raw)
            if type(decoded) == "table" then
                kickData = decoded
            end
        end)
    end
    
    -- รีเซ็ตประวัติเฉพาะเมื่อผ่านไปเกิน 15 นาที (900 วินาที)
    if nowTime - (kickData.lastKick or 0) > 900 then
        kickData.count = 0
        getgenv().EmergencyKickLockout = false
        if writefile then
            pcall(function() writefile(kickLogFile, HS:JSONEncode(kickData)) end)
        end
    end
    
    -- หากถูกเตะสะสม 4 ครั้งขึ้นไปภายใน 10 นาที จึงสั่งล็อกดาวน์ฉุกเฉิน
    if (kickData.count or 0) >= 4 and (nowTime - (kickData.lastKick or 0) < 600) then
        getgenv().EmergencyKickLockout = true
        getgenv().SecurityStatusMessage = string.format("ล็อกดาวน์ฉุกเฉิน: ถูกเตะติดต่อกัน %d ครั้ง (ป้องกันแบน Error 600)", kickData.count)
        task.spawn(function()
            task.wait(2)
            SafeNotify("🛑 ล็อกดาวน์ความปลอดภัยฉุกเฉิน", string.format("ตรวจพบว่าไอดีนี้เพิ่งถูกเตะติดต่อกัน %d ครั้ง!\nระบบสั่งหยุดทำงานอัตโนมัติชั่วคราว เพื่อป้องกันการถูกแบนถาวร", kickData.count), 15)
        end)
    end
    
    -- บันทึกเหตุการณ์ถูกเตะหรือถูกแบนแบบเรียลไทม์ (ดักจับ Error 600 / Error 267 / Ban API ของ Roblox)
    GuiService.ErrorMessageChanged:Connect(function(msg)
        if msg and type(msg) == "string" and msg ~= "" then
            local lowerMsg = msg:lower()
            local isBan600 = msg:find("600") or lowerMsg:find("ban") or lowerMsg:find("restricted") or lowerMsg:find("suspended")
            local isRealKick = isBan600 or msg:find("267") or lowerMsg:find("kicked") or msg:find("unexpected client behavior") or msg:find("Security")
            
            if isBan600 then
                getgenv().EmergencyBanLockout = true
                getgenv().EmergencyKickLockout = true
                getgenv().SecurityStatusMessage = "🚨 ตรวจพบการถูกแบน (Error 600) สั่งตัดไฟสคริปต์ 100% ทันที!"
                banData = {
                    banned = true,
                    code = 600,
                    message = msg,
                    banTime = os.time(),
                    userId = userUidStr
                }
                if writefile then
                    pcall(function()
                        writefile(banLogFile, HS:JSONEncode(banData))
                    end)
                end
                if getgenv().RemoteQueue then table.clear(getgenv().RemoteQueue) end
                getgenv().PetDiceScriptToken = nil -- สั่งยุติการทำงานของลูปทั้งหมดทันที
            elseif isRealKick then
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

-- 2. PlaceVersion Sentinel (ตรวจจับการอัปเดตแพทช์ใหม่ของตัวเกมแบบเรียลไทม์ - บันทึกสถานะเท่านั้น ไม่สั่งตัดไฟ)
local function CheckGamePatch()
    local curVersion = game.PlaceVersion
    getgenv().EmergencyPatchHalt = false
    getgenv().SecurityStatusMessage = string.format("ระบบปลอดภัย Game Patch v%d", curVersion); return true
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
        local pd = RS:WaitForChild("PetDice", 8)
        assert(pd, "PetDice missing")
        local rem = pd:WaitForChild("Remotes", 5)
        assert(rem and rem:FindFirstChild("Action"), "Remotes.Action missing")
    end)
    if not valid then
        if tick() - (getgenv().PetDiceScriptToken or 0) < 15 then
            return true
        end
        getgenv().EmergencyStructuralHalt = true
        getgenv().SecurityStatusMessage = "โครงสร้างโมดูลเกมเปลี่ยนแปลง - หยุดส่งคำสั่งฉุกเฉิน"; return false
    else
        getgenv().EmergencyStructuralHalt = false
    end
    return true
end

-- ตรวจสอบความปลอดภัยครั้งแรกทันทีตอนเริ่มสคริปต์ (ทำงานแบบ Non-blocking Async ไม่บล็อกการโหลด UI)
CheckGamePatch()
task.spawn(function()
    pcall(CheckCloudSecurity)
    pcall(CheckStructuralIntegrity)
end)

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
local PetDice = RS:WaitForChild("PetDice", 25)
if not PetDice then
    warn("[PetDice] Timeout waiting for PetDice folder in ReplicatedStorage.")
    return
end
local Remotes = PetDice:WaitForChild("Remotes", 15)
if not Remotes then
    warn("[PetDice] Timeout waiting for Remotes.")
    return
end
local Action = Remotes:WaitForChild("Action", 15)
local TradeRemote = Remotes:WaitForChild("Trade", 15)
if not Action then
    warn("[PetDice] Timeout waiting for Action Remote.")
    return
end

State = require(PetDice.Client.Core.State)
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
local LootBagController = nil
pcall(function()
    if PetDice.Client:FindFirstChild("Cutscenes") and PetDice.Client.Cutscenes:FindFirstChild("LootBagController") then
        LootBagController = require(PetDice.Client.Cutscenes.LootBagController)
    end
end)
local CutsceneDirector = nil
pcall(function()
    if PetDice.Client:FindFirstChild("Cutscenes") and PetDice.Client.Cutscenes:FindFirstChild("CutsceneDirector") then
        CutsceneDirector = require(PetDice.Client.Cutscenes.CutsceneDirector)
    end
end)
local HalloweenConfig = { Goals = {}, Items = {} }
pcall(function()
    if PetDice.Configs:FindFirstChild("HalloweenConfig") then
        HalloweenConfig = require(PetDice.Configs.HalloweenConfig)
    end
end)
local HalloweenShopConfig = {}
pcall(function()
    if PetDice.Configs:FindFirstChild("HalloweenShopConfig") then
        HalloweenShopConfig = require(PetDice.Configs.HalloweenShopConfig)
    end
end)

-- ==============================================================================
-- [HALLOWEEN CANDY STORM EVENT TRACKER & REMOTES]
-- ==============================================================================
local ActiveCandies = {}
local VisitedCandies = {}

pcall(function()
    if getgenv().PetDiceCandyConn then
        pcall(function() getgenv().PetDiceCandyConn:Disconnect() end)
        getgenv().PetDiceCandyConn = nil
    end
    local candyRemote = PetDice:WaitForChild("Remotes", 10) and PetDice.Remotes:FindFirstChild("CandyStorm")
    if candyRemote then
        getgenv().PetDiceCandyConn = candyRemote.OnClientEvent:Connect(function(cmd, id, kind, pos)
            if getgenv().PetDiceScriptToken ~= scriptToken then return end
            if cmd == "Drop" and type(id) == "number" and typeof(pos) == "Vector3" then
                ActiveCandies[id] = { Id = id, Kind = kind, Position = pos, Born = tick() }
            elseif cmd == "Grabbed" and type(id) == "number" then
                ActiveCandies[id] = nil
            elseif cmd == "Clear" then
                table.clear(ActiveCandies)
            end
        end)
    end
end)

-- Forward Declarations for Halloween Event Functions
local GetHalloweenEntry
local CanTrickOrTreat
local IsCandyStormActive
local GetSecondsUntilNextStorm
local GetAvailableCandies
local WalkToPawcula
local SafeCollectPlazaCandies
local UpdateHalloweenStatus

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
    local diff = val * pct; return val + (math.random() * (diff * 2) - diff)
end

local function GetRealItemCount(itemName)
    local data = State and State.Data
    if not data then return 0 end
    local itemCfg = Config and Config.TradeItemByKey and Config.TradeItemByKey[itemName]
    if itemCfg and Stats and Stats.TradeItemCount then
        local count = Stats.TradeItemCount(data, itemCfg)
        if itemName == "SuperRolls" then count = count - (State.SuperQueued or 0)
        elseif itemName == "JackpotRolls" then count = count - (State.JackpotQueued or 0) end; return math.max(0, count)
    end
    if type(data[itemName]) == "number" then return data[itemName] end
    if data.Inventory and type(data.Inventory[itemName]) == "number" then return data.Inventory[itemName] end
    if data.Potions and type(data.Potions[itemName]) == "number" then return data.Potions[itemName] end
    if data.Items and type(data.Items[itemName]) == "number" then return data.Items[itemName] end
    if data.Currencies and type(data.Currencies[itemName]) == "number" then return data.Currencies[itemName] end
    return 0
end

local function GetTradeWindow()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
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

local IsFeatureUnlocked = nil

-- ==============================================================================
-- 👑 UNIVERSAL PRIORITY HIERARCHY MANAGER (AIRTIGHT BOSS & TOWER SENTINEL)
-- 1. ตีบอสโลก (World Boss) - ลำดับ 1 (สูงสุดเมื่อประตูเปิด / กำลังต่อสู้)
-- 2. เทรดปลอดภัย (Safe Trade) - ลำดับ 2
-- 3. อีเวนต์ฮาโลวีน (Halloween Event) - ลำดับ 3
-- 4. หอคอย (Infinity Tower) - ลำดับ 4
-- 5. สุ่มฟาร์มทั่วไป (General Auto Farm) - ลำดับ 5 (ต่ำสุด)
-- ==============================================================================
local isTrickOrTreatMutex = false
local isCollectingCandyMutex = false
local wasInWorldBossFight = false
local IsEnteringBossPortal = false
local isWorldBossTransitioning = false
local isBossActiveLock = false
getgenv().IsBossActiveLock = false
local lastBossActiveLockTime = 0

local function ClearQueueDuringBoss()
    pcall(function()
        if getgenv().RemoteQueue then
            table.clear(getgenv().RemoteQueue)
        end
    end)
end

local function IsTradeActive()
    return (IsInTrade and IsInTrade()) or (getgenv().TradeActiveSession == true) or (getgenv().CurrentTradeSession ~= nil) or (GetTradeWindow and GetTradeWindow() ~= nil) or ((getgenv().TradeLockedUntil or 0) > tick())
end

local function DoesWorldBossMatchFilter()
    local cfg = CFG or getgenv().CFG or {}
    local elemFilter = cfg.WorldBossElementFilter
    local diffFilter = cfg.WorldBossDifficultyFilter
    local wbElem = RS:GetAttribute("WorldBossElement") or ""
    local wbDiff = RS:GetAttribute("WorldBossDifficulty") or ""
    local elemMatch = (not elemFilter) or 
                     (elemFilter == "[ ตีทุกธาตุ (All Elements) ]") or 
                     (wbElem:lower() == tostring(elemFilter):lower()) or
                     (tostring(elemFilter):find(wbElem))
    local diffMatch = (not diffFilter) or 
                     (diffFilter == "[ ตีทุกระดับ (All Difficulties) ]") or
                     (wbDiff:lower() == tostring(diffFilter):lower()) or
                     (tostring(diffFilter):find(wbDiff))
    return elemMatch and diffMatch
end

local function IsWorldBossActive()
    local cfg = CFG or getgenv().CFG or {}
    if cfg.AutoWorldBoss == false then return false end
    
    -- 1. ตรวจสอบสถานะล็อกดาวน์บอส หรือตัวละครอยู่ในบอส กำลังเดินเข้าประตู อยู่ในรอบต่อสู้ หรือกำลังเดินทางกลับ
    if isBossActiveLock or getgenv().IsBossActiveLock then return true end
    
    local isJoined = (LocalPlayer and LocalPlayer:GetAttribute("WorldBossJoined") == true) or 
                     (LocalPlayer and LocalPlayer:GetAttribute("InWorldBoss") == true) or 
                     (IsEnteringBossPortal == true) or 
                     (wasInWorldBossFight == true) or
                     (isWorldBossTransitioning == true)
    if isJoined then return true end
    
    -- 2. ตัวเกมอยู่ในช่วงเปิดรับสมัคร (Joining) หรือกำลังต่อสู้จริงในเซิร์ฟเวอร์ (Fighting)
    local wbState = RS:GetAttribute("WorldBossState")
    if wbState == "Joining" then
        if DoesWorldBossMatchFilter() then
            return true
        end
    elseif wbState == "Fighting" then
        if wasInWorldBossFight or isJoined or DoesWorldBossMatchFilter() then
            return true
        end
    end
    
    return false
end

local function IsHalloweenActive()
    local cfg = CFG or getgenv().CFG or {}
    local stormActive = false
    if cfg.HalloweenAutoCollectCandy and IsCandyStormActive then
        local ok, act = pcall(IsCandyStormActive)
        if ok and act then stormActive = true end
    end
    return stormActive or (getgenv().IsCandyStormActiveRunning == true) or (getgenv().CandyStormMutex == true) or (getgenv().IsTrickOrTreatActiveRunning == true) or (getgenv().TrickOrTreatMutex == true) or (isCollectingCandyMutex == true) or (isTrickOrTreatMutex == true)
end

-- ลำดับ 1 (ตีบอสโลก): ให้ความสำคัญสูงสุดเมื่อประตูบอสเปิด
local function CanRunWorldBoss()
    local ok, res, reason = pcall(function()
        return true
    end)
    if not ok then return false, tostring(res) end
    return res, reason
end

-- ลำดับ 3 (ฮาโลวีน): ทำงานได้เมื่อไม่มีการเทรด และไม่ได้กำลังตีบอสโลก
local function CanRunHalloween()
    local ok, res, reason = pcall(function()
        if isBossActiveLock or getgenv().IsBossActiveLock or isWorldBossTransitioning or IsWorldBossActive() then
            return false, "Priority 1 Active: World Boss in progress"
        end
        if IsTradeActive() then return false, "Priority 2 Active: Trade in progress" end
        return true
    end)
    if not ok then return false, tostring(res) end
    return res, reason
end

-- ลำดับ 4 (หอคอย): ทำงานได้เมื่อ World Boss, Trade, Halloween ไม่ได้ทำงาน
local function CanRunTower()
    local ok, res, reason = pcall(function()
        if isBossActiveLock or getgenv().IsBossActiveLock or isWorldBossTransitioning then
            return false, "Priority 1 Active: World Boss lockout in progress"
        end
        if IsWorldBossActive and IsWorldBossActive() then
            return false, "Priority 1 Active: World Boss in progress"
        end
        if isArenaTransitionLock or getgenv().IsArenaTransitionActive then
            return false, "Priority 0 Active: Arena/Tower transition in progress"
        end
        if IsTradeActive() then return false, "Priority 2 Active: Trade in progress" end
        if IsHalloweenActive() then return false, "Priority 3 Active: Halloween Event in progress" end
        if IsFeatureUnlocked and not IsFeatureUnlocked("Towers", "towers") then return false, "Towers not unlocked in tree" end
        return true
    end)
    if not ok then return false, tostring(res) end
    return res, reason
end

local scriptStartupTimestamp = tick()

-- ลำดับ 5 (สุ่มฟาร์มทั่วไป): ทำงานได้เมื่อ World Boss, Trade, Halloween ไม่ได้ทำงาน
local function CanRunGeneralFarm()
    local ok, res, reason = pcall(function()
        if tick() - scriptStartupTimestamp < 4.0 then
            return false, "Startup grace period in progress (waiting 4.0s)"
        end
        if isBossActiveLock or getgenv().IsBossActiveLock or isWorldBossTransitioning or IsWorldBossActive() then
            return false, "Priority 1 Active: World Boss in progress"
        end
        if isArenaTransitionLock or getgenv().IsArenaTransitionActive then
            return false, "Priority 0 Active: Arena/Tower transition in progress"
        end
        if IsTradeActive() then return false, "Priority 2 Active: Trade in progress" end
        if isCollectingCandyMutex or getgenv().CandyStormMutex or isTrickOrTreatMutex or getgenv().TrickOrTreatMutex then
            return false, "Priority 3 Active: Halloween Event in progress"
        end
        return true
    end)
    if not ok then return false, tostring(res) end
    return res, reason
end

local function GetTradeReadyButton()
    local tp = GetTradeWindow()
    if not tp then return nil, "" end
    local readyFrame = tp:FindFirstChild("Ready", true)
    if not readyFrame then return nil, "" end
    local face = readyFrame:FindFirstChild("Face") or readyFrame:FindFirstChildWhichIsA("TextButton", true)
    local lbl = readyFrame:FindFirstChildWhichIsA("TextLabel", true); return face, (lbl and lbl.Text or "")
end

local LastRemoteFire = {}
local RemoteRateLimits = {
    RollTrait = 0.35,        -- ปรับเป็น 0.35s เพื่อความปลอดภัยบน UGPhone
    RollGrade = 0.35,        -- ปรับเป็น 0.35s เพื่อความปลอดภัยบน UGPhone
    UpgradePet = 0.45,       -- อัปเกรดเลเวลสัตว์เลี้ยง
    UpgradePetLevels = 0.45,
    BuyAllUpgrades = 1.80,   -- ป้องกันการยิงรัวซื้ออัปเกรดต้นไม้
    MarketBuyAll = 2.00,     -- ป้องกันการยิงรัวกวาดซื้อของในตลาด
    MarketBuy = 0.60,        -- ซื้อของชิ้นเดี่ยวในตลาด
    Teleport = 3.50,         -- ป้องกัน Error 600 / Teleport State Collision / Desync
    TowerStart = 3.50,       -- ป้องกัน Tower Spurt
    TowerExit = 3.00,
    TowerLeave = 3.50,
    WorldBossJoin = 3.50,
    WorldBossLeave = 3.00,
    Rebirth = 2.50,
    UsePotion = 0.50,
    OpenLootBag = 1.00,
    QuestClaim = 0.50,
    GoalClaim = 0.50,
    ClaimDaily = 1.20,
    ClaimPlaytime = 1.20,
    ClaimSocial = 1.20,
    SendExpedition = 1.20,
    ClaimExpedition = 1.00,
    TradeRequest = 3.00,     -- เว้นระยะอย่างน้อย 3.00s ต่อการส่งคำขอเทรด ป้องกันการสแปม
    TradeRespond = 2.00,     -- เว้นระยะ 2.00s ต่อการตอบรับคำขอเทรด
    TrickOrTreat = 2.50,     -- เว้นระยะ 2.50s ต่อการขอขนมฮาโลวีน ป้องกัน Error 267
    SpookyBuy = 1.50,        -- เว้นระยะ 1.50s ต่อการซื้อของร้าน Spooky Shop
    HalloweenGoalClaim = 1.50, -- เว้นระยะ 1.50s ต่อการเคลมรางวัลฮาโลวีน
    TradeReady = 2.00,       -- เว้นระยะ 2.00s ต่อการกด Ready/Unready
    TradeItem = 0.40,        -- เว้นระยะ 0.40s ต่อการวางไอเทมลงในช่องเทรด
    TradeAddPets = 0.50,     -- เว้นระยะ 0.50s ต่อการใส่สัตว์เลี้ยงลงในช่องเทรด
    TradeRemovePets = 0.50,  -- เว้นระยะ 0.50s ต่อการดึงสัตว์เลี้ยงออกจากช่องเทรด
    TradeCancel = 1.50,      -- เว้นระยะ 1.50s ต่อการกดยกเลิกการเทรด
    BuyDice = 1.80,
    EquipDice = 0.80,
    EquipBest = 2.50,
    SellKeys = 0.80,
    ClaimLootPets = 1.00,
    Roll = 0.80,             -- ทอยเต๋า ตาม Cooldown ของเกม ป้องกัน Server Spam Count
    SetAuto = 1.50,          -- สลับสถานะ Auto Roll
    SetSetting = 1.00,       -- บันทึกการตั้งค่า
    PortalRepair = 3.00,     -- ซ่อมแซมประตูบอสโลก
    BuyUpgrade = 0.60,       -- ซื้ออัปเกรดเดี่ยว
}

-- Global Zone Transition Serialization & Anti-Conflict State Machine
-- ป้องกันการส่งคำสั่งเปลี่ยนแมพ/อารีน่าซ้อนกัน (Tower, Boss, Teleport) ซึ่งเป็นสาเหตุหลักของ Error 267
local LastZoneTransitionTime = 0
local isZoneTransitionLocked = false
local isArenaTransitionLock = false
local lastArenaTransitionLockTime = 0
getgenv().IsArenaTransitionActive = false
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
local GetCurrentTowerFloor
local UpdateTowerStatus
local ResolveTowerId
local LeaveTowerCleanly
local ExitArenaCleanly
local isSwitchingTower = false
-- IsEnteringBossPortal declared above in top-level priority scope
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
    EndedTick = 0,
    LastFloorTime = 0
}
local function IsPlayerAtHomePlot()
    local char = LocalPlayer.Character or Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return true end
    
    local pos = hrp.Position
    local distCenter = Vector3.new(pos.X, 0, pos.Z).Magnitude
    
    -- ลานพลาซ่า/ฮับศูนย์กลาง (Hub Plaza) มีรัศมีประมาณ 110 studs จากจุดกึ่งกลาง (0,0)
    if distCenter < 110 then
        return false
    end
    
    -- พื้นที่หน้าประตูบอสโลกและตลาด (World Boss Portal / Market) อยู่ที่ Z = -298
    local distBossPortal = (pos - Vector3.new(0, 17.85, -298)).Magnitude
    if distBossPortal < 140 then
        return false
    end
    
    -- ตรวจสอบตำแหน่งแปลงบ้านของผู้เล่น
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        local uid = LocalPlayer.UserId
        for _, p in ipairs(plots:GetChildren()) do
            local ownerId = p:GetAttribute("OwnerId") or p:GetAttribute("Owner")
            if ownerId and (tonumber(ownerId) == uid or tostring(ownerId) == tostring(uid)) then
                local cf, sz = p:GetBoundingBox()
                local d = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(cf.Position.X, 0, cf.Position.Z)).Magnitude
                if d <= 180 then
                    return true
                end
            end
        end
    end
    
    return distCenter >= 140
end
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
getgenv().NeedEquipBest = false
getgenv().IsEquipBestPending = false

-- Trade Deferred Action Queue (จัดคิวคำสั่งอื่นที่เข้ามาขณะกำลังเทรด ให้รอทำตามลำดับหลังจากเทรดเสร็จ)
local TradeDeferredQueue = {}
local MAX_TRADE_DEFERRED_QUEUE = 40
local isFlushingTradeQueue = false

-- Centralized Remote Dispatcher Queue (100% Single-Threaded Anti-Collision & Anti-Kick Dispatcher)
-- ป้องกันการยิงคำสั่งพร้อมกันในเฟรมเดียวกัน (Single-Threaded FIFO Serializer)
local RemoteQueue = {}
getgenv().RemoteQueue = RemoteQueue

local function ClearQueueDuringTransition()
    pcall(function()
        if #RemoteQueue > 0 then
            local cleaned = {}
            for _, item in ipairs(RemoteQueue) do
                if item.action == "TowerExit" or item.action == "TowerStart" or item.action == "SetSetting" or item.action == "TowerLeave" then
                    table.insert(cleaned, item)
                end
            end
            table.clear(RemoteQueue)
            for _, item in ipairs(cleaned) do
                table.insert(RemoteQueue, item)
            end
        end
    end)
end
local LoopHeartbeats = {}
getgenv().LoopHeartbeats = LoopHeartbeats
local MIN_GLOBAL_REMOTE_INTERVAL = 0.28 -- ปรับเป็น 0.28s เพื่อรองรับปิงแกว่งบน UGPhone และ Cloud Emulators
local LastGlobalRemoteFireTime = 0

-- Global Token Bucket Rate Limiter (ป้องกันการยิงพร้อมกันจากทุกฟังก์ชันเกินขีดจำกัดเซิร์ฟเวอร์)
-- ขีดจำกัดเซิร์ฟเวอร์ของตัวเกมแท้: PerSecond = 12, Burst = 24
-- ขีดจำกัดความปลอดภัยขั้นสูงสุดของสคริปต์สำหรับ PC และ UGPhone: PerSecond = 3.0, MaxBurst = 6.0
local GlobalTokenBucket = {
    Tokens = 6.0,
    MaxTokens = 6.0,
    RefillRate = 3.0,  -- เติม 3 token ต่อวินาที (ต่ำกว่าเซิร์ฟเวอร์ถึง 75% ป้องกันเซิร์ฟเวอร์เตะ Error 267 แน่นอน 100%)
    LastRefill = tick(),
    Costs = {
        RollTrait = 0.5,
        RollGrade = 0.5,
        TrickOrTreat = 2.0,
        SpookyBuy = 1.0,
        HalloweenGoalClaim = 1.0,
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
        BuyAllUpgrades = 2.0,
        Teleport = 2.5,
        TowerStart = 2.5,
        WorldBossJoin = 2.5,
        PortalRepair = 2.0,
        Rebirth = 2.0,
        Menu = 0,
        -- รายการอื่นๆ มี Cost เริ่มต้นเป็น 1.0 ตามระบบเกม
    }
}

IsFeatureUnlocked = function(featureName, idName)
    local data = State.Data
    local u = data and data.Upgrades
    if not u then return false end
    local openByFunc = false
    if Upgrades and Upgrades.IsOpen then
        local ok, res = pcall(function() return Upgrades.IsOpen(u, featureName) end)
        if ok and res == true then openByFunc = true end
    end
    local openById = (u[idName] or 0) > 0 or (u[featureName] or 0) > 0; return openByFunc == true or openById == true
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

Fire = function(...) 
    local args = {...}
    local action = args[1]
    if typeof(action) ~= "string" then
        if State and type(State.Send) == "function" then
            State.Send(unpack(args))
        else
            Action:FireServer(unpack(args))
        end
        return
    end

    -- 0. ระบบความปลอดภัย: Cloud Kill-Switch เท่านั้น
    if getgenv().EmergencyCloudHalt then
        return -- ตัดการส่งคำสั่งเฉพาะเมื่อผู้พัฒนาสั่งหยุดฉุกเฉินจาก Cloud เท่านั้น
    end

    -- 0.04 Master Boss Lockout (หยุดการยิงคำสั่งอื่นทั้งหมดทันทีเมื่อประตูบอสเปิดหรือกำลังตีบอสโลก)
    local BossAllowedActions = {
        WorldBossJoin = true,
        WorldBossLeave = true,
        TowerLeave = true,
        TowerExit = true,
        Teleport = true,
        SetSetting = true,
    }
    if (isBossActiveLock or getgenv().IsBossActiveLock or isWorldBossTransitioning) and not BossAllowedActions[action] then
        return -- ตัดคำสั่งทั้งหมดออกทันทีระหว่างช่วงเปิดประตูบอสและสู้บอส
    end

    -- 0.05 Master Arena & Tower Transition Lockout (ตัดการยิงคำสั่งอื่นทั้งหมดทันทีระหว่างเข้าหอคอยหรือออกจากอารีน่า)
    local TransitionAllowedActions = {
        TowerStart = true,
        TowerExit = true,
        TowerLeave = true,
        SetSetting = true,
    }
    if (isArenaTransitionLock or getgenv().IsArenaTransitionActive) and not TransitionAllowedActions[action] then
        return -- ตัดคำสั่งทั้งหมดออกทันทีระหว่างช่วงเปลี่ยนผ่าน
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
    if action == "RollGrade" and not IsFeatureUnlocked("Grades", "grades") then return
    end
    if action == "RollTrait" and not IsFeatureUnlocked("Traits", "traits") then return
    end
    if (action == "UpgradePet" or action == "UpgradePetLevels") and not IsFeatureUnlocked("PetUpgrades", "petup") then return
    end
    if (action == "SendExpedition" or action == "ClaimExpedition") and not IsFeatureUnlocked("Expeditions", "expeditions") then return
    end
    if action == "TowerStart" then
        if not IsFeatureUnlocked("Towers", "towers") then
            return
        end
        local towerId = args[2]
        local team = args[3]
        if not towerId or not team or type(team) ~= "table" or #team == 0 then return -- ไม่มีหอคอยหรือไม่มีสัตว์เลี้ยงในทีม ไม่ส่งเด็ดขาด ป้องกัน Error 267
        end
        if IsHalloweenActive() then
            return -- ห้ามเริ่มหอคอยเด็ดขาดหากกิจกรรมฮาโลวีนหรือพายุลูกกวาดกำลังทำงาน (Priority 3 เหนือกว่า Priority 4)
        end
        if IsWorldBossActive and IsWorldBossActive() then
            return -- ป้องกันการเริ่มหอคอยระหว่างศึกบอสโลก (Priority 2 เหนือกว่า Priority 4)
        end
        if (LiveTower and LiveTower.Active == true and not LiveTower.Starting) then return -- ป้องกันการยิง TowerStart ซ้ำซ้อนขณะที่อยู่ในหอคอยอยู่แล้ว (ป้องกัน Error 267)
        end
        if (tick() - (LastRemoteFire["TowerLeave"] or 0) < 3.0) then
            return -- หน่วง 3.0 วินาทีหลังออกจากหอคอย ให้เซิร์ฟเวอร์เคลียร์สถานะอย่างสมบูรณ์
        end
    end
    if action == "TowerLeave" then
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local hud = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI:FindFirstChild("Root") and pg.PetDiceUI.Root:FindFirstChild("Hud")
        local inUi = hud and ((hud:FindFirstChild("TowerTracker") and hud.TowerTracker.Visible) or (hud:FindFirstChild("Battle") and hud.Battle.Visible))
        local d = State.Data
        local inTower = inUi or (IsTowerRunning and IsTowerRunning()) or (d and d.TowerResume ~= nil)
        if not inTower then
            return -- ไม่ได้อยู่ในหอคอย ไม่ส่งคำสั่งออกจากหอ
        end
    end
    if action == "TowerExit" then
        if IsWorldBossActive and IsWorldBossActive() then
            return -- บอสโลกทำงาน ไม่ส่งคำสั่ง TowerExit
        end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local hud = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI:FindFirstChild("Root") and pg.PetDiceUI.Root:FindFirstChild("Hud")
        local inArenaUi = hud and hud:FindFirstChild("Battle") and hud.Battle.Visible
        if not inArenaUi and (not IsTowerInArena or not IsTowerInArena()) then
            return -- ไม่ได้อยู่ในอารีน่าจริง ไม่ส่ง TowerExit
        end
    end
    if action == "WorldBossJoin" then
        if not IsFeatureUnlocked("WorldBoss", "worldboss") then return end
        local wbState = RS:GetAttribute("WorldBossState")
        if wbState ~= "Joining" then
            return -- บอสโลกยังไม่เปิดให้เข้าร่วม (ไม่ใช่สถานะ Joining) ห้ามส่งเด็ดขาด ป้องกัน Error 267
        end
        if LocalPlayer:GetAttribute("WorldBossJoined") == true or LocalPlayer:GetAttribute("InWorldBoss") == true then
            return -- เข้าร่วมอยู่แล้ว ไม่ส่งซ้ำ
        end
        local d = State.Data
        if not d or not d.PortalRepaired then
            return -- ประตูยังไม่ได้ซ่อมแซม ห้ามเข้าร่วม
        end
        local char = LocalPlayer.Character or Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local p = (workspace:FindFirstChild("Market") and workspace.Market:FindFirstChild("WorldBossPortal")) or workspace:FindFirstChild("WorldBossPortal", true)
        local spot = p and (p:FindFirstChild("PromptSpot") or p:FindFirstChild("JoinZone"))
        local bossPortalPos = spot and spot.Position or Vector3.new(0, 17.85, -298.0)
        if not hrp or (hrp.Position - bossPortalPos).Magnitude > 14 then
            return -- ต้องอยู่ใกล้หน้าประตูบอสโลกไม่เกิน 14 studs (PromptSpot 16 studs) ป้องกัน Error 267
        end
        if hrp.AssemblyLinearVelocity.Magnitude > 0.25 then
            local waitStop = tick()
            while hrp and hrp.AssemblyLinearVelocity.Magnitude > 0.25 and (tick() - waitStop < 1.5) do
                task.wait(0.1)
            end
            if not hrp or hrp.AssemblyLinearVelocity.Magnitude > 0.25 then return end
        end
        if (tick() - (LastRemoteFire["Teleport"] or 0) < 2.5) then
            return -- ต้องรอหลังเทเลพอร์ตอย่างน้อย 2.5 วิ ให้เซิร์ฟเวอร์ Sync พิกัดตัวละครให้ตรงกัน 100%
        end
    end
    if action == "WorldBossLeave" then
        if not IsFeatureUnlocked("WorldBoss", "worldboss") then return end
        local isJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if not isJoined then return end
    end
    if action == "PortalRepair" then
        return -- ปิดกั้นการส่งรีโมต PortalRepair เด็ดขาด เนื่องจากตัวเกมแท้ต้องทำเควสต์หยิบ Keystone วิ่งไปส่งหน้าประตูก่อน การยิงรีโมตตรงส่งผลให้เซิร์ฟเวอร์ตรวจพบความผิดปกติและตัดการเชื่อมต่อ Error 267
    end
    if action == "Teleport" then
        local dest = args[2]
        if dest ~= "Home" and dest ~= "Hub" then
            return -- ป้องกัน Error 267 เด็ดขาด: ปลายทาง Teleport ของตัวเกม Pet Dice มีเพียง "Home" และ "Hub" เท่านั้น
        end
    end
    if action == "BuyUpgrade" and args[2] == "worldboss" and not IsFeatureUnlocked("PetUpgrades", "petup") then return
    end
    if (action == "MarketBuyAll" or action == "MarketBuy") and not IsFeatureUnlocked("Market", "market") then return
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
        if (IsTowerInArena and IsTowerInArena()) or (IsInTrade and IsInTrade()) or getgenv().TradeActiveSession then return end
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
        if IsInTrade and (IsInTrade() or getgenv().TradeActiveSession) then return end
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
    if action == "BuyDice" then
        local diceId = args[2]
        if not diceId or not data or not data.OwnedDice or not Config.Dice then return end
        if data.OwnedDice[diceId] == true then return end -- มีอยู่แล้ว ไม่ซื้อซ้ำ
        local diceDef = nil
        for _, d in ipairs(Config.Dice) do
            if d.Id == diceId then diceDef = d; break end
        end
        if not diceDef or (data.Money or 0) < (diceDef.Cost or 0) then return end
    end
    if action == "TrickOrTreat" then
        if not CanTrickOrTreat or not CanTrickOrTreat() then
            return -- ยังติดคูลดาวน์ Trick or Treat หรือขอไปแล้ว
        end
        local canH, reason = CanRunHalloween()
        if not canH then return end
        local char = LocalPlayer.Character or Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local pawculaPos = Vector3.new(38.9, 2.25, -38.4)
        if not hrp or (hrp.Position - pawculaPos).Magnitude > 10 then
            return -- ต้องอยู่ใกล้เคานต์พาวคูลาในระยะปลอดภัย (Prompt 12 studs) ป้องกันเซิร์ฟเวอร์เตะ Error 267
        end
        if hrp.AssemblyLinearVelocity.Magnitude > 0.5 then
            local waitStop = tick()
            while hrp and hrp.AssemblyLinearVelocity.Magnitude > 0.5 and (tick() - waitStop < 1.0) do
                task.wait(0.1)
            end
            if not hrp or hrp.AssemblyLinearVelocity.Magnitude > 0.5 then return end
        end
    end
    if action == "SpookyBuy" then
        local canH, reason = CanRunHalloween()
        if not canH then return end
        local itemKey = args[2]
        if not itemKey then return end
        local itemDef = HalloweenShopConfig and ((HalloweenShopConfig.ById and HalloweenShopConfig.ById[itemKey]) or (HalloweenShopConfig.Items and HalloweenShopConfig.Items[itemKey]))
        if not itemDef then return end -- ไอเทมไม่มีอยู่จริงในร้าน ไม่ส่ง
        local entry = GetHalloweenEntry and GetHalloweenEntry()
        if itemKey == "LimitedPull" then
            local maxStock = (itemDef and itemDef.Stock) or 10
            local boughtPulls = entry and entry.Bought and (entry.Bought.LimitedPull or entry.Bought.HalloweenPull or entry.Bought.SinglePull) or 0
            if boughtPulls >= maxStock then return end -- ซื้อครบโควต้าตามแพทช์ v172 แล้ว ไม่ส่งซ้ำ
        end
        local candyCost = itemDef.Price or 0
        local candyHave = (entry and entry.Candy) or (data and (data.Candy or data.Candies or (data.Halloween and data.Halloween.Candy))) or 0
        if candyCost > 0 and candyHave < candyCost then
            return -- ลูกอมไม่พอซื้อ ยกเลิกทันที ไม่ยิงไปเซิร์ฟเวอร์
        end
    end
    if action == "HalloweenGoalClaim" then
        local canH, reason = CanRunHalloween()
        if not canH then return end
        local goalId = args[2]
        local entry = GetHalloweenEntry and GetHalloweenEntry()
        if not goalId or not entry then return end
    end
    if action == "EquipBest" then
        if IsTowerInArena and IsTowerInArena() then return end
        if IsHalloweenActive() then return end
        local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if isBoss or IsEnteringBossPortal == true then return end
        if IsInTrade and (IsInTrade() or getgenv().TradeActiveSession) then return end
        if isZoneTransitionLocked then return end
        if isAutoSellingActive or isPetEnhanceRolling then return end
    end
    if action == "EquipDice" then
        if IsTowerInArena and IsTowerInArena() then return end
        if IsHalloweenActive() then return end
        local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if isBoss or IsEnteringBossPortal == true then return end
        if IsInTrade and (IsInTrade() or getgenv().TradeActiveSession) then return end
        if isZoneTransitionLocked then return end
        local diceId = args[2]
        if not diceId or not data or not data.OwnedDice then return end
        if not data.OwnedDice[diceId] then return end -- ยังไม่ได้เป็นเจ้าของ ห้ามส่งคำสั่ง
        if data.Dice == diceId then return end -- สวมใส่อยู่แล้ว ไม่ส่งซ้ำ
    end
    if action == "SellKeys" then
        if IsInTrade and (IsInTrade() or getgenv().TradeActiveSession) then return end
        local keys = args[2]
        if not keys or type(keys) ~= "table" or #keys == 0 then return end
    end
    if action == "UsePotion" then
        local potKey = args[2]
        if not data or not data.Potions or (data.Potions[potKey] or 0) <= 0 then
            return -- ไม่มีน้ำยาจริงในคลัง ยกเลิกทันที ไม่ยิงไปเซิร์ฟเวอร์
        end
    end
    if action == "Rebirth" then
        if IsTowerInArena and IsTowerInArena() then return end
        if IsHalloweenActive() then return end
        local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if isBoss or IsEnteringBossPortal == true then return end
        if IsInTrade and (IsInTrade() or getgenv().TradeActiveSession) then return end
        if isZoneTransitionLocked then return end
        local cost = Stats and Stats.RebirthCost and Stats.RebirthCost(data)
        if not cost or not data or (data.Money or 0) < cost then
            return -- เงินไม่พอเกิดใหม่ ยกเลิกทันที
        end
    end
    if action == "Roll" then
        local nowRoll = tick()
        local lastRoll = LastRemoteFire["Roll"] or 0
        if (nowRoll - lastRoll < 0.60) then return end
        if State.Rolling and (nowRoll - lastRoll < 1.2) then return end
        if IsTowerInArena and IsTowerInArena() then return end
        local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if isBoss or IsEnteringBossPortal == true then return end
        if IsInTrade and (IsInTrade() or getgenv().TradeActiveSession) then return end
    end
    if action == "SetAuto" then
        local val = args[2]
        if type(val) ~= "boolean" then return end
        if State.Auto == val then return end
    end
    if action == "SetSetting" then
        local sKey = args[2]
        local sVal = args[3]
        if not sKey or type(sKey) ~= "string" then return end
        if data and data.Settings and data.Settings[sKey] == sVal then return end
    end
    if action == "Teleport" then
        if IsTowerInArena and IsTowerInArena() then
            return -- ห้ามส่งคำสั่ง Teleport เด็ดขาดขณะอยู่ใน 3D Battle Arena ของหอคอย (ต้องอยู่ใน Away Mode ก่อน) ป้องกัน Error 267
        end
        local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if isBoss or IsEnteringBossPortal == true then return -- ห้ามส่งคำสั่ง Teleport ขณะกำลังสู้บอสโลก ป้องกัน Error 267
        end
        if IsInTrade and (IsInTrade() or getgenv().TradeActiveSession) then
            return -- ห้ามส่งคำสั่ง Teleport ระหว่างเทรด
        end
        
        local dest = args[2]
        if dest ~= "Home" and dest ~= "Hub" then
            return -- ป้องกัน Error 267 เด็ดขาด: ปลายทาง Teleport มีเพียง "Home" และ "Hub" เท่านั้น
        end
        
        -- ตรวจสอบตัวละครและสภาพร่างกายก่อนวาร์ป ป้องกัน desync และ Error 600
        local char = LocalPlayer.Character or Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hum or not hrp or hum.Health <= 0 then
            return
        end
        
        local mag = Vector3.new(hrp.Position.X, 0, hrp.Position.Z).Magnitude
        if dest == "Hub" and mag < 120 then return -- อยู่ในลานพลาซ่า/ฮับศูนย์กลางอยู่แล้ว ห้ามส่ง Teleport Hub ซ้ำ ป้องกัน Error 267
        end
        if dest == "Home" and IsPlayerAtHomePlot() and not (IsTowerRunning and IsTowerRunning()) then return -- อยู่ในพื้นที่บ้าน (Home Plot) ของตัวเองอยู่แล้ว ไม่ต้องส่ง Teleport Home ซ้ำ ป้องกัน Error 267
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
                    foundDiff = d; break
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
                foundExp = exp; break
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
                if gd.Id == gId then gDef = gd; break end
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
    if action == "SocialStart" then
        local sType = args[2]
        if not data or not data.Social then return end
        if sType == "Like" then
            if data.Social.Like then return end
            local waitSec = (Config and Config.Social and Config.Social.LikeWaitSeconds) or 20
            getgenv().SocialLikeReadyTime = os.clock() + waitSec
        end
    end
    if action == "ClaimSocial" then
        local sType = args[2]
        if not data or not data.Social then return end
        if sType == "Group" then
            if data.Social.Group then return end
            local isInGroup = false
            pcall(function() isInGroup = LocalPlayer:IsInGroup(3281836) end)
            if not isInGroup then return end -- ยังไม่ได้เข้ากลุ่มผู้พัฒนาจริง ห้ามยิงเด็ดขาด ป้องกันเซิร์ฟเวอร์ดักจับ
        elseif sType == "Like" then
            if data.Social.Like then return end
            if not getgenv().SocialLikeReadyTime or os.clock() < getgenv().SocialLikeReadyTime then
                return -- ต้องส่ง SocialStart และรอครบ 20 วินาทีตามกลไกทางการของเกม ป้องกันโดนแบน Error 600
            end
        end
    end
    if action == "TradeRequest" then
        local targetUserId = tonumber(args[2])
        if not targetUserId then return end
        if targetUserId == LocalPlayer.UserId then return end
        
        local targetPlayer = Players:GetPlayerByUserId(targetUserId)
        if not targetPlayer or targetPlayer.Parent ~= Players then return end
        if targetPlayer:GetAttribute("PetDiceTradeOff") == true then return end
        if targetPlayer:GetAttribute("PetDiceTradeLocked") == true then return end
        
        if not data or not Config.TradeUnlocked or not Config.TradeUnlocked(data) then return end
        -- ต้องไม่เคยอยู่ในเซสชันเทรดที่เปิดอยู่แล้ว หรือหน้าต่างเทรดเปิดอยู่แล้ว
        if getgenv().CurrentTradeSession ~= nil or (GetTradeWindow and GetTradeWindow() ~= nil) then return end
        if IsTowerInArena and IsTowerInArena() then return end
        local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if isBoss or IsEnteringBossPortal == true then return end
        if isZoneTransitionLocked then return end
        
        -- ป้องกันการยิง TradeRequest ซ้ำรัวๆ ภายใน 3 วินาที
        local lastReq = getgenv().LastTradeRequestRemoteFire or 0
        if (tick() - lastReq) < 3.0 then return end
        getgenv().LastTradeRequestRemoteFire = tick()
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
            if getgenv().TradeLockedUntil and tick() < getgenv().TradeLockedUntil then return end
        end
        local _, btnText = GetTradeReadyButton()
        if btnText and string.upper(btnText):find("WAIT") then return end
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
        
        if session and session.You and session.You.Pets then
            for _, uid in ipairs(petUids) do
                if session.You.Pets[tostring(uid)] or session.You.Pets[tonumber(uid)] then
                    return -- มีสัตว์เลี้ยงตัวนี้ในช่องเทรดอยู่แล้ว ไม่ใส่ซ้ำ
                end
            end
        end
        
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
        if session and session.You and session.You.Pets then
            local validRemove = false
            for _, uid in ipairs(petUids) do
                if session.You.Pets[tostring(uid)] or session.You.Pets[tonumber(uid)] then
                    validRemove = true; break
                end
            end
            if not validRemove then return end
        end
    end
    if action == "TradeCancel" then
        local session = getgenv().CurrentTradeSession
        if not session and (not GetTradeWindow or not GetTradeWindow()) and not getgenv().TradeActiveSession then
            return
        end
    end

    -- UGPhone & Mobile Cloud Protection: ป้องกันคิวยาวเกินไปเมื่อเครื่องแลคหรือปิงกระตุก
    if #RemoteQueue >= 10 then
        local DroppableActions = {
            Roll = true,
            RollGrade = true,
            RollTrait = true,
            SetAuto = true,
            EquipBest = true,
            BuyUpgrade = true,
            UpgradePet = true,
            UpgradePetLevels = true,
        }
        if DroppableActions[action] then
            return -- สลัดคำสั่งทั่วไปทิ้งทันทีเมื่อคิวสะสม ป้องกันการปล่อยแพ็กเก็ต Burst หลังหายแลค (100% Anti-Kick Error 267)
        end
    end

    -- ป้องกันคิวทะลักขั้นเด็ดขาด (Hard Queue Cap)
    if #RemoteQueue >= 18 then
        return
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
                
                if not getgenv().EmergencyCloudHalt and not getgenv().EmergencyPatchHalt and not getgenv().EmergencyKickLockout and not getgenv().EmergencyBanLockout and not getgenv().EmergencyStructuralHalt then
                    -- 1. ควบคุมความถี่เฉพาะของแต่ละคำสั่ง (Per-Action Rate Limiting)
                    local minInterval = RemoteRateLimits[action] or 0.15
                    local now = tick()
                    local diff = now - (LastRemoteFire[action] or 0)
                    if diff < minInterval then
                        task.wait(minInterval - diff)
                    end
                    
                    -- 2. Single-Threaded Global Inter-Packet Serializer (เว้นระยะอย่างน้อย MIN_GLOBAL_REMOTE_INTERVAL)
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
                        if State and type(State.Send) == "function" then
                            State.Send(unpack(args))
                        else
                            Action:FireServer(unpack(args))
                        end
                    end)
                else
                    table.clear(RemoteQueue)
                    task.wait(0.5)
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
    local diff = val * pct; return val + (math.random() * (diff * 2) - diff)
end

-- Human Activity & Mobile Heuristic Simulator (UGPhone & 24/7 Cloud Bot Protection)
local LastHumanActivityTime = tick()
local LastMicroIdleTime = tick()

function Humanizer.SimulateActivity()
    local now = tick()
    -- 1. Camera Yaw Drift: จำลองการหมุนมุมกล้องเบาๆ ทุก 35 - 75 วินาที เสมือนมีคนแตะหน้าจอมือถือจริง
    if now - LastHumanActivityTime >= math.random(35, 75) then
        LastHumanActivityTime = now
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam and cam.CameraType == Enum.CameraType.Custom then
                local currentCf = cam.CFrame
                local subtleAngle = math.rad(math.random(-30, 30) / 10) -- สุ่มหมุนเล็กน้อย -3.0 ถึง +3.0 องศา
                cam.CFrame = currentCf * CFrame.Angles(0, subtleAngle, 0)
            end
        end)
    end
    
    -- 2. Natural Micro-Idle: พักมือตามธรรมชาติ 4 - 8 วินาที ทุกๆ 20 - 30 นาที ทำลายแพทเทิร์นหุ่นยนต์ 100%
    if now - LastMicroIdleTime >= math.random(1200, 1800) then
        LastMicroIdleTime = now
        task.wait(math.random(40, 80) / 10)
    end
end

-- Telemetry Sync: ส่ง Track UI เมื่อเปิดฟังก์ชันสำคัญ ให้เซิร์ฟเวอร์เห็นเหมือนเล่นผ่าน GUI ปกติ
function Humanizer.SyncUi(panelName, isOpen)
    if State and type(State.Send) == "function" then
        pcall(function()
            State.Send("Track", "Ui", panelName, isOpen == true)
        end)
    end
end

-- Background Thread: รัน Human Activity Simulator ตลอด 24/7 สำหรับ UGPhone และ Cloud Emulators
task.spawn(function()
    while true do
        task.wait(5.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if not getgenv().EmergencyBanLockout and not getgenv().EmergencyKickLockout then
            pcall(Humanizer.SimulateActivity)
        end
    end
end)

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
        hrp = char and char:FindFirstChild("HumanoidRootPart"); return hrp and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(destination.X, 0, destination.Z)).Magnitude <= 8
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
    hrp = char and char:FindFirstChild("HumanoidRootPart"); return hrp and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(destination.X, 0, destination.Z)).Magnitude <= 10
end

-- ==============================================================================
-- 🎃 HALLOWEEN HELPER FUNCTIONS (Pawcula & Candy Storm Engine)
-- ==============================================================================
local function GetCurrentTimestamp()
    local ok, t = pcall(function() return workspace:GetServerTimeNow() end)
    if ok and t then return t end
    return os.time()
end

WalkToPawcula = function()
    local canH, blockReason = CanRunHalloween()
    if not canH then return false, blockReason end
    
    local char = LocalPlayer.Character or Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or not hrp or hum.Health <= 0 then return false end
    
    local pawculaPos = Vector3.new(38.9, 2.25, -38.4)
    local targetStand = Vector3.new(36.5, 2.25, -36.0)
    
    -- หากตัวละครอยู่ใกล้เคานต์พาวคูลาอยู่แล้ว (ไม่เกิน 15 studs) ให้ถือว่าถึงแล้วทันที
    if (hrp.Position - pawculaPos).Magnitude <= 15 then
        return true
    end
    
    -- หากกำลังอยู่ในอารีน่าหอคอย ให้ออกจากอารีน่าสู่โหมดเบื้องหลัง (Away Mode) ก่อน
    if IsTowerInArena and IsTowerInArena() then
        if ExitArenaCleanly then
            ExitArenaCleanly()
        else
            Fire("TowerExit")
        end
        Humanizer.Wait(1.5, 2.5)
        char = LocalPlayer.Character or Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return false end
    end
    
    -- หากตัวละครไม่ได้อยู่ในพลาซ่า ให้ใช้วาร์ปทางการของเกมไปที่ Hub (พลาซ่า) ก่อน ปลอดภัย 100%
    local isAlreadyInHub = not IsPlayerAtHomePlot()
    if not isAlreadyInHub then
        Fire("Teleport", "Hub")
        local tWait = tick()
        while IsPlayerAtHomePlot() and (tick() - tWait < 4.0) do
            task.wait(0.2)
        end
        char = LocalPlayer.Character or Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return false end
        if IsPlayerAtHomePlot() then
            return false, "Teleport to Hub not completed yet"
        end
    end
    
    -- คำนวณระยะทางและตั้งเวลาเดินแบบไดนามิก ป้องกันการหมดเวลากลางคัน
    local curDist = (hrp.Position - targetStand).Magnitude
    local timeLimit = math.max(16.0, math.ceil(curDist / 10.0) + 8.0)
    
    -- เดินด้วย PathfindingService ตามเส้นทางที่ปลอดภัย กระโดดข้ามสิ่งกีดขวางอัตโนมัติ ไร้การติดขัดกลางแมพ
    local reached = WalkAlongPath(targetStand, timeLimit)
    
    Humanizer.Wait(0.4, 0.8)
    char = LocalPlayer.Character or Character
    hrp = char and char:FindFirstChild("HumanoidRootPart")
    -- ตรวจสอบระยะห่างจากเคานต์พาวคูลาจริง ต้องไม่เกิน 14 studs (ตามระยะ ProximityPrompt สูงสุดของเกม)
    if hrp and (hrp.Position - pawculaPos).Magnitude <= 14 then
        return true
    end
    return false
end

IsCandyStormActive = function()
    local now = GetCurrentTimestamp()
    
    -- 1. ตรวจสอบจาก Attributes บน ReplicatedStorage.PetDice (ระบบหลักของเกม 100%)
    local okAttr, isHappeningAttr, secLeftAttr = pcall(function()
        local PetDice = RS:FindFirstChild("PetDice")
        local attrStart = PetDice and PetDice:GetAttribute("CandyStorm")
        local attrEnd = PetDice and PetDice:GetAttribute("CandyStormEnds")
        if type(attrStart) == "number" and type(attrEnd) == "number" then
            if now >= attrStart and now < attrEnd then
                return true, math.max(0, attrEnd - now)
            end
        end
        return false, 0
    end)
    if okAttr and isHappeningAttr then
        return true, secLeftAttr
    end
    
    -- 2. ระบบสำรอง: คำนวณจาก ScheduleConfig และรอบเวลา 600 วินาที (Every = 600, Lasts = 75)
    local lasts = 75
    local okCs, isHappening, secLeft = pcall(function()
        local cs = ScheduleConfig and ScheduleConfig.CandyStorm
        if cs then
            lasts = tonumber(cs.Lasts) or 75
            local curIdx = ScheduleConfig.Index(cs, now)
            local startOf = ScheduleConfig.StartOf(cs, curIdx)
            if (now - startOf) < lasts then
                return true, math.max(0, lasts - (now - startOf))
            end
        end
        return false, 0
    end)
    if okCs and isHappening then
        return true, secLeft
    end
    
    local mod = now % 600
    if mod < lasts then
        return true, math.max(0, lasts - mod)
    end
    return false, 0
end

GetSecondsUntilNextStorm = function()
    local now = GetCurrentTimestamp()
    
    local isRunning, _ = IsCandyStormActive()
    if isRunning then return 0 end
    
    local okAttr, secAttr = pcall(function()
        local PetDice = RS:FindFirstChild("PetDice")
        local attrStart = PetDice and PetDice:GetAttribute("CandyStorm")
        if type(attrStart) == "number" and attrStart > now then
            return math.max(0, attrStart - now)
        end
    end)
    if okAttr and type(secAttr) == "number" then
        return secAttr
    end
    
    local okCs, secCs = pcall(function()
        local cs = ScheduleConfig and ScheduleConfig.CandyStorm
        if cs then
            local nextStorm = ScheduleConfig.Next(cs, now)
            if type(nextStorm) == "number" and nextStorm > now then
                return math.max(0, nextStorm - now)
            end
        end
    end)
    if okCs and type(secCs) == "number" then
        return secCs
    end
    
    local mod = now % 600; return math.max(0, 600 - mod)
end

GetAvailableCandies = function()
    local list = {}
    local seen = {}
    local now = tick()
    
    for k, t in pairs(VisitedCandies) do
        if now - t > 10.0 then VisitedCandies[k] = nil end
    end
    
    -- 1. จากรายการ ActiveCandies ที่ดักจับจากแพ็กเก็ต Remote
    for id, c in pairs(ActiveCandies) do
        if c and c.Position and (now - (c.Born or 0) < 65) then
            local posKey = string.format("%.1f_%.1f", c.Position.X, c.Position.Z)
            if not VisitedCandies[id] and not VisitedCandies[posKey] then
                table.insert(list, {
                    Id = id,
                    Kind = c.Kind,
                    Position = c.Position,
                    Born = c.Born,
                    Key = id
                })
                seen[posKey] = true
            end
        else
            ActiveCandies[id] = nil
        end
    end
    
    -- 2. สำรวจจาก workspace.PetDiceCandy.Pieces ในกรณีที่สคริปต์เพิ่งโหลดตอนพายุกำลังตกอยู่
    pcall(function()
        local folder = workspace:FindFirstChild("PetDiceCandy")
        local pieces = folder and folder:FindFirstChild("Pieces")
        if pieces then
            for _, m in ipairs(pieces:GetChildren()) do
                if m:IsA("Model") and not VisitedCandies[m] then
                    local rootPart = m.PrimaryPart or m:FindFirstChild("Root") or m:FindFirstChildWhichIsA("BasePart")
                    local pos = rootPart and rootPart.Position
                    if pos and pos.Y > 1.0 and pos.Magnitude > 2.0 then
                        local posKey = string.format("%.1f_%.1f", pos.X, pos.Z)
                        if not VisitedCandies[posKey] and not seen[posKey] then
                            table.insert(list, {
                                Model = m,
                                Kind = m.Name,
                                Position = pos,
                                Born = now,
                                Key = m
                            })
                            seen[posKey] = true
                        end
                    end
                end
            end
        end
    end)
    
    return list
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
    hrp = char and char:FindFirstChild("HumanoidRootPart"); return hrp and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude <= 8
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
local EnhanceConfig = {
    GradeOptions = {
        "ZZZ (Rank 1)", "ZZ (Rank 2)", "Z+ (Rank 3)", "Z (Rank 4)",
        "SSS (Rank 5)", "SS (Rank 6)", "S+ (Rank 7)", "S (Rank 8)",
        "A+ (Rank 9)", "A (Rank 10)", "B (Rank 11)", "C (Rank 12)"
    },
    GradeRankMap = {
        ["ZZZ (Rank 1)"] = 1, ["ZZ (Rank 2)"] = 2, ["Z+ (Rank 3)"] = 3, ["Z (Rank 4)"] = 4,
        ["SSS (Rank 5)"] = 5, ["SS (Rank 6)"] = 6, ["S+ (Rank 7)"] = 7, ["S (Rank 8)"] = 8,
        ["A+ (Rank 9)"] = 9, ["A (Rank 10)"] = 10, ["B (Rank 11)"] = 11, ["C (Rank 12)"] = 12
    },
    TraitOptions = {
        "OMNIPOTENT (Rank 1)", "IMMORTAL (Rank 2)", "ALPHA (Rank 3)", "ROYAL (Rank 4)",
        "HEROIC (Rank 5)", "VALIANT (Rank 6)", "SPIRITED (Rank 7)",
        "GREEDY II (Rank 8)", "FIERCE II (Rank 9)", "STURDY II (Rank 10)"
    },
    TraitRankMap = {
        ["OMNIPOTENT (Rank 1)"] = 1, ["IMMORTAL (Rank 2)"] = 2, ["ALPHA (Rank 3)"] = 3, ["ROYAL (Rank 4)"] = 4,
        ["HEROIC (Rank 5)"] = 5, ["VALIANT (Rank 6)"] = 6, ["SPIRITED (Rank 7)"] = 7,
        ["GREEDY II (Rank 8)"] = 8, ["FIERCE II (Rank 9)"] = 9, ["STURDY II (Rank 10)"] = 10
    },
    GradeNameById = {},
    TraitNameById = {},
    UpgradeStepOptions = {
        "+1 เลเวล (ทีละ 1 ขั้น - ปลอดภัยสูงสุด)",
        "+5 เลเวล (ทีละ 5 เลเวล)",
        "+10 เลเวล (ทีละ 10 เลเวล)",
        "+25 เลเวล (ทีละ 25 เลเวล)",
        "อัปจนถึงเป้าหมายสูงสุด (Max เท่าที่เงินพอ)"
    },
    UpgradeStepMap = {
        ["+1 เลเวล (ทีละ 1 ขั้น - ปลอดภัยสูงสุด)"] = 1,
        ["+5 เลเวล (ทีละ 5 เลเวล)"] = 5,
        ["+10 เลเวล (ทีละ 10 เลเวล)"] = 10,
        ["+25 เลเวล (ทีละ 25 เลเวล)"] = 25,
        ["อัปจนถึงเป้าหมายสูงสุด (Max เท่าที่เงินพอ)"] = 999
    }
}
for _, g in ipairs(Modifiers.Grades) do
    EnhanceConfig.GradeNameById[g.Id] = g.Name
end
for _, t in ipairs(Modifiers.Traits) do
    EnhanceConfig.TraitNameById[t.Id] = t.Name
end

local function IsPetEligibleForEnhance(pet)
    if not pet then return false end
    local petId = pet.Id or pet.PetId
    if not petId then return false end
    local def = PetData and PetData.ById and PetData.ById[petId]
    if not def then return false end
    
    -- กรองสัตว์เลี้ยงประเภท Limited / Copy / Exclusive ทั้งหมด
    -- (เซิร์ฟเวอร์ปฏิเสธการอัปเลเวล / สุ่มเกรด / สุ่มเทรตสัตว์เลี้ยงเหล่านี้เด็ดขาด)
    if def.Limited == true or def.Rarity == "Limited" then return false
    end
    if def.Copy == true or def.Copies == true then return false
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
    targetRank = targetRank or (getgenv().CFG and getgenv().CFG.TargetGradeRank) or 8; return GetPetGradeRank(pet) <= targetRank
end

local function IsPetTraitLocked(pet, targetRank)
    if not IsPetEligibleForEnhance(pet) then return true end -- สัตว์เลี้ยงประเภทพิเศษไม่สามารถสุ่มเทรตได้ ให้ถือว่าล็อคข้ามเสมอ
    targetRank = targetRank or (getgenv().CFG and getgenv().CFG.TargetTraitRank) or 6; return GetPetTraitRank(pet) <= targetRank
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

-- UpgradeStepOptions merged into EnhanceConfig

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
local userUid = (LocalPlayer and LocalPlayer.UserId) or 0
local userConfigFile = string.format("PetDice_Config_%s.json", tostring(userUid))
local legacyConfigFile = "PetDice_Master_v4_Config.json"
local ConfigFile = userConfigFile

local defaultCFG = {
    Tower = true, AutoPlay = true, AutoExitArena = true,
    HalloweenAutoClaim = false,
    HalloweenAutoBuyBags = false,
    HalloweenAutoBuyLimitedPull = false,
    HalloweenAutoOpenBags = false,
    HalloweenAutoTrickOrTreat = false,
    HalloweenAutoCollectCandy = false,
    SelectedTower = "Infinity",
    SelectedTowerOption = "ด่าน 7: INFINITY TOWER (ไร้สิ้นสุด) [Infinity]",
    TowerRestartDelay = 5,
    AutoWorldBoss = false,
    WorldBossElementFilter = "[ ตีทุกธาตุ (All Elements) ]",
    WorldBossDifficultyFilter = "[ ตีทุกระดับ (All Difficulties) ]",
    PauseTowerForBoss = true,
    AutoRebirth = false, TargetRebirths = 0, AutoBuyDice = true, AutoEquipBest = true,
    Reward = true, Quest = true, Cutscene = false,
    UpgradeTree = true, UpgradeTreeDelay = 3,
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
    RollSpeed = 0.40,
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
    AutoBuyMarket = false,
    DiscordWebhookUrl = "",
    DiscordAutoNotify = false,
    DiscordNotifyInterval = 30
}

getgenv().CFG = getgenv().CFG or {}
for k, v in pairs(defaultCFG) do
    if getgenv().CFG[k] == nil then
        getgenv().CFG[k] = v
    end
end

if readfile and isfile then
    local fileToLoad = isfile(userConfigFile) and userConfigFile or (isfile(legacyConfigFile) and legacyConfigFile)
    if fileToLoad then
        pcall(function()
            local saved = HS:JSONDecode(readfile(fileToLoad))
            for k, v in pairs(saved) do getgenv().CFG[k] = v end
        end)
    end
end

-- ตั้งค่าเริ่มต้นหากยังไม่มีการเลือกหอคอย
if not getgenv().CFG.SelectedTower or getgenv().CFG.SelectedTower == "" then
    getgenv().CFG.SelectedTower = "Infinity"
    getgenv().CFG.SelectedTowerOption = "ด่าน 7: INFINITY TOWER (ไร้สิ้นสุด) [Infinity]"
end

if getgenv().CFG.TradeTarget == "[ เลือกทุกคนในห้อง ]" then
    getgenv().CFG.TradeTargetId = nil
end

if getgenv().CFG.AutoReady == nil or ((getgenv().CFG.SenderMode or getgenv().CFG.ReceiverMode) and getgenv().CFG.AutoReady == false) then
    getgenv().CFG.AutoReady = true
end

if getgenv().CFG.AutoPlay == nil then getgenv().CFG.AutoPlay = true end
if getgenv().CFG.AutoBuyDice == nil then getgenv().CFG.AutoBuyDice = true end
if getgenv().CFG.UpgradeTree == nil then getgenv().CFG.UpgradeTree = true end
if getgenv().CFG.Reward == nil then getgenv().CFG.Reward = true end
if getgenv().CFG.Quest == nil then getgenv().CFG.Quest = true end
if getgenv().CFG.AutoEquipBest == nil then getgenv().CFG.AutoEquipBest = true end

CFG = getgenv().CFG

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
pcall(function()
    local safeContainer = (gethui and gethui()) or CG
    if safeContainer then
        for _, c in ipairs(safeContainer:GetChildren()) do
            if c:IsA("ScreenGui") and (c.Name == "PetDiceFluentGui" or c.Name:find("Fluent") or c.Name:find("Rayfield")) then
                pcall(function() c:Destroy() end)
            end
        end
    end
end)

-- ==============================================================================
-- [5] LOAD FLUENT UI & SETUP WINDOW
-- ==============================================================================
-- 1. ตรวจสอบไฟล์ UI แคชในเครื่องก่อน (Potassium Workspace) เพื่อความรวดเร็วและปลอดภัยสูงสุด ไม่ต้องผ่านเครือข่าย
pcall(function()
    if isfile and readfile and isfile("fluent.lua") then
        local localSrc = readfile("fluent.lua")
        if localSrc and #localSrc > 1000 then
            local ok, res = pcall(function() return loadstring(localSrc)() end)
            if ok and res and type(res) == "table" and res.CreateWindow then
                Fluent = res
            end
        end
    end
end)

-- 2. ฟังก์ชันดาวน์โหลดแบบปลอดภัย (บายพาสบัค HttpGet ของ Potassium โดยใช้ request / http_request)
local function FetchFluentSource(url)
    local content = nil
    pcall(function() content = game:HttpGet(url, true) end)
    if not content or type(content) ~= "string" or #content < 500 then
        local req = request or http_request or (http and http.request) or (syn and syn.request)
        if req then
            pcall(function()
                local resp = req({ Url = url, Method = "GET" })
                if resp and resp.Body and #resp.Body > 500 then
                    content = resp.Body
                end
            end)
        end
    end
    return content
end

if not Fluent then
    local fluentUrls = {
        "https://raw.githubusercontent.com/markrunerppl-boop/petdicezaza/main/fluent.lua",
        "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
        "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"
    }

    for _, url in ipairs(fluentUrls) do
        local src = FetchFluentSource(url)
        if src and #src > 1000 then
            local ok, res = pcall(function() return loadstring(src)() end)
            if ok and res and type(res) == "table" and res.CreateWindow then
                Fluent = res
                pcall(function()
                    if writefile then writefile("fluent.lua", src) end
                end)
                break
            end
        end
    end
end

assert(Fluent, "Failed to load Fluent UI Library on this executor. Please ensure your executor supports HttpGet or local storage.")
getgenv().PetDiceFluent = Fluent

local Window
do
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1024, 768)
    local winWidth = math.min(590, math.max(340, vp.X - 20))
    local winHeight = math.min(480, math.max(300, vp.Y - 60))

    Window = Fluent:CreateWindow({
        Title = "Pet Dice Pro Farm",
        SubTitle = "Master Safe Edition v4.8",
        TabWidth = (winWidth < 450 and 120 or 160),
        Size = UDim2.fromOffset(winWidth, winHeight),
        Acrylic = false,
        Theme = "Darker",
        MinimizeKey = Enum.KeyCode.RightControl
    })
    getgenv().PetDiceWindow = Window
    getgenv().PetDiceFluentGui = Window and Window.Root
    if Window and Window.Root then
        pcall(function() Window.Root.Name = "PetDiceFluentGui" end)
    end

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
            local c = workspace.CurrentCamera
            local v = c and c.ViewportSize or Vector2.new(800, 600)
            local frame = win and (win.Frame or (win.Root and win.Root.Parent))
            if frame and frame:IsA("GuiObject") then
                local w = frame.AbsoluteSize.X > 100 and frame.AbsoluteSize.X or winWidth
                local h = frame.AbsoluteSize.Y > 100 and frame.AbsoluteSize.Y or winHeight
                local curX = frame.Position.X.Offset
                local curY = frame.Position.Y.Offset
                if curX < 0 or curX > (v.X - 60) or curY < 0 or curY > (v.Y - 60) then
                    local posX = math.max(10, math.floor((v.X - w) / 2))
                    local posY = math.max(10, math.floor((v.Y - h) / 2))
                    frame.Position = UDim2.fromOffset(posX, posY)
                end
            end
        end)
    end
    task.spawn(function()
        task.wait(0.3)
        EnsureWindowInViewport(Window)
    end)
end

local function Notify(title, content, duration)
    pcall(function()
        Fluent:Notify({
            Title = title,
            Content = content,
            Duration = duration or 3
        })
    end)
end

-- Floating Mobile Toggle Button (🎲) in PlayerGui / gethui
do
    local ToggleGui = Instance.new("ScreenGui")
    ToggleGui.Name = "PetDiceMobileToggle"
    ToggleGui.ResetOnSpawn = false
    ToggleGui.DisplayOrder = 999999
    local safeToggleParent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
    ToggleGui.Parent = safeToggleParent
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

    ToggleBtn.Activated:Connect(function()
        Window:Minimize()
    end)
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
    Halloween  = Window:AddTab({ Title = "อีเวนต์ฮาโลวีน", Icon = "ghost" }),
    Trade      = Window:AddTab({ Title = "ระบบเทรดปลอดภัย", Icon = "arrow-left-right" }),
    Settings   = Window:AddTab({ Title = "ความปลอดภัย & ตั้งค่า", Icon = "shield" }),
    Discord    = Window:AddTab({ Title = "แจ้งเตือน Discord", Icon = "bell" })
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

Tabs.Overview:AddButton({
    Title = "🔓 ปลดล็อคความปลอดภัย (Reset Anti-Ban Lockout)",
    Description = "กดเพื่อรีเซ็ตสถานะตัดไฟฉุกเฉินและเริ่มการทำงานสคริปต์ใหม่ทันทีเมื่อไอดีพ้นโทษแบน",
    Callback = function()
        getgenv().EmergencyBanLockout = false
        getgenv().EmergencyKickLockout = false
        getgenv().SecurityStatusMessage = string.format("ระบบปลอดภัย Game Patch v%d", game.PlaceVersion)
        local userUidStr = tostring(LocalPlayer and LocalPlayer.UserId or "0")
        local kickLogFile = string.format("petdice_kick_guard_%s.json", userUidStr)
        local banLogFile = string.format("petdice_ban_guard_%s.json", userUidStr)
        if delfile then
            pcall(function() delfile(banLogFile) end)
            pcall(function() delfile(kickLogFile) end)
        elseif writefile then
            pcall(function() writefile(banLogFile, HS:JSONEncode({ banned = false })) end)
            pcall(function() writefile(kickLogFile, HS:JSONEncode({ count = 0 })) end)
        end
        Notify("🔓 ปลดล็อคสำเร็จ", "รีเซ็ตสถานะความปลอดภัยเรียบร้อย! สคริปต์กลับมาทำงานปกติแล้วครับ", 4)
        pcall(function() if UpdateOverviewTab then UpdateOverviewTab() end end)
    end
})

Tabs.Overview:AddSection("⚡ สวิตช์ควบคุมหลัก (Master Quick Controls)")

local TogOverviewAutoPlay, TogTowerAutoPlay
local TogOverviewAutoBuyDice, TogTowerAutoBuyDice
local TogOverviewTree, TogRebirthTree
local TogOverviewTower, TogTowerTower
local TogOverviewAutoRebirth, TogRebirthAutoRebirth
local TogOverviewRewards, TogExpeditionRewards
local isSyncingMasterToggles = false
local isUIInitializing = true

local function HandleMasterToggle(key, val, t1, t2, onNotifyTitle, onNotifyMsg, offNotifyMsg)
    UpdateCFG(key, val)
    if not isSyncingMasterToggles then
        isSyncingMasterToggles = true
        pcall(function()
            if t1 and t1.Value ~= val then t1:SetValue(val) end
            if t2 and t2.Value ~= val then t2:SetValue(val) end
        end)
        isSyncingMasterToggles = false
    end
    if not isUIInitializing then
        if val then
            if onNotifyTitle and onNotifyMsg then Notify(onNotifyTitle, onNotifyMsg, 2) end
        else
            if onNotifyTitle and offNotifyMsg then Notify(onNotifyTitle, offNotifyMsg, 2) end
        end
    end
end

TogOverviewAutoPlay = Tabs.Overview:AddToggle("TogAutoPlayOverview", {
    Title = "🎲 กลิ้งลูกเต๋าอัตโนมัติ (Auto Roll Dice)",
    Default = CFG.AutoPlay,
    Callback = function(V)
        HandleMasterToggle("AutoPlay", V, TogOverviewAutoPlay, TogTowerAutoPlay, "🎲 กลิ้งลูกเต๋า", "เปิดระบบทอยลูกเต๋าอัตโนมัติแล้ว!", "ปิดระบบทอยลูกเต๋าแล้ว")
        if isUIInitializing or isSyncingMasterToggles then return end
        if V then
            task.spawn(function()
                local data = State.Data
                if data and Stats and Stats.HasAuto and Stats.HasAuto(data, State.Mods and State.Mods() or {}) then
                    Fire("SetAuto", true)
                end
                Fire("Roll")
                if UpdateTowerStatus then task.delay(0.2, UpdateTowerStatus) end
            end)
        else
            Fire("SetAuto", false)
            if UpdateTowerStatus then task.delay(0.2, UpdateTowerStatus) end
        end
    end
})

TogOverviewAutoBuyDice = Tabs.Overview:AddToggle("TogAutoBuyDiceOverview", {
    Title = "🎲 ซื้อลูกเต๋าอัตโนมัติ (Auto Buy Dice)",
    Default = CFG.AutoBuyDice,
    Callback = function(V)
        HandleMasterToggle("AutoBuyDice", V, TogOverviewAutoBuyDice, TogTowerAutoBuyDice, "🎲 ซื้อลูกเต๋า", "เปิดระบบซื้อลูกเต๋าอัตโนมัติแล้ว!", "ปิดระบบซื้อลูกเต๋าแล้ว")
    end
})

TogOverviewTree = Tabs.Overview:AddToggle("TogTreeOverview", {
    Title = "🌳 อัปเกรดสกิลทรีอัตโนมัติ (Auto Upgrade Skill Tree)",
    Default = CFG.UpgradeTree,
    Callback = function(V)
        HandleMasterToggle("UpgradeTree", V, TogOverviewTree, TogRebirthTree, "🌳 สกิลทรี", "เปิดระบบอัปเกรดสกิลทรีอัตโนมัติแล้ว!", "ปิดระบบอัปเกรดสกิลทรีแล้ว")
    end
})

TogOverviewTower = Tabs.Overview:AddToggle("TogTowerOverview", {
    Title = "🏰 ลงหอคอยอัตโนมัติ (Auto Infinity Tower)",
    Default = CFG.Tower,
    Callback = function(V)
        HandleMasterToggle("Tower", V, TogOverviewTower, TogTowerTower, "🏰 หอคอย", "เปิดระบบลงหอคอยอัตโนมัติแล้ว!", "ปิดระบบลงหอคอยแล้ว")
        if isUIInitializing or isSyncingMasterToggles then return end
        if V and (not IsFeatureUnlocked or IsFeatureUnlocked("Towers", "towers")) then
            task.spawn(function()
                task.wait(0.2)
                local targetId = ResolveTowerId and ResolveTowerId(CFG.SelectedTower) or "Infinity"
                if SwitchOrStartTower then
                    SwitchOrStartTower(targetId, true)
                end
            end)
        elseif not V then
            if LeaveTowerCleanly then
                LeaveTowerCleanly("ปิดระบบฟาร์มหอคอยและออกจากหอเรียบร้อย")
            end
        end
    end
})

TogOverviewAutoRebirth = Tabs.Overview:AddToggle("TogAutoRebirthOverview", {
    Title = "🔄 เกิดใหม่อัตโนมัติเมื่อเงินครบ (Auto Rebirth)",
    Default = CFG.AutoRebirth,
    Callback = function(V)
        HandleMasterToggle("AutoRebirth", V, TogOverviewAutoRebirth, TogRebirthAutoRebirth, "🔄 เกิดใหม่", "เปิดระบบเกิดใหม่อัตโนมัติแล้ว!", "ปิดระบบเกิดใหม่อัตโนมัติแล้ว")
    end
})

TogOverviewRewards = Tabs.Overview:AddToggle("TogRewardsOverview", {
    Title = "🎁 รับรางวัลและเควสท์อัตโนมัติ (Auto Rewards & Quests)",
    Default = CFG.Reward,
    Callback = function(V)
        UpdateCFG("Reward", V)
        UpdateCFG("Quest", V)
        if not isSyncingMasterToggles then
            isSyncingMasterToggles = true
            pcall(function()
                if TogExpeditionRewards and TogExpeditionRewards.Value ~= V then
                    TogExpeditionRewards:SetValue(V)
                end
            end)
            isSyncingMasterToggles = false
        end
        if V then
            Notify("🎁 รางวัล & เควสท์", "เปิดระบบรับรางวัลและเควสท์อัตโนมัติแล้ว!", 2)
        else
            Notify("🎁 รางวัล & เควสท์", "ปิดระบบรับรางวัลและเควสท์แล้ว", 2)
        end
    end
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
        getgenv().NeedEquipBest = true
        Notify("🐾 สัตว์เลี้ยง", "เปิดระบบ Auto Equip Best เรียบร้อย!", 2)
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
        if isPetOperationMutex or isAutoSellingActive or isPetEnhanceRolling or getgenv().PetOperationMutex then
            Notify("⚠️ กำลังทำรายการอื่น", "กำลังจัดการสัตว์เลี้ยงอยู่ จะสวมใส่ให้อัตโนมัติเมื่อพร้อม...", 2)
            getgenv().NeedEquipBest = true; return
        end
        getgenv().NeedEquipBest = true
        Notify("⭐ สวมใส่สัตว์เลี้ยง", "ส่งคำขอสวมใส่ทีมที่ดีที่สุดเรียบร้อย!", 2)
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
                currentBatchAmounts[s.Key] = sellFromStack
                batchCount = batchCount + 1
                if batchCount >= 18 then
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
        
        if toSell == 0 or #sellBatches == 0 then return 0, kept
        end
        
        -- ส่งคำสั่งขายแบบ Humanized Batch (ป้องกัน Anti-Cheat / Rate Limit 100%)
        for bIndex, batch in ipairs(sellBatches) do
            if getgenv().PetDiceScriptToken ~= scriptToken then break end
            Fire("SellKeys", batch.keys, batch.amounts)
            if bIndex < #sellBatches then
                Humanizer.Wait(0.80, 1.20)
            end
        end
        
        return toSell, kept
    end)
    isAutoSellingActive = false
    isPetOperationMutex = false
    getgenv().PetOperationMutex = false
    getgenv().LastPetOperationStartTime = 0
    getgenv().NeedEquipBest = true
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

local RebirthStatusPara
local TreeStatusPara
local GetCurrentTowerFloor
local IsTowerRunning
local IsTowerInArena
local GetActiveTowerId

local function UpdateOverviewTab()
    pcall(function()
        local data = State.Data
        if not data then return end
        
        -- Update Overview Stats
        local moneyStr = Format.Money(data.Money or 0)
        local gemsStr = Format.Commas(data.Gems or 0)
        local shardsStr = Format.Commas(data.Shards or 0)
        local liveFloor = 0
        pcall(function()
            if GetCurrentTowerFloor then
                liveFloor = GetCurrentTowerFloor() or 0
            end
        end)
        local isRunning = IsTowerRunning and IsTowerRunning()
        local inArena = IsTowerInArena and IsTowerInArena()
        local towerFloor = liveFloor > 0 and liveFloor or (isRunning and data.TowerResume and data.TowerResume.Floor) or (data.TowerBest and (data.TowerBest.Infinity or data.TowerBest.Meadow)) or (data.TowerResume and data.TowerResume.Floor) or 0
        local modeDesc = ""
        if isRunning then
            modeDesc = inArena and " (ในอารีน่า)" or " (โหมดเบื้องหลัง Away)"
        end
        local totalPets = 0
        if data.Pets then for _ in pairs(data.Pets) do totalPets = totalPets + 1 end end
        
        SafeUpdatePara(OverviewStats, 
            string.format("💰 เงิน: %s | 💎 เพชร: %s | 🔮 ชาร์ด: %s", moneyStr, gemsStr, shardsStr),
            string.format("🏰 หอคอยชั้น: %d%s | 🐾 สัตว์เลี้ยง: %d ตัว", towerFloor, modeDesc, totalPets)
        )
        
        if SecurityStatusPara then
            if getgenv().EmergencyBanLockout then
                SafeUpdatePara(SecurityStatusPara,
                    "🚨 บัญชีติดสถานะแบน Error 600 (ระบบตัดไฟ 100%)",
                    getgenv().SecurityStatusMessage or "ระบบสั่งหยุดทำงานถาวรเพื่อป้องกันการแบนลูกโซ่ไปยังไอดีอื่นใน UGPhone/IP เดียวกัน"
                )
            elseif getgenv().EmergencyPatchHalt then
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
                    "ถูกเตะติดต่อกันเกินเกณฑ์ ระบบสั่งพักเพื่อความปลอดภัยจากการแบนถาวร"
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
                    local gName = gId and (EnhanceConfig.GradeNameById[gId] or gId) or "None"
                    local tName = tId and (EnhanceConfig.TraitNameById[tId] or tId) or "None"
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
        
        if RebirthStatusPara then
            local cost = Stats and Stats.RebirthCost and Stats.RebirthCost(data) or 0
            local curRebirths = data.Rebirths or 0
            local curMoney = data.Money or 0
            local targetR = tonumber(CFG.TargetRebirths) or 0
            
            local statusStr = "พร้อมเกิดใหม่ทันที! (เงินครบแล้ว)"
            if targetR > 0 and curRebirths >= targetR then
                statusStr = string.format("บรรลุเป้าหมายแล้ว (%d/%d ครั้ง) - หยุดเกิดใหม่อัตโนมัติ", curRebirths, targetR)
            elseif curMoney < cost then
                statusStr = string.format("เงินยังไม่พอ (ขาดอีก %s)", Format.Money(cost - curMoney))
            end
            
            local targetDesc = targetR > 0 and string.format(" | เป้าหมาย: %d ครั้ง", targetR) or " | เป้าหมาย: ไม่จำกัด"
            SafeUpdatePara(RebirthStatusPara,
                string.format("🌟 สถานะ: %s | เกิดใหม่แล้ว: %s ครั้ง%s", CFG.AutoRebirth and "เปิดอัตโนมัติ" or "ปิดอยู่", Format.Commas(curRebirths), targetDesc),
                string.format("💰 เงินปัจจุบัน: %s / ค่าเกิดใหม่: %s\n📌 ความคืบหน้า: %s", Format.Money(curMoney), Format.Money(cost), statusStr)
            )
        end
        
        if TreeStatusPara then
            local upgrades = data.Upgrades or {}
            local curMoney = data.Money or 0
            local fullyMaxed = 0
            local unmaxedRevealed = {}
            local minNextCost = nil
            local cheapestName = nil
            
            if Upgrades and Upgrades.List then
                for _, upg in ipairs(Upgrades.List) do
                    local curLvl = (Upgrades.Level and Upgrades.Level(upgrades, upg.Id)) or (upgrades[upg.Id] or 0)
                    local maxLvl = upg.Max or 1
                    if maxLvl > 0 and curLvl < maxLvl then
                        local isRev = Upgrades.Revealed and Upgrades.Revealed(upgrades, upg)
                        if isRev then
                            local cost = Upgrades.Cost and Upgrades.Cost(upg, curLvl)
                            if cost then
                                table.insert(unmaxedRevealed, { id = upg.Id, name = upg.Name, cost = cost })
                                if not minNextCost or cost < minNextCost then
                                    minNextCost = cost
                                    cheapestName = upg.Name or upg.Id
                                end
                            end
                        end
                    else
                        fullyMaxed = fullyMaxed + 1
                    end
                end
            end
            
            local planned, totalCost = nil, 0
            if Upgrades and Upgrades.PlanBuyAll then
                pcall(function()
                    planned, totalCost = Upgrades.PlanBuyAll(upgrades, curMoney, 50)
                end)
            end
            
            local canBuyCount = (planned and #planned) or 0
            local statusTitle = string.format("🌳 สถานะต้นไม้: %s | ตันแล้ว: %d/%d สกิล", CFG.UpgradeTree and "เปิดวนซื้อ" or "ปิดอยู่", fullyMaxed, (Upgrades and Upgrades.List and #Upgrades.List) or 103)
            local statusDesc = ""
            
            if canBuyCount > 0 then
                statusDesc = string.format("✨ พร้อมซื้อทันที: %d รายการ (รวม %s)\n💰 เงินปัจจุบัน: %s | ระบบกำลังวนซื้ออัตโนมัติตามคิว", canBuyCount, Format and Format.Money and Format.Money(totalCost) or tostring(totalCost), Format and Format.Money and Format.Money(curMoney) or tostring(curMoney))
            elseif #unmaxedRevealed > 0 and minNextCost then
                local diff = math.max(0, minNextCost - curMoney)
                local diffStr = diff > 0 and string.format(" (ขาดอีก %s)", Format and Format.Money and Format.Money(diff) or tostring(diff)) or ""
                statusDesc = string.format("⏳ เงินยังไม่พอซื้อขั้นถัดไป | ขั้นต่ำ: %s (%s)%s\n💰 เงินปัจจุบัน: %s | กำลังฟาร์มเงินเพื่อซื้ออัตโนมัติ", Format and Format.Money and Format.Money(minNextCost) or tostring(minNextCost), cheapestName or "Next Tier", diffStr, Format and Format.Money and Format.Money(curMoney) or tostring(curMoney))
            else
                statusDesc = "🎉 ต้นไม้ทักษะอัปเกรดครบเต็มแม็กซ์ 100% แล้ว! (ไม่มีอัปเกรดเหลือให้ซื้อ)"
            end
            
            SafeUpdatePara(TreeStatusPara, statusTitle, statusDesc)
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
task.wait()
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
        Values = EnhanceConfig.UpgradeStepOptions,
        Default = CFG.UpgradeLevelStepName or "+1 เลเวล (ทีละ 1 ขั้น - ปลอดภัยสูงสุด)",
        Multi = false,
        Callback = function(val)
            UpdateCFG("UpgradeLevelStepName", val)
            local step = EnhanceConfig.UpgradeStepMap[val] or 1
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
    Values = EnhanceConfig.GradeOptions,
    Default = CFG.TargetGradeName or "S (Rank 8)",
    Multi = false,
    Callback = function(val)
        UpdateCFG("TargetGradeName", val)
        UpdateCFG("TargetGradeRank", EnhanceConfig.GradeRankMap[val] or 8)
        UpdateOverviewTab()
    end
})

Tabs.Enhance:AddDropdown("DropTargetTrait", {
    Title = "🎯 คุณสมบัติบัฟเป้าหมายขั้นต่ำ",
    Description = "ระบบจะหยุดสุ่มบัฟทันทีเมื่อได้บัฟนี้หรือสูงกว่า",
    Values = EnhanceConfig.TraitOptions,
    Default = CFG.TargetTraitName or "VALIANT (Rank 6)",
    Multi = false,
    Callback = function(val)
        UpdateCFG("TargetTraitName", val)
        UpdateCFG("TargetTraitRank", EnhanceConfig.TraitRankMap[val] or 6)
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
                isManualUpgrading = false; return 
            end
            if not IsFeatureUnlocked("PetUpgrades", "petup") then
                Notify("⚠️ ยังไม่ปลดล็อค", "กรุณาปลดล็อค Pet Upgrades ในต้นไม้ทักษะก่อนใช้งาน", 3)
                isManualUpgrading = false; return
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
                isManualRollingGrade = false; return
            end
            if not IsFeatureUnlocked("Grades", "grades") then
                Notify("⚠️ ยังไม่ปลดล็อค", "กรุณาปลดล็อค Grades ในต้นไม้ทักษะก่อนใช้งาน", 3)
                isManualRollingGrade = false; return
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
                isManualRollingTrait = false; return
            end
            if not IsFeatureUnlocked("Traits", "traits") then
                Notify("⚠️ ยังไม่ปลดล็อค", "กรุณาปลดล็อค Traits ในต้นไม้ทักษะก่อนใช้งาน", 3)
                isManualRollingTrait = false; return
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
task.wait()
local GetActiveTowerId
local SafeWalkToBossPortal
-- isSwitchingTower forward declared
local lastLoopStartAttempt = 0
-- IsEnteringBossPortal forward declared
do -- TAB 3: TOWER & DICE
Tabs.Tower:AddSection("📊 สถานะหอคอยแบบเรียลไทม์ (Live Tower Status)")

-- ==============================================================================
-- [REAL-TIME LIVE TOWER TRACKER & DEEP GAME SYNC]
-- ==============================================================================
-- LiveTower and ResolveTowerId declared at line 550
IsEnteringBossPortal = false

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

isSwitchingTower = false
-- lastLoopStartAttempt forward declared

ResolveTowerId = function(val)
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
            if not LiveTower.Active or LiveTower.Starting then
                local tName = payload.Tower or LiveTower.TowerId or "หอคอย"
                local tDef = Towers and Towers.ById and Towers.ById[tName]
                local displayName = tDef and tDef.Name or tName
                Notify("🏰 หอคอย", "เริ่มลง [" .. tostring(displayName) .. "] ชั้น " .. tostring(payload.Floor or 1) .. " สำเร็จ!", 3)
            end
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
        LiveTower.Away = false; return
    end
    
    -- ตรวจสอบและปิดป๊อปอัปผลรางวัล LootBag ที่ค้างอยู่บนหน้าจออัตโนมัติ
    pcall(function()
        local lb = pg and pg:FindFirstChild("PetDiceLootBag")
        if lb then
            local done = lb:FindFirstChild("Done", true)
            if done and done:FindFirstChild("Face") then
                firesignal(done.Face.Activated)
            elseif done and done:IsA("GuiButton") then
                firesignal(done.Activated)
            end
        end
    end)
    
    local hud = root and root:FindFirstChild("Hud")
    local tracker = hud and hud:FindFirstChild("TowerTracker")
    local battle = hud and hud:FindFirstChild("Battle")
    
    local isAway = tracker and tracker.Visible == true
    local isArena = battle and battle.Visible == true
    
    -- ตรวจสอบว่า UI กำลังแสดงผลช่วงจบหรือนับถอยหลังรอบใหม่หรือไม่
    local isTransitioning = false
    local isRunEnded = false
    local isClearStuck = false
    local now = tick()
    
    local function checkStatusText(container)
        for _, lbl in ipairs(container:GetDescendants()) do
            if lbl:IsA("TextLabel") and lbl.Text ~= "" then
                local txt = lbl.Text:upper()
                if txt:find("NEXT RUN IN") or txt:find("STARTING...") or txt:find("VICTORY") then
                    isTransitioning = true
                elseif txt:find("DEFEAT") or txt:find("TIME'S UP") or txt:find("LEFT TOWER") or txt:find("แพ้") or txt:find("หมดเวลา") then
                    isRunEnded = true
                elseif (txt:find("CLEAR") or txt:find("เคลียร์")) and LiveTower.LastFloorTime and (now - LiveTower.LastFloorTime > 15.0) then
                    isClearStuck = true
                end
            end
        end
    end
    
    if isAway and tracker then checkStatusText(tracker) end
    if isArena and battle then checkStatusText(battle) end
    
    if isRunEnded or isClearStuck then
        LiveTower.Active = false
        LiveTower.Starting = false
        LiveTower.TowerId = nil
        LiveTower.InArena = false
        LiveTower.Away = false; return
    end
    
    -- หากกำลังอยู่ในช่วงเปลี่ยนผ่านระหว่างชั้น (VICTORY, NEXT RUN IN, STARTING...)
    -- ถือว่าหอคอยยังคงทำงานอยู่อย่างต่อเนื่อง (ห้ามเริ่มใหม่เด็ดขาด ป้องกันการส่งคำสั่งซ้อนจนโดนเตะ)
    if isTransitioning then
        LiveTower.Active = true
        LiveTower.InArena = isArena
        LiveTower.Away = isAway
        LiveTower.LastEventTime = tick(); return
    end
    
    -- 1. ดึงข้อมูลจาก UI จริงของตัวเกม (TowerTracker บน HUD หรือ Battle ในอารีน่า)
    if isAway or isArena then
        LiveTower.Active = true
        LiveTower.Starting = false
        LiveTower.JustEnded = false
        LiveTower.InArena = isArena
        LiveTower.Away = isAway
        
        -- ตรวจสอบชื่อหอคอยจาก State ของเกมเป็นอันดับแรก (Authoritative)
        local data = State and State.Data
        if data and data.TowerResume and data.TowerResume.Tower then
            LiveTower.TowerId = data.TowerResume.Tower
        end
        
        local container = (isArena and battle) or tracker
        for _, lbl in ipairs(container:GetDescendants()) do
            if lbl:IsA("TextLabel") and lbl.Text ~= "" then
                local txt = lbl.Text:upper()
                -- ตรวจสอบชื่อหอคอยเฉพาะชื่อเต็มเท่านั้น (เช่น "INFINITY TOWER", "STORM TOWER")
                -- ห้ามเช็ค t.Id เดี่ยวๆ เช่น "STORM" เพราะจะชนกับชื่อมอนสเตอร์/ธาตุจนทำให้ระบุหอคอยผิดพลาด
                for _, t in ipairs(Towers.List or {}) do
                    if txt:find(t.Name:upper(), 1, true) or txt:find(t.Id:upper() .. " TOWER", 1, true) then
                        LiveTower.TowerId = t.Id; break
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
        LiveTower.LastEventTime = tick(); return
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

GetActiveTowerId = function()
    SyncLiveTowerFromGame()
    if LiveTower.Active then
        return LiveTower.TowerId or GetCurrentOrNextTowerId(false) or "Infinity"
    end
    return nil
end

IsTowerRunning = function()
    if IsFeatureUnlocked and not IsFeatureUnlocked("Towers", "towers") then
        LiveTower.Active = false
        LiveTower.Starting = false; return false
    end
    SyncLiveTowerFromGame()
    return LiveTower.Active == true
end

IsTowerInArena = function()
    if IsFeatureUnlocked and not IsFeatureUnlocked("Towers", "towers") then
        LiveTower.InArena = false; return false
    end
    SyncLiveTowerFromGame()
    return LiveTower.Active == true and LiveTower.InArena == true
end

GetCurrentTowerFloor = function()
    SyncLiveTowerFromGame()
    if LiveTower.Active and LiveTower.Floor and LiveTower.Floor > 0 then
        return LiveTower.Floor
    end
    return 0
end

local isExitingArenaCleanly = false
ExitArenaCleanly = function(reason)
    if isExitingArenaCleanly then return end
    if not IsTowerInArena or not IsTowerInArena() then return end
    isExitingArenaCleanly = true

    -- 1. ตัดการยิงคำสั่งอื่นๆ ทั้งหมดออกทันทีตั้งแต่เสี้ยววินาทีแรก (Lockdown & Purge Queue)
    isArenaTransitionLock = true
    getgenv().IsArenaTransitionActive = true
    lastArenaTransitionLockTime = tick()
    pcall(ClearQueueDuringTransition)

    task.spawn(function()
        -- 2. หน่วงเวลาออกจากอารีน่าแบบสุ่มเวลา (Randomized Human Pre-Exit Delay: 1.5 - 2.8 วินาที)
        -- จำลองผู้เล่นกวาดสายตามองผลการต่อสู้ก่อนกดปุ่มออกจากอารีน่า
        Humanizer.Wait(1.5, 2.8)

        local fired = false
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local pdUI = pg and pg:FindFirstChild("PetDiceUI")
            local root = pdUI and pdUI:FindFirstChild("Root")
            local hud = root and root:FindFirstChild("Hud")
            local battle = hud and hud:FindFirstChild("Battle")
            local exitArena = battle and battle:FindFirstChild("ExitArena", true)
            local exitFace = exitArena and exitArena:FindFirstChild("Face")
            if exitFace and firesignal then
                pcall(function() firesignal(exitFace.Activated) end)
                fired = true
            end
        end)

        if not fired then
            pcall(function()
                Fire("TowerExit")
            end)
        end

        LastRemoteFire["TowerExit"] = tick()
        
        -- 3. รอให้ตัวเกมสลับโหมดเสร็จสมบูรณ์ (Battle หายไป และเข้าสู่ Away Mode) สูงสุด 4.0 วินาที
        local t0 = tick()
        while tick() - t0 < 4.0 do
            task.wait(0.2)
            if not IsTowerInArena or not IsTowerInArena() then break end
        end

        LiveTower.InArena = false
        LiveTower.Away = true
        
        -- 4. เมื่อออกจากอารีน่าแล้ว หน่วงเวลาแบบมนุษย์ (Randomized Human Post-Exit Settling Delay)
        -- จำลองผู้เล่นปรับตำแหน่งและมุมกล้องหลังจากวาร์ปกลับมาลานพลาซ่า (2.2 - 3.8 วินาที)
        -- โดยระหว่างนี้คำสั่งอื่นๆ ยังคงถูกตัด/ระงับอยู่ 100%
        local humanDelay = math.random(22, 38) / 10.0
        local msg = reason or string.format("ออกจากอารีน่าสู่โหมดเบื้องหลังเรียบร้อย (พักปรับตัวแบบมนุษย์ %.1fs ก่อนเริ่มคำสั่งอื่น)...", humanDelay)
        Notify("🚪 หอคอย", msg, 3)
        task.wait(humanDelay)

        -- 5. เมื่อหน่วงเวลาแบบมนุษย์เสร็จสมบูรณ์ ค่อยเริ่มรันคำสั่งอื่นๆ ตามมา (Unlock)
        isArenaTransitionLock = false
        getgenv().IsArenaTransitionActive = false
        isExitingArenaCleanly = false
        
        task.delay(0.2, function()
            if UpdateTowerStatus then UpdateTowerStatus() end
        end)
    end)
end
getgenv().ExitArenaCleanly = ExitArenaCleanly

local isLeavingTowerCleanly = false
LeaveTowerCleanly = function(reason)
    if isLeavingTowerCleanly then return end
    isLeavingTowerCleanly = true

    -- 1. ปิด Master Config และ Sync สวิตช์ UI ทั้งหมดทันที 100% ป้องกัน Loop 1 กลับมาสตาร์ท
    UpdateCFG("Tower", false)
    isSyncingMasterToggles = true
    if TogTowerTower and TogTowerTower.SetValue and TogTowerTower.Value ~= false then 
        pcall(function() TogTowerTower:SetValue(false) end) 
    end
    if TogOverviewTower and TogOverviewTower.SetValue and TogOverviewTower.Value ~= false then 
        pcall(function() TogOverviewTower:SetValue(false) end) 
    end
    isSyncingMasterToggles = false
    isSwitchingTower = false
    lastLoopStartAttempt = tick() + 10.0 -- หน่วง Loop 1 ไว้อย่างน้อย 10 วินาที

    task.spawn(function()
        -- 2. ปิด TowerAutoplay ของระบบเกมแท้ทันที เพื่อไม่ให้เซิร์ฟเวอร์เริ่มชั้นถัดไปอัตโนมัติ
        pcall(function()
            Fire("SetSetting", "TowerAutoplay", false)
        end)

        -- 3. ตรวจสอบ UI และยิงสัญญาณออกจากหอคอย
        local function triggerExitButtons()
            pcall(function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                local hud = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root:FindFirstChild("Hud")
                if hud then
                    -- หากอยู่ใน 3D Battle Arena ให้กดปุ่ม Stop (StopRun)
                    local battle = hud:FindFirstChild("Battle")
                    if battle and battle.Visible then
                        local stopRun = battle:FindFirstChild("StopRun", true)
                        local stopFace = stopRun and stopRun:FindFirstChild("Face")
                        if stopFace and firesignal then
                            pcall(function() firesignal(stopFace.Activated) end)
                            pcall(function() firesignal(stopFace.MouseButton1Click) end)
                        end
                    end

                    -- หากอยู่ในโหมดเบื้องหลัง (Away Tracker) ให้กดปุ่ม StopTower
                    local tracker = hud:FindFirstChild("TowerTracker")
                    if tracker and tracker.Visible then
                        local stopTower = tracker:FindFirstChild("StopTower", true)
                        local stopFace = stopTower and stopTower:FindFirstChild("Face")
                        if stopFace and firesignal then
                            pcall(function() firesignal(stopFace.Activated) end)
                            pcall(function() firesignal(stopFace.MouseButton1Click) end)
                        end
                    end
                end
            end)
        end

        -- ส่งสัญญาณรอบที่ 1
        triggerExitButtons()
        pcall(function()
            Fire("TowerLeave")
        end)

        -- ตรวจสอบและจัดการกรณีเกมสลับจาก Away Mode กลับมายัง Battle Arena
        local waitStart = tick()
        while tick() - waitStart < 2.0 do
            task.wait(0.2)
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local hud = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root:FindFirstChild("Hud")
            local battle = hud and hud:FindFirstChild("Battle")
            local tracker = hud and hud:FindFirstChild("TowerTracker")
            local inArena = battle and battle.Visible == true
            local inTracker = tracker and tracker.Visible == true

            if not inArena and not inTracker then
                break -- ออกจากหอคอยสำเร็จทั้งสองโหมดแล้ว
            end

            -- หากตัวเกมดีดกลับมาหน้า Battle Arena ให้กดยืนยัน StopRun ซ้ำทันที
            if inArena then
                triggerExitButtons()
                pcall(function()
                    Fire("TowerLeave")
                end)
            end
        end

        -- 4. ล้างสถานะ LiveTower ทันที
        LiveTower.Active = false
        LiveTower.Starting = false
        LiveTower.LastEventTime = 0
        LiveTower.TowerId = nil
        LiveTower.Floor = 0
        LiveTower.InArena = false
        LiveTower.Away = false
        LiveTower.LastStartTick = 0

        -- 5. ปิด BattleResults UI ทันทีหากมีเปิดขึ้นมา หรือกดปุ่ม ResultsOk
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local br = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root:FindFirstChild("Effects") and pg.PetDiceUI.Root.Effects:FindFirstChild("BattleResults")
            if br then
                if br.Visible then br.Visible = false end
                local okBtn = br:FindFirstChild("ResultsOk", true)
                local okFace = okBtn and okBtn:FindFirstChild("Face")
                if okFace and firesignal then
                    pcall(function() firesignal(okFace.Activated) end)
                end
            end
        end)

        -- 6. แจ้งเตือนผู้เล่น และอัปเดตหน้าต่าง UI
        local msg = reason or "ออกจากหอคอยและปิดระบบฟาร์มหอคอยเรียบร้อย 100%!"
        Notify("🛑 หอคอย", msg, 3)
        task.delay(0.2, function()
            if UpdateTowerStatus then UpdateTowerStatus() end
        end)
        isLeavingTowerCleanly = false
    end)
end
getgenv().LeaveTowerCleanly = LeaveTowerCleanly

local TowerStatusPara = Tabs.Tower:AddParagraph({
    Title = "⏳ กำลังโหลดสถานะหอคอย...",
    Content = "กำลังตรวจสอบชั้นและสถานะการลงหอคอย..."
})

local BossStatusPara = Tabs.Tower:AddParagraph({
    Title = "⏳ กำลังโหลดสถานะบอสโลก...",
    Content = "กำลังตรวจสอบกำหนดการและระดับของบอสโลก..."
})

SafeWalkToBossPortal = function()
    if not IsFeatureUnlocked("WorldBoss", "worldboss") then
        return false
    end
    IsEnteringBossPortal = true
    ClearQueueDuringBoss()
    local ok, res = pcall(function()
        local char = LocalPlayer.Character or Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hum or not hrp or hum.Health <= 0 then return false end
        
        -- รอให้เซิร์ฟเวอร์เคลียร์สถานะออกจากหอคอยอย่างสมบูรณ์ก่อนเริ่มเดินทาง (ป้องกัน Zone Collision / Error 267)
        local timeSinceTowerLeave = tick() - (LastRemoteFire["TowerLeave"] or 0)
        if timeSinceTowerLeave < 3.5 then
            task.wait(3.5 - timeSinceTowerLeave)
        end
        
        local portalModel = (workspace:FindFirstChild("Market") and workspace.Market:FindFirstChild("WorldBossPortal")) or workspace:FindFirstChild("WorldBossPortal", true)
        local promptSpot = portalModel and portalModel:FindFirstChild("PromptSpot")
        local targetPos = promptSpot and promptSpot.Position or Vector3.new(0, 17.85, -298)
        
        char = LocalPlayer.Character or Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return false end
        
        local distToPortal = (hrp.Position - targetPos).Magnitude
        if distToPortal <= 10 then
            return true -- ถึงหน้าประตูอยู่แล้ว
        end
        
        -- หากตัวละครอยู่ที่แปลงบ้าน (Home Plot) หรืออยู่ไกลเกิน 120 studs ให้ใช้วาร์ปไปที่ลานพลาซ่า (Hub) อย่างเป็นทางการ
        if IsPlayerAtHomePlot() or distToPortal > 120 then
            Humanizer.Wait(0.5, 1.0)
            Fire("Teleport", "Hub")
            
            local t0 = tick()
            while tick() - t0 < 4.5 do
                task.wait(0.2)
                char = LocalPlayer.Character or Character
                hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and not IsPlayerAtHomePlot() and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z).Magnitude < 110) then
                    break
                end
            end
            -- หน่วงเวลาพักหลังลงจอด เลียนแบบผู้เล่นจริงและรอเซิร์ฟเวอร์ Sync ตำแหน่ง
            Humanizer.Wait(1.5, 2.2)
        end
        
        char = LocalPlayer.Character or Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return false end
        
        -- เดินด้วยระบบ Pathfinding ตามเส้นทางขึ้นบันไดและชานชาลา (0, 17.85, -288) อย่างเป็นธรรมชาติ
        local midWayPos = Vector3.new(0, 17.85, -288)
        if (hrp.Position - midWayPos).Magnitude > 8 then
            WalkAlongPath(midWayPos, 16.0)
            Humanizer.Wait(0.2, 0.4)
        end
        
        char = LocalPlayer.Character or Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return false end
        
        -- เดินก้าวเท้าเข้าสู่โซนประตู PromptSpot (0, 17.85, -298) อย่างเป็นธรรมชาติ
        if (hrp.Position - targetPos).Magnitude > 4 then
            hum:MoveTo(targetPos)
            local walkStart = tick()
            while tick() - walkStart < 3.5 do
                task.wait(0.05)
                char = LocalPlayer.Character or Character
                hum = char and char:FindFirstChildOfClass("Humanoid")
                hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp or hum.Health <= 0 then break end
                if (hrp.Position - targetPos).Magnitude <= 4 then
                    break
                end
            end
        end
        
        -- หยุดเดินให้สนิทและรอความเร็วเป็น 0 เพื่อความสมจริงและป้องกันเซิร์ฟเวอร์ดีดกลับ
        char = LocalPlayer.Character or Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum then hum:Move(Vector3.zero) end
        
        local stopWait = tick()
        while hrp and hrp.AssemblyLinearVelocity.Magnitude > 0.15 and (tick() - stopWait < 1.5) do
            task.wait(0.1)
        end
        
        char = LocalPlayer.Character or Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - targetPos).Magnitude <= 12 then
            Humanizer.Wait(0.8, 1.5) -- ยืนนิ่งหน้าประตูอย่างปลอดภัยก่อนตอบรับ
            return true
        end
        return false
    end)
    IsEnteringBossPortal = false; return ok and res == true
end

local lastTowerStartTick = 0

local function GetTowerTeam(towerDef, teamSize)
    local data = State.Data
    if not data or not data.Pets then return {} end
    
    local targetSize = teamSize or (Towers and Towers.TeamSize) or 5
    pcall(function()
        if Towers and Towers.TeamSizeFor then
            targetSize = Towers.TeamSizeFor(data) or targetSize
        end
    end)
    
    local team = {}
    
    -- 1. คัดเลือกสัตว์เลี้ยงที่ดีที่สุดตามธาตุหอคอย หรือตามพลังสูงสุดผ่าน TeamPairs.Best (ครอบคลุมทั้ง 6 ธาตุ และ Infinity)
    if towerDef and TeamPairs and TeamPairs.Best then
        pcall(function()
            local res = TeamPairs.Best(data, towerDef, targetSize)
            if res and #res > 0 then team = res end
        end)
    end
    
    -- 2. กรณีฉุกเฉินหาก TeamPairs.Best ไม่ได้ผล ให้ใช้ Meadow เป็น fallback
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
    
    if IsFeatureUnlocked and not IsFeatureUnlocked("Towers", "towers") then
        LiveTower.Active = false
        LiveTower.Starting = false; return false, "Towers not unlocked in tree"
    end
    
    if IsWorldBossActive() then
        return false, "In World Boss (Priority 2)"
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
    
    -- 1. ตัดการยิงคำสั่งอื่นๆ ทั้งหมดออกทันที (Lockdown & Purge Queue)
    isArenaTransitionLock = true
    getgenv().IsArenaTransitionActive = true
    lastArenaTransitionLockTime = tick()
    pcall(ClearQueueDuringTransition)

    -- 2. หน่วงเวลาเข้าหอคอยแบบสุ่มเวลา (Randomized Human Pre-Start Delay: 1.5 - 2.8 วินาที)
    -- จำลองผู้เล่นกวาดตามองทีมและเลือกหอคอยก่อนเริ่ม
    Humanizer.Wait(1.5, 2.8)

    -- เปิดระบบ TowerAutoplay ของตัวเกม เพื่อให้หอคอยไต่ชั้นอัตโนมัติอย่างต่อเนื่องไร้รอยต่อ (AUTO: ON)
    pcall(function()
        if data.Settings and data.Settings.TowerAutoplay ~= true then
            Fire("SetSetting", "TowerAutoplay", true)
        end
    end)
    
    -- หน่วงเวลารอให้เซิร์ฟเวอร์เคลียร์สถานะ TowerLeave อย่างสมบูรณ์ก่อนส่งคำสั่ง TowerStart
    while (tick() - (LastRemoteFire["TowerLeave"] or 0) < 3.2) do
        task.wait(0.2)
    end
    
    -- สั่งเริ่มหอคอยผ่าน Remote Action ของเกมทันที
    Fire("TowerStart", towerDef.Id, team)
    
    LiveTower.Starting = true
    LiveTower.LastStartTick = tick()
    LiveTower.TowerId = towerDef.Id
    LiveTower.LastEventTime = tick()
    
    -- ปิดหน้าต่าง BattleResults UI ถ้ามีค้างอยู่
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local pdUI = pg and pg:FindFirstChild("PetDiceUI")
        local root = pdUI and pdUI:FindFirstChild("Root")
        local br = root and root:FindFirstChild("Effects") and root.Effects:FindFirstChild("BattleResults")
        if br and br.Visible then br.Visible = false end
    end)
    
    -- หากไม่ได้เปิด AutoExitArena ให้ปลดล็อคคำสั่งอื่นหลังเข้าอารีน่าเสร็จ
    if not CFG.AutoExitArena then
        task.spawn(function()
            Humanizer.Wait(2.0, 3.5)
            isArenaTransitionLock = false
            getgenv().IsArenaTransitionActive = false
        end)
    end

    return true
end

SwitchOrStartTower = function(targetTowerId, force)
    if IsInTrade() or getgenv().TradeActiveSession then
        return false, "In Trade"
    end
    
    if IsFeatureUnlocked and not IsFeatureUnlocked("Towers", "towers") then
        LiveTower.Active = false
        LiveTower.Starting = false; return false, "Towers not unlocked in tree"
    end
    
    if IsWorldBossActive() then
        if force then
            Notify("⚔️ บอสโลก (Priority 2)", "กำลังอยู่ในช่วงเวลากิจกรรมบอสโลก หอคอยจะเริ่มให้อัตโนมัติหลังตีบอสเสร็จสิ้น", 3)
        end
        return false, "In World Boss (Priority 2)"
    end
    
    local nowTick = tick()
    -- Hard Debounce: ป้องกันการส่งคำสั่งเริ่ม/สลับหอคอยซ้อนกันถี่เกินไป (ขั้นต่ำ 5.0 วินาทีเสมอ แม้จะส่ง force มาก็ตาม)
    if (nowTick - lastTowerStartTick < 5.0) then
        return false, "Rate limited (5s debounce)"
    end
    
    if isSwitchingTower then
        if (nowTick - (LiveTower.SwitchingTick or 0) > 5.0) then
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
    
    -- หากกำลังลงหอคอยนี้อยู่แล้ว ไม่ต้องออกจากหอคอยเด็ดขาด (ป้องกันการเตะตัวเองหลุดชั้นและรีเซ็ตกลับชั้น 1)
    if isRunning and activeTower == resolvedId then
        pcall(function()
            local d = State.Data
            if d and d.Settings and d.Settings.TowerAutoplay ~= true then
                Fire("SetSetting", "TowerAutoplay", true)
            end
        end)
        if CFG.AutoExitArena and IsTowerInArena() then
            if ExitArenaCleanly then
                ExitArenaCleanly()
            else
                Fire("TowerExit")
            end
        end
        task.delay(0.2, function() if UpdateTowerStatus then UpdateTowerStatus() end end)
        return true
    end
    
    isSwitchingTower = true
    LiveTower.SwitchingTick = nowTick
    lastTowerStartTick = nowTick
    
    local ok, res = pcall(function()
        -- หากกำลังลงหอคอยอื่นอยู่ ให้สั่งออกจากหอเดิมอย่างสมบูรณ์ก่อน
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
                local pdUI = pg and pg:FindFirstChild("PetDiceUI")
                local root = pdUI and pdUI:FindFirstChild("Root")
                local hud = root and root:FindFirstChild("Hud")
                local away = hud and hud:FindFirstChild("TowerTracker") and hud.TowerTracker.Visible == true
                local arena = hud and hud:FindFirstChild("Battle") and hud.Battle.Visible == true
                if not away and not arena then break end
            end
            
            -- ล้างหน้าต่างผลลัพธ์ BattleResults ทันที
            pcall(function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                local pdUI = pg and pg:FindFirstChild("PetDiceUI")
                local root = pdUI and pdUI:FindFirstChild("Root")
                local br = root and root:FindFirstChild("Effects") and root.Effects:FindFirstChild("BattleResults")
                if br and br.Visible then br.Visible = false end
            end)
            
            -- หน่วงเวลาให้เซิร์ฟเวอร์เคลียร์สถานะอย่างสมบูรณ์อย่างน้อย 3.5 วินาที
            while (tick() - (LastRemoteFire["TowerLeave"] or 0) < 3.5) do
                task.wait(0.2)
            end
        end
        
        local success = StartTowerDirect(resolvedId)
        if success then
            if force then
                Notify("🏰 หอคอย", "กำลังเริ่มลง [" .. tostring(towerDef.Name or resolvedId) .. "]...", 3)
            end
            if CFG.AutoExitArena then
                task.spawn(function()
                    local waitStart = tick()
                    while tick() - waitStart < 12.0 do
                        task.wait(0.5)
                        if getgenv().PetDiceScriptToken ~= scriptToken then break end
                        if IsTowerInArena() then
                            if ExitArenaCleanly then
                                ExitArenaCleanly()
                            else
                                Fire("TowerExit")
                            end
                            break
                        end
                        if not IsTowerRunning() then break end
                    end
                end)
            end
            task.delay(0.4, function() if UpdateTowerStatus then UpdateTowerStatus() end end)
            return true
        end
        return false
    end)
    isSwitchingTower = false
    if not ok then
        warn("[SwitchOrStartTower error]:", res)
        return false, res
    end
    return res
end

local function StartSelectedTower()
    local targetId = GetSelectedTowerId()
    SwitchOrStartTower(targetId, true)
end

UpdateTowerStatus = function()
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
            timeStr = string.format("%d:%02d", math.floor(leftStart / 60), leftStart % 60)
            timeToJoinStr = string.format("%d:%02d", math.floor(leftJoin / 60), leftJoin % 60)
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
                if not IsTowerRunning() then
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
                if not IsTowerRunning() then
                    SwitchOrStartTower(id, true)
                end
            end)
        end
    end
})

TogTowerTower = Tabs.Tower:AddToggle("TogTower", {
    Title = "1. ฟาร์มหอคอยอัตโนมัติ (Auto Tower)",
    Default = CFG.Tower,
    Callback = function(V)
        UpdateCFG("Tower", V)
        if not isSyncingMasterToggles and TogOverviewTower and TogOverviewTower.Value ~= V then
            isSyncingMasterToggles = true
            pcall(function() TogOverviewTower:SetValue(V) end)
            isSyncingMasterToggles = false
        end
        if isUIInitializing or isSyncingMasterToggles then return end
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
                SwitchOrStartTower(targetId, true)
                task.delay(0.2, UpdateTowerStatus)
            end)
        else
            if LeaveTowerCleanly then
                LeaveTowerCleanly("ปิดระบบฟาร์มหอคอยและออกจากหอเรียบร้อย")
            end
        end
    end
})

local SliderTowerDelay = Tabs.Tower:AddSlider("SlideTowerDelay", {
    Title = "ระยะเวลาหน่วงก่อนเริ่มรอบใหม่ (วินาที)",
    Description = "ปรับเวลารอก่อนเริ่มหอคอยรอบใหม่เพื่อความปลอดภัยและสมจริง (แนะนำ 5-8 วินาที เพื่อป้องกันการตรวจจับ)",
    Default = CFG.TowerRestartDelay or 5,
    Min = 2,
    Max = 20,
    Rounding = 0,
    Callback = function(val)
        UpdateCFG("TowerRestartDelay", val)
    end
})

Tabs.Tower:AddInput("InputTowerDelay", {
    Title = "⌨️ กำหนดระยะเวลาหน่วงเอง (พิมพ์วินาที)",
    Default = tostring(CFG.TowerRestartDelay or 5),
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
                    if ExitArenaCleanly then
                        ExitArenaCleanly("ออกจากอารีน่ามาทำงานเบื้องหลังเรียบร้อย!")
                    end
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
        if ExitArenaCleanly then
            ExitArenaCleanly("ออกจากอารีน่าสู่โหมดเบื้องหลังเรียบร้อย!")
        end
    end
})

Tabs.Tower:AddButton({
    Title = "🛑 สั่งหยุดลงหอคอย (Stop Tower Run)",
    Description = "ส่งคำสั่งหยุดการลงหอคอยรอบปัจจุบันและปิดระบบฟาร์มทันที",
    Callback = function()
        if LeaveTowerCleanly then
            LeaveTowerCleanly("สั่งหยุดลงหอคอยและปิดระบบฟาร์มเรียบร้อย!")
        end
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
        
        if wbState == "Joining" then
            if CFG.PauseTowerForBoss and IsTowerRunning() then
                Fire("TowerLeave")
                Humanizer.Wait(0.8, 1.5)
            end
            
            local arrived = SafeWalkToBossPortal()
            if arrived then
                Humanizer.Wait(0.3, 0.6)
                Fire("WorldBossJoin")
                Notify("⚔️ บอสโลก", string.format("ส่งคำสั่งเข้าร่วมบอสโลก [%s %s] สำเร็จ!", wbDiff, wbElem), 3)
            else
                Notify("⚠️ บอสโลก", "ไม่สามารถเดินถึงหน้าประตูบอสโลกได้ (ยกเลิกเพื่อป้องกัน Error 267)", 3)
            end
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

TogTowerAutoPlay = Tabs.Tower:AddToggle("TogAutoPlay", {
    Title = "4. กลิ้งลูกเต๋าอัตโนมัติ (Auto Roll Dice)",
    Default = CFG.AutoPlay,
    Callback = function(V)
        UpdateCFG("AutoPlay", V)
        if not isSyncingMasterToggles and TogOverviewAutoPlay and TogOverviewAutoPlay.Value ~= V then
            isSyncingMasterToggles = true
            pcall(function() TogOverviewAutoPlay:SetValue(V) end)
            isSyncingMasterToggles = false
        end
        if V then
            task.spawn(function()
                local data = State.Data
                if data and Stats and Stats.HasAuto and Stats.HasAuto(data, State.Mods and State.Mods() or {}) then
                    Fire("SetAuto", true)
                end
                Fire("Roll")
                Notify("🎲 กลิ้งลูกเต๋า", "เปิดระบบทอยลูกเต๋าอัตโนมัติเรียบร้อย!", 2)
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

TogTowerAutoBuyDice = Tabs.Tower:AddToggle("TogAutoBuyDice", {
    Title = "5. ซื้อลูกเต๋าอัตโนมัติเมื่อเงินพอ (Auto Buy Dice)",
    Default = CFG.AutoBuyDice,
    Callback = function(V)
        UpdateCFG("AutoBuyDice", V)
        if not isSyncingMasterToggles and TogOverviewAutoBuyDice and TogOverviewAutoBuyDice.Value ~= V then
            isSyncingMasterToggles = true
            pcall(function() TogOverviewAutoBuyDice:SetValue(V) end)
            isSyncingMasterToggles = false
        end
        if V then
            Notify("🎲 ซื้อลูกเต๋า", "เปิดระบบซื้อลูกเต๋าอัตโนมัติเรียบร้อย!", 2)
        else
            Notify("🎲 ซื้อลูกเต๋า", "ปิดระบบซื้อลูกเต๋าอัตโนมัติแล้ว", 2)
        end
    end
})
end -- END TAB 3: TOWER & DICE

-- ------------------------------------------------------------------------------
-- 🔄 TAB 4: REBIRTH & SKILL TREE
-- ------------------------------------------------------------------------------
task.wait()
Tabs.Rebirth:AddSection("🌟 เกิดใหม่อัตโนมัติ (Auto Rebirth)")

RebirthStatusPara = Tabs.Rebirth:AddParagraph({
    Title = "📊 สถานะการเกิดใหม่ (Rebirth Status): กำลังคำนวณ...",
    Content = "กำลังตรวจสอบจำนวน Rebirths และค่าใช้จ่าย..."
})

TogRebirthAutoRebirth = Tabs.Rebirth:AddToggle("TogAutoRebirth", {
    Title = "เปิดระบบเกิดใหม่อัตโนมัติเมื่อเงินครบ (Auto Rebirth)",
    Default = CFG.AutoRebirth,
    Callback = function(V)
        UpdateCFG("AutoRebirth", V)
        if not isSyncingMasterToggles and TogOverviewAutoRebirth and TogOverviewAutoRebirth.Value ~= V then
            isSyncingMasterToggles = true
            pcall(function() TogOverviewAutoRebirth:SetValue(V) end)
            isSyncingMasterToggles = false
        end
        if UpdateOverviewTab then UpdateOverviewTab() end
    end
})

Tabs.Rebirth:AddInput("InputTargetRebirths", {
    Title = "🎯 กำหนดเป้าหมายจำนวนครั้งการเกิดใหม่ (0 = ไม่จำกัด)",
    Default = tostring(CFG.TargetRebirths or 0),
    Placeholder = "เช่น 10 เพื่อปลดล็อกเทรด หรือ 20 (Celestial)",
    Numeric = true,
    Finished = true,
    Callback = function(val)
        local n = tonumber(val) or 0
        local target = math.max(0, math.floor(n))
        UpdateCFG("TargetRebirths", target)
        Notify("🌟 เป้าหมายเกิดใหม่", target > 0 and ("ตั้งเป้าหมายเป็น " .. target .. " ครั้ง") or "ตั้งเป็นไม่จำกัด (เกิดใหม่ตลอด)", 2)
        if UpdateOverviewTab then UpdateOverviewTab() end
    end
})

Tabs.Rebirth:AddButton({
    Title = "⚡ กดเกิดใหม่ทันที (Rebirth Now)",
    Description = "เช็คความพร้อมของเงินและส่งคำสั่งเกิดใหม่",
    Callback = function()
        local data = State.Data
        if not data then return end
        local cost = Stats and Stats.RebirthCost and Stats.RebirthCost(data)
        if cost and (data.Money or 0) >= cost then
            if isEconomyActionMutex or getgenv().EconomyActionMutex or isZoneTransitionLocked then
                Notify("⚠️ กำลังทำรายการอื่น", "กำลังทำรายการเศรษฐกิจอยู่ กรุณารอสักครู่...", 2)
                return
            end
            Fire("Rebirth")
            Notify("🌟 เกิดใหม่", "ส่งคำสั่งเกิดใหม่สำเร็จ!", 3)
        else
            local diff = cost and ((cost or 0) - (data.Money or 0)) or 0
            Notify("⚠️ เงินไม่พอ", "เงินของคุณยังไม่พอเกิดใหม่ (ขาดอีก " .. (Format and Format.Money and Format.Money(diff) or tostring(diff)) .. ")", 3)
        end
    end
})

Tabs.Rebirth:AddSection("🌳 อัปเกรดต้นไม้ทักษะ (Skill Tree)")

TreeStatusPara = Tabs.Rebirth:AddParagraph({
    Title = "🌳 สถานะต้นไม้ทักษะ: กำลังคำนวณ...",
    Content = "กำลังตรวจสอบจำนวนอัปเกรดและเลเวลสูงสุด..."
})

TogRebirthTree = Tabs.Rebirth:AddToggle("TogTree", {
    Title = "วนซื้ออัปเกรดต้นไม้ทั้งหมดอัตโนมัติ",
    Default = CFG.UpgradeTree,
    Callback = function(V)
        UpdateCFG("UpgradeTree", V)
        if not isSyncingMasterToggles and TogOverviewTree and TogOverviewTree.Value ~= V then
            isSyncingMasterToggles = true
            pcall(function() TogOverviewTree:SetValue(V) end)
            isSyncingMasterToggles = false
        end
    end
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
                Notify("⚠️ ยังไม่มีอัปเกรดที่เงินพอซื้อ", "อัปเกรดที่ปลดล็อคแล้วราคาขั้นต่ำสูงกว่าเงินที่คุณมี (ระบบจะซื้อให้อัตโนมัติเมื่อเงินครบ)", 3)
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
task.wait()
local UpdatePotionStatus
local UpdateMarketStatus
do -- TAB 5: POTIONS & CONSUMABLES
Tabs.Items:AddSection("📊 สถานะน้ำยาและไอเทมแบบเรียลไทม์ (นับถอยหลังวินาที)")

local PotionStatusPara = Tabs.Items:AddParagraph({
    Title = "⏳ กำลังโหลดสถานะน้ำยา...",
    Content = "กำลังตรวจสอบเวลานับถอยหลังของน้ำยาแต่ละชนิด..."
})

UpdatePotionStatus = function()
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
            local secs = left % 60; return string.format("✅ เหลืออีก %d:%02d นาที", mins, secs)
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

UpdateMarketStatus = function()
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
        local _, canBuyCount, totalCost, _totalLeft = Market.PlanBuyAll(currentWindow, bought, data.Rebirths or 0, data.Money or 0)
        
        local unlockStr = isUnlocked and "✅ ปลดล็อกแล้ว (พร้อมซื้อ)" or "🔒 ล็อกอยู่ (ต้องปลดล็อกที่ต้นไม้อัปเกรด)"
        local costStr = Format and Format.Money and Format.Money(totalCost or 0) or tostring(totalCost or 0)
        local moneyStr = Format and Format.Money and Format.Money(data.Money or 0) or tostring(data.Money or 0)
        
        local desc = string.format("🏪 สถานะตลาด: %s\n⏳ รีสต็อกสินค้าใหม่ในอีก: %s\n📦 สินค้าที่ซื้อได้: %d ชิ้น (คงเหลือในสต็อก %d ชิ้น)\n💰 ราคารวมทั้งหมด: %s (ยอดเงินของคุณ: %s)",
            unlockStr, restockStr, canBuyCount or 0, _totalLeft or 0, costStr, moneyStr
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
        local _, canBuyCount, totalCost, _totalLeft = Market.PlanBuyAll(currentWindow, bought, data.Rebirths or 0, data.Money or 0)
        
        if (canBuyCount or 0) <= 0 then
            if (_totalLeft or 0) <= 0 then
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
end -- END TAB 5: POTIONS & CONSUMABLES

-- ------------------------------------------------------------------------------
-- 🌙 TAB 6: EXPEDITIONS & QUESTS
-- ------------------------------------------------------------------------------
task.wait()
local UpdateExpeditionStatus
local GetBestExpeditionPets
local ClaimAllDoneExpeditions
do -- TAB 6: EXPEDITIONS & QUESTS
Tabs.Expedition:AddSection("🌙 สถานะผจญภัย & เควสแบบเรียลไทม์")

local ExpeditionStatusPara = Tabs.Expedition:AddParagraph({
    Title = "⏳ กำลังโหลดสถานะผจญภัย & เควส...",
    Content = "กำลังตรวจสอบเรือสำรวจและเควสคงเหลือ..."
})

UpdateExpeditionStatus = function()
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

GetBestExpeditionPets = function(maxCount, excludeUids)
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
    local _, pets = GetBestExpeditionPets(maxCount, excludeUids); return pets or {}
end

ClaimAllDoneExpeditions = function()
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
                        canPlaytime = true; break
                    end
                end
            end
        end)
        if canPlaytime then
            Fire("ClaimPlaytime", "all")
            claimedCount = claimedCount + 1
            Humanizer.Wait(0.4, 0.8)
        end
        
        -- Note: Social rewards (Like/Group) require GUI/SocialStart handshake, skipped in auto-claim for safety
        
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

TogExpeditionRewards = Tabs.Expedition:AddToggle("TogReward", {
    Title = "1. รับรางวัลประจำวัน & เวลาเล่นอัตโนมัติ (Auto Rewards)",
    Default = CFG.Reward,
    Callback = function(V)
        UpdateCFG("Reward", V)
        if not isSyncingMasterToggles and TogOverviewRewards and TogOverviewRewards.Value ~= V then
            isSyncingMasterToggles = true
            pcall(function() TogOverviewRewards:SetValue(V) end)
            isSyncingMasterToggles = false
        end
    end
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
end -- END TAB 6: EXPEDITIONS & QUESTS

-- 🎃 TAB 7: HALLOWEEN EVENT
-- ------------------------------------------------------------------------------
task.wait()
do -- TAB 7: HALLOWEEN EVENT
Tabs.Halloween:AddSection("🎃 กิจกรรมฮาโลวีน (Halloween Event)")

GetHalloweenEntry = function()
    local data = State.Data
    if not data or not data.Seasons then return nil end
    if data.Seasons.Halloween2026 then return data.Seasons.Halloween2026 end
    for k, v in pairs(data.Seasons) do
        if string.find(tostring(k), "Halloween") then
            return v
        end
    end
    return nil
end

CanTrickOrTreat = function()
    local data = State.Data
    if not data then return false end
    local entry = GetHalloweenEntry()
    if not entry then return false end
    if not entry.TreatDay then return true end
    
    local now = workspace:GetServerTimeNow()
    local okSeason, currentDay = pcall(function()
        if Season and type(Season.TreatDay) == "function" then
            return Season.TreatDay(now)
        end
    end)
    if okSeason and type(currentDay) == "number" then
        return entry.TreatDay < currentDay
    end
    
    local nowDay = math.floor(now / 86400); return entry.TreatDay < nowDay
end

local HalloweenStatusPara = Tabs.Halloween:AddParagraph({
    Title = "🎃 สถานะอีเวนต์ฮาโลวีน (Live Status)",
    Content = "กำลังเชื่อมต่อข้อมูลฮาโลวีน..."
})

UpdateHalloweenStatus = function()
    pcall(function()
        local entry = GetHalloweenEntry()
        local data = State.Data
        local now = workspace:GetServerTimeNow()
        
        local candy = (entry and entry.Candy) or (data and data.Season and data.Season.Candy) or 0
        local stormCandy = (entry and entry.StormCandy) or 0
        local bags = (data and data.SeasonBags and data.SeasonBags.Halloween) or 0
        local boughtPulls = (entry and entry.Bought and (entry.Bought.LimitedPull or entry.Bought.HalloweenPull or entry.Bought.SinglePull)) or 0
        local canTreat = CanTrickOrTreat()
        
        local dayNow = math.floor(now / 86400)
        local resetSeconds = math.max(0, ((dayNow + 1) * 86400) - now)
        pcall(function()
            if Season and type(Season.TreatReset) == "function" then
                local sReset = Season.TreatReset(now)
                if type(sReset) == "number" and sReset > 0 then
                    resetSeconds = sReset
                end
            end
        end)
        local resetMins = math.floor(resetSeconds / 60)
        local resetSecs = math.floor(resetSeconds % 60)
        local countdown = string.format("%d:%02d", resetMins, resetSecs)
        
        local isStormActive, stormSecLeft = IsCandyStormActive()
        local secToNext = GetSecondsUntilNextStorm()
        
        local stormStatusStr = ""
        if isStormActive then
            stormStatusStr = string.format("🚨 พายุกำลังตก! (เหลืออีก %d วิ) 🌪️ วิ่งกวาดลูกอม", math.ceil(stormSecLeft))
        else
            local m = math.floor(secToNext / 60)
            local s = math.floor(secToNext % 60)
            if secToNext <= 10 then
                stormStatusStr = string.format("⚡ พายุกำลังจะเริ่มในอีก %d วิ! (เตรียมวาร์ปไปรอพลาซ่า)", math.ceil(secToNext))
            else
                stormStatusStr = string.format("⏳ รออีก %d:%02d นาที (วาร์ปไปรออัตโนมัติ)", m, s)
            end
        end
        
        local treatStatusStr = canTreat and "✅ พร้อมขอขนมฟรี! (เดินไปหาเคานต์พาวคูลาได้เลย)" or ("⏳ ขอของวันนี้แล้ว (รีเซ็ตในอีก " .. countdown .. ")")
        local bagStr = bags > 0 and (tostring(bags) .. " ใบ (พร้อมกดเปิดทันที!)") or "0 ใบ"
        
        -- ประสานงานระบบหอคอย & บอสโลก & เก็บลูกอม (Safety 100%)
        local coordStatusStr = ""
        local inBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true) or (IsEnteringBossPortal == true)
        local inArena = false
        local isTowerRun = false
        pcall(function()
            if type(IsTowerInArena) == "function" then inArena = IsTowerInArena() end
            if type(IsTowerRunning) == "function" then isTowerRun = IsTowerRunning() end
        end)
        
        if inBoss then
            coordStatusStr = "⚔️ กำลังต่อสู้กับบอสโลก (พักหอคอย & พักเก็บลูกอมชั่วคราวเพื่อความปลอดภัย 100%)"
        elseif getgenv().IsCandyStormActiveRunning or isStormActive then
            if isTowerRun then
                coordStatusStr = "🌪️ กำลังเก็บพายุลูกกวาดในพลาซ่า | 🏰 หอคอยทำงานคู่ขนานในโหมด Away (ปลอดภัย 100%)"
            else
                coordStatusStr = "🌪️ กำลังเก็บพายุลูกกวาดในพลาซ่า (พักเริ่มหอคอยรอบใหม่ชั่วคราวเพื่อไม่ให้วาร์ปทับซ้อน)"
            end
        elseif inArena then
            coordStatusStr = "⚠️ อยู่ในอารีน่าหอคอย (ระบบจะเปลี่ยนเป็น Away Mode อัตโนมัติเมื่อพายุมา)"
        elseif isTowerRun then
            coordStatusStr = "🏰 ฟาร์มหอคอยในโหมด Away (พร้อมเดินทางเก็บแคนดี้ทันทีเมื่อพายุเริ่ม)"
        else
            coordStatusStr = "💤 สแตนด์บายที่บ้าน (พร้อมเริ่มหอคอยรอบใหม่ & เก็บแคนดี้เมื่อพายุมา)"
        end
        
        local candyStr = (Format and Format.Commas and Format.Commas(candy)) or tostring(candy)
        local title = string.format("🎃 อีเวนต์ฮาโลวีน | 🍬 ลูกอม: %s | 🎒 กระเป๋า: %d ใบ", candyStr, bags)
        local desc = string.format(
            "🍬 ยอดลูกอมปัจจุบัน: %s ลูก (ซื้อกระเป๋าใช้ 270 | ซื้อตั๋วใช้ 800)\n" ..
            "🎒 กระเป๋าฮาโลวีนในตัว: %s\n" ..
            "🌪️ สถานะพายุลูกกวาด: %s (เก็บแล้ว: %d ลูก)\n" ..
            "🧛 สิทธิ์ขอขนมฟรี: %s\n" ..
            "🎟️ โควต้า Limited Pull: %d/5 ครั้ง\n" ..
            "⚡ ประสานงานระบบ: %s",
            candyStr,
            bagStr,
            stormStatusStr,
            stormCandy,
            treatStatusStr,
            boughtPulls,
            coordStatusStr
        )
        
        local okTitle = pcall(function() HalloweenStatusPara:SetTitle(title) end)
        if not okTitle and HalloweenStatusPara and HalloweenStatusPara.TitleLabel then
            pcall(function() HalloweenStatusPara.TitleLabel.Text = title end)
        end
        local okDesc = pcall(function() HalloweenStatusPara:SetDesc(desc) end)
        if not okDesc and HalloweenStatusPara and HalloweenStatusPara.DescLabel then
            pcall(function() HalloweenStatusPara.DescLabel.Text = desc end)
        end
    end)
end

task.spawn(UpdateHalloweenStatus)
task.spawn(function()
    while true do
        task.wait(1.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        pcall(UpdateHalloweenStatus)
    end
end)

Tabs.Halloween:AddButton({
    Title = "🎁 กดรับรางวัลเป้าหมายฮาโลวีนทั้งหมด (1 คลิก)",
    Callback = function()
        local entry = GetHalloweenEntry()
        if not entry then 
            Notify("⚠️ ข้อมูลฮาโลวีน", "ไม่พบข้อมูลกิจกรรมฮาโลวีน", 2)
            return 
        end
        local readyGoals = {}
        for _, g in ipairs(HalloweenConfig.Goals or {}) do
            local currentTier = entry.Goals and entry.Goals[g.Id] or 0
            local nextTierIdx = currentTier + 1
            local nextTier = g.Tiers and g.Tiers[nextTierIdx]
            local stat = entry.Stats and entry.Stats[g.Stat] or 0
            if nextTier ~= nil and nextTier.Goal ~= nil and stat >= nextTier.Goal then
                table.insert(readyGoals, {id = g.Id, tier = nextTierIdx})
            end
        end
        if #readyGoals == 0 then
            Notify("🎃 เป้าหมายฮาโลวีน", "ไม่มีเป้าหมายที่สำเร็จพร้อมรับในขณะนี้ (ความคืบหน้ายังไม่ถึง)", 3)
            return
        end
        for _, rg in ipairs(readyGoals) do
            Fire("HalloweenGoalClaim", rg.id)
            Humanizer.Wait(1.2, 2.0)
        end
        Notify("🎃 ฮาโลวีน", "รับรางวัลเป้าหมาย " .. #readyGoals .. " รายการเรียบร้อย!", 3)
        task.delay(0.5, UpdateHalloweenStatus)
    end
})

Tabs.Halloween:AddButton({
    Title = "🛍️ ซื้อแพ็คกระเป๋า 10 ใบ (270 ลูกอม)",
    Callback = function()
        if IsInTrade() or getgenv().TradeActiveSession then
            Notify("⚠️ กำลังทำกิจกรรมอื่น", "กรุณาจบการเทรดก่อนซื้อไอเทม", 3)
            return
        end
        local entry = GetHalloweenEntry()
        local candy = entry and entry.Candy or 0
        if candy >= 270 then
            Fire("SpookyBuy", "HalloweenBag10")
            Notify("🛍️ ซื้อกระเป๋า", "ซื้อแพ็คกระเป๋าฮาโลวีน 10 ใบสำเร็จ! (เหลือลูกอม: " .. (candy - 270) .. ")", 3)
        else
            Notify("⚠️ ลูกอมไม่พอ", "ต้องใช้ 270 ลูกอม (คุณมี: " .. candy .. ")", 2)
        end
        task.delay(0.5, UpdateHalloweenStatus)
    end
})

Tabs.Halloween:AddButton({
    Title = "🎟️ ซื้อตั๋ว Limited Pull (800 ลูกอม)",
    Callback = function()
        if IsInTrade() or getgenv().TradeActiveSession then
            Notify("⚠️ กำลังทำกิจกรรมอื่น", "กรุณาจบการเทรดก่อนซื้อไอเทม", 3)
            return
        end
        local entry = GetHalloweenEntry()
        local candy = entry and entry.Candy or 0
        local boughtPulls = entry and entry.Bought and entry.Bought.LimitedPull or 0
        if boughtPulls >= 10 then
            Notify("⚠️ สิทธิ์เต็มแล้ว", "คุณซื้อตั๋ว Limited Pull ครบโควต้า 10/10 แล้ว", 3)
            return
        end
        if candy >= 800 then
            Fire("SpookyBuy", "LimitedPull")
            Notify("🎟️ ซื้อ Limited Pull", "ซื้อสำเร็จ! (" .. (boughtPulls + 1) .. "/10) (เหลือลูกอม: " .. (candy - 800) .. ")", 3)
        else
            Notify("⚠️ ลูกอมไม่พอ", "ต้องใช้ 800 ลูกอม (คุณมี: " .. candy .. ")", 2)
        end
        task.delay(0.5, UpdateHalloweenStatus)
    end
})

Tabs.Halloween:AddButton({
    Title = "🎒 เปิดกระเป๋าฮาโลวีนทั้งหมด (Open All Bags)",
    Callback = function()
        task.spawn(function()
            local bagCount = State.Data and State.Data.SeasonBags and State.Data.SeasonBags.Halloween or 0
            if bagCount <= 0 then
                Notify("⚠️ ไม่มีกระเป๋า", "คุณไม่มีกระเป๋าฮาโลวีนในตัว", 2)
                return
            end
            local isBusy = false
            pcall(function()
                if LootBagController and LootBagController.Api and LootBagController.Api.Busy then
                    isBusy = LootBagController.Api.Busy()
                end
                if not isBusy and CutsceneDirector and CutsceneDirector.Director and CutsceneDirector.Director.Playing then
                    isBusy = CutsceneDirector.Director.Playing()
                end
            end)
            if isBusy then
                Notify("⏳ ระบบกำลังทำงาน", "กรุณารอแอนิเมชันหรือคัตซีนเดิมจบก่อน", 2)
                return
            end
            if LootBagController and LootBagController.Api and LootBagController.Api.Open then
                LootBagController.Api.Open("all", "Halloween")
            else
                Fire("OpenLootBag", "all", "Halloween")
            end
            Notify("🎒 เปิดกระเป๋า", "กำลังเปิดกระเป๋าฮาโลวีน " .. bagCount .. " ใบ...", 3)
            Humanizer.Wait(4.5, 6.0)
            local waitingPets = 0
            pcall(function()
                if State.Data and PetData and PetData.WaitingCount then
                    waitingPets = PetData.WaitingCount(State.Data, "Season")
                end
            end)
            if waitingPets > 0 then
                Humanizer.Wait(1.0, 1.8)
                Fire("ClaimLootPets", "Season")
                Notify("🐾 รับสัตว์เลี้ยง", "รับสัตว์เลี้ยงฮาโลวีน " .. waitingPets .. " ตัวเรียบร้อย!", 3)
            end
            task.delay(0.5, UpdateHalloweenStatus)
        end)
    end
})

Tabs.Halloween:AddButton({
    Title = "🐾 เคลมสัตว์เลี้ยงฮาโลวีนที่รอรับ (Claim Waiting Pets)",
    Callback = function()
        local waitingPets = 0
        pcall(function()
            if State.Data and PetData and PetData.WaitingCount then
                waitingPets = PetData.WaitingCount(State.Data, "Season")
            end
        end)
        if waitingPets > 0 then
            Fire("ClaimLootPets", "Season")
            Notify("🐾 รับสัตว์เลี้ยง", "รับสัตว์เลี้ยงฮาโลวีน " .. waitingPets .. " ตัวเรียบร้อย!", 3)
        else
            Notify("🐾 สัตว์เลี้ยงฮาโลวีน", "ไม่มีสัตว์เลี้ยงที่ค้างรอรับในระบบ", 2)
        end
        task.delay(0.5, UpdateHalloweenStatus)
    end
})

Tabs.Halloween:AddButton({
    Title = "🍬 เดินไปขอขนมฮาโลวีน (Safe Legitimate Walking)",
    Description = "เดินไปหาเคานต์พาวคูลาด้วยระบบ Pathfinding ปลอดภัย 100% ไร้การแบน (หากขอแล้วจะพาไปเพื่อชมร้านค้าและกลับบ้านอัตโนมัติ)",
    Callback = function()
        task.spawn(function()
            if IsInTrade() or getgenv().TradeActiveSession then
                Notify("⚠️ กำลังทำกิจกรรมอื่น", "กรุณาจบการเทรดก่อนเดินไปหาเคานต์พาวคูลา", 3)
                return
            end
            if IsTowerInArena() then
                Notify("⚠️ กำลังสู้ในอารีน่า", "กำลังสู้อยู่ในอารีน่าหอคอย กรุณารอรอบสู้จบหรือกดออกจากอารีน่าก่อน", 3)
                return
            end
            
            local canTreat = CanTrickOrTreat()
            local resetTime = Season and Season.TreatReset and Season.TreatReset(State.Now and State.Now() or os.time()) or 0
            local countdown = Season and Season.Countdown and Season.Countdown(resetTime) or "เร็วๆ นี้"
            
            if canTreat then
                Notify("🍬 กำลังไปขอขนม", "กำลังเดินไปยังเคานต์พาวคูลาเพื่อขอขนมประจำวันอย่างปลอดภัย...", 3)
            else
                Notify("🍬 ขอขนมวันนี้ไปแล้ว", "คุณขอขนมประจำวันนี้ไปแล้ว (รีเซ็ตในอีก " .. countdown .. ")\nระบบจะพาเดินไปหาเคานต์พาวคูลาเพื่อเยี่ยมชมร้านค้าอย่างปลอดภัย...", 4)
            end
            
            local arrived = WalkToPawcula()
            if arrived then
                Humanizer.Wait(0.8, 1.4)
                if CanTrickOrTreat() then
                    Fire("TrickOrTreat")
                    Notify("🍬 Trick or Treat", "ส่งคำขอขนมฮาโลวีนเรียบร้อย!", 3)
                    Humanizer.Wait(2.5, 4.0)
                    Fire("Teleport", "Home")
                    Notify("🏠 กลับบ้าน", "เดินทางกลับบ้านเรียบร้อย พร้อมฟาร์มต่ออัตโนมัติ", 2)
                else
                    Notify("🧛 ถึงเคานต์พาวคูลาแล้ว", "คุณขอขนมวันนี้ไปแล้ว (รีเซ็ตในอีก " .. countdown .. ")\nเปิดบทสนทนาและร้านค้า Spooky Shop ให้แล้ว", 3)
                    pcall(function()
                        local p = workspace:FindFirstChild("PetDiceHalloween")
                            and workspace.PetDiceHalloween:FindFirstChild("HauntedCorner")
                            and workspace.PetDiceHalloween.HauntedCorner:FindFirstChild("CountPawcula")
                        local prompt = p and p:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and typeof(fireproximityprompt) == "function" then
                            fireproximityprompt(prompt)
                        end
                    end)
                    Humanizer.Wait(3.5, 5.0)
                    Fire("Teleport", "Home")
                    Notify("🏠 กลับบ้าน", "เดินทางกลับบ้านเรียบร้อย", 2)
                end
            else
                Notify("⚠️ เดินไม่ถึงจุด", "มีสิ่งกีดขวางหรือไม่สามารถเดินถึงเคานต์พาวคูลาได้", 3)
            end
            UpdateHalloweenStatus()
        end)
    end
})

-- isCollectingCandyMutex declared at line 430
SafeCollectPlazaCandies = function(isManual)
    local canH, blockReason = CanRunHalloween()
    if not canH then
        if isManual then
            Notify("⚠️ ไม่สามารถทำได้", "ติดสถานะสำคัญกว่า: " .. tostring(blockReason), 3)
        end
        return false
    end
    if isCollectingCandyMutex or getgenv().CandyStormMutex or getgenv().IsCandyStormActiveRunning then
        if isManual then
            Notify("🌪️ กำลังเก็บแคนดี้อยู่แล้ว", "ระบบกำลังวิ่งเก็บแคนดี้ในพลาซ่าให้อยู่ในขณะนี้", 3)
        end
        return false
    end
    
    if IsInTrade() or getgenv().TradeActiveSession then
        if isManual then Notify("⚠️ กำลังทำกิจกรรมอื่น", "กรุณาจบการเทรดก่อนเก็บแคนดี้", 3) end
        return false
    end
    
    local isBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
    if isBoss or IsEnteringBossPortal == true then
        if isManual then Notify("⚔️ บอสโลก", "กรุณาจบรอบบอสโลกก่อนเก็บแคนดี้", 3) end
        return false
    end
    
    -- ล็อค Mutex และ Flag ทันทีตั้งแต่ก้าวแรก ป้องกัน Loop อื่นๆ (เช่น Tower หรือ Boss) แทรกแซง
    isCollectingCandyMutex = true
    getgenv().CandyStormMutex = true
    getgenv().IsCandyStormActiveRunning = true
    getgenv().LastCandyStormStartTime = tick()
    
    -- หากกำลังอยู่ใน 3D Battle Arena ให้ออกจากอารีน่าสู่โหมดเบื้องหลัง (Away Mode) เพื่อให้ตัวละครเดินเก็บแคนดี้ในลานพลาซ่าได้ โดยไม่ต้องยกเลิกหอคอย
    if IsTowerInArena and IsTowerInArena() then
        Notify("🏰 หอคอย", "ออกจากอารีน่าสู่โหมดเบื้องหลัง เพื่อเก็บพายุลูกกวาด...", 2)
        if ExitArenaCleanly then
            ExitArenaCleanly()
        else
            Fire("TowerExit")
        end
        Humanizer.Wait(1.5, 2.5)
    end
    
    local collectedThisRound = 0
    
    local ok, err = pcall(function()
        local char = LocalPlayer.Character or Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hum or not hrp or hum.Health <= 0 then return end
        
        -- ตรวจสอบว่าผู้เล่นอยู่ใน Hub หรือยัง (หากไม่ได้อยู่ที่ลานบ้าน แปลว่าอยู่ในพลาซ่า/ฮับแล้ว)
        local isAlreadyInHub = not IsPlayerAtHomePlot()
        if not isAlreadyInHub then
            Notify("🌪️ พายุลูกกวาด", "กำลังเดินทางไปพลาซ่าเพื่อเก็บแคนดี้...", 2)
            Fire("Teleport", "Hub")
            local tWait = tick()
            while IsPlayerAtHomePlot() and (tick() - tWait < 4.0) do
                task.wait(0.2)
            end
            char = LocalPlayer.Character or Character
            hum = char and char:FindFirstChildOfClass("Humanoid")
            hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then return end
            if IsPlayerAtHomePlot() then
                return
            end
        end
        
        local targets = GetAvailableCandies()
        local isStormActive, stormSecLeft = IsCandyStormActive()
        local secToNext = GetSecondsUntilNextStorm()
        
        if #targets == 0 and not isStormActive and secToNext > 8 then
            if isManual then
                local m = math.floor(secToNext / 60)
                local s = math.floor(secToNext % 60)
                Notify("⏳ ยังไม่มีพายุลูกกวาด", string.format("ขณะนี้ยังไม่มีแคนดี้ในพลาซ่า (พายุรอบถัดไปในอีก %d นาที %02d วิ)\nระบบจะพากลับบ้าน และจะวาร์ปมาเก็บให้อัตโนมัติเมื่อพายุเริ่ม", m, s), 4)
            end
            Humanizer.Wait(1.5, 2.0)
            Fire("Teleport", "Home")
            Humanizer.Wait(3.0, 4.0)
            LastZoneTransitionTime = tick(); return
        end
        
        Notify("🍬 เริ่มเก็บแคนดี้", "เริ่มกวาดเก็บแคนดี้ทั่วทั้งพลาซ่าแบบ Real-Time และปลอดภัย 100%...", 3)
        
        local lastCandySeen = tick()
        local maxSessionTime = tick() + 90.0
        
        while tick() < maxSessionTime do
            if getgenv().PetDiceScriptToken ~= scriptToken then break end
            if not isManual and not CFG.HalloweenAutoCollectCandy then break end
            if IsInTrade() or getgenv().TradeActiveSession then break end
            if IsTowerInArena() then break end
            local bossNow = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
            if bossNow or IsEnteringBossPortal == true then break end
            
            char = LocalPlayer.Character or Character
            hum = char and char:FindFirstChildOfClass("Humanoid")
            hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then break end
            
            targets = GetAvailableCandies()
            local stormActive, _ = IsCandyStormActive()
            local nextWait = GetSecondsUntilNextStorm()
            
            if #targets == 0 then
                -- หากพายุยังคงตกอยู่ หรือยังเหลือเวลาพายุ หรือพายุรอบใหม่กำลังจะเริ่มในอีก 8 วิ
                -- ให้อยู่ในพลาซ่าต่อไป ไม่วาร์ปกลับบ้านเด็ดขาด ป้องกันการวาร์ปไป-กลับซ้ำซากจนโดน Error 267!
                if stormActive or (nextWait <= 8) then
                    local centerPos = Vector3.new(0, hrp.Position.Y, 0)
                    if (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(0, 0, 0)).Magnitude > 12 then
                        hum:MoveTo(centerPos)
                    end
                    task.wait(0.35); continue
                else
                    -- พายุจบลงจริง 100% แล้ว และไม่มีลูกอมเหลืออยู่บนพื้น
                    -- รอเคลียร์เผื่อลูกอมลูกสุดท้ายอีก 4.0 วินาที
                    if tick() - lastCandySeen > 4.0 then
                        break
                    end
                    task.wait(0.35); continue
                end
            end
            
            lastCandySeen = tick()
            
            -- คัดเลือกเป้าหมายที่คุ้มค่าและใกล้ที่สุดทั่วทั้งพลาซ่า (ระยะไกลสุด 350 studs ครอบคลุมทั้งแผนที่)
            local curPos = hrp.Position
            local bestCandy = nil
            local bestScore = math.huge
            
            for _, c in ipairs(targets) do
                if c and c.Position then
                    local d = (Vector3.new(c.Position.X, 0, c.Position.Z) - Vector3.new(curPos.X, 0, curPos.Z)).Magnitude
                    if d <= 350 then
                        local weight = 1.0
                        local kind = c.Kind or (c.Model and c.Model.Name) or ""
                        if kind:find("Bucket") then
                            weight = 3.5 -- Pumpkin Bucket: 15 ลูกอม
                        elseif kind:find("Bag") then
                            weight = 2.2 -- Candy Bag: 5 ลูกอม
                        elseif kind:find("Lollipop") then
                            weight = 1.4 -- Lollipop: 2 ลูกอม
                        end
                        
                        local score = d / weight
                        if score < bestScore then
                            bestScore = score
                            bestCandy = c
                        end
                    end
                end
            end
            
            if bestCandy and bestCandy.Position then
                local targetCandy = bestCandy
                local targetPos = targetCandy.Position
                local groundTarget = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
                local startDist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
                
                local moveSpeed = math.max(16, hum.WalkSpeed)
                local walkTimeout = math.clamp((startDist / moveSpeed) * 1.35 + 1.8, 1.8, 7.0)
                
                hum:MoveTo(groundTarget)
                
                local moveStart = tick()
                local lastCheckPos = hrp.Position
                local lastCheckTime = tick()
                local isCollected = false
                
                while (tick() - moveStart < walkTimeout) do
                    task.wait(0.04)
                    if getgenv().PetDiceScriptToken ~= scriptToken then break end
                    if not isManual and not CFG.HalloweenAutoCollectCandy then break end
                    
                    char = LocalPlayer.Character or Character
                    hum = char and char:FindFirstChildOfClass("Humanoid")
                    hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hum or not hrp or hum.Health <= 0 then break end
                    
                    -- ตรวจสอบว่าแคนดี้ถูกเซิร์ฟเวอร์เก็บไปแล้วหรือไม่
                    if targetCandy.Id and not ActiveCandies[targetCandy.Id] then
                        isCollected = true; break
                    end
                    if targetCandy.Model and not targetCandy.Model.Parent then
                        isCollected = true; break
                    end
                    
                    local curDist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
                    
                    -- เมื่อเข้าสู่ระยะสัมผัสของเกม (curDist <= 3.2 studs):
                    -- ให้ตัวละครอยู่ในระยะสัมผัสสักครู่ (0.18s ตาม GrabGap 0.15s ของเกม)
                    -- เพื่อให้สคริปต์ทางการของเกม (CandyStorm.luau) ส่ง Remote State.Send("CandyGrab", id)
                    -- และให้เซิร์ฟเวอร์ตรวจสอบตำแหน่งตัวละครได้อย่างถูกต้องขณะอยู่ใกล้แคนดี้ 100% ป้องกันโดนเตะ Error 267
                    if curDist <= 3.2 then
                        isCollected = true
                        task.wait(0.18)
                        break
                    end
                    
                    -- ระบบตรวจจับการติดสิ่งกีดขวาง (Smart Anti-Stuck & Auto-Jump)
                    local nowTime = tick()
                    if nowTime - lastCheckTime >= 0.35 then
                        local deltaMoved = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(lastCheckPos.X, 0, lastCheckPos.Z)).Magnitude
                        lastCheckPos = hrp.Position
                        lastCheckTime = nowTime
                        
                        if deltaMoved < 0.8 and curDist > 4.5 then
                            hum.Jump = true
                            hum:MoveTo(groundTarget)
                        else
                            hum:MoveTo(groundTarget)
                        end
                    end
                end
                
                local candyKey = targetCandy.Key or targetCandy.Id or targetCandy.Model or string.format("%.1f_%.1f", targetCandy.Position.X, targetCandy.Position.Z)
                if isCollected then
                    collectedThisRound = collectedThisRound + 1
                    VisitedCandies[candyKey] = tick()
                    if targetCandy.Id then
                        ActiveCandies[targetCandy.Id] = nil
                    end
                else
                    VisitedCandies[candyKey] = tick() - 7.0
                end
                
                task.wait(0.04)
            else
                task.wait(0.1)
            end
        end
        
        -- เมื่อเสร็จสิ้นรอบการเก็บ ให้วาร์ปกลับบ้าน (Home) อย่างปลอดภัยเสมอ (หากไม่ได้ติดเทรดหรือบอสโลก)
        local char = LocalPlayer.Character or Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local inHigherPriority = IsInTrade() or (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        if hrp and not inHigherPriority then
            Fire("Teleport", "Home")
            Notify("🌪️ พายุลูกกวาด", string.format("เสร็จสิ้นรอบการเก็บแคนดี้ (%d ชิ้น)! เดินทางกลับบ้านเรียบร้อย", collectedThisRound), 3)
            Humanizer.Wait(4.5, 5.5)
            LastZoneTransitionTime = tick()
        end
    end)
    
    Humanizer.Wait(1.5, 2.0)
    isCollectingCandyMutex = false
    getgenv().CandyStormMutex = false
    getgenv().IsCandyStormActiveRunning = false
    getgenv().LastCandyStormStartTime = 0
    LastZoneTransitionTime = tick()
    pcall(UpdateHalloweenStatus)
    return true
end

Tabs.Halloween:AddButton({
    Title = "🌪️ เดินไปเก็บแคนดี้พายุลูกกวาดทันที (Collect Plaza Candy Now)",
    Description = "เดินทางไปลานพลาซ่าเพื่อกวาดเก็บแคนดี้ทันที (หากยังไม่ถึงเวลาพายุ จะตรวจสอบและแจ้งเวลานับถอยหลังรอบถัดไปให้ทราบทันที)",
    Callback = function()
        task.spawn(function()
            SafeCollectPlazaCandies(true)
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

Tabs.Halloween:AddButton({
    Title = "🛍️ ซื้อแพ็ค 10 กระเป๋าฮาโลวีนทันที (270 ลูกอม)",
    Description = "ส่งคำสั่งซื้อแพ็ค 10 กระเป๋าฮาโลวีนทันที 1 ครั้ง (คุ้มกว่าซื้อทีละใบ)",
    Callback = function()
        local entry = GetHalloweenEntry and GetHalloweenEntry()
        local candyHave = (entry and entry.Candy) or 0
        if candyHave < 270 then
            Notify("⚠️ ลูกอมไม่พอ", string.format("คุณมีลูกอม %d ชิ้น (ต้องใช้ 270 ชิ้น)", candyHave), 3)
            return
        end
        Fire("SpookyBuy", "HalloweenBag10")
        Notify("🛍️ ซื้อกระเป๋าฮาโลวีน", "ซื้อแพ็ค 10 กระเป๋าเรียบร้อย!", 3)
    end
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

Tabs.Halloween:AddToggle("TogHalCollectCandy", {
    Title = "6. เก็บแคนดี้พายุลูกกวาดอัตโนมัติ (Auto Collect Candy Storm)",
    Description = "เดินเก็บแคนดี้ (Candy Corn, Lollipop, Candy Bag, Bucket) ในพลาซ่าอัตโนมัติเมื่อพายุเริ่ม ปลอดภัย 100% ด้วยระบบฟิสิกส์เดินปกติ ไร้การบิน/Tween และกลับบ้านอัตโนมัติ",
    Default = CFG.HalloweenAutoCollectCandy,
    Callback = function(V)
        UpdateCFG("HalloweenAutoCollectCandy", V)
        if V then
            Notify("🍬 แคนดี้ฮาโลวีน", "เปิดระบบเก็บแคนดี้พายุลูกกวาดอัตโนมัติแล้ว!", 3)
        else
            Notify("🍬 แคนดี้ฮาโลวีน", "ปิดระบบเก็บแคนดี้พายุลูกกวาด", 2)
        end
    end
})
end -- END TAB 7: HALLOWEEN EVENT

-- ------------------------------------------------------------------------------
-- 🤝 TAB 8: SAFE AUTO TRADE
-- ------------------------------------------------------------------------------
task.wait()
local PutSafeTwoWayTradeItem
local IsAllowedTradeSender
local RespondAcceptTrade
do -- TAB 8: SAFE AUTO TRADE
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
            if not t then
                local sLow = tostring(selection):lower()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and (p.Name:lower() == sLow or (p.DisplayName and p.DisplayName:lower() == sLow)) then
                        t = p; break
                    end
                end
            end
            if t then UpdateCFG("TradeTargetId", t.UserId) end 
        end
    end
})

local function RefreshPlayerDropdown()
    pcall(function()
        if DropdownTrade and DropdownTrade.SetValues then
            DropdownTrade:SetValues(GetPlayerNames())
        end
    end)
end

Players.PlayerAdded:Connect(function()
    task.wait(1)
    if getgenv().PetDiceScriptToken ~= scriptToken then return end
    RefreshPlayerDropdown()
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    if getgenv().PetDiceScriptToken ~= scriptToken then return end
    RefreshPlayerDropdown()
end)

Tabs.Trade:AddButton({
    Title = "🔄 รีเฟรชรายชื่อผู้เล่น",
    Callback = function()
        RefreshPlayerDropdown()
        Notify("🤝 ผู้เล่น", "รีเฟรชรายชื่อผู้เล่นในห้องเรียบร้อย", 2)
    end
})

Tabs.Trade:AddSection("⚙️ การส่งไอเทม & โหมดการทำงาน")

local tradeItemList = {}
for _, item in ipairs(Config.TradeItems or {}) do table.insert(tradeItemList, item.Key) end
if #tradeItemList == 0 then
    tradeItemList = {"PotionLuck", "PotionCash", "PotionSpeed", "Gems", "Shards", "SuperRolls", "JackpotRolls", "LootBags"}
end

local TogSender, TogReceiver, TogAutoDropItems, TogAutoReady

TogAutoDropItems = Tabs.Trade:AddToggle("TogAutoDropItems", {
    Title = "🎁 ส่งไอเทมทั้งหมดอัตโนมัติ (เฉพาะโหมดผู้ส่ง)",
    Default = CFG.AutoDropItems,
    Callback = function(V) UpdateCFG("AutoDropItems", V) end
})

TogAutoReady = Tabs.Trade:AddToggle("TogAutoReady", {
    Title = "✅ กดพร้อม (Ready) อัตโนมัติ",
    Default = CFG.AutoReady,
    Callback = function(V) UpdateCFG("AutoReady", V) end
})

TogSender = Tabs.Trade:AddToggle("TogSender", {
    Title = "🚀 โหมดผู้ส่ง (Sender - ส่งคำขอเทรด + โอนไอเทมทั้งหมด)",
    Default = CFG.SenderMode,
    Callback = function(V) 
        UpdateCFG("SenderMode", V) 
        if V then
            UpdateCFG("AutoDropItems", true)
            UpdateCFG("AutoReady", true)
            if TogAutoDropItems and TogAutoDropItems.SetValue then
                pcall(function() TogAutoDropItems:SetValue(true) end)
            end
            if TogAutoReady and TogAutoReady.SetValue then
                pcall(function() TogAutoReady:SetValue(true) end)
            end
            if CFG.ReceiverMode then
                UpdateCFG("ReceiverMode", false)
                if TogReceiver and TogReceiver.SetValue then
                    pcall(function() TogReceiver:SetValue(false) end)
                end
            end
        end
    end
})

TogReceiver = Tabs.Trade:AddToggle("TogReceiver", {
    Title = "🛒 โหมดผู้รับ (Receiver - รับคำขอเทรด + กันแบน Mule)",
    Default = CFG.ReceiverMode,
    Callback = function(V) 
        UpdateCFG("ReceiverMode", V) 
        if V then
            UpdateCFG("AutoDropItems", false)
            UpdateCFG("AutoReady", true)
            if TogAutoDropItems and TogAutoDropItems.SetValue then
                pcall(function() TogAutoDropItems:SetValue(false) end)
            end
            if TogAutoReady and TogAutoReady.SetValue then
                pcall(function() TogAutoReady:SetValue(true) end)
            end
            if CFG.SenderMode then
                UpdateCFG("SenderMode", false)
                if TogSender and TogSender.SetValue then
                    pcall(function() TogSender:SetValue(false) end)
                end
            end
        end
    end
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
        getgenv().LastTradeRequestTime = tick()
        Fire("TradeRequest", CFG.TradeTargetId)
        getgenv().TradeActiveSession = true
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
        local data = State.Data
        local canTrade = data and Config.TradeUnlocked and Config.TradeUnlocked(data)
        
        local unlockNotice = ""
        if not canTrade then
            local toGo = (Config.TradeToGo and Config.TradeToGo(data)) or ""
            if toGo ~= "" then
                unlockNotice = string.format("⚠️ บัญชียังไม่ปลดล็อคเทรดในเกม (ขาด: %s)\n", toGo)
            else
                local needStr = Config.TradeNeed or "10 REBIRTHS & 10,000 ROLLS"
                unlockNotice = string.format("⚠️ บัญชียังไม่ปลดล็อคเทรดในเกม (ต้องการ: %s)\n", needStr)
            end
        end

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
        
        local titleHeader = canTrade and ("🛡️ ระบบเทรดปลอดภัย: " .. cdStatus) or "🛡️ ระบบเทรด: ⚠️ ยังไม่ปลดล็อคในเกม"
        SafeUpdatePara(TradeStatusPara, titleHeader,
            string.format("%sโหมด: %s\nสถานะ: %s\n%s\nระบบแลกเปลี่ยนสองทาง: %s | หน่วงเวลา Ready: %d วิ",
            unlockNotice, modeStr, inTradeStatus, queueStatus, twoWayStatus, CFG.TradeReadyDelay or 4))
    end)
end

task.spawn(function()
    while true do
        task.wait(3.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        UpdateTradeStatus()
    end
end)

PutSafeTwoWayTradeItem = function()
    local data = State.Data
    if not data then return false end
    
    -- 1. ค้นหาน้ำยาหรือไอเทมพื้นฐานที่มีในตัวมากกว่า 0 (ใส่เพียง 1 ชิ้นเพื่อความปลอดภัย)
    local safeCandidates = {
        "PotionSpeed", "PotionLuck", "PotionCash", 
        "Speed15", "Speed30", "Speed60", "LootBags"
    }
    for _, itemKey in ipairs(safeCandidates) do
        local count = GetRealItemCount(itemKey)
        if count and count >= 1 then
            Fire("TradeItem", itemKey, 1)
            return true, itemKey .. " (1 ชิ้น)"
        end
    end
    
    -- 2. หากไม่มีน้ำยาข้างต้น ให้ใส่ Gems หรือ Shards จำนวนน้อย (10 ชิ้น) ป้องกัน Mule Flag
    for _, itemKey in ipairs({"Gems", "Shards"}) do
        local count = GetRealItemCount(itemKey)
        if count and count >= 10 then
            Fire("TradeItem", itemKey, 10)
            return true, itemKey .. " (10 ชิ้น)"
        end
    end
    
    -- 3. หากไม่มีไอเทมใดๆ ตรวจสอบสัตว์เลี้ยงระดับล่าง (Rank >= 7 หรือเกรด F/E/D/C) ที่ไม่ได้ล็อค ปลอดภัย 100%
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
                        return true, "Pet_" .. tostring(pet.Id) .. " (Rank " .. tostring(rank) .. ")"
                    end
                end
            end
        end
    end
    
    return false
end

IsAllowedTradeSender = function(senderId, senderName)
    if not senderId and not senderName then return false end
    -- หากเป็นค่าเริ่มต้น หรือเลือกทุกคนในห้อง หรือไม่มีการล็อคไอดี -> ยอมรับทุกคน
    if not CFG.TradeTarget or CFG.TradeTarget == "[ เลือกทุกคนในห้อง ]" or CFG.TradeTargetId == nil then return true
    end
    -- เช็คความตรงกันของ UserId (แปลงเป็นตัวเลขป้องกัน type mismatch)
    if CFG.TradeTargetId and senderId and tonumber(senderId) == tonumber(CFG.TradeTargetId) then
        return true
    end
    -- เช็คความตรงกันของชื่อผู้เล่น (แปลงพิมพ์เล็กป้องกัน case sensitive mismatch)
    if senderName and CFG.TradeTarget then
        local sLower = tostring(senderName):lower()
        local tLower = tostring(CFG.TradeTarget):lower()
        if sLower == tLower then return true
        end
        local targetPlr = Players:GetPlayerByUserId(tonumber(CFG.TradeTargetId) or 0)
        if targetPlr then
            if targetPlr.Name:lower() == sLower or (targetPlr.DisplayName and targetPlr.DisplayName:lower() == sLower) then
                return true
            end
        end
    end
    return false
end

local lastTradeRespondTick = 0

RespondAcceptTrade = function(senderId, senderName)
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
            getgenv().TradeActiveSession = false; return
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
end -- END TAB 8: SAFE AUTO TRADE

-- ------------------------------------------------------------------------------
-- 🛡️ TAB 9: SAFETY & SETTINGS
-- ------------------------------------------------------------------------------
task.wait()
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
                local url = "https://raw.githubusercontent.com/markrunerppl-boop/petdicezaza/main/petdicezaza.lua?t=" .. tostring(tick()); return game:HttpGet(url)
            end)
            if not success or not newCode or #newCode < 1000 then
                success, newCode = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/markrunerppl-boop/petdicezaza/main/petdicezaza.lua")
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

-- ==============================================================================
-- 🔔 TAB 10: DISCORD WEBHOOK INVENTORY & STATS NOTIFICATION
-- ==============================================================================
task.wait()
local SendDiscordInventoryReport
local lastDiscordNotifyTick = 0
do -- TAB 10: DISCORD WEBHOOK

SendDiscordInventoryReport = function(isManual)
    local webhookUrl = tostring(CFG.DiscordWebhookUrl or ""):gsub("^%s*(.-)%s*$", "%1")
    if webhookUrl == "" or not (webhookUrl:find("^https://discord%.com/api/webhooks/") or webhookUrl:find("^https://discordapp%.com/api/webhooks/")) then
        if isManual then
            Notify("⚠️ Discord Webhook", "กรุณากรอก Discord Webhook URL ให้ถูกต้องก่อนส่งข้อมูล!\n(ต้องขึ้นต้นด้วย https://discord.com/api/webhooks/...)", 5)
        end
        return false, "Invalid Webhook URL"
    end
    
    local now = tick()
    if isManual and (now - lastDiscordNotifyTick < 10) then
        Notify("⏳ กรุณารอสักครู่", string.format("ระบบจำกัดความถี่เพื่อป้องกัน Discord Rate Limit (รออีก %.0f วินาที)", 10 - (now - lastDiscordNotifyTick)), 3)
        return false, "Cooldown"
    end
    
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if not req then
        if isManual then
            Notify("❌ ไม่รองรับ HTTP", "Executor ของคุณไม่รองรับฟังก์ชันส่ง HTTP Request ภายนอก", 4)
        end
        return false, "No HTTP Support"
    end
    
    local data = State.Data
    if not data then
        if isManual then
            Notify("⚠️ ข้อผิดพลาด", "ไม่พบข้อมูลตัวละคร กำลังรอการเชื่อมต่อข้อมูล...", 3)
        end
        return false, "No Data"
    end
    
    local lp = LocalPlayer
    local headshotUrl = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", lp.UserId)
    local avatarUrl = string.format("https://www.roblox.com/avatar-thumbnail/image?userId=%d&width=420&height=420&format=png", lp.UserId)
    
    local function fmtNum(n)
        if not n then return "0" end
        n = tonumber(n) or 0
        if n >= 1e12 then return string.format("%.2fT", n / 1e12)
        elseif n >= 1e9 then return string.format("%.2fB", n / 1e9)
        elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
        elseif n >= 1e3 then return string.format("%.2fK", n / 1e3)
        else return tostring(math.floor(n)) end
    end

    local function fmtComma(n)
        local s = tostring(math.floor(tonumber(n) or 0)); return (s:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", ""))
    end
    
    local playHours = math.floor((data.PlaySeconds or 0) / 3600)
    local playMins = math.floor(((data.PlaySeconds or 0) % 3600) / 60)
    
    local fields = {}
    
    -- 1. ผู้เล่น & บัญชี
    table.insert(fields, {
        name = "👤 ข้อมูลผู้เล่น & บัญชี (Player Profile)",
        value = string.format("• **ชื่อในเกม:** `%s` (`@%s`)\n• **เกิดใหม่ (Rebirth):** `%s`\n• **ทอยเต๋าไปแล้ว:** `%s ครั้ง`\n• **สุ่มแจ็คพอตสะสม:** `%s ครั้ง`\n• **ตั๋ว/บัตรผ่าน:** `%s ใบ`\n• **เวลาเล่นทั้งหมด:** `%d ชม. %d นาที`",
            lp.DisplayName, lp.Name, tostring(data.Rebirth or data.Rebirths or 0), fmtComma(data.Rolls or 0), fmtComma(data.JackpotRolls or 0), fmtComma(data.Tickets or 0), playHours, playMins),
        inline = false
    })
    
    -- 2. สถานะการเงิน & ความคืบหน้า
    local liveF = (GetCurrentTowerFloor and GetCurrentTowerFloor()) or 0
    local isRunningF = IsTowerRunning and IsTowerRunning()
    local towerFloor = liveF > 0 and liveF or (isRunningF and data.TowerResume and data.TowerResume.Floor) or (data.TowerBest and data.TowerBest.Infinity) or (data.TowerResume and data.TowerResume.Floor) or 0
    local towerBest = (data.TowerBest and data.TowerBest.Infinity) or towerFloor
    table.insert(fields, {
        name = "💰 สถานะการเงิน & ความคืบหน้า (Currencies)",
        value = string.format("• **เงินสด (Cash):** `$%s` (`$%s`)\n• **เพชร (Gems):** `💎 %s`\n• **ชาร์ด (Shards):** `🔮 %s`\n• **หอคอยอินฟินิตี้:** `🗼 ชั้น %d (สูงสุด: %d)`",
            fmtNum(data.Money), fmtComma(data.Money), fmtComma(data.Gems), fmtComma(data.Shards or data.ShardsU or 0), towerFloor, towerBest),
        inline = true
    })
    
    -- 3. อีเวนต์ฮาโลวีน
    local halEntry = data.Seasons and (data.Seasons.Halloween2026 or data.Seasons.Halloween)
    local candyCount = halEntry and (halEntry.Candy or 0) or 0
    local stormCandyCount = halEntry and (halEntry.StormCandy or (halEntry.Stats and halEntry.Stats.StormCandy) or 0) or 0
    local halBags = (data.SeasonBags and data.SeasonBags.Halloween) or 0
    local halPity = (data.SeasonBagPity and data.SeasonBagPity.Halloween) or 0
    local boughtBags = (halEntry and halEntry.Bought and halEntry.Bought.HalloweenBag10 or 0)
    table.insert(fields, {
        name = "🎃 อีเวนต์ฮาโลวีน (Halloween 2026)",
        value = string.format("• **ลูกอม (Candy):** `🍬 %s ลูก`\n• **ลูกอมพายุสะสม:** `⚡ %s ลูก`\n• **ถุงสุ่มฮาโลวีน:** `🎒 %s ถุง` (การันตี: `%d/100`)\n• **ซื้อถุงสุ่มไปแล้ว:** `🛒 %d ครั้ง`",
            fmtComma(candyCount), fmtComma(stormCandyCount), fmtComma(halBags), halPity, boughtBags),
        inline = true
    })
    
    -- 4. ยาบัฟทั้งหมด & บัฟที่เปิดอยู่
    local pots = data.Potions or {}
    local potEnds = data.PotionEnds or {}
    local nowSec = os.time()
    local activeBuffs = {}
    for potName, endSec in pairs(potEnds) do
        local left = (tonumber(endSec) or 0) - nowSec
        if left > 0 then
            local m = math.floor(left / 60)
            local s = math.floor(left % 60)
            table.insert(activeBuffs, string.format("`%s` (เหลือ %d:%02d)", potName, m, s))
        end
    end
    local buffStr = #activeBuffs > 0 and table.concat(activeBuffs, ", ") or "ไม่มีบัฟที่เปิดใช้งาน"
    local totalPotions = (pots.Luck or 0) + (pots.Speed or 0) + (pots.Cash or 0)
    table.insert(fields, {
        name = "🧪 ขวดยาบัฟ & บัฟที่ใช้งาน (Potions & Active Buffs)",
        value = string.format("• **Luck Potion:** `🍀 %s ขวด`\n• **Speed Potion:** `⚡ %s ขวด`\n• **Cash Potion:** `💵 %s ขวด`\n• **รวมยาในคลัง:** `%s ขวด`\n• **บัฟที่กำลังทำงาน:** %s",
            fmtComma(pots.Luck or 0), fmtComma(pots.Speed or 0), fmtComma(pots.Cash or 0), fmtComma(totalPotions), buffStr),
        inline = false
    })
    
    -- 5. จีโอด, ถุงสุ่ม & วัตถุดิบ
    local geods = data.Geodes or {}
    local geodeTiers = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
    local geodeParts = {}
    local totalGeodes = 0
    for _, tier in ipairs(geodeTiers) do
        local cnt = tonumber(geods[tier]) or 0
        totalGeodes = totalGeodes + cnt
        if cnt > 0 then
            table.insert(geodeParts, string.format("**%s:** `%s`", tier, fmtComma(cnt)))
        end
    end
    local geodeStr = #geodeParts > 0 and table.concat(geodeParts, " | ") or "ไม่มีจีโอดในคลัง"
    
    local elemBags = data.ElementBags or {}
    local elemBagParts = {}
    for k, v in pairs(elemBags) do
        local cnt = tonumber(v) or 0
        if cnt > 0 then table.insert(elemBagParts, string.format("%s: `%s`", tostring(k), fmtComma(cnt))) end
    end
    local elemBagStr = #elemBagParts > 0 and table.concat(elemBagParts, ", ") or "ไม่มี"
    
    local mats = data.Materials or {}
    local matParts = {}
    for k, v in pairs(mats) do
        local cnt = tonumber(v) or 0
        if cnt > 0 then table.insert(matParts, string.format("%s: `%s`", tostring(k), fmtComma(cnt))) end
    end
    local matStr = #matParts > 0 and table.concat(matParts, ", ") or "ไม่มี"
    
    table.insert(fields, {
        name = "💎 จีโอด, ถุงสุ่ม & วัตถุดิบ (Geodes, Bags & Materials)",
        value = string.format("• **จีโอด (Geodes รวม %s ก้อน):**\n  └ %s\n• **ถุงสุ่ม (Bags):** ถุงดรอป: `%s ถุง` (การันตี: `%d/100`) | ถุงธาตุ: %s\n• **วัตถุดิบ (Materials):** %s",
            fmtComma(totalGeodes), geodeStr, fmtComma(data.LootBags or 0), data.LootBagPity or 0, elemBagStr, matStr),
        inline = false
    })
    
    -- 6. ลูกเต๋า & แฟชั่น
    local diceList = {}
    if data.OwnedDice then
        for diceName, owned in pairs(data.OwnedDice) do
            if owned then table.insert(diceList, "`" .. tostring(diceName) .. "`") end
        end
    end
    local cosm = data.Cosmetics or {}
    local ownedCosmCount = 0
    if cosm.Owned then for _ in pairs(cosm.Owned) do ownedCosmCount = ownedCosmCount + 1 end end
    local hatStr = (cosm.Hat and cosm.Hat ~= "") and ("`" .. cosm.Hat .. "`") or "ไม่ได้สวมใส่"
    local trailStr = (cosm.Trail and cosm.Trail ~= "") and ("`" .. cosm.Trail .. "`") or "ไม่ได้สวมใส่"
    
    table.insert(fields, {
        name = string.format("🎲 ลูกเต๋า & แฟชั่น (Dice & Cosmetics - มี %d แบบ)", #diceList),
        value = string.format("• **ลูกเต๋าที่ใช้งาน:** `🎲 %s`\n• **ลูกเต๋าที่ครอบครอง:** %s\n• **หมวก:** %s | **รอยเท้า:** %s | **ไอเทมแฟชั่น:** `%d ชิ้น`",
            tostring(data.Dice or "Basic"), table.concat(diceList, ", "), hatStr, trailStr, ownedCosmCount),
        inline = false
    })
    
    -- 7 & 8. สัตว์เลี้ยงที่สวมใส่ (แบ่ง 2 คอลัมน์ ช่อง 1-6 และ ช่อง 7-12 ป้องกัน Discord 1024 char limit)
    local eq1, eq2 = {}, {}
    local totalEquipped = 0
    if (data.EquippedPets or data.Equipped) and data.Pets then
        local eqSource = data.EquippedPets or data.Equipped
        for idx, uid in ipairs(eqSource) do
            local p = data.Pets[tostring(uid)] or data.Pets[uid]
            if p then
                totalEquipped = totalEquipped + 1
                local def = PetData and PetData.ById and PetData.ById[p.Id]
                local petName = def and def.Name or p.Id
                local inc = def and def.Income and fmtComma(def.Income) or "0"
                local info = string.format("`#%02d` **%s** `($%s/s)` [G: `%s` | T: `%s` | M: `%s`]",
                    idx, petName, inc, tostring(p.G or "-"), tostring(p.T or "-"), tostring(p.M or "-"))
                if idx <= 6 then
                    table.insert(eq1, info)
                else
                    table.insert(eq2, info)
                end
            end
        end
    end
    
    table.insert(fields, {
        name = string.format("🐾 สัตว์เลี้ยงที่สวมใส่ (ช่อง 1 - 6) [ทีม %d ตัว]", totalEquipped),
        value = #eq1 > 0 and table.concat(eq1, "\n") or "ไม่มีสัตว์เลี้ยง",
        inline = true
    })
    table.insert(fields, {
        name = "🐾 สัตว์เลี้ยงที่สวมใส่ (ช่อง 7 - 12)",
        value = #eq2 > 0 and table.concat(eq2, "\n") or "ไม่มีสัตว์เลี้ยง",
        inline = true
    })
    
    -- 9. สัตว์เลี้ยงที่ดีที่สุดในกระเป๋า (Top 5 Best Pets in Backpack)
    local allPetsList = {}
    local totalPets = 0
    for uid, p in pairs(data.Pets or {}) do
        totalPets = totalPets + 1
        local def = PetData and PetData.ById and PetData.ById[p.Id]
        table.insert(allPetsList, {
            Uid = uid,
            Name = def and def.Name or p.Id,
            Income = def and def.Income or 0,
            Grade = p.G or "-",
            Trait = p.T or "-",
            Mutation = p.M or "-"
        })
    end
    table.sort(allPetsList, function(a, b) return a.Income > b.Income end)
    
    local top5List = {}
    local medals = {"🥇", "🥈", "🥉", "4️⃣", "5️⃣"}
    for i = 1, math.min(5, #allPetsList) do
        local p = allPetsList[i]
        table.insert(top5List, string.format("%s **%s** `($%s/s)` [เกรด: `%s` | ทักษะ: `%s` | มิวเทชั่น: `%s`]",
            medals[i], p.Name, fmtComma(p.Income), p.Grade, p.Trait, p.Mutation))
    end
    
    table.insert(fields, {
        name = string.format("⭐ สัตว์เลี้ยงที่ดีที่สุดในกระเป๋า (Top 5 Pets - คลังทั้งหมด %s ตัว)", fmtComma(totalPets)),
        value = #top5List > 0 and table.concat(top5List, "\n") or "ไม่มีสัตว์เลี้ยงในกระเป๋า",
        inline = false
    })
    
    local payload = {
        username = "Pet Dice Pro Master Tracker",
        avatar_url = headshotUrl,
        embeds = {
            {
                title = "🎒 สรุปคลังไอเทมและข้อมูลตัวละคร (Inventory & Character Report)",
                description = string.format("รายงานสถานะไอเทมในตัวละครของ **%s** ประจำเวลา `%s`", lp.DisplayName, os.date("!%Y-%m-%d %H:%M:%S UTC")),
                color = 16744216,
                author = {
                    name = string.format("Pet Dice Tracker • %s", lp.Name),
                    icon_url = headshotUrl
                },
                thumbnail = {
                    url = headshotUrl
                },
                image = {
                    url = avatarUrl
                },
                fields = fields,
                footer = {
                    text = "Pet Dice Pro Farm Master Safe Edition • Real-Time Inventory Notifier",
                    icon_url = headshotUrl
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    
    lastDiscordNotifyTick = tick()
    if isManual then
        Notify("📨 กำลังส่งข้อมูล...", "กำลังเชื่อมต่อไปยัง Discord Webhook...", 2)
    end
    
    task.spawn(function()
        local ok, res = pcall(function() return req({
                Url = webhookUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HS:JSONEncode(payload)
            })
        end)
        
        if ok and res and (res.StatusCode == 200 or res.StatusCode == 204) then
            if isManual then
                Notify("✅ ส่งสำเร็จ!", "ส่งสรุปคลังไอเทมและของในตัวเข้า Discord เรียบร้อยแล้ว 📨", 4)
            end
        elseif ok and res and res.StatusCode == 429 then
            if isManual then
                Notify("⏳ ติด Rate Limit", "Discord ขอให้ชะลอการส่ง กรุณารอ 1-2 นาที", 4)
            end
        else
            local errCode = (res and res.StatusCode) or "Error"
            if isManual then
                Notify("❌ ส่งไม่สำเร็จ", "เกิดข้อผิดพลาดในการส่งเข้า Discord (HTTP " .. tostring(errCode) .. ")", 4)
            end
        end
    end)
    return true
end

-- UI Controls for Tabs.Discord
Tabs.Discord:AddSection("🔔 ตั้งค่าระบบแจ้งเตือน Discord Webhook")

Tabs.Discord:AddParagraph({
    Title = "ℹ️ คำแนะนำการใช้งาน",
    Content = "นำลิงก์ Webhook จากห้องแชทใน Discord ของคุณมาใส่ในช่องด้านล่าง เพื่อรับการแจ้งเตือนสรุปไอเทม เงิน สัตว์เลี้ยง และลูกอมฮาโลวีนทั้งหมดแบบเป็นหมวดหมู่ พร้อมรูปภาพประกอบตัวละครของคุณอย่างสวยงาม"
})

Tabs.Discord:AddInput("InputDiscordWebhook", {
    Title = "🔗 Discord Webhook URL",
    Default = CFG.DiscordWebhookUrl or "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Finished = true,
    Callback = function(val)
        local trimmed = tostring(val or ""):gsub("^%s*(.-)%s*$", "%1")
        UpdateCFG("DiscordWebhookUrl", trimmed)
        if trimmed ~= "" then
            if trimmed:find("^https://discord%.com/api/webhooks/") or trimmed:find("^https://discordapp%.com/api/webhooks/") then
                Notify("✅ บันทึก Webhook", "บันทึก Discord Webhook URL สำเร็จ!", 3)
            else
                Notify("⚠️ ลิงก์ไม่ถูกต้อง", "ลิงก์ต้องขึ้นต้นด้วย https://discord.com/api/webhooks/...", 4)
            end
        end
    end
})

Tabs.Discord:AddToggle("TogDiscordAutoNotify", {
    Title = "⏰ เปิดแจ้งเตือนอัตโนมัติตามรอบเวลา (Auto Notify)",
    Description = "ส่งรายงานสถานะคลังไอเทมและของในตัวเข้า Discord อัตโนมัติในพื้นหลังโดยไม่รบกวนการเล่นหรือการฟาร์ม",
    Default = CFG.DiscordAutoNotify,
    Callback = function(val)
        UpdateCFG("DiscordAutoNotify", val)
    end
})

Tabs.Discord:AddSlider("SlideDiscordInterval", {
    Title = "⏱️ ความถี่ในการแจ้งเตือนอัตโนมัติ (นาที)",
    Description = "ระยะเวลาระหว่างการส่งรายงานแต่ละรอบ (แนะนำ 30-60 นาที เพื่อความปลอดภัย)",
    Default = CFG.DiscordNotifyInterval or 30,
    Min = 5,
    Max = 180,
    Rounding = 0,
    Callback = function(val)
        UpdateCFG("DiscordNotifyInterval", val)
    end
})

Tabs.Discord:AddSection("🚀 ส่งข้อมูลทันที (Manual Trigger)")

Tabs.Discord:AddButton({
    Title = "📤 ส่งสรุปกระเป๋าและของในตัวเข้า Discord เดี๋ยวนี้ (Send Now)",
    Description = "ดึงข้อมูลเงิน, เพชร, สัตว์เลี้ยง, ขวดยา, ลูกเต๋า และอีเวนต์ฮาโลวีน พร้อมรูปภาพส่งเข้าห้อง Discord ทันที",
    Callback = function()
        SendDiscordInventoryReport(true)
    end
})

Tabs.Discord:AddSection("📋 รายละเอียดหัวข้อที่จะได้รับใน Discord")

Tabs.Discord:AddParagraph({
    Title = "🖼️ ข้อมูลใน Embed ที่จัดหมวดหมู่อย่างเป็นระเบียบ",
    Content = "• 👤 ข้อมูลผู้เล่น & บัญชี (ชื่อ, Rebirth, ยอดสุ่ม, สุ่มแจ็คพอต, ตั๋ว/บัตรผ่าน, เวลาเล่น)\n• 💰 สถานะการเงิน & ความคืบหน้า (เงินสด, เพชร, ชาร์ด, หอคอยอินฟินิตี้)\n• 🎃 อีเวนต์ฮาโลวีน 2026 (ลูกอม, ลูกอมพายุสะสม, ถุงสุ่มในตัว, แต้มการันตี, สถิติซื้อ)\n• 🧪 ขวดยาบัฟ & บัฟที่ใช้งาน (Luck, Speed, Cash พร้อมเวลานับถอยหลังของบัฟที่เปิดอยู่)\n• 💎 จีโอด, ถุงสุ่ม & วัตถุดิบ (แยกเกรด Common-Mythic, ถุงดรอป, ถุงธาตุ, Essence)\n• 🎲 ลูกเต๋า & แฟชั่น (ลูกเต๋าที่ใช้และที่สะสมครบทุกแบบ, หมวก, รอยเท้า, ของแต่งตัว)\n• 🐾 สัตว์เลี้ยงที่สวมใส่ (แยก 2 คอลัมน์ 12 ตัว พร้อม $/s, เกรด, ทักษะ, มิวเทชั่น)\n• ⭐ สัตว์เลี้ยงที่ดีที่สุดในกระเป๋า (Top 5 Pets พร้อมเหรียญรางวัลและยอดรวมในคลัง)\n• 🖼️ รูปภาพประกอบ: Avatar Headshot Thumbnail และ 3D Full-Body Render"
})
end -- END TAB 10: DISCORD WEBHOOK

task.wait()
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
    elseif event == "Open" then
        getgenv().TradeActiveSession = true
        getgenv().CurrentTradeSession = payload
        getgenv().TradeItemsDropped = false
        getgenv().ReceiverItemPut = false
        getgenv().TradeLockedUntil = tick() + ((payload and payload.You and payload.You.LockedFor) or 3)
    elseif event == "Update" then
        getgenv().TradeActiveSession = true
        getgenv().CurrentTradeSession = payload
        if payload and payload.You and payload.You.LockedFor and payload.You.LockedFor > 0 then
            getgenv().TradeLockedUntil = tick() + payload.You.LockedFor
        end
    elseif event == "Closed" then
        getgenv().CurrentTradeSession = nil
        getgenv().TradeItemsDropped = false
        getgenv().ReceiverItemPut = false
        getgenv().TradeLockedUntil = nil
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
                
                -- AutoEquipBest ตรวจสอบการเปลี่ยนแปลงจำนวนสัตว์เลี้ยงผ่าน Loop 6 อัตโนมัติ (ไม่เซ็ต NeedEquipBest รัว ป้องกันการแย่งคิว Loop 10/11/12)
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
        if not CanRunGeneralFarm() then task.wait(2.0); continue end
        local char = LocalPlayer.Character or Character
        local hum = char and (char:FindFirstChildOfClass("Humanoid") or Humanoid)
        if not char or not hum or hum.Health <= 0 then task.wait(2.0); continue end
        
        if CFG.AutoPlay then
            pcall(function()
                local data = State.Data
                if not data then return end
                
                -- สแกนเรียลไทม์: หากผู้เล่นมีบัฟ/สกิล Auto Roll ของตัวเกม ให้เปิดใช้งาน Native Auto
                local hasNativeAuto = Stats and Stats.HasAuto and Stats.HasAuto(data, State.Mods and State.Mods() or {})
                if hasNativeAuto then
                    if not State.Auto then
                        Fire("SetAuto", true)
                        Humanizer.Wait(0.5, 0.8)
                    end
                    -- เมื่อตัวเกมเปิดระบบ Native Auto Roll สำเร็จแล้ว เซิร์ฟเวอร์จะทอยให้อัตโนมัติ 100%
                    -- ห้ามส่งคำสั่ง Roll ซ้ำเด็ดขาดขณะ State.Auto เป็นจริง เพื่อป้องกันการยิงชนกันและ Error 267
                    if not State.Auto and not State.Rolling then
                        Fire("Roll")
                    end
                    Humanizer.Wait(1.5, 2.5)
                else
                    -- หากยังไม่มีระบบ Native Auto ของเกม ให้สคริปต์ส่งคำสั่งทอยเต๋าตามปกติ
                    Fire("Roll")
                    Humanizer.Wait(1.2, 1.9)
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
        if not CanRunGeneralFarm() then task.wait(2.0); continue end
        
        if CFG.AutoBuyDice then
            pcall(function()
                local data = State.Data
                if not data or not data.Money or not data.OwnedDice or not Config.Dice then return end
                
                local function HasDice(owned, diceId)
                    if not owned or not diceId then return false end
                    if owned[diceId] == true then return true end
                    for _, v in pairs(owned) do
                        if v == diceId then return true end
                    end
                    return false
                end

                -- สแกนเรียลไทม์: ซื้อลูกเต๋าที่ดีที่สุดที่ยังไม่มีและเงินพอ
                for i = #Config.Dice, 1, -1 do
                    local d = Config.Dice[i]
                    if not HasDice(data.OwnedDice, d.Id) and (data.Money or 0) >= (d.Cost or 0) then
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
                        if HasDice(data.OwnedDice, d.Id) then
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
    local lastBossStateInTower = RS:GetAttribute("WorldBossState") or "Idle"
    
    while true do
        task.wait(1.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        LoopHeartbeats["Loop3_AutoTower"] = tick()
        
        local ok, loopErr = pcall(function()
            local curBossState = RS:GetAttribute("WorldBossState") or "Idle"
            if lastBossStateInTower == "Fighting" and curBossState ~= "Fighting" then
                consecutiveFailCount = 0
                lastLoopStartAttempt = 0
            end
            lastBossStateInTower = curBossState
            
            -- ตรวจสอบลำดับความสำคัญ World Boss (Priority 1):
            -- หากบอสโลกกำลังดำเนินอยู่ (ช่วง Joining ที่ตรงตามตัวกรอง หรือช่วง Fighting หรือติด Boss Lockout) ต้องหยุดและออกจากหอคอยทันที
            if isBossActiveLock or getgenv().IsBossActiveLock or (IsWorldBossActive and IsWorldBossActive()) then
                LiveTower.Active = false
                LiveTower.Starting = false
                if IsTowerRunning and IsTowerRunning() and not isWorldBossTransitioning then
                    isWorldBossTransitioning = true
                    Notify("🏰 หอคอย", "พักหอคอยชั่วคราวเพื่อเตรียมตัวสู้บอสโลก...", 2)
                    ClearQueueDuringBoss()
                    if IsTowerInArena and IsTowerInArena() then
                        if ExitArenaCleanly then
                            ExitArenaCleanly()
                        else
                            Fire("TowerLeave")
                        end
                    else
                        Fire("TowerLeave")
                    end
                    task.delay(3.0, function()
                        isWorldBossTransitioning = false
                    end)
                end
                return
            end
            
            if not CanRunTower() then
                if not (IsTowerRunning and IsTowerRunning()) then
                    LiveTower.Active = false
                    LiveTower.Starting = false
                end
                return
            end
            
            local char = LocalPlayer.Character or Character
            local hum = char and (char:FindFirstChildOfClass("Humanoid") or Humanoid)
            if not char or not hum or hum.Health <= 0 then return end
            
            if CFG.Tower and (not IsFeatureUnlocked or IsFeatureUnlocked("Towers", "towers")) then
                local data = State.Data
                if data then
                    -- ตรวจสอบและปิดป๊อปอัป BattleResults และ LootBag หากมีค้างอยู่
                    pcall(function()
                        local pg = LocalPlayer:FindFirstChild("PlayerGui")
                        local br = pg and pg:FindFirstChild("PetDiceUI") and pg.PetDiceUI.Root:FindFirstChild("Effects") and pg.PetDiceUI.Root.Effects:FindFirstChild("BattleResults")
                        if br and br.Visible then br.Visible = false end
                        
                        local lb = pg and pg:FindFirstChild("PetDiceLootBag")
                        if lb then
                            local done = lb:FindFirstChild("Done", true)
                            if done and done:FindFirstChild("Face") then
                                firesignal(done.Face.Activated)
                            elseif done and done:IsA("GuiButton") then
                                firesignal(done.Activated)
                            end
                        end
                    end)
                    
                    -- ปลดล็อค isSwitchingTower อัตโนมัติหากค้างเกิน 5 วินาที
                    local now = tick()
                    if isSwitchingTower and (now - (LiveTower.SwitchingTick or 0) > 5.0) then
                        isSwitchingTower = false
                    end
                    
                    local isRunning = IsTowerRunning()
                    local activeId = GetActiveTowerId()
                    local targetId = (ResolveTowerId and ResolveTowerId(CFG.SelectedTower)) or "Infinity"
                    
                    -- ตรวจสอบเงื่อนไขการพักหอคอยเมื่อกิจกรรมบอสโลกกำลังดำเนินอยู่
                    if not (IsWorldBossActive and IsWorldBossActive()) then
                        if isRunning then
                            consecutiveFailCount = 0
                            -- [PROTECTION] หากกำลังลงหอคอยอยู่ ให้ปล่อยให้สู้ต่อไปจนจบรอบตามปกติ (ห้าม Abort/Switch กลางคันเด็ดขาด เพื่อป้องกัน Error 267)
                            -- เมื่อจบรอบหรือตายแล้ว ระบบจะเริ่มหอคอยเป้าหมาย (targetId) ให้อัตโนมัติในบล็อกถัดไป
                            
                            -- ตรวจสอบและเปิด TowerAutoplay ของตัวเกมให้เป็นจริงเสมอ เพื่อการไต่ชั้นอย่างต่อเนื่อง
                            pcall(function()
                                if data.Settings and data.Settings.TowerAutoplay ~= true then
                                    Fire("SetSetting", "TowerAutoplay", true)
                                end
                            end)
                            
                            -- หากอยู่ในอารีน่า และเปิดออโต้ออกจากอารีน่า ให้ส่งคำสั่งออกสู่ Away Mode
                            if IsTowerInArena() and CFG.AutoExitArena then
                                if ExitArenaCleanly then
                                    ExitArenaCleanly()
                                else
                                    Fire("TowerExit")
                                end
                                Humanizer.Wait(1.0, 1.8)
                            end
                            
                            -- Watchdog: ตรวจสอบกรณีติดค้างเฉพาะเมื่ออยู่ในอารีน่า 3D จริงเท่านั้น
                            -- (ใน Away Mode ตัวเกมแท้จะจัดการไต่ชั้นอัตโนมัติ 100% ไม่ต้องส่งคำสั่งกวน)
                            if IsTowerInArena() and LiveTower.LastFloorTime and (now - LiveTower.LastFloorTime > 85.0) and (now - LastZoneTransitionTime > 6.0) then
                                LiveTower.LastFloorTime = now
                                Fire("TowerLeave")
                                task.wait(4.0)
                                SwitchOrStartTower(targetId, true)
                            end
                        else
                            local baseDelay = math.max(3.0, tonumber(CFG.TowerRestartDelay) or 4.0)
                            local backoffDelay = baseDelay + math.min(20, consecutiveFailCount * 3.0)
                            if not isSwitchingTower and (now - lastLoopStartAttempt >= backoffDelay) then
                                lastLoopStartAttempt = now
                                SwitchOrStartTower(targetId, true)
                                task.delay(4.0, function()
                                    if not IsTowerRunning() then
                                        consecutiveFailCount = consecutiveFailCount + 1
                                        if consecutiveFailCount >= 3 and (consecutiveFailCount % 3 == 0) then
                                            Notify("⏳ หอคอย", "กำลังเว้นระยะห่างก่อนเริ่มหอคอยใหม่ (ป้องกันการส่งคำสั่งซ้ำ)...", 4)
                                        end
                                    else
                                        consecutiveFailCount = 0
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end)
        if not ok then
            warn("[PetDice] AutoTower error caught safely: " .. tostring(loopErr))
        end
    end
end)

-- 3.1. Auto World Boss Runner (Safe Real-Time Engine - Priority 1 Master Boss Sentinel)
task.spawn(function()
    local lastBossJoinAttempt = 0
    local wasInBoss = false
    local hasAttemptedBossJoinThisJoining = false
    local lastWbState = RS:GetAttribute("WorldBossState") or "Idle"
    while true do
        task.wait(1.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        LoopHeartbeats["Loop3_WorldBoss"] = tick()
        if not CanRunWorldBoss() then task.wait(1.5); continue end
        local char = LocalPlayer.Character or Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then task.wait(1.5); continue end
        
        local wbState = RS:GetAttribute("WorldBossState") or "Idle"
        local isJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
        
        if wbState ~= "Joining" then
            hasAttemptedBossJoinThisJoining = false
        end
        
        if isJoined or (wbState == "Fighting" and (wasInBoss or DoesWorldBossMatchFilter())) then
            wasInBoss = true
            wasInWorldBossFight = true
            if not isBossActiveLock then
                isBossActiveLock = true
                getgenv().IsBossActiveLock = true
                lastBossActiveLockTime = tick()
                ClearQueueDuringBoss()
            end
        end
        
        -- เมื่อบอสโลกจบลง ให้พากลับบ้านอย่างปลอดภัย และหน่วงเวลาแบบมนุษย์ก่อนค่อยๆ เริ่มยิงคำสั่งอื่นเข้ามา
        local bossJustEnded = (wasInBoss or wasInWorldBossFight) and (wbState ~= "Fighting" and wbState ~= "Joining") and not isJoined
        if bossJustEnded then
            wasInBoss = false
            wasInWorldBossFight = false
            isWorldBossTransitioning = true
            isBossActiveLock = true
            getgenv().IsBossActiveLock = true
            lastBossActiveLockTime = tick()
            
            Notify("🏆 บอสโลก", "จบศึกบอสโลกเรียบร้อย กำลังวาร์ปกลับบ้าน...", 3)
            -- หน่วงเวลารอคัตซีนและสรุปผลรางวัลบอสจบลง
            Humanizer.Wait(1.8, 2.8)
            pcall(function()
                Fire("Teleport", "Home")
            end)
            LastZoneTransitionTime = tick()
            
            -- [HUMANIZED POST-BOSS DELAY] หน่วงเวลาแบบมนุษย์หลังออกจากด่านบอส ก่อนค่อยๆ เริ่มส่งคำสั่งอื่นเข้ามา
            Notify("⏳ พักผ่อน", "หน่วงเวลาแบบมนุษย์หลังจบศึกบอสโลก กำลังเตรียมความพร้อม...", 4)
            Humanizer.Wait(4.5, 7.5)
            
            -- เคลียร์คิวคำสั่งตกค้างทั้งหมด ป้องกันคำสั่งรัวหลังปลดล็อค
            ClearQueueDuringBoss()
            
            -- ปลดล็อคระบบบอส
            isWorldBossTransitioning = false
            isBossActiveLock = false
            getgenv().IsBossActiveLock = false
            lastBossActiveLockTime = 0
            
            Notify("🚀 เริ่มทำงานต่อ", "สิ้นสุดการพักหน่วงเวลา ค่อยๆ ทยอยเริ่มระบบงานอื่นตามลำดับ...", 3)
            
            -- ทยอยเริ่มระบบหอคอยต่อแบบเว้นระยะห่าง (Staggered Resume)
            if CFG.Tower and SwitchOrStartTower then
                task.spawn(function()
                    Humanizer.Wait(2.2, 3.8)
                    if not isBossActiveLock and not (IsWorldBossActive and IsWorldBossActive()) then
                        local targetId = (ResolveTowerId and ResolveTowerId(CFG.SelectedTower)) or "Infinity"
                        SwitchOrStartTower(targetId, true)
                    end
                end)
            end
        end
        lastWbState = wbState
        
        if CFG.AutoWorldBoss then
            pcall(function()
                local wbElem = RS:GetAttribute("WorldBossElement") or ""
                local wbDiff = RS:GetAttribute("WorldBossDifficulty") or ""
                
                if wbState == "Joining" and not isJoined and not hasAttemptedBossJoinThisJoining then
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
                        -- [DOOR OPEN IMMEDIATE LOCKOUT] ประตูบอสเปิด: ตัดการยิงคำสั่งอื่นทั้งหมดทันที และให้ความสำคัญการตีบอสเป็นอันดับแรก!
                        if not isBossActiveLock then
                            isBossActiveLock = true
                            getgenv().IsBossActiveLock = true
                            lastBossActiveLockTime = tick()
                            ClearQueueDuringBoss()
                            Notify("⚔️ ประตูบอสโลกเปิดแล้ว!", string.format("ตรวจพบประตูบอสโลก [%s %s] เปิดรับสมัคร!\nหยุดยิงคำสั่งอื่นทั้งหมด เพื่อเตรียมตัวตีบอสเป็นอันดับแรก...", wbDiff, wbElem), 4)
                        end
                        
                        local now = tick()
                        if now - lastBossJoinAttempt >= 5.0 then
                            lastBossJoinAttempt = now
                            CircuitBreaker.Execute("WorldBossJoin", function()
                                local data = State.Data
                                local isBossUnlocked = IsFeatureUnlocked("WorldBoss", "worldboss")
                                
                                -- ถ้ายังไม่ปลดล็อค ไม่ต้องออกจากหอคอย
                                if not isBossUnlocked then
                                    isBossActiveLock = false
                                    getgenv().IsBossActiveLock = false
                                    return
                                end
                                
                                -- ตรวจสอบความสมบูรณ์ของประตูบอสโลก
                                if data and data.PortalRepaired == false then
                                    Notify("⚠️ ประตูบอสชำรุด", "กรุณานำ Keystone ไปวางที่หน้าประตูบอสโลกก่อน จึงจะสามารถเข้าร่วมได้!", 5)
                                    isBossActiveLock = false
                                    getgenv().IsBossActiveLock = false
                                    return
                                end
                                
                                -- [HUMAN REACTION DELAY] จำลองเวลามนุษย์รับรู้ว่าประตูบอสเปิด
                                Humanizer.Wait(1.2, 2.2)
                                if getgenv().PetDiceScriptToken ~= scriptToken or not CFG.AutoWorldBoss then return end
                                
                                -- 1. พักหอคอยก่อนเพื่อให้สัตว์เลี้ยงว่างพร้อมตีบอส (Priority 1 เหนือกว่า Tower)
                                if IsTowerRunning and IsTowerRunning() then
                                    Notify("🏰 หอคอย", "ออกจากหอคอยชั่วคราวเพื่อให้สัตว์เลี้ยงพร้อมสู้บอสโลก...", 2)
                                    isWorldBossTransitioning = true
                                    ClearQueueDuringBoss()
                                    if IsTowerInArena and IsTowerInArena() then
                                        if ExitArenaCleanly then
                                            ExitArenaCleanly()
                                        else
                                            Fire("TowerLeave")
                                        end
                                    else
                                        Fire("TowerLeave")
                                    end
                                    local leaveWaitStart = tick()
                                    while IsTowerRunning() and (tick() - leaveWaitStart < 4.0) do
                                        task.wait(0.2)
                                    end
                                    LiveTower.Active = false
                                    LiveTower.Starting = false
                                    LiveTower.LastEventTime = 0
                                    LiveTower.TowerId = nil
                                    -- หน่วงเวลาแบบมนุษย์หลังออกจากหอคอย/อารีน่า
                                    Humanizer.Wait(2.0, 3.2)
                                    LastZoneTransitionTime = tick()
                                    isWorldBossTransitioning = false
                                end
                                
                                -- [HUMAN DELAY BEFORE WALKING]
                                Humanizer.Wait(0.8, 1.5)
                                if getgenv().PetDiceScriptToken ~= scriptToken or not CFG.AutoWorldBoss then return end
                                
                                -- 2. เดินทางไปหน้าประตูบอสด้วยระบบทางการของตัวเกม และเดินขึ้นบันไดตามธรรมชาติ (ปลอดภัยจากการตรวจจับ 100%)
                                local arrived = SafeWalkToBossPortal()
                                
                                -- [HUMAN DELAY AT PORTAL] หน่วงเวลาแบบมนุษย์ที่หน้าประตู
                                Humanizer.Wait(0.8, 1.6)
                                if getgenv().PetDiceScriptToken ~= scriptToken or not CFG.AutoWorldBoss then return end
                                
                                -- 3. ส่งคำสั่งเข้าร่วมบอสโลก
                                if arrived then
                                    hasAttemptedBossJoinThisJoining = true
                                    Fire("WorldBossJoin")
                                    Notify("⚔️ บอสโลก", string.format("เข้าร่วมการตีบอสโลก [%s %s] สำเร็จ!", wbDiff, wbElem), 4)
                                    Humanizer.Wait(1.5, 2.5)
                                else
                                    Notify("⚠️ บอสโลก", "เดินไม่ถึงหน้าประตูบอสโลก ยกเลิกการส่งคำสั่งเพื่อป้องกัน Error 267", 3)
                                end
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
        task.wait(3.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if not CanRunGeneralFarm() then task.wait(2.0); continue end
        if IsTowerInArena and IsTowerInArena() then task.wait(2.0); continue end
        
        if CFG.AutoRebirth then
            local data = State.Data
            if not data then task.wait(1.5); continue end
            
            -- ตรวจสอบเป้าหมาย Rebirth (ถ้าตั้งไว้ และถึงเป้าหมายแล้ว ให้หยุดเกิดใหม่)
            local currentRebirths = data.Rebirths or 0
            local targetRebirths = tonumber(CFG.TargetRebirths) or 0
            if targetRebirths > 0 and currentRebirths >= targetRebirths then
                task.wait(4.0); continue
            end
            
            local cost = Stats and Stats.RebirthCost and Stats.RebirthCost(data)
            if cost and (data.Money or 0) >= cost then
                if isEconomyActionMutex or getgenv().EconomyActionMutex or isZoneTransitionLocked then
                    task.wait(1.0); continue
                end
                
                isEconomyActionMutex = true
                getgenv().EconomyActionMutex = true
                getgenv().LastEconomyActionStartTime = tick()
                
                pcall(function()
                    CircuitBreaker.Execute("AutoRebirth", function()
                        local freshData = State.Data
                        local freshCost = Stats and Stats.RebirthCost and Stats.RebirthCost(freshData)
                        if freshCost and (freshData.Money or 0) >= freshCost then
                            Fire("Rebirth")
                            Humanizer.Wait(2.5, 3.5)
                        end
                    end)
                end)
                
                isEconomyActionMutex = false
                getgenv().EconomyActionMutex = false
                getgenv().LastEconomyActionStartTime = 0
            end
        end
    end
end)

-- 5. Auto Upgrade Skill Tree (Buy All Affordable Upgrades - Safe & Ready Checked)
task.spawn(function()
    while true do
        local delayTime = math.max(3.0, CFG.UpgradeTreeDelay or 3)
        task.wait(delayTime)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if isBossActiveLock or getgenv().IsBossActiveLock or (IsWorldBossActive and IsWorldBossActive()) or not CanRunGeneralFarm() then task.wait(2.0); continue end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0); continue end
        
        if CFG.UpgradeTree or (IsFeatureUnlocked and not IsFeatureUnlocked("Towers", "towers")) then
            if isEconomyActionMutex then task.wait(1.5); continue end
            isEconomyActionMutex = true
            getgenv().EconomyActionMutex = true
            getgenv().LastEconomyActionStartTime = tick()
            
            pcall(function()
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
            
            isEconomyActionMutex = false
            getgenv().EconomyActionMutex = false
            getgenv().LastEconomyActionStartTime = 0
        end
    end
end)

-- 6. Auto Equip Best Pets (Single-Threaded Mutex Guarded - 100% Anti-Kick & Error 267 Immune)
task.spawn(function()
    local lastTotalPets = 0
    local lastPeriodicEquipTime = 0
    while true do
        task.wait(1.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if isBossActiveLock or getgenv().IsBossActiveLock or (IsWorldBossActive and IsWorldBossActive()) or not CanRunGeneralFarm() then task.wait(2.0); continue end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0); continue end
        
        if CFG.AutoEquipBest then
            CircuitBreaker.Execute("AutoEquipBest", function()
                local data = State.Data
                if not data or not data.Pets then return end
                
                -- อนุญาตให้ทำงานในโหมด Tower Away Mode ได้ แต่บล็อกเฉพาะขณะอยู่ใน 3D Arena
                if IsTowerInArena and IsTowerInArena() then
                    return
                end
                if not CanRunGeneralFarm() then
                    return
                end
                
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
                local shouldEquip = false
                
                -- ตรวจสอบเงื่อนไขกระตุ้น:
                -- 1. มีคำขอสวมใส่จากภายนอก (NeedEquipBest = true)
                -- 2. จำนวนสัตว์เลี้ยงเปลี่ยน (มีสัตว์เลี้ยงใหม่หรือขายออก)
                -- 3. สัตว์เลี้ยงที่สวมใส่อยู่ยังไม่เต็มโควต้า
                -- 4. สัตว์เลี้ยงเพิ่งถูกอัปเกรดเลเวล/เกรด/บัฟ (เว้นระยะอย่างน้อย 6 วิ)
                -- 5. สแกนตามรอบเวลา Periodic Check (ทุก 20 วินาที) เผื่อสเตตัสสัตว์เลี้ยงเปลี่ยน
                if getgenv().NeedEquipBest == true then
                    shouldEquip = true
                elseif equippedCount < maxEquipped then
                    shouldEquip = true
                elseif currentTotal ~= lastTotalPets and (now - lastPeriodicEquipTime >= 15.0) then
                    shouldEquip = true
                elseif getgenv().LastPetUpgradedTime and (now - getgenv().LastPetUpgradedTime < 10.0) and (now - lastPeriodicEquipTime >= 10.0) then
                    shouldEquip = true
                elseif (now - lastPeriodicEquipTime >= 20.0) then
                    shouldEquip = true
                else
                    lastTotalPets = currentTotal
                end
                
                if shouldEquip then
                    -- ตั้ง Flag แจ้งให้ Loop อื่นๆ (AutoRollGrade, AutoRollTrait, AutoUpgrade) สละคิวรอเฉพาะขณะสวมใส่
                    getgenv().IsEquipBestPending = true
                    
                    -- รอให้คำสั่งที่กำลังส่งอยู่เสร็จสิ้น (ไม่เกิน 2.0 วินาที)
                    local waitYield = 0
                    while (isPetOperationMutex or isPetEnhanceRolling or isAutoSellingActive or isZoneTransitionLocked) and waitYield < 20 do
                        task.wait(0.1)
                        waitYield = waitYield + 1
                    end
                    
                    -- ล็อค Pet Mutex ป้องกันระบบอื่นแทรกแซงขณะสวมใส่
                    isPetOperationMutex = true
                    getgenv().PetOperationMutex = true
                    getgenv().LastPetOperationStartTime = tick()
                    
                    pcall(function()
                        getgenv().NeedEquipBest = false
                        lastTotalPets = currentTotal
                        lastPeriodicEquipTime = tick()
                        
                        Fire("EquipBest")
                        -- หน่วงเวลาให้เซิร์ฟเวอร์อัปเดตข้อมูลเสร็จสิ้นก่อนปลดล็อค Mutex
                        Humanizer.Wait(1.8, 2.5)
                    end)
                    
                    isPetOperationMutex = false
                    getgenv().PetOperationMutex = false
                    getgenv().IsEquipBestPending = false
                    getgenv().NeedEquipBest = false
                    getgenv().LastPetOperationStartTime = 0
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
        if isBossActiveLock or getgenv().IsBossActiveLock or (IsWorldBossActive and IsWorldBossActive()) or not CanRunGeneralFarm() then task.wait(2.0); continue end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0); continue end
        
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

        -- 3.1 Arena Transition Lock Watchdog (25s Fail-safe)
        if (isArenaTransitionLock or getgenv().IsArenaTransitionActive) and (nowTick - lastArenaTransitionLockTime > 25.0) then
            isArenaTransitionLock = false
            getgenv().IsArenaTransitionActive = false
        end

        -- 3.2 Boss Active Lock Watchdog (Fail-safe: 12 minutes max or 30s if boss state is idle and not joined)
        if isBossActiveLock or getgenv().IsBossActiveLock then
            local wbState = RS:GetAttribute("WorldBossState") or "Idle"
            local isJoined = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
            local lockT = lastBossActiveLockTime or 0
            if (wbState == "Idle" or wbState == "") and not isJoined and not wasInWorldBossFight and not isWorldBossTransitioning then
                if lockT > 0 and (nowTick - lockT > 30.0) then
                    isBossActiveLock = false
                    getgenv().IsBossActiveLock = false
                    lastBossActiveLockTime = 0
                end
            elseif lockT > 0 and (nowTick - lockT > 720.0) then
                isBossActiveLock = false
                getgenv().IsBossActiveLock = false
                lastBossActiveLockTime = 0
            end
        end

        -- 4. Trade Session Watchdog (Auto-clears orphaned TradeActiveSession flag if trade window/session is gone)
        if getgenv().TradeActiveSession then
            local hasSession = (getgenv().CurrentTradeSession ~= nil)
            local hasWindow = (GetTradeWindow and GetTradeWindow() ~= nil)
            if not hasSession and not hasWindow then
                local reqTime = getgenv().LastTradeRequestTime or 0
                if reqTime == 0 or (nowTick - reqTime > 10.0) then
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


-- ==============================================================================
-- 🎃 8. AUTO HALLOWEEN ENGINE (100% Anti-Detection, Priority 3 Integrated)
-- ==============================================================================
task.spawn(function()
    local lastHalloweenBagBuyTick = 0
    local lastHalloweenLimitedPullTick = 0
    local lastHalloweenBagOpenTick = 0
    
    while true do
        task.wait(2.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        
        -- Priority 3 Check: Trade(1) or World Boss(2) takes precedence!
        local canH, blockReason = CanRunHalloween()
        if not canH then
            task.wait(2.0); continue
        end
        
        CircuitBreaker.Execute("AutoHalloween", function()
            local entry = GetHalloweenEntry and GetHalloweenEntry()
            if not entry then return end
            local nowTick = tick()
            
            -- 1. Auto Claim Goals
            if CFG.HalloweenAutoClaim and HalloweenConfig.Goals then
                for _, g in ipairs(HalloweenConfig.Goals) do
                    local currentTier = entry.Goals and entry.Goals[g.Id] or 0
                    local nextTierIdx = currentTier + 1
                    local nextTier = g.Tiers and g.Tiers[nextTierIdx]
                    local stat = entry.Stats and entry.Stats[g.Stat] or 0
                    if nextTier ~= nil and nextTier.Goal ~= nil and stat >= nextTier.Goal then
                        Fire("HalloweenGoalClaim", g.Id)
                        Humanizer.Wait(1.2, 1.8)
                        break
                    end
                end
            end
            
            -- 2. Auto Buy Limited Pull (800 Candy, Limit 10)
            if CFG.HalloweenAutoBuyLimitedPull and (nowTick - lastHalloweenLimitedPullTick > 8) then
                local boughtPulls = entry.Bought and (entry.Bought.LimitedPull or entry.Bought.HalloweenPull or entry.Bought.SinglePull) or 0
                local candyHave = (entry.Candy or 0)
                if boughtPulls < 10 and candyHave >= 800 then
                    lastHalloweenLimitedPullTick = nowTick
                    Fire("SpookyBuy", "LimitedPull")
                    Notify("🎟️ ซื้อตั๋วฮาโลวีน", string.format("ซื้อ Limited Pull สำเร็จ! (%d/10)", boughtPulls + 1), 3)
                    Humanizer.Wait(1.5, 2.5)
                end
            end
            
            -- 3. Auto Buy 10 Bags (270 Candy)
            if CFG.HalloweenAutoBuyBags and (nowTick - lastHalloweenBagBuyTick > 6) then
                local candyHave = (entry.Candy or 0)
                if candyHave >= 270 then
                    lastHalloweenBagBuyTick = nowTick
                    Fire("SpookyBuy", "HalloweenBag10")
                    Notify("🛍️ ซื้อกระเป๋าฮาโลวีน", "ซื้อแพ็ค 10 กระเป๋าเรียบร้อย!", 3)
                    Humanizer.Wait(1.5, 2.5)
                end
            end
            
            -- 4. Auto Open Bags
            if CFG.HalloweenAutoOpenBags and (nowTick - lastHalloweenBagOpenTick > 10) then
                local isBusy = false
                pcall(function()
                    if LootBagController and LootBagController.Api and LootBagController.Api.Busy then
                        isBusy = LootBagController.Api.Busy()
                    end
                    if not isBusy and CutsceneDirector and CutsceneDirector.Director and CutsceneDirector.Director.Playing then
                        isBusy = CutsceneDirector.Director.Playing()
                    end
                end)
                
                if not isBusy then
                    local bagCount = State.Data and State.Data.SeasonBags and State.Data.SeasonBags.Halloween or 0
                    if bagCount > 0 then
                        lastHalloweenBagOpenTick = nowTick
                        if LootBagController and LootBagController.Api and LootBagController.Api.Open then
                            LootBagController.Api.Open("all", "Halloween")
                        else
                            Fire("OpenLootBag", "all", "Halloween")
                        end
                        Notify("🎒 ฮาโลวีน", "กำลังเปิดกระเป๋าฮาโลวีน (" .. bagCount .. " ใบ)...", 3)
                        Humanizer.Wait(4.5, 6.0)
                    end
                    
                    local waitingPets = 0
                    pcall(function()
                        if State.Data and PetData and PetData.WaitingCount then
                            waitingPets = PetData.WaitingCount(State.Data, "Season")
                        end
                    end)
                    if waitingPets > 0 then
                        Humanizer.Wait(1.0, 1.8)
                        Fire("ClaimLootPets", "Season")
                        Notify("🐾 รับสัตว์เลี้ยง", "รับสัตว์เลี้ยงฮาโลวีน " .. waitingPets .. " ตัวเรียบร้อย!", 3)
                        Humanizer.Wait(1.5, 2.5)
                    end
                end
            end
            
            -- 5. Auto Trick or Treat (เดินไปขอขนมเคานต์พาวคูลา)
            if CFG.HalloweenAutoTrickOrTreat and CanTrickOrTreat and CanTrickOrTreat() then
                local canHNow = CanRunHalloween()
                if canHNow and not isCollectingCandyMutex and not isTrickOrTreatMutex and not getgenv().IsCandyStormActiveRunning then
                    isTrickOrTreatMutex = true
                    getgenv().IsTrickOrTreatActiveRunning = true
                    getgenv().TrickOrTreatMutex = true
                    getgenv().LastTrickOrTreatStartTime = tick()
                    
                    pcall(function()
                        if IsTowerInArena and IsTowerInArena() then
                            Notify("🏰 หอคอย", "ออกจากอารีน่าสู่โหมดเบื้องหลังเพื่อไปขอขนม...", 2)
                            if ExitArenaCleanly then
                                ExitArenaCleanly()
                            else
                                Fire("TowerExit")
                            end
                            Humanizer.Wait(1.5, 2.5)
                            LastZoneTransitionTime = tick()
                        end
                        
                        Notify("🍬 ขอขนมฮาโลวีน", "กำลังเดินไปหาเคานต์พาวคูลาเพื่อขอขนมประจำวัน...", 3)
                        local arrived = WalkToPawcula and WalkToPawcula()
                        if arrived and CanTrickOrTreat() then
                            local char = LocalPlayer.Character or Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if hrp and hrp.AssemblyLinearVelocity.Magnitude > 1.5 then
                                task.wait(0.6) -- รอให้ตัวละครหยุดนิ่งสนิทก่อนส่งคำสั่ง เพื่อป้องกัน position desync
                            end
                            
                            Humanizer.Wait(1.0, 1.6)
                            Fire("TrickOrTreat")
                            Notify("🍬 Trick or Treat", "ขอขนมฮาโลวีนสำเร็จเรียบร้อย!", 4)
                            Humanizer.Wait(3.0, 4.2)
                            Fire("Teleport", "Home")
                            Humanizer.Wait(3.5, 4.5)
                            LastZoneTransitionTime = tick()
                        end
                    end)
                    
                    isTrickOrTreatMutex = false
                    getgenv().IsTrickOrTreatActiveRunning = false
                    getgenv().TrickOrTreatMutex = false
                    getgenv().LastTrickOrTreatStartTime = 0
                end
            end
            pcall(UpdateHalloweenStatus)
        end)
    end
end)

-- 8.1. Auto Candy Storm Collector (Priority 3 - Safe Walk, Zero Speed-Hack/Ban)
task.spawn(function()
    while true do
        task.wait(1.0)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        
        -- Watchdogs
        if getgenv().CandyStormMutex or getgenv().IsCandyStormActiveRunning or isCollectingCandyMutex then
            local startT = getgenv().LastCandyStormStartTime or 0
            if startT > 0 and (tick() - startT > 105.0) then
                getgenv().CandyStormMutex = false
                getgenv().IsCandyStormActiveRunning = false
                isCollectingCandyMutex = false
                getgenv().LastCandyStormStartTime = 0
            end
        end
        if getgenv().TrickOrTreatMutex or getgenv().IsTrickOrTreatActiveRunning or isTrickOrTreatMutex then
            local startT = getgenv().LastTrickOrTreatStartTime or 0
            if startT > 0 and (tick() - startT > 60.0) then
                getgenv().TrickOrTreatMutex = false
                getgenv().IsTrickOrTreatActiveRunning = false
                isTrickOrTreatMutex = false
                getgenv().LastTrickOrTreatStartTime = 0
                pcall(function() Fire("Teleport", "Home") end)
            end
        end
        
        if not CFG.HalloweenAutoCollectCandy then
            task.wait(2.0); continue
        end
        
        -- Priority 3 Check: Trade(1) or World Boss(2) takes precedence!
        local canH = CanRunHalloween()
        if not canH then
            task.wait(2.0); continue
        end
        
        local isStormActive = IsCandyStormActive and IsCandyStormActive()
        local targets = GetAvailableCandies and GetAvailableCandies() or {}
        
        -- ตรวจสอบเงื่อนไขเริ่มทำงาน: พายุกำลังตกจริง หรือมีลูกอมในพลาซ่าจริงเท่านั้น
        if isStormActive or #targets > 0 then
            SafeCollectPlazaCandies(false)
        end
    end
end)

-- 9. Auto Trade Runner (Safe Real-Time Engine)
task.spawn(function()
    while true do
        task.wait(1.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if isBossActiveLock or getgenv().IsBossActiveLock or (IsWorldBossActive and IsWorldBossActive()) then task.wait(2.0); continue end
        
        -- สแกนเรียลไทม์: ตรวจสอบเงื่อนไขว่าปลดล็อคการเทรดในเกมหรือยัง (10 Rebirths & 10,000 Rolls)
        local data = State.Data
        local canTrade = data and Config.TradeUnlocked and Config.TradeUnlocked(data)
        if not canTrade then
            task.wait(5.0); continue
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
            if CFG.SenderMode then
                if not CFG.TradeTargetId and CFG.TradeTarget and CFG.TradeTarget ~= "[ เลือกทุกคนในห้อง ]" then
                    local p = Players:FindFirstChild(CFG.TradeTarget)
                    if not p then
                        local sLow = tostring(CFG.TradeTarget):lower()
                        for _, pl in ipairs(Players:GetPlayers()) do
                            if pl ~= LocalPlayer and (pl.Name:lower() == sLow or (pl.DisplayName and pl.DisplayName:lower() == sLow)) then
                                p = pl; break
                            end
                        end
                    end
                    if p then CFG.TradeTargetId = p.UserId end
                end

                if CFG.TradeTargetId then
                    local lastComplete = getgenv().LastTradeCompleteTime or 0
                    local elapsed = tick() - lastComplete
                    local cd = CFG.TradeCooldown or 90
                    
                    if elapsed >= cd then
                        CircuitBreaker.Execute("TradeSender", function()
                            local inWBoss = (LocalPlayer:GetAttribute("WorldBossJoined") == true) or (LocalPlayer:GetAttribute("InWorldBoss") == true)
                            if inWBoss then return end
                            
                            local targetPlayer = Players:GetPlayerByUserId(CFG.TradeTargetId)
                            if targetPlayer and targetPlayer.Parent == Players then
                                if targetPlayer:GetAttribute("PetDiceTradeOff") == true then
                                    return
                                end
                                if targetPlayer:GetAttribute("PetDiceTradeLocked") == true then
                                    return
                                end

                                -- เคลียร์การลงหอคอย/อารีน่าอย่างปลอดภัยก่อนส่งคำขอเทรด
                                if IsTowerInArena and IsTowerInArena() then
                                    Fire("TowerExit")
                                    Humanizer.Wait(0.5, 0.8)
                                end
                                
                                -- ส่งคำขอเทรดและล็อคสถานะ TradeActiveSession
                                getgenv().LastTradeRequestTime = tick()
                                Fire("TradeRequest", CFG.TradeTargetId)
                                getgenv().TradeActiveSession = true
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
                                    reqSenderPlayer = p; break
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
            -- ป้องกันฝั่ง Receiver ไม่ให้ดรอปของทั้งหมดเด็ดขาด ทำงานเฉพาะเมื่อเป็นฝั่ง Sender เท่านั้น
            local isSender = (CFG.SenderMode or CFG.AutoDropItems) and not CFG.ReceiverMode
            if isSender and not getgenv().TradeItemsDropped then
                Humanizer.Wait(1.5, 2.2)
                if IsInTrade() then
                    local droppedCount = 0
                    local itemsToDrop = {}
                    if Config.TradeItems then
                        for _, it in ipairs(Config.TradeItems) do
                            table.insert(itemsToDrop, it.Key)
                        end
                    else
                        itemsToDrop = {
                            "PotionLuck", "PotionCash", "PotionSpeed",
                            "Gems", "Shards", "SuperRolls", "JackpotRolls",
                            "LootBags", "BagWorld", "Speed15", "Speed30", "Speed60"
                        }
                    end
                    
                    for _, itemKey in ipairs(itemsToDrop) do
                        if not IsInTrade() then break end
                        local realCount = GetRealItemCount(itemKey)
                        local curSession = getgenv().CurrentTradeSession
                        local curYou = curSession and curSession.You
                        local alreadyInTrade = (curYou and curYou.Items and curYou.Items[itemKey]) or 0
                        if realCount > 0 and alreadyInTrade < realCount then
                            Fire("TradeItem", itemKey, realCount)
                            droppedCount = droppedCount + 1
                            Humanizer.Wait(0.35, 0.55)
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
                Humanizer.Wait(1.0, 1.8)
                if IsInTrade() then
                    local okPut, putItem = PutSafeTwoWayTradeItem()
                    if okPut then
                        Notify("🛡️ เทรดสองทาง", "ใส่ไอเทมตอบแทนกลับเรียบร้อย (" .. tostring(putItem) .. ") ป้องกัน Mule Flag", 3)
                        Humanizer.Wait(0.8, 1.4)
                        getgenv().ReceiverItemPut = true
                    else
                        Notify("⚠️ เทรดสองทาง", "ไม่มีไอเทมหรือสัตว์เลี้ยงสำหรับตอบแทน (ดำเนินเทรดต่อ)", 3)
                        getgenv().ReceiverItemPut = true
                    end
                end
            end
            
            -- 3. โหมดกด Ready อัตโนมัติอย่างปลอดภัย (Safe Auto Ready & Real-Time Sync)
            if CFG.AutoReady or CFG.SenderMode or CFG.ReceiverMode then
                session = getgenv().CurrentTradeSession
                you = session and session.You
                them = session and session.Them
                
                -- ตรวจสอบสถานะปุ่ม Ready จริงของเกม
                local _, readyStatusText = GetTradeReadyButton()
                local cleanStatus = string.upper((string.gsub(readyStatusText or "", "%s+", "")))
                
                -- ถ้าปุ่มอยู่ในสถานะรอคูลดาวน์ (เช่น "WAIT 3", "WAIT 2", "WAIT 1") ให้รอจนกว่าคูลดาวน์หมด
                local isLocked = cleanStatus:find("WAIT") or (getgenv().TradeLockedUntil and tick() < getgenv().TradeLockedUntil)
                if isLocked then
                    task.wait(0.5)
                elseif cleanStatus:find("UNREADY") or (you and you.Ready) then
                    -- ฝั่งเรากดพร้อมเรียบร้อยแล้ว ไม่ต้องกดซ้ำ (ป้องกันการกดยกเลิก)
                elseif (cleanStatus:find("READY") or cleanStatus == "") and (not you or not you.Ready) then
                    -- ฝั่งเรายังไม่ได้กดพร้อม และปุ่มปลดล็อคให้กดได้
                    local canPressReady = true
                    
                    -- ตรวจสอบเงื่อนไขฝั่งส่ง: ต้องใส่ไอเทมเสร็จสิ้นแล้ว
                    if isSender and not getgenv().TradeItemsDropped then
                        canPressReady = false
                    end
                    
                    -- ตรวจสอบเงื่อนไขฝั่งรับ: ต้องใส่ไอเทมสองทางแล้ว และรอให้อีกฝ่ายพร้อมหรือใส่ของแล้ว
                    if CFG.ReceiverMode then
                        if (CFG.TwoWayTrade ~= false) and not getgenv().ReceiverItemPut then
                            canPressReady = false
                        elseif them and not them.Ready then
                            local themHasItems = false
                            if them.Pets and #them.Pets > 0 then
                                themHasItems = true
                            elseif them.Items then
                                for _, itCount in pairs(them.Items) do
                                    if type(itCount) == "number" and itCount > 0 then
                                        themHasItems = true; break
                                    end
                                end
                            end
                            if not themHasItems then
                                canPressReady = false
                            end
                        end
                    end
                    
                    if canPressReady and IsInTrade() then
                        -- หน่วงเวลาก่อนกด Ready เพื่อจำลองมนุษย์ตรวจสอบไอเทม (3-5 วินาที)
                        local readyDelay = tonumber(CFG.TradeReadyDelay) or 4
                        if readyDelay > 0 then
                            Humanizer.Wait(readyDelay * 0.75, readyDelay * 1.1)
                        end
                        
                        -- Re-check confirmation before sending
                        if IsInTrade() then
                            local readyFaceNow, textNow = GetTradeReadyButton()
                            local cleanNow = string.upper((string.gsub(textNow or "", "%s+", "")))
                            local curSession = getgenv().CurrentTradeSession
                            local curYou = curSession and curSession.You
                            if (cleanNow == "" or cleanNow:find("READY")) and not cleanNow:find("UNREADY") and not cleanNow:find("WAIT") and (not curYou or not curYou.Ready) then
                                Fire("TradeReady", true)
                                if readyFaceNow and firesignal then
                                    pcall(function() firesignal(readyFaceNow.Activated) end)
                                    pcall(function() firesignal(readyFaceNow.MouseButton1Click) end)
                                    pcall(function() firesignal(readyFaceNow.MouseButton1Down) end)
                                    pcall(function() firesignal(readyFaceNow.MouseButton1Up) end)
                                end
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
        if isBossActiveLock or getgenv().IsBossActiveLock or (IsWorldBossActive and IsWorldBossActive()) or not CanRunGeneralFarm() then task.wait(2.0); continue end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0); continue end
        
        if CFG.AutoUpgradePetLevel then
            if isPetOperationMutex or isAutoSellingActive or getgenv().IsEquipBestPending then
                task.wait(0.3); continue
            end
            isPetOperationMutex = true
            getgenv().PetOperationMutex = true
            getgenv().LastPetOperationStartTime = tick()
            local waitAfter = 0
            
            pcall(function()
                CircuitBreaker.Execute("AutoUpgradePetLevel", function()
                    local data = State.Data
                    if not data or not data.Pets or not data.Money or data.Money <= 0 then 
                        waitAfter = 3.0; return 
                    end
                    
                    -- ตรวจสอบว่าปลดล็อคระบบอัปเลเวลในต้นไม้ทักษะแล้วหรือไม่ ("PetUpgrades" / "petup")
                    if not IsFeatureUnlocked("PetUpgrades", "petup") then
                        waitAfter = 6.0
                        return
                    end
                    
                    local cap = Stats.PetLevelCap(data.Upgrades)
                    if not cap or cap <= 0 then waitAfter = 3.0; return end
                    
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
                        getgenv().NeedEquipBest = true
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
        if isBossActiveLock or getgenv().IsBossActiveLock or (IsWorldBossActive and IsWorldBossActive()) or not CanRunGeneralFarm() then task.wait(2.0); continue end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0); continue end
        
        if CFG.AutoRollGrade then
            if isPetOperationMutex or isPetEnhanceRolling or isAutoSellingActive or getgenv().IsEquipBestPending then
                task.wait(0.25); continue
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
                        waitAfter = 3.0; return
                    end
                    
                    -- ตรวจสอบว่าปลดล็อคระบบเกรดในต้นไม้ทักษะแล้วหรือไม่ ("Grades" / "grades")
                    if not IsFeatureUnlocked("Grades", "grades") then
                        waitAfter = 6.0
                        return
                    end
                    
                    local targetRank = CFG.TargetGradeRank or 8
                    local targetUids = GetTopBestPets(CFG.EnhancePetCount or 4)
                    local rollDelay = math.clamp(CFG.RollSpeed or 0.40, 0.35, 1.5)
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
                        getgenv().LastPetUpgradedTime = tick()
                        getgenv().NeedEquipBest = true
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
        if isBossActiveLock or getgenv().IsBossActiveLock or (IsWorldBossActive and IsWorldBossActive()) or not CanRunGeneralFarm() then task.wait(2.0); continue end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0); continue end
        
        if CFG.AutoRollTrait then
            if isPetOperationMutex or isPetEnhanceRolling or isAutoSellingActive or getgenv().IsEquipBestPending then
                task.wait(0.25); continue
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
                        waitAfter = 3.0; return
                    end
                    
                    -- ตรวจสอบว่าปลดล็อคระบบ Trait (บัฟ) ในต้นไม้ทักษะแล้วหรือไม่ ("Traits" / "traits")
                    if not IsFeatureUnlocked("Traits", "traits") then
                        waitAfter = 6.0
                        return
                    end
                    
                    local targetRank = CFG.TargetTraitRank or 6
                    local targetUids = GetTopBestPets(CFG.EnhancePetCount or 4)
                    local rollDelay = math.clamp(CFG.RollSpeed or 0.40, 0.35, 1.5)
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
                        getgenv().LastPetUpgradedTime = tick()
                        getgenv().NeedEquipBest = true
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
    task.wait(3.5)
    while true do
        task.wait(2.5)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        if isBossActiveLock or getgenv().IsBossActiveLock or (IsWorldBossActive and IsWorldBossActive()) or not CanRunGeneralFarm() then task.wait(2.0); continue end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0); continue end
        if not Character or not Humanoid or Humanoid.Health <= 0 then task.wait(2.0); continue end
        
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
        if isBossActiveLock or getgenv().IsBossActiveLock or (IsWorldBossActive and IsWorldBossActive()) or not CanRunGeneralFarm() then task.wait(2.0); continue end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(2.0); continue end
        
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
                            if not claimed and reached then canPlaytime = true; break end
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
        if isBossActiveLock or getgenv().IsBossActiveLock or (IsWorldBossActive and IsWorldBossActive()) or not CanRunGeneralFarm() then task.wait(3.0); continue end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(3.0); continue end
        if LocalPlayer:GetAttribute("PetDiceLoading") == true then task.wait(2.0); continue end
        
        if CFG.AutoBuyMarket then
            if isEconomyActionMutex then task.wait(1.5); continue end
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
                    local _, canBuyCount, totalCost, _totalLeft = Market.PlanBuyAll(currentWindow, bought, data.Rebirths or 0, data.Money or 0)
                    
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
        if isBossActiveLock or getgenv().IsBossActiveLock or (IsWorldBossActive and IsWorldBossActive()) or not CanRunGeneralFarm() then task.wait(3.0); continue end
        if IsInTrade() or getgenv().TradeActiveSession then task.wait(3.0); continue end
        
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

-- 17. Discord Auto-Notify Background Loop
task.spawn(function()
    while true do
        task.wait(15)
        if getgenv().PetDiceScriptToken ~= scriptToken then break end
        pcall(function()
            if CFG.DiscordAutoNotify and CFG.DiscordWebhookUrl and CFG.DiscordWebhookUrl ~= "" then
                local intervalSec = math.max(5, (tonumber(CFG.DiscordNotifyInterval) or 30)) * 60
                if (tick() - lastDiscordNotifyTick >= intervalSec) then
                    SendDiscordInventoryReport(false)
                end
            end
        end)
    end
end)

-- Expose core tower functions to global environment for external access and re-entry
getgenv().PetDiceStartTower = function(towerId)
    local targetId = ResolveTowerId(towerId or CFG.SelectedTower); return SwitchOrStartTower(targetId, true)
end

isUIInitializing = false
getgenv().PetDiceScriptLoaded = true
getgenv().PetDiceScriptStarting = nil
getgenv().PetDiceNotify = Notify
Notify("🚀 สคริปต์พร้อมทำงาน", "Pet Dice Master Fluent Edition v4.8 โหลดสำเร็จ!", 4)

-- Auto-start tower immediately upon script load if enabled and unlocked
if CFG and CFG.Tower then
    task.delay(1.5, function()
        if getgenv().PetDiceScriptToken == scriptToken and CFG.Tower and not IsTowerRunning() then
            if IsFeatureUnlocked and IsFeatureUnlocked("Towers", "towers") then
                local targetId = ResolveTowerId(CFG.SelectedTower)
                SwitchOrStartTower(targetId, true)
            else
                LiveTower.Active = false
                LiveTower.Starting = false
            end
        end
    end)
end
