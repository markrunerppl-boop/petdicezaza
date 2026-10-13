-- =========================================================
-- Pet Dice Pro Farm (Manual Item Drop + Auto Ready Edition)
-- =========================================================
repeat task.wait() until game:IsLoaded()

local P = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local VU = game:GetService("VirtualUser")
local HS = game:GetService("HttpService")
local CG = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local VIM = game:GetService("VirtualInputManager")
local Action = RS:WaitForChild("PetDice"):WaitForChild("Remotes"):WaitForChild("Action")

local function Fire(...) 
    Action:FireServer(unpack({...})) 
end

-- กันหลุด AFK 100%
P.LocalPlayer.Idled:Connect(function()
    VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- =========================================================
-- 💾 ระบบ Load / Auto-Save 
-- =========================================================
local File = "PetDice_MasterConfig.json"
getgenv().CFG = getgenv().CFG or {
    Tower = false, AutoPlay = false, Exit = false,
    Reward = false, Quest = false, Upgrade = false, Cutscene = false,
    SenderMode = false, ReceiverMode = false, 
    TradeTarget = "[ เลือกทุกคนในห้อง ]", TradeTargetId = nil
}

if readfile and isfile and isfile(File) then
    pcall(function()
        local saved = HS:JSONDecode(readfile(File))
        for k, v in pairs(saved) do getgenv().CFG[k] = v end
    end)
end

local function UpdateCFG(key, val)
    getgenv().CFG[key] = val
    if writefile then pcall(function() writefile(File, HS:JSONEncode(getgenv().CFG)) end) end
end

-- =========================================================
-- 📱 ปุ่มลอย UI 
-- =========================================================
if CG:FindFirstChild("PetDiceMobileToggle") then CG.PetDiceMobileToggle:Destroy() end
local ToggleGui = Instance.new("ScreenGui", CG) 
ToggleGui.Name = "PetDiceMobileToggle"

local ToggleBtn = Instance.new("TextButton", ToggleGui)
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(0, 10, 0.3, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "UI"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16
ToggleBtn.Draggable = true

ToggleBtn.MouseButton1Click:Connect(function()
    VIM:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
    task.wait(0.05)
    VIM:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
end)

-- =========================================================
-- โหลด Rayfield UI Library
-- =========================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🎲 Pet Dice Pro Farm",
    LoadingTitle = "Loading Script...",
    LoadingSubtitle = "Manual Drop & Auto Ready Edition",
    Theme = "DarkBlue",
    KeySystem = false
})

-- =========================================================
-- สร้าง TAB 
-- =========================================================
local TabFarm = Window:CreateTab("⚔️ ฟาร์ม & รางวัล")
local TabTrade = Window:CreateTab("🤝 เทรดออโต้")
local TabSet = Window:CreateTab("⚙️ ตั้งค่า & ลดแลค")

-- =========================================================
-- ⚔️ แท็บ 1: ฟาร์ม & รางวัล
-- =========================================================
TabFarm:CreateSection("หอคอย Infinity")
TabFarm:CreateToggle({Name = "1. ลงหอคอย Infinity", CurrentValue = CFG.Tower, Flag = "T1", Callback = function(V) UpdateCFG("Tower", V) end})
TabFarm:CreateToggle({Name = "2. เปิดระบบตีอัตโนมัติ (Autoplay)", CurrentValue = CFG.AutoPlay, Flag = "T2", Callback = function(V) UpdateCFG("AutoPlay", V) end})
TabFarm:CreateToggle({Name = "3. กดออกหอคอย (Exit)", CurrentValue = CFG.Exit, Flag = "T3", Callback = function(V) UpdateCFG("Exit", V) end})

TabFarm:CreateSection("รางวัล & อัปเกรด")
TabFarm:CreateToggle({Name = "4. รับรางวัลหลัก (Daily)", CurrentValue = CFG.Reward, Flag = "T4", Callback = function(V) UpdateCFG("Reward", V) end})
TabFarm:CreateToggle({Name = "5. รับเควสทั้งหมด (Quest)", CurrentValue = CFG.Quest, Flag = "T5", Callback = function(V) UpdateCFG("Quest", V) end})
TabFarm:CreateToggle({Name = "6. ซื้ออัปเกรดอัตโนมัติ", CurrentValue = CFG.Upgrade, Flag = "T6", Callback = function(V) UpdateCFG("Upgrade", V) end})
TabFarm:CreateToggle({Name = "7. ข้ามคัทซีนทั้งหมด", CurrentValue = CFG.Cutscene, Flag = "T7", Callback = function(V) UpdateCFG("Cutscene", V) end})

-- =========================================================
-- 🤝 แท็บ 2: ระบบเทรดออโต้
-- =========================================================
TabTrade:CreateSection("เป้าหมายการเทรด")

local function GetPlayerNames() 
    local n = {"[ เลือกทุกคนในห้อง ]"} 
    for _, p in ipairs(P:GetPlayers()) do 
        if p ~= P.LocalPlayer then table.insert(n, p.Name) end 
    end 
    if #n == 1 then table.insert(n, "ไม่มีผู้เล่นอื่นในเซิร์ฟ") end 
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
            local t = P:FindFirstChild(selection) 
            if t then UpdateCFG("TradeTargetId", t.UserId) end 
        end
    end
})
TabTrade:CreateButton({Name = "🔄 รีเฟรชรายชื่อผู้เล่น", Callback = function() DropdownTrade:Refresh(GetPlayerNames()) end})

TabTrade:CreateSection("โหมดการทำงาน (เลือกอย่างใดอย่างหนึ่ง)")

TabTrade:CreateToggle({
    Name = "🚀 โหมดไอดีหลัก (ส่งเทรดอัตโนมัติ)",
    CurrentValue = CFG.SenderMode,
    Flag = "TogSender",
    Callback = function(V) UpdateCFG("SenderMode", V) end
})

TabTrade:CreateToggle({
    Name = "🛒 โหมดไอดีไก่ (รับคำขอ + กดพร้อมอัตโนมัติ)",
    CurrentValue = CFG.ReceiverMode,
    Flag = "TogReceiver",
    Callback = function(V) UpdateCFG("ReceiverMode", V) end
})

-- ปุ่มกดโยนไอเทมด้วยมือ (รวบรวมทุกชื่อไอเทมที่คุณเคยส่งมา)
TabTrade:CreateSection("ปุ่มโยนไอเทมด้วยมือ")
TabTrade:CreateButton({
    Name = "🎁 โยนไอเทมทั้งหมดใส่ช่องเทรด (กดปุ่มนี้ตอนอยู่หน้าเทรด)", 
    Callback = function() 
        task.spawn(function() 
            local allItems = {"PotionLuck", "PotionCash", "Speed30", "GeodeLegendary" , "PotionSpeed", "Gems", "Shards", "SuperRolls", "LootBags", "Speed15", "BagWorld", "GeodeEpic", "JackpotRolls"} 
            for _, item in ipairs(allItems) do 
                Fire("TradeItem", item, 999999999) 
                task.wait(0.1) 
            end 
        end) 
    end
})

-- =========================================================
-- ⚙️ แท็บ 3: ตั้งค่า & ลดแลค
-- =========================================================
TabSet:CreateSection("บูสต์ FPS ลดการกิน CPU")
TabSet:CreateButton({
    Name = "🚀 เปิดโหมดภาพกากขั้นสุด (ลบเอฟเฟคทั้งเกม)",
    Callback = function()
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; Lighting.Brightness = 0
            for _, v in pairs(Lighting:GetChildren()) do 
                if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then v:Destroy() end 
            end
            workspace.Terrain.WaterWaveSize = 0
            workspace.Terrain.Decoration = false
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then 
                    v.Material = Enum.Material.SmoothPlastic 
                    v.Reflectance = 0 
                    v.CastShadow = false
                elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then 
                    v:Destroy()
                elseif v:IsA("MeshPart") or v:IsA("SpecialMesh") then 
                    v.TextureID = "" 
                    v.TextureId = "" 
                elseif v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") then 
                    v:Destroy() 
                end
            end
        end)
    end
})
TabSet:CreateToggle({Name = "⬛ ปิดประมวลผล 3D (จอดำลด CPU)", CurrentValue = false, Flag = "TogBlackScreen", Callback = function(V) pcall(function() RunService:Set3dRenderingEnabled(not V) end) end})
TabSet:CreateSection("การจัดการ")
TabSet:CreateButton({Name = "❌ ปิด UI ออกจากหน้าจอ", Callback = function() Rayfield:Destroy() if ToggleGui then ToggleGui:Destroy() end end})


-- =========================================================
-- ⚙️ Master Loop Workers (ทำงานฟาร์มอัตโนมัติ)
-- =========================================================
task.spawn(function() while task.wait(4) do if CFG.Tower then pcall(function() Fire("Funnel", "Towers", 1) task.wait(1) Fire("TowerStart", "Infinity", {"5","8","2","3","7","1"}) end) end end end)
task.spawn(function() while task.wait(3) do if CFG.AutoPlay then pcall(function() Fire("SetSetting", "TowerAutoplay", true) end) end end end)
task.spawn(function() while task.wait(4) do if CFG.Exit then pcall(function() Fire("TowerExit") end) end end end)
task.spawn(function() while task.wait(15) do if CFG.Reward then pcall(function() Fire("Funnel", "Daily", 1) task.wait(0.5) Fire("ClaimPlaytime", "all") task.wait(0.5) Fire("ClaimDaily") end) end end end)
task.spawn(function() while task.wait(20) do if CFG.Quest then pcall(function() Fire("Funnel", "Quests", 1) task.wait(0.5) for i=1,10 do Fire("QuestClaim", "Daily", i) Fire("QuestClaim", "Weekly", i) end end) end end end)
task.spawn(function() while task.wait(15) do if CFG.Upgrade then pcall(function() Fire("Funnel", "UpgradeTree", 1) task.wait(0.5) Fire("BuyAllUpgrades") end) end end end)
task.spawn(function() while task.wait(1) do if CFG.Cutscene then pcall(function() Fire("CutsceneDone") end) end end end)

-- =========================================================
-- 🤝 Trade Loop Worker (ส่งคำขออัตโนมัติ + ฝั่งรับกดพร้อมอัตโนมัติเมื่ออยู่หน้าเทรด)
-- =========================================================
local function IsInTrade()
    local pg = P.LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local tradeUI = pg:FindFirstChild("Trading") or pg:FindFirstChild("Trade")
        if tradeUI then
            if tradeUI:IsA("ScreenGui") then return tradeUI.Enabled end
            if tradeUI:IsA("Frame") or tradeUI:IsA("GuiObject") then return tradeUI.Visible end
            return true 
        end
    end
    return false
end

-- 1. ลูปของ "ไอดีหลัก" (ส่งคำขอเทรดอัตโนมัติ)
task.spawn(function()
    while task.wait(3.0) do
        if CFG.SenderMode then
            pcall(function()
                if not IsInTrade() then
                    if CFG.TradeTarget == "[ เลือกทุกคนในห้อง ]" then
                        for _, p in ipairs(P:GetPlayers()) do 
                            if p ~= P.LocalPlayer then 
                                Fire("TradeRequest", p.UserId) 
                                task.wait(0.2)
                            end 
                        end
                    elseif CFG.TradeTargetId then
                        Fire("TradeRequest", CFG.TradeTargetId)
                    end
                end
            end)
        end
    end
end)

-- 2. ลูปของ "ไอดีไก่" (รับคำขอเทรดอัตโนมัติ และกดพร้อม Ready อัตโนมัติเมื่อเข้าหน้าเทรด)
task.spawn(function()
    while task.wait(2.0) do
        if CFG.ReceiverMode then
            pcall(function()
                if IsInTrade() then
                    -- เมื่ออยู่หน้าเทรดแล้ว ฝั่งรับทำการกดพร้อม (TradeReady) ให้ทันที
                    task.wait(1.0)
                    Fire("TradeReady", true)
                else
                    -- รับคำขอเทรด
                    if CFG.TradeTarget == "[ เลือกทุกคนในห้อง ]" then
                        for _, p in ipairs(P:GetPlayers()) do 
                            if p ~= P.LocalPlayer then 
                                Fire("TradeRespond", p.UserId, true) 
                                task.wait(0.2)
                            end 
                        end
                    elseif CFG.TradeTargetId then
                        Fire("TradeRespond", CFG.TradeTargetId, true)
                    end
                    task.wait(1.0)
                    Fire("Funnel", "Trading", 1)
                end
            end)
        end
    end
end)
