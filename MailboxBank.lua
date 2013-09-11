local E, L, V, P, G, _ = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local getn, tinsert = table.getn, table.insert
local floor = math.floor
local match = string.match
local isStacked
local checkMailTick
--local daysLeftYellow, daysLeftRed = 5, 3 --daysLeftYellow should greater than daysLeftRed
local playername = E.myname..'-'..E.myrealm
local selectValue = playername

MailboxBank_db = {
	daysLeftYellow = 5,
	daysLeftRed = 3,
	buttonSize = 36,
	buttonSpacing = 4,
	topOffset = 40,
	leftOffset = 8,
	frameWidth = 330,
	frameHeight = 500,
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
	tinsert(MailboxBank_db[playername], item)
	MailboxBank_db[playername].itemCount = MailboxBank_db[playername].itemCount + 1
end

function MailboxBank_CheckMail()
	MailboxBank_db[playername] = {itemCount = 0, money = 0}
	local numItems, totalItems = GetInboxNumItems()
	if numItems and numItems > 0 then
		for mailIndex = 1, numItems do
			local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(mailIndex);
			--if isGM ~= nil then print("GM@"..sender) end
			if money > 0 then MailboxBank_db[playername].money = MailboxBank_db[playername].money + money end
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
	MailboxBank_db[playername].checkMailTick = checkMailTick
	--return true
end

local function ChooseChar_OnClick(self)
	MailboxBank_UpdateContainer(self.value)
	selectValue = self.value
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameDropDown, self.value);

	local text = MailboxBankFrameDropDownText;
	local width = text:GetStringWidth();
	MailboxBankFrameDropDown:SetWidth(width+60)	
end

---- GUI ----
function MailboxBank_DropDownMenuInitialize()
	local info = UIDropDownMenu_CreateInfo();
	
	for k, v in pairs(MailboxBank_db) do
		if type(k) == 'string' and type(v) == 'table' then
			info = UIDropDownMenu_CreateInfo()
			info.text = k
			info.value = k
			info.func = ChooseChar_OnClick;
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
	f:SetWidth(MailboxBank_db.frameWidth)
	f:SetHeight(MailboxBank_db.frameHeight)
	f:SetPoint("CENTER",0,0)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:RegisterForClicks("AnyUp");
	f:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
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
		MailboxBank_UpdateContainer(playername)
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
	f.scrollBar:SetPoint("BOTTOMRIGHT", -30, 8)
	f.scrollBar:Hide()
	f.scrollBar:SetScript("OnVerticalScroll", function() 
		FauxScrollFrame_OnVerticalScroll(self, offset, 16, MailboxBank_ScrollBarUpdate());
	end)
	f.scrollBar:SetScript("OnShow", function()
		MailboxBank_ScrollBarUpdate()
	end)
	E:GetModule("Skins"):HandleScrollBar(f.scrollBar);
	
	f.Container = {}
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
					if leftday < MailboxBank_db.daysLeftRed then
						rL, gL, bL = 1, 0, 0
					elseif leftday < MailboxBank_db.daysLeftYellow then
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

--[[function MailboxBank_SlotClick(self)
	
end]]

function MailboxBank_UpdateContainer(playername)
	local f = MailboxBankFrame or MailboxBank_CreatFrame("MailboxBankFrame");
	
	local sorted_db = MailboxBank_db
	local buttonSize = sorted_db.buttonSize
	local buttonSpacing = sorted_db.buttonSpacing
	local containerWidth = f:GetWidth()
	local topOffset = sorted_db.topOffset
	local leftOffset = sorted_db.leftOffset
	local numContainerColumns = floor(containerWidth / (buttonSize + buttonSpacing));
	local lastButton;
	local lastRowButton;
	local numContainerRows = 0;
	local stackon
--	local playername = selectValue
	local numItems = sorted_db[playername].itemCount
	local containerID = 1
	f.totalSlots = 0;
	
	--Hide all slot
	for k, v in pairs(f.Container[containerID]) do
		if v then
			v:Hide()
		end
	end
	
	f.mailboxGold:SetText("郵箱金幣: "..(sorted_db[playername].money / 10000).." G")
	--f.mailboxGold:SetText(floor(difftime(time(),sorted_db[playername].checkMailTick)/60).." 分鐘前掃描" or "");
	if numItems > 0 then
		if not f.Container[containerID] then
			f.Container[containerID] = CreateFrame('Frame', f:GetName()..'Container'..containerID, f);
			f.Container[containerID]:SetID(containerID);
			f.Container[containerID]:Show()
			f.Container[containerID].numSlots = 0;
	--	else
	--		for i = 1, f.Container[containerID].numSlots do
	--			if f.Container[containerID][i] then
	--				f.Container[containerID][i]:Hide()
	--			end
	--		end
		end
		
		local usedSlot = 0
		for itemID = 1, numItems do
			local slot
			if isStacked then
				for i = 1, usedSlot do
					if tonumber(match(f.Container[containerID][i].link, "item:(%d+)")) == tonumber(match(sorted_db[playername][itemID].itemLink, "item:(%d+)")) then
						slot = f.Container[containerID][i]
						stackon = i
					end
				end

			end			
			if not slot then
				usedSlot = usedSlot + 1
				slot = f.Container[containerID][usedSlot]
			end
			if not slot then
				f.totalSlots = f.totalSlots + 1;
				f.Container[containerID].numSlots = f.Container[containerID].numSlots + 1
				slot = CreateFrame('Button', f:GetName()..'Bank'..containerID..'Slot'..f.Container[containerID].numSlots, f.Container[containerID]);
				slot:SetTemplate('Default');
				slot:StyleButton();
				slot:Size(buttonSize);
				
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
				--slot:HookScript("OnClick", function(self) MailboxBank_SlotClick(self) end)
				slot:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)
				
				f.Container[containerID][f.Container[containerID].numSlots] = slot
			end
			
			if not stackon then
				slot.link = sorted_db[playername][itemID].itemLink
				slot.checkMailTick = sorted_db[playername].checkMailTick
				slot.sender = {}
				slot.dayleft = {}
				slot.countnum = {}
			end
			tinsert(slot.sender , sorted_db[playername][itemID].sender)
			tinsert(slot.dayleft , sorted_db[playername][itemID].daysLeft)
			tinsert(slot.countnum , sorted_db[playername][itemID].count)
			
			slot:Show()
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
			if not stackon then
				if lastButton then
					if (usedSlot - 1) % numContainerColumns == 0 then
						slot:Point('TOP', lastRowButton, 'BOTTOM', 0, -buttonSpacing);
						lastRowButton = f.Container[containerID][usedSlot];
						numContainerRows = numContainerRows + 1;
					else
						slot:Point('LEFT', lastButton, 'RIGHT', buttonSpacing, 0);
					end
				else
					slot:Point('TOPLEFT', f, 'TOPLEFT', leftOffset, -topOffset);
					lastRowButton = f.Container[containerID][usedSlot];
					numContainerRows = numContainerRows + 1;
				end
				lastButton = f.Container[containerID][usedSlot];
			end
			stackon = nil
		end
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
		MailboxBank_UpdateContainer(playername)
	end
	if event == "MAIL_SHOW" then
		--if MailboxBankFrame == nil then MailboxBankFrame = MailboxBank_CreatFrame("MailboxBankFrame") end
		if not MailboxBankFrame:IsVisible() then MailboxBank_Show(); end
	end
	if event == "MAIL_CLOSED" then
		MailboxBank_Hide()
	end
	if event == "ADDON_LOADED" then
	--	print("MailboxBank loaded")
	end
	if event == "PLAYER_ENTERING_WORLD" then
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
		MailboxBank_UpdateContainer(playername)
		MailboxBank_Show()
	end
end;