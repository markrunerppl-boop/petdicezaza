repeat task.wait() until game:IsLoaded()
local P, RS, VU, HS = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("VirtualUser"), game:GetService("HttpService")
local Action = RS:WaitForChild("PetDice"):WaitForChild("Remotes"):WaitForChild("Action")
local function Fire(...) Action:FireServer(unpack({...})) end

-- กัน AFK
P.LocalPlayer.Idled:Connect(function() VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame) task.wait(1) VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end)

-- โหลดค่าที่เซฟ
local File = "PetDice_MinFarm.json"
getgenv().CFG = getgenv().CFG or {}
if readfile and isfile and isfile(File) then pcall(function() for k,v in pairs(HS:JSONDecode(readfile(File))) do getgenv().CFG[k] = v end end) end

-- ล้าง UI เก่า
local CG = game:GetService("CoreGui")
if CG:FindFirstChild("AutoUI") then CG.AutoUI:Destroy() end

-- สร้าง UI (ปรับความสูงเป็น 480 เพื่อรับช่องใส่ชื่อ)
local Gui = Instance.new("ScreenGui", CG) Gui.Name = "AutoUI"
local Main = Instance.new("Frame", Gui) Main.Size, Main.Position, Main.BackgroundColor3, Main.Draggable, Main.Active = UDim2.new(0, 250, 0, 480), UDim2.new(0.5, -125, 0.4, 0), Color3.fromRGB(30, 30, 35), true, true
local Top = Instance.new("Frame", Main) Top.Size, Top.BackgroundColor3 = UDim2.new(1, 0, 0, 35), Color3.fromRGB(20, 20, 25)
local Title = Instance.new("TextLabel", Top) Title.Size, Title.BackgroundTransparency, Title.Text, Title.TextColor3, Title.Font, Title.TextSize = UDim2.new(0.8, 0, 1, 0), 1, " Pet Dice Pro Farm", Color3.new(1,1,1), 3, 14
local Min = Instance.new("TextButton", Top) Min.Size, Min.Position, Min.BackgroundTransparency, Min.Text, Min.TextColor3, Min.TextSize = UDim2.new(0, 35, 1, 0), UDim2.new(1, -35, 0, 0), 1, "-", Color3.new(1,1,1), 20
local Content = Instance.new("Frame", Main) Content.Size, Content.Position, Content.BackgroundTransparency = UDim2.new(1, 0, 1, -35), UDim2.new(0, 0, 0, 35), 1
local UIL = Instance.new("UIListLayout", Content) UIL.Padding, UIL.HorizontalAlignment = UDim.new(0, 5), 1
Instance.new("UIPadding", Content).PaddingTop = UDim.new(0, 10)

Min.MouseButton1Click:Connect(function() Content.Visible = not Content.Visible; Main.Size = Content.Visible and UDim2.new(0, 250, 0, 480) or UDim2.new(0, 250, 0, 35); Min.Text = Content.Visible and "-" or "+" end)

-- ฟังก์ชันสร้างปุ่มลูป
local Order = 1
local function AddBtn(txt, id, func)
    local b = Instance.new("TextButton", Content)
    b.Size, b.Font, b.TextSize, b.LayoutOrder = UDim2.new(0.9, 0, 0, 35), 3, 13, Order
    Order = Order + 1
    local function Upd()
        b.BackgroundColor3 = getgenv().CFG[id] and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
        b.Text = txt .. (getgenv().CFG[id] and ": เปิด" or ": ปิด")
        if getgenv().CFG[id] then task.spawn(func) end
    end
    b.MouseButton1Click:Connect(function() getgenv().CFG[id] = not getgenv().CFG[id]; Upd() end); Upd()
end

-- ลูปบอทฟาร์ม (ปุ่ม 1-8)
AddBtn("1. ลงหอคอย", "T1", function() while getgenv().CFG.T1 do pcall(function() Fire("Funnel", "Towers", 1) task.wait(1) Fire("TowerStart", "Infinity", {"5","8","2","3","7","1"}) end) task.wait(5) end end)
AddBtn("2. เปิดตีอัตโนมัติ", "T2", function() while getgenv().CFG.T2 do pcall(function() Fire("SetSetting", "TowerAutoplay", true) end) task.wait(3) end end)
AddBtn("3. ออกหอคอย", "T3", function() while getgenv().CFG.T3 do pcall(function() Fire("TowerExit") end) task.wait(4) end end)
AddBtn("4. รับรางวัลหลัก", "T4", function() while getgenv().CFG.T4 do pcall(function() Fire("Funnel", "Daily", 1) task.wait(0.5) Fire("ClaimPlaytime", "all") task.wait(0.5) Fire("ClaimDaily") end) task.wait(15) end end)
AddBtn("5. รับเควสทั้งหมด", "T5", function() while getgenv().CFG.T5 do pcall(function() Fire("Funnel", "Quests", 1) task.wait(0.5) for i=1,10 do Fire("QuestClaim", "Daily", i) Fire("QuestClaim", "Weekly", i) task.wait(0.05) end end) task.wait(20) end end)
AddBtn("6. ซื้ออัปเกรดอัตโนมัติ", "T6", function() while getgenv().CFG.T6 do pcall(function() Fire("Funnel", "UpgradeTree", 1) task.wait(0.5) Fire("BuyAllUpgrades") end) task.wait(15) end end)
AddBtn("7. ออโต้วาร์ปเก็บลูกอม", "T7", function() 
    while getgenv().CFG.T7 do pcall(function() local r = P.LocalPlayer.Character and P.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if r then for _,v in ipairs(workspace:GetDescendants()) do if not getgenv().CFG.T7 then break end local id = tonumber(v.Name) or (v.Name:lower():find("candy") or v.Name:lower():find("drop")) and (tonumber(string.match(v.Name, "%d+")) or v:GetAttribute("ID") or v:GetAttribute("CandyId")) local cf = v:IsA("BasePart") and v.CFrame or (v:IsA("Model") and v.PrimaryPart and v.PrimaryPart.CFrame) if id and cf and tonumber(id)>1000 then r.CFrame = cf task.wait(0.15) Fire("CandyGrab", tonumber(id)) if v:IsA("BasePart") then v.Transparency=1 end task.wait(0.05) end end end end) task.wait(1.5) end 
end)
AddBtn("8. ข้ามคัทซีน", "T8", function() while getgenv().CFG.T8 do pcall(function() Fire("CutsceneDone") end) task.wait(1) end end)

-- ==========================================
-- 📦 ระบบเทรดของทั้งหมด (Trade All)
-- ==========================================
local TxtTarget = Instance.new("TextBox", Content)
TxtTarget.Size, TxtTarget.BackgroundColor3, TxtTarget.TextColor3, TxtTarget.Text, TxtTarget.Font, TxtTarget.TextSize = UDim2.new(0.9, 0, 0, 30), Color3.fromRGB(40, 40, 45), Color3.new(1,1,1), " พิมพ์ชื่อคนที่จะเทรดด้วย...", 3, 12
TxtTarget.ClearTextOnFocus = true
TxtTarget.LayoutOrder = 9

local BtnTrade = Instance.new("TextButton", Content)
BtnTrade.Size, BtnTrade.BackgroundColor3, BtnTrade.TextColor3, BtnTrade.Text, BtnTrade.Font, BtnTrade.TextSize = UDim2.new(0.9, 0, 0, 35), Color3.fromRGB(200, 100, 50), Color3.new(1,1,1), "🤝 โยนของทั้งหมดให้คนนี้", 3, 13
BtnTrade.LayoutOrder = 10

BtnTrade.MouseButton1Click:Connect(function()
    local tName = TxtTarget.Text:lower()
    local target = nil
    -- ค้นหาผู้เล่นในห้องจากชื่อที่พิมพ์ (พิมพ์แค่บางส่วนก็ได้)
    for _, p in pairs(P:GetPlayers()) do
        if p ~= P.LocalPlayer and (p.Name:lower():find(tName) or p.DisplayName:lower():find(tName)) then 
            target = p 
            break 
        end
    end
    
    if target then
        BtnTrade.Text = "กำลังเทรดให้: " .. target.Name
        BtnTrade.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
        task.spawn(function()
            pcall(function()
                -- ยืนยันคำขอเทรดด้วย UserId ของเป้าหมาย
                Fire("TradeRespond", target.UserId, true)
                task.wait(0.5)
                Fire("Funnel", "Trading", 1)
                task.wait(1) -- รอให้หน้าต่างเทรดเด้งขึ้นมาก่อน
                
                -- ลิสต์ไอเทมทั้งหมดที่คุณระบุมา
                local items = {"PotionLuck", "PotionCash", "PotionSpeed", "Gems", "Shards", "SuperRolls", "LootBags", "Speed15"}
                
                -- ยิงรหัสเทรดของเข้าเซิร์ฟเวอร์ (ใส่เลข 999999999 เพื่อดูดของหมดกระเป๋า)
                for _, item in ipairs(items) do
                    Fire("TradeItem", item, 999999999)
                    task.wait(0.1) -- หน่วงเวลา 0.1 วิ ต่อชิ้น กันเกมตัดการเชื่อมต่อ
                end
            end)
            task.wait(1)
            BtnTrade.Text, BtnTrade.BackgroundColor3 = "🤝 โยนของทั้งหมดให้คนนี้", Color3.fromRGB(200, 100, 50)
        end)
    else
        BtnTrade.Text, BtnTrade.BackgroundColor3 = "❌ หาชื่อผู้เล่นไม่เจอ!", Color3.fromRGB(200, 50, 50)
        task.wait(1.5)
        BtnTrade.Text, BtnTrade.BackgroundColor3 = "🤝 โยนของทั้งหมดให้คนนี้", Color3.fromRGB(200, 100, 50)
    end
end)

-- ปุ่ม Save
local SaveB = Instance.new("TextButton", Content)
SaveB.Size, SaveB.BackgroundColor3, SaveB.TextColor3, SaveB.Text, SaveB.Font, SaveB.TextSize, SaveB.LayoutOrder = UDim2.new(0.9, 0, 0, 35), Color3.fromRGB(50, 100, 200), Color3.new(1,1,1), "💾 บันทึกการตั้งค่า", 3, 13, 11
SaveB.MouseButton1Click:Connect(function()
    if writefile then pcall(function() writefile(File, HS:JSONEncode(getgenv().CFG)) end) end
    SaveB.Text, SaveB.BackgroundColor3 = "✅ บันทึกสำเร็จ!", Color3.fromRGB(50, 200, 50)
    task.wait(1.5); SaveB.Text, SaveB.BackgroundColor3 = "💾 บันทึกการตั้งค่า", Color3.fromRGB(50, 100, 200)
end)
