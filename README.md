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
| `/ak` | Displays this help message in-game |
| `/autokings slot [number]` | Sets the **action bar slot** where **Greater Blessing of Kings** is placed. Default is slot **12**. |
| `/autokings` | Casts the blessing on the class with the most players in range. |
| `/script AutoKingsSlot = X` | Sets the **action bar slot** where **Greater Blessing of Kings** is placed. Default is slot **12**. |
| `/script CastKings()` | Casts the blessing on the class with the most players in range. |

> 💡 **Example:**  
> If the spell is on action button 6, type:  
> `/autokings slot 6`  
> or  
> `/script AutoKingsSlot = 6`

Here you can see where the **ActionID slots** are located on your action bars:

| Action Bar               | Slot Range  |
|--------------------------|-------------|
| Action Bar Page 1        | 1–12        |
| Action Bar Page 2        | 13–24       |
| Right Action Bar (Page 3)| 25–36       |
| Right Action Bar 2 (Page 4) | 37–48    |
| Bottom Right Action Bar (Page 5) | 49–60 |
| Bottom Left Action Bar (Page 6)  | 61–72 |

Make sure **Greater Blessing of Kings** is placed in one of these slots, and tell the addon which one by using `/autokings slot X`. 
---

## 💾 Persistence

Your chosen action slot is saved automatically and will persist across sessions.

---

## 📦 Installation

1. Download the release ZIP:
   `https://github.com/Reniry/AutoKings/archive/refs/heads/main.zip`

2. Extract into your Interface/AddOns folder
   → Path: `World of Warcraft\_classic_\Interface\AddOns\AutoKings`

3. Ensure the folder is named exactly `AutoKings`

4. Restart WoW or type `/reload` in-game

---

## 👤 Author

Created by **Reniry**  
Version: **1.0.1**

---

## 📜 License

This project is licensed under the MIT License. See [LICENSE.txt](LICENSE.txt) for details.