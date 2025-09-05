-- AutoKings v1.0

-- Variable global para la ranura por defecto (12)
AutoKingsSlot = 12

local f = CreateFrame("Frame")

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
  if name == "AutoKings" then
    -- Registrar comando slash /autokings
    SLASH_AUTOKINGS1 = "/autokings"
    SlashCmdList["AUTOKINGS"] = function(msg)
      local args = {}
      for word in msg:gmatch("%S+") do
        table.insert(args, word)
      end

      if args[1] == "slot" and tonumber(args[2]) then
        AutoKingsSlot = tonumber(args[2])
        print("|cff00ff00[AutoKings]|r Slot de acción cambiado a: " .. AutoKingsSlot)
      else
        CastKings()
      end
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




