-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local _, TSM = ...
local Queue = TSM.Crafting:NewPackage("Queue")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = { db = nil }
local QUEUE_DB_SCHEMA = {
	fields = {
		spellId = "number",
		profession = "string",
		players = "string",
		num = "number",
	},
	fieldAttributes = {
		spellId = { "unique" },
	}
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Queue.OnEnable()
	private.db = TSMAPI_FOUR.Database.New(QUEUE_DB_SCHEMA)
	for spellId, data in pairs(TSM.db.factionrealm.internalData.crafts) do
		Queue.SetNum(spellId, data.queued) -- sanitize / cache the number queued
	end
end

function Queue.CreateQuery()
	return private.db:NewQuery()
end

function Queue.SetNum(spellId, num)
	local craftInfo = TSM.db.factionrealm.internalData.crafts[spellId]
	if not craftInfo then
		TSM:LOG_ERR("Could not find craft: "..spellId)
		return
	end
	craftInfo.queued = max(TSMAPI_FOUR.Util.Round(num or 0), 0)
	local row = private.db:NewQuery()
		:Equal("spellId", spellId)
		:GetFirstResultAndRelease()
	if row and craftInfo.queued == 0 then
		-- delete this row
		private.db:DeleteRow(row)
	elseif row then
		-- update this row
		row:SetField("num", num)
		row:Save()
	elseif craftInfo.queued > 0 then
		-- insert a new row
		local players = TSMAPI_FOUR.Util.AcquireTempTable()
		for player in pairs(craftInfo.players) do
			tinsert(players, player)
		end
		local playersStr = strjoin(",", TSMAPI_FOUR.Util.UnpackAndReleaseTempTable(players))
		private.db:NewRow()
			:SetField("spellId", spellId)
			:SetField("profession", craftInfo.profession)
			:SetField("players", playersStr)
			:SetField("num", num)
			:Save()
	end
end

function Queue.GetNum(spellId)
	local row = private.db:NewQuery()
		:Equal("spellId", spellId)
		:GetFirstResultAndRelease()
	return row and row:GetField("num") or 0
end

function Queue.Add(spellId, quantity)
	Queue.SetNum(spellId, Queue.GetNum(spellId) + quantity)
end

function Queue.Remove(spellId, quantity)
	Queue.SetNum(spellId, Queue.GetNum(spellId) - quantity)
end

function Queue.Clear()
	local query = private.db:NewQuery()
		:Select("spellId")
	for _, spellId in query:Iterator(true) do
		local craftInfo = TSM.db.factionrealm.internalData.crafts[spellId]
		if craftInfo then
			craftInfo.queued = 0
		end
	end
	query:Release()
	private.db:Truncate()
end

function Queue.GetNumItems()
	local query = private.db:NewQuery()
	local num = query:Count()
	query:Release()
	return num
end

function Queue.GetTotalCostAndProfit()
	local totalCost, totalProfit = nil, nil
	local query = private.db:NewQuery()
		:Select("spellId", "num")
	for _, spellId, numQueued in query:Iterator(true) do
		local numResult = TSM.db.factionrealm.internalData.crafts[spellId] and TSM.db.factionrealm.internalData.crafts[spellId].numResult or 0
		local cost, _, profit = TSM.Crafting.Cost.GetCostsBySpellId(spellId)
		if cost then
			totalCost = (totalCost or 0) + cost * numQueued * numResult
		end
		if profit then
			totalProfit = (totalProfit or 0) + profit * numQueued * numResult
		end
	end
	query:Release()
	return totalCost, totalProfit
end

function Queue.RestockGroups(groups)
	private.db:SetQueryUpdatesPaused(true)
	for _, groupPath in ipairs(groups) do
		for operationName, operationSettings in TSMAPI_FOUR.Operations.Iterator("Crafting", groupPath) do
			if private.IsOperationValid(operationName, operationSettings) then
				for _, itemString in TSMAPI_FOUR.Groups.ItemIterator(groupPath) do
					private.RestockItem(itemString, operationSettings)
				end
			end
		end
	end
	private.db:SetQueryUpdatesPaused(false)
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.IsOperationValid(operationName, operationSettings)
	if operationSettings.minRestock > operationSettings.maxRestock then
		-- invalid cause min > max restock quantity (shouldn't happen)
		TSM:Printf(L["'%s' is an invalid operation! Min restock of %d is higher than max restock of %d."], operationName, operationSettings.minRestock, operationSettings.maxRestock)
		return false
	end
	return true
end

function private.RestockItem(itemString, operationSettings)
	local cheapestSpellId, cheapestCost = nil, nil
	for _, spellId in TSM.Crafting.GetSpellIdsByItem(itemString) do
		local cost = TSM.Crafting.Cost.GetCraftingCostBySpellId(spellId)
		if cost and (not cheapestCost or cost < cheapestCost) then
			cheapestSpellId = spellId
			cheapestCost = cost
		end
	end
	if not cheapestSpellId then
		-- can't craft this item
		return
	end
	local itemValue = TSM.Crafting.Cost.GetCraftedItemValue(itemString)
	local profit = itemValue and cheapestCost and (itemValue - cheapestCost) or nil
	local minProfit = operationSettings.minProfit and TSMAPI_FOUR.CustomPrice.GetValue(operationSettings.minProfit, itemString) or nil
	if operationSettings.minProfit and (not minProfit or not profit or profit < minProfit) then
		-- profit is too low
		return
	end

	local haveQuantity = TSMAPI_FOUR.Inventory.GetTotalQuantity(itemString)
	for guild, ignored in pairs(TSM.db.global.craftingOptions.ignoreGuilds) do
		if ignored then
			haveQuantity = haveQuantity - TSMAPI_FOUR.Inventory.GetGuildQuantity(itemString, guild)
		end
	end
	for player, ignored in pairs(TSM.db.global.craftingOptions.ignoreCharacters) do
		if ignored then
			haveQuantity = haveQuantity - TSMAPI_FOUR.Inventory.GetBagQuantity(itemString, player)
			haveQuantity = haveQuantity - TSMAPI_FOUR.Inventory.GetBankQuantity(itemString, player)
			haveQuantity = haveQuantity - TSMAPI_FOUR.Inventory.GetReagentBankQuantity(itemString, player)
			haveQuantity = haveQuantity - TSMAPI_FOUR.Inventory.GetAuctionQuantity(itemString, player)
			haveQuantity = haveQuantity - TSMAPI_FOUR.Inventory.GetMailQuantity(itemString, player)
		end
	end
	assert(haveQuantity >= 0)
	local neededQuantity = operationSettings.maxRestock - haveQuantity
	if neededQuantity <= 0 then
		-- don't need to queue any
		return
	elseif neededQuantity < operationSettings.minRestock then
		-- we're below the min restock quantity
		return
	end
	-- queue only if it satisfies all operation criteria
	Queue.SetNum(cheapestSpellId, floor(neededQuantity / TSM.db.factionrealm.internalData.crafts[cheapestSpellId].numResult))
end