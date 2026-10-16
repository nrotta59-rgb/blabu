--[[
    ============================================================
    Script Supremo com Auto Reset em 3 Minutos
    - Auto Play Again
    - Auto Pre-run Shop Confirm
    - Auto Reset (Padrão: 3 minutos)
    - Anti-Lag (Otimizador de Desempenho)
    - Proteção e Bypass contra falhas do Main_Game
    ============================================================
]]

if _G.SupremeAutomationRunning then
    warn("[Automation] Instância anterior detectada. Reiniciando...")
    _G.SupremeAutomationRunning = false
    task.wait(0.5)
end
_G.SupremeAutomationRunning = true

local function startMasterScript()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CoreGui = game:GetService("CoreGui")
    local Lighting = game:GetService("Lighting")
    local HttpService = game:GetService("HttpService")
    
    local player = Players.LocalPlayer
    if not player then
        task.wait(1)
        return startMasterScript()
    end

    -- Limpeza de interfaces anteriores na CoreGui
    if CoreGui:FindFirstChild("Rayfield") then
        pcall(function() CoreGui.Rayfield:Destroy() end)
    end

    -- Tabela de Configurações (Auto Reset definido em 3 minutos)
    local config = {
        AutoPlayAgainEnabled = false,
        AutoShopConfirmEnabled = false,
        AutoResetEnabled = false,
        AutoResetMinutes = 3, -- Definido para 3 minutos
        AntiLagEnabled = false
    }

    local settingsFileName = "SupremeAutomationConfig.json"

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

    -- Carregamento Seguro da Rayfield
    local Rayfield = nil
    local successRayfield, result = pcall(function()
        local source = game:HttpGet('https://sirius.menu/rayfield')
        if not source or source == "" then error("Fonte vazia") end
        return loadstring(source)()
    end)

    if not successRayfield or not result then
        warn("[Erro] Falha ao carregar a interface Rayfield. Verifique a conexão do executor.")
        _G.SupremeAutomationRunning = false
        return
    end
    Rayfield = result

    -- Criação da Janela
    local Window = nil
    local successWindow = pcall(function()
        Window = Rayfield:CreateWindow({
            Name = "Painel de Automação Blindado",
            LoadingTitle = "Iniciando...",
            LoadingSubtitle = "Proteção Anti-Erro Ativa",
            ConfigurationSaving = { Enabled = false },
            KeySystem = false,
        })
    end)

    if not successWindow or not Window then
        _G.SupremeAutomationRunning = false
        return
    end

    local MainTab = Window:CreateTab("Automação", 4483362458)
    local SettingsTab = Window:CreateTab("Configurações", 4483362458)

    -- ==========================================
    -- 1. Auto Play Again (Execução Direta)
    -- ==========================================
    MainTab:CreateSection("Auto Play Again")
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

    MainTab:CreateToggle({
        Name = "Ativar Auto Play Again",
        CurrentValue = config.AutoPlayAgainEnabled,
        Flag = "SupremePlayAgainToggle",
        Callback = function(Value)
            config.AutoPlayAgainEnabled = Value
            saveSettings()
        end,
    })

    -- ==========================================
    -- 2. Auto Pre-run Shop Confirm
    -- ==========================================
    MainTab:CreateSection("Auto Pre-run Shop Confirm")
    local shopProcessed = false

    task.spawn(function()
        while _G.SupremeAutomationRunning do
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

    MainTab:CreateToggle({
        Name = "Ativar Auto Pre-run Shop Confirm",
        CurrentValue = config.AutoShopConfirmEnabled,
        Flag = "SupremeShopConfirmToggle",
        Callback = function(Value)
            config.AutoShopConfirmEnabled = Value
            saveSettings()
            if Value then
                shopProcessed = false
            end
        end,
    })

    -- ==========================================
    -- 3. Auto Reset (Ajustado para 3 Minutos)
    -- ==========================================
    MainTab:CreateSection("Auto Reset (Anti-Bug)")

    task.spawn(function()
        local timer = 0
        while _G.SupremeAutomationRunning do
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

    MainTab:CreateToggle({
        Name = "Ativar Auto Reset Periódico",
        CurrentValue = config.AutoResetEnabled,
        Flag = "AutoResetToggle",
        Callback = function(Value)
            config.AutoResetEnabled = Value
            saveSettings()
        end,
    })

    MainTab:CreateSlider({
        Name = "Tempo do Auto Reset (Minutos)",
        Range = {1, 5},
        Increment = 1,
        CurrentValue = config.AutoResetMinutes,
        Flag = "AutoResetSlider",
        Callback = function(Value)
            config.AutoResetMinutes = Value
            saveSettings()
        end,
    })

    -- ==========================================
    -- 4. Anti-Lag (Otimizador de Desempenho)
    -- ==========================================
    SettingsTab:CreateSection("Otimização de Desempenho")

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

    SettingsTab:CreateToggle({
        Name = "Ativar Anti-Lag (Remove Sombras/Efeitos)",
        CurrentValue = config.AntiLagEnabled,
        Flag = "AntiLagToggle",
        Callback = function(Value)
            config.AntiLagEnabled = Value
            applyAntiLag(Value)
            saveSettings()
        end,
    })

    if config.AntiLagEnabled then
        applyAntiLag(true)
    end

    SettingsTab:CreateButton({
        Name = "Salvar Configurações Manualmente",
        Callback = function()
            saveSettings()
            Rayfield:Notify({
                Title = "Sucesso",
                Content = "Configurações salvas!",
                Duration = 2,
                Image = 4483362458,
            })
        end,
    })

    print("[Automation] Sistema carregado com Auto Reset em 3 minutos.")
end

pcall(startMasterScript)
