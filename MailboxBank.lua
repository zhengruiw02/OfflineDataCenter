--@@ TODO: solve COD item, maybe displaying COD amount above the slot icon or using tool-tip
	--UC..don't know how to layout in tool-tip..
--@@ TODO: function SortDB must clear up! collect garbage !!!
	--done?
--@@ TODO: change frame's layout!
	--holy shit..
--@@ TODO: add AH ordering
	--UC..bad to do
--@@ TODO: should stacked attachments can be collect??
	--UC.. new window to produce? or pop-up ?
--@@ TODO: should attachments be alerted to player to collect when almost in deadline?
	--UC.. should make new function to calculate deadline time?
--@@ TODO: localization!
	--UC.. done?
--local E, L, V, P, G, _ = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local MB = LibStub("AceAddon-3.0"):NewAddon("MailboxBank")
local L = LibStub("AceLocale-3.0"):GetLocale("MailboxBank")
local getn, tinsert = table.getn, table.insert
local floor = math.floor
local len, sub, find, format, join, match = string.len, string.sub, string.find, string.format, string.join, string.match
local playername = GetUnitName("player")..'-'..GetRealmName()
local selectValue = playername
local slotDB

local MB.Config_INIT = {
	daysLeftYellow = 5,
	daysLeftRed = 3,
	buttonSize = 36,
	buttonSpacing = 4,
	numItemsPerRow = 8,
	numItemsRows = 10,
	itemsSlotDisplay = 80,
	frameWidth = 350,
	frameHeight = 500,
	rowcount = 8,
	maxrow = 10,
	px = 0,
	py = 0,
	isStacked = false,
}	

local itemTypes, itemSubTypes

local function BuildSortOrder()
	itemTypes = {}
	itemSubTypes = {}
	for i, iType in ipairs({GetAuctionItemClasses()}) do
		itemTypes[iType] = i
		itemSubTypes[iType] = {}
		for ii, isType in ipairs({GetAuctionItemSubClasses(i)}) do
			itemSubTypes[iType][isType] = ii
		end
	end
end

local function MB:AddItem(sender, itemLink, count, daysLeft, mailIndex, attachIndex, CODAmount, wasReturned, recipient)
	local item = {}
	item["sender"] = sender
	item["count"] = count
	item["itemLink"] = itemLink
	item["daysLeft"] = daysLeft
	item["mailIndex"] = mailIndex
	item["attachIndex"] = attachIndex
	if CODAmount > 0 then item["CODAmount"] = CODAmount end
	if wasReturned then item["wasReturned"] = wasReturned end
	if recipient then
		tinsert(MB_DB[recipient], 1, item)
		MB_DB[recipient].itemCount = MB_DB[recipient].itemCount + 1
	else
		tinsert(MB_DB[playername], item)
		MB_DB[playername].itemCount = MB_DB[playername].itemCount + 1
	end
end

local function MB:CheckMail(isCollectMoney)
	if isCollectMoney and MB_DB[playername].money == 0 then return end
	MB_DB[playername] = {itemCount = 0, money = 0}
	local numItems, totalItems = GetInboxNumItems()
	if numItems and numItems > 0 then
		for mailIndex = 1, numItems do
			--local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(mailIndex);
			local _, _, sender, _, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, _, _, _ = GetInboxHeaderInfo(mailIndex);
			--if isGM ~= nil then print("GM@"..sender) end
			if money > 0 then
				if isCollectMoney then
					TakeInboxMoney(mailIndex)
				else
					MB_DB[playername].money = MB_DB[playername].money + money
				end
			end
			if hasItem then
			--@@ TODO: solve COD item, maybe can display COD amount in the slot icon or tooltip
				if sender == nil then
					--sender = "UNKNOWN SENDER CAUSE OF NETWORK" 
					sender = L["UNKNOWN SENDER"]
					--return false
				end
				for attachIndex = 1, ATTACHMENTS_MAX_RECEIVE do
					local itemLink = GetInboxItemLink(mailIndex, attachIndex)
					if itemLink then
						local _, _, count, _, _ = GetInboxItem(mailIndex, attachIndex)
						self:AddItem(sender, itemLink, count, daysLeft, mailIndex, attachIndex, CODAmount, wasReturned)
					end
				end
			end
		end
	end
	MB_DB[playername].checkMailTick = time()
	--return true
end

local function MailboxBank_CalcDeadline()

end

local function MB:SearchReset()
	self:UpdateContainer()
end

local function MB:UpdateSearch()
	local f = MailboxBankFrame
	local MIN_REPEAT_CHARACTERS = 3;
	local searchString = f.searchingBar:GetText();
	if (len(searchString) > MIN_REPEAT_CHARACTERS) then
		local repeatChar = true;
		for i=1, MIN_REPEAT_CHARACTERS, 1 do 
			if ( sub(searchString,(0-i), (0-i)) ~= sub(searchString,(-1-i),(-1-i)) ) then
				repeatChar = false;
				break;
			end
		end
		if ( repeatChar ) then
			MB:SearchBarResetAndClear(self);
			return;
		end
	end
	MB:UpdateContainer();
end

local function MB:OpenEditbox()
	local f = MailboxBankFrame
	f.searchingBarText:Hide();
	f.searchingBar:Show();
	f.searchingBar:SetText(SEARCH);
	f.searchingBar:HighlightText();
end

local function MB:SearchBarResetAndClear()
	local f = MailboxBankFrame
	f.searchingBarText:Show();
	
	f.searchingBar:ClearFocus();
	MB:SearchReset();
end

local function MB:CollectMoney()
	MB:CheckMail(true)
end

local function MB:InsertToRevIndexTable(RevsubDB, keyword)

end

local function MB:InsertToIndexTable(subDB, Type, subType, keyword)
	if not subDB or not Type then return false end
	----one-level and two-level are difference!!
	if not subDB[RevsubDB[Type]] then
	
	elseif subType then
		if not subDB[RevsubDB[Type]][RevsubsubDB[subType]] then
		
		else
		
		end
	else
	
	end
	
	
	----
	for Index = 1, subDB.count do
		if subDB[Index].value == Type then
			for subIndex = 1, getn(subDB[subIndex]) - 1 do -- except value
			
			end
		end
	end
	--
end

local SelectSortMethod = {
	["normal"] = function(usedSlot)
		slotDB[usedSlot] = {}
		return slotDB[usedSlot]
	end,
	["AH"] = function()
		local keyword = "itemID"
	
	end,
	["sender"] = function()
		local keyword = "sender"
	end,
	["quality"] = function()
		local keyword = "quality"
	end,
	["codOnly"] = function() 
		local keyword = "sender"
	end,
}

local function MB:CheckSlotFromSortDB(itemIndexCount, usedSlot)
	for i = 1, usedSlot do
		if tonumber(match(slotDB[i].link, "item:(%d+)")) == tonumber(match(MB_DB[selectValue][itemIndexCount].itemLink, "item:(%d+)")) then
			return slotDB[i]
		end
	end
	return nil
end

local function MB:InsertToSortDB(slot, itemIndexCount, isInit)
----TODO: merge checkMailTick and dayLeft to leftTick
	if isInit then
		slot.link = MB_DB[selectValue][itemIndexCount].itemLink
		slot.checkMailTick = MB_DB[selectValue].checkMailTick
		slot.sender = {}
		slot.dayLeft = {}
		slot.countNum = {}
		slot.wasReturned = nil
		slot.mailIndex = nil
		slot.attachIndex = nil
		if not MB_config.isStacked then
			slot.wasReturned = MB_DB[selectValue][itemIndexCount].wasReturned
			slot.CODAmount = MB_DB[selectValue][itemIndexCount].CODAmount
		end
		return slot
	end
	if selectValue == playername then
		if not slot.mailIndex then slot.mailIndex = {} end
		if not slot.attachIndex then slot.attachIndex = {} end
		tinsert(slot.mailIndex , MB_DB[selectValue][itemIndexCount].mailIndex)
		tinsert(slot.attachIndex , MB_DB[selectValue][itemIndexCount].attachIndex)
	end
	tinsert(slot.sender , MB_DB[selectValue][itemIndexCount].sender)
	tinsert(slot.dayLeft , MB_DB[selectValue][itemIndexCount].daysLeft)
	tinsert(slot.countNum , MB_DB[selectValue][itemIndexCount].count)
	return slot
end

function MB:SortDB(method, args)
--@@  TODO: clear up! collect garbage
	if not method then method = "normal" end
	local usedSlot = 0
	slotDB = {}
	for itemIndexCount = 1, MB_DB[selectValue].itemCount do
		local slot
		if MB_config.isStacked then
			slot = self:CheckSlotFromSortDB(itemIndexCount, usedSlot)
		end	
		if not slot then
			
			usedSlot = usedSlot + 1
			
			slot = SelectSortMethod[method](usedSlot, args)
			
			slot = self:InsertToSortDB(slot, itemIndexCount, true)
		end
		
		slot = self:InsertToSortDB(slot, itemIndexCount)
	end
	slotDB.usedSlot = usedSlot
	--return slotDB
end

---- GUI ----
function MB:ChooseChar_OnClick(self)
	selectValue = self.value
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameDropDown, self.value);
	MB:SearchBarResetAndClear()
	MB:Update(true)
	
	local text = MailboxBankFrameDropDownText;
	local width = text:GetStringWidth();
	MailboxBankFrameDropDown:SetWidth(width+60)	
end

local function MB:DropDownMenuInitialize()
	local info = UIDropDownMenu_CreateInfo();
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			info = UIDropDownMenu_CreateInfo()
			info.text = k
			info.value = k
			info.func = MB:ChooseChar_OnClick;
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameDropDown, selectValue);
	local text = MailboxBankFrameDropDownText;
	local width = text:GetStringWidth();
	MailboxBankFrameDropDown:SetWidth(width+60)
end

function MB:CreatMailboxBankFrame(name)
	----Create mailbox bank frame
	local E
	if ElvUI then E = unpack(ElvUI) end
	local f = CreateFrame("Frame", name, UIParent)
	if E then
		f:SetTemplate(E.db.bags.transparent and "notrans" or "Transparent")
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
	f:SetWidth(MB_config.frameWidth)
	f:SetHeight(MB_config.frameHeight)
	f:SetPoint(MB_config.pa or "CENTER", MB_config.px or 0, MB_config.py or 0)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:RegisterForClicks("AnyUp");
	f:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		MB_config.p, MB_config.pf, MB_config.pa, MB_config.px, MB_config.py = self:GetPoint()
	end)
	f:Hide()
	
	----Create close button
	f.closeButton = CreateFrame("Button", name.."CloseButton", f, "UIPanelCloseButton");
	f.closeButton:Point("TOPRIGHT", -2, -2);
	f.closeButton:HookScript("OnClick", function()
		MB:SearchBarResetAndClear()
		collectgarbage("collect")
	end)
	
	----Create stack up button
	f.stackUpCheckButton = CreateFrame("CheckButton", name.."StackUpCheckButton", f, "UICheckButtonTemplate");
	f.stackUpCheckButton:Point("TOPLEFT", 2, -2)
	f.stackUpCheckButton.text:SetText(L["Stack items"])
	f.stackUpCheckButton:SetScript("OnClick", function(self)
		MB_config.isStacked = self:GetChecked()
		MB:Update(true)
	end)

	----Create choose char dropdown menu
	tinsert(UISpecialFrames, name)
	f.chooseChar = CreateFrame('Frame', name..'DropDown', f, 'UIDropDownMenuTemplate')
	f.chooseChar:Point("TOPLEFT", f, 80, -6)
	UIDropDownMenu_Initialize(chooseChar, MB:DropDownMenuInitialize);
	
	----Search
	f.searchingBar = CreateFrame('EditBox', name..'searchingBar', f);
	f.searchingBar:SetFrameLevel(f.searchingBar:GetFrameLevel() + 2);
	f.searchingBar:CreateBackdrop('Default', true);
	f.searchingBar:Height(15);
	f.searchingBar:Width(200);
	f.searchingBar:Hide();
	f.searchingBar:Point('TOPLEFT', f, 'TOPLEFT', 8, -40);
	--f.searchingBar:Point('TOPLEFT', f, 'TOPLEFT', 120, 60);
	f.searchingBar:SetAutoFocus(true);
	f.searchingBar:SetScript("OnEscapePressed", MB:SearchBarResetAndClear);
	f.searchingBar:SetScript("OnEnterPressed", MB:SearchBarResetAndClear);
	f.searchingBar:SetScript("OnEditFocusLost", f.searchingBar.Hide);
	f.searchingBar:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
		MB:UpdateSearch()
	end);
	f.searchingBar:SetScript("OnTextChanged", MB:UpdateSearch);
	f.searchingBar:SetScript('OnChar', MB:UpdateSearch);
	f.searchingBar:SetText(SEARCH);
	f.searchingBar:FontTemplate();

	f.searchingBarText = f:CreateFontString(nil, "ARTWORK");
	f.searchingBarText:FontTemplate();
	f.searchingBarText:SetAllPoints(f.searchingBar);
	f.searchingBarText:SetJustifyH("LEFT");
	f.searchingBarText:SetText("|cff9999ff" .. SEARCH);
		
	local button = CreateFrame("Button", nil, f)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	button:SetAllPoints(f.searchingBarText);
	button:SetScript("OnClick", function(f, btn)
		if btn == "RightButton" then
			MB:OpenEditbox();
		else
			if f:GetParent().searchingBar:IsShown() then
				f:GetParent().searchingBar:Hide();
				f:GetParent().searchingBar:ClearFocus();
				f:GetParent().searchingBarText:Show();
				MB:SearchReset();
			else
				MB:OpenEditbox();
			end
		end
	end)
	
	----Create collect mailbox gold button
	f.CollectGoldButton = CreateFrame("Button", name.."CollectGoldButton", f, "UIPanelButtonTemplate");
	f.CollectGoldButton:SetWidth(100)
	f.CollectGoldButton:SetHeight(30)
	f.CollectGoldButton:Point("BOTTOMLEFT", 10, 5);
	f.CollectGoldButton:SetText(L["Collect gold"])
	f.CollectGoldButton:SetScript("OnClick", MB:CollectMoney)
	
	----Create mailbox gold text
	f.mailboxGoldText = f:CreateFontString(nil, 'OVERLAY');
	f.mailboxGoldText:FontTemplate()
	f.mailboxGoldText:Point("LEFT", f.CollectGoldButton, "RIGHT", 20, 0);
	
	----Create check time text
	-- f.checktime = f:CreateFontString(nil, 'OVERLAY');
	-- f.checktime:FontTemplate()
	-- f.checktime:Point("BOTTOMLEFT", 20, 5);
	
	----Create scroll frame
	f.scrollBar = CreateFrame("ScrollFrame", name.."ScrollBarFrame", f, "FauxScrollFrameTemplate")
	f.scrollBar:SetPoint("TOPLEFT", 0, -64)
	f.scrollBar:SetPoint("BOTTOMRIGHT", -28, 40)
	f.scrollBar:SetHeight( MB_config.numItemsRows * MB_config.buttonSize + (MB_config.numItemsRows - 1) * MB_config.buttonSpacing)
	f.scrollBar:Hide()
	--f.scrollBar:EnableMouseWheel(true)
	f.scrollBar:SetScript("OnVerticalScroll",  function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, MB_config.buttonSize + MB_config.buttonSpacing);
		MB:Update()
	end)
	f.scrollBar:SetScript("OnShow", function()
		MB:Update()
	end)
	
	if E then
		local S = E:GetModule("Skins")
		if S then
			S:HandleCloseButton(f.closeButton);
			S:HandleCheckBox(f.stackUpCheckButton);
			S:HandleDropDownBox(f.chooseChar, 180)
			S:HandleButton(f.CollectGoldButton)
			S:HandleScrollBar(f.scrollBar);
		end
	end
	
	----Create Container
	local containerID = 1
	f.Container = {}
	f.Container[containerID] = CreateFrame('Frame', name..'Container'..containerID, f);
	--f.Container[containerID]:SetID(containerID);
	f.Container[containerID]:Point('TOPLEFT', f, 'TOPLEFT', 8, -64);
	f.Container[containerID]:Point('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 8);
	f.Container[containerID]:Show()
	
	local numContainerRows = 0;
	local lastButton;
	local lastRowButton;
	for i = 1, MB_config.itemsSlotDisplay do
		local slot = CreateFrame('Button', name..'Container'..containerID..'Slot'..i, f.Container[containerID]);
		slot:Hide()
		slot:SetTemplate('Default');
		slot:StyleButton();
		slot:Size(MB_config.buttonSize);
		
		slot.count = slot:CreateFontString(nil, 'OVERLAY');
		slot.count:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE')
		slot.count:FontTemplate()
		slot.count:Point('BOTTOMRIGHT', 0, 2);
		
		slot.tex = slot:CreateTexture(nil, "OVERLAY", nil)
		slot.tex:Point("TOPLEFT", slot, "TOPLEFT", 2, -2)
		slot.tex:Point("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 2)
		slot.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		
		slot:SetScript("OnEnter", function(self)
			MB:TooltipShow(self)
		end)
		slot:HookScript("OnClick", function(self,button)
			MB:SlotClick(self,button)
		end)
		slot:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		
		f.Container[containerID][i] = slot
		
		if lastButton then
			if (i - 1) % MB_config.numItemsPerRow == 0 then
				slot:Point('TOP', lastRowButton, 'BOTTOM', 0, -MB_config.buttonSpacing);
				lastRowButton = f.Container[containerID][i];
				numContainerRows = numContainerRows + 1;
			else
				slot:Point('LEFT', lastButton, 'RIGHT', MB_config.buttonSpacing, 0);
			end
		else
			slot:Point('TOPLEFT', f.Container[containerID], 'TOPLEFT',0, 0)
			--slot:Point('TOPLEFT', f, 'TOPLEFT', 8, -60);
			lastRowButton = f.Container[containerID][i];
			numContainerRows = numContainerRows + 1;
		end
		lastButton = f.Container[containerID][i];
	end
	
	-- return f
end

function MB:TooltipShow(self)
	if self and self.link then
		local x = self:GetRight();
		if ( x >= ( GetScreenWidth() / 2 ) ) then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		end
		GameTooltip:SetHyperlink(self.link)
		
		local formatList = {}
		for i = 1 , getn(self.countnum) do
			if formatList[self.sender[i]] == nil then
				formatList[self.sender[i]] = {}
				local row = {}
				row.lefttext = L["Sender: "] ..self.sender[i]
				row.righttext = 0
				tinsert(formatList[self.sender[i]], row)
			end
			
			local lefttext = L["+ Left time"]
			local dayLeftTick = difftime(floor(self.dayleft[i] * 86400) + self.checkMailTick,time())
			local leftday = floor(dayLeftTick / 86400)
			if leftday > 0 then
				lefttext = lefttext..L["greater than"]..tostring(leftday)..L["days"]
			else
				local lefthour = floor((dayLeftTick-leftday*86400) / 3600) 
				local leftminute = floor((dayLeftTick-leftday*86400-lefthour*3600) / 60)
				lefttext = lefttext..tostring(lefthour)..L["hours"]..tostring(leftminute)..L["minutes"]
			end
			
			local foundSameLefttime = false
			for j = 1, getn(formatList[self.sender[i]]) do
				if formatList[self.sender[i]][j].lefttext == lefttext then
					formatList[self.sender[i]][j].righttext = formatList[self.sender[i]][j].righttext + self.countnum[i]
					formatList[self.sender[i]][1].righttext = formatList[self.sender[i]][1].righttext + self.countnum[i]
					foundSameLefttime = true
				end
			end
			
			if foundSameLefttime == false then
				local row = {}
				row.lefttext = lefttext
				row.righttext = self.countnum[i]
				row.leftday = leftday
				formatList[self.sender[i]][1].righttext = formatList[self.sender[i]][1].righttext + self.countnum[i]
				tinsert(formatList[self.sender[i]], row)
			end
		end

		for k in pairs(formatList) do
			for i = 1, getn(formatList[k]) do
				local rL, gL, bL = 1, 1, 1
				if i > 1 then
					local leftday = formatList[k][i].leftday
					if leftday < MB_config.daysLeftRed then
						rL, gL, bL = 1, 0, 0
					elseif leftday < MB_config.daysLeftYellow then
						rL, gL, bL = 1, 1, 0
					else
						rL, gL, bL = 0, 1, 0
					end
				end
				GameTooltip:AddDoubleLine(formatList[k][i].lefttext, formatList[k][i].righttext, rL, gL, bL)
			end
		end
		
		if self.wasReturned == 1 then
			GameTooltip:AddLine(L["was returned"])
		end

		GameTooltip:Show()
	end
end

function MB:SlotClick(self,button)
	local msg = self.link
	if not msg then return; end
	if IsShiftKeyDown() and button == 'LeftButton' then
		if AuctionFrame and AuctionFrame:IsVisible() then
			BrowseName:SetText(GetItemInfo(msg))
			return;
		end
		if ChatFrame1EditBox:IsShown() then
			ChatFrame1EditBox:Insert(msg);
		else
			local ExistMSG = ChatFrame1EditBox:GetText() or "";
			ChatFrame1EditBox:SetText(ExistMSG..msg);
			ChatEdit_SendText(ChatFrame1EditBox);
			ChatFrame1EditBox:SetText("");
			ChatFrame1EditBox:Hide();
		end
	elseif button == 'LeftButton' then
		if self.mailIndex and self.attachIndex then
			for i = 1 , getn(self[mailIndex]) do
				TakeInboxItem(self[mailIndex][i], self[attachIndex][i])
			end
			MB:Update(true)
		end
	end

end

function MB:UpdateContainer()
	local f = MailboxBankFrame
	local containerID = 1
	for i = 1, MB_config.itemsSlotDisplay do
		if f.Container[containerID][i] then
			f.Container[containerID][i]:Hide()
		end
	end
	f.stackUpCheckButton:SetChecked(MB_config.isStacked)
	if not slotDB then return end
	
	f.mailboxGoldText:SetText(L["Mailbox gold: "]..GetCoinTextureString(MB_DB[selectValue].money))
	--f.mailboxTime:SetText(floor(difftime(time(),sorted_db[selectValue].checkMailTick)/60).." 分鐘前掃描" or "");

	local offset = FauxScrollFrame_GetOffset(f.scrollBar)
	
	local iconDisplayCount
	if (slotDB.usedSlot - offset * 8) > MB_config.itemsSlotDisplay then
		iconDisplayCount = MB_config.itemsSlotDisplay
	else
		iconDisplayCount = slotDB.usedSlot - offset * 8
	end
	
	for i = 1, iconDisplayCount do
		local itemIndex = i + offset * 8
		
		local slot = f.Container[containerID][i]
		slot.link = slotDB[itemIndex].link
		slot.checkMailTick = slotDB[itemIndex].checkMailTick
		slot.sender = slotDB[itemIndex].sender
		slot.dayleft = slotDB[itemIndex].dayLeft
		slot.countnum = slotDB[itemIndex].countNum
		
		slot.mailIndex = slotDB[itemIndex].mailIndex
		slot.attachIndex = slotDB[itemIndex].attachIndex
		slot.wasReturned = slotDB[itemIndex].wasReturned
		
		if slot.link then
			slot.name, _, slot.rarity, _, _, _, _, _, _, slot.texture = GetItemInfo(slot.link);
			if slot.rarity and slot.rarity > 1 then
				local r, g, b = GetItemQualityColor(slot.rarity);
				slot:SetBackdropBorderColor(r, g, b);
			else
				--slot:SetBackdropBorderColor(unpack(E.media.bordercolor));
				slot:SetBackdropBorderColor(0.3, 0.3, 0.3)
			end
			slot.tex:SetTexture(slot.texture)
		else
			--slot:SetBackdropBorderColor(unpack(E.media.bordercolor));
			slot:SetBackdropBorderColor(0.3, 0.3, 0.3)
		end
		
		local countnum = 0
		for i = 1 , getn(slot.countnum) do
			countnum = countnum + slot.countnum[i]
		end
		slot.count:SetText(countnum > 1 and countnum or '');
		
		slot.tex:SetVertexColor(1, 1, 1)
		slot.count:SetTextColor(1, 1, 1)
		if slot.CODAmount then
			slot.tex:SetDesaturated(1)
		end
		if f.searchingBar:HasFocus() then
			if not slot.name then break end
			local searchingStr = f.searchingBar:GetText();
			if not find(slot.name, searchingStr) then
				slot.tex:SetVertexColor(0.25, 0.25, 0.25)
				slot:SetBackdropBorderColor(0.3, 0.3, 0.3)
				slot.count:SetTextColor(0.3, 0.3, 0.3)
			end
		end

		slot:Show()
	end
	FauxScrollFrame_Update(f.scrollBar, ceil(slotDB.usedSlot / MB_config.numItemsPerRow) , MB_config.numItemsRows, MB_config.buttonSize + MB_config.buttonSpacing );
end

function MB:Update(isSortDB)
	if isSortDB then MB:SortDB() end
	MB:UpdateContainer()
end

function MB:AlertDeadlineMails()
	if not MB_DB[playername] then return end
	local DeadlineList = {}
	for i = MB_DB[playername].itemCount , 1, -1 do
		local dayLeft = floor(difftime(floor(MB_DB[playername][i].daysLeft * 86400) + MB_DB[playername].checkMailTick,time()) / 86400)
		if dayLeft < 3 then
			tinsert(DeadlineList, MB_DB[playername][i].itemLink)
		else
			break
		end
	end
	if DeadlineList ~= {} then
		local alertText = L["MailboxBank: |cffaa0000: |r"]
		for i, v in pairs(DeadlineList) do
			alertText = alertText .. v
		end
		alertText = alertText .. L["|cffaa0000Please remember to check it!|r"]
		print(alertText)
	end
end

local function MB:HookSendMail(recipient, subject, body)
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			if recipient..'-'..GetRealmName() == k then
				for i = ATTACHMENTS_MAX_RECEIVE, 1, -1 do
					local Name, _, count, _ = GetSendMailItem(i)
					if Name then
						local _, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(Name or "")
						MB:AddItem(GetUnitName("player"), itemLink, count, 31, 1, i, 0, nil, k)
					end
				end
				if MailboxBankFrame:IsVisible() and selectValue == k then
					MB:Update(true)
				end
				break
			end
		end
	end
end

local function MB:FrameShow()
	MailboxBankFrame:Show()
end

local function MB:FrameHide()
	MailboxBankFrame:Hide()
	MB:SearchBarResetAndClear()
	collectgarbage("collect")
end

local function MB:MAIL_INBOX_UPDATE()
	MB:CheckMail()
	if selectValue == playername then
		MB:Update(true)
	end
end

local function MB:MAIL_SHOW()
	if not MailboxBankFrame:IsVisible() then self:FrameShow(); end
end

local function MB:MAIL_CLOSED()
	self:FrameHide()
end

---- Event ----

function MB:OnInitialize()
	-- Register events
	self:RegisterEvent("MAIL_INBOX_UPDATE")
	self:RegisterEvent("MAIL_SHOW")
	self:RegisterEvent("MAIL_CLOSED")

	if MB_config == nil then
		MB_config = {}
		for k ,v in pairs(MailboxBank_Config_INIT) do
			MB_config[k] = v;
		end
	end
	if not MB_DB then MB_DB = {} end
	self.CreatMailboxBankFrame("MailboxBankFrame")
	MB:AlertDeadlineMails()
		
	self.OnInitialize = nil
end

hooksecurefunc("SendMail", MB:HookSendMail)

SLASH_MAILBOXBANK1 = "/mb";
SLASH_MAILBOXBANK2 = "/mailbox";
SlashCmdList["MAILBOXBANK"] = function()
	if not MailboxBankFrame then return end
	if MailboxBankFrame:IsVisible() then
		MB:FrameHide()
	else
		MB:Update(true)
		MB:FrameShow()
	end
end;