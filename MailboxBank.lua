local E, L, V, P, G, _ = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
--local MB = E:NewModule("MailboxBank")
local getn, tinsert = table.getn, table.insert
local floor = math.floor
local match, join, format = string.match, string.join, string.format
local isStacked
local isMailShow = false
local checkMailTick
local playername = E.myname..'-'..E.myrealm
local selectValue = playername
--local NUM_BAGITEMS_PER_ROW, NUM_BAGITEMS_ROWS, BAGITEMS_ICON_DISPLAYED = 8, 10, 80
local SlotDB

local MailboxBank_config_init = {
	daysLeftYellow = 5,
	daysLeftRed = 3,
	buttonSize = 36,
	buttonSpacing = 4,
	numItemsPerRow = 8,
	numItemsRows = 10,
	itemsSlotDisplay = 80,
	topOffset = 40,
	leftOffset = 8,
	frameWidth = 350,
	frameHeight = 500,
	rowcount = 8,
	maxrow = 10,
	px = 0,
	py = 0,
}	

function MailboxBank_AddItem(sender, name, itemTexture, count, itemLink, daysLeft, mailIndex, itemIndex, wasReturned)
	local item = {}
	--item["name"] = name
	item["sender"] = sender
	--item["itemTexture"] = itemTexture
	item["count"] = count
	item["itemLink"] = itemLink
	item["daysLeft"] = daysLeft
	item["mailIndex"] = mailIndex
	item["itemIndex"] = itemIndex
	--item["wasReturned"] = wasReturned
	tinsert(MB_DB[playername], item)
	MB_DB[playername].itemCount = MB_DB[playername].itemCount + 1
end

function MailboxBank_CheckMail()
	MB_DB[playername] = {itemCount = 0, money = 0}
	local numItems, totalItems = GetInboxNumItems()
	if numItems and numItems > 0 then
		for mailIndex = 1, numItems do
			local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(mailIndex);
			--if isGM ~= nil then print("GM@"..sender) end
			if money > 0 then MB_DB[playername].money = MB_DB[playername].money + money end
			if hasItem and CODAmount == 0 then
				if sender == nil then
					sender = "UNKNOWN SENDER CAUSE OF NETWORK" 
					--return false
				end
				if wasRead then hasItem = ATTACHMENTS_MAX_RECEIVE end
				for itemIndex = 1, hasItem do
					local name, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, itemIndex)
					local itemLink = GetInboxItemLink(mailIndex, itemIndex)
					if name and itemLink then
						MailboxBank_AddItem(sender, name, itemTexture, count, itemLink, daysLeft, mailIndex, itemIndex, wasReturned)
					end
				end
			end
		end
	end
	checkMailTick = time()
	MB_DB[playername].checkMailTick = checkMailTick
	--return true
end

function MailboxBank_ChooseChar_OnClick(self)
	MailboxBank_UpdateContainer(self.value)
	selectValue = self.value
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameDropDown, self.value);

	local text = MailboxBankFrameDropDownText;
	local width = text:GetStringWidth();
	MailboxBankFrameDropDown:SetWidth(width+60)	
end

function FormatMoney(money)
	--if money == 0 or not money then return 0 end
	local copperFormatter = join("", "%d", L.copperabbrev)
	local silverFormatter = join("", "%d", L.silverabbrev, " %.2d", L.copperabbrev)
	local goldFormatter =  join("", "%s", L.goldabbrev, " %.2d", L.silverabbrev, " %.2d", L.copperabbrev)
	local gold, silver, copper = floor(abs(money / 10000)), abs(mod(money / 100, 100)), abs(mod(money, 100))
	if gold ~= 0 then
		if gold > 999 then
			return format("%s"..L.goldabbrev, BreakUpLargeNumbers(gold))
		else
			return format(goldFormatter, BreakUpLargeNumbers(gold), silver, copper)
		end		
	elseif silver ~= 0 then
		return format(silverFormatter, silver, copper)
	else
		return format(copperFormatter, copper)
	end
end

function MailboxBank_SortDB(oriDB, player, isStacked)

	local numItems = oriDB[player].itemCount
	local usedSlot = 0
	local slotDB = {}
	for itemID = 1, numItems do
		local slot
		if isStacked then
			for i = 1, usedSlot do
				if tonumber(match(slotDB[i].link, "item:(%d+)")) == tonumber(match(oriDB[player][itemID].itemLink, "item:(%d+)")) then
					slot = slotDB[i]
				end
			end
		end	
		if not slot then
			usedSlot = usedSlot + 1
			slotDB[usedSlot] = {}
			slot = slotDB[usedSlot]
			
			slot.link = oriDB[player][itemID].itemLink
			slot.checkMailTick = oriDB[player].checkMailTick
			slot.sender = {}
			slot.dayLeft = {}
			slot.countNum = {}
			if player == playername and not isStacked then
				slot.mailIndex = oriDB[player][itemID].mailIndex
				slot.itemIndex = oriDB[player][itemID].itemIndex
			end
		end
		
		tinsert(slot.sender , oriDB[player][itemID].sender)
		tinsert(slot.dayLeft , oriDB[player][itemID].daysLeft)
		tinsert(slot.countNum , oriDB[player][itemID].count)
	end
	slotDB.usedSlot = usedSlot
	return slotDB
end


---- GUI ----
function MailboxBank_DropDownMenuInitialize()
	local info = UIDropDownMenu_CreateInfo();
	
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			info = UIDropDownMenu_CreateInfo()
			info.text = k
			info.value = k
			info.func = MailboxBank_ChooseChar_OnClick;
			UIDropDownMenu_AddButton(info, level)
		end
	end
	
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameDropDown, selectValue);
	local text = MailboxBankFrameDropDownText;
	local width = text:GetStringWidth();
	MailboxBankFrameDropDown:SetWidth(width+60)
end

function MailboxBank_ScrollBarUpdate()

end

function MailboxBank_CreatFrame(name)
	----Create mailbox bank frame
	local f = CreateFrame("Button", name, UIParent)
	f:SetTemplate(E.db.bags.transparent and "notrans" or "Transparent")
	f:SetFrameStrata("DIALOG");
	f:SetWidth(MB_config.frameWidth)
	f:SetHeight(MB_config.frameHeight)
	f:SetPoint(MB_config.pa or "CENTER", MB_config.px or 0, MB_config.py or 0)
	--f:SetPoint("CENTER", 0, 0)
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
	E:GetModule("Skins"):HandleCloseButton(f.closeButton);
	
	----Creat check button
	f.checkButton = CreateFrame("CheckButton", name.."CheckButton", f, "UICheckButtonTemplate");
	f.checkButton:Point("TOPLEFT", 2, -2)
	f.checkButton.text:SetText("堆疊物品")
	f.checkButton:SetScript("OnClick", function(self)
		isStacked = self:GetChecked()
		MailboxBank_UpdateContainer(selectValue)
	end)
	E:GetModule("Skins"):HandleCheckBox(f.checkButton);
	
	----Create check time text
	f.mailboxGold = f:CreateFontString(nil, 'OVERLAY');
	f.mailboxGold:FontTemplate()
	f.mailboxGold:Point("BOTTOMLEFT", 20, 5);
	
	tinsert(UISpecialFrames, f:GetName())
	local chooseChar = CreateFrame('Frame', f:GetName()..'DropDown', f, 'UIDropDownMenuTemplate')
	chooseChar:Point("TOPLEFT", 80, -6)
	E.Skins:HandleDropDownBox(chooseChar, 180)
	f.chooseChar = chooseChar
	UIDropDownMenu_Initialize(chooseChar, MailboxBank_DropDownMenuInitialize);

	----Create sort dropdown menu
	--[[local f.dropDownMenu = CreateFrame("Frame", f:GetName().."DropDown", f, "UIDropDownMenuTemplate")
	f.dropDownMenu:Point("TOPLEFT", 80, -6)
	E.Skins:HandleDropDownBox(f.dropDownMenu, 180)
	UIDropDownMenu_Initialize(f.dropDownMenu, MailboxBank_DropDownMenuInitialize);]]
	
	f.scrollBar = CreateFrame("ScrollFrame", name.."ScrollBarFrame", f, "FauxScrollFrameTemplate")
	f.scrollBar:SetPoint("TOPLEFT", 0, -40)
	f.scrollBar:SetPoint("BOTTOMRIGHT", -28, 8)
	f.scrollBar:SetHeight( MB_config.numItemsRows * MB_config.buttonSize + (MB_config.numItemsRows - 1) * MB_config.buttonSpacing)
	f.scrollBar:Hide()
	f.scrollBar:HookScript("OnVerticalScroll",  function(self, offset)
		print("-------")	
		print("OnVerticalScroll offset "..offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, MB_config.buttonSize + MB_config.buttonSpacing/2, MailboxBank_Update());
	end)
	f.scrollBar:SetScript("OnShow", function()
		MailboxBank_UpdateContainer(selectValue)
	end)

	E:GetModule("Skins"):HandleScrollBar(f.scrollBar);
	
	local containerID = 1
	f.Container = {}
	f.Container[containerID] = CreateFrame('Frame', f:GetName()..'Container'..containerID, f);
	f.Container[containerID]:SetID(containerID);
	f.Container[containerID]:Show()
	
	--f.scrollBar:SetScrollChild(f.Container[containerID])
	--f.Container[containerID].numSlots = 0;
	
	local numContainerRows = 0;
	local lastButton;
	local lastRowButton;
	for i = 1, MB_config.itemsSlotDisplay do
		local slot = CreateFrame('Button', f:GetName()..'Container'..containerID..'Slot'..i, f.Container[containerID]);
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
			MailboxBank_TooltipShow(self)
		end)
		slot:HookScript("OnClick", function(self,button)
			MailboxBank_SlotClick(self,button)
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
			slot:Point('TOPLEFT', f, 'TOPLEFT', MB_config.leftOffset, -MB_config.topOffset);
			lastRowButton = f.Container[containerID][i];
			numContainerRows = numContainerRows + 1;
		end
		lastButton = f.Container[containerID][i];
		
	end
	
	return f
end

function MailboxBank_TooltipShow(self)
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
				row.lefttext = "發件人: "..self.sender[i]
				row.righttext = 0
				tinsert(formatList[self.sender[i]], row)
			end
			
			local lefttext = "+ 剩餘 "
			local dayLeftTick = difftime(floor(self.dayleft[i] * 86400) + self.checkMailTick,time())
			local leftday = floor(dayLeftTick / 86400)
			if leftday > 0 then
				lefttext = lefttext.."大於"..tostring(leftday).."天"
			else
				local lefthour = floor((dayLeftTick-leftday*86400) / 3600) 
				local leftminute = floor((dayLeftTick-leftday*86400-lefthour*3600) / 60)
				lefttext = lefttext..tostring(lefthour).."小時"..tostring(leftminute).."分鐘"
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
		
		GameTooltip:Show()
	end
end

function MailboxBank_SlotClick(self,button)
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
		if self.mailIndex and self.itemIndex then
			TakeInboxItem(self.mailIndex, self.itemIndex)
		end
	end

end

function MailboxBank_UpdateContainer(playername,offset)
	local f = MailboxBankFrame --or MailboxBank_CreatFrame("MailboxBankFrame");
	f.mailboxGold:SetText("郵箱金幣: "..FormatMoney(MB_DB[playername].money))
	--f.mailboxTime:SetText(floor(difftime(time(),sorted_db[playername].checkMailTick)/60).." 分鐘前掃描" or "");
--	local playername = selectValue

	SlotDB = MailboxBank_SortDB(MB_DB, playername, isStacked)
	local usedSlot = SlotDB.usedSlot
	local containerID = 1

	--scrollbar!!!
	if ( usedSlot > MB_config.itemsSlotDisplay) then
		f.scrollBar:Show();
	else
		f.scrollBar:Hide();
	end

	local offset = FauxScrollFrame_GetOffset(f.scrollBar)
	--print("ScrollBar offset: "..offset)

	for i = 1, MB_config.itemsSlotDisplay do
		if f.Container[containerID][i] then
			f.Container[containerID][i]:Hide()
		end
	end
	FauxScrollFrame_Update(f.scrollBar, ceil(usedSlot / MB_config.numItemsPerRow) , MB_config.numItemsRows, MB_config.buttonSize + MB_config.buttonSpacing );
	--FauxScrollFrame_Update(f.scrollBar, usedSlot, MAX_ROWS or 10, buttonSize + buttonSpacing)

	local iconDisplayCount
	if (usedSlot - offset * 8) > MB_config.itemsSlotDisplay then
		iconDisplayCount = MB_config.itemsSlotDisplay
	else
		iconDisplayCount = usedSlot - offset * 8
	end
	
	for i = 1, iconDisplayCount do
		local itemID = i + offset * 8
		
		slot = f.Container[containerID][i]
		slot.link = SlotDB[itemID].link
		slot.checkMailTick = SlotDB[itemID].checkMailTick
		slot.sender = SlotDB[itemID].sender
		slot.dayleft = SlotDB[itemID].dayLeft
		slot.countnum = SlotDB[itemID].countNum
		
		if SlotDB[itemID].mailIndex and SlotDB[itemID].itemIndex then
			--print()
			slot.mailIndex = SlotDB[itemID].mailIndex
			slot.itemIndex = SlotDB[itemID].itemIndex
		end
		
		if slot.link then
			slot.name, _, slot.rarity, _, _, _, _, _, _, slot.texture = GetItemInfo(slot.link);
			if slot.rarity and slot.rarity > 1 then
				local r, g, b = GetItemQualityColor(slot.rarity);
				slot:SetBackdropBorderColor(r, g, b);
			else
				slot:SetBackdropBorderColor(unpack(E.media.bordercolor));
			end
			slot.tex:SetTexture(slot.texture)
		else
			slot:SetBackdropBorderColor(unpack(E.media.bordercolor));
		end
		
		local countnum = 0
		for i = 1 , getn(slot.countnum) do
			countnum = countnum + slot.countnum[i]
		end
		slot.count:SetText(countnum > 1 and countnum or '');
		slot:Show()
	end
end

---- Event ----
function MailboxBank_Show()
	selectValue = playername;
	MailboxBankFrame:Show()
end

function MailboxBank_Hide()
	MailboxBankFrame:Hide()
end

function MailboxBank_OnEvent(self, event, ...)
	if event == "MAIL_INBOX_UPDATE" then
		MailboxBank_CheckMail()
		if selectValue == playername then
			MailboxBank_UpdateContainer(playername)
		end
	end
	if event == "MAIL_SHOW" then
		isMailShow = true
		if not MailboxBankFrame:IsVisible() then MailboxBank_Show(); end
	end
	if event == "MAIL_CLOSED" then
		isMailShow = false
		MailboxBank_Hide()
	end
	if event == "ADDON_LOADED" then
	--	print("MailboxBank loaded")
	end
	if event == "PLAYER_ENTERING_WORLD" then
		if MB_config == nil then
			MB_config = {}
			E:CopyTable(MB_config, MailboxBank_config_init)
		end
		if not MB_DB then MB_DB = {} end
		MailboxBankFrame = MailboxBank_CreatFrame("MailboxBankFrame")
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end

local MailboxBank_Event = CreateFrame("Frame")
MailboxBank_Event:RegisterEvent("ADDON_LOADED")
MailboxBank_Event:RegisterEvent("PLAYER_ENTERING_WORLD")
MailboxBank_Event:RegisterEvent("MAIL_INBOX_UPDATE")
MailboxBank_Event:RegisterEvent("MAIL_SHOW")
MailboxBank_Event:RegisterEvent("MAIL_CLOSED")
MailboxBank_Event:SetScript("OnEvent", MailboxBank_OnEvent)

SLASH_MAILBOXBANK1 = "/mb";
SLASH_MAILBOXBANK2 = "/mailbox";
SlashCmdList["MAILBOXBANK"] = function()
	if MailboxBankFrame and MailboxBankFrame:IsVisible() then
		MailboxBank_Hide()
	else
		MailboxBank_UpdateContainer(selectValue)
		MailboxBank_Show()
	end
end;