--[[
    ============================================================
    Script de Automação Suprema e Masterizada (Versão Definitiva)
    - Auto Play Again + Anti-Morte
    - Auto Pre-run Shop Confirm (Loop de Alta Frequência)
    - Correção Permanente para Elementos que Sumem na UI
    - Salvamento de Configurações e Auto-Reload Blindado
    Local de Instalação: StarterPlayerScripts (LocalScript)
    ============================================================
]]

if _G.UltimateAutomationRunning then
    warn("[Automation] Instância anterior já ativa. Encerrando...")
    return
end
_G.UltimateAutomationRunning = true

local function startMasterScript()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CoreGui = game:GetService("CoreGui")
    local HttpService = game:GetService("HttpService")
    
    local player = Players.LocalPlayer
    if not player then
        task.wait(1)
        return startMasterScript()
    end

    -- Limpeza de instâncias residuais
    if CoreGui:FindFirstChild("Rayfield") then
        pcall(function() CoreGui.Rayfield:Destroy() end)
    end

    -- Gerenciamento de Configurações
    local config = {
        AutoPlayAgainEnabled = false,
        AutoShopConfirmEnabled = false,
        AutoInitializeEnabled = true
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

    -- Auto Reload em caso de falha crítica
    local function reloadScript(reason)
        warn("[AutoReload] Motivo: " .. tostring(reason) .. ". Reiniciando...")
        _G.UltimateAutomationRunning = false
        task.wait(1.5)
        pcall(startMasterScript)
    end

    -- Carregamento da Rayfield
    local Rayfield = nil
    local successRayfield, result = pcall(function()
        local source = game:HttpGet('https://sirius.menu/rayfield')
        if not source or source == "" then error("Link vazio") end
        return loadstring(source)()
    end)

    if successRayfield and result then
        Rayfield = result
    else
        return reloadScript("Falha ao carregar a biblioteca Rayfield")
    end

    -- Criação da Janela
    local Window = nil
    local successWindow = pcall(function()
        Window = Rayfield:CreateWindow({
            Name = "Painel Supremo de Automação",
            LoadingTitle = "Iniciando Sistema...",
            LoadingSubtitle = "Estável & Otimizado",
            ConfigurationSaving = {
                Enabled = true,
                FolderName = "SupremeAutomation",
                FileName = "SessionData"
            },
            KeySystem = false,
        })
    end)

    if not successWindow or not Window then
        return reloadScript("Falha ao criar a janela")
    end

    local MainTab, SettingsTab
    pcall(function()
        MainTab = Window:CreateTab("Automação", 4483362458)
        SettingsTab = Window:CreateTab("Configurações", 4483362458)
    end)

    if not MainTab or not SettingsTab then
        return reloadScript("Falha ao criar as abas")
    end

    -- ==========================================================
    -- CORREÇÃO PERMANENTE: Monitor de Layout Anti-Sumumo da UI
    -- ==========================================================
    task.spawn(function()
        while _G.UltimateAutomationRunning do
            pcall(function()
                local rayfieldCore = CoreGui:FindFirstChild("Rayfield")
                if rayfieldCore then
                    for _, desc in ipairs(rayfieldCore:GetDescendants()) do
                        if desc:IsA("ScrollingFrame") then
                            if desc.UIListLayout then
                                desc.CanvasSize = UDim2.new(0, 0, 0, desc.UIListLayout.AbsoluteContentSize.Y + 40)
                            end
                        end
                    end
                end
            end)
            task.wait(2) -- Atualiza o layout a cada 2 segundos para nunca sumir ou travar
        end
    end)

    -- ==========================================
    -- 1. Sistema Auto Play Again
    -- ==========================================
    MainTab:CreateSection("Auto Play Again")
    local isDeadProcessing = false

    local function triggerPlayAgain()
        if isDeadProcessing then return end
        isDeadProcessing = true
        
        pcall(function()
            local remotesFolder = ReplicatedStorage and ReplicatedStorage:FindFirstChild("RemotesFolder")
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
        
        task.spawn(function()
            while character and character.Parent do
                if config.AutoPlayAgainEnabled and humanoid.Health <= 0 and not isDeadProcessing then
                    triggerPlayAgain()
                    break
                end
                task.wait(1)
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
    -- 2. Sistema Auto Pre-run Shop Confirm
    -- ==========================================
    MainTab:CreateSection("Auto Pre-run Shop Confirm")
    local shopProcessed = false

    local function runShopAutomation()
        if shopProcessed or not config.AutoShopConfirmEnabled then return end
        
        task.spawn(function()
            while config.AutoShopConfirmEnabled and not shopProcessed do
                pcall(function()
                    if ReplicatedStorage then
                        local remotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder", 2)
                        if remotesFolder then
                            local preRunShop = remotesFolder:WaitForChild("PreRunShop", 2)
                            if preRunShop and preRunShop:IsA("RemoteEvent") then
                                preRunShop:FireServer({}, false, {})
                            end
                        end
                    end
                end)
                task.wait(0.15)
            end
        end)
    end

    shopProcessed = false
    runShopAutomation()

    MainTab:CreateToggle({
        Name = "Ativar Auto Pre-run Shop Confirm",
        CurrentValue = config.AutoShopConfirmEnabled,
        Flag = "SupremeShopConfirmToggle",
        Callback = function(Value)
            config.AutoShopConfirmEnabled = Value
            saveSettings()
            if Value then
                shopProcessed = false
                runShopAutomation()
            end
        end,
    })

    -- ==========================================
    -- 3. Gerenciamento e Configurações
    -- ==========================================
    SettingsTab:CreateSection("Opções do Sistema")

    SettingsTab:CreateToggle({
        Name = "Auto Initialize (Persistência)",
        CurrentValue = config.AutoInitializeEnabled,
        Flag = "SupremeInitToggle",
        Callback = function(Value)
            config.AutoInitializeEnabled = Value
            saveSettings()
        end,
    })

    SettingsTab:CreateButton({
        Name = "Recarregar Script Manualmente",
        Callback = function()
            reloadScript("Solicitação manual")
        end,
    })

    SettingsTab:CreateButton({
        Name = "Salvar Configurações Agora",
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

    player.OnTeleport:Connect(function()
        if config.AutoInitializeEnabled then pcall(saveSettings) end
    end)

    pcall(function() Rayfield:LoadConfiguration() end)
    print("[UltimateAutomation] Sistema operacional e estabilizado com sucesso.")
end

pcall(startMasterScript)
