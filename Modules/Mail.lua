local ODC = LibStub("AceAddon-3.0"):GetAddon("OfflineDataCenter")
local ODC_SF = ODC:GetModule("SortFilter")
if not ODC_SF then return end
local ODC_Mail = ODC:NewModule("OfflineMail", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("OfflineDataCenter")
ODC_Mail.description = L["Offline MailBox"]
ODC_Mail.type = "tab"

ODC_Mail.TabTextures = {
	["mail"] = "Interface\\MailFrame\\Mail-Icon.blp",
}

ODC_Mail.TabTooltip = {
	["mail"] = L['Offline MailBox'],
}

local playername, selectChar, selectTab = ODC.playername, ODC.selectChar, ODC.selectTab

local Config = {
	daysLeftWarning = 5,
}

local function AddItemMail(itemLink, count, mailIndex, attachIndex, sender, daysLeft, money, CODAmount, wasReturned, recipient, firstItem)
	if recipient and firstItem then
		local t ={}
		tinsert(MB_DB[recipient], 1, t)
	elseif not recipient then
		recipient = playername
	end
	
	if not MB_DB[recipient][mailIndex] or firstItem then
		MB_DB[recipient][mailIndex] = {
			sender = sender,
			daysLeft = daysLeft,
			wasReturned = wasReturned,
			money = (money > 0) and money or nil,
			CODAmount = (CODAmount > 0) and CODAmount or nil,}
		MB_DB[recipient].mailCount = MB_DB[recipient].mailCount + 1
	end
	
	if not itemLink then return end --for money only
	MB_DB[recipient][mailIndex][attachIndex] = {
		count = count,
		itemLink = itemLink,}
	MB_DB[recipient].itemCount = MB_DB[recipient].itemCount + 1
end
--[[
new structure:
				mailIndex	attachIndex
[charName] = {	[1]			[1]			{	.count
				[n]			.sender			.itemLink
				.daysLeft 	.wasReturned
				.mailCount	.CODAmount?
				.itemCount	.money?
enum:
for i = 1, getn(mailIndex) do
	curr.sender, curr.daysLeft, curr.wasReturned, curr.CODAmount
	for j = 1, ATTACHMENTS_MAX_RECEIVE do
		if MB_DB[charName].i.j then
			
		end
	end
end
]]
function ODC_Mail:CheckMail()
	MB_DB[playername] = {mailCount = 0, itemCount = 0, money = 0}
	local numItems, totalItems = GetInboxNumItems()
	if numItems and numItems > 0 then
		for mailIndex = 1, numItems do
			--local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(mailIndex);
			local _, _, sender, _, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, _, _, _ = GetInboxHeaderInfo(mailIndex);
			--if isGM ~= nil then print("GM@"..sender) end
			if money > 0 then
				MB_DB[playername].money = MB_DB[playername].money + money
			end
			AddItemMail(nil, nil, mailIndex, nil, sender, daysLeft, money, CODAmount, wasReturned)
			if hasItem then
				if sender == nil then
					sender = L["UNKNOWN SENDER"]
				end
				for attachIndex = 1, ATTACHMENTS_MAX_RECEIVE do
					local itemLink = GetInboxItemLink(mailIndex, attachIndex)
					if itemLink then
						local _, _, count, _, _ = GetInboxItem(mailIndex, attachIndex)
						AddItemMail(itemLink, count, mailIndex, attachIndex)
					end
				end
			end
		end
	end
	MB_DB[playername].checkMailTick = time()
	
	if ODC.Frame:IsVisible() and selectChar == playername and selectTab == "mail" then
		ODC_SF:Update("sort")
	end
end

function ODC_Mail:HookSendMail(recipient, subject, body)
	if not recipient then recipient = _G["SendMailNameEditBox"]:GetText() end
	if not recipient then return end
	recipient = string.upper(string.sub(recipient, 1, 1))..string.sub(recipient, 2, -1)
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			if recipient..'-'..GetRealmName() == k then
				local Getmoney = GetSendMailMoney()
				local Sendmoney, Codmoney = 0, 0
				if Getmoney then
					if _G["SendMailSendMoneyButton"]:GetChecked() then
						Sendmoney = Getmoney
						MB_DB[k].money = MB_DB[k].money + Sendmoney
					else
						Codmoney = Getmoney
					end
				end
				local firstItem = true
				for i = ATTACHMENTS_MAX_RECEIVE, 1, -1 do
					local Name, _, count, _ = GetSendMailItem(i)
					if Name then
						local _, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(Name or "")
						self:AddItemMail(itemLink, count, 1, i, GetUnitName("player"), 31, Sendmoney, Codmoney, nil, k, firstItem)
						firstItem = nil
					end
				end
				if ODC.Frame:IsVisible() and selectChar == k then
					ODC_SF:Update("sort")
				end
				return
			end
		end
	end
end

local function CalcLeftDay(player, mailIndex)
	return floor(difftime(floor(MB_DB[player][mailIndex].daysLeft * 86400) + MB_DB[player].checkMailTick,time()) / 86400)
end

local function AlertDeadlineMails()
	local DeadlineList = {__count = 0}
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
		--.mailCount .itemCount
			for i = MB_DB[k].mailCount , 1, -1 do
				local dayLeft = CalcLeftDay(k, i)
				if dayLeft < Config.daysLeftWarning then
					if not DeadlineList[k] then 
						DeadlineList[k] = {}
						DeadlineList.__count = DeadlineList.__count +1
					end
					for j, u in pairs(MB_DB[k][i]) do
						if type(u) == "table" then
							tinsert(DeadlineList[k], u.itemLink)
						end
					end
				--else--because of cod items' deadline is 3 days !!
					--break
				end
			end
		end
	end
	if DeadlineList.__count > 0 then
		local alertText = L["Offline Data Center"] .. L[": |cff00aabbYou have mails soon expire: |r"]
		for k, t in pairs(DeadlineList) do
			if k ~= "__count" then
				alertText = alertText.."\r\n\[".. k .. "\]: "
				for i, v in pairs(t) do
					alertText = alertText .. v
				end
			end
		end
		print(alertText)
	end
end

function ODC_Mail:MAIL_INBOX_UPDATE()
	self:CheckMail()
end

function ODC_Mail:OnInitialize()
	if not MB_DB[playername] then MB_DB[playername] = {mailCount = 0, itemCount = 0, money = 0} end
	if MB_Config.toggle.mail then
		AlertDeadlineMails()
	end
end

local SelectTabFunc = function()
	ODC_SF:CreateOrShowSubFrame("mail")
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

function ODC_Mail:OnEnable()
	MB_Config.toggle.mail = true
	ODC:AddModule(self)
	ODC:AddFunc("mail", "selectTab", SelectTabFunc)
	ODC:AddFunc("mail", "selectChar", SelectCharFunc)
	ODC:AddFunc("mail", "selectTabCallback", RefreshSelectedTabFunc)
	ODC:AddFunc("mail", "selectCharCallback", RefreshSelectedCharFunc)
	self:RegisterEvent("MAIL_INBOX_UPDATE")
	self:SecureHook('SendMail', 'HookSendMail');
end

function ODC_Mail:OnDisable()
	MB_Config.toggle.mail = false
	ODC:RemoveModule(self)
	ODC:RemoveFunc("mail", "selectTab")
	ODC:RemoveFunc("mail", "selectTab")
	-- self:UnhookAll()	
	-- self:UnregisterEvent("MAIL_INBOX_UPDATE")
end