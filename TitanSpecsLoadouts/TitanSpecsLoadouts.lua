local ADDON_NAME, L = ...
local VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

local PluginID = "TITAN_SPECS_LOADOUTS"
local DefaultIcon = "Interface\\Icons\\ability_dualwield"
local TopMenuMinWidth = 170
local SubMenuMinWidth = 170
local LeftClickLabel = "|cff66ccffLClick|r"
local RightClickLabel = "|cffff9900RClick|r"
local frame = CreateFrame("Button", "TitanPanel" .. PluginID .. "Button", UIParent, "TitanPanelComboTemplate")

local pending = {
	targetSpecID = nil,
	targetConfigID = nil,
}

-- Track the config we loaded ourselves, since GetLastSelectedSavedConfigID
-- does not update reliably after LoadConfig fires.
local addonTrackedConfigID = nil

-- Track the last spec we knew about so PLAYER_SPECIALIZATION_CHANGED can
-- distinguish a real spec change from an intra-spec loadout switch
-- (WoW fires that event for both).
local lastKnownSpecID = nil

local function getTitanHideMenuText()
	if TITAN_PANEL_MENU_HIDE and TITAN_PANEL_MENU_HIDE ~= "" then
		return TITAN_PANEL_MENU_HIDE
	end

	if LibStub then
		local aceLocale = LibStub("AceLocale-3.0", true)
		if aceLocale then
			local titanLocale = aceLocale:GetLocale("Titan", true)
			if titanLocale and titanLocale["TITAN_PANEL_MENU_HIDE"] then
				return titanLocale["TITAN_PANEL_MENU_HIDE"]
			end
		end
	end

	return HIDE or "Hide"
end

local function apiGetNumSpecializations()
	if C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializations then
		return C_SpecializationInfo.GetNumSpecializations() or 0
	end
	if GetNumSpecializations then
		return GetNumSpecializations() or 0
	end
	return 0
end

local function apiGetSpecialization()
	if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
		return C_SpecializationInfo.GetSpecialization()
	end
	if GetSpecialization then
		return GetSpecialization()
	end
	return nil
end

local function apiGetSpecializationInfo(specIndex)
	local id, name, description, icon

	if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
		id, name, description, icon = C_SpecializationInfo.GetSpecializationInfo(specIndex)
	end

	if type(id) == "table" then
		local info = id
		id = info.specializationID or info.specID or info.id
		name = info.name or name
		description = info.description or description
		icon = info.icon or info.iconID or icon
	end

	if type(id) ~= "number" and GetSpecializationInfo then
		id, name, description, icon = GetSpecializationInfo(specIndex)
	end

	if type(id) ~= "number" then
		return nil, nil, nil, nil
	end

	return id, name, description, icon
end

local function apiGetSpecializationInfoByID(specID)
	if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfoByID then
		local a, b, c, d = C_SpecializationInfo.GetSpecializationInfoByID(specID)
		if type(a) == "table" then
			local info = a
			local id = info.specializationID or info.specID or specID
			local name = info.name
			local description = info.description
			local icon = info.icon or info.iconID
			return id, name, description, icon
		end
		if type(a) == "string" then
			return specID, a, b, c
		end
		if type(b) == "string" then
			return specID, b, c, d
		end
	end

	if GetSpecializationInfoByID then
		local id, name, description, icon = GetSpecializationInfoByID(specID)
		return id or specID, name, description, icon
	end

	return specID, nil, nil, nil
end

local function apiSetSpecialization(specIndex)
	if C_SpecializationInfo and C_SpecializationInfo.SetSpecialization then
		C_SpecializationInfo.SetSpecialization(specIndex)
		return true
	end
	if SetSpecialization then
		SetSpecialization(specIndex)
		return true
	end
	return false
end

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
	local specIndex = apiGetSpecialization()
	if not specIndex then
		return nil
	end

	local specID, name, description, icon = apiGetSpecializationInfo(specIndex)
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

local function getCurrentSpecID()
	local currentSpec = getCurrentSpecInfo()
	return currentSpec and currentSpec.specID or nil
end

local function getCurrentSelectedConfigID()
	if not C_ClassTalents then
		return nil
	end

	-- First priority: what we explicitly loaded (reliable, since the API doesn't update GetLastSelectedSavedConfigID)
	if addonTrackedConfigID then
		return addonTrackedConfigID
	end

	-- Fallback: read from WoW API for initial state (before any addon-initiated switch)
	local currentSpec = getCurrentSpecInfo()
	if currentSpec then
		local lastSelectedID = C_ClassTalents.GetLastSelectedSavedConfigID and C_ClassTalents.GetLastSelectedSavedConfigID(currentSpec.specID)
		if lastSelectedID and lastSelectedID > 0 then
			return lastSelectedID
		end
	end

	local activeID = C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
	if activeID and activeID > 0 then
		return activeID
	end

	return nil
end

local function updateDynamicIcon()
	if not frame or not frame.registry then
		return
	end

	local specInfo = getCurrentSpecInfo()
	frame.registry.icon = (specInfo and specInfo.icon) or DefaultIcon
end

local function isLoadoutChecked(specID, configID)
	local currentSpecID = getCurrentSpecID()
	if not currentSpecID or specID ~= currentSpecID then
		return false
	end

	local selectedConfigID = getCurrentSelectedConfigID()
	return selectedConfigID and selectedConfigID == configID or false
end

local function openTalentsAndLoadouts()
	if ToggleTalentFrame then
		ToggleTalentFrame()
		return
	end

	if PlayerSpellsMicroButton and PlayerSpellsMicroButton.Click then
		PlayerSpellsMicroButton:Click()
		return
	end

	if not PlayerSpellsFrame and PlayerSpellsFrame_LoadUI then
		PlayerSpellsFrame_LoadUI()
	end

	if PlayerSpellsFrame then
		if ShowUIPanel then
			ShowUIPanel(PlayerSpellsFrame)
		else
			PlayerSpellsFrame:Show()
		end
	end
end

local function getClassSpecIDs()
	local specIDs = {}
	local numSpecs = apiGetNumSpecializations()
	for specIndex = 1, numSpecs do
		local specID = apiGetSpecializationInfo(specIndex)
		if specID then
			tinsert(specIDs, specID)
		end
	end

	return specIDs
end

local function getSpecName(specID)
	local _, specName = apiGetSpecializationInfoByID(specID)
	if not specName or specName == "" then
		return "Spec " .. tostring(specID)
	end

	return specName
end

local function getConfigInfo(configID)
	if not configID then
		return nil
	end

	-- C_ClassTalents.GetConfigInfo returns the user-defined config name (for saved loadouts)
	if C_ClassTalents and C_ClassTalents.GetConfigInfo then
		return C_ClassTalents.GetConfigInfo(configID)
	end

	-- Fall back to C_Traits if C_ClassTalents not available
	if C_Traits and C_Traits.GetConfigInfo then
		return C_Traits.GetConfigInfo(configID)
	end

	return nil
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
	if not C_ClassTalents then
		return L["NoLoadout"]
	end

	local configID = getCurrentSelectedConfigID()
	if not configID then
		return L["NoLoadout"]
	end

	local cfg = getConfigInfo(configID)
	if not cfg or not cfg.name or cfg.name == "" then
		return L["NoLoadout"]
	end

	return cfg.name
end

local function updateButton()
	if frame and frame.registry and frame.registry.id then
		updateDynamicIcon()
		TitanPanelButton_UpdateButton(frame.registry.id)
	end
end

local function clearPending()
	pending.targetSpecID = nil
	pending.targetConfigID = nil
end

local function loadConfigID(specID, configID)
	if not C_ClassTalents or not C_ClassTalents.LoadConfig then
		showSwitchFailed()
		return
	end

	local result = C_ClassTalents.LoadConfig(configID, true)
	result = normalizeLoadConfigResult(result)

	if Enum and Enum.LoadConfigResult then
		if result == Enum.LoadConfigResult.Error then
			showSwitchFailed()
			return
		end
	end

	-- LoadConfig succeeded (LoadInProgress or NoChangesNecessary both mean it applied/is applying)
	-- Track the config we loaded so display updates correctly regardless of what the API returns
	addonTrackedConfigID = configID
end

local function tryFinalizePending()
	if not pending.targetConfigID then
		return
	end

	-- Must already be on the target spec; if not, wait for the next event
	local currentSpec = getCurrentSpecInfo()
	if not currentSpec or currentSpec.specID ~= pending.targetSpecID then
		return
	end

	if not C_ClassTalents or not C_ClassTalents.LoadConfig then
		showSwitchFailed()
		clearPending()
		return
	end

	local result = C_ClassTalents.LoadConfig(pending.targetConfigID, true)
	result = normalizeLoadConfigResult(result)

	if Enum and Enum.LoadConfigResult and result == Enum.LoadConfigResult.Error then
		-- Spec is not fully settled yet; keep pending and retry on next event
		return
	end

	-- LoadInProgress or NoChangesNecessary both mean the load is applying
	addonTrackedConfigID = pending.targetConfigID
	clearPending()
	updateButton()
end

local function activateLoadout(specID, configID)
	if not configID then
		return
	end

	configID = tonumber(configID) or configID

	local current = getCurrentSpecInfo()
	if current and current.specID == specID then
		-- Check if this loadout is already active
		local currentConfigID = getCurrentSelectedConfigID()
		if currentConfigID and tonumber(currentConfigID) == tonumber(configID) then
			-- Already active, no action needed
			return
		end
		-- User explicitly chose a same-spec loadout; cancel any in-flight cross-spec pending
		-- so a delayed tryFinalizePending() event doesn't overwrite our new choice.
		clearPending()
		-- Load the new loadout for current spec
		loadConfigID(specID, configID)
		-- Force display update even if load is async/in-progress
		updateButton()
		return
	end
	pending.targetSpecID = specID
	pending.targetConfigID = configID

	if not C_SpecializationInfo and not SetSpecialization then
		loadConfigID(specID, configID)
		clearPending()
		updateButton()
		return
	end

	local numSpecs = apiGetNumSpecializations()
	for specIndex = 1, numSpecs do
		local candidateSpecID = apiGetSpecializationInfo(specIndex)
		if candidateSpecID == specID then
			apiSetSpecialization(specIndex)
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

	local isChecked = isLoadoutChecked(specID, configID)
	if isChecked then
		cfgName = string.format("|cff00ff00[%s]|r %s", L["Current"], cfgName)
	end

	info.text = cfgName
	info.func = function()
		activateLoadout(specID, configID)
	end
	info.keepShownOnClick = false
	info.minWidth = SubMenuMinWidth

	info.checked = isChecked

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
		TitanPanelRightClickMenu_AddSpacer()

		local specIDs = getClassSpecIDs()
		for _, specID in ipairs(specIDs) do
			local info = L_UIDropDownMenu_CreateInfo()
			info.text = getSpecName(specID)
			info.hasArrow = true
			info.notCheckable = true
			info.keepShownOnClick = true
			info.minWidth = TopMenuMinWidth
			info.value = specID
			L_UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end

		TitanPanelRightClickMenu_AddSpacer()
		TitanPanelRightClickMenu_AddCommand(getTitanHideMenuText(), id, TITAN_PANEL_MENU_FUNC_HIDE)
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
	local coloredSpec = string.format("|cff66ccff%s|r", specName)
	local coloredLoadout = string.format("|cffffff00%s|r", loadoutName)
	return L["Label"] .. ": ", string.format("%s - %s", coloredSpec, coloredLoadout)
end

local function getTooltipText()
	local specInfo = getCurrentSpecInfo()
	local specName = (specInfo and specInfo.name) or L["NoSpec"]
	local loadoutName = getCurrentLoadoutName()
	return string.format("\n|cff66ccff%s:|r %s\n|cffffff00Loadout:|r %s\n\n%s - %s\n%s - %s", L["Label"], specName, loadoutName, LeftClickLabel, L["HintLeft"], RightClickLabel, L["HintRight"])
end

-- Seed addonTrackedConfigID from the WoW API when it is nil.
-- Only called from PLAYER_TALENT_UPDATE, which fires after talents are
-- fully settled (on login/reload and after any spec or loadout change).
local function seedTrackedConfigFromAPI()
	if addonTrackedConfigID ~= nil then
		-- Already set by an addon-initiated switch; don't overwrite.
		return
	end
	if pending.targetConfigID then
		-- A cross-spec switch is in progress; don't seed with the auto-loaded default.
		return
	end
	if not C_ClassTalents then
		return
	end
	local currentSpec = getCurrentSpecInfo()
	if not currentSpec then
		return
	end
	local id = C_ClassTalents.GetLastSelectedSavedConfigID and C_ClassTalents.GetLastSelectedSavedConfigID(currentSpec.specID)
	if id and id > 0 then
		addonTrackedConfigID = id
	end
end

local function onRelevantUpdate()
	tryFinalizePending()
	updateButton()
end

local eventsTable = {
	PLAYER_ENTERING_WORLD = function(self)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		local spec = getCurrentSpecInfo()
		lastKnownSpecID = spec and spec.specID
		addonTrackedConfigID = nil  -- clear so PLAYER_TALENT_UPDATE seeds from API
		onRelevantUpdate()
	end,
	ACTIVE_TALENT_GROUP_CHANGED = function()
		-- WoW fires this for both real spec changes and same-spec loadout switches.
		-- Only clear addonTrackedConfigID when the spec actually changed.
		-- Guard against nil: if the spec API is unavailable mid-event, don't clear.
		local currentSpec = getCurrentSpecInfo()
		local currentSpecID = currentSpec and currentSpec.specID
		if currentSpecID and currentSpecID ~= lastKnownSpecID then
			addonTrackedConfigID = nil
			lastKnownSpecID = currentSpecID
		end
		onRelevantUpdate()
	end,
	PLAYER_SPECIALIZATION_CHANGED = function()
		-- WoW fires this event for BOTH real spec changes AND same-spec loadout switches.
		-- Only clear addonTrackedConfigID when the spec actually changed, so that intra-spec
		-- loadout switches don't wipe out the config we just set.
		-- Do NOT call tryFinalizePending here: WoW auto-loads its default loadout for the new
		-- spec AFTER this event fires; finalize on PLAYER_TALENT_UPDATE instead.
		-- Guard against nil: if the spec API is unavailable mid-event, don't clear.
		local currentSpec = getCurrentSpecInfo()
		local currentSpecID = currentSpec and currentSpec.specID
		if currentSpecID and currentSpecID ~= lastKnownSpecID then
			addonTrackedConfigID = nil
			lastKnownSpecID = currentSpecID
		end
		updateButton()
	end,
	TRAIT_CONFIG_LIST_UPDATED = function()
		onRelevantUpdate()
	end,
	TRAIT_CONFIG_UPDATED = function()
		onRelevantUpdate()
	end,
	PLAYER_TALENT_UPDATE = function()
		-- Keep lastKnownSpecID current so PLAYER_SPECIALIZATION_CHANGED comparisons are accurate.
		local spec = getCurrentSpecInfo()
		if spec then lastKnownSpecID = spec.specID end
		-- tryFinalizePending runs first: ensures addonTrackedConfigID is set to our
		-- target before seedTrackedConfigFromAPI can overwrite it with the default.
		onRelevantUpdate()
		-- Seed from API only if no addon-initiated switch has set addonTrackedConfigID.
		seedTrackedConfigFromAPI()
	end,
}

frame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, ...)
	end
end)

frame:SetScript("OnClick", function(self, button, ...)
	if button == "LeftButton" then
		openTalentsAndLoadouts()
	end

	TitanPanelButton_OnClick(self, button, ...)
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
		icon = DefaultIcon,
		iconWidth = 16,
		category = "Information",
		version = VERSION,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			DisplayOnRightSide = true,
		},
		savedVariables = {
			ShowIcon = 1,
			ShowLabelText = 1,
			DisplayOnRightSide = false,
		},
	}

	updateDynamicIcon()
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
