local ODC = LibStub("AceAddon-3.0"):GetAddon("OfflineDataCenter")
local ODC_Inventory = ODC:NewModule("OfflineInventory", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("OfflineDataCenter")
ODC_Inventory.description = L["Offline Character"]

ODC_Inventory.TabTextures = {
	["inventory"] = "INTERFACE\\CHARACTERFRAME\\TempPortrait.blp",
}

ODC_Inventory.TabTooltip = {
	["inventory"] = L['Offline Character'],
}

local playername, selectChar, selectTab = ODC.playername, ODC.selectChar, ODC.selectTab
--local MB_Config, IN_DB = ODC.MB_Config, ODC.IN_DB

local function AddItemEquipped(itemLink, slotID)
	IN_DB[playername][1][slotID] = {count = 1, itemLink = itemLink}
end
--[[
IN_DB structure:
							INVSLOT
[charName] = {	[1]		{	[1]			{	.count
							[2]				.itemLink
				["stat"]{	.stat1
							.statN
]]
function ODC_Inventory:CheckEquipped()
	if not IN_DB[playername] then
		IN_DB[playername] = {}
		IN_DB[playername][1] = {}
	end
	for slotID = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local link = GetInventoryItemLink("player", slotID);
		if link then
			AddItemEquipped(link, slotID)
		end
	end
	
	if ODC.Frame:IsVisible() and selectChar == playername and selectTab == "inventory" then
		ODC:Update("sort")
	end
end

function ODC_Inventory:UNIT_INVENTORY_CHANGED()
	self:CheckEquipped()
end

function ODC_Inventory:ITEM_UPGRADE_MASTER_UPDATE()
	self:CheckEquipped()
end

function ODC_Inventory:REPLACE_ENCHANT()
	self:CheckEquipped()
end

function ODC_Inventory:OnEnable()
	MB_Config.toggle.inventory = true
	ODC:AddModule(self)
	if not IN_DB[playername] then self:CheckEquipped() end
	self:RegisterEvent("UNIT_INVENTORY_CHANGED");
	self:RegisterEvent("REPLACE_ENCHANT");
	self:RegisterEvent("ITEM_UPGRADE_MASTER_UPDATE");
end

function ODC_Inventory:OnDisable()
	MB_Config.toggle.inventory = false
	ODC:RemoveModule(self)
	-- self:UnregisterEvent("UNIT_INVENTORY_CHANGED");
	-- self:UnregisterEvent("REPLACE_ENCHANT");
	-- self:UnregisterEvent("ITEM_UPGRADE_MASTER_UPDATE");	
end