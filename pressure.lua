-- Carregar Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Criar a Janela Principal
local Window = Rayfield:CreateWindow({
   Name = "Pressure Script",
   Icon = 0,
   LoadingTitle = "Carregando Interface...",
   LoadingSubtitle = "Preparando o script para Pressure",
   Theme = "Default",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = false
   }
})

-- --- Variáveis de Estado e Referências Essenciais ---
local vals = {
    NoLocalDamage = false,
    AntiSearchlights = false,
    Fullbright = false,
    NoDeath = false, -- Variável para o No Death
    NotifyMonsters = false,
    ESP_Currency = false,
    ESP_Keycard = false,
    SafeTeleport = false
}
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Events = ReplicatedStorage.Events
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")

local searchlights = {}

-- --- Funções Auxiliares ---

local blockedRemoteObjects = {}

local function blockInstance(object, condition)
    local originalParent = object.Parent
    blockedRemoteObjects[object] = originalParent

    RunService.RenderStepped:Connect(function()
        if vals[condition] then
            if object and object.Parent == originalParent then
                object.Parent = nil
            end
        else
            if object and not object.Parent and originalParent then
                object.Parent = originalParent
            end
        end
    end)
end

local function collectObjects(obj)
    if not obj or not obj.Parent then return end

    if obj:IsA("RemoteEvent") then
        if obj.Parent and obj.Parent:IsA("Part") and obj.Name == "RemoteEvent" and obj.Parent.Name:lower():match("searchlight") then
            table.insert(searchlights, obj)
            if vals.AntiSearchlights then
                blockInstance(obj, "AntiSearchlights")
            end
        end
    end
end

-- Iniciar coleta de objetos existentes e monitorar novos
for _, v in workspace:GetDescendants() do
    task.spawn(collectObjects, v)
end
workspace.DescendantAdded:Connect(collectObjects)

-- --- Lógica Fullbright ---
local originalAmbient
local originalOutdoorAmbient
local originalBrightness
local originalFogEnd
local originalFogStart
local originalFogColor

local function activateFullbright()
    originalAmbient = Lighting.Ambient
    originalOutdoorAmbient = Lighting.OutdoorAmbient
    originalBrightness = Lighting.Brightness
    originalFogEnd = Lighting.FogEnd
    originalFogStart = Lighting.FogStart
    originalFogColor = Lighting.FogColor

    Lighting.Ambient = Color3.new(1, 1, 1)
    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    Lighting.Brightness = 2
    Lighting.FogEnd = 100000
    Lighting.FogStart = 90000
    Lighting.FogColor = Color3.new(0, 0, 0)
end

local function deactivateFullbright()
    Lighting.Ambient = originalAmbient
    Lighting.OutdoorAmbient = originalOutdoorAmbient
    Lighting.Brightness = originalBrightness
    Lighting.FogEnd = originalFogEnd
    Lighting.FogStart = originalFogStart
    Lighting.FogColor = originalFogColor
end


--- UI Rayfield ---

-- Criar a aba "Entities"
local EntitiesTab = Window:CreateTab("Entities", 4483362458)
local EntitiesSection = EntitiesTab:CreateSection("Opções de Entidades")

-- Anti Searchlights
EntitiesTab:CreateToggle({
    Name = "Anti Searchlights",
    CurrentValue = vals.AntiSearchlights,
    Callback = function(state)
        vals.AntiSearchlights = state
        for _, event in ipairs(searchlights) do
            if event and event.Parent then
                blockInstance(event, "AntiSearchlights")
            end
        end
    end
})
local monstrosDetectados = {}
local nomesMonstros = {
    Angler = true, Pinkie = true, Chainsmoker = true,
    Blitz = true, Pandemonium = true, Froger = true, A60 = true
}

-- Armazenamento para ESPs
local espCurrencyList = {}
local espKeycardList = {}

-- Armazenamento para teleport
local originalPosition = nil
local teleportPlatform = nil

-- Scan inicial e ao adicionar
local function scanRoomObject(obj)
    if vals.ESP_Currency then highlightCurrency(obj) end
    if vals.ESP_Keycard then highlightKeycard(obj) end
end

for _, obj in ipairs(Workspace.GameplayFolder.Rooms:GetDescendants()) do
    scanRoomObject(obj)
end

Workspace.GameplayFolder.Rooms.DescendantAdded:Connect(scanRoomObject)

-- TELEPORTAR PARA O CÉU SE MONSTRO APARECER
local function teleportUp()
    if not character or not HumanoidRootPart then return end
    originalPosition = HumanoidRootPart.Position

    -- Criar plataforma
    teleportPlatform = Instance.new("Part", workspace)
    teleportPlatform.Anchored = true
    teleportPlatform.Size = Vector3.new(20, 2, 20)
    teleportPlatform.Position = originalPosition + Vector3.new(0, 149, 0)
    teleportPlatform.Name = "SafeTeleportPlatform"
    teleportPlatform.Transparency = 0.2
    teleportPlatform.BrickColor = BrickColor.new("Bright green")
    teleportPlatform.Material = Enum.Material.Neon
    teleportPlatform.CanCollide = true

    HumanoidRootPart.CFrame = CFrame.new(originalPosition + Vector3.new(0, 150, 0))
end

local function returnFromTeleport()
    if originalPosition and HumanoidRootPart then
        HumanoidRootPart.CFrame = CFrame.new(originalPosition)
    end
    if teleportPlatform then
        teleportPlatform:Destroy()
        teleportPlatform = nil
    end
end

-- Scan inicial e ao adicionar
local function scanRoomObject(obj)
    if vals.ESP_Currency then highlightCurrency(obj) end
    if vals.ESP_Keycard then highlightKeycard(obj) end
end

for _, obj in ipairs(Workspace.GameplayFolder.Rooms:GetDescendants()) do
    scanRoomObject(obj)
end

-- MONITORAMENTO DE MONSTROS
local function monitorarMonstros(obj)
    if obj:IsA("Part") and nomesMonstros[obj.Name] and not monstrosDetectados[obj] then
        monstrosDetectados[obj] = true
        Rayfield:Notify({
            Title = "Monstro Detectado!",
            Content = "Um " .. obj.Name .. " apareceu!",
            Duration = 10
        })

        if vals.SafeTeleport then
            teleportUp()
        end

        obj.AncestryChanged:Connect(function()
            if not obj:IsDescendantOf(workspace) then
                if vals.SafeTeleport then
                    returnFromTeleport()
                end
                monstrosDetectados[obj] = nil
            end
        end)
    end
end

-- ChildAdded = novo monstro detectado
Workspace.ChildAdded:Connect(function(obj)
    if vals.NotifyMonsters then
        task.wait(0.1)
        monitorarMonstros(obj)
    end
end)

EntitiesTab:CreateToggle({
    Name = "Notificar Monstros",
    CurrentValue = vals.NotifyMonsters,
    Callback = function(state)
        vals.NotifyMonsters = state
        if state then
            for _, obj in ipairs(workspace:GetChildren()) do
                monitorarMonstros(obj)
            end
        else
            monstrosDetectados = {}
        end
    end
})

EntitiesTab:CreateToggle({
    Name = "Safe Teleport ao ver monstro",
    CurrentValue = vals.SafeTeleport,
    Callback = function(state)
        vals.SafeTeleport = state
        Rayfield:Notify({
            Title = "Safe Teleport",
            Content = state and "Ativado." or "Desativado.",
            Duration = 3
        })
    end
})


-- Criar a aba "Player"
local PlayerTab = Window:CreateTab("Player", 4483362458)
local PlayerSection = PlayerTab:CreateSection("Opções do Jogador")

-- No Damage
PlayerTab:CreateToggle({
    Name = "No Damage",
    CurrentValue = vals.NoLocalDamage,
    Callback = function(state)
        vals.NoLocalDamage = state
        local localDamageEvent = Events:FindFirstChild("LocalDamage")
        if localDamageEvent then
            blockInstance(localDamageEvent, "NoLocalDamage")
        else
            Rayfield:Notify({Title = "Aviso", Content = "RemoteEvent 'LocalDamage' não encontrado. No Damage pode não funcionar.", Duration = 3})
        end
    end
})

-- No Death - REVERIFICADO E COLOCADO AQUI
PlayerTab:CreateToggle({
    Name = "Not working",
    CurrentValue = vals.NoDeath,
    Callback = function(state)
        vals.NoDeath = state
        local deathEvent = Events:FindFirstChild("Death")
        if deathEvent then
            blockInstance(deathEvent, "NoDeath")
        else
            Rayfield:Notify({Title = "Aviso", Content = "RemoteEvent 'Death' não encontrado. No Death pode não funcionar.", Duration = 3})
        end
    end
})

-- ESP para Currency (Model)
local function highlightCurrency(model)
    if not model:IsA("Model") or espCurrencyList[model] or not model.Name:lower():find("currency") then return end
    local part = model:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    local gui = Instance.new("BillboardGui", part)
    gui.Name = "CurrencyESP"
    gui.Size = UDim2.new(0, 100, 0, 30)
    gui.AlwaysOnTop = true
    gui.StudsOffset = Vector3.new(0, 2, 0)

    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = "💰 " .. model.Name
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 0)
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true

    espCurrencyList[model] = gui
end

-- ESP para Keycard
local function highlightKeycard(obj)
    if obj:IsA("Model") and obj.Name:lower():find("normalkey") then
        local part = obj:FindFirstChildWhichIsA("BasePart")
        if part and not espKeycardList[obj] then
        local gui = Instance.new("BillboardGui", obj)
        gui.Name = "KeycardESP"
        gui.Size = UDim2.new(0, 100, 0, 30)
        gui.AlwaysOnTop = true
        gui.StudsOffset = Vector3.new(0, 2, 0)

        local label = Instance.new("TextLabel", gui)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = "🔑 " .. obj.Name
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(0, 200, 255)
        label.TextStrokeTransparency = 0.5
        label.Font = Enum.Font.SourceSansBold
        label.TextScaled = true

        espKeycardList[obj] = gui
         end
    end
end
-- Criar a aba "pAinTer"
local pAinTerTab = Window:CreateTab("pAinTer", 4483362458)
local pAinTerSection = pAinTerTab:CreateSection("Ferramentas")

-- Fullbright
pAinTerTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = vals.Fullbright,
    Callback = function(state)
        vals.Fullbright = state
        if state then
            activateFullbright()
            Rayfield:Notify({Title = "Fullbright", Content = "Ativado! O ambiente está totalmente iluminado.", Duration = 3})
        else
            deactivateFullbright()
            Rayfield:Notify({Title = "Fullbright", Content = "Desativado! A iluminação original foi restaurada.", Duration = 3})
        end
    end
})

pAinTerTab:CreateToggle({
    Name = "ESP Currency",
    CurrentValue = vals.ESP_Currency,
    Callback = function(state)
        vals.ESP_Currency = state
        if not state then
            for model, gui in pairs(espCurrencyList) do if gui then gui:Destroy() end end
            espCurrencyList = {}
        else
            for _, obj in ipairs(Workspace.GameplayFolder.Rooms:GetDescendants()) do
                highlightCurrency(obj)
            end
        end
    end
})

pAinTerTab:CreateToggle({
    Name = "ESP Keycards",
    CurrentValue = vals.ESP_Keycard,
    Callback = function(state)
        vals.ESP_Keycard = state
        if not state then
            for obj, gui in pairs(espKeycardList) do if gui then gui:Destroy() end end
            espKeycardList = {}
        else
            for _, obj in ipairs(Workspace.GameplayFolder.Rooms:GetDescendants()) do
                highlightKeycard(obj)
            end
        end
    end
})

-- Valor fixo do alcance da aura
local AUTO_INTERACT_RANGE = 15

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local autoInteractEnabled = false
local interactConnection

local function fireProximityPrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        task.spawn(function()
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.1)
                prompt:InputHoldEnd()
            end)
        end)
    end
end

local function interactWithPromptsInRange()
    if not HumanoidRootPart then return end
    local pos = HumanoidRootPart.Position

    for _, prompt in pairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Parent and prompt.Parent:IsA("BasePart") then
            local part = prompt.Parent
            local distance = (part.Position - pos).Magnitude
            if distance <= AUTO_INTERACT_RANGE then
                fireProximityPrompt(prompt)
            end
        end
    end
end

-- Toggle para ligar/desligar a aura automática
pAinTerTab:CreateToggle({
    Name = "Aura Auto Interact (alcance 15 studs)",
    CurrentValue = false,
    Callback = function(state)
        autoInteractEnabled = state
        if state then
            interactConnection = RunService.Heartbeat:Connect(function()
                interactWithPromptsInRange()
            end)
        else
            if interactConnection then
                interactConnection:Disconnect()
                interactConnection = nil
            end
        end
    end
})