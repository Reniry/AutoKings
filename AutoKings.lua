-- AutoKings v1.01

-- Variable global para la ranura por defecto (12)
AutoKingsSlot = 12

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
  if AutoKingsDB and AutoKingsDB.slot then
    AutoKingsSlot = AutoKingsDB.slot
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
    print("|cff00ff00[AutoKings]|r Casted on " .. bestClass .. " (" .. bestCount .. " nearby).")
  else
    print("|cffff0000[AutoKings]|r No valid targets in range.")
  end
end




