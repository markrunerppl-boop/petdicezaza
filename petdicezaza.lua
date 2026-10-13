-- =========================================================
-- Pet Dice Pro Farm (Rayfield UI Version)
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
-- โหลด Rayfield UI Library
-- =========================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

-- =========================================================
-- TABS (แบ่งหมวดหมู่)
-- =========================================================
local TabTower = Window:CreateTab("⚔️ หอคอย", nil)
local TabRewards = Window:CreateTab("🎁 รางวัล & อัปเกรด", nil)
local TabEvent = Window:CreateTab("🎃 กิจกรรม & อื่นๆ", nil)
local TabTrade = Window:CreateTab("🤝 ระบบเทรด", nil)

-- =========================================================
-- แท็บ 1: หอคอย (Tower)
-- =========================================================
TabTower:CreateSection("Infinity Tower")

TabTower:CreateToggle({
    Name = "ลงหอคอย Infinity",
    CurrentValue = false,
    Flag = "TogTower",
    Callback = function(Value)
        getgenv().CFG.Tower = Value
        if Value then
            task.spawn(function()
                while getgenv().CFG.Tower do
                    pcall(function()
                        Fire("Funnel", "Towers", 1)
                        task.wait(1)
                        Fire("TowerStart", "Infinity", {"5","8","2","3","7","1"})
                    end)
                    task.wait(5)
                end
            end)
        end
    end
})

TabTower:CreateToggle({
    Name = "เปิดระบบตีอัตโนมัติ (Autoplay)",
    CurrentValue = false,
    Flag = "TogAutoPlay",
    Callback = function(Value)
        getgenv().CFG.AutoPlay = Value
        if Value then
            task.spawn(function()
                while getgenv().CFG.AutoPlay do
                    pcall(function() Fire("SetSetting", "TowerAutoplay", true) end)
                    task.wait(3)
                end
            end)
        end
    end
})

TabTower:CreateToggle({
    Name = "กดออกหอคอย (Exit)",
    CurrentValue = false,
    Flag = "TogExit",
    Callback = function(Value)
        getgenv().CFG.Exit = Value
        if Value then
            task.spawn(function()
                while getgenv().CFG.Exit do
                    pcall(function() Fire("TowerExit") end)
                    task.wait(4)
                end
            end)
        end
    end
})

-- =========================================================
-- แท็บ 2: รางวัล & อัปเกรด (Rewards & Upgrade)
-- =========================================================
TabRewards:CreateSection("รับของรางวัลอัตโนมัติ")

TabRewards:CreateToggle({
    Name = "รับรางวัลหลัก (Daily / Playtime)",
    CurrentValue = false,
    Flag = "TogReward",
    Callback = function(Value)
        getgenv().CFG.Reward = Value
        if Value then
            task.spawn(function()
                while getgenv().CF
