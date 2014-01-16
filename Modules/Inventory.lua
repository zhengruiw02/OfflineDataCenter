local ODC = LibStub("AceAddon-3.0"):GetAddon("OfflineDataCenter")
local ODC_SF = ODC:GetModule("SortFilter")
if not ODC_SF then return end
local ODC_Inventory = ODC:NewModule("OfflineInventory", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("OfflineDataCenter")
ODC_Inventory.description = L["Offline Character"]
ODC_Inventory.type = "tab"
ODC_Inventory.name = "OfflineInventory"
ODC_Inventory.tabs = {
	["inventory"] = {
		["Textures"] = "INTERFACE\\CHARACTERFRAME\\TempPortrait.blp",
		["Tooltip"] = L['Offline Character'],
		["CallTabFunc"] = function()
			ODC_SF:CreateOrShowSubFrame("inventory")
			ODC_SF:Update("sort")
		end,
		["CharChangedFunc"] = function()
			ODC_SF:Update("sort")
		end,
	}
}

local playername, selectChar, selectTab = ODC.playername, ODC.selectChar, ODC.selectTab

local function AddItemEquipped(itemLink, slotID)
	if not itemLink then
		ODC_DB[playername]["inventory"][1][slotID] = nil
	else
		ODC_DB[playername]["inventory"][1][slotID] = {count = 1, itemLink = itemLink}
	end
end
--[[
ODC_DB["inventory"] structure:
							INVSLOT
[charName] = {	[1]		{	[1]			{	.count
							[2]				.itemLink
				--["stat"]{	.stat1
							.statN
]]
function ODC_Inventory:CheckEquipped()
	for slotID = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local link = GetInventoryItemLink("player", slotID);
		AddItemEquipped(link, slotID)
	end

	if ODC.Frame:IsVisible() and selectChar == playername and selectTab == "inventory" then
		ODC_SF:Update("sort")
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

ODC_Inventory.selectTabCallbackFunc = function(selectedTab)
	selectTab = selectedTab
end

ODC_Inventory.selectCharCallbackFunc = function(selectedChar)
	selectChar = selectedChar
end

function ODC_Inventory:OnInitialize()
	if ODC_Config.toggle.inventory == nil then ODC_Config.toggle.inventory = true end
	ODC:AddAvaliableTab("inventory", self)
end

function ODC_Inventory:OnEnable()
	if not ODC_Config.toggle.inventory then return end
	ODC:AddModule(self)
	ODC:AddTab("inventory", self.tabs["inventory"])
	if not ODC_DB[playername]["inventory"] then
		ODC_DB[playername]["inventory"] = {[1] = {}}
		self:CheckEquipped()
	end
	self:RegisterEvent("UNIT_INVENTORY_CHANGED");
	self:RegisterEvent("REPLACE_ENCHANT");
	self:RegisterEvent("ITEM_UPGRADE_MASTER_UPDATE");
end

function ODC_Inventory:OnDisable()
	if ODC_Config.toggle.inventory then return end
	ODC:RemoveModule(self)
	ODC:RemoveTab("inventory")
	self:UnhookAll()
	-- self:UnregisterEvent("UNIT_INVENTORY_CHANGED");
	-- self:UnregisterEvent("REPLACE_ENCHANT");
	-- self:UnregisterEvent("ITEM_UPGRADE_MASTER_UPDATE");	
end