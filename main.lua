--@@ TODO: solve COD item, maybe displaying COD amount above the slot icon or using tool-tip
	--UC..don't know how to layout in tool-tip..
--@@ TODO: should stacked attachments can be collect??
	--UC.. new window to produce? or pop-up ? COD to collect?
--@@ TODO: should attachments be alerted to player to collect when almost in deadline?
	--UC.. to optimize

local ODC = LibStub("AceAddon-3.0"):NewAddon("OfflineDataCenter", "AceHook-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("OfflineDataCenter")
local getn, tinsert = table.getn, table.insert
local floor = math.floor
local len, sub, find, format, match = string.len, string.sub, string.find, string.format, string.match
ODC.playername = GetUnitName("player")..'-'..GetRealmName()
ODC.selectChar = ODC.playername
ODC.selectTab = nil

--[[
ODC.tabs = { [tabName] = ...}
[tabName] = { Textures, Tooltip, subFrame, CallTabFunc, CharChangedFunc }
]]
ODC.TabChangedCallback = {}
ODC.CharChangedCallback = {}
ODC.Tabs = {}
ODC.TabsAvaliable = {}

ODC.config_const = {
	frameWidth = 360,
	frameHeight = 580,
}

local function SetSelectedTab()
	for k, v in pairs(ODC.TabChangedCallback) do
		ODC.TabChangedCallback[k](ODC.selectTab)
	end
end

local function SetSelectedChar()
	for k, v in pairs(ODC.CharChangedCallback) do
		ODC.CharChangedCallback[k](ODC.selectChar)
	end
end

local function ChooseChar_OnClick(self)
	ODC.selectChar = self.value
	SetSelectedChar()

	UIDropDownMenu_SetSelectedValue(ODC.Frame.chooseChar, self.value);

	ODC.Tabs[ODC.selectTab].CharChangedFunc()
	
	local text = OfflineDataCenterFrameChooseCharDropDownText;
	local width = text:GetStringWidth();
	UIDropDownMenu_SetWidth(ODC.Frame.chooseChar, width+40);
	ODC.Frame.chooseChar:SetWidth(width+60)	
end

local function ChooseCharMenuInitialize(self, level)
	local info = UIDropDownMenu_CreateInfo();
	for k, v in pairs(ODC_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			local info = UIDropDownMenu_CreateInfo()
			info.text = k
			info.value = k
			info.func = function(self)
				ChooseChar_OnClick(self)
			end;
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_SetSelectedValue(ODC.Frame.chooseChar, ODC.selectChar);
	local text = OfflineDataCenterFrameChooseCharDropDownText;
	local width = text:GetStringWidth();
	UIDropDownMenu_SetWidth(ODC.Frame.chooseChar, width+40);
	ODC.Frame.chooseChar:SetWidth(width+60)
end

function ODC:ShowSubFrame (tabName, subFrame)
	local thisFrame = self.Tabs[tabName].subFrame

	if not thisFrame then
		self.Tabs[tabName].subFrame = subFrame
		thisFrame = subFrame
	end

	for k, tab in pairs(self.Tabs) do
		local frame = tab.subFrame
		if frame ~= nil then
			if ( frame ~= thisFrame ) then
				frame:Hide();
			else
				frame:Show();
			end
		end
	end 
end

---- GUI ----

function ODC:SetActiveTab(tabName, showFrame)
	self.selectTab = tabName
	ODC_Config.UI.activePage = tabName
	SetSelectedTab()
	if not ODC_Config.toggle[tabName] then
		print(ODC.Tabs[tabName].Tooltip..'is not Enabled')
		return;
	end

	for k, v in pairs(ODC_Config.toggle) do
		if k == tabName then
			_G["OfflineDataCenterFrame"..k..'Tab']:SetChecked(true)
		elseif v then
			_G["OfflineDataCenterFrame"..k..'Tab']:SetChecked(false)
		end
	end
	if showFrame then self:FrameShow() end
	
	self.Tabs[tabName].CallTabFunc()

end
	
local function CreateODCFrame()
	----Create ODC frame
	local name = "OfflineDataCenterFrame"
	local f = CreateFrame("Frame", name , UIParent)
	ODC.Frame = f
	if ODC_Config.UI == nil then ODC_Config.UI = {} end
	
	if ElvUI then
		f:SetTemplate(ElvUI[1].db.bags.transparent and "notrans" or "Transparent")
	else
		f:SetBackdrop({
			bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
			edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 1, right = 1, top = 1, bottom = 1 }
		})
	end
	f:EnableMouse(true)
	f:SetFrameStrata("DIALOG");
	f:SetClampedToScreen(true)
	f:SetWidth(ODC.config_const.frameWidth)
	f:SetHeight(ODC.config_const.frameHeight)
	f:SetPoint(ODC_Config.UI.pa or "CENTER", ODC_Config.UI.px or 0, ODC_Config.UI.py or 0)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		ODC_Config.UI.p, ODC_Config.UI.pf, ODC_Config.UI.pa, ODC_Config.UI.px, ODC_Config.UI.py = self:GetPoint()
	end)
	f:Hide()
	
	----Create title
	f.title = f:CreateFontString(nil, 'OVERLAY');
	if ElvUI then
		f.title:FontTemplate(nil, 14, 'OUTLINE')
	else
		f.title:SetFont(STANDARD_TEXT_FONT, 14);
	end
	f.title:SetPoint("TOPLEFT", 10, -10);
	f.title:SetText(L["Offline Data Center"])
	
	----Create choose char dropdown menu
	f.chooseChar = CreateFrame('Frame', name..'ChooseCharDropDown', f, 'UIDropDownMenuTemplate')
	f.chooseChar:SetPoint("LEFT", f.title, f.title:GetStringWidth(), -5)
	UIDropDownMenu_Initialize(f.chooseChar, ChooseCharMenuInitialize)
	--UIDropDownMenu_SetWidth(OfflineDataCenterFrameChooseCharDropDown, 200);
	
	----Create close button
	f.closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton");
	f.closeButton:SetPoint("TOPRIGHT", -2, -2);
	f.closeButton:HookScript("OnClick", function()
		collectgarbage("collect")
	end)
	
	----Create container for subFrame
	--[[
	f.subFrame = CreateFrame('Frame', name.."SubFrame", f);
	f.subFrame:SetPoint('TOPLEFT', 0, -40);
	f.subFrame:SetPoint('BOTTOMRIGHT', 0, 0);]]
	
	if ElvUI then
		local S = ElvUI[1]:GetModule("Skins")
		if S then
			S:HandleCloseButton(f.closeButton);
			S:HandleDropDownBox(f.chooseChar)
		end
	end
end

local function CreateFrameTab(f)
	--tab button
	local tabIndex = 1
	for k , v in pairs(ODC.Tabs) do
		texture = v.Textures
		if not ODC_Config.toggle[k] then
			if _G[f:GetName()..k..'Tab'] then
				_G[f:GetName()..k..'Tab']:Hide()
				_G[f:GetName()..k..'Tab'] = nil
			end
		else
			local tab = _G[f:GetName()..k..'Tab'] or CreateFrame("CheckButton", f:GetName()..k..'Tab', f, "SpellBookSkillLineTabTemplate SecureActionButtonTemplate")
			tab:ClearAllPoints()
			if ElvUI then
				--local S = ElvUI[1]:GetModule("Skins")
				tab:SetPoint("TOPLEFT", f, "TOPRIGHT", 2, (-44 * tabIndex) + 34)
				tab:DisableDrawLayer("BACKGROUND")
				tab:SetNormalTexture(texture)
				tab:GetNormalTexture():ClearAllPoints()
				tab:GetNormalTexture():Point("TOPLEFT", 2, -2)
				tab:GetNormalTexture():Point("BOTTOMRIGHT", -2, 2)
				tab:GetNormalTexture():SetTexCoord(0.1, 0.9, 0.1, 0.9)

				tab:CreateBackdrop("Default")
				tab.backdrop:SetAllPoints()
				tab:StyleButton()
			else
				tab:SetPoint("TOPLEFT", f, "TOPRIGHT", 0, (-48 * tabIndex) + 18)
				tab:SetNormalTexture(texture)
			end	
			tabIndex = tabIndex + 1
			tab:SetAttribute("type", "spell")
			tab:SetAttribute("spell", f:GetName())
			tab.tabName = k
			tab:SetScript("OnClick", function(self)
				ODC:SetActiveTab(self.tabName)
			end)
			
			tab.name = name
			tab.tooltip = ODC.Tabs[k].Tooltip
			tab:Show()
		end
	end
end

function ODC:CreatePopupFrame()
	self.PopupFrame = CreateFrame("Frame", nil , UIParent)
	local f = self.PopupFrame

	if ElvUI then
		f:SetTemplate(ElvUI[1].db.bags.transparent and "notrans" or "Transparent")
	else
		f:SetBackdrop({
			bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
			edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 1, right = 1, top = 1, bottom = 1 }
		})
	end
	f:EnableMouse(true)
	f:SetFrameStrata("DIALOG");
	f:SetWidth(333)
	f:SetHeight(200)
	f:SetPoint("CENTER", 0, 0)
	--f:SetFrameLevel(self:GetFrameLevel() + 20);
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)
	f:Hide()
	
	f.accept = CreateFrame("Button", nil, f, "UIPanelButtonTemplate");
	f.accept:SetWidth(100)
	f.accept:SetHeight(30)
	f.accept:SetPoint("BOTTOMLEFT", 10, 5);
	f.accept:SetText(ACCEPT)
	
	f.cancle = CreateFrame("Button", nil, f, "UIPanelButtonTemplate");
	f.cancle:SetWidth(100)
	f.cancle:SetHeight(30)
	f.cancle:SetPoint("BOTTOMRIGHT", -10, -5);
	f.cancle:SetText(CANCEL)
end



local OfflineDataCenterPopMenu = {}

local function AddPopMenu(tabName, tabTooltip)
	local t = {text = tabTooltip,
		func = function() PlaySound("igMainMenuOpen"); ODC:SetActiveTab(tabName, true) end},
	tinsert(OfflineDataCenterPopMenu, t)
end

local function RemovePopMenu(tabTooltip)
	for i, t in pairs(OfflineDataCenterPopMenu) do
		if t.text == tabTooltip then
			t = nil
		end
	end
end

local function DropDown(list, frame, xOffset, yOffset)
	if not frame.buttons then
		frame.buttons = {}
		frame:SetFrameStrata("TOOLTIP")
		frame:SetClampedToScreen(true)
		tinsert(UISpecialFrames, frame:GetName())
		frame:Hide()
	end

	xOffset = xOffset or 0
	yOffset = yOffset or 0

	for i=1, #frame.buttons do
		frame.buttons[i]:Hide()
	end

	for i=1, #list do 
		if not frame.buttons[i] then
			frame.buttons[i] = CreateFrame("Button", nil, frame)
			
			frame.buttons[i].hoverTex = frame.buttons[i]:CreateTexture(nil, 'OVERLAY')
			frame.buttons[i].hoverTex:SetAllPoints()
			frame.buttons[i].hoverTex:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
			frame.buttons[i].hoverTex:SetBlendMode("ADD")
			frame.buttons[i].hoverTex:Hide()

			frame.buttons[i].text = frame.buttons[i]:CreateFontString(nil, 'BORDER')
			frame.buttons[i].text:SetAllPoints()
			frame.buttons[i].text:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE')
			frame.buttons[i].text:SetJustifyH("LEFT")

			frame.buttons[i]:SetScript("OnEnter", function(btn)
				btn.hoverTex:Show()
			end)
			frame.buttons[i]:SetScript("OnLeave", function(btn)
				btn.hoverTex:Hide()
			end)
		end

		frame.buttons[i]:Show()
		frame.buttons[i]:SetHeight(16)
		frame.buttons[i]:SetWidth(135)
		frame.buttons[i].text:SetText(list[i].text)
		frame.buttons[i].func = list[i].func
		frame.buttons[i]:SetScript("OnClick", function(btn)
			btn.func()
			btn:GetParent():Hide()
		end)

		if i == 1 then
			frame.buttons[i]:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
		else
			frame.buttons[i]:SetPoint("TOPLEFT", frame.buttons[i-1], "BOTTOMLEFT")
		end
	end

	frame:SetHeight((#list * 16) + 10 * 2)
	frame:SetWidth(135 + 10 * 2)

	local UIScale = UIParent:GetScale();
	local x, y = GetCursorPosition();
	x = x/UIScale
	y = y/UIScale
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + xOffset, y + yOffset)	

	ToggleFrame(frame)
end

local menuFrame = CreateFrame("Frame", "OfflineDataCenterClickMenu", UIParent)
menuFrame:SetBackdrop({
	bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
	edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

local function CreateElvUIBagToggleButton(name, parent)
	local f = CreateFrame('Button', nil, parent)
	f:Height(20)
	f:Width(20)
	f:SetFrameLevel(f:GetFrameLevel() + 2)
	f:SetTemplate('Default')
	f:StyleButton()
	f:SetNormalTexture(ODC.Tabs[name].Textures)
	f:GetNormalTexture():SetTexCoord(0.1, 0.9, 0.1, 0.9)
	f:GetNormalTexture():SetInside()
	f:CreateBackdrop("Default")
	f.backdrop:SetAllPoints()
	f:SetScript("OnClick", function()
		ODC:SetActiveTab(name, true)
	end)
	f:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self:GetParent(), "ANCHOR_TOP", 0, 4)
		GameTooltip:ClearLines()
		GameTooltip:AddLine(ODC.Tabs[name].Tooltip)
		GameTooltip:Show()
	end)
	f:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	return f
end

local function CreateToggleButton(f)
	if not f then return; end
	if InCombatLockdown() then
		print(L["Offline Data Center toggle button can not be created in Combating, please leave the combat before retry!"]);
		return;
	end
	
	if f:GetName() == 'ContainerFrame1' and not ContainerFrame1PortraitButton.dropdownmenu then
		ContainerFrame1PortraitButton:RegisterForClicks('AnyUp', 'AnyDown')
		ContainerFrame1PortraitButton:EnableMouse(true)
		ContainerFrame1PortraitButton:SetScript("OnClick", function(self)
			DropDown(OfflineDataCenterPopMenu, menuFrame)
		end)
		ContainerFrame1PortraitButton:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:AddLine(L['Offline Frame'])
			GameTooltip:AddLine(BACKPACK_TOOLTIP, 1.0, 1.0, 1.0);
			if (GetBindingKey("TOGGLEBACKPACK")) then
				GameTooltip:AddLine(" "..NORMAL_FONT_COLOR_CODE.."("..GetBindingKey("TOGGLEBACKPACK")..")"..FONT_COLOR_CODE_CLOSE)
			end
			GameTooltip:SetClampedToScreen(true)
			GameTooltip:Show()
		end)		
		ContainerFrame1PortraitButton.dropdownmenu = true
		return ContainerFrame1PortraitButton
	end

	if ElvUI then --and not f.offlineButton
		f.offlineButton = {}
		--offline button
		if ODC_Config.toggle.bag then
			tinsert(f.offlineButton, CreateElvUIBagToggleButton('bag', f))
		end
		if ODC_Config.toggle.bank then
			tinsert(f.offlineButton, CreateElvUIBagToggleButton('bank', f))
		end
		if ODC_Config.toggle.mail then
			tinsert(f.offlineButton, CreateElvUIBagToggleButton('mail', f))
		end
		if ODC_Config.toggle.inventory then
			tinsert(f.offlineButton, CreateElvUIBagToggleButton('inventory', f))
		end
		if #f.offlineButton > 0 then
			for i = 1, #f.offlineButton do
				if i == 1 then
					f.offlineButton[i]:Point('TOPLEFT', f, 'TOPLEFT', 8, -20)
				else
					f.offlineButton[i]:Point("LEFT", f.offlineButton[i-1], "RIGHT", 6, 0)
				end
			end
		end		
	end
	
	return f
end

function ODC:AddModule(module)
	self.TabChangedCallback[module.name] = module.selectTabCallbackFunc
	self.CharChangedCallback[module.name] = module.selectCharCallbackFunc
end

function ODC:RemoveModule(module)
	self.TabChangedCallback[module.name] = nil
	self.CharChangedCallback[module.name] = nil
end

function ODC:AddTab(tabName, tab)
	self.Tabs[tabName] = tab
	AddPopMenu(tabName, tab.Tooltip)
	CreateFrameTab(self.Frame)
end

function ODC:RemoveTab(tabName)
	self.Tabs[tabName] = nil
	RemovePopMenu(tabName)
	CreateFrameTab(self.Frame)
end

function ODC:AddAvaliableTab(tabName, module)
	self.TabsAvaliable[tabName] = module
end

local function PrintCmdHelper()
	print("Unknow ODC command! ODC command helper:\n"..
	"/ODC toggle: to toggle ODC window\n"..
	"/ODC enable [tab name]: to enable [tab name]\n"..
	"/ODC disable [tab name]: to disable [tab name]\n"..
	"/ODC state: to show tabs state\n")
end

function ODC:FrameShow()
	self.Frame:Show()
end

function ODC:FrameHide()
	self.Frame:Hide()
	ODC_Config.UI.activePage = self.selectTab
	if not InCombatLockdown() then
		collectgarbage("collect")
	end
end

function ODC:ToggleWindow()
	if self.Frame:IsVisible() then
		self:FrameHide()
	else
		--self:Update("sort")
		self:FrameShow()
	end
end

local function PrintTabState()
	for k, v in pairs(ODC_Config.toggle) do
		if v then
			print(k.." is enabled")
		else
			print(k.." is disabled")
		end
	end
end

function ODC:EnableTab(tabName)
	if not tabName then
		PrintCmdHelper()
	elseif ODC_Config.toggle[tabName] == nil then
		print("Tab name does not exist!")
		PrintTabState()
	else
		ODC_Config.toggle[tabName] = true
		self.TabsAvaliable[tabName]:OnEnable()
	end
end

function ODC:DisableTab(tabName)
	if not tabName then
		PrintCmdHelper()
	elseif ODC_Config.toggle[tabName] == nil then
		print("Tab name does not exist!")
		PrintTabState()
	else
		ODC_Config.toggle[tabName] = false
		self.TabsAvaliable[tabName]:OnDisable()
	end
end

function ODC:SlashCmdHandler(param)
	param = string.lower(param)
	local _, _, arg1, arg2 = string.find(param, "(%a+)%s*(%a*)")
	if arg1 == "toggle" then
		self:ToggleWindow()
	elseif arg1 == "enable" then
		self:EnableTab(arg2)
	elseif arg1 == "disable" then
		self:DisableTab(arg2)
	elseif arg1 == "state" then
		PrintTabState()
	else
		PrintCmdHelper()
	end
end

function ODC:OpenBags()
	CreateToggleButton(ElvUI_ContainerFrame)
	CreateToggleButton(ContainerFrame1)
end

local function CopyTable(ori_tab)
    if (type(ori_tab) ~= "table") then
        return nil;
    end
    local new_tab = {};
    for i,v in pairs(ori_tab) do
        local vtyp = type(v);
        if (vtyp == "table") then
            new_tab[i] = CopyTable(v);
        else
            new_tab[i] = v;
        end
    end
    return new_tab;
end
--[[
MB_DB structure:
				mailIndex		attachIndex
[charName] = {	[1]				[1]			{	.count
				[n]				.sender			.itemLink
				/.mailCount		.daysLeft
				/.itemCount		.wasReturned
				.checkMailTick	.CODAmount?
								.money?

BB_DB structure:
				bagID		slotID
[charName] = {	[1]			[1]			{	.count
				[n]			/.slotMAX		.itemLink

IN_DB structure:
							INVSLOT
[charName] = {	[1]		{	[1]			{	.count
							[2]				.itemLink
]]
local function ConvertOldDB()
	if type(MB_DB) == "table" then
		for playerName, t in pairs(MB_DB) do
			if type(t) == "table" then
				if not ODC_DB[playerName] then ODC_DB[playerName] = {} end
				ODC_DB[playerName]["mail"] = {}
				ODC_DB[playerName]["mail"] = CopyTable(t)
				ODC_DB[playerName]["mail"].mailCount = nil
				ODC_DB[playerName]["mail"].itemCount = nil
			end
		end
		MB_DB = nil
	end
	if type(BB_DB) == "table" then
		for playerName, t in pairs(BB_DB) do
			if type(t) == "table" then
				if not ODC_DB[playerName] then ODC_DB[playerName] = {} end
				ODC_DB[playerName]["bag"] = {}
				ODC_DB[playerName]["bank"] = {}
				local BagIDs = {0, 1, 2, 3, 4}
				local BankIDs = {-1, 5, 6, 7, 8, 9, 10, 11}
				for _, i in pairs(BagIDs) do
					if t[i] and type(t[i]) == "table" then
						ODC_DB[playerName]["bag"][i] = CopyTable(t[i])
						ODC_DB[playerName]["bag"][i].slotMAX = nil
					end
				end
				for _, i in pairs(BankIDs) do
					if t[i] and type(t[i]) == "table" then
						ODC_DB[playerName]["bank"][i] = CopyTable(t[i])
						ODC_DB[playerName]["bank"][i].slotMAX = nil
					end
				end
			end
		end
		BB_DB = nil
	end
	if type(IN_DB) == "table" then
		for playerName, t in pairs(IN_DB) do
			if type(t) == "table" then
				if not ODC_DB[playerName] then ODC_DB[playerName] = {} end
				ODC_DB[playerName]["inventory"] = {}
				ODC_DB[playerName]["inventory"] = CopyTable(t)
			end
		end
		IN_DB = nil
	end
	if type(MB_Config) == "table" then
		ODC_Config.UI = CopyTable(MB_Config)
		MB_Config = nil
	end
end

function ODC:OnInitialize()
	if ODC_Config == nil then ODC_Config = {UI = {},toggle = {}} end--,player = {}
	if ODC_DB == nil then ODC_DB = {} end
	if ODC_DB[ODC.playername] == nil then ODC_DB[ODC.playername] = {} end
	ConvertOldDB()
	--ODC_Config.player[ODC.playername] = true
	self.selectTab = ODC_Config.UI.activePage or nil

	CreateODCFrame()

	self:SecureHook('OpenAllBags', 'OpenBags')
	self:SecureHook('ToggleBag', 'OpenBags')
	---- Slash command ----

	SLASH_OFFLINEDATACENTER1 = "/odc";
	SlashCmdList["OFFLINEDATACENTER"] = function(param)
		ODC:SlashCmdHandler(param)
	end;
end