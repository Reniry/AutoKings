# 🛡️ AutoKings

**AutoKings** is a lightweight addon for **World of Warcraft 1.12** that automatically casts **Greater Blessing of Kings** on the **most populated class within range** of the paladin for make aggro.

It helps optimize blessing distribution in groups and raids by targeting the class with the highest number of nearby players.

---

## ⚙️ Features

- Detects which class has the most players in range.
- Automatically casts **Greater Blessing of Kings** on that class.
- Customizable action bar slot for the spell.
- Works in both party and raid environments.
- Simple, efficient, and made for Turtle WoW.

---

## 🧙 Commands

| Command | Description |
|--------|-------------|
| `/script CastKings()` | Casts the blessing on the class with the most players in range. |
| `/script AutoKingsSlot = X` | Sets the **action bar slot** where **Greater Blessing of Kings** is placed. Default is slot **12**. |
| Dont work ATM`/autokings` | Casts the blessing on the class with the most players in range. |
| Dont work ATM`/autokings slot [number]` | Sets the **action bar slot** where **Greater Blessing of Kings** is placed. Default is slot **12**. |

> 💡 **Example:**  
> If the spell is on action button 6, type:  
> `/autokings slot 6`  
> or  
> `/script AutoKingsSlot = 6`

---

## 📦 Installation

1. Download or clone the repository:
   ```bash
   git clone https://github.com/Reniry/AutoKings.git
