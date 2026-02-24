local ADDON_NAME, L = ...
local VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

local PluginID = "TITAN_SPECS_LOADOUTS"
local frame = CreateFrame("Button", "TitanPanel" .. PluginID .. "Button", UIParent, "TitanPanelComboTemplate")

local pending = {
	targetSpecID = nil,
	targetConfigID = nil,
}

local function showSwitchFailed()
	if UIErrorsFrame and UIErrorsFrame.AddExternalErrorMessage then
		UIErrorsFrame:AddExternalErrorMessage(L["SwitchFailed"])
	end
end

local function normalizeLoadConfigResult(result)
	if type(result) == "table" then
		return result.result or result
	end
	return result
end

local function getCurrentSpecInfo()
	if not C_SpecializationInfo or not C_SpecializationInfo.GetSpecialization then
		return nil
	end

	local specIndex = C_SpecializationInfo.GetSpecialization()
	if not specIndex then
		return nil
	end

	local specID, name, description, icon = C_SpecializationInfo.GetSpecializationInfo(specIndex)
	if not specID then
		return nil
	end

	return {
		specIndex = specIndex,
		specID = specID,
		name = name,
		description = description,
		icon = icon,
	}
end

local function getClassSpecIDs()
	if not C_SpecializationInfo or not C_SpecializationInfo.GetNumSpecializations then
		return {}
	end

	local specIDs = {}
	local numSpecs = C_SpecializationInfo.GetNumSpecializations() or 0
	for specIndex = 1, numSpecs do
		local specID = C_SpecializationInfo.GetSpecializationInfo(specIndex)
		if specID then
			tinsert(specIDs, specID)
		end
	end

	return specIDs
end

local function getSpecName(specID)
	if not C_SpecializationInfo or not C_SpecializationInfo.GetSpecializationInfoByID then
		return "Spec " .. tostring(specID)
	end

	local _, specName = C_SpecializationInfo.GetSpecializationInfoByID(specID)
	if not specName or specName == "" then
		return "Spec " .. tostring(specID)
	end

	return specName
end

local function getConfigInfo(configID)
	if not configID or not C_Traits or not C_Traits.GetConfigInfo then
		return nil
	end

	return C_Traits.GetConfigInfo(configID)
end

local function getSavedLoadoutsBySpecID(specID)
	if not specID or not C_ClassTalents or not C_ClassTalents.GetConfigIDsBySpecID then
		return {}
	end

	local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID) or {}
	local loadouts = {}
	for _, configID in ipairs(configIDs) do
		local cfg = getConfigInfo(configID)
		if cfg then
			tinsert(loadouts, {
				configID = configID,
				name = cfg.name or ("Loadout " .. tostring(configID)),
			})
		end
	end

	table.sort(loadouts, function(a, b)
		return a.name:lower() < b.name:lower()
	end)

	return loadouts
end

local function getCurrentLoadoutName()
	if not C_ClassTalents or not C_ClassTalents.GetActiveConfigID then
		return L["NoLoadout"]
	end

	local activeConfigID = C_ClassTalents.GetActiveConfigID()
	if not activeConfigID then
		return L["NoLoadout"]
	end

	local cfg = getConfigInfo(activeConfigID)
	if not cfg or not cfg.name or cfg.name == "" then
		return L["NoLoadout"]
	end

	return cfg.name
end

local function updateButton()
	if frame and frame.registry and frame.registry.id then
		TitanPanelButton_UpdateButton(frame.registry.id)
	end
end

local function clearPending()
	pending.targetSpecID = nil
	pending.targetConfigID = nil
end

local function loadConfigID(configID)
	if not C_ClassTalents or not C_ClassTalents.LoadConfig then
		showSwitchFailed()
		return
	end

	local result = C_ClassTalents.LoadConfig(configID, true)
	result = normalizeLoadConfigResult(result)

	if Enum and Enum.LoadConfigResult and result == Enum.LoadConfigResult.Error then
		showSwitchFailed()
	end
end

local function tryFinalizePending()
	if not pending.targetConfigID then
		return
	end
	if not C_ClassTalents or not C_ClassTalents.GetActiveConfigID then
		return
	end

	local activeConfigID = C_ClassTalents.GetActiveConfigID()
	if not activeConfigID then
		return
	end

	local configID = pending.targetConfigID
	clearPending()
	loadConfigID(configID)
	updateButton()
end

local function activateLoadout(specID, configID)
	if not configID then
		return
	end

	local current = getCurrentSpecInfo()
	if current and current.specID == specID then
		loadConfigID(configID)
		updateButton()
		return
	end

	pending.targetSpecID = specID
	pending.targetConfigID = configID

	if not C_SpecializationInfo or not C_SpecializationInfo.SetSpecialization then
		loadConfigID(configID)
		clearPending()
		updateButton()
		return
	end

	local numSpecs = C_SpecializationInfo.GetNumSpecializations and (C_SpecializationInfo.GetNumSpecializations() or 0) or 0
	for specIndex = 1, numSpecs do
		local candidateSpecID = C_SpecializationInfo.GetSpecializationInfo(specIndex)
		if candidateSpecID == specID then
			C_SpecializationInfo.SetSpecialization(specIndex)
			return
		end
	end

	showSwitchFailed()
	clearPending()
	updateButton()
end

local function makeLoadoutButton(specID, configID)
	local info = L_UIDropDownMenu_CreateInfo()
	local cfg = getConfigInfo(configID)
	local cfgName = (cfg and cfg.name and cfg.name ~= "") and cfg.name or ("Loadout " .. tostring(configID))

	info.text = cfgName
	info.func = function()
		activateLoadout(specID, configID)
	end
	info.keepShownOnClick = false

	local activeConfigID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID() or nil
	info.checked = activeConfigID and activeConfigID == configID

	L_UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end

local function addNoLoadoutsLine()
	local info = L_UIDropDownMenu_CreateInfo()
	info.text = L["NoSavedLoadouts"]
	info.notCheckable = true
	info.disabled = true
	L_UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end

local function prepareMenu(_, id)
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		TitanPanelRightClickMenu_AddTitle(TitanPlugins[id].menuText)
		TitanPanelRightClickMenu_AddToggleIcon(id)
		TitanPanelRightClickMenu_AddToggleLabelText(id)
		TitanPanelRightClickMenu_AddToggleRightSide(id)
		TitanPanelRightClickMenu_AddSpacer()

		local specIDs = getClassSpecIDs()
		for _, specID in ipairs(specIDs) do
			local info = L_UIDropDownMenu_CreateInfo()
			info.text = getSpecName(specID)
			info.hasArrow = true
			info.notCheckable = true
			info.keepShownOnClick = true
			info.value = specID
			L_UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end

		TitanPanelRightClickMenu_AddSpacer()
		TitanPanelRightClickMenu_AddCommand(TITAN_PANEL_MENU_HIDE, id, TITAN_PANEL_MENU_FUNC_HIDE)
		return
	end

	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
		local specID = tonumber(UIDROPDOWNMENU_MENU_VALUE)
		if not specID then
			addNoLoadoutsLine()
			return
		end

		local loadouts = getSavedLoadoutsBySpecID(specID)
		if #loadouts == 0 then
			addNoLoadoutsLine()
			return
		end

		for _, loadout in ipairs(loadouts) do
			makeLoadoutButton(specID, loadout.configID)
		end
	end
end

local function getButtonText()
	local specInfo = getCurrentSpecInfo()
	local specName = (specInfo and specInfo.name) or L["NoSpec"]
	local loadoutName = getCurrentLoadoutName()
	return L["Label"] .. ": ", string.format("%s - %s", specName, loadoutName)
end

local function getTooltipText()
	local specInfo = getCurrentSpecInfo()
	local specName = (specInfo and specInfo.name) or L["NoSpec"]
	local loadoutName = getCurrentLoadoutName()
	return string.format("%s: %s\nLoadout: %s\n\n%s", L["Label"], specName, loadoutName, L["Hint"])
end

local function onRelevantUpdate()
	tryFinalizePending()
	updateButton()
end

local eventsTable = {
	PLAYER_ENTERING_WORLD = function(self)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		onRelevantUpdate()
	end,
	ACTIVE_TALENT_GROUP_CHANGED = function()
		onRelevantUpdate()
	end,
	PLAYER_SPECIALIZATION_CHANGED = function()
		onRelevantUpdate()
	end,
	TRAIT_CONFIG_LIST_UPDATED = function()
		onRelevantUpdate()
	end,
	TRAIT_CONFIG_UPDATED = function()
		onRelevantUpdate()
	end,
	PLAYER_TALENT_UPDATE = function()
		onRelevantUpdate()
	end,
}

frame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, ...)
	end
end)

function frame:ADDON_LOADED(addon)
	if addon ~= ADDON_NAME then
		return
	end

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	self.registry = {
		id = PluginID,
		menuText = L["Name"] .. "|r",
		buttonTextFunction = "TitanPanelButton_Get" .. PluginID .. "ButtonText",
		tooltipTitle = L["Name"],
		tooltipTextFunction = "TitanPanelButton_Get" .. PluginID .. "TooltipText",
		icon = "Interface\\Icons\\ability_dualwield",
		iconWidth = 16,
		category = "Information",
		version = VERSION,
		savedVariables = {
			ShowIcon = 1,
			ShowLabelText = 1,
			DisplayOnRightSide = false,
		},
	}
end

frame:RegisterEvent("ADDON_LOADED")
for event, func in pairs(eventsTable) do
	frame[event] = func
	frame:RegisterEvent(event)
end

_G["TitanPanelRightClickMenu_Prepare" .. PluginID .. "Menu"] = function(...)
	return prepareMenu(frame, PluginID, ...)
end

_G["TitanPanelButton_Get" .. PluginID .. "ButtonText"] = function(...)
	return getButtonText(frame, PluginID, ...)
end

_G["TitanPanelButton_Get" .. PluginID .. "TooltipText"] = function(...)
	return getTooltipText(frame, PluginID, ...)
end
