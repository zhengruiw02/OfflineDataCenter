SLASH_MAILBOXBANK1 = "/mb";

local E = unpack(ElvUI);
local getn, tinsert = table.getn, table.insert
local floor = math.floor
local match = string.match
local isStacked
local checkMailTick
local daysLeftYellow, daysLeftRed = 5, 3 --daysLeftYellow should greater than daysLeftRed

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
	tinsert(MailboxBank_db, item)
	MailboxBank_db.itemCount = MailboxBank_db.itemCount + 1
end

function MailboxBank_CheckMail()
	MailboxBank_db = {itemCount = 0, money = 0}
	local numItems, totalItems = GetInboxNumItems()
	if numItems and numItems > 0 then
		for mailIndex = 1, numItems do
			local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(mailIndex);
			--if isGM ~= nil then print("GM@"..sender) end
			if money > 0 then MailboxBank_db.money = MailboxBank_db.money + 1 end
			if hasItem and CODAmount == 0 then
				if sender == nil then
					sender = "UNKNOWN SENDER CAUSE OF NETWORK" 
					--return false
				end
				if wasRead then hasItem = ATTACHMENTS_MAX_RECEIVE end
				for itemIndex = 1, hasItem do
					local name, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, itemIndex)
					local itemLink = GetInboxItemLink(mailIndex, itemIndex)
					if name ~= nil then
						MailboxBank_AddItem(sender, name, itemTexture, count, itemLink, daysLeft, mailIndex, itemIndex, wasReturned)
					end
				end
			end
		end
	end
	checkMailTick = time()
	MailboxBank_db.checkMailTick = checkMailTick
	--return true
end


---- GUI ----
function MailboxBank_CreatFrame(name)
	----Create mailbox bank frame
	local f = CreateFrame("Button", name, UIParent)
	f:SetTemplate(E.db.bags.transparent and "notrans" or "Transparent")
	f:SetFrameStrata("DIALOG");
	f:SetWidth(333)
	f:SetHeight(500)
	f:SetPoint("CENTER",0,0)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:RegisterForClicks("AnyUp");
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	f:Hide()
	
	----Create close button
	f.closeButton = CreateFrame("Button", name.."CloseButton", f, "UIPanelCloseButton");
	f.closeButton:Point("TOPRIGHT", -2, -2);
	E:GetModule("Skins"):HandleCloseButton(f.closeButton);
	
	----Creat check button
	f.checkButton = CreateFrame("CheckButton", name.."CheckButton", f, "UICheckButtonTemplate");
	f.checkButton:Point("TOPLEFT", 2, -2)
	f.checkButton.text:SetText("堆疊物品")
	f.checkButton:SetScript("OnClick", function(self) isStacked = self:GetChecked() MailboxBank_UpdateContainer() end)
	E:GetModule("Skins"):HandleCheckBox(f.checkButton);
	
	----Create check time text
	f.checkTime = f:CreateFontString(nil, 'OVERLAY');
	f.checkTime:FontTemplate()
	f.checkTime:Point("TOPLEFT", 120, -10);
	
	----Create sort dropdown menu
	--[[local chooseSortType = CreateFrame("Frame", f:GetName().."DropDown", f, "UIDropDownMenuTemplate")
	chooseSortType:Point("TOPLEFT", 80, -6)
	E.Skins:HandleDropDownBox(chooseSortType, 180)
	f.chooseSortType = chooseSortType
	UIDropDownMenu_Initialize(chooseSortType, ChooseSortType_Initialize);]]
	
	f.Container = {}
	return f
end

local MailboxBank_TooltipShow = function (self)
	if self and self.link then
		local x = self:GetRight();
		if ( x >= ( GetScreenWidth() / 2 ) ) then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		end
		GameTooltip:SetHyperlink(self.link)
		for i = 1 , getn(self.countnum)do
			local lefttext = self.countnum[i].." 個,從"..self.sender[i]
			local righttext = "剩餘 "
			local dayLeftTick = difftime(floor(self.dayleft[i] * 86400) + self.checkMailTick,time())
			local leftday = floor(dayLeftTick / 86400)
			if leftday > 0 then
				righttext = righttext.."大於"..tostring(leftday).."天"
			else
				local lefthour = floor((dayLeftTick-leftday*86400) / 3600) 
				local leftminute = floor((dayLeftTick-leftday*86400-lefthour*3600) / 60)
				righttext = righttext..tostring(lefthour).."小時"..tostring(leftminute).."分鐘"
			end
			local rR, gR, bR
			if leftday < daysLeftRed then
				rR, gR, bR = 1, 0, 0
			elseif leftday < daysLeftYellow then
				rR, gR, bR = 1, 1, 0
			else
				rR, gR, bR = 0, 1, 0
			end
			GameTooltip:AddDoubleLine(lefttext, righttext, 1, 1, 1, rR, gR, bR)
		end

		GameTooltip:Show()
	end
end

--[[local MailboxBank_SlotClick = function (self)
	
end]]


function MailboxBank_UpdateContainer()
	local f = MailboxBankFrame
	local buttonSize = 36
	local buttonSpacing = 4
	local containerWidth = f:GetWidth()
	local topOffset = 40
	local leftOffset = 8
	local numContainerColumns = floor(containerWidth / (buttonSize + buttonSpacing));
	local lastButton;
	local lastRowButton;
	local numContainerRows = 0;
	local stackon = nil
	local sorted_db = MailboxBank_db
	local numItems = sorted_db.itemCount
	local containerID = 1
	f.totalSlots = 0;
	f.checkTime:SetText(floor(difftime(time(),sorted_db.checkMailTick)/60).." 分鐘前掃描" or "");
	if numItems > 0 then
		if not f.Container[containerID] then
			f.Container[containerID] = CreateFrame('Frame', f:GetName()..'Container'..containerID, f);
			f.Container[containerID]:SetID(containerID);
			f.Container[containerID]:Show()
			f.Container[containerID].numSlots = 0;
		else
			for i = 1, f.Container[containerID].numSlots do
				if f.Container[containerID][i] then
					f.Container[containerID][i]:Hide()
				end
			end
			
		end
		
		local usedSlot = 0
		for itemID = 1, numItems do
			local slot
			if isStacked then
				for i = 1, usedSlot do
					if tonumber(match(f.Container[containerID][i].link, "item:(%d+)")) == tonumber(match(sorted_db[itemID].itemLink, "item:(%d+)")) then
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
				
				slot:SetScript("OnEnter", MailboxBank_TooltipShow)
				--slot:HookScript("OnClick", MailboxBank_SlotClick)
				slot:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)
				

				
				f.Container[containerID][f.Container[containerID].numSlots] = slot
			end
			
			if stackon == nil then
				slot.link = sorted_db[itemID].itemLink
				slot.checkMailTick = sorted_db.checkMailTick
				slot.sender = {}
				slot.dayleft = {}
				slot.countnum = {}
			end
			tinsert(slot.sender , sorted_db[itemID].sender)
			tinsert(slot.dayleft , sorted_db[itemID].daysLeft)
			tinsert(slot.countnum , sorted_db[itemID].count)
			
			slot:Show()
			if slot.link then
				slot.name, _, slot.rarity, _, _, _, _, _, _, slot.texture = GetItemInfo(slot.link);
				if slot.rarity and slot.rarity > 1 then
					local r, g, b = GetItemQualityColor(slot.rarity);
					slot:SetBackdropBorderColor(r, g, b);
				else
					slot:SetBackdropBorderColor(unpack(E.media.bordercolor));
				end
			else
				slot:SetBackdropBorderColor(unpack(E.media.bordercolor));
			end
			slot.tex:SetTexture(slot.texture)
			local countnum = 0
			for i = 1 , getn(slot.countnum) do
				countnum = countnum + slot.countnum[i]
			end
			slot.count:SetText(countnum > 1 and countnum or '');
			if stackon == nil then
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
	MailboxBankFrame:Show()
end

function MailboxBank_Hide()
	MailboxBankFrame:Hide()
end

function MailboxBank_OnEvent(self, event, ...)
	if event == "MAIL_INBOX_UPDATE" then
		MailboxBank_CheckMail()
		MailboxBank_UpdateContainer()
	end
	if event == "MAIL_SHOW" then
		--if MailboxBankFrame == nil then MailboxBankFrame = MailboxBank_CreatFrame("MailboxBankFrame") end
		if MailboxBankFrame:IsVisible() then return end
		MailboxBank_Show()
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

SlashCmdList["MAILBOXBANK"] = function(msg)
	if MailboxBankFrame:IsVisible() then
		MailboxBank_Hide()
	else
		MailboxBank_UpdateContainer()
		MailboxBank_Show()
	end
end;