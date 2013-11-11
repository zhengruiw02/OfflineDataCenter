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
local L = LibStub("AceLocale-3.0"):GetLocale("MailboxBank")
local getn, tinsert = table.getn, table.insert
local floor = math.floor
local len, sub, find, format, match = string.len, string.sub, string.find, string.format, string.match
local playername = GetUnitName("player")..'-'..GetRealmName()
local selectValue = playername
local slotDB

local MB = CreateFrame("Frame", nil , UIParent)
MB:SetPoint("CENTER", 0, 0)

MB.config_init = {
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

function MB:BuildAHOrder()
	self.itemTypes = {}
	self.itemSubTypes = {}
	for i, iType in ipairs({GetAuctionItemClasses()}) do
		self.itemTypes[iType] = i
		self.itemSubTypes[iType] = {}
		for ii, isType in ipairs({GetAuctionItemSubClasses(i)}) do
			self.itemSubTypes[iType][isType] = ii
		end
	end
end

function MB:AddItem(sender, itemLink, count, daysLeft, mailIndex, attachIndex, CODAmount, wasReturned, recipient)
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

function MB:CheckMail(isCollectMoney)
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

function MB:CalcDeadline()

end

function MB:UpdateSearch()
	local f = self.MB_Frame
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
			self:SearchBarResetAndClear();
			return;
		end
	end
	self:UpdateContainer();
end

function MB:OpenEditbox()
	local f = self.MB_Frame
	f.searchingBarText:Hide();
	f.searchingBar:Show();
	f.searchingBar:SetText(SEARCH);
	f.searchingBar:HighlightText();
end

function MB:SearchBarResetAndClear()
	local f = self.MB_Frame
	f.searchingBarText:Show();
	f.searchingBar:ClearFocus();
	f.searchingBar:SetText("");
	self:UpdateContainer()
end

function MB:CollectMoney()
	self:CheckMail(true)
end

function MB:InsertToRevIndexTable(RevsubDB, keyword)

end

function MB:InsertToIndexTable(subDB, Type, subType, keyword)
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

function MB:CheckSlotFromSortDB(itemIndexCount, usedSlot)
	for i = 1, usedSlot do
		if tonumber(match(slotDB[i].link, "item:(%d+)")) == tonumber(match(MB_DB[selectValue][itemIndexCount].itemLink, "item:(%d+)")) then
			return slotDB[i]
		end
	end
	return nil
end

function MB:InsertToSortDB(slot, itemIndexCount, isInit)
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
function MB:ChooseChar_OnClick(value) ---!!!
	local f = self.MB_Frame
	selectValue = value
	UIDropDownMenu_SetSelectedValue(f.chooseChar, value);
	self:SearchBarResetAndClear()
	self:Update(true)
	
	local text = MailboxBankFrameDropDownText;
	local width = text:GetStringWidth();
	f.chooseChar:SetWidth(width+60)	
end

function MB:DropDownMenuInitialize()
	--local info = UIDropDownMenu_CreateInfo();
	local f = self.MB_Frame
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			local info = UIDropDownMenu_CreateInfo()
			info.text = k
			info.value = k
			info.func = self:ChooseChar_OnClick(info.value); ---???
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_SetSelectedValue(f.chooseChar, selectValue);
	local text = MailboxBankFrameDropDownText;
	local width = text:GetStringWidth();
	f.chooseChar:SetWidth(width+60)
end

function MB:CreatMailboxBankFrame()
	----Create mailbox bank frame
	local E
	if ElvUI then E = unpack(ElvUI) end
	--self.MB_Frame = {}
	--self.MB_Frame = CreateFrame("Frame", nil , UIParent)
	self.MB_Frame = CreateFrame("Frame", nil , UIParent)
	print(self.MB_Frame)
	local f = self.MB_Frame
	f:SetParent(self)
	print(f)
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
	f:SetPoint("CENTER",self,"CENTER", 0, 0)
	--f:SetPoint(MB_config.pa or "CENTER", MB_config.px or 0, MB_config.py or 0)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		MB_config.p, MB_config.pf, MB_config.pa, MB_config.px, MB_config.py = self:GetPoint()
	end)
	--f:Hide()
	
	----Create close button
	f.closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton");
	f.closeButton:SetPoint("TOPRIGHT", -2, -2);
	f.closeButton:HookScript("OnClick", function()
		self:SearchBarResetAndClear()
		collectgarbage("collect")
	end)
	
	----Create stack up button
	f.stackUpCheckButton = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	f.stackUpCheckButton:SetPoint("TOPLEFT", 2, -2)
	f.stackUpCheckButton.text:SetText(L["Stack items"])
	f.stackUpCheckButton:SetScript("OnClick", function(self)
		MB_config.isStacked = self:GetChecked()
		f:GetParent():Update(true)
	end)

	----Search
	if E then
		f.searchingBar = CreateFrame('EditBox', nil, f);
		f.searchingBar:CreateBackdrop('Default', true);
	else
		f.searchingBar = CreateFrame('EditBox', nil, f, "BagSearchBoxTemplate");
	end
	f.searchingBar:SetFrameLevel(self:GetFrameLevel() + 2);
	--f.searchingBar:CreateBackdrop('Default', true);
	f.searchingBar:SetHeight(15);
	f.searchingBar:SetWidth(200);
	f.searchingBar:Hide();
	f.searchingBar:SetPoint('TOPLEFT', f, 'TOPLEFT', 8, -40);
	if E then
		f.searchingBar:FontTemplate()
	else
		f.searchingBar:SetFont(STANDARD_TEXT_FONT, 12);
	end

	f.searchingBarText = f:CreateFontString(nil, "ARTWORK");
	if E then
		f.searchingBarText:FontTemplate()
	else	
		f.searchingBarText:SetFont(STANDARD_TEXT_FONT, 12);
	end
	f.searchingBarText:SetAllPoints(f.searchingBar);
	f.searchingBarText:SetJustifyH("LEFT");
	f.searchingBarText:SetText("|cff9999ff" .. SEARCH);
	
	f.searchingBar:SetAutoFocus(true);
	f.searchingBar:SetText(SEARCH);
	--f.searchingBar:FontTemplate();
	f.searchingBar:SetFont(STANDARD_TEXT_FONT, 12)
		
	local button = CreateFrame("Button", nil, f)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	button:SetAllPoints(f.searchingBarText);
	button:SetScript("OnClick", function(f, btn)
		if btn == "RightButton" then
			f:GetParent():OpenEditbox();
		else
			if f.searchingBar:IsShown() then
				f:GetParent():SearchBarResetAndClear()
			else
				f:GetParent():OpenEditbox();
			end
		end
	end)
	
	----Create choose char dropdown menu
	tinsert(UISpecialFrames, f)
	f.chooseChar = CreateFrame('Frame', "MailboxBankFrameDropDown", f, 'UIDropDownMenuTemplate')
	f.chooseChar:SetPoint("TOPLEFT", f, 80, -6)
	
	
	----Create collect mailbox gold button
	f.CollectGoldButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate");
	f.CollectGoldButton:SetWidth(100)
	f.CollectGoldButton:SetHeight(30)
	f.CollectGoldButton:SetPoint("BOTTOMLEFT", 10, 5);
	f.CollectGoldButton:SetText(L["Collect gold"])

	
	----Create mailbox gold text
	f.mailboxGoldText = f:CreateFontString(nil, 'OVERLAY');
	--f.mailboxGoldText:FontTemplate()
	if E then
		f.mailboxGoldText:FontTemplate()
	else
		f.mailboxGoldText:SetFont(STANDARD_TEXT_FONT, 12);
	end
	f.mailboxGoldText:SetPoint("LEFT", f.CollectGoldButton, "RIGHT", 20, 0);
	
	----Create check time text
	-- f.checktime = f:CreateFontString(nil, 'OVERLAY');
	-- f.checktime:FontTemplate()
	-- f.checktime:SetPoint("BOTTOMLEFT", 20, 5);
	
	----Create scroll frame
	f.scrollBar = CreateFrame("ScrollFrame", "MailboxBankFrameScrollBar", f, "FauxScrollFrameTemplate")
	f.scrollBar:SetPoint("TOPLEFT", 0, -64)
	f.scrollBar:SetPoint("BOTTOMRIGHT", -28, 40)
	f.scrollBar:SetHeight( MB_config.numItemsRows * MB_config.buttonSize + (MB_config.numItemsRows - 1) * MB_config.buttonSpacing)
	f.scrollBar:Hide()
	--f.scrollBar:EnableMouseWheel(true)

	
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
	f.Container = CreateFrame('Frame', nil, f);
	f.Container:SetPoint('TOPLEFT', f, 'TOPLEFT', 8, -64);
	f.Container:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 8);
	f.Container:Show()
	
	local numContainerRows = 0;
	local lastButton;
	local lastRowButton;
	for i = 1, MB_config.itemsSlotDisplay do
		local slot
		if E then
			slot = CreateFrame('Button', nil, f.Container);
			slot:SetTemplate('Default');
			slot:StyleButton();
			slot:Size(MB_config.buttonSize);
		else
			slot = CreateFrame('Button', nil, f.Container, "ItemButtonTemplate");
			slot:SetSize(MB_config.buttonSize, MB_config.buttonSize);
		end
		slot:Hide()
		
		slot.count = slot:CreateFontString(nil, 'OVERLAY');
		if E then
			slot.count:FontTemplate()
		else
			slot.count:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE');
		end
		--slot.count:SetFont(STANDARD_TEXT_FONT, 14)
		slot.count:SetPoint('BOTTOMRIGHT', 0, 2);
		
		slot.tex = slot:CreateTexture(nil, "OVERLAY", nil)
		slot.tex:SetPoint("TOPLEFT", slot, "TOPLEFT", 2, -2)
		slot.tex:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 2)
		slot.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		
		slot:SetScript("OnEnter", function(self)
			f:GetParent():TooltipShow(self)----???
		end)
		slot:HookScript("OnClick", function(self,button)
			f:GetParent():SlotClick(self,button)----???
		end)
		slot:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		
		f.Container[i] = slot
		
		if lastButton then
			if (i - 1) % MB_config.numItemsPerRow == 0 then
				slot:SetPoint('TOP', lastRowButton, 'BOTTOM', 0, -MB_config.buttonSpacing);
				lastRowButton = f.Container[i];
				numContainerRows = numContainerRows + 1;
			else
				slot:SetPoint('LEFT', lastButton, 'RIGHT', MB_config.buttonSpacing, 0);
			end
		else
			slot:SetPoint('TOPLEFT', f.Container, 'TOPLEFT',0, 0)
			--slot:SetPoint('TOPLEFT', f, 'TOPLEFT', 8, -60);
			lastRowButton = f.Container[i];
			numContainerRows = numContainerRows + 1;
		end
		lastButton = f.Container[i];
	end
	
	
	---- SetScript
	
	f.searchingBar:SetScript("OnEscapePressed", function()
		f:GetParent():SearchBarResetAndClear()
	end);
	f.searchingBar:SetScript("OnEnterPressed", function()
		f:GetParent():SearchBarResetAndClear()
	end);
	f.searchingBar:SetScript("OnEditFocusLost", f.searchingBar.Hide);
	f.searchingBar:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
		f:GetParent():UpdateSearch()
	end);
	f.searchingBar:SetScript("OnTextChanged", function()
		f:GetParent():UpdateSearch()
	end);
	f.searchingBar:SetScript('OnChar', function()
		f:GetParent():UpdateSearch()
	end);
	
	f.scrollBar:SetScript("OnVerticalScroll",  function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, MB_config.buttonSize + MB_config.buttonSpacing);
		f:GetParent():Update()
	end)
	f.scrollBar:SetScript("OnShow", function()
		f:GetParent():Update()
	end)
	
	f.CollectGoldButton:SetScript("OnClick", function()
		f:GetParent():CollectMoney()
	end)
	UIDropDownMenu_Initialize(f.chooseChar, self:DropDownMenuInitialize());
	-- return f
end

function MB:TooltipShow(self)--self=slot
	
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

function MB:SlotClick(self,button)----self=slot
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
			for i = getn(self[mailIndex]), 1, -1 do
				TakeInboxItem(self[mailIndex][i], self[attachIndex][i])
			end
			MB:Update(true)
		end
	end

end

function MB:UpdateContainer()
	local f = self.MB_Frame
	if not f or not f.Container then return end
	for i = 1, MB_config.itemsSlotDisplay do
		if f.Container[i] then
			f.Container[i]:Hide()
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
		
		local slot = f.Container[i]
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
	if not self.SortDB then return end
	if isSortDB then self:SortDB() end
	self:UpdateContainer()
end

function MB.AlertDeadlineMails()
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
	if getn(DeadlineList) > 0 then
		local alertText = L["MailboxBank: |cffaa0000: |r"]
		for i, v in pairs(DeadlineList) do
			alertText = alertText .. v
		end
		alertText = alertText .. L["|cffaa0000Please remember to check it!|r"]
		print(alertText)
	end
end

function MB:HookSendMail(recipient, subject, body)
	if not recipient then return end
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			if recipient..'-'..GetRealmName() == k then
				for i = ATTACHMENTS_MAX_RECEIVE, 1, -1 do
					local Name, _, count, _ = GetSendMailItem(i)
					if Name then
						local _, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(Name or "")
						self:AddItem(GetUnitName("player"), itemLink, count, 31, 1, i, 0, nil, k)
					end
				end
				if self.MB_Frame:IsVisible() and selectValue == k then
					self:Update(true)
				end
				break
			end
		end
	end
end

function MB:FrameShow()
	self.MB_Frame:Show()
end

function MB:FrameHide()
	self.MB_Frame:Hide()
	self:SearchBarResetAndClear()
	collectgarbage("collect")
end

function MB:MAIL_INBOX_UPDATE()
	MB:CheckMail()
	if selectValue == playername then
		self:Update(true)
	end
end

function MB:MAIL_SHOW()
	if not self.MB_Frame:IsVisible() then self:FrameShow(); end
end

function MB:MAIL_CLOSED()
	self:FrameHide()
end

---- Event ----

function MB:PLAYER_ENTERING_WORLD()
	-- Register events
	self:RegisterEvent("MAIL_INBOX_UPDATE")
	self:RegisterEvent("MAIL_SHOW")
	self:RegisterEvent("MAIL_CLOSED")
	print("PLAYER_ENTERING_WORLD")
	if MB_config == nil then
		MB_config = {}
		for k ,v in pairs(self.Config_INIT) do
			MB_config[k] = v;
		end
	end
	if not MB_DB then MB_DB = {} end
	self:CreatMailboxBankFrame()
	self:AlertDeadlineMails()
	
	hooksecurefunc("SendMail", self:HookSendMail())
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

---- Event ----

local function MailboxBank_OnEvent(self, event)
	if event == "MAIL_INBOX_UPDATE" then
		self:CheckMail()
		if selectValue == playername then
			self:Update(true)
		end
	end
	if event == "MAIL_SHOW" then
		if not self.MB_Frame:IsVisible() then 
			print(self.MB_Frame:IsVisible())
			self:FrameShow();
			print(self.MB_Frame:IsVisible())
			print(self.MB_Frame)
		end
	end
	if event == "MAIL_CLOSED" then
		self:FrameHide()
	end
	-- if event == "ADDON_LOADED" then
		-- print("MailboxBank loaded")
	-- end
	if event == "PLAYER_ENTERING_WORLD" then
		self:RegisterEvent("MAIL_INBOX_UPDATE")
		self:RegisterEvent("MAIL_SHOW")
		self:RegisterEvent("MAIL_CLOSED")
		if MB_config == nil then
			MB_config = {}
			for k ,v in pairs(self.config_init) do
				MB_config[k] = v;
			end
		end
		if not MB_DB then MB_DB = {} end
		self:CreatMailboxBankFrame()
		self:AlertDeadlineMails()
		print(self.MB_Frame:IsVisible())
		hooksecurefunc("SendMail", function() self:HookSendMail() end)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end
MB:RegisterEvent("PLAYER_ENTERING_WORLD")
MB:SetScript("OnEvent", MailboxBank_OnEvent)
---- Slash command ----

SLASH_MAILBOXBANK1 = "/mb";
SLASH_MAILBOXBANK2 = "/mailbox";
SlashCmdList["MAILBOXBANK"] = function()
	if not MB.MB_Frame then print("not yet");return end
	if MB.MB_Frame:IsVisible() then
		MB:FrameHide()
	else
		MB:Update(true)
		MB:FrameShow()
	end
end;