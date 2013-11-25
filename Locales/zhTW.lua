local L = LibStub("AceLocale-3.0"):NewLocale("MailboxBank", "zhTW")
if L then
	L["MailboxBank"] = "郵箱銀行"
	L["UNKNOWN SENDER"] = "\[未知發件人\]"
	L["Stack items"] = "堆疊物品"
	L["No sorting"] = "不排序"
	L["AH"] = "拍賣行"
	L["sender"] = "發件人"
	--L["quality"] = "品質"
	L["quality"] = QUALITY
	L["left day"] = "剩餘時間"
	--L["C.O.D."] = "付費取件"
	L["C.O.D."] = COD
	L["money"] = MONEY
	L["has money"] = "擁有錢"
	L["is C.O.D."] = "付費取件"
	L["not C.O.D."] = "非付費取件"
	L["Collect gold"] = "收取金幣"
	L["Sender: "]  = "發件人: "
	L["+ Left time: "] = "+ 剩餘 "
	L["more than "] = "大於"
	--L["C.O.D. item"] = "付費取件物品"
	L["C.O.D. item"] = COD.." "..ITEMS
	L["pay for: "] = "需付費: "
	L[" days"] = "天"
	L[" hours"] = "小時"
	L[" minutes"] = "分鐘"
	L["was returned"] = "已被退回"
	L["Mailbox gold: "] = "郵箱金幣: "
	L["Character gold: "] = "角色金幣: "
	L["Quality summary: "] = "品質統計: "
	L[": |cff00aabbYou have mails soon expire: |r"] = ": |cffaa0000您的郵箱有快到期的附件: |r"
	--L[""] = ""
	
	L['Offline MailBox'] = '離線郵箱';
	L['Offline Bag'] = '離線背包';
	L['Offline Bank'] = '離線銀行';	
	L['Offline Frame'] = '離線窗口';
	
	L['Hold down the ALT key'] = '按住Alt鍵';
	L['Show the number of items for all Character'] = '顯示所有角色的物品數量';
end