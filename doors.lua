--[[
    ============================================================
    Script com Bypass de Dependência do Main_Game
    - Dispara os RemoteEvents diretamente na memória do ReplicatedStorage
    - Não depende da inicialização do Main_Game ou da PromptService
    - Mantém a automação ativa de forma autônoma
    ============================================================
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- Estado Global Indevassável
if not _G.GlobalState then
    _G.GlobalState = {
        AutoPlayAgainEnabled = false,
        AutoShopConfirmEnabled = false,
        AutoInitializeEnabled = true,
        ShopProcessed = false,
        IsDeadProcessing = false
    }
end

local config = _G.GlobalState
local settingsFileName = "SupremeAutomationConfig.json"

local function saveSettings()
    pcall(function()
        if writefile and HttpService then
            writefile(settingsFileName, HttpService:JSONEncode({
                AutoPlayAgainEnabled = config.AutoPlayAgainEnabled,
                AutoShopConfirmEnabled = config.AutoShopConfirmEnabled,
                AutoInitializeEnabled = config.AutoInitializeEnabled
            }))
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
                    if decoded.AutoPlayAgainEnabled ~= nil then config.AutoPlayAgainEnabled = decoded.AutoPlayAgainEnabled end
                    if decoded.AutoShopConfirmEnabled ~= nil then config.AutoShopConfirmEnabled = decoded.AutoShopConfirmEnabled end
                    if decoded.AutoInitializeEnabled ~= nil then config.AutoInitializeEnabled = decoded.AutoInitializeEnabled end
                end
            end
        end
    end)
end

loadSettings()

-- ==========================================================
-- ENGINE DIRETA (Executa sem depender do Main_Game)
-- ==========================================================

-- Loop Auto Pre-run Shop Confirm
if not _G.ShopLoopStarted then
    _G.ShopLoopStarted = true
    task.spawn(function()
        while true do
            if config.AutoShopConfirmEnabled and not config.ShopProcessed then
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
end

-- Monitoramento Direct Humanoid para Auto Play Again
local function triggerPlayAgain()
    if config.IsDeadProcessing then return end
    config.IsDeadProcessing = true
    
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
    config.IsDeadProcessing = false
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

-- ==========================================================
-- CRIAÇÃO DA INTERFACE VISUAL
-- ==========================================================

local function createGUI()
    if CoreGui:FindFirstChild("Rayfield") then
        pcall(function() CoreGui.Rayfield:Destroy() end)
    end

    local Rayfield = nil
    local successRayfield, result = pcall(function()
        local source = game:HttpGet('https://sirius.menu/rayfield')
        return loadstring(source)()
    end)

    if not successRayfield or not result then return nil end

    Rayfield = result

    local Window = Rayfield:CreateWindow({
        Name = "Painel de Automação Direta",
        LoadingTitle = "Carregando...",
        LoadingSubtitle = "Modo Direto Ativo",
        ConfigurationSaving = { Enabled = false },
        KeySystem = false,
    })

    local MainTab = Window:CreateTab("Automação", 4483362458)
    local SettingsTab = Window:CreateTab("Configurações", 4483362458)

    MainTab:CreateSection("Auto Play Again")
    MainTab:CreateToggle({
        Name = "Ativar Auto Play Again",
        CurrentValue = config.AutoPlayAgainEnabled,
        Flag = "PlayAgainToggle",
        Callback = function(Value)
            config.AutoPlayAgainEnabled = Value
            saveSettings()
        end,
    })

    MainTab:CreateSection("Auto Pre-run Shop Confirm")
    MainTab:CreateToggle({
        Name = "Ativar Auto Pre-run Shop Confirm",
        CurrentValue = config.AutoShopConfirmEnabled,
        Flag = "ShopConfirmToggle",
        Callback = function(Value)
            config.AutoShopConfirmEnabled = Value
            if Value then config.ShopProcessed = false end
            saveSettings()
        end,
    })

    SettingsTab:CreateSection("Sistema")
    SettingsTab:CreateButton({
        Name = "Recarregar Interface Visual",
        Callback = function()
            createGUI()
        end,
    })

    return Rayfield
end

createGUI()

<ElicitationsGroup message="Se precisar de mais ajustes no script:">
  <Elicitation label="Testar sem Rayfield" query="Pode fazer uma versão sem nenhuma interface visual (sem Rayfield), que rode totalmente direto ao injetar?" />
  <Elicitation label="Verificar novos remotes" query="Como posso verificar se o servidor mudou os nomes dos RemoteEvents da loja?" />
</ElicitationsGroup>
