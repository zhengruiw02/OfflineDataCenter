local ODC = LibStub("AceAddon-3.0"):GetAddon("OfflineDataCenter")
local ODC_SF = ODC:GetModule("SortFilter")
if not ODC_SF then return end
local ODC_Inventory = ODC:NewModule("OfflineInventory", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("OfflineDataCenter")
ODC_Inventory.description = L["Offline Character"]
ODC_Inventory.type = "tab"

ODC_Inventory.TabTextures = {
	["inventory"] = "INTERFACE\\CHARACTERFRAME\\TempPortrait.blp",
}

ODC_Inventory.TabTooltip = {
	["inventory"] = L['Offline Character'],
}

local playername, selectChar, selectTab = ODC.playername, ODC.selectChar, ODC.selectTab

local function AddItemEquipped(itemLink, slotID)
	if not itemLink then
		IN_DB[playername][1][slotID] = nil
	else
		IN_DB[playername][1][slotID] = {count = 1, itemLink = itemLink}
	end
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
		AddItemEquipped(link, slotID)
	end
	
	if ODC.Frame:IsVisible() and selectChar == playername and selectTab == "inventory" then
		ODC_SF:Update("sort")
	end
end

function ODC_Inventory:UNIT_INVENTORY_CHANGED()
	print("item changed!")
	self:CheckEquipped()
end

function ODC_Inventory:ITEM_UPGRADE_MASTER_UPDATE()
	self:CheckEquipped()
end

function ODC_Inventory:REPLACE_ENCHANT()
	self:CheckEquipped()
end

local SelectTabFunc = function()
	ODC_SF:CreateOrShowSubFrame("inventory")
	--ODC_SF:UpdateSortMenu()
	ODC_SF:Update("sort")
end

local SelectCharFunc = function()
	ODC_SF:Update("sort")
end

local RefreshSelectedTabFunc = function(selectedTab)
	selectTab = selectedTab
end

local RefreshSelectedCharFunc = function(selectedChar)
	selectChar = selectedChar
end

function ODC_Inventory:OnEnable()
	MB_Config.toggle.inventory = true
	ODC:AddModule(self)
	ODC:AddFunc("inventory", "selectTab", SelectTabFunc)
	ODC:AddFunc("inventory", "selectChar", SelectCharFunc)
	ODC:AddFunc("inventory", "selectTabCallback", RefreshSelectedTabFunc)
	ODC:AddFunc("inventory", "selectCharCallback", RefreshSelectedCharFunc)
	if not IN_DB[playername] then self:CheckEquipped() end
	self:RegisterEvent("UNIT_INVENTORY_CHANGED");
	self:RegisterEvent("REPLACE_ENCHANT");
	self:RegisterEvent("ITEM_UPGRADE_MASTER_UPDATE");
end

function ODC_Inventory:OnDisable()
	MB_Config.toggle.inventory = false
	ODC:RemoveModule(self)
	ODC:RemoveFunc("inventory", "selectTab")
	ODC:RemoveFunc("inventory", "selectTab")
	-- self:UnregisterEvent("UNIT_INVENTORY_CHANGED");
	-- self:UnregisterEvent("REPLACE_ENCHANT");
	-- self:UnregisterEvent("ITEM_UPGRADE_MASTER_UPDATE");	
end