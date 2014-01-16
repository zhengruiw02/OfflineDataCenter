local ODC = LibStub("AceAddon-3.0"):GetAddon("OfflineDataCenter")
local ODC_SF = ODC:GetModule("SortFilter")
if not ODC_SF then return end
local ODC_Bag = ODC:NewModule("OfflineBag", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("OfflineDataCenter")
ODC_Bag.description = L["Offline Bag"]
ODC_Bag.type = "tab"
ODC_Bag.name = "OfflineBag"
ODC_Bag.tabs = {
	["bag"] = {
		["Textures"] = "Interface\\Buttons\\Button-Backpack-Up",
		["Tooltip"] = L['Offline Bag'],
		["CallTabFunc"] = function()
			ODC_SF:CreateOrShowSubFrame("bag")
			ODC_SF:Update("sort")
		end,
		["CharChangedFunc"] = function()
			ODC_SF:Update("sort")
		end,
	},
	["bank"] = {
		["Textures"] = "Interface\\ICONS\\ACHIEVEMENT_GUILDPERK_MOBILEBANKING.blp",
		["Tooltip"] = L['Offline Bank'],
		["CallTabFunc"] = function()
			ODC_SF:CreateOrShowSubFrame("bank")
			ODC_SF:Update("sort")
		end,
		["CharChangedFunc"] = function()
			ODC_SF:Update("sort")
		end,
	},
}

local playername, selectChar, selectTab = ODC.playername, ODC.selectChar, ODC.selectTab

local function AddItem(itemLink, bagID, slotID)
	local dest
	if bagID <= 4 and bagID >= 0 then
		dest = "bag"
	else
		dest = "bank"
	end
	if not ODC_DB[playername][dest][bagID] then
		local numSlots = GetContainerNumSlots(bagID)
		ODC_DB[playername][dest][bagID] = {slotMAX = numSlots}
	end
	if not itemLink then
		ODC_DB[playername][dest][bagID][slotID] = nil
	else
		local _, count, _, _, _ = GetContainerItemInfo(bagID, slotID)
		ODC_DB[playername][dest][bagID][slotID] = {count = count, itemLink = itemLink}
	end
end

--[[
ODC_DB[charName] structure:
				bagID		slotID
["bag/bank"]= {	[1]			[1]			{	.count
				[n]			--.slotMAX		.itemLink
				.itemCountBank?
				.itemCountBag?
]]
function ODC_Bag:CheckBags()
	local BagIDs = self.isBankOpened and {-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11} or {0, 1, 2, 3, 4}
	local numSlots, full = GetNumBankSlots();
	ODC_DB[playername]["bag"].money = GetMoney()
	for k, bagID in pairs(BagIDs) do
		local numSlots = GetContainerNumSlots(bagID)
		if numSlots > 0 then
			--ODC_DB[playername]["bag\bank"][bagID] = {slotMAX = numSlots}
			for slotIndex = 1, numSlots do
				local itemLink = GetContainerItemLink(bagID, slotIndex)
				AddItem(itemLink, bagID, slotIndex)
			end
		end
	end
	
	if ODC.Frame:IsVisible() and selectChar == playername and (selectTab == "bag" or selectTab == "bank") then
		ODC_SF:Update("sort")
	end
end

function ODC_Bag:BAG_UPDATE_DELAYED()
	self:CancelAllTimers()
	self:ScheduleTimer("CheckBags", 2)
end

function ODC_Bag:BANKFRAME_OPENED()
	self.isBankOpened = true
	self:CheckBags()
end

function ODC_Bag:BANKFRAME_CLOSED()
	self.isBankOpened = nil
end

ODC_Bag.selectTabCallbackFunc = function(selectedTab)
	selectTab = selectedTab
end

ODC_Bag.selectCharCallbackFunc = function(selectedChar)
	selectChar = selectedChar
end

function ODC_Bag:OnInitialize()
	if ODC_Config.toggle.bag == nil then ODC_Config.toggle.bag = true end
	if ODC_Config.toggle.bank == nil then ODC_Config.toggle.bank = true end
	ODC:AddAvaliableTab("bag", self)
	ODC:AddAvaliableTab("bank", self)
end

function ODC_Bag:OnEnable()

	if ODC_Config.toggle.bag then
		if not ODC_DB[playername]["bag"] then
			ODC_DB[playername]["bag"] = {}
			self:CheckBags()
		end
		if not ODC_DB[playername]["bag"].money then
			ODC_DB[playername]["bag"].money = GetMoney() or 0
		end
		ODC:AddTab("bag", self.tabs["bag"])
	end
	if ODC_Config.toggle.bank then
		if not ODC_DB[playername]["bank"] then
			ODC_DB[playername]["bank"] = {}
		end
		ODC:AddTab("bank", self.tabs["bank"])
		self:RegisterEvent("BANKFRAME_OPENED")
		self:RegisterEvent("BANKFRAME_CLOSED")
	end
	if ODC_Config.toggle.bag or ODC_Config.toggle.bank then
		ODC:AddModule(self)
		self:RegisterEvent("BAG_UPDATE_DELAYED")
	end
	-- self:SecureHook('OpenAllBags', 'OpenBags')
	-- self:SecureHook('ToggleBag', 'OpenBags')
end

function ODC_Bag:OnDisable()
	if not ODC_Config.toggle.bag then
		ODC:RemoveTab("bag")
	end
	if not ODC_Config.toggle.bank then
		ODC:RemoveTab("bank")
		self:UnregisterEvent("BANKFRAME_OPENED")
		self:UnregisterEvent("BANKFRAME_CLOSED")
	end
	if not ODC_Config.toggle.bag and not ODC_Config.toggle.bank then
		ODC:RemoveModule(self)
		self:UnhookAll()
		-- self:UnregisterEvent("BAG_UPDATE_DELAYED")
	end
	-- ODC_Config.toggle.bag = false
	-- ODC_Config.toggle.bank = false
	-- self:UnhookAll()
	-- self:UnregisterEvent("BANKFRAME_OPENED")
	-- self:UnregisterEvent("BANKFRAME_CLOSED")	
	-- self:UnregisterEvent("BAG_UPDATE_DELAYED")	
end