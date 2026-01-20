-- Title         : ConcentrationAlert
-- Author        : Echellon
-- Last Updated  : 20JAN2025
-- Game Version  : 12.0.0
-- Addon Version : 1.1.0
-- https://github.com/ninthwalker/ConcentrationAlert

-- Slash Commands
SLASH_CONALERTRESET1 = "/conalertresetall"
SlashCmdList["CONALERTRESET"] = function()
  ConAlertDB = {}
  ReloadUI()
end

-- Init
if ConAlertDB == nil then
  ConAlertDB = {}
end

-- Record Concentration amount and save
local function RecordConcentration(self, event, ...)
  local skillLineID = C_TradeSkillUI.GetProfessionChildSkillLineID()
  local currencyID = C_TradeSkillUI.GetConcentrationCurrencyID(skillLineID)
	if currencyID then
	  local concentration = C_CurrencyInfo.GetCurrencyInfo(currencyID)
	  if concentration then
	
	    -- Get concentration info
		local conName = concentration.name
		local conQuantity = concentration.quantity
		local conData = conName .. "_" .. conQuantity .. "_" .. time()
	  
	    -- Get character info
		local charName, realm = UnitName("Player")
		local charRealm = GetRealmName()
		local nameRealm = charName .. "_" .. charRealm
		local varId = nameRealm .. "_" .. skillLineID
		
		-- Save data
		ConAlertDB[varId] = conData
		return true
	  else
		return false
	  end
	else
	  return false
	end
end

-- Register for trade skill update
local f = CreateFrame("Frame")
f:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
f:SetScript("OnEvent", RecordConcentration)
