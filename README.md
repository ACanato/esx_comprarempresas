# 🏢 Buy Companies (v1.2) – ESX FiveM

This script allows players to acquire, manage, and profit from companies on an ESX-based FiveM server.  
Perfect for enriching your server’s economy with a realistic and engaging business dynamic.

---

## 📌 Main Features

### 🏪 Buy Companies
- Players can acquire available companies that have no owner.
- The purchase price is automatically deducted from the player’s bank account.
- After purchase, the player becomes the owner and gains access to company management.

### 📈 Tiered Investment System
- Each company has investment levels (from 0 to 5).
- The owner can pay to level up, with progressive costs.
- Higher levels offer greater profits and strategic advantages.

### 💸 Passive Income
- Every 15 minutes, the owner receives profits based on the company’s current level.
- The system is fully automated and integrated into the server loop.

### 🛠️ Maintenance and Expenses
- Every 10 minutes, a maintenance fee is charged to the company.
- If the bank balance is insufficient, the player receives a warning.
- After 3 consecutive warnings, the company goes bankrupt and is removed from the owner.

### 🔁 Selling the Company
- The owner can sell the company at any time.
- They receive 80% of the company’s base value.
- The company becomes available again for new buyers.

### 💰 Company Safe
- Company safe system where profits go directly into the safe.
- The owner can access the Company Menu to withdraw accumulated funds from the safe.

### 🏬 Companies Available
- Purchasable companies scattered across the map. (Store, Coffee, Dealership)

### 🌐 Multiple Language Support
- The script supports Portuguese, English, Spanish, and French.

---

## 🛠️ Requirements
- **ESX Framework**
- es_extended 1.1
- MySQL database

---

## 📂 Installation

1. Place the script folder in your `resources/` directory.
2. Add to your `server.cfg`:
   ```bash
   ensure esx_comprarempresas
