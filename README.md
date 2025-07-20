# 🏢 Comprar Empresas (v1.0) – ESX FiveM

Este script permite aos jogadores adquirir, gerir e lucrar com empresas no servidor FiveM baseado em ESX. Ideal para enriquecer a economia do teu servidor com uma dinâmica de negócios realista e envolvente.

---

## 📌 Funcionalidades Principais

### 🏪 Comprar Empresas
- Jogadores podem adquirir empresas disponíveis que não tenham dono.
- O valor da compra é automaticamente retirado da conta bancária do jogador.
- Após a compra, o jogador torna-se o proprietário e ganha acesso à gestão da empresa.

### 📈 Sistema de Investimento por Níveis
- Cada empresa possui níveis de investimento (de 0 a 5).
- O dono pode pagar para subir de nível, com custos progressivos.
- Níveis mais altos oferecem maiores lucros e vantagens estratégicas.

### 💸 Rendimentos Passivos
- A cada 15 minutos, o proprietário recebe lucros com base no nível atual da empresa.
- O sistema é totalmente automático e integrado no loop do servidor.

### 🛠️ Manutenção e Despesas
- A cada 10 minutos, é cobrado um valor de manutenção da empresa.
- Caso o saldo bancário seja insuficiente, o jogador recebe um aviso.
- Após 3 avisos consecutivos, a empresa entra em falência e é retirada ao dono.

### 🔁 Venda da Empresa
- O proprietário pode vender a empresa a qualquer momento.
- Recebe 80% do valor base da empresa.
- A empresa volta a ficar disponível para novos compradores.

---

## 🛠️ Requisitos
- **ESX Framework**
- Base de dados MySQL

---

## 📂 Instalação

1. Coloca a pasta do script na tua diretoria `resources/`.
2. Adiciona ao `server.cfg`:
   ```bash
   ensure esx_comprarempresas
