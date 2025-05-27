Config = {}

-- Configurações dos Blips
Config.Blips = {
    {
        coords = vector3(1389.9, 3608.67, 38.70-1.0),
        sprite = 499, -- Ícone do blip (laboratório)
        color = 1, -- Cor vermelha
        scale = 0.8,
        name = "Laboratório Químico",
        shortRange = true
    }
    -- Adicione mais blips aqui se necessário
    -- {
    --     coords = vector3(x, y, z),
    --     sprite = 499,
    --     color = 1,
    --     scale = 0.8,
    --     name = "Laboratório Químico 2",
    --     shortRange = true
    -- }
}

-- Configurações das Receitas
Config.Recipes = {
    {
        id = "metanfetamina",
        name = "Metanfetamina",
        purity = "99,9%",
        productionTime = 10, -- em segundos
        ingredients = {
            {
                item = "composito",
                amount = 5,
                label = "Composito x5"
            }
        },
        output = {
            item = "metanfetamina",
            amount = 1
        }
    }
    -- Adicione mais receitas aqui
    -- {
    --     id = "cocaina_pura",
    --     name = "Cocaína Pura",
    --     purity = "95%",
    --     productionTime = 15,
    --     ingredients = {
    --         {
    --             item = "folha_coca",
    --             amount = 3,
    --             label = "Folha de Coca"
    --         },
    --         {
    --             item = "acido_sulfurico",
    --             amount = 1,
    --             label = "Ácido Sulfúrico"
    --         }
    --     },
    --     output = {
    --         item = "cocaina_pura",
    --         amount = 2
    --     }
    -- }
}

-- Configurações Gerais
Config.Settings = {
    maxDistance = 3.0, -- Distância máxima para abrir a NUI
    cooldownTime = 2000, -- Cooldown entre produções (ms)
    enableBlips = true, -- Habilitar/desabilitar blips
    enableNotifications = true, -- Habilitar/desabilitar notificações
    requiredPermission = "suporte.permissao" -- Permissão necessária para usar o laboratório
}

-- Mensagens
Config.Messages = {
    ["not_enough_items"] = "Você não possui os ingredientes necessários!",
    ["production_started"] = "Produção iniciada com sucesso!",
    ["production_completed"] = "Produção concluída! Você recebeu: %s x%d",
    ["production_cancelled"] = "Produção cancelada!",
    ["too_far"] = "Você está muito longe do laboratório!",
    ["cooldown_active"] = "Aguarde antes de iniciar uma nova produção!",
    ["inventory_full"] = "Seu inventário está cheio!"
}

Config.CollectRoute = {
    start = { x = 1395.05, y = 3613.95, z = 34.99 }, -- Blip para iniciar rota (Sandy Shores)
    points = {
        -- Próximo ao laboratório (Sandy Shores)
        { x = 1360.0, y = 3600.0, z = 34.0 },
        -- Saindo de Sandy Shores
        { x = 1700.0, y = 3290.0, z = 41.0 },
        -- Próximo à rodovia
        { x = 2000.0, y = 3050.0, z = 47.0 },
        -- Chegando em Grapeseed
        { x = 2440.0, y = 4970.0, z = 46.0 },
        -- Próximo ao Lago Zancudo
        { x = 1550.0, y = 4370.0, z = 44.0 },
        -- Próximo à rodovia sentido cidade
        { x = 1040.0, y = 2650.0, z = 39.0 },
        -- Entrada de Los Santos (perto do aeroporto)
        { x = -1037.0, y = -2738.0, z = 20.0 },
        -- Centro de Los Santos
        { x = 215.0, y = -810.0, z = 30.0 },
        -- Perto da praça central
        { x = -425.0, y = -278.0, z = 35.0 }
        -- Adicione/remova pontos conforme desejar
    }
}

Config.CollectBlip = {
    sprite = 501,
    color = 46,
    scale = 0.7,
    name = "Coleta de Composito"
}