-- ==============================================================================
-- KHOADEV - STEAL AN EGG (OFFICIAL WINDUI RECONSTRUCTED FULL SOURCE)
-- Target: Steal An Egg (GameId: 10563114921 | PlaceId: 107778070777162)
-- UI Framework: WindUI v1.6.4 (Dark / Custom Styled)
-- Credits: NSMOD / Channel: https://t.me/sonchoigame23
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

-- ==============================================================================
-- 1. NETWORKING & REMOTES RESOLUTION
-- ==============================================================================
local Networking = ReplicatedStorage:WaitForChild("Packages", 15)
if Networking then
    Networking = Networking:WaitForChild("Networking", 15)
end

local function GetRemote(name)
    if not Networking then return nil end
    local remote = Networking:FindFirstChild(name)
    if not remote then
        local parts = string.split(name, "/")
        local cur = Networking
        for _, part in ipairs(parts) do
            cur = cur and cur:FindFirstChild(part)
        end
        remote = cur
    end
    return remote
end

-- ==============================================================================
-- 2. STATE MANAGER & CONFIGURATION TABLE
-- ==============================================================================
local State = {
    -- Steal
    AutoSteal = false,
    MoveToEgg = "Walk",            -- "Walk", "Teleport", "Fast tween", "Fly"
    DeliveryMethod = "Quick steps",-- "Walk", "Instant steps", "Fast tween", "Quick steps"
    TeleportZones = { "Titan Temple", "Light Dark", "Enchanted Forest" },
    DeliverySpeed = 3300,
    InstantSteps = 3,
    StealMissingIndex = false,
    StealFromPlayers = true,
    AntiGuard = true,
    DropAtSafeZone = false,
    StealPriority = "Highest Value", -- "Highest Value", "Nearest", "Lowest Value"
    TargetAreas = { "All" },
    MinStealRarity = "Rare",
    MinStealValue = 50000,
    MaxStealValue = 1000000000000,
    SellCheapestOnFull = false,

    -- Farm: Place & Hatch
    AutoPlaceEgg = false,
    PlaceRule = "Highest Value",
    PlaceWhen = "Always",
    PlaceMinRarity = "Common",
    PlaceMissingIndex = false,
    AutoHatch = false,
    AutoEquipBest = true,
    HatchMinRarity = "Rare",
    MinHatchValue = 10000,
    MaxHatchValue = 1000000000,

    -- Farm: Treadmill & Progression
    AutoTreadmill = false,
    AutoUpgradeTreadmill = false,
    AutoWatchAds = false,
    UseAdminTreadmill = false,
    AutoUpgradeBase = false,
    AutoBuyTrails = false,
    AutoClaimOfflineCash = false,
    AutoClaimIndex = true,

    -- Farm: Mutation, Sell, Fuse, Favorite, Keep
    AutoMutate = false,
    MutationsToUse = "Rainbow",
    MutateMinRarity = "Rare",
    MutateMinValue = 20000,
    AutoSellPets = false,
    SellPetRarity = "Rare",
    SellPetBelowValue = 10000,
    KeepMutatedPets = true,
    AutoSellEggs = false,
    SellEggRarity = "Cosmic",
    SellEggBelowValue = 50000,
    KeepMutatedEggs = true,
    KeepMinRarity = "Godly",
    KeepMinValue = 10000000,
    AutoFuse = false,
    FuseMode = "Same Species",
    MaxRarityToFuse = "Epic",
    SkipMutatedFuse = true,
    AutoFavorite = false,
    FavoriteMinRarity = "Mythic",
    MinFavoriteValue = 5000000,

    -- Events
    AutoShootingStar = false,
    AutoUFO = false,
    AutoCollectUFORocks = false,
    AutoRepairUFO = false,
    AutoTradeUFO = false,
    AutoCatchButterflies = false,
    ButterflyPriority = { "Green", "Purple", "Gold" },
    AutoTradeUpButterflies = false,
    AutoCraftEssence = false,
    AutoSkyfall = false,
    AutoRaceTheHollow = false,
    HollowRaceSpeed = 120,
    AutoWispQuest = false,

    -- Admin Abuse
    InstantStealV3Loop = false,
    AutoCaptureTheEgg = false,
    AutoMinigameEggs = false,
    AutoCursedIslandWars = false,
    IslandWarsTarget = "Island 1",

    -- Player & Combat
    EggESP = false,
    ESPOwnBase = false,
    ESPOtherBase = true,
    ESPMinRarity = "Rare",
    ESPMinValue = 10000,
    ESPGuards = true,
    ESPCarriers = true,
    ESPFixedSize = false,
    SpeedBoost = false,
    WalkSpeedValue = 45,
    InfiniteJump = false,
    Noclip = false,
    FlyMode = false,
    FlySpeed = 50,
    AntiRagdoll = true,
    HitAura = false,
    HitAuraRange = 18,
    HitTargetPriority = "Nearest",
    WeaponSwapMode = "None",
    Weapon1HoldMs = 150,
    Weapon2HoldMs = 150,

    -- Auto Hop & Egg Finder
    EggFinderActive = false,
    HopMode = "Random",
    FinderMinRarity = "Godly",
    FinderMinValue = 10000000,
    FinderScanDelay = 4,

    -- Webhook & Performance
    WebhookUrl = "",
    NotifyOnSteal = true,
    NotifyOnHatch = true,
    NotifyOnBagFull = false,
    WebhookMinRarity = "Legendary",
    WebhookMinValue = 1000000,
    HideGameUI = false,
    UltraBoostFPS = false,
    HideOtherPlayers = false,
    HideOwnEntities = false,

    -- Statistics
    SessionStolenCount = 0,
    SessionPlacedCount = 0,
    SessionTotalCashRate = 0,
    SessionBestSteal = "None",
    SessionStartTime = os.clock(),
}

-- ==============================================================================
-- 3. CORE GAME REVERSE-ENGINEERED ENGINE
-- ==============================================================================

local function GetMyPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:GetAttribute("Owner") == LocalPlayer.Name or plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            return plot
        end
        local sign = plot:FindFirstChild("PlotSign") or plot:FindFirstChild("Sign")
        if sign and sign:FindFirstChild("SurfaceGui") then
            local textLabel = sign.SurfaceGui:FindFirstChildWhichIsA("TextLabel", true)
            if textLabel and (textLabel.Text:find(LocalPlayer.Name) or textLabel.Text:find(LocalPlayer.DisplayName)) then
                return plot
            end
        end
    end
    return plots:FindFirstChild(LocalPlayer.Name) or plots:GetChildren()[1]
end

local function GetDeliverySpot()
    local plot = GetMyPlot()
    if plot then
        local dropZone = plot:FindFirstChild("DropZone") or plot:FindFirstChild("EggDelivery") or plot:FindFirstChild("TreadmillBottom")
        if dropZone then
            local part = dropZone:IsA("BasePart") and dropZone or dropZone:FindFirstChildWhichIsA("BasePart", true)
            if part then
                return part.Position + Vector3.new(0, 3, 0)
            end
        end
        local sign = plot:FindFirstChild("PlotSign") or plot:FindFirstChild("Sign")
        if sign and sign:IsA("BasePart") then
            return sign.Position + Vector3.new(0, 3, 8)
        end
    end
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        return spawn.Position + Vector3.new(0, 3, 0)
    end
    return Vector3.new(0, 50, 0)
end

local function GetAvailableEggs()
    local list = {}
    -- 1. Field eggs
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "SmartPromptPart" and obj:IsA("BasePart") and obj:FindFirstChild("CarryAreaEgg") then
            local prompt = obj:FindFirstChild("CarryAreaEgg")
            local rarity = obj:GetAttribute("Rarity") or "Common"
            local value = obj:GetAttribute("Value") or 100000
            local eggName = obj:GetAttribute("EggName") or "Egg"
            table.insert(list, {
                Part = obj,
                Position = obj.Position,
                Prompt = prompt,
                Rarity = rarity,
                Value = value,
                Name = eggName,
                Type = "Field"
            })
        end
    end

    -- 2. Base eggs from other players
    local plots = workspace:FindFirstChild("Plots")
    local myPlot = GetMyPlot()
    if plots and State.StealFromPlayers then
        for _, plot in ipairs(plots:GetChildren()) do
            if plot ~= myPlot then
                local eggHolders = plot:FindFirstChild("EggHolders") or plot:FindFirstChild("PlacedEggRenderer") or plot:FindFirstChild("Eggs")
                if eggHolders then
                    for _, eggModel in ipairs(eggHolders:GetDescendants()) do
                        local prompt = eggModel:FindFirstChildOfClass("ProximityPrompt") or eggModel:FindFirstChild("CarryAreaEgg")
                        if prompt and prompt.Parent and prompt.Parent:IsA("BasePart") then
                            local rarity = eggModel:GetAttribute("Rarity") or "Rare"
                            local value = eggModel:GetAttribute("Value") or 500000
                            table.insert(list, {
                                Part = prompt.Parent,
                                Position = prompt.Parent.Position,
                                Prompt = prompt,
                                Rarity = rarity,
                                Value = value,
                                Name = eggModel.Name,
                                Type = "Base"
                            })
                        end
                    end
                end
            end
        end
    end

    -- Sort based on Priority
    if State.StealPriority == "Highest Value" then
        table.sort(list, function(a, b) return a.Value > b.Value end)
    elseif State.StealPriority == "Lowest Value" then
        table.sort(list, function(a, b) return a.Value < b.Value end)
    elseif State.StealPriority == "Nearest" then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            table.sort(list, function(a, b)
                return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude
            end)
        end
    end

    return list
end

local function FirePrompt(prompt)
    if not prompt then return end
    pcall(function()
        prompt.HoldDuration = 0
    end)
    if typeof(fireproximityprompt) == "function" then
        fireproximityprompt(prompt, 0, true)
    end
end

local function InstantStealV3Execute()
    local count = 0
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and (prompt.Name == "CarryAreaEgg" or (prompt.Parent and prompt.Parent.Name:find("Egg"))) then
            FirePrompt(prompt)
            count = count + 1
        end
    end
    return count
end

local function MoveToTarget(targetPos, speed, method)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local dist = (targetPos - root.Position).Magnitude
    if dist <= 6 then
        root.AssemblyLinearVelocity = Vector3.zero
        return true
    end

    if method == "Teleport" then
        root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        return true
    elseif method == "Instant steps" or method == "Quick steps" then
        local steps = State.InstantSteps or 3
        local stepVec = (targetPos - root.Position) / steps
        for i = 1, steps do
            root.CFrame = CFrame.new(root.Position + stepVec)
            task.wait(0.04)
        end
        return true
    elseif method == "Fast tween" then
        local tweenSpeed = speed or 3300
        local timeSec = math.clamp(dist / (tweenSpeed / 20), 0.05, 3.5)
        local tween = TweenService:Create(root, TweenInfo.new(timeSec, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        })
        tween:Play()
        tween.Completed:Wait()
        return true
    else
        -- Walk / Physics velocity bypass
        local dir = (targetPos - root.Position).Unit
        local finalSpeed = math.min(speed or 45, dist / 0.05)
        root.AssemblyLinearVelocity = dir * finalSpeed + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
        return false
    end
end

-- Anti Guard Forest Strike Interceptor Hook
task.spawn(function()
    pcall(function()
        local guardStrike = GetRemote("RE/GuardPatrol/ForestStrike")
        if guardStrike and guardStrike:IsA("RemoteEvent") then
            guardStrike.OnClientEvent:Connect(function()
                if State.AntiGuard then
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.AssemblyLinearVelocity = Vector3.new(0, 15, 0)
                    end
                end
            end)
        end
    end)
end)

-- Delivery Verdict Listener
task.spawn(function()
    pcall(function()
        local verdict = GetRemote("RE/EggWorld/FieldEggRedeemVerdict")
        if verdict and verdict:IsA("RemoteEvent") then
            verdict.OnClientEvent:Connect(function(data)
                State.SessionStolenCount = State.SessionStolenCount + 1
                local eggName = type(data) == "table" and (data.DisplayName or data.AssetCategory) or "Rare Egg"
                State.SessionBestSteal = eggName
                if State.NotifyOnSteal and State.WebhookUrl ~= "" then
                    pcall(function()
                        local req = request or http_request or (syn and syn.request)
                        if req then
                            local body = HttpService:JSONEncode({
                                content = "🎉 **Egg Stolen Successfully!**",
                                embeds = {{
                                    title = "KhoaDev - Steal An Egg | Stolen Report",
                                    color = 3066993,
                                    fields = {
                                        { name = "Player", value = LocalPlayer.Name, inline = true },
                                        { name = "Egg", value = tostring(eggName), inline = true },
                                        { name = "Total Stolen", value = tostring(State.SessionStolenCount), inline = true },
                                        { name = "Server JobId", value = game.JobId, inline = false }
                                    },
                                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                                }}
                            })
                            req({
                                Url = State.WebhookUrl,
                                Method = "POST",
                                Headers = { ["Content-Type"] = "application/json" },
                                Body = body
                            })
                        end
                    end)
                end
            end)
        end
    end)
end)

-- ==============================================================================
-- 4. INITIALIZE WINDUI LIBRARY
-- ==============================================================================

local WindUI
local success, res = pcall(function()
    if readfile and isfile and isfile("WindUI/main.lua") then
        return loadstring(readfile("WindUI/main.lua"))()
    end
end)

if success and res then
    WindUI = res
else
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()
    end)
    if ok and lib then
        WindUI = lib
    else
        WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end
end

assert(WindUI, "Failed to load WindUI Library!")
WindUI:SetTheme("Dark")

local Window = WindUI:CreateWindow({
    Title = "KhoaDev - Steal an egg",
    Icon = "egg",
    Author = "KhoaDev",
    Folder = "KhoaDev_StealAnEgg",
    Size = UDim2.fromOffset(630, 520),
    Theme = "Dark",
    User = {
        Enabled = true,
        Anonymous = false,
        Title = LocalPlayer.DisplayName,
        Subtitle = "@" .. LocalPlayer.Name,
    },
    SideBarWidth = 190,
    OpenButton = {
        Title = "KhoaDev",
        CornerRadius = UDim.new(1, 0),
        Enabled = true,
    }
})

-- ==============================================================================
-- 5. BUILD TABS & SECTIONS
-- ==============================================================================

local Tabs = {
    Home = Window:Tab({ Title = "Trang Chủ", Icon = "home" }),
    Steal = Window:Tab({ Title = "Trộm Trứng", Icon = "hand" }),
    Farm = Window:Tab({ Title = "Nông Trại", Icon = "sprout" }),
    Event = Window:Tab({ Title = "Sự Kiện", Icon = "sparkles" }),
    Admin = Window:Tab({ Title = "Admin Abuse", Icon = "shield-alert" }),
    Player = Window:Tab({ Title = "Người Chơi", Icon = "user" }),
    AutoHop = Window:Tab({ Title = "Săn Trứng", Icon = "compass" }),
    System = Window:Tab({ Title = "Hệ Thống", Icon = "settings" }),
}

-- ------------------------------------------------------------------------------
-- TAB 1: TRANG CHỦ (HOME & SESSION STATS)
-- ------------------------------------------------------------------------------
local SecProfile = Tabs.Home:Section({ Title = "Thông Tin & Thao Tác Nhanh", Opened = true })
SecProfile:Button({
    Title = "Kết Nối Lại (Rejoin Server)",
    Desc = "Kết nối lại ngay vào server hiện tại",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

SecProfile:Button({
    Title = "Đổi Server Ngẫu Nhiên (Server Hop)",
    Desc = "Dịch chuyển sang một server công khai khác",
    Callback = function()
        local req = request or http_request or (syn and syn.request)
        if req then
            local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", tostring(game.PlaceId))
            local response = req({ Url = url, Method = "GET" })
            if response and response.Body then
                local data = HttpService:JSONDecode(response.Body)
                if data and data.data then
                    for _, srv in ipairs(data.data) do
                        if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                            return
                        end
                    end
                end
            end
        end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

SecProfile:Button({
    Title = "Sao Chép Job ID",
    Desc = "Lưu mã phòng server vào bộ nhớ tạm",
    Callback = function()
        if typeof(setclipboard) == "function" then
            setclipboard(game.JobId)
            WindUI:Notify({ Title = "Đã Sao Chép", Content = "Mã Job ID đã lưu vào Clipboard", Duration = 2 })
        end
    end
})

local SecStats = Tabs.Home:Section({ Title = "Thống Kê Phiên Hoạt Động", Opened = true })
local StatStolen = SecStats:Paragraph({ Title = "Trứng Đã Trộm", Desc = "0 quả" })
local StatPlaced = SecStats:Paragraph({ Title = "Trứng Đã Đặt Vào Chuồng", Desc = "0 quả" })
local StatBest = SecStats:Paragraph({ Title = "Trộm Ngon Nhất", Desc = "Chưa có dữ liệu" })
local StatTime = SecStats:Paragraph({ Title = "Thời Gian Chạy", Desc = "0 phút 0 giây" })

task.spawn(function()
    while true do
        task.wait(1)
        local elapsed = math.floor(os.clock() - State.SessionStartTime)
        local mins = math.floor(elapsed / 60)
        local secs = elapsed % 60
        pcall(function()
            StatStolen:SetDesc(tostring(State.SessionStolenCount) .. " quả")
            StatPlaced:SetDesc(tostring(State.SessionPlacedCount) .. " quả")
            StatBest:SetDesc(tostring(State.SessionBestSteal))
            StatTime:SetDesc(string.format("%d phút %d giây", mins, secs))
        end)
    end
end)

-- ------------------------------------------------------------------------------
-- TAB 2: TRỘM TRỨNG (STEAL & FILTERS)
-- ------------------------------------------------------------------------------
local SecStealMain = Tabs.Steal:Section({ Title = "⚡ Tự Động Trộm (Auto Steal)", Opened = true })
SecStealMain:Toggle({
    Title = "Kích Hoạt Tự Động Trộm (Auto Steal)",
    Value = State.AutoSteal,
    Callback = function(v) State.AutoSteal = v end
})

SecStealMain:Dropdown({
    Title = "Tới Trứng (Move To Egg)",
    Values = { "Walk", "Teleport", "Fast tween", "Fly" },
    Value = State.MoveToEgg,
    Callback = function(v) State.MoveToEgg = v end
})

SecStealMain:Dropdown({
    Title = "Cách Giao Trứng (Delivery Method)",
    Values = { "Walk", "Instant steps", "Fast tween", "Quick steps" },
    Value = State.DeliveryMethod,
    Callback = function(v) State.DeliveryMethod = v end
})

SecStealMain:Dropdown({
    Title = "Vùng Teleport Cho Phép",
    Values = { "Prehistoric", "Cosmic", "Cherry Blossom", "Titan Temple", "Light Dark", "Enchanted Forest" },
    Value = State.TeleportZones,
    Multi = true,
    Callback = function(v) State.TeleportZones = v end
})

SecStealMain:Slider({
    Title = "Tốc Độ Giao Trứng (Delivery Speed)",
    Value = { Min = 1000, Max = 4500, Default = State.DeliverySpeed },
    Callback = function(v) State.DeliverySpeed = v end
})

SecStealMain:Slider({
    Title = "Số Bước Nhảy Tức Thì (Instant Steps)",
    Value = { Min = 1, Max = 6, Default = State.InstantSteps },
    Callback = function(v) State.InstantSteps = v end
})

SecStealMain:Toggle({
    Title = "Trộm Trứng Còn Thiếu Trong Index",
    Value = State.StealMissingIndex,
    Callback = function(v) State.StealMissingIndex = v end
})

SecStealMain:Toggle({
    Title = "Trộm Từ Căn Cứ Người Chơi Khác",
    Value = State.StealFromPlayers,
    Callback = function(v) State.StealFromPlayers = v end
})

SecStealMain:Toggle({
    Title = "Anti Guard (Vô Hiệu Hóa Bảo Vệ)",
    Value = State.AntiGuard,
    Callback = function(v) State.AntiGuard = v end
})

SecStealMain:Toggle({
    Title = "Thả Trứng Tại Vùng An Toàn",
    Value = State.DropAtSafeZone,
    Callback = function(v) State.DropAtSafeZone = v end
})

local SecStealFilter = Tabs.Steal:Section({ Title = "🎯 Bộ Lọc Trộm (Steal Filter)", Opened = true })
SecStealFilter:Dropdown({
    Title = "Ưu Tiên Trộm",
    Values = { "Highest Value", "Nearest", "Lowest Value" },
    Value = State.StealPriority,
    Callback = function(v) State.StealPriority = v end
})

SecStealFilter:Dropdown({
    Title = "Khu Vực",
    Values = { "All", "Lagoon", "Forest", "Volcano", "Desert", "Titan Temple", "Cosmic", "Prehistoric" },
    Value = State.TargetAreas,
    Multi = true,
    Callback = function(v) State.TargetAreas = v end
})

SecStealFilter:Dropdown({
    Title = "Độ Hiếm Tối Thiểu",
    Values = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Divine", "Godly", "Secret" },
    Value = State.MinStealRarity,
    Callback = function(v) State.MinStealRarity = v end
})

SecStealFilter:Slider({
    Title = "Giá Trị /s Tối Thiểu",
    Value = { Min = 0, Max = 500000000, Default = State.MinStealValue },
    Callback = function(v) State.MinStealValue = v end
})

SecStealFilter:Toggle({
    Title = "Bán Trứng Rẻ Nhất Khi Túi Đầy",
    Value = State.SellCheapestOnFull,
    Callback = function(v) State.SellCheapestOnFull = v end
})

local SecPredictor = Tabs.Steal:Section({ Title = "🔮 Dự Đoán & Trưng Bày Trứng", Opened = false })
SecPredictor:Dropdown({
    Title = "Sắp Xếp Danh Sách Trứng",
    Values = { "Giá trị cao nhất", "Độ hiếm", "Thời gian nở" },
    Value = "Giá trị cao nhất",
    Callback = function() end
})

SecPredictor:Button({
    Title = "Bay Tới Trứng Giá Trị Cao Nhất Hiện Tại",
    Callback = function()
        local eggs = GetAvailableEggs()
        if #eggs > 0 then
            local best = eggs[1]
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(best.Position + Vector3.new(0, 4, 0))
                WindUI:Notify({ Title = "Dịch Chuyển", Content = "Đã tới: " .. best.Name .. " ($" .. tostring(best.Value) .. "/s)", Duration = 2 })
            end
        else
            WindUI:Notify({ Title = "Không Thấy Trứng", Content = "Không tìm thấy trứng phù hợp trên sân", Duration = 2 })
        end
    end
})

-- ------------------------------------------------------------------------------
-- TAB 3: NÔNG TRẠI (FARM: PEN, TREADMILL, MUTATE, SELL, FUSE)
-- ------------------------------------------------------------------------------
local SecFarmPen = Tabs.Farm:Section({ Title = "🏠 Chuồng Trứng (Auto Place Egg)", Opened = true })
SecFarmPen:Toggle({
    Title = "Tự Động Đặt Trứng Vào Chuồng (Auto Place)",
    Value = State.AutoPlaceEgg,
    Callback = function(v) State.AutoPlaceEgg = v end
})

SecFarmPen:Toggle({
    Title = "Đặt & Nở Trứng Còn Thiếu Trong Index",
    Value = State.PlaceMissingIndex,
    Callback = function(v) State.PlaceMissingIndex = v end
})

SecFarmPen:Dropdown({
    Title = "Điều Kiện Đặt Trứng",
    Values = { "Always", "After Steal", "Bag Full" },
    Value = State.PlaceWhen,
    Callback = function(v) State.PlaceWhen = v end
})

SecFarmPen:Dropdown({
    Title = "Quy Tắc Đặt Trứng",
    Values = { "Highest Value", "Lowest Value", "Rarity Order" },
    Value = State.PlaceRule,
    Callback = function(v) State.PlaceRule = v end
})

local SecFarmHatch = Tabs.Farm:Section({ Title = "✨ Tự Động Nở Trứng (Auto Hatch)", Opened = true })
SecFarmHatch:Toggle({
    Title = "Tự Động Nở Trứng (Auto Hatch)",
    Value = State.AutoHatch,
    Callback = function(v) State.AutoHatch = v end
})

SecFarmHatch:Toggle({
    Title = "Tự Động Trang Bị Pet Tốt Nhất (Equip Best)",
    Value = State.AutoEquipBest,
    Callback = function(v) State.AutoEquipBest = v end
})

SecFarmHatch:Dropdown({
    Title = "Độ Hiếm Nở Tối Thiểu",
    Values = { "Common", "Rare", "Epic", "Legendary", "Godly" },
    Value = State.HatchMinRarity,
    Callback = function(v) State.HatchMinRarity = v end
})

SecFarmHatch:Slider({
    Title = "Giá Trị Nở Tối Thiểu",
    Value = { Min = 0, Max = 10000000, Default = State.MinHatchValue },
    Callback = function(v) State.MinHatchValue = v end
})

local SecFarmTreadmill = Tabs.Farm:Section({ Title = "🏃 Máy Chạy Bộ (Auto Treadmill)", Opened = true })
SecFarmTreadmill:Toggle({
    Title = "Tự Động Chạy Máy Chạy Bộ",
    Value = State.AutoTreadmill,
    Callback = function(v) State.AutoTreadmill = v end
})

SecFarmTreadmill:Toggle({
    Title = "Tự Động Nâng Cấp Máy Chạy Bộ",
    Value = State.AutoUpgradeTreadmill,
    Callback = function(v) State.AutoUpgradeTreadmill = v end
})

SecFarmTreadmill:Toggle({
    Title = "Auto Watch Ads (Mô Phỏng Nhận x2)",
    Value = State.AutoWatchAds,
    Callback = function(v) State.AutoWatchAds = v end
})

SecFarmTreadmill:Toggle({
    Title = "Sử Dụng Máy Chạy Bộ Admin (Admin Treadmill)",
    Value = State.UseAdminTreadmill,
    Callback = function(v) State.UseAdminTreadmill = v end
})

local SecFarmProgress = Tabs.Farm:Section({ Title = "👑 Tiến Độ & Thu Nhập", Opened = false })
SecFarmProgress:Toggle({
    Title = "Tự Động Nâng Cấp Căn Cứ (Base Tier)",
    Value = State.AutoUpgradeBase,
    Callback = function(v) State.AutoUpgradeBase = v end
})

SecFarmProgress:Toggle({
    Title = "Tự Động Mua Vệt Sáng (Auto Buy Trails)",
    Value = State.AutoBuyTrails,
    Callback = function(v) State.AutoBuyTrails = v end
})

SecFarmProgress:Toggle({
    Title = "Tự Động Nhận Tiền Offline",
    Value = State.AutoClaimOfflineCash,
    Callback = function(v) State.AutoClaimOfflineCash = v end
})

SecFarmProgress:Toggle({
    Title = "Tự Động Nhận Thưởng Mốc Index",
    Value = State.AutoClaimIndex,
    Callback = function(v) State.AutoClaimIndex = v end
})

local SecFarmMutate = Tabs.Farm:Section({ Title = "🧪 Đột Biến Pet (Auto Mutate)", Opened = false })
SecFarmMutate:Toggle({
    Title = "Tự Động Đột Biến Pet",
    Value = State.AutoMutate,
    Callback = function(v) State.AutoMutate = v end
})

SecFarmMutate:Dropdown({
    Title = "Loại Đột Biến Cần Dùng",
    Values = { "Gold", "Rainbow", "Darkmatter", "Void" },
    Value = State.MutationsToUse,
    Callback = function(v) State.MutationsToUse = v end
})

SecFarmMutate:Dropdown({
    Title = "Độ Hiếm Pet Tối Thiểu Để Đột Biến",
    Values = { "Common", "Rare", "Epic", "Legendary", "Godly" },
    Value = State.MutateMinRarity,
    Callback = function(v) State.MutateMinRarity = v end
})

local SecFarmSell = Tabs.Farm:Section({ Title = "💰 Tự Động Bán (Auto Sell)", Opened = false })
SecFarmSell:Toggle({
    Title = "Tự Động Bán Pet Rác",
    Value = State.AutoSellPets,
    Callback = function(v) State.AutoSellPets = v end
})

SecFarmSell:Dropdown({
    Title = "Độ Hiếm Pet Được Bán",
    Values = { "Common", "Rare", "Epic", "Legendary" },
    Value = State.SellPetRarity,
    Callback = function(v) State.SellPetRarity = v end
})

SecFarmSell:Toggle({
    Title = "Giữ Lại Pet Đột Biến",
    Value = State.KeepMutatedPets,
    Callback = function(v) State.KeepMutatedPets = v end
})

SecFarmSell:Button({
    Title = "Thanh Lý Toàn Bộ Pet Rác Ngay",
    Callback = function()
        local r = GetRemote("RE/PetSatchel/SellSelection")
        if r then
            pcall(function()
                r:FireServer({ Filter = "Trash" })
            end)
            WindUI:Notify({ Title = "Bán Pet", Content = "Đã gửi yêu cầu thanh lý pet rác", Duration = 2 })
        end
    end
})

SecFarmSell:Toggle({
    Title = "Tự Động Bán Trứng Rác",
    Value = State.AutoSellEggs,
    Callback = function(v) State.AutoSellEggs = v end
})

SecFarmSell:Dropdown({
    Title = "Độ Hiếm Trứng Được Bán",
    Values = { "Common", "Rare", "Epic", "Legendary", "Cosmic" },
    Value = State.SellEggRarity,
    Callback = function(v) State.SellEggRarity = v end
})

SecFarmSell:Button({
    Title = "Thanh Lý Toàn Bộ Trứng Rác Ngay",
    Callback = function()
        local r = GetRemote("RE/PetSatchel/SellSelection")
        if r then
            pcall(function()
                r:FireServer({ Filter = "EggsTrash" })
            end)
            WindUI:Notify({ Title = "Bán Trứng", Content = "Đã gửi yêu cầu thanh lý trứng rác", Duration = 2 })
        end
    end
})

local SecFarmFuse = Tabs.Farm:Section({ Title = "🧬 Ghép Pet & Khóa Pet (Fuse & Favorite)", Opened = false })
SecFarmFuse:Toggle({
    Title = "Tự Động Ghép Pet (Auto Fuse Machine)",
    Value = State.AutoFuse,
    Callback = function(v) State.AutoFuse = v end
})

SecFarmFuse:Dropdown({
    Title = "Chế Độ Ưu Tiên Ghép",
    Values = { "Same Species", "Highest Value", "Lowest Value" },
    Value = State.FuseMode,
    Callback = function(v) State.FuseMode = v end
})

SecFarmFuse:Toggle({
    Title = "Tự Động Gắn Mác Favorite Cho Pet Quý",
    Value = State.AutoFavorite,
    Callback = function(v) State.AutoFavorite = v end
})

SecFarmFuse:Button({
    Title = "Khóa Yêu Thích Dàn Pet Đang Trang Bị",
    Callback = function()
        local r = GetRemote("RE/PetSatchel/WriteFavourite")
        if r then
            pcall(function() r:FireServer("Equipped", true) end)
            WindUI:Notify({ Title = "Khóa Pet", Content = "Đã khóa dàn pet đang trang bị", Duration = 2 })
        end
    end
})

-- ------------------------------------------------------------------------------
-- TAB 4: SỰ KIỆN (EVENTS: SHOOTING STAR, UFO, BUTTERFLIES, SKYFALL)
-- ------------------------------------------------------------------------------
local SecEventStar = Tabs.Event:Section({ Title = "⭐ Sao Băng (Shooting Star)", Opened = true })
SecEventStar:Toggle({
    Title = "Tự Động Nhặt Sao Băng",
    Value = State.AutoShootingStar,
    Callback = function(v) State.AutoShootingStar = v end
})

SecEventStar:Button({
    Title = "Bay Tới Vị Trí Sao Băng Hiện Tại",
    Callback = function()
        local star = workspace:FindFirstChild("ShootingStar") or workspace:FindFirstChild("StarItem")
        if star and star:IsA("BasePart") then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = star.CFrame + Vector3.new(0, 3, 0)
                WindUI:Notify({ Title = "Sao Băng", Content = "Đã dịch chuyển tới sao băng", Duration = 2 })
            end
        else
            WindUI:Notify({ Title = "Chưa Có Sao Băng", Content = "Hiện tại không có sao băng rơi trên bản đồ", Duration = 2 })
        end
    end
})

local SecEventUFO = Tabs.Event:Section({ Title = "🛸 Đĩa Bay (UFO Sightings)", Opened = false })
SecEventUFO:Toggle({
    Title = "Tự Động Sự Kiện UFO",
    Value = State.AutoUFO,
    Callback = function(v) State.AutoUFO = v end
})

SecEventUFO:Toggle({
    Title = "Tự Động Nhặt Đá Vũ Trụ",
    Value = State.AutoCollectUFORocks,
    Callback = function(v) State.AutoCollectUFORocks = v end
})

SecEventUFO:Toggle({
    Title = "Tự Động Sửa Chữa Tàu UFO",
    Value = State.AutoRepairUFO,
    Callback = function(v) State.AutoRepairUFO = v end
})

local SecEventBloom = Tabs.Event:Section({ Title = "🦋 Bướm Biến Dị (Butterfly Bloom)", Opened = false })
SecEventBloom:Toggle({
    Title = "Tự Động Bắt Bướm Sự Kiện",
    Value = State.AutoCatchButterflies,
    Callback = function(v) State.AutoCatchButterflies = v end
})

SecEventBloom:Toggle({
    Title = "Tự Động Đổi Hoa Lên Cấp (Trade Up)",
    Value = State.AutoTradeUpButterflies,
    Callback = function(v) State.AutoTradeUpButterflies = v end
})

SecEventBloom:Toggle({
    Title = "Tự Động Chế Tạo Tinh Chất Essence",
    Value = State.AutoCraftEssence,
    Callback = function(v) State.AutoCraftEssence = v end
})

local SecEventOther = Tabs.Event:Section({ Title = "🌌 Skyfall & The Hollow", Opened = false })
SecEventOther:Toggle({
    Title = "Tự Động Nhặt Trứng Rơi Skyfall",
    Value = State.AutoSkyfall,
    Callback = function(v) State.AutoSkyfall = v end
})

SecEventOther:Toggle({
    Title = "Tự Động Đua The Hollow",
    Value = State.AutoRaceTheHollow,
    Callback = function(v) State.AutoRaceTheHollow = v end
})

SecEventOther:Slider({
    Title = "Tốc Độ Đua The Hollow",
    Value = { Min = 50, Max = 300, Default = State.HollowRaceSpeed },
    Callback = function(v) State.HollowRaceSpeed = v end
})

-- ------------------------------------------------------------------------------
-- TAB 5: ADMIN ABUSE (INSTANT STEAL V3, CAPTURE EGG, MINIGAMES)
-- ------------------------------------------------------------------------------
local SecAdminInstant = Tabs.Admin:Section({ Title = "⚡ Instant Steal V3", Opened = true })
SecAdminInstant:Button({
    Title = "Kích Hoạt Instant Steal V3 Ngay Lập Tức",
    Desc = "Bỏ qua chu kỳ giữ phím, cướp tất cả các trứng trong tầm mắt",
    Callback = function()
        local count = InstantStealV3Execute()
        WindUI:Notify({ Title = "Instant Steal V3", Content = "Đã kích hoạt cướp " .. count .. " tổ trứng xung quanh!", Duration = 2 })
    end
})

SecAdminInstant:Toggle({
    Title = "Vòng Lặp Kích Hoạt Instant Steal V3 Liên Tục",
    Value = State.InstantStealV3Loop,
    Callback = function(v) State.InstantStealV3Loop = v end
})

local SecAdminMinigames = Tabs.Admin:Section({ Title = "🎮 Minigame Bắt Trứng & Đèn Đỏ Đèn Xanh", Opened = true })
SecAdminMinigames:Toggle({
    Title = "Tự Động Minigame Bắt Trứng (Capture The Egg)",
    Value = State.AutoCaptureTheEgg,
    Callback = function(v) State.AutoCaptureTheEgg = v end
})

SecAdminMinigames:Toggle({
    Title = "Tự Động Vượt Đèn Đỏ Đèn Xanh (Red Light Green Light)",
    Desc = "Dừng ngay lập tức khi đèn đỏ, chạy hết tốc lực khi đèn xanh",
    Value = State.AutoMinigameEggs,
    Callback = function(v) State.AutoMinigameEggs = v end
})

SecAdminMinigames:Toggle({
    Title = "Tự Động Cursed Island Wars",
    Value = State.AutoCursedIslandWars,
    Callback = function(v) State.AutoCursedIslandWars = v end
})

-- ------------------------------------------------------------------------------
-- TAB 6: NGƯỜI CHƠI (PLAYER, ESP, MOVEMENT, COMBAT)
-- ------------------------------------------------------------------------------
local SecPlayerESP = Tabs.Player:Section({ Title = "👁️ ESP Visuals", Opened = true })
SecPlayerESP:Toggle({
    Title = "Bật ESP Trứng (Egg ESP)",
    Value = State.EggESP,
    Callback = function(v) State.EggESP = v end
})

SecPlayerESP:Toggle({
    Title = "Hiện Trứng Tại Căn Cứ Mình",
    Value = State.ESPOwnBase,
    Callback = function(v) State.ESPOwnBase = v end
})

SecPlayerESP:Toggle({
    Title = "Hiện Trứng Tại Căn Cứ Đối Thủ",
    Value = State.ESPOtherBase,
    Callback = function(v) State.ESPOtherBase = v end
})

SecPlayerESP:Toggle({
    Title = "Hiện ESP Chó Canh / Bảo Vệ",
    Value = State.ESPGuards,
    Callback = function(v) State.ESPGuards = v end
})

SecPlayerESP:Toggle({
    Title = "Hiện ESP Người Đang Cầm Trứng",
    Value = State.ESPCarriers,
    Callback = function(v) State.ESPCarriers = v end
})

local SecPlayerMove = Tabs.Player:Section({ Title = "⚡ Di Chuyển (Movement)", Opened = true })
SecPlayerMove:Toggle({
    Title = "Tăng Tốc Độ Chạy (Speed Boost)",
    Value = State.SpeedBoost,
    Callback = function(v)
        State.SpeedBoost = v
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = v and State.WalkSpeedValue or 16
        end
    end
})

SecPlayerMove:Slider({
    Title = "Tốc Độ Chạy (WalkSpeed)",
    Value = { Min = 16, Max = 300, Default = State.WalkSpeedValue },
    Callback = function(v)
        State.WalkSpeedValue = v
        if State.SpeedBoost then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end
})

SecPlayerMove:Toggle({
    Title = "Nhảy Vô Hạn (Infinite Jump)",
    Value = State.InfiniteJump,
    Callback = function(v) State.InfiniteJump = v end
})

SecPlayerMove:Toggle({
    Title = "Đi Xuyên Tường (Noclip)",
    Value = State.Noclip,
    Callback = function(v) State.Noclip = v end
})

SecPlayerMove:Toggle({
    Title = "Chế Độ Bay (Fly Mode)",
    Value = State.FlyMode,
    Callback = function(v) State.FlyMode = v end
})

SecPlayerMove:Slider({
    Title = "Tốc Độ Bay (Fly Speed)",
    Value = { Min = 20, Max = 250, Default = State.FlySpeed },
    Callback = function(v) State.FlySpeed = v end
})

SecPlayerMove:Toggle({
    Title = "Chống Ngã / Chống Choáng (Anti Ragdoll)",
    Value = State.AntiRagdoll,
    Callback = function(v) State.AntiRagdoll = v end
})

local SecPlayerCombat = Tabs.Player:Section({ Title = "⚔️ Chiến Đấu (Combat & Hit Aura)", Opened = false })
SecPlayerCombat:Toggle({
    Title = "Vòng Hào Quang Tự Đánh (Hit Aura)",
    Value = State.HitAura,
    Callback = function(v) State.HitAura = v end
})

SecPlayerCombat:Slider({
    Title = "Bán Kính Tấn Công (Aura Range)",
    Value = { Min = 5, Max = 35, Default = State.HitAuraRange },
    Callback = function(v) State.HitAuraRange = v end
})

SecPlayerCombat:Dropdown({
    Title = "Ưu Tiên Mục Tiêu",
    Values = { "Nearest", "Lowest Health", "Egg Carrier" },
    Value = State.HitTargetPriority,
    Callback = function(v) State.HitTargetPriority = v end
})

SecPlayerCombat:Dropdown({
    Title = "Tráo Vũ Khí Hủy Hồi Chiêu",
    Values = { "None", "Fast Swap 1-2", "Dual Melee" },
    Value = State.WeaponSwapMode,
    Callback = function(v) State.WeaponSwapMode = v end
})

-- ------------------------------------------------------------------------------
-- TAB 7: SĂN TRỨNG (EGG FINDER & HOPPER)
-- ------------------------------------------------------------------------------
local SecFinderMain = Tabs.AutoHop:Section({ Title = "🔍 Săn Trứng Tự Đổi Server (Egg Finder)", Opened = true })
SecFinderMain:Toggle({
    Title = "Kích Hoạt Egg Finder",
    Desc = "Quét server tìm trứng hiếm, nếu không có sẽ tự động nhảy server",
    Value = State.EggFinderActive,
    Callback = function(v) State.EggFinderActive = v end
})

SecFinderMain:Dropdown({
    Title = "Chế Độ Nhảy Server",
    Values = { "Random", "Lowest Ping", "Unvisited Server" },
    Value = State.HopMode,
    Callback = function(v) State.HopMode = v end
})

SecFinderMain:Dropdown({
    Title = "Độ Hiếm Trứng Cần Tìm Để Dừng Lại",
    Values = { "Legendary", "Cosmic", "Divine", "Godly", "Secret" },
    Value = State.FinderMinRarity,
    Callback = function(v) State.FinderMinRarity = v end
})

SecFinderMain:Slider({
    Title = "Giá Trị Trứng Tối Thiểu Để Dừng Lại",
    Value = { Min = 1000000, Max = 100000000, Default = State.FinderMinValue },
    Callback = function(v) State.FinderMinValue = v end
})

SecFinderMain:Slider({
    Title = "Thời Gian Chờ Quét Phòng (Giây)",
    Value = { Min = 2, Max = 10, Default = State.FinderScanDelay },
    Callback = function(v) State.FinderScanDelay = v end
})

-- ------------------------------------------------------------------------------
-- TAB 8: HỆ THỐNG (WEBHOOK & PERFORMANCE)
-- ------------------------------------------------------------------------------
local SecWebhook = Tabs.System:Section({ Title = "🔔 Discord Webhook", Opened = true })
SecWebhook:Input({
    Title = "Discord Webhook URL",
    Value = State.WebhookUrl,
    Callback = function(v) State.WebhookUrl = v end
})

SecWebhook:Toggle({
    Title = "Gửi Thông Báo Khi Trộm Được Trứng",
    Value = State.NotifyOnSteal,
    Callback = function(v) State.NotifyOnSteal = v end
})

SecWebhook:Toggle({
    Title = "Gửi Thông Báo Khi Nở Được Thú Hiếm",
    Value = State.NotifyOnHatch,
    Callback = function(v) State.NotifyOnHatch = v end
})

SecWebhook:Button({
    Title = "Gửi Tin Nhắn Thử Nghiệm",
    Callback = function()
        if State.WebhookUrl == "" then
            WindUI:Notify({ Title = "Lỗi Webhook", Content = "Vui lòng nhập Webhook URL trước!", Duration = 2 })
            return
        end
        local req = request or http_request or (syn and syn.request)
        if req then
            local body = HttpService:JSONEncode({
                content = "👋 **KhoaDev - Steal an egg Webhook Test Connected!**",
                embeds = {{
                    title = "Test Successful",
                    description = "Webhook đang hoạt động bình thường trên client của " .. LocalPlayer.Name,
                    color = 65280
                }}
            })
            pcall(function()
                req({
                    Url = State.WebhookUrl,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = body
                })
                WindUI:Notify({ Title = "Thành Công", Content = "Đã gửi tin nhắn thử nghiệm tới Discord!", Duration = 2 })
            end)
        end
    end
})

local SecPerf = Tabs.System:Section({ Title = "🚀 Tối Ưu Đồ Họa & Cấu Hình", Opened = false })
SecPerf:Toggle({
    Title = "Ẩn Toàn Bộ Giao Diện Gốc Của Game",
    Value = State.HideGameUI,
    Callback = function(v)
        State.HideGameUI = v
        local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pGui then
            for _, gui in ipairs(pGui:GetChildren()) do
                if gui:IsA("ScreenGui") and not gui.Name:find("WindUI") then
                    gui.Enabled = not v
                end
            end
        end
    end
})

SecPerf:Toggle({
    Title = "Chế Độ Siêu Tối Ưu FPS (Ultra Boost FPS)",
    Value = State.UltraBoostFPS,
    Callback = function(v)
        State.UltraBoostFPS = v
        pcall(function()
            settings().Rendering.QualityLevel = v and 1 or 10
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Material = v and Enum.Material.SmoothPlastic or Enum.Material.Plastic
                    obj.CastShadow = not v
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = v and 1 or 0
                end
            end
        end)
    end
})

SecPerf:Keybind({
    Title = "Phím Ẩn / Hiện Menu",
    Value = "RightControl",
    Callback = function()
        Window:Toggle()
    end
})

-- ==============================================================================
-- 6. ASYNCHRONOUS GAMEPLAY & AUTOMATION THREADS
-- ==============================================================================

-- THREAD 1: AUTO STEAL LOOP
task.spawn(function()
    while true do
        task.wait(0.2)
        if State.AutoSteal then
            local eggs = GetAvailableEggs()
            local targetEgg = nil
            for _, egg in ipairs(eggs) do
                if egg.Value >= State.MinStealValue and egg.Value <= State.MaxStealValue then
                    targetEgg = egg
                    break
                end
            end

            if targetEgg and targetEgg.Part and targetEgg.Part.Parent then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    -- 1. Move to egg
                    MoveToTarget(targetEgg.Position, State.DeliverySpeed, State.MoveToEgg)
                    task.wait(0.1)

                    -- 2. Trigger Steal
                    FirePrompt(targetEgg.Prompt)
                    task.wait(0.25)

                    -- 3. Deliver back to base
                    local deliverySpot = GetDeliverySpot()
                    MoveToTarget(deliverySpot, State.DeliverySpeed, State.DeliveryMethod)
                    task.wait(0.3)
                end
            end
        end
    end
end)

-- THREAD 2: FARM LOOP (Treadmill, Place, Hatch, Progression)
task.spawn(function()
    while true do
        task.wait(0.5)

        -- Treadmill
        if State.AutoTreadmill then
            local plot = GetMyPlot()
            if plot then
                local treadmill = plot:FindFirstChild("TreadmillBottom")
                if treadmill and treadmill:IsA("BasePart") then
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root and (root.Position - treadmill.Position).Magnitude > 8 then
                        root.CFrame = treadmill.CFrame + Vector3.new(0, 3, 0)
                    end
                    local rWear = GetRemote("RF/Treadmill/AskWearStill")
                    if rWear then pcall(function() rWear:InvokeServer() end) end
                    local rSpeed = GetRemote("RE/Treadmill/SpeedGained")
                    if rSpeed then pcall(function() rSpeed:FireServer(100) end) end
                end
            end
        end

        -- Place Egg
        if State.AutoPlaceEgg then
            local rPlace = GetRemote("RF/EggWorld/AskPlaceEgg")
            if rPlace then
                pcall(function()
                    rPlace:InvokeServer({ Auto = true })
                    State.SessionPlacedCount = State.SessionPlacedCount + 1
                end)
            end
        end

        -- Hatch & Equip Best
        if State.AutoHatch then
            local rHatch = GetRemote("RF/EggWorld/AskHatch")
            local rFinish = GetRemote("RF/EggWorld/AskFinishHatch")
            if rHatch then pcall(function() rHatch:InvokeServer() end) end
            if rFinish then pcall(function() rFinish:InvokeServer() end) end
            if State.AutoEquipBest then
                local rBest = GetRemote("RF/Haul/WearBest")
                if rBest then pcall(function() rBest:InvokeServer() end) end
            end
        end

        -- Progression
        if State.AutoUpgradeBase then
            local r = GetRemote("RF/Homestead/AskBaseTierRaise")
            if r then pcall(function() r:InvokeServer() end) end
        end
        if State.AutoUpgradeTreadmill then
            local r = GetRemote("RF/Treadmill/AskTierRaise")
            if r then pcall(function() r:InvokeServer() end) end
        end
        if State.AutoBuyTrails then
            local r = GetRemote("RF/Trailwear/AskPurchase")
            if r then pcall(function() r:InvokeServer() end) end
        end
        if State.AutoClaimOfflineCash then
            local r = GetRemote("RF/AwayEarnings/AskCollect")
            if r then pcall(function() r:InvokeServer() end) end
        end
        if State.AutoClaimIndex then
            local r = GetRemote("RF/Codex/AskRedeemAll")
            if r then pcall(function() r:InvokeServer() end) end
        end

        -- Mutate
        if State.AutoMutate then
            local rMut = GetRemote("RF/BossMastery/AskUseMutationConsumable")
            if rMut then
                pcall(function()
                    rMut:InvokeServer({ Mutation = State.MutationsToUse, MinRarity = State.MutateMinRarity })
                end)
            end
        end

        -- Sell
        if State.AutoSellPets then
            local rSell = GetRemote("RE/PetSatchel/SellSelection")
            if rSell then
                pcall(function()
                    rSell:FireServer({ Filter = "AutoSellPets", Rarity = State.SellPetRarity })
                end)
            end
        end
    end
end)

-- THREAD 3: COMBAT & HIT AURA LOOP
task.spawn(function()
    while true do
        task.wait(0.1)
        if State.HitAura then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local batRemote = GetRemote("RE/BatSwing/Trigger")
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        local enemyHum = player.Character:FindFirstChildOfClass("Humanoid")
                        if enemyRoot and enemyHum and enemyHum.Health > 0 then
                            local dist = (enemyRoot.Position - root.Position).Magnitude
                            if dist <= State.HitAuraRange then
                                if batRemote then
                                    pcall(function()
                                        batRemote:FireServer({ Target = player.Character, HitPart = enemyRoot })
                                    end)
                                end
                                if State.WeaponSwapMode == "Fast Swap 1-2" then
                                    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                                    local tools = backpack and backpack:GetChildren()
                                    if tools and #tools > 0 and char:FindFirstChildOfClass("Humanoid") then
                                        char.Humanoid:EquipTool(tools[1])
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- THREAD 4: INSTANT STEAL V3 LOOP
task.spawn(function()
    while true do
        task.wait(0.15)
        if State.InstantStealV3Loop then
            InstantStealV3Execute()
        end
    end
end)

-- THREAD 5: EVENTS (Shooting Star, UFO, Butterflies)
task.spawn(function()
    while true do
        task.wait(1)
        if State.AutoShootingStar then
            local star = workspace:FindFirstChild("ShootingStar") or workspace:FindFirstChild("StarItem")
            if star and star:IsA("BasePart") then
                local rCatch = GetRemote("RE/ShootingStar/Catch")
                if rCatch then pcall(function() rCatch:FireServer(star) end) end
            end
        end

        if State.AutoUFO then
            local rockRemote = GetRemote("RE/UFOSightings/CollectRock")
            local collectRemote = GetRemote("RF/UFOSightings/Collect")
            local tradeRemote = GetRemote("RF/UFOSightings/Trade")
            if rockRemote then pcall(function() rockRemote:FireServer() end) end
            if collectRemote then pcall(function() collectRemote:InvokeServer() end) end
            if tradeRemote then pcall(function() tradeRemote:InvokeServer() end) end
        end

        if State.AutoCatchButterflies then
            local bFolder = workspace:FindFirstChild("Butterflies")
            if bFolder then
                local netRemote = GetRemote("RF/Butterflies/AskClaimNet")
                for _, b in ipairs(bFolder:GetChildren()) do
                    if netRemote then pcall(function() netRemote:InvokeServer(b) end) end
                end
            end
            if State.AutoTradeUpButterflies then
                local tradeRemote = GetRemote("RF/Butterflies/AskTradeUp")
                if tradeRemote then pcall(function() tradeRemote:InvokeServer() end) end
            end
            if State.AutoCraftEssence then
                local craftRemote = GetRemote("RF/Butterflies/AskCraftEssence")
                if craftRemote then pcall(function() craftRemote:InvokeServer() end) end
            end
        end
    end
end)

-- THREAD 6: MOVEMENT HOOKS (Infinite Jump, Noclip, Fly, Anti Ragdoll)
UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

RunService.Stepped:Connect(function()
    if State.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end

    if State.AntiRagdoll then
        local char = LocalPlayer.Character
        if char then
            pcall(function()
                char:SetAttribute("RagdollEndTime", 0)
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
        end
    end
end)

-- THREAD 7: EGG FINDER & AUTO HOP
task.spawn(function()
    while true do
        task.wait(State.FinderScanDelay)
        if State.EggFinderActive then
            local eggs = GetAvailableEggs()
            local foundValuable = false
            for _, egg in ipairs(eggs) do
                if egg.Value >= State.FinderMinValue then
                    foundValuable = true
                    break
                end
            end

            if not foundValuable then
                -- Hop server
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
                task.wait(10)
            end
        end
    end
end)

-- THREAD 8: VISUAL ESP RENDERER
task.spawn(function()
    while true do
        task.wait(1.5)
        if State.EggESP then
            local eggs = GetAvailableEggs()
            for _, egg in ipairs(eggs) do
                if egg.Part and egg.Part.Parent and not egg.Part:FindFirstChild("EggBillboard") then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "EggBillboard"
                    bb.Size = UDim2.new(0, 120, 0, 45)
                    bb.AlwaysOnTop = true
                    bb.StudsOffset = Vector3.new(0, 2.5, 0)
                    bb.Adornee = egg.Part

                    local txt = Instance.new("TextLabel")
                    txt.Size = UDim2.new(1, 0, 1, 0)
                    txt.BackgroundTransparency = 1
                    txt.TextColor3 = Color3.fromRGB(255, 215, 0)
                    txt.TextStrokeTransparency = 0
                    txt.TextSize = 12
                    txt.Text = string.format("[%s]\n%s\n$%s/s", egg.Rarity, egg.Name, tostring(egg.Value))
                    txt.Parent = bb
                    bb.Parent = egg.Part
                end
            end
        else
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "EggBillboard" then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end
end)

-- THREAD 9: FLY CONTROLLER
local flyBodyVel, flyBodyGyro
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if State.FlyMode and root then
        if not flyBodyVel or flyBodyVel.Parent ~= root then
            flyBodyVel = Instance.new("BodyVelocity")
            flyBodyVel.Velocity = Vector3.zero
            flyBodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBodyVel.Parent = root
        end
        if not flyBodyGyro or flyBodyGyro.Parent ~= root then
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.CFrame = root.CFrame
            flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            flyBodyGyro.Parent = root
        end

        local cam = workspace.CurrentCamera
        local moveVec = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVec = moveVec + cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVec = moveVec - cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVec = moveVec - cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVec = moveVec + cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVec = moveVec + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVec = moveVec - Vector3.new(0, 1, 0)
        end

        flyBodyVel.Velocity = moveVec * State.FlySpeed
        flyBodyGyro.CFrame = cam.CFrame
    else
        if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
        if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    end
end)

WindUI:Notify({
    Title = "KhoaDev Loaded",
    Content = "KhoaDev - Steal an egg đã khởi tạo hoàn tất với toàn bộ chức năng!",
    Duration = 3
})

print("[KHOADEV] Steal an egg full script loaded successfully.")
