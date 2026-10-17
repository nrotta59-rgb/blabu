--[[
    ============================================================
    Script Supremo Nativo - Versão Orion Library
    ============================================================
]]

if queue_on_teleport then
    pcall(function()
        queue_on_teleport([[
            task.wait(1)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/nrotta59-rgb/blabu/refs/heads/main/doors.lua?v=" .. tick()))()
        ]])
    end)
end

if _G.NativeAutomationRunning then
    _G.NativeAutomationRunning = false
    task.wait(0.3)
end
_G.NativeAutomationRunning = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
if not player then return end

local config = {
    AutoPlayAgain = false,
    AutoShopConfirm = false,
    AutoReset = false,
    AutoResetMinutes = 4,
    AntiAFK = true
}

local settingsFileName = "NativeAutomationConfig.json"

local function saveSettings()
    pcall(function()
        if writefile and HttpService then
            writefile(settingsFileName, HttpService:JSONEncode(config))
        end
    end)
end

local function loadSettings()
    pcall(function()
        if readfile and isfile and isfile(settingsFileName) then
            local fileContent = readfile(settingsFileName)
            local decodedTable = HttpService:JSONDecode(fileContent)
            if type(decodedTable) == "table" then
                for k, v in pairs(decodedTable) do 
                    config[k] = v 
                end
            end
        end
    end)
end
loadSettings()

config.AutoResetMinutes = 4
saveSettings()

-- Carrega a Orion Library
local OrionLib = nil
pcall(function()
    OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
end)

if not OrionLib then
    warn("[Automation] Falha ao carregar a Orion Library.")
    return
end

local Window = OrionLib:MakeWindow({
    Name = "Painel Supremo - Doors",
    HidePremium = true,
    SaveConfig = true,
    ConfigFolder = "SupremeAutomation"
})

local Tab = Window:MakeTab({
    Name = "Automação",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
})

-- 1. Auto Play Again
local isDeadProcessing = false
local function triggerPlayAgain()
    if isDeadProcessing then return end
    isDeadProcessing = true
    
    pcall(function()
        local playerGui = player:WaitForChild("PlayerGui", 5)
        local mainUI = playerGui and playerGui:WaitForChild("MainUI", 5)
        
        if mainUI then
            local deathPanel = mainUI:WaitForChild("DeathPanel", 10)
            if deathPanel then
                local timeout = tick() + 5
                while not deathPanel.Visible and tick() < timeout and _G.NativeAutomationRunning do
                    task.wait(0.2)
                end
            end
        end

        task.wait(1.5)

        local remotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder", 5)
        local playAgainEvent = remotesFolder and remotesFolder:WaitForChild("PlayAgain", 5)

        if playAgainEvent then
            playAgainEvent:FireServer()
            print("[Automation] Play Again disparado com sucesso!")
        else
            warn("[Automation] RemoteEvent 'PlayAgain' não encontrado.")
        end
    end)
    
    task.wait(4)
    isDeadProcessing = false
end

local function monitorCharacter(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 15)
    if not humanoid then return end
    
    humanoid.Died:Connect(function()
        if config.AutoPlayAgain then
            triggerPlayAgain()
        end
    end)
end

if player.Character then 
    task.spawn(function() monitorCharacter(player.Character) end)
end

player.CharacterAdded:Connect(function(newCharacter)
    task.spawn(function() monitorCharacter(newCharacter) end)
end)

Tab:AddToggle({
    Name = "Auto Play Again",
    Default = config.AutoPlayAgain,
    Callback = function(Value)
        config.AutoPlayAgain = Value
        saveSettings()
    end    
})

-- 2. Auto Pre-run Shop Confirm
local cachedShopRemote = nil
local function startShopThread()
    task.spawn(function()
        while _G.NativeAutomationRunning do
            if config.AutoShopConfirm then
                pcall(function()
                    if not cachedShopRemote or not cachedShopRemote.Parent then
                        local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
                        if remotesFolder then
                            cachedShopRemote = remotesFolder:FindFirstChild("PreRunShop") or remotesFolder:FindFirstChild("ConfirmShop") or remotesFolder:FindFirstChild("ShopConfirm")
                        end
                    end
                    if cachedShopRemote then
                        cachedShopRemote:FireServer({}, false, {})
                    end
                end)
            end
            task.wait(1)
        end
    end)
end
startShopThread()

Tab:AddToggle({
    Name = "Auto Shop Confirm",
    Default = config.AutoShopConfirm,
    Callback = function(Value)
        config.AutoShopConfirm = Value
        saveSettings()
    end    
})

-- 3. Auto Reset (4 Minutos Exatos)
local resetToggleElement = nil

local function startResetThread()
    task.spawn(function()
        local timer = 0
        while _G.NativeAutomationRunning do
            task.wait(1)
            
            if config.AutoReset then
                timer = timer + 1
                local maxSeconds = config.AutoResetMinutes * 60
                local remaining = maxSeconds - timer
                if remaining < 0 then remaining = 0 end
                
                local mins = math.floor(remaining / 60)
                local secs = remaining % 60
                
                if resetToggleElement and config.AutoReset then
                    resetToggleElement:Set({Name = string.format("Auto Reset (%02d:%02d)", mins, secs)})
                end
                
                if timer >= maxSeconds then
                    timer = 0
                    pcall(function()
                        if player.Character then
                            local hum = player.Character:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum.Health = 0
                                print("[Automation] Auto Reset acionado.")
                            end
                        end
                    end)
                end
            else
                timer = 0
                if resetToggleElement then
                    resetToggleElement:Set({Name = "Auto Reset"})
                end
            end
        end
    end)
end
startResetThread()

resetToggleElement = Tab:AddToggle({
    Name = "Auto Reset",
    Default = config.AutoReset,
    Callback = function(Value)
        config.AutoReset = Value
        saveSettings()
    end    
})

-- 4. Anti-AFK
local function startAFKThread()
    task.spawn(function()
        while _G.NativeAutomationRunning do
            if config.AntiAFK then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            end
            task.wait(60)
        end
    end)
end
startAFKThread()

Tab:AddToggle({
    Name = "Anti-AFK",
    Default = config.AntiAFK,
    Callback = function(Value)
        config.AntiAFK = Value
        saveSettings()
    end    
})

OrionLib:Init()
print("[SupremeAutomation] Script carregado com sucesso via Orion Library!")
