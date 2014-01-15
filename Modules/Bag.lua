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

local function AddItemBag(itemLink, count, bagID, slotID)
	BB_DB[playername][bagID][slotID] = {count = count, itemLink = itemLink}
end
--[[
BB_DB structure:
				bagID		slotID
[charName] = {	[1]			[1]			{	.count
				[n]			.slotMAX		.itemLink
				.itemCountBank?
				.itemCountBag?
]]
function ODC_Bag:CheckBags()
	if not BB_DB[playername] then BB_DB[playername] = {} end
	local BagIDs = self.isBankOpened and {-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11} or {0, 1, 2, 3, 4}
	local numSlots, full = GetNumBankSlots();
	BB_DB[playername].money = GetMoney()
	for k, bagID in pairs(BagIDs) do
		local numSlots = GetContainerNumSlots(bagID)
		if numSlots > 0 then
			BB_DB[playername][bagID] = {slotMAX = numSlots}
			-- local inbagItemCount = 0
			for slotIndex = 1, numSlots do
				local itemLink = GetContainerItemLink(bagID, slotIndex)
				if itemLink then
					local _, count, _, _, _ = GetContainerItemInfo(bagID, slotIndex)
					AddItemBag(itemLink, count, bagID, slotIndex)
					-- inbagItemCount = inbagItemCount + 1
				end
			end
			-- BB_DB[playername][bagID].inbagItemCount = inbagItemCount
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
	if not MB_Config.toggle.bag then MB_Config.toggle.bag = true end
	if not MB_Config.toggle.bank then MB_Config.toggle.bank = true end
end

function ODC_Bag:OnEnable()
	if MB_Config.toggle.bag or MB_Config.toggle.bank then
		ODC:AddModule(self)
		self:RegisterEvent("BAG_UPDATE_DELAYED")
		if not BB_DB[playername] then
			BB_DB[playername] = {}
			self:CheckBags()
		end
		if not BB_DB[playername].money then BB_DB[playername].money = GetMoney() or 0 end
	end
	if MB_Config.toggle.bag then
		ODC:AddTab("bag", self.tabs["bag"])
	end
	if MB_Config.toggle.bank then
		ODC:AddTab("bank", self.tabs["bank"])
		self:RegisterEvent("BANKFRAME_OPENED")
		self:RegisterEvent("BANKFRAME_CLOSED")
	end
	-- self:SecureHook('OpenAllBags', 'OpenBags')
	-- self:SecureHook('ToggleBag', 'OpenBags')
end

function ODC_Bag:OnDisable()
	if not MB_Config.toggle.bag then
		ODC:RemoveTab("bag")
	end
	if not MB_Config.toggle.bank then
		ODC:RemoveTab("bank")
		self:UnregisterEvent("BANKFRAME_OPENED")
		self:UnregisterEvent("BANKFRAME_CLOSED")
	end
	if not MB_Config.toggle.bag and not MB_Config.toggle.bank then
		ODC:RemoveModule(self)
		self:UnhookAll()
		-- self:UnregisterEvent("BAG_UPDATE_DELAYED")
	end
	-- MB_Config.toggle.bag = false
	-- MB_Config.toggle.bank = false
	-- self:UnhookAll()
	-- self:UnregisterEvent("BANKFRAME_OPENED")
	-- self:UnregisterEvent("BANKFRAME_CLOSED")	
	-- self:UnregisterEvent("BAG_UPDATE_DELAYED")	
end