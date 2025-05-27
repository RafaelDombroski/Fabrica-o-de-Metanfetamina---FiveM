local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")

local isNuiOpen = false
local currentBlip = nil
local lastProduction = 0
local activeProductions = {}
local pendingProductions = {} -- Para controlar produções pendentes
local isCollectingRoute = false
local currentCollectIndex = 0
local collectBlip = nil

-- Criar blips
Citizen.CreateThread(function()
    if Config.Settings.enableBlips then
        for _, blipData in pairs(Config.Blips) do
            local blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
            SetBlipSprite(blip, blipData.sprite)
            SetBlipColour(blip, blipData.color)
            SetBlipScale(blip, blipData.scale)
            SetBlipAsShortRange(blip, blipData.shortRange)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(blipData.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Criar blip de início da rota
Citizen.CreateThread(function()
    local cfg = Config.CollectRoute.start
    local blip = AddBlipForCoord(cfg.x, cfg.y, cfg.z)
    SetBlipSprite(blip, 514)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Iniciar Rota de Coleta")
    EndTextCommandSetBlipName(blip)
end)

-- Thread principal para verificar proximidade
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        for _, blipData in pairs(Config.Blips) do
            local distance = #(playerCoords - blipData.coords)
            
            if distance <= Config.Settings.maxDistance then
                sleep = 0
                
                -- Desenhar texto 3D
                DrawText3D(blipData.coords.x, blipData.coords.y, blipData.coords.z + 1.0, 
                    "[~b~E~w~] Abrir Laboratório")
                
                -- Verificar input
                if IsControlJustPressed(0, 38) then -- E key
                    if not isNuiOpen then
                        OpenChemicalLab()
                    end
                end
            elseif isNuiOpen and distance > Config.Settings.maxDistance then
                -- Fechar NUI se o jogador se afastar
                CloseChemicalLab()
                TriggerEvent('Notify', "importante", "Você se afastou muito do laboratório!")
            end
        end
        
        Citizen.Wait(sleep)
    end
end)

-- Thread para interação com o ponto de início da rota
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if not isCollectingRoute then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local start = Config.CollectRoute.start
            local dist = #(coords - vector3(start.x, start.y, start.z))
            if dist < 2.0 then
                sleep = 0
                DrawText3D(start.x, start.y, start.z + 1.0, "[~b~E~w~] Iniciar Rota de Coleta")
                if IsControlJustPressed(0, 38) then
                    StartCollectRoute()
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

-- Função para desenhar texto 3D
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
    end
end

-- Abrir laboratório químico
function OpenChemicalLab()
    if GetGameTimer() - lastProduction < Config.Settings.cooldownTime then
        TriggerEvent('Notify', "negado", "Aguarde antes de iniciar uma nova produção!")
        return
    end

    -- Checa permissão no servidor antes de abrir a NUI
    TriggerServerEvent('chemical:checkPermission')
end

-- Recebe resposta do servidor sobre permissão
RegisterNetEvent('chemical:permissionResult')
AddEventHandler('chemical:permissionResult', function(allowed)
    if allowed then
        isNuiOpen = true
        SetNuiFocus(true, true)

        -- Enviar receitas para a NUI
        local recipes = {}
        for _, recipe in pairs(Config.Recipes) do
            table.insert(recipes, {
                id = recipe.id,
                name = recipe.name,
                purity = recipe.purity,
                ingredients = recipe.ingredients,
                productionTime = recipe.productionTime * 1000 -- Converter para ms
            })
        end

        SendNUIMessage({
            action = "openLab",
            recipes = recipes
        })
    else
        TriggerEvent('Notify', "negado", "Você não tem permissão para usar este laboratório!")
    end
end)

-- Fechar laboratório químico
function CloseChemicalLab()
    isNuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "closeLab"
    })
end

function StartCollectRoute()
    isCollectingRoute = true
    currentCollectIndex = 1
    TriggerEvent('Notify', "importante", "Rota de coleta iniciada!")
    SetNextCollectBlip()
end

function SetNextCollectBlip()
    if collectBlip then
        RemoveBlip(collectBlip)
        collectBlip = nil
    end
    local point = Config.CollectRoute.points[currentCollectIndex]
    if point then
        collectBlip = AddBlipForCoord(point.x, point.y, point.z)
        SetBlipSprite(collectBlip, Config.CollectBlip.sprite)
        SetBlipColour(collectBlip, Config.CollectBlip.color)
        SetBlipScale(collectBlip, Config.CollectBlip.scale)
        SetBlipAsShortRange(collectBlip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.CollectBlip.name)
        EndTextCommandSetBlipName(collectBlip)
    end
end

-- Callbacks da NUI
RegisterNUICallback('closeLab', function(data, cb)
    CloseChemicalLab()
    cb('ok')
end)

RegisterNUICallback('startProduction', function(data, cb)
    local recipeId = data.recipeId
    
    -- Verificar se a receita existe
    local recipe = nil
    for _, r in pairs(Config.Recipes) do
        if r.id == recipeId then
            recipe = r
            break
        end
    end
    
    if not recipe then
        cb({success = false, message = "Receita não encontrada!"})
        return
    end
    
    -- Gerar ID único para esta produção
    local productionId = tostring(GetGameTimer())
    
    -- Adicionar à lista de produções pendentes
    pendingProductions[productionId] = {
        recipe = recipe,
        callback = cb
    }
    
    print(string.format("[CHEMICAL DEBUG] Verificando ingredientes para produção %s", productionId))
    
    -- Verificar ingredientes no servidor
    TriggerServerEvent('chemical:checkIngredients', recipe.ingredients, productionId)
end)

RegisterNUICallback('cancelProduction', function(data, cb)
    local productionId = data.productionId
    
    if activeProductions[productionId] then
        activeProductions[productionId] = nil
        TriggerEvent('Notify', "importante", "Produção cancelada!")
    end
    
    cb('ok')
end)

-- Completar produção
function CompleteProduction(productionId)
    local production = activeProductions[productionId]
    if not production then return end
    
    local recipe = production.recipe
    
    -- Dar item ao jogador no servidor
    TriggerServerEvent('chemical:completeProduction', recipe.output.item, recipe.output.amount)
    
    -- Remover da lista de produções ativas
    activeProductions[productionId] = nil
    
    -- Notificar NUI sobre conclusão
    SendNUIMessage({
        action = "productionCompleted",
        productionId = productionId
    })
end

-- Evento para resultado da verificação de ingredientes
RegisterNetEvent('chemical:ingredientsResult')
AddEventHandler('chemical:ingredientsResult', function(hasItems, productionId, message)
    print(string.format("[CHEMICAL DEBUG] Resultado ingredientes - ID: %s, Tem itens: %s, Mensagem: %s", productionId, tostring(hasItems), message))
    
    local pendingProduction = pendingProductions[productionId]
    if not pendingProduction then
        print("[CHEMICAL DEBUG] Produção pendente não encontrada!")
        return
    end
    
    local recipe = pendingProduction.recipe
    local cb = pendingProduction.callback
    
    -- Remover da lista de pendentes
    pendingProductions[productionId] = nil
    
    if hasItems then
        -- Iniciar produção
        activeProductions[productionId] = {
            recipe = recipe,
            startTime = GetGameTimer(),
            duration = recipe.productionTime * 1000
        }
        
        lastProduction = GetGameTimer()
        
        -- Timer para completar produção
        Citizen.SetTimeout(recipe.productionTime * 1000, function()
            CompleteProduction(productionId)
        end)
        
        cb({success = true, productionId = productionId})
        print(string.format("[CHEMICAL DEBUG] Produção %s iniciada com sucesso!", productionId))
    else
        cb({success = false, message = message})
        print(string.format("[CHEMICAL DEBUG] Produção %s falhou: %s", productionId, message))
    end
end)

-- Eventos
RegisterNetEvent('chemical:productionCompleted')
AddEventHandler('chemical:productionCompleted', function(itemName, amount)
    -- Notificação já é enviada pelo servidor
end)

-- Fechar NUI com ESC
Citizen.CreateThread(function()
    while true do
        if isNuiOpen then
            if IsControlJustPressed(0, 322) then -- ESC key
                CloseChemicalLab()
            end
        end
        Citizen.Wait(0)
    end
end)

-- Thread para interação com pontos de coleta
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if isCollectingRoute and currentCollectIndex > 0 then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local point = Config.CollectRoute.points[currentCollectIndex]
            if point then
                local dist = #(coords - vector3(point.x, point.y, point.z))
                if dist < 30.0 then
                    sleep = 0
                    DrawMarker(1, point.x, point.y, point.z - 1.0, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.0, 46, 204, 113, 120, false, false, 2, false, nil, nil, false)
                    if dist < 2.0 then
                        DrawText3D(point.x, point.y, point.z + 1.0, "[~b~E~w~] Coletar Composito")
                        if IsControlJustPressed(0, 38) then
                            local amount = math.random(1, 7)
                            TriggerServerEvent("chemical:giveComposito", amount)
                            TriggerEvent('Notify', "sucesso", "Você coletou "..amount.."x composito.")
                            currentCollectIndex = currentCollectIndex + 1
                            if currentCollectIndex > #Config.CollectRoute.points then
                                TriggerEvent('Notify', "sucesso", "Rota de coleta finalizada!")
                                isCollectingRoute = false
                                currentCollectIndex = 0
                                if collectBlip then RemoveBlip(collectBlip) collectBlip = nil end
                            else
                                SetNextCollectBlip()
                            end
                        end
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

-- (todo o código de interação com NUI, blips, player, etc, já está correto aqui)