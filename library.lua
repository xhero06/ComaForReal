loadstring(game:HttpGet('https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua'))()
v = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local OriginalLighting = {Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,FogEnd=Lighting.FogEnd,FogStart=Lighting.FogStart}

local Player = Players.LocalPlayer


if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    Player:Kick("Sorry, this is not mobile supported.")
    return
end

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera
v.OriginalFOV = Camera.FieldOfView
v.originalPosition = nil
v.SavedTeleportCFrame = nil

local States = {
    Flying = false, NoClipping = false, Spinning = false,
    Swimming = false, VehicleFlying = false, ESPEnabled = false,
    TargetPlayer = nil, OriginalCFrame = nil,
    StickyAimEnabled = false, StickyAimTarget = nil, StickyAimStareAt = false,
    SilentAimEnabled = false, SilentAimTarget = nil
}

v.ESPObjects = {}
v.StickyAimHighlight = nil

v.SilentAimFOV = nil
v.SilentCurrentPing = 0
v.SilentPrediction = 0.17
v.SilentLastPingUpdate = 0

getgenv().SilentAim = {
    Enabled = false,
    AutoPrediction = true,
    ManualPrediction = 0.17,
    InAirPrediction = true,
    InAirPredValue = 0.03,
    TargetPart = "HumanoidRootPart",
    WallCheck = true,
    FOVRadius = 200,
    FOVVisible = true,
    HitChance = 100,
    TeamCheck = false,
    AliveCheck = false,
    VisibleCheck = false,
    StareAt = false
}


local repo = 'https://raw.githubusercontent.com/liminalin/LinoriaIsGay/refs/heads/main/'
local chosenUI = 'linoria'

local _libSrc = game:HttpGet('https://raw.githubusercontent.com/liminalin/LinoriaIsGay/refs/heads/main/Library.lua')
local _libFn, _libErr = loadstring(_libSrc)
if not _libFn then error('failed to load library: ' .. tostring(_libErr)) end
local Library = _libFn()



local CAS = game:GetService('ContextActionService')
local _inactiveBound = false

local function sinkAll(_, _, _) return Enum.ContextActionResult.Sink end

local function lockInputs()
    if _inactiveBound then return end
    _inactiveBound = true
    CAS:BindActionAtPriority('__inactiveMode', sinkAll, false,
        Enum.ContextActionPriority.High.Value,

        Enum.UserInputType.Keyboard,

        Enum.UserInputType.MouseButton1,
        Enum.UserInputType.MouseButton2,
        Enum.UserInputType.MouseButton3,
        Enum.UserInputType.MouseMovement,
        Enum.UserInputType.MouseWheel,

        Enum.UserInputType.Gamepad1
    )

    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

    local char = Player.Character
    if char then
        local hum = char:FindFirstChildOfClass('Humanoid')
        if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end
    end
end

local function unlockInputs()
    if not _inactiveBound then return end
    _inactiveBound = false
    CAS:UnbindAction('__inactiveMode')
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    local char = Player.Character
    if char then
        local hum = char:FindFirstChildOfClass('Humanoid')
        if hum then
            hum.WalkSpeed = Options.speedinput and Options.speedinput.Value or 16
            hum.JumpPower = 50
        end
    end
end




local _execVisible = false
do
    local _execGui = nil
    local _execBox = nil
    local _blockedFuncs = {}

    local function buildExecGui()
        if _execGui and _execGui.Parent then return end
        local sg = Instance.new('ScreenGui')
        sg.Name = 'MonarchExec'; sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        pcall(function() sg.IgnoreGuiInset = true end)
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(sg) end end)
        pcall(function() sg.Parent = gethui and gethui() or game:GetService('CoreGui') end)
        if not sg.Parent then sg.Parent = Players.LocalPlayer:WaitForChild('PlayerGui') end
        _execGui = sg

        local vp = workspace.CurrentCamera.ViewportSize
        local W, H = 620, 400
        local Outer = Instance.new('Frame')
        Outer.Size = UDim2.fromOffset(W, H)
        Outer.Position = UDim2.fromOffset(math.floor((vp.X-W)/2), math.floor((vp.Y-H)/2))
        Outer.BackgroundColor3 = Library.MainColor or Color3.fromRGB(30,30,30)
        Outer.BorderColor3 = Library.AccentColor or Color3.fromRGB(54,93,171)
        Outer.BorderSizePixel = 1; Outer.ZIndex = 200; Outer.Parent = sg

        local TitleBar = Instance.new('Frame')
        TitleBar.Size = UDim2.new(1,0,0,26)
        TitleBar.BackgroundColor3 = Library.AccentColor or Color3.fromRGB(54,93,171)
        TitleBar.BorderSizePixel = 0; TitleBar.ZIndex = 201; TitleBar.Parent = Outer
        TitleBar.Active = true


        local _dragging, _dragStart, _startPos = false, nil, nil
        TitleBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                _dragging = true
                _dragStart = inp.Position
                _startPos = Outer.Position
            end
        end)
        TitleBar.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                _dragging = false
            end
        end)
        game:GetService('UserInputService').InputChanged:Connect(function(inp)
            if _dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local d = inp.Position - _dragStart
                Outer.Position = UDim2.fromOffset(_startPos.X.Offset + d.X, _startPos.Y.Offset + d.Y)
            end
        end)

        local TitleLabel = Instance.new('TextLabel')
        TitleLabel.Size = UDim2.new(1,-34,1,0); TitleLabel.Position = UDim2.fromOffset(8,0)
        TitleLabel.BackgroundTransparency = 1; TitleLabel.Text = 'cosmical execution'
        TitleLabel.TextColor3 = Color3.new(1,1,1); TitleLabel.Font = Enum.Font.Code
        TitleLabel.TextSize = 14; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.ZIndex = 202; TitleLabel.Parent = TitleBar

        local CloseBtn = Instance.new('TextButton')
        CloseBtn.Size = UDim2.fromOffset(26,26); CloseBtn.Position = UDim2.new(1,-26,0,0)
        CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = 'x'
        CloseBtn.TextColor3 = Color3.new(1,1,1); CloseBtn.Font = Enum.Font.Code
        CloseBtn.TextSize = 14; CloseBtn.ZIndex = 202; CloseBtn.Parent = TitleBar
        CloseBtn.MouseButton1Click:Connect(function() Library:ToggleInternalExec() end)

        local BoxFrame = Instance.new('Frame')
        BoxFrame.Size = UDim2.new(1,-16,1,-80); BoxFrame.Position = UDim2.fromOffset(8,34)
        BoxFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
        BoxFrame.BorderColor3 = Library.OutlineColor or Color3.fromRGB(60,60,60)
        BoxFrame.BorderSizePixel = 1; BoxFrame.ZIndex = 201; BoxFrame.Parent = Outer

        local Box = Instance.new('TextBox')
        Box.Size = UDim2.new(1,-8,1,-8); Box.Position = UDim2.fromOffset(4,4)
        Box.BackgroundTransparency = 1; Box.Text = ''
        Box.PlaceholderText = '-- write your code here'
        Box.TextColor3 = Color3.new(1,1,1)
        Box.PlaceholderColor3 = Color3.fromRGB(120,120,120)
        Box.Font = Enum.Font.Code; Box.TextSize = 14
        Box.TextXAlignment = Enum.TextXAlignment.Left
        Box.TextYAlignment = Enum.TextYAlignment.Top
        Box.MultiLine = true; Box.ClearTextOnFocus = false
        Box.ZIndex = 202; Box.Parent = BoxFrame
        _execBox = Box

        local BtnY = H - 38
        local function makeBtn(text, x, w)
            local b = Instance.new('TextButton')
            b.Size = UDim2.fromOffset(w,26); b.Position = UDim2.fromOffset(x, BtnY)
            b.BackgroundColor3 = Library.AccentColor or Color3.fromRGB(54,93,171)
            b.BorderSizePixel = 0; b.Text = text
            b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.Code
            b.TextSize = 13; b.ZIndex = 201; b.Parent = Outer
            return b
        end

        local ExecBtn = makeBtn('execute', 8, 80)
        local ClearBtn = makeBtn('clear', 96, 60)

        local RiskyValues = {'setfflag','replicatesignal','getscriptclosure','writefile'}
        local RiskySelected = {}
        local RiskyBtn = makeBtn('risky: none', 164, 160)
        local RiskyOpen = false
        local RiskyMenu = nil

        local function updateRiskyLabel()
            local n = 0; for _ in pairs(RiskySelected) do n+=1 end
            RiskyBtn.Text = n==0 and 'risky: none' or ('risky: '..n..' blocked')
            _blockedFuncs = RiskySelected
        end

        RiskyBtn.MouseButton1Click:Connect(function()
            RiskyOpen = not RiskyOpen
            if RiskyMenu then RiskyMenu:Destroy(); RiskyMenu = nil end
            if not RiskyOpen then return end
            RiskyMenu = Instance.new('Frame')
            RiskyMenu.Size = UDim2.fromOffset(160, #RiskyValues*22+4)
            RiskyMenu.Position = UDim2.fromOffset(164, BtnY-(#RiskyValues*22+4))
            RiskyMenu.BackgroundColor3 = Library.MainColor or Color3.fromRGB(30,30,30)
            RiskyMenu.BorderColor3 = Library.AccentColor or Color3.fromRGB(54,93,171)
            RiskyMenu.BorderSizePixel = 1; RiskyMenu.ZIndex = 210; RiskyMenu.Parent = Outer
            for i,name in ipairs(RiskyValues) do
                local row = Instance.new('TextButton')
                row.Size = UDim2.new(1,0,0,22); row.Position = UDim2.fromOffset(0,(i-1)*22+2)
                row.BackgroundTransparency = 1
                row.Text = (RiskySelected[name] and '[x] ' or '[ ] ')..name
                row.TextColor3 = Color3.new(1,1,1); row.Font = Enum.Font.Code
                row.TextSize = 13; row.TextXAlignment = Enum.TextXAlignment.Left
                row.ZIndex = 211; row.Parent = RiskyMenu
                row.MouseButton1Click:Connect(function()
                    RiskySelected[name] = not RiskySelected[name] or nil
                    updateRiskyLabel()
                    row.Text = (RiskySelected[name] and '[x] ' or '[ ] ')..name
                end)
            end
        end)

        ExecBtn.MouseButton1Click:Connect(function()
            local code = Box.Text or ''
            if code == '' then return end
            for fname in pairs(_blockedFuncs) do
                if code:find(fname) then
                    Library:Notify('blocked: '..fname..' is in risky list', 4); return
                end
            end
            local fn, err = loadstring(code)
            if fn then
                local ok, runErr = pcall(fn)
                if not ok then Library:Notify('error: '..tostring(runErr), 4) end
            else
                Library:Notify('syntax: '..tostring(err), 4)
            end
        end)

        ClearBtn.MouseButton1Click:Connect(function()
            Box.Text = ''
            if RiskyMenu then RiskyMenu:Destroy(); RiskyMenu = nil end
            RiskyOpen = false
        end)

        Outer.Visible = false
    end

    function Library:ToggleInternalExec()
        if not (_execGui and _execGui.Parent) then buildExecGui() end
        _execVisible = not _execVisible
        local outer = _execGui and _execGui:FindFirstChildWhichIsA('Frame')
        if outer then outer.Visible = _execVisible end

        if Toggles.inactivemode and Toggles.inactivemode.Value then
            if _execVisible then
                lockInputs()
            else
                unlockInputs()
            end
        end
    end

    task.defer(buildExecGui)
end

local fallbackRepo = 'https://raw.githubusercontent.com/underscoreReal/LinoriaLib/main/'
local function safeLoad(path)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(repo .. path))()
    end)
    if ok and result then return result end
    return loadstring(game:HttpGet(fallbackRepo .. path))()
end
local ThemeManager = safeLoad('addons/ThemeManager.lua')
local SaveManager = safeLoad('addons/SaveManager.lua')

local Toggles = Library.Toggles or getgenv().Toggles or {}
local Options = Library.Options or getgenv().Options or {}
getgenv().Toggles = Toggles
getgenv().Options = Options

local windowConfig = {
    Title = 'Cosmical Universal',
    Version = 'Freemium',
    VersionColor = Color3.fromRGB(255, 255, 255),
    Center = true,
    AutoShow = true,
    TabPadding = 4,
    MenuFadeTime = 0,
    ColoredTitle = true,
    ColoredVersion = true,
}
local Window = Library:CreateWindow(windowConfig)

local Tabs = {
    Info = Window:AddTab("info"),
    Main = Window:AddTab("main"),
    Visuals = Window:AddTab("visuals"),
    World = Window:AddTab("world"),
    Exploits = Window:AddTab("exploits"),
    Players = Window:AddTab("players"),
    Aimbot = Window:AddTab("legit"),
    Misc = Window:AddTab("misc"),
    ['UI Settings'] = Window:AddTab("ui settings")
}


local InfoChangelog = Tabs.Info:AddLeftLabelGroup("script - changelogs")
InfoChangelog:AddColoredLabel("new emotes", Color3.fromRGB(0, 255, 128))
InfoChangelog:AddColoredLabel("disable chat icon", Color3.fromRGB(0, 255, 128))
InfoChangelog:AddColoredLabel("view model offsets", Color3.fromRGB(0, 255, 128))
InfoChangelog:AddColoredLabel("added prompt reach", Color3.fromRGB(0, 255, 128))
InfoChangelog:AddColoredLabel("added execution", Color3.fromRGB(0, 255, 128))
InfoChangelog:AddColoredLabel("added wind aura", Color3.fromRGB(0, 255, 128))
InfoChangelog:AddColoredLabel("new tab world (exported things from visuals)", Color3.fromRGB(0, 255, 128))
InfoChangelog:AddColoredLabel("anti fling", Color3.fromRGB(0, 255, 128))
InfoChangelog:AddColoredLabel("anti void", Color3.fromRGB(0, 255, 128))
InfoChangelog:AddColoredLabel("removed reset button for animation packs", Color3.fromRGB(0, 255, 128))
InfoChangelog:AddColoredLabel("added exploits tab (a bit from misc)", Color3.fromRGB(0, 255, 128))

local InfoNotes = Tabs.Info:AddRightLabelGroup("notes")
InfoNotes:AddColoredLabel("aimbot tab is outdated", Color3.fromRGB(255, 180, 0))
InfoNotes:AddColoredLabel("flying is buggy (only normal mode)", Color3.fromRGB(255, 180, 0))
InfoNotes:AddColoredLabel("use smooth or cframe flying instead", Color3.fromRGB(255, 180, 0))


v.ExploitsLeft = Tabs.Exploits:AddLeftGroupbox("exploits")
v.ExploitsRight = Tabs.Exploits:AddRightGroupbox("server")

v.ExploitsLeft:AddButton({
    Text = "open dex explorer",
    Func = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
    end
})

v.orbitConnection = nil
v.orbitAngle = 0
v.bangOriginalPosition = nil
v.bangConnection = nil

v.Main = Tabs.Main:AddLeftGroupbox("speed")
v.MainOther = Tabs.Main:AddLeftGroupbox("flying")
v.MainMovement = Tabs.Main:AddLeftGroupbox("movement")
v.MainDesync = Tabs.Main:AddLeftGroupbox("desyncing")
v.Right = Tabs.Main:AddRightGroupbox("tools")
v.MainHealth = Tabs.Main:AddRightGroupbox("health")
v.Tright = Tabs.Main:AddRightGroupbox("velocity breaking")
v.Mright = Tabs.Main:AddRightGroupbox("ragdoller")
v.Bright = Tabs.Main:AddRightGroupbox("lag")
v.FlingGroup = Tabs.Main:AddLeftGroupbox("fling")
v.TeleportMain = Tabs.Main:AddLeftGroupbox("teleports")
v.TeleportStuff = Tabs.Main:AddRightGroupbox("teleport stuff")
v.VisualsLeft = Tabs.Visuals:AddLeftGroupbox("esp")
v.VisualsTeamESP = Tabs.Visuals:AddLeftGroupbox("team esp")
v.VisualsEnemyESP = Tabs.Visuals:AddLeftGroupbox("enemy esp")
v.VisualsUp = Tabs.Visuals:AddLeftGroupbox("esp setup")
v.VisualsDown = Tabs.Visuals:AddLeftGroupbox("crosshair")
v.VisualsRight = Tabs.World:AddRightGroupbox("world")
v.VisualsPlayer = Tabs.Visuals:AddRightGroupbox("player")
v.VisualsMiddle = Tabs.World:AddLeftGroupbox("color correction")
v.VisualsThere = Tabs.Visuals:AddRightGroupbox("anims break")
v.VisualsHere = Tabs.World:AddLeftGroupbox("skybox changer")
v.PlayersBox = Tabs.Players:AddLeftGroupbox("player selection")
v.PlayersKeybind = Tabs.Players:AddLeftGroupbox("targeting")
v.PlayersInfo = Tabs.Players:AddLeftGroupbox("player info")
v.PlayersActions = Tabs.Players:AddLeftGroupbox("actions")
v.PlayersOrbit = Tabs.Players:AddLeftGroupbox("orbit")
v.PlayersHitbox = Tabs.Players:AddLeftGroupbox("hitbox expander")
v.PlayersVisuals = Tabs.Players:AddRightGroupbox("visuals")
v.PlayersAimbot = Tabs.Players:AddRightGroupbox("aimbot")
v.PlayersTriggerbot = Tabs.Players:AddRightGroupbox("triggerbot")
v.PlayersTp = Tabs.Players:AddRightGroupbox("loop teleport")
v.PlayersButtons = Tabs.Players:AddRightGroupbox("user info")
v.SilentAimBox = Tabs.Aimbot:AddLeftGroupbox("silent")
v.TargetLock = Tabs.Aimbot:AddLeftGroupbox("camlock")
v.TargetWl = Tabs.Aimbot:AddLeftGroupbox("whitelisting camlock")
v.TargetFov = Tabs.Aimbot:AddLeftGroupbox("fov")
v.AimbotLeft = Tabs.Aimbot:AddLeftGroupbox("sticky aim")

v.TargetUni = Tabs.Aimbot:AddRightGroupbox("esp")
v.TargetActions = Tabs.Aimbot:AddRightGroupbox("orbitting")
v.Trigger = Tabs.Aimbot:AddRightGroupbox("triggerbotting")
v.MiscCharacter = Tabs.Misc:AddLeftGroupbox("character")
v.MiscAnimations = Tabs.Misc:AddLeftGroupbox("animations")
v.AnimPackGroup = Tabs.Misc:AddLeftGroupbox("animation pack")
v.MiscUniversal = Tabs.Misc:AddLeftGroupbox("universal")
v.MiscChatSpam = Tabs.Misc:AddLeftGroupbox("chat spam")
v.MiscTitleBox = Tabs.Misc:AddLeftGroupbox("custom title")
v.EmoteMain = Tabs.Misc:AddRightGroupbox("emotes")
v.MiscServer = Tabs.Misc:AddRightGroupbox("server")
v.ViewOffsetGroup = Tabs.Misc:AddRightGroupbox("view offset")
v.MiscExploits = Tabs.Misc:AddRightGroupbox("exploits")
v.MiscServerActions = Tabs.Misc:AddRightGroupbox("server actions")
v.MiscScripts = Tabs.Misc:AddLeftGroupbox("scripts")
v.CmdSets = Tabs.Misc:AddLeftGroupbox("command sets")
v.ChatCmds = Tabs.Misc:AddRightGroupbox("chat commands")


v.AvatarLeft = Tabs.Visuals:AddLeftGroupbox("accessories")
v.AvatarRight = Tabs.Visuals:AddRightGroupbox("avatar character")
v.RainGroup = Tabs.World:AddRightGroupbox("world effects")


local function GetCharacter() return Player.Character end

local function GetHumanoid()
    local c = GetCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
    local c = GetCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function FindPlayerByName(name)
    local n = name:lower()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():find(n) or p.DisplayName:lower():find(n) then return p end
    end
end

local function GetNearestPlayer(mode)
    local best, closest = nil, math.huge
    local myRoot = GetRootPart()

    if not myRoot then return nil end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local targetRoot = plr.Character.HumanoidRootPart
            local distance

            if mode == "nearest you" then
                distance = (myRoot.Position - targetRoot.Position).Magnitude
            else
                local sp, onScreen = Camera:WorldToViewportPoint(targetRoot.Position)
                local mp = UserInputService:GetMouseLocation()
                distance = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
            end

            if distance < closest then closest = distance best = plr end
        end
    end

    return best
end

local function GetAllPlayerNames()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player then t[#t+1] = p.Name end
    end
    return t
end

local function UpdateStickyAimHighlight()
    if v.StickyAimHighlight then
        v.StickyAimHighlight:Destroy()
        v.StickyAimHighlight = nil
    end

    if States.StickyAimEnabled and States.StickyAimTarget and States.StickyAimTarget.Character then
        v.StickyAimHighlight = Instance.new("Highlight")
        v.StickyAimHighlight.Parent = States.StickyAimTarget.Character
        v.StickyAimHighlight.FillColor = Options.stickycolor.Value
        v.StickyAimHighlight.OutlineColor = Options.stickycolor.Value
        v.StickyAimHighlight.FillTransparency = 0.3
        v.StickyAimHighlight.OutlineTransparency = 0
        v.StickyAimHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
end


v.AimbotLeft:AddToggle("stickytoggle", {
    Text = "sticky aim",
    Default = false,
    Tooltip = "sticky aim"
})

Toggles.stickytoggle:AddKeyPicker("stickykey", {
    Text = "sticky aim",
    Default = "NONE",
    SyncToggleState = false
})

v.AimbotLeft:AddToggle("allowuntarget", {
    Text = "allow untarget",
    Default = true,
    Tooltip = "on = press key again to unstick | off = press key again to switch to nearest player"
})

Toggles.stickytoggle:AddColorPicker("stickycolor", {
    Default = Color3.new(1, 1, 1),
    Title = "sticky aim highlight",
    Callback = function(Value)
        if v.StickyAimHighlight then
            v.StickyAimHighlight.FillColor = Value
            v.StickyAimHighlight.OutlineColor = Value
        end
    end
})

v.AimbotLeft:AddDropdown("stickymode", {
    Text = "detection mode",
    Default = 1,
    Values = {"nearest mouse", "nearest you"},
    AllowNull = false
})

v.AimbotLeft:AddToggle("stickytracertoggle", {
    Text = "tracer",
    Default = false,
    Tooltip = "line from your mouse to the sticky aim target"
})

Toggles.stickytracertoggle:AddColorPicker("stickytracercolor", {
    Default = Color3.new(1, 1, 1),
    Title = "sticky aim tracer color"
})

v.StickyAimTracerLine = nil

RunService.RenderStepped:Connect(function()
    if Toggles.stickytracertoggle.Value and States.StickyAimEnabled and States.StickyAimTarget and States.StickyAimTarget.Character then
        local targetPart = States.StickyAimTarget.Character:FindFirstChild("Head") or States.StickyAimTarget.Character:FindFirstChild("HumanoidRootPart")
        if targetPart then
            if not v.StickyAimTracerLine then
                v.StickyAimTracerLine = Drawing.new("Line")
                v.StickyAimTracerLine.Thickness = 2
                v.StickyAimTracerLine.Transparency = 1
                v.StickyAimTracerLine.Visible = true
            end
            v.StickyAimTracerLine.Color = Options.stickytracercolor.Value
            local mousePos = UserInputService:GetMouseLocation()
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                v.StickyAimTracerLine.From = Vector2.new(mousePos.X, mousePos.Y)
                v.StickyAimTracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                v.StickyAimTracerLine.Visible = true
            else
                v.StickyAimTracerLine.Visible = false
            end
        end
    else
        if v.StickyAimTracerLine then
            v.StickyAimTracerLine.Visible = false
            v.StickyAimTracerLine:Remove()
            v.StickyAimTracerLine = nil
        end
    end
end)

v.targetCharAddedConn = nil

local function EnableStickyAim()
    local detectionMode = Options.stickymode.Value
    States.StickyAimTarget = GetNearestPlayer(detectionMode)
    States.StickyAimEnabled = true
    UpdateStickyAimHighlight()
    if States.StickyAimTarget then
        Library:Notify("sticked to " .. States.StickyAimTarget.Name)
        if v.targetCharAddedConn then v.targetCharAddedConn:Disconnect() end
        v.targetCharAddedConn = States.StickyAimTarget.CharacterAdded:Connect(function()
            task.wait(0.1)
            UpdateStickyAimHighlight()
        end)
    else
        Library:Notify("no target found!")
    end
end

local function DisableStickyAim()
    States.StickyAimEnabled = false
    States.StickyAimTarget = nil
    if v.StickyAimHighlight then v.StickyAimHighlight:Destroy() v.StickyAimHighlight = nil end
    if v.targetCharAddedConn then v.targetCharAddedConn:Disconnect() v.targetCharAddedConn = nil end
    if v.StickyAimTracerLine then v.StickyAimTracerLine.Visible = false v.StickyAimTracerLine:Remove() v.StickyAimTracerLine = nil end
end


Options.stickykey:OnChanged(function()
    if not Options.stickykey.Value then return end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local stickyKeyCode = Options.stickykey and Options.stickykey.Value
    if not stickyKeyCode or stickyKeyCode == "NONE" then return end
    local keyEnum = Enum.KeyCode[stickyKeyCode] or (Enum.UserInputType[stickyKeyCode])
    if input.KeyCode ~= keyEnum and input.UserInputType ~= keyEnum then return end

    if States.StickyAimEnabled then
        if Toggles.allowuntarget and Toggles.allowuntarget.Value then

            Toggles.stickytoggle:SetValue(false)
            DisableStickyAim()
        else

            EnableStickyAim()
        end
    else
        Toggles.stickytoggle:SetValue(true)
        EnableStickyAim()
    end
end)

Toggles.stickytoggle:OnChanged(function(value)
    if not value then
        DisableStickyAim()
    end
end)

local function GetSilentPing()
    local stats = game:GetService("Stats")
    if stats and stats.Network and stats.Network.ServerStatsItem then
        return stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end
    return 100
end

local function SilentWallCheck(destination, ignore)
    if not getgenv().SilentAim.WallCheck then return true end
    local Origin = Camera.CFrame.p
    local CheckRay = Ray.new(Origin, destination - Origin)
    local Hit = workspace:FindPartOnRayWithIgnoreList(CheckRay, ignore)
    return Hit == nil
end

local function IsInAir(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local state = hum:GetState()
    return state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping
end

local function GetClosestPartToPlayer(character)
    if not character then return nil end
    local myRoot = GetRootPart()
    if not myRoot then return nil end

    local parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
    local closestPart = nil
    local closestDistance = math.huge

    for _, partName in pairs(parts) do
        local part = character:FindFirstChild(partName)
        if part then
            local distance = (myRoot.Position - part.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestPart = part
            end
        end
    end

    return closestPart
end

local function GetSilentTarget()
    if not States.SilentAimEnabled then return nil end

    if States.StickyAimEnabled and States.StickyAimTarget then
        return States.StickyAimTarget
    end

    local Target, Closest = nil, math.huge
    local Inset = game:GetService("GuiService"):GetGuiInset().Y
    local Mouse = Player:GetMouse()

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local char = plr.Character
            local hrp = char.HumanoidRootPart
            local hum = char:FindFirstChildOfClass("Humanoid")

            local passedChecks = true

            if getgenv().SilentAim.TeamCheck then
                if plr.Team and Player.Team and plr.Team == Player.Team then
                    passedChecks = false
                end
            end

            if getgenv().SilentAim.AliveCheck then
                if not hum or hum.Health <= 0 then
                    passedChecks = false
                end
            end

            if getgenv().SilentAim.VisibleCheck then
                local ray = Ray.new(Camera.CFrame.Position, (hrp.Position - Camera.CFrame.Position).Unit * (hrp.Position - Camera.CFrame.Position).Magnitude)
                local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {Player.Character, char})
                if hit then
                    passedChecks = false
                end
            end

            if passedChecks then
                local Position, OnScreen = Camera:WorldToScreenPoint(hrp.Position)
                local Distance = (Vector2.new(Position.X, Position.Y) - Vector2.new(Mouse.X, Mouse.Y + Inset)).Magnitude

                if getgenv().SilentAim.FOVRadius > Distance and Distance < Closest and OnScreen and SilentWallCheck(hrp.Position, {Player.Character, char}) then
                    Closest = Distance
                    Target = plr
                end
            end
        end
    end

    return Target
end

v.SilentAimFOV = Drawing.new("Circle")
v.SilentAimFOV.Transparency = 0.5
v.SilentAimFOV.Thickness = 2
v.SilentAimFOV.Color = Color3.fromRGB(255, 255, 255)
v.SilentAimFOV.Filled = false
v.SilentAimFOV.Visible = false


v.SilentAimFOVOutline = Drawing.new("Circle")
v.SilentAimFOVOutline.Transparency = 1
v.SilentAimFOVOutline.Thickness = 2
v.SilentAimFOVOutline.Color = Color3.fromRGB(255, 255, 255)
v.SilentAimFOVOutline.Filled = false
v.SilentAimFOVOutline.Visible = false


v.SilentAimFOVLines = {}
for i = 1, 10 do
    local l = Drawing.new("Line")
    l.Visible = false
    l.Thickness = 2
    l.Color = Color3.fromRGB(255, 255, 255)
    v.SilentAimFOVLines[i] = l
end

v.SilentFOVCurrentPos = Vector2.new(0, 0)
v.SilentFOVCurrentRadius = 0
v.SilentFOVShape = "circle"

local function GetPolygonPoints(cx, cy, r, sides)
    local pts = {}
    for i = 0, sides - 1 do
        local a = math.rad((360 / sides) * i - 90)
        pts[i + 1] = Vector2.new(cx + math.cos(a) * r, cy + math.sin(a) * r)
    end
    return pts
end

local function HideAllFOVShapes()
    v.SilentAimFOV.Visible = false
    v.SilentAimFOVOutline.Visible = false
    for _, l in ipairs(v.SilentAimFOVLines) do l.Visible = false end
end

local function DrawFOVShape(pos, radius, shape, color, filled, fillColor)
    HideAllFOVShapes()
    if shape == "circle" then
        v.SilentAimFOV.Position = pos
        v.SilentAimFOV.Radius = radius
        v.SilentAimFOV.Filled = filled
        v.SilentAimFOV.Color = filled and (fillColor or color) or color
        v.SilentAimFOV.Transparency = filled and 0.7 or 1
        v.SilentAimFOV.Visible = true

        v.SilentAimFOVOutline.Position = pos
        v.SilentAimFOVOutline.Radius = radius
        v.SilentAimFOVOutline.Color = color
        v.SilentAimFOVOutline.Filled = false
        v.SilentAimFOVOutline.Transparency = 1
        v.SilentAimFOVOutline.Visible = true
    else
        local sides = shape == "pentagon" and 5 or shape == "star" and 10 or shape == "heart" and 8 or 4
        local pts
        if shape == "star" then
            pts = {}
            for i = 0, 9 do
                local a = math.rad(36 * i - 90)
                local r2 = i % 2 == 0 and radius or radius * 0.45
                pts[i + 1] = Vector2.new(pos.X + math.cos(a) * r2, pos.Y + math.sin(a) * r2)
            end
        else
            pts = GetPolygonPoints(pos.X, pos.Y, radius, sides)
        end
        for i = 1, #pts do
            local next = pts[(i % #pts) + 1]
            v.SilentAimFOVLines[i].From = pts[i]
            v.SilentAimFOVLines[i].To = next
            v.SilentAimFOVLines[i].Color = color
            v.SilentAimFOVLines[i].Visible = true
        end
    end
end

v.SilentAimHighlight = nil
v.silentHighlightEnabled = false
v.silentHighlightColor = Color3.fromRGB(255, 255, 255)

RunService.RenderStepped:Connect(function()
    if States.SilentAimEnabled and getgenv().SilentAim.FOVVisible then
        local targetPos
        if Toggles.silentfovfollowmouse and Toggles.silentfovfollowmouse.Value then
            local Mouse = Player:GetMouse()
            local Inset = game:GetService("GuiService"):GetGuiInset().Y
            targetPos = Vector2.new(Mouse.X, Mouse.Y + Inset)
        else
            local vp = Camera.ViewportSize
            targetPos = Vector2.new(vp.X / 2, vp.Y / 2)
        end
        local targetRadius = getgenv().SilentAim.FOVRadius

        local lerpSpeed = Options.silentfovlerp and Options.silentfovlerp.Value or 1
        v.SilentFOVCurrentPos = v.SilentFOVCurrentPos:Lerp(targetPos, lerpSpeed)
        v.SilentFOVCurrentRadius = v.SilentFOVCurrentRadius + (targetRadius - v.SilentFOVCurrentRadius) * lerpSpeed

        local fovColor = Options.silentfovcolor and Options.silentfovcolor.Value or Color3.new(1,1,1)
        local filled = Toggles.silentfovfill and Toggles.silentfovfill.Value and v.SilentFOVShape == "circle"
        local fillColor = Options.silentfovfillcolor and Options.silentfovfillcolor.Value or Color3.new(1,1,1)
        DrawFOVShape(v.SilentFOVCurrentPos, v.SilentFOVCurrentRadius, v.SilentFOVShape, fovColor, filled, fillColor)
    else
        HideAllFOVShapes()
    end

    if v.silentHighlightEnabled and States.SilentAimEnabled then
        local target = GetSilentTarget()
        if target and target.Character then
            if v.SilentAimHighlight and v.SilentAimHighlight.Parent ~= target.Character then
                v.SilentAimHighlight:Destroy()
                v.SilentAimHighlight = nil
            end

            if not v.SilentAimHighlight then
                v.SilentAimHighlight = Instance.new("Highlight")
                v.SilentAimHighlight.Parent = target.Character
                v.SilentAimHighlight.FillColor = v.silentHighlightColor
                v.SilentAimHighlight.OutlineColor = v.silentHighlightColor
                v.SilentAimHighlight.FillTransparency = 0.5
                v.SilentAimHighlight.OutlineTransparency = 0
                v.SilentAimHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            else
                v.SilentAimHighlight.FillColor = v.silentHighlightColor
                v.SilentAimHighlight.OutlineColor = v.silentHighlightColor
            end
        else
            if v.SilentAimHighlight then
                v.SilentAimHighlight:Destroy()
                v.SilentAimHighlight = nil
            end
        end
    else
        if v.SilentAimHighlight then
            v.SilentAimHighlight:Destroy()
            v.SilentAimHighlight = nil
        end
    end

    if tick() - v.SilentLastPingUpdate >= 0.5 then
        v.SilentCurrentPing = GetSilentPing()
        v.SilentLastPingUpdate = tick()
    end

    local target = GetSilentTarget()
    States.SilentAimTarget = target

    if target and target.Character then
        local part
        if getgenv().SilentAim.TargetPart == "Closest Part" then
            part = GetClosestPartToPlayer(target.Character)
        else
            part = target.Character:FindFirstChild(getgenv().SilentAim.TargetPart)
        end
        if part then
            local pred = getgenv().SilentAim.ManualPrediction

            if getgenv().SilentAim.AutoPrediction then
                pred = v.SilentCurrentPing / 1000
                if getgenv().SilentAim.InAirPrediction and IsInAir(target.Character) then
                    pred = getgenv().SilentAim.InAirPredValue
                end
            end

            v.SilentPrediction = math.clamp(pred, 0.001, 1.0)
        end
    end

    if getgenv().SilentAim.StareAt then
        local targetToLookAt = nil

        if States.StickyAimEnabled and States.StickyAimTarget and States.StickyAimTarget.Character then
            targetToLookAt = States.StickyAimTarget
        elseif States.SilentAimEnabled and States.SilentAimTarget and States.SilentAimTarget.Character then
            targetToLookAt = States.SilentAimTarget
        end

        if targetToLookAt then
            local targetPart = targetToLookAt.Character:FindFirstChild("HumanoidRootPart")
            local myChar = GetCharacter()
            local myRoot = GetRootPart()
            local myHum = GetHumanoid()

            if targetPart and myChar and myRoot and myHum then
                myHum.AutoRotate = false
                local targetPosition = targetPart.Position
                local myPosition = myRoot.Position
                local lookVector = (targetPosition - myPosition).Unit
                local newCFrame = CFrame.new(myPosition, myPosition + Vector3.new(lookVector.X, 0, lookVector.Z))
                myRoot.CFrame = newCFrame
            end
        end
    else
        local myHum = GetHumanoid()
        if myHum then
            myHum.AutoRotate = true
        end
    end
end)

v.OldIndex = hookmetamethod(game, "__index", function(self, key)
    if not getgenv().SilentAim then return v.OldIndex(self, key) end

    if self:IsA("Mouse") and key == "Hit" and States.SilentAimEnabled then
        local hitChance = getgenv().SilentAim.HitChance or 100
        local randomChance = math.random(0, 100)

        if randomChance <= hitChance then
            local target = States.SilentAimTarget or GetSilentTarget()
            if target and target.Character then
                local part
                if getgenv().SilentAim.TargetPart == "Closest Part" then
                    part = GetClosestPartToPlayer(target.Character)
                else
                    part = target.Character:FindFirstChild(getgenv().SilentAim.TargetPart)
                end
                if part then
                    return part.CFrame + (part.Velocity * v.SilentPrediction)
                end
            end
        end
    end

    return v.OldIndex(self, key)
end)

v.SilentAimBox:AddToggle("silentaimtoggle", {
    Text = "silent aim",
    Default = false,
    Tooltip = "automatically aims at closest target in FOV"
})

Toggles.silentaimtoggle:AddKeyPicker("silentaimkey", {
    Text = "silent aim",
    Default = "NONE",
    SyncToggleState = true
})

Toggles.silentaimtoggle:OnChanged(function(value)
    States.SilentAimEnabled = value
    getgenv().SilentAim.Enabled = value
end)

Toggles.silentaimtoggle:AddColorPicker("silentfovcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "fov circle color",
    Callback = function(value)
        if v.SilentAimFOV then
            v.SilentAimFOV.Color = value
        end
    end
})

v.SilentAimBox:AddToggle("silentfovtoggle", {
    Text = "show fov circle",
    Default = true,
    Callback = function(value)
        getgenv().SilentAim.FOVVisible = value
    end
})

v.SilentAimBox:AddToggle("silentfovfollowmouse", {
    Text = "follow mouse",
    Default = true,
    Tooltip = "fov follows your mouse, off = stays centered on screen"
})

v.SilentAimBox:AddToggle("silentstare", {
    Text = "stare at target",
    Default = false,
    Tooltip = "ur character stares at the targetted person",
    Callback = function(value)
        getgenv().SilentAim.StareAt = value
        States.StickyAimStareAt = value
    end
})

v.SilentAimBox:AddToggle("crosshairontarget", {
    Text = "crosshair on target",
    Default = false,
    Tooltip = "crosshair goes on silent/sticky aim target's head"
})

v.SilentAimBox:AddSlider("silentfovsize", {
    Text = "fov size",
    Default = 200,
    Min = 10,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        getgenv().SilentAim.FOVRadius = value
    end
})

v.SilentAimBox:AddSlider("silentfovlerp", {
    Text = "fov lerp",
    Default = 1,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Tooltip = "fov lerp"
})

v.SilentAimBox:AddToggle("silentfovfill", {
    Text = "fov fill",
    Default = false,
    Tooltip = "fills the fov (circle only)"
}):AddColorPicker("silentfovfillcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "fov fill color"
})

Toggles.silentfovfill:OnChanged(function()

end)

Options.silentfovfillcolor:OnChanged(function()

end)

v.SilentAimBox:AddDropdown("silentfovshape", {
    Text = "fov shape",
    Values = {"circle", "pentagon", "star"},
    Default = 1,
    Multi = false,
    Callback = function(value)
        v.SilentFOVShape = value
    end
})

v.SilentAimBox:AddToggle("silenthighlight", {
    Text = "highlight",
    Default = false
})

Toggles.silenthighlight:AddColorPicker("silenthighlightcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "highlight color"
})

Toggles.silenthighlight:OnChanged(function()
    v.silentHighlightEnabled = Toggles.silenthighlight.Value
    if not v.silentHighlightEnabled and v.SilentAimHighlight then
        v.SilentAimHighlight:Destroy()
        v.SilentAimHighlight = nil
    end
end)

Options.silenthighlightcolor:OnChanged(function()
    v.silentHighlightColor = Options.silenthighlightcolor.Value
    if v.SilentAimHighlight then
        v.SilentAimHighlight.FillColor = Options.silenthighlightcolor.Value
        v.SilentAimHighlight.OutlineColor = Options.silenthighlightcolor.Value
    end
end)

v.SilentAimBox:AddDropdown("silenttargetpart", {
    Text = "target part",
    Default = 1,
    Values = {"HumanoidRootPart", "Head", "UpperTorso", "LowerTorso", "Closest Part"},
    Callback = function(value)
        getgenv().SilentAim.TargetPart = value
    end
})

v.SilentAimBox:AddSlider("silenthitchance", {
    Text = "hit chance %",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        getgenv().SilentAim.HitChance = value
    end
})

v.SilentAimBox:AddToggle("teamcheck", {
    Text = "team check",
    Default = false,
    Callback = function(value)
        getgenv().SilentAim.TeamCheck = value
    end
})

v.SilentAimBox:AddToggle("alivecheck", {
    Text = "alive check",
    Default = false,
    Callback = function(value)
        getgenv().SilentAim.AliveCheck = value
    end
})

v.SilentAimBox:AddToggle("visiblecheck", {
    Text = "visible check",
    Default = false,
    Callback = function(value)
        getgenv().SilentAim.VisibleCheck = value
    end
})

v.SavedAccessoryIDs = {}
v.LoadedAccessories = {}
v.AccessoryNames = {}

local function WearAccessory(assetId)
    local char = GetCharacter()
    if not char then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    local success, accessory = pcall(function()
        return game:GetObjects("rbxassetid://" .. assetId)[1]
    end)

    if not success or not accessory then
        return false
    end

    if accessory:IsA("Accessory") then
        local handle = accessory:FindFirstChild("Handle")
        if handle then
            accessory.Parent = char


            local tag = Instance.new("BoolValue")
            tag.Name = "ScriptAccessory"
            tag.Value = true
            tag.Parent = accessory


            local idValue = Instance.new("StringValue")
            idValue.Name = "AssetID"
            idValue.Value = assetId
            idValue.Parent = accessory

            local attachment = handle:FindFirstChildOfClass("Attachment")
            if attachment then
                local attachmentName = attachment.Name
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("Attachment") and part.Name == attachmentName then
                        handle.CFrame = part.Parent.CFrame * part.CFrame

                        local weld = Instance.new("Weld")
                        weld.Part0 = part.Parent
                        weld.Part1 = handle
                        weld.C0 = part.CFrame
                        weld.C1 = attachment.CFrame
                        weld.Parent = handle
                        break
                    end
                end
            end

            table.insert(v.LoadedAccessories, assetId)
            return true
        end
    end

    return false
end

local function RemoveAccessory(assetId)
    local char = GetCharacter()
    if not char then return false end

    for _, item in pairs(char:GetChildren()) do
        if item:IsA("Accessory") and item:FindFirstChild("ScriptAccessory") then
            local idValue = item:FindFirstChild("AssetID")
            if idValue and idValue.Value == assetId then
                item:Destroy()


                for i = #v.LoadedAccessories, 1, -1 do
                    if v.LoadedAccessories[i] == assetId then
                        table.remove(v.LoadedAccessories, i)
                    end
                end
                return true
            end
        end
    end
    return false
end

v.AvatarLeft:AddInput("accessoryid", {
    Default = "",
    Numeric = true,
    Finished = false,
    Text = "accessory id",
    Tooltip = "enter accessory id",
    Placeholder = "enter id..."
})

v.AvatarLeft:AddInput("accessoryname", {
    Default = "",
    Numeric = false,
    Finished = false,
    Text = "name accessory",
    Tooltip = "enter accessory name",
    Placeholder = "enter name..."
})

v.AvatarLeft:AddButton({
    Text = "add accessory",
    Func = function()
        local id = Options.accessoryid.Value
        local name = Options.accessoryname.Value
        if id ~= "" then
            if name == "" then
                name = id
            end

            v.AccessoryNames[id] = name

            if not table.find(v.SavedAccessoryIDs, id) then
                table.insert(v.SavedAccessoryIDs, id)
            end

            local dropdownValues = {}
            for _, accessoryId in pairs(v.SavedAccessoryIDs) do
                local displayName = v.AccessoryNames[accessoryId] or accessoryId
                table.insert(dropdownValues, displayName)
            end

            Options.savedaccessories:SetValues(dropdownValues)
            Library:Notify("added: " .. name)
            Options.accessoryid:SetValue("")
            Options.accessoryname:SetValue("")
        end
    end
})

v.AvatarLeft:AddButton({
    Text = "remove all accessories",
    Func = function()
        local char = GetCharacter()
        if char then
            for _, item in pairs(char:GetChildren()) do
                if item:IsA("Accessory") and item:FindFirstChild("ScriptAccessory") then
                    item:Destroy()
                end
            end
            v.LoadedAccessories = {}
            Library:Notify("removed all script accessories")
        end
    end
})

v.AvatarLeft:AddDropdown("savedaccessories", {
    Text = "saved accessories",
    Default = 1,
    Values = {},
    Multi = true,
    AllowNull = true,
    Callback = function(selectedValues)
        if not selectedValues then selectedValues = {} end
        if type(selectedValues) ~= "table" then
            selectedValues = {selectedValues}
        end

        local selectedIds = {}
        for selectedName, isSelected in pairs(selectedValues) do
            if isSelected then
                for id, name in pairs(v.AccessoryNames) do
                    if name == selectedName then
                        table.insert(selectedIds, id)
                        break
                    end
                end
            end
        end

        local char = GetCharacter()
        if char then
            for _, item in pairs(char:GetChildren()) do
                if item:IsA("Accessory") and item:FindFirstChild("ScriptAccessory") then
                    local idValue = item:FindFirstChild("AssetID")
                    if idValue then
                        local shouldKeep = table.find(selectedIds, idValue.Value)
                        if not shouldKeep then
                            item:Destroy()
                        end
                    end
                end
            end

            for _, id in pairs(selectedIds) do
                local alreadyWearing = false
                for _, item in pairs(char:GetChildren()) do
                    if item:IsA("Accessory") and item:FindFirstChild("ScriptAccessory") then
                        local idValue = item:FindFirstChild("AssetID")
                        if idValue and idValue.Value == id then
                            alreadyWearing = true
                            break
                        end
                    end
                end

                if not alreadyWearing then
                    WearAccessory(id)
                end
            end
        end
    end
})

v.AvatarLeft:AddToggle("violetvalk", {
    Text = "violet valk",
    Default = false,
    Callback = function(value)
        if value then
            WearAccessory("1402432199")
        else
            RemoveAccessory("1402432199")
        end
    end
})

v.AvatarLeft:AddToggle("bluevalk", {
    Text = "blue valk",
    Default = false,
    Callback = function(value)
        if value then
            WearAccessory("1365767")
        else
            RemoveAccessory("1365767")
        end
    end
})

v.AvatarLeft:AddToggle("icevalk", {
    Text = "ice valk",
    Default = false,
    Callback = function(value)
        if value then
            WearAccessory("4390891467")
        else
            RemoveAccessory("4390891467")
        end
    end
})

v.AvatarLeft:AddToggle("blackironhorns", {
    Text = "black iron horns",
    Default = false,
    Callback = function(value)
        if value then
            WearAccessory("628771505")
        else
            RemoveAccessory("628771505")
        end
    end
})

v.AvatarLeft:AddToggle("poisonhorn", {
    Text = "poison horn",
    Default = false,
    Callback = function(value)
        if value then
            WearAccessory("1744060292")
        else
            RemoveAccessory("1744060292")
        end
    end
})

v.AvatarLeft:AddToggle("frigidhorn", {
    Text = "frigid horn",
    Default = false,
    Callback = function(value)
        if value then
            WearAccessory("74891470")
        else
            RemoveAccessory("74891470")
        end
    end
})

v.AvatarLeft:AddToggle("firehorns", {
    Text = "fire horns",
    Default = false,
    Callback = function(value)
        if value then
            WearAccessory("215718515")
        else
            RemoveAccessory("215718515")
        end
    end
})

v.AvatarLeft:AddToggle("rexdominus", {
    Text = "rex dominus",
    Default = false,
    Callback = function(value)
        if value then
            WearAccessory("250395631")
        else
            RemoveAccessory("250395631")
        end
    end
})

v.AvatarLeft:AddToggle("empyrusdominus", {
    Text = "empyrus dominus",
    Default = false,
    Callback = function(value)
        if value then
            WearAccessory("21070012")
        else
            RemoveAccessory("21070012")
        end
    end
})

v.AvatarLeft:AddToggle("frigidusdominus", {
    Text = "frigidus dominus",
    Default = false,
    Callback = function(value)
        if value then
            WearAccessory("48545806")
        else
            RemoveAccessory("48545806")
        end
    end
})

v.AvatarLeft:AddToggle("blackskotn", {
    Text = "black skotn",
    Default = false,
    Callback = function(value)
        if value then
            WearAccessory("439946249")
        else
            RemoveAccessory("439946249")
        end
    end
})

v.AvatarRight:AddToggle("headless", {
    Text = "headless",
    Default = false,
    Tooltip = "free headless!1!1!",
    Callback = function(state)
        local char = GetCharacter()
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end

        head.Transparency = state and 1 or 0

        for _, child in pairs(head:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                child.Transparency = state and 1 or 0
            end
        end

        Library:Notify(state and "Headless enabled" or "Headless disabled")
    end
})

v.KorbloxOriginals = {}

local function applyKorblox(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 2)
    if not hum then return end

    v.KorbloxOriginals = {}

    if hum.RigType == Enum.HumanoidRigType.R15 then
        local limbs = {
            {"RightLowerLeg", 902942093, true},
            {"RightUpperLeg", 902942096, false, 902843398},
            {"RightFoot",     902942089, true}
        }
        for _, info in ipairs(limbs) do
            local p = char:FindFirstChild(info[1])
            if p then

                v.KorbloxOriginals[info[1]] = {
                    MeshId = p.MeshId,
                    TextureID = p.TextureID,
                    Transparency = p.Transparency
                }
                p.MeshId = "http://www.roblox.com/asset/?id=" .. info[2]
                if info[3] then p.Transparency = 1 end
                if info[4] then
                    p.TextureID = "http://roblox.com/asset/?id=" .. info[4]
                end
            end
        end
    else
        local base = char:FindFirstChild("Right Leg")
        if not base then return end

        v.KorbloxOriginals["Right Leg"] = { Transparency = base.Transparency }
        base.Transparency = 1

        local shell = char:FindFirstChild("KorbloxShell")
        if shell then shell:Destroy() end

        shell = Instance.new("Part")
        shell.Name = "KorbloxShell"
        shell.Size = Vector3.new(1, 2, 1)
        shell.CanCollide = false
        shell.Massless = true
        shell.CFrame = base.CFrame * CFrame.new(0, 0.75, 0)
        shell.Parent = char

        local lock = Instance.new("WeldConstraint")
        lock.Part0 = shell
        lock.Part1 = base
        lock.Parent = shell

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "http://www.roblox.com/asset/?id=902942093"
        mesh.TextureId = "http://roblox.com/asset/?id=902843398"
        mesh.Scale = Vector3.new(0.85, 1.25, 0.85)
        mesh.Parent = shell
    end
end

local function removeKorblox(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.RigType == Enum.HumanoidRigType.R15 then
        local limbs = {"RightLowerLeg", "RightUpperLeg", "RightFoot"}
        for _, name in ipairs(limbs) do
            local p = char:FindFirstChild(name)
            if p then
                local orig = v.KorbloxOriginals[name]
                if orig then
                    p.MeshId = orig.MeshId
                    p.TextureID = orig.TextureID
                    p.Transparency = orig.Transparency
                else
                    p.Transparency = 0
                end
            end
        end
    else
        local base = char:FindFirstChild("Right Leg")
        if base then
            local orig = v.KorbloxOriginals["Right Leg"]
            base.Transparency = orig and orig.Transparency or 0
        end
        local shell = char:FindFirstChild("KorbloxShell")
        if shell then shell:Destroy() end
    end
    v.KorbloxOriginals = {}
end

v.AvatarRight:AddToggle("korblox", {
    Text = "korblox",
    Default = false,
    Tooltip = "free korblox right leg!",
    Callback = function(state)
        local char = GetCharacter()
        if state then
            applyKorblox(char)
        else
            removeKorblox(char)
        end
        Library:Notify(state and "Korblox enabled" or "Korblox disabled")
    end
})

v.AvatarRight:AddToggle("resetkeep", {
    Text = "reset keep",
    Default = false,
    Tooltip = "keeps script accessories after death/reset"
})


v.AccessoryToggleMap = {
    VioletValk = "1402432199",
    BlackIronHorns = "628771505",
    PoisonHorn = "1744060292",
    FrigidHorn = "74891470",
    FireHorns = "215718515",
    RexDominus = "250395631",
    EmpyrusDominus = "21070012",
    FrigidusDominus = "48545806",
    BlackSkotn = "439946249"
}

Player.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)

    if Toggles.korblox and Toggles.korblox.Value then
        applyKorblox(newChar)
    end

    if Toggles.resetkeep and Toggles.resetkeep.Value then
        for toggleName, accessoryId in pairs(v.AccessoryToggleMap) do
            if Toggles[toggleName] and Toggles[toggleName].Value then
                WearAccessory(accessoryId)
            end
        end

        for _, id in pairs(v.SavedAccessoryIDs) do
            WearAccessory(id)
        end
    end
end)



v.Main:AddToggle("speedtoggle", {
    Text = "speed hack",
    Default = false
})

Toggles.speedtoggle:AddKeyPicker("speedkey", {
    Text = "speed hack",
    Default = "NONE",
    SyncToggleState = true
})

v.Main:AddSlider("speedinput", {
    Text = "speed value",
    Default = 50,
    Min = 1,
    Max = 10000,
    Rounding = 0,
    Compact = false
})

v.Main:AddDropdown("speedmode", {
    Text = "type",
    Default = 1,
    Values = {"Speed Hack", "Velocity", "CFrame"},
    AllowNull = false
})

RunService.Heartbeat:Connect(function()
    if Toggles.speedtoggle.Value then
        local root = GetRootPart()
        local hum = GetHumanoid()
        if root and hum then
            local mode = Options.speedmode.Value
            local speed = tonumber(Options.speedinput.Value) or 50

            if mode == "Speed Hack" then
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    root.CFrame = root.CFrame + (moveDir * (speed / 60))
                end
            elseif mode == "Velocity" then
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    root.Velocity = Vector3.new(moveDir.X * speed, root.Velocity.Y, moveDir.Z * speed)
                end
            elseif mode == "CFrame" then
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    root.CFrame = root.CFrame + (moveDir * (speed / 60))
                end
            end
        end
    end
end)


v.MainMovement:AddToggle("spinbottoggle", {
    Text = "spinbot",
    Default = false,
    Tooltip = "lets u spin"
})

Toggles.spinbottoggle:AddKeyPicker("spinbotkey", {
    Text = "spinbot",
    Default = "NONE",
    SyncToggleState = true
})

v.MainMovement:AddSlider("spinbotspeed", {
    Text = "spinbot speed",
    Min = 1,
    Max = 2000,
    Default = 50,
    Rounding = 0
})

v.spinAngle = 0
RunService.RenderStepped:Connect(function(deltaTime)
    if Toggles.spinbottoggle.Value then
        local root = GetRootPart()
        if root then
            local speed = Options.spinbotspeed.Value
            v.spinAngle += math.rad(speed) * deltaTime * 28
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, v.spinAngle, 0)
        end
    end
end)


v.MainMovement:AddToggle("noclip", {
    Text = "noclip",
    Default = false,
    Tooltip = "lets you go through parts like walls"
})

Toggles.noclip:AddKeyPicker("noclipkey", {
    Text = "noclip",
    Default = "NONE",
    SyncToggleState = true
})

v.noclipping = false

Toggles.noclip:OnChanged(function(value)
    v.noclipping = value
end)

RunService.Stepped:Connect(function()
    if v.noclipping then
        local char = GetCharacter()
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end
end)

v.MainMovement:AddToggle("bunnyhop", {
    Text = "bunnyhop",
    Default = false,
    Tooltip = "makes your character continuously jump"
})

Toggles.bunnyhop:AddKeyPicker("bunnyhopkey", {
    Text = "bunnyhop",
    Default = "NONE",
    SyncToggleState = true
})

v.bunnyhopping = false

Toggles.bunnyhop:OnChanged(function(value)
    v.bunnyhopping = value
end)

RunService.RenderStepped:Connect(function()
    if v.bunnyhopping then
        local char = GetCharacter()
        local hum = GetHumanoid()
        if char and hum and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)


v.MainOther:AddToggle("flighttoggle", {
    Text = "flight",
    Default = false
})

Toggles.flighttoggle:AddKeyPicker("flightkey", {
    Text = "flight",
    Default = "NONE",
    SyncToggleState = true
})

v.MainOther:AddSlider("flightspeed", {
    Text = "flight speed",
    Min = 1,
    Max = 3000,
    Default = 50,
    Rounding = 0
})

v.MainOther:AddDropdown("flightmode", {
    Text = "flight type",
    Default = 1,
    Values = {"Normal", "Smooth", "CFrame"},
    AllowNull = false
})

v.MainOther:AddDropdown("flightdirection", {
    Text = "flight direction",
    Default = 1,
    Values = {"horizontally", "vertically"},
    AllowNull = false
})

v.smoothVelocity = Vector3.new(0, 0, 0)

Toggles.flighttoggle:OnChanged(function()
    local root = GetRootPart()
    if Toggles.flighttoggle.Value and root then
        local mode = Options.flightmode.Value

        if mode == "Normal" then

            local char = GetCharacter()
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            local T = GetRootPart()
            if not T then return end

            v._normalFlyControl = {F=0,B=0,L=0,R=0,Q=0,E=0}
            v._normalFlylControl = {F=0,B=0,L=0,R=0,Q=0,E=0}
            v._normalFlyActive = false

            local BG = Instance.new("BodyGyro")
            local BV = Instance.new("BodyVelocity")
            BG.P = 9e4
            BG.Parent = T
            BV.Parent = T
            BG.MaxTorque = Vector3.new(9e9,9e9,9e9)
            BG.CFrame = T.CFrame
            BV.Velocity = Vector3.new(0,0,0)
            BV.MaxForce = Vector3.new(9e9,9e9,9e9)
            v.BodyGyro = BG
            v.BodyVelocity = BV

            if v._normalFlyKeyDown then v._normalFlyKeyDown:Disconnect() end
            if v._normalFlyKeyUp then v._normalFlyKeyUp:Disconnect() end

            v._normalFlyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
                if processed then return end
                local C = v._normalFlyControl
                if input.KeyCode == Enum.KeyCode.W then C.F = 1
                elseif input.KeyCode == Enum.KeyCode.S then C.B = -1
                elseif input.KeyCode == Enum.KeyCode.A then C.L = -1
                elseif input.KeyCode == Enum.KeyCode.D then C.R = 1
                elseif input.KeyCode == Enum.KeyCode.E then C.Q = 1
                elseif input.KeyCode == Enum.KeyCode.Q then C.E = -1
                end
            end)
            v._normalFlyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
                if processed then return end
                local C = v._normalFlyControl
                if input.KeyCode == Enum.KeyCode.W then C.F = 0
                elseif input.KeyCode == Enum.KeyCode.S then C.B = 0
                elseif input.KeyCode == Enum.KeyCode.A then C.L = 0
                elseif input.KeyCode == Enum.KeyCode.D then C.R = 0
                elseif input.KeyCode == Enum.KeyCode.E then C.Q = 0
                elseif input.KeyCode == Enum.KeyCode.Q then C.E = 0
                end
            end)

            task.spawn(function()
                while States.Flying and mode == "Normal" do
                    task.wait()
                    local cam = workspace.CurrentCamera
                    local speed = Options.flightspeed.Value
                    local C = v._normalFlyControl
                    local lC = v._normalFlylControl
                    if humanoid then humanoid.PlatformStand = true end
                    local moving = (C.L+C.R) ~= 0 or (C.F+C.B) ~= 0 or (C.Q+C.E) ~= 0
                    if moving then
                        local horizontal = (cam.CFrame.LookVector * (C.F+C.B)) + (cam.CFrame.RightVector * (C.L+C.R))
                        local vertical = Vector3.new(0, (C.Q+C.E) * speed, 0)
                        BV.Velocity = horizontal.Unit * speed + vertical
                        v._normalFlylControl = {F=C.F,B=C.B,L=C.L,R=C.R,Q=C.Q,E=C.E}
                        v._normalFlyActive = true
                    else
                        BV.Velocity = Vector3.new(0,0,0)
                        v._normalFlyActive = false
                    end
                    BG.CFrame = cam.CFrame
                end
                v._normalFlyControl = {F=0,B=0,L=0,R=0,Q=0,E=0}
                v._normalFlylControl = {F=0,B=0,L=0,R=0,Q=0,E=0}
                v._normalFlyActive = false
                if humanoid then humanoid.PlatformStand = false end
                if v._normalFlyKeyDown then v._normalFlyKeyDown:Disconnect() end
                if v._normalFlyKeyUp then v._normalFlyKeyUp:Disconnect() end
            end)

        elseif mode == "Smooth" then
            local attachment = Instance.new("Attachment")
            attachment.Parent = root

            v.LinearVelocity = Instance.new("LinearVelocity")
            v.LinearVelocity.Attachment0 = attachment
            v.LinearVelocity.MaxForce = math.huge
            v.LinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
            v.LinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
            v.LinearVelocity.Parent = root

            v.AlignOrientation = Instance.new("AlignOrientation")
            v.AlignOrientation.Attachment0 = attachment
            v.AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
            v.AlignOrientation.MaxTorque = math.huge
            v.AlignOrientation.Responsiveness = 200
            v.AlignOrientation.Parent = root

        elseif mode == "CFrame" then
            v.CFrameBodyVelocity = Instance.new("BodyVelocity")
            v.CFrameBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            v.CFrameBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            v.CFrameBodyVelocity.Parent = root

            v.CFrameBodyGyro = Instance.new("BodyGyro")
            v.CFrameBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            v.CFrameBodyGyro.P = 9e4
            v.CFrameBodyGyro.Parent = root
        end

        States.Flying = true
        v.smoothVelocity = Vector3.new(0, 0, 0)
    else
        States.Flying = false
        v.smoothVelocity = Vector3.new(0, 0, 0)

        if v._normalFlyKeyDown then v._normalFlyKeyDown:Disconnect(); v._normalFlyKeyDown = nil end
        if v._normalFlyKeyUp then v._normalFlyKeyUp:Disconnect(); v._normalFlyKeyUp = nil end
        v._normalFlyActive = false

        if v.BodyVelocity then v.BodyVelocity:Destroy() end
        if v.BodyGyro then v.BodyGyro:Destroy() end

        if v.LinearVelocity then
            if v.LinearVelocity.Attachment0 then
                v.LinearVelocity.Attachment0:Destroy()
            end
            v.LinearVelocity:Destroy()
        end
        if v.AlignOrientation then v.AlignOrientation:Destroy() end

        if v.CFrameBodyVelocity then v.CFrameBodyVelocity:Destroy() end
        if v.CFrameBodyGyro then v.CFrameBodyGyro:Destroy() end
    end
end)

RunService.RenderStepped:Connect(function()
    if States.Flying then
        local root = GetRootPart()
        local hum = GetHumanoid()
        if root and hum then
            local speed = Options.flightspeed.Value
            local mode = Options.flightmode.Value
            local direction = Options.flightdirection.Value

            local targetVelocity = Vector3.new(0, 0, 0)
            local moveDirection = nil


            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                targetVelocity = targetVelocity + Camera.CFrame.LookVector * speed
                moveDirection = Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                targetVelocity = targetVelocity - Camera.CFrame.LookVector * speed
                moveDirection = -Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                targetVelocity = targetVelocity - Camera.CFrame.RightVector * speed
                moveDirection = -Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                targetVelocity = targetVelocity + Camera.CFrame.RightVector * speed
                moveDirection = Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                targetVelocity = targetVelocity + Vector3.new(0, speed, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                targetVelocity = targetVelocity - Vector3.new(0, speed, 0)
            end

            if mode == "Normal" and v.BodyVelocity and v.BodyGyro then


            elseif mode == "Smooth" and v.LinearVelocity and v.AlignOrientation then
                local lerpSpeed
                if targetVelocity.Magnitude > 0 then
                    lerpSpeed = 0.03
                else
                    lerpSpeed = 0.004
                end

                v.smoothVelocity = v.smoothVelocity:Lerp(targetVelocity, lerpSpeed)
                v.LinearVelocity.VectorVelocity = v.smoothVelocity

                if direction == "horizontally" then
                    v.AlignOrientation.CFrame = Camera.CFrame
                elseif direction == "vertically" and moveDirection then
                    local lookAt = root.Position + Vector3.new(moveDirection.X, 0, moveDirection.Z)
                    v.AlignOrientation.CFrame = CFrame.new(root.Position, lookAt)
                end

                hum:ChangeState(Enum.HumanoidStateType.Freefall)

            elseif mode == "CFrame" and v.CFrameBodyVelocity and v.CFrameBodyGyro then
                if targetVelocity.Magnitude > 0 then
                    local moveDir = targetVelocity.Unit
                    local moveSpeed = speed / 60
                    root.CFrame = root.CFrame + (moveDir * moveSpeed)
                end

                v.CFrameBodyVelocity.Velocity = Vector3.new(0, 0, 0)

                if direction == "horizontally" then
                    v.CFrameBodyGyro.CFrame = Camera.CFrame
                elseif direction == "vertically" and moveDirection then
                    local lookAt = root.Position + Vector3.new(moveDirection.X, 0, moveDirection.Z)
                    v.CFrameBodyGyro.CFrame = CFrame.new(root.Position, lookAt)
                end
            end
        end
    end
end)


v.DesyncMode = v.MainDesync:AddDropdown('desyncmode', {
    Values = {'position', 'skyhide'},
    Default = 1,
    Multi = false,
    Text = 'Desync Mode',
    Tooltip = 'position (desyncs at ur place) skyhide (Tp u to sky,then desync there)'
})

v.VisualizerToggle = v.MainDesync:AddToggle('visualizer', {
    Text = 'visualizer',
    Default = false,
    Tooltip = 'Shows a ball at your desync position'
})

v.ColorPicker = v.VisualizerToggle:AddColorPicker('visualizercolor', {
    Default = Color3.new(1, 1, 1),
    Title = 'visualizer Color'
})

v.DesyncToggle = v.MainDesync:AddToggle('desync', {
    Text = 'desync',
    Default = false,
    Tooltip = 'ur character gets frozen but on ur client u can still move fly etc'
})

v.visualizerPart = nil
v.desyncPosition = nil

local function createVisualizer(position)
    if v.visualizerPart then
        v.visualizerPart:Destroy()
    end

    v.visualizerPart = Instance.new("Part")
    v.visualizerPart.Shape = Enum.PartType.Ball
    v.visualizerPart.Size = Vector3.new(3, 3, 3)
    v.visualizerPart.Position = position
    v.visualizerPart.Anchored = true
    v.visualizerPart.CanCollide = false
    v.visualizerPart.Material = Enum.Material.Neon
    v.visualizerPart.Color = Options.visualizercolor.Value or Color3.fromRGB(255, 0, 0)
    v.visualizerPart.Transparency = v.VisualizerToggle.Value and 0.3 or 1
    v.visualizerPart.Name = "DesyncVisualizer"
    v.visualizerPart.Parent = workspace
end

local function updateVisualizerVisibility()
    if v.visualizerPart then
        if v.VisualizerToggle.Value then
            v.visualizerPart.Transparency = 0.3
        else
            v.visualizerPart.Transparency = 1
        end
    end
end

v.VisualizerToggle:OnChanged(function()
    if v.VisualizerToggle.Value and v.DesyncToggle.Value and v.desyncPosition then

        if not v.visualizerPart then
            createVisualizer(v.desyncPosition)
        else
            updateVisualizerVisibility()
        end
    else
        updateVisualizerVisibility()
    end
end)

v.ColorPicker:OnChanged(function()
    if v.visualizerPart then
        v.visualizerPart.Color = Options.visualizercolor.Value or Color3.fromRGB(255, 0, 0)
    end
end)


RunService.Heartbeat:Connect(function()
    if v.DesyncToggle.Value and v.desyncPosition then

        if v.visualizerPart then
            v.visualizerPart.Position = v.desyncPosition
        end


        if v.visualizerPart and Options.visualizercolor then
            v.visualizerPart.Color = Options.visualizercolor.Value or Color3.fromRGB(255, 0, 0)
        end


        if v.visualizerPart then
            v.visualizerPart.Transparency = v.VisualizerToggle.Value and 0.3 or 1
        end


        if not v.visualizerPart and v.VisualizerToggle.Value then
            createVisualizer(v.desyncPosition)
        end
    end
end)

v.DesyncToggle:OnChanged(function(value)
    local selectedMode = v.DesyncMode.Value
    local player = game.Players.LocalPlayer
    local character = player.Character

    if selectedMode == 'position' then
        if value and character and character:FindFirstChild("HumanoidRootPart") then

            v.desyncPosition = character.HumanoidRootPart.Position
            createVisualizer(v.desyncPosition)


            setfflag("NextGenReplicatorEnabledWrite4", "true")

        elseif not value then

            setfflag("NextGenReplicatorEnabledWrite4", "false")

            if v.visualizerPart then
                v.visualizerPart:Destroy()
                v.visualizerPart = nil
            end
            v.desyncPosition = nil
        end

    elseif selectedMode == 'skyhide' then
        if value and character and character:FindFirstChild("HumanoidRootPart") then
            v.originalPosition = character.HumanoidRootPart.CFrame


            character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame + Vector3.new(0, 1945007, 0)

            task.wait(1)


            setfflag("NextGenReplicatorEnabledWrite4", "true")


            v.desyncPosition = character.HumanoidRootPart.Position


            createVisualizer(v.desyncPosition)

            task.wait(1)


            character.HumanoidRootPart.CFrame = v.originalPosition

        elseif not value then

            setfflag("NextGenReplicatorEnabledWrite4", "false")

            if v.visualizerPart then
                v.visualizerPart:Destroy()
                v.visualizerPart = nil
            end
            v.desyncPosition = nil
        end
    end
end)

v.DesyncToggle:AddKeyPicker('desynckey', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'desync',
    NoUI = false
})

v.MainMovement:AddToggle("infinitejump", {
    Text = "infinite jump",
    Default = false,
    Tooltip = "lets you jump infinitely, even in the air"
})

UserInputService.JumpRequest:Connect(function()
    if Toggles.infinitejump and Toggles.infinitejump.Value then
        local hum = GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

v.AirClimbToggle = v.MainMovement:AddToggle("airclimb", {
    Text = "air climb",
    Default = false,
    Tooltip = "lets u climb air"
})
v.AirClimbToggle:AddKeyPicker("airclimbkey", {
    Text = "air climb",
    Default = "NONE",
    SyncToggleState = true
})

v.airClimbConnection = nil
Toggles.airclimb:OnChanged(function(enabled)
    if enabled then
        v.airClimbConnection = RunService.RenderStepped:Connect(function()
            local hum = GetHumanoid()
            local root = GetRootPart()
            if not hum or not root then return end

            hum:ChangeState(Enum.HumanoidStateType.Climbing)


            local vy = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                vy = hum.WalkSpeed
            elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
                vy = -hum.WalkSpeed
            end

            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X,
                vy,
                root.AssemblyLinearVelocity.Z
            )
        end)
    else
        if v.airClimbConnection then
            v.airClimbConnection:Disconnect()
            v.airClimbConnection = nil
        end
        local hum = GetHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end
    end
end)


v.SwimToggle = v.MainMovement:AddToggle("swimtoggle", {
    Text = "swim",
    Default = false,
    Tooltip = "lets you swim!"
})
Toggles.swimtoggle = v.SwimToggle
v.SwimToggle:AddKeyPicker("swimkey", {
    Text = "swim",
    Default = "NONE",
    SyncToggleState = true
})
v.MainMovement:AddSlider("swimspeed", {
    Text = "swim speed",
    Min = 10,
    Max = 1000,
    Default = 50,
    Rounding = 0
})
v.swimConnection = nil
Toggles.swimtoggle:OnChanged(function(enabled)
    local player = Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    if enabled then
        hum:ChangeState(Enum.HumanoidStateType.Swimming)
        v.swimConnection = RunService.RenderStepped:Connect(function()
            hum:ChangeState(Enum.HumanoidStateType.Swimming)
            local move = Vector3.zero
            local cam = workspace.CurrentCamera
            local speed = Options.swimspeed.Value
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                move += cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                move -= cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                move -= cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                move += cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                move += Vector3.new(0, 1, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                move -= Vector3.new(0, 1, 0)
            end
            root.Velocity = move * speed
        end)
    else
        if v.swimConnection then
            v.swimConnection:Disconnect()
            v.swimConnection = nil
        end
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end)


v.MainMovement:AddToggle("gravitytoggle", {
    Text = "gravity changer",
    Default = false,
    Tooltip = "changes ur gravity"
})

v.MainMovement:AddSlider("gravityvalue", {
    Text = "gravity value",
    Default = 196.2,
    Min = 0,
    Max = 196,
    Rounding = 1,
    Compact = false
})

v.MainMovement:AddButton({
    Text = "stop force",
    Func = function()
        local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        workspace.Gravity = 196.2
        Options.gravityvalue:SetValue(196.2)
        if Toggles.gravitytoggle.Value then
            Toggles.gravitytoggle:SetValue(false)
        end
    end,
    Tooltip = "if you have a low gravity,u will freeze in the air to prevent floating (Then untoggle)"
})

Toggles.gravitytoggle:OnChanged(function()
    if Toggles.gravitytoggle.Value then
        local gravityValue = tonumber(Options.gravityvalue.Value)
        if gravityValue then
            workspace.Gravity = gravityValue
            Library:Notify("Gravity set to " .. gravityValue, 3)
        end
    else
        workspace.Gravity = 196.2

    end
end)

Options.gravityvalue:OnChanged(function()
    if Toggles.gravitytoggle.Value then
        local gravityValue = tonumber(Options.gravityvalue.Value)
        if gravityValue then
            workspace.Gravity = gravityValue
        end
    end
end)

local _upsideDownTrack = nil
v.MainMovement:AddToggle("upsidedowntoggle", {
    Text = "upside down",
    Default = false,
    Tooltip = "plays the upside down emote",
    Callback = function(value)
        local char = GetCharacter()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if value then
            local animator = hum:FindFirstChildOfClass("Animator")
            if not animator then
                animator = Instance.new("Animator")
                animator.Parent = hum
            end
            local anim
            pcall(function()
                local objects = game:GetObjects("rbxassetid://115279034344573")
                for _, obj in ipairs(objects) do
                    if obj:IsA("Animation") then anim = obj break end
                end
            end)
            if not anim then
                anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://115279034344573"
            end
            local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
            if not ok or not track then return end
            track.Priority = Enum.AnimationPriority.Action4
            track.Looped = true
            track:Play()
            track:AdjustSpeed(Options.emotespeed and Options.emotespeed.Value or 1)
            _upsideDownTrack = track
        else
            if _upsideDownTrack then
                pcall(function() _upsideDownTrack:Stop() end)
                _upsideDownTrack = nil
            end
        end
    end
})
Toggles.upsidedowntoggle:AddKeyPicker("upsidedownkeybind", {
    Default = "None",
    Text = "upside down keybind",
    SyncToggleState = true
})


local flingActive = false
local flingDiedConn = nil
local flingNoclipConn = nil
local walkflingActive = false
local walkflingDiedConn = nil
local walkflingNoclipConn = nil

local function getFlingRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function stopFling()
    flingActive = false
    if flingNoclipConn then flingNoclipConn:Disconnect() flingNoclipConn = nil end
    if flingDiedConn then flingDiedConn:Disconnect() flingDiedConn = nil end
    local char = Player.Character
    if not char then return end
    local root = getFlingRoot(char)
    if root then
        for _, v in pairs(root:GetChildren()) do
            if v.ClassName == "BodyAngularVelocity" then v:Destroy() end
        end
    end
    for _, v in pairs(char:GetDescendants()) do
        if v.ClassName == "Part" or v.ClassName == "MeshPart" then
            v.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
        end
    end
end

local function startFling()
    stopFling()
    local char = Player.Character
    if not char or not getFlingRoot(char) then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
        end
    end
    flingNoclipConn = RunService.Stepped:Connect(function()
        local c = Player.Character
        if not c then return end
        for _, v in pairs(c:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide == true then
                v.CanCollide = false
            end
        end
    end)
    task.wait(0.1)
    local root = getFlingRoot(char)
    if not root then stopFling() return end
    local bambam = Instance.new("BodyAngularVelocity")
    bambam.Name = "IYFlingBAV"
    bambam.Parent = root
    bambam.AngularVelocity = Vector3.new(0, 99999, 0)
    bambam.MaxTorque = Vector3.new(0, math.huge, 0)
    bambam.P = math.huge
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.Massless = true
            v.Velocity = Vector3.new(0, 0, 0)
        end
    end
    flingActive = true
    flingDiedConn = char:FindFirstChildOfClass("Humanoid").Died:Connect(function()
        Toggles.flingtoggle:SetValue(false)
    end)
    task.spawn(function()
        while flingActive do
            local r = getFlingRoot(Player.Character)
            if r then
                for _, v in pairs(r:GetChildren()) do
                    if v.Name == "IYFlingBAV" then v.AngularVelocity = Vector3.new(0, 99999, 0) end
                end
            end
            task.wait(0.2)
            if not flingActive then break end
            local r2 = getFlingRoot(Player.Character)
            if r2 then
                for _, v in pairs(r2:GetChildren()) do
                    if v.Name == "IYFlingBAV" then v.AngularVelocity = Vector3.new(0, 0, 0) end
                end
            end
            task.wait(0.1)
        end
    end)
end

local function stopWalkFling()
    walkflingActive = false
    if walkflingNoclipConn then walkflingNoclipConn:Disconnect() walkflingNoclipConn = nil end
    if walkflingDiedConn then walkflingDiedConn:Disconnect() walkflingDiedConn = nil end
end

local function startWalkFling()
    stopWalkFling()
    local char = Player.Character
    if not char then return end
    walkflingNoclipConn = RunService.Stepped:Connect(function()
        local c = Player.Character
        if not c then return end
        for _, v in pairs(c:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide == true then
                v.CanCollide = false
            end
        end
    end)
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        walkflingDiedConn = humanoid.Died:Connect(function()
            Toggles.walkflingtoggle:SetValue(false)
        end)
    end
    walkflingActive = true
    task.spawn(function()
        while walkflingActive do
            RunService.Heartbeat:Wait()
            local character = Player.Character
            local root = getFlingRoot(character)
            local movel = 0.1
            while not (character and character.Parent and root and root.Parent) do
                RunService.Heartbeat:Wait()
                character = Player.Character
                root = getFlingRoot(character)
            end
            local vel = root.Velocity
            root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            if character and character.Parent and root and root.Parent then
                root.Velocity = vel
            end
            RunService.Stepped:Wait()
            if character and character.Parent and root and root.Parent then
                root.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        end
    end)
end

v.FlingGroup:AddToggle("flingtoggle", {
    Text = "fling",
    Default = false,
    Tooltip = "flings whoever is near to u (DO NOT ENABLE SHIFTLOCK ON U WILL FLING URSELF)",
    Callback = function(val)
        if val then startFling() else stopFling() end
    end
})
v.FlingGroup:AddToggle("walkflingtoggle", {
    Text = "walkfling",
    Default = false,
    Tooltip = "flings whoever is near u,but they dont see it",
    Callback = function(val)
        if val then startWalkFling() else stopWalkFling() end
    end
})
v.FlingGroup:AddLabel("fling keybind"):AddKeyPicker("flingkeybind", { Default = "None", Text = "fling keybind", SyncToggleState = false })
v.FlingGroup:AddLabel("walkfling keybind"):AddKeyPicker("walkflingkeybind", { Default = "None", Text = "walkfling keybind", SyncToggleState = false })


v.ViewOffsetGroup:AddToggle("viewoffsettoggle", {
    Text = "view offset",
    Default = false,
    Tooltip = "Offsets the camera position relative to your character"
})
v.ViewOffsetGroup:AddSlider("viewoffsetx", {
    Text = "x", Default = 0, Min = -30, Max = 30, Rounding = 1, Compact = false
})
v.ViewOffsetGroup:AddSlider("viewoffsety", {
    Text = "y", Default = 0, Min = -30, Max = 30, Rounding = 1, Compact = false
})
v.ViewOffsetGroup:AddSlider("viewoffsetz", {
    Text = "z", Default = 0, Min = -30, Max = 30, Rounding = 1, Compact = false
})
local viewOffsetConn = nil
local function applyViewOffset()
    local humanoid = GetHumanoid()
    if humanoid then
        humanoid.CameraOffset = Vector3.new(Options.viewoffsetx.Value, Options.viewoffsety.Value, Options.viewoffsetz.Value)
    end
end
Toggles.viewoffsettoggle:OnChanged(function()
    if Toggles.viewoffsettoggle.Value then
        applyViewOffset()
        viewOffsetConn = RunService.RenderStepped:Connect(applyViewOffset)
    else
        if viewOffsetConn then viewOffsetConn:Disconnect() viewOffsetConn = nil end
        local humanoid = GetHumanoid()
        if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
    end
end)
Options.viewoffsetx:OnChanged(function() if Toggles.viewoffsettoggle.Value then applyViewOffset() end end)
Options.viewoffsety:OnChanged(function() if Toggles.viewoffsettoggle.Value then applyViewOffset() end end)
Options.viewoffsetz:OnChanged(function() if Toggles.viewoffsettoggle.Value then applyViewOffset() end end)

local function GetAllToolNames()
    local toolNames = {}
    local char = GetCharacter()


    for _, tool in pairs(Player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(toolNames, tool.Name)
        end
    end


    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(toolNames, tool.Name)
            end
        end
    end


    local uniqueTools = {}
    local seen = {}
    for _, name in pairs(toolNames) do
        if not seen[name] then
            seen[name] = true
            table.insert(uniqueTools, name)
        end
    end

    return uniqueTools
end

local function UpdateToolDropdown()
    local tools = GetAllToolNames()
    if #tools > 0 then
        Options.tooldropdown:SetValues(tools)
    else
        Options.tooldropdown:SetValues({"found tool"})
    end
end


v.Right:AddDropdown("tooldropdown", {
    Text = "tools",
    Default = 1,
    Multi = true,
    Values = {"No tools found"},
    Tooltip = "select multiple tools to equip at once"
})


v.Right:AddButton({
    Text = "refresh list",
    Func = function()
        UpdateToolDropdown()
        Library:Notify("refreshed")
    end
})


v.Right:AddButton({
    Text = "equip selected",
    Func = function()
        local char = GetCharacter()
        if not char then

            return
        end


        local selectedTools = {}


        if Options.tooldropdown.Value then
            for toolName, isSelected in pairs(Options.tooldropdown.Value) do
                if isSelected then
                    table.insert(selectedTools, toolName)
                end
            end
        end




        if #selectedTools == 0 then

            return
        end

        if selectedTools[1] == "No tools found" then

            return
        end

        local equippedCount = 0

        for _, toolName in pairs(selectedTools) do

            local tool = Player.Backpack:FindFirstChild(toolName)

            if tool and tool:IsA("Tool") then

                tool.Parent = char
                equippedCount = equippedCount + 1
                task.wait(0.01)
            else

                local equippedTool = char:FindFirstChild(toolName)
                if equippedTool and equippedTool:IsA("Tool") then
                    Library:Notify(toolName .. " already equipped")
                else
                    Library:Notify(toolName .. " not found")
                end
            end
        end

        if equippedCount > 0 then

        else

        end
    end
})


v.Right:AddButton({
    Text = "equip every tools",
    Func = function()
        local char = GetCharacter()
        if not char then

            return
        end

        local equippedCount = 0


        for _, tool in pairs(Player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = char
                equippedCount = equippedCount + 1
                task.wait(0.01)
            end
        end

        if equippedCount > 0 then

        else

        end
    end
})


v.Right:AddButton({
    Text = "unequip all",
    Func = function()
        local char = GetCharacter()
        if not char then

            return
        end

        local unequippedCount = 0


        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = Player.Backpack
                unequippedCount = unequippedCount + 1
                task.wait(0.05)
            end
        end

        if unequippedCount > 0 then

        else

        end
    end
})

v.Right:AddButton({
    Text = "get all items",
    Func = function()
        for _, tool in pairs(workspace:GetDescendants()) do
            if tool:IsA("Tool") then
                tool.Parent = Player.Backpack
            end
        end
        Library:Notify("collected all items from workspace")
    end
})

v.Right:AddButton({
    Text = "drop all tools",
    Func = function()
        local char = GetCharacter()
        local root = GetRootPart()
        if not char or not root then return end

        local droppedCount = 0


        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = workspace
                droppedCount = droppedCount + 1
            end
        end


        for _, tool in pairs(Player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = workspace
                droppedCount = droppedCount + 1
            end
        end

        Library:Notify("dropped " .. droppedCount .. " tools")
    end
})


Player.Backpack.ChildAdded:Connect(function()
    task.wait(0.1)
    UpdateToolDropdown()
end)

Player.Backpack.ChildRemoved:Connect(function()
    task.wait(0.1)
    UpdateToolDropdown()
end)


task.spawn(function()
    task.wait(1)
    UpdateToolDropdown()
end)

v.isRagdolled = false
v.currentShape = "ball"


local function enableRagdoll()
    if GetHumanoid() and GetHumanoid():FindFirstChildOfClass("Animator") then
        for _, track in pairs(GetHumanoid():FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end

    GetHumanoid().AutoRotate = false
    GetHumanoid().PlatformStand = true

    GetRootPart().CFrame = GetRootPart().CFrame + Vector3.new(0, 2, 0)
end

local function disableRagdoll()
    GetHumanoid().AutoRotate = true
    GetHumanoid().PlatformStand = false
end

game:GetService("RunService").Heartbeat:Connect(function()
    if v.isRagdolled and GetHumanoid() then
        local moveDirection = GetHumanoid().MoveDirection
        local camera = workspace.CurrentCamera

        GetRootPart().AssemblyAngularVelocity = Vector3.new(0, 0, 0)

        if moveDirection.Magnitude > 0 then
            local direction = (camera.CFrame.LookVector * -moveDirection.Z + camera.CFrame.RightVector * -moveDirection.X)
            direction = Vector3.new(direction.X, 0, direction.Z).Unit

            if v.currentShape == "ball" or v.currentShape == "sphere" then
                GetRootPart().CFrame = GetRootPart().CFrame:Lerp(GetRootPart().CFrame * CFrame.Angles(direction.Z * 0.08, 0, -direction.X * 0.08), 0.5)
                GetRootPart().Velocity = Vector3.new(direction.X * 16, GetRootPart().Velocity.Y, direction.Z * 16)
            elseif v.currentShape == "square" or v.currentShape == "cube" then
                GetRootPart().CFrame = GetRootPart().CFrame:Lerp(GetRootPart().CFrame * CFrame.Angles(direction.Z * 0.04, direction.X * 0.04, 0), 0.5)
                GetRootPart().Velocity = Vector3.new(direction.X * 16, GetRootPart().Velocity.Y, direction.Z * 16)
            end
        else
            GetRootPart().Velocity = Vector3.new(0, GetRootPart().Velocity.Y, 0)
        end
    end
end)

v.RagdolledToggle = v.Mright:AddToggle('ragdolled', {
    Text = 'Ragdoll player',
    Default = false,
    Tooltip = 'walk like shapes',
    Callback = function(Value)
        v.isRagdolled = Value
        if Value then
            enableRagdoll()
        else
            disableRagdoll()
        end
    end
})

Toggles.ragdolled = v.RagdolledToggle

v.Mright:AddDropdown('shape', {
    Values = {'ball', 'sphere', 'square', 'cube'},
    Default = 1,
    Multi = false,
    Text = 'shape',
    Tooltip = 'select movement shape',
    Callback = function(Value)
        v.currentShape = Value
    end
})

v.RagdolledToggle:AddKeyPicker('ragdollkeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'ragdoll',
    NoUI = false,
})

v.HumanoidBox = Tabs.Main:AddRightGroupbox('humanoid')

v.walkspeedEnabled = false
v.walkspeedValue = 16
v.jumppowerEnabled = false
v.jumppowerValue = 50


GetHumanoid().UseJumpPower = true

game:GetService("RunService").Heartbeat:Connect(function()
    if v.walkspeedEnabled then
        GetHumanoid().WalkSpeed = v.walkspeedValue
    end

    if v.jumppowerEnabled then
        GetHumanoid().UseJumpPower = true
        GetHumanoid().JumpPower = v.jumppowerValue
    end
end)

v.HumanoidBox:AddToggle('walkspeed', {
    Text = 'walkspeed',
    Default = false,
    Tooltip = 'change walkspeed',
    Callback = function(Value)
        v.walkspeedEnabled = Value
        if not Value then
            GetHumanoid().WalkSpeed = 16
        end
    end
})

v.HumanoidBox:AddSlider('walkspeedvalue', {
    Text = 'walkspeed value',
    Default = 16,
    Min = 1,
    Max = 10000,
    Rounding = 0,
    Compact = false,
    Tooltip = 'set walkspeed amount',
    Callback = function(Value)
        v.walkspeedValue = Value
    end
})

v.HumanoidBox:AddToggle('jumppower', {
    Text = 'jumppower',
    Default = false,
    Tooltip = 'change jumppower',
    Callback = function(Value)
        v.jumppowerEnabled = Value
        if not Value then
            GetHumanoid().UseJumpPower = true
            GetHumanoid().JumpPower = 50
        end
    end
})

v.HumanoidBox:AddSlider('jumppowervalue', {
    Text = 'jumppower value',
    Default = 50,
    Min = 1,
    Max = 10000,
    Rounding = 0,
    Compact = false,
    Tooltip = 'set jumppower amount',
    Callback = function(Value)
        v.jumppowerValue = Value
    end
})

v.VelocityBreakerToggle = v.Tright:AddToggle('velocitybreaker', {
    Text = 'Velocity breaker',
    Default = false,
    Tooltip = 'Break your velocity'
})

Toggles.velocitybreaker = v.VelocityBreakerToggle

v.VelocityBreakerToggle:AddKeyPicker('velocitybreakerkey', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'velocity breaking',
    NoUI = false
})

v.Tright:AddSlider('velocitystrength', {
    Text = 'strenght',
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = true,
    Suffix = ''
})

game:GetService("RunService").Heartbeat:Connect(function()
    if Toggles.velocitybreaker.Value then
        local character = game.Players.LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            local strength = Options.velocitystrength.Value / 100

            if hrp:FindFirstChild("v.BodyVelocity") then
                hrp.BodyVelocity:Destroy()
            end

            hrp.Velocity = hrp.Velocity * (1 - strength)
        end
    end
end)

v.FakeLagToggle = v.Bright:AddToggle('fakelagtoggle', {
    Text = 'fake lag',
    Default = false,
    Tooltip = 'simulate lag'
})
Toggles.fakelagtoggle = v.FakeLagToggle
v.FakeLagToggle:AddKeyPicker('flagkey', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'fake lag',
    NoUI = false
})

v.Bright:AddDropdown('fakelagmode', {
    Values = {'realistic', 'freeze', 'ultra lag'},
    Default = 1,
    Multi = false,
    Text = 'lag mode'
})

v.fakeLagEnabled = false
v.fakeLagMode = "realistic"
v.freezeTimer = 0
v.teleportTimer = 0
v.isFrozen = false

Toggles.fakelagtoggle:OnChanged(function(Value)
    v.fakeLagEnabled = Value
    if not Value then
        v.freezeTimer = 0
        v.teleportTimer = 0
        v.isFrozen = false
        local root = GetRootPart()
        if root then
            root.Anchored = false
        end
    end
end)

Options.fakelagmode:OnChanged(function(Value)
    v.fakeLagMode = Value
end)

RunService.Heartbeat:Connect(function(dt)
    if v.fakeLagEnabled then
        local root = GetRootPart()
        local hum = GetHumanoid()
        if not root or not hum then return end

        v.freezeTimer = v.freezeTimer + dt
        v.teleportTimer = v.teleportTimer + dt

        if v.fakeLagMode == "realistic" then
            if hum.MoveDirection.Magnitude > 0 then
                if v.freezeTimer > (math.random(60, 200) / 100) then
                    if not v.isFrozen then
                        v.isFrozen = true
                        root.Anchored = true
                        task.spawn(function()
                            task.wait(math.random(3, 8) / 10)
                            if root and v.fakeLagEnabled then
                                root.Anchored = false
                                v.isFrozen = false
                            end
                        end)
                        v.freezeTimer = 0
                    end
                end
            end

        elseif v.fakeLagMode == "freeze" then
            if hum.MoveDirection.Magnitude > 0 then
                if v.freezeTimer > (math.random(20, 80) / 100) then
                    if not v.isFrozen then
                        v.isFrozen = true
                        root.Anchored = true
                        task.spawn(function()
                            task.wait(math.random(8, 15) / 10)
                            if root and v.fakeLagEnabled then
                                root.Anchored = false
                                v.isFrozen = false
                            end
                        end)
                        v.freezeTimer = 0
                    end
                end
            end

        elseif v.fakeLagMode == "ultra lag" then
            if hum.MoveDirection.Magnitude > 0 then
                local shouldFreeze = math.random(1, 2) == 1

                if shouldFreeze and v.freezeTimer > (math.random(40, 100) / 100) then
                    if not v.isFrozen then
                        v.isFrozen = true
                        root.Anchored = true
                        task.spawn(function()
                            task.wait(math.random(5, 12) / 10)
                            if root and v.fakeLagEnabled then
                                root.Anchored = false
                                v.isFrozen = false
                            end
                        end)
                        v.freezeTimer = 0
                    end
                end

                if v.teleportTimer > (math.random(60, 150) / 100) then
                    if not v.isFrozen then
                        local randomX = math.random(-3, 3)
                        local randomZ = math.random(-3, 3)
                        root.CFrame = root.CFrame + Vector3.new(randomX, 0, randomZ)
                        v.teleportTimer = 0
                    end
                end
            end
        end
    end
end)

local function CreateESP(player)
    if player == Player and not Toggles.selfesp.Value then return end

    local v1 = {Player = player, Drawings = {}, Connections = {}}

    v1.Drawings.Box = Drawing.new("Square")
    v1.Drawings.Box.Visible = false
    v1.Drawings.Box.Color = Color3.new(1, 1, 1)
    v1.Drawings.Box.Thickness = 1
    v1.Drawings.Box.Filled = false

    v1.Drawings.BoxFill = Drawing.new("Square")
    v1.Drawings.BoxFill.Visible = false
    v1.Drawings.BoxFill.Color = Color3.new(1, 1, 1)
    v1.Drawings.BoxFill.Thickness = 0
    v1.Drawings.BoxFill.Filled = true
    v1.Drawings.BoxFill.Transparency = 0.5

    v1.Drawings.Name = Drawing.new("Text")
    v1.Drawings.Name.Visible = false
    v1.Drawings.Name.Center = true
    v1.Drawings.Name.Outline = true
    v1.Drawings.Name.Color = Color3.new(1, 1, 1)
    v1.Drawings.Name.Size = 13
    v1.Drawings.Name.Font = 2

    v1.Drawings.Distance = Drawing.new("Text")
    v1.Drawings.Distance.Visible = false
    v1.Drawings.Distance.Center = true
    v1.Drawings.Distance.Outline = true
    v1.Drawings.Distance.Color = Color3.new(1, 1, 1)
    v1.Drawings.Distance.Size = 12
    v1.Drawings.Distance.Font = 2

    v1.Drawings.TracerOutline = Drawing.new("Line")
    v1.Drawings.TracerOutline.Visible = false
    v1.Drawings.TracerOutline.Color = Color3.new(0, 0, 0)
    v1.Drawings.TracerOutline.Thickness = 3

    v1.Drawings.Tracer = Drawing.new("Line")
    v1.Drawings.Tracer.Visible = false
    v1.Drawings.Tracer.Color = Color3.new(1, 1, 1)
    v1.Drawings.Tracer.Thickness = 1

    v1.Drawings.Username = Drawing.new("Text")
    v1.Drawings.Username.Visible = false
    v1.Drawings.Username.Center = true
    v1.Drawings.Username.Outline = true
    v1.Drawings.Username.Color = Color3.new(0.5, 0.5, 1)
    v1.Drawings.Username.Size = 12
    v1.Drawings.Username.Font = 2

    v1.Drawings.HealthBarBG = Drawing.new("Square")
    v1.Drawings.HealthBarBG.Visible = false
    v1.Drawings.HealthBarBG.Color = Color3.new(0, 0, 0)
    v1.Drawings.HealthBarBG.Thickness = 1
    v1.Drawings.HealthBarBG.Filled = true

    v1.Drawings.HealthBar = Drawing.new("Square")
    v1.Drawings.HealthBar.Visible = false
    v1.Drawings.HealthBar.Color = Color3.new(0, 1, 0)
    v1.Drawings.HealthBar.Thickness = 1
    v1.Drawings.HealthBar.Filled = true

    v1.Drawings.HealthText = Drawing.new("Text")
    v1.Drawings.HealthText.Visible = false
    v1.Drawings.HealthText.Center = true
    v1.Drawings.HealthText.Outline = true
    v1.Drawings.HealthText.Color = Color3.new(1, 1, 1)
    v1.Drawings.HealthText.Size = 11
    v1.Drawings.HealthText.Font = 2

    v1.Drawings.Tool = Drawing.new("Text")
    v1.Drawings.Tool.Visible = false
    v1.Drawings.Tool.Center = true
    v1.Drawings.Tool.Outline = true
    v1.Drawings.Tool.Color = Color3.new(1, 0.5, 0)
    v1.Drawings.Tool.Size = 12
    v1.Drawings.Tool.Font = 2


    v1.Drawings.Skeleton = {}
    for i = 1, 14 do
        local sl = Drawing.new("Line")
        sl.Visible = false
        sl.Color = Color3.new(1,1,1)
        sl.Thickness = 1
        v1.Drawings.Skeleton[i] = sl
    end


    v1.Drawings.ChinaHatDrawings = {}
    for _ = 1, 25 do
        local tri  = Drawing.new("Triangle")
        tri.Filled = true
        tri.ZIndex = 1
        tri.Visible = false
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.ZIndex = 2
        line.Visible = false
        table.insert(v1.Drawings.ChinaHatDrawings, {line, tri})
    end


    v1.Drawings.Ping = Drawing.new("Text")
    v1.Drawings.Ping.Visible = false
    v1.Drawings.Ping.Center = true
    v1.Drawings.Ping.Outline = true
    v1.Drawings.Ping.Color = Color3.new(0.4,1,0.4)
    v1.Drawings.Ping.Size = 11
    v1.Drawings.Ping.Font = 2

    v.ESPObjects[player] = v1
end

local function RemoveESP(player)
    local v1 = v.ESPObjects[player]
    if v1 then
        for k, v2 in pairs(v1.Drawings) do
            if k == "Skeleton" then
                for _, sl in ipairs(v2) do if sl then sl:Remove() end end
            elseif k == "ChinaHatDrawings" then
                for _, pair in ipairs(v2) do
                    if pair[1] then pair[1]:Remove() end
                    if pair[2] then pair[2]:Remove() end
                end
            elseif v2 then
                v2:Remove()
            end
        end
        for _, v2 in pairs(v1.Connections) do
            v2:Disconnect()
        end
        v.ESPObjects[player] = nil
    end
end

local function IsOnSameTeam(player)
    if not Player.Team or not player.Team then return false end
    return Player.Team == player.Team
end

local function UpdateESP()
    if not Toggles.espenabled.Value then
        for _, v1 in pairs(v.ESPObjects) do
            for _, v2 in pairs(v1.Drawings) do
                if v2 then v2.Visible = false end
            end
        end
        return
    end

    local v2 = Color3.new(1, 1, 1)
    if Toggles.rainbowesp.Value then
        v2 = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end

    for _, v3 in ipairs(Players:GetPlayers()) do
        if v3 == Player and not Toggles.selfesp.Value then continue end

        if Toggles.espwhitelist and Toggles.espwhitelist.Value then
            local isWhitelisted = false
            for _, wName in pairs(v.ESPWhitelistedPlayers) do
                if v3.Name == wName then
                    isWhitelisted = true
                    break
                end
            end
            if isWhitelisted then
                local v1 = v.ESPObjects[v3]
                if v1 then
                    for _, v8 in pairs(v1.Drawings) do
                        if v8 then v8.Visible = false end
                    end
                end
                continue
            end
        end

        local v28 = IsOnSameTeam(v3)
        if v28 and not Toggles.teamesp.Value then
            local v1 = v.ESPObjects[v3]
            if v1 then
                for _, v8 in pairs(v1.Drawings) do
                    if v8 then v8.Visible = false end
                end
            end
            continue
        end

        local v1 = v.ESPObjects[v3]
        if not v1 then
            CreateESP(v3)
            v1 = v.ESPObjects[v3]
        end
        if not v1 then continue end

        local v4 = v3.Character
        local v5 = v4 and v4:FindFirstChild("HumanoidRootPart")
        local v6 = v4 and v4:FindFirstChild("Head")
        local v7 = v4 and v4:FindFirstChildOfClass("Humanoid")

        local function hideAll()
            for k, v8 in pairs(v1.Drawings) do
                if k == "Skeleton" then
                    for _, sl in ipairs(v8) do sl.Visible = false end
                elseif k == "ChinaHatDrawings" then
                    for _, pair in ipairs(v8) do
                        if pair[1] then pair[1].Visible = false end
                        if pair[2] then pair[2].Visible = false end
                    end
                elseif v8 then
                    v8.Visible = false
                end
            end
        end

        if not (v5 and v6 and v7 and v7.Health > 0) then
            hideAll() continue
        end

        local v9, v10 = Camera:WorldToViewportPoint(v5.Position)
        if not v10 then

        end

        local v11 = Camera:WorldToViewportPoint(v6.Position + Vector3.new(0, 0.5, 0))
        local v12 = Camera:WorldToViewportPoint(v5.Position - Vector3.new(0, 3, 0))
        local v13 = (Vector2.new(v11.X, v11.Y) - Vector2.new(v12.X, v12.Y)).Magnitude
        local v14 = Vector2.new(v13 * 0.9, v13)
        local v15 = Vector2.new(v9.X - v14.X / 2, v9.Y - v14.Y / 2)
        local v16 = (GetRootPart().Position - v5.Position).Magnitude

        if Toggles.espdistancelimit.Value then
            local maxDist = tonumber(Options.espmaxdistance.Value) or 500
            if v16 > maxDist then
                for _, v8 in pairs(v1.Drawings) do
                    if v8 then v8.Visible = false end
                end
                continue
            end
        end

        if Toggles.rainbowesp.Value then
            v1.Drawings.Box.Color = v2
            v1.Drawings.Name.Color = v2
            v1.Drawings.Distance.Color = v2
            v1.Drawings.Tracer.Color = v2
            v1.Drawings.TracerOutline.Color = v2
            v1.Drawings.Username.Color = v2
            v1.Drawings.HealthText.Color = v2
            v1.Drawings.Tool.Color = v2
        else
            local isTeam = IsOnSameTeam(v3)
            if isTeam and Toggles.teamcolorsenabled and Toggles.teamcolorsenabled.Value then
                v1.Drawings.Box.Color = Options.teamboxcolor.Value
                v1.Drawings.Name.Color = Options.teamnamecolor.Value
                v1.Drawings.Distance.Color = Options.teamdistancecolor.Value
                v1.Drawings.Tracer.Color = Options.teamtracercolor.Value
                v1.Drawings.TracerOutline.Color = Options.traceroutlinecolor.Value
                v1.Drawings.Username.Color = Options.teamusernamecolor.Value
                v1.Drawings.HealthText.Color = Options.healthtextcolor.Value
                v1.Drawings.Tool.Color = Options.teamtoolcolor.Value
            elseif not isTeam and Toggles.enemycolorsenabled and Toggles.enemycolorsenabled.Value then
                v1.Drawings.Box.Color = Options.enemyboxcolor.Value
                v1.Drawings.Name.Color = Options.enemynamecolor.Value
                v1.Drawings.Distance.Color = Options.enemydistancecolor.Value
                v1.Drawings.Tracer.Color = Options.enemytracercolor.Value
                v1.Drawings.TracerOutline.Color = Options.traceroutlinecolor.Value
                v1.Drawings.Username.Color = Options.enemyusernamecolor.Value
                v1.Drawings.HealthText.Color = Options.healthtextcolor.Value
                v1.Drawings.Tool.Color = Options.enemytoolcolor.Value
            else
                v1.Drawings.Box.Color = Options.boxcolor.Value
                v1.Drawings.Name.Color = Options.namecolor.Value
                v1.Drawings.Distance.Color = Options.distancecolor.Value
                v1.Drawings.Tracer.Color = Options.tracercolor.Value
                v1.Drawings.TracerOutline.Color = Options.traceroutlinecolor.Value
                v1.Drawings.Username.Color = Options.usernamecolor.Value
                v1.Drawings.HealthText.Color = Options.healthtextcolor.Value
                v1.Drawings.Tool.Color = Options.toolcolor.Value
            end
        end

        v1.Drawings.Box.Visible = Toggles.espbox.Value
        if Toggles.espbox.Value then
            v1.Drawings.Box.Size = v14
            v1.Drawings.Box.Position = v15
        end

        v1.Drawings.BoxFill.Visible = Toggles.espboxfill and Toggles.espboxfill.Value
        if Toggles.espboxfill and Toggles.espboxfill.Value then
            v1.Drawings.BoxFill.Size = v14
            v1.Drawings.BoxFill.Position = v15
            v1.Drawings.BoxFill.Color = Options.boxfillcolor and Options.boxfillcolor.Value or Color3.new(1,1,1)
        end

        local v17 = Options.nameplacement.Value == "up" and -16 or v14.Y + 2
        local v18 = Options.nameplacement.Value == "up" and -28 or v14.Y + 14

        v1.Drawings.Name.Visible = Toggles.espname.Value
        if Toggles.espname.Value then
            v1.Drawings.Name.Text = v3.DisplayName
            v1.Drawings.Name.Position = Vector2.new(v9.X, v15.Y + v17)
            v1.Drawings.Name.Size = Options.esptextsize.Value
        end

        v1.Drawings.Username.Visible = Toggles.espusername.Value
        if Toggles.espusername.Value then
            v1.Drawings.Username.Text = "@" .. v3.Name
            v1.Drawings.Username.Position = Vector2.new(v9.X, v15.Y + v18)
            v1.Drawings.Username.Size = Options.esptextsize.Value
        end

        v1.Drawings.Distance.Visible = Toggles.espdistance.Value
        if Toggles.espdistance.Value then
            v1.Drawings.Distance.Text = string.format("%.0fm", v16)
            v1.Drawings.Distance.Position = Vector2.new(v9.X, v15.Y + v14.Y + 2)
            v1.Drawings.Distance.Size = Options.esptextsize.Value
        end

        v1.Drawings.Tool.Visible = Toggles.esptool.Value
        if Toggles.esptool.Value then
            local v19 = v4:FindFirstChildOfClass("Tool")
            if v19 then
                v1.Drawings.Tool.Text = v19.Name
                v1.Drawings.Tool.Position = Vector2.new(v9.X, v15.Y + v14.Y + 16)
                v1.Drawings.Tool.Size = Options.esptextsize.Value
            else
                v1.Drawings.Tool.Visible = false
            end
        end

        v1.Drawings.Tracer.Visible = Toggles.esptracers.Value
        v1.Drawings.TracerOutline.Visible = Toggles.esptracers.Value
        if Toggles.esptracers.Value then
            local v20 = Options.tracermode.Value
            local v21
            if v20 == "Bottom" then
                v21 = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            elseif v20 == "Mouse" then
                local v22 = UserInputService:GetMouseLocation()
                v21 = Vector2.new(v22.X, v22.Y)
            elseif v20 == "Top" then
                v21 = Vector2.new(Camera.ViewportSize.X / 2, 0)
            elseif v20 == "Center" then
                v21 = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            end

            v1.Drawings.TracerOutline.From = v21
            v1.Drawings.TracerOutline.To = Vector2.new(v9.X, v9.Y)
            v1.Drawings.Tracer.From = v21
            v1.Drawings.Tracer.To = Vector2.new(v9.X, v9.Y)
        end

        if Toggles.esphealth.Value then
            local v23 = v7.Health / v7.MaxHealth
            local v24 = v14.Y * v23
            v1.Drawings.HealthBarBG.Visible = true
            v1.Drawings.HealthBar.Visible = true
            v1.Drawings.HealthText.Visible = true
            v1.Drawings.HealthBarBG.Size = Vector2.new(3, v14.Y)
            v1.Drawings.HealthBarBG.Position = Vector2.new(v15.X - 5, v15.Y)
            v1.Drawings.HealthBar.Size = Vector2.new(3, v24)
            v1.Drawings.HealthBar.Position = Vector2.new(v15.X - 5, v15.Y + (v14.Y - v24))
            local isTeam = IsOnSameTeam(v3)
            if Toggles.rainbowesp.Value then
                v1.Drawings.HealthBar.Color = v2
            elseif isTeam and Toggles.teamcolorsenabled and Toggles.teamcolorsenabled.Value then
                v1.Drawings.HealthBar.Color = Options.teamhealthbarcolor.Value
            elseif not isTeam and Toggles.enemycolorsenabled and Toggles.enemycolorsenabled.Value then
                v1.Drawings.HealthBar.Color = Options.enemyhealthbarcolor.Value
            else
                v1.Drawings.HealthBar.Color = Options.healthbarcolor.Value
            end
            v1.Drawings.HealthText.Text = math.floor(v7.Health)
            v1.Drawings.HealthText.Position = Vector2.new(v15.X - 3, v15.Y - 12)
            v1.Drawings.HealthText.Size = Options.esptextsize.Value
        else
            v1.Drawings.HealthBarBG.Visible = false
            v1.Drawings.HealthBar.Visible = false
            v1.Drawings.HealthText.Visible = false
        end


        local headSP = Camera:WorldToViewportPoint(v6.Position)

        local skelVisible = Toggles.espskeleton and Toggles.espskeleton.Value and v10
        local skelColor = Options.skeletoncolor and Options.skeletoncolor.Value or Color3.new(1,1,1)

        local bonePairs = {
            {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
            {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
            {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
            {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
            {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        }
        for i, pair in ipairs(bonePairs) do
            local sl = v1.Drawings.Skeleton[i]
            if sl then
                local pA = v4:FindFirstChild(pair[1])
                local pB = v4:FindFirstChild(pair[2])
                if skelVisible and pA and pB then
                    local spA = Camera:WorldToViewportPoint(pA.Position)
                    local spB = Camera:WorldToViewportPoint(pB.Position)
                    sl.From = Vector2.new(spA.X, spA.Y)
                    sl.To   = Vector2.new(spB.X, spB.Y)
                    sl.Color = Toggles.rainbowesp and Toggles.rainbowesp.Value and v2 or skelColor
                    sl.Visible = true
                else
                    sl.Visible = false
                end
            end
        end


        do
            local hatEnabled = Toggles.espchinhat and Toggles.espchinhat.Value
            local hatDrawings = v1.Drawings.ChinaHatDrawings
            if hatEnabled and v10 then
                local sides   = 25
                local hatH    = 0.7
                local hatR    = 2
                local hatOY   = 0.5
                local hatTrs  = 0.35
                local fullC   = math.pi * 2
                local hatCol  = Toggles.rainbowesp and Toggles.rainbowesp.Value and v2 or (Options.chinahatcolor and Options.chinahatcolor.Value or Color3.fromRGB(255,80,80))
                local headPos = v6.Position
                local topPos  = headPos + Vector3.new(0, hatOY + hatH, 0)
                local basePos = headPos + Vector3.new(0, hatOY, 0)
                for i = 1, sides do
                    local pair = hatDrawings[i]
                    local a1   = (i / sides) * fullC
                    local a2   = ((i % sides + 1) / sides) * fullC
                    local p1   = basePos + Vector3.new(math.cos(a1),0,math.sin(a1)) * hatR
                    local p2   = basePos + Vector3.new(math.cos(a2),0,math.sin(a2)) * hatR
                    local sp1  = Camera:WorldToViewportPoint(p1)
                    local sp2  = Camera:WorldToViewportPoint(p2)
                    local spTop = Camera:WorldToViewportPoint(topPos)
                    pair[1].From  = Vector2.new(sp1.X, sp1.Y)
                    pair[1].To    = Vector2.new(sp2.X, sp2.Y)
                    pair[1].Color = hatCol
                    pair[1].Visible = true
                    pair[2].PointA = Vector2.new(spTop.X, spTop.Y)
                    pair[2].PointB = Vector2.new(sp1.X, sp1.Y)
                    pair[2].PointC = Vector2.new(sp2.X, sp2.Y)
                    pair[2].Color  = hatCol
                    pair[2].Transparency = hatTrs
                    pair[2].Visible = true
                end
            else
                for _, pair in ipairs(v1.Drawings.ChinaHatDrawings) do
                    if pair[1] then pair[1].Visible = false end
                    if pair[2] then pair[2].Visible = false end
                end
            end
        end


        v1.Drawings.Ping.Visible = Toggles.espping and Toggles.espping.Value and v10
        if Toggles.espping and Toggles.espping.Value and v10 then
            local ping = math.floor(v3:GetNetworkPing() * 1000)
            local pingCol = ping < 80 and Color3.new(0.3,1,0.3) or ping < 150 and Color3.new(1,1,0.2) or Color3.new(1,0.3,0.3)
            v1.Drawings.Ping.Text = ping .. "ms"
            v1.Drawings.Ping.Position = Vector2.new(v15.X + v14.X + 6, v15.Y + v14.Y - 11)
            v1.Drawings.Ping.Color = Toggles.rainbowesp and Toggles.rainbowesp.Value and v2 or pingCol
            v1.Drawings.Ping.Size = Options.esptextsize and Options.esptextsize.Value or 11
        end


        if not v10 then
            for k, v8 in pairs(v1.Drawings) do
                if k == "Skeleton" then for _, sl in ipairs(v8) do sl.Visible = false end
                elseif k == "ChinaHatDrawings" then
                    for _, pair in ipairs(v8) do
                        if pair[1] then pair[1].Visible = false end
                        if pair[2] then pair[2].Visible = false end
                    end
                elseif v8 then v8.Visible = false end
            end
        end
    end
end

local v25, v26, v27 = {}, {}, 0
v.crosshairCurrentPos = Vector2.new(0, 0)
v.crosshairDot = nil
v.scriptNameLabel = nil
v.crosshairPulseTime = 0

local function InitializeCrosshair()
    for i = 1, 4 do
        local v1 = Drawing.new("Line")
        v1.Visible = false
        v1.Color = Color3.new(0, 0, 0)
        v1.Thickness = 4
        v26[i] = v1

        local v2 = Drawing.new("Line")
        v2.Visible = false
        v2.Color = Color3.new(1, 1, 1)
        v2.Thickness = 2
        v25[i] = v2
    end

    v.crosshairDot = Drawing.new("Circle")
    v.crosshairDot.Visible = false
    v.crosshairDot.Filled = true
    v.crosshairDot.Radius = 3
    v.crosshairDot.Color = Color3.new(1, 1, 1)
    v.crosshairDot.Thickness = 1

    v.scriptNameLabel = Drawing.new("Text")
    v.scriptNameLabel.Visible = false
    v.scriptNameLabel.Text = "Cosmical"
    v.scriptNameLabel.Size = 16
    v.scriptNameLabel.Center = true
    v.scriptNameLabel.Outline = true
    v.scriptNameLabel.Color = Color3.new(1, 1, 1)
end

local function UpdateCrosshair()
    if not Toggles.crosshairenabled or not Toggles.crosshairenabled.Value then
        for _, v1 in ipairs(v25) do v1.Visible = false end
        for _, v1 in ipairs(v26) do v1.Visible = false end
        if v.crosshairDot then v.crosshairDot.Visible = false end
        if v.scriptNameLabel then v.scriptNameLabel.Visible = false end
        return
    end

    local targetPos

    if Toggles.crosshairontarget and Toggles.crosshairontarget.Value then
        local aimTarget = nil

        if States.StickyAimEnabled and States.StickyAimTarget and States.StickyAimTarget.Character then
            aimTarget = States.StickyAimTarget
        elseif States.SilentAimEnabled and States.SilentAimTarget and States.SilentAimTarget.Character then
            aimTarget = States.SilentAimTarget
        end

        if aimTarget then
            local head = aimTarget.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    targetPos = Vector2.new(screenPos.X, screenPos.Y)
                end
            end
        end
    end

    if not targetPos then
        if Toggles.crosshairfollowmouse and Toggles.crosshairfollowmouse.Value then
            targetPos = UserInputService:GetMouseLocation()
        else
            local screenSize = Camera.ViewportSize
            targetPos = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
        end
    end

    local lerpSpeed = Options.crosshairlerp and Options.crosshairlerp.Value or 1
    v.crosshairCurrentPos = v.crosshairCurrentPos:Lerp(targetPos, lerpSpeed)

    local v1 = v.crosshairCurrentPos
    local v2 = Options.crosshairlength.Value
    local v28 = Options.crosshairgap and Options.crosshairgap.Value or 5
    local v3 = Color3.new(1, 1, 1)

    if Toggles.crosshairrainbow and Toggles.crosshairrainbow.Value then
        v3 = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end

    if Toggles.crosshairrotate and Toggles.crosshairrotate.Value then
        v27 = v27 + (Options.crosshairrotatespeed.Value * 0.1)
        if v27 >= 360 then v27 = 0 end
    end


    local pulseGap = v28
    if Toggles.crosshairpulse and Toggles.crosshairpulse.Value then
        v.crosshairPulseTime = v.crosshairPulseTime + (Options.crosshairpulsespeed.Value * 0.01)
        local bounce = math.sin(v.crosshairPulseTime) * 4
        pulseGap = v28 + bounce
    end

    local v4 = math.rad(v27)
    local v5 = {
        {
            start = Vector2.new(v1.X + math.sin(v4) * pulseGap, v1.Y - math.cos(v4) * pulseGap),
            endPos = Vector2.new(v1.X + math.sin(v4) * (pulseGap + v2), v1.Y - math.cos(v4) * (pulseGap + v2))
        },
        {
            start = Vector2.new(v1.X - math.sin(v4) * pulseGap, v1.Y + math.cos(v4) * pulseGap),
            endPos = Vector2.new(v1.X - math.sin(v4) * (pulseGap + v2), v1.Y + math.cos(v4) * (pulseGap + v2))
        },
        {
            start = Vector2.new(v1.X - math.cos(v4) * pulseGap, v1.Y - math.sin(v4) * pulseGap),
            endPos = Vector2.new(v1.X - math.cos(v4) * (pulseGap + v2), v1.Y - math.sin(v4) * (pulseGap + v2))
        },
        {
            start = Vector2.new(v1.X + math.cos(v4) * pulseGap, v1.Y + math.sin(v4) * pulseGap),
            endPos = Vector2.new(v1.X + math.cos(v4) * (pulseGap + v2), v1.Y + math.sin(v4) * (pulseGap + v2))
        }
    }

    local lineColors = {
        Options.crosshairline1color and Options.crosshairline1color.Value or Color3.new(1, 1, 1),
        Options.crosshairline2color and Options.crosshairline2color.Value or Color3.new(1, 1, 1),
        Options.crosshairline3color and Options.crosshairline3color.Value or Color3.new(1, 1, 1),
        Options.crosshairline4color and Options.crosshairline4color.Value or Color3.new(1, 1, 1)
    }

    local outlineColors = {
        Options.crosshairline1outline and Options.crosshairline1outline.Value or Color3.new(0, 0, 0),
        Options.crosshairline2outline and Options.crosshairline2outline.Value or Color3.new(0, 0, 0),
        Options.crosshairline3outline and Options.crosshairline3outline.Value or Color3.new(0, 0, 0),
        Options.crosshairline4outline and Options.crosshairline4outline.Value or Color3.new(0, 0, 0)
    }

    for i = 1, 4 do
        v26[i].From = v5[i].start
        v26[i].To = v5[i].endPos
        v26[i].Visible = true
        v26[i].Color = outlineColors[i]
        v26[i].Thickness = Options.crosshairthickness.Value + 2

        v25[i].From = v5[i].start
        v25[i].To = v5[i].endPos
        v25[i].Visible = true
        v25[i].Color = Toggles.crosshairrainbow and Toggles.crosshairrainbow.Value and v3 or lineColors[i]
        v25[i].Thickness = Options.crosshairthickness.Value
    end


    if v.crosshairDot then
        if Toggles.crosshairdot and Toggles.crosshairdot.Value then
            v.crosshairDot.Position = v1
            v.crosshairDot.Visible = true
            if Toggles.crosshairrainbow and Toggles.crosshairrainbow.Value then
                v.crosshairDot.Color = v3
            else
                v.crosshairDot.Color = Options.crosshairdotcolor and Options.crosshairdotcolor.Value or Color3.new(1, 1, 1)
            end
        else
            v.crosshairDot.Visible = false
        end
    end


    if v.scriptNameLabel then
        if Toggles.crosshairscriptname and Toggles.crosshairscriptname.Value then
            v.scriptNameLabel.Position = Vector2.new(v1.X, v1.Y + 20)
            v.scriptNameLabel.Visible = true
            if Toggles.crosshairrainbow and Toggles.crosshairrainbow.Value then
                v.scriptNameLabel.Color = v3
            else
                v.scriptNameLabel.Color = Options.crosshairscriptnamecolor and Options.crosshairscriptnamecolor.Value or Color3.new(1, 1, 1)
            end
        else
            v.scriptNameLabel.Visible = false
        end
    end
end

InitializeCrosshair()

v.VisualsLeft:AddToggle("espenabled", {
    Text = "enabled",
    Default = false,
    Tooltip = "if off, no esp do anything"
})

Toggles.espenabled:OnChanged(function()
    if Toggles.espenabled.Value then
        for _, v1 in pairs(Players:GetPlayers()) do
            if v1 == Player and Toggles.selfesp.Value then
                CreateESP(v1)
            elseif v1 ~= Player then
                CreateESP(v1)
            end
        end
    else
        for v1, v2 in pairs(v.ESPObjects) do
            for _, v3 in pairs(v2.Drawings) do
                if v3 then v3.Visible = false end
            end
        end
        task.wait(0.1)
        for v1, _ in pairs(v.ESPObjects) do
            RemoveESP(v1)
        end
    end
end)

v.VisualsLeft:AddToggle("selfesp", {
    Text = "self",
    Default = false,
    Tooltip = "show self esp (enable the first toggle and esp)"
})

Toggles.selfesp:OnChanged(function()
    if Toggles.espenabled.Value then
        if Toggles.selfesp.Value then
            CreateESP(Player)
        else
            RemoveESP(Player)
        end
    end
end)

v.VisualsLeft:AddToggle("teamesp", {
    Text = "team esp",
    Default = false,
    Tooltip = "show esp on teammates (off = no teammates shown)"
})

v.VisualsLeft:AddToggle("rainbowesp", {
    Text = "rainbow",
    Default = false,
    Tooltip = "makes every esp color rainbow"
})

v.VisualsLeft:AddToggle("espwhitelist", {
    Text = "esp whitelist",
    Default = false,
    Tooltip = "hide esp for selected players"
})

v.VisualsLeft:AddDropdown("espwhitelistplayers", {
    Values = GetAllPlayerNames(),
    Default = 1,
    Multi = true,
    Text = "select players",
    Tooltip = "selected players wont have esp shown",
    Callback = function(Value)
        v.ESPWhitelistedPlayers = {}
        if type(Value) == "table" then
            for name, selected in pairs(Value) do
                if selected == true then
                    table.insert(v.ESPWhitelistedPlayers, name)
                end
            end
        end
    end
})

v.VisualsLeft:AddButton({
    Text = 'refresh esp whitelist',
    Func = function()
        if Options.espwhitelistplayers then
            Options.espwhitelistplayers:SetValues(GetAllPlayerNames())
            Library:Notify('esp whitelist refreshed')
        end
    end,
})

v.VisualsLeft:AddToggle("espname", { Text = "name", Default = false }):AddColorPicker("namecolor", {
    Default = Color3.new(1, 1, 1)
})
v.VisualsLeft:AddToggle("espbox", { Text = "box", Default = false }):AddColorPicker("boxcolor", {
    Default = Color3.new(1, 1, 1)
})
v.VisualsLeft:AddToggle("espboxfill", { Text = "fill", Default = false, Tooltip = "fills the esp box" }):AddColorPicker("boxfillcolor", {
    Default = Color3.new(1, 1, 1)
})
v.VisualsLeft:AddToggle("esptracers", { Text = "tracers", Default = false }):AddColorPicker("tracercolor", {
    Default = Color3.new(1, 1, 1)
}):AddColorPicker("traceroutlinecolor", {
    Default = Color3.new(1, 1, 1)
})
v.VisualsLeft:AddToggle("espdistance", { Text = "distance", Default = false }):AddColorPicker("distancecolor", {
    Default = Color3.new(1, 1, 1)
})
v.VisualsLeft:AddToggle("esptool", { Text = "tool held", Default = false }):AddColorPicker("toolcolor", {
    Default = Color3.new(1, 1, 1)
})
v.VisualsLeft:AddToggle("esptoolforcefield", {
    Text = "tool forcefield",
    Default = false,
    Tooltip = "makes tools held by players look like forcefield"
}):AddColorPicker("esptoolforcefieldcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "tool forcefield color"
})
v.VisualsLeft:AddToggle("espaura", {
    Text = "aura",
    Default = false,
    Tooltip = "puts the same aura u chose on other players"
}):AddColorPicker("espauracolor", {
    Default = Color3.new(1, 1, 1),
    Title = "aura color"
})

v.VisualsLeft:AddToggle("espusername", { Text = "username", Default = false }):AddColorPicker("usernamecolor", {
    Default = Color3.new(1, 1, 1)
})

v.VisualsLeft:AddToggle("espskeleton", {
    Text = "skeleton",
    Default = false,
    Tooltip = "draws bone lines over the player"
}):AddColorPicker("skeletoncolor", {
    Default = Color3.new(1, 1, 1),
    Title = "skeleton color"
})

v.VisualsLeft:AddToggle("espchinhat", {
    Text = "samurai hat",
    Default = false,
    Tooltip = "renders a conical hat above the player's head"
}):AddColorPicker("chinahatcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "samurai hat color"
})

v.VisualsLeft:AddToggle("espping", {
    Text = "ping",
    Default = false,
    Tooltip = "shows player ping — green <80ms, yellow <150ms, red 150ms+"
})
v.VisualsLeft:AddToggle("esphealth", { Text = "health", Default = false }):AddColorPicker("healthbarcolor", {
    Default = Color3.new(1, 1, 1)
}):AddColorPicker("healthtextcolor", {
    Default = Color3.new(1, 1, 1)
})

v.VisualsLeft:AddToggle("espforcefield", {
    Text = "forcefield",
    Default = false,
    Tooltip = "makes other players look like forcefield"
}):AddColorPicker("espforcefieldcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "forcefield color"
})

v.espForcefieldParts = {}
v.espForcefieldCharacters = {}

local function ApplyForcefieldToCharacter(plr, char)
    if not char then return end
    v.espForcefieldParts[plr] = {}
    v.espForcefieldCharacters[plr] = char

    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
            pcall(function() obj.Transparency = 1 end)
        end
    end

    char.DescendantAdded:Connect(function(obj)
        if not Toggles.espforcefield or not Toggles.espforcefield.Value then return end
        if v.espForcefieldCharacters[plr] ~= char then return end
        if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
            pcall(function() obj.Transparency = 1 end)
        end
        if obj:IsA("BasePart") then
            v.espForcefieldParts[plr][obj] = {Material = obj.Material, Color = obj.Color}
            obj.Material = Enum.Material.ForceField
            obj.Color = Options.espforcefieldcolor.Value
        end
    end)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            v.espForcefieldParts[plr][part] = {Material = part.Material, Color = part.Color}
            part.Material = Enum.Material.ForceField
            part.Color = Options.espforcefieldcolor.Value
        end
    end
end

local function RestoreForcefieldForPlayer(plr)
    if v.espForcefieldParts[plr] then
        for part, original in pairs(v.espForcefieldParts[plr]) do
            if part and part.Parent then
                part.Material = original.Material
                part.Color = original.Color
            end
        end
        v.espForcefieldParts[plr] = nil
        v.espForcefieldCharacters[plr] = nil
    end
end

Toggles.espforcefield:OnChanged(function()
    if not Toggles.espforcefield.Value then
        for plr, _ in pairs(v.espForcefieldParts) do
            RestoreForcefieldForPlayer(plr)
        end
        v.espForcefieldParts = {}
        v.espForcefieldCharacters = {}
    end
end)

Options.espforcefieldcolor:OnChanged(function()
    if Toggles.espforcefield.Value then
        for player, parts in pairs(v.espForcefieldParts) do
            for part, _ in pairs(parts) do
                if part and part.Parent then
                    part.Color = Options.espforcefieldcolor.Value
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not Toggles.espforcefield or not Toggles.espforcefield.Value then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player then
            local char = plr.Character
            if char then

                if v.espForcefieldCharacters[plr] ~= char then
                    ApplyForcefieldToCharacter(plr, char)
                else

                    if Toggles.rainbowesp and Toggles.rainbowesp.Value then
                        local rainbowColor = Color3.fromHSV((tick() * 0.5) % 1, 1, 1)
                        for part, _ in pairs(v.espForcefieldParts[plr] or {}) do
                            if part and part.Parent then
                                part.Color = rainbowColor
                            end
                        end
                    else
                        for part, _ in pairs(v.espForcefieldParts[plr] or {}) do
                            if part and part.Parent then
                                part.Color = Options.espforcefieldcolor.Value
                            end
                        end
                    end
                end
            end

        end
    end
end)


v.espToolForcefieldParts = {}
RunService.Heartbeat:Connect(function()
    if not Toggles.esptoolforcefield or not Toggles.esptoolforcefield.Value then
        for plr, parts in pairs(v.espToolForcefieldParts) do
            for part, original in pairs(parts) do
                if part and part.Parent then
                    part.Material = original.Material
                    part.Color = original.Color
                end
            end
        end
        v.espToolForcefieldParts = {}
        return
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local char = plr.Character

            local toolParts = {}
            for _, obj in pairs(char:GetChildren()) do
                if obj:IsA("Tool") then
                    for _, part in pairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then
                            table.insert(toolParts, part)
                        end
                    end
                end
            end
            if not v.espToolForcefieldParts[plr] then v.espToolForcefieldParts[plr] = {} end

            for _, part in pairs(toolParts) do
                if not v.espToolForcefieldParts[plr][part] then
                    v.espToolForcefieldParts[plr][part] = {Material = part.Material, Color = part.Color}
                    part.Material = Enum.Material.ForceField
                    part.Color = Options.esptoolforcefieldcolor and Options.esptoolforcefieldcolor.Value or Color3.new(1,1,1)
                end
            end

            for part, original in pairs(v.espToolForcefieldParts[plr]) do
                local stillTool = false
                for _, tp in pairs(toolParts) do if tp == part then stillTool = true break end end
                if not stillTool or not part.Parent then
                    if part and part.Parent then
                        part.Material = original.Material
                        part.Color = original.Color
                    end
                    v.espToolForcefieldParts[plr][part] = nil
                end
            end
        end
    end
end)



local function MakeEmitter(att, props)
    local e = Instance.new("ParticleEmitter")
    e.LockedToPart    = true
    e.LightEmission   = props.le   or 1
    e.Brightness      = props.br   or 10
    e.Rate            = props.rate or 20
    e.Texture         = props.tex  or "rbxassetid://8047533775"
    e.Lifetime        = NumberRange.new(props.lt or 1.5, props.lt or 1.5)
    e.Speed           = NumberRange.new(props.spd or 3, (props.spd or 3) + (props.spdR or 4))
    e.SpreadAngle     = props.spread or Vector2.new(180, -180)
    e.VelocitySpread  = props.vs   or 180
    e.Size            = props.size or NumberSequence.new(1)
    e.Color           = props.col  or ColorSequence.new(Color3.new(1,1,1))
    e.Acceleration    = props.accel or Vector3.new(0, 3, 0)
    e.ZOffset         = props.z    or 0
    e.Drag            = props.drag or 0
    e.RotSpeed        = props.rotS or NumberRange.new(-200, 200)
    e.Rotation        = props.rot  or NumberRange.new(-180, 180)
    e.Orientation     = props.ori  or Enum.ParticleOrientation.VelocityPerpendicular
    e.Parent          = att
    return e
end

local AuraTypes = {}

AuraTypes["Skibidi RedRizz"] = function(att, col)
    local cs = ColorSequence.new(col)
    MakeEmitter(att, { tex="rbxassetid://8047533775", col=cs, rate=20, spd=3, spdR=3, lt=1.5, le=0.4, br=10, z=0,
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,3.0624998,1.8805969),NumberSequenceKeypoint.new(0.642,1.9999999,1.762),NumberSequenceKeypoint.new(1,0.75,0.75)}) })
    MakeEmitter(att, { tex="rbxassetid://8047796070", col=cs, rate=20, spd=3, spdR=2, lt=1.5, le=1, br=10, z=0,
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,3.125),NumberSequenceKeypoint.new(0.416,1.375,1.375),NumberSequenceKeypoint.new(1,0.9375,0.9375)}) })
    MakeEmitter(att, { tex="rbxassetid://8611887361", col=cs, rate=40, spd=5, spdR=10, lt=1, le=1, br=10, z=-1,
        drag=3, vs=180, accel=Vector3.new(0,3,0), ori=Enum.ParticleOrientation.VelocityParallel,
        rotS=NumberRange.new(-30,30), rot=NumberRange.new(-30,30),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.147,0.437,0.188),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8611887703", col=cs, rate=25, spd=5, spdR=5, lt=1.5, le=1, br=10, z=2,
        drag=3, vs=180, accel=Vector3.new(0,3,0),
        rotS=NumberRange.new(-30,30), rot=NumberRange.new(-30,30),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.149,0.687,0.687),NumberSequenceKeypoint.new(1,0)}) })
end

AuraTypes["Inferno"] = function(att, col)
    local cs = ColorSequence.new(col)
    MakeEmitter(att, { tex="rbxassetid://1266170274", col=cs, rate=50, spd=4, spdR=4, lt=1.2, le=0.8, br=8, z=0,
        spread=Vector2.new(15,-15), vs=15, accel=Vector3.new(0,8,0),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,2.5,0.5),NumberSequenceKeypoint.new(0.5,1.5,0.5),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8611887361", col=cs, rate=60, spd=3, spdR=6, lt=0.8, le=1, br=12, z=1,
        drag=1, vs=180, accel=Vector3.new(0,12,0), ori=Enum.ParticleOrientation.VelocityParallel,
        rotS=NumberRange.new(-60,60), rot=NumberRange.new(-180,180),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.2,0.5,0.2),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8047533775", col=cs, rate=15, spd=1, spdR=2, lt=2, le=0.5, br=5, z=-1,
        spread=Vector2.new(90,-90), vs=90, accel=Vector3.new(0,2,0),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,4,1),NumberSequenceKeypoint.new(0.5,2,1),NumberSequenceKeypoint.new(1,0)}) })
end

AuraTypes["Blizzard"] = function(att, col)
    local cs = ColorSequence.new(col)
    MakeEmitter(att, { tex="rbxassetid://8047796070", col=cs, rate=35, spd=4, spdR=4, lt=2, le=0.3, br=6, z=0,
        accel=Vector3.new(0,-1,0), vs=180,
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,1.5,0.5),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8611887361", col=cs, rate=25, spd=6, spdR=6, lt=1, le=0.8, br=10, z=1,
        drag=2, vs=180, accel=Vector3.new(0,-4,0), ori=Enum.ParticleOrientation.VelocityParallel,
        rotS=NumberRange.new(-45,45),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.1,0.6,0.2),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://1266170274", col=cs, rate=15, spd=1, spdR=2, lt=3, le=0.1, br=3, z=-2,
        vs=180, accel=Vector3.new(0,0,0), drag=3,
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.4,3,1),NumberSequenceKeypoint.new(1,0)}) })
end

AuraTypes["Holy"] = function(att, col)
    local cs = ColorSequence.new(col)
    MakeEmitter(att, { tex="rbxassetid://8047533775", col=cs, rate=20, spd=2, spdR=2, lt=2.5, le=1, br=15, z=0,
        spread=Vector2.new(10,-10), vs=10, accel=Vector3.new(0,5,0),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.2,2,0.5),NumberSequenceKeypoint.new(0.8,1.5,0.5),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8611887703", col=cs, rate=30, spd=3, spdR=4, lt=2, le=1, br=15, z=2,
        drag=2, vs=180, accel=Vector3.new(0,4,0), rotS=NumberRange.new(-20,20),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.2,1.2,0.5),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8047796070", col=cs, rate=10, spd=5, spdR=2, lt=1.5, le=1, br=20, z=3,
        spread=Vector2.new(5,-5), vs=5, accel=Vector3.new(0,0,0),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(0.5,1.5,0.5),NumberSequenceKeypoint.new(1,0)}) })
end

AuraTypes["Shadow"] = function(att, col)
    local cs = ColorSequence.new(col)
    MakeEmitter(att, { tex="rbxassetid://1266170274", col=cs, rate=30, spd=2, spdR=3, lt=2, le=0.6, br=8, z=0,
        vs=180, accel=Vector3.new(0,-1,0), drag=1,
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,3,1),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8611887361", col=cs, rate=35, spd=4, spdR=4, lt=1.2, le=0.9, br=12, z=1,
        drag=0.5, vs=180, accel=Vector3.new(0,-6,0), ori=Enum.ParticleOrientation.VelocityParallel,
        rotS=NumberRange.new(-90,90),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.15,0.5,0.2),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8047533775", col=cs, rate=12, spd=3, spdR=5, lt=3, le=0.4, br=6, z=-1,
        vs=180, accel=Vector3.new(0,0,0), drag=3,
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.2,2,0.8),NumberSequenceKeypoint.new(1,0)}) })
end

AuraTypes["Thunder"] = function(att, col)
    local cs = ColorSequence.new(col)
    MakeEmitter(att, { tex="rbxassetid://8611887361", col=cs, rate=50, spd=8, spdR=8, lt=0.4, le=1, br=20, z=1,
        drag=0, vs=180, accel=Vector3.new(0,0,0), ori=Enum.ParticleOrientation.VelocityParallel,
        rotS=NumberRange.new(-180,180),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.1,0.8,0.3),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8047533775", col=cs, rate=20, spd=6, spdR=6, lt=0.6, le=1, br=25, z=0,
        vs=180, accel=Vector3.new(0,0,0),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.2,1.5,0.5),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8611887703", col=cs, rate=30, spd=10, spdR=5, lt=0.5, le=1, br=20, z=2,
        drag=1, vs=180, accel=Vector3.new(0,0,0), rotS=NumberRange.new(-180,180), rot=NumberRange.new(-180,180),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(0.3,1,0.4),NumberSequenceKeypoint.new(1,0)}) })
end

AuraTypes["Toxic"] = function(att, col)
    local cs = ColorSequence.new(col)
    MakeEmitter(att, { tex="rbxassetid://1266170274", col=cs, rate=20, spd=2, spdR=2, lt=3, le=0.5, br=6, z=-1,
        vs=180, accel=Vector3.new(0,3,0), drag=2,
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,4,1),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8047796070", col=cs, rate=25, spd=2, spdR=3, lt=2, le=0.7, br=8, z=0,
        vs=180, accel=Vector3.new(0,5,0), drag=1,
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(0.5,1,0.4),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8611887361", col=cs, rate=40, spd=3, spdR=5, lt=1, le=0.8, br=10, z=1,
        drag=0.5, vs=180, accel=Vector3.new(0,-8,0), ori=Enum.ParticleOrientation.VelocityParallel,
        rotS=NumberRange.new(-30,30),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.1,0.4,0.15),NumberSequenceKeypoint.new(1,0)}) })
end

AuraTypes["Sakura"] = function(att, col)
    local cs = ColorSequence.new(col)
    MakeEmitter(att, { tex="rbxassetid://8047796070", col=cs, rate=25, spd=2, spdR=2, lt=4, le=0.4, br=5, z=0,
        vs=180, accel=Vector3.new(0,1,0), drag=3, rotS=NumberRange.new(-80,80), rot=NumberRange.new(-180,180),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.2,1.5,0.5),NumberSequenceKeypoint.new(0.7,1,0.5),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8611887703", col=cs, rate=20, spd=2, spdR=3, lt=3, le=0.8, br=8, z=1,
        drag=2, vs=180, accel=Vector3.new(0,2,0), rotS=NumberRange.new(-40,40),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,0.8,0.4),NumberSequenceKeypoint.new(1,0)}) })
    MakeEmitter(att, { tex="rbxassetid://8047533775", col=cs, rate=10, spd=4, spdR=3, lt=2.5, le=0.3, br=4, z=-1,
        vs=180, accel=Vector3.new(0,1,0), drag=4,
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.4,2,0.8),NumberSequenceKeypoint.new(1,0)}) })
end

AuraTypes["Angelic"] = function(att, col)
    local anchor = att.Parent
    local att1 = Instance.new('Attachment')
    att1.CFrame = CFrame.new(-1.012, 0.5, 0.852, 0.966, 0, 0.259, 0, 1, 0, -0.259, 0, 0.966)
    att1.Parent = anchor
    local e1 = Instance.new('ParticleEmitter')
    e1.Lifetime = NumberRange.new(1,1); e1.LockedToPart = true
    e1.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.944),NumberSequenceKeypoint.new(0.2,0),NumberSequenceKeypoint.new(0.8,0),NumberSequenceKeypoint.new(1,1)})
    e1.LightEmission = 1; e1.Color = ColorSequence.new(col)
    e1.Speed = NumberRange.new(0.05,0.05); e1.Size = NumberSequence.new(2.75,3.5)
    e1.Rate = 4; e1.Texture = 'http://www.roblox.com/asset/?id=13267054240'
    e1.EmissionDirection = Enum.NormalId.Back
    e1.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
    e1.Rotation = NumberRange.new(-15,-15); e1.Parent = att1
    local att2 = Instance.new('Attachment')
    att2.CFrame = CFrame.new(1.167, 0.5, 0.852, 0.966, 0, -0.259, 0, 1, 0, 0.259, 0, 0.966)
    att2.Parent = anchor
    local e2 = Instance.new('ParticleEmitter')
    e2.Lifetime = NumberRange.new(1,1); e2.LockedToPart = true
    e2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.944),NumberSequenceKeypoint.new(0.2,0),NumberSequenceKeypoint.new(0.8,0),NumberSequenceKeypoint.new(1,1)})
    e2.LightEmission = 1; e2.Color = ColorSequence.new(col)
    e2.Speed = NumberRange.new(0.05,0.05); e2.Size = NumberSequence.new(2.75,3.5)
    e2.Rate = 4; e2.Texture = 'http://www.roblox.com/asset/?id=13267054240'
    e2.EmissionDirection = Enum.NormalId.Front
    e2.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
    e2.Rotation = NumberRange.new(-15,-15); e2.Parent = att2
    local att3 = Instance.new('Attachment')
    att3.CFrame = CFrame.new(0,0.3,0); att3.Parent = anchor
    local e3 = Instance.new('ParticleEmitter')
    e3.Lifetime = NumberRange.new(2,2)
    e3.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
    e3.SpreadAngle = Vector2.new(180,180); e3.LockedToPart = true
    e3.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0.3),NumberSequenceKeypoint.new(1,1)})
    e3.LightEmission = 1; e3.Color = ColorSequence.new(col)
    e3.VelocitySpread = 180; e3.Speed = NumberRange.new(0.5,0.5)
    e3.Brightness = 2; e3.Size = NumberSequence.new(3,4); e3.Rate = 5
    e3.Texture = 'rbxassetid://11402221943'
    e3.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
    e3.Rotation = NumberRange.new(0,360); e3.Parent = att3
end

AuraTypes["Ambient"] = function(att, col)
    local e1 = Instance.new('ParticleEmitter')
    e1.Lifetime = NumberRange.new(2,2); e1.SpreadAngle = Vector2.new(0.001,0.001)
    e1.LockedToPart = true; e1.Transparency = NumberSequence.new(0,1)
    e1.LightEmission = 1; e1.Color = ColorSequence.new(col)
    e1.VelocitySpread = 0.001; e1.Squash = NumberSequence.new(0)
    e1.Speed = NumberRange.new(0.001,0.001); e1.Brightness = 2
    e1.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,1),NumberSequenceKeypoint.new(0.6,2.5),NumberSequenceKeypoint.new(0.8,4),NumberSequenceKeypoint.new(1,6)})
    e1.RotSpeed = NumberRange.new(-600,600)
    e1.Texture = 'https://assetgame.roblox.com/asset/?id=12713358087&assetName=crescent'
    e1.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
    e1.Rotation = NumberRange.new(0,360); e1.Parent = att
    local e2 = Instance.new('ParticleEmitter')
    e2.Lifetime = NumberRange.new(2,2); e2.SpreadAngle = Vector2.new(0.001,0.001)
    e2.LockedToPart = true
    e2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.6,0.2),NumberSequenceKeypoint.new(1,1)})
    e2.LightEmission = 1; e2.Color = ColorSequence.new(col)
    e2.VelocitySpread = 0.001; e2.Squash = NumberSequence.new(0,2)
    e2.Speed = NumberRange.new(0.001,0.001); e2.Brightness = 2
    e2.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,1),NumberSequenceKeypoint.new(0.6,2.5),NumberSequenceKeypoint.new(0.8,4),NumberSequenceKeypoint.new(1,6)})
    e2.RotSpeed = NumberRange.new(-30,30); e2.Texture = 'rbxassetid://7216849325'
    e2.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
    e2.Rotation = NumberRange.new(0,360); e2.Parent = att
    local e3 = Instance.new('ParticleEmitter')
    e3.Lifetime = NumberRange.new(2,2); e3.SpreadAngle = Vector2.new(0.001,0.001)
    e3.LockedToPart = true
    e3.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0.3),NumberSequenceKeypoint.new(1,1)})
    e3.LightEmission = 1; e3.Color = ColorSequence.new(col)
    e3.VelocitySpread = 0.001; e3.Squash = NumberSequence.new(0)
    e3.Speed = NumberRange.new(0.001,0.001); e3.Brightness = 2
    e3.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,2),NumberSequenceKeypoint.new(0.6,5),NumberSequenceKeypoint.new(0.8,8),NumberSequenceKeypoint.new(1,12)})
    e3.RotSpeed = NumberRange.new(-40,40); e3.Texture = 'rbxassetid://7216855136'
    e3.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
    e3.Rotation = NumberRange.new(0,360); e3.Parent = att
end

AuraTypes["Halo"] = function(att, col)
    local e1 = Instance.new('ParticleEmitter')
    e1.Lifetime = NumberRange.new(1,1); e1.SpreadAngle = Vector2.new(5,5)
    e1.LockedToPart = true
    e1.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0),NumberSequenceKeypoint.new(0.8,0),NumberSequenceKeypoint.new(1,1)})
    e1.LightEmission = 1; e1.Color = ColorSequence.new(col)
    e1.VelocitySpread = 5; e1.Speed = NumberRange.new(0.001,0.001)
    e1.Brightness = 2; e1.Size = NumberSequence.new(2.5,3)
    e1.RotSpeed = NumberRange.new(-400,400); e1.Rate = 7
    e1.Texture = 'rbxassetid://8819682608'
    e1.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
    e1.Rotation = NumberRange.new(0,360); e1.Parent = att
    local e2 = Instance.new('ParticleEmitter')
    e2.Lifetime = NumberRange.new(1,1); e2.SpreadAngle = Vector2.new(5,5)
    e2.LockedToPart = true
    e2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0),NumberSequenceKeypoint.new(0.8,0),NumberSequenceKeypoint.new(1,1)})
    e2.LightEmission = 1; e2.Color = ColorSequence.new(col)
    e2.VelocitySpread = 5; e2.Speed = NumberRange.new(0.001,0.001)
    e2.Brightness = 2; e2.Size = NumberSequence.new(2,3)
    e2.RotSpeed = NumberRange.new(-400,400); e2.Rate = 7
    e2.Texture = 'rbxassetid://8819682608'
    e2.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
    e2.Rotation = NumberRange.new(0,360); e2.Parent = att
end

AuraTypes["Whirlwind"] = function(att, col)
    local e = Instance.new('ParticleEmitter')
    e.LightInfluence = 1; e.LockedToPart = true
    e.LightEmission = 1; e.Color = ColorSequence.new(col)
    e.Speed = NumberRange.new(0.01,0.01); e.Size = NumberSequence.new(6,10)
    e.RotSpeed = NumberRange.new(360,360); e.Rate = 1
    e.Texture = 'http://www.roblox.com/asset/?id=8553497052'
    e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
    e.Parent = att
end

AuraTypes["Wind"] = function(att, col)
    local e = Instance.new("ParticleEmitter")
    e.Texture = "rbxassetid://243660364"
    e.Rate = 250
    e.Lifetime = NumberRange.new(1)
    e.Speed = NumberRange.new(2, 5)
    e.SpreadAngle = Vector2.new(180, 180)
    e.VelocitySpread = 180
    e.LockedToPart = false
    e.LightEmission = 1
    e.Color = ColorSequence.new(col)
    e.Parent = att
end


local function BuildAuraAttachment(root, col, selectedList)
    local att = Instance.new("Attachment")
    att.Name = "AuraAttachment"
    att.Parent = root
    local sel = selectedList
    if type(sel) == "string" then sel = {sel} end
    if not sel or #sel == 0 then sel = {"Angelic"} end
    for _, name in pairs(sel) do
        local builder = AuraTypes[name]
        if builder then builder(att, col) end
    end
    return att
end


v.espAuraAttachments = {}
v.espAuraChars = {}


local function GetSharedAuraTypes()
    local list = {}
    if Toggles.aura_angelic and Toggles.aura_angelic.Value then table.insert(list, "Angelic") end
    if Toggles.aura_ambient and Toggles.aura_ambient.Value then table.insert(list, "Ambient") end
    if Toggles.aura_halo    and Toggles.aura_halo.Value    then table.insert(list, "Halo")    end
    if Toggles.aura_whirlwind and Toggles.aura_whirlwind.Value then table.insert(list, "Whirlwind") end
    if Toggles.aura_wind and Toggles.aura_wind.Value then table.insert(list, "Wind") end

    return list
end

local function ApplyESPAura(plr)
    if v.espAuraAttachments[plr] then
        pcall(function() v.espAuraAttachments[plr]:Destroy() end)
        v.espAuraAttachments[plr] = nil
        v.espAuraChars[plr] = nil
    end
    local char = plr.Character
    if not char then return end
    local root = char:FindFirstChild("LowerTorso") or char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local col = Options.espauracolor and Options.espauracolor.Value or Color3.fromRGB(234, 8, 255)
    local att = BuildAuraAttachment(root, col, GetSharedAuraTypes())
    att.Name = "ESPAuraAttachment"
    v.espAuraAttachments[plr] = att
    v.espAuraChars[plr] = char
end

local function RemoveESPAura(plr)
    if v.espAuraAttachments[plr] then
        pcall(function() v.espAuraAttachments[plr]:Destroy() end)
        v.espAuraAttachments[plr] = nil
        v.espAuraChars[plr] = nil
    end
end

local function UpdateESPAuraColor()
    local col = Options.espauracolor and Options.espauracolor.Value or Color3.fromRGB(234, 8, 255)
    for _, att in pairs(v.espAuraAttachments) do
        if att and att.Parent then
            for _, e in pairs(att:GetChildren()) do
                if e:IsA("ParticleEmitter") then
                    e.Color = ColorSequence.new(col)
                end
            end
        end
    end
end

local function RefreshAllESPAuras()
    for plr, _ in pairs(v.espAuraAttachments) do
        RemoveESPAura(plr)
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player then
            ApplyESPAura(plr)
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not Toggles.espaura or not Toggles.espaura.Value then

        for plr, _ in pairs(v.espAuraAttachments) do
            RemoveESPAura(plr)
        end
        return
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player then
            local char = plr.Character
            local root = char and (char:FindFirstChild("LowerTorso") or char:FindFirstChild("HumanoidRootPart"))

            if root then
                local att = v.espAuraAttachments[plr]

                if not att or not att.Parent or v.espAuraChars[plr] ~= char then
                    ApplyESPAura(plr)
                end
            else

                if v.espAuraAttachments[plr] then
                    RemoveESPAura(plr)
                end
            end
        end
    end


    for plr, _ in pairs(v.espAuraAttachments) do
        if not plr or not plr.Parent then
            RemoveESPAura(plr)
        end
    end
end)

Toggles.espaura:OnChanged(function()
    if not Toggles.espaura.Value then
        for plr, _ in pairs(v.espAuraAttachments) do
            RemoveESPAura(plr)
        end
    end
end)

Options.espauracolor:OnChanged(function()
    if Toggles.espaura and Toggles.espaura.Value then
        UpdateESPAuraColor()
    end
end)



v.VisualsTeamESP:AddToggle("teamcolorsenabled", {
    Text = "enable colors",
    Default = false,
    Tooltip = "use custom colors for teammates, otherwise uses esp colors"
})
v.VisualsTeamESP:AddLabel("team esp colors"):AddColorPicker("teamnamecolor", {
    Default = Color3.new(1, 1, 1),
    Title = "team name color"
})
v.VisualsTeamESP:AddLabel("team box"):AddColorPicker("teamboxcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "team box color"
})
v.VisualsTeamESP:AddLabel("team tracers"):AddColorPicker("teamtracercolor", {
    Default = Color3.new(1, 1, 1),
    Title = "team tracer color"
})
v.VisualsTeamESP:AddLabel("team distance"):AddColorPicker("teamdistancecolor", {
    Default = Color3.new(1, 1, 1),
    Title = "team distance color"
})
v.VisualsTeamESP:AddLabel("team tool"):AddColorPicker("teamtoolcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "team tool color"
})
v.VisualsTeamESP:AddLabel("team username"):AddColorPicker("teamusernamecolor", {
    Default = Color3.new(1, 1, 1),
    Title = "team username color"
})
v.VisualsTeamESP:AddLabel("team health bar"):AddColorPicker("teamhealthbarcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "team health bar"
})

v.VisualsEnemyESP:AddToggle("enemycolorsenabled", {
    Text = "enable colors",
    Default = false,
    Tooltip = "use custom colors for enemies, otherwise uses esp colors"
})
v.VisualsEnemyESP:AddLabel("enemy esp colors"):AddColorPicker("enemynamecolor", {
    Default = Color3.new(1, 1, 1),
    Title = "enemy name color"
})
v.VisualsEnemyESP:AddLabel("enemy box"):AddColorPicker("enemyboxcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "enemy box color"
})
v.VisualsEnemyESP:AddLabel("enemy tracers"):AddColorPicker("enemytracercolor", {
    Default = Color3.new(1, 1, 1),
    Title = "enemy tracer color"
})
v.VisualsEnemyESP:AddLabel("enemy distance"):AddColorPicker("enemydistancecolor", {
    Default = Color3.new(1, 1, 1),
    Title = "enemy distance color"
})
v.VisualsEnemyESP:AddLabel("enemy tool"):AddColorPicker("enemytoolcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "enemy tool color"
})
v.VisualsEnemyESP:AddLabel("enemy username"):AddColorPicker("enemyusernamecolor", {
    Default = Color3.new(1, 1, 1),
    Title = "enemy username color"
})
v.VisualsEnemyESP:AddLabel("enemy health bar"):AddColorPicker("enemyhealthbarcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "enemy health bar"
})

v.VisualsUp:AddSlider("esptextsize", {
    Text = "text size",
    Min = 1,
    Max = 200,
    Default = 13,
    Rounding = 0
})

v.VisualsUp:AddDropdown("tracermode", {
    Text = "tracer mode",
    Values = {"Bottom", "Mouse", "Top", "Center"},
    Default = 1,
    Tooltip = "choose what to do with tracers (top is recommended)"
})

v.VisualsUp:AddDropdown("nameplacement", {
    Text = "name placement",
    Values = {"up", "down"},
    Default = 1,
    Tooltip = "where the name and username appear"
})

v.VisualsUp:AddToggle("espdistancelimit", {
    Text = "distance limit",
    Default = false,
    Tooltip = "only show esp for players within specified range"
})

v.VisualsUp:AddSlider("espmaxdistance", {
    Text = "max distance",
    Default = 1000,
    Min = 0,
    Max = 100000,
    Rounding = 0,
    Compact = false
})


v.VisualsDown:AddToggle("crosshairenabled", {
    Text = "crosshair",
    Default = false,
    Tooltip = "4 lines following your cursor"
})

v.VisualsDown:AddToggle("crosshairfollowmouse", {
    Text = "follow mouse",
    Default = true,
    Tooltip = "crosshair follows mouse, if off it stays centered"
})

v.VisualsDown:AddToggle("crosshairrainbow", {
    Text = "rainbow",
    Default = false,
    Tooltip = "makes crosshair rainbow"
})

v.VisualsDown:AddToggle("crosshairrotate", {
    Text = "rotate",
    Default = false,
    Tooltip = "makes the crosshair rotate"
})

v.VisualsDown:AddToggle("crosshairpulse", {
    Text = "pulse",
    Default = false,
    Tooltip = "lines bounce in and out"
})

v.VisualsDown:AddSlider("crosshairpulsespeed", {
    Text = "pulse speed",
    Min = 1,
    Max = 20,
    Default = 5,
    Rounding = 0,
    Tooltip = "how fast the lines bounce"
})

v.VisualsDown:AddToggle("crosshairscriptname", {
    Text = "Script name",
    Default = false,
    Tooltip = "shows 'Cosmical' text below the crosshair"
}):AddColorPicker("crosshairscriptnamecolor", {
    Default = Color3.new(1, 1, 1),
    Title = "script name color"
})

v.VisualsDown:AddToggle("crosshairdot", {
    Text = "dot",
    Default = false,
    Tooltip = "dot in the center of the crosshair"
}):AddColorPicker("crosshairdotcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "dot color"
})

v.VisualsDown:AddSlider("crosshairrotatespeed", {
    Text = "rotation speed",
    Min = 1,
    Max = 50,
    Default = 10,
    Rounding = 0,
    Tooltip = "how fast the crosshair rotates"
})

v.VisualsDown:AddSlider("crosshairlerp", {
    Text = "lerp",
    Min = 0.01,
    Max = 1,
    Default = 1,
    Rounding = 2,
    Tooltip = "smoothness (1 = instant, lower = smoother)"
})

v.VisualsDown:AddSlider("crosshairthickness", {
    Text = "thickness",
    Min = 1,
    Max = 10,
    Default = 2,
    Rounding = 0,
    Tooltip = "thickness of crosshair lines"
})

v.VisualsDown:AddSlider("crosshairlength", {
    Text = "length",
    Min = 5,
    Max = 50,
    Default = 15,
    Rounding = 0,
    Tooltip = "length of crosshair lines"
})

v.VisualsDown:AddSlider("crosshairgap", {
    Text = "gap",
    Min = 0,
    Max = 50,
    Default = 5,
    Rounding = 0,
    Tooltip = "distance between crosshair lines and center"
})

v.VisualsDown:AddLabel("line 1 (top)"):AddColorPicker("crosshairline1color", {
    Default = Color3.new(1, 1, 1),
    Title = "line 1 color"
}):AddColorPicker("crosshairline1outline", {
    Default = Color3.new(1, 1, 1),
    Title = "line 1 outline"
})

v.VisualsDown:AddLabel("line 2 (bottom)"):AddColorPicker("crosshairline2color", {
    Default = Color3.new(1, 1, 1),
    Title = "line 2 color"
}):AddColorPicker("crosshairline2outline", {
    Default = Color3.new(1, 1, 1),
    Title = "line 2 outline"
})

v.VisualsDown:AddLabel("line 3 (left)"):AddColorPicker("crosshairline3color", {
    Default = Color3.new(1, 1, 1),
    Title = "line 3 color"
}):AddColorPicker("crosshairline3outline", {
    Default = Color3.new(1, 1, 1),
    Title = "line 3 outline"
})

v.VisualsDown:AddLabel("line 4 (right)"):AddColorPicker("crosshairline4color", {
    Default = Color3.new(1, 1, 1),
    Title = "line 4 color"
}):AddColorPicker("crosshairline4outline", {
    Default = Color3.new(1, 1, 1),
    Title = "line 4 outline"
})

RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateCrosshair()
end)

Players.PlayerAdded:Connect(function(v1)
    if Toggles.espenabled.Value then
        task.wait(0.5)
        if v1 == Player and Toggles.selfesp.Value then
            CreateESP(v1)
        elseif v1 ~= Player then
            CreateESP(v1)
        end
    end
end)

Players.PlayerRemoving:Connect(function(v1)
    RemoveESP(v1)
end)




v.VisualsRight:AddToggle("noshadows", {
    Text = "no shadows",
    Default = false,
    Tooltip = "removes all shadows (fullbright)"
})

Toggles.noshadows:OnChanged(function()
    if Toggles.noshadows.Value then
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 100000
        game.Lighting.Brightness = 2
    else
        game.Lighting.GlobalShadows = true
        game.Lighting.FogEnd = 100000
        game.Lighting.Brightness = getfenv().OriginalBrightness
    end
end)



getfenv().XrayObjects = {}
v.VisualsRight:AddToggle("xray", {
    Text = "xray",
    Default = false,
    Tooltip = "lets you xray through stuff (minecraft lookin xray)"
})

Toggles.xray:OnChanged(function(state)
    if state then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(Player.Character) then
                getfenv().XrayObjects[v] = v.Transparency
                v.Transparency = 0.8
            end
        end
    else
        for part, oldTransparency in pairs(getfenv().XrayObjects) do
            if part and part.Parent then
                part.Transparency = oldTransparency
            end
        end
        table.clear(getfenv().XrayObjects)
    end
end)


v.VisualsRight:AddToggle("exposurecomp", {
    Text = "exposure compensation",
    Default = false,
    Tooltip = "adjust exposure,use this as brightness aswell"
})

v.VisualsRight:AddSlider("exposureslider", {
    Text = "exposure",
    Default = 0,
    Min = -10,
    Max = 3,
    Rounding = 2,
    Compact = false
})

Toggles.exposurecomp:OnChanged(function()
    game.Lighting.ExposureCompensation = Toggles.exposurecomp.Value and Options.exposureslider.Value or 0
end)

Options.exposureslider:OnChanged(function()
    if Toggles.exposurecomp.Value then
        game.Lighting.ExposureCompensation = Options.exposureslider.Value
    end
end)


getfenv().OriginalClockTime = game.Lighting.ClockTime

v.VisualsRight:AddToggle("timechange", {
    Text = "time change",
    Default = false,
    Tooltip = "change time of day (client-sided)"
})

v.VisualsRight:AddSlider("timeslider", {
    Text = "time (hours)",
    Default = 14,
    Min = 0,
    Max = 24,
    Rounding = 1,
    Compact = false
})

Toggles.timechange:OnChanged(function()
    game.Lighting.ClockTime = Toggles.timechange.Value and Options.timeslider.Value or getfenv().OriginalClockTime
end)

Options.timeslider:OnChanged(function()
    if Toggles.timechange.Value then
        game.Lighting.ClockTime = Options.timeslider.Value
    end
end)


getfenv().OriginalFogEnd = game.Lighting.FogEnd
getfenv().OriginalFogStart = game.Lighting.FogStart
getfenv().OriginalFogColor = game.Lighting.FogColor

v.VisualsRight:AddToggle("fogenable", {
    Text = "fog",
    Default = false,
    Tooltip = "fog that actually covers the skybox"
}):AddColorPicker("fogcolorpicker", {
    Default = Color3.new(1, 1, 1),
    Title = "fog color",
    Callback = function(color)
        if Toggles.fogenable.Value then
            game.Lighting.FogColor = color
            local atmo = game.Lighting:FindFirstChildOfClass("Atmosphere")
            if atmo then atmo.Color = color atmo.Decay = color end
        end
    end
})
v.VisualsRight:AddSlider("fogdensityslider", {
    Text = "fog density",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
})
v.VisualsRight:AddSlider("fogendslider", {
    Text = "fog end",
    Default = 1000,
    Min = 0,
    Max = 10000,
    Rounding = 0,
})
v.VisualsRight:AddSlider("fogstartslider", {
    Text = "fog start",
    Default = 0,
    Min = 0,
    Max = 10000,
    Rounding = 0,
})

local function applyFog()
    local color = Options.fogcolorpicker.Value
    local density = Options.fogdensityslider.Value / 100
    game.Lighting.FogColor = color
    game.Lighting.FogEnd = Options.fogendslider.Value
    game.Lighting.FogStart = Options.fogstartslider.Value

    local atmo = game.Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmo then atmo = Instance.new("Atmosphere") atmo.Parent = game.Lighting end
    atmo.Density = density
    atmo.Color = color
    atmo.Decay = color
    atmo.Glare = 0
    atmo.Haze = Options.fogdensityslider.Value / 10
end

Toggles.fogenable:OnChanged(function()
    if Toggles.fogenable.Value then
        applyFog()
    else
        game.Lighting.FogEnd = getfenv().OriginalFogEnd
        game.Lighting.FogStart = getfenv().OriginalFogStart
        game.Lighting.FogColor = getfenv().OriginalFogColor
        local atmo = game.Lighting:FindFirstChildOfClass("Atmosphere")
        if atmo then atmo:Destroy() end
    end
end)
Options.fogdensityslider:OnChanged(function() if Toggles.fogenable.Value then applyFog() end end)
Options.fogendslider:OnChanged(function() if Toggles.fogenable.Value then applyFog() end end)
Options.fogstartslider:OnChanged(function() if Toggles.fogenable.Value then applyFog() end end)


v.VisualsRight:AddToggle("brightnesstoggle", {
    Text = "brightness",
    Default = false,
})
v.VisualsRight:AddSlider("brightnessslider", {
    Text = "brightness",
    Default = 1,
    Min = 0,
    Max = 10,
    Rounding = 2,
})
Toggles.brightnesstoggle:OnChanged(function()
    game.Lighting.Brightness = Toggles.brightnesstoggle.Value and Options.brightnessslider.Value or OriginalLighting.Brightness
end)
Options.brightnessslider:OnChanged(function()
    if Toggles.brightnesstoggle.Value then game.Lighting.Brightness = Options.brightnessslider.Value end
end)


v.VisualsRight:AddToggle("colorshifttop", {
    Text = "color shift top",
    Default = false,
}):AddColorPicker("colorshifttopcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "color shift top",
    Callback = function(color)
        if Toggles.colorshifttop.Value then game.Lighting.ColorShift_Top = color end
    end
})
Toggles.colorshifttop:OnChanged(function()
    game.Lighting.ColorShift_Top = Toggles.colorshifttop.Value and Options.colorshifttopcolor.Value or Color3.fromRGB(0,0,0)
end)


v.VisualsRight:AddToggle("colorshiftbottom", {
    Text = "color shift bottom",
    Default = false,
}):AddColorPicker("colorshiftbottomcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "color shift bottom",
    Callback = function(color)
        if Toggles.colorshiftbottom.Value then game.Lighting.ColorShift_Bottom = color end
    end
})
Toggles.colorshiftbottom:OnChanged(function()
    game.Lighting.ColorShift_Bottom = Toggles.colorshiftbottom.Value and Options.colorshiftbottomcolor.Value or Color3.fromRGB(0,0,0)
end)


v.VisualsRight:AddToggle("bloomtoggle", {
    Text = "bloom",
    Default = false,
})
v.VisualsRight:AddSlider("bloomintensity", { Text = "intensity", Default = 1, Min = 0, Max = 10, Rounding = 1 })
v.VisualsRight:AddSlider("bloomsize", { Text = "size", Default = 24, Min = 0, Max = 56, Rounding = 0 })
v.VisualsRight:AddSlider("bloomthreshold", { Text = "threshold", Default = 1, Min = 0, Max = 5, Rounding = 1 })
local function applyBloom()
    local b = game.Lighting:FindFirstChild("ScriptBloom") or Instance.new("BloomEffect")
    b.Name = "ScriptBloom" b.Intensity = Options.bloomintensity.Value
    b.Size = Options.bloomsize.Value b.Threshold = Options.bloomthreshold.Value b.Parent = game.Lighting
end
Toggles.bloomtoggle:OnChanged(function()
    if Toggles.bloomtoggle.Value then applyBloom()
    else local b = game.Lighting:FindFirstChild("ScriptBloom") if b then b:Destroy() end end
end)
Options.bloomintensity:OnChanged(function() if Toggles.bloomtoggle.Value then applyBloom() end end)
Options.bloomsize:OnChanged(function() if Toggles.bloomtoggle.Value then applyBloom() end end)
Options.bloomthreshold:OnChanged(function() if Toggles.bloomtoggle.Value then applyBloom() end end)


v.VisualsRight:AddToggle("blurtoggle", { Text = "blur", Default = false })
v.VisualsRight:AddSlider("blursize", { Text = "blur size", Default = 10, Min = 0, Max = 56, Rounding = 0 })
Toggles.blurtoggle:OnChanged(function()
    local blur = game.Lighting:FindFirstChild("ScriptBlur")
    if Toggles.blurtoggle.Value then
        if not blur then blur = Instance.new("BlurEffect") blur.Name = "ScriptBlur" blur.Parent = game.Lighting end
        blur.Size = Options.blursize.Value
    else if blur then blur:Destroy() end end
end)
Options.blursize:OnChanged(function()
    local blur = game.Lighting:FindFirstChild("ScriptBlur")
    if Toggles.blurtoggle.Value and blur then blur.Size = Options.blursize.Value end
end)


v.VisualsRight:AddToggle("sunraystoggle", { Text = "sun rays", Default = false })
v.VisualsRight:AddSlider("sunraysintensity", { Text = "intensity", Default = 0, Min = 0, Max = 1, Rounding = 2 })
v.VisualsRight:AddSlider("sunraysspread", { Text = "spread", Default = 1, Min = 0, Max = 1, Rounding = 2 })
local function applySunRays()
    local sr = game.Lighting:FindFirstChild("ScriptSunRays") or Instance.new("SunRaysEffect")
    sr.Name = "ScriptSunRays" sr.Intensity = Options.sunraysintensity.Value sr.Spread = Options.sunraysspread.Value sr.Parent = game.Lighting
end
Toggles.sunraystoggle:OnChanged(function()
    if Toggles.sunraystoggle.Value then applySunRays()
    else local sr = game.Lighting:FindFirstChild("ScriptSunRays") if sr then sr:Destroy() end end
end)
Options.sunraysintensity:OnChanged(function() if Toggles.sunraystoggle.Value then applySunRays() end end)
Options.sunraysspread:OnChanged(function() if Toggles.sunraystoggle.Value then applySunRays() end end)


v.VisualsRight:AddToggle("doftoggle", { Text = "depth of field", Default = false, Tooltip = "blurs background like a camera lens" })
v.VisualsRight:AddSlider("doffocaldistance", { Text = "focal distance", Default = 25, Min = 0, Max = 300, Rounding = 0 })
v.VisualsRight:AddSlider("dofinrange", { Text = "in range", Default = 5, Min = 0, Max = 50, Rounding = 1 })
v.VisualsRight:AddSlider("dofoutrange", { Text = "out range", Default = 10, Min = 0, Max = 50, Rounding = 1 })
local function applyDOF()
    local dof = game.Lighting:FindFirstChild("ScriptDOF") or Instance.new("DepthOfFieldEffect")
    dof.Name = "ScriptDOF" dof.FocusDistance = Options.doffocaldistance.Value
    dof.InFocusRadius = Options.dofinrange.Value dof.NearIntensity = Options.dofoutrange.Value
    dof.FarIntensity = Options.dofoutrange.Value dof.Parent = game.Lighting
end
Toggles.doftoggle:OnChanged(function()
    if Toggles.doftoggle.Value then applyDOF()
    else local dof = game.Lighting:FindFirstChild("ScriptDOF") if dof then dof:Destroy() end end
end)
Options.doffocaldistance:OnChanged(function() if Toggles.doftoggle.Value then applyDOF() end end)
Options.dofinrange:OnChanged(function() if Toggles.doftoggle.Value then applyDOF() end end)
Options.dofoutrange:OnChanged(function() if Toggles.doftoggle.Value then applyDOF() end end)


v.VisualsPlayer:AddToggle("selfforcefield", {
    Text = "self forcefield",
    Default = false,
    Tooltip = "forcefield effect"
}):AddColorPicker("selfforcefieldcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "forcefield color"
})

v.VisualsPlayer:AddDropdown("selfforcefieldmaterial", {
    Values = {"forcefield", "neon"},
    Default = "forcefield",
    Multi = false,
    Text = "person cham type",
})

v.VisualsPlayer:AddToggle("selftoolforcefield", {
    Text = "tool forcefield",
    Default = false,
    Tooltip = "makes tools you hold look like forcefield"
}):AddColorPicker("selftoolforcefieldcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "tool forcefield color"
})

v.VisualsPlayer:AddDropdown("selftoolforcefieldmaterial", {
    Values = {"forcefield", "neon"},
    Default = "forcefield",
    Multi = false,
    Text = "tool cham type",
})

v.VisualsPlayer:AddToggle("selfoutlinetoggle", {
    Text = "self outline",
    Default = false,
    Tooltip = "puts a highlight outline around your character",
    Callback = function(value)
        local char = GetCharacter()
        if not char then return end
        if value then
            local highlight = char:FindFirstChild("_SelfOutline")
            if not highlight then
                highlight = Instance.new("SelectionBox")
                highlight.Name = "_SelfOutline"
                highlight.LineThickness = 0.05
                highlight.Color3 = Options.selfoutlinecolor and Options.selfoutlinecolor.Value or Color3.new(1,1,1)
                highlight.SurfaceColor3 = Color3.new(1,1,1)
                highlight.SurfaceTransparency = 1
                highlight.Adornee = char
                highlight.Parent = char
            end
        else
            local highlight = char:FindFirstChild("_SelfOutline")
            if highlight then highlight:Destroy() end
        end
    end
}):AddColorPicker("selfoutlinecolor", {
    Default = Color3.new(1, 1, 1),
    Title = "outline color",
    Callback = function(color)
        local char = GetCharacter()
        if not char then return end
        local highlight = char:FindFirstChild("_SelfOutline")
        if highlight then highlight.Color3 = color end
    end
})

v.AuraGroupbox = Tabs.Visuals:AddRightGroupbox("auras")

v.AuraGroupbox:AddToggle("selfaura", {
    Text = "enable aura",
    Default = false,
    Tooltip = "displays a particle aura around your character"
}):AddColorPicker("selfauracolor", {
    Default = Color3.new(1, 1, 1),
    Title = "aura color"
})

v.AuraGroupbox:AddToggle("aura_angelic", { Text = "angelic",  Default = false })
v.AuraGroupbox:AddToggle("aura_ambient", { Text = "ambient",  Default = false })
v.AuraGroupbox:AddToggle("aura_halo",    { Text = "halo",     Default = false })
v.AuraGroupbox:AddToggle("aura_whirlwind", { Text = "whirlwind",  Default = false })
v.AuraGroupbox:AddToggle("aura_wind", { Text = "wind", Default = false, Tooltip = "wind particles all around your character" })
v.AuraGroupbox:AddToggle("aura_samuraihat", { Text = "samurai hat", Default = false, Tooltip = "renders a samurai hat above your head as part of your aura" })
v.AuraGroupbox:AddToggle("aura_3dcircle", { Text = "3d circle", Default = false, Tooltip = "renders a 3d circle around your character" })
v.AuraGroupbox:AddToggle("aura_rainbow", { Text = "rainbow",  Default = false, Tooltip = "cycles aura color through rainbow" })


for _, key in ipairs({"aura_angelic","aura_ambient","aura_halo","aura_whirlwind","aura_wind"}) do
    Toggles[key]:OnChanged(function()
        if Toggles.espaura and Toggles.espaura.Value then
            RefreshAllESPAuras()
        end
    end)
end

v.selfForcefieldParts = {}
v.selfForcefieldConn = nil

local function ApplySelfForcefield(char)
    if not char then return end
    v.selfForcefieldParts = {}

    local selfMat = (Options.selfforcefieldmaterial and Options.selfforcefieldmaterial.Value == "neon")
        and Enum.Material.Neon or Enum.Material.ForceField

    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
            pcall(function() obj.Transparency = 1 end)
        end
    end
    char.DescendantAdded:Connect(function(obj)
        if not Toggles.selfforcefield or not Toggles.selfforcefield.Value then return end
        if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
            pcall(function() obj.Transparency = 1 end)
        end
        if obj:IsA("BasePart") then
            local orig = {Material = obj.Material, Color = obj.Color}
            if obj:IsA("MeshPart") then orig.TextureID = obj.TextureID end
            v.selfForcefieldParts[obj] = orig
            obj.Material = selfMat
            obj.Color = Options.selfforcefieldcolor.Value
            if obj:IsA("MeshPart") then obj.TextureID = "" end
        end
    end)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local orig = {Material = part.Material, Color = part.Color}
            if part:IsA("MeshPart") then orig.TextureID = part.TextureID end
            v.selfForcefieldParts[part] = orig
            part.Material = selfMat
            part.Color = Options.selfforcefieldcolor.Value
            if part:IsA("MeshPart") then part.TextureID = "" end
        end
    end
end

local function RemoveSelfForcefield()
    for part, original in pairs(v.selfForcefieldParts) do
        if part and part.Parent then
            part.Material = original.Material
            part.Color = original.Color
            if part:IsA("MeshPart") and original.TextureID then
                part.TextureID = original.TextureID
            end
        end
    end
    v.selfForcefieldParts = {}
end

Toggles.selfforcefield:OnChanged(function()
    if Toggles.selfforcefield.Value then
        ApplySelfForcefield(GetCharacter())

        if v.selfForcefieldConn then v.selfForcefieldConn:Disconnect() end
        v.selfForcefieldConn = Player.CharacterAdded:Connect(function(char)
            if Toggles.selfforcefield and Toggles.selfforcefield.Value then
                task.wait(0.1)
                ApplySelfForcefield(char)
            end
        end)
    else
        RemoveSelfForcefield()
        if v.selfForcefieldConn then
            v.selfForcefieldConn:Disconnect()
            v.selfForcefieldConn = nil
        end
    end
end)

Options.selfforcefieldcolor:OnChanged(function()
    if Toggles.selfforcefield.Value then
        for part, _ in pairs(v.selfForcefieldParts) do
            if part and part.Parent then
                part.Color = Options.selfforcefieldcolor.Value
            end
        end
    end
end)

Options.selfforcefieldmaterial:OnChanged(function()
    if Toggles.selfforcefield.Value then
        ApplySelfForcefield(GetCharacter())
    end
end)


v.selfToolFFParts = {}
RunService.Heartbeat:Connect(function()
    if not Toggles.selftoolforcefield or not Toggles.selftoolforcefield.Value then
        for part, original in pairs(v.selfToolFFParts) do
            if part and part.Parent then
                part.Material = original.Material
                part.Color = original.Color
                if part:IsA("MeshPart") and original.TextureID then
                    part.TextureID = original.TextureID
                end
            end
        end
        v.selfToolFFParts = {}
        return
    end
    local char = GetCharacter()
    if not char then return end
    local toolMat = (Options.selftoolforcefieldmaterial and Options.selftoolforcefieldmaterial.Value == "neon")
        and Enum.Material.Neon or Enum.Material.ForceField
    local toolParts = {}
    for _, obj in pairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            for _, part in pairs(obj:GetDescendants()) do
                if part:IsA("BasePart") then
                    table.insert(toolParts, part)
                end
            end
        end
    end
    for _, part in pairs(toolParts) do
        if not v.selfToolFFParts[part] then
            local orig = {Material = part.Material, Color = part.Color}
            if part:IsA("MeshPart") then orig.TextureID = part.TextureID end
            v.selfToolFFParts[part] = orig
            part.Material = toolMat
            part.Color = Options.selftoolforcefieldcolor and Options.selftoolforcefieldcolor.Value or Color3.new(1,1,1)
            if part:IsA("MeshPart") then part.TextureID = "" end
        else
            part.Material = toolMat
            part.Color = Options.selftoolforcefieldcolor and Options.selftoolforcefieldcolor.Value or Color3.new(1,1,1)
            if part:IsA("MeshPart") then part.TextureID = "" end
        end
    end

    for part, original in pairs(v.selfToolFFParts) do
        local stillTool = false
        for _, tp in pairs(toolParts) do if tp == part then stillTool = true break end end
        if not stillTool or not part.Parent then
            if part and part.Parent then
                part.Material = original.Material
                part.Color = original.Color
                if part:IsA("MeshPart") and original.TextureID then
                    part.TextureID = original.TextureID
                end
            end
            v.selfToolFFParts[part] = nil
        end
    end
end)


do
    local selfAuraEnabled = false
    local selfAuraColor   = Color3.fromRGB(133, 220, 255)
    local selfAuraTypes   = {}
    local selfAttachments = {}
    local selfParticles   = {}
    local selfCharConn    = nil
    local selfHatDrawings = {}
    for _ = 1, 25 do
        local tri  = Drawing.new("Triangle")
        tri.Filled = true; tri.ZIndex = 1; tri.Visible = false
        local line = Drawing.new("Line")
        line.Thickness = 1; line.ZIndex = 2; line.Visible = false
        table.insert(selfHatDrawings, {line, tri})
    end

    local selfCircleDrawings = {}
    local TRAIL_SEGS = 60
    for _ = 1, TRAIL_SEGS do
        local seg = Drawing.new("Line")
        seg.Thickness = 3; seg.ZIndex = 3; seg.Visible = false
        table.insert(selfCircleDrawings, seg)
    end

    local function selfClearAll()
        for _, att in ipairs(selfAttachments) do
            if att and att.Parent then att:Destroy() end
        end
        selfAttachments = {}
        selfParticles   = {}
        for _, pair in ipairs(selfHatDrawings) do
            if pair[1] then pair[1].Visible = false end
            if pair[2] then pair[2].Visible = false end
        end
        for _, seg in ipairs(selfCircleDrawings) do
            if seg then seg.Visible = false end
        end
    end

    local function selfUpdateColors()
        for _, e in ipairs(selfParticles) do
            if e and e.Parent then
                e.Color = ColorSequence.new(selfAuraColor)
            end
        end
    end

    local function selfCreateAngelic()
        local char = GetCharacter()
        if not char then return end
        local torso = char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
        if not torso then return end

        local att1 = Instance.new('Attachment')
        att1.CFrame = CFrame.new(-1.012, 0.5, 0.852, 0.966, 0, 0.259, 0, 1, 0, -0.259, 0, 0.966)
        att1.Parent = torso
        table.insert(selfAttachments, att1)

        local e1 = Instance.new('ParticleEmitter')
        e1.Lifetime = NumberRange.new(1,1); e1.LockedToPart = true
        e1.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.944),NumberSequenceKeypoint.new(0.2,0),NumberSequenceKeypoint.new(0.8,0),NumberSequenceKeypoint.new(1,1)})
        e1.LightEmission = 1; e1.Color = ColorSequence.new(selfAuraColor)
        e1.Speed = NumberRange.new(0.05,0.05); e1.Size = NumberSequence.new(2.75,3.5)
        e1.Rate = 4; e1.Texture = 'http://www.roblox.com/asset/?id=13267054240'
        e1.EmissionDirection = Enum.NormalId.Back
        e1.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
        e1.Rotation = NumberRange.new(-15,-15); e1.Parent = att1
        table.insert(selfParticles, e1)

        local att2 = Instance.new('Attachment')
        att2.CFrame = CFrame.new(1.167, 0.5, 0.852, 0.966, 0, -0.259, 0, 1, 0, 0.259, 0, 0.966)
        att2.Parent = torso
        table.insert(selfAttachments, att2)

        local e2 = Instance.new('ParticleEmitter')
        e2.Lifetime = NumberRange.new(1,1); e2.LockedToPart = true
        e2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.944),NumberSequenceKeypoint.new(0.2,0),NumberSequenceKeypoint.new(0.8,0),NumberSequenceKeypoint.new(1,1)})
        e2.LightEmission = 1; e2.Color = ColorSequence.new(selfAuraColor)
        e2.Speed = NumberRange.new(0.05,0.05); e2.Size = NumberSequence.new(2.75,3.5)
        e2.Rate = 4; e2.Texture = 'http://www.roblox.com/asset/?id=13267054240'
        e2.EmissionDirection = Enum.NormalId.Front
        e2.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
        e2.Rotation = NumberRange.new(-15,-15); e2.Parent = att2
        table.insert(selfParticles, e2)

        local att3 = Instance.new('Attachment')
        att3.CFrame = CFrame.new(0,0.3,0); att3.Parent = torso
        table.insert(selfAttachments, att3)

        local e3 = Instance.new('ParticleEmitter')
        e3.Lifetime = NumberRange.new(2,2)
        e3.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
        e3.SpreadAngle = Vector2.new(180,180); e3.LockedToPart = true
        e3.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0.3),NumberSequenceKeypoint.new(1,1)})
        e3.LightEmission = 1; e3.Color = ColorSequence.new(selfAuraColor)
        e3.VelocitySpread = 180; e3.Speed = NumberRange.new(0.5,0.5)
        e3.Brightness = 2; e3.Size = NumberSequence.new(3,4); e3.Rate = 5
        e3.Texture = 'rbxassetid://11402221943'
        e3.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
        e3.Rotation = NumberRange.new(0,360); e3.Parent = att3
        table.insert(selfParticles, e3)
    end

    local function selfCreateAmbient()
        local char = GetCharacter()
        if not char then return end
        local hrp = char:FindFirstChild('HumanoidRootPart')
        if not hrp then return end

        local att = Instance.new('Attachment')
        att.CFrame = CFrame.new(0,-2.75,0); att.Parent = hrp
        table.insert(selfAttachments, att)

        local e1 = Instance.new('ParticleEmitter')
        e1.Lifetime = NumberRange.new(2,2); e1.SpreadAngle = Vector2.new(0.001,0.001)
        e1.LockedToPart = true; e1.Transparency = NumberSequence.new(0,1)
        e1.LightEmission = 1; e1.Color = ColorSequence.new(selfAuraColor)
        e1.VelocitySpread = 0.001; e1.Squash = NumberSequence.new(0)
        e1.Speed = NumberRange.new(0.001,0.001); e1.Brightness = 2
        e1.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,1),NumberSequenceKeypoint.new(0.6,2.5),NumberSequenceKeypoint.new(0.8,4),NumberSequenceKeypoint.new(1,6)})
        e1.RotSpeed = NumberRange.new(-600,600)
        e1.Texture = 'https://assetgame.roblox.com/asset/?id=12713358087&assetName=crescent'
        e1.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
        e1.Rotation = NumberRange.new(0,360); e1.Parent = att
        table.insert(selfParticles, e1)

        local e2 = Instance.new('ParticleEmitter')
        e2.Lifetime = NumberRange.new(2,2); e2.SpreadAngle = Vector2.new(0.001,0.001)
        e2.LockedToPart = true
        e2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.6,0.2),NumberSequenceKeypoint.new(1,1)})
        e2.LightEmission = 1; e2.Color = ColorSequence.new(selfAuraColor)
        e2.VelocitySpread = 0.001; e2.Squash = NumberSequence.new(0,2)
        e2.Speed = NumberRange.new(0.001,0.001); e2.Brightness = 2
        e2.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,1),NumberSequenceKeypoint.new(0.6,2.5),NumberSequenceKeypoint.new(0.8,4),NumberSequenceKeypoint.new(1,6)})
        e2.RotSpeed = NumberRange.new(-30,30); e2.Texture = 'rbxassetid://7216849325'
        e2.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
        e2.Rotation = NumberRange.new(0,360); e2.Parent = att
        table.insert(selfParticles, e2)

        local e3 = Instance.new('ParticleEmitter')
        e3.Lifetime = NumberRange.new(2,2); e3.SpreadAngle = Vector2.new(0.001,0.001)
        e3.LockedToPart = true
        e3.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0.3),NumberSequenceKeypoint.new(1,1)})
        e3.LightEmission = 1; e3.Color = ColorSequence.new(selfAuraColor)
        e3.VelocitySpread = 0.001; e3.Squash = NumberSequence.new(0)
        e3.Speed = NumberRange.new(0.001,0.001); e3.Brightness = 2
        e3.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,2),NumberSequenceKeypoint.new(0.6,5),NumberSequenceKeypoint.new(0.8,8),NumberSequenceKeypoint.new(1,12)})
        e3.RotSpeed = NumberRange.new(-40,40); e3.Texture = 'rbxassetid://7216855136'
        e3.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
        e3.Rotation = NumberRange.new(0,360); e3.Parent = att
        table.insert(selfParticles, e3)
    end

    local function selfCreateHalo()
        local char = GetCharacter()
        if not char then return end
        local head = char:FindFirstChild('Head')
        if not head then return end

        local att = Instance.new('Attachment')
        att.CFrame = CFrame.new(-0.25, 0.933, 0.259, 0.469, -0.25, -0.847, -0.117, 0.933, -0.34, 0.875, 0.259, 0.408)
        att.Parent = head
        table.insert(selfAttachments, att)

        local e1 = Instance.new('ParticleEmitter')
        e1.Lifetime = NumberRange.new(1,1); e1.SpreadAngle = Vector2.new(5,5)
        e1.LockedToPart = true
        e1.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0),NumberSequenceKeypoint.new(0.8,0),NumberSequenceKeypoint.new(1,1)})
        e1.LightEmission = 1; e1.Color = ColorSequence.new(selfAuraColor)
        e1.VelocitySpread = 5; e1.Speed = NumberRange.new(0.001,0.001)
        e1.Brightness = 2; e1.Size = NumberSequence.new(2.5,3)
        e1.RotSpeed = NumberRange.new(-400,400); e1.Rate = 7
        e1.Texture = 'rbxassetid://8819682608'
        e1.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
        e1.Rotation = NumberRange.new(0,360); e1.Parent = att
        table.insert(selfParticles, e1)

        local e2 = Instance.new('ParticleEmitter')
        e2.Lifetime = NumberRange.new(1,1); e2.SpreadAngle = Vector2.new(5,5)
        e2.LockedToPart = true
        e2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0),NumberSequenceKeypoint.new(0.8,0),NumberSequenceKeypoint.new(1,1)})
        e2.LightEmission = 1; e2.Color = ColorSequence.new(selfAuraColor)
        e2.VelocitySpread = 5; e2.Speed = NumberRange.new(0.001,0.001)
        e2.Brightness = 2; e2.Size = NumberSequence.new(2,3)
        e2.RotSpeed = NumberRange.new(-400,400); e2.Rate = 7
        e2.Texture = 'rbxassetid://8819682608'
        e2.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
        e2.Rotation = NumberRange.new(0,360); e2.Parent = att
        table.insert(selfParticles, e2)
    end

    local function selfCreateWhirlwind()
        local char = GetCharacter()
        if not char then return end
        local hrp = char:FindFirstChild('HumanoidRootPart')
        if not hrp then return end

        local att = Instance.new('Attachment')
        att.CFrame = CFrame.new(0,-3,0); att.Parent = hrp
        table.insert(selfAttachments, att)

        local e = Instance.new('ParticleEmitter')
        e.LightInfluence = 1; e.LockedToPart = true
        e.LightEmission = 1; e.Color = ColorSequence.new(selfAuraColor)
        e.Speed = NumberRange.new(0.01,0.01); e.Size = NumberSequence.new(6,10)
        e.RotSpeed = NumberRange.new(360,360); e.Rate = 1
        e.Texture = 'http://www.roblox.com/asset/?id=8553497052'
        e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
        e.Parent = att
        table.insert(selfParticles, e)
    end

    local function selfCreateWind()
        local char = GetCharacter()
        if not char then return end
        local hrp = char:FindFirstChild('HumanoidRootPart')
        if not hrp then return end

        local att = Instance.new('Attachment')
        att.CFrame = CFrame.new(0, 0, 0); att.Parent = hrp
        table.insert(selfAttachments, att)

        local e = Instance.new('ParticleEmitter')
        e.Texture = "rbxassetid://243660364"
        e.Rate = 250
        e.Lifetime = NumberRange.new(1)
        e.Speed = NumberRange.new(2, 5)
        e.SpreadAngle = Vector2.new(180, 180)
        e.VelocitySpread = 180
        e.LockedToPart = false
        e.LightEmission = 1
        e.Color = ColorSequence.new(selfAuraColor)
        e.Parent = att
        table.insert(selfParticles, e)
    end

    local function selfRefresh()
        if not selfAuraEnabled then selfClearAll() return end
        selfClearAll()
        if selfAuraTypes['Angelic'] then selfCreateAngelic() end
        if selfAuraTypes['Ambient'] then selfCreateAmbient() end
        if selfAuraTypes['Halo']    then selfCreateHalo()    end
        if selfAuraTypes['Whirlwind'] then selfCreateWhirlwind() end
        if selfAuraTypes['Wind'] then selfCreateWind() end
    end

    RunService.RenderStepped:Connect(function()
        local isRainbow = Toggles.aura_rainbow and Toggles.aura_rainbow.Value
        local drawCol = isRainbow and Color3.fromHSV((tick() * 0.3) % 1, 1, 1) or selfAuraColor
        local char = GetCharacter()
        local head = char and char:FindFirstChild('Head')
        local hrp  = char and char:FindFirstChild('HumanoidRootPart')


        local showHat = selfAuraEnabled and selfAuraTypes['SamuraiHat'] and head
        if showHat then
            local sides  = 25
            local hatH   = 0.7
            local hatR   = 2
            local hatOY  = 0.5
            local hatTrs = 0.35
            local fullC  = math.pi * 2
            local headPos = head.Position
            local topPos  = headPos + Vector3.new(0, hatOY + hatH, 0)
            local basePos = headPos + Vector3.new(0, hatOY, 0)
            for i = 1, sides do
                local pair  = selfHatDrawings[i]
                local a1    = (i / sides) * fullC
                local a2    = ((i % sides + 1) / sides) * fullC
                local p1    = basePos + Vector3.new(math.cos(a1), 0, math.sin(a1)) * hatR
                local p2    = basePos + Vector3.new(math.cos(a2), 0, math.sin(a2)) * hatR
                local sp1   = Camera:WorldToViewportPoint(p1)
                local sp2   = Camera:WorldToViewportPoint(p2)
                local spTop = Camera:WorldToViewportPoint(topPos)
                pair[1].From  = Vector2.new(sp1.X, sp1.Y)
                pair[1].To    = Vector2.new(sp2.X, sp2.Y)
                pair[1].Color = drawCol
                pair[1].Visible = true
                pair[2].PointA  = Vector2.new(spTop.X, spTop.Y)
                pair[2].PointB  = Vector2.new(sp1.X, sp1.Y)
                pair[2].PointC  = Vector2.new(sp2.X, sp2.Y)
                pair[2].Color   = drawCol
                pair[2].Transparency = hatTrs
                pair[2].Visible = true
            end
        else
            for _, pair in ipairs(selfHatDrawings) do
                if pair[1] then pair[1].Visible = false end
                if pair[2] then pair[2].Visible = false end
            end
        end


        local showCircle = selfAuraEnabled and selfAuraTypes['Circle3D'] and hrp
        if showCircle then
            local radius      = 3.5
            local thick       = 2.5
            local rotSpeed    = 3
            local visible     = 0.35
            local angleOffset = (tick() * rotSpeed) % (math.pi * 2)

            for i = 1, TRAIL_SEGS do
                local f = i / TRAIL_SEGS

                if f > visible then
                    if selfCircleDrawings[i] then
                        selfCircleDrawings[i].Visible = false
                    end
                else
                    local line = selfCircleDrawings[i]
                    local a = f * math.pi * 2 + angleOffset
                    local b = (i + 1) / TRAIL_SEGS * math.pi * 2 + angleOffset
                    local p1 = hrp.Position + Vector3.new(math.cos(a), 0, math.sin(a)) * radius
                    local p2 = hrp.Position + Vector3.new(math.cos(b), 0, math.sin(b)) * radius
                    local s1 = Camera:WorldToViewportPoint(p1)
                    local s2 = Camera:WorldToViewportPoint(p2)

                    line.From      = Vector2.new(s1.X, s1.Y)
                    line.To        = Vector2.new(s2.X, s2.Y)
                    line.Thickness = thick
                    line.Color     = drawCol


                    local d1 = f * TRAIL_SEGS
                    local d2 = visible * TRAIL_SEGS - f * TRAIL_SEGS
                    line.Transparency = (d1 < 7 and d1 / 7) or (d2 < 7 and d2 / 7) or 1
                    line.Visible = true
                end
            end
        else
            for _, seg in ipairs(selfCircleDrawings) do
                if seg then seg.Visible = false end
            end
        end

    end)

    local function selfRebuildTypes()
        selfAuraTypes = {}
        if Toggles.aura_angelic and Toggles.aura_angelic.Value then selfAuraTypes["Angelic"] = true end
        if Toggles.aura_ambient and Toggles.aura_ambient.Value then selfAuraTypes["Ambient"] = true end
        if Toggles.aura_halo and Toggles.aura_halo.Value then selfAuraTypes["Halo"]    = true end
        if Toggles.aura_whirlwind and Toggles.aura_whirlwind.Value then selfAuraTypes["Whirlwind"] = true end
        if Toggles.aura_samuraihat and Toggles.aura_samuraihat.Value then selfAuraTypes["SamuraiHat"] = true end
        if Toggles.aura_3dcircle and Toggles.aura_3dcircle.Value then selfAuraTypes["Circle3D"] = true end
        if Toggles.aura_wind and Toggles.aura_wind.Value then selfAuraTypes["Wind"] = true end
    end

    local function doRefresh()
        task.spawn(function()
            task.wait(0.1)
            selfRebuildTypes()
            selfRefresh()
        end)
    end

    Toggles.selfaura:OnChanged(function(val)
        selfAuraEnabled = val
        if val then
            selfAuraColor = Options.selfauracolor and Options.selfauracolor.Value or Color3.fromRGB(133,220,255)
            doRefresh()
            if selfCharConn then selfCharConn:Disconnect() end
            selfCharConn = Player.CharacterAdded:Connect(function()
                if Toggles.selfaura and Toggles.selfaura.Value then
                    task.wait(0.5)
                    selfRebuildTypes()
                    selfRefresh()
                end
            end)
        else
            selfClearAll()
            if selfCharConn then selfCharConn:Disconnect() selfCharConn = nil end
        end
    end)

    Options.selfauracolor:OnChanged(function(col)
        selfAuraColor = col
        if Toggles.selfaura and Toggles.selfaura.Value then selfUpdateColors() end
    end)

    RunService.Heartbeat:Connect(function()
        if not selfAuraEnabled then return end
        if not (Toggles.aura_rainbow and Toggles.aura_rainbow.Value) then return end
        local col = Color3.fromHSV((tick() * 0.3) % 1, 1, 1)
        for _, e in ipairs(selfParticles) do
            if e and e.Parent then e.Color = ColorSequence.new(col) end
        end
    end)

    for _, key in ipairs({"aura_angelic","aura_ambient","aura_halo","aura_whirlwind","aura_samuraihat","aura_3dcircle","aura_wind"}) do
        Toggles[key]:OnChanged(function()
            if Toggles.selfaura and Toggles.selfaura.Value then doRefresh() end
        end)
    end
end

v.VisualsPlayer:AddToggle("playerfov", {
    Text = "fov",
    Default = false,
    Tooltip = "changes your field of view"
})

v.VisualsPlayer:AddSlider("playerfovvalue", {
    Text = "fov value",
    Default = 90,
    Min = 60,
    Max = 120,
    Rounding = 0
})

Toggles.playerfov:OnChanged(function(state)
    Camera.FieldOfView = state and Options.playerfovvalue.Value or v.OriginalFOV
end)

Options.playerfovvalue:OnChanged(function(val)
    if Toggles.playerfov.Value then
        Camera.FieldOfView = val
    end
end)

v.VisualsPlayer:AddToggle("stretchedrestoggle", {
    Text = "stretched res",
    Default = false,
})

v.VisualsPlayer:AddSlider("stretchedresx", {
    Text = "stretch x",
    Default = 100,
    Min = 10,
    Max = 119,
    Rounding = 1,
})

v.VisualsPlayer:AddSlider("stretchedresy", {
    Text = "stretch y",
    Default = 65,
    Min = 10,
    Max = 119,
    Rounding = 1,
})

RunService.RenderStepped:Connect(function()
    if not Toggles.stretchedrestoggle or not Toggles.stretchedrestoggle.Value then return end
    local sx = (Options.stretchedresx and Options.stretchedresx.Value or 100) / 100
    local sy = (Options.stretchedresy and Options.stretchedresy.Value or 65) / 100
    Camera.CFrame = Camera.CFrame * CFrame.new(0,0,0, sx,0,0, 0,sy,0, 0,0,1)
end)

v.VisualsPlayer:AddToggle("chartransptoggle", {
    Text = "character transparency",
    Default = false,
    Callback = function(value)
        local char = GetCharacter()
        if not char then return end
        local transparency = value and (Options.chartranspslider and Options.chartranspslider.Value or 0.5) or 0
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.LocalTransparencyModifier = transparency
            end
        end
    end
})

v.VisualsPlayer:AddSlider("chartranspslider", {
    Text = "transparency",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        if not Toggles.chartransptoggle or not Toggles.chartransptoggle.Value then return end
        local t = value / 100
        local char = GetCharacter()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.LocalTransparencyModifier = t
            end
        end
    end
})

RunService.RenderStepped:Connect(function()
    if not Toggles.chartransptoggle or not Toggles.chartransptoggle.Value then return end
    local char = GetCharacter()
    if not char then return end
    local t = (Options.chartranspslider and Options.chartranspslider.Value or 50) / 100
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.LocalTransparencyModifier = t
        end
    end
end)

getfenv().ColorCorrectionEffect = Instance.new("ColorCorrectionEffect")
getfenv().ColorCorrectionEffect.Name = "ColorCorrectionEffect"
getfenv().ColorCorrectionEffect.Parent = game.Lighting

v.VisualsMiddle:AddToggle("colorcorrection", {
    Text = "color correction",
    Default = false,
    Tooltip = "change color corrections"
})

v.VisualsMiddle:AddSlider("saturationslider", {
    Text = "saturation",
    Default = 0,
    Min = -10,
    Max = 10,
    Rounding = 2,
    Compact = false
})

v.VisualsMiddle:AddSlider("contrastslider", {
    Text = "contrast",
    Default = 0,
    Min = -10,
    Max = 10,
    Rounding = 2,
    Compact = false
})

v.VisualsMiddle:AddSlider("ccbrightness", {
    Text = "brightness",
    Default = 0,
    Min = -10,
    Max = 10,
    Rounding = 2,
    Compact = false
})

Toggles.colorcorrection:OnChanged(function()
    if Toggles.colorcorrection.Value then
        getfenv().ColorCorrectionEffect.Saturation = Options.saturationslider.Value
        getfenv().ColorCorrectionEffect.Contrast = Options.contrastslider.Value
        getfenv().ColorCorrectionEffect.Brightness = Options.ccbrightness.Value
        getfenv().ColorCorrectionEffect.Enabled = true
    else
        getfenv().ColorCorrectionEffect.Saturation = 0
        getfenv().ColorCorrectionEffect.Contrast = 0
        getfenv().ColorCorrectionEffect.Brightness = 0
        getfenv().ColorCorrectionEffect.Enabled = false
    end
end)

Options.saturationslider:OnChanged(function()
    if Toggles.colorcorrection.Value then
        getfenv().ColorCorrectionEffect.Saturation = Options.saturationslider.Value
    end
end)

Options.contrastslider:OnChanged(function()
    if Toggles.colorcorrection.Value then
        getfenv().ColorCorrectionEffect.Contrast = Options.contrastslider.Value
    end
end)

Options.ccbrightness:OnChanged(function()
    if Toggles.colorcorrection.Value then
        getfenv().ColorCorrectionEffect.Brightness = Options.ccbrightness.Value
    end
end)


v.VisualsMiddle:AddToggle("cctint", {
    Text = "tint color",
    Default = false,
    Tooltip = "adds a color tint over the whole screen"
}):AddColorPicker("cctintcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "tint color",
    Callback = function(color)
        if Toggles.cctint.Value then
            getfenv().ColorCorrectionEffect.TintColor = color
            getfenv().ColorCorrectionEffect.Enabled = true
        end
    end
})
Toggles.cctint:OnChanged(function()
    if Toggles.cctint.Value then
        getfenv().ColorCorrectionEffect.TintColor = Options.cctintcolor.Value
        getfenv().ColorCorrectionEffect.Enabled = true
    else
        getfenv().ColorCorrectionEffect.TintColor = Color3.fromRGB(255, 255, 255)
    end
end)


v.VisualsMiddle:AddToggle("tonemaptoggle", {
    Text = "tone map",
    Default = false,
    Tooltip = "changes scene tone mapping style"
})
v.VisualsMiddle:AddDropdown("tonemapstyle", {
    Text = "style",
    Values = {"Linear", "Filmic", "Retro", "SFR"},
    Default = 1,
    Multi = false,
})
Toggles.tonemaptoggle:OnChanged(function()
    local tm = game.Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if Toggles.tonemaptoggle.Value then
        local t = game.Lighting:FindFirstChild("ScriptToneMap") or Instance.new("ColorCorrectionEffect")
        t.Name = "ScriptToneMap"
        t.Parent = game.Lighting
    else
        local t = game.Lighting:FindFirstChild("ScriptToneMap")
        if t then t:Destroy() end
    end
end)




getfenv().AnimationBreakerEnabled = false
getfenv().LagAmount = 50
getfenv().JitterAmount = 50
getfenv().animationConnections = {}

v.VisualsThere:AddToggle("animbreaker", {
    Text = "animation breaker",
    Default = false
})

Toggles.animbreaker:OnChanged(function(state)
    getfenv().AnimationBreakerEnabled = state

    if state then
        getfenv().animationConnections.RenderStepped = RunService.RenderStepped:Connect(function()
            if not getfenv().AnimationBreakerEnabled then return end
            if not GetCharacter() then return end
            if not GetCharacter():FindFirstChildOfClass("Humanoid") then return end

            for _, track in pairs(GetCharacter():FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()) do
                if track.IsPlaying then
                    track:AdjustSpeed(getfenv().LagAmount / 50)

                    if getfenv().JitterAmount > 0 then
                        if track.TimePosition + ((math.random() - 0.5) * (getfenv().JitterAmount / 100)) >= 0 and track.TimePosition + ((math.random() - 0.5) * (getfenv().JitterAmount / 100)) <= track.Length then
                            track.TimePosition = track.TimePosition + ((math.random() - 0.5) * (getfenv().JitterAmount / 100))
                        end
                    end
                end
            end
        end)

        getfenv().animationConnections.Heartbeat = RunService.Heartbeat:Connect(function()
            if not getfenv().AnimationBreakerEnabled then return end
            if not GetCharacter() then return end
            if not GetCharacter():FindFirstChildOfClass("Humanoid") then return end

            for _, track in pairs(GetCharacter():FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()) do
                if track.IsPlaying then
                    track:AdjustSpeed(math.max(0.1, (getfenv().LagAmount / 50) + ((math.random() - 0.5) * (getfenv().JitterAmount / 100))))
                end
            end
        end)
    else
        for _, connection in pairs(getfenv().animationConnections) do
            connection:Disconnect()
        end
        getfenv().animationConnections = {}

        if GetCharacter() and GetCharacter():FindFirstChildOfClass("Humanoid") then
            for _, track in pairs(GetCharacter():FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()) do
                track:AdjustSpeed(1)
            end
        end
    end
end)

v.VisualsThere:AddSlider("animlag", {
    Text = "lagger",
    Default = 50,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        getfenv().LagAmount = Value
    end
})

v.VisualsThere:AddSlider("animjitter", {
    Text = "jitter",
    Default = 50,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        getfenv().JitterAmount = Value
    end
})

Options.animlag:OnChanged(function(val)
    getfenv().LagAmount = val
end)

Options.animjitter:OnChanged(function(val)
    getfenv().JitterAmount = val
end)

Player.CharacterAdded:Connect(function(newChar)
    if not getfenv().AnimationBreakerEnabled then return end

    task.wait(0.5)
    for _, connection in pairs(getfenv().animationConnections) do
        connection:Disconnect()
    end
    getfenv().animationConnections = {}

    getfenv().animationConnections.RenderStepped = RunService.RenderStepped:Connect(function()
        if not getfenv().AnimationBreakerEnabled then return end
        if not newChar:FindFirstChildOfClass("Humanoid") then return end

        for _, track in pairs(newChar:FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()) do
            if track.IsPlaying then
                track:AdjustSpeed(getfenv().LagAmount / 50)

                if getfenv().JitterAmount > 0 then
                    if track.TimePosition + ((math.random() - 0.5) * (getfenv().JitterAmount / 100)) >= 0 and track.TimePosition + ((math.random() - 0.5) * (getfenv().JitterAmount / 100)) <= track.Length then
                        track.TimePosition = track.TimePosition + ((math.random() - 0.5) * (getfenv().JitterAmount / 100))
                    end
                end
            end
        end
    end)

    getfenv().animationConnections.Heartbeat = RunService.Heartbeat:Connect(function()
        if not getfenv().AnimationBreakerEnabled then return end
        if not newChar:FindFirstChildOfClass("Humanoid") then return end

        for _, track in pairs(newChar:FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()) do
            if track.IsPlaying then
                track:AdjustSpeed(math.max(0.1, (getfenv().LagAmount / 50) + ((math.random() - 0.5) * (getfenv().JitterAmount / 100))))
            end
        end
    end)
end)

v.originalSkybox = {}
v.skyboxAssets = {


    ["Anime Girl"] = {
        SkyboxBk = "rbxassetid://271042516",
        SkyboxDn = "rbxassetid://271077243",
        SkyboxFt = "rbxassetid://271042556",
        SkyboxLf = "rbxassetid://271042467",
        SkyboxRt = "rbxassetid://271042310",
        SkyboxUp = "rbxassetid://271077958"
    },
    ["Pastel Dream"] = {
        SkyboxBk = "rbxassetid://271042516",
        SkyboxDn = "rbxassetid://271077958",
        SkyboxFt = "rbxassetid://271042467",
        SkyboxLf = "rbxassetid://271042556",
        SkyboxRt = "rbxassetid://271042310",
        SkyboxUp = "rbxassetid://271077243"
    },
    ["Pink Daylight"] = {
        SkyboxBk = "rbxassetid://271042516",
        SkyboxDn = "rbxassetid://271077243",
        SkyboxFt = "rbxassetid://271042556",
        SkyboxLf = "rbxassetid://271042310",
        SkyboxRt = "rbxassetid://271042467",
        SkyboxUp = "rbxassetid://271077958"
    },
    ["Sakura Sky"] = {
        SkyboxBk = "rbxassetid://271042467",
        SkyboxDn = "rbxassetid://271077243",
        SkyboxFt = "rbxassetid://271042310",
        SkyboxLf = "rbxassetid://271042516",
        SkyboxRt = "rbxassetid://271042556",
        SkyboxUp = "rbxassetid://271077958"
    },
    ["Soft Pink"] = {
        SkyboxBk = "rbxassetid://271042310",
        SkyboxDn = "rbxassetid://271077958",
        SkyboxFt = "rbxassetid://271042516",
        SkyboxLf = "rbxassetid://271077243",
        SkyboxRt = "rbxassetid://271042467",
        SkyboxUp = "rbxassetid://271042556"
    },
    ["Cotton Candy"] = {
        SkyboxBk = "rbxassetid://271042556",
        SkyboxDn = "rbxassetid://271077243",
        SkyboxFt = "rbxassetid://271042516",
        SkyboxLf = "rbxassetid://271077958",
        SkyboxRt = "rbxassetid://271042310",
        SkyboxUp = "rbxassetid://271042467"
    },
    ["Dreamy Clouds"] = {
        SkyboxBk = "rbxassetid://271077958",
        SkyboxDn = "rbxassetid://271077243",
        SkyboxFt = "rbxassetid://271042516",
        SkyboxLf = "rbxassetid://271042467",
        SkyboxRt = "rbxassetid://271042556",
        SkyboxUp = "rbxassetid://271042310"
    },
    ["Lofi Night"] = {
        SkyboxBk = "rbxassetid://12064107",
        SkyboxDn = "rbxassetid://12064152",
        SkyboxFt = "rbxassetid://12064121",
        SkyboxLf = "rbxassetid://218954748",
        SkyboxRt = "rbxassetid://218955425",
        SkyboxUp = "rbxassetid://12064131"
    },
    ["Chill Vibes"] = {
        SkyboxBk = "rbxassetid://570557620",
        SkyboxDn = "rbxassetid://159454296",
        SkyboxFt = "rbxassetid://570557559",
        SkyboxLf = "rbxassetid://159454286",
        SkyboxRt = "rbxassetid://570557677",
        SkyboxUp = "rbxassetid://271077958"
    },
    ["Y2K Pink"] = {
        SkyboxBk = "rbxassetid://271042467",
        SkyboxDn = "rbxassetid://271042310",
        SkyboxFt = "rbxassetid://271077958",
        SkyboxLf = "rbxassetid://271042556",
        SkyboxRt = "rbxassetid://271042516",
        SkyboxUp = "rbxassetid://271077243"
    },
    ["Vaporwave"] = {
        SkyboxBk = "rbxassetid://1417494030",
        SkyboxDn = "rbxassetid://1417494146",
        SkyboxFt = "rbxassetid://1417494253",
        SkyboxLf = "rbxassetid://1417494402",
        SkyboxRt = "rbxassetid://1417494499",
        SkyboxUp = "rbxassetid://1417494643"
    },
    ["Midnight Pink"] = {
        SkyboxBk = "rbxassetid://1417494402",
        SkyboxDn = "rbxassetid://1417494146",
        SkyboxFt = "rbxassetid://271042516",
        SkyboxLf = "rbxassetid://1417494030",
        SkyboxRt = "rbxassetid://271042467",
        SkyboxUp = "rbxassetid://1417494643"
    },
    ["Aesthetic Purple"] = {
        SkyboxBk = "rbxassetid://1417494030",
        SkyboxDn = "rbxassetid://1417494146",
        SkyboxFt = "rbxassetid://159454293",
        SkyboxLf = "rbxassetid://1417494402",
        SkyboxRt = "rbxassetid://159454286",
        SkyboxUp = "rbxassetid://1417494643"
    },
    ["Kawaii Sky"] = {
        SkyboxBk = "rbxassetid://271042310",
        SkyboxDn = "rbxassetid://271077243",
        SkyboxFt = "rbxassetid://271042467",
        SkyboxLf = "rbxassetid://271042556",
        SkyboxRt = "rbxassetid://271077958",
        SkyboxUp = "rbxassetid://271042516"
    },
    ["Rose Gold"] = {
        SkyboxBk = "rbxassetid://570557620",
        SkyboxDn = "rbxassetid://271077243",
        SkyboxFt = "rbxassetid://271042516",
        SkyboxLf = "rbxassetid://570557559",
        SkyboxRt = "rbxassetid://271042467",
        SkyboxUp = "rbxassetid://271077958"
    },
    ["Fairy Lights"] = {
        SkyboxBk = "rbxassetid://271042556",
        SkyboxDn = "rbxassetid://12064152",
        SkyboxFt = "rbxassetid://271042310",
        SkyboxLf = "rbxassetid://12064107",
        SkyboxRt = "rbxassetid://271042516",
        SkyboxUp = "rbxassetid://271077958"
    },
    ["Alt Girl"] = {
        SkyboxBk = "rbxassetid://159454286",
        SkyboxDn = "rbxassetid://1417494146",
        SkyboxFt = "rbxassetid://1417494253",
        SkyboxLf = "rbxassetid://159454300",
        SkyboxRt = "rbxassetid://1417494499",
        SkyboxUp = "rbxassetid://159454288"
    },
    ["Soft Grunge"] = {
        SkyboxBk = "rbxassetid://218955819",
        SkyboxDn = "rbxassetid://271077243",
        SkyboxFt = "rbxassetid://218954302",
        SkyboxLf = "rbxassetid://271042310",
        SkyboxRt = "rbxassetid://218955425",
        SkyboxUp = "rbxassetid://271077958"
    },


    ["Sunset"] = {
        SkyboxBk = "rbxassetid://570557620",
        SkyboxDn = "rbxassetid://570557514",
        SkyboxFt = "rbxassetid://570557559",
        SkyboxLf = "rbxassetid://570557620",
        SkyboxRt = "rbxassetid://570557559",
        SkyboxUp = "rbxassetid://570557677"
    },
    ["Golden Hour"] = {
        SkyboxBk = "rbxassetid://570557620",
        SkyboxDn = "rbxassetid://570557514",
        SkyboxFt = "rbxassetid://570557677",
        SkyboxLf = "rbxassetid://570557559",
        SkyboxRt = "rbxassetid://570557620",
        SkyboxUp = "rbxassetid://271077958"
    },
    ["Dawn"] = {
        SkyboxBk = "rbxassetid://570557559",
        SkyboxDn = "rbxassetid://570557514",
        SkyboxFt = "rbxassetid://271042556",
        SkyboxLf = "rbxassetid://570557620",
        SkyboxRt = "rbxassetid://271042467",
        SkyboxUp = "rbxassetid://271077958"
    },
    ["Dusk"] = {
        SkyboxBk = "rbxassetid://218955819",
        SkyboxDn = "rbxassetid://570557514",
        SkyboxFt = "rbxassetid://570557559",
        SkyboxLf = "rbxassetid://218954748",
        SkyboxRt = "rbxassetid://218955425",
        SkyboxUp = "rbxassetid://1417494643"
    },
    ["Cloudy Day"] = {
        SkyboxBk = "rbxassetid://271042516",
        SkyboxDn = "rbxassetid://271077243",
        SkyboxFt = "rbxassetid://271042467",
        SkyboxLf = "rbxassetid://271042310",
        SkyboxRt = "rbxassetid://271042556",
        SkyboxUp = "rbxassetid://271042516"
    },
    ["Arctic"] = {
        SkyboxBk = "rbxassetid://149397692",
        SkyboxDn = "rbxassetid://271077243",
        SkyboxFt = "rbxassetid://149397697",
        SkyboxLf = "rbxassetid://149397684",
        SkyboxRt = "rbxassetid://149397688",
        SkyboxUp = "rbxassetid://271077958"
    },


    ["Night Sky"] = {
        SkyboxBk = "rbxassetid://12064107",
        SkyboxDn = "rbxassetid://12064152",
        SkyboxFt = "rbxassetid://12064121",
        SkyboxLf = "rbxassetid://12063984",
        SkyboxRt = "rbxassetid://12064115",
        SkyboxUp = "rbxassetid://12064131"
    },
    ["Galaxy"] = {
        SkyboxBk = "rbxassetid://218955819",
        SkyboxDn = "rbxassetid://218954524",
        SkyboxFt = "rbxassetid://218954302",
        SkyboxLf = "rbxassetid://218954748",
        SkyboxRt = "rbxassetid://218955425",
        SkyboxUp = "rbxassetid://218954909"
    },
    ["Deep Space"] = {
        SkyboxBk = "rbxassetid://159454299",
        SkyboxDn = "rbxassetid://159454296",
        SkyboxFt = "rbxassetid://159454293",
        SkyboxLf = "rbxassetid://159454286",
        SkyboxRt = "rbxassetid://159454300",
        SkyboxUp = "rbxassetid://159454288"
    },
    ["Purple Nebula"] = {
        SkyboxBk = "rbxassetid://159454286",
        SkyboxDn = "rbxassetid://159454296",
        SkyboxFt = "rbxassetid://159454293",
        SkyboxLf = "rbxassetid://159454286",
        SkyboxRt = "rbxassetid://159454300",
        SkyboxUp = "rbxassetid://159454288"
    },
    ["Space"] = {
        SkyboxBk = "rbxassetid://149397692",
        SkyboxDn = "rbxassetid://149397686",
        SkyboxFt = "rbxassetid://149397697",
        SkyboxLf = "rbxassetid://149397684",
        SkyboxRt = "rbxassetid://149397688",
        SkyboxUp = "rbxassetid://149397702"
    },
    ["Starfield"] = {
        SkyboxBk = "rbxassetid://159454286",
        SkyboxDn = "rbxassetid://159454296",
        SkyboxFt = "rbxassetid://159454293",
        SkyboxLf = "rbxassetid://159454300",
        SkyboxRt = "rbxassetid://159454286",
        SkyboxUp = "rbxassetid://159454288"
    },
    ["Neon City"] = {
        SkyboxBk = "rbxassetid://1417494030",
        SkyboxDn = "rbxassetid://1417494146",
        SkyboxFt = "rbxassetid://1417494253",
        SkyboxLf = "rbxassetid://1417494402",
        SkyboxRt = "rbxassetid://1417494499",
        SkyboxUp = "rbxassetid://1417494643"
    },


    ["Troll"] = {
        SkyboxBk = "rbxassetid://1014796",
        SkyboxDn = "rbxassetid://1014796",
        SkyboxFt = "rbxassetid://1014796",
        SkyboxLf = "rbxassetid://1014796",
        SkyboxRt = "rbxassetid://1014796",
        SkyboxUp = "rbxassetid://1014796"
    },
    ["Void"] = {
        SkyboxBk = "rbxassetid://6444884337",
        SkyboxDn = "rbxassetid://6444884337",
        SkyboxFt = "rbxassetid://6444884337",
        SkyboxLf = "rbxassetid://6444884337",
        SkyboxRt = "rbxassetid://6444884337",
        SkyboxUp = "rbxassetid://6444884337"
    },


    ["Anime Girls"] = {
        SkyboxBk = "rbxassetid://105189455817751",
        SkyboxDn = "rbxassetid://105189455817751",
        SkyboxFt = "rbxassetid://105189455817751",
        SkyboxLf = "rbxassetid://105189455817751",
        SkyboxRt = "rbxassetid://105189455817751",
        SkyboxUp = "rbxassetid://105189455817751"
    },
    ["Minecraft"] = {
        SkyboxBk = "rbxassetid://2758029221",
        SkyboxDn = "rbxassetid://2758029221",
        SkyboxFt = "rbxassetid://2758029221",
        SkyboxLf = "rbxassetid://2758029221",
        SkyboxRt = "rbxassetid://2758029221",
        SkyboxUp = "rbxassetid://2758029221"
    },
    ["Aurora"] = {
        SkyboxBk = "rbxassetid://340909375",
        SkyboxDn = "rbxassetid://340909375",
        SkyboxFt = "rbxassetid://340909375",
        SkyboxLf = "rbxassetid://340909375",
        SkyboxRt = "rbxassetid://340909375",
        SkyboxUp = "rbxassetid://340909375"
    },
    ["Earth"] = {
        SkyboxBk = "rbxassetid://196277044",
        SkyboxDn = "rbxassetid://196277044",
        SkyboxFt = "rbxassetid://196277044",
        SkyboxLf = "rbxassetid://196277044",
        SkyboxRt = "rbxassetid://196277044",
        SkyboxUp = "rbxassetid://196277044"
    },
    ["City"] = {
        SkyboxBk = "rbxassetid://93768215",
        SkyboxDn = "rbxassetid://93768215",
        SkyboxFt = "rbxassetid://93768215",
        SkyboxLf = "rbxassetid://93768215",
        SkyboxRt = "rbxassetid://93768215",
        SkyboxUp = "rbxassetid://93768215"
    },
    ["Squid Game Bridge"] = {
        SkyboxBk = "rbxassetid://10232248373",
        SkyboxDn = "rbxassetid://10232248373",
        SkyboxFt = "rbxassetid://10232248373",
        SkyboxLf = "rbxassetid://10232248373",
        SkyboxRt = "rbxassetid://10232248373",
        SkyboxUp = "rbxassetid://10232248373"
    },
    ["Kawaii"] = {
        SkyboxBk = "rbxassetid://12320046362",
        SkyboxDn = "rbxassetid://12320046362",
        SkyboxFt = "rbxassetid://12320046362",
        SkyboxLf = "rbxassetid://12320046362",
        SkyboxRt = "rbxassetid://12320046362",
        SkyboxUp = "rbxassetid://12320046362"
    },
    ["FREAKBOB"] = {
        SkyboxBk = "rbxassetid://18789180567",
        SkyboxDn = "rbxassetid://18789180567",
        SkyboxFt = "rbxassetid://18789180567",
        SkyboxLf = "rbxassetid://18789180567",
        SkyboxRt = "rbxassetid://18789180567",
        SkyboxUp = "rbxassetid://18789180567"
    },
    ["Sfoth"] = {
        SkyboxBk = "rbxassetid://79471886",
        SkyboxDn = "rbxassetid://79471886",
        SkyboxFt = "rbxassetid://79471886",
        SkyboxLf = "rbxassetid://79471886",
        SkyboxRt = "rbxassetid://79471886",
        SkyboxUp = "rbxassetid://79471886"
    },
    ["Snow Mountains"] = {
        SkyboxBk = "rbxassetid://8304203797",
        SkyboxDn = "rbxassetid://8304203797",
        SkyboxFt = "rbxassetid://8304203797",
        SkyboxLf = "rbxassetid://8304203797",
        SkyboxRt = "rbxassetid://8304203797",
        SkyboxUp = "rbxassetid://8304203797"
    },
    ["Night sky"] = {
        SkyboxBk = "rbxassetid://911025794",
        SkyboxDn = "rbxassetid://911025794",
        SkyboxFt = "rbxassetid://911025794",
        SkyboxLf = "rbxassetid://911025794",
        SkyboxRt = "rbxassetid://911025794",
        SkyboxUp = "rbxassetid://911025794"
    },
    ["Pee"] = {
        SkyboxBk = "rbxassetid://11549102836",
        SkyboxDn = "rbxassetid://11549102836",
        SkyboxFt = "rbxassetid://11549102836",
        SkyboxLf = "rbxassetid://11549102836",
        SkyboxRt = "rbxassetid://11549102836",
        SkyboxUp = "rbxassetid://11549102836"
    },
    ["Nebula"] = {
        SkyboxBk = "rbxassetid://130093177270069",
        SkyboxDn = "rbxassetid://130093177270069",
        SkyboxFt = "rbxassetid://130093177270069",
        SkyboxLf = "rbxassetid://130093177270069",
        SkyboxRt = "rbxassetid://130093177270069",
        SkyboxUp = "rbxassetid://130093177270069"
    },
    ["Blackhole"] = {
        SkyboxBk = "rbxassetid://14201658516",
        SkyboxDn = "rbxassetid://14201658516",
        SkyboxFt = "rbxassetid://14201658516",
        SkyboxLf = "rbxassetid://14201658516",
        SkyboxRt = "rbxassetid://14201658516",
        SkyboxUp = "rbxassetid://14201658516"
    },
}

v.VisualsHere:AddToggle("skyboxtoggle", {
    Text = "skybox changer",
    Default = false,
    Tooltip = "change the skybox"
})

v.VisualsHere:AddDropdown("skyboxselect", {
    Values = {

        "Anime Girl", "Pastel Dream", "Pink Daylight", "Sakura Sky", "Soft Pink",
        "Cotton Candy", "Dreamy Clouds", "Lofi Night", "Chill Vibes", "Y2K Pink",
        "Vaporwave", "Midnight Pink", "Aesthetic Purple", "Kawaii Sky", "Rose Gold",
        "Fairy Lights", "Alt Girl", "Soft Grunge",

        "Sunset", "Golden Hour", "Dawn", "Dusk", "Cloudy Day", "Arctic",

        "Night Sky", "Galaxy", "Deep Space", "Purple Nebula", "Space", "Starfield", "Neon City",

        "Troll", "Void",

        "Anime Girls", "Minecraft", "Aurora", "Earth", "City", "Squid Game Bridge",
        "Kawaii", "FREAKBOB", "Sfoth", "Snow Mountains", "Night sky", "Pee", "Nebula", "Blackhole"
    },
    Default = 1,
    Multi = false,
    Text = "skybox"
})

Toggles.skyboxtoggle:OnChanged(function()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
    end

    if Toggles.skyboxtoggle.Value then
        if not v.originalSkybox.saved then
            v.originalSkybox.SkyboxBk = sky.SkyboxBk
            v.originalSkybox.SkyboxDn = sky.SkyboxDn
            v.originalSkybox.SkyboxFt = sky.SkyboxFt
            v.originalSkybox.SkyboxLf = sky.SkyboxLf
            v.originalSkybox.SkyboxRt = sky.SkyboxRt
            v.originalSkybox.SkyboxUp = sky.SkyboxUp
            v.originalSkybox.saved = true
        end

        local selected = Options.skyboxselect.Value
        local skyboxData = v.skyboxAssets[selected]
        if skyboxData then
            sky.SkyboxBk = skyboxData.SkyboxBk
            sky.SkyboxDn = skyboxData.SkyboxDn
            sky.SkyboxFt = skyboxData.SkyboxFt
            sky.SkyboxLf = skyboxData.SkyboxLf
            sky.SkyboxRt = skyboxData.SkyboxRt
            sky.SkyboxUp = skyboxData.SkyboxUp
        end
    else
        if v.originalSkybox.saved then
            sky.SkyboxBk = v.originalSkybox.SkyboxBk
            sky.SkyboxDn = v.originalSkybox.SkyboxDn
            sky.SkyboxFt = v.originalSkybox.SkyboxFt
            sky.SkyboxLf = v.originalSkybox.SkyboxLf
            sky.SkyboxRt = v.originalSkybox.SkyboxRt
            sky.SkyboxUp = v.originalSkybox.SkyboxUp
        end
    end
end)

Options.skyboxselect:OnChanged(function()
    if Toggles.skyboxtoggle.Value then
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky then
            local selected = Options.skyboxselect.Value
            local skyboxData = v.skyboxAssets[selected]
            if skyboxData then
                sky.SkyboxBk = skyboxData.SkyboxBk
                sky.SkyboxDn = skyboxData.SkyboxDn
                sky.SkyboxFt = skyboxData.SkyboxFt
                sky.SkyboxLf = skyboxData.SkyboxLf
                sky.SkyboxRt = skyboxData.SkyboxRt
                sky.SkyboxUp = skyboxData.SkyboxUp
            end
        end
    end
end)


getgenv().RainSettings = {
    Enabled = false,
    Color = Color3.fromRGB(255, 255, 255),
    Lifetime = 5,
    Rate = 1000,
    Speed = 100,
}
getgenv().SnowSettings = {
    Enabled = false,
    Color = Color3.fromRGB(255, 255, 255),
    Lifetime = 100,
    Rate = 100,
    Speed = 10,
}
local rainPart = nil
local rainEmitter = nil
local rainConnection = nil
local snowPart = nil
local snowEmitter = nil
local snowConnection = nil

local function rainParticleEmitter()
    if rainPart then
        rainPart:Destroy()
        rainPart = nil
        rainEmitter = nil
    end
    rainPart = Instance.new("Part")
    rainPart.Size = Vector3.new(51.8, 0.001, 52.084)
    rainPart.CanCollide = false
    rainPart.Anchored = true
    rainPart.Transparency = 1
    rainPart.Parent = workspace
    rainEmitter = Instance.new("ParticleEmitter")
    rainEmitter.Color = ColorSequence.new(RainSettings.Color)
    rainEmitter.LightEmission = 1
    rainEmitter.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
    rainEmitter.Size = NumberSequence.new(0.4)
    rainEmitter.Squash = NumberSequence.new(4)
    rainEmitter.Texture = "rbxassetid://129110349"
    rainEmitter.EmissionDirection = Enum.NormalId.Bottom
    rainEmitter.Lifetime = NumberRange.new(RainSettings.Lifetime)
    rainEmitter.Rate = RainSettings.Rate
    rainEmitter.Speed = NumberRange.new(RainSettings.Speed)
    rainEmitter.LockedToPart = true
    rainEmitter.Enabled = true
    rainEmitter.Parent = rainPart
end

local function snowParticleEmitter()
    if snowPart then
        snowPart:Destroy()
        snowPart = nil
        snowEmitter = nil
    end
    snowPart = Instance.new("Part")
    snowPart.Name = "SnowEmitterPart"
    snowPart.Size = Vector3.new(51.8, 0.001, 52.084)
    snowPart.Anchored = true
    snowPart.CanCollide = false
    snowPart.Transparency = 1
    snowPart.Parent = workspace
    snowEmitter = Instance.new("ParticleEmitter")
    snowEmitter.Color = ColorSequence.new(SnowSettings.Color)
    snowEmitter.EmissionDirection = Enum.NormalId.Bottom
    snowEmitter.Enabled = true
    snowEmitter.Lifetime = NumberRange.new(5, 100)
    snowEmitter.LightEmission = 0
    snowEmitter.LightInfluence = 0
    snowEmitter.LockedToPart = false
    snowEmitter.Orientation = Enum.ParticleOrientation.FacingCamera
    snowEmitter.Rate = SnowSettings.Rate
    snowEmitter.RotSpeed = NumberRange.new(360, 360)
    snowEmitter.Rotation = NumberRange.new(20, 20)
    snowEmitter.Shape = Enum.ParticleEmitterShape.Box
    snowEmitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
    snowEmitter.ShapePartial = 1
    snowEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    snowEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2, 0.4),
        NumberSequenceKeypoint.new(1, 0.2, 0.4)
    })
    snowEmitter.Speed = NumberRange.new(SnowSettings.Speed)
    snowEmitter.SpreadAngle = Vector2.new(90, 90)
    snowEmitter.Squash = NumberSequence.new(0)
    snowEmitter.Texture = "rbxassetid://129110349"
    snowEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8625),
        NumberSequenceKeypoint.new(0.15, 0),
        NumberSequenceKeypoint.new(0.196326, 0.70625),
        NumberSequenceKeypoint.new(1, 0),
    })
    snowEmitter.WindAffectsDrag = false
    snowEmitter.Parent = snowPart
end

v.RainGroup:AddToggle('RainEnabled', {
    Text = 'rain enabled',
    Default = false,
    Callback = function(Value)
        RainSettings.Enabled = Value
        if Value then
            rainParticleEmitter()
            rainConnection = RunService.Heartbeat:Connect(function()
                local camPos = Camera.CFrame.Position
                rainPart.CFrame = CFrame.new(camPos + Vector3.new(0, 30, 0))
            end)
        else
            if rainConnection then
                rainConnection:Disconnect()
                rainConnection = nil
            end
            if rainPart then
                rainPart:Destroy()
                rainPart = nil
                rainEmitter = nil
            end
        end
    end
}):AddColorPicker('RainColor', {
    Default = RainSettings.Color,
    Title = 'rain color',
    Callback = function(Value)
        RainSettings.Color = Value
        if RainSettings.Enabled then
            rainParticleEmitter()
        end
    end
})

v.RainGroup:AddSlider('RainLifetime', {
    Text = 'lifetime',
    Default = 1,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        RainSettings.Lifetime = Value
        if RainSettings.Enabled then
            rainParticleEmitter()
        end
    end
})

v.RainGroup:AddSlider('RainRate', {
    Text = 'Amount',
    Default = RainSettings.Rate,
    Min = 1,
    Max = 10000,
    Rounding = 0,
    Callback = function(Value)
        RainSettings.Rate = Value
        if RainSettings.Enabled then
            rainParticleEmitter()
        end
    end
})

v.RainGroup:AddSlider('RainSpeed', {
    Text = 'Speed',
    Default = RainSettings.Speed,
    Min = 10,
    Max = 1000,
    Rounding = 0,
    Callback = function(Value)
        RainSettings.Speed = Value
        if RainSettings.Enabled then
            rainParticleEmitter()
        end
    end
})

v.RainGroup:AddToggle('SnowEnabled', {
    Text = 'snow enabled',
    Default = false,
    Callback = function(Value)
        SnowSettings.Enabled = Value
        if Value then
            snowParticleEmitter()
            snowConnection = RunService.Heartbeat:Connect(function()
                local camPos = Camera.CFrame.Position
                snowPart.CFrame = CFrame.new(camPos + Vector3.new(0, 5, 0))
            end)
        else
            if snowConnection then
                snowConnection:Disconnect()
                snowConnection = nil
            end
            if snowPart then
                snowPart:Destroy()
                snowPart = nil
                snowEmitter = nil
            end
        end
    end
}):AddColorPicker('SnowColor', {
    Default = SnowSettings.Color,
    Title = 'snow color',
    Callback = function(Value)
        SnowSettings.Color = Value
        if SnowSettings.Enabled then
            snowParticleEmitter()
        end
    end
})

v.RainGroup:AddSlider('SnowRate', {
    Text = 'snow amount',
    Default = SnowSettings.Rate,
    Min = 1,
    Max = 1000,
    Rounding = 0,
    Callback = function(Value)
        SnowSettings.Rate = Value
        if SnowSettings.Enabled then
            snowParticleEmitter()
        end
    end
})

v.RainGroup:AddSlider('SnowSpeed', {
    Text = 'snow speed',
    Default = SnowSettings.Speed,
    Min = 1,
    Max = 1000,
    Rounding = 0,
    Callback = function(Value)
        SnowSettings.Speed = Value
        if SnowSettings.Enabled then
            snowParticleEmitter()
        end
    end
})




v.PlayersBox:AddDropdown("playerdropdown", {
    Values = GetAllPlayerNames(),
    Default = 1,
    Multi = false,
    AllowNull = true,
    Text = 'select player',
    Tooltip = 'choose a player from the dropdown'
})

v.PlayersBox:AddInput("playertextbox", {
    Text = "username/display",
    Default = "",
    Numeric = false,
    Finished = false,
    Placeholder = "type username..."
})

local function UpdateActiveToggles()
    if Toggles.viewtoggle and Toggles.viewtoggle.Value and States.TargetPlayer then
        Camera.CameraSubject = States.TargetPlayer.Character and States.TargetPlayer.Character:FindFirstChildOfClass("Humanoid")
    end

    if Toggles.playerhighlighttoggle and Toggles.playerhighlighttoggle.Value then
        if v.PlayerHighlight then
            v.PlayerHighlight:Destroy()
            v.PlayerHighlight = nil
        end

        if States.TargetPlayer and States.TargetPlayer.Character then
            v.PlayerHighlight = Instance.new("Highlight")
            v.PlayerHighlight.Name = "playerhighlight"
            v.PlayerHighlight.Adornee = States.TargetPlayer.Character
            v.PlayerHighlight.FillColor = Options.playerhighlightfill.Value
            v.PlayerHighlight.OutlineColor = Options.playerhighlightoutline.Value
            v.PlayerHighlight.FillTransparency = 0.5
            v.PlayerHighlight.OutlineTransparency = 0
            v.PlayerHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            v.PlayerHighlight.Parent = States.TargetPlayer.Character
        end
    end

    if Toggles.freezetoggle and Toggles.freezetoggle.Value and States.TargetPlayer then
        local targetRoot = States.TargetPlayer.Character and States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            targetRoot.Anchored = true
        end
    end

    if Toggles.playerorbittoggle and Toggles.playerorbittoggle.Value then
        if v.playerOrbitConnection then
            v.playerOrbitConnection:Disconnect()
        end
        if States.TargetPlayer then
            v.playerOrbitAngle = 0
            v.playerOrbitConnection = RunService.Heartbeat:Connect(function()
                if States.TargetPlayer and States.TargetPlayer.Character then
                    local targetRoot = States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local myRoot = GetRootPart()
                    if targetRoot and myRoot then
                        v.playerOrbitAngle = v.playerOrbitAngle + (Options.playerorbitspeed.Value or 0.05)
                        local distance = Options.playerorbitdistance.Value or 10
                        local height = Options.playerorbitheight.Value or 5
                        local x = math.cos(v.playerOrbitAngle) * distance
                        local z = math.sin(v.playerOrbitAngle) * distance
                        myRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(x, height, z))
                    end
                end
            end)
        end
    end

    if States.StickyAimTarget and States.StickyAimEnabled then
        UpdateStickyAimHighlight()
    end
end


v.updatingPlayerSelection = false

Options.playertextbox:OnChanged(function()
    if v.updatingPlayerSelection then return end

    local playerName = Options.playertextbox.Value

    if playerName ~= "" then
        local foundPlayer = FindPlayerByName(playerName)
        States.TargetPlayer = foundPlayer

        if foundPlayer then
            v.updatingPlayerSelection = true
            Options.playerdropdown:SetValue(foundPlayer.Name)
            v.updatingPlayerSelection = false
            UpdateActiveToggles()
        end
    else
        States.TargetPlayer = nil
        v.updatingPlayerSelection = true
        Options.playerdropdown:SetValue(nil)
        v.updatingPlayerSelection = false
    end
end)


Options.playerdropdown:OnChanged(function()
    if v.updatingPlayerSelection then return end

    local playerName = Options.playerdropdown.Value

    if playerName and playerName ~= "" then
        local foundPlayer = FindPlayerByName(playerName)
        States.TargetPlayer = foundPlayer

        if foundPlayer then
            v.updatingPlayerSelection = true
            Options.playertextbox:SetValue(foundPlayer.Name)
            v.updatingPlayerSelection = false
            UpdateActiveToggles()
        end
    else
        States.TargetPlayer = nil
        v.updatingPlayerSelection = true
        Options.playertextbox:SetValue("")
        v.updatingPlayerSelection = false
    end
end)



v.PlayersKeybind:AddToggle("chooseplayertoggle", {
    Text = "keybind set targ",
    Default = false,
    Tooltip = "automatically select nearest player"
}):AddKeyPicker("chooseplayerkey", {
    Default = "None",
    SyncToggleState = false,
    Mode = "Toggle",
    Text = "keybind set targ",
    NoUI = false
})

v.PlayersKeybind:AddToggle("playersallowuntarget", {
    Text = "allow untarget",
    Default = true,
    Tooltip = "on = press key again to deselect | off = press key again to switch to nearest player"
})

v.PlayersKeybind:AddDropdown("choosemode", {
    Values = {"nearest you", "nearest mouse"},
    Default = 1,
    Multi = false,
    Text = "detection mode"
})

local function DoChoosePlayer()
    local mode = Options.choosemode.Value
    local nearestPlayer = GetNearestPlayer(mode)
    if nearestPlayer then
        States.TargetPlayer = nearestPlayer
        Options.playerdropdown:SetValue(nearestPlayer.Name)
        Options.playertextbox:SetValue(nearestPlayer.Name)
        Library:Notify("selected " .. nearestPlayer.Name, 2)
        UpdateActiveToggles()
    else
        Library:Notify("no player found", 2)
    end
end

Toggles.chooseplayertoggle:OnChanged(function(value)
    if value then
        if States.TargetPlayer and Toggles.playersallowuntarget and Toggles.playersallowuntarget.Value then

            States.TargetPlayer = nil
            Library:Notify("deselected", 2)
            Toggles.chooseplayertoggle:SetValue(false)
        else
            DoChoosePlayer()
            Toggles.chooseplayertoggle:SetValue(false)
        end
    end
end)



v.HealthLabel = v.PlayersInfo:AddLabel("Health: ?")
v.AccountAgeLabel = v.PlayersInfo:AddLabel("Account age: ?")
v.DisplayNameLabel = v.PlayersInfo:AddLabel("Display name: ?")

v.PlayersInfo:AddToggle("makesticky", {
    Text = "make sticky",
    Default = false,
    Tooltip = "enables sticky aim on selected player"
})

Toggles.makesticky:OnChanged(function(value)
    if value and States.TargetPlayer then
        States.StickyAimTarget = States.TargetPlayer
        States.StickyAimEnabled = true
        UpdateStickyAimHighlight()
        Library:Notify("sticky aim locked to " .. States.TargetPlayer.Name, 2)
    else
        States.StickyAimEnabled = false
        States.StickyAimTarget = nil
        if v.StickyAimHighlight then
            v.StickyAimHighlight:Destroy()
            v.StickyAimHighlight = nil
        end
    end
end)

v.PlayersInfo:AddToggle("notifydeath", {
    Text = "notify death",
    Default = false,
    Tooltip = "notifies when selected player dies"
})

v.PlayersInfo:AddToggle("notifyhealthloss", {
    Text = "notify health loss",
    Default = false,
    Tooltip = "notifies when selected player loses health"
})

v.LastHealth = nil

RunService.RenderStepped:Connect(function()
    if States.TargetPlayer and States.TargetPlayer.Character then
        local humanoid = States.TargetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local currentHealth = math.floor(humanoid.Health)
            local maxHealth = math.floor(humanoid.MaxHealth)
            local healthPercent = (currentHealth / maxHealth) * 100


            local healthEmoji = ""
            v.HealthLabel:SetText("Health: " .. currentHealth .. "/" .. maxHealth)

            if Toggles.notifydeath and Toggles.notifydeath.Value then
                if currentHealth <= 0 and (v.LastHealth and v.LastHealth > 0) then
                    Library:Notify(States.TargetPlayer.Name .. " has died!")
                end
            end

            if Toggles.notifyhealthloss and Toggles.notifyhealthloss.Value then
                if v.LastHealth and currentHealth < v.LastHealth and currentHealth > 0 then
                    Library:Notify(States.TargetPlayer.Name .. " health is " .. currentHealth)
                end
            end

            v.LastHealth = currentHealth
        else
            v.HealthLabel:SetText("Health: ?")
            v.LastHealth = nil
        end

        local accountAge = States.TargetPlayer.AccountAge
        local years = math.floor(accountAge / 365)
        local months = math.floor((accountAge % 365) / 30)
        local days = accountAge % 30
        v.AccountAgeLabel:SetText("Account age: " .. years .. "y, " .. months .. "m, " .. days .. "d")

        v.DisplayNameLabel:SetText("Display name: " .. States.TargetPlayer.DisplayName)
    else
        v.HealthLabel:SetText("Health: ?")
        v.AccountAgeLabel:SetText("Account age: ?")
        v.DisplayNameLabel:SetText("Display name: ?")
        v.LastHealth = nil
    end
end)



v.PlayersActions:AddToggle("viewtoggle", {
    Text = "view",
    Default = false,
    Tooltip = "view selected player"
}):AddKeyPicker("viewkey", {
    Text = "view",
    Default = "NONE",
    SyncToggleState = true
})

Toggles.viewtoggle:OnChanged(function()
    if Toggles.viewtoggle.Value and States.TargetPlayer then
        Camera.CameraSubject = States.TargetPlayer.Character and States.TargetPlayer.Character:FindFirstChildOfClass("Humanoid")
    else
        Camera.CameraSubject = GetHumanoid()
    end
end)

v.PlayersActions:AddToggle("freezetoggle", {
    Text = "freeze",
    Default = false,
    Tooltip = "freeze selected player (clientside)"
})

Toggles.freezetoggle:OnChanged(function()
    if States.TargetPlayer and States.TargetPlayer.Character then
        local hrp = States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = Toggles.freezetoggle.Value
        end
    end
end)

v.PlayersActions:AddToggle("playersstaretoggle", {
    Text = "stare",
    Default = false,
})

RunService.RenderStepped:Connect(function()
    if not Toggles.playersstaretoggle or not Toggles.playersstaretoggle.Value then return end
    if not States.TargetPlayer or not States.TargetPlayer.Character then return end
    local root = GetRootPart()
    local targetHRP = States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not targetHRP then return end
    local lookPos = Vector3.new(targetHRP.Position.X, root.Position.Y, targetHRP.Position.Z)
    pcall(function()
        root.CFrame = CFrame.lookAt(root.Position, lookPos)
    end)
end)




v.PlayersActions:AddButton({
    Text = "fling player",
    Tooltip = "teleports inside the target player, spins to fling them for 2 seconds, then returns you",
    Func = function()
        local target = States.TargetPlayer
        if not target or not target.Character then
            Library:Notify("no player selected", 3)
            return
        end
        local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then
            Library:Notify("target has no root part", 3)
            return
        end
        local myRoot = GetRootPart()
        if not myRoot then return end

        local savedCFrame = myRoot.CFrame


        local char = Player.Character
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
            end
        end


        local noclipConn = RunService.Stepped:Connect(function()
            local c = Player.Character
            if not c then return end
            for _, part in pairs(c:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide == true then
                    part.CanCollide = false
                end
            end
        end)

        task.wait(0.1)


        myRoot.CFrame = targetHRP.CFrame


        for _, v in pairs(char:GetChildren()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
                v.Massless = true
                v.Velocity = Vector3.new(0, 0, 0)
            end
        end


        local bambam = Instance.new("BodyAngularVelocity")
        bambam.Name = "IYFlingBAVBtn"
        bambam.Parent = myRoot
        bambam.AngularVelocity = Vector3.new(0, 99999, 0)
        bambam.MaxTorque = Vector3.new(0, math.huge, 0)
        bambam.P = math.huge


        local stickConn = RunService.Heartbeat:Connect(function()
            local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            local r = GetRootPart()
            if tHRP and r then
                r.CFrame = tHRP.CFrame
            end
        end)


        local elapsed = 0
        local pulseConn
        pulseConn = RunService.Heartbeat:Connect(function(dt)
            elapsed = elapsed + dt
            local r = GetRootPart()
            if r then
                for _, v in pairs(r:GetChildren()) do
                    if v.Name == "IYFlingBAVBtn" then
                        v.AngularVelocity = Vector3.new(0, 99999, 0)
                    end
                end
            end
        end)

        task.wait(2)


        pulseConn:Disconnect()
        stickConn:Disconnect()
        noclipConn:Disconnect()
        bambam:Destroy()


        local c2 = Player.Character
        if c2 then
            for _, v in pairs(c2:GetDescendants()) do
                if v.ClassName == "Part" or v.ClassName == "MeshPart" then
                    v.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                end
            end
        end


        local r = GetRootPart()
        if r then r.CFrame = savedCFrame end
    end
})


v.PlayersOrbit:AddToggle("playerorbittoggle", {
    Text = "orbit",
    Default = false,
    Tooltip = "orbits selected player"
}):AddKeyPicker("playerorbitkey", {
    Text = "orbit",
    Default = "NONE",
    SyncToggleState = true
})

v.PlayersOrbit:AddSlider("playerorbitspeed", {
    Text = "orbit speed",
    Min = 1,
    Max = 200,
    Default = 50,
    Rounding = 0
})

v.PlayersOrbit:AddSlider("playerorbitdistance", {
    Text = "orbit distance",
    Min = 5,
    Max = 100,
    Default = 15,
    Rounding = 0
})

v.PlayersOrbit:AddSlider("playerorbitheight", {
    Text = "orbit height",
    Min = 1,
    Max = 100,
    Default = 10,
    Rounding = 0
})

v.playerOrbitAngle = 0
v.playerOrbitOriginalPosition = nil
v.playerIsLocked = false
v.playerOrbitConnection = nil

Toggles.playerorbittoggle:OnChanged(function(state)
    if state then
        local root = GetRootPart()
        if root then
            v.playerOrbitOriginalPosition = root.CFrame
        end
    else
        if v.playerOrbitConnection then
            v.playerOrbitConnection:Disconnect()
            v.playerOrbitConnection = nil
        end

        local root = GetRootPart()
        if root and v.playerOrbitOriginalPosition then
            v.playerIsLocked = true
            root.Anchored = true

            task.wait(0.9)

            root.CFrame = v.playerOrbitOriginalPosition
            root.Anchored = false
            v.playerIsLocked = false
            v.playerOrbitOriginalPosition = nil
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Toggles.playerorbittoggle and Toggles.playerorbittoggle.Value and States.TargetPlayer and States.TargetPlayer.Character and not v.playerIsLocked then
        local targetRoot = States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local root = GetRootPart()

        if targetRoot and root then
            v.playerOrbitAngle = v.playerOrbitAngle + (Options.playerorbitspeed.Value / 100)
            local radius = Options.playerorbitdistance.Value
            local height = Options.playerorbitheight.Value
            local x = math.sin(v.playerOrbitAngle) * radius
            local z = math.cos(v.playerOrbitAngle) * radius
            root.CFrame = CFrame.new(targetRoot.Position + Vector3.new(x, height, z), targetRoot.Position)
        end
    end
end)



v.PlayersHitbox:AddToggle("hitboxtoggle", {
    Text = "hitbox expand",
    Default = false,
    Tooltip = "expand their hitbox"
}):AddKeyPicker("hitboxkey", {
    Text = "hitbox expand",
    Default = "NONE",
    SyncToggleState = true
}):AddColorPicker("hitboxcolor", {
    Default = Color3.new(1, 1, 1),
    Title = "hitbox color"
})

v.PlayersHitbox:AddToggle("hitboxtransparent", {
    Text = "transparent",
    Default = false,
    Tooltip = "makes the hitbox part transparent"
})

v.PlayersHitbox:AddSlider("hitboxsize", {
    Text = "hitbox size",
    Min = 1,
    Max = 1000,
    Default = 20,
    Rounding = 0
})

v.PlayersHitbox:AddDropdown("hitboxshape", {
    Values = {'square', 'cube', 'sphere'},
    Default = 1,
    Multi = false,
    Text = 'hitbox shape'
})

v.PlayersHitbox:AddToggle("hitboxcollidetoggle", {
    Text = "collide",
    Default = false,
    Tooltip = "whether u collide with the hitbox expand or not"
})

v.HitboxPart = nil
v.HitboxConnection = nil

local function ClearHitbox()
    if v.HitboxConnection then
        v.HitboxConnection:Disconnect()
        v.HitboxConnection = nil
    end
    if v.HitboxPart then
        v.HitboxPart:Destroy()
        v.HitboxPart = nil
    end
    if States.TargetPlayer and States.TargetPlayer.Character then
        local hrp = States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Size = Vector3.new(2, 2, 1)
            hrp.Transparency = 1
        end
    end
end

local function UpdateHitbox()
    ClearHitbox()

    if not Toggles.hitboxtoggle or not Toggles.hitboxtoggle.Value then return end
    if not States.TargetPlayer or not States.TargetPlayer.Character then return end

    local hrp = States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local size = Options.hitboxsize.Value
    local shape = Options.hitboxshape.Value
    local color = Options.hitboxcolor.Value
    local canCollide = Toggles.hitboxcollidetoggle.Value
    local isTransparent = Toggles.hitboxtransparent.Value

    hrp.Size = Vector3.new(size, size, size)
    hrp.Transparency = isTransparent and 1 or 0.5
    hrp.CanCollide = canCollide
    hrp.Massless = true

    v.HitboxPart = Instance.new("Part")
    v.HitboxPart.Anchored = true
    v.HitboxPart.CanCollide = false
    v.HitboxPart.Transparency = isTransparent and 1 or 0.7
    v.HitboxPart.Material = Enum.Material.Neon
    v.HitboxPart.Color = color
    v.HitboxPart.Name = "hitboxpart"

    if shape == "sphere" then
        v.HitboxPart.Shape = Enum.PartType.Ball
        v.HitboxPart.Size = Vector3.new(size, size, size)
    elseif shape == "cube" then
        v.HitboxPart.Shape = Enum.PartType.Block
        v.HitboxPart.Size = Vector3.new(size, size, size)
    elseif shape == "square" then
        v.HitboxPart.Shape = Enum.PartType.Block
        v.HitboxPart.Size = Vector3.new(size, 0.5, size)
    end

    v.HitboxPart.CFrame = hrp.CFrame
    v.HitboxPart.Parent = workspace

    v.HitboxConnection = RunService.Heartbeat:Connect(function()
        if States.TargetPlayer and States.TargetPlayer.Character and hrp and hrp.Parent then
            v.HitboxPart.CFrame = hrp.CFrame
        else
            ClearHitbox()
        end
    end)
end

Toggles.hitboxtoggle:OnChanged(function()
    UpdateHitbox()
end)

Toggles.hitboxtransparent:OnChanged(function()
    if Toggles.hitboxtoggle.Value then
        UpdateHitbox()
    end
end)

Options.hitboxsize:OnChanged(function()
    if Toggles.hitboxtoggle.Value then
        UpdateHitbox()
    end
end)

Options.hitboxshape:OnChanged(function()
    if Toggles.hitboxtoggle.Value then
        UpdateHitbox()
    end
end)

Options.hitboxcolor:OnChanged(function()
    if v.HitboxPart then
        v.HitboxPart.Color = Options.hitboxcolor.Value
    end
end)

Toggles.hitboxcollidetoggle:OnChanged(function()
    if States.TargetPlayer and States.TargetPlayer.Character then
        local hrp = States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CanCollide = Toggles.hitboxcollidetoggle.Value
        end
    end
end)



v.PlayerHighlight = nil

v.PlayersVisuals:AddToggle("playerhighlighttoggle", {
    Text = "highlight",
    Default = false,
    Tooltip = "highlights selected player"
}):AddColorPicker("playerhighlightfill", {
    Default = Color3.new(1, 1, 1),
    Title = "fill color"
}):AddColorPicker("playerhighlightoutline", {
    Default = Color3.new(1, 1, 1),
    Title = "outline color"
})

Toggles.playerhighlighttoggle:OnChanged(function()
    if v.PlayerHighlight then
        v.PlayerHighlight:Destroy()
        v.PlayerHighlight = nil
    end

    if Toggles.playerhighlighttoggle.Value and States.TargetPlayer and States.TargetPlayer.Character then
        v.PlayerHighlight = Instance.new("Highlight")
        v.PlayerHighlight.Name = "playerhighlight"
        v.PlayerHighlight.Adornee = States.TargetPlayer.Character
        v.PlayerHighlight.FillColor = Options.playerhighlightfill.Value
        v.PlayerHighlight.OutlineColor = Options.playerhighlightoutline.Value
        v.PlayerHighlight.FillTransparency = 0.5
        v.PlayerHighlight.OutlineTransparency = 0
        v.PlayerHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        v.PlayerHighlight.Parent = States.TargetPlayer.Character
    end
end)

Options.playerhighlightfill:OnChanged(function()
    if v.PlayerHighlight then
        v.PlayerHighlight.FillColor = Options.playerhighlightfill.Value
    end
end)

Options.playerhighlightoutline:OnChanged(function()
    if v.PlayerHighlight then
        v.PlayerHighlight.OutlineColor = Options.playerhighlightoutline.Value
    end
end)

v.PlayersVisuals:AddToggle("playertracertoggle", {
    Text = "tracer",
    Default = false,
    Tooltip = "tracer from your mouse to their head"
}):AddColorPicker("playertracercolor", {
    Default = Color3.new(1, 1, 1),
    Title = "tracer color"
})

v.PlayerTracerLine = nil
v.PlayerTracerAttachment0 = nil
v.PlayerTracerAttachment1 = nil
v.PlayerTracerPart = nil

RunService.RenderStepped:Connect(function()
    if Toggles.playertracertoggle and Toggles.playertracertoggle.Value and States.TargetPlayer and States.TargetPlayer.Character then
        local targetHead = States.TargetPlayer.Character:FindFirstChild("Head")
        local mouse = game.Players.LocalPlayer:GetMouse()

        if targetHead and mouse then
            if not v.PlayerTracerLine then
                v.PlayerTracerAttachment0 = Instance.new("Attachment")
                v.PlayerTracerAttachment1 = Instance.new("Attachment")

                v.PlayerTracerLine = Instance.new("Beam")
                v.PlayerTracerLine.Attachment0 = v.PlayerTracerAttachment0
                v.PlayerTracerLine.Attachment1 = v.PlayerTracerAttachment1
                v.PlayerTracerLine.Color = ColorSequence.new(Options.playertracercolor.Value)
                v.PlayerTracerLine.Width0 = 0.1
                v.PlayerTracerLine.Width1 = 0.1
                v.PlayerTracerLine.FaceCamera = true

                v.PlayerTracerPart = Instance.new("Part")
                v.PlayerTracerPart.Anchored = true
                v.PlayerTracerPart.CanCollide = false
                v.PlayerTracerPart.Transparency = 1
                v.PlayerTracerPart.Size = Vector3.new(0.1, 0.1, 0.1)
                v.PlayerTracerPart.Parent = workspace

                v.PlayerTracerAttachment0.Parent = targetHead
                v.PlayerTracerAttachment1.Parent = v.PlayerTracerPart
                v.PlayerTracerLine.Parent = targetHead
            end

            v.PlayerTracerPart.Position = mouse.Hit.Position
            v.PlayerTracerLine.Color = ColorSequence.new(Options.playertracercolor.Value)
        end
    else
        if v.PlayerTracerLine then
            v.PlayerTracerLine:Destroy()
            v.PlayerTracerAttachment0:Destroy()
            v.PlayerTracerAttachment1:Destroy()
            v.PlayerTracerPart:Destroy()
            v.PlayerTracerLine = nil
            v.PlayerTracerAttachment0 = nil
            v.PlayerTracerAttachment1 = nil
            v.PlayerTracerPart = nil
        end
    end
end)



v.PlayersAimbot:AddToggle("camlocktoggle", {
    Text = "camlock",
    Default = false,
    Tooltip = "tracks selected player head with camera"
}):AddKeyPicker("camlockkey", {
    Default = "NONE",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "camlock selected player",
    NoUI = false
})

v.PlayersAimbot:AddToggle("copyaimbotsettings", {
    Text = "copy exact sets",
    Default = false,
    Tooltip = "copies exact settings from aimbot tab"
})

RunService.RenderStepped:Connect(function()
    if Toggles.camlocktoggle and Toggles.camlocktoggle.Value then
        local targetPlayer = States.TargetPlayer

        if targetPlayer and targetPlayer.Character then
            local targetPart = targetPlayer.Character:FindFirstChild(v.CamlockStates.TargetPart or "Head")
            if targetPart then
                if Toggles.copyaimbotsettings and Toggles.copyaimbotsettings.Value then

                    if v.CamlockStates.Prediction then
                        local velocity = targetPart.AssemblyLinearVelocity
                        local predictedPos = targetPart.Position + (velocity * v.CamlockStates.PredictionAmount)
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, predictedPos)
                    else
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                    end
                else
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                end
            end
        end
    end
end)



v.PlayersTriggerbot:AddToggle("triggerbottoggle", {
    Text = "triggerbot",
    Default = false,
    Tooltip = "auto clicks when mouse is on selected player"
}):AddKeyPicker("triggerbotkey", {
    Text = "triggerbot",
    Default = "NONE",
    SyncToggleState = true
})

v.PlayersTriggerbot:AddToggle("copytriggerbotsettings", {
    Text = "copy exact sets",
    Default = false,
    Tooltip = "copies exact settings from triggerbot tab"
})

v.playerTriggerbotLastClick = 0

RunService.RenderStepped:Connect(function()
    if Toggles.triggerbottoggle and Toggles.triggerbottoggle.Value and States.TargetPlayer then
        local mouse = game.Players.LocalPlayer:GetMouse()
        local delay = Toggles.copytriggerbotsettings.Value and (v.TriggerbotStates.Delay / 1000) or 0.1

        if tick() - v.playerTriggerbotLastClick < delay then return end

        if mouse.Target then
            local targetChar = mouse.Target:FindFirstAncestorOfClass("Model")
            if targetChar then
                local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
                if targetPlayer and targetPlayer == States.TargetPlayer then
                    local chance = Toggles.copytriggerbotsettings.Value and v.TriggerbotStates.Chance or 100
                    if math.random(1, 100) <= chance then
                        mouse1click()
                        v.playerTriggerbotLastClick = tick()
                    end
                end
            end
        end
    end
end)



v.PlayersTp:AddToggle("looptptoggle", {
    Text = "loop teleport",
    Default = false,
    Tooltip = "continuously teleport to selected player"
})

v.PlayersTp:AddDropdown("looptpdirection", {
    Values = {'behind', 'underground', 'infront'},
    Default = 1,
    Multi = false,
    Text = 'tp direction'
})

v.PlayersTp:AddSlider("looptpoffsetx", {
    Text = "offset x",
    Min = -50,
    Max = 50,
    Default = 0,
    Rounding = 1,
    Compact = false
})

v.PlayersTp:AddSlider("looptpoffsety", {
    Text = "offset y",
    Min = -50,
    Max = 50,
    Default = 0,
    Rounding = 1,
    Compact = false
})

v.PlayersTp:AddSlider("looptpoffsetz", {
    Text = "offset z",
    Min = -50,
    Max = 50,
    Default = 0,
    Rounding = 1,
    Compact = false
})

v.loopTpConnection = nil

Toggles.looptptoggle:OnChanged(function(enabled)
    if enabled then
        v.loopTpConnection = task.spawn(function()
            while Toggles.looptptoggle.Value do
                if States.TargetPlayer and States.TargetPlayer.Character then
                    local targetRoot = States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local root = GetRootPart()

                    if targetRoot and root then
                        local direction = Options.looptpdirection.Value
                        local offsetX = Options.looptpoffsetx.Value
                        local offsetY = Options.looptpoffsety.Value
                        local offsetZ = Options.looptpoffsetz.Value
                        local customOffset = Vector3.new(offsetX, offsetY, offsetZ)
                        local offset

                        if direction == 'behind' then
                            offset = targetRoot.CFrame.LookVector * -5
                            root.CFrame = CFrame.new(targetRoot.Position + offset + customOffset, targetRoot.Position)
                        elseif direction == 'underground' then
                            offset = Vector3.new(0, -10, 0)
                            root.CFrame = CFrame.new(targetRoot.Position + offset + customOffset)
                        elseif direction == 'infront' then
                            offset = targetRoot.CFrame.LookVector * 5
                            root.CFrame = CFrame.new(targetRoot.Position + offset + customOffset, targetRoot.Position)
                        end

                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        if v.loopTpConnection then
            task.cancel(v.loopTpConnection)
            v.loopTpConnection = nil
        end
        local root = GetRootPart()
        if root then
            root.Anchored = false
        end
    end
end)



v.PlayersButtons:AddButton({
    Text = "copy userId",
    Func = function()
        if States.TargetPlayer then
            setclipboard(tostring(States.TargetPlayer.UserId))
            Library:Notify("copied userid: " .. States.TargetPlayer.UserId, 3)
        else
            Library:Notify("no player selected", 3)
        end
    end
})

v.PlayersButtons:AddButton({
    Text = "copy username",
    Func = function()
        if States.TargetPlayer then
            setclipboard(States.TargetPlayer.Name)
            Library:Notify("copied username to clipboard: " .. States.TargetPlayer.Name, 3)
        else
            Library:Notify("no player selected", 3)
        end
    end
})

v.PlayersButtons:AddButton({
    Text = "goto | tp",
    Func = function()
        if States.TargetPlayer and States.TargetPlayer.Character then
            local targetRoot = States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local root = GetRootPart()

            if targetRoot and root then
                root.CFrame = targetRoot.CFrame
                Library:Notify("teleported to player", 2)
            end
        else
            Library:Notify("no player selected", 3)
        end
    end
})

v.PlayersButtons:AddButton({
    Text = "tween tp",
    Func = function()
        if States.TargetPlayer and States.TargetPlayer.Character then
            local targetRoot = States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local root = GetRootPart()

            if targetRoot and root then
                local TweenService = game:GetService("TweenService")
                local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)
                local tween = TweenService:Create(root, tweenInfo, {CFrame = targetRoot.CFrame})
                tween:Play()
                Library:Notify("tweening to player", 2)
            end
        else
            Library:Notify("no player selected", 3)
        end
    end
})

v.sendFriendClicks = 0
v.PlayersButtons:AddButton({
    Text = "friend request",
    Func = function()
        if States.TargetPlayer then
            v.sendFriendClicks = v.sendFriendClicks + 1

            if v.sendFriendClicks == 1 then
                Library:Notify("click again to confirm", 2)
                task.wait(3)
                v.sendFriendClicks = 0
            elseif v.sendFriendClicks >= 2 then
                game.Players.LocalPlayer:RequestFriendship(States.TargetPlayer)
                Library:Notify("sent friend request to " .. States.TargetPlayer.Name, 3)
                v.sendFriendClicks = 0
            end
        else
            Library:Notify("no player selected", 3)
        end
    end
})

v.unfriendClicks = 0
v.PlayersButtons:AddButton({
    Text = "unfriend",
    Func = function()
        if States.TargetPlayer then
            v.unfriendClicks = v.unfriendClicks + 1

            if v.unfriendClicks == 1 then
                Library:Notify("click again to confirm", 2)
                task.wait(3)
                v.unfriendClicks = 0
            elseif v.unfriendClicks >= 2 then
                game.Players.LocalPlayer:RevokeFriendship(States.TargetPlayer)
                Library:Notify("unfriended " .. States.TargetPlayer.Name, 3)
                v.unfriendClicks = 0
            end
        else
            Library:Notify("no player selected", 3)
        end
    end
})

v.PlayersButtons:AddButton({
    Text = "copy coordinates",
    Func = function()
        if States.TargetPlayer and States.TargetPlayer.Character then
            local targetRoot = States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local pos = targetRoot.Position
                local coords = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
                setclipboard(coords)
                Library:Notify("copied coordinates: " .. coords, 3)
            else
                Library:Notify("player has no HumanoidRootPart", 3)
            end
        else
            Library:Notify("no player selected", 3)
        end
    end
})


Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    if Options.playerdropdown then
        Options.playerdropdown:SetValues(GetAllPlayerNames())
    end
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    if Options.playerdropdown then
        Options.playerdropdown:SetValues(GetAllPlayerNames())
    end
end)

v.CamlockStates = {
    Enabled = false,
    LockedPlayer = nil,
    LastSwitchedPlayer = nil,
    TargetPart = 'Head',
    Smoothing = false,
    SmoothAmount = 0.5,
    Prediction = false,
    PredictionAmount = 0.13,
    DistanceCheck = false,
    MaxDistance = 100,
    Mode = 'near you',
    HighlightEnabled = false,
    NearMouseEnabled = false,
    MouseDistance = 100,
    HighlightEnabled = false,
    HighlightColor = Color3.fromRGB(255, 255, 255),
    HighlightOutlineColor = Color3.fromRGB(255, 255, 255),
    OrbitEnabled = false,
    OrbitRadius = 8,
    OrbitSpeed = 30,
    OrbitDistance = 8,
    OrbitHeight = 0,
    OrbitOriginalPosition = nil,
    OrbitOriginalCameraOffset = nil,
    FovEnabled = false,
    FovFilled = false,
    FovFillColor = Color3.fromRGB(255, 255, 255),
    FovSize = 100,
    FovShape = 'circle',
    FovMouseFollow = true,
    StopOnFovExit = false,
    StopIfDies = false,
    SwitchOnDeath = false,
    VisibleCheck = false,
    TeamCheck = false,
    WhitelistedPlayers = {}
}

v.TriggerbotStates = {
    Enabled = false,
    ToolOnly = false,
    VisibleCheck = false,
    TeamCheck = false,
    WhitelistedPlayers = {},
    Chance = 100,
    Delay = 0,
    LastShot = 0
}

v.ESPWhitelistedPlayers = {}

v.TeleportStates = {
    SavedTeleports = {},
    SelectedTP = nil,
    TweenEnabled = false,
    TweenSpeed = 5,
    TPKeybindEnabled = false,
    MouseTPEnabled = false
}

v.CamlockHighlight = nil
v.orbitAngleCamlock = 0

v.FovCircle = Drawing.new("Circle")
v.FovCircle.Thickness = 2
v.FovCircle.NumSides = 64
v.FovCircle.Radius = 100
v.FovCircle.Filled = false
v.FovCircle.Transparency = 1
v.FovCircle.Color = Color3.fromRGB(255, 255, 255)
v.FovCircle.Visible = false

v.FovCircleOutline = Drawing.new("Circle")
v.FovCircleOutline.Thickness = 2
v.FovCircleOutline.NumSides = 64
v.FovCircleOutline.Radius = 100
v.FovCircleOutline.Filled = false
v.FovCircleOutline.Transparency = 1
v.FovCircleOutline.Color = Color3.fromRGB(255, 255, 255)
v.FovCircleOutline.Visible = false

v.FovCurrentPos = Vector2.new(0, 0)
v.FovCurrentRadius = 0

v.FovShapeLines = {}
for i = 1, 20 do
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Transparency = 1
    line.Color = Color3.fromRGB(255, 255, 255)
    line.Visible = false
    table.insert(v.FovShapeLines, line)
end

local function GetMousePosition()
    return UserInputService:GetMouseLocation()
end

local function GetScreenCenter()
    local viewportSize = Camera.ViewportSize
    return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
end

local function GetScreenPosition(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function IsVisible(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end

    local targetPart = targetPlayer.Character:FindFirstChild(v.CamlockStates.TargetPart) or targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return false end

    local myRoot = GetRootPart()
    if not myRoot then return false end

    local ray = Ray.new(myRoot.Position, (targetPart.Position - myRoot.Position).Unit * (targetPart.Position - myRoot.Position).Magnitude)
    local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, {Player.Character, targetPlayer.Character})

    return hit == nil or hit:IsDescendantOf(targetPlayer.Character)
end

local function IsSameTeam(targetPlayer)
    if not targetPlayer then return false end

    local localPlayer = game.Players.LocalPlayer
    if localPlayer.Team == nil or targetPlayer.Team == nil then
        return false
    end

    return localPlayer.Team == targetPlayer.Team
end

local function IsCamlockWhitelisted(player)
    if not player then return false end
    for _, whitelistedName in pairs(v.CamlockStates.WhitelistedPlayers) do
        if whitelistedName == player.Name then
            return true
        end
    end
    return false
end

local function IsTriggerbotWhitelisted(player)
    if not player then return false end
    for _, whitelistedName in pairs(v.TriggerbotStates.WhitelistedPlayers) do
        if whitelistedName == player.Name then
            return true
        end
    end
    return false
end

local function DisableOrbit()
    if v.CamlockStates.OrbitOriginalPosition then
        local myRoot = GetRootPart()
        if myRoot then
            myRoot.Anchored = true
            myRoot.CFrame = v.CamlockStates.OrbitOriginalPosition

            if myRoot:FindFirstChild("AssemblyLinearVelocity") then
                myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            if myRoot:FindFirstChild("Velocity") then
                myRoot.Velocity = Vector3.new(0, 0, 0)
            end

            task.wait(0.2)
            myRoot.Anchored = false
        end
        v.CamlockStates.OrbitOriginalPosition = nil
    end

    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = GetHumanoid()
end

local function GetDistanceFromMouse(player)
    if not player.Character then return math.huge end
    local targetPart = player.Character:FindFirstChild(v.CamlockStates.TargetPart) or player.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return math.huge end

    local screenPos, onScreen = GetScreenPosition(targetPart.Position)
    if not onScreen then return math.huge end

    local mousePos = GetMousePosition()
    return (screenPos - mousePos).Magnitude
end

local function GetDistanceFromPlayer(player)
    if not player.Character then return math.huge end
    local targetPart = player.Character:FindFirstChild(v.CamlockStates.TargetPart) or player.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return math.huge end

    local myRoot = GetRootPart()
    if not myRoot then return math.huge end

    return (myRoot.Position - targetPart.Position).Magnitude
end

local function GetShapePoints(centerX, centerY, radius, shape)
    local points = {}

    if shape == 'circle' then
        return nil
    elseif shape == 'pentagon' then
        for i = 1, 5 do
            local angle = (i / 5) * math.pi * 2 - math.pi / 2
            local x = centerX + math.cos(angle) * radius
            local y = centerY + math.sin(angle) * radius
            table.insert(points, Vector2.new(x, y))
        end
    elseif shape == 'heart' then
        for i = 0, 20 do
            local t = (i / 20) * math.pi * 2
            local x = 16 * math.sin(t)^3
            local y = -(13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t))
            local scale = radius / 17
            table.insert(points, Vector2.new(centerX + x * scale, centerY + y * scale))
        end
    elseif shape == 'star' then
        for i = 1, 10 do
            local angle = (i / 10) * math.pi * 2 - math.pi / 2
            local r = (i % 2 == 1) and radius or (radius * 0.4)
            local x = centerX + math.cos(angle) * r
            local y = centerY + math.sin(angle) * r
            table.insert(points, Vector2.new(x, y))
        end
    end

    return points
end

local function UpdateFovShape()
    local targetPos = v.CamlockStates.FovMouseFollow and GetMousePosition() or GetScreenCenter()
    local targetRadius = v.CamlockStates.FovSize

    local lerpSpeed = Options.camlockfovlerp and Options.camlockfovlerp.Value or 1
    v.FovCurrentPos = v.FovCurrentPos:Lerp(targetPos, lerpSpeed)
    v.FovCurrentRadius = v.FovCurrentRadius + (targetRadius - v.FovCurrentRadius) * lerpSpeed

    local centerPos = v.FovCurrentPos
    local shape = v.CamlockStates.FovShape
    local radius = v.FovCurrentRadius
    local color = Options.fovcolor.Value

    if shape == 'circle' then
        v.FovCircle.Visible = v.CamlockStates.FovEnabled
        v.FovCircle.Position = centerPos
        v.FovCircle.Radius = radius

        v.FovCircleOutline.Visible = v.CamlockStates.FovEnabled
        v.FovCircleOutline.Position = centerPos
        v.FovCircleOutline.Radius = radius
        v.FovCircleOutline.Color = color
        v.FovCircleOutline.Filled = false
        v.FovCircleOutline.Transparency = 1

        if v.CamlockStates.FovFilled then
            v.FovCircle.Filled = true
            v.FovCircle.Transparency = 0.1
            v.FovCircle.Color = Options.fovfillcolor.Value
        else
            v.FovCircle.Filled = false
            v.FovCircle.Transparency = 1
            v.FovCircle.Color = color
        end

        for _, line in pairs(v.FovShapeLines) do
            line.Visible = false
        end
    else
        v.FovCircle.Visible = false
        v.FovCircleOutline.Visible = false

        local points = GetShapePoints(centerPos.X, centerPos.Y, radius, shape)
        if points then
            for i = 1, #points do
                local line = v.FovShapeLines[i]
                if line then
                    local nextIndex = (i % #points) + 1
                    line.From = points[i]
                    line.To = points[nextIndex]
                    line.Color = color
                    line.Transparency = 1
                    line.Visible = v.CamlockStates.FovEnabled
                end
            end

            for i = #points + 1, #v.FovShapeLines do
                v.FovShapeLines[i].Visible = false
            end
        end
    end
end

local function IsInFov(player)
    if not v.CamlockStates.FovEnabled then return true end

    if not player.Character then return false end
    local targetPart = player.Character:FindFirstChild(v.CamlockStates.TargetPart) or player.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return false end

    local screenPos, onScreen = GetScreenPosition(targetPart.Position)
    if not onScreen then return false end

    local centerPos = v.CamlockStates.FovMouseFollow and GetMousePosition() or GetScreenCenter()
    local distance = (screenPos - centerPos).Magnitude

    return distance <= v.CamlockStates.FovSize
end

local function GetNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            if IsCamlockWhitelisted(player) then
                continue
            end

            if v.CamlockStates.TeamCheck and IsSameTeam(player) then
                continue
            end

            if v.CamlockStates.VisibleCheck and not IsVisible(player) then
                continue
            end

            if not IsInFov(player) then
                continue
            end

            local distance

            if v.CamlockStates.Mode == 'near mouse' then
                distance = GetDistanceFromMouse(player)
            else
                distance = GetDistanceFromPlayer(player)
            end

            if distance < shortestDistance then
                shortestDistance = distance
                nearestPlayer = player
            end
        end
    end

    return nearestPlayer
end

local function UpdateHighlight()
    if v.CamlockHighlight then
        v.CamlockHighlight:Destroy()
        v.CamlockHighlight = nil
    end

    if v.CamlockStates.HighlightEnabled and v.CamlockStates.LockedPlayer and v.CamlockStates.LockedPlayer.Character then
        v.CamlockHighlight = Instance.new("Highlight")
        v.CamlockHighlight.Name = "CamlockHighlight"
        v.CamlockHighlight.Adornee = v.CamlockStates.LockedPlayer.Character
        v.CamlockHighlight.FillColor = v.CamlockStates.HighlightColor
        v.CamlockHighlight.OutlineColor = v.CamlockStates.HighlightOutlineColor
        v.CamlockHighlight.FillTransparency = 0.5
        v.CamlockHighlight.OutlineTransparency = 0
        v.CamlockHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        v.CamlockHighlight.Parent = v.CamlockStates.LockedPlayer.Character
    end
end

local function HasToolEquipped()
    local char = game.Players.LocalPlayer.Character
    if not char then return false end

    for _, item in pairs(char:GetChildren()) do
        if item:IsA("Tool") then
            return true
        end
    end
    return false
end

local function GetPlayerUnderMouse()
    local mouse = game.Players.LocalPlayer:GetMouse()
    local target = mouse.Target

    if target then
        local character = target:FindFirstAncestorOfClass("Model")
        if character then
            local player = game.Players:GetPlayerFromCharacter(character)
            if player and player ~= game.Players.LocalPlayer then
                return player
            end
        end
    end
    return nil
end

task.spawn(function()
    while task.wait(0.1) do
        if v.TriggerbotStates.Enabled then
            if v.TriggerbotStates.ToolOnly and not HasToolEquipped() then
                continue
            end

            local targetPlayer = nil

            if States.StickyAimEnabled then
                targetPlayer = States.StickyAimTarget

                if targetPlayer and targetPlayer.Character then
                    local mouse = game.Players.LocalPlayer:GetMouse()
                    if mouse.Target and mouse.Target:IsDescendantOf(targetPlayer.Character) then
                        local chance = v.TriggerbotStates.Chance or 100
                        if math.random(1, 100) <= chance then
                            local currentTime = tick()
                            if currentTime - v.TriggerbotStates.LastShot >= 0.2 then
                                local delay = (v.TriggerbotStates.Delay or 0) / 1000
                                if delay > 0 then task.wait(delay) end
                                mouse1press()


                                task.wait(0.05)
                                mouse1release()
                                v.TriggerbotStates.LastShot = tick()
                            end
                        end
                    end
                end
            else
                targetPlayer = GetPlayerUnderMouse()
                if targetPlayer then
                    if IsTriggerbotWhitelisted(targetPlayer) then
                        continue
                    end

                    if v.TriggerbotStates.TeamCheck and IsSameTeam(targetPlayer) then
                        continue
                    end

                    if v.TriggerbotStates.VisibleCheck and not IsVisible(targetPlayer) then
                        continue
                    end

                    local chance = v.TriggerbotStates.Chance or 100
                    if math.random(1, 100) <= chance then
                        local currentTime = tick()
                        if currentTime - v.TriggerbotStates.LastShot >= 0.2 then
                            local delay = (v.TriggerbotStates.Delay or 0) / 1000
                            if delay > 0 then task.wait(delay) end
                            mouse1press()
                            task.wait(0.05)
                            mouse1release()
                            v.TriggerbotStates.LastShot = tick()
                        end
                    end
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if v.CamlockStates.FovEnabled then
        UpdateFovShape()
    else
        v.FovCircle.Visible = false
        v.FovCircleOutline.Visible = false
        for _, line in pairs(v.FovShapeLines) do
            line.Visible = false
        end
    end

    if v.CamlockStates.Enabled then
        local target = nil

        if States.StickyAimEnabled and States.StickyAimTarget then
            target = States.StickyAimTarget
        else
            target = v.CamlockStates.LockedPlayer
        end

        if not target then return end

        if not target or not target.Character or not target.Character:FindFirstChild("Humanoid") or target.Character.Humanoid.Health <= 0 then
            if v.CamlockStates.StopIfDies then
                v.CamlockStates.LockedPlayer = nil
                v.CamlockStates.LastSwitchedPlayer = nil
                if v.CamlockHighlight then
                    v.CamlockHighlight:Destroy()
                    v.CamlockHighlight = nil
                end
                if v.CamlockStates.OrbitEnabled then
                    DisableOrbit()
                end
                Library:Notify('target died - camlock stopped')
            elseif v.CamlockStates.SwitchOnDeath then

                if v.CamlockStates.LastSwitchedPlayer ~= target then
                    local newTarget = GetNearestPlayer("nearest you")
                    if newTarget and newTarget ~= target then
                        v.CamlockStates.LastSwitchedPlayer = target
                        v.CamlockStates.LockedPlayer = newTarget
                        Library:Notify('switched to ' .. newTarget.Name)
                        UpdateHighlight()
                    else
                        v.CamlockStates.LockedPlayer = nil
                        v.CamlockStates.LastSwitchedPlayer = nil
                        Library:Notify('no new target found')
                        if v.CamlockHighlight then
                            v.CamlockHighlight:Destroy()
                            v.CamlockHighlight = nil
                        end
                        if v.CamlockStates.OrbitEnabled then
                            DisableOrbit()
                        end
                    end
                end
            end
            return
        end

        if v.CamlockStates.Mode == 'near mouse' then
            if v.CamlockStates.NearMouseEnabled then
                local mouseDist = GetDistanceFromMouse(target)
                if mouseDist > v.CamlockStates.MouseDistance then
                    if v.CamlockStates.StopIfDies then
                        v.CamlockStates.LockedPlayer = nil
                        if v.CamlockHighlight then
                            v.CamlockHighlight:Destroy()
                            v.CamlockHighlight = nil
                        end
                        Library:Notify('target out of mouse range')
                        return
                    elseif v.CamlockStates.SwitchOnDeath then

                        if v.CamlockStates.LastSwitchedPlayer ~= target then
                            local newTarget = GetNearestPlayer("nearest you")
                            if newTarget and newTarget ~= target then
                                v.CamlockStates.LastSwitchedPlayer = target
                                v.CamlockStates.LockedPlayer = newTarget
                                Library:Notify('switched target - old one out of range')
                                UpdateHighlight()
                            else
                                v.CamlockStates.LockedPlayer = nil
                                v.CamlockStates.LastSwitchedPlayer = nil
                                if v.CamlockHighlight then
                                    v.CamlockHighlight:Destroy()
                                    v.CamlockHighlight = nil
                                end
                                Library:Notify('target out of mouse range')
                                return
                            end
                        end
                    end
                end
            end
        else
            if v.CamlockStates.DistanceCheck then
                local playerDist = GetDistanceFromPlayer(target)
                if playerDist > v.CamlockStates.MaxDistance then
                    if v.CamlockStates.StopIfDies then
                        v.CamlockStates.LockedPlayer = nil
                        if v.CamlockHighlight then
                            v.CamlockHighlight:Destroy()
                            v.CamlockHighlight = nil
                        end
                        Library:Notify('target too far')
                        return
                    elseif v.CamlockStates.SwitchOnDeath then

                        if v.CamlockStates.LastSwitchedPlayer ~= target then
                            local newTarget = GetNearestPlayer("nearest you")
                            if newTarget and newTarget ~= target then
                                v.CamlockStates.LastSwitchedPlayer = target
                                v.CamlockStates.LockedPlayer = newTarget
                                Library:Notify('switched target old one too far')
                                UpdateHighlight()
                            else
                                v.CamlockStates.LockedPlayer = nil
                                v.CamlockStates.LastSwitchedPlayer = nil
                                if v.CamlockHighlight then
                                    v.CamlockHighlight:Destroy()
                                    v.CamlockHighlight = nil
                                end
                                Library:Notify('target too far')
                                return
                            end
                        end
                    end
                end
            end
        end

        if v.CamlockStates.StopOnFovExit then
            if v.CamlockStates.FovEnabled and not IsInFov(target) then
                v.CamlockStates.LockedPlayer = nil
                if v.CamlockHighlight then
                    v.CamlockHighlight:Destroy()
                    v.CamlockHighlight = nil
                end
                if v.CamlockStates.OrbitEnabled then
                    DisableOrbit()
                end
                Library:Notify('target left fov')
                return
            end
        end

        local targetPart = target.Character:FindFirstChild(v.CamlockStates.TargetPart)
        if not targetPart then
            targetPart = target.Character:FindFirstChild("HumanoidRootPart")
        end

        if targetPart then

            if v.CamlockStates.OrbitEnabled then
                local myRoot = GetRootPart()
                if myRoot then
                    if not v.CamlockStates.OrbitOriginalPosition then
                        v.CamlockStates.OrbitOriginalPosition = myRoot.CFrame
                    end

                    v.orbitAngleCamlock = v.orbitAngleCamlock + (v.CamlockStates.OrbitSpeed / 100) * dt * 50
                    local radius = v.CamlockStates.OrbitDistance
                    local x = math.sin(v.orbitAngleCamlock) * radius
                    local z = math.cos(v.orbitAngleCamlock) * radius
                    myRoot.CFrame = CFrame.new(targetPart.Position + Vector3.new(x, v.CamlockStates.OrbitHeight, z), targetPart.Position)
                end
            end

            local targetPosition = targetPart.Position

            if v.CamlockStates.Prediction then
                local targetVelocity = targetPart.AssemblyLinearVelocity or targetPart.Velocity
                local predValue = 1 / v.CamlockStates.PredictionAmount
                targetPosition = targetPosition + (targetVelocity / predValue)
            end

            if v.CamlockStates.Smoothing then
                local currentCFrame = Camera.CFrame
                local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
                local smoothValue = 1 / v.CamlockStates.SmoothAmount
                Camera.CFrame = currentCFrame:Lerp(targetCFrame, smoothValue)
            else
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
            end


        end
    end
end)



v.TargetLock:AddToggle('camlockEnabled', {
    Text = 'camlock',
    Default = false,
    Tooltip = "ur camera locks onto a nearby target",
    Callback = function(Value)
        v.CamlockStates.Enabled = Value
        if Value then
            v.CamlockStates.LastSwitchedPlayer = nil
            local humanoid = GetHumanoid()
            if humanoid then
                v.CamlockStates.OrbitOriginalCameraOffset = humanoid.CameraOffset
                v.CamlockStates.GlueOriginalCameraOffset = humanoid.CameraOffset
            end
            v.CamlockStates.LockedPlayer = GetNearestPlayer()
            if v.CamlockStates.LockedPlayer then
                Library:Notify('camlockin ' .. v.CamlockStates.LockedPlayer.Name)
                UpdateHighlight()
            else
                Library:Notify('no target found')
            end
        else
            v.CamlockStates.LockedPlayer = nil
            v.CamlockStates.LastSwitchedPlayer = nil
            if v.CamlockHighlight then
                v.CamlockHighlight:Destroy()
                v.CamlockHighlight = nil
            end
            if v.CamlockStates.OrbitEnabled then
                DisableOrbit()
            end

            if v.CamlockStates.OrbitOriginalCameraOffset then
                local humanoid = GetHumanoid()
                if humanoid then
                    humanoid.CameraOffset = v.CamlockStates.OrbitOriginalCameraOffset
                end
                v.CamlockStates.OrbitOriginalCameraOffset = nil
                v.CamlockStates.GlueOriginalCameraOffset = nil
            end

            Camera.CameraType = Enum.CameraType.Custom
            Camera.CameraSubject = GetHumanoid()
            Library:Notify('camlocked off')
        end
    end
}):AddKeyPicker('camlockKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'camlock',
    NoUI = false,
})


v.TargetLock:AddDropdown('camlockMode', {
    Values = {'near you', 'near mouse'},
    Default = 1,
    Multi = false,
    Text = 'target mode',
    Callback = function(Value)
        v.CamlockStates.Mode = Value
        Library:Notify('camlock mode: ' .. Value)
    end
})

v.TargetLock:AddToggle('visibleCheck', {
    Text = 'visible check',
    Default = false,
    Tooltip = 'only locks on visible targets (not behind walls)',
    Callback = function(Value)
        v.CamlockStates.VisibleCheck = Value
    end
})

v.TargetLock:AddToggle('teamCheck', {
    Text = 'team check',
    Default = false,
    Tooltip = 'ignores teammates',
    Callback = function(Value)
        v.CamlockStates.TeamCheck = Value
    end
})

v.TargetLock:AddToggle('stopIfDies', {
    Text = 'stop if target dies',
    Default = false,
    Callback = function(Value)
        v.CamlockStates.StopIfDies = Value
        if Value then
            v.CamlockStates.SwitchOnDeath = false
        end
    end
})

v.TargetLock:AddToggle('switchOnDeath', {
    Text = 'switch on death',
    Default = false,
    Callback = function(Value)
        v.CamlockStates.SwitchOnDeath = Value
        if Value then
            v.CamlockStates.StopIfDies = false
        end
    end
})

v.TargetLock:AddToggle('stopOnFovExit', {
    Text = 'stop if leaves fov',
    Default = false,
    Callback = function(Value)
        v.CamlockStates.StopOnFovExit = Value
    end
})

v.TargetLock:AddToggle('camlockPrediction', {
    Text = 'prediction',
    Default = false,
    Tooltip = "predicts where target will move",
    Callback = function(Value)
        v.CamlockStates.Prediction = Value
    end
})

v.TargetLock:AddSlider('camlockPredictionAmount', {
    Text = 'prediction value',
    Default = 0.13,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Tooltip = 'lower = better precision (recommended 0.1 or 0.075)',
    Callback = function(Value)
        v.CamlockStates.PredictionAmount = Value
    end
})

v.TargetLock:AddDropdown('camlockTargetPart', {
    Values = {'Head', 'UpperTorso', 'LowerTorso', 'Torso', 'HumanoidRootPart', 'LeftArm', 'RightArm', 'LeftLeg', 'RightLeg', 'LeftHand', 'RightHand', 'LeftFoot', 'RightFoot', 'LeftUpperArm', 'RightUpperArm', 'LeftLowerArm', 'RightLowerArm', 'LeftUpperLeg', 'RightUpperLeg', 'LeftLowerLeg', 'RightLowerLeg'},
    Default = 1,
    Multi = false,
    Text = 'body part',
    Callback = function(Value)
        v.CamlockStates.TargetPart = Value
    end
})

v.TargetLock:AddToggle('camlockSmoothing', {
    Text = 'smoothing',
    Default = false,
    Callback = function(Value)
        v.CamlockStates.Smoothing = Value
    end
})

v.TargetLock:AddSlider('camlockSmoothAmount', {
    Text = 'smooth value',
    Default = 0.5,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Tooltip = 'lower is smoother,bad if u use orbit or glue)',
    Callback = function(Value)
        v.CamlockStates.SmoothAmount = Value
    end
})


v.TargetWl:AddDropdown('camlockWhitelist', {
    Values = GetAllPlayerNames(),
    Default = 1,
    Multi = true,
    Text = 'select players',
    Tooltip = 'whitelisted players wont be camlocked',
    Callback = function(Value)
        v.CamlockStates.WhitelistedPlayers = {}
        if type(Value) == "table" then
            for name, selected in pairs(Value) do
                if selected == true then
                    table.insert(v.CamlockStates.WhitelistedPlayers, name)
                end
            end
        end
        print("camlock whitelist updated:", table.concat(v.CamlockStates.WhitelistedPlayers, ", "))
    end
})

v.TargetWl:AddButton({
    Text = 'refresh player list',
    Func = function()
        if Options.camlockwhitelist then
            Options.camlockwhitelist:SetValues(GetAllPlayerNames())
            Library:Notify('camlock whitelist refreshed')
        end
    end,
})


v.TargetFov:AddToggle('camlockFov', {
    Text = 'fov circle',
    Default = false,
    Tooltip = 'only camlock targets inside the shape',
    Callback = function(Value)
        v.CamlockStates.FovEnabled = Value
    end
}):AddColorPicker('fovcolor', {
    Default = Color3.new(1, 1, 1)
})

v.TargetFov:AddToggle('camlockFovFill', {
    Text = 'fill circle',
    Default = false,
    Tooltip = 'only works with circle shape',
    Callback = function(Value)
        v.CamlockStates.FovFilled = Value
    end
}):AddColorPicker('fovfillcolor', {
    Default = Color3.new(1, 1, 1)
})

v.TargetFov:AddToggle('fovMouseFollow', {
    Text = 'fov mouse follow',
    Default = true,
    Tooltip = 'if on,the fov shape follows ur cursor',
    Callback = function(Value)
        v.CamlockStates.FovMouseFollow = Value
    end
})

v.TargetFov:AddSlider('camlockFovSize', {
    Text = 'fov size',
    Default = 100,
    Min = 1,
    Max = 500,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        v.CamlockStates.FovSize = Value
    end
})

v.TargetFov:AddSlider('camlockFovLerp', {
    Text = 'fov lerp',
    Default = 1,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Tooltip = 'smoothness of fov movement (1 = instant, lower = smoother)'
})

v.TargetFov:AddDropdown('fovShape', {
    Values = {'circle', 'pentagon', 'heart', 'star'},
    Default = 1,
    Multi = false,
    Text = 'shape',
    Tooltip = 'fov shape',
    Callback = function(Value)
        v.CamlockStates.FovShape = Value
    end
})


v.TargetUni:AddToggle('camlockHighlight', {
    Text = 'highlight',
    Default = false,
    Tooltip = 'highlight camlocked person',
    Callback = function(Value)
        v.CamlockStates.HighlightEnabled = Value
        UpdateHighlight()
    end
}):AddColorPicker('highlightcolor', {
    Default = Color3.new(1, 1, 1),
    Title = 'highlight fill color',
    Callback = function(Value)
        v.CamlockStates.HighlightColor = Value
        if v.CamlockHighlight then
            v.CamlockHighlight.FillColor = Value
        end
    end
}):AddColorPicker('highlightoutlinecolor', {
    Default = Color3.new(1, 1, 1),
    Title = 'highlight outline color',
    Callback = function(Value)
        v.CamlockStates.HighlightOutlineColor = Value
        if v.CamlockHighlight then
            v.CamlockHighlight.OutlineColor = Value
        end
    end
})

v.TargetUni:AddToggle('camlocktracertoggle', {
    Text = 'tracer',
    Default = false,
    Tooltip = 'line from your mouse to the camlocked target'
}):AddColorPicker('camlocktracercolor', {
    Default = Color3.new(1, 1, 1),
    Title = 'tracer color'
})

v.CamlockTracerLine = nil

RunService.RenderStepped:Connect(function()
    if Toggles.camlocktracertoggle and Toggles.camlocktracertoggle.Value and States.TargetPlayer and States.TargetPlayer.Character then
        local head = States.TargetPlayer.Character:FindFirstChild("Head") or States.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if head then
            local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local Inset = game:GetService("GuiService"):GetGuiInset().Y
                local mouse = Player:GetMouse()
                local mousePos = Vector2.new(mouse.X, mouse.Y + Inset)
                if not v.CamlockTracerLine then
                    v.CamlockTracerLine = Drawing.new("Line")
                    v.CamlockTracerLine.Thickness = 2
                end
                v.CamlockTracerLine.From = mousePos
                v.CamlockTracerLine.To = Vector2.new(sp.X, sp.Y)
                v.CamlockTracerLine.Color = Options.camlocktracercolor and Options.camlocktracercolor.Value or Color3.new(1,1,1)
                v.CamlockTracerLine.Visible = true
                return
            end
        end
    end
    if v.CamlockTracerLine then v.CamlockTracerLine.Visible = false end
end)



v.TargetActions:AddToggle('camlockOrbit', {
    Text = 'orbit camlocked',
    Default = false,
    Tooltip = 'makes u orbit them',
    Callback = function(Value)
        v.CamlockStates.OrbitEnabled = Value
        if not Value then
            DisableOrbit()
            v.orbitAngleCamlock = 0
        end
    end
})

v.TargetActions:AddSlider('orbitDistance', {
    Text = 'orbit distance',
    Default = 8,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        v.CamlockStates.OrbitDistance = Value
    end
})

v.TargetActions:AddSlider('orbitSpeed', {
    Text = 'orbit speed',
    Default = 30,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        v.CamlockStates.OrbitSpeed = Value
    end
})

v.TargetActions:AddSlider('orbitHeight', {
    Text = 'orbit height',
    Default = 0,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Tooltip = 'height above target while orbiting',
    Callback = function(Value)
        v.CamlockStates.OrbitHeight = Value
    end
})


v.Trigger:AddToggle('triggerbotEnabled', {
    Text = 'triggerbot',
    Default = false,
    Tooltip = 'autoclicks when ur mouse is positioned on someone',
    Callback = function(Value)
        v.TriggerbotStates.Enabled = Value
    end
}):AddKeyPicker('triggerbotKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'triggerbot',
    NoUI = false,
})

v.Trigger:AddToggle('triggerbotToolOnly', {
    Text = 'tool only',
    Default = false,
    Tooltip = 'triggerbot only activates when tool held',
    Callback = function(Value)
        v.TriggerbotStates.ToolOnly = Value
    end
})

v.Trigger:AddToggle('triggerbotVisibleCheck', {
    Text = 'visible check',
    Default = false,
    Tooltip = 'only shoots visible targets',
    Callback = function(Value)
        v.TriggerbotStates.VisibleCheck = Value
    end
})

v.Trigger:AddToggle('triggerbotTeamCheck', {
    Text = 'team check',
    Default = false,
    Tooltip = 'ignores teammates',
    Callback = function(Value)
        v.TriggerbotStates.TeamCheck = Value
    end
})

v.Trigger:AddSlider('triggerbotChance', {
    Text = 'chance %',
    Default = 100,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        v.TriggerbotStates.Chance = Value
    end
})

v.Trigger:AddSlider('triggerbotDelay', {
    Text = 'delay (ms)',
    Default = 0,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        v.TriggerbotStates.Delay = Value
    end
})

v.Trigger:AddDropdown('triggerbotWhitelist', {
    Values = GetAllPlayerNames(),
    Default = 1,
    Multi = true,
    Text = 'select players',
    Tooltip = 'whitelisted players wont be shot',
    Callback = function(Value)
        v.TriggerbotStates.WhitelistedPlayers = {}
        if type(Value) == "table" then
            for name, selected in pairs(Value) do
                if selected == true then
                    table.insert(v.TriggerbotStates.WhitelistedPlayers, name)
                end
            end
        end
    end
})

v.Trigger:AddButton({
    Text = 'refresh player list',
    Func = function()
        if Options.triggerbotwhitelist then
            Options.triggerbotwhitelist:SetValues(GetAllPlayerNames())
            Library:Notify('triggerbot whitelist refreshed')
        end
    end,
})

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    if Options.camlockwhitelist then
        Options.camlockwhitelist:SetValues(GetAllPlayerNames())
    end
    if Options.triggerbotwhitelist then
        Options.triggerbotwhitelist:SetValues(GetAllPlayerNames())
    end
    if Options.espwhitelistplayers then
        Options.espwhitelistplayers:SetValues(GetAllPlayerNames())
    end
end)

Players.PlayerRemoving:Connect(function(player)
    task.wait(0.5)

    if Options.camlockwhitelist then
        Options.camlockwhitelist:SetValues(GetAllPlayerNames())
    end
    if Options.triggerbotwhitelist then
        Options.triggerbotwhitelist:SetValues(GetAllPlayerNames())
    end
    if Options.espwhitelistplayers then
        Options.espwhitelistplayers:SetValues(GetAllPlayerNames())
    end

    for i = #v.CamlockStates.WhitelistedPlayers, 1, -1 do
        if v.CamlockStates.WhitelistedPlayers[i] == player.Name then
            table.remove(v.CamlockStates.WhitelistedPlayers, i)
        end
    end

    for i = #v.TriggerbotStates.WhitelistedPlayers, 1, -1 do
        if v.TriggerbotStates.WhitelistedPlayers[i] == player.Name then
            table.remove(v.TriggerbotStates.WhitelistedPlayers, i)
        end
    end

    for i = #v.ESPWhitelistedPlayers, 1, -1 do
        if v.ESPWhitelistedPlayers[i] == player.Name then
            table.remove(v.ESPWhitelistedPlayers, i)
        end
    end
end)

v.VirtualUser = game:GetService("VirtualUser")

v.request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)

v.FrozenTrack = nil
v.FrozenAnimationId = nil
v.LastAnimationTrack = nil
v.originalPromptDurations = {}
v.DeathPosition = nil
v.FreecamEnabled = false
v.FreecamCFrame = nil
v.OriginalCFrame = nil
v.CtrlHeld = false
v.HoverNameGui = nil
v.HoverHitboxAdornment = nil
v.IdleStartTime = nil
v.IdleKickTime = 40 * 60
v.IdleViewerGui = nil
v.IdleConnection = nil
v.BlockedAnims = {}
v.OriginalColors = {}
v.OriginalMaterials = {}
v.WhitelistedIds = {}

v.MiscExploits:AddToggle('hovername', {
    Text = 'hover name',
    Default = false,
    Tooltip = 'shows username when mouse over players'
})

Toggles.hovername:OnChanged(function()
    if Toggles.hovername.Value then
        if not v.HoverNameGui then
            v.HoverNameGui = Instance.new("BillboardGui")
            v.HoverNameGui.Name = "hovername"
            v.HoverNameGui.AlwaysOnTop = true
            v.HoverNameGui.Size = UDim2.new(0, 200, 0, 50)
            v.HoverNameGui.StudsOffset = Vector3.new(0, 3, 0)

            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextStrokeTransparency = 0.5
            textLabel.TextScaled = true
            textLabel.Font = Enum.Font.SourceSans
            textLabel.Parent = v.HoverNameGui
        end

        RunService.RenderStepped:Connect(function()
            if not Toggles.hovername.Value then return end

            local mouse = Player:GetMouse()
            local target = mouse.Target

            if target then
                local player = Players:GetPlayerFromCharacter(target.Parent)
                if player and player ~= Player then
                    v.HoverNameGui.Parent = target.Parent:FindFirstChild("Head")
                    if v.HoverNameGui.Parent then
                        v.HoverNameGui.TextLabel.Text = player.Name
                    end
                else
                    v.HoverNameGui.Parent = nil
                end
            else
                v.HoverNameGui.Parent = nil
            end
        end)
    else
        if v.HoverNameGui then
            v.HoverNameGui.Parent = nil
        end
    end
end)



v.MiscExploits:AddToggle('securityidlekick', {
    Text = 'security idle kick',
    Default = false,
    Tooltip = 'custom idle kick timer'
})

v.MiscExploits:AddDropdown('idlekicktime', {
    Values = {'40 mins', '1 hour', '2 hours'},
    Default = 1,
    Multi = false,
    Text = 'idle time'
})

Options.idlekicktime:OnChanged(function(value)
    if value == '40 mins' then
        v.IdleKickTime = 40 * 60
    elseif value == '1 hour' then
        v.IdleKickTime = 60 * 60
    elseif value == '2 hours' then
        v.IdleKickTime = 120 * 60
    end
end)

Toggles.securityidlekick:OnChanged(function()
    if Toggles.securityidlekick.Value then
        v.IdleStartTime = tick()

        local function resetIdle()
            v.IdleStartTime = tick()
        end

        UserInputService.InputBegan:Connect(resetIdle)
        UserInputService.InputChanged:Connect(resetIdle)

        RunService.Heartbeat:Connect(function()
            if not Toggles.securityidlekick.Value then return end

            local idleTime = tick() - v.IdleStartTime
            if idleTime >= v.IdleKickTime then
                Player:Kick("idle for too long")
            end
        end)
    end
end)

v.MiscCharacter:AddToggle('viewidle', {
    Text = 'view idle',
    Default = false,
    Tooltip = 'shows idle timer gui'
})

Toggles.viewidle:OnChanged(function()
    if Toggles.viewidle.Value then
        v.IdleStartTime = tick()

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "IdleViewer"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = Player:WaitForChild("PlayerGui")

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 250, 0, 80)
        frame.Position = UDim2.new(0.5, -125, 0.1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Draggable = true
        frame.Parent = screenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0.4, 0)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "idling for:"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.Font.SourceSansBold
        title.TextSize = 18
        title.Parent = frame

        local timeLabel = Instance.new("TextLabel")
        timeLabel.Size = UDim2.new(1, 0, 0.6, 0)
        timeLabel.Position = UDim2.new(0, 0, 0.4, 0)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Text = "0s"
        timeLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        timeLabel.Font = Enum.Font.SourceSans
        timeLabel.TextSize = 24
        timeLabel.Parent = frame

        v.IdleViewerGui = screenGui

        local function resetIdleTimer()
            v.IdleStartTime = tick()
        end

        UserInputService.InputBegan:Connect(resetIdleTimer)
        UserInputService.InputChanged:Connect(resetIdleTimer)

        v.IdleConnection = RunService.RenderStepped:Connect(function()
            if not Toggles.viewidle.Value then return end

            local elapsed = tick() - v.IdleStartTime
            local hours = math.floor(elapsed / 3600)
            local minutes = math.floor((elapsed % 3600) / 60)
            local seconds = math.floor(elapsed % 60)

            if hours > 0 then
                timeLabel.Text = string.format("%dh %dm %ds", hours, minutes, seconds)
            elseif minutes > 0 then
                timeLabel.Text = string.format("%dm %ds", minutes, seconds)
            else
                timeLabel.Text = string.format("%ds", seconds)
            end
        end)

        frame.BackgroundTransparency = 1
        for i = 1, 20 do
            task.wait(0.02)
            frame.BackgroundTransparency = 1 - (i / 20) * 0.9
        end
    else
        if v.IdleViewerGui then
            v.IdleViewerGui:Destroy()
            v.IdleViewerGui = nil
        end
        if v.IdleConnection then
            v.IdleConnection:Disconnect()
            v.IdleConnection = nil
        end
    end
end)

v.MiscCharacter:AddToggle('unlockthirdperson', {
    Text = 'third person',
    Default = false,
    Tooltip = 'unlock third person in restricted games'
})

Toggles.unlockthirdperson:OnChanged(function()
    if Toggles.unlockthirdperson.Value then
        Player.CameraMaxZoomDistance = 50000
    else
        Player.CameraMaxZoomDistance = 128
    end
end)

v.MiscCharacter:AddToggle('unlockfirstperson', {
    Text = 'first person',
    Default = false,
    Tooltip = 'unlock first person in restricted games'
})

Toggles.unlockfirstperson:OnChanged(function()
    if Toggles.unlockfirstperson.Value then
        Player.CameraMinZoomDistance = 0
    else
        Player.CameraMinZoomDistance = 0.5
    end
end)

v.MiscCharacter:AddToggle('antisit', {
    Text = 'anti sit',
    Default = false,
    Tooltip = 'prevents sitting'
})

v.AntiSitConnection = nil

Toggles.antisit:OnChanged(function()
    if Toggles.antisit.Value then
        local Humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.Sit = false
        end

        v.AntiSitConnection = RunService.Heartbeat:Connect(function()
            local Character = Player.Character
            if Character then
                local Hum = Character:FindFirstChildOfClass("Humanoid")
                if Hum and Hum.Sit then
                    Hum.Sit = false
                end
            end
        end)
    else
        if v.AntiSitConnection then
            v.AntiSitConnection:Disconnect()
            v.AntiSitConnection = nil
        end
    end
end)

v.MiscCharacter:AddToggle('freecam', {
    Text = 'free cam',
    Default = false,
    Tooltip = 'move camera freely with wasd'
})

v.FreeCamConnection = nil

Toggles.freecam:OnChanged(function()
    local cam = workspace.CurrentCamera

    if Toggles.freecam.Value then
        v.FreecamEnabled = true
        v.OriginalCFrame = cam.CFrame
        cam.CameraType = Enum.CameraType.Scriptable

        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition

        local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutoRotate = false
        end

        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = true
        end

        v.FreeCamConnection = RunService.RenderStepped:Connect(function(dt)
            if not v.FreecamEnabled then return end

            local speed = 1
            local move = Vector3.new(0, 0, 0)

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                move = move + (cam.CFrame.LookVector * speed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                move = move - (cam.CFrame.LookVector * speed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                move = move - (cam.CFrame.RightVector * speed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                move = move + (cam.CFrame.RightVector * speed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                move = move + Vector3.new(0, speed, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                move = move - Vector3.new(0, speed, 0)
            end

            cam.CFrame = cam.CFrame + move
        end)

        v.FreeCamMouseConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and v.FreecamEnabled then
                local delta = input.Delta
                local rotX = -delta.Y * 0.003
                local rotY = -delta.X * 0.003
                cam.CFrame = cam.CFrame * CFrame.Angles(rotX, rotY, 0)
            end
        end)
    else
        v.FreecamEnabled = false
        cam.CameraType = Enum.CameraType.Custom

        UserInputService.MouseBehavior = Enum.MouseBehavior.Default

        local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutoRotate = true
        end

        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = false
        end

        if v.FreeCamConnection then
            v.FreeCamConnection:Disconnect()
            v.FreeCamConnection = nil
        end

        if v.FreeCamMouseConnection then
            v.FreeCamMouseConnection:Disconnect()
            v.FreeCamMouseConnection = nil
        end

        if v.OriginalCFrame then
            cam.CFrame = v.OriginalCFrame
        end
    end
end)

v.MiscCharacter:AddToggle('hideavatar', {
    Text = 'hide avatar',
    Default = false,
    Tooltip = 'makes your character invisible'
})

Toggles.hideavatar:OnChanged(function()
    local char = Player.Character
    if not char then return end

    if Toggles.hideavatar.Value then
        for _, descendant in pairs(char:GetDescendants()) do
            if descendant:IsA("BasePart") then
                if not v.OriginalColors[descendant] then
                    v.OriginalColors[descendant] = descendant.Transparency
                end
                descendant.Transparency = 1
            elseif descendant:IsA("Decal") then
                if not v.OriginalMaterials[descendant] then
                    v.OriginalMaterials[descendant] = descendant.Transparency
                end
                descendant.Transparency = 1
            end
        end
    else
        for _, descendant in pairs(char:GetDescendants()) do
            if descendant:IsA("BasePart") and v.OriginalColors[descendant] ~= nil then
                descendant.Transparency = v.OriginalColors[descendant]
                v.OriginalColors[descendant] = nil
            elseif descendant:IsA("Decal") and v.OriginalMaterials[descendant] ~= nil then
                descendant.Transparency = v.OriginalMaterials[descendant]
                v.OriginalMaterials[descendant] = nil
            end
        end
    end
end)

v.MiscAnimations:AddToggle('animationspeed', {
    Text = 'animation speeds',
    Default = false,
    Tooltip = 'speed up animations'
})

v.MiscAnimations:AddSlider('animspeedslider', {
    Text = 'speed multiplier',
    Default = 1,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
    Compact = false
})

RunService.RenderStepped:Connect(function()
    if Toggles.animationspeed and Toggles.animationspeed.Value then
        local hum = GetHumanoid()
        if hum then
            for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                track:AdjustSpeed(Options.animspeedslider.Value)
            end
        end
    end
end)

v.MiscAnimations:AddToggle('antianim', {
    Text = 'anti anim',
    Default = false,
    Tooltip = 'blocks specific animations'
})

v.MiscAnimations:AddDropdown('antianimtype', {
    Values = {'walk', 'run', 'jump', 'fall'},
    Default = 1,
    Multi = true,
    Text = 'blocked anims'
})

Options.antianimtype:OnChanged(function(value)
    v.BlockedAnims = {}
    for anim, _ in pairs(value) do
        v.BlockedAnims[anim:lower()] = true
    end
end)

RunService.RenderStepped:Connect(function()
    if not Toggles.antianim or not Toggles.antianim.Value then return end

    local hum = GetHumanoid()
    if not hum then return end

    local idleTrack = nil
    for _, track in pairs(hum:GetPlayingAnimationTracks()) do
        local animName = track.Animation.Name:lower()
        if animName:find("idle") then
            idleTrack = track
        end
    end

    for _, track in pairs(hum:GetPlayingAnimationTracks()) do
        local animName = track.Animation.Name:lower()

        local shouldBlock = false
        if v.BlockedAnims.walk and animName:find("walk") then
            shouldBlock = true
        end
        if v.BlockedAnims.run and animName:find("run") then
            shouldBlock = true
        end
        if v.BlockedAnims.jump and animName:find("jump") then
            shouldBlock = true
        end
        if v.BlockedAnims.fall and animName:find("fall") then
            shouldBlock = true
        end

        if shouldBlock then
            track:Stop()
            if idleTrack and not idleTrack.IsPlaying then
                idleTrack:Play()
            end
        end
    end
end)

v.ExploitsLeft:AddToggle('tpbackondeath', {
    Text = 'tp back on death',
    Default = false,
    Tooltip = 'teleports you back to where you died'
})

Toggles.tpbackondeath:OnChanged(function()
    if Toggles.tpbackondeath.Value then
        local root = GetRootPart()
        if root then
            v.DeathPosition = root.CFrame
        end
    end
end)

Player.CharacterAdded:Connect(function(char)
    if Toggles.tpbackondeath and Toggles.tpbackondeath.Value and v.DeathPosition then
        task.wait(0.5)
        local root = char:WaitForChild("HumanoidRootPart")
        if root then
            root.CFrame = v.DeathPosition
        end
    end
end)

v.ExploitsLeft:AddToggle('ctrlclicktp', {
    Text = 'ctrl m1 tp',
    Default = false,
    Tooltip = 'hold ctrl and click to teleport'
})

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        v.CtrlHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        v.CtrlHeld = false
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if Toggles.ctrlclicktp and Toggles.ctrlclicktp.Value and v.CtrlHeld and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mouse = Player:GetMouse()
        local root = GetRootPart()
        if root and mouse.Hit then
            root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end)

v.CoreGui = game:GetService("CoreGui")


v.MiscTitleBox:AddToggle('customtitletoggle', {
    Text = 'custom title',
    Default = false,
    Tooltip = 'adds a colored [title] before your name in chat (client sided)'
}):AddColorPicker('customtitlecolor', {
    Default = Color3.new(1, 1, 1),
    Title = 'title color'
})

v.MiscTitleBox:AddInput('customtitletext', {
    Text = 'title',
    Default = '',
    Numeric = false,
    Finished = false,
    Placeholder = 'enter your title...'
})

v.TCS = game:GetService("TextChatService")

local function applyTitleHook()
    if v.TCS.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = v.TCS:FindFirstChild("TextChannels") and v.TCS.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            channel.OnIncomingMessage = function(msg)
                if not Toggles.customtitletoggle or not Toggles.customtitletoggle.Value then return end
                if msg.TextSource and msg.TextSource.UserId == Player.UserId then
                    local title = Options.customtitletext and Options.customtitletext.Value or ""
                    if title ~= "" then
                        local color = Options.customtitlecolor and Options.customtitlecolor.Value or Color3.new(1, 0.4, 0.4)
                        local hex = string.format("%02X%02X%02X", math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
                        local props = Instance.new("TextChatMessageProperties")
                        props.PrefixText = string.format('<font color="#%s">[%s]</font> %s', hex, title, msg.PrefixText)
                        return props
                    end
                end
            end
        end
    end
end

task.defer(applyTitleHook)

v.MiscServer:AddToggle('autorejoinonkick', {
    Text = 'auto rejoin on kick',
    Default = false,
    Tooltip = 'automatically rejoins when kicked'
})

Toggles.autorejoinonkick:OnChanged(function()
    if Toggles.autorejoinonkick.Value then
        Player.OnTeleport:Connect(function(State)
            if State == Enum.TeleportState.Started then
                syn.queue_on_teleport([[
                    repeat task.wait() until game:IsLoaded()
                    task.wait(1)
                ]])
            end
        end)

        game:GetService("GuiService").ErrorMessageChanged:Connect(function()
            if Toggles.autorejoinonkick and Toggles.autorejoinonkick.Value then
                task.wait(0.5)
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
            end
        end)

        v.CoreGui.ChildAdded:Connect(function(child)
            if Toggles.autorejoinonkick and Toggles.autorejoinonkick.Value then
                if child.Name == "RobloxPromptGui" then
                    task.wait(0.5)
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
                end
            end
        end)
    end
end)

v.MiscUniversal:AddToggle('fpscaptoggle', {
    Text = 'fps cap',
    Default = false
})

v.MiscUniversal:AddSlider('fpscapslider', {
    Text = 'fps value',
    Default = 60,
    Min = 1,
    Max = 1000,
    Rounding = 0
})

Toggles.fpscaptoggle:OnChanged(function()
    if Toggles.fpscaptoggle.Value then
        setfpscap(Options.fpscapslider.Value)
    else
        setfpscap(1000)
    end
end)

Options.fpscapslider:OnChanged(function(value)
    if Toggles.fpscaptoggle.Value then
        setfpscap(value)
    end
end)


local antiflingConn = nil
v.ExploitsLeft:AddToggle("antifling", {
    Text = "anti fling",
    Default = false,
    Tooltip = "prevents other exploiters from flinging u",
    Callback = function(value)
        if antiflingConn then
            antiflingConn:Disconnect()
            antiflingConn = nil
        end
        if value then
            antiflingConn = RunService.Stepped:Connect(function()
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= Player and plr.Character then
                        for _, part in pairs(plr.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    end
})


local antivoidConn = nil
v.ExploitsLeft:AddToggle("antivoid", {
    Text = "anti void",
    Default = false,
    Tooltip = "prevents dying to void",
    Callback = function(value)
        if antivoidConn then
            antivoidConn:Disconnect()
            antivoidConn = nil
        end
        if value then
            local destroyHeight = workspace.FallenPartsDestroyHeight
            antivoidConn = RunService.Stepped:Connect(function()
                local char = GetCharacter()
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root and root.Position.Y <= destroyHeight + 25 then
                    root.Velocity = root.Velocity + Vector3.new(0, 250, 0)
                end
            end)
        end
    end
})

v.MiscUniversal:AddToggle("removechathighlight", {
    Text = "remove chat icon",
    Default = false,
    Tooltip = "hides the chat button from the topbar",
    Callback = function(value)
        if v._chatHighlightConn then
            v._chatHighlightConn:Disconnect()
            v._chatHighlightConn = nil
        end

        local StarterGui = game:GetService("StarterGui")

        local function setChatVisible(visible)
            pcall(function()
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, visible)
            end)
        end

        setChatVisible(not value)

        if value then

            v._chatHighlightConn = RunService.Heartbeat:Connect(function()
                pcall(function()
                    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
                end)
            end)
        end
    end
})

v.ChatSpamMessages = {}
v.ChatSpamConnection = nil
v.AdvertiseMessages = {
    "Cryogen is just better",
    "just use Cryogen, or keep dying",
    "Cryogen on top fr",
    "get good with Cryogen",
    "Cryogen > your script",
    "cop at 2CQMYveEcY",
    "cheap n best 2CQMYveEcY",
    "nice paste 2CQMYveEcY",
    "g u can use Cryogen instead of that trash script"
}


local function randomizeCaps(text)
    if not Toggles.randomcaps or not Toggles.randomcaps.Value then
        return text
    end

    local result = ""
    for i = 1, #text do
        local char = text:sub(i, i)
        if math.random(0, 1) == 1 then
            result = result .. char:upper()
        else
            result = result .. char:lower()
        end
    end
    return result
end

v.MiscChatSpam:AddToggle('chatspam', {
    Text = 'chat spam',
    Default = false,
    Tooltip = 'spam messages in chat'
})

v.MiscChatSpam:AddToggle('randomcaps', {
    Text = 'random caps',
    Default = false,
    Tooltip = 'randomizes capitalization in messages'
})

v.MiscChatSpam:AddToggle('chatflood', {
    Text = 'flood',
    Default = false,
    Tooltip = 'spams a max length message every 0.5s'
})

v.ChatFloodConnection = nil

v.MiscChatSpam:AddDropdown('chatspammode', {
    Values = {'custom', 'advertise'},
    Default = 1,
    Multi = false,
    Text = 'spam mode'
})

v.MiscChatSpam:AddInput('chatspamcustom', {
    Text = 'custom message',
    Default = '',
    Numeric = false,
    Finished = true,
    Placeholder = 'type message and press enter',
    Callback = function(value)
        if value and value ~= "" then
            table.insert(v.ChatSpamMessages, value)
            Options.chatspamcustom:SetValue('')

            local messagesList = {}
            for i, msg in ipairs(v.ChatSpamMessages) do
                table.insert(messagesList, msg)
            end
            Options.chatspammessages:SetValues(messagesList)

            Library:Notify("message added: " .. value)
        end
    end
})

v.MiscChatSpam:AddDropdown('chatspammessages', {
    Values = {},
    Default = 1,
    Multi = false,
    Text = 'saved messages',
    Callback = function(value)
        for i, msg in ipairs(v.ChatSpamMessages) do
            if msg == value then
                table.remove(v.ChatSpamMessages, i)

                local messagesList = {}
                for j, m in ipairs(v.ChatSpamMessages) do
                    table.insert(messagesList, m)
                end
                Options.chatspammessages:SetValues(messagesList)

                Library:Notify("message removed: " .. value)
                break
            end
        end
    end
})

v.MiscChatSpam:AddSlider('chatspamdelay', {
    Text = 'delay (seconds)',
    Default = 2,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Compact = false
})

local function sendChatMessage(message)
    if game:GetService("TextChatService").ChatVersion == Enum.ChatVersion.TextChatService then
        game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(message)
    else
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
    end
end

Toggles.chatflood:OnChanged(function()
    if Toggles.chatflood.Value then
        v.ChatFloodConnection = task.spawn(function()
            local floodMsg = string.rep("A", 200)
            while Toggles.chatflood.Value do
                pcall(function()
                    sendChatMessage(floodMsg)
                end)
                task.wait(0.5)
            end
        end)
    else
        if v.ChatFloodConnection then
            task.cancel(v.ChatFloodConnection)
            v.ChatFloodConnection = nil
        end
    end
end)

Toggles.chatspam:OnChanged(function()
    if Toggles.chatspam.Value then
        v.ChatSpamConnection = task.spawn(function()
            while Toggles.chatspam.Value do
                local message = ""
                local mode = Options.chatspammode.Value

                if mode == "advertise" then
                    message = v.AdvertiseMessages[math.random(1, #v.AdvertiseMessages)]
                elseif mode == "custom" then
                    if #v.ChatSpamMessages > 0 then
                        message = v.ChatSpamMessages[math.random(1, #v.ChatSpamMessages)]
                    else
                        Library:Notify("no custom messages added!")
                        Toggles.chatspam:SetValue(false)
                        break
                    end
                end

                if message ~= "" then
                    message = randomizeCaps(message)
                    pcall(function()
                        sendChatMessage(message)
                    end)
                end

                task.wait(Options.chatspamdelay.Value)
            end
        end)
    else
        if v.ChatSpamConnection then
            task.cancel(v.ChatSpamConnection)
            v.ChatSpamConnection = nil
        end
    end
end)

v.MiscChatSpam:AddToggle('chatspying', {
    Text = 'chat spying',
    Default = false,
    Tooltip = 'see all chat messages even in games with disabled chat'
})

v.ChatSpyConnection = nil
v.ChatSpyGui = nil
v.ChatSpyFrame = nil

local function createChatSpyGui()
    if v.ChatSpyGui then return end

    v.ChatSpyGui = Instance.new("ScreenGui")
    v.ChatSpyGui.Name = "ChatSpyGui"
    v.ChatSpyGui.ResetOnSpawn = false
    v.ChatSpyGui.Parent = game:GetService("CoreGui")

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 400, 0, 300)
    Frame.Position = UDim2.new(0, 10, 0.5, -150)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Frame.BorderSizePixel = 0
    Frame.Parent = v.ChatSpyGui
    v.ChatSpyFrame = Frame

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Title.BorderSizePixel = 0
    Title.Text = "Chat Spy"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.Parent = Frame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = Title

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
    ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.Parent = Frame
    v.ChatSpyScrollFrame = ScrollFrame

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 2)
    Layout.Parent = ScrollFrame
end

local function addMessage(playerName, message)
    if not v.ChatSpyScrollFrame then createChatSpyGui() end

    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Size = UDim2.new(1, -10, 0, 20)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.Text = playerName .. ": " .. message
    MessageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    MessageLabel.Font = Enum.Font.Gotham
    MessageLabel.TextSize = 12
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    MessageLabel.TextWrapped = true
    MessageLabel.Parent = v.ChatSpyScrollFrame

    MessageLabel.Size = UDim2.new(1, -10, 0, MessageLabel.TextBounds.Y + 4)

    v.ChatSpyScrollFrame.CanvasSize = UDim2.new(0, 0, 0, v.ChatSpyScrollFrame.UIListLayout.AbsoluteContentSize.Y)
    v.ChatSpyScrollFrame.CanvasPosition = Vector2.new(0, v.ChatSpyScrollFrame.CanvasSize.Y.Offset)
end

Toggles.chatspying:OnChanged(function(enabled)
    if enabled then
        createChatSpyGui()
        if v.ChatSpyFrame then
            v.ChatSpyFrame.Visible = true
        end

        if not v.ChatSpyConnection then
            local TextChatService = game:GetService("TextChatService")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")

            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                v.ChatSpyConnection = TextChatService.MessageReceived:Connect(function(message)
                    addMessage(message.TextSource.Name, message.Text)
                end)
            else
                local DefaultChatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 5)
                if DefaultChatEvents then
                    local OnMessageDoneFiltering = DefaultChatEvents:WaitForChild("OnMessageDoneFiltering", 5)
                    if OnMessageDoneFiltering then
                        v.ChatSpyConnection = OnMessageDoneFiltering.OnClientEvent:Connect(function(messageData)
                            if messageData and messageData.FromSpeaker and messageData.Message then
                                addMessage(messageData.FromSpeaker, messageData.Message)
                            end
                        end)
                    end
                end
            end
        end

    else
        if v.ChatSpyFrame then
            v.ChatSpyFrame.Visible = false
        end
    end
end)

v.SafeModeEnabled = false
v.SafeModeThreshold = 50
v.OriginalPosition = nil
v.InSafeMode = false

v.MainHealth:AddToggle('safemode', {
    Text = 'safe mode',
    Default = false,
    Tooltip = 'teleports you high in the sky when health is low'
})

v.MainHealth:AddSlider('safemodethreshold', {
    Text = 'safe mode threshold',
    Default = 50,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Tooltip = 'health value to trigger safe mode'
})

v.MainHealth:AddToggle("resetathealth", {
    Text = "reset at",
    Default = false,
    Tooltip = "auto resets when health is below threshold"
})

v.MainHealth:AddSlider("resethealthvalue", {
    Text = "reset threshold",
    Default = 50,
    Min = 1,
    Max = 100,
    Rounding = 0
})

task.spawn(function()
    while task.wait(0.1) do
        if Toggles.resetathealth and Toggles.resetathealth.Value then
            local hum = GetHumanoid()
            if hum and hum.Health > 0 and hum.Health <= Options.resethealthvalue.Value then
                hum.Health = 0
            end
        end
    end
end)

Toggles.safemode:OnChanged(function(enabled)
    v.SafeModeEnabled = enabled
    if not enabled then
        v.InSafeMode = false
        v.OriginalPosition = nil
    end
end)

Options.safemodethreshold:OnChanged(function(value)
    v.SafeModeThreshold = value
end)

RunService.RenderStepped:Connect(function()
    if v.SafeModeEnabled then
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        if hum.Health > 0 and hum.Health < v.SafeModeThreshold and not v.InSafeMode then
            v.OriginalPosition = root.CFrame
            v.InSafeMode = true
            root.CFrame = CFrame.new(root.Position.X, 100000, root.Position.Z)
            root.Anchored = true
            Library:Notify("safe mode activated!")
        elseif v.InSafeMode then
            if hum.Health >= v.SafeModeThreshold then
                root.Anchored = false
                if v.OriginalPosition then
                    root.CFrame = v.OriginalPosition
                    v.OriginalPosition = nil
                end
                v.InSafeMode = false
                Library:Notify("safe mode deactivated!")
            else
                root.CFrame = CFrame.new(root.Position.X, 100000, root.Position.Z)
                root.Anchored = true
            end
        end
    end
end)

v.MiscScripts:AddButton({
    Text = "infinite yield",
    Func = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
        Library:Notify("loaded infinite yield")
    end
})

v.MiscScripts:AddButton({
    Text = "rspy",
    Func = function()
        loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))()
    end
})

v.MiscScripts:AddButton({
    Text = "owl hub",
    Func = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/CriShoux/OwlHub/master/OwlHub.txt"))()
        Library:Notify("loaded owl hub")
    end
})

v.MiscScripts:AddButton({
    Text = "internal injector",
    Func = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/Littmsn/LittExec/main/LittExec%20Internal'))()
        Library:Notify("loaded internal injector")
    end
})


v.ExecGroup = Tabs.Exploits:AddLeftGroupbox("execution")
v.ExecGroup:AddLabel("same sunc and unc as ur exc")
v.ExecGroup:AddInput("execinput", {
    Text = "code",
    Default = "",
    Placeholder = 'print("hi")',
    Callback = function() end,
})
v.ExecGroup:AddButton({
    Text = "execute",
    Func = function()
        local code = Options.execinput and Options.execinput.Value or ""
        if code == "" then return end


        if Toggles.blacklistrisky.Value then
            local selected = Options.riskyfunctions and Options.riskyfunctions.Value or {}
            local blocked = nil
            for funcName, _ in pairs(selected) do
                if code:lower():find(funcName:lower()) then
                    blocked = funcName
                    break
                end
            end
            if blocked then
                Library:Notify("blocked: script uses blacklisted function '" .. blocked .. "'", 5)
                return
            end
        end

        local fn, err = loadstring(code)
        if fn then
            local ok, runErr = pcall(fn)
            if not ok then
                if Toggles.notifyerrorredirect.Value then
                    Library:Notify("error: " .. tostring(runErr), 5)
                else
                    warn("[exec error] " .. tostring(runErr))
                end
            else

                if Toggles.notifyexecution.Value then
                    local preview = code:len() > 40 and code:sub(1, 40) .. "..." or code
                    Library:Notify("executed: " .. preview, 4)
                end
            end
        else
            if Toggles.notifyerrorredirect.Value then
                Library:Notify("syntax error: " .. tostring(err), 5)
            else
                warn("[syntax error] " .. tostring(err))
            end
        end
    end,
})
v.ExecGroup:AddButton({
    Text = "clear",
    Func = function()
        if Options.execinput then
            Options.execinput:SetValue("")
        end
    end,
})
v.ExecGroup:AddToggle("notifyerrorredirect", {
    Text = "notify error redirect",
    Default = true,
    Tooltip = "sends script errors as a notification instead of printing to console"
})
v.ExecGroup:AddToggle("notifyexecution", {
    Text = "notify execution",
    Default = false,
    Tooltip = "notifies you with a preview of what you executed (only fires if no error)"
})
v.ExecGroup:AddToggle("blacklistrisky", {
    Text = "blacklist risky functions",
    Default = false,
    Tooltip = "blocks execution if the script uses any selected risky functions"
})
v.ExecGroup:AddDropdown("riskyfunctions", {
    Text = "risky functions",
    Values = {"setfflag", "replicatesignal", "getscriptclosure", "writefile"},
    Default = {},
    Multi = true,
    Tooltip = "select functions to block from being used in executed scripts"
})

v.ExecGroup:AddDivider()
v.ExecGroup:AddLabel("internal ui keybind"):AddKeyPicker("internalexeckeybind", {
    Default = "None",
    Text = "internal execution ui",
    NoUI = false,
    Mode = "Toggle",
    SyncToggleState = false,
    Callback = function(state)
        if Library.ToggleInternalExec then
            Library:ToggleInternalExec()
        end
    end
})
v.ExecGroup:AddToggle('inactivemode', {
    Text = 'inactive mode',
    Default = false,
    Tooltip = 'when on, any roblox input is blocked, clicking, walking will not work (only toggling ui works.)'
})
Toggles.inactivemode:OnChanged(function(value)
    if not value then
        unlockInputs()
    elseif value and _execVisible then
        lockInputs()
    end
end)

v.ExploitsRight:AddToggle('antimod', {
    Text = 'anti mod',
    Default = false,
    Tooltip = 'kicks or notifies when whitelisted players join'
})

v.ExploitsRight:AddDropdown('antimodaction', {
    Values = {'kick', 'notification', 'servhop'},
    Default = 1,
    Multi = false,
    Text = 'action type'
})

v.ExploitsRight:AddInput("idwhitelist", {
    Text = "id whitelist",
    Default = "",
    Numeric = true,
    Finished = true,
    Tooltip = "enter player id to whitelist"
})

v.ExploitsRight:AddDropdown('whitelistedplayers', {
    Values = {},
    Default = 1,
    Multi = true,
    Text = 'whitelisted ids'
})

Options.idwhitelist:OnChanged(function(value)
    if value and value ~= "" then
        local userId = tonumber(value)
        if userId then
            local success, username = pcall(function()
                return Players:GetNameFromUserIdAsync(userId)
            end)

            if success and username then
                v.WhitelistedIds[tostring(userId)] = username

                local dropdownValues = {}
                for id, name in pairs(v.WhitelistedIds) do
                    table.insert(dropdownValues, name .. " (" .. id .. ")")
                end

                Options.whitelistedplayers.Values = dropdownValues
                Options.whitelistedplayers:SetValues(dropdownValues)

                Library:Notify("whitelisted: " .. username)
                Options.idwhitelist:SetValue("")
            else
                Library:Notify("invalid user id")
            end
        end
    end
end)

local function checkWhitelistedPlayer(player)
    if not Toggles.antimod.Value then return end
    if player == Player then return end

    if v.WhitelistedIds[tostring(player.UserId)] then
        local selectedIds = Options.whitelistedplayers.Value
        local playerString = v.WhitelistedIds[tostring(player.UserId)] .. " (" .. player.UserId .. ")"

        if selectedIds[playerString] then
            local actionType = Options.antimodaction.Value

            if actionType == "kick" then
                Player:Kick("[" .. player.UserId .. "] " .. player.Name .. " joined ur server.")
            elseif actionType == "servhop" then
                Library:Notify("[" .. player.UserId .. "] " .. player.Name .. " joined. server hopping...")
                task.wait(0.5)
                local TeleportService = game:GetService("TeleportService")
                local HttpService = game:GetService("HttpService")
                local servers = {}
                local req = game:HttpGet(string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId))
                local body = HttpService:JSONDecode(req)

                if body and body.data then
                    for i, v in next, body.data do
                        if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
                            table.insert(servers, v.id)
                        end
                    end
                end

                if #servers > 0 then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], Player)
                end
            else
                Library:Notify("[" .. player.UserId .. "] " .. player.Name .. " has joined your server.")
            end
        end
    end
end

Toggles.antimod:OnChanged(function()
    if Toggles.antimod.Value then
        Players.PlayerAdded:Connect(function(player)
            checkWhitelistedPlayer(player)
        end)
    end
end)

v.MiscExploits:AddToggle("antiafk", {
    Text = "anti idle",
    Default = false,
    Tooltip = "prevents kicking after 20 mins of idling"
})

Player.Idled:Connect(function()
    if Toggles.antiafk.Value then
        v.VirtualUser:CaptureController()
        v.VirtualUser:ClickButton2(Vector2.new())
    end
end)

v.ExploitsLeft:AddToggle('instantinteraction', {
    Text = 'instant interactions',
    Default = false,
    Tooltip = 'bypasses hold interactions'
})

local function updateProximityPrompts(instant)
    for _, prompt in pairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if instant then
                if not v.originalPromptDurations[prompt] then
                    v.originalPromptDurations[prompt] = prompt.HoldDuration
                end
                prompt.HoldDuration = 0
            else
                if v.originalPromptDurations[prompt] then
                    prompt.HoldDuration = v.originalPromptDurations[prompt]
                end
            end
        end
    end
end

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ProximityPrompt") then
        task.wait(0.1)
        if Toggles.instantinteraction.Value then
            v.originalPromptDurations[descendant] = descendant.HoldDuration
            descendant.HoldDuration = 0
        end
    end
end)

Toggles.instantinteraction:OnChanged(function()
    updateProximityPrompts(Toggles.instantinteraction.Value)
end)


v.ExploitsLeft:AddToggle('promptreach', {
    Text = 'prompt reach',
    Default = false,
    Tooltip = 'interact with proximity prompts from far away'
})
v.ExploitsLeft:AddSlider('promptreachdistance', {
    Text = 'reach distance',
    Default = 20,
    Min = 5,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        if Toggles.promptreach and Toggles.promptreach.Value then
            for _, prompt in pairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    prompt.MaxActivationDistance = value
                end
            end
        end
    end
})
local promptReachConn = nil
Toggles.promptreach:OnChanged(function(value)
    if promptReachConn then promptReachConn:Disconnect(); promptReachConn = nil end
    local dist = Options.promptreachdistance and Options.promptreachdistance.Value or 20
    if value then
        for _, prompt in pairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt.MaxActivationDistance = dist
            end
        end
        promptReachConn = workspace.DescendantAdded:Connect(function(desc)
            if desc:IsA("ProximityPrompt") then
                task.wait(0.05)
                desc.MaxActivationDistance = Options.promptreachdistance and Options.promptreachdistance.Value or 20
            end
        end)
    else
        for _, prompt in pairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt.MaxActivationDistance = 10
            end
        end
    end
end)


v.MiscExploits:AddToggle('unlockmaxzoom', {
    Text = 'unlock max zoom',
    Default = false,
    Tooltip = 'unlocks max zoom,u can see everything'
})

Toggles.unlockmaxzoom:OnChanged(function()
    if Toggles.unlockmaxzoom.Value then
        Player.CameraMaxZoomDistance = 9999
        Player.CameraMinZoomDistance = 0
    else
        Player.CameraMaxZoomDistance = 128
        Player.CameraMinZoomDistance = 0.5
    end
end)

v.MiscCharacter:AddToggle('zoomtoggle', {
    Text = 'zoom',
    Default = false,
    Tooltip = 'zooms in your camera'
}):AddKeyPicker('zoomkey', {
    Text = 'zoom',
    Default = 'NONE',
    SyncToggleState = true
})

v.MiscCharacter:AddSlider('zoomslider', {
    Text = 'zooming',
    Default = 40,
    Min = 10,
    Max = 120,
    Rounding = 0,
    Compact = false
})

v.OriginalZoomFOV = Camera.FieldOfView

Toggles.zoomtoggle:OnChanged(function()
    if Toggles.zoomtoggle.Value then
        Camera.FieldOfView = Options.zoomslider.Value
    else
        Camera.FieldOfView = v.OriginalZoomFOV
    end
end)

Options.zoomslider:OnChanged(function()
    if Toggles.zoomtoggle.Value then
        Camera.FieldOfView = Options.zoomslider.Value
    end
end)

v.MiscAnimations:AddToggle("noanimation", {
    Text = "no anims",
    Default = false,
    Tooltip = "freeze current animation"
})

RunService.RenderStepped:Connect(function()
    local hum = GetHumanoid()
    if not hum then return end

    if Toggles.noanimation.Value then
        if not v.FrozenTrack or not v.FrozenAnimationId then
            for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                if track.IsPlaying then
                    v.FrozenAnimationId = track.Animation.AnimationId
                    v.FrozenTrack = track
                    v.FrozenTrack.Looped = true
                    break
                end
            end
        end

        for _, track in pairs(hum:GetPlayingAnimationTracks()) do
            if track.Animation.AnimationId ~= v.FrozenAnimationId then
                track:Stop()
            end
        end

        if v.FrozenTrack then
            if not v.FrozenTrack.IsPlaying then
                v.FrozenTrack:Play()
            end
            v.FrozenTrack.Looped = true
        end
    else
        if v.FrozenTrack then
            v.FrozenTrack.Looped = false
        end
        v.FrozenTrack = nil
        v.FrozenAnimationId = nil
    end

    if not Toggles.noanimation.Value then
        for _, track in pairs(hum:GetPlayingAnimationTracks()) do
            if track.IsPlaying then
                v.LastAnimationTrack = track
            end
        end
    end
end)


local animPackEnabled = false
local animKeepOnDeath = false

local AnimSlots = {
    idle1 = {
        ["none"]      = nil,
        ["default"]   = "180435571",
        ["bubbly"]    = "910004836",
        ["cartoon"]   = "742637544",
        ["catwalk"]   = "133806214992291",
        ["elder"]     = "845386501",
        ["knight"]    = "657595757",
        ["mage"]      = "707742142",
        ["ninja"]     = "656117400",
        ["pirate"]    = "750785693",
        ["robot"]     = "616088211",
        ["superhero"] = "616111295",
        ["toy"]       = "782841498",
        ["vampire"]   = "1083465857",
        ["zombie"]    = "616158929",
    },
    idle2 = {
        ["none"]      = nil,
        ["default"]   = "180435792",
        ["bubbly"]    = "910009958",
        ["cartoon"]   = "742638445",
        ["catwalk"]   = "94970088341563",
        ["elder"]     = "845397899",
        ["knight"]    = "657568135",
        ["mage"]      = "707855907",
        ["ninja"]     = "656118341",
        ["pirate"]    = "750782770",
        ["robot"]     = "616089559",
        ["superhero"] = "616113536",
        ["toy"]       = "782841498",
        ["vampire"]   = "1083465857",
        ["zombie"]    = "616160636",
    },
    walk = {
        ["none"]      = nil,
        ["default"]   = "180426354",
        ["bubbly"]    = "910034870",
        ["cartoon"]   = "742640026",
        ["catwalk"]   = "109168724482748",
        ["elder"]     = "845403856",
        ["knight"]    = "657552124",
        ["mage"]      = "707897309",
        ["ninja"]     = "656121766",
        ["pirate"]    = "750785693",
        ["robot"]     = "616095330",
        ["superhero"] = "616122287",
        ["toy"]       = "782841498",
        ["vampire"]   = "1083465857",
        ["zombie"]    = "616168032",
    },
    run = {
        ["none"]      = nil,
        ["default"]   = "180426354",
        ["bubbly"]    = "910025107",
        ["cartoon"]   = "742638842",
        ["catwalk"]   = "81024476153754",
        ["elder"]     = "845386501",
        ["knight"]    = "657564596",
        ["mage"]      = "707861613",
        ["ninja"]     = "656118852",
        ["pirate"]    = "750782770",
        ["robot"]     = "616091570",
        ["superhero"] = "616117076",
        ["toy"]       = "782841498",
        ["vampire"]   = "1083465857",
        ["zombie"]    = "616163682",
    },
    jump = {
        ["none"]      = nil,
        ["default"]   = "125750702",
        ["bubbly"]    = "910016857",
        ["cartoon"]   = "742637942",
        ["catwalk"]   = "116936326516985",
        ["elder"]     = "845386501",
        ["knight"]    = "657560148",
        ["mage"]      = "707853694",
        ["ninja"]     = "656117878",
        ["pirate"]    = "750782770",
        ["robot"]     = "616090535",
        ["superhero"] = "616115533",
        ["toy"]       = "782841498",
        ["vampire"]   = "1083465857",
        ["zombie"]    = "616161997",
    },
    climb = {
        ["none"]      = nil,
        ["default"]   = "180436334",
        ["bubbly"]    = "910009958",
        ["cartoon"]   = "742636889",
        ["catwalk"]   = "119377220967554",
        ["elder"]     = "845386501",
        ["knight"]    = "657556206",
        ["mage"]      = "707826056",
        ["ninja"]     = "656114359",
        ["pirate"]    = "750782770",
        ["robot"]     = "616086039",
        ["superhero"] = "616104706",
        ["toy"]       = "782841498",
        ["vampire"]   = "1083465857",
        ["zombie"]    = "616156119",
    },
    fall = {
        ["none"]      = nil,
        ["default"]   = "180436148",
        ["bubbly"]    = "910009958",
        ["cartoon"]   = "742637151",
        ["catwalk"]   = "92294537340807",
        ["elder"]     = "845386501",
        ["knight"]    = "657552124",
        ["mage"]      = "707829716",
        ["ninja"]     = "656115606",
        ["pirate"]    = "750782770",
        ["robot"]     = "616087089",
        ["superhero"] = "616108001",
        ["toy"]       = "782841498",
        ["vampire"]   = "1083465857",
        ["zombie"]    = "616157476",
    },
}

local AnimSelected = {
    idle1 = nil, idle2 = nil,
    walk  = nil, run   = nil,
    jump  = nil, climb = nil, fall = nil,
}

local DefaultAnims = {
    idle1 = "http://www.roblox.com/asset/?id=180435571",
    idle2 = "http://www.roblox.com/asset/?id=180435792",
    walk  = "http://www.roblox.com/asset/?id=180426354",
    run   = "http://www.roblox.com/asset/?id=180426354",
    jump  = "http://www.roblox.com/asset/?id=125750702",
    climb = "http://www.roblox.com/asset/?id=180436334",
    fall  = "http://www.roblox.com/asset/?id=180436148",
}

local function resetAnimations(character)
    if not character or not character:FindFirstChild("Animate") then return end
    local Animate = character.Animate
    local Cloned = Animate:Clone()
    Cloned.idle.Animation1.AnimationId = DefaultAnims.idle1
    Cloned.idle.Animation2.AnimationId = DefaultAnims.idle2
    Cloned.walk.WalkAnim.AnimationId   = DefaultAnims.walk
    Cloned.run.RunAnim.AnimationId     = DefaultAnims.run
    Cloned.jump.JumpAnim.AnimationId   = DefaultAnims.jump
    Cloned.climb.ClimbAnim.AnimationId = DefaultAnims.climb
    Cloned.fall.FallAnim.AnimationId   = DefaultAnims.fall
    Animate:Destroy()
    Cloned.Parent = character
end

local function applyCustomAnimations(character)
    if not animPackEnabled then return end
    if not character or not character:FindFirstChild("Animate") then return end
    local Animate = character.Animate
    local Cloned = Animate:Clone()
    local base = "http://www.roblox.com/asset/?id="
    if AnimSelected.idle1 then Cloned.idle.Animation1.AnimationId = base .. AnimSelected.idle1 end
    if AnimSelected.idle2 then Cloned.idle.Animation2.AnimationId = base .. AnimSelected.idle2 end
    if AnimSelected.walk  then Cloned.walk.WalkAnim.AnimationId   = base .. AnimSelected.walk  end
    if AnimSelected.run   then Cloned.run.RunAnim.AnimationId     = base .. AnimSelected.run   end
    if AnimSelected.jump  then Cloned.jump.JumpAnim.AnimationId   = base .. AnimSelected.jump  end
    if AnimSelected.climb then Cloned.climb.ClimbAnim.AnimationId = base .. AnimSelected.climb end
    if AnimSelected.fall  then Cloned.fall.FallAnim.AnimationId   = base .. AnimSelected.fall  end
    Animate:Destroy()
    Cloned.Parent = character
end

Player.CharacterAdded:Connect(function(char)
    if animKeepOnDeath and animPackEnabled then
        task.wait(1.5)
        applyCustomAnimations(char)
    end
end)

local function makeSlotDropdown(slotKey, labelText)
    local names = {"none"}
    for name, _ in pairs(AnimSlots[slotKey]) do
        if name ~= "none" then table.insert(names, name) end
    end
    table.sort(names, function(a, b)
        if a == "none" then return true end
        if b == "none" then return false end
        return a < b
    end)
    v.AnimPackGroup:AddDropdown("animslot_" .. slotKey, {
        Values = names,
        Default = 1,
        Multi = false,
        AllowNull = false,
        Text = labelText,
        Searchable = true,
        Callback = function(value)
            AnimSelected[slotKey] = AnimSlots[slotKey][value]
            if animPackEnabled and GetCharacter() then
                applyCustomAnimations(GetCharacter())
            end
        end
    })
end

v.AnimPackGroup:AddToggle("animpackenabled", {
    Text = "enabled",
    Default = false,
    Tooltip = "enable/disable custom animations",
    Callback = function(value)
        animPackEnabled = value
        if value then
            if GetCharacter() then applyCustomAnimations(GetCharacter()) end
        else
            if GetCharacter() then resetAnimations(GetCharacter()) end
        end
    end
})

makeSlotDropdown("idle1", "idle 1")
makeSlotDropdown("idle2", "idle 2")
makeSlotDropdown("walk",  "walk")
makeSlotDropdown("run",   "run")
makeSlotDropdown("jump",  "jump")
makeSlotDropdown("climb", "climb")
makeSlotDropdown("fall",  "fall")

v.AnimPackGroup:AddToggle("animpackkeepondeath", {
    Text = "keep on death",
    Default = false,
    Tooltip = "reapply on respawn",
    Callback = function(value) animKeepOnDeath = value end
})



v.EmoteDances = {
    ["Floss"]               = 10714340543,
    ["Yung Blud"]           = 15609995579,
    ["Victory Dance"]       = 15506503658,
    ["Baby Dance"]          = 4272484885,
    ["Side To Side"]        = 3762641826,
    ["The Zabb"]            = 71389516735424,
    ["Bouncy Twirl"]        = 14353423348,
    ["Go Mufasa"]           = 94118707925458,
    ["Jabba Switchway"]     = 103538719480738,
    ["Jabba Dance"]         = 125997227556930,
    ["Needa Circle Shake"]  = 120674455567362,
    ["Hugo Hilaire"]        = 89114994401113,
    ["Party Rocker"]        = 96443347889042,
    ["Rambunctious"]        = 108128682361404,
    ["L Dance"]             = 114846964045392,
    ["Griddy"]              = 77017926307035,
    ["Wa Wa Wa Cringe"]     = 98263064912190,
    ["Russian Dance"]       = 74608751145756,
    ["Default Dance"]       = 80877772569772,
    ["Popular"]             = 90880350857136,
    ["I Came To Goon"]      = 126910355078348,
    ["Chinese Dance"]       = 96832918119470,
    ["CaramellDansen"]      = 97847706148165,
    ["Kawaii Bouncy"]       = 130855166586798,
    ["The Squabble"]        = 109214877196088,
    ["Dia Delicia"]         = 117033010486869,
    ["Floating"]            = 78399469246181,
    ["Billy Bounce"]        = 126516908191316,
}

v.EmoteAnim = {
    current = nil,
    currentID = nil,
}

local function emotePlay(id)
    if v.EmoteAnim.current then
        pcall(function() v.EmoteAnim.current:Stop() end)
        v.EmoteAnim.current = nil
    end
    local char = GetCharacter()
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local anim
    pcall(function()
        local objects = game:GetObjects("rbxassetid://" .. tostring(id))
        for _, obj in ipairs(objects) do
            if obj:IsA("Animation") then
                anim = obj
                break
            end
        end
    end)

    if not anim then
        anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. tostring(id)
    end

    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if not ok or not track then return end

    track.Priority = Enum.AnimationPriority.Action4
    track.Looped = true
    track:Play()
    track:AdjustSpeed(Options.emotespeed and Options.emotespeed.Value or 1)
    v.EmoteAnim.current = track
    v.EmoteAnim.currentID = id
end

local function emoteClear()
    if v.EmoteAnim.current then
        pcall(function() v.EmoteAnim.current:Stop() end)
        v.EmoteAnim.current = nil
        v.EmoteAnim.currentID = nil
    end
end

v.EmoteMain:AddToggle("useemotes", {
    Text = "emoting",
    Default = false,
    Tooltip = "gives u free emote"
}):AddKeyPicker("emotekey", {
    Text = "Emote",
    Default = "NONE",
    SyncToggleState = true
})

v.EmoteMain:AddToggle("emotestopwalk", {
    Text = "stop after walking",
    Default = false,
    Tooltip = "cancels the emote if you walk jump"
})

v.EmoteMain:AddDropdown("emoteanimation", {
    Text = "emote",
    Values = {
        "Floss", "Yung Blud", "Victory Dance", "Baby Dance", "Side To Side",
        "The Zabb", "Bouncy Twirl", "Go Mufasa", "Jabba Switchway", "Jabba Dance",
        "Needa Circle Shake", "Hugo Hilaire", "Party Rocker", "Rambunctious",
        "L Dance", "Griddy", "Wa Wa Wa Cringe", "Russian Dance",
        "Default Dance", "Popular", "I Came To Goon", "Chinese Dance",
        "CaramellDansen", "Kawaii Bouncy", "The Squabble", "Dia Delicia",
        "Floating", "Billy Bounce",
    },
    Default = 1,
    Multi = false,
})

v.EmoteMain:AddToggle("emotecustom", {
    Text = "custom",
    Default = false,
    Tooltip = "put a valid marketplace id to play"
}):AddKeyPicker("emotecustomkey", {
    Text = "Custom emote",
    Default = "NONE",
    SyncToggleState = true
})

v.EmoteMain:AddDropdown("emotecustomslot", {
    Text = "custom slot",
    Values = { "none" },
    Default = 1,
    Multi = false,
    Tooltip = "pick a saved custom emote to play"
})

v.EmoteMain:AddInput("emotecustomname", {
    Text = "name",
    Default = "",
    Placeholder = "emote name",
    Tooltip = "name for your custom slot"
})

v.EmoteMain:AddInput("emotecustomid", {
    Text = "id",
    Default = "",
    Numeric = true,
    Placeholder = "animation / catalog id",
    Tooltip = "paste any Roblox animation or catalog id"
})

v.EmoteCustomSlots = {}

v.EmoteMain:AddButton({
    Text = "save slot",
    Tooltip = "adds this name + id as a custom slot in the dropdown",
    Func = function()
        local name = Options.emotecustomname and Options.emotecustomname.Value or ""
        local rawid = Options.emotecustomid and Options.emotecustomid.Value or ""
        local id = tonumber(rawid:match("%d+"))
        if name == "" then Library:Notify("enter a name first") return end
        if not id then Library:Notify("enter a valid id first") return end
        name = name:sub(1, 24)
        for _, s in ipairs(v.EmoteCustomSlots) do
            if s == name then Library:Notify(name .. " already exists") return end
        end
        v.EmoteDances[name] = id
        table.insert(v.EmoteCustomSlots, name)
        Options.emotecustomslot:SetValues(v.EmoteCustomSlots)
        Library:Notify("saved: " .. name)
    end
})

v.EmoteMain:AddButton({
    Text = "remove slot",
    Tooltip = "removes the currently selected custom slot",
    Func = function()
        local sel = Options.emotecustomslot and Options.emotecustomslot.Value
        if not sel or sel == "(none)" then Library:Notify("no slot selected") return end
        local removed = sel
        v.EmoteDances[sel] = nil
        for i, s in ipairs(v.EmoteCustomSlots) do
            if s == sel then table.remove(v.EmoteCustomSlots, i) break end
        end
        if #v.EmoteCustomSlots == 0 then
            Options.emotecustomslot:SetValues({ "(none)" })
        else
            Options.emotecustomslot:SetValues(v.EmoteCustomSlots)
        end
        Library:Notify("removed: " .. removed)
    end
})

v.EmoteMain:AddSlider("emotespeed", {
    Text = "speed",
    Default = 1,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
    Tooltip = "playback speed of the emote animation"
})

local function emoteApplyCurrent()
    local id
    if Toggles.emotecustom and Toggles.emotecustom.Value then
        local sel = Options.emotecustomslot and Options.emotecustomslot.Value
        if sel and sel ~= "(none)" then
            id = v.EmoteDances[sel]
        end
    else
        local sel = Options.emoteanimation and Options.emoteanimation.Value
        id = sel and v.EmoteDances[sel]
    end
    if id then emotePlay(id) end
end

Toggles.useemotes:OnChanged(function(val)
    if val then
        emoteApplyCurrent()
    else
        emoteClear()
    end
end)

Toggles.emotecustom:OnChanged(function(val)
    if Toggles.useemotes and Toggles.useemotes.Value then
        emoteApplyCurrent()
    end
end)

Options.emoteanimation:OnChanged(function(val)
    if Toggles.useemotes and Toggles.useemotes.Value and not (Toggles.emotecustom and Toggles.emotecustom.Value) then
        local id = v.EmoteDances[val]
        if id then emotePlay(id) end
    end
end)

Options.emotecustomslot:OnChanged(function(val)
    if Toggles.useemotes and Toggles.useemotes.Value and Toggles.emotecustom and Toggles.emotecustom.Value then
        if val and val ~= "(none)" then
            local id = v.EmoteDances[val]
            if id then emotePlay(id) end
        end
    end
end)

Options.emotespeed:OnChanged(function(val)
    if v.EmoteAnim.current and v.EmoteAnim.current.IsPlaying then
        pcall(function() v.EmoteAnim.current:AdjustSpeed(val) end)
    end
end)

do
    RunService.Heartbeat:Connect(function()
        if not Toggles.useemotes or not Toggles.useemotes.Value then return end
        if not Toggles.emotestopwalk or not Toggles.emotestopwalk.Value then return end
        local char = GetCharacter()
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if hum.MoveDirection.Magnitude > 0.1 or hum.Jump then
            Toggles.useemotes:SetValue(false)
        end
    end)
end

Player.CharacterAdded:Connect(function()
    v.EmoteAnim.current = nil
    v.EmoteAnim.currentID = nil
    if Toggles.useemotes and Toggles.useemotes.Value then
        task.wait(0.5)
        emoteApplyCurrent()
    end
end)

v.MiscServer:AddToggle('muteboomboxes', {
    Text = 'mute all boomboxes',
    Default = false,
    Tooltip = 'mutes all boombox sounds'
})

RunService.RenderStepped:Connect(function()
    if Toggles.muteboomboxes and Toggles.muteboomboxes.Value then
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                for _, obj in pairs(player.Character:GetDescendants()) do
                    if obj:IsA("Sound") and obj.Parent and obj.Parent.Name:lower():find("boom") then
                        obj.Volume = 0
                    end
                end
            end
        end
    end
end)

v.MiscExploits:AddSlider('volumecontrol', {
    Text = 'volume',
    Default = 0.5,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Compact = false
})

Options.volumecontrol:OnChanged(function(value)
    UserSettings():GetService("UserGameSettings").MasterVolume = value / 10
end)

v.MiscServerActions:AddSlider('timerminutes', {
    Text = 'timer (minutes)',
    Default = 30,
    Min = 1,
    Max = 120,
    Rounding = 0,
    Compact = false,
    Tooltip = 'set how many minutes before action'
})

v.MiscServerActions:AddToggle('everyxminutes', {
    Text = 'every .. minutes',
    Default = false,
    Tooltip = 'performs action every X minutes'
})

v.MiscServerActions:AddDropdown('everyxminutesaction', {
    Values = {'rejoin', 'serverhop', 'leave'},
    Default = 1,
    Multi = false,
    Text = 'action'
})

v.EveryXMinutesTimer = 0
v.EveryXMinutesStartTime = tick()

Toggles.everyxminutes:OnChanged(function(enabled)
    if enabled then
        v.EveryXMinutesStartTime = tick()
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Toggles.everyxminutes and Toggles.everyxminutes.Value then
            local elapsed = tick() - v.EveryXMinutesStartTime
            local minutes = Options.timerminutes.Value
            local seconds = minutes * 60

            if elapsed >= seconds then
                local action = Options.everyxminutesaction.Value

                if action == "rejoin" then
                    Library:Notify(minutes .. " minutes passed - rejoining...")
                    task.wait(1)
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
                elseif action == "serverhop" then
                    Library:Notify(minutes .. " minutes passed - server hopping...")
                    task.wait(1)

                    local cursor = nil
                    local servers = {}

                    for i = 1, 5 do
                        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor and "&cursor=" .. cursor or "")

                        local response = v.request({
                            Url = url,
                            Method = "GET"
                        })

                        local data = HttpService:JSONDecode(response.Body)

                        for _, server in ipairs(data.data or {}) do
                            if server.id ~= game.JobId and server.playing < server.maxPlayers - 1 then
                                table.insert(servers, server.id)
                            end
                        end

                        cursor = data.nextPageCursor
                        if not cursor then break end
                    end

                    local target = servers[math.random(#servers)]
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, target, Player)
                elseif action == "leave" then
                    Library:Notify(minutes .. " minutes passed - leaving...")
                    task.wait(1)
                    game:Shutdown()
                end

                v.EveryXMinutesStartTime = tick()
            end
        end
    end
end)

v.MiscServerActions:AddInput("jobidtextbox", {
    Text = "jobid joiner",
    Default = "",
    Numeric = false,
    Finished = false
})

v.MiscServerActions:AddButton({
    Text = "join jobid",
    Func = function()
        local jobId = Options.jobidtextbox.Value
        if jobId and jobId ~= "" then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, Player)
        end
    end
})

v.MiscServerActions:AddButton({
    Text = "rejoin",
    Func = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end
})

v.MiscServerActions:AddButton({
    Text = "servhop",
    Func = function()
        Library:Notify("searching for servers...")

        local cursor = nil
        local servers = {}

        for i = 1, 5 do
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor and "&cursor=" .. cursor or "")

            local response = v.request({
                Url = url,
                Method = "GET"
            })

            local data = HttpService:JSONDecode(response.Body)

            for _, server in ipairs(data.data or {}) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers - 1 then
                    table.insert(servers, server.id)
                end
            end

            cursor = data.nextPageCursor
            if not cursor then break end
        end

        local target = servers[math.random(#servers)]
        Library:Notify("teleporting to new server...")

        task.wait(0.2)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, target, Player)
    end
})

v.MiscServerActions:AddButton({
    Text = "get jobid",
    Func = function()
        setclipboard(game.JobId)
        Library:Notify("jobid copied to clipboard")
    end
})

v.MiscServerActions:AddButton({
    Text = "get game id",
    Func = function()
        setclipboard(tostring(game.PlaceId))
        Library:Notify("game id copied to clipboard")
    end
})

v.MiscServerActions:AddButton({
    Text = "get group name",
    Func = function()
        local groupId = game.CreatorType == Enum.CreatorType.Group and game.CreatorId or nil
        if groupId then
            local success, result = pcall(function()
                return game:GetService("GroupService"):GetGroupInfoAsync(groupId)
            end)
            if success and result then
                setclipboard(result.Name)
                Library:Notify("group name copied: " .. result.Name)
            else
                Library:Notify("failed to get group name")
            end
        else
            Library:Notify("this game is not owned by a group")
        end
    end
})

v.MiscServerActions:AddButton({
    Text = "copy discord",
    Func = function()
        setclipboard("https://discord.gg/2CQMYveEcY")
        Library:Notify("discord link copied to clipboard")
    end
})

v.MiscServerActions:AddButton({
    Text = "refresh pos",
    Func = function()
        local root = GetRootPart()
        if root then
            v.DeathPosition = root.CFrame
            Library:Notify("position refreshed")
        end
    end
})

v.MiscServerActions:AddButton({
    Text = "reset",
    Func = function()
        local hum = GetHumanoid()
        if hum then
            hum.Health = 0
            Library:Notify("character reset")
        end
    end
})



Player.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")

    v.FrozenTrack = nil
    v.FrozenAnimationId = nil
    v.LastAnimationTrack = nil

    if Toggles.espenabled and Toggles.espenabled.Value then
        for player, _ in pairs(v.ESPObjects) do
            RemoveESP(player)
        end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Player then
                CreateESP(player)
            end
        end
    end
end)

v.CmdSets:AddToggle("cmdenabled", {Text = "enabled", Default = false, Tooltip = "makes u able to uses toggles with chatting"})
v.CmdSets:AddInput("cmdprefix", {Text = "prefix", Default = "!", Placeholder = "Enter command prefix"})
v.CmdSets:AddDivider()
v.CmdSets:AddToggle("cmdcooldown", {Text = "enable cooldown", Default = false, Tooltip = "prevents u from spamming v.cmds"})
v.CmdSets:AddInput("cooldowntime", {Text = "cooldown (seconds)", Default = "5", Numeric = true, Finished = false, Placeholder = "cooldown time"})

v.cmdPrefix = "!"
v.cmds = {
    "speedvelocity (number)", "speedcframe (number)", "speednone", "fly (number)", "flight (number)",
    "flysmooth (number)", "flightsmooth (number)", "unfly", "noclip", "clip", "swim (number)", "unswim",
    "desync", "desyncskyhide", "visualizing", "sync", "gravity (number)", "ngravity", "jumppower (number)",
    "nojumppower", "infjump", "noinfjump", "gettools", "dropalltool", "reset", "view (player)", "unview",
    "outline (player)", "noline", "lockon (player)", "lockoff", "spin (number)", "unspin", "hide (player)", "show (player)",
    "orbit (player) (speed) (height) (distance)", "unorbit", "tp (player)", "tweentp (player) (speed)", "rejoin", "servhop"
}
for i = 1, #v.cmds do v.ChatCmds:AddLabel(v.cmdPrefix .. v.cmds[i]) if i % 6 == 0 then v.ChatCmds:AddDivider() end end

v.lastCmdTime = 0
v.ncConn, v.ijConn, v.swConn, v.orbConn, v.lockConn, v.spinConn = nil, nil, nil, nil, nil, nil
v.normGrav, v.jpEnabled, v.jpVal, v.orbOrigPos = 196.2, false, 50, nil
v.outlinedPlr, v.outlineAdorns = nil, {}
v.hiddenPlayers = {}

local function CheckCD()
    if not Toggles.cmdcooldown.Value then return true end
    local ct, cd = tick(), tonumber(Options.cooldowntime.Value) or 5
    local tl = cd - (ct - v.lastCmdTime)
    if tl <= 0 then v.lastCmdTime = ct return true else Library:Notify(string.format("Cooldown v.cmd is on, wait another %.1fs", tl), 3) return false end
end

local function FindPlr(name)
    name = name:lower()
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr.Name:lower():find(name) or plr.DisplayName:lower():find(name) then return plr end
    end
end

task.spawn(function()
    while true do
        local plr = game.Players.LocalPlayer
        if plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v.jpEnabled and v.jpVal or 50 end
        end
        task.wait(0.1)
    end
end)

v.cmd = {
    speedvelocity = function(v) Toggles.speedtoggle:SetValue(true) Options.speedmode:SetValue("Velocity") Options.speedinput:SetValue(tostring(v)) end,
    speedcframe = function(v) Toggles.speedtoggle:SetValue(true) Options.speedmode:SetValue("CFrame") Options.speedinput:SetValue(tostring(v)) end,
    speednone = function() local h = GetHumanoid() if h then h.WalkSpeed = 16 end Toggles.speedtoggle:SetValue(false) end,
    fly = function(v) Options.flightmode:SetValue("Normal") Options.flightspeed:SetValue(tonumber(v) or 50) Toggles.flighttoggle:SetValue(true) end,
    flysmooth = function(v) Options.flightmode:SetValue("Smooth") Options.flightspeed:SetValue(tonumber(v) or 50) Toggles.flighttoggle:SetValue(true) end,
    unfly = function() Toggles.flighttoggle:SetValue(false) end,
    noclip = function()
        if v.ncConn then return end
        v.ncConn = RunService.Stepped:Connect(function()
            local c = GetCharacter()
            if c then for _, pt in pairs(c:GetDescendants()) do if pt:IsA("BasePart") then pt.CanCollide = false end end end
        end)
    end,
    clip = function()
        if v.ncConn then v.ncConn:Disconnect() v.ncConn = nil end
        local c = GetCharacter()
        if c then for _, pt in pairs(c:GetDescendants()) do if pt:IsA("BasePart") then pt.CanCollide = true end end end
    end,
    swim = function(v)
        if v.swConn then v.swConn:Disconnect() end
        local plr, c = Players.LocalPlayer, Players.LocalPlayer.Character
        local h, r = c and c:FindFirstChild("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
        if not h or not r then return end
        local spd = tonumber(v) or 50
        h:ChangeState(Enum.HumanoidStateType.Swimming)
        v.swConn = RunService.RenderStepped:Connect(function()
            h:ChangeState(Enum.HumanoidStateType.Swimming)
            local mv, cm = Vector3.zero, workspace.CurrentCamera
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cm.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cm.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cm.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cm.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0, 1, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0, 1, 0) end
            r.Velocity = mv * spd
        end)
    end,
    unswim = function()
        if v.swConn then v.swConn:Disconnect() v.swConn = nil end
        local c, h = GetCharacter(), GetCharacter() and GetCharacter():FindFirstChild("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end,
    desync = function()
        local r = GetRootPart()
        if r then v.desyncPosition = r.Position setfflag("NextGenReplicatorEnabledWrite4", "true") if Toggles.desync then Toggles.desync:SetValue(true) end end
    end,
    desyncskyhide = function()
        local r = GetRootPart()
        if r then
            local op = r.CFrame
            r.CFrame = r.CFrame + Vector3.new(0, 1945007, 0) task.wait(1)
            setfflag("NextGenReplicatorEnabledWrite4", "true") v.desyncPosition = r.Position task.wait(1) r.CFrame = op
            if Toggles.desync then Toggles.desync:SetValue(true) end
        end
    end,
    visualizing = function() if Toggles.visualizer then Toggles.visualizer:SetValue(not Toggles.visualizer.Value) end end,
    sync = function() setfflag("NextGenReplicatorEnabledWrite4", "false") if Toggles.desync then Toggles.desync:SetValue(false) end v.desyncPosition = nil end,
    gravity = function(v) workspace.Gravity = tonumber(v) or 196.2 end,
    ngravity = function() workspace.Gravity = v.normGrav end,
    jumppower = function(v) v.jpEnabled, v.jpVal = true, tonumber(v) or 50 end,
    nojumppower = function() v.jpEnabled, v.jpVal = false, 50 end,
    infjump = function()
        if v.ijConn then return end
        v.ijConn = UserInputService.JumpRequest:Connect(function() local h = GetHumanoid() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end)
    end,
    noinfjump = function() if v.ijConn then v.ijConn:Disconnect() v.ijConn = nil end end,
    gettools = function()
        local r = GetRootPart()
        if not r then return end
        local op = r.CFrame
        for _, o in pairs(workspace:GetDescendants()) do
            if o:IsA("Tool") and not o:IsDescendantOf(GetCharacter()) then r.CFrame = o.Handle.CFrame task.wait(0.2) end
        end
        r.CFrame = op
    end,
    dropalltool = function()
        local h = GetHumanoid()
        if not h then return end
        for _, t in pairs(Player.Backpack:GetChildren()) do if t:IsA("Tool") then h:EquipTool(t) task.wait(0.1) t.Parent = workspace end end
        for _, t in pairs(GetCharacter():GetChildren()) do if t:IsA("Tool") then t.Parent = workspace end end
    end,
    reset = function() local h = GetHumanoid() if h then h.Health = 0 end end,
    view = function(a) local tp = FindPlr(a[2]) if not tp then return end workspace.CurrentCamera.CameraSubject = tp.Character and tp.Character:FindFirstChild("Humanoid") end,
    unview = function() workspace.CurrentCamera.CameraSubject = GetHumanoid() end,
    outline = function(a)
        if v.outlinedPlr then for _, ad in pairs(v.outlineAdorns) do ad:Destroy() end v.outlineAdorns = {} end
        local tp = FindPlr(a[2])
        if not tp then return end
        v.outlinedPlr = tp
        local function cOut(c)
            for _, ad in pairs(v.outlineAdorns) do ad:Destroy() end v.outlineAdorns = {}
            for _, pt in pairs(c:GetDescendants()) do
                if pt:IsA("BasePart") and pt.Name ~= "HumanoidRootPart" then
                    local hl = Instance.new("Highlight") hl.Adornee = pt
                    hl.FillColor, hl.OutlineColor = Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255)
                    hl.FillTransparency, hl.OutlineTransparency, hl.Parent = 0.5, 0, pt
                    table.insert(v.outlineAdorns, hl)
                end
            end
        end
        if tp.Character then cOut(tp.Character) end
        tp.CharacterAdded:Connect(function(c) if v.outlinedPlr == tp then task.wait(0.1) cOut(c) end end)
    end,
    noline = function() for _, ad in pairs(v.outlineAdorns) do ad:Destroy() end v.outlineAdorns = {} v.outlinedPlr = nil end,
    lockon = function(a)
        if v.lockConn then v.lockConn:Disconnect() end
        local tp = FindPlr(a[2])
        if not tp then return end
        v.lockConn = RunService.RenderStepped:Connect(function()
            local tc, th = tp.Character, tp.Character and tp.Character:FindFirstChild("Head")
            if th then workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, th.Position) end
        end)
    end,
    lockoff = function() if v.lockConn then v.lockConn:Disconnect() v.lockConn = nil end end,
    spin = function(v)
        if v.spinConn then v.spinConn:Disconnect() end
        local r = GetRootPart()
        if not r then return end
        local spd = tonumber(v) or 50
        v.spinConn = RunService.Heartbeat:Connect(function()
            local rt = GetRootPart()
            if rt then rt.CFrame = rt.CFrame * CFrame.Angles(0, math.rad(spd), 0) end
        end)
    end,
    unspin = function() if v.spinConn then v.spinConn:Disconnect() v.spinConn = nil end end,
    hide = function(a)
        local tp = FindPlr(a[2])
        if not tp or not tp.Character then return end
        v.hiddenPlayers[tp.UserId] = {}
        for _, part in pairs(tp.Character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                v.hiddenPlayers[tp.UserId][part] = part.Transparency
                part.Transparency = 1
            end
        end
    end,
    show = function(a)
        local tp = FindPlr(a[2])
        if not tp or not tp.Character or not v.hiddenPlayers[tp.UserId] then return end
        for part, trans in pairs(v.hiddenPlayers[tp.UserId]) do
            if part and part.Parent then
                part.Transparency = trans
            end
        end
        v.hiddenPlayers[tp.UserId] = nil
    end,
    orbit = function(a)
        local tp = FindPlr(a[2])
        if not tp then return end
        if v.orbConn then v.orbConn:Disconnect() end
        local r = GetRootPart()
        if r then v.orbOrigPos = r.CFrame r.Anchored = true end
        local ang = 0
        v.orbConn = RunService.Heartbeat:Connect(function()
            local rt, tc, tr = GetRootPart(), tp.Character, tp.Character and tp.Character:FindFirstChild("HumanoidRootPart")
            if rt and tr then
                ang = ang + (tonumber(a[3]) or 0.05)
                local x, z = math.cos(ang) * (tonumber(a[5]) or 10), math.sin(ang) * (tonumber(a[5]) or 10)
                rt.CFrame = CFrame.new(tr.Position + Vector3.new(x, tonumber(a[4]) or 5, z))
            end
        end)
    end,
    unorbit = function()
        if v.orbConn then v.orbConn:Disconnect() v.orbConn = nil end
        local r = GetRootPart()
        if r then r.Anchored = false if v.orbOrigPos then r.CFrame = v.orbOrigPos v.orbOrigPos = nil end end
    end,
    tp = function(a)
        local tp = FindPlr(a[2])
        if not tp then return end
        local r, tc, tr = GetRootPart(), tp.Character, tp.Character and tp.Character:FindFirstChild("HumanoidRootPart")
        if r and tr then r.CFrame = tr.CFrame end
    end,
    tweentp = function(a)
        local tp = FindPlr(a[2])
        if not tp then return end
        local r, tc, tr = GetRootPart(), tp.Character, tp.Character and tp.Character:FindFirstChild("HumanoidRootPart")
        if r and tr then
            local ti = TweenInfo.new(tonumber(a[3]) or 1, Enum.EasingStyle.Linear)
            TweenService:Create(r, ti, {CFrame = tr.CFrame}):Play()
        end
    end,
    rejoin = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end,
    servhop = function()
        Library:Notify("searching for servers...")
        local cursor = nil
        local servers = {}
        for i = 1, 5 do
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor and "&cursor=" .. cursor or "")
            local response = v.request({Url = url, Method = "GET"})
            local data = HttpService:JSONDecode(response.Body)
            for _, server in ipairs(data.data or {}) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers - 1 then
                    table.insert(servers, server.id)
                end
            end
            cursor = data.nextPageCursor
            if not cursor then break end
        end
        local target = servers[math.random(#servers)]
        Library:Notify("teleporting to new server...")
        task.wait(0.2)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, target, Player)
    end
}

v.cmd.flight, v.cmd.flightsmooth = v.cmd.fly, v.cmd.flysmooth

Player.Chatted:Connect(function(msg)
    if not Toggles.cmdenabled.Value then return end
    local pfx = Options.cmdprefix.Value or "!"
    if msg:sub(1, #pfx) ~= pfx then return end
    if not CheckCD() then return end
    local a = {}
    for w in msg:gmatch("%S+") do table.insert(a, w) end
    local c = a[1]:sub(#pfx + 1):lower()
    local f = v.cmd[c]
    if f then
        if c == "orbit" or c == "tp" or c == "tweentp" or c == "view" or c == "outline" or c == "lockon" or c == "hide" or c == "show" then f(a) else f(a[2]) end
    end
end)



v.TeleportMain:AddInput("tpnameinput", {
    Text = "teleport name",
    Default = "",
    Numeric = false,
    Finished = true,
    Placeholder = "enter name..."
})

v.TeleportMain:AddButton({
    Text = 'save tp',
    Func = function()
        local name = Options.tpnameinput.Value
        if name ~= "" then
            local root = GetRootPart()
            if root then
                v.TeleportStates.SavedTeleports[name] = root.Position
                Library:Notify("saved tp: " .. name)
                Options.tpnameinput:SetValue("")
                if Options.tpdropdown then
                    local tpNames = {}
                    for n, _ in pairs(v.TeleportStates.SavedTeleports) do
                        table.insert(tpNames, n)
                    end
                    Options.tpdropdown:SetValues(tpNames)
                end
            end
        end
    end,
})

v.TeleportMain:AddDropdown('tpdropdown', {
    Values = {},
    Default = 1,
    Multi = false,
    Text = 'saved teleports',
    Callback = function(Value)
        v.TeleportStates.SelectedTP = Value
    end
})

v.TeleportMain:AddButton({
    Text = 'teleport',
    Func = function()
        if v.TeleportStates.SelectedTP then
            local pos = v.TeleportStates.SavedTeleports[v.TeleportStates.SelectedTP]
            if pos then
                local root = GetRootPart()
                if root then
                    if v.TeleportStates.TweenEnabled then
                        local ti = TweenInfo.new(3 - (v.TeleportStates.TweenSpeed / 3.5), Enum.EasingStyle.Linear)
                        TweenService:Create(root, ti, {CFrame = CFrame.new(pos)}):Play()
                    else
                        root.CFrame = CFrame.new(pos)
                    end
                end
            end
        end
    end,
})

v.TeleportMain:AddButton({
    Text = 'remove',
    Func = function()
        if v.TeleportStates.SelectedTP and v.TeleportStates.SavedTeleports[v.TeleportStates.SelectedTP] then
            local name = v.TeleportStates.SelectedTP
            v.TeleportStates.SavedTeleports[name] = nil
            Library:Notify("removed tp: " .. name)
            v.TeleportStates.SelectedTP = nil
            if Options.tpdropdown then
                local tpNames = {}
                for n, _ in pairs(v.TeleportStates.SavedTeleports) do
                    table.insert(tpNames, n)
                end
                Options.tpdropdown:SetValues(tpNames)
                Options.tpdropdown:SetValue(nil)
            end
        else
            Library:Notify("no teleport selected", 3)
        end
    end,
})

v.TPCoordsLabel = v.TeleportMain:AddLabel("coordinates: 0, 0, 0")

task.spawn(function()
    while task.wait(0.5) do
        if v.TeleportStates.SelectedTP then
            local pos = v.TeleportStates.SavedTeleports[v.TeleportStates.SelectedTP]
            if pos then
                v.TPCoordsLabel:SetText(string.format("coordinates: %.0f, %.0f, %.0f", pos.X, pos.Y, pos.Z))
            end
        end
    end
end)

v.TeleportMain:AddToggle('tptween', {
    Text = 'tween tp',
    Default = false,
    Callback = function(Value)
        v.TeleportStates.TweenEnabled = Value
    end
})

v.TeleportMain:AddSlider('tptweenspeed', {
    Text = 'tween speed',
    Default = 5,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(Value)
        v.TeleportStates.TweenSpeed = Value
    end
})

v.TPCurrentPosLabel = v.TeleportMain:AddLabel("current position: 0, 0, 0")

task.spawn(function()
    while task.wait(0.5) do
        local root = GetRootPart()
        if root then
            local pos = root.Position
            v.TPCurrentPosLabel:SetText(string.format("current position: %.0f, %.0f, %.0f", pos.X, pos.Y, pos.Z))
        end
    end
end)

v.TeleportStuff:AddToggle('tpkeybind', {
    Text = 'teleport',
    Default = false,
    Callback = function(Value)
        v.TeleportStates.TPKeybindEnabled = Value
    end
}):AddKeyPicker('tpkeybindkey', {
    Default = 'None',
    SyncToggleState = false,
    Mode = 'Toggle',
    Text = 'teleport keybind',
    NoUI = false,
    Callback = function()
        if v.TeleportStates.SelectedTP then
            local pos = v.TeleportStates.SavedTeleports[v.TeleportStates.SelectedTP]
            if pos then
                local root = GetRootPart()
                if root then
                    if v.TeleportStates.TweenEnabled then
                        local ti = TweenInfo.new(11 - v.TeleportStates.TweenSpeed, Enum.EasingStyle.Linear)
                        TweenService:Create(root, ti, {CFrame = CFrame.new(pos)}):Play()
                    else
                        root.CFrame = CFrame.new(pos)
                    end
                end
            end
        end
    end
})

v.TeleportStuff:AddButton({
    Text = 'copy coordinates',
    Func = function()
        local root = GetRootPart()
        if root then
            local pos = root.Position
            setclipboard(string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z))
            Library:Notify("coordinates copied!")
        end
    end,
})

v.TeleportStuff:AddButton({
    Text = 'copy mouse pos',
    Func = function()
        local mouse = Player:GetMouse()
        if mouse.Hit then
            local pos = mouse.Hit.Position
            setclipboard(string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z))
            Library:Notify("mouse position copied!")
        end
    end,
})

v.TeleportStuff:AddDropdown('tpplayerdropdown', {
    Values = GetAllPlayerNames(),
    Default = 1,
    Multi = false,
    Text = 'select player'
})

v.TeleportStuff:AddButton({
    Text = 'teleport',
    Func = function()
        local pName = Options.tpplayerdropdown.Value
        if pName then
            local p = FindPlayerByName(pName)
            if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local root = GetRootPart()
                if root then
                    root.CFrame = p.Character.HumanoidRootPart.CFrame
                end
            end
        end
    end,
})

v.TeleportStuff:AddButton({
    Text = 'teleport behind',
    Func = function()
        local pName = Options.tpplayerdropdown.Value
        if pName then
            local p = FindPlayerByName(pName)
            if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local root = GetRootPart()
                if root then
                    root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                end
            end
        end
    end,
})

v.TeleportStuff:AddButton({
    Text = 'teleport infront',
    Func = function()
        local pName = Options.tpplayerdropdown.Value
        if pName then
            local p = FindPlayerByName(pName)
            if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local root = GetRootPart()
                if root then
                    root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
                end
            end
        end
    end,
})

v.TeleportStuff:AddButton({
    Text = 'teleport upwards',
    Func = function()
        local pName = Options.tpplayerdropdown.Value
        if pName then
            local p = FindPlayerByName(pName)
            if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local root = GetRootPart()
                if root then
                    root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
                end
            end
        end
    end,
})

v.TeleportStuff:AddButton({
    Text = 'teleport down',
    Func = function()
        local pName = Options.tpplayerdropdown.Value
        if pName then
            local p = FindPlayerByName(pName)
            if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local root = GetRootPart()
                if root then
                    root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, -5, 0)
                end
            end
        end
    end,
})

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    if Options.tpplayerdropdown then
        Options.tpplayerdropdown:SetValues(GetAllPlayerNames())
    end
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    if Options.tpplayerdropdown then
        Options.tpplayerdropdown:SetValues(GetAllPlayerNames())
    end
end)

v.InfoLeft = Tabs.Info:AddLeftGroupbox('session info')
v.InfoContributors = Tabs.Info:AddRightGroupbox('contributors')

v.SessionStart = tick()
v.HWID = game:GetService("RbxAnalyticsService"):GetClientId()

v.InfoPlayersLabel = v.InfoLeft:AddLabel("Players in game: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
v.InfoLeft:AddLabel("game id: " .. game.PlaceId)
v.InfoLeft:AddLabel("job id: " .. game.JobId)

task.spawn(function()
    while task.wait(2) do
        v.InfoPlayersLabel:SetText("Players in game: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
    end
end)

v.InfoTimeLabel = v.InfoLeft:AddLabel("executed for: 0s")

task.spawn(function()
    while task.wait(1) do
        local timeElapsed = math.floor(tick() - v.SessionStart)
        local hours = math.floor(timeElapsed / 3600)
        local minutes = math.floor((timeElapsed % 3600) / 60)
        local seconds = timeElapsed % 60

        if hours > 0 then
            v.InfoTimeLabel:SetText("executed for: " .. hours .. "h " .. minutes .. "m " .. seconds .. "s")
        elseif minutes > 0 then
            v.InfoTimeLabel:SetText("executed for: " .. minutes .. "m " .. seconds .. "s")
        else
            v.InfoTimeLabel:SetText("executed for: " .. seconds .. "s")
        end
    end
end)

v.InfoDateLabel = v.InfoLeft:AddLabel("")
task.spawn(function()
    local dateInfo = os.date("!*t")
    v.InfoDateLabel:SetText(string.format("date: %02d/%02d/%04d %02d:%02d:%02d UTC",
        dateInfo.month, dateInfo.day, dateInfo.year, dateInfo.hour, dateInfo.min, dateInfo.sec))
end)

pcall(function()
    local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    v.InfoLeft:AddLabel("Game name: " .. gameName)
end)



v.InfoFPSPingLabel = v.InfoLeft:AddLabel("fps: 0  |  ping: 0")

task.spawn(function()
    while task.wait(1) do
        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        local ping = math.floor(Player:GetNetworkPing() * 1000)
        v.InfoFPSPingLabel:SetText("fps: " .. fps .. "  |  ping: " .. ping .. "ms")
    end
end)

v.executorName = identifyexecutor and identifyexecutor() or "Unknown"
v.supportedExecutors = {
    ["awp.gg"] = true,
    ["chocosploit"] = true,
    ["nihon lite"] = true,
    ["potassium"] = true,
    ["synapse z"] = true,
    ["volcano"] = true,
    ["volt"] = true,
    ["cryptic"] = true,
    ["wiindows"] = true,
    ["wave"] = true
}

v.isSupported = false
for name, _ in pairs(v.supportedExecutors) do
    if v.executorName:lower():find(name:lower()) then
        v.isSupported = true
        break
    end
end

if v.isSupported then
    v.InfoLeft:AddLabel("Executor: " .. v.executorName)
else
    v.InfoLeft:AddLabel("Executor: " .. v.executorName)
end

v.InfoContributors:AddLabel("thfg13 main developer")
v.InfoContributors:AddLabel("liminalin developer")
v.InfoContributors:AddLabel("killerslash ex developer")

v.InfoScript = Tabs.Info:AddRightGroupbox("script")
v.InfoScript:AddLabel("thank you to do the key system", true)
v.InfoScript:AddLabel("key length is 28 hours", true)
v.InfoScript:AddLabel("do not share the key", true)
v.InfoScript:AddLabel("we appreciate you for doing the key system!", true)

local KEY_FILE = "cosmical_key_time.txt"
local KEY_DURATION = 100800

local function getActivationTime()
    local ok, data = pcall(function() return readfile(KEY_FILE) end)
    if ok and data and tonumber(data) then
        return tonumber(data)
    end
    local now = os.time()
    pcall(function() writefile(KEY_FILE, tostring(now)) end)
    return now
end

local activationTime = getActivationTime()

v.KeyValidateLabel = v.InfoScript:AddLabel("key validate: calculating...", false)

task.spawn(function()
    while true do
        local elapsed = os.time() - activationTime
        local remaining = KEY_DURATION - elapsed
        if remaining <= 0 then
            v.KeyValidateLabel:SetText("key validate: expired!")
            break
        end
        local h = math.floor(remaining / 3600)
        local m = math.floor((remaining % 3600) / 60)
        local s = remaining % 60
        v.KeyValidateLabel:SetText(string.format("key validate: %02dh %02dm %02ds left", h, m, s))
        task.wait(1)
    end
end)


v.InfoLeft:AddButton({
    Text = "copy info",
    Func = function()
        local info = {}

        table.insert(info, "session info")
        table.insert(info, "players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
        table.insert(info, "game id: " .. game.PlaceId)
        table.insert(info, "job id: " .. game.JobId)

        local timeElapsed = math.floor(tick() - v.SessionStart)
        local hours = math.floor(timeElapsed / 3600)
        local minutes = math.floor((timeElapsed % 3600) / 60)
        local seconds = timeElapsed % 60
        if hours > 0 then
            table.insert(info, "session time: " .. hours .. "h " .. minutes .. "m " .. seconds .. "s")
        elseif minutes > 0 then
            table.insert(info, "session time: " .. minutes .. "m " .. seconds .. "s")
        else
            table.insert(info, "session time: " .. seconds .. "s")
        end

        local dateInfo = os.date("!*t")
        table.insert(info, "date: " .. string.format("%02d/%02d/%04d %02d:%02d:%02d UTC",
            dateInfo.month, dateInfo.day, dateInfo.year, dateInfo.hour, dateInfo.min, dateInfo.sec))

        pcall(function()
            local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
            table.insert(info, "game name: " .. gameName)
        end)

        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        local ping = math.floor(Player:GetNetworkPing() * 1000)
        table.insert(info, "fps: " .. fps .. " | Ping: " .. ping .. "ms")

        v.executorName = identifyexecutor and identifyexecutor() or "Unknown"
        table.insert(info, "executor: " .. v.executorName)

        local infoText = table.concat(info, "\n")
        setclipboard(infoText)
        Library:Notify("info copied to clipboard!")
    end
})



v.MenuGroup = Tabs['UI Settings']:AddLeftGroupbox("menu")

v.MenuGroup:AddButton('test notification', function()
    Library:Notify('this is a test notification!')
end)

v.MenuGroup:AddButton('Unload', function()
    Library:Notify("unloading")
    task.wait(0.5)

    for player, _ in pairs(v.ESPObjects) do
        RemoveESP(player)
    end

    if States.DesyncUndergroundPart then
        States.DesyncUndergroundPart:Destroy()
    end

    if PositionTextLabel then
        PositionTextLabel:Remove()
    end

    if AntiVoidPlatform then
        AntiVoidPlatform:Destroy()
    end

    Library:Unload()
end)

v.MenuGroup:AddLabel('menu keybind'):AddKeyPicker('menukeybind', { Default = 'RightShift', NoUI = true, Text = 'menu keybind' })

v.MenuGroup:AddToggle('showkeybindmenu', {
    Text = 'show keybind menu',
    Default = false,
    Callback = function(value)
        Library:SetKeybindMenuVisible(value)
    end
})




v.MenuGroup:AddDropdown('guifont', {
    Text = 'font',
    Values = Library.FontNames or { 'code', 'gotham', 'gotham bold', 'roboto', 'roboto mono', 'source sans', 'ubuntu', 'arial' },
    Default = 1,
    Multi = false,
    Callback = function(value)
        Library:SetFont(({
            ['code']        = Enum.Font.Code,
            ['gotham']      = Enum.Font.Gotham,
            ['gotham bold'] = Enum.Font.GothamBold,
            ['roboto']      = Enum.Font.Roboto,
            ['roboto mono'] = Enum.Font.RobotoMono,
            ['source sans'] = Enum.Font.SourceSans,
            ['ubuntu']      = Enum.Font.Ubuntu,
            ['arial']       = Enum.Font.Arial,
        })[value] or Enum.Font.Code)
    end
})




v.FadeColorGroup = Tabs['UI Settings']:AddRightGroupbox('fade color')
v.FadeColorGroup:AddToggle('fadecolortoggle', {
    Text    = 'fade color',
    Default = true,
    Tooltip = 'color that title letters pulse to during the animation',
}):AddColorPicker('fadecolorpicker', {
    Default = Color3.fromRGB(54, 93, 171),
    Title    = 'fade color',
    Callback = function(color)
        Library.FadeColor = color
    end,
})




v.NotifGroup = Tabs['UI Settings']:AddLeftGroupbox("notifications")

v.NotifGroup:AddDropdown('notifbarside', {
    Text = 'bar side',
    Values = {'left', 'right', 'top', 'bottom'},
    Default = 1,
    Multi = false,
    Callback = function(value)
        Library.NotificationStyle.BarSide = value:sub(1,1):upper() .. value:sub(2)
    end
})

v.NotifGroup:AddDropdown('notifalignment', {
    Text = 'alignment',
    Values = {'left', 'center', 'right'},
    Default = 1,
    Multi = false,
    Callback = function(value)
        Library.NotificationStyle.Alignment = value:sub(1,1):upper() .. value:sub(2)
    end
})

v.NotifGroup:AddSlider('notifx', {
    Text = 'position x',
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        Library.NotificationStyle.X = value
    end
})

v.NotifGroup:AddSlider('notify', {
    Text = 'position y',
    Default = 10,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        Library.NotificationStyle.Y = value / 100
    end
})

v.NotifGroup:AddSlider('notiftransparency', {
    Text = 'transparency',
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        Library.NotificationStyle.Transparency = value / 100
    end
})



Library:OnUnload(function()
    print('Unload')
    Library.Unloaded = true
end)


Library.ToggleKeybind = Options.menukeybind



ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'menukeybind' })
ThemeManager:SetFolder('CryogenScript')
SaveManager:SetFolder('CryogenHeat')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()


if true then
    Library.AccentColor = Color3.fromRGB(54, 93, 171)
    Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
    Library.FadeColor = Color3.fromRGB(54, 93, 171)
    Library:UpdateColorsUsingRegistry()
end


local execName = "unknown"
pcall(function()
    if identifyexecutor then execName = identifyexecutor() end
end)


Library:Notify("cosmical universal loaded | executor: " .. execName, 6)


print("Cosmical Universal")


local supportedExecutors = { "wave", "volt", "awp", "synapse z", "potassium", "isaeva" }
local isSupported = false
for _, name in ipairs(supportedExecutors) do
    if execName:lower():find(name) then
        isSupported = true
        break
    end
end
if isSupported then
    print("your executor: supported!")
else
    print("your executor: unsupported!")
end


task.spawn(function()
    while Library.Watermark do
        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        local ms = math.floor(Player:GetNetworkPing() * 1000)
        Library:SetWatermark("cosmical  |  " .. fps .. " fps  |  " .. ms .. " ms")
        task.wait(0.5)
    end
end)
Library:SetWatermarkVisibility(true)
