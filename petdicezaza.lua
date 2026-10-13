-- =========================================================
-- Pet Dice Pro Farm (Fix Auto Trade + Ultra Potato Mode)
-- =========================================================
repeat task.wait() until game:IsLoaded()

local P = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local VU = game:GetService("VirtualUser")
local HS = game:GetService("HttpService")
local CG = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Action = RS:WaitForChild("PetDice"):WaitForChild("Remotes"):WaitForChild("Action")

local function Fire(...)
    Action:FireServer(unpack({...}))
end

-- Anti-AFK
P.LocalPlayer.Idled:Connect(function()
    VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- =========================================================
-- 💾 ระบบ Load/Save การตั้งค่า
-- =========================================================
local File = "PetDice_FarmConfig.json"
getgenv().CFG = getgenv().CFG or {
    Tower = false, AutoPlay = false, Exit = false,
    Reward = false, Quest = false, Upgrade = false,
    Cutscene = false, 
    AutoRequest = false, AutoAccept = false, AutoGive = false
}

if readfile and isfile and isfile(File) then
    pcall(function()
        local saved = HS:JSONDecode(readfile(File))
        for k, v in pairs(saved) do getgenv().CFG[k] = v end
    end)
end

local function SaveSettings()
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

local VIM = game:GetService("VirtualInputManager")
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
    LoadingSubtitle = "Trade Fixed Edition",
    Theme = "DarkBlue",
    Discord = { Enabled = false },
    KeySystem = false
})

-- =========================================================
-- สร้าง TAB
-- =========================================================
local TabTower = Window:CreateTab("⚔️ หอคอย")
local TabRewards = Window:CreateTab("🎁 รางวัล & อัปเกรด")
local TabOther = Window:CreateTab("⚡ อื่นๆ & ลดแลค")
local TabTrade = Window:CreateTab("🤝 ระบบเทรดออโต้")
local TabSettings = Window:CreateTab("⚙️ ตั้งค่า")

-- =========================================================
-- ⚙️ แท็บตั้งค่า (Settings)
-- =========================================================
TabSettings:CreateSection("ระบบบันทึกและจัดการ")
TabSettings:CreateButton({Name = "💾 บันทึกการทำงาน (Save Config)", Callback = function() SaveSettings() Rayfield:Notify({Title = "✅ บันทึกสำเร็จ!", Content = "สคริปต์จะจำค่าไว้ทำงานออโต้ครั้งหน้า", Duration = 3}) end})
TabSettings:CreateButton({Name = "❌ ล้าง UI ออกจากหน้าจอ", Callback = function() Rayfield:Destroy() if ToggleGui then ToggleGui:Destroy() end end})

-- =========================================================
-- ⚔️ แท็บหอคอย
-- =========================================================
TabTower:CreateSection("Infinity Tower")
TabTower:CreateToggle({Name = "ลงหอคอย Infinity", CurrentValue = getgenv().CFG.Tower, Flag = "TogTower", Callback = function(V) getgenv().CFG.Tower = V if V then task.spawn(function() while getgenv().CFG.Tower do pcall(function() Fire("Funnel", "Towers", 1) task.wait(1) Fire("TowerStart", "Infinity", {"5","8","2","3","7","1"}) end) task.wait(5) end end) end end})
TabTower:CreateToggle({Name = "เปิดระบบตีอัตโนมัติ (Autoplay)", CurrentValue = getgenv().CFG.AutoPlay, Flag = "TogAutoPlay", Callback = function(V) getgenv().CFG.AutoPlay = V if V then task.spawn(function() while getgenv().CFG.AutoPlay do pcall(function() Fire("SetSetting", "TowerAutoplay", true) end) task.wait(3) end end) end end})
TabTower:CreateToggle({Name = "กดออกหอคอย (Exit)", CurrentValue = getgenv().CFG.Exit, Flag = "TogExit", Callback = function(V) getgenv().CFG.Exit = V if V then task.spawn(function() while getgenv().CFG.Exit do pcall(function() Fire("TowerExit") end) task.wait(4) end end) end end})

-- =========================================================
-- 🎁 แท็บรางวัล
-- =========================================================
TabRewards:CreateSection("ระบบรับรางวัล")
TabRewards:CreateToggle({Name = "รับรางวัลหลัก (Daily/Playtime)", CurrentValue = getgenv().CFG.Reward, Flag = "TogReward", Callback = function(V) getgenv().CFG.Reward = V if V then task.spawn(function() while getgenv().CFG.Reward do pcall(function() Fire("Funnel", "Daily", 1) task.wait(0.5) Fire("ClaimPlaytime", "all") task.wait(0.5) Fire("ClaimDaily") end) task.wait(15) end end) end end})
TabRewards:CreateToggle({Name = "รับเควสทั้งหมด (Quest)", CurrentValue = getgenv().CFG.Quest, Flag = "TogQuest", Callback = function(V) getgenv().CFG.Quest = V if V then task.spawn(function() while getgenv().CFG.Quest do pcall(function() Fire("Funnel", "Quests", 1) task.wait(0.5) for i=1,10 do Fire("QuestClaim", "Daily", i) Fire("QuestClaim", "Weekly", i) task.wait(0.05) end end) task.wait(20) end end) end end})
TabRewards:CreateSection("ระบบอัปเกรด")
TabRewards:CreateToggle({Name = "ซื้อต้นไม้อัปเกรดอัตโนมัติ", CurrentValue = getgenv().CFG.Upgrade, Flag = "TogUpgrade", Callback = function(V) getgenv().CFG.Upgrade = V if V then task.spawn(function() while getgenv().CFG.Upgrade do pcall(function() Fire("Funnel", "UpgradeTree", 1) task.wait(0.5) Fire("BuyAllUpgrades") end) task.wait(15) end end) end end})

-- =========================================================
-- ⚡ แท็บอื่นๆ & ลดแลค (Ultra Potato)
-- =========================================================
TabOther:CreateSection("ระบบข้ามเวลา")
TabOther:CreateToggle({Name = "ข้ามคัทซีนทั้งหมด", CurrentValue = getgenv().CFG.Cutscene, Flag = "TogCutscene", Callback = function(V) getgenv().CFG.Cutscene = V if V then task.spawn(function() while getgenv().CFG.Cutscene do pcall(function() Fire("CutsceneDone") end) task.wait(1) end end) end end})

TabOther:CreateSection("บูสต์ FPS รีไซดทรัพยากร (Potato Mode)")
TabOther:CreateButton({
    Name = "🚀 เปิดโหมดภาพกากขั้นสุด (ล้างเอฟเฟค 100%)",
    Callback = function()
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 0
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then v:Destroy() end
            end
            local T = workspace.Terrain
            T.WaterWaveSize, T.WaterWaveSpeed, T.WaterReflectance, T.WaterTransparency, T.Decoration = 0, 0, 0, 0, false
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic v.Reflectance = 0 v.CastShadow = false
                elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Sparkles") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Light") then v:Destroy()
                elseif v:IsA("MeshPart") then v.TextureID = "" 
                elseif v:IsA("SpecialMesh") then v.TextureId = ""
                elseif v:IsA("ShirtGraphic") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("Accessory") then v:Destroy() end
            end
            Rayfield:Notify({Title = "🚀 Ultra FPS Boost", Content = "ล้างบางกราฟิกเรียบร้อย! ทรัพยากรเครื่องถูกรีดให้ใช้ขั้นต่ำแล้ว", Duration = 5})
        end)
    end
})

TabOther:CreateToggle({Name = "⬛ ปิดการประมวลผล 3D (จอดำลด CPU 90%)", CurrentValue = false, Flag = "TogBlackScreen", Callback = function(V) pcall(function() RunService:Set3dRenderingEnabled(not V) end) end})

-- =========================================================
-- 🤝 แท็บเทรดออโต้ (✅ แก้ไขหน้าต่างยกเลิกแล้ว)
-- =========================================================
TabTrade:CreateSection("เป้าหมายการเทรด")

local TargetPlayerUserId = "ALL"
local TargetPlayerName = "ทุกคน"

local function GetPlayerNames() 
    local n = {"[ เลือกทุกคนในห้อง ]"} 
    for _, p in ipairs(P:GetPlayers()) do if p ~= P.LocalPlayer then table.insert(n, p.Name) end end 
    if #n == 1 then table.insert(n, "ไม่มีผู้เล่นอื่นในเซิร์ฟ") end 
    return n 
end

local DropdownTrade = TabTrade:CreateDropdown({
    Name = "เลือกผู้เล่นที่จะเทรดด้วย",
    Options = GetPlayerNames(),
    CurrentOption = {"[ เลือกทุกคนในห้อง ]"},
    MultipleOptions = false,
    Flag = "DropTrade",
    Callback = function(O) 
        local selection = O[1]
        if selection == "[ เลือกทุกคนในห้อง ]" then
            TargetPlayerUserId = "ALL"
            TargetPlayerName = "ทุกคน"
        else
            local t = P:FindFirstChild(selection) 
            if t then TargetPlayerUserId = t.UserId; TargetPlayerName = t.Name end 
        end
    end
})
TabTrade:CreateButton({Name = "🔄 รีเฟรชรายชื่อผู้เล่น", Callback = function() DropdownTrade:Refresh(GetPlayerNames()) end})

TabTrade:CreateSection("ระบบ Auto Trade")

TabTrade:CreateToggle({
    Name = "ออโต้ส่งคำขอเทรด (Auto Request)",
    CurrentValue = getgenv().CFG.AutoRequest,
    Flag = "TogAutoRequest",
    Callback = function(V)
        getgenv().CFG.AutoRequest = V
        if V then
            task.spawn(function()
                while getgenv().CFG.AutoRequest do
                    pcall(function()
                        -- ✅ ตรวจสอบ: ถ้ายืนเทรดอยู่แล้ว ห้ามส่งคำขอเด็ดขาด
                        if not P.LocalPlayer.PlayerGui:FindFirstChild("Trading") then
                            if TargetPlayerUserId == "ALL" then
                                for _, p in ipairs(P:GetPlayers()) do
                                    if p ~= P.LocalPlayer then Fire("TradeRequest", p.UserId) end
                                end
                            elseif TargetPlayerUserId then
                                Fire("TradeRequest", TargetPlayerUserId)
                            end
                        end
                    end)
                    task.wait(4) -- ยิงทุก 4 วิ
                end
            end)
        end
    end
})

TabTrade:CreateToggle({
    Name = "ออโต้ยอมรับเทรด (Auto Accept)",
    CurrentValue = getgenv().CFG.AutoAccept,
    Flag = "TogAutoAccept",
    Callback = function(V)
        getgenv().CFG.AutoAccept = V
        if V then
            task.spawn(function()
                while getgenv().CFG.AutoAccept do
                    pcall(function()
                        -- ✅ ตรวจสอบ: ถ้ายืนเทรดอยู่แล้ว ห้ามกดยอมรับซ้ำเด็ดขาด
                        if not P.LocalPlayer.PlayerGui:FindFirstChild("Trading") then
                            if TargetPlayerUserId == "ALL" then
                                for _, p in ipairs(P:GetPlayers()) do
                                    if p ~= P.LocalPlayer then Fire("TradeRespond", p.UserId, true) end
                                end
                                task.wait(0.5); Fire("Funnel", "Trading", 1)
                            elseif TargetPlayerUserId then
                                Fire("TradeRespond", TargetPlayerUserId, true)
                                task.wait(0.5); Fire("Funnel", "Trading", 1)
                            end
                        end
                    end)
                    task.wait(2.5) -- เช็คคนส่งเทรดมาทุก 2.5 วิ
                end
            end)
        end
    end
})

TabTrade:CreateToggle({
    Name = "ออโต้โยนไอเทมทั้งหมด (Auto Give)",
    CurrentValue = getgenv().CFG.AutoGive,
    Flag = "TogAutoGive",
    Callback = function(V)
        getgenv().CFG.AutoGive = V
        if V then
            task.spawn(function()
                while getgenv().CFG.AutoGive do
                    pcall(function()
                        -- ✅ ตรวจสอบ: ต้องรอให้หน้าต่างเทรดเด้งขึ้นมาก่อน ถึงจะเริ่มสูบของลงกล่องเทรด
                        if P.LocalPlayer.PlayerGui:FindFirstChild("Trading") then
                            local items = {"PotionLuck", "PotionCash", "PotionSpeed", "Gems", "Shards", "SuperRolls", "LootBags", "Speed15"} 
                            for _, item in ipairs(items) do 
                                Fire("TradeItem", item, 999999999) 
                                task.wait(0.1) 
                            end
                            task.wait(3) -- โยนของเสร็จให้พักแปปนึง
                        end
                    end)
                    task.wait(1) -- คอยดักจับหน้าต่างเทรดทุกๆ 1 วินาที
                end
            end)
        end
    end
})

-- โหลดค่าตั้งต้นเมื่อรันสคริปต์
Rayfield:LoadConfiguration()
