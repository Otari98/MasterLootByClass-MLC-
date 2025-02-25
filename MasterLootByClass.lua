--Most of this code taken from https://github.com/CosminPOP/TWAssignments and https://github.com/Ko0z/XLoot
--Main idea - keep it simple, no fancy functions
local MLBC = CreateFrame("Frame")
local RaidDropDown = CreateFrame('Frame', 'RaidDropDown', UIParent, 'UIDropDownMenuTemplate')
LootFrame:SetScript("OnMouseUp", CloseDropDownMenus)
LootFrame:UnregisterEvent("OPEN_MASTER_LOOT_LIST")

MLBC:RegisterEvent("OPEN_MASTER_LOOT_LIST")
MLBC:RegisterEvent("RAID_ROSTER_UPDATE")
MLBC:RegisterEvent("LOOT_SLOT_CLEARED")

MLBC.classColors = {
  ["warrior"] = { r = 0.78, g = 0.61, b = 0.43, c = "|cffc79c6e" },
  ["mage"] = { r = 0.41, g = 0.8, b = 0.94, c = "|cff69ccf0" },
  ["rogue"] = { r = 1, g = 0.96, b = 0.41, c = "|cfffff569" },
  ["druid"] = { r = 1, g = 0.49, b = 0.04, c = "|cffff7d0a" },
  ["hunter"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cffabd473" },
  ["shaman"] = { r = 0.14, g = 0.35, b = 1.0, c = "|cff0070de" },
  ["priest"] = { r = 1, g = 1, b = 1, c = "|cffffffff" },
  ["warlock"] = { r = 0.58, g = 0.51, b = 0.79, c = "|cff9482c9" },
  ["paladin"] = { r = 0.96, g = 0.55, b = 0.73, c = "|cfff58cba" },
}

MLBC.raid = {
  ['warrior'] = {},
  ['paladin'] = {},
  ['druid'] = {},
  ['warlock'] = {},
  ['mage'] = {},
  ['priest'] = {},
  ['rogue'] = {},
  ['shaman'] = {},
  ['hunter'] = {},
}

function MLBC.fillRaidData()
  for _, data in pairs(MLBC.raid) do
    for index in pairs(data) do
      data[index] = nil
    end
    table.setn(data, 0)
  end
  if UnitInRaid("player") then
    for i = 1, GetNumRaidMembers() do
      if GetRaidRosterInfo(i) then
          local name = GetRaidRosterInfo(i);
          local _, unitClass = UnitClass('raid' .. i)
          unitClass = string.lower(unitClass)
          table.insert(MLBC.raid[unitClass], name)
      end
    end
  end
  if UnitInParty("player") and not UnitInRaid("player") then
    local _, playerClass = UnitClass("player")
    local playerName = UnitName("player")
    playerClass = string.lower(playerClass)
    table.insert(MLBC.raid[playerClass], playerName)
    for i = 1, GetNumPartyMembers() do
      if UnitName('party' .. i) then
        local name = UnitName('party' .. i)
        local _, unitClass = UnitClass('party' .. i)
        unitClass = string.lower(unitClass)
        table.insert(MLBC.raid[unitClass], name)
      end
    end
  end
  for class in pairs(MLBC.raid) do
    table.sort(MLBC.raid[class])
  end
end

local function GetMLID(name)
  if GetNumRaidMembers() > 0 then
    for i = 1, 40 do
      if name == GetMasterLootCandidate(i) then
        return i
      end
    end
  end
  DEFAULT_CHAT_FRAME:AddMessage("|cffcc6666[MasterLootByClass]|r|cffffff00 "..name.." can not receive this item.|r")
  return nil
end

local function IsOffline(name)
  for i = 1, GetNumRaidMembers() do
      if (GetRaidRosterInfo(i)) then
          local n, _, _, _, _, _, o = GetRaidRosterInfo(i);
          if n == name and o == 'Offline' then
              return true
          end
      end
  end
  return false
end

local function GiveToRandom()
	local max = GetNumRaidMembers() and 40 or 5
	local name, id
  local item = LootFrame.selectedSlot
  local link = GetLootSlotLink(item)
	while not name do
		id = math.random(1, max)
		name = GetMasterLootCandidate(id)
	end
  if name and id and item and link and max > 0 then
    SendChatMessage("Rolling the dice...", "RAID") 
    SendChatMessage(name.." wins "..link.."!", "RAID")
    GiveMasterLoot(item, id);
  end
end

local function GiveLoot(name)
  local item = LootFrame.selectedSlot
  local id = GetMLID(name)
  if not item or not id then return end
  GiveMasterLoot(item, id);
end

local function BuildRaidMenu()

  if UnitInRaid("player") and UIDROPDOWNMENU_MENU_LEVEL == 1 then
      local title = {};
      title.isTitle = true
      title.textHeight = 12
      title.notCheckable = true
      title.text = "Give Loot To:"
      UIDropDownMenu_AddButton(title);

      local me = {};
      local myname = UnitName("player")
      me.text = "Me"
      me.textHeight = 12
      me.disabled = false
      me.isTitle = false
      me.notCheckable = true
      me.func = GiveLoot
      me.arg1 = myname
      UIDropDownMenu_AddButton(me, UIDROPDOWNMENU_MENU_LEVEL);

      local random = {};
      random.text = "Random"
      random.disabled = false
      random.textHeight = 12
      random.isTitle = false
      random.notCheckable = true
      random.func = GiveToRandom
      UIDropDownMenu_AddButton(random, UIDROPDOWNMENU_MENU_LEVEL);  
      
      local separator = {};
      separator.text = ""
      separator.disabled = true
      UIDropDownMenu_AddButton(separator);

      local Warriors = {}
      Warriors.text = MLBC.classColors['warrior'].c .. 'Warriors'
      Warriors.textHeight = 12
      Warriors.notCheckable = true
      Warriors.hasArrow = true
      Warriors.value = {
          ['key'] = 'warrior'
      }
      if next(MLBC.raid['warrior']) ~= nil then
        UIDropDownMenu_AddButton(Warriors, UIDROPDOWNMENU_MENU_LEVEL);
      end

      local Druids = {}
      Druids.text = MLBC.classColors['druid'].c .. 'Druids'
      Druids.textHeight = 12
      Druids.notCheckable = true
      Druids.hasArrow = true
      Druids.value = {
          ['key'] = 'druid'
      }
      if next(MLBC.raid['druid']) ~= nil then
        UIDropDownMenu_AddButton(Druids, UIDROPDOWNMENU_MENU_LEVEL);
      end

      local Paladins = {}
      Paladins.text = MLBC.classColors['paladin'].c .. 'Paladins'
      Paladins.textHeight = 12
      Paladins.notCheckable = true
      Paladins.hasArrow = true
      Paladins.value = {
          ['key'] = 'paladin'
      }
      if next(MLBC.raid['paladin']) ~= nil then
        UIDropDownMenu_AddButton(Paladins, UIDROPDOWNMENU_MENU_LEVEL);
      end

      local Warlocks = {}
      Warlocks.text = MLBC.classColors['warlock'].c .. 'Warlocks'
      Warlocks.textHeight = 12
      Warlocks.notCheckable = true
      Warlocks.hasArrow = true
      Warlocks.value = {
          ['key'] = 'warlock'
      }
      if next(MLBC.raid['warlock']) ~= nil then
        UIDropDownMenu_AddButton(Warlocks, UIDROPDOWNMENU_MENU_LEVEL);
      end

      local Mages = {}
      Mages.text = MLBC.classColors['mage'].c .. 'Mages'
      Mages.textHeight = 12
      Mages.notCheckable = true
      Mages.hasArrow = true
      Mages.value = {
          ['key'] = 'mage'
      }
      if next(MLBC.raid['mage']) ~= nil then
        UIDropDownMenu_AddButton(Mages, UIDROPDOWNMENU_MENU_LEVEL);
      end

      local Priests = {}
      Priests.text = MLBC.classColors['priest'].c .. 'Priests'
      Priests.textHeight = 12
      Priests.notCheckable = true
      Priests.hasArrow = true
      Priests.value = {
          ['key'] = 'priest'
      }
      if next(MLBC.raid['priest']) ~= nil then
        UIDropDownMenu_AddButton(Priests, UIDROPDOWNMENU_MENU_LEVEL);
      end

      local Rogues = {}
      Rogues.text = MLBC.classColors['rogue'].c .. 'Rogues'
      Rogues.textHeight = 12
      Rogues.notCheckable = true
      Rogues.hasArrow = true
      Rogues.value = {
          ['key'] = 'rogue'
      }
      if next(MLBC.raid['rogue']) ~= nil then
        UIDropDownMenu_AddButton(Rogues, UIDROPDOWNMENU_MENU_LEVEL);
      end

      local Hunters = {}
      Hunters.text = MLBC.classColors['hunter'].c .. 'Hunters'
      Hunters.textHeight = 12
      Hunters.notCheckable = true
      Hunters.hasArrow = true
      Hunters.value = {
          ['key'] = 'hunter'
      }
      if next(MLBC.raid['hunter']) ~= nil then
        UIDropDownMenu_AddButton(Hunters, UIDROPDOWNMENU_MENU_LEVEL);
      end

      local Shamans = {}
      Shamans.text = MLBC.classColors['shaman'].c .. 'Shamans'
      Shamans.textHeight = 12
      Shamans.notCheckable = true
      Shamans.hasArrow = true
      Shamans.value = {
          ['key'] = 'shaman'
      }
      if next(MLBC.raid['shaman']) ~= nil then
        UIDropDownMenu_AddButton(Shamans, UIDROPDOWNMENU_MENU_LEVEL);
      end
    elseif UnitInParty("player") and not UnitInRaid("player") and UIDROPDOWNMENU_MENU_LEVEL == 1 then
      local info, candidate, class
      for i = 1, MAX_PARTY_MEMBERS + 1, 1 do
        candidate = GetMasterLootCandidate(i);
        if candidate then
          for k,v in pairs(MLBC.raid) do
            for k2,v2 in pairs(MLBC.raid[k]) do
              if v2 == candidate then
                class = k
              end
            end
          end
          if class then
            local color = MLBC.classColors[class].c
            info = {}
            info.text = color .. candidate
            info.textHeight = 12
            info.notCheckable = 1
            info.arg1 = LootFrame.selectedSlot
            info.arg2 = i
            info.func = GiveMasterLoot
            UIDropDownMenu_AddButton(info)
          end
        end
      end
  end
  if UIDROPDOWNMENU_MENU_LEVEL == 2 then

      for i, player in next, MLBC.raid[UIDROPDOWNMENU_MENU_VALUE['key']] do
          local Players = {}
          local color = MLBC.classColors[UIDROPDOWNMENU_MENU_VALUE['key']].c
          Players.notCheckable = true
          Players.hasArrow = false
          Players.func = GiveLoot
          Players.arg1 = player
          Players.textHeight = 12
          if IsOffline(player) then
            Players.disabled = true
            Players.text = player
          else
            Players.text = color..player
            Players.disabled = false
          end
          UIDropDownMenu_AddButton(Players, UIDROPDOWNMENU_MENU_LEVEL);
      end
    return
  end
end

MLBC:SetScript("OnEvent", function()
  if GetLootMethod() == "master" then
    if event == "RAID_ROSTER_UPDATE" then
        MLBC.fillRaidData()
    elseif event == "OPEN_MASTER_LOOT_LIST" then
      MLBC.fillRaidData();
      UIDropDownMenu_Initialize(RaidDropDown, BuildRaidMenu, "MENU");
      ToggleDropDownMenu(1, nil, RaidDropDown, LootFrame.selectedLootButton, 0, 0)
    elseif event == "LOOT_SLOT_CLEARED" then
      CloseDropDownMenus()
    end
  end
end)

UnitPopupButtons["ITEM_QUALITY1_DESC"] = { text = TEXT(ITEM_QUALITY1_DESC), dist = 0, color = ITEM_QUALITY_COLORS[1] };
tinsert(UnitPopupMenus["LOOT_THRESHOLD"], 1, "ITEM_QUALITY1_DESC")

local Original_UnitPopup_OnClick = UnitPopup_OnClick

local function Hook_UnitPopup_OnClick()
  Original_UnitPopup_OnClick()
  local button = this.value
  if button == "ITEM_QUALITY1_DESC" or button == "ITEM_QUALITY2_DESC" or button == "ITEM_QUALITY3_DESC" or button == "ITEM_QUALITY4_DESC" then
		SetLootThreshold(this:GetID())
		local color = ITEM_QUALITY_COLORS[this:GetID()]
		UIDropDownMenu_SetButtonText(1, 3, UnitPopupButtons[button].text, color.r, color.g, color.b)
  end
end

UnitPopup_OnClick = Hook_UnitPopup_OnClick
