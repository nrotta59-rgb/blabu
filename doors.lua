--[[
    ============================================================
    Script Supremo de Automação (Orion Library - Carregamento Seguro)
    - Auto Play Again
    - Auto Pre-run Shop Confirm
    - Auto Reset (3 minutos por padrão)
    - Anti-Lag (Otimizador de Desempenho)
    - Duplo Método de HTTP (Previne erro de nil value)
    ============================================================
]]

if _G.OrionAutomationRunning then
    warn("[Automation] Instância anterior detectada. Reiniciando...")
    _G.OrionAutomationRunning = false
    task.wait(0.5)
end
_G.OrionAutomationRunning = true

local function startMasterScript()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Lighting = game:GetService("Lighting")
    local HttpService = game:GetService("HttpService")
    
    local player = Players.LocalPlayer
    if not player then
        task.wait(1)
        return startMasterScript()
    end

    -- Carregamento Blindado da Orion Library (request / HttpGet)
    local OrionLib = nil
    local successOrion, result = pcall(function()
        local source = nil
        
        if request then
            local req = request({
                Url = "https://raw.githubusercontent.com/shlexware/Orion/main/source",
                Method = "GET"
            })
            if req and req.Body then
                source = req.Body
            end
        end
        
        if not source or source == "" then
            source = game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source")
        end
        
        if not source or source == "" then
            error("Conteúdo do link retornou vazio.")
        end
        
        return loadstring(source)()
    end)

    if not successOrion or not result then
        warn("[Erro Crítico] O executor bloqueou o download da biblioteca.")
        _G.OrionAutomationRunning = false
        return
    end
    OrionLib = result

    -- Configurações Locais
    local config = {
        AutoPlayAgainEnabled = false,
        AutoShopConfirmEnabled = false,
        AutoResetEnabled = false,
        AutoResetMinutes = 3,
        AntiLagEnabled = false
    }

    local settingsFileName = "OrionAutomationConfig.json"

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
                local rawData = readfile(settingsFileName)
                if rawData then
                    local decoded = HttpService:JSONDecode(rawData)
                    if type(decoded) == "table" then
                        for k, v in pairs(decoded) do
                            if config[k] ~= nil then config[k] = v end
                        end
                    end
                end
            end
        end)
    end

    loadSettings()

    -- Janela Principal
    local Window = OrionLib:MakeWindow({
        Name = "Painel de Automação (Orion UI)",
        HidePremium = true,
        SaveConfig = false,
        IntroEnabled = true,
        IntroText = "Carregando Módulos...",
        Icon = "rbxassetid://4483362458"
    })

    local MainTab = Window:MakeTab({
        Name = "Automação",
        Icon = "rbxassetid://4483362458",
        PremiumOnly = false
    })

    local SettingsTab = Window:MakeTab({
        Name = "Configurações",
        Icon = "rbxassetid://4483362458",
        PremiumOnly = false
    })

    -- ==========================================
    -- 1. Auto Play Again
    -- ==========================================
    MainTab:AddSection({ Name = "Auto Play Again" })
    local isDeadProcessing = false

    local function triggerPlayAgain()
        if isDeadProcessing then return end
        isDeadProcessing = true
        
        pcall(function()
            local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
            if remotesFolder then
                local playAgainEvent = remotesFolder:FindFirstChild("PlayAgain")
                if playAgainEvent and playAgainEvent:IsA("RemoteEvent") then
                    playAgainEvent:FireServer()
                end
            end
        end)
        
        task.wait(3)
        isDeadProcessing = false
    end

    local function monitorCharacter(character)
        if not character then return end
        local humanoid = character:WaitForChild("Humanoid", 15)
        if not humanoid then return end
        
        humanoid.Died:Connect(function()
            if config.AutoPlayAgainEnabled then
                task.wait(0.15)
                if humanoid and humanoid.Health <= 0 then
                    triggerPlayAgain()
                end
            end
        end)
    end

    if player.Character then monitorCharacter(player.Character) end
    player.CharacterAdded:Connect(monitorCharacter)

    MainTab:AddToggle({
        Name = "Ativar Auto Play Again",
        Default = config.AutoPlayAgainEnabled,
        Callback = function(Value)
            config.AutoPlayAgainEnabled = Value
            saveSettings()
        end
    })

    -- ==========================================
    -- 2. Auto Pre-run Shop Confirm
    -- ==========================================
    MainTab:AddSection({ Name = "Auto Pre-run Shop Confirm" })
    local shopProcessed = false

    task.spawn(function()
        while _G.OrionAutomationRunning do
            if config.AutoShopConfirmEnabled and not shopProcessed do
                pcall(function()
                    local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
                    if remotesFolder then
                        local preRunShop = remotesFolder:FindFirstChild("PreRunShop")
                        if preRunShop and preRunShop:IsA("RemoteEvent") then
                            preRunShop:FireServer({}, false, {})
                        end
                    end
                end)
            end
            task.wait(0.15)
        end
    end)

    MainTab:AddToggle({
        Name = "Ativar Auto Pre-run Shop Confirm",
        Default = config.AutoShopConfirmEnabled,
        Callback = function(Value)
            config.AutoShopConfirmEnabled = Value
            saveSettings()
            if Value then
                shopProcessed = false
            end
        end
    })

    -- ==========================================
    -- 3. Auto Reset (3 Minutos Padrão)
    -- ==========================================
    MainTab:AddSection({ Name = "Auto Reset (Anti-Bug)" })

    task.spawn(function()
        local timer = 0
        while _G.OrionAutomationRunning do
            task.wait(1)
            if config.AutoResetEnabled then
                timer = timer + 1
                local targetSeconds = config.AutoResetMinutes * 60
                if timer >= targetSeconds then
                    timer = 0
                    pcall(function()
                        local char = player.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid.Health = 0
                        end
                    end)
                end
            else
                timer = 0
            end
        end
    end)

    MainTab:AddToggle({
        Name = "Ativar Auto Reset Periódico",
        Default = config.AutoResetEnabled,
        Callback = function(Value)
            config.AutoResetEnabled = Value
            saveSettings()
        end
    })

    MainTab:AddSlider({
        Name = "Tempo do Auto Reset (Minutos)",
        Min = 1,
        Max = 5,
        Default = config.AutoResetMinutes,
        Color = Color3.fromRGB(255, 255, 255),
        Increment = 1,
        ValueName = "min",
        Callback = function(Value)
            config.AutoResetMinutes = Value
            saveSettings()
        end    
    })

    -- ==========================================
    -- 4. Anti-Lag
    -- ==========================================
    SettingsTab:AddSection({ Name = "Otimização e Desempenho" })

    local function applyAntiLag(state)
        pcall(function()
            if state then
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") then
                        obj.Enabled = false
                    end
                end
            else
                Lighting.GlobalShadows = true
            end
        end)
    end

    SettingsTab:AddToggle({
        Name = "Ativar Anti-Lag (Remove Sombras/Efeitos)",
        Default = config.AntiLagEnabled,
        Callback = function(Value)
            config.AntiLagEnabled = Value
            applyAntiLag(Value)
            saveSettings()
        end
    })

    if config.AntiLagEnabled then
        applyAntiLag(true)
    end

    SettingsTab:AddButton({
        Name = "Salvar Configurações Manualmente",
        Callback = function()
            saveSettings()
            OrionLib:MakeNotification({
                Name = "Sucesso",
                Content = "Configurações salvas!",
                Image = "rbxassetid://4483362458",
                Time = 3
            })
        end
    })

    OrionLib:Init()
    print("[OrionAutomation] Script executado com sucesso.")
end

pcall(startMasterScript)
