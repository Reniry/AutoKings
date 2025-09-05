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
  local classCount = {}
  local classInRange = {}
  local max = 1
  local target = "player"
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
    local _, class = UnitClass(unit)
    if class and UnitHealth(unit) > 1 then
      classCount[class] = (classCount[class] or 0) + 1
      if not classInRange[class] then
        TargetUnit(unit)
        if IsActionInRange(AutoKingsSlot) == 1 then
          classInRange[class] = unit
        end
        TargetLastTarget()
      end
      if classCount[class] > max and classInRange[class] then
        max = classCount[class]
        target = classInRange[class]
      end
    end
  end

  TargetUnit(target)
  CastSpellByName("Greater Blessing of Kings")
  TargetLastTarget()
end




