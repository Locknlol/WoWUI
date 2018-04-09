-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local _, TSM = ...
local General = TSM.MainUI.Settings:NewPackage("General")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local LibDBIcon = LibStub("LibDBIcon-1.0")
local private = { frame = nil, characterList = {}, guildList = {}, chatFrameList = {} }



-- ============================================================================
-- Module Functions
-- ============================================================================

function General.OnInitialize()
	TSM.MainUI.Settings.RegisterSettingPage("General Settings", "top", private.GetGeneralSettingsFrame)
	TSM.Sync.Connection.RegisterConnectionChangedCallback(private.SyncConnectionChangedCallback)
end



-- ============================================================================
-- General Settings UI
-- ============================================================================

function private.GetGeneralSettingsFrame()
	wipe(private.chatFrameList)
	local defaultChatFrame = nil
	for i = 1, NUM_CHAT_WINDOWS do
		local name = strlower(GetChatWindowInfo(i) or "")
		if DEFAULT_CHAT_FRAME == _G["ChatFrame"..i] then
			defaultChatFrame = name
		end
		if name ~= "" then
			tinsert(private.chatFrameList, name)
		end
	end
	if not tContains(private.chatFrameList, TSM.db.global.coreOptions.chatFrame) then
		TSM.db.global.coreOptions.chatFrame = defaultChatFrame
	end

	wipe(private.characterList)
	for _, character in TSMAPI_FOUR.PlayerInfo.CharacterIterator(true) do
		if character ~= UnitName("player") then
			tinsert(private.characterList, character)
		end
	end

	wipe(private.guildList)
	for guild in TSMAPI_FOUR.PlayerInfo.GuildIterator(true) do
		tinsert(private.guildList, guild)
	end

	return TSMAPI_FOUR.UI.NewElement("ScrollFrame", "generalSettings")
		:SetStyle("padding.left", 12)
		:SetStyle("padding.right", 12)
		:SetScript("OnUpdate", private.FrameOnUpdate)
		:SetScript("OnHide", private.FrameOnHide)
		:AddChild(TSM.MainUI.Settings.CreateHeading("generalHeading", L["General Options"])
			:SetStyle("margin.bottom", 16)
		)
		:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "checkboxLine")
			:SetLayout("HORIZONTAL")
			:SetStyle("height", 28)
			:SetStyle("margin.bottom", 8)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Checkbox", "minimapCheckbox")
				:SetStyle("autoWidth", true)
				:SetStyle("height", 24)
				:SetStyle("margin.left", -5)
				:SetStyle("margin.right", 16)
				:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
				:SetStyle("fontHeight", 12)
				:SetText(L["Hide minimap icon"])
				:SetSettingInfo(TSM.db.global.coreOptions.minimapIcon, "hide")
				:SetScript("OnValueChanged", private.MinimapOnValueChanged)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Checkbox", "globalOperationCheckbox")
				:SetStyle("height", 24)
				:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
				:SetStyle("fontHeight", 12)
				:SetText(L["Store operations globally"])
				:SetScript("OnValueChanged", private.GlobalOperationsOnValueChanged)
			)
		)
		:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "dropdownLabelLine")
			:SetLayout("HORIZONTAL")
			:SetStyle("height", 18)
			:SetStyle("margin.bottom", 4)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "chatTabLabel")
				:SetStyle("margin.right", 16)
				:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
				:SetStyle("fontHeight", 14)
				:SetStyle("textColor", "#ffffff")
				:SetText(L["Chat Tab"])
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "forgetLabel")
				:SetStyle("margin.right", 16)
				:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
				:SetStyle("fontHeight", 14)
				:SetStyle("textColor", "#ffffff")
				:SetText(L["Forget Character"])
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "ignoreLabel")
				:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
				:SetStyle("fontHeight", 14)
				:SetStyle("textColor", "#ffffff")
				:SetText(L["Ignore Guilds"])
			)
		)
		:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "dropdownLabelLine")
			:SetLayout("HORIZONTAL")
			:SetStyle("height", 18)
			:SetStyle("margin.bottom", 24)
			:AddChild(TSMAPI_FOUR.UI.NewElement("SelectionDropdown", "chatTabDropdown")
				:SetStyle("margin.right", 16)
				:SetItems(private.chatFrameList, private.chatFrameList)
				:SetSettingInfo(TSM.db.global.coreOptions, "chatFrame")
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("SelectionDropdown", "forgetDropdown")
				:SetStyle("margin.right", 16)
				:SetItems(private.characterList, private.characterList)
				:SetScript("OnSelectionChanged", private.ForgetCharacterOnSelectionChanged)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("MultiselectionDropdown", "ignoreDropdown")
				:SetItems(private.guildList, private.guildList)
				:SetSettingInfo(TSM.db.factionrealm.coreOptions, "ignoreGuilds")
			)
		)
		:AddChild(TSM.MainUI.Settings.CreateHeading("profilesHeading", L["Profiles"]))
		:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "profilesDesc")
			:SetStyle("height", 18)
			:SetStyle("margin.bottom", 16)
			:SetStyle("fontHeight", 14)
			:SetStyle("textColor", "#ffffff")
			:SetText(L["Below, you can manage your profiles which allow you to have entirely different sets of groups."])
		)
		:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "currentProfileHeading")
			:SetStyle("height", 18)
			:SetStyle("margin.bottom", 4)
			:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
			:SetStyle("fontHeight", 14)
			:SetStyle("textColor", "#ffffff")
			:SetText(L["Current Profiles"])
		)
		:AddChildrenWithFunction(private.AddProfileRows)
		:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "newProfileLine")
			:SetLayout("HORIZONTAL")
			:SetStyle("height", 26)
			:SetStyle("margin.top", 8)
			:SetStyle("margin.bottom", 24)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Input", "newProfileInput")
				:SetStyle("margin.right", 16)
				:SetStyle("font", TSM.UI.Fonts.MontserratRegular)
				:SetStyle("fontHeight", 14)
				:SetStyle("justifyH", "LEFT")
				:SetStyle("hintJustifyH", "LEFT")
				:SetHintText(L["Enter a name for the new profile"])
				:SetScript("OnEnterPressed", private.NewProfileInputOnEnterPressed)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("ActionButton", "newProfileBtn")
				:SetStyle("width", 240)
				:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
				:SetStyle("fontHeight", 14)
				:SetText(L["CREATE NEW PROFILE"])
				:SetScript("OnClick", private.NewProfileBtnOnClick)
			)
		)
		:AddChild(TSM.MainUI.Settings.CreateHeading("accountSyncHeader", L["Account Syncing"]))
		:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "accountSyncDesc")
			:SetStyle("height", 18)
			:SetStyle("margin.bottom", 4)
			:SetStyle("fontHeight", 14)
			:SetStyle("textColor", "#ffffff")
			:SetText(L["TSM can sync data automatically between multiple accounts."])
		)
		:AddChildrenWithFunction(private.AddAccountSyncRows)
		:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "accountSyncLine")
			:SetLayout("HORIZONTAL")
			:SetStyle("height", 26)
			:SetStyle("margin.top", 8)
			:SetStyle("margin.bottom", 24)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Input", "newAccountSyncInput")
				:SetStyle("margin.right", 16)
				:SetStyle("font", TSM.UI.Fonts.MontserratRegular)
				:SetStyle("fontHeight", 14)
				:SetStyle("justifyH", "LEFT")
				:SetStyle("hintJustifyH", "LEFT")
				:SetHintText(L["Enter name of logged-in character from other account"])
				:SetScript("OnEnterPressed", private.NewAccountSyncInputOnEnterPressed)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("ActionButton", "newAccountSyncBtn")
				:SetStyle("width", 240)
				:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
				:SetStyle("fontHeight", 14)
				:SetText(L["SETUP ACCOUNT SYNC"])
				:SetScript("OnClick", private.NewAccountSyncBtnOnClick)
			)
		)
		:AddChild(TSM.MainUI.Settings.CreateHeading("twitterHeader", L["Twitter Integration"]))
		:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "twitterDesc")
			:SetStyle("height", 36)
			:SetStyle("margin.bottom", 8)
			:SetStyle("fontHeight", 14)
			:SetStyle("textColor", "#ffffff")
			:SetText(L["If you have WoW's Twitter integration setup, TSM will add a share link to its enhanced auction sale / purchase messages, as well as replace URLs with a TSM link."])
		)
		:AddChildrenWithFunction(private.AddTwitterSetting)
end

function private.AddProfileRows(frame)
	for _, profileName in TSM.db:ProfileIterator() do
		local isCurrentProfile = profileName == TSM.db:GetCurrentProfile()
		frame:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "profileRow_"..profileName)
			:SetLayout("HORIZONTAL")
			:SetStyle("height", 28)
			:SetStyle("margin.left", -16)
			:SetStyle("margin.right", -12)
			:SetStyle("padding.left", 16)
			:SetStyle("padding.right", 12)
			:SetScript("OnEnter", private.ProfileRowOnEnter)
			:SetScript("OnLeave", private.ProfileRowOnLeave)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Checkbox", "checkbox")
				:SetStyle("autoWidth", true)
				:SetStyle("margin.left", -5)
				:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
				:SetStyle("fontHeight", 12)
				:SetText(profileName)
				:SetChecked(isCurrentProfile)
				:SetScript("OnValueChanged", private.ProfileCheckboxOnValueChanged)
				:SetScript("OnEnter", TSM.UI.GetPropagateScriptFunc("OnEnter"))
				:SetScript("OnLeave", TSM.UI.GetPropagateScriptFunc("OnLeave"))
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Spacer", "spacer"))
			:AddChild(TSMAPI_FOUR.UI.NewElement("ActionButton", "duplicateBtn")
				:SetStyle("width", 110)
				:SetStyle("height", 20)
				:SetStyle("margin.right", 8)
				:SetContext(profileName)
				:SetText(L["Duplicate"])
				:SetScript("OnClick", private.DuplicateProfileOnClick)
				:SetScript("OnEnter", TSM.UI.GetPropagateScriptFunc("OnEnter"))
				:SetScript("OnLeave", TSM.UI.GetPropagateScriptFunc("OnLeave"))
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("ActionButton", "deleteResetBtn")
				:SetStyle("width", 110)
				:SetStyle("height", 20)
				:SetContext(profileName)
				:SetText(isCurrentProfile and RESET or DELETE)
				:SetScript("OnClick", isCurrentProfile and private.ResetProfileOnClick or private.RemoveProfileOnClick)
				:SetScript("OnEnter", TSM.UI.GetPropagateScriptFunc("OnEnter"))
				:SetScript("OnLeave", TSM.UI.GetPropagateScriptFunc("OnLeave"))
			)
		)
		frame:GetElement("profileRow_"..profileName..".duplicateBtn"):Hide()
		frame:GetElement("profileRow_"..profileName..".deleteResetBtn"):Hide()
	end
end

function private.AddAccountSyncRows(frame)
	local newAccountStatusText = TSM.Sync.Connection.GetNewAccountStatus()
	if newAccountStatusText then
		frame:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "accountSyncRow_New")
			:SetLayout("HORIZONTAL")
			:SetStyle("height", 28)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "status")
				:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
				:SetStyle("fontHeight", 12)
				:SetText(newAccountStatusText)
			)
		)
	end
	for _, account in TSM.db:SyncAccountIterator() do
		local characters = TSMAPI_FOUR.Util.AcquireTempTable()
		for _, character in TSM.db:FactionrealmCharacterByAccountIterator(account) do
			tinsert(characters, character)
		end
		sort(characters)
		local statusText = TSM.Sync.Connection.GetStatus(account).." | "..table.concat(characters, ", ")
		TSMAPI_FOUR.Util.ReleaseTempTable(characters)
		frame:AddChild(TSMAPI_FOUR.UI.NewElement("Frame", "accountSyncRow_"..account)
			:SetLayout("HORIZONTAL")
			:SetStyle("height", 28)
			:SetStyle("margin.left", -16)
			:SetStyle("margin.right", -12)
			:SetStyle("padding.left", 16)
			:SetStyle("padding.right", 12)
			:SetScript("OnEnter", private.AccountSyncRowOnEnter)
			:SetScript("OnLeave", private.AccountSyncRowOnLeave)
			:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "status")
				:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
				:SetStyle("fontHeight", 12)
				:SetText(statusText)
			)
			:AddChild(TSMAPI_FOUR.UI.NewElement("ActionButton", "removeBtn")
				:SetStyle("width", 110)
				:SetStyle("height", 20)
				:SetContext(account)
				:SetText(REMOVE)
				:SetScript("OnClick", private.RemoveAccountSyncOnClick)
				:SetScript("OnEnter", TSM.UI.GetPropagateScriptFunc("OnEnter"))
				:SetScript("OnLeave", TSM.UI.GetPropagateScriptFunc("OnLeave"))
			)
		)
		frame:GetElement("accountSyncRow_"..account..".removeBtn"):Hide()
	end
end

function private.AddTwitterSetting(frame)
	if C_Social.IsSocialEnabled() or true then
		frame:AddChild(TSMAPI_FOUR.UI.NewElement("Checkbox", "checkbox")
			:SetStyle("height", 28)
			:SetStyle("margin.left", -5)
			:SetStyle("font", TSM.UI.Fonts.MontserratMedium)
			:SetStyle("fontHeight", 12)
			:SetSettingInfo(TSM.db.global.coreOptions, "tsmItemTweetEnabled")
			:SetText(L["Enable tweet enhancement"])
		)
	else
		frame:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "label")
			:SetStyle("textColor", "#c41f3b")
			:SetStyle("height", 20)
			:SetStyle("fontHeight", 18)
			:SetStyle("justifyH", "CENTER")
			:SetText(L["Twitter Integration Not Enabled"])
		)
	end
end



-- ============================================================================
-- Local Script Handlers
-- ============================================================================

function private.SyncConnectionChangedCallback()
	if private.frame then
		private.frame:GetParentElement():ReloadContent()
	end
end

function private.FrameOnUpdate(frame)
	frame:SetScript("OnUpdate", nil)
	private.frame = frame
end

function private.FrameOnHide(frame)
	private.frame = nil
end

function private.MinimapOnValueChanged(self, value)
	if value then
		LibDBIcon:Hide("TradeSkillMaster")
	else
		LibDBIcon:Show("TradeSkillMaster")
	end
end

function private.GlobalOperationsOnValueChanged(checkbox, value)
	-- restore the previous value until it's confirmed
	checkbox:SetChecked(not value, true)
	local desc = L["If you have multiple profile set up with operations, enabling this will cause all but the current profile's operations to be irreversibly lost. Are you sure you want to continue?"]
	checkbox:GetBaseElement():ShowConfirmationDialog(L["Global Operation Confirmation"], desc, OKAY, private.GlobalOperationsConfirmed, checkbox, value)
end

function private.GlobalOperationsConfirmed(checkbox, newValue)
	checkbox:SetChecked(newValue, true)
	-- we shouldn't be running the OnProfileUpdated callback while switching profiles
	TSM.Modules.ignoreProfileUpdated = true
	TSM.db.global.coreOptions.globalOperations = newValue
	if TSM.db.global.coreOptions.globalOperations then
		-- move current profile to global
		TSM.db.global.userData.operations = CopyTable(TSM.db.profile.userData.operations)
		-- clear out old operations
		for profile in TSMAPI:GetTSMProfileIterator() do
			TSM.db.profile.userData.operations = nil
		end
	else
		-- move global to all profiles
		for profile in TSMAPI:GetTSMProfileIterator() do
			TSM.db.profile.userData.operations = CopyTable(TSM.db.global.userData.operations)
		end
		-- clear out old operations
		TSM.db.global.userData.operations = nil
	end
	TSM.Modules.ignoreProfileUpdated = false
	TSM.Modules.ProfileUpdated()
end

function private.ChatTabOnSelectionChanged(self, selection)
	TSM.db.global.coreOptions.chatFrame = selection
end

function private.ForgetCharacterOnSelectionChanged(self)
	local character = self:GetSelectedItem()
	if not character then return end
	TSM.db:RemoveSyncCharacter(character)
	TSM.db.factionrealm.internalData.pendingMail[character] = nil
	TSM.db.factionrealm.internalData.characterGuilds[character] = nil
	TSM:Printf(L["%s removed."], character)
	assert(TSMAPI_FOUR.Util.TableRemoveByValue(private.characterList, character) == 1)
	self:SetSelectedItem(nil)
		:SetItems(private.characterList)
		:Draw()
end

function private.ProfileRowOnEnter(frame)
	frame:SetStyle("background", "#30ffd839")
	if not frame:GetElement("checkbox"):IsChecked() then
		frame:GetElement("duplicateBtn"):Show()
	end
	frame:GetElement("deleteResetBtn"):Show()
	frame:Draw()
end

function private.ProfileRowOnLeave(frame)
	frame:SetStyle("background", nil)
	frame:GetElement("duplicateBtn"):Hide()
	frame:GetElement("deleteResetBtn"):Hide()
	frame:Draw()
end

function private.ProfileCheckboxOnValueChanged(checkbox, value)
	if not value then
		-- can't uncheck profile checkboxes
		checkbox:SetChecked(true,  true)
		checkbox:Draw()
		return
	end
	-- uncheck the current profile row
	local currentProfileRow = checkbox:GetElement("__parent.__parent.profileRow_"..TSM.db:GetCurrentProfile())
	currentProfileRow:GetElement("checkbox")
		:SetChecked(false, true)
	currentProfileRow:GetElement("deleteResetBtn")
		:SetText(DELETE)
		:SetScript("OnClick", private.RemoveProfileOnClick)
	currentProfileRow:Draw()
	-- set the profile
	TSM.db:SetProfile(checkbox:GetText())
	-- set this row as the current one
	checkbox:GetElement("__parent.deleteResetBtn")
		:SetText(RESET)
		:SetScript("OnClick", private.ResetProfileOnClick)
		:Draw()
end

function private.DuplicateProfileOnClick(button)
	button:SetPressed(false)
		:Draw()
	local profileName = button:GetContext()
	local desc = format(L["This will copy the settings from '%s' into your currently-active one."], profileName)
	button:GetBaseElement():ShowConfirmationDialog(L["Duplicate Profile Confirmation"], desc, OKAY, private.DuplicateProfileConfirmed, profileName)
end

function private.DuplicateProfileConfirmed(profileName)
	TSM.db:CopyProfile(profileName)
end

function private.ResetProfileOnClick(button)
	button:SetPressed(false)
		:Draw()
	local desc = L["This will reset all groups and operations (if not stored globally) to be wiped from this profile."]
	button:GetBaseElement():ShowConfirmationDialog(L["Reset Profile Confirmation"], desc, OKAY, private.ResetProfileConfirmed)
end

function private.ResetProfileConfirmed()
	TSM.db:ResetProfile()
end

function private.RemoveProfileOnClick(button)
	button:SetPressed(false)
		:Draw()
	local profileName = button:GetContext()
	local desc = format(L["This will permanently delete the '%s' profile."], profileName)
	button:GetBaseElement():ShowConfirmationDialog(L["Delete Profile Confirmation"], desc, OKAY, private.DeleteProfileConfirmed, button, profileName)
end

function private.DeleteProfileConfirmed(button, profileName)
	TSM.db:DeleteProfile(profileName)
	button:GetParentElement():GetParentElement():GetParentElement():ReloadContent()
end

function private.NewProfileInputOnEnterPressed(input)
	input:GetElement("__parent.newProfileBtn"):Click()
end

function private.NewProfileBtnOnClick(button)
	button:SetPressed(false)
		:Draw()
	local profileName = strtrim(button:GetElement("__parent.newProfileInput"):GetText())
	if not TSM.db:IsValidProfileName(profileName) then
		return TSM:Print(L["This is not a valid profile name. Profile names must be at least one character long and may not contain '@' characters."])
	end
	TSM.db:SetProfile(profileName)
	button:GetParentElement():GetParentElement():GetParentElement():ReloadContent()
end

function private.AccountSyncRowOnEnter(frame)
	frame:SetStyle("background", "#30ffd839")
	frame:GetElement("removeBtn"):Show()
	frame:Draw()
end

function private.AccountSyncRowOnLeave(frame)
	frame:SetStyle("background", nil)
	frame:GetElement("removeBtn"):Hide()
	frame:Draw()
end

function private.RemoveAccountSyncOnClick(button)
	TSM.Sync.Connection.Remove(button:GetContext())
	button:GetParentElement():GetParentElement():GetParentElement():ReloadContent()
	TSM:Print(L["Account sync removed. Please delete the account sync from the other account as well."])
end

function private.NewAccountSyncInputOnEnterPressed(input)
	input:GetElement("__parent.newAccountSyncBtn"):Click()
end

function private.NewAccountSyncBtnOnClick(button)
	button:SetPressed(false)
		:Draw()
	local input = button:GetElement("__parent.newAccountSyncInput")
	local character = strtrim(input:GetText())
	if TSM.Sync.Connection.Establish(character) then
		TSM:Printf(L["Establishing connection to %s. Make sure that you've entered this character's name on the other account."], character)
		private.SyncConnectionChangedCallback()
	else
		input:SetText("")
		input:Draw()
	end
end