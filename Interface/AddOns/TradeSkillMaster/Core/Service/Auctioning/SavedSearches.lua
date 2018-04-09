-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local _, TSM = ...
local SavedSearches = TSM.Auctioning:NewPackage("SavedSearches")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = { db = nil }
local FILTER_SEP = "\001"
local SAVED_SEARCHES_SCHEMA = {
	fields = {
		index = "number",
		lastSearch = "number",
		isFavorite = "boolean",
		searchType = "string",
		name = "string",
		filter = "string",
	}
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function SavedSearches.OnInitialize()
	-- remove duplicates
	local keepSearch = TSMAPI_FOUR.Util.AcquireTempTable()
	for i, data in ipairs(TSM.db.global.userData.savedAuctioningSearches) do
		local filter = data.filter
		if not keepSearch[filter] then
			keepSearch[filter] = data
		else
			if data.isFavorite == keepSearch[filter].isFavorite then
				if data.lastSearch > keepSearch[filter].lastSearch then
					keepSearch[filter] = data
				end
			elseif data.isFavorite then
				keepSearch[filter] = data
			end
		end
	end
	for i = #TSM.db.global.userData.savedAuctioningSearches, 1, -1 do
		if not keepSearch[TSM.db.global.userData.savedAuctioningSearches[i].filter] then
			tremove(TSM.db.global.userData.savedAuctioningSearches, i)
		end
	end
	TSMAPI_FOUR.Util.ReleaseTempTable(keepSearch)

	private.db = TSMAPI_FOUR.Database.New(SAVED_SEARCHES_SCHEMA)
	for i, data in ipairs(TSM.db.global.userData.savedAuctioningSearches) do
		assert(data.searchType == "postItems" or data.searchType == "postGroups" or data.searchType == "cancelGroups")
		private.db:NewRow()
			:SetField("index", i)
			:SetField("lastSearch", data.lastSearch)
			:SetField("isFavorite", data.isFavorite and true or false)
			:SetField("searchType", data.searchType)
			:SetField("filter", data.filter)
			:SetField("name", private.GetSearchName(data.filter, data.searchType))
			:Save()
	end
end

function SavedSearches.CreateRecentSearchesQuery()
	return private.db:NewQuery()
		:OrderBy("lastSearch", false)
end

function SavedSearches.CreateFavoriteSearchesQuery()
	return private.db:NewQuery()
		:Equal("isFavorite", true)
		:OrderBy("lastSearch", false)
end

function SavedSearches.SetSearchIsFavorite(dbRow, isFavorite)
	local data = TSM.db.global.userData.savedAuctioningSearches[dbRow:GetField("index")]
	data.isFavorite = isFavorite or nil
	dbRow:SetField("isFavorite",  isFavorite)
		:Save()
end

function SavedSearches.DeleteSearch(dbRow)
	local index = dbRow:GetField("index")
	tremove(TSM.db.global.userData.savedAuctioningSearches, index)
	private.db:SetQueryUpdatesPaused(true)
	private.db:DeleteRow(dbRow)
	-- need to decrement the index fields of all the rows which got shifted up
	local query = private.db:NewQuery()
		:GreaterThanOrEqual("index", index)
	for _, row in query:Iterator() do
		row:DecrementField("index")
			:Save()
	end
	query:Release()
	private.db:SetQueryUpdatesPaused(false)
end

function SavedSearches.RecordSearch(searchList, searchType)
	assert(searchType == "postItems" or searchType == "postGroups" or searchType == "cancelGroups")
	local filter = table.concat(searchList, FILTER_SEP)
	local found = false
	for i, data in ipairs(TSM.db.global.userData.savedAuctioningSearches) do
		if data.filter == filter then
			data.lastSearch = time()
			local query = private.db:NewQuery()
				:Equal("index", i)
			local dbRow = query:GetSingleResult()
			query:Release()
			dbRow:SetField("lastSearch", data.lastSearch)
			dbRow:Save()
			found = true
			break
		end
	end
	if not found then
		local data = {
			filter = filter,
			lastSearch = time(),
			searchType = searchType,
			isFavorite = nil,
		}
		tinsert(TSM.db.global.userData.savedAuctioningSearches, data)
		private.db:NewRow()
			:SetField("index", #TSM.db.global.userData.savedAuctioningSearches)
			:SetField("lastSearch", data.lastSearch)
			:SetField("isFavorite", data.isFavorite and true or false)
			:SetField("searchType", data.searchType)
			:SetField("filter", data.filter)
			:SetField("name", private.GetSearchName(data.filter, data.searchType))
			:Save()
	end
end

function SavedSearches.FilterIterator(dbRow)
	return TSMAPI_FOUR.Util.VarargIterator(strsplit(FILTER_SEP, dbRow:GetField("filter")))
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.GetSearchName(filter, searchType)
	local filters = TSMAPI_FOUR.Util.AcquireTempTable()
	local searchTypeStr, numFiltersStr = nil, nil
	if searchType == "postGroups" or searchType == "cancelGroups" then
		for _, groupPath in TSMAPI_FOUR.Util.VarargIterator(strsplit(FILTER_SEP, filter)) do
			local _, groupName = TSMAPI_FOUR.Groups.SplitPath(groupPath)
			local level = select('#', strsplit(TSM.CONST.GROUP_SEP, groupPath))
			local color = gsub(TSM.UI.GetGroupLevelColor(level), "#", "|cff")
			tinsert(filters, color..groupName.."|r")
		end
		searchTypeStr = searchType == "postGroups" and L["Post Scan"] or L["Cancel Scan"]
		numFiltersStr = #filters == 1 and L["1 Group"] or format(L["%d Groups"], #filters)
	elseif searchType == "postItems" then
		local numItems = 0
		for _, itemString in TSMAPI_FOUR.Util.VarargIterator(strsplit(FILTER_SEP, filter)) do
			numItems = numItems + 1
			local coloredName = TSM.UI.GetColoredItemName(itemString)
			if coloredName then
				tinsert(filters, coloredName)
			end
		end
		searchTypeStr = L["Post Scan"]
		numFiltersStr = numItems == 1 and L["1 Item"] or format(L["%d Items"], numItems)
	else
		error("Unknown searchType: "..tostring(searchType))
	end
	local groupList = nil
	if #filters > 10 then
		groupList = table.concat(filters, ", ", 1, 10)..",..."
		TSMAPI_FOUR.Util.ReleaseTempTable(filters)
	else
		groupList = strjoin(", ", TSMAPI_FOUR.Util.UnpackAndReleaseTempTable(filters))
	end
	return format("%s (%s): %s", searchTypeStr, numFiltersStr, groupList)
end