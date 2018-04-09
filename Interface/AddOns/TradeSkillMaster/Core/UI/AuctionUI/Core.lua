-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local _, TSM = ...
local AuctionUI = TSM.UI:NewPackage("AuctionUI")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {
	topLevelPages = {},
	frame = nil,
	isSwitching = false,
	scanningPage = nil,
}
local HEADER_LINE_TEXT_MARGIN = { right = 8 }
local HEADER_LINE_MARGIN = { top = 16, bottom = 16 }
local MIN_FRAME_SIZE = { width = 830, height = 587 }



-- ============================================================================
-- Module Functions
-- ============================================================================

function AuctionUI.OnInitialize()
	UIParent:UnregisterEvent("AUCTION_HOUSE_SHOW")
	TSMAPI_FOUR.Event.Register("AUCTION_HOUSE_SHOW", private.ShowAuctionFrame)
	TSMAPI_FOUR.Event.Register("AUCTION_HOUSE_CLOSED", private.HideAuctionFrame)
	TSMAPI_FOUR.Delay.AfterTime(1, function() LoadAddOn("Blizzard_AuctionUI") end)
end

function AuctionUI.RegisterTopLevelPage(name, texturePack, callback)
	tinsert(private.topLevelPages, { name = name, texturePack = texturePack, callback = callback })
end

function AuctionUI.CreateHeadingLine(id, text)
	return TSMAPI_FOUR.UI.NewElement("Frame", id)
		:SetLayout("HORIZONTAL")
		:SetStyle("height", 34)
		:SetStyle("margin", HEADER_LINE_MARGIN)
		:AddChild(TSMAPI_FOUR.UI.NewElement("Text", "text")
			:SetStyle("textColor", "#79a2ff")
			:SetStyle("fontHeight", 24)
			:SetStyle("margin", HEADER_LINE_TEXT_MARGIN)
			:SetStyle("autoWidth", true)
			:SetText(text)
		)
		:AddChild(TSMAPI_FOUR.UI.NewElement("Texture", "vline")
			:SetStyle("color", "#e2e2e2")
			:SetStyle("height", 2)
		)
end

function AuctionUI.StartingScan(pageName)
	if private.scanningPage and private.scanningPage ~= pageName then
		TSM:Printf(L["A scan is already in progress in another page (%s). Please stop that scan before starting another one."], private.scanningPage)
		return false
	end
	private.scanningPage = pageName
	TSM:LOG_INFO("Starting scan %s", pageName)
	if private.frame then
		private.frame:SetPulsingNavButton(private.scanningPage)
	end
	return true
end

function AuctionUI.EndedScan(pageName)
	if private.scanningPage == pageName then
		TSM:LOG_INFO("Ended scan %s", pageName)
		private.scanningPage = nil
		if private.frame then
			private.frame:SetPulsingNavButton()
		end
	end
end



-- ============================================================================
-- Main Frame
-- ============================================================================

function private.ShowAuctionFrame()
	if private.frame then
		return
	end
	if not private.hasShown then
		private.hasShown = true
		local tabId = AuctionFrame.numTabs + 1
		local tab = CreateFrame("Button", "AuctionFrameTab"..tabId, AuctionFrame, "AuctionTabTemplate")
		tab:Hide()
		tab:SetID(tabId)
		tab:SetText("|cff99ffffTSM4|r")
		tab:SetNormalFontObject(GameFontHighlightSmall)
		tab:SetPoint("LEFT", _G["AuctionFrameTab"..tabId-1], "RIGHT", -8, 0)
		tab:Show()
		PanelTemplates_SetNumTabs(AuctionFrame, tabId)
		PanelTemplates_EnableTab(AuctionFrame, tabId)
		tab:SetScript("OnClick", private.TSMTabOnClick)
	end
	private.frame = private.CreateMainFrame()
	private.frame:Show()
	private.frame:Draw()
end

function private.HideAuctionFrame()
	if not private.frame then
		return
	end
	private.frame:Hide()
	assert(not private.frame)
end

function private.CreateMainFrame()
	local frame = TSMAPI_FOUR.UI.NewElement("LargeApplicationFrame", "base")
		:SetParent(UIParent)
		:SetMinResize(MIN_FRAME_SIZE.width, MIN_FRAME_SIZE.height)
		:SetContextTable(TSM.db.global.internalData.auctionUIFrameContext, TSM.db:GetDefaultReadOnly("global", "internalData", "auctionUIFrameContext"))
		:SetStyle("strata", "HIGH")
		:SetTitle("TSM Auction House")
		:SetScript("OnHide", private.BaseFrameOnHide)
	frame:GetElement("titleFrame")
		:AddChild(TSMAPI_FOUR.UI.NewElement("Button", "switchBtn")
			:SetStyle("width", 131)
			:SetStyle("height", 16)
			:SetStyle("backgroundTexturePack", "uiFrames.DefaultUIButton")
			:SetStyle("margin", { left = 8 })
			:SetStyle("font", TSM.UI.Fonts.MontserratBold)
			:SetStyle("fontHeight", 10)
			:SetStyle("textColor", "#2e2e2e")
			:SetText(L["Switch to WoW UI"])
			:SetScript("OnClick", private.SwitchBtnOnClick)
		)
	for _, info in ipairs(private.topLevelPages) do
		frame:AddNavButton(info.name, info.texturePack, info.callback)
	end
	return frame
end



-- ============================================================================
-- Local Script Handlers
-- ============================================================================

function private.BaseFrameOnHide(frame)
	assert(frame == private.frame)
	frame:Release()
	private.frame = nil
	if not private.isSwitching then
		CloseAuctionHouse()
	end
end

function private.GetNavFrame(_, path)
	return private.topLevelPages.callback[path]()
end

function private.SwitchBtnOnClick(button)
	private.isSwitching = true
	private.HideAuctionFrame()
	UIParent_OnEvent(UIParent, "AUCTION_HOUSE_SHOW")
	private.isSwitching = false
end

local function NoOp()
	-- do nothing - what did you expect?
end
function private.TSMTabOnClick()
	-- Replace CloseAuctionHouse() with a no-op while hiding the AH frame so we don't stop interacting with the AH NPC
	local origCloseAuctionHouse = CloseAuctionHouse
	CloseAuctionHouse = NoOp
	AuctionFrame_Hide()
	CloseAuctionHouse = origCloseAuctionHouse
	private.ShowAuctionFrame()
end