local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")

-- Evento para checar ingredientes
RegisterNetEvent('chemical:checkIngredients')
AddEventHandler('chemical:checkIngredients', function(ingredients, productionId)
    local source = source
    local user_id = vRP.getUserId(source)
    local hasAll = true
    local message = ""

    -- Checa se o jogador tem todos os ingredientes
    for _, ingredient in pairs(ingredients) do
        local amount = vRP.getInventoryItemAmount(user_id, ingredient.item)
        if amount < ingredient.amount then
            hasAll = false
            message = "Você não possui os ingredientes necessários!"
            TriggerClientEvent('Notify', source, "negado", "Faltam ingredientes: "..ingredient.item.." ("..amount.."/"..ingredient.amount..")")
            break
        end
    end

    -- Se tiver, remove os ingredientes
    if hasAll then
        for _, ingredient in pairs(ingredients) do
            local ok = vRP.tryGetInventoryItem(user_id, ingredient.item, ingredient.amount)
            if ok then
                TriggerClientEvent('Notify', source, "sucesso", "Ingrediente removido: "..ingredient.item.." x"..ingredient.amount)
            else
                TriggerClientEvent('Notify', source, "negado", "Erro ao remover: "..ingredient.item)
            end
        end
    end

    TriggerClientEvent('chemical:ingredientsResult', source, hasAll, productionId, message)
end)

-- Evento para completar produção
RegisterNetEvent('chemical:completeProduction')
AddEventHandler('chemical:completeProduction', function(item, amount)
    local source = source
    local user_id = vRP.getUserId(source)
    vRP.giveInventoryItem(user_id, item, amount)
    TriggerClientEvent('Notify', source, "sucesso", "Produção concluída! Você recebeu: "..item.." x"..amount)
end)

RegisterNetEvent('chemical:checkPermission')
AddEventHandler('chemical:checkPermission', function()
    local source = source
    local user_id = vRP.getUserId(source)
    local allowed = false

    if user_id and vRP.hasPermission(user_id, Config.Settings.requiredPermission) then
        allowed = true
    end

    TriggerClientEvent('chemical:permissionResult', source, allowed)
end)

RegisterNetEvent('chemical:giveComposito')
AddEventHandler('chemical:giveComposito', function(amount)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        vRP.giveInventoryItem(user_id, "composito", amount)
    end
end)