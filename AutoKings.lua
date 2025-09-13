-- AutoKings v1.1 - Optimized Professional Version
-- Author: Enhanced by Reniry
-- Compatible with WoW 1.12 (Turtle WoW)

-- AutoKings v1.1 - Optimized & Fixed
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
    return time()
end

-- ========================================
-- SISTEMA DE CACHÉ SIMPLE
-- ========================================
local function IsValidCache()
    local currentTime = GetCurrentTime()
    return AutoKingsCache.lastUpdate > 0 and 
           (currentTime - AutoKingsCache.lastUpdate) < AutoKingsCache.duration
end

local function InvalidateCache()
    AutoKingsCache.lastUpdate = 0
    AutoKingsCache.data = {}
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
    
    -- Determinar tipo de grupo y cantidad de miembros
    if GetNumRaidMembers() > 0 then
        groupType = "raid"
        groupMembers = GetNumRaidMembers()
    elseif GetNumPartyMembers() > 0 then
        groupType = "party" 
        groupMembers = GetNumPartyMembers()
    else
        -- Solo el jugador - revisar también al player
        local _, playerClass = UnitClass("player")
        if playerClass then
            classInRangeCount[playerClass] = 1
            classToTarget[playerClass] = "player"
        end
        
        AutoKingsCache.data = {classCount = classInRangeCount, targets = classToTarget}
        AutoKingsCache.lastUpdate = currentTime
        return AutoKingsCache.data
    end
    
    -- Guardar target actual
    local hadTarget = UnitExists("target")
    local previousTarget = nil
    if hadTarget then
        previousTarget = UnitName("target")
    end
    
    -- IMPORTANTE: En raids, el índice 0 es el player, del 1 al 39 son los demás
    -- En party, el player no está incluido en la numeración
    
    if groupType == "raid" then
        -- Procesar al player primero (raid0 no existe, usar "player")
        local _, playerClass = UnitClass("player")
        if playerClass and UnitHealth("player") > 1 then
            -- Para el player, siempre está "en rango" de sí mismo
            classInRangeCount[playerClass] = (classInRangeCount[playerClass] or 0) + 1
            if not classToTarget[playerClass] then
                classToTarget[playerClass] = "player"
            end
        end
        
        -- Procesar miembros del raid (1 a 40, excluyendo al player)
        for i = 1, 40 do
            local unit = "raid" .. i
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
    else
        -- Para party: incluir al player + party members
        local _, playerClass = UnitClass("player")
        if playerClass and UnitHealth("player") > 1 then
            classInRangeCount[playerClass] = (classInRangeCount[playerClass] or 0) + 1
            if not classToTarget[playerClass] then
                classToTarget[playerClass] = "player"
            end
        end
        
        -- Procesar miembros del party (1 a 4)
        for i = 1, 4 do
            local unit = "party" .. i
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
    
    if AutoKingsDebug then
        local totalPlayers = 0
        local totalClasses = 0
        if AutoKingsCache.data.classCount then
            for class, count in pairs(AutoKingsCache.data.classCount) do
                totalPlayers = totalPlayers + count
                totalClasses = totalClasses + 1
            end
        end
        AutoKings_Print("Cache actualizado - " .. totalClasses .. " clases diferentes, " .. 
                       totalPlayers .. " jugadores totales")
    end
    
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
    
    -- Encontrar la mejor clase (más jugadores)
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
        -- Target al mejor objetivo antes de lanzar
        if bestTarget ~= "player" then
            TargetUnit(bestTarget)
        end
        
        -- Lanzar el hechizo
        CastSpellByName(spellName)
        
        if AutoKingsDebug then
            AutoKings_Print("Lanzado Greater Blessing of Kings en " .. bestClass .. 
                           " (" .. bestCount .. " jugadores)")
        end
        
        -- Invalidar caché después del cast exitoso
        InvalidateCache()
    else
        AutoKings_Print("No se encontró objetivo válido.")
    end
end

-- ========================================
-- COMANDOS Y AYUDA
-- ========================================
local function ShowHelp()
    AutoKings_Print("=== AutoKings v1.1 - Ayuda ===")
    DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00Comandos disponibles:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  /autokings o /ak           - Lanzar Greater Blessing of Kings")
    DEFAULT_CHAT_FRAME:AddMessage("  /ak debug                  - Activar/desactivar debug")
    DEFAULT_CHAT_FRAME:AddMessage("  /ak status                 - Mostrar estado actual")
    DEFAULT_CHAT_FRAME:AddMessage("  /ak slot [numero]          - Cambiar slot de acción")
    DEFAULT_CHAT_FRAME:AddMessage("  /ak cache [segundos]       - Cambiar duración del caché")
    DEFAULT_CHAT_FRAME:AddMessage("  /ak help                   - Mostrar esta ayuda")
end

local function ShowStatus()
    AutoKings_Print("=== Estado Actual ===")
    DEFAULT_CHAT_FRAME:AddMessage("Slot de Acción: " .. AutoKingsSlot)
    DEFAULT_CHAT_FRAME:AddMessage("Debug: " .. (AutoKingsDebug and "ON" or "OFF"))
    DEFAULT_CHAT_FRAME:AddMessage("Caché: " .. AutoKingsCache.duration .. " segundos")
    
    -- Forzar actualización del caché para mostrar estado actual
    InvalidateCache()
    local cacheData = UpdateCache()
    
    if cacheData.classCount and next(cacheData.classCount) then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00Clases en rango:|r")
        local totalPlayers = 0
        for class, count in pairs(cacheData.classCount) do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. class .. ": " .. count .. " jugadores")
            totalPlayers = totalPlayers + count
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFFFFFTotal: " .. totalPlayers .. " jugadores|r")
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
        
        AutoKings_Print("v1.1 cargado! Usa /ak help para ver comandos.")
        
    elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
        InvalidateCache()
    end
end)
