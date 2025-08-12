ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local INTERVALO_MANUTENCAO = 10 -- minutos
local MAX_AVISOS = 3

local empresasDB = {}

MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT * FROM empresas', {}, function(results)
        for _, row in ipairs(results) do
            empresasDB[row.id] = {
                dono = row.dono,
                nivel = tonumber(row.nivel) or 0,
                avisos = tonumber(row.avisos) or 0
            }
        end
    end)
end)

-- RENDIMENTO EMPRESA
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.intervaloPagamento * 60 * 1000)
        for empresaId, empresaData in pairs(empresasDB) do
            if empresaData.dono and empresaData.dono ~= '' then
                local configEmpresa = Config.Empresas[empresaId]
                if not configEmpresa then goto continue end
                local nivel = empresaData.nivel or 0
                local pagamento = configEmpresa.pagamentoPorNivel[nivel]

                if pagamento ~= nil then
                    MySQL.Async.execute('UPDATE empresas SET dinheiro = dinheiro + @pagamento WHERE id = @id', {
                        ['@pagamento'] = pagamento,
                        ['@id'] = empresaId
                    }, function(rowsChanged)
                        if rowsChanged > 0 then
                            local xPlayer = ESX.GetPlayerFromIdentifier(empresaData.dono)
                            if xPlayer then
                                TriggerClientEvent('esx:showNotification', xPlayer.source, 
                                    _U('income_notification', ESX.Math.GroupDigits(pagamento), configEmpresa.nome))
                            end
                        else
                            print(_U('error_add_payment', configEmpresa.nome))
                        end
                    end)
                end
                ::continue::
            end
        end
    end
end)

-- MANUTENÇÃO / AVISOS
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(INTERVALO_MANUTENCAO * 60 * 1000)
        for empresaId, empresaData in pairs(empresasDB) do
            if empresaData.dono and empresaData.dono ~= '' then
                local configEmpresa = Config.Empresas[empresaId]
                if not configEmpresa then goto continue end
                local valorManutencao = configEmpresa.manutencao or 0
                if valorManutencao > 0 then
                    local xPlayer = ESX.GetPlayerFromIdentifier(empresaData.dono)
                    if xPlayer then
                        local bankMoney = xPlayer.getAccount('bank').money
                        local avisosAtuais = empresaData.avisos or 0
                        if bankMoney >= valorManutencao then
                            xPlayer.removeAccountMoney('bank', valorManutencao)
                            TriggerClientEvent('esx:showNotification', xPlayer.source,
                              _U('maintenance_payment_notification', ESX.Math.GroupDigits(valorManutencao), configEmpresa.nome))
                        else
                            local novosAvisos = avisosAtuais + 1
                            empresaData.avisos = novosAvisos
                            MySQL.Async.execute('UPDATE empresas SET avisos = @avisos WHERE id = @id', {
                                ['@avisos'] = novosAvisos,
                                ['@id'] = empresaId
                            })
                            if novosAvisos >= MAX_AVISOS then
                                empresaData.dono = ''
                                empresaData.nivel = 0
                                empresaData.avisos = 0
                                MySQL.Async.execute('UPDATE empresas SET dono = "", nivel = 0, avisos = 0 WHERE id = @id', {
                                    ['@id'] = empresaId
                                })
                                TriggerClientEvent('esx:showNotification', xPlayer.source,
                                  _U('bankruptcy_notification', configEmpresa.nome, MAX_AVISOS))
                            else
                                TriggerClientEvent('esx:showNotification', xPlayer.source,
                                  _U('maintenance_warning_notification', configEmpresa.nome, novosAvisos, MAX_AVISOS))
                            end
                        end
                    end
                end
            end
            ::continue::
        end
    end
end)

RegisterServerEvent('comprarempresas:abrirMenu')
AddEventHandler('comprarempresas:abrirMenu', function(empresaId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.identifier
    local empresa = Config.Empresas[empresaId]

    if not empresa then
        TriggerClientEvent('esx:showNotification', src, _U('invalid_company'))
        return
    end

    MySQL.Async.fetchAll('SELECT * FROM empresas WHERE id = @id', { ['@id'] = empresaId }, function(results)
        local empresaDB = { dono = '', nivel = 0 }
        if results[1] then
            empresaDB.dono = results[1].dono or ''
            empresaDB.nivel = tonumber(results[1].nivel) or 0
            empresaDB.avisos = tonumber(results[1].avisos) or 0
        end

        if empresaDB.dono == '' then
            TriggerClientEvent('comprarempresas:abrirMenuCompra', src, empresaId, empresa)
        else
            local isDono = (empresaDB.dono == identifier)
            if isDono then
                empresa.nivel = empresaDB.nivel or 0
                empresa.avisos = empresaDB.avisos or 0
                TriggerClientEvent('comprarempresas:abrirMenuCliente', src, empresaId, empresa, true)
            else
                TriggerClientEvent('esx:showNotification', src, _U('company_already_owned'))
            end
        end
    end)
end)

RegisterServerEvent('comprarempresas:subirNivel')
AddEventHandler('comprarempresas:subirNivel', function(empresaId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.identifier
    local empresaConfig = Config.Empresas[empresaId]

    if not empresaConfig then
        TriggerClientEvent('esx:showNotification', src, _U('invalid_company'))
        return
    end

    MySQL.Async.fetchAll('SELECT * FROM empresas WHERE id = @id', {['@id'] = empresaId}, function(results)
        if not results[1] then
            TriggerClientEvent('esx:showNotification', src, _U('company_not_owned'))
            return
        end

        local empresaDB = results[1]
        if empresaDB.dono ~= identifier then
            TriggerClientEvent('esx:showNotification', src, _U('only_owner_can_manage'))
            return
        end

        local nivelAtual = tonumber(empresaDB.nivel) or 0
        local maxNivel = empresaConfig.maxNivel or 5

        if nivelAtual >= maxNivel then
            TriggerClientEvent('esx:showNotification', src, _U('max_level_investment'))
            return
        end

        local proximoNivel = nivelAtual + 1
        local custo = empresaConfig.investimento[proximoNivel]

        if not custo then
            TriggerClientEvent('esx:showNotification', src, _U('next_level_cost_not_defined'))
            return
        end

        local bankMoney = xPlayer.getAccount('bank').money
        if bankMoney < custo then
            TriggerClientEvent('esx:showNotification', src, _U('not_enough_money'))
            return
        end

        xPlayer.removeAccountMoney('bank', custo)

        MySQL.Async.execute('UPDATE empresas SET nivel = @nivel WHERE id = @id', {
            ['@nivel'] = proximoNivel,
            ['@id'] = empresaId
        }, function(rowsChanged)
            TriggerClientEvent('esx:showNotification', src, _U('investment_successful', proximoNivel))
        end)
    end)
end)

-- Dinheiro empresa
RegisterServerEvent('comprarempresas:verDinheiro')
AddEventHandler('comprarempresas:verDinheiro', function(empresaId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.identifier
    local empresa = Config.Empresas[empresaId]
    
    local empresaData = empresasDB[empresaId]
    if not empresaData or empresaData.dono ~= identifier then
        TriggerClientEvent('esx:showNotification', src, _U('no_permission_to_view_money'))
        return
    end

    MySQL.Async.fetchScalar('SELECT dinheiro FROM empresas WHERE id = @id', {["@id"] = empresaId}, function(dinheiro)
        if dinheiro then
            TriggerClientEvent('comprarempresas:abrirCofreEmpresa', src, empresaId, dinheiro, empresa)
        else
            TriggerClientEvent('esx:showNotification', src, _U('error_getting_money'))
        end
    end)
end)

RegisterServerEvent('comprarempresas:retirarDinheiro')
AddEventHandler('comprarempresas:retirarDinheiro', function(empresaId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.identifier
    
    local empresaData = empresasDB[empresaId]
    if not empresaData or empresaData.dono ~= identifier then
        TriggerClientEvent('esx:showNotification', src, _U('no_permission_to_withdraw'))
        return
    end

    MySQL.Async.fetchScalar('SELECT dinheiro FROM empresas WHERE id = @id', {["@id"] = empresaId}, function(dinheiro)
        if dinheiro and dinheiro > 0 then
            xPlayer.addAccountMoney('bank', dinheiro)
            MySQL.Async.execute('UPDATE empresas SET dinheiro = 0 WHERE id = @id', {["@id"] = empresaId})
            TriggerClientEvent('esx:showNotification', src, _U('money_withdrawn', ESX.Math.GroupDigits(dinheiro)))
        else
            TriggerClientEvent('esx:showNotification', src, _U('no_money_to_withdraw'))
        end
    end)
end)

RegisterServerEvent('comprarempresas:comprarEmpresa')
AddEventHandler('comprarempresas:comprarEmpresa', function(empresaId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local empresa = Config.Empresas[empresaId]
    if not empresa then
        TriggerClientEvent('esx:showNotification', src, _U('invalid_company'))
        return
    end

    MySQL.Async.fetchAll('SELECT * FROM empresas WHERE id = @id', { ['@id'] = empresaId }, function(results)
        local empresaDB = { dono = '' }
        if results[1] then
            empresaDB.dono = results[1].dono or ''
        end

        if empresaDB.dono ~= '' then
            TriggerClientEvent('esx:showNotification', src, _U('company_already_owned'))
            return
        end

        local preco = empresa.preco
        local bankMoney = xPlayer.getAccount('bank').money

        if bankMoney >= preco then
            xPlayer.removeAccountMoney('bank', preco)
            MySQL.Async.execute([[
                INSERT INTO empresas (id, dono, nivel, avisos)
                VALUES (@id, @dono, 0, 0)
                ON DUPLICATE KEY UPDATE dono = @dono
            ]],
            {
                ['@id'] = empresaId,
                ['@dono'] = xPlayer.identifier
            }, function(rowsChanged)
                empresasDB[empresaId] = {
                    dono = xPlayer.identifier,
                    nivel = 0,
                    avisos = 0
                }
                TriggerClientEvent('esx:showNotification', src, _U('congratulations_bought', empresa.nome))
            end)
        else
            TriggerClientEvent('esx:showNotification', src, _U('not_enough_money_buy'))
        end
    end)
end)

RegisterServerEvent('comprarempresas:venderEmpresa')
AddEventHandler('comprarempresas:venderEmpresa', function(empresaId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.identifier
    local empresaDB = empresasDB[empresaId]
    local empresaConfig = Config.Empresas[empresaId]

    if not empresaDB or not empresaConfig then
        TriggerClientEvent('esx:showNotification', src, _U('invalid_company'))
        return
    end

    if empresaDB.dono ~= identifier then
        TriggerClientEvent('esx:showNotification', src, _U('sale_error'))
        return
    end

    local precoVenda = math.floor(empresaConfig.preco * 0.8)

    empresaDB.dono = ''
    empresaDB.nivel = 0
    empresaDB.avisos = 0

    MySQL.Async.execute('UPDATE empresas SET dono = "", nivel = 0, avisos = 0 WHERE id = @id', {
        ['@id'] = empresaId
    })

    xPlayer.addAccountMoney('bank', precoVenda)
    TriggerClientEvent('esx:showNotification', src, _U('company_sold', ESX.Math.GroupDigits(precoVenda)))
end)
