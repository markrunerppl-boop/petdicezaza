-- =========================================================
-- Pet Dice Pro Farm (Standalone Rayfield UI Version)
-- =========================================================
repeat task.wait() until game:IsLoaded()

local P = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local VU = game:GetService("VirtualUser")
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

getgenv().CFG = {
    Tower = false, AutoPlay = false, Exit = false,
    Reward = false, Quest = false, Upgrade = false,
    Candy = false, Cutscene = false
}

-- =========================================================
-- ดึง Rayfield UI แบบใช้ pcall เพื่อป้องกัน Error
-- =========================================================
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Failed to load Rayfield UI. Loading Fallback UI...")
    -- =========================================================
    -- ระบบ UI สำรอง (Fallback UI) ในกรณีที่ Rayfield โหลดไม่ขึ้น
    -- =========================================================
    local CG = game:GetService("CoreGui")
    if CG:FindFirstChild("AutoUI") then CG.AutoUI:Destroy() end
    local Gui = Instance.new("ScreenGui", CG) Gui.Name = "AutoUI"
    local Main = Instance.new("Frame", Gui) Main.Size, Main.Position, Main.BackgroundColor3, Main.Draggable, Main.Active = UDim2.new(0, 250, 0, 480), UDim2.new(0.5, -125, 0.4, 0), Color3.fromRGB(30, 30, 35), true, true
    local Top = Instance.new("Frame", Main) Top.Size, Top.BackgroundColor3 = UDim2.new(1, 0, 0, 35), Color3.fromRGB(20, 20, 25)
    local Title = Instance.new("TextLabel", Top) Title.Size, Title.BackgroundTransparency, Title.Text, Title.TextColor3, Title.Font, Title.TextSize = UDim2.new(0.8, 0, 1, 0), 1, " Pet Dice Farm (Fallback)", Color3.new(1,1,1), 3, 14
    local Content = Instance.new("Frame", Main) Content.Size, Content.Position, Content.BackgroundTransparency = UDim2.new(1, 0, 1, -35), UDim2.new(0, 0, 0, 35), 1
    local UIL = Instance.new("UIListLayout", Content) UIL.Padding, UIL.HorizontalAlignment = UDim.new(0, 5), 1
    Instance.new("UIPadding", Content).PaddingTop = UDim.new(0, 10)

    local function AddBtn(txt, id, func)
        local b = Instance.new("TextButton", Content)
        b.Size, b.Font, b.TextSize = UDim2.new(0.9, 0, 0, 35), 3, 13
        local function Upd()
            b.BackgroundColor3 = getgenv().CFG[id] and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
            b.Text = txt .. (getgenv().CFG[id] and ": เปิด" or ": ปิด")
            if getgenv().CFG[id] then task.spawn(func) end
        end
        b.MouseButton1Click:Connect(function() getgenv().CFG[id] = not getgenv().CFG[id]; Upd() end); Upd()
    end

    AddBtn("1. ลงหอคอย", "Tower", function() while getgenv().CFG.Tower do pcall(function() Fire("Funnel", "Towers", 1) task.wait(1) Fire("TowerStart", "Infinity", {"5","8","2","3","7","1"}) end) task.wait(5) end end)
    AddBtn("2. เปิดตีอัตโนมัติ", "AutoPlay", function() while getgenv().CFG.AutoPlay do pcall(function() Fire("SetSetting", "TowerAutoplay", true) end) task.wait(3) end end)
    AddBtn("3. ออกหอคอย", "Exit", function() while getgenv().CFG.Exit do pcall(function() Fire("TowerExit") end) task.wait(4) end end)
    AddBtn("4. รับรางวัลหลัก", "Reward", function() while getgenv().CFG.Reward do pcall(function() Fire("Funnel", "Daily", 1) task.wait(0.5) Fire("ClaimPlaytime", "all") task.wait(0.5) Fire("ClaimDaily") end) task.wait(15) end end)
    AddBtn("5. รับเควสทั้งหมด", "Quest", function() while getgenv().CFG.Quest do pcall(function() Fire("Funnel", "Quests", 1) task.wait(0.5) for i=1,10 do Fire("QuestClaim", "Daily", i) Fire("QuestClaim", "Weekly", i) task.wait(0.05) end end) task.wait(20) end end)
    AddBtn("6. ซื้ออัปเกรดอัตโนมัติ", "Upgrade", function() while getgenv().CFG.Upgrade do pcall(function() Fire("Funnel", "UpgradeTree", 1) task.wait(0.5) Fire("BuyAllUpgrades") end) task.wait(15) end end)
    AddBtn("7. ออโต้วาร์ปเก็บลูกอม", "Candy", function() while getgenv().CFG.Candy do pcall(function() local r = P.LocalPlayer.Character and P.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if r then for _,v in ipairs(workspace:GetDescendants()) do if not getgenv().CFG.Candy then break end local id = tonumber(v.Name) or (v.Name:lower():find("candy") or v.Name:lower():find("drop")) and (tonumber(string.match(v.Name, "%d+")) or v:GetAttribute("ID") or v:GetAttribute("CandyId")) local cf = v:IsA("BasePart") and v.CFrame or (v:IsA("Model") and v.PrimaryPart and v.PrimaryPart.CFrame) if id and cf and tonumber(id)>1000 then r.CFrame = cf task.wait(0.15) Fire("CandyGrab", tonumber(id)) if v:IsA("BasePart") then v.Transparency=1 end task.wait(0.05) end end end end) task.wait(1.5) end end)
    AddBtn("8. ข้ามคัทซีน", "Cutscene", function() while getgenv().CFG.Cutscene do pcall(function() Fire("CutsceneDone") end) task.wait(1) end end)

    local TxtTarget = Instance.new("TextBox", Content)
    TxtTarget.Size, TxtTarget.BackgroundColor3, TxtTarget.TextColor3, TxtTarget.Text, TxtTarget.Font, TxtTarget.TextSize = UDim2.new(0.9, 0, 0, 30), Color3.fromRGB(40, 40, 45), Color3.new(1,1,1), " พิมพ์ชื่อคนที่จะเทรดด้วย...", 3, 12
    TxtTarget.ClearTextOnFocus = true

    local BtnTrade = Instance.new("TextButton", Content)
    BtnTrade.Size, BtnTrade.BackgroundColor3, BtnTrade.TextColor3, BtnTrade.Text, BtnTrade.Font, BtnTrade.TextSize = UDim2.new(0.9, 0, 0, 35), Color3.fromRGB(200, 100, 50), Color3.new(1,1,1), "🤝 โยนของทั้งหมดให้คนนี้", 3, 13
    BtnTrade.MouseButton1Click:Connect(function()
        local tName = TxtTarget.Text:lower()
        local target = nil
        for _, p in pairs(P:GetPlayers()) do
            if p ~= P.LocalPlayer and (p.Name:lower():find(tName) or p.DisplayName:lower():find(tName)) then 
                target = p 
                break 
            end
        end
        if target then
            BtnTrade.Text = "กำลังเทรดให้: " .. target.Name
            task.spawn(function()
                pcall(function()
                    Fire("TradeRespond", target.UserId, true)
                    task.wait(0.5)
                    Fire("Funnel", "Trading", 1)
                    task.wait(1)
                    local items = {"PotionLuck", "PotionCash", "PotionSpeed", "Gems", "Shards", "SuperRolls", "LootBags", "Speed15"}
                    for _, item in ipairs(items) do Fire("TradeItem", item, 999999999) task.wait(0.1) end
                end)
                task.wait(1)
                BtnTrade.Text = "🤝 โยนของทั้งหมดให้คนนี้"
            end)
        end
    end)
    return -- จบการทำงานของ UI สำรอง
end

-- =========================================================
-- ถ้าระบบ UI Rayfield โหลดผ่าน จะทำส่วนนี้ต่อ
-- =========================================================
local Window = Rayfield:CreateWindow({
    Name = "🎲 Pet Dice Pro Farm",
    LoadingTitle = "Loading Script...",
    LoadingSubtitle = "by You",
    Theme = "DarkBlue",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PetDiceFarm",
        FileName = "FarmConfig"
    },
    Discord = { Enabled = false },
    KeySystem = false
})

local TabTower = Window:CreateTab("⚔️ หอคอย", nil)
local TabRewards = Window:CreateTab("🎁 รางวัล & อัปเกรด", nil)
local TabEvent = Window:CreateTab("🎃 กิจกรรม & อื่นๆ", nil)
local TabTrade = Window:CreateTab("🤝 ระบบเทรด", nil)

TabTower:CreateSection("Infinity Tower")
TabTower:CreateToggle({Name = "ลงหอคอย Infinity", CurrentValue = false, Flag = "TogTower", Callback = function(V) getgenv().CFG.Tower = V; if V then task.spawn(function() while getgenv().CFG.Tower do pcall(function() Fire("Funnel", "Towers", 1) task.wait(1) Fire("TowerStart", "Infinity", {"5","8","2","3","7","1"}) end) task.wait(5) end end) end end})
TabTower:CreateToggle({Name = "เปิดระบบตีอัตโนมัติ", CurrentValue = false, Flag = "TogAutoPlay", Callback = function(V) getgenv().CFG.AutoPlay = V; if V then task.spawn(function() while getgenv().CFG.AutoPlay do pcall(function() Fire("SetSetting", "TowerAutoplay", true) end) task.wait(3) end end) end end})
TabTower:CreateToggle({Name = "กดออกหอคอย", CurrentValue = false, Flag = "TogExit", Callback = function(V) getgenv().CFG.Exit = V; if V then task.spawn(function() while getgenv().CFG.Exit do pcall(function() Fire("TowerExit") end) task.wait(4) end end) end end})

TabRewards:CreateSection("รับของรางวัลอัตโนมัติ")
TabRewards:CreateToggle({Name = "รับรางวัลหลัก", CurrentValue = false, Flag = "TogReward", Callback = function(V) getgenv().CFG.Reward = V; if V then task.spawn(function() while getgenv().CFG.Reward do pcall(function() Fire("Funnel", "Daily", 1) task.wait(0.5) Fire("ClaimPlaytime", "all") task.wait(0.5) Fire("ClaimDaily") end) task.wait(15) end end) end end})
TabRewards:CreateToggle({Name = "รับเควสทั้งหมด", CurrentValue = false, Flag = "TogQuest", Callback = function(V) getgenv().CFG.Quest = V; if V then task.spawn(function() while getgenv().CFG.Quest do pcall(function() Fire("Funnel", "Quests", 1) task.wait(0.5) for i = 1, 10 do Fire("QuestClaim", "Daily", i) Fire("QuestClaim", "Weekly", i) task.wait(0.05) end end) task.wait(20) end end) end end})
TabRewards:CreateSection("ต้นไม้อัปเกรด")
TabRewards:CreateToggle({Name = "ซื้ออัปเกรดอัตโนมัติ", CurrentValue = false, Flag = "TogUpgrade", Callback = function(V) getgenv().CFG.Upgrade = V; if V then task.spawn(function() while getgenv().CFG.Upgrade do pcall(function() Fire("Funnel", "UpgradeTree", 1) task.wait(0.5) Fire("BuyAllUpgrades") end) task.wait(15) end end) end end})

TabEvent:CreateSection("กิจกรรม (Event)")
TabEvent:CreateToggle({Name = "ออโต้วาร์ปเก็บลูกอม", CurrentValue = false, Flag = "TogCandy", Callback = function(V) getgenv().CFG.Candy = V; if V then task.spawn(function() while getgenv().CFG.Candy do pcall(function() local r = P.LocalPlayer.Character and P.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if r then for _,v in ipairs(workspace:GetDescendants()) do if not getgenv().CFG.Candy then break end local id = tonumber(v.Name) or (v.Name:lower():find("candy") or v.Name:lower():find("drop")) and (tonumber(string.match(v.Name, "%d+")) or v:GetAttribute("ID") or v:GetAttribute("CandyId")) local cf = v:IsA("BasePart") and v.CFrame or (v:IsA("Model") and v.PrimaryPart and v.PrimaryPart.CFrame) if id and cf and tonumber(id)>1000 then r.CFrame = cf task.wait(0.15) Fire("CandyGrab", tonumber(id)) if v:IsA("BasePart") then v.Transparency=1 end task.wait(0.05) end end end end) task.wait(1.5) end end) end end})
TabEvent:CreateSection("ระบบข้ามเวลา")
TabEvent:CreateToggle({Name = "ข้ามคัทซีนทั้งหมด", CurrentValue = false, Flag = "TogCutscene", Callback = function(V) getgenv().CFG.Cutscene = V; if V then task.spawn(function() while getgenv().CFG.Cutscene do pcall(function() Fire("CutsceneDone") end) task.wait(1) end end) end end})

TabTrade:CreateSection("เลือกผู้เล่นเป้าหมาย")
local TargetPlayerUserId, TargetPlayerName = nil, nil
local function GetPlayerNames() local n = {} for _, p in ipairs(P:GetPlayers()) do if p ~= P.LocalPlayer then table.insert(n, p.Name) end end if #n == 0 then table.insert(n, "ไม่มีผู้เล่นอื่นในเซิร์ฟ") end return n end
local DropdownTrade = TabTrade:CreateDropdown({Name = "เลือกผู้เล่นที่จะเทรดด้วย", Options = GetPlayerNames(), CurrentOption = {"กรุณาเลือกผู้เล่น"}, MultipleOptions = false, Flag = "DropTrade", Callback = function(O) local t = P:FindFirstChild(O[1]) if t then TargetPlayerUserId = t.UserId; TargetPlayerName = t.Name end end})
TabTrade:CreateButton({Name = "🔄 รีเฟรชรายชื่อผู้เล่น", Callback = function() DropdownTrade:Refresh(GetPlayerNames()) end})

TabTrade:CreateSection("ดำเนินการเทรด")
TabTrade:CreateButton({Name = "1. ส่งคำขอเทรด (Send Request)", Callback = function() if TargetPlayerUserId then Fire("TradeRequest", TargetPlayerUserId) Rayfield:Notify({Title = "เทรด", Content = "ส่งคำขอเทรดไปให้ " .. TargetPlayerName .. " แล้ว", Duration = 3}) end end})
TabTrade:CreateButton({Name = "2. ตอบรับเทรดที่ส่งมา (Accept Request)", Callback = function() if TargetPlayerUserId then Fire("TradeRespond", TargetPlayerUserId, true) task.wait(0.5) Fire("Funnel", "Trading", 1) end end})
TabTrade:CreateSection("โยนไอเทม")
TabTrade:CreateButton({Name = "🎁 โยนไอเทมทั้งหมดใส่ช่องเทรด", Callback = function() task.spawn(function() local items = {"PotionLuck", "PotionCash", "PotionSpeed", "Gems", "Shards", "SuperRolls", "LootBags", "Speed15"} for _, item in ipairs(items) do Fire("TradeItem", item, 999999999) task.wait(0.1) end end) end})

Rayfield:LoadConfiguration()
