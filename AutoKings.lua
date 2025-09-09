-- AutoKings v1.1 - Optimized Professional Version
-- Author: Enhanced by Reniry
-- Compatible with WoW 1.12 (Turtle WoW)

AutoKingsSlot = 12
AutoKingsDebug = false
AutoKingsCache = {
    data = {},
    lastUpdate = 0,
    duration = 2 -- segundos de caché
}

-- ========================================
-- FUNCIONES DE UTILIDAD
-- ========================================
local function AutoKings_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AutoKings]|r " .. tostring(msg))
end

local function GetCurrentTime()
    -- En WoW 1.12 no existe GetTime(), usamos GetFramerate() como aproximación
    return time()
end

-- ========================================
-- SISTEMA DE CACHÉ SIMPLE
-- ========================================
local function IsValidCache()
    return AutoKingsCache.lastUpdate > 0
end

local function InvalidateCache()
    AutoKingsCache.lastUpdate = 0
end

local function UpdateCache()
    local currentTime = GetCurrentTime()
    
    -- Si el caché es válido, no actualizar
    if IsValidCache() and AutoKingsCache.data.classCount then
        return AutoKingsCache.data
    end
    
    local classInRangeCount = {}
    local classToTarget = {}
    local groupType, groupMembers
    
    -- Determinar tipo de grupo
    if GetNumRaidMembers() > 0 then
        groupType = "raid"
        groupMembers = GetNumRaidMembers()
    elseif GetNumPartyMembers() > 0 then
        groupType = "party"
        groupMembers = GetNumPartyMembers()
    else
        -- Solo el jugador
        AutoKingsCache.data = {classCount = {}, targets = {}}
        AutoKingsCache.lastUpdate = currentTime
        return AutoKingsCache.data
    end
    
    -- Guardar target actual
    local hadTarget = UnitExists("target")
    local previousTarget = nil
    if hadTarget then
        previousTarget = UnitName("target")
    end
    
    -- Procesar miembros
    for i = 1, groupMembers do
        local unit = groupType .. i
        if UnitExists(unit) and UnitHealth(unit) > 1 then
            local _, class = UnitClass(unit)
            if class then
                -- Target temporal para verificar rango
                TargetUnit(unit)
                if IsActionInRange(AutoKingsSlot) == 1 then
                    classInRangeCount[class] = (classInRangeCount[class] or 0) + 1
                    if not classToTarget[class] then
                        classToTarget[class] = unit
                    end
                end
            end
        end
    end
    
    -- Restaurar target
    if hadTarget and previousTarget then
        TargetByName(previousTarget, true)
    else
        ClearTarget()
    end
    
    -- Actualizar caché
    AutoKingsCache.data = {
        classCount = classInRangeCount,
        targets = classToTarget
    }
    AutoKingsCache.lastUpdate = currentTime
    
    return AutoKingsCache.data
end

-- ========================================
-- FUNCIÓN PRINCIPAL MEJORADA
-- ========================================
function CastKings()
    -- Verificar si tenemos el hechizo
    local hasSpell = false
    local spellName = "Greater Blessing of Kings"
    
    -- En WoW 1.12, verificamos el spellbook
    local i = 1
    while true do
        local spell = GetSpellName(i, BOOKTYPE_SPELL)
        if not spell then
            break
        elseif spell == spellName then
            hasSpell = true
            break
        end
        i = i + 1
    end
    
    if not hasSpell then
        AutoKings_Print("No tienes " .. spellName .. "!")
        return
    end
    
    -- Verificar cooldown básico
    local start, duration = GetActionCooldown(AutoKingsSlot)
    if start and start > 0 and duration and duration > 1.5 then
        AutoKings_Print("El hechizo está en cooldown.")
        return
    end
    
    local cacheData = UpdateCache()
    
    if not cacheData.classCount or not next(cacheData.classCount) then
        AutoKings_Print("No hay objetivos válidos en rango.")
        return
    end
    
    -- Encontrar la mejor clase
    local bestClass = nil
    local bestCount = 0
    local bestTarget = nil
    
    for class, count in pairs(cacheData.classCount) do
        if count > bestCount then
            bestCount = count
            bestClass = class
            bestTarget = cacheData.targets[class]
        end
    end
    
    if bestTarget then
        -- Lanzar el hechizo
        CastSpellByName(spellName, bestTarget)
        
        if AutoKingsDebug then
            AutoKings_Print("Lanzado en " .. bestClass .. " (" .. bestCount .. " jugadores cerca)")
        end
    else
        AutoKings_Print("No se encontró objetivo válido.")
    end
end

-- ========================================
-- INVALIDAR CACHÉ EN EVENTOS
-- ========================================
local function InvalidateCache()
    AutoKingsCache.lastUpdate = 0
end

-- ========================================
-- COMANDOS Y AYUDA
-- ========================================
local function ShowHelp()
    AutoKings_Print("=== AutoKings v2.0 - Ayuda ===")
    DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00Comandos disponibles:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  /autokings o /ak           - Lanzar Greater Blessing of Kings")
    DEFAULT_CHAT_FRAME:AddMessage("  /ak debug                  - Activar/desactivar debug")
    DEFAULT_CHAT_FRAME:AddMessage("  /ak status                 - Mostrar estado actual")
    DEFAULT_CHAT_FRAME:AddMessage("  /ak help                   - Mostrar esta ayuda")
end

local function ShowStatus()
    AutoKings_Print("=== Estado Actual ===")
    DEFAULT_CHAT_FRAME:AddMessage("Slot de Acción: " .. AutoKingsSlot)
    DEFAULT_CHAT_FRAME:AddMessage("Debug: " .. (AutoKingsDebug and "ON" or "OFF"))
    DEFAULT_CHAT_FRAME:AddMessage("Caché: " .. AutoKingsCache.duration .. " segundos")
    
    local cacheData = UpdateCache()
    if cacheData.classCount and next(cacheData.classCount) then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00Clases en rango:|r")
        for class, count in pairs(cacheData.classCount) do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. class .. ": " .. count .. " jugadores")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("No hay jugadores en rango.")
    end
end

-- ========================================
-- MANEJO DE COMANDOS
-- ========================================
local function HandleCommand(msg)
    if not msg then msg = "" end
    
    local args = {}
    local i = 1
    for word in string.gfind(msg, "%S+") do
        args[i] = string.lower(word)
        i = i + 1
    end
    
    if args[1] == "help" then
        ShowHelp()
    elseif args[1] == "slot" and args[2] and tonumber(args[2]) then
        local slot = tonumber(args[2])
        if slot >= 1 and slot <= 120 then
            AutoKingsSlot = slot
            if AutoKingsDB then
                AutoKingsDB.slot = slot
            end
            AutoKings_Print("Slot cambiado a: " .. slot)
            InvalidateCache()
        else
            AutoKings_Print("Slot inválido. Usa números del 1 al 120.")
        end
    elseif args[1] == "debug" then
        AutoKingsDebug = not AutoKingsDebug
        if AutoKingsDB then
            AutoKingsDB.debug = AutoKingsDebug
        end
        AutoKings_Print("Debug: " .. (AutoKingsDebug and "ON" or "OFF"))
    elseif args[1] == "cache" and args[2] and tonumber(args[2]) then
        local duration = tonumber(args[2])
        if duration >= 1 and duration <= 10 then
            AutoKingsCache.duration = duration
            if AutoKingsDB then
                AutoKingsDB.cacheDuration = duration
            end
            AutoKings_Print("Duración del caché: " .. duration .. " segundos")
            InvalidateCache()
        else
            AutoKings_Print("Duración inválida. Usa números del 1 al 10.")
        end
    elseif args[1] == "status" then
        ShowStatus()
    else
        CastKings()
    end
end

-- ========================================
-- INICIALIZACIÓN Y EVENTOS
-- ========================================
local AutoKingsFrame = CreateFrame("Frame")

AutoKingsFrame:RegisterEvent("ADDON_LOADED")
AutoKingsFrame:RegisterEvent("VARIABLES_LOADED")
AutoKingsFrame:RegisterEvent("RAID_ROSTER_UPDATE")
AutoKingsFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")

AutoKingsFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" or event == "VARIABLES_LOADED" then
        -- Cargar configuración guardada
        if AutoKingsDB then
            AutoKingsSlot = AutoKingsDB.slot or AutoKingsSlot
            AutoKingsDebug = AutoKingsDB.debug or AutoKingsDebug
            AutoKingsCache.duration = AutoKingsDB.cacheDuration or AutoKingsCache.duration
        else
            -- Crear tabla de configuración
            AutoKingsDB = {
                slot = AutoKingsSlot,
                debug = AutoKingsDebug,
                cacheDuration = AutoKingsCache.duration
            }
        end
        
        -- Registrar comandos slash
        SLASH_AUTOKINGS1 = "/autokings"
        SLASH_AUTOKINGS2 = "/ak"
        SlashCmdList["AUTOKINGS"] = HandleCommand
        
        AutoKings_Print("v2.0 cargado! Usa /ak help para ver comandos.")
        
    elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
        InvalidateCache()
    end
end)

--]]

--[[ -- AutoKings v1.0

-- Variable global para la ranura por defecto (12)
AutoKingsSlot = 12
AutoKingsDebug = false


-- Función para mostrar ayuda
local function ShowHelp()
  print("|cff00ff00[AutoKings Help]|r")
  print("Use /autokings slot X  - Set the action bar slot where Greater Blessing of Kings is located.")
  print("Use /autokings         - Cast Greater Blessing of Kings on the class with most players in range.")
end

-- Registrar comando /ak para ayuda
SLASH_AUTOKINGS_HELP1 = "/ak"
SlashCmdList["AUTOKINGS_HELP"] = function()
  ShowHelp()
end


local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  print("|cff00ff00[AutoKings]|r Addon loaded!")

   -- Load saved value or fallback
  AutoKingsDB = AutoKingsDB or {}

  if AutoKingsDB.slot then
    AutoKingsSlot = AutoKingsDB.slot
  else
    AutoKingsDB.slot = AutoKingsSlot  -- guarda el valor por defecto (12) si no hay nada
  end


  -- Register slash command
  SLASH_AUTOKINGS1 = "/autokings"
  SlashCmdList["AUTOKINGS"] = function(msg)
    msg = msg or ""
    local args = {}
    for word in string.gfind(msg, "%S+") do
      table.insert(args, word)
    end

    if args[1] == "slot" and tonumber(args[2]) then
      AutoKingsSlot = tonumber(args[2])
      AutoKingsDB = AutoKingsDB or {}
      AutoKingsDB.slot = AutoKingsSlot
      print("|cff00ff00[AutoKings]|r Action slot changed to: " .. AutoKingsSlot)
    else
      CastKings()
    end
  end
end)


function CastKings()
  local classInRangeCount = {}
  local classToTarget = {}
  local bestClass = nil
  local bestCount = 0
  local bestTarget = nil

  -- Save current target (enemy or friendly)
  local hadTarget = UnitExists("target")
  local previousTarget = nil
  if hadTarget then
    previousTarget = UnitName("target")
  end

  local groupType, groupMembers

  if UnitInRaid("player") then
    groupType = "raid"
    groupMembers = GetNumRaidMembers()
  else
    groupType = "party"
    groupMembers = GetNumPartyMembers()
  end

  for i = 1, groupMembers do
    local unit = groupType .. i
    if UnitExists(unit) and UnitHealth(unit) > 1 then
      local _, class = UnitClass(unit)
      if class then
        -- Temporarily target to check range
        TargetUnit(unit)
        if IsActionInRange(AutoKingsSlot) == 1 then
          classInRangeCount[class] = (classInRangeCount[class] or 0) + 1
          classToTarget[class] = unit
        end
      end
    end
  end

  -- Restore previous target if needed
  if hadTarget and previousTarget then
    TargetByName(previousTarget, true)
  else
    ClearTarget()
  end

  -- Pick the best class
  for class, count in pairs(classInRangeCount) do
    if count > bestCount then
      bestCount = count
      bestClass = class
      bestTarget = classToTarget[class]
    end
  end

  if bestTarget then
  -- Cast the spell without changing target
    CastSpellByName("Greater Blessing of Kings", bestTarget)

    -- Optional debug output
    if AutoKingsDebug then
      print("|cff00ff00[AutoKings]|r Casted on " .. bestClass .. " (" .. bestCount .. " nearby).")
    end
  else
  print("|cffff0000[AutoKings]|r No valid targets in range.")
  end
end

--]]


