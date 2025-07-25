Config = {}

Config.Marker = {
    type         = 20,
    size         = vector3(1.0, 1.0, 1.0),
    color        = { r = 50, g = 50, b = 204 },
    drawDistance = 20.0
}

Config.intervaloPagamento = 15 -- minutos

Config.Empresas = {
    ['loja'] = {
        nome         = 'Loja',
        tipo         = 'loja',
        coords       = vector3(28.23, -1339.41, 30.5),
        preco        = 550000,
        investimento = {
            [1] = 100000,
            [2] = 150000,
            [3] = 200000,
            [4] = 300000,
            [5] = 500000
        },
        maxNivel = 5,
        pagamentoPorNivel = {
            [0] = 5000,
            [1] = 10000,
            [2] = 20000,
            [3] = 35000,
            [4] = 50000,
            [5] = 75000
        },
        manutencao = 2500 -- Preço
    }
}
