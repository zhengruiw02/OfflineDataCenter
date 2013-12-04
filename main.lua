--@@ TODO: solve COD item, maybe displaying COD amount above the slot icon or using tool-tip
	--UC..don't know how to layout in tool-tip..
--@@ TODO: should stacked attachments can be collect??
	--UC.. new window to produce? or pop-up ? COD to collect?
--@@ TODO: should attachments be alerted to player to collect when almost in deadline?
	--UC.. to optimize

--@@ TODO: optimize & combine same action in function Filter() UpdateRevIdxTb() InsToIdxTb()
local ODC = LibStub("AceAddon-3.0"):NewAddon("OfflineDataCenter", "AceHook-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("OfflineDataCenter")
local getn, tinsert = table.getn, table.insert
local floor = math.floor
local len, sub, find, format, match = string.len, string.sub, string.find, string.format, string.match
ODC.playername = GetUnitName("player")..'-'..GetRealmName()
ODC.selectChar = ODC.playername
ODC.selectTab = nil

ODC.module = {}
ODC.TabTextures = {}
ODC.TabTooltip = {}
ODC.PopupMenu = {}
ODC.TabChangedFunc = {}
ODC.CharChangedFunc = {}


ODC.config_const = {
	frameWidth = 360,
	frameHeight = 580,
}

local function ChooseChar_OnClick(self)
	ODC.selectChar = self.value
	UIDropDownMenu_SetSelectedValue(ODC.Frame.chooseChar, self.value);

	ODC.CharChangedFunc[ODC.selectTab]()
	
	local text = OfflineDataCenterFrameChooseCharDropDownText;
	local width = text:GetStringWidth();
	UIDropDownMenu_SetWidth(ODC.Frame.chooseChar, width+40);
	ODC.Frame.chooseChar:SetWidth(width+60)	
end

local function ChooseCharMenuInitialize(self, level)
	local info = UIDropDownMenu_CreateInfo();
	for k, v in pairs(BB_DB) do
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

---- GUI ----

function ODC:SetActiveTab(tabName, showFrame)
	self.selectTab = tabName
	if not MB_Config.toggle[tabName] then
		print(ODC.TabTooltip[tabName]..'is not Enabled')
		return;
	end

	for k, v in pairs(MB_Config.toggle) do
		if k == tabName then
			_G["OfflineDataCenterFrame"..k..'Tab']:SetChecked(true)
		elseif v then
			_G["OfflineDataCenterFrame"..k..'Tab']:SetChecked(false)
		end
	end
	if showFrame then self:FrameShow() end
	self.TabChangedFunc[tabName]()

end
	
local function CreateODCFrame()
	----Create ODC frame
	local name = "OfflineDataCenterFrame"
	local f = CreateFrame("Frame", name , UIParent)
	ODC.Frame = f
	if MB_Config.UI == nil then MB_Config.UI = {} end
	
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
	f:SetPoint(MB_Config.UI.pa or "CENTER", MB_Config.UI.px or 0, MB_Config.UI.py or 0)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		MB_Config.UI.p, MB_Config.UI.pf, MB_Config.UI.pa, MB_Config.UI.px, MB_Config.UI.py = self:GetPoint()
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
	--UIDropDownMenu_Initialize(f.chooseChar, self:DropDownMenuInitialize());
	--UIDropDownMenu_SetWidth(OfflineDataCenterFrameDropDown, 200);
	
	----Create close button
	f.closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton");
	f.closeButton:SetPoint("TOPRIGHT", -2, -2);
	f.closeButton:HookScript("OnClick", function()
		collectgarbage("collect")
	end)
	
	UIDropDownMenu_Initialize(f.chooseChar, ChooseCharMenuInitialize)
end

local function CreateFrameTab(f)
	--tab button
	local tabIndex = 1
	for k , v in pairs(ODC.TabTextures) do
		if not MB_Config.toggle[k] then
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
				tab:SetNormalTexture(v)
				tab:GetNormalTexture():ClearAllPoints()
				tab:GetNormalTexture():Point("TOPLEFT", 2, -2)
				tab:GetNormalTexture():Point("BOTTOMRIGHT", -2, 2)
				tab:GetNormalTexture():SetTexCoord(0.1, 0.9, 0.1, 0.9)

				tab:CreateBackdrop("Default")
				tab.backdrop:SetAllPoints()
				tab:StyleButton()
			else
				tab:SetPoint("TOPLEFT", f, "TOPRIGHT", 0, (-48 * tabIndex) + 18)
				tab:SetNormalTexture(v)
			end	
			tabIndex = tabIndex + 1
			tab:SetAttribute("type", "spell")
			tab:SetAttribute("spell", f:GetName())
			tab.typeStr = k
			tab:SetScript("OnClick", function(self)
				ODC:SetActiveTab(self.typeStr)
			end)
			
			tab.name = name
			tab.tooltip = ODC.TabTooltip[k]
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

function ODC:FrameShow()
	self.Frame:Show()
end

function ODC:FrameHide()
	self.Frame:Hide()
	MB_Config.UI.activePage = self.selectTab
	if not InCombatLockdown() then
		collectgarbage("collect")
	end
end

local OfflineDataCenterPopMenu = {
	{text = L['Offline MailBox'],
	func = function() PlaySound("igMainMenuOpen"); ODC:SetActiveTab('mail', true) end},
	{text = L['Offline Bag'],
	func = function() PlaySound("igMainMenuOpen"); ODC:SetActiveTab('bag', true) end},
	{text = L['Offline Bank'], 
	func = function() PlaySound("igMainMenuOpen"); ODC:SetActiveTab('bank', true) end},
	{text = L['Offline Character'], 
	func = function() PlaySound("igMainMenuOpen"); ODC:SetActiveTab('inventory', true) end},
}

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
	f:SetNormalTexture(ODC.TabTextures[name])
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
		GameTooltip:AddLine(ODC.TabTooltip[name])
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

	if ElvUI and not f.offlineButton then
		f.offlineButton = {}
		--offline button
		if MB_Config.toggle.bag then
			tinsert(f.offlineButton, CreateElvUIBagToggleButton('bag', f))
			tinsert(f.offlineButton, CreateElvUIBagToggleButton('bank', f))
		end
		if MB_Config.toggle.mail then
			tinsert(f.offlineButton, CreateElvUIBagToggleButton('mail', f))
		end
		if MB_Config.toggle.inventory then
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
	if module.type == "tab" then
		for k, v in pairs(module.TabTextures) do
			self.TabTextures[k] = v
		end
		for k, v in pairs(module.TabTooltip) do
			self.TabTooltip[k] = v
		end
		CreateFrameTab(ODC.Frame)
	end
	--self:SetActiveTab(selectTab)
end

function ODC:RemoveModule(module)
	if module.type == "tab" then
		for k, v in pairs(module.TabTextures) do
			self.TabTextures[k] = nil
		end
		for k, v in pairs(module.TabTooltip) do
			self.TabTooltip[k] = nil
		end
		CreateFrameTab(ODC.Frame)
	end
end
-- ODC.TabChangedFunc = {}
-- ODC.CharChangedFunc = {}
function ODC:AddFunc(name, action, func)
	if action == "selectTab" then
		self.TabChangedFunc[name] = func
	elseif action == "selectChar" then
		self.CharChangedFunc[name] = func
	end
end

function ODC:RemoveFunc(name, action)
	if action == "selectTab" then
		self.TabChangedFunc[name] = nil
	elseif action == "selectChar" then
		self.CharChangedFunc[name] = nil
	end
end

function ODC:OpenBags()
	CreateToggleButton(ElvUI_ContainerFrame)
	CreateToggleButton(ContainerFrame1)
end

function ODC:Toggle()
	if MB_Config.toggle == nil then
		print("toggled")
		MB_Config.toggle = {
			['mail'] = true,
			['bag'] = true,
			['bank'] = true,
			['inventory'] = true,
		}
	end
	local tabNumber = 0
	self.selectTab = MB_Config.UI.activePage
	for k, v in pairs(MB_Config.toggle) do
		tabNumber = tabNumber + 1
		if not self.selectTab then
			self.selectTab = k
		end
	end

	if tabNumber == 0 then 
		if OfflineDataCenterFrame then OfflineDataCenterFrame:Hide() end
	else
		CreateODCFrame()
		--CreateFrameTab(ODC.Frame)
		--self:SetActiveTab(selectTab)
	end
end
		
function ODC:OnInitialize()
	if MB_Config == nil then MB_Config = {UI = {},player = {}} end
	--if MB_Config.UI == nil then MB_Config.UI = {} end
	--MB_Config.player[ODC.playername] = true
	
	--self:Toggle()
	CreateODCFrame()
	if not MB_DB then MB_DB = {} end
	if not BB_DB then BB_DB = {} end
	if not IN_DB then IN_DB = {} end
	self:SecureHook('OpenAllBags', 'OpenBags')
	self:SecureHook('ToggleBag', 'OpenBags')
	---- Slash command ----

	SLASH_OFFLINEDATACENTER1 = "/mb";
	SLASH_OFFLINEDATACENTER2 = "/odc";
	SlashCmdList["OFFLINEDATACENTER"] = function()
		if self.Frame:IsVisible() then
			self:FrameHide()
		else
			--self:Update("sort")
			self:FrameShow()
		end
	end;	
end