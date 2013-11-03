--@@ TODO: solve COD item, maybe displaying COD amount above the slot icon or using tool-tip

--@@ TODO: function SortDB must clear up! collect garbage !!!
	--UC..
--@@ TODO: add searching bar!

--@@ TODO: add AH ordering
	--UC..bad to do
--@@ TODO: should stacked attachments can be collect??

--@@ TODO: collect mailbox gold??
	--DONE!
--@@ TODO: should attachments info be saved to database when sending to known player's other characters?
	--DONE!
--@@ TODO: should attachments be alerted to player to collect when almost in deadline?

--@@ TODO: localization!

local E, L, V, P, G, _ = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
--local MB = E:NewModule("MailboxBank")
local getn, tinsert = table.getn, table.insert
local floor = math.floor
local match, join, format = string.match, string.join, string.format
local playername = E.myname..'-'..E.myrealm
local selectValue = playername
local slotDB, sendItemInfo

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
	isStacked = false,
}	

local itemTypes, itemSubTypes

-- local function BuildSortOrder()
	-- itemTypes = {}
	-- itemSubTypes = {}
	-- for i, iType in ipairs({GetAuctionItemClasses()}) do
		-- itemTypes[iType] = i
		-- itemSubTypes[iType] = {}
		-- for ii, isType in ipairs({GetAuctionItemSubClasses(i)}) do
			-- itemSubTypes[iType][isType] = ii
		-- end
	-- end
-- end

local function MailboxBank_AddItem(sender, itemLink, count, daysLeft, mailIndex, itemIndex, wasReturned, recipient)
	local item = {}
	item["sender"] = sender
	item["count"] = count
	item["itemLink"] = itemLink
	item["daysLeft"] = daysLeft
	item["mailIndex"] = mailIndex
	item["itemIndex"] = itemIndex
	item["wasReturned"] = wasReturned
	if recipient then
		tinsert(MB_DB[recipient], 1, item)
		MB_DB[recipient].itemCount = MB_DB[recipient].itemCount + 1
	else
		tinsert(MB_DB[playername], item)
		MB_DB[playername].itemCount = MB_DB[playername].itemCount + 1
	end
end

local function MailboxBank_CheckMail(isCollectMoney)
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
			if hasItem and CODAmount == 0 then
			--@@ TODO: solve COD item, maybe can display COD amount in the slot icon or tooltip
				if sender == nil then
					--sender = "UNKNOWN SENDER CAUSE OF NETWORK" 
					sender = "----" 
					--return false
				end
				-- if wasRead then hasItem = ATTACHMENTS_MAX_RECEIVE end
				-- for itemIndex = 1, hasItem do
				for itemIndex = 1, ATTACHMENTS_MAX_RECEIVE do
					local name, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, itemIndex)
					local itemLink = GetInboxItemLink(mailIndex, itemIndex)
					if itemLink then
						MailboxBank_AddItem(sender, itemLink, count, daysLeft, mailIndex, itemIndex, wasReturned)
					end
				end
			end
		end
	end
	MB_DB[playername].checkMailTick = time()
	--return true
end

local function FormatMoney(money)
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

local function MailboxBank_CollectMoney()
	MailboxBank_CheckMail(true)
end

function MailboxBank_SortDB()
--@@  TODO: clear up! collect grabage
	local numItems = MB_DB[selectValue].itemCount
	local usedSlot = 0
	slotDB = {}
	for itemIndexCount = 1, numItems do
		local slot
		if MB_config.isStacked then
			for i = 1, usedSlot do
				if tonumber(match(slotDB[i].link, "item:(%d+)")) == tonumber(match(MB_DB[selectValue][itemIndexCount].itemLink, "item:(%d+)")) then
					slot = slotDB[i]
				end
			end
		end	
		if not slot then
		--@@  TODO: add AH ordering
			--[[if isAHOrder then ---- TODO: ordering as AH
				if not itemTypes then BuildSortOrder() end
				-- local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink)
				if not ahOrdering then local ahOrdering = {} end
				local _, _, _, _, _, itemType, itemSubType, _, _, _, _ = GetItemInfo(MB_DB[selectValue][itemIndex].itemLink)
				local itemID = tonumber(match(MB_DB[selectValue][itemIndex].itemLink, "item:(%d+)"))
				local ahIndex = itemTypes[itemType] * 100 + itemSubTypes[itemType][itemSubType]
				local itemAHIndex = ahIndex * 1000000 + itemID
				itemAHIndex = itemAHIndex * 1000 + 999 --  format: AABBIIIIIINN
				
				usedSlot = usedSlot + 1
				for slotID, value in ipairs(ahOrdering) do
					if slotID == getn(ahOrdering) then
						if ((value mod 1000) == (itemAHIndex mod 1000) )then
							ahOrdering[slotID + 1] = value + 1
						else
							ahOrdering[slotID + 1] = itemAHIndex - 999
						end
						
						slotDB[slotID + 1] = {}
						slot = slotDB[slotID + 1]
						break
					elseif slotID == 1 and ahOrdering[slotID] > itemAHIndex then
						for i = getn(ahOrdering), slotID , -1 do -- move forward
							ahOrdering[i + 1] = ahOrdering[i]
						end
						ahOrdering[slotID + 1] = itemAHIndex - 999
						
						slotDB[slotID + 1] = {}
						slot = slotDB[slotID + 1]
						break
					elseif ((value < itemAHIndex) or (slotID == 1)) and ahOrdering[slotID + 1] > itemAHIndex then
						for i = getn(ahOrdering), slotID + 1, -1 do -- move forward
							ahOrdering[i + 1] = ahOrdering[i]
						end
						if (value mod 1000) == (itemAHIndex mod 1000) then
							ahOrdering[slotID + 1] = value + 1
						else
							ahOrdering[slotID + 1] = itemAHIndex - 999
						end
						
						slotDB[slotID + 1] = {}
						slot = slotDB[slotID + 1]
						break
					end
				end
				
			else
				usedSlot = usedSlot + 1
				slotDB[usedSlot] = {}
				slot = slotDB[usedSlot]
			end]]

			
			usedSlot = usedSlot + 1
			--slotDB[usedSlot] = {}
			--slot = slotDB[usedSlot]
			
			
			slotDB[usedSlot] = {}
			slot = slotDB[usedSlot]
			
			slot.link = MB_DB[selectValue][itemIndexCount].itemLink
			slot.checkMailTick = MB_DB[selectValue].checkMailTick
			slot.sender = {}
			slot.dayLeft = {}
			slot.countNum = {}
			slot.wasReturned = {}
			if selectValue == playername and not MB_config.isStacked then
				slot.mailIndex = MB_DB[selectValue][itemIndexCount].mailIndex
				slot.itemIndex = MB_DB[selectValue][itemIndexCount].itemIndex
			end
			if not MB_config.isStacked then
			--@@  TODO: should attachments can be collected when items are stacked??
				slot.wasReturned = MB_DB[selectValue][itemIndexCount].wasReturned
			end
		end
		
		tinsert(slot.sender , MB_DB[selectValue][itemIndexCount].sender)
		tinsert(slot.dayLeft , MB_DB[selectValue][itemIndexCount].daysLeft)
		tinsert(slot.countNum , MB_DB[selectValue][itemIndexCount].count)
	end
	slotDB.usedSlot = usedSlot
	return slotDB
end

---- GUI ----
function MailboxBank_ChooseChar_OnClick(self)
	selectValue = self.value
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameDropDown, self.value);

	MailboxBank_Update(true)
	
	local text = MailboxBankFrameDropDownText;
	local width = text:GetStringWidth();
	MailboxBankFrameDropDown:SetWidth(width+60)	
end

local function MailboxBank_DropDownMenuInitialize()
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

local function MailboxBank_CreatFrame(name)
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
	f.closeButton:HookScript("OnClick", function()
		collectgarbage("collect")
	end)
	E:GetModule("Skins"):HandleCloseButton(f.closeButton);
	
	----Create stack up button
	f.stackUpCheckButton = CreateFrame("CheckButton", name.."StackUpCheckButton", f, "UICheckButtonTemplate");
	f.stackUpCheckButton:Point("TOPLEFT", 2, -2)
	f.stackUpCheckButton.text:SetText("堆疊物品")
	f.stackUpCheckButton:SetScript("OnClick", function(self)
		MB_config.isStacked = self:GetChecked()
		MailboxBank_Update(true)
	end)
	E:GetModule("Skins"):HandleCheckBox(f.stackUpCheckButton);
	
	----Create collect mailbox gold button
	f.CollectGoldButton = CreateFrame("Button", name.."CollectGoldButton", f, "UIPanelButtonTemplate");
	f.CollectGoldButton:SetWidth(100)
	f.CollectGoldButton:SetHeight(30)
	f.CollectGoldButton:Point("BOTTOMLEFT", 10, 5);
	f.CollectGoldButton:SetText("收取金幣")
	f.CollectGoldButton:SetScript("OnClick", MailboxBank_CollectMoney)
	E:GetModule("Skins"):HandleButton(f.CollectGoldButton)
	
	----Create mailbox gold text
	f.mailboxGoldText = f:CreateFontString(nil, 'OVERLAY');
	f.mailboxGoldText:FontTemplate()
	f.mailboxGoldText:Point("LEFT", f.CollectGoldButton, "RIGHT", 20, 0);
	
	----Create check time text
	-- f.checktime = f:CreateFontString(nil, 'OVERLAY');
	-- f.checktime:FontTemplate()
	-- f.checktime:Point("BOTTOMLEFT", 20, 5);
	
	----Create choose char dropdown menu
	tinsert(UISpecialFrames, name)
	local chooseChar = CreateFrame('Frame', name..'DropDown', f, 'UIDropDownMenuTemplate')
	chooseChar:Point("TOPLEFT", 80, -6)
	E.Skins:HandleDropDownBox(chooseChar, 180)
	f.chooseChar = chooseChar
	UIDropDownMenu_Initialize(chooseChar, MailboxBank_DropDownMenuInitialize);

	----Create scroll frame
	f.scrollBar = CreateFrame("ScrollFrame", name.."ScrollBarFrame", f, "FauxScrollFrameTemplate")
	f.scrollBar:SetPoint("TOPLEFT", 0, -40)
	f.scrollBar:SetPoint("BOTTOMRIGHT", -28, 64)
	f.scrollBar:SetHeight( MB_config.numItemsRows * MB_config.buttonSize + (MB_config.numItemsRows - 1) * MB_config.buttonSpacing)
	f.scrollBar:Hide()
	--f.scrollBar:EnableMouseWheel(true)
	f.scrollBar:SetScript("OnVerticalScroll",  function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, MB_config.buttonSize + MB_config.buttonSpacing);
		MailboxBank_Update()
	end)
	f.scrollBar:SetScript("OnShow", function()
		MailboxBank_Update()
		--MailboxBank_Update(true)
	end)
	
	--f.scrollBar:SetScript("OnMouseWheel", function(self, delta)
	--	collectgarbage()
    --  DEFAULT_CHAT_FRAME:AddMessage(delta)
	--end)
	E:GetModule("Skins"):HandleScrollBar(f.scrollBar);
	
	----Create Container
	local containerID = 1
	f.Container = {}
	f.Container[containerID] = CreateFrame('Frame', name..'Container'..containerID, f);
	f.Container[containerID]:SetID(containerID);
	f.Container[containerID]:Show()
	
	--f.scrollBar:SetScrollChild(f.Container[containerID])
	--f.Container[containerID].numSlots = 0;
	
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
	
	-- return f
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
		
		if self.wasReturned == 1 then
			GameTooltip:AddLine("已被退回")
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
			MailboxBank_Update(true)
		end
	end

end

function MailboxBank_UpdateContainer()
	local f = MailboxBankFrame --or MailboxBank_CreatFrame("MailboxBankFrame");
	local containerID = 1
	for i = 1, MB_config.itemsSlotDisplay do
		if f.Container[containerID][i] then
			f.Container[containerID][i]:Hide()
		end
	end
	f.stackUpCheckButton:SetChecked(MB_config.isStacked)
	if not slotDB then return end
	
	f.mailboxGoldText:SetText("郵箱金幣: "..FormatMoney(MB_DB[selectValue].money))
	--f.mailboxTime:SetText(floor(difftime(time(),sorted_db[selectValue].checkMailTick)/60).." 分鐘前掃描" or "");

	local offset = FauxScrollFrame_GetOffset(f.scrollBar)
	
	local iconDisplayCount
	if (slotDB.usedSlot - offset * 8) > MB_config.itemsSlotDisplay then
		iconDisplayCount = MB_config.itemsSlotDisplay
	else
		iconDisplayCount = slotDB.usedSlot - offset * 8
	end
	
	for i = 1, iconDisplayCount do
		local itemID = i + offset * 8
		
		local slot = f.Container[containerID][i]
		slot.link = slotDB[itemID].link
		slot.checkMailTick = slotDB[itemID].checkMailTick
		slot.sender = slotDB[itemID].sender
		slot.dayleft = slotDB[itemID].dayLeft
		slot.countnum = slotDB[itemID].countNum
		
		if slotDB[itemID].mailIndex and slotDB[itemID].itemIndex then
			slot.mailIndex = slotDB[itemID].mailIndex
			slot.itemIndex = slotDB[itemID].itemIndex
		end
		if slotDB[itemID].wasReturned then
			slot.wasReturned = slotDB[itemID].wasReturned
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
	FauxScrollFrame_Update(f.scrollBar, ceil(slotDB.usedSlot / MB_config.numItemsPerRow) , MB_config.numItemsRows, MB_config.buttonSize + MB_config.buttonSpacing );
end

function MailboxBank_Update(isSortDB)
	if isSortDB then MailboxBank_SortDB() end
	MailboxBank_UpdateContainer()
end

---- Event ----
local function MailboxBank_HookSendMail(recipient, subject, body)
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			if recipient..'-'..E.myrealm == k then
				for i = ATTACHMENTS_MAX_RECEIVE, 1, -1 do
					local Name, _, count, _ = GetSendMailItem(i)
					if Name then
						local _, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(Name or "")
						MailboxBank_AddItem(E.myname, itemLink, count, 31, 1, i, nil, k)
					end
				end
				if MailboxBankFrame:IsVisible() and selectValue == k then
					MailboxBank_Update(true)
				end
				break
			end
		end
	end
end

local function MailboxBank_Show()
	--selectValue = playername;
	MailboxBankFrame:Show()
end

local function MailboxBank_Hide()
	MailboxBankFrame:Hide()
	collectgarbage("collect")
end

local function MailboxBank_OnEvent(self, event, args)
	if event == "MAIL_INBOX_UPDATE" then
		MailboxBank_CheckMail()
		if selectValue == playername then
			MailboxBank_Update(true)
		end
	end
	if event == "MAIL_SHOW" then
		if not MailboxBankFrame:IsVisible() then MailboxBank_Show(); end
	end
	if event == "MAIL_CLOSED" then
		MailboxBank_Hide()
	end
	-- if event == "ADDON_LOADED" then
		-- print("MailboxBank loaded")
	-- end
	if event == "PLAYER_ENTERING_WORLD" then
		if MB_config == nil then
			MB_config = {}
			E:CopyTable(MB_config, MailboxBank_config_init)
		end
		if not MB_DB then MB_DB = {} end
		MailboxBank_CreatFrame("MailboxBankFrame")
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
	-- if event == "MAIL_SEND_INFO_UPDATE" then
		-- MailboxBank_MailSendInfoUpdate()
		-- print(event)
	-- end
	-- if event == "MAIL_SEND_SUCCESS" then
		-- print(event)
	-- end
end

local MailboxBank_Event = CreateFrame("Frame")
--MailboxBank_Event:RegisterEvent("ADDON_LOADED")
MailboxBank_Event:RegisterEvent("PLAYER_ENTERING_WORLD")
MailboxBank_Event:RegisterEvent("MAIL_INBOX_UPDATE")
MailboxBank_Event:RegisterEvent("MAIL_SHOW")
MailboxBank_Event:RegisterEvent("MAIL_CLOSED")
--MailboxBank_Event:RegisterEvent("MAIL_SEND_INFO_UPDATE")
--MailboxBank_Event:RegisterEvent("MAIL_SEND_SUCCESS")
MailboxBank_Event:SetScript("OnEvent", MailboxBank_OnEvent)

hooksecurefunc("SendMail", MailboxBank_HookSendMail)

SLASH_MAILBOXBANK1 = "/mb";
SLASH_MAILBOXBANK2 = "/mailbox";
SlashCmdList["MAILBOXBANK"] = function()
	if not MailboxBankFrame then return end
	if MailboxBankFrame:IsVisible() then
		MailboxBank_Hide()
	else
		MailboxBank_Update(true)
		MailboxBank_Show()
	end
end;