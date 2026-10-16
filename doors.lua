--[[
    Script de Automação Direta (Sem Interface Visual / Sem Rayfield)
    Executa instantaneamente ao injetar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Configurações de Ativação (Altere para true ou false)
local AUTO_PLAY_AGAIN = true
local AUTO_SHOP_CONFIRM = true

print("--- [AUTOMATION] Script Autônomo Iniciado ---")

-- 1. Loop para Auto Pre-run Shop Confirm
task.spawn(function()
    while AUTO_SHOP_CONFIRM do
        pcall(function()
            local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
            if remotesFolder then
                local preRunShop = remotesFolder:FindFirstChild("PreRunShop")
                if preRunShop and preRunShop:IsA("RemoteEvent") then
                    preRunShop:FireServer({}, false, {})
                end
            end
        end)
        task.wait(0.15)
    end
end)

-- 2. Sistema para Auto Play Again
local function triggerPlayAgain()
    pcall(function()
        local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
        if remotesFolder then
            local playAgainEvent = remotesFolder:FindFirstChild("PlayAgain")
            if playAgainEvent and playAgainEvent:IsA("RemoteEvent") then
                playAgainEvent:FireServer()
                print("--- [AUTOMATION] Play Again Disparado ---")
            end
        end
    end)
end

local function monitorCharacter(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 15)
    if not humanoid then return end
    
    humanoid.Died:Connect(function()
        if AUTO_PLAY_AGAIN then
            task.wait(0.15)
            if humanoid and humanoid.Health <= 0 then
                triggerPlayAgain()
            end
        end
    end)
end

if player.Character then monitorCharacter(player.Character) end
player.CharacterAdded:Connect(monitorCharacter)
