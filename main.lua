--[[
=====================================================================
    ROCKET FLY v4.0 — ULTIMATE
    Автор: Rocket Way
    Назначение: красивый полёт с анимацией и нормальным управлением
    Формат: LocalScript / executor
    Разбит на 10 частей — вставлять подряд в один файл
=====================================================================

    ЧАСТЬ 1: Сервисы, конфиг, состояние
    ЧАСТЬ 2: Утилиты
    ЧАСТЬ 3: Персонаж, поза полёта (горизонтальная)
    ЧАСТЬ 4: Эффекты (трейл, частицы, свет, аура)
    ЧАСТЬ 5: Крылья (3D), звук
    ЧАСТЬ 6: Управление, движение, наклон
    ЧАСТЬ 7: Взлёт, посадка, hover, anti-void
    ЧАСТЬ 8: Dash, камера
    ЧАСТЬ 9: UI
    ЧАСТЬ 10: Хоткеи, инициализация, запуск

=====================================================================
--]]

-- ============================================================
-- СЕРВИСЫ
-- ============================================================
local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")
local TweenService         = game:GetService("TweenService")
local Lighting             = game:GetService("Lighting")
local SoundService         = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")
local Debris               = game:GetService("Debris")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ============================================================
-- КОНФИГ
-- ============================================================
local CONFIG = {
    -- ===== СКОРОСТЬ =====
    BaseSpeed        = 55,
    BoostMultiplier  = 2.8,
    SlowMultiplier   = 0.35,
    AccelRate        = 5.0,
    DecelRate        = 7.0,
    MaxSpeedCap      = 350,

    -- ===== УПРАВЛЕНИЕ =====
    CameraRelativeMove = true,       -- true = движение относительно камеры
    InvertPitch        = false,      -- инверсия наклона корпуса
    MoveInputDeadzone  = 0.05,       -- мёртвая зона ввода

    -- ===== АНИМАЦИЯ =====
    BobAmplitude     = 0.30,
    BobSpeed         = 2.0,
    SwayAmplitude    = 0.15,
    SwaySpeed        = 1.4,

    -- ===== НАКЛОН =====
    TiltMaxAngle     = 25,
    TiltSmoothing    = 0.12,
    RollOnStrafe     = true,
    PitchOnForward   = true,
    BodyLeanAngle    = 60,           -- наклон корпуса вперёд (лежит горизонтально)

    -- ===== ВЗЛЁТ / ПОСАДКА =====
    TakeoffDuration  = 0.80,
    LandingDuration  = 0.55,
    TakeoffHeight    = 9,
    LandingRayLen    = 600,

    -- ===== DASH =====
    DashPower        = 200,
    DashCooldown     = 0.80,
    DashFovBoost     = 12,
    DashFovTime      = 0.30,

    -- ===== КАМЕРА =====
    CameraFovBase    = 70,
    CameraFovMax     = 100,
    CameraFovSpeed   = 3.0,
    CameraLag        = 0.20,
    CameraEnabled    = true,

    -- ===== ЭФФЕКТЫ =====
    EnableTrail      = true,
    EnableParticles  = true,
    EnableSound      = true,
    EnableLight      = true,
    EnableWings      = true,
    EnableAura       = true,
    EnableSmoke      = true,

    TrailColor       = Color3.fromRGB(0, 200, 255),
    ParticleColor    = Color3.fromRGB(130, 225, 255),
    WingColor        = Color3.fromRGB(0, 170, 255),
    AuraColor        = Color3.fromRGB(0, 220, 255),
    LightColor       = Color3.fromRGB(0, 200, 255),
    SmokeColor       = Color3.fromRGB(200, 240, 255),

    LightRange       = 18,
    LightBrightness  = 3,

    -- ===== ПОЗА =====
    FlyPoseEnabled   = true,
    PoseHorizontal   = true,         -- лежит горизонтально
    PoseIdle         = "rbxassetid://0",
    PoseForward      = "rbxassetid://0",

    -- ===== БЕЗОПАСНОСТЬ =====
    AntiVoidEnabled  = true,
    VoidY            = -90,
    AntiVoidRecover  = 55,

    -- ===== КЛАВИШИ =====
    ToggleKey        = Enum.KeyCode.F,
    BoostKey         = Enum.KeyCode.LeftShift,
    SlowKey          = Enum.KeyCode.LeftControl,
    UpKey            = Enum.KeyCode.Space,
    DownKey          = Enum.KeyCode.LeftAlt,
    DashKey          = Enum.KeyCode.Q,
    GuiToggleKey     = Enum.KeyCode.RightShift,
    CamToggleKey     = Enum.KeyCode.C,
    WingsToggleKey   = Enum.KeyCode.G,
    AuraToggleKey    = Enum.KeyCode.H,

    -- ===== ПРОЧЕЕ =====
    Debug            = true,
    Version          = "4.0",
}

-- ============================================================
-- СОСТОЯНИЕ
-- ============================================================
local State = {
    Enabled      = false,
    Flying       = false,
    TakingOff    = false,
    Landing      = false,
    Dashing      = false,
    LastDash     = 0,

    Velocity     = Vector3.zero,
    DesiredVel   = Vector3.zero,
    SpeedMul     = 1,

    BobTime      = 0,
    SwayTime     = 0,
    CurrentTilt  = CFrame.new(),
    TargetTilt   = CFrame.new(),
    BodyLean     = CFrame.new(),

    Humanoid     = nil,
    RootPart     = nil,
    Animator     = nil,
    PoseTrack    = nil,

    Trail        = nil,
    Attachment0  = nil,
    Attachment1  = nil,
    Particle     = nil,
    Smoke        = nil,
    Sound        = nil,
    Light        = nil,
    WingL        = nil,
    WingR        = nil,
    Aura         = nil,

    CamBaseFov   = nil,
    CamOffset    = CFrame.new(),
    LastCamPos   = nil,

    Connections  = {},
    Started      = false,
    GuiRefs      = {},
}

-- ============================================================
-- ХРАНИЛИЩЕ ГЛОБАЛЬНЫХ ССЫЛОК (для склейки частей)
-- ============================================================
_G.RF = _G.RF or {}
_G.RF.Config  = CONFIG
_G.RF.State   = State
_G.RF.Services = {
    Players          = Players,
    RunService       = RunService,
    UserInputService = UserInputService,
    TweenService     = TweenService,
    Lighting         = Lighting,
    SoundService     = SoundService,
    Debris           = Debris,
    ReplicatedStorage = ReplicatedStorage,
    LocalPlayer      = LocalPlayer,
    Camera           = Camera,
}
_G.RF.Modules = _G.RF.Modules or {}

print("[ROCKET-FLY v" .. CONFIG.Version .. "] Часть 1 загружена — сервисы, конфиг, состояние.")

-- ============================================================
-- ЧАСТЬ 2: Утилиты
-- ============================================================

local RF = _G.RF
local CONFIG = RF.Config
local State  = RF.State
local Services = RF.Services

-- ============================================================
-- МОДУЛЬ: LOG
-- ============================================================
local Log = {}

function Log.info(msg)
    if CONFIG.Debug then
        print(("[ROCKET-FLY v%s] %s"):format(CONFIG.Version, tostring(msg)))
    end
end

function Log.warn(msg)
    warn(("[ROCKET-FLY v%s] %s"):format(CONFIG.Version, tostring(msg)))
end

function Log.err(msg)
    warn(("[ROCKET-FLY ERROR v%s] %s"):format(CONFIG.Version, tostring(msg)))
end

-- ============================================================
-- МОДУЛЬ: MATH (числа)
-- ============================================================
local Math = {}

function Math.lerp(a, b, t)
    return a + (b - a) * t
end

function Math.clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

function Math.clamp01(v)
    return Math.clamp(v, 0, 1)
end

function Math.round(v, n)
    local m = 10 ^ (n or 0)
    return math.floor(v * m + 0.5) / m
end

function Math.sign(v)
    if v > 0 then return 1 end
    if v < 0 then return -1 end
    return 0
end

function Math.lerpAngle(a, b, t)
    local diff = (b - a + math.pi) % (2 * math.pi) - math.pi
    return a + diff * t
end

-- ============================================================
-- МОДУЛЬ: EASING
-- ============================================================
local Ease = {}

function Ease.linear(t)
    return Math.clamp01(t)
end

function Ease.outQuad(t)
    t = Math.clamp01(t)
    return 1 - (1 - t) * (1 - t)
end

function Ease.outCubic(t)
    t = Math.clamp01(t)
    return 1 - (1 - t) ^ 3
end

function Ease.outQuart(t)
    t = Math.clamp01(t)
    return 1 - (1 - t) ^ 4
end

function Ease.outQuint(t)
    t = Math.clamp01(t)
    return 1 - (1 - t) ^ 5
end

function Ease.inQuad(t)
    t = Math.clamp01(t)
    return t * t
end

function Ease.inCubic(t)
    t = Math.clamp01(t)
    return t ^ 3
end

function Ease.inOutCubic(t)
    t = Math.clamp01(t)
    if t < 0.5 then
        return 4 * t ^ 3
    else
        return 1 - ((-2 * t + 2) ^ 3) / 2
    end
end

function Ease.inOutQuad(t)
    t = Math.clamp01(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return 1 - ((-2 * t + 2) ^ 2) / 2
    end
end

function Ease.smoothstep(t)
    t = Math.clamp01(t)
    return t * t * (3 - 2 * t)
end

function Ease.smootherstep(t)
    t = Math.clamp01(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

function Ease.outBack(t)
    t = Math.clamp01(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

function Ease.outElastic(t)
    t = Math.clamp01(t)
    if t == 0 or t == 1 then return t end
    local c4 = (2 * math.pi) / 3
    return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end

-- ============================================================
-- МОДУЛЬ: VECTOR
-- ============================================================
local Vec = {}

function Vec.lerp(a, b, t)
    return Vector3.new(
        a.X + (b.X - a.X) * t,
        a.Y + (b.Y - a.Y) * t,
        a.Z + (b.Z - a.Z) * t
    )
end

function Vec.unitSafe(v)
    if v.Magnitude > 0.0001 then
        return v.Unit
    end
    return Vector3.zero
end

function Vec.flatten(v)
    return Vector3.new(v.X, 0, v.Z)
end

function Vec.flattenUnit(v)
    local f = Vec.flatten(v)
    if f.Magnitude > 0.0001 then
        return f.Unit
    end
    return Vector3.zero
end

function Vec.distance(a, b)
    return (a - b).Magnitude
end

function Vec.dot(a, b)
    return a:Dot(b)
end

function Vec.projectOnPlane(v, normal)
    return v - normal * v:Dot(normal)
end

-- ============================================================
-- МОДУЛЬ: CFrame-хелперы
-- ============================================================
local CFrameUtil = {}

function CFrameUtil.fromDirection(dir, up)
    up = up or Vector3.new(0, 1, 0)
    if dir.Magnitude < 0.0001 then
        return CFrame.new()
    end
    dir = dir.Unit
    local right = dir:Cross(up)
    if right.Magnitude < 0.0001 then
        right = dir:Cross(Vector3.new(1, 0, 0))
    end
    right = right.Unit
    local realUp = right:Cross(dir).Unit
    return CFrame.fromMatrix(Vector3.zero, right, realUp)
end

function CFrameUtil.pitch(angle)
    return CFrame.Angles(angle, 0, 0)
end

function CFrameUtil.yaw(angle)
    return CFrame.Angles(0, angle, 0)
end

function CFrameUtil.roll(angle)
    return CFrame.Angles(0, 0, angle)
end

function CFrameUtil.lerp(a, b, t)
    return a:Lerp(b, Math.clamp01(t))
end

function CFrameUtil.lookAt(from, to, up)
    return CFrame.lookAt(from, to, up or Vector3.new(0, 1, 0))
end

-- ============================================================
-- МОДУЛЬ: RAYCAST
-- ============================================================
local Ray = {}

function Ray.down(origin, length, ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList or {}
    params.IgnoreWater = true
    return workspace:Raycast(origin, Vector3.new(0, -(length or 500), 0), params)
end

function Ray.fromTo(from, to, ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList or {}
    params.IgnoreWater = true
    return workspace:Raycast(from, to - from, params)
end

function Ray.direction(origin, dir, length, ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList or {}
    params.IgnoreWater = true
    return workspace:Raycast(origin, dir.Unit * (length or 500), params)
end

-- ============================================================
-- МОДУЛЬ: INSTANCE
-- ============================================================
local Inst = {}

function Inst.safeDestroy(inst)
    if inst and typeof(inst) == "Instance" then
        pcall(function()
            if inst.Parent then inst:Destroy() end
        end)
    end
end

function Inst.make(className, props, parent)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            pcall(function() inst[k] = v end)
        end
    end
    if parent then inst.Parent = parent end
    return inst
end

function Inst.corner(parent, radius)
    return Inst.make("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
    }, parent)
end

function Inst.stroke(parent, color, thickness, transparency)
    return Inst.make("UIStroke", {
        Color = color or Color3.fromRGB(0, 200, 255),
        Thickness = thickness or 1.5,
        Transparency = transparency or 0.25,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

function Inst.padding(parent, px)
    return Inst.make("UIPadding", {
        PaddingTop    = UDim.new(0, px),
        PaddingBottom = UDim.new(0, px),
        PaddingLeft   = UDim.new(0, px),
        PaddingRight  = UDim.new(0, px),
    }, parent)
end

function Inst.gradient(parent, color1, color2, rotation)
    local seq = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2),
    })
    return Inst.make("UIGradient", {
        Color = seq,
        Rotation = rotation or 90,
    }, parent)
end

-- ============================================================
-- МОДУЛЬ: CONNECTIONS
-- ============================================================
local Conn = {}

function Conn.track(c)
    table.insert(State.Connections, c)
    return c
end

function Conn.clear()
    for _, c in ipairs(State.Connections) do
        pcall(function() c:Disconnect() end)
    end
    State.Connections = {}
end

-- ============================================================
-- МОДУЛЬ: SAFE SPAWN
-- ============================================================
local Thread = {}

function Thread.spawn(fn, ...)
    local args = {...}
    local co = coroutine.create(function()
        local ok, err = pcall(fn, table.unpack(args))
        if not ok then
            Log.err("Ошибка в потоке: " .. tostring(err))
        end
    end)
    coroutine.resume(co)
    return co
end

function Thread.delay(sec, fn)
    task.delay(sec, function()
        local ok, err = pcall(fn)
        if not ok then
            Log.err("Ошибка в delay: " .. tostring(err))
        end
    end)
end

-- ============================================================
-- ЭКСПОРТ
-- ============================================================
RF.Modules.Log       = Log
RF.Modules.Math      = Math
RF.Modules.Ease      = Ease
RF.Modules.Vec       = Vec
RF.Modules.CFrame    = CFrameUtil
RF.Modules.Ray       = Ray
RF.Modules.Inst      = Inst
RF.Modules.Conn      = Conn
RF.Modules.Thread    = Thread

-- Короткие ссылки
_G.RF.Log    = Log
_G.RF.Math   = Math
_G.RF.Ease   = Ease
_G.RF.Vec    = Vec
_G.RF.CFrame = CFrameUtil
_G.RF.Ray    = Ray
_G.RF.Inst   = Inst
_G.RF.Conn   = Conn
_G.RF.Thread = Thread

Log.info("Часть 2 загружена — утилиты.")

-- ============================================================
-- ЧАСТЬ 3: Персонаж, поза полёта, эффекты
-- ============================================================

local RF     = _G.RF
local CONFIG = RF.Config
local State  = RF.State
local Log    = RF.Log
local Math   = RF.Math
local Ease   = RF.Ease
local Vec    = RF.Vec
local CFrameUtil = RF.CFrame
local Ray    = RF.Ray
local Inst   = RF.Inst
local Conn   = RF.Conn
local Thread = RF.Thread
local Services = RF.Services

local Players          = Services.Players
local RunService       = Services.RunService
local TweenService     = Services.TweenService
local SoundService     = Services.SoundService
local LocalPlayer      = Services.LocalPlayer
local Camera           = Services.Camera

-- ============================================================
-- МОДУЛЬ: ПОЗА
-- ============================================================
local Pose = {}

function Pose.getIdleCFrame()
    return CFrame.Angles(math.rad(-90), 0, 0)
end

function Pose.getForwardCFrame()
    return CFrame.Angles(math.rad(-CONFIG.BodyLeanAngle), 0, 0)
end

function Pose.compose(baseTilt, move)
    local pitch = 0
    local roll = 0

    if CONFIG.PitchOnForward and move.Z ~= 0 then
        pitch = -move.Z * math.rad(CONFIG.TiltMaxAngle)
    end
    if CONFIG.RollOnStrafe and move.X ~= 0 then
        roll = -move.X * math.rad(CONFIG.TiltMaxAngle)
    end

    local bodyPose = CFrame.Angles(math.rad(-90), 0, 0)
    local tilt = CFrame.Angles(pitch, 0, roll)

    return baseTilt * bodyPose * tilt
end

function Pose.apply(baseCamCF, move, dt)
    if not State.RootPart then return end

    local pos = State.RootPart.Position
    local base = CFrame.new(pos, pos + baseCamCF.LookVector)
    local poseCF = Pose.compose(CFrame.new(), move)
    local target = base * poseCF
    local t = Math.clamp01(CONFIG.TiltSmoothing * dt * 60)
    State.CurrentTilt = State.CurrentTilt:Lerp(target, t)
    State.RootPart.CFrame = State.CurrentTilt
end

function Pose.start()
    if State.PoseTrack then
        pcall(function() State.PoseTrack:Play(0.15) end)
    end
end

function Pose.stop()
    if State.PoseTrack then
        pcall(function() State.PoseTrack:Stop(0.15) end)
    end
end

function Pose.setSpeed(speed)
    if not State.PoseTrack then return end
    local maxSpeed = CONFIG.BaseSpeed * CONFIG.BoostMultiplier
    local s = Math.clamp(speed / math.max(maxSpeed, 1), 0.25, 2.5)
    pcall(function() State.PoseTrack:AdjustSpeed(s) end)
end

-- ============================================================
-- ЗАГРУЗКА АНИМАЦИИ
-- ============================================================
local function loadPoseTrack(animator, id)
    if not id or id == "" or id == "rbxassetid://0" then
        return nil
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    local ok, track = pcall(function()
        return animator:LoadAnimation(anim)
    end)
    if ok and track then
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = true
        return track
    end
    return nil
end

-- ============================================================
-- ЭФФЕКТ: ТРЕЙЛ
-- ============================================================
local function createTrail(root)
    if not CONFIG.EnableTrail then return nil end

    local a0 = Inst.make("Attachment", {
        Name = "RF_TrailA0",
        Position = Vector3.new(0, 1.2, 0),
    }, root)

    local a1 = Inst.make("Attachment", {
        Name = "RF_TrailA1",
        Position = Vector3.new(0, -1.2, 0),
    }, root)

    local trail = Inst.make("Trail", {
        Name = "RF_Trail",
        Attachment0 = a0,
        Attachment1 = a1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, CONFIG.TrailColor),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 240, 255)),
            ColorSequenceKeypoint.new(1, CONFIG.TrailColor),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.6, 0.4),
            NumberSequenceKeypoint.new(1, 1),
        }),
        WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.7),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Lifetime = 0.55,
        MinLength = 0.1,
        LightEmission = 0.85,
        LightInfluence = 0,
        FaceCamera = true,
    }, root)

    State.Attachment0 = a0
    State.Attachment1 = a1
    return trail
end

-- ============================================================
-- ЭФФЕКТ: ЧАСТИЦЫ
-- ============================================================
local function createParticles(root)
    if not CONFIG.EnableParticles then return nil end

    return Inst.make("ParticleEmitter", {
        Name = "RF_Particles",
        Texture = "rbxassetid://243660364",
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, CONFIG.ParticleColor),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
        }),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.9),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Lifetime = NumberRange.new(0.35, 0.75),
        Rate = 55,
        Speed = NumberRange.new(3, 9),
        SpreadAngle = Vector2.new(180, 180),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-180, 180),
        LightEmission = 0.95,
        LightInfluence = 0,
        Acceleration = Vector3.new(0, 4, 0),
    }, root)
end

-- ============================================================
-- ЭФФЕКТ: ДЫМ (для усиления на boost)
-- ============================================================
local function createSmoke(root)
    if not CONFIG.EnableSmoke then return nil end

    return Inst.make("ParticleEmitter", {
        Name = "RF_Smoke",
        Texture = "rbxassetid://241876428",
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, CONFIG.SmokeColor),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
        }),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1.5),
            NumberSequenceKeypoint.new(1, 4),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Lifetime = NumberRange.new(0.6, 1.2),
        Rate = 12,
        Speed = NumberRange.new(1, 3),
        SpreadAngle = Vector2.new(180, 180),
        LightEmission = 0.3,
    }, root)
end

-- ============================================================
-- ЭФФЕКТ: СВЕТ
-- ============================================================
local function createLight(root)
    if not CONFIG.EnableLight then return nil end

    return Inst.make("PointLight", {
        Name = "RF_Light",
        Color = CONFIG.LightColor,
        Range = CONFIG.LightRange,
        Brightness = CONFIG.LightBrightness,
        Shadows = false,
    }, root)
end

-- ============================================================
-- ЭФФЕКТ: АУРА (сфера ForceField)
-- ============================================================
local function createAura(root)
    if not CONFIG.EnableAura then return nil end

    local sphere = Inst.make("Part", {
        Name = "RF_Aura",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(6, 6, 6),
        Transparency = 0.75,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
        Massless = true,
        Anchored = false,
        Material = Enum.Material.ForceField,
        Color = CONFIG.AuraColor,
        CFrame = root.CFrame,
    }, root)

    local weld = Inst.make("WeldConstraint", {
        Part0 = root,
        Part1 = sphere,
    }, sphere)

    return sphere
end

-- ============================================================
-- ЭФФЕКТ: ЗВУК
-- ============================================================
local function createSound()
    if not CONFIG.EnableSound then return nil end

    return Inst.make("Sound", {
        Name = "RF_Sound",
        SoundId = "rbxassetid://9125402735",
        Volume = 0.35,
        Looped = true,
        PlaybackSpeed = 1.1,
    }, SoundService)
end

-- ============================================================
-- УДАЛЕНИЕ ЭФФЕКТОВ
-- ============================================================
local function cleanupEffects()
    Inst.safeDestroy(State.Trail)
    Inst.safeDestroy(State.Attachment0)
    Inst.safeDestroy(State.Attachment1)
    Inst.safeDestroy(State.Particle)
    Inst.safeDestroy(State.Smoke)
    Inst.safeDestroy(State.Sound)
    Inst.safeDestroy(State.Light)
    Inst.safeDestroy(State.WingL)
    Inst.safeDestroy(State.WingR)
    Inst.safeDestroy(State.Aura)

    State.Trail       = nil
    State.Attachment0 = nil
    State.Attachment1 = nil
    State.Particle    = nil
    State.Smoke       = nil
    State.Sound       = nil
    State.Light       = nil
    State.WingL       = nil
    State.WingR       = nil
    State.Aura        = nil
end

-- ============================================================
-- ВКЛЮЧЕНИЕ / ВЫКЛЮЧЕНИЕ ЭФФЕКТОВ
-- ============================================================
local function setEffectsEnabled(on)
    if State.Trail then State.Trail.Enabled = on end
    if State.Particle then State.Particle.Enabled = on end
    if State.Smoke then State.Smoke.Enabled = on end
    if State.Light then State.Light.Enabled = on end

    local wingAlpha = on and 0.35 or 1
    local auraAlpha = on and 0.75 or 1

    if State.WingL then State.WingL.Transparency = wingAlpha end
    if State.WingR then State.WingR.Transparency = wingAlpha end
    if State.Aura then State.Aura.Transparency = auraAlpha end

    if State.Sound then
        if on then
            if not State.Sound.IsPlaying then State.Sound:Play() end
        else
            State.Sound:Stop()
        end
    end
end

-- ============================================================
-- АНИМАЦИЯ ЭФФЕКТОВ
-- ============================================================
local function updateEffects(dt)
    if not State.Flying then return end
    local t = tick()

    if State.Light then
        State.Light.Brightness = CONFIG.LightBrightness + math.sin(t * 4) * 0.8
        State.Light.Range = CONFIG.LightRange + math.sin(t * 2.2) * 2
    end

    if State.Aura then
        local pulse = 1 + math.sin(t * 3.4) * 0.06
        State.Aura.Size = Vector3.new(6, 6, 6) * pulse
    end

    if State.WingL and State.WingR then
        local flutter = math.sin(t * 9) * 0.15
        State.WingL.CFrame = State.WingL.CFrame * CFrame.Angles(0, 0, flutter)
        State.WingR.CFrame = State.WingR.CFrame * CFrame.Angles(0, 0, -flutter)
    end

    if State.Particle then
        State.Particle.Rate = 55 + math.sin(t * 5) * 15
    end

    if State.Smoke then
        local boost = State.SpeedMul > 1 and 1.5 or 1
        State.Smoke.Rate = 12 * boost
    end
end

-- ============================================================
-- ПРИВЯЗКА ПЕРСОНАЖА
-- ============================================================
local Bind = {}

function Bind.character(char)
    if not char then return end

    local humanoid = char:WaitForChild("Humanoid", 5)
    local root     = char:WaitForChild("HumanoidRootPart", 5)

    if not humanoid or not root then
        Log.warn("Не удалось привязать персонажа.")
        return
    end

    State.Humanoid = humanoid
    State.RootPart = root

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    State.Animator = animator

    if CONFIG.FlyPoseEnabled then
        State.PoseTrack = loadPoseTrack(animator, CONFIG.PoseIdle)
        if not State.PoseTrack then
            State.PoseTrack = loadPoseTrack(animator, CONFIG.PoseForward)
        end
    end

    -- Эффекты
    State.Trail    = createTrail(root)
    State.Particle = createParticles(root)
    State.Smoke    = createSmoke(root)
    State.Light    = createLight(root)
    State.Aura     = createAura(root)
    State.Sound    = createSound()

    -- Скрываем до включения
    setEffectsEnabled(false)
    if State.Sound then State.Sound:Stop() end

    Conn.track(humanoid.Died:Connect(function()
        Log.info("Персонаж погиб — выключаем полёт.")
        if RF.Rocket and RF.Rocket.disableFly then
            RF.Rocket.disableFly()
        end
        cleanupEffects()
    end))

    Log.info("Персонаж привязан.")
end

-- ============================================================
-- ЭКСПОРТ
-- ============================================================
RF.Pose = Pose
RF.Bind = Bind
RF.Effects = {
    createTrail      = createTrail,
    createParticles  = createParticles,
    createSmoke      = createSmoke,
    createLight      = createLight,
    createAura       = createAura,
    createSound      = createSound,
    cleanup          = cleanupEffects,
    setEnabled       = setEffectsEnabled,
    update           = updateEffects,
}

Log.info("Часть 3 загружена — персонаж, поза, эффекты.")

-- ============================================================
-- ЧАСТЬ 4: Крылья (3D), звук ускорения, эффекты dash
-- ============================================================

local RF     = _G.RF
local CONFIG = RF.Config
local State  = RF.State
local Log    = RF.Log
local Math   = RF.Math
local Ease   = RF.Ease
local Vec    = RF.Vec
local CFrameUtil = RF.CFrame
local Ray    = RF.Ray
local Inst   = RF.Inst
local Conn   = RF.Conn
local Thread = RF.Thread
local Services = RF.Services

local RunService       = Services.RunService
local TweenService     = Services.TweenService
local SoundService     = Services.SoundService
local LocalPlayer      = Services.LocalPlayer
local Camera           = Services.Camera

-- ============================================================
-- МОДУЛЬ: КРЫЛЬЯ
-- ============================================================
-- Создаём два крыла из нескольких частей-перьев, чтобы было похоже
-- на настоящие 3D-крылья, а не на плоские прямоугольники.

local Wings = {}

local WING_PER_FEATHER = 5  -- количество перьев на крыло

-- Создание одного пера
local function createFeather(root, side, index, total)
    local feather = Inst.make("Part", {
        Name = ("RF_Feather_%s_%d"):format(side, index),
        Size = Vector3.new(0.1, 0.6, 1.6),
        Transparency = 0.15,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
        Massless = true,
        Anchored = false,
        Material = Enum.Material.Neon,
        Color = CONFIG.WingColor,
        CFrame = root.CFrame,
    }, root)

    -- Смещение: перья идут веером назад и вниз
    local ratio = (index - 1) / math.max(total - 1, 1)
    local angle = math.rad(-30 - ratio * 55)          -- наклон пера
    local offsetX = (side == "L") and -1.5 or 1.5
    local offsetY = 0.4 - ratio * 0.6
    local offsetZ = -0.4 - ratio * 1.4

    local cframe = root.CFrame
        * CFrame.new(offsetX, offsetY, offsetZ)
        * CFrame.Angles(0, 0, 0)
        * CFrame.Angles(angle, 0, 0)

    feather.CFrame = cframe

    -- Weld к root
    Inst.make("WeldConstraint", {
        Part0 = root,
        Part1 = feather,
    }, feather)

    -- Свечение (Trail по краю пера)
    local a0 = Inst.make("Attachment", { Position = Vector3.new(0, 0.3, 0.8) }, feather)
    local a1 = Inst.make("Attachment", { Position = Vector3.new(0, -0.3, -0.8) }, feather)

    Inst.make("Trail", {
        Attachment0 = a0,
        Attachment1 = a1,
        Color = ColorSequence.new(CONFIG.WingColor),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Lifetime = 0.25,
        LightEmission = 1,
        FaceCamera = true,
    }, feather)

    return feather
end

-- Создание крыла целиком
function Wings.create(root, side)
    if not CONFIG.EnableWings then return nil end

    -- Контейнер-модель
    local model = Inst.make("Model", {
        Name = "RF_Wing_" .. side,
    }, root)

    local feathers = {}
    for i = 1, WING_PER_FEATHER do
        local f = createFeather(root, side, i, WING_PER_FEATHER)
        table.insert(feathers, f)
    end

    return {
        model = model,
        feathers = feathers,
        side = side,
    }
end

-- Обновление (взмах крыльев)
function Wings.update(wing, dt)
    if not wing then return end
    if not wing.feathers then return end

    local t = tick()
    local flap = math.sin(t * 6) * 0.25
    local dir = (wing.side == "L") and 1 or -1

    for i, f in ipairs(wing.feathers) do
        if f and f.Parent then
            local base = f:FindFirstChild("RF_Base")
            -- Слегка поворачиваем каждое перо
            local ratio = (i - 1) / math.max(#wing.feathers - 1, 1)
            local angle = flap * (0.5 + ratio)
            f.CFrame = f.CFrame * CFrame.Angles(0, 0, angle * dir * dt * 20)
        end
    end
end

-- Очистка крыльев
function Wings.destroy(wing)
    if not wing then return end
    if wing.feathers then
        for _, f in ipairs(wing.feathers) do
            Inst.safeDestroy(f)
        end
    end
    Inst.safeDestroy(wing.model)
end

-- Применение прозрачности (для вкл/выкл)
function Wings.setVisible(wing, visible)
    if not wing then return end
    local alpha = visible and 0.15 or 1
    if wing.feathers then
        for _, f in ipairs(wing.feathers) do
            if f and f.Parent then
                f.Transparency = alpha
            end
        end
    end
end

-- ============================================================
-- ЗВУК УСКОРЕНИЯ (отдельный, играет при boost)
-- ============================================================
local BoostSound = {}

function BoostSound.create()
    if not CONFIG.EnableSound then return nil end
    local s = Inst.make("Sound", {
        Name = "RF_BoostSound",
        SoundId = "rbxassetid://131237241", -- свой звук можно поставить
        Volume = 0.4,
        Looped = false,
        PlaybackSpeed = 1.2,
    }, SoundService)
    return s
end

function BoostSound.play(sound)
    if not sound then return end
    pcall(function()
        sound:Stop()
        sound:Play()
    end)
end

-- ============================================================
-- ЭФФЕКТ DASH (взрыв частиц + рывок визуально)
-- ============================================================
local DashEffect = {}

function DashEffect.createBurst(root)
    if not root then return end

    -- Частицы-вспышка
    local burst = Inst.make("Part", {
        Name = "RF_DashBurst",
        Size = Vector3.new(0.1, 0.1, 0.1),
        Transparency = 1,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
        Anchored = true,
        CFrame = root.CFrame,
    }, workspace)

    local emitter = Inst.make("ParticleEmitter", {
        Texture = "rbxassetid://243660364",
        Color = ColorSequence.new(CONFIG.ParticleColor),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 2.5),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Lifetime = NumberRange.new(0.4, 0.7),
        Speed = NumberRange.new(20, 40),
        SpreadAngle = Vector2.new(180, 180),
        Rate = 0,
        LightEmission = 1,
    }, burst)

    emitter:Emit(60)

    -- Удаляем через секунду
    Inst.make("Debris", {}, nil) -- заглушка (не используется)
    game:GetService("Debris"):AddItem(burst, 1.2)
end

-- Шлейф-волна (кольцо)
function DashEffect.createRing(root)
    if not root then return end

    local ring = Inst.make("Part", {
        Name = "RF_DashRing",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(0.2, 4, 4),
        Transparency = 0.3,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
        Anchored = true,
        Material = Enum.Material.Neon,
        Color = CONFIG.ParticleColor,
        CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90)),
    }, workspace)

    local tween = TweenService:Create(
        ring,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(0.2, 16, 16),
            Transparency = 1,
        }
    )
    tween:Play()

    game:GetService("Debris"):AddItem(ring, 0.7)
end

function DashEffect.play(root)
    DashEffect.createBurst(root)
    DashEffect.createRing(root)
end

-- ============================================================
-- ИНТЕГРАЦИЯ В ОБЩУЮ СИСТЕМУ
-- ============================================================
-- Переопределяем существующие State поля под крылья-объекты

local function rebuildWings()
    if not State.RootPart then return end
    Wings.destroy(State.WingL)
    Wings.destroy(State.WingR)
    State.WingL = Wings.create(State.RootPart, "L")
    State.WingR = Wings.create(State.RootPart, "R")
    if State.Flying then
        Wings.setVisible(State.WingL, true)
        Wings.setVisible(State.WingR, true)
    else
        Wings.setVisible(State.WingL, false)
        Wings.setVisible(State.WingR, false)
    end
end

-- Обновление взмаха крыльев
local function updateWings(dt)
    Wings.update(State.WingL, dt)
    Wings.update(State.WingR, dt)
end

-- ============================================================
-- ЭКСПОРТ
-- ============================================================
RF.Wings = Wings
RF.BoostSound = BoostSound
RF.DashEffect = DashEffect

RF.Extras = {
    rebuildWings = rebuildWings,
    updateWings  = updateWings,
}

Log.info("Часть 4 загружена — крылья, звук ускорения, эффекты dash.")

-- ============================================================
-- ЧАСТЬ 5: Управление (чистое), движение, наклон
-- ============================================================

local RF     = _G.RF
local CONFIG = RF.Config
local State  = RF.State
local Log    = RF.Log
local Math   = RF.Math
local Ease   = RF.Ease
local Vec    = RF.Vec
local CFrameUtil = RF.CFrame
local Ray    = RF.Ray
local Inst   = RF.Inst
local Conn   = RF.Conn
local Thread = RF.Thread
local Services = RF.Services

local RunService       = Services.RunService
local UserInputService = Services.UserInputService
local LocalPlayer      = Services.LocalPlayer
local Camera           = Services.Camera

-- ============================================================
-- МОДУЛЬ: УПРАВЛЕНИЕ (INPUT)
-- ============================================================
-- Собираем вектор ввода от игрока (WASD + Space/Alt).
-- Управление простое: W вперёд, S назад, A влево, D вправо.
-- Не зависит от камеры, если CameraRelativeMove = false.

local Input = {}

-- Внутренний кэш клавиш
local KeyState = {
    W = false, A = false, S = false, D = false,
    Up = false, Down = false,
    Boost = false, Slow = false,
}

function Input.updateKeyState()
    KeyState.W = UserInputService:IsKeyDown(Enum.KeyCode.W)
    KeyState.A = UserInputService:IsKeyDown(Enum.KeyCode.A)
    KeyState.S = UserInputService:IsKeyDown(Enum.KeyCode.S)
    KeyState.D = UserInputService:IsKeyDown(Enum.KeyCode.D)
    KeyState.Up = UserInputService:IsKeyDown(CONFIG.UpKey)
    KeyState.Down = UserInputService:IsKeyDown(CONFIG.DownKey)
    KeyState.Boost = UserInputService:IsKeyDown(CONFIG.BoostKey)
    KeyState.Slow = UserInputService:IsKeyDown(CONFIG.SlowKey)
end

-- Возвращает «сырой» вектор ввода (единичный, в системе координат WASD)
function Input.getRawMove()
    Input.updateKeyState()
    local move = Vector3.zero

    if KeyState.W then move += Vector3.new(0, 0, -1) end
    if KeyState.S then move += Vector3.new(0, 0,  1) end
    if KeyState.A then move += Vector3.new(-1, 0, 0) end
    if KeyState.D then move += Vector3.new( 1, 0, 0) end
    if KeyState.Up   then move += Vector3.new(0,  1, 0) end
    if KeyState.Down then move += Vector3.new(0, -1, 0) end

    if move.Magnitude > CONFIG.MoveInputDeadzone then
        move = move.Unit
    else
        move = Vector3.zero
    end

    return move
end

-- Преобразование в мировые координаты
function Input.toWorld(move)
    if move.Magnitude < 0.0001 then
        return Vector3.zero
    end

    if not CONFIG.CameraRelativeMove then
        -- Простое управление: WASD = мировые оси XZ, Space/Alt = Y
        return Vector3.new(move.X, move.Y, move.Z)
    end

    local camCF = Camera.CFrame
    local look  = camCF.LookVector
    local right = camCF.RightVector

    look  = Vec.flattenUnit(look)
    right = Vec.flattenUnit(right)

    local world = Vector3.zero
    world += right * move.X
    world += look  * (-move.Z)
    world += Vector3.new(0, 1, 0) * move.Y

    if world.Magnitude > 0 then
        world = world.Unit
    end
    return world
end

-- Публичный метод: получить вектор движения в мире
function Input.getWorldMove()
    local raw = Input.getRawMove()
    return Input.toWorld(raw)
end

-- Публичный метод: получить вектор для анимации наклона
function Input.getLocalMove()
    return Input.getRawMove()
end

-- ============================================================
-- МОДУЛЬ: ДВИЖЕНИЕ (MOTION)
-- ============================================================
-- Основной цикл: считаем желаемую скорость → плавно интерполируем
-- → применяем к CFrame HumanoidRootPart.

local Motion = {}

function Motion.getSpeedMultiplier()
    local mul = 1
    if UserInputService:IsKeyDown(CONFIG.BoostKey) then
        mul = CONFIG.BoostMultiplier
    elseif UserInputService:IsKeyDown(CONFIG.SlowKey) then
        mul = CONFIG.SlowMultiplier
    end
    State.SpeedMul = mul
    return mul
end

function Motion.computeDesiredVelocity(dt)
    local world = Input.getWorldMove()
    local mul = Motion.getSpeedMultiplier()
    local speed = CONFIG.BaseSpeed * mul

    if State.Dashing then
        speed = CONFIG.DashPower
    end

    local desired = world * speed

    -- Ограничение
    if desired.Magnitude > CONFIG.MaxSpeedCap then
        desired = desired.Unit * CONFIG.MaxSpeedCap
    end

    return desired
end

function Motion.updateVelocity(dt)
    local desired = Motion.computeDesiredVelocity(dt)
    State.DesiredVel = desired

    -- Разгон / торможение
    local rate = (desired.Magnitude > State.Velocity.Magnitude)
        and CONFIG.AccelRate or CONFIG.DecelRate
    local t = Math.clamp01(rate * dt)
    State.Velocity = Vec.lerp(State.Velocity, desired, t)
end

function Motion.applyToRoot(dt)
    if not State.RootPart then return end
    if not State.Flying then return end

    local newPos = State.RootPart.Position + State.Velocity * dt

    -- Применяем
    State.RootPart.CFrame = CFrame.new(newPos) * State.CurrentTilt

    -- Обнуляем физику
    State.RootPart.Velocity = Vector3.zero
    State.RootPart.RotVelocity = Vector3.zero
    State.RootPart.AssemblyLinearVelocity = Vector3.zero
    State.RootPart.AssemblyAngularVelocity = Vector3.zero
end

function Motion.update(dt)
    if not State.Flying then return end
    Motion.updateVelocity(dt)
    Motion.applyToRoot(dt)
end

-- ============================================================
-- МОДУЛЬ: НАКЛОН (TILT)
-- ============================================================
-- Управляет поворотом корпуса персонажа:
--   * при движении вперёд — наклоняется вперёд
--   * при стрейфе — крен в сторону
--   * в покое — базовая горизонтальная поза

local Tilt = {}

function Tilt.computeTarget(move)
    local pitch = 0
    local roll = 0

    if CONFIG.PitchOnForward and move.Z ~= 0 then
        pitch = -move.Z * math.rad(CONFIG.TiltMaxAngle)
    end
    if CONFIG.RollOnStrafe and move.X ~= 0 then
        roll = -move.X * math.rad(CONFIG.TiltMaxAngle)
    end

    if CONFIG.InvertPitch then
        pitch = -pitch
    end

    return pitch, roll
end

function Tilt.update(dt)
    if not State.RootPart then return end
    if not State.Flying then return end

    local move = Input.getLocalMove()
    local pitch, roll = Tilt.computeTarget(move)

    -- Базовая ориентация по камере
    local camCF = Camera.CFrame
    local lookVec = camCF.LookVector
    local rightVec = camCF.RightVector
    local upVec = Vector3.new(0, 1, 0)

    local base = CFrame.fromMatrix(Vector3.zero, rightVec, upVec, -lookVec)

    -- Горизонтальная поза
    local bodyPose = CFrame.Angles(math.rad(-90), 0, 0)

    -- Наклон
    local tilt = CFrame.Angles(pitch, 0, roll)

    local target = base * bodyPose * tilt

    -- Сглаживание
    local t = Math.clamp01(CONFIG.TiltSmoothing * dt * 60)
    State.CurrentTilt = State.CurrentTilt:Lerp(target, t)
end

-- ============================================================
-- HOVER (покачивание)
-- ============================================================
local Hover = {}

function Hover.update(dt)
    if not State.Flying then return end
    if not State.RootPart then return end

    State.BobTime += dt * CONFIG.BobSpeed
    State.SwayTime += dt * CONFIG.SwaySpeed

    local move = Input.getLocalMove()
    local intensity = 1 - Math.clamp01(move.Magnitude)

    local bob  = math.sin(State.BobTime) * CONFIG.BobAmplitude * intensity
    local sway = math.sin(State.SwayTime) * CONFIG.SwayAmplitude * intensity

    local camCF = Camera.CFrame
    local right = Vec.flattenUnit(camCF.RightVector)
    local up = Vector3.new(0, 1, 0)

    local offset = up * bob + right * sway
    State.RootPart.CFrame = State.RootPart.CFrame + offset * dt * 60
end

-- ============================================================
-- ОБЩИЙ ЦИКЛ ДВИЖЕНИЯ
-- ============================================================
local function flightLoop(dt)
    if not State.Flying then return end
    if State.TakingOff or State.Landing then return end

    Tilt.update(dt)
    Motion.update(dt)
    Hover.update(dt)

    -- Обновляем позу
    if RF.Pose and RF.Pose.setSpeed then
        RF.Pose.setSpeed(State.Velocity.Magnitude)
    end
end

Conn.track(RunService.Heartbeat:Connect(flightLoop))

-- ============================================================
-- ЭКСПОРТ
-- ============================================================
RF.Input  = Input
RF.Motion = Motion
RF.Tilt   = Tilt
RF.Hover  = Hover

Log.info("Часть 5 загружена — управление, движение, наклон.")

-- ============================================================
-- ЧАСТЬ 6: Взлёт, посадка, anti-void
-- ============================================================

local RF     = _G.RF
local CONFIG = RF.Config
local State  = RF.State
local Log    = RF.Log
local Math   = RF.Math
local Ease   = RF.Ease
local Vec    = RF.Vec
local CFrameUtil = RF.CFrame
local Ray    = RF.Ray
local Inst   = RF.Inst
local Conn   = RF.Conn
local Thread = RF.Thread
local Services = RF.Services

local RunService       = Services.RunService
local TweenService     = Services.TweenService
local LocalPlayer      = Services.LocalPlayer
local Camera           = Services.Camera

-- ============================================================
-- ВСПОМОГАТЕЛЬНОЕ: ПОИСК ЗЕМЛИ ПОД ПЕРСОНАЖЕМ
-- ============================================================
local function findGroundBelow(origin, length)
    if not LocalPlayer.Character then return nil end
    return Ray.down(origin, length or CONFIG.LandingRayLen, {LocalPlayer.Character})
end

-- ============================================================
-- МОДУЛЬ: ВЗЛЁТ
-- ============================================================
local Takeoff = {}

function Takeoff.start()
    if not State.RootPart or not State.Humanoid then return end
    if State.TakingOff or State.Flying then return end

    State.TakingOff = true
    Log.info("Взлёт начат.")

    local startPos = State.RootPart.Position
    local endPos   = startPos + Vector3.new(0, CONFIG.TakeoffHeight, 0)
    local elapsed  = 0
    local dur      = CONFIG.TakeoffDuration

    -- Отключаем стандартную физику на время взлёта
    if State.Humanoid then
        State.Humanoid.PlatformStand = true
    end

    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not State.RootPart then
            conn:Disconnect()
            State.TakingOff = false
            return
        end

        elapsed += dt
        local a = Math.clamp01(elapsed / dur)
        local eased = Ease.outCubic(a)
        local p = Vec.lerp(startPos, endPos, eased)
        State.RootPart.CFrame = CFrame.new(p) * State.CurrentTilt
        State.RootPart.Velocity = Vector3.zero

        if a >= 1 then
            conn:Disconnect()
            State.TakingOff = false
            State.Flying = true

            -- Включаем эффекты
            if RF.Effects and RF.Effects.setEnabled then
                RF.Effects.setEnabled(true)
            end

            -- Крылья
            if RF.Wings then
                RF.Wings.setVisible(State.WingL, true)
                RF.Wings.setVisible(State.WingR, true)
            end

            -- Поза
            if RF.Pose then RF.Pose.start() end

            Log.info("Взлёт завершён.")
        end
    end)
end

-- ============================================================
-- МОДУЛЬ: ПОСАДКА
-- ============================================================
local Landing = {}

function Landing.start()
    if not State.RootPart then return end
    if State.Landing then return end

    State.Landing = true
    State.Flying = false
    Log.info("Посадка начата.")

    local startPos = State.RootPart.Position

    -- Ищем землю
    local result = findGroundBelow(startPos)
    local endPos
    if result then
        endPos = result.Position + Vector3.new(0, 3.5, 0)
    else
        endPos = startPos
    end

    local elapsed = 0
    local dur = CONFIG.LandingDuration

    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not State.RootPart then
            conn:Disconnect()
            State.Landing = false
            return
        end

        elapsed += dt
        local a = Math.clamp01(elapsed / dur)
        local eased = Ease.smoothstep(a)
        local p = Vec.lerp(startPos, endPos, eased)
        State.RootPart.CFrame = CFrame.new(p) * State.CurrentTilt
        State.RootPart.Velocity = Vector3.zero

        if a >= 1 then
            conn:Disconnect()
            State.Landing = false

            if State.Humanoid then
                State.Humanoid.PlatformStand = false
            end

            if RF.Effects and RF.Effects.setEnabled then
                RF.Effects.setEnabled(false)
            end

            if RF.Wings then
                RF.Wings.setVisible(State.WingL, false)
                RF.Wings.setVisible(State.WingR, false)
            end

            if RF.Pose then RF.Pose.stop() end

            Log.info("Посадка завершена.")
        end
    end)
end

-- ============================================================
-- МОДУЛЬ: HOVER-LOCK (парение без движения)
-- ============================================================
-- Если игрок не двигается, слегка приподнимаем корпус —
-- создаём эффект «висения в воздухе».

local HoverLock = {}

function HoverLock.apply(dt)
    if not State.Flying then return end
    if not State.RootPart then return end

    local move = RF.Input and RF.Input.getLocalMove() or Vector3.zero
    if move.Magnitude > 0.1 then return end

    -- Микро-подъём
    local t = tick()
    local lift = math.sin(t * 1.8) * 0.06
    State.RootPart.CFrame = State.RootPart.CFrame + Vector3.new(0, lift * dt * 60, 0)
end

-- ============================================================
-- МОДУЛЬ: ANTI-VOID
-- ============================================================
local AntiVoid = {}

function AntiVoid.check()
    if not CONFIG.AntiVoidEnabled then return end
    if not State.RootPart then return end
    if not State.Flying then return end

    if State.RootPart.Position.Y < CONFIG.VoidY then
        Log.warn("Anti-void сработал — возврат наверх.")
        local p = State.RootPart.Position
        State.RootPart.CFrame = CFrame.new(
            Vector3.new(p.X, CONFIG.AntiVoidRecover, p.Z)
        ) * State.CurrentTilt
        State.Velocity = Vector3.zero
        State.DesiredVel = Vector3.zero
    end
end

-- ============================================================
-- МОДУЛЬ: СТАБИЛИЗАЦИЯ (защита от выбросов)
-- ============================================================
-- Если персонаж почему-то оказался слишком далеко от ожидаемой
-- позиции — плавно возвращаем. Также защита от NaN.

local Stabilizer = {}

local lastValidPos = nil

function Stabilizer.update(dt)
    if not State.RootPart then return end

    local pos = State.RootPart.Position

    -- Защита от NaN
    if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then
        Log.warn("NaN в позиции — сброс.")
        if lastValidPos then
            State.RootPart.CFrame = CFrame.new(lastValidPos) * State.CurrentTilt
            State.Velocity = Vector3.zero
        end
        return
    end

    -- Защита от запредельной скорости
    if State.Velocity.Magnitude > CONFIG.MaxSpeedCap * 2 then
        State.Velocity = State.Velocity.Unit * CONFIG.MaxSpeedCap
    end

    lastValidPos = pos
end

-- ============================================================
-- ВКЛЮЧЕНИЕ / ВЫКЛЮЧЕНИЕ ПОЛЁТА
-- ============================================================
local Fly = {}

function Fly.enable()
    if State.Enabled then return end
    if not State.RootPart or not State.Humanoid then
        Log.warn("Нет персонажа.")
        return
    end
    State.Enabled = true
    Log.info("Полёт включён.")
    Takeoff.start()
end

function Fly.disable()
    if not State.Enabled and not State.Flying and not State.TakingOff then
        return
    end
    State.Enabled = false
    Log.info("Полёт выключен.")

    if State.Flying or State.TakingOff then
        Landing.start()
    end

    State.Velocity = Vector3.zero
    State.DesiredVel = Vector3.zero
    State.SpeedMul = 1
end

function Fly.toggle()
    if State.Enabled then
        Fly.disable()
    else
        Fly.enable()
    end
end

-- ============================================================
-- ОБЩИЙ ЦИКЛ: ВЗЛЁТ / ПОСАДКА / ANTI-VOID / STABILIZER
-- ============================================================
local function takeoffLandingLoop(dt)
    if not State.RootPart then return end

    -- Anti-void
    AntiVoid.check()

    -- Hover-lock (только в полёте)
    if State.Flying then
        HoverLock.apply(dt)
    end

    -- Стабилизация
    Stabilizer.update(dt)
end

Conn.track(RunService.Heartbeat:Connect(takeoffLandingLoop))

-- ============================================================
-- ЭКСПОРТ
-- ============================================================
RF.Takeoff   = Takeoff
RF.Landing   = Landing
RF.HoverLock = HoverLock
RF.AntiVoid  = AntiVoid
RF.Stabilizer = Stabilizer
RF.Fly       = Fly

-- Привязка к ROCKET (для совместимости со следующими частями)
RF.Rocket = RF.Rocket or {}
RF.Rocket.enableFly  = Fly.enable
RF.Rocket.disableFly = Fly.disable
RF.Rocket.toggleFly  = Fly.toggle
RF.Rocket.takeoff    = Takeoff.start
RF.Rocket.land       = Landing.start

Log.info("Часть 6 загружена — взлёт, посадка, anti-void, стабилизатор.")

-- ============================================================
-- ЧАСТЬ 7: Dash, камера, эффекты скорости
-- ============================================================

local RF     = _G.RF
local CONFIG = RF.Config
local State  = RF.State
local Log    = RF.Log
local Math   = RF.Math
local Ease   = RF.Ease
local Vec    = RF.Vec
local CFrameUtil = RF.CFrame
local Ray    = RF.Ray
local Inst   = RF.Inst
local Conn   = RF.Conn
local Thread = RF.Thread
local Services = RF.Services

local RunService       = Services.RunService
local TweenService     = Services.TweenService
local UserInputService = Services.UserInputService
local LocalPlayer      = Services.LocalPlayer
local Camera           = Services.Camera

-- ============================================================
-- МОДУЛЬ: DASH
-- ============================================================
local Dash = {}

function Dash.canDash()
    if not State.Flying then return false end
    if State.Dashing then return false end
    if tick() - State.LastDash < CONFIG.DashCooldown then return false end
    return true
end

function Dash.getDirection()
    local world = RF.Input and RF.Input.getWorldMove() or Vector3.zero
    if world.Magnitude < 0.0001 then
        world = Camera.CFrame.LookVector
    end
    return world.Unit
end

function Dash.playEffects()
    if not State.RootPart then return end
    if RF.DashEffect and RF.DashEffect.play then
        RF.DashEffect.play(State.RootPart)
    end
end

function Dash.applyVelocity(dir)
    local dashVel = dir * CONFIG.DashPower
    State.Velocity = dashVel
    State.DesiredVel = dashVel
end

function Dash.fovBoost()
    if not CONFIG.CameraEnabled then return end
    if not State.CamBaseFov then return end

    local target = State.CamBaseFov + CONFIG.DashFovBoost
    local tween = TweenService:Create(
        Camera,
        TweenInfo.new(CONFIG.DashFovTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { FieldOfView = target }
    )
    tween:Play()

    Thread.delay(CONFIG.DashFovTime, function()
        local back = TweenService:Create(
            Camera,
            TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            { FieldOfView = State.CamBaseFov }
        )
        back:Play()
    end)
end

function Dash.execute()
    if not Dash.canDash() then
        Log.info("Dash на перезарядке.")
        return
    end

    State.LastDash = tick()
    State.Dashing = true
    Log.info("Dash!")

    local dir = Dash.getDirection()
    Dash.applyVelocity(dir)
    Dash.playEffects()
    Dash.fovBoost()

    Thread.delay(0.18, function()
        State.Dashing = false
    end)
end

-- ============================================================
-- МОДУЛЬ: КАМЕРА
-- ============================================================
local CameraModule = {}

function CameraModule.saveBase()
    if not Camera then return end
    State.CamBaseFov = Camera.FieldOfView or CONFIG.CameraFovBase
end

function CameraModule.resetFov()
    if not Camera then return end
    if State.CamBaseFov then
        Camera.FieldOfView = State.CamBaseFov
    end
end

-- Инерция камеры (плавное следование за персонажем)
function CameraModule.applyLag(dt)
    if not CONFIG.CameraEnabled then return end
    if not State.RootPart then return end
    if not State.Flying then return end

    local targetPos = State.RootPart.Position
    if not State.LastCamPos then
        State.LastCamPos = targetPos
    end

    State.LastCamPos = Vec.lerp(
        State.LastCamPos,
        targetPos,
        Math.clamp01(CONFIG.CameraLag * dt * 60)
    )

    -- Параллакс: смещаем камеру в сторону движения
    local vel = State.Velocity
    if vel.Magnitude > 1 then
        local dir = vel.Unit
        local offset = dir * math.min(vel.Magnitude * 0.02, 3.5)
        Camera.CFrame = Camera.CFrame + offset * dt * 6
    end
end

-- FOV от скорости
function CameraModule.applyFov(dt)
    if not CONFIG.CameraEnabled then return end
    if not State.Flying then return end

    local speed = State.Velocity.Magnitude
    local maxSpeed = CONFIG.BaseSpeed * CONFIG.BoostMultiplier
    local a = Math.clamp01(speed / math.max(maxSpeed, 1))

    local targetFov = CONFIG.CameraFovBase
        + (CONFIG.CameraFovMax - CONFIG.CameraFovBase) * a

    Camera.FieldOfView = Math.lerp(
        Camera.FieldOfView,
        targetFov,
        Math.clamp01(CONFIG.CameraFovSpeed * dt)
    )
end

-- Возврат FOV к базовому, если не летим
function CameraModule.restoreFov(dt)
    if not CONFIG.CameraEnabled then return end
    if State.Flying then return end
    if not State.CamBaseFov then return end

    Camera.FieldOfView = Math.lerp(
        Camera.FieldOfView,
        State.CamBaseFov,
        Math.clamp01(2.5 * dt)
    )
end

function CameraModule.update(dt)
    if not Camera then return end

    if State.Flying then
        CameraModule.applyLag(dt)
        CameraModule.applyFov(dt)
    else
        CameraModule.restoreFov(dt)
    end
end

Conn.track(RunService.RenderStepped:Connect(function(dt)
    CameraModule.update(dt)
end))

-- ============================================================
-- МОДУЛЬ: ЭФФЕКТЫ СКОРОСТИ (Speed FX)
-- ============================================================
-- Усиление трейла/частиц при boost, шлейф скорости при dash.

local SpeedFX = {}

local speedLinesGui = nil

function SpeedFX.createSpeedLines()
    if speedLinesGui then return speedLinesGui end

    local screen = Inst.make("ScreenGui", {
        Name = "RF_SpeedLines",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = -1,
    }, LocalPlayer:WaitForChild("PlayerGui"))

    speedLinesGui = screen
    return screen
end

function SpeedFX.applyTrailColor(t)
    if not State.Trail then return end
    -- При boost — сдвиг цвета к белому
    local c = CONFIG.TrailColor
    local white = Color3.fromRGB(255, 255, 255)
    local blended = Color3.new(
        Math.lerp(c.R, white.R, t),
        Math.lerp(c.G, white.G, t),
        Math.lerp(c.B, white.B, t)
    )
    State.Trail.Color = ColorSequence.new(blended)
end

function SpeedFX.update(dt)
    if not State.Flying then
        SpeedFX.applyTrailColor(0)
        return
    end

    local speed = State.Velocity.Magnitude
    local maxSpeed = CONFIG.BaseSpeed * CONFIG.BoostMultiplier
    local a = Math.clamp01(speed / math.max(maxSpeed, 1))

    -- Трейл белее при boost
    SpeedFX.applyTrailColor(a * 0.6)

    -- Частицы чаще
    if State.Particle then
        State.Particle.Rate = 55 + a * 60
    end

    -- Свет ярче
    if State.Light then
        State.Light.Brightness = CONFIG.LightBrightness + a * 3
    end

    -- Звук выше тоном
    if State.Sound then
        State.Sound.PlaybackSpeed = 1.0 + a * 0.5
    end
end

Conn.track(RunService.Heartbeat:Connect(function(dt)
    SpeedFX.update(dt)
end))

-- ============================================================
-- МОДУЛЬ: BOOST-ЗВУК
-- ============================================================
local BoostSoundPlayer = {}

function BoostSoundPlayer.setup()
    if not CONFIG.EnableSound then return end
    if not State.BoostSound then
        State.BoostSound = RF.BoostSound and RF.BoostSound.create()
    end
end

function BoostSoundPlayer.play()
    if State.BoostSound and RF.BoostSound then
        RF.BoostSound.play(State.BoostSound)
    end
end

-- Играем звук при нажатии boost-клавиши
Conn.track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CONFIG.BoostKey and State.Flying then
        BoostSoundPlayer.play()
    end
end))

-- ============================================================
-- МОДУЛЬ: БЫСТРАЯ РЕАКЦИЯ (boost / slow) — реакция на клавиши
-- ============================================================
local SpeedControl = {}

Conn.track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not State.Enabled then return end

    if input.KeyCode == CONFIG.BoostKey then
        State.SpeedMul = CONFIG.BoostMultiplier
    elseif input.KeyCode == CONFIG.SlowKey then
        State.SpeedMul = CONFIG.SlowMultiplier
    end
end))

Conn.track(UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CONFIG.BoostKey or input.KeyCode == CONFIG.SlowKey then
        State.SpeedMul = 1
    end
end))

-- ============================================================
-- ЭКСПОРТ
-- ============================================================
RF.Dash        = Dash
RF.CameraMod   = CameraModule
RF.SpeedFX     = SpeedFX
RF.BoostSoundP = BoostSoundPlayer
RF.SpeedControl = SpeedControl

-- Совместимость: RF.Rocket.dash
RF.Rocket = RF.Rocket or {}
RF.Rocket.dash = Dash.execute

Log.info("Часть 7 загружена — dash, камера, эффекты скорости.")

-- ============================================================
-- ЧАСТЬ 8: UI (кнопки, слайдеры, переключатели)
-- ============================================================

local RF     = _G.RF
local CONFIG = RF.Config
local State  = RF.State
local Log    = RF.Log
local Math   = RF.Math
local Ease   = RF.Ease
local Vec    = RF.Vec
local Inst   = RF.Inst
local Conn   = RF.Conn
local Thread = RF.Thread
local Services = RF.Services

local RunService   = Services.RunService
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local LocalPlayer  = Services.LocalPlayer
local Camera       = Services.Camera

-- ============================================================
-- МОДУЛЬ: UI
-- ============================================================
local UI = {}

-- Внутренние ссылки
local refs = {
    screen = nil,
    frame  = nil,
    status = nil,
    speed  = nil,
    buttons = {},
    toggles = {},
}

-- ============================================================
-- ХЕЛПЕРЫ
-- ============================================================
local function corner(parent, radius)
    return Inst.corner(parent, radius or 8)
end

local function stroke(parent, color, thickness)
    return Inst.stroke(parent, color or Color3.fromRGB(0, 200, 255), thickness or 1.5, 0.3)
end

local function gradient(parent, c1, c2, rot)
    return Inst.gradient(parent, c1, c2, rot or 90)
end

local function makeLabel(parent, props)
    return Inst.make("TextLabel", props, parent)
end

-- ============================================================
-- СОЗДАНИЕ КНОПКИ
-- ============================================================
local function makeButton(parent, name, y, text, color, callback)
    local btn = Inst.make("TextButton", {
        Name = name,
        Size = UDim2.new(1, -24, 0, 34),
        Position = UDim2.new(0, 12, 0, y),
        BackgroundColor3 = color or Color3.fromRGB(35, 35, 50),
        BorderSizePixel = 0,
        Text = text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(235, 235, 245),
        AutoButtonColor = true,
    }, parent)

    corner(btn, 8)

    if callback then
        btn.MouseButton1Click:Connect(function()
            Thread.spawn(callback)
        end)
    end

    table.insert(refs.buttons, { name = name, obj = btn })
    return btn
end

-- ============================================================
-- СОЗДАНИЕ ПЕРЕКЛЮЧАТЕЛЯ (toggle)
-- ============================================================
local function makeToggle(parent, name, y, text, default, callback)
    local row = Inst.make("Frame", {
        Name = name .. "_Row",
        Size = UDim2.new(1, -24, 0, 30),
        Position = UDim2.new(0, 12, 0, y),
        BackgroundTransparency = 1,
    }, parent)

    local label = makeLabel(row, {
        Size = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(210, 220, 240),
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local toggle = Inst.make("TextButton", {
        Name = name .. "_Toggle",
        Size = UDim2.new(0, 48, 0, 24),
        Position = UDim2.new(1, -48, 0.5, -12),
        BackgroundColor3 = default and Color3.fromRGB(0, 160, 220) or Color3.fromRGB(60, 60, 70),
        BorderSizePixel = 0,
        Text = default and "ON" or "OFF",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(255, 255, 255),
    }, row)
    corner(toggle, 12)

    local state = default
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.Text = state and "ON" or "OFF"
        toggle.BackgroundColor3 = state
            and Color3.fromRGB(0, 160, 220)
            or Color3.fromRGB(60, 60, 70)
        if callback then
            pcall(callback, state)
        end
    end)

    table.insert(refs.toggles, { name = name, obj = toggle, get = function() return state end })
    return toggle
end

-- ============================================================
-- СОЗДАНИЕ СЛАЙДЕРА
-- ============================================================
local function makeSlider(parent, name, y, text, minV, maxV, default, callback)
    local row = Inst.make("Frame", {
        Name = name .. "_Row",
        Size = UDim2.new(1, -24, 0, 42),
        Position = UDim2.new(0, 12, 0, y),
        BackgroundTransparency = 1,
    }, parent)

    local label = makeLabel(row, {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = text .. ":  " .. tostring(default),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(200, 220, 240),
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local track = Inst.make("Frame", {
        Name = name .. "_Track",
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = Color3.fromRGB(40, 40, 55),
        BorderSizePixel = 0,
    }, row)
    corner(track, 3)

    local fill = Inst.make("Frame", {
        Name = name .. "_Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 200, 255),
        BorderSizePixel = 0,
    }, track)
    corner(fill, 3)

    local knob = Inst.make("Frame", {
        Name = name .. "_Knob",
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 0, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, track)
    corner(knob, 7)
    stroke(knob, Color3.fromRGB(0, 200, 255), 1.5)

    local value = default
    local dragging = false

    local function updateFromX(x)
        local rel = Math.clamp01((x - track.AbsolutePosition.X) / track.AbsoluteSize.X)
        value = Math.lerp(minV, maxV, rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, -7)
        label.Text = text .. ":  " .. tostring(Math.round(value, 1))
        if callback then
            pcall(callback, value)
        end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Инициализация позиции
    local initRel = (default - minV) / math.max(maxV - minV, 0.0001)
    fill.Size = UDim2.new(initRel, 0, 1, 0)
    knob.Position = UDim2.new(initRel, 0, 0.5, -7)

    return track
end

-- ============================================================
-- ПОСТРОЕНИЕ GUI
-- ============================================================
function UI.build()
    if refs.screen and refs.screen.Parent then
        return refs.screen, refs.frame
    end

    local screen = Inst.make("ScreenGui", {
        Name = "RocketFlyGui",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, LocalPlayer:WaitForChild("PlayerGui"))

    local frame = Inst.make("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 300, 0, 520),
        Position = UDim2.new(0, 24, 0.5, -260),
        BackgroundColor3 = Color3.fromRGB(16, 16, 26),
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Visible = false,
        Active = true,
        Draggable = true,
    }, screen)
    corner(frame, 14)
    stroke(frame, Color3.fromRGB(0, 200, 255), 1.5)
    gradient(frame, Color3.fromRGB(30, 30, 55), Color3.fromRGB(12, 12, 20), 90)

    -- Заголовок
    local title = makeLabel(frame, {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        Text = "ROCKET FLY",
        Font = Enum.Font.GothamBlack,
        TextSize = 22,
        TextColor3 = Color3.fromRGB(0, 220, 255),
    })

    local subtitle = makeLabel(frame, {
        Name = "Subtitle",
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 42),
        BackgroundTransparency = 1,
        Text = "v" .. CONFIG.Version .. "  •  Rocket Way",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(140, 200, 230),
    })

    -- Статус
    local status = makeLabel(frame, {
        Name = "Status",
        Size = UDim2.new(1, -24, 0, 24),
        Position = UDim2.new(0, 12, 0, 66),
        BackgroundColor3 = Color3.fromRGB(28, 28, 40),
        BorderSizePixel = 0,
        Text = "Статус: выключено",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(200, 230, 255),
    })
    corner(status, 6)

    -- Кнопка полёта
    makeButton(frame, "FlyBtn", 100, "ВКЛЮЧИТЬ ПОЛЁТ  [F]",
        Color3.fromRGB(0, 130, 180), function()
            if RF.Fly then RF.Fly.toggle() end
        end)

    -- Слайдер базовой скорости
    makeSlider(frame, "Speed", 142, "Базовая скорость", 20, 200, CONFIG.BaseSpeed,
        function(v)
            CONFIG.BaseSpeed = v
        end)

    -- Слайдер усиления
    makeSlider(frame, "Boost", 190, "Множитель boost", 1.5, 6, CONFIG.BoostMultiplier,
        function(v)
            CONFIG.BoostMultiplier = v
        end)

    -- Слайдер наклона
    makeSlider(frame, "Tilt", 238, "Наклон корпуса", 5, 50, CONFIG.TiltMaxAngle,
        function(v)
            CONFIG.TiltMaxAngle = v
        end)

    -- Переключатели
    makeToggle(frame, "Trail", 288, "Трейл", CONFIG.EnableTrail, function(on)
        CONFIG.EnableTrail = on
        if State.Trail then State.Trail.Enabled = on end
    end)

    makeToggle(frame, "Particles", 322, "Частицы", CONFIG.EnableParticles, function(on)
        CONFIG.EnableParticles = on
        if State.Particle then State.Particle.Enabled = on end
    end)

    makeToggle(frame, "Wings", 356, "Крылья", CONFIG.EnableWings, function(on)
        CONFIG.EnableWings = on
        if RF.Wings then
            RF.Wings.setVisible(State.WingL, on and State.Flying)
            RF.Wings.setVisible(State.WingR, on and State.Flying)
        end
    end)

    makeToggle(frame, "Aura", 390, "Аура", CONFIG.EnableAura, function(on)
        CONFIG.EnableAura = on
        if State.Aura then
            State.Aura.Transparency = on and (State.Flying and 0.75 or 1) or 1
        end
    end)

    makeToggle(frame, "Camera", 424, "Камера", CONFIG.CameraEnabled, function(on)
        CONFIG.CameraEnabled = on
        if not on and RF.CameraMod then
            RF.CameraMod.resetFov()
        end
    end)

    -- Кнопка dash
    makeButton(frame, "DashBtn", 460, "DASH  [Q]",
        Color3.fromRGB(180, 80, 30), function()
            if RF.Dash then RF.Dash.execute() end
        end)

    -- Кнопка скрыть
    makeButton(frame, "CloseBtn", 496, "Скрыть  [RightShift]",
        Color3.fromRGB(60, 30, 60), function()
            frame.Visible = false
        end)

    refs.screen = screen
    refs.frame = frame
    refs.status = status

    return screen, frame
end

-- ============================================================
-- ОБНОВЛЕНИЕ СТАТУСА
-- ============================================================
function UI.updateStatus()
    if not refs.frame or not refs.frame.Visible then return end
    if not refs.status then return end

    local txt
    if State.TakingOff then
        txt = "Статус: взлёт..."
    elseif State.Landing then
        txt = "Статус: посадка..."
    elseif State.Flying and State.Dashing then
        txt = "Статус: DASH!"
    elseif State.Flying then
        txt = ("Статус: полёт  •  %d studs/s"):format(math.floor(State.Velocity.Magnitude))
    else
        txt = "Статус: выключено"
    end

    refs.status.Text = txt

    -- Кнопка полёта меняет вид
    local btn = nil
    for _, b in ipairs(refs.buttons) do
        if b.name == "FlyBtn" then btn = b.obj break end
    end
    if btn then
        if State.Enabled then
            btn.Text = "ВЫКЛЮЧИТЬ ПОЛЁТ  [F]"
            btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        else
            btn.Text = "ВКЛЮЧИТЬ ПОЛЁТ  [F]"
            btn.BackgroundColor3 = Color3.fromRGB(0, 130, 180)
        end
    end
end

-- ============================================================
-- TOGGLE GUI
-- ============================================================
function UI.toggle()
    if not refs.frame then
        UI.build()
    end
    refs.frame.Visible = not refs.frame.Visible
end

-- ============================================================
-- ПЕРИОДИЧЕСКОЕ ОБНОВЛЕНИЕ
-- ============================================================
Conn.track(RunService.Heartbeat:Connect(function()
    UI.updateStatus()
end))

-- ============================================================
-- ЭКСПОРТ
-- ============================================================
RF.UI = UI
RF.Rocket = RF.Rocket or {}
RF.Rocket.buildGui = UI.build
RF.Rocket.toggleGui = UI.toggle

Log.info("Часть 8 загружена — UI (кнопки, слайдеры, переключатели).")

-- ============================================================
-- ЧАСТЬ 9: Хоткеи, реакции на смерть/респавн, авто-ремонт
-- ============================================================

local RF     = _G.RF
local CONFIG = RF.Config
local State  = RF.State
local Log    = RF.Log
local Math   = RF.Math
local Ease   = RF.Ease
local Vec    = RF.Vec
local Inst   = RF.Inst
local Conn   = RF.Conn
local Thread = RF.Thread
local Services = RF.Services

local RunService       = Services.RunService
local UserInputService = Services.UserInputService
local TweenService     = Services.TweenService
local LocalPlayer      = Services.LocalPlayer
local Camera           = Services.Camera

-- ============================================================
-- МОДУЛЬ: ХОТКЕИ
-- ============================================================
local Hotkeys = {}

function Hotkeys.onKeyDown(input, gp)
    if gp then return end

    local key = input.KeyCode

    -- Основной тумблер полёта
    if key == CONFIG.ToggleKey then
        if RF.Fly then RF.Fly.toggle() end
        return
    end

    -- GUI
    if key == CONFIG.GuiToggleKey then
        if RF.UI then RF.UI.toggle() end
        return
    end

    -- Только во время полёта
    if not State.Enabled then return end

    if key == CONFIG.DashKey then
        if RF.Dash then RF.Dash.execute() end

    elseif key == CONFIG.CamToggleKey then
        CONFIG.CameraEnabled = not CONFIG.CameraEnabled
        Log.info("Камера: " .. tostring(CONFIG.CameraEnabled))
        if not CONFIG.CameraEnabled and RF.CameraMod then
            RF.CameraMod.resetFov()
        end

    elseif key == CONFIG.WingsToggleKey then
        CONFIG.EnableWings = not CONFIG.EnableWings
        if RF.Wings then
            RF.Wings.setVisible(State.WingL, CONFIG.EnableWings and State.Flying)
            RF.Wings.setVisible(State.WingR, CONFIG.EnableWings and State.Flying)
        end
        Log.info("Крылья: " .. tostring(CONFIG.EnableWings))

    elseif key == CONFIG.AuraToggleKey then
        CONFIG.EnableAura = not CONFIG.EnableAura
        if State.Aura then
            State.Aura.Transparency = CONFIG.EnableAura
                and (State.Flying and 0.75 or 1)
                or 1
        end
        Log.info("Аура: " .. tostring(CONFIG.EnableAura))
    end
end

function Hotkeys.onKeyUp(input, gp)
    if gp then return end
    if input.KeyCode == CONFIG.BoostKey or input.KeyCode == CONFIG.SlowKey then
        State.SpeedMul = 1
    end
end

function Hotkeys.bind()
    Conn.track(UserInputService.InputBegan:Connect(Hotkeys.onKeyDown))
    Conn.track(UserInputService.InputEnded:Connect(Hotkeys.onKeyUp))
end

-- ============================================================
-- МОДУЛЬ: РЕАКЦИЯ НА СМЕРТЬ / РЕСПАВН
-- ============================================================
local Lifecycle = {}

function Lifecycle.onCharacterAdded(char)
    Log.info("Персонаж заспавнился — перепривязка.")

    -- Сброс состояния
    State.Humanoid = nil
    State.RootPart = nil
    State.Animator = nil
    State.PoseTrack = nil

    State.Velocity = Vector3.zero
    State.DesiredVel = Vector3.zero
    State.CurrentTilt = CFrame.new()
    State.LastCamPos = nil

    -- Очистка эффектов
    if RF.Effects and RF.Effects.cleanup then
        RF.Effects.cleanup()
    end
    if RF.Wings then
        RF.Wings.destroy(State.WingL)
        RF.Wings.destroy(State.WingR)
        State.WingL = nil
        State.WingR = nil
    end

    -- Небольшая задержка, чтобы персонаж успел прогрузиться
    task.wait(0.15)

    -- Привязка
    if RF.Bind and RF.Bind.character then
        RF.Bind.character(char)
    end

    -- Пересоздаём крылья (если включены)
    if RF.Extras and RF.Extras.rebuildWings then
        RF.Extras.rebuildWings()
    end
end

function Lifecycle.bind()
    Conn.track(LocalPlayer.CharacterAdded:Connect(Lifecycle.onCharacterAdded))
end

-- ============================================================
-- МОДУЛЬ: АВТО-РЕМОНТ ЭФФЕКТОВ
-- ============================================================
-- Раз в несколько секунд проверяет, что все эффекты на месте,
-- и если что-то потерялось — восстанавливает.

local AutoRepair = {}

local function hasEffect(inst)
    return inst ~= nil and inst.Parent ~= nil
end

function AutoRepair.tick()
    if not State.Started then return end
    if not State.RootPart or not State.RootPart.Parent then return end

    -- Трейл
    if CONFIG.EnableTrail and not hasEffect(State.Trail) then
        Log.warn("Авто-ремонт: восстанавливаем трейл.")
        if RF.Effects and RF.Effects.createTrail then
            State.Trail = RF.Effects.createTrail(State.RootPart)
            if State.Trail then
                State.Trail.Enabled = State.Flying
            end
        end
    end

    -- Частицы
    if CONFIG.EnableParticles and not hasEffect(State.Particle) then
        Log.warn("Авто-ремонт: восстанавливаем частицы.")
        if RF.Effects and RF.Effects.createParticles then
            State.Particle = RF.Effects.createParticles(State.RootPart)
            if State.Particle then
                State.Particle.Enabled = State.Flying
            end
        end
    end

    -- Дым
    if CONFIG.EnableSmoke and not hasEffect(State.Smoke) then
        if RF.Effects and RF.Effects.createSmoke then
            State.Smoke = RF.Effects.createSmoke(State.RootPart)
            if State.Smoke then
                State.Smoke.Enabled = State.Flying
            end
        end
    end

    -- Свет
    if CONFIG.EnableLight and not hasEffect(State.Light) then
        if RF.Effects and RF.Effects.createLight then
            State.Light = RF.Effects.createLight(State.RootPart)
            if State.Light then
                State.Light.Enabled = State.Flying
            end
        end
    end

    -- Аура
    if CONFIG.EnableAura and not hasEffect(State.Aura) then
        if RF.Effects and RF.Effects.createAura then
            State.Aura = RF.Effects.createAura(State.RootPart)
            if State.Aura then
                State.Aura.Transparency = State.Flying and 0.75 or 1
            end
        end
    end

    -- Крылья
    if CONFIG.EnableWings then
        local brokenL = not State.WingL or not State.WingL.model or not State.WingL.model.Parent
        local brokenR = not State.WingR or not State.WingR.model or not State.WingR.model.Parent
        if brokenL or brokenR then
            Log.warn("Авто-ремонт: восстанавливаем крылья.")
            if RF.Extras and RF.Extras.rebuildWings then
                RF.Extras.rebuildWings()
            end
        end
    end

    -- Звук
    if CONFIG.EnableSound and not hasEffect(State.Sound) then
        if RF.Effects and RF.Effects.createSound then
            State.Sound = RF.Effects.createSound()
            if State.Sound and State.Flying then
                State.Sound:Play()
            end
        end
    end
end

function AutoRepair.start()
    Thread.spawn(function()
        while State.Started do
            task.wait(3)
            pcall(AutoRepair.tick)
        end
    end)
end

-- ============================================================
-- МОДУЛЬ: ЗАЩИТА ОТ ДУРАКА
-- ============================================================
-- Если игрок случайно умер в полёте, эффекты и поза сбрасываются.
-- Если персонаж не двигается физически — двигаем принудительно.
-- Если игра блокирует CFrame — пробуем через Velocity.

local Safety = {}

function Safety.checkCharacterAlive()
    if not State.Humanoid then return false end
    if State.Humanoid.Health <= 0 then return false end
    return true
end

function Safety.enforceFlying()
    if not State.Flying then return end
    if not State.RootPart then return end

    -- Если позиция не меняется при движении — принудительно двигаем
    local move = RF.Input and RF.Input.getWorldMove() or Vector3.zero
    if move.Magnitude > 0.1 and State.Velocity.Magnitude < 0.5 then
        State.Velocity = move * CONFIG.BaseSpeed * State.SpeedMul
    end
end

function Safety.checkHealth()
    if not State.Enabled then return end
    if not State.Humanoid then return end
    if State.Humanoid.Health <= 0 then
        if State.Flying or State.TakingOff then
            Log.warn("Смерть в полёте — принудительное выключение.")
            if RF.Fly then RF.Fly.disable() end
        end
    end
end

Conn.track(RunService.Heartbeat:Connect(function()
    Safety.checkHealth()
    Safety.enforceFlying()
end))

-- ============================================================
-- МОДУЛЬ: СИНХРОНИЗАЦИЯ UI С КОНФИГОМ
-- ============================================================
-- Если настройки были изменены хоткеем — обновляем UI.

local Sync = {}

function Sync.update()
    if not RF.UI or not RF.UI.build then return end
    -- UI уже следит за состоянием сам
end

-- ============================================================
-- ХУКИ ЗАПУСКА / ОСТАНОВКИ
-- ============================================================
function Hotkeys.disableAll()
    State.SpeedMul = 1
    State.Velocity = Vector3.zero
    State.DesiredVel = Vector3.zero
end

-- ============================================================
-- ЭКСПОРТ
-- ============================================================
RF.Hotkeys    = Hotkeys
RF.Lifecycle  = Lifecycle
RF.AutoRepair = AutoRepair
RF.Safety     = Safety
RF.Sync       = Sync

-- Связываем характер с жизненным циклом
Hotkeys.bind()
Lifecycle.bind()

Log.info("Часть 9 загружена — хоткеи, респавн, авто-ремонт, безопасность.")

-- ============================================================
-- ЧАСТЬ 10: Инициализация, финальный запуск, авто-очистка
-- ============================================================

local RF     = _G.RF
local CONFIG = RF.Config
local State  = RF.State
local Log    = RF.Log
local Math   = RF.Math
local Ease   = RF.Ease
local Vec    = RF.Vec
local Inst   = RF.Inst
local Conn   = RF.Conn
local Thread = RF.Thread
local Services = RF.Services

local RunService       = Services.RunService
local UserInputService = Services.UserInputService
local TweenService     = Services.TweenService
local LocalPlayer      = Services.LocalPlayer
local Camera           = Services.Camera

-- ============================================================
-- МОДУЛЬ: ИНИЦИАЛИЗАЦИЯ
-- ============================================================
local Init = {}

-- Проверка: все ли части загружены
function Init.checkModules()
    local required = {
        "Log", "Math", "Ease", "Vec", "CFrame", "Ray", "Inst", "Conn", "Thread",
        "Pose", "Bind", "Effects", "Wings", "Input", "Motion", "Tilt", "Hover",
        "Takeoff", "Landing", "AntiVoid", "Fly", "Dash", "CameraMod",
        "SpeedFX", "UI", "Hotkeys", "Lifecycle", "AutoRepair", "Safety",
    }

    local missing = {}
    for _, name in ipairs(required) do
        if not RF[name] then
            table.insert(missing, name)
        end
    end

    if #missing > 0 then
        Log.warn("Не загружены модули: " .. table.concat(missing, ", "))
        return false
    end

    Log.info("Все модули загружены корректно.")
    return true
end

-- Установка базового FOV
function Init.setBaseFov()
    if Camera then
        State.CamBaseFov = Camera.FieldOfView or CONFIG.CameraFovBase
    end
end

-- Сборка GUI
function Init.buildGui()
    if RF.UI and RF.UI.build then
        RF.UI.build()
    end
end

-- Привязка текущего персонажа
function Init.bindCurrentCharacter()
    if LocalPlayer.Character and RF.Bind and RF.Bind.character then
        RF.Bind.character(LocalPlayer.Character)
    end
end

-- Запуск авто-ремонта
function Init.startAutoRepair()
    if RF.AutoRepair and RF.AutoRepair.start then
        RF.AutoRepair.start()
    end
end

-- Финальный запуск
function Init.run()
    if State.Started then
        Log.warn("Уже запущено.")
        return
    end

    Log.info("═══════════════════════════════════════════")
    Log.info("  ROCKET FLY v" .. CONFIG.Version .. " — инициализация")
    Log.info("═══════════════════════════════════════════")

    -- Проверка модулей
    if not Init.checkModules() then
        Log.warn("Часть модулей отсутствует — часть функций может не работать.")
    end

    -- Базовый FOV
    Init.setBaseFov()

    -- GUI
    Init.buildGui()

    -- Привязка персонажа
    Init.bindCurrentCharacter()

    -- Авто-ремонт
    Init.startAutoRepair()

    -- Готово
    State.Started = true

    Log.info("═══════════════════════════════════════════")
    Log.info("  ROCKET FLY ЗАПУЩЕН")
    Log.info("  F — полёт | Q — dash | RightShift — GUI")
    Log.info("  Shift — boost | Ctrl — slow | Space/Alt — вверх/вниз")
    Log.info("  G — крылья | H — аура | C — камера")
    Log.info("═══════════════════════════════════════════")
end

-- ============================================================
-- МОДУЛЬ: ВЫКЛЮЧЕНИЕ / ОЧИСТКА
-- ============================================================
local Shutdown = {}

function Shutdown.run()
    if not State.Started then return end
    Log.info("Выключение ROCKET FLY...")

    State.Started = false

    -- Отключаем полёт
    if RF.Fly and RF.Fly.disable then
        pcall(function() RF.Fly.disable() end)
    end

    -- Очищаем эффекты
    if RF.Effects and RF.Effects.cleanup then
        pcall(function() RF.Effects.cleanup() end)
    end

    -- Уничтожаем крылья
    if RF.Wings then
        pcall(function()
            RF.Wings.destroy(State.WingL)
            RF.Wings.destroy(State.WingR)
        end)
        State.WingL = nil
        State.WingR = nil
    end

    -- Уничтожаем звук
    Inst.safeDestroy(State.BoostSound)
    State.BoostSound = nil

    -- Возвращаем FOV
    if Camera and State.CamBaseFov then
        Camera.FieldOfView = State.CamBaseFov
    end

    -- Возвращаем Humanoid
    if State.Humanoid then
        pcall(function()
            State.Humanoid.PlatformStand = false
        end)
    end

    -- Уничтожаем GUI
    if RF.UI and RF.UI.build then
        local refs = RF.UI
        if RF.UI and RF.UI._refs and RF.UI._refs.screen then
            Inst.safeDestroy(RF.UI._refs.screen)
        end
    end

    -- Чистим соединения
    Conn.clear()

    Log.info("Выключено.")
end

-- ============================================================
-- МОДУЛЬ: ПУБЛИЧНОЕ API
-- ============================================================
local API = {}

function API.start()
    Init.run()
end

function API.stop()
    Shutdown.run()
end

function API.toggle()
    if State.Started then
        API.stop()
    else
        API.start()
    end
end

function API.enableFly()
    if RF.Fly then RF.Fly.enable() end
end

function API.disableFly()
    if RF.Fly then RF.Fly.disable() end
end

function API.dash()
    if RF.Dash then RF.Dash.execute() end
end

function API.toggleGui()
    if RF.UI then RF.UI.toggle() end
end

function API.setSpeed(speed)
    CONFIG.BaseSpeed = Math.clamp(speed or 55, 10, 500)
end

function API.setBoost(mult)
    CONFIG.BoostMultiplier = Math.clamp(mult or 2.8, 1, 10)
end

function API.setWings(on)
    CONFIG.EnableWings = on and true or false
    if RF.Wings then
        RF.Wings.setVisible(State.WingL, on and State.Flying)
        RF.Wings.setVisible(State.WingR, on and State.Flying)
    end
end

function API.setAura(on)
    CONFIG.EnableAura = on and true or false
    if State.Aura then
        State.Aura.Transparency = on and (State.Flying and 0.75 or 1) or 1
    end
end

function API.setCamera(on)
    CONFIG.CameraEnabled = on and true or false
    if not on and RF.CameraMod then
        RF.CameraMod.resetFov()
    end
end

function API.getState()
    return {
        Enabled   = State.Enabled,
        Flying    = State.Flying,
        TakingOff = State.TakingOff,
        Landing   = State.Landing,
        Dashing   = State.Dashing,
        Speed     = State.Velocity.Magnitude,
        SpeedMul  = State.SpeedMul,
    }
end

-- ============================================================
-- ЗАПУСК
-- ============================================================
task.spawn(function()
    -- Ждём игрока
    if not LocalPlayer then return end

    -- Ждём персонажа
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end

    task.wait(0.5)

    -- Запуск
    Init.run()
end)

-- ============================================================
-- АВТО-ОЧИСТКА ПРИ ВЫХОДЕ
-- ============================================================
game:BindToClose(function()
    pcall(function()
        Shutdown.run()
    end)
end)

-- Обработка исключений при выходе игрока
LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then
        pcall(function() Shutdown.run() end)
    end
end)

-- ============================================================
-- ЭКСПОРТ ПУБЛИЧНОГО API
-- ============================================================
RF.Init     = Init
RF.Shutdown = Shutdown
RF.API      = API

-- Совместимость со старым API
RF.Rocket = RF.Rocket or {}
RF.Rocket.start = API.start
RF.Rocket.stop = API.stop
RF.Rocket.toggle = API.toggle
RF.Rocket.getState = API.getState

-- Глобальный доступ (для внешних скриптов)
_G.ROCKET_FLY = API
_G.ROCKET = API

Log.info("═══════════════════════════════════════════")
Log.info("  Часть 10 загружена — финальная инициализация")
Log.info("  Все модули готовы. Скрипт запущен.")
Log.info("  Управление:")
Log.info("    F — вкл/выкл полёт")
Log.info("    Q — dash")
Log.info("    RightShift — открыть GUI")
Log.info("    Shift — ускорение")
Log.info("    Ctrl — замедление")
Log.info("    Space — вверх, LeftAlt — вниз")
Log.info("    G — крылья вкл/выкл")
Log.info("    H — аура вкл/выкл")
Log.info("    C — камера вкл/выкл")
Log.info("═══════════════════════════════════════════")
