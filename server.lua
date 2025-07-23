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
                                local pagamentoFormatado = ESX.Math.GroupDigits(pagamento)
                                TriggerClientEvent('esx:showNotification', xPlayer.source, 
                                    ("Recebeste ~g~%s€~w~ de rendimento da tua empresa '%s'."):format(pagamentoFormatado, configEmpresa.nome))
                            end
                        else
                            print(("Erro ao tentar adicionar pagamento à empresa '%s'."):format(configEmpresa.nome))
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
                              ("Pagamento de manutenção: ~r~%s€~w~ descontado pela empresa '%s'."):
                              format(ESX.Math.GroupDigits(valorManutencao), configEmpresa.nome))
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
                                  ("A tua empresa '%s' foi à falência após ~r~%d avisos~w~ por falta de pagamento."):
                                  format(configEmpresa.nome, MAX_AVISOS))
                            else
                                TriggerClientEvent('esx:showNotification', xPlayer.source,
                                  ("Não tens dinheiro suficiente para pagar a manutenção da empresa '%s'. ~r~Aviso %d/%d.~w~"):
                                  format(configEmpresa.nome, novosAvisos, MAX_AVISOS))
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
        TriggerClientEvent('esx:showNotification', src, 'Empresa inválida.')
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
                TriggerClientEvent('esx:showNotification', src, 'Esta empresa já tem dono.')
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
        TriggerClientEvent('esx:showNotification', src, '~r~Empresa inválida.~w~')
        return
    end

    MySQL.Async.fetchAll('SELECT * FROM empresas WHERE id = @id', {['@id'] = empresaId}, function(results)
        if not results[1] then
            TriggerClientEvent('esx:showNotification', src, 'Esta empresa ainda não tem dono.')
            return
        end

        local empresaDB = results[1]
        if empresaDB.dono ~= identifier then
            TriggerClientEvent('esx:showNotification', src, 'Só o dono pode gerir esta empresa.')
            return
        end

        local nivelAtual = tonumber(empresaDB.nivel) or 0
        local maxNivel = empresaConfig.maxNivel or 5

        if nivelAtual >= maxNivel then
            TriggerClientEvent('esx:showNotification', src, 'Já atingiste o nível máximo de investimento.')
            return
        end

        local proximoNivel = nivelAtual + 1
        local custo = empresaConfig.investimento[proximoNivel]

        if not custo then
            TriggerClientEvent('esx:showNotification', src, 'Custo do próximo nível não definido.')
            return
        end

        local bankMoney = xPlayer.getAccount('bank').money
        if bankMoney < custo then
            TriggerClientEvent('esx:showNotification', src, 'Não tens dinheiro suficiente para o próximo investimento.')
            return
        end

        xPlayer.removeAccountMoney('bank', custo)

        MySQL.Async.execute('UPDATE empresas SET nivel = @nivel WHERE id = @id', {
            ['@nivel'] = proximoNivel,
            ['@id'] = empresaId
        }, function(rowsChanged)
            TriggerClientEvent('esx:showNotification', src, '~g~Investimento feito!~w~ Agora estás no nível ' .. proximoNivel)
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
        TriggerClientEvent('esx:showNotification', src, "Não tens permissão para ver o dinheiro desta empresa.")
        return
    end

    MySQL.Async.fetchScalar('SELECT dinheiro FROM empresas WHERE id = @id', {["@id"] = empresaId}, function(dinheiro)
        if dinheiro then
            TriggerClientEvent('comprarempresas:abrirCofreEmpresa', src, empresaId, dinheiro, empresa)
        else
            TriggerClientEvent('esx:showNotification', src, "Erro ao obter o dinheiro da empresa.")
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
        TriggerClientEvent('esx:showNotification', src, "Não tens permissão para retirar o dinheiro desta empresa.")
        return
    end

    MySQL.Async.fetchScalar('SELECT dinheiro FROM empresas WHERE id = @id', {["@id"] = empresaId}, function(dinheiro)
        if dinheiro and dinheiro > 0 then
            xPlayer.addAccountMoney('bank', dinheiro)
            MySQL.Async.execute('UPDATE empresas SET dinheiro = 0 WHERE id = @id', {["@id"] = empresaId})
            TriggerClientEvent('esx:showNotification', src, "Retiraste ~g~" .. ESX.Math.GroupDigits(dinheiro) .. "€~w~ do cofre da empresa.")
        else
            TriggerClientEvent('esx:showNotification', src, "Não há dinheiro disponível para retirada.")
        end
    end)
end)

RegisterServerEvent('comprarempresas:comprarEmpresa')
AddEventHandler('comprarempresas:comprarEmpresa', function(empresaId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local empresa = Config.Empresas[empresaId]
    if not empresa then
        TriggerClientEvent('esx:showNotification', src, '~r~Empresa inválida~w~')
        return
    end

    MySQL.Async.fetchAll('SELECT * FROM empresas WHERE id = @id', { ['@id'] = empresaId }, function(results)
        local empresaDB = { dono = '' }
        if results[1] then
            empresaDB.dono = results[1].dono or ''
        end

        if empresaDB.dono ~= '' then
            TriggerClientEvent('esx:showNotification', src, 'Esta empresa já tem dono')
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
                TriggerClientEvent('esx:showNotification', src, '~g~Parabéns!~w~ Compraste a empresa: ' .. empresa.nome)
            end)
        else
            TriggerClientEvent('esx:showNotification', src, 'Não tens dinheiro suficiente')
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
        TriggerClientEvent('esx:showNotification', src, "~r~Empresa inválida.~w~")
        return
    end

    if empresaDB.dono ~= identifier then
        TriggerClientEvent('esx:showNotification', src, "Erro, tenta dar RR")
        return
    end

    local precoVenda = math.floor(empresaConfig.preco * 0.8) -- Percentagem da venda

    empresaDB.dono = ''
    empresaDB.nivel = 0
    empresaDB.avisos = 0

    MySQL.Async.execute('UPDATE empresas SET dono = "", nivel = 0, avisos = 0 WHERE id = @id', {
        ['@id'] = empresaId
    })

    xPlayer.addAccountMoney('bank', precoVenda)
    TriggerClientEvent('esx:showNotification', src, "Vendeste a empresa por ~g~" .. ESX.Math.GroupDigits(precoVenda) .. "€~w~")
end)
