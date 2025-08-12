ESX = nil
local menuAberto = false
local empresaPos = nil
local DISTANCIA_FECHAR_MENU = 1.5

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local sleep = 1000
        for id, empresa in pairs(Config.Empresas) do
            local dist = #(playerCoords - empresa.coords)
            if dist < Config.Marker.drawDistance then
                sleep = 0
                DrawMarker(
                    Config.Marker.type,
                    empresa.coords.x, empresa.coords.y, empresa.coords.z - 0.9,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    Config.Marker.size.x, Config.Marker.size.y, Config.Marker.size.z,
                    Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b,
                    100, false, true, 2, nil, nil, false
                )
                if dist < 1.5 and not menuAberto then
                    SetTextComponentFormat("STRING")
                    AddTextComponentString(_U('menu_access'))
                    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                    if IsControlJustReleased(0, 38) then
                        menuAberto = true
                        empresaPos = empresa.coords
                        TriggerServerEvent('comprarempresas:abrirMenu', id)
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        if menuAberto and empresaPos then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - empresaPos)

            if dist > DISTANCIA_FECHAR_MENU then
                ESX.UI.Menu.CloseAll()
                menuAberto = false
                empresaPos = nil
                ESX.ShowNotification(_U('left_company_area'))
            end
        else
            Citizen.Wait(1000)
        end
    end
end)

RegisterNetEvent('comprarempresas:abrirMenuCliente')
AddEventHandler('comprarempresas:abrirMenuCliente', function(empresaId, empresa, isDono)
    local elements = {}

    if isDono then   
        table.insert(elements, {label = _U('warnings_label', empresa.avisos or 0), value = "info_avisos", disabled = true})
        table.insert(elements, {label = _U('current_investment_label', empresa.nivel or 0), value = "info_nivel", disabled = true})
        table.insert(elements, {label = _U('company_vault_label'), value = "ver_dinheiro"})
        if empresa.nivel < (Config.Empresas[empresaId].maxNivel or 5) then
            local proximoNivel = (empresa.nivel or 0) + 1
            local custo = Config.Empresas[empresaId].investimento[proximoNivel]
            table.insert(elements, {label = _U('make_investment_label', proximoNivel, ESX.Math.GroupDigits(custo)), value = "subir_nivel"})
        else
            table.insert(elements, {label = _U('max_level_reached'), value = "nil", disabled = true})
        end
        table.insert(elements, {label = "-----------------------------------------", value = ""})
        local precoVenda = math.floor(empresa.preco * 0.8)
        table.insert(elements, {label = _U('sell_company_label', ESX.Math.GroupDigits(precoVenda)), value = "vender_empresa"})
    end

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'menu_empresa_'..empresaId, {
        title = empresa.nome,
        align = 'left',
        elements = elements
    }, function(data, menu)
        if data.current.value == "subir_nivel" then
            TriggerServerEvent('comprarempresas:subirNivel', empresaId)
            menu.close()
            menuAberto = false
        elseif data.current.value == "ver_dinheiro" then    
            TriggerServerEvent('comprarempresas:verDinheiro', empresaId)
        elseif data.current.value == "vender_empresa" then    
            ESX.UI.Menu.CloseAll()
            menu.close()
            menuAberto = false

            TriggerServerEvent('comprarempresas:venderEmpresa', empresaId)
        end
    end, function(data, menu)
        menu.close()
        menuAberto = false
    end)
end)

RegisterNetEvent('comprarempresas:abrirMenuCompra')
AddEventHandler('comprarempresas:abrirMenuCompra', function(empresaId, empresa)
    ESX.UI.Menu.CloseAll()
    local elements = {
        {label = _U('buy_company_label', ESX.Math.GroupDigits(empresa.preco)), value = "comprar"},
        {label = _U('close_label'), value = "fechar"}
    }
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'menu_compra_empresa', {
        title = _U('buy_company_title', empresa.nome),
        align = 'left',
        elements = elements
    }, function(data, menu)
        if data.current.value == 'comprar' then
            TriggerServerEvent('comprarempresas:comprarEmpresa', empresaId)
            menu.close()
            menuAberto = false
            empresaPos = nil
        elseif data.current.value == 'fechar' then
            menu.close()
            menuAberto = false
            empresaPos = nil
        end
    end, function(data, menu)
        menu.close()
        menuAberto = false
        empresaPos = nil
    end)
end)

RegisterNetEvent('comprarempresas:abrirCofreEmpresa')
AddEventHandler('comprarempresas:abrirCofreEmpresa', function(empresaId, dinheiro, empresa)
    local elements = {
        {label = _U('vault_money_label', ESX.Math.GroupDigits(dinheiro)), value = nil, disabled = true},
        {label = _U('withdraw_money_label'), value = "retirar_dinheiro"}
    }

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'menu_cofre_empresa', {
        title = _U('company_vault_title', empresa.nome),
        align = 'left',
        elements = elements
    }, function(data, menu)
        if data.current.value == 'retirar_dinheiro' then
            TriggerServerEvent('comprarempresas:retirarDinheiro', empresaId)
            menu.close()
        end
    end, function(data, menu)
        menu.close()
    end)
end)
