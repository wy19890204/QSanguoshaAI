-- This is the Smart AI, and it should be loaded and run at the server side

-- "middleclass" is the Lua OOP library written by kikito
-- more information see: https://github.com/kikito/middleclass
require "middleclass"

-- initialize the random seed for later use
math.randomseed(os.time())

-- SmartAI is the base class for all other specialized AI classes
SmartAI = class "SmartAI"

version = "QSanguosha AI 20130222 (V1.05 Alpha)"

-- checkout https://github.com/haveatry823/QSanguoshaAI for details

--- this function is only function that exposed to the host program
--- and it clones an AI instance by general name
-- @param player The ServerPlayer object that want to create the AI object
-- @return The AI object
function CloneAI(player)
	return SmartAI(player).lua_ai
end

sgs.ais = {}
sgs.ai_card_intention = 	{}
sgs.ai_playerchosen_intention = {}
sgs.ai_skillInvoke_intention = {}
sgs.ai_skillChoice_intention = {}
sgs.ai_cardChosen_intention = {}
sgs.role_evaluation = 		{}
sgs.ai_role = 				{}
sgs.ai_keep_value = 		{}
sgs.ai_use_value = 			{}
sgs.ai_use_priority = 		{}
sgs.ai_suit_priority = 		{}
sgs.ai_chaofeng = 			{}
sgs.ai_global_flags = 		{}
sgs.ai_skill_invoke = 		{}
sgs.ai_skill_suit = 		{}
sgs.ai_skill_cardask = 		{}
sgs.ai_skill_choice = 		{}
sgs.ai_skill_askforag = 	{}
sgs.ai_skill_askforyiji = 	{}
sgs.ai_skill_pindian = 		{}
sgs.ai_filterskill_filter = {}
sgs.ai_skill_playerchosen = {}
sgs.ai_skill_discard = 		{}
sgs.ai_cardshow = 			{}
sgs.ai_skill_cardchosen = 	{}
sgs.ai_skill_use = 			{}
sgs.ai_cardneed = 			{}
sgs.ai_skill_use_func = 	{}
sgs.ai_skills = 			{}
sgs.ai_slash_weaponfilter = {}
sgs.ai_slash_prohibit = 	{}
sgs.ai_trick_prohibit =		{} -- obsolete
sgs.ai_view_as = {}
sgs.ai_cardsview = {}
sgs.dynamic_value = 		{
	damage_card = 			{},
	control_usecard = 		{},
	control_card = 			{},
	lucky_chance = 			{},
	benefit = 				{}
}
sgs.ai_choicemade_filter = 	{
	cardUsed = 				{},
	cardResponded = 		{},
	skillInvoke = 			{},
	skillChoice = 			{},
	Nullification =			{},
	playerChosen =			{},
	cardChosen =			{}
}

sgs.card_lack =				{}
sgs.ai_need_damaged =		{}
sgs.ai_debug_func =			{}
sgs.ai_chat_func =			{}
sgs.ai_event_callback =		{}
sgs.explicit_renegade =     false 


for i=sgs.NonTrigger, sgs.NumOfEvents, 1 do
	sgs.ai_debug_func[i]	={}
	sgs.ai_chat_func[i]		={}
	sgs.ai_event_callback[i]={}
end

function setInitialTables()
	sgs.current_mode_players = { lord = 0, loyalist = 0, rebel = 0, renegade = 0 }
	sgs.ai_type_name = 			{"Skill", "Basic", "Trick", "Equip"}
	sgs.target = 				{loyalist = nil, rebel = nil, renegade = nil } -- obsolete
	sgs.discard_pile =			global_room:getDiscardPile()
	sgs.draw_pile = 			global_room:getDrawPile()
	sgs.lose_equip_skill = 		"xiaoji|xuanfeng|nosxuanfeng"
	sgs.need_kongcheng = 		"lianying|kongcheng"
	sgs.masochism_skill = 		"guixin|yiji|fankui|jieming|fenyong|neoganglie|ganglie|enyuan|fangzhu|nosenyuan|jianxiong|langgu|quanji|zhiyu|tanlan|tongxin|huashen"
	sgs.wizard_skill = 		"guicai|guidao|jilve|tiandu|luoying|noszhenlie|huanshi"
	sgs.wizard_harm_skill = 	"guicai|guidao|jilve"
	sgs.priority_skill = 		"dimeng|haoshi|qingnang|jizhi|guzheng|qixi|jieyin|guose|duanliang|jujian|fanjian|neofanjian|lijian|" ..
						"manjuan|tuxi|qiaobian|yongsi|zhiheng|luoshen|rende|mingce|wansha|gongxin|jilve|anxu|" ..
						"qice|yinling|qingcheng|houyuan|zhaoxin"
	sgs.save_skill = 		"jijiu|buyi|nosjiefan|chunlao|longhun"
	sgs.exclusive_skill = 		"huilei|duanchang|wuhun|buqu|zhuiyi|dushi|jincui"
	sgs.cardneed_skill =		"paoxiao|tianyi|xianzhen|shuangxiong|jizhi|guose|duanliang|qixi|qingnang|yinling|luoyi|guhuo|kanpo|" ..
						"jieyin|renjie|zhiheng|rende|nosjujian|guicai|guidao|longhun|luanji|qiaobian|beige|jieyuan|" ..
						"mingce|nosfuhun|lirang|longluo|xuanfeng|xinzhan|dangxian|xiaoguo|neoluoyi|fuhun"
	sgs.drawpeach_skill =		"tuxi|qiaobian"
	sgs.recover_skill =		"rende|kuanggu|zaiqi|jieyin|qingnang|yinghun|hunzi|shenzhi|longhun|nosmiji|zishou|ganlu|xueji|shangshi|" ..
						"nosshangshi|chengxiang|buqu|miji"
	sgs.use_lion_skill =		 "longhun|duanliang|qixi|guidao|lijian|jujian|nosjujian|zhiheng|mingce|yongsi|fenxun|gongqi|" ..
						"yinling|jilve|qingcheng|neoluoyi|diyyicong"								  
	
	for _, aplayer in sgs.qlist(global_room:getAllPlayers()) do
		table.insert(sgs.role_evaluation, aplayer:objectName())
		table.insert(sgs.ai_role, aplayer:objectName())
		if aplayer:isLord() then
			sgs.role_evaluation[aplayer:objectName()] = {lord = 99999, rebel = 0, loyalist = 99999, renegade = 0}
			sgs.ai_role[aplayer:objectName()] = "loyalist"
		else
			sgs.role_evaluation[aplayer:objectName()] = {rebel = 0, loyalist = 0, renegade = 0}
			sgs.ai_role[aplayer:objectName()] = "neutral"
		end
	end
	
end

function SmartAI:initialize(player)
	self.player = player
	self.room = player:getRoom()
	self.role  = player:getRole()
	self.lua_ai = sgs.LuaAI(player)
	self.lua_ai.callback = function(full_method_name, ...)
		--The __FUNCTION__ macro is defined as CLASS_NAME::SUBCLASS_NAME::FUNCTION_NAME 
		--in MSVC, while in gcc only FUNCTION_NAME is in place.
		local method_name_start = 1
		while true do			
			local found = string.find(full_method_name, "::", method_name_start)
			if found ~= nil then				
				method_name_start = found + 2
			else				
				break
			end				 
		end
		local method_name = string.sub(full_method_name, method_name_start)
		local method = self[method_name]
		if method then
			local success, result1, result2
			success, result1, result2 = pcall(method, self, ...)
			if not success then
				self.room:writeToConsole(result1)
				self.room:writeToConsole(method_name)
				self.room:writeToConsole(debug.traceback())
				self.room:writeToConsole("Event stack:")
				self.room:outputEventStack()
				self.room:writeToConsole("End of Event Stack")
			else
				return result1, result2
			end
		end
	end

	self.retain = 2
	self.keepValue = {}
	self.kept = {}
	if not sgs.initialized then
		sgs.initialized = true
		sgs.ais = {}
		sgs.turncount = 0
		sgs.debugmode = false
		global_room = self.room
		global_room:writeToConsole(version .. ", Powered by " .. _VERSION)
				
		setInitialTables()
		if sgs.isRolePredictable() then
			for _, aplayer in sgs.qlist(global_room:getAllPlayers()) do
				if aplayer:getRole() ~= "lord" then sgs.role_evaluation[aplayer:objectName()][aplayer:getRole()] = 65535 end
			end
		end
	end

	sgs.ais[player:objectName()] = self

	sgs.card_lack[player:objectName()] = {}
	sgs.card_lack[player:objectName()]["Slash"] = 0
	sgs.card_lack[player:objectName()]["Jink"] = 0
	sgs.card_lack[player:objectName()]["Peach"] = 0

	if self.player:isLord() and not sgs.GetConfig("EnableHegemony", false) then
		if (sgs.ai_chaofeng[self.player:getGeneralName()] or 0) < 3 then
			sgs.ai_chaofeng[self.player:getGeneralName()] = 3
		end
	end
	
	self:updateAlivePlayerRoles()
	self:updatePlayers()
end

function sgs.getValue(player)
	if not player then global_room:writeToConsole(debug.traceback()) end
	return player:getHp() * 2 + player:getHandcardNum()
end

function sgs.getDefense(player)
	local defense = math.min(sgs.getValue(player), player:getHp() * 3)
	if player:getArmor() and not player:getArmor():isKindOf("GaleShell") then
		defense = defense + 2
	end
	if not player:getArmor() and player:hasSkill("bazhen") then
		defense = defense + 2
	end
	if not player:getArmor() and player:hasSkill("yizhong") then
		defense = defense + 2
	end
	local m = sgs.masochism_skill:split("|")
	for _, masochism in ipairs(m) do
		if player:hasSkill(masochism) then
			defense = defense + 1
		end
	end
	if player:getArmor() and player:getArmor():isKindOf("EightDiagram") 
	  and (player:hasSkill("yiji") or player:hasSkill("leiji") or player:hasSkill("noszhenlie") or player:hasSkill("gushou")) then
		defense = defense + 0.5
	end
	if player:hasSkill("jieming") or player:hasSkill("yiji") or player:hasSkill("guixin") then
		defense = defense + 4
	end
	if player:getMark("@tied") > 0 then
		defense = defense + 1
	end
	if player:hasSkill("qingguo") and player:getHandcardNum() > 1 then
		defense = defense + 0.5
	end
	if player:hasSkill("longhun") and player:getHp() == 1 and player:getHandcardNum() > 1 then
		defense = defense + 0.4
	end
	if player:hasSkill("longdan") and player:getHandcardNum()>2 then
		defense = defense + 0.3
	end
	return defense
end

function SmartAI:assignKeep(num,start)
	if num<=0 then return end
	if start then 
		self.keepValue={}
		self.kept={}
	end
	local cards=self.player:getHandcards()
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards,true,self.kept)
	for _,card in ipairs(cards) do
		if not self.keepValue[card:getId()] then
			self.keepValue[card:getId()]=self:getKeepValue(card,self.kept)
			table.insert(self.kept,card)
			--self:log(card:getClassName())
			self:assignKeep(num-1)
			break
		end
	end
end

function SmartAI:getKeepValue(card,kept)
	if not kept then return self.keepValue[card:getId()] or 0 end

	local class_name = card:getClassName()
	local suit_string = card:getSuitString()
	local value, newvalue
	
	local i = 0
	for _, askill in sgs.qlist(self.player:getVisibleSkillList()) do
		if sgs[askill:objectName() .. "_keep_value"] then
			local v = sgs[askill:objectName() .. "_keep_value"][class_name]
			if v then
				i = i + 1
				if value then value = value + v else value = v end
			end
		end
	end
	if value then return value / i end
	i = 0
	for _, askill in sgs.qlist(self.player:getVisibleSkillList()) do
		if sgs[askill:objectName() .. "_suit_value"] then
			local v = sgs[askill:objectName() .. "_suit_value"][suit_string]
			if v then
				i = i + 1
				if value then value = value + v else value = v end
			end
		end
	end
	if value then value = value / i end
	
	newvalue = sgs.ai_keep_value[class_name] or 0
	for _, acard in ipairs(kept) do
		if acard:getClassName() == card:getClassName() then newvalue = newvalue - 1.2
		elseif acard:isKindOf("Slash") and card:isKindOf("Slash") then newvalue = newvalue - 1
		end
		local madai = self.room:findPlayerBySkillName("nosqianxi")
		if madai and madai:distanceTo(self.player) == 1 and not self:isFriend(madai) then
			if acard:isKindOf("Jink") and card:isKindOf("Jink") then newvalue = newvalue + 2 end
		end
	end
	if not value or newvalue > value then value = newvalue end
	return value
end

function SmartAI:getUseValue(card)
	local class_name = card:getClassName()
	local v = sgs.ai_use_value[class_name] or 0
	if class_name == "LuaSkillCard" then
		v = sgs.ai_use_value[card:objectName()] or 0
	end

	if card:isKindOf("GuhuoCard") then
		local userstring = card:toString()
		userstring = (userstring:split(":"))[3]
		local guhuocard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
		local usevalue = self:getUseValue(guhuocard) + #self.enemies*0.3
		local subcards = card:getSubcards()
		if subcards and not subcards:isEmpty() then
			local sub_id = subcards:first()
			if sgs.Sanguosha:getCard(sub_id):objectName() == userstring and card:getSuit() == sgs.Card_Heart then 
				usevalue = usevalue + 3 
			end
		end
		return usevalue
	end

	if card:getTypeId() == sgs.Card_Equip then
		if self:hasEquip(card) then
			if card:isKindOf("OffensiveHorse") and self.player:getAttackRange()>2 then return 5.5 end
			if card:isKindOf("DefensiveHorse") and self:isEquip("EightDiagram") then return 5.5 end
			return 9
		end
		if not self:getSameEquip(card) then v = 6.7 end
		if self.weaponUsed and card:isKindOf("Weapon") then v = 2 end
		if self:hasSkills("qiangxi|taichen|zhulou") and card:isKindOf("Weapon") then v = 2 end
		if self.player:hasSkill("kurou") and card:isKindOf("Crossbow") then return 9 end
		if (self:hasSkill("bazhen") or self:hasSkill("yizhong")) and card:isKindOf("Armor") then v = 2 end
		if self.role == "loyalist" and self.player:getKingdom()=="wei" and not self.player:hasSkill("bazhen") and getLord(self.player) and getLord(self.player):hasLordSkill("hujia") and card:isKindOf("EightDiagram") then
			v = 9
		end
		if self:hasSkills(sgs.lose_equip_skill) then return 10 end
	elseif card:getTypeId() == sgs.Card_Basic then
		if card:isKindOf("Slash") then
			
			v = sgs.ai_use_value[class_name] or 0

			if self.player:hasFlag("tianyi_success") or self.player:hasFlag("jiangchi_invoke")
				or self:hasHeavySlashDamage(self.player, card) then v = 8.7 end
			if self:isEquip("Crossbow") then v = v + 4 end

			if card:getSkillName() == "Spear"   then v = v - 1 end
			if card:getSkillName() == "longdan" and self:hasSkills("chongzhen") then v = v + 1 end

		elseif card:isKindOf("Jink") then
			if self:getCardsNum("Jink") > 1 then v = v-6 end
			if self.player:hasSkill("longdan") and self:hasSkills("chongzhen") then v = 8.7 end
		elseif card:isKindOf("Peach") then
			if self.player:isWounded() then v = v + 6 end
		end
	elseif card:getTypeId() == sgs.Card_Trick then
		if self.player:getWeapon() and not self:hasSkills(sgs.lose_equip_skill) and card:isKindOf("Collateral") then v = 2 end
		if self.player:getMark("shuangxiong") > 0 and card:isKindOf("Duel") then v = 8 end
		if self.player:hasSkill("jizhi") then v = 8.7 end
		if self.player:hasSkill("wumou") and card:isNDTrick() and not card:isKindOf("AOE") then
			if not (card:isKindOf("Duel") and self.player:hasUsed("WuqianCard")) then v = 1 end
		end
		local to = card:targetFixed() and self.player or self.player:getNextAlive()
		if not self:hasTrickEffective(card, to, self.player) then v = 0 end
	end

	if self:hasSkills(sgs.need_kongcheng) then
		if self.player:getHandcardNum() == 1 then v = 10 end
	end
	if self.player:hasWeapon("Halberd") and card:isKindOf("Slash") and self.player:isLastHandCard(card) then v = 10 end
	if self.player:getPhase()==sgs.Player_Play then v = self:adjustUsePriority(card, v) end
	return v
end

function SmartAI:getUsePriority(card)
	local class_name = card:getClassName()
	local v = 0
	if card:isKindOf("EquipCard") then
		if self:hasSkills(sgs.lose_equip_skill) then return 15 end
		if card:isKindOf("Armor") and not self.player:getArmor() then v = 6
		elseif card:isKindOf("Weapon") and not self.player:getWeapon() then v = 5.7
		elseif card:isKindOf("DefensiveHorse") and not self.player:getDefensiveHorse() then v = 5.8
		elseif card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then v = 5.5
		end
		return v
	end

	v = sgs.ai_use_priority[class_name] or 0
	if class_name == "LuaSkillCard" then
		v = sgs.ai_use_priority[card:objectName()] or 0
	end
	local to = card:targetFixed() and self.player or self.player:getNextAlive()
	if not self:hasTrickEffective(card, to, self.player) then v = 0 end
	return self:adjustUsePriority(card, v)	
end

function SmartAI:adjustUsePriority(card,v)
	local suits={"club","spade","diamond","heart"}

	if card:getTypeId() == sgs.Card_Skill then return v end

	for _, askill in sgs.qlist(self.player:getVisibleSkillList()) do
		local callback = sgs.ai_suit_priority[askill:objectName()]
		if type(callback) == "function" then
			suits =callback(self,card):split("|")
			break
		elseif type(callback) == "string" then
			suits = callback:split("|")
			break
		end
	end
	
	table.insert(suits,"no_suit")
	if card:isKindOf("Slash") then 
		if card:getSkillName() == "Spear" then v = v - 0.01 end
		if card:getSkillName() == "longdan" and self:hasSkills("chongzhen") then v = v + 0.01 end
		if card:getSkillName() == "fuhun" then v = v + 0.1 end
	end

	local suits_value={}
	for index,suit in ipairs(suits) do
		suits_value[suit] = 10 - index*2 
	end
	v = v + (suits_value[card:getSuitString()] or 0) / 100
	v = v + (13 - card:getNumber()) / 1000
	return v
end

function SmartAI:getDynamicUsePriority(card)
	if not card then return 0 end

	local type = card:getTypeId()
	local dummy_use = {}
	dummy_use.isDummy = true
	if type == sgs.Card_Trick then
		self:useTrickCard(card, dummy_use)
	elseif type == sgs.Card_Basic then
		self:useBasicCard(card, dummy_use)
	elseif type == sgs.Card_Equip then
		self:useEquipCard(card, dummy_use)
	else
		self:useSkillCard(card, dummy_use)
	end

	local value = self:getUsePriority(card)
	if dummy_use.card then
		local use_card = dummy_use.card
		local card_name = use_card:getClassName()

		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)

		if use_card:isKindOf("AmazingGrace") then
			local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
			if zhugeliang and self:isEnemy(zhugeliang) and zhugeliang:isKongcheng() then
				value = math.max(sgs.ai_use_priority.Slash, sgs.ai_use_priority.Duel) + 0.1
			end
		end

		if use_card:isKindOf("YanxiaoCard") and self.player:containsTrick("YanxiaoCard") then
			value = 0.1
		end

		if self.player:getMark("shuangxiong") > 0 and use_card:isKindOf("Duel") then 
			value = sgs.ai_use_priority.ExNihilo - 0.1
		end
		
		if use_card:isKindOf("Indulgence") and use_card:isVirtualCard() and use_card:subcardsLength() > 0 then 
			value = sgs.ai_use_priority.Indulgence - 0.01
		end

		if use_card:isKindOf("SupplyShortage") and use_card:isVirtualCard() and use_card:subcardsLength() > 0 then 
			value = sgs.ai_use_priority.SupplyShortage - 0.01
		end

		if use_card:isKindOf("IronChain") and self:hasSkills("yeyan") then 
			value = sgs.ai_use_priority.GreatYeyanCard + 0.1
		end

		if use_card:isKindOf("Analeptic") and use_card:isVirtualCard() then 
			value = sgs.ai_use_priority.Analeptic - 0.01
		end

		if sgs.evaluateRoleTrends(self.player) == "neutral" and use_card:isKindOf("YisheAskCard") then 
			value = sgs.ai_use_priority.Slash - 0.5
		end

		if (self:hasHeavySlashDamage(self.player) or self:getOverflow() > 0) and use_card:isKindOf("QingnangCard") then 
			value = math.min(sgs.ai_use_priority.Slash, sgs.ai_use_priority.Duel) - 0.1
		end
		
		if use_card:isKindOf("Duel") and (self:hasCrossbowEffect(self.player) or self.player:hasFlag("xianzhen_success")
				or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, slash) > 0
				or self.player:hasSkill("duanbing")) then 
			value = sgs.ai_use_priority.Slash - 0.1
		end
		
		if use_card:isKindOf("KurouCard") and self.player:getHp()==1 and self.player:getRole()~="lord" 
			and self.player:getRole()~="renegade" and self:getCardsNum("Analeptic")==0 then
			value = 0.1
		end

	end
	return value
end

function SmartAI:cardNeed(card)
	if not self.friends then self.room:writeToConsole(debug.traceback()) self.room:writeToConsole(sgs.turncount) return end
	local class_name = card:getClassName()
	local suit_string = card:getSuitString()
	local value
	if card:isKindOf("Peach") then
		self:sort(self.friends,"hp")
		if self.friends[1]:getHp() < 2 then return 10 end
		if (self.player:getHp() < 3 or self.player:getLostHp() > 1 and not self:hasSkills("longhun|buqu")) or self:hasSkills("kurou|benghuai") then return 14 end
		return self:getUseValue(card)
	end
	local wuguotai = self.room:findPlayerBySkillName("buyi")
	if wuguotai and self:isFriend(wuguotai) and not card:isKindOf("BasicCard") then
		if (self.player:getHp() < 3 or self.player:getLostHp() > 1 and not self:hasSkills("longhun|buqu")) or self:hasSkills("kurou|benghuai") then return 13 end
	end
	if self:isWeak() and card:isKindOf("Jink") and self:getCardsNum("Jink") < 1 then return 12 end
	
	local i = 0
	for _, askill in sgs.qlist(self.player:getVisibleSkillList()) do
		if sgs[askill:objectName() .. "_keep_value"] then
			local v = sgs[askill:objectName() .. "_keep_value"][class_name]
			if v then
				i = i + 1
				if value then value = value + v else value = v end
			end
		end
	end
	if value then return value / i + 4 end
	i = 0
	for _, askill in sgs.qlist(self.player:getVisibleSkillList()) do
		if sgs[askill:objectName() .. "_suit_value"] then
			local v = sgs[askill:objectName() .. "_suit_value"][suit_string]
			if v then
				i = i + 1
				if value then value = value + v else value = v end
			end
		end
	end
	if value then return value / i + 4 end

	if card:isKindOf("Slash") and self:getCardsNum("Slash") == 0 then return 5.9 end
	if card:isKindOf("Analeptic") then
		if self.player:getHp() < 2 then return 10 end
	end
	if card:isKindOf("Slash") and (self:getCardsNum("Slash") > 0) then return 4 end
	if card:isKindOf("Crossbow") and  self:hasSkills("luoshen|yongsi|kurou|keji|wusheng|wushen",self.player) then return 20 end
	if card:isKindOf("Axe") and  self:hasSkills("luoyi|jiushi|jiuchi|pojun",self.player) then return 15 end
	if card:isKindOf("Weapon") and (not self.player:getWeapon()) and (self:getCardsNum("Slash") > 1) then return 6 end
	if card:isKindOf("Nullification") and self:getCardsNum("Nullification") == 0 then
		if self:willSkipPlayPhase() or self:willSkipDrawPhase() then return 10 end
		for _,friend in ipairs(self.friends) do
			if self:willSkipPlayPhase(friend) or self:willSkipDrawPhase(friend) then return 9 end
		end
		return 6
	end
	return self:getUseValue(card)
end

-- compare functions
sgs.ai_compare_funcs = {
	hp = function(a, b)
		local c1 = a:getHp()
		local c2 = b:getHp()
		if c1 == c2 then
			return sgs.ai_compare_funcs.defense(a, b)
		else
			return c1 < c2
		end
	end,

	handcard = function(a, b)
		local c1 = a:getHandcardNum()
		local c2 = b:getHandcardNum()
		if c1 == c2 then
			return sgs.ai_compare_funcs.defense(a, b)
		else
			return c1 < c2
		end
	end,

	handcard_defense = function(a, b)
		local c1 = a:getHandcardNum()
		local c2 = b:getHandcardNum()
		if c1 == c2 then
			return  sgs.ai_compare_funcs.defense(a, b) 
		else
			return c1 < c2
		end
	end,

	value = function(a, b)
		return sgs.getValue(a) < sgs.getValue(b)
	end,

	chaofeng = function(a, b)
		local c1 = sgs.ai_chaofeng[a:getGeneralName()]	or 0
		local c2 = sgs.ai_chaofeng[b:getGeneralName()] or 0

		if c1 == c2 then
			return sgs.ai_compare_funcs.value(a, b)
		else
			return c1 > c2
		end
	end,

	defense = function(a,b)
		return sgs.getDefenseSlash(a) < sgs.getDefenseSlash(b)
	end,

	threat = function (a, b)
		local players = sgs.QList2Table(a:getRoom():getOtherPlayers(a))
		local d1 = a:getHandcardNum()
		for _, player in ipairs(players) do
			if a:canSlash(player) then
				d1 = d1+10/(sgs.getDefense(player))
			end
		end
		players = sgs.QList2Table(b:getRoom():getOtherPlayers(b))
		local d2 = b:getHandcardNum()
		for _, player in ipairs(players) do
			if b:canSlash(player) then
				d2 = d2+10/(sgs.getDefense(player))
			end
		end

		local c1 = sgs.ai_chaofeng[a:getGeneralName()]	or 0
		local c2 = sgs.ai_chaofeng[b:getGeneralName()] or 0

		return d1+c1/2 > d2+c2/2
	end,
}

function SmartAI:sort(players, key)
	if not players then self.room:writeToConsole(debug.traceback()) end
	local func = sgs.ai_compare_funcs[key or "defense"]
	if #players > 0 then table.sort(players, func) end	
end

function SmartAI:sortByKeepValue(cards,inverse,kept)
	local compare_func = function(a,b)
		local value1 = self:getKeepValue(a, kept)
		local value2 = self:getKeepValue(b, kept)

		local v1 = self:adjustUsePriority(a, value1)
		local v2 = self:adjustUsePriority(b, value2)
		if a:isKindOf("NatureSlash") then v1 = v1 - 0.1 end
		if b:isKindOf("NatureSlash") then v2 = v2 - 0.1 end

		if v1 ~= v2 then
			if inverse then return v1 > v2 end
			return v1 < v2
		end
	end

	table.sort(cards, compare_func)
end



function SmartAI:sortByUseValue(cards,inverse)
	local compare_func = function(a,b)
		local value1 = self:getUseValue(a)
		local value2 = self:getUseValue(b)

		if value1 ~= value2 then
			if not inverse then return value1 > value2 end
			return value1 < value2
		else
			if not inverse then return a:getNumber() > b:getNumber() end
			return a:getNumber() < b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByUsePriority(cards, player)
	local compare_func = function(a,b)
		local value1 = self:getUsePriority(a)
		local value2 = self:getUsePriority(b)

		if value1 ~= value2 then
			return value1 > value2
		else
			return a:getNumber() > b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByDynamicUsePriority(cards)
	local compare_func = function(a,b)
		local value1 = self:getDynamicUsePriority(a)
		local value2 = self:getDynamicUsePriority(b)

		if value1 ~= value2 then
			return value1 > value2
		else
			return a and a:getTypeId() ~= sgs.Card_Skill and not (b and b:getTypeId() ~= sgs.Card_Skill)
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByCardNeed(cards, inverse)
	local compare_func = function(a,b)
		local value1 = self:cardNeed(a)
		local value2 = self:cardNeed(b)
		
		if not inverse then
			if value1 ~= value2 then
				return value1 < value2
			else
				return a:getNumber() < b:getNumber()
			end
		else
			if value1 ~= value2 then
				return value1 > value2
			else
				return a:getNumber() > b:getNumber()
			end
		end
	end

	table.sort(cards, compare_func)
end


function SmartAI:getPriorTarget()
	if #self.enemies == 0 then return end 
	self:sort(self.enemies, "defense")
	return self.enemies[1]
end

function sgs.evaluatePlayerRole(player)
	if not player then global_room:writeToConsole("Player is empty in role's evaluation!") return end
	if player:isLord() then return "loyalist" end
	return sgs.ai_role[player:objectName()]
end

function sgs.backwardEvaluation(player)
	return sgs.evaluatePlayerRole(player)
end

function sgs.modifiedRoleEvaluation()	
end

function sgs.modifiedRoleTrends(role)	
end

function sgs.evaluateRoleTrends(player)
	return sgs.evaluatePlayerRole(player)
end

function sgs.compareRoleEvaluation(player, first, second)
	if player:isLord() then return "loyalist" end
	if sgs.isRolePredictable() then return player:getRole() end
	if (first == "renegade" or second == "renegade") and sgs.ai_role[player:objectName()] == "renegade" then return "renegade" end	
	if sgs.ai_role[player:objectName()] == first then return first end
	if sgs.ai_role[player:objectName()] == second then return second end	
	return "neutral"	
end

function sgs.isRolePredictable()
	if sgs.GetConfig("RolePredictable", true) then return true end
	local mode = string.lower(global_room:getMode())
	if not mode:find("0") or mode:find("02p") or mode:find("03p") or mode:find("02_1v1") or mode:find("04_1v3") or mode == "06_3v3" or mode:find("mini") then return true end
	return false
end

function sgs.findIntersectionSkills(first, second)
	if type(first) == "string" then first = first:split("|") end
	if type(second) == "string" then second = second:split("|") end

	local findings = {}
	for _, skill in ipairs(first) do
		for _, compare_skill in ipairs(second) do
			if skill == compare_skill and not table.contains(findings, skill) then table.insert(findings, skill) end
		end
	end
	return findings
end

function sgs.findUnionSkills(first, second)
	if type(first) == "string" then first = first:split("|") end
	if type(second) == "string" then second = second:split("|") end
	
	local findings = table.copyFrom(first)
	for _, skill in ipairs(second) do
		if not table.contains(findings, skill) then table.insert(findings, skill) end
	end
	
	return findings
end
	
sgs.ai_card_intention.general = function(from, to, level)
	if sgs.isRolePredictable() then return end
	if not to then global_room:writeToConsole(debug.traceback()) return end
	if from:isLord() or level == 0 then return end

	-- 将level固定为 10或者-10，目的是由原来的忠反值的变化 更改为 统计AI跳身份的行为次数，因为感觉具体的level值不太好把握，容易出现忠反值不合理飙涨的情况
	level = level > 0 and 10 or -10

	sgs.outputRoleValues(from, level)
	
	local loyalist_value = sgs.role_evaluation[from:objectName()]["loyalist"]
	local renegade_value = sgs.role_evaluation[from:objectName()]["renegade"]
	
	
	if sgs.evaluatePlayerRole(to) == "loyalist" then
		sgs.role_evaluation[from:objectName()]["loyalist"] = sgs.role_evaluation[from:objectName()]["loyalist"] - level

		if sgs.current_mode_players["rebel"] == 0 and sgs.current_mode_players["renegade"] > 0 
				and sgs.current_mode_players["loyalist"] > 0 and level > 0 and sgs.explicit_renegade == false then
			-- 进入主忠内, 但是没人跳过内，这个时候忠臣之间的相互攻击，不更新内奸值				
		elseif (sgs.ai_role[from:objectName()] == "loyalist" and level > 0) or (sgs.ai_role[from:objectName()] == "rebel" and level < 0) then 
			sgs.role_evaluation[from:objectName()]["renegade"] = sgs.role_evaluation[from:objectName()]["renegade"] + math.abs(level) 
		elseif sgs.ai_role[from:objectName()] ~= "rebel" and sgs.ai_role[from:objectName()] ~= "neutral" and level > 0 and to:isLord() then
			sgs.role_evaluation[from:objectName()]["renegade"] = sgs.role_evaluation[from:objectName()]["renegade"] + math.abs(level)
		end
	end

	if sgs.evaluatePlayerRole(to) == "rebel" then
		sgs.role_evaluation[from:objectName()]["loyalist"] = sgs.role_evaluation[from:objectName()]["loyalist"] + level
		if (sgs.ai_role[from:objectName()] == "rebel" and level > 0) or (sgs.ai_role[from:objectName()] == "loyalist" and level < 0) then 
			sgs.role_evaluation[from:objectName()]["renegade"] = sgs.role_evaluation[from:objectName()]["renegade"] + math.abs(level) 
		end
	end
			
	if global_room:getTag("humanCount") and global_room:getTag("humanCount"):toInt() ==1 then
		local diffarr = {
			loyalist_value	= sgs.role_evaluation[from:objectName()]["loyalist"] - loyalist_value ,
			renegade_value	= sgs.role_evaluation[from:objectName()]["renegade"] - renegade_value 
		}

		local value_changed = false
		
		for msgtype,diffvalue in pairs(diffarr) do
			if diffvalue ~= 0 then
				value_changed = true
				local log= sgs.LogMessage()
				log.type = "#" .. msgtype .. (diffvalue > 0 and "_inc" or "_dec")
				log.from = from
				log.arg= math.abs(math.ceil(diffvalue))
				global_room:sendLog(log)
			end
		end
		
		if value_changed then
			local log= sgs.LogMessage()
			log.type = sgs.role_evaluation[from:objectName()]["loyalist"] >= 0 and  "#show_intention_loyalist" or "#show_intention_rebel"
			log.from = from
			log.arg  = string.format("%d", math.abs(math.ceil(sgs.role_evaluation[from:objectName()]["loyalist"])))
			log.arg2 = string.format("%d", sgs.role_evaluation[from:objectName()]["renegade"])
			global_room:sendLog(log)			
		end
	end
	sgs.outputRoleValues(from, level)
end

function sgs.outputRoleValues(player, level)
	global_room:writeToConsole(player:getGeneralName() .. " " .. level .. " " .. sgs.evaluatePlayerRole(player)
								.. " L" .. math.ceil(sgs.role_evaluation[player:objectName()]["loyalist"])
								.. " r" .. math.ceil(sgs.role_evaluation[player:objectName()]["renegade"])
								.. " " .. sgs.gameProcess(player:getRoom())
								.. " " .. sgs.current_mode_players["loyalist"] .. sgs.current_mode_players["rebel"]	.. sgs.current_mode_players["renegade"])
end

function sgs.updateIntention(from, to, intention, card)
	if not to then global_room:writeToConsole(debug.traceback()) return end
	if from:objectName() == to:objectName() then return end
	
	sgs.ai_card_intention.general(from, to, intention) 
end

function sgs.updateIntentions(from, tos, intention, card)
	for _, to in ipairs(tos) do
		sgs.updateIntention(from, to, intention, card)
	end
end

function sgs.isLordHealthy()
	local lord = global_room:getLord()
	local lord_hp
	if not lord then return true end
	if lord:hasSkill("benghuai") and lord:getHp() > 4 then lord_hp = 4 
	else lord_hp = lord:getHp() end
	return lord_hp > 3 or (lord_hp > 2 and sgs.getDefense(lord) > 3)
end

function sgs.isLordInDanger()
	local lord = global_room:getLord()
	local lord_hp
	if not lord then return false end
	if lord:hasSkill("benghuai") and lord:getHp() > 4 then lord_hp = 4 
	else lord_hp = lord:getHp() end
	return lord_hp < 3 
end

function sgs.gameProcess(room,arg1)
	local rebel_num = sgs.current_mode_players["rebel"]
	local loyal_num = sgs.current_mode_players["loyalist"]
	if rebel_num == 0 and loyal_num> 0 then return "loyalist"
	elseif loyal_num == 0 and rebel_num > 1 then return "rebel" end
	local loyal_value, rebel_value = 0, 0, 0
	local health = sgs.isLordHealthy()
	local danger = sgs.isLordInDanger()
	local currentplayer = room:getCurrent()
	for _, aplayer in sgs.qlist(room:getAlivePlayers()) do
		local role=aplayer:getRole()
		if role == "rebel" then
			local rebel_hp
			if aplayer:hasSkill("benghuai") and aplayer:getHp() > 4 then rebel_hp = 4
			else rebel_hp = aplayer:getHp() end
			if aplayer:getMaxHp() == 3 then rebel_value = rebel_value + 0.5 end
			rebel_value = rebel_value + rebel_hp + math.max(sgs.getDefense(aplayer) - rebel_hp * 2, 0) * 0.7
			if aplayer:getDefensiveHorse() then
				rebel_value = rebel_value + 0.5
			end
			if aplayer:getMark("@duanchang") > 0 and aplayer:getMaxHp() <= 3 then rebel_value = rebel_value - 1 end
		elseif role == "loyalist" or role == "lord" then
			local loyal_hp
			if aplayer:hasSkill("benghuai") and aplayer:getHp() > 4 then loyal_hp = 4
			else loyal_hp = aplayer:getHp() end
			if aplayer:getMaxHp() == 3 then loyal_value = loyal_value + 0.5 end
			loyal_value = loyal_value + (loyal_hp + math.max(sgs.getDefense(aplayer) - loyal_hp * 2, 0) * 0.7)
			if aplayer:getDefensiveHorse() then
				loyal_value = loyal_value + 0.5
			end
			if aplayer:getMark("@duanchang")==1 and aplayer:getMaxHp() <=3 then loyal_value = loyal_value - 1 end
		end		
	end
	local diff = loyal_value - rebel_value + (loyal_num + 1 - rebel_num) * 2
	if arg1==1 then return diff end

	if diff >= 2 then
		if health then return "loyalist"
		else return "dilemma" end
	elseif diff >= 1 then 
		if health then return "loyalish"
		elseif danger then return "dilemma" 
		else return "rebelish" end
	elseif diff <= -2 then return "rebel"
	elseif diff <= -1 then 
		if health then return "rebelish"
		else return "rebel" end
	elseif not health then return "rebelish"
	else return "neutral" end
end

function SmartAI:objectiveLevel(player)
	if player:objectName() == self.player:objectName() then return -2 end

	local players = self.room:getOtherPlayers(self.player)
	players = sgs.QList2Table(players)

	if #players == 1 then return 5 end
	
	if sgs.isRolePredictable() then
		if self.lua_ai:isFriend(player) then return -2
		elseif self.lua_ai:isEnemy(player) then return 5
		elseif self.lua_ai:relationTo(player) == sgs.AI_Neutrality then
			if self.lua_ai:getEnemies():isEmpty() then return 4 else return 0 end
		else return 0 end
	end

	local rebel_num = sgs.current_mode_players["rebel"]
	local loyal_num = sgs.current_mode_players["loyalist"]
	local renegade_num = sgs.current_mode_players["renegade"]
	local process = sgs.gameProcess(self.room)
	local target_role = player:getRole()

	if self.role == "renegade" then
		if rebel_num == 0 or loyal_num == 0 then
			if rebel_num > 0 then
				if rebel_num > 1 then
					if player:isLord() then
						return -2
					elseif target_role == "rebel" then
						return 5
					else
						return 0
					end
				elseif renegade_num > 1 then
					if player:isLord() then
						return 0
					elseif target_role == "renegade" then
						return 3
					else
						return 5
					end
				else
					if process == "loyalist" then
						if player:isLord() then
							if not sgs.isLordHealthy() then return -1
							else return 1 end
						elseif target_role == "rebel" then
							return 0
						else
							return 5
						end
					elseif process:match("rebel") then
						if target_role == "rebel" then 
							return 5
						else 
							return -1 
						end
					else
						if player:isLord() then
							return 0
						else
							return 5
						end
					end
				end
			elseif loyal_num > 0 then
				if player:isLord() then
					if not sgs.isLordHealthy() then return 0
					else return 1 end
				elseif target_role == "renegade" and renegade_num > 1 then
					return 3
				else
					return 5
				end
			else
				if player:isLord() then
					if sgs.isLordInDanger then return 0
					elseif not sgs.isLordHealthy() then return 3
					else return 5 end
				elseif sgs.isLordHealthy() then return 3
				else
					return 5
				end
			end	
		elseif process == "neutral" or (sgs.turncount <= 1 and sgs.isLordHealthy()) then			
			if sgs.turncount <= 1 and sgs.isLordHealthy() then
				if self:getOverflow() <= 0 then return 0 end
				if player:isLord() then return -1 end
				if sgs.evaluatePlayerRole(player) == "loyalist" then return 0
				elseif sgs.evaluatePlayerRole(player) == "rebel" then return 3.5
				else return 5
				end
			end
			if player:isLord() then return -1 end

			local renegade_attack_skill = string.format("buqu|%s|%s|%s|%s",sgs.priority_skill,sgs.save_skill,sgs.recover_skill,sgs.drawpeach_skill)
			for i=1, #players, 1 do
				if not players[i]:isLord() and self:hasSkills(renegade_attack_skill,players[i]) then return 5 end
				if not players[i]:isLord() and math.abs(sgs.ai_chaofeng[players[i]:getGeneralName()] or 0) >3 then return 5 end
			end
			return 3
		elseif process:match("rebel") then			
			return target_role == "rebel" and 5 or -1
		elseif process:match("dilemma") then
			if target_role == "rebel" then return 5
			elseif player:isLord() then return -2
			elseif target_role == "renegade" then return 0
			else return 5 end
		else
			if player:isLord() or target_role == "renegade" then return 0 end
			return target_role == "rebel" and -2 or 5
		end
	end
	
	if self.player:isLord() or self.role == "loyalist" then
		if player:isLord() then return -2 end

		if self.role == "loyalist" and loyal_num == 1 and renegade_num == 0 then return 5 end
		if sgs.evaluatePlayerRole(player) == "neutral" then return 0 end
	  
		if rebel_num == 0 then
			if #players == 2 and self.role == "loyalist" then return 5 end

			if self.player:isLord() and self:hasHeavySlashDamage(self.player, nil, player) and player:getHp() <= 2 then
				return 0
			end

			if not sgs.explicit_renegade then
				self:sort(players, "hp")
				local maxhp = players[#players]:isLord() and players[#players - 1]:getHp() or players[#players]:getHp()
				if maxhp > 2 then return player:getHp() == maxhp and 5 or 0 end
				if maxhp == 2 then return self.player:isLord() and 0 or (player:getHp() == maxhp and 5 or 1) end      
				return self.player:isLord() and 0 or 5
			else
				if self.player:isLord() then
					if sgs.evaluatePlayerRole(player) == "renegade" and player:getHp() > 1 then
						return 5
					else
						return player:getHp() > 1 and 1 or 0
					end
				else
					return sgs.evaluatePlayerRole(player) == "renegade" and 5 or 0
				end
			end
		end
		if loyal_num == 0 then
			if rebel_num > 2 then
				if target_role == "renegade" then return -1 end
			elseif rebel_num > 1 then
				if target_role == "renegade" then return -1 end
			elseif target_role == "renegade" then return sgs.isLordInDanger() and -1 or 4 end
		end
		if renegade_num == 0 then
			if not (sgs.evaluatePlayerRole(player) == "loyalist" or sgs.evaluateRoleTrends(player) == "loyalist") then return 5 end
		end

		if process == "rebel" and rebel_num > loyal_num and target_role == "renegade" then return -2 end

		if sgs.evaluatePlayerRole(player) == "rebel" then return 5
		elseif sgs.evaluatePlayerRole(player) == "loyalist" then return -2		
		else return 0 end
	elseif self.role == "rebel" then
	
		if loyal_num ==0 and renegade_num ==0 then return player:isLord() and 5 or -2 end
		if sgs.evaluatePlayerRole(player) == "neutral" then return 0 end

		if process == "loyalist" and renegade_num > 0 and sgs.evaluatePlayerRole(player) == "renegade" then return -2 end
	  
		if player:isLord() then return 5
		elseif sgs.evaluatePlayerRole(player) == "loyalist" then return 5
		elseif sgs.evaluatePlayerRole(player) == "rebel" then return -2
		else return 0 end
	end
end

function SmartAI:isFriend(other, another)
	if not other then self.room:writeToConsole(debug.traceback()) return end
	if another then return self:isFriend(other)==self:isFriend(another) end
	if sgs.isRolePredictable() and self.lua_ai:relationTo(other) ~= sgs.AI_Neutrality then return self.lua_ai:isFriend(other) end
	if self.player:objectName() == other:objectName() then return true end
	if self:objectiveLevel(other) < 0 then return true end
	return false
end

function SmartAI:isEnemy(other, another)
	if not other then self.room:writeToConsole(debug.traceback()) return end
	if another then return self:isFriend(other)~=self:isFriend(another) end
	if sgs.isRolePredictable() and self.lua_ai:relationTo(other) ~= sgs.AI_Neutrality then return self.lua_ai:isEnemy(other) end
	if self.player:objectName() == other:objectName() then return false end
	if self:objectiveLevel(other) > 0 then return true end
	return false
end

function SmartAI:getFriendsNoself(player)
	player = player or self.player
	if self:isFriend(self.player, player) then
		return self.friends_noself
	elseif self:isEnemy(self.player, player) then
		friends = sgs.QList2Table(self.lua_ai:getEnemies())
		for i = #friends, 1, -1 do
			if friends[i]:objectName() == player:objectName() or not friends[i]:isAlive() then
				table.remove(friends, i)
			end
		end
		return friends
	else
		return {}
	end
end

function SmartAI:getFriends(player)
	player = player or self.player
	if self:isFriend(self.player, player) then
		return self.friends
	elseif self:isEnemy(self.player, player) then
		return self.enemies
	else
		return {player}
	end
end

function SmartAI:getEnemies(player)
	if self:isFriend(self.player, player) then
		return self.enemies
	elseif self:isEnemy(self.player, player) then
		return self.friends
	else
		return {}
	end
end

function SmartAI:sortEnemies(players)
	local comp_func = function(a,b)
		local alevel = self:objectiveLevel(a)
		local blevel = self:objectiveLevel(b)

		if alevel~= blevel then return alevel > blevel end
		return sgs.getDefenseSlash(a) < sgs.getDefenseSlash(b)
	end
	table.sort(players,comp_func)
end

function SmartAI:updateAlivePlayerRoles()
	for _, arole in ipairs({"lord", "loyalist", "rebel", "renegade"}) do
		sgs.current_mode_players[arole] = 0
	end
	for _, aplayer in sgs.qlist(self.room:getAllPlayers()) do
		sgs.current_mode_players[aplayer:getRole()] = sgs.current_mode_players[aplayer:getRole()] + 1
	end	
end

function SmartAI:updatePlayers(clear_flags)
	if clear_flags ~= false then clear_flags = true end
	if self.role ~= self.player:getRole() then
		if not ((self.role=='lord' and self.player:getRole()=='loyalist') or (self.role=='loyalist' and self.player:getRole()=='lord')) then			
			sgs.role_evaluation[self.player:objectName()]["loyalist"]= 0
			sgs.role_evaluation[self.player:objectName()]["rebel"]= 0
			sgs.role_evaluation[self.player:objectName()]["renegade"]= 0
		end
		self.role = self.player:getRole()
	end
	if clear_flags then
		for _, aflag in ipairs(sgs.ai_global_flags) do
			sgs[aflag] = nil
		end
	end

	sgs.discard_pile = global_room:getDiscardPile()
	sgs.draw_pile = global_room:getDrawPile()
	
	if sgs.isRolePredictable() then
		self.friends = {}
		self.friends_noself = {}
		local friends = sgs.QList2Table(self.lua_ai:getFriends())
		for i = 1, #friends, 1 do
			if friends[i]:isAlive() and friends[i]:objectName() ~= self.player:objectName() then
				table.insert(self.friends, friends[i])
				table.insert(self.friends_noself, friends[i])
			end
		end
		table.insert(self.friends, self.player)

		local enemies = sgs.QList2Table(self.lua_ai:getEnemies())
		for i = 1, #enemies, 1 do
			if enemies[i]:isDead() or enemies[i]:objectName() == self.player:objectName() then table.remove(enemies, i) end
		end
		self.enemies = enemies
		
		self.retain = 2
		self.harsh_retain = false
		if #self.enemies == 0 then
			local neutrality = {}
			for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if self.lua_ai:relationTo(aplayer) == sgs.AI_Neutrality and not aplayer:isDead() then table.insert(neutrality, aplayer) end
			end
			local function compare_func(a,b)
				return self:objectiveLevel(a) > self:objectiveLevel(b)
			end
			table.sort(neutrality, compare_func)
			table.insert(self.enemies, neutrality[1])
		end
		return
	end

	self.enemies = {}
	self.friends = {}
	self.friends_noself = {}

	
	local role = self.role
	self.retain = 2
	self.harsh_retain = true

	for _,player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:objectiveLevel(player) < 0 and player:isAlive() then 
			table.insert(self.friends_noself, player)
			table.insert(self.friends, player)
		end
		if self:objectiveLevel(player) > 0 and player:isAlive() then
			table.insert(self.enemies, player)
		end
	end	
	table.insert(self.friends,self.player)
	
	if sgs.isRolePredictable() then return end
	self:updateAlivePlayerRoles()

	local players = sgs.QList2Table(self.room:getAlivePlayers())
	local cmp = function(a, b)
		return sgs.role_evaluation[a:objectName()]["renegade"] > sgs.role_evaluation[b:objectName()]["renegade"]
	end
	table.sort(players, cmp)
	
	for i =1, #players, 1 do
		local p = players[i]
		local renegade_val = sgs.current_mode_players["rebel"] == 0 and 10 or 20
		if i <= sgs.current_mode_players["renegade"] and sgs.role_evaluation[p:objectName()]["renegade"] >= renegade_val then
			sgs.ai_role[p:objectName()] = "renegade"
			sgs.explicit_renegade = true
		else
			if (sgs.role_evaluation[p:objectName()]["loyalist"] > 0 and sgs.current_mode_players["loyalist"] > 0) or p:isLord() then
				sgs.ai_role[p:objectName()] = "loyalist" 
			elseif sgs.role_evaluation[p:objectName()]["loyalist"] < 0 and sgs.current_mode_players["rebel"] > 0 then 
				sgs.ai_role[p:objectName()] = "rebel"
			else
				if sgs.role_evaluation[p:objectName()]["loyalist"] > 0  then sgs.ai_role[p:objectName()] = "loyalist" end
				if sgs.role_evaluation[p:objectName()]["loyalist"] < 0  then sgs.ai_role[p:objectName()] = "rebel" end
				if sgs.role_evaluation[p:objectName()]["loyalist"] == 0 then sgs.ai_role[p:objectName()] = "neutral" end
			end
		end
		if sgs.current_mode_players["rebel"] == 0 and sgs.current_mode_players["loyalist"] == 0 and not p:isLord() then
			sgs.ai_role[p:objectName()] = "renegade"
			sgs.explicit_renegade = true			
		end
	end


end
--查找room内指定objectName的player
function findPlayerByObjectName(room, name, include_death, except)
	if not room then
		return
	end
	local players = nil
	if include_death then
		players = room:getPlayers()
	else
		players = room:getAllPlayers()
	end
	if except then
		players:removeOne(except)
	end
	for _,p in sgs.qlist(players) do
		if p:objectName() == name then
			return p
		end
	end
end
--获取对target使用的锦囊TrickClass的一般仇恨值--
function getTrickIntention(TrickClass, target)
	local Intention = sgs.ai_card_intention[TrickClass]
	if type(Intention) == "number" then
		return Intention 
	elseif type(Intention == "function") then
		if TrickClass == "IronChain" then --这个铁索连环真让人头疼……不知还有没有别的仇恨值是函数的锦囊……
			if target:isChained() then
				return -80
			else
				return 80
			end
		end
	end
	if sgs.dynamic_value.damage_card[TrickClass] then 
		return 70
	end
	if sgs.dynamic_value.benefit[TrickClass] then --没想到铁索连环会是有益锦囊……
		return -40
	end
	if target then
		if TrickClass == "Snatch" or TrickClass == "Dismantlement" then
			local judgelist = target:getCards("j")
			if not judgelist or judgelist:isEmpty() then
				local armor = target:getArmor()
				if not armor or not armor:isKindOf("SilverLion") or not armor:isKindOf("GaleShell") then
					return 80
				end
			end
		end
	end
	return 0
end
--无懈可击：更新仇恨值--
--promptlist{?, trick:className(), to:objectName(), positive<"true"or"false">}--
--用于判断player使用的、无懈掉对to的trick的无懈可击
--positive=true为维护性无懈可击
sgs.ai_nullification_level = {} --无懈可击层级记录
sgs.ai_trick_struct = {"source", "target", "trick"} --被无懈可击的一般锦囊
sgs.ai_choicemade_filter.Nullification.general = function(player, promptlist)
	local room = player:getRoom() --当前房间
	local NFSource = player:objectName() --使用当前无懈可击的角色 --from
	local TrickClass = promptlist[2] --被无懈可击的锦囊 --card
	local TrickTarget = promptlist[3] --被无懈可击的锦囊的使用目标 --to,始终是第一层级
	local positive = true --无懈可击的作用是否是用于维护此被无懈可击的锦囊
	if promptlist[4] == "false" then 
		positive = false 
	end
	local level = #sgs.ai_nullification_level --已有层数
	if TrickClass == "Nullification" then --无懈某人的无懈可击
		table.insert(sgs.ai_nullification_level, NFSource)
		local target = sgs.ai_nullification_level[1]
		if NFSource ~= target then --并非是无懈 对 以自己为目标的原锦囊 的无懈可击
			local count = 0
			for _,name in pairs(sgs.ai_nullification_level) do
				if name == NFSource then
					count = count + 1
				end
			end
			local pos = math.mod(level, 2) --注意这个level是更新前的，比当前的level少1
			local to = findPlayerByObjectName(room, target)
			local intention = count * 25
			if pos == 0 then --现有奇数级，当前级为友方
				sgs.updateIntention(player, to, -intention)
			else --现有偶数级，当前级为敌方
				sgs.updateIntention(player, to, intention)
			end
		end
	else
		if NFSource == TrickTarget then --（自己）无懈对自己使用的一般锦囊
			local me = findPlayerByObjectName(room, TrickTarget)
			local intention = getTrickIntention(TrickClass, me)
			if level > 0 and sgs.ai_nullification_level[1] == TrickTarget then
				if sgs.ai_trick_struct[3] == TrickClass then
					table.insert(sgs.ai_nullification_level, NFSource)
				else
					if intention > 0 then
						sgs.ai_nullification_level = {TrickTarget, TrickTarget, NFSource}
					else
						sgs.ai_nullification_level = {TrickTarget, NFSource}
					end
					sgs.ai_trick_struct = {NFSource, TrickTarget, TrickClass}
				end
			else
				if intention > 0 then --无懈对自己的不利锦囊，属于友方行为，再无懈视为敌方
					sgs.ai_nullification_level = {TrickTarget, TrickTarget, NFSource}
				else --无懈对自己的有利锦囊，属于敌方行为，再无懈视为友方
					sgs.ai_nullification_level = {TrickTarget, NFSource}
				end
				sgs.ai_trick_struct = {NFSource, TrickTarget, TrickClass}
			end 
		else --无懈对他人的一般锦囊
			sgs.lastclass = TrickClass
			local to = findPlayerByObjectName(room, TrickTarget, false, player) --被无懈可击的锦囊的使用目标
			local intention = getTrickIntention(TrickClass, to)
			if intention > 0 then --无懈不利锦囊，属于友方行为，再无懈视为敌方
				sgs.ai_nullification_level = {TrickTarget, TrickTarget, NFSource}
			else --无懈有利锦囊，属于敌方行为，再无懈属于友方
				sgs.ai_nullification_level = {TrickTarget, NFSource}
			end
			sgs.ai_trick_struct = {NFSource, TrickTarget, TrickClass}
			sgs.updateIntention(player, to, -intention) --取相反的仇恨值
		end
	end
end

sgs.ai_choicemade_filter.playerChosen.general = function(from, promptlist)
	if from:objectName() == promptlist[3] then return end
	local reason = string.gsub(promptlist[2], "%-", "_")
	local to
	for _, p in sgs.qlist(from:getRoom():getAlivePlayers()) do
		if p:objectName() == promptlist[3] then to = p break end
	end
	local callback = sgs.ai_playerchosen_intention[reason]
	if callback then
		if type(callback) == "number" then
			sgs.updateIntention(from, to, sgs.ai_playerchosen_intention[reason])
		elseif type(callback) == "function" then
			callback(from, to)
		end
	end
end

sgs.ai_choicemade_filter.cardChosen.general = function(from, promptlist)
	local reason = string.gsub(promptlist[2], "%-", "_")
	local callback = sgs.ai_cardChosen_intention[reason] 
	local to = global_room:getCurrent()
	if callback and to then 
		if type(callback) == "number" and to:objectName() ~= from:objectName() then
			sgs.updateIntention(from, to, sgs.ai_cardChosen_intention[reason])
		elseif type(callback) == "function" then
			local card_id = promptlist[3]
			callback(from, to, card_id)
		end
	end	
end

function SmartAI:filterEvent(event, player, data)
	if not sgs.recorder then
		sgs.recorder = self
	end
	if player:objectName()==self.player:objectName() then		
		if sgs.debugmode and type(sgs.ai_debug_func[event])=="table" then
			for _,callback in pairs(sgs.ai_debug_func[event]) do
				if type(callback)=="function" then callback(self,player,data) end
			end
		end
		if type(sgs.ai_chat_func[event])=="table" and sgs.GetConfig("AIChat", true) and player:getState() == "robot" then
			for _,callback in pairs(sgs.ai_chat_func[event]) do
				if type(callback)=="function" then callback(self,player,data) end
			end
		end
		if type(sgs.ai_event_callback[event])=="table" then
			for _,callback in pairs(sgs.ai_event_callback[event]) do
				if type(callback)=="function" then callback(self,player,data) end
			end
		end
	end

	--if event ==sgs.AskForPeaches then endlessNiepan(data:toDying().who) end

	sgs.lastevent = event
	sgs.lasteventdata = eventdata
	if event == sgs.ChoiceMade and self == sgs.recorder then
		local carduse = data:toCardUse()
		if carduse and carduse.card ~= nil then
			for _, aflag in ipairs(sgs.ai_global_flags) do
				sgs[aflag] = nil
			end
			for _, callback in ipairs(sgs.ai_choicemade_filter.cardUsed) do
				if type(callback) == "function" then
					callback(player, carduse)
				end
			end
		elseif data:toString() then
			promptlist = data:toString():split(":")
			local callbacktable = sgs.ai_choicemade_filter[promptlist[1]]
			if callbacktable and type(callbacktable) == "table" then
				local index = 2 
				if promptlist[1] == "cardResponded" then
					if (promptlist[2] == "@guicai" or promptlist[2] == "@guidao") and promptlist[4] ~= "_nil_" then
						sgs.RetrialPlayer = player
					end
					index = 3 
				end
				local callback = callbacktable[promptlist[index]] or callbacktable.general
				if type(callback) == "function" then
					callback(player, promptlist, self)
				end
			end
			if data:toString() == "skillInvoke:fenxin:yes" then
				for _, aplayer in sgs.qlist(self.room:getAllPlayers()) do
					if aplayer:hasFlag("FenxinTarget") then
						local temp_table = sgs.role_evaluation[player:objectName()]
						sgs.role_evaluation[player:objectName()] = sgs.role_evaluation[aplayer:objectName()]
						sgs.role_evaluation[aplayer:objectName()] = temp_table
						self:updatePlayers()
						break
					end
				end
			end
		end
	elseif event == sgs.CardUsed or event == sgs.CardEffect or event == sgs.GameStart or event == sgs.EventPhaseStart then
		self:updatePlayers()
	elseif event == sgs.Death or event == sgs.HpChanged or event == sgs.MaxHpChanged or event == sgs.BuryVictim then
		self:updatePlayers(false)
	end
	
	if event == sgs.Death or event == sgs.BuryVictim then
		if self == sgs.recorder then self:updateAlivePlayerRoles() end
	end
	if event == sgs.EventPhaseStart then
		if self.room:getCurrent():getPhase() == sgs.Player_NotActive then sgs.modifiedRoleEvaluation() end
	end

	if self.player:objectName() == player:objectName() and event == sgs.AskForPeaches then
		local dying = data:toDying()
		if self:isFriend(dying.who) and dying.who:getHp() < 1 then
			sgs.card_lack[player:objectName()]["Peach"]=1
		end
	end
	
	if self ~= sgs.recorder then return end
	
	if event == sgs.TargetConfirmed then
	
		local struct = data:toCardUse()
		local from  = struct.from
		if from and from:objectName() == player:objectName() then
			local card = struct.card
			local to = sgs.QList2Table(struct.to)

			local callback = sgs.ai_card_intention[card:getClassName()]
			if callback then
				if type(callback) == "function" then
					callback(self, card, from, to)
				elseif type(callback) == "number" then
					sgs.updateIntentions(from, to, callback, card)
				end
			end
			if card:getClassName() == "LuaSkillCard" and card:isKindOf("LuaSkillCard") then
				local luaskillcardcallback = sgs.ai_card_intention[card:objectName()]
				if luaskillcardcallback then
					if type(luaskillcardcallback) == "function" then
						luaskillcardcallback(self, card, from, to)
					elseif type(luaskillcardcallback) == "number" then
						sgs.updateIntentions(from, to, luaskillcardcallback, card)
					end
				end
			end
		end
		
		local lord = getLord(player)
		if lord and struct.card and lord:getHp() == 1 and self:aoeIsEffective(struct.card, lord, from) then
			if struct.card:isKindOf("SavageAssault") and struct.to:contains(lord) then
				sgs.ai_lord_in_danger_SA = true
			elseif struct.card:isKindOf("ArcheryAttack") and struct.to:contains(lord) then
				sgs.ai_lord_in_danger_AA = true
			end
		end
		
	elseif event == sgs.CardEffect then
		local struct = data:toCardEffect()
		local card = struct.card
		local from = struct.from
		local to = struct.to
		if card and card:isKindOf("AOE") and to and to:isLord() and (sgs.ai_lord_in_danger_SA or sgs.ai_lord_in_danger_AA) then
			sgs.ai_lord_in_danger_SA = nil
			sgs.ai_lord_in_danger_AA = nil
		end
		if card:isKindOf("Collateral") then sgs.ai_collateral = true end
		if card:isKindOf("Dismantlement") or card:isKindOf("Snatch") or card:isKindOf("YinlingCard") then
			sgs.ai_snat_disma_effect = true
			sgs.ai_snat_dism_from = struct.from
		end

		if card:isKindOf("Slash") then
			if to:hasSkill("leiji") and (getCardsNum("Jink", to) > 0 or to:hasArmorEffect("EightDiagram")) then
				if to:isLord() and not hasExplicitRebel(self.room) then sgs.updateIntention(from, to, 50) end
				sgs.ai_leiji_effect = true
			end
		end
		
		if from and to and to:hasSkills("longdan+chongzhen") and (card:isKindOf("AOE") or card:isKindOf("Slash")) then
			sgs.chongzhen_target = from
		end
		
	elseif event == sgs.PreHpReduced then
		local damage = data:toDamage()
		local lord = getLord(player)
		if lord and damage.trigger_chain and lord:isChained() and self:damageIsEffective(lord, damage.nature, from) then
			if lord:hasArmorEffect("Vine") and damage.nature == sgs.DamageStruct_Fire and lord:getHp() <= damage.damage + 1 then
				sgs.LordNeedPeach = damage.damage + 2 - lord:getHp()
			elseif lord:getHp() <= damage.damage then
				sgs.LordNeedPeach = damage.damage + 1 - lord:getHp()
			end
		else
			sgs.LordNeedPeach = nil
		end
	elseif event == sgs.Damage then
		local damage = data:toDamage()
		if damage.from and damage.to and damage.from:objectName() ~= damage.to:objectName() then
			if damage.to:hasSkill("fankui") then
				sgs.fankui_target = damage.from
			elseif damage.to:hasSkills("ganglie|neoganglie") then
				sgs.ganglie_target = damage.from
			elseif damage.to:hasSkill("langgu") then
				sgs.langgu_target = damage.from
			elseif damage.to:hasSkill("tanlan") then
				sgs.tanlan_target = damage.from
			elseif damage.to:hasSkill("enyuan") then
				sgs.enyuan_damage_target = damage.from
			end
		end
	elseif event == sgs.Damaged then
		local damage = data:toDamage()
		local card = damage.card
		local from = damage.from
		local to = damage.to
		local source = self.room:getCurrent()
		
		if not damage.card then
			local intention
			if sgs.ai_quhu_effect then
				sgs.ai_quhu_effect = false
				local xunyu = self.room:findPlayerBySkillName("quhu")
				intention = 80
				from = xunyu
			else
				intention = 100 
			end

			-- if sgs.ai_ganglie_effect and sgs.ai_ganglie_effect ==string.format("%s_%s_%d",from:objectName(), to:objectName(), sgs.turncount)  then
				-- sgs.ai_ganglie_effect = nil
				-- intention = -30
			-- end
			
			if damage.transfer or damage.chain then intention = 0 end
			
			if from and intention~=0 then sgs.updateIntention(from, to, intention) end
		end
	elseif event == sgs.CardUsed then
		
		local struct = data:toCardUse()
		local card = struct.card
		local lord = getLord(player)
		local who
		if not struct.to:isEmpty() then who = struct.to:first() end
		
		if sgs.turncount == 1 and lord and who then
			if (card:isKindOf("Snatch") or card:isKindOf("Dismantlement") or card:isKindOf("YinlingCard")) and sgs.evaluateRoleTrends(who) == "neutral" then
				local aplayer = self:exclude({lord}, card, struct.from)
				if #aplayer ==1 then sgs.updateIntention(player, lord, -70) end
			end
		end
		
		if card and lord and card:isKindOf("Duel") and lord:hasFlag("will_wake") then
			lord:setFlags("-will_wake")
		end
		
		if sgs.chongzhen_target then sgs.chongzhen_target = nil end
		
	elseif event == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		local from = nil   -- convert move.from from const Player * to ServerPlayer *
		local to   = nil   -- convert move.to to const Player * to ServerPlayer *
		if move.from then from = findPlayerByObjectName(self.room, move.from:objectName(), true) end
		if move.to   then to   = findPlayerByObjectName(self.room, move.to:objectName(), true)	end
		local reason = move.reason
		local from_places=sgs.QList2Table(move.from_places)

		for i = 0, move.card_ids:length()-1 do
			local place = move.from_places:at(i)
			local card_id=move.card_ids:at(i)
			local card = sgs.Sanguosha:getCard(card_id)

			if sgs.ai_snat_disma_effect then
				sgs.ai_snat_disma_effect = false
				local intention = 70
				if place == sgs.Player_PlaceDelayedTrick then
					if not card:isKindOf("Disaster") then intention = -intention else intention = 0 end
					if card:isKindOf("YanxiaoCard") then intention=math.abs(intention) end
				elseif place == sgs.Player_PlaceEquip then
					if player:getLostHp() > 1 and card:isKindOf("SilverLion") then 
						if self:hasSkills(sgs.use_lion_skill, player) then 
							intention = player:containsTrick("indulgence") and -intention or 0
						else	
							intention = self:isWeak(player) and  -intention  or -intention / 10 
						end
					end
					if self:hasSkills(sgs.lose_equip_skill, player) then 
						if self:isWeak(player) and (card:isKindOf("DefensiveHorse") or card:isKindOf("Armor")) then
							intention=math.abs(intention)
						else
							intention = 0 
						end						
					end
				elseif place == sgs.Player_PlaceHand then
					if player:hasSkill("kongcheng") and player:isKongcheng() then						
						intention = - (intention / 10)
					end
				end				
				if from then sgs.updateIntention(sgs.ai_snat_dism_from, from, intention) end
			end
			
			if move.to_place == sgs.Player_PlaceHand and to and player:objectName() == to:objectName() then
				if card:hasFlag("visible") then
					if isCard("Slash",card, player) then sgs.card_lack[player:objectName()]["Slash"]=0 end
					if isCard("Jink",card, player) then sgs.card_lack[player:objectName()]["Jink"]=0 end
					if isCard("Peach",card, player) then sgs.card_lack[player:objectName()]["Peach"]=0 end
				else
					sgs.card_lack[player:objectName()]["Slash"]=0
					sgs.card_lack[player:objectName()]["Jink"]=0
					sgs.card_lack[player:objectName()]["Peach"]=0
				end
			end

			if move.to_place == sgs.Player_PlaceHand and to and place ~= sgs.Player_DrawPile then
				if from and player:objectName() == from:objectName()
					and from:objectName() ~= to:objectName() and place == sgs.Player_PlaceHand and not card:hasFlag("visible") then
					local flag = string.format("%s_%s_%s", "visible", from:objectName(), to:objectName())
					global_room:setCardFlag(card_id, flag, from)
				end
			end

			if reason.m_skillName == "qiaobian" and from and to and self.room:getCurrent():objectName() == player:objectName() then			
				if table.contains(from_places,sgs.Player_PlaceDelayedTrick) then
					if card:isKindOf("YanxiaoCard") then
						sgs.updateIntention(player, from, 80)
						sgs.updateIntention(player, to, -80)
					end
					if card:isKindOf("SupplyShortage") or card:isKindOf("Indulgence") then
						sgs.updateIntention(player, from, -80)
						sgs.updateIntention(player, to, 80)
					end
				end

				if table.contains(from_places,sgs.Player_PlaceEquip) then
					sgs.updateIntention(player, to, -80)
				end

			end

			if reason.m_skillName == "yiji" and reason.m_reason == sgs.CardMoveReason_S_REASON_PREVIEW and to and to:objectName() == player:objectName() then			
				global_room:setCardFlag(card_id, "yijicard")
			end
			if move.to_place == sgs.Player_PlaceHand and place == sgs.Player_PlaceHand and to and from and from:objectName() == player:objectName()
					and (from:hasSkill("yiji") and card:hasFlag("yijicard") or from:hasSkill("miji") and from:getPhase() == sgs.Player_Finish)
					and (reason.m_reason == sgs.CardMoveReason_S_REASON_GIVE or reason.m_reason == sgs.CardMoveReason_S_REASON_PREVIEWGIVE) then
				if (to:hasSkill("manjuan") and to:getPhase() == sgs.Player_NotActive) or to:hasSkill("kongcheng") then
				else
					sgs.updateIntention(from, to, -70)
				end	
			end
			
			if player:hasFlag("Playing") and sgs.turncount <= 3 and player:getPhase() == sgs.Player_Discard 
						and reason.m_reason==sgs.CardMoveReason_S_REASON_RULEDISCARD and not self:needBear(player) then
				local is_neutral = sgs.evaluateRoleTrends(player) == "neutral"
					
				if isCard("Slash", card, player) and player:canSlashWithoutCrossbow() then
					for _, target in sgs.qlist(self.room:getOtherPlayers(player)) do
						local has_slash_prohibit_skill = false
						for _, askill in sgs.qlist(target:getVisibleSkillList()) do
					 		local s_name = askill:objectName()
							local filter = sgs.ai_slash_prohibit[s_name]
							if filter and type(filter) == "function" and not (s_name == "tiandu" or s_name == "hujia" or s_name == "huilei" or s_name == "weidi") then
								has_slash_prohibit_skill = true
								break
							end
						end
						
						if target:hasSkill("fangzhu") and target:getLostHp() <= 2 then
							has_slash_prohibit_skill = true
						end

						if player:canSlash(target, card, true) and self:slashIsEffective(card, target)
								and not has_slash_prohibit_skill and sgs.isGoodTarget(target,self.enemies, self) then
							if is_neutral then sgs.updateIntention(player, target, -35) end
						end
					end
				end

				if isCard("Indulgence", card, player) and getLord(player) and not getLord(player):hasSkill("qiaobian") then
					for _, target in sgs.qlist(self.room:getOtherPlayers(player)) do
						if not (target:containsTrick("indulgence") or target:containsTrick("YanxiaoCard") or self:hasSkills("qiaobian", target)) then
							local aplayer = self:exclude( {target}, card, player)
							if #aplayer ==1 and is_neutral then sgs.updateIntention(player, target, -35) end
						end
					end
				end

				if isCard("SupplyShortage", card, player) and getLord(player) and not getLord(player):hasSkill("qiaobian") then
					for _, target in sgs.qlist(self.room:getOtherPlayers(player)) do
						if player:distanceTo(target) <= (player:hasSkill("duanliang") and 2 or 1) and 
								not (target:containsTrick("supply_shortage") or target:containsTrick("YanxiaoCard") or self:hasSkills("qiaobian", target)) then
							local aplayer = self:exclude( {target}, card, player)
							if #aplayer ==1 and is_neutral then sgs.updateIntention(player, target, -35) end
						end
					end
				end
			end
		end
		
		if from and to and from:objectName() ~= to:objectName() and from:isAlive() and to:hasSkill("enyuan") and 
			move.card_ids:length() > 1 and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE then
			sgs.enyuan_drawcard_target = from
		end
		
	elseif event == sgs.StartJudge then
		local judge = data:toJudge()
		local reason = judge.reason
		if reason == "beige" then
			local caiwenji = self.room:findPlayerBySkillName("beige")
			local intention = -60
			if player:objectName() == caiwenji:objectName() then intention = 0 end
			sgs.updateIntention(caiwenji, player, intention)
		end
		sgs.JudgeResult = judge:isGood()
	elseif event == sgs.AskForRetrial then
		local judge = data:toJudge()
		if sgs.JudgeResult ~= judge:isGood() and sgs.RetrialPlayer and judge.who then
			local reason = "bazhen|EightDiagram|wuhun|supply_shortage|tuntian|nosqianxi|nosmiji|indulgence|lightning|baonue$"..
									"|leiji|caizhaoji_hujia|caizhaoji_hujia|tieji|luoshen|ganglie|neoganglie"
			if reason:match(judge.reason) then
				if judge:isGood() then
					sgs.updateIntention(sgs.RetrialPlayer, judge.who, -10)
				else
					sgs.updateIntention(sgs.RetrialPlayer, judge.who, 10)
				end
			end
			sgs.RetrialPlayer = nil
			sgs.JudgeResult = judge:isGood()
		end
	elseif event == sgs.EventPhaseEnd and player:getPhase() ==  sgs.Player_Play then
		self.room:setPlayerFlag(player, "Playing")
	elseif event == sgs.EventPhaseStart and player:getPhase() ==  sgs.Player_NotActive then
		if player:isLord() then sgs.turncount = sgs.turncount + 1 end

		sgs.debugmode = io.open("lua/ai/debug")
		if sgs.debugmode then sgs.debugmode:close() end

		if sgs.turncount == 1 and player:isLord() then			
			local msg = ""
			local humanCount = 0
			for _, aplayer in sgs.qlist(self.room:getAllPlayers()) do
				if aplayer:getState() ~= "robot" then humanCount = humanCount +1 end
				if not aplayer:isLord() then 
					msg = msg..string.format("%s\t%s\r\n",aplayer:getGeneralName(),aplayer:getRole())
				end
			end
			self.room:setTag("humanCount",sgs.QVariant(humanCount))

			if humanCount == 1 and not sgs.isRolePredictable() and not sgs.GetConfig("EnableHegemony", false) then 
				global_room:writeToConsole(msg)
			end
		end

	elseif event == sgs.GameStart then		
		sgs.debugmode = io.open("lua/ai/debug")
		if sgs.debugmode then sgs.debugmode:close() end
		--self.room:acquireSkill(self.room:getOwner(),"shenwei")
		--self.room:acquireSkill(self.room:getOwner(),"qianxun")
		if player:isLord() then			
			if sgs.debugmode then logmsg("ai.html","<meta charset='utf-8'/>") end
		end
		
	end
end

function SmartAI:askForSuit(reason)
	if not reason then return sgs.ai_skill_suit.fanjian(self) end -- this line is kept for back-compatibility
	local callback = sgs.ai_skill_suit[reason]
	if type(callback) == "function" then
		if callback(self) then return callback(self) end
	end
	return math.random(0,3)
end

function SmartAI:askForSkillInvoke(skill_name, data)
	skill_name = string.gsub(skill_name, "%-", "_")
	local invoke = sgs.ai_skill_invoke[skill_name]
	if type(invoke) == "boolean" then
		return invoke
	elseif type(invoke) == "function" then
		return invoke(self, data)
	else
		local skill = sgs.Sanguosha:getSkill(skill_name)
		return skill and skill:getFrequency() == sgs.Skill_Frequent
	end
end

function SmartAI:askForChoice(skill_name, choices, data)
	local choice = sgs.ai_skill_choice[skill_name]
	if type(choice) == "string" then
		return choice
	elseif type(choice) == "function" then
		return choice(self, choices, data)
	else
		local skill = sgs.Sanguosha:getSkill(skill_name)
		if skill and choices:match(skill:getDefaultChoice(self.player)) then
			return skill:getDefaultChoice(self.player)
		else
			local choice_table = choices:split("+")
			for index, achoice in ipairs(choice_table) do
				if achoice == "benghuai" then table.remove(choice_table, index) break end
			end
			local r = math.random(1, #choice_table)
			return choice_table[r]
		end
	end
end

function SmartAI:askForDiscard(reason, discard_num, min_num, optional, include_equip)
	min_num = min_num or discard_num
	local exchange = { "lihun", "enyuan", "shichou", "quanji" }
	local callback = sgs.ai_skill_discard[reason]
	self:assignKeep(self.player:getHp(), true)
	if type(callback) == "function" then
		local cb = callback(self, discard_num, min_num, optional, include_equip)
		if cb then
			for _, card_id in ipairs(cb) do
				if not table.contains(exchange, reason) and self.player:isJilei(sgs.Sanguosha:getCard(card_id)) then
					return {}
				end
			end
			return cb
		end
	elseif optional then
		return {}
	end

	local flag = "h"
	if include_equip and (self.player:getEquips():isEmpty() or not self.player:isJilei(self.player:getEquips():first())) then flag = flag .. "e" end
	local cards = self.player:getCards(flag)
	local to_discard = {}
	cards = sgs.QList2Table(cards)
	local aux_func = function(card)
		local place = self.room:getCardPlace(card:getEffectiveId())
		if place == sgs.Player_PlaceEquip then
			if card:isKindOf("SilverLion") and self.player:isWounded() then return -2
			elseif card:isKindOf("Weapon") and self.player:getHandcardNum() < discard_num + 2 and not self:needKongcheng() then return 0
			elseif card:isKindOf("OffensiveHorse") and self.player:getHandcardNum() < discard_num + 2 and not self:needKongcheng() then return 0
			elseif card:isKindOf("OffensiveHorse") then return 1
			elseif card:isKindOf("Weapon") then return 2
			elseif card:isKindOf("DefensiveHorse") then return 3
			elseif self:hasSkills("bazhen|yizhong") and card:isKindOf("Armor") then return 0
			elseif card:isKindOf("Armor") then return 4
			end
		elseif self:hasSkills(sgs.lose_equip_skill) then return 5
		else return 0
		end
	end
	local compare_func = function(a, b)
		if aux_func(a) ~= aux_func(b) then return aux_func(a) < aux_func(b) end
		return self:getKeepValue(a) < self:getKeepValue(b)
	end

	table.sort(cards, compare_func)
	local least = min_num
	if discard_num - min_num > 1 then
		least = discard_num - 1
	end
	for _, card in ipairs(cards) do
		if (self.player:hasSkill("qinyin") and #to_discard >= least) or #to_discard >= discard_num then break end
		if table.contains(exchange, reason) or not self.player:isJilei(card) then table.insert(to_discard, card:getId()) end
	end
	return to_discard
end

sgs.ai_skill_discard.gamerule = function(self, discard_num, min_num)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local to_discard = {}	
	local peaches, jinks, analeptics, nullifications, slashes = {}, {}, {}, {}, {}
	local keeparr = {}
	local debugprint = false

	local keepdata = {"peach1", "peach2", "jink1", "peach3", "analeptic", "jink2", "nullification", "slash" }

	if not self:isWeak() and (self.player:getHp() > getBestHp(self.player) or self:getDamagedEffects(self.player) or not sgs.isGoodTarget(self.player)) then
		keepdata = {"peach1", "peach2", "analeptic","peach3", "nullification", "slash" }
	end
	
	for _, name in ipairs(keepdata) do 	keeparr[name] = nil end

	local compare_func = function(a, b)
		local v1 = self:adjustUsePriority(a,1)
		local v2 = self:adjustUsePriority(b,1)
		if a:isKindOf("NatureSlash") then v1 = v1 - 0.1 end
		if b:isKindOf("NatureSlash") then v2 = v2 - 0.1 end
		return  v1 < v2 
	end
	
	local resetCards = function(allcards, keepcards)
		local result = {}
		for _, acard in ipairs(allcards) do
			local found = false
			for _, keepcard in pairs(keepcards) do
				if keepcard and keepcard:getEffectiveId() == acard:getEffectiveId() then
					found = true
					break
				end
			end
			if not found then table.insert(result, acard) end
		end
		return result
	end

	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then table.insert(peaches, card) end
	end	
	table.sort(peaches, compare_func)
	if #peaches >= 1 and table.contains(keepdata, "peach1") then keeparr.peach1 = peaches[1] end
	if #peaches >= 2 and table.contains(keepdata, "peach2") then keeparr.peach2 = peaches[2] end
	if #peaches >= 3 and table.contains(keepdata, "peach3") then keeparr.peach3 = peaches[3] end

	cards = resetCards(cards, keeparr)	
	for _, card in ipairs(cards) do
		if isCard("Jink", card, self.player) then table.insert(jinks, card)	end
	end
	table.sort(jinks, compare_func)
	if #jinks >= 1 and table.contains(keepdata, "jink1") then keeparr.jink1 = jinks[1] end
	if #jinks >= 2 and table.contains(keepdata, "jink2") then keeparr.jink2 = jinks[2] end
 
	cards = resetCards(cards, keeparr)	
	for _, card in ipairs(cards) do
		if isCard("Analeptic", card, self.player) then table.insert(analeptics, card) end
	end
	table.sort(analeptics, compare_func)
	if #analeptics >= 1 and table.contains(keepdata, "analeptic") then keeparr.analeptic = analeptics[1] end
	
	cards = resetCards(cards, keeparr)	
	for _, card in ipairs(cards) do
		if isCard("Nullification", card, self.player) then table.insert(nullifications, card) end
	end
	table.sort(nullifications, compare_func)
	if #nullifications >= 1 and table.contains(keepdata, "nullification") then keeparr.nullification = nullifications[1] end

	cards = resetCards(cards, keeparr)	
	for _, card in ipairs(cards) do
		if isCard("Slash", card, self.player) then table.insert(slashes, card) end
	end
	table.sort(slashes, compare_func)
	if #slashes >= 1 and table.contains(keepdata, "slash") then keeparr.slash = slashes[1] end

	cards = resetCards(cards,keeparr)
	self:sortByUseValue(cards)
	self:sortByKeepValue(cards, true)

	if debugprint then
		logmsg("discard.html", "<meta charset='utf-8'/><pre>")
		logmsg("discard.html", "========================="..self.player:getGeneralName().."=================================")
		logmsg("discard.html", "")
	end

	local sortedCards = {}
	for _, name in ipairs(keepdata) do
		if keeparr[name] then 
			table.insert(sortedCards, keeparr[name]) 
			if debugprint then logmsg("discard.html", "keep :  "  ..keeparr[name]:getLogName()) end
		end
	end
	
	for _, card in ipairs(cards) do
		table.insert(sortedCards, card)
		if debugprint then logmsg("discard.html", "other :  "  ..card:getLogName()) end
	end
	
	if debugprint then logmsg("discard.html", ":::") end


	local least = min_num
	if discard_num - min_num > 1 then
		least = discard_num -1
	end

	for i = #sortedCards, 1, -1 do		
		if not self.player:isJilei(sortedCards[i]) then			
			table.insert(to_discard, sortedCards[i]:getId())
			if debugprint then logmsg("discard.html", "discard :  "  ..sortedCards[i]:getLogName()) end
		end
		if (self.player:hasSkill("qinyin") and #to_discard >= least) or #to_discard >= discard_num or self.player:isKongcheng() then break end
	end
	return to_discard
end


--询问无懈可击--
function SmartAI:askForNullification(trick, from, to, positive)
	if self.player:isDead() then return nil end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local null_card
	null_card = self:getCardId("Nullification") --无懈可击
	local null_num = 0
	local menghuo = self.room:findPlayerBySkillName("huoshou") --“祸首”
	for _, acard in ipairs(cards) do
		if acard:isKindOf("Nullification") then
			null_num = null_num + 1
		end
	end
	if null_card then null_card = sgs.Card_Parse(null_card) else return nil end --没有无懈可击
	if (from and from:isDead()) or (to and to:isDead()) then return nil end --已死
	if self.player:hasSkill("wumou") and self.player:getMark("@wrath") == 0 and (self:isWeak() or self.player:isLord()) then return nil end

	if trick:isKindOf("FireAttack") and (to:isKongcheng() or from:isKongcheng()) then return nil end
	if ("snatch|dismantlement"):match(trick:objectName()) and to:isAllNude() then return nil end
	
	if self:isFriend(to) and to:hasFlag("will_wake") then return end
	
	if from and not from:hasSkill("jueqing") then
		if (to:hasSkill("wuyan") or (self:getDamagedEffects(to, from) and self:isFriend(to)))
			and (trick:isKindOf("Duel") or trick:isKindOf("FireAttack") or trick:isKindOf("AOE")) then
		return nil
	end --“绝情”“无言”、决斗、火攻、AOE
		if not self:damageIsEffective(to, sgs.DamageStruct_Normal) and (trick:isKindOf("Duel") or trick:isKindOf("AOE")) then return nil end --决斗、AOE
		if not self:damageIsEffective(to, sgs.DamageStruct_Fire) and trick:isKindOf("FireAttack") then return nil end --火攻
	end 
	if self:needToLoseHp(to, from) and self:isFriend(to)
		and (trick:isKindOf("Duel") or trick:isKindOf("FireAttack") or trick:isKindOf("AOE")) then
		return nil --扣减体力有利
	end
	--准备使用无懈可击--
	if positive then
		if ("snatch|dismantlement"):match(trick:objectName()) and not to:containsTrick("YanxiaoCard") and (to:containsTrick("indulgence") or to:containsTrick("supply_shortage")) then
			if self:isEnemy(from) then return null_card end
			if self:isFriend(to) and to:isNude() then return nil end
		end
		
		if from and self:isEnemy(from) and (sgs.evaluateRoleTrends(from) ~= "neutral" or sgs.isRolePredictable()) then
			--使用者是敌方，自己有技能“空城”且无懈可击为最后一张手牌->命中
			if self:hasSkill("kongcheng") and self.player:getHandcardNum() == 1 and self.player:isLastHandCard(null_card) and trick:isKindOf("SingleTargetTrick") then
				return null_card
			end
			--敌方在虚弱、需牌技、漫卷中使用无中生有->命中
			if trick:isKindOf("ExNihilo") and (self:isWeak(from) or self:hasSkills(sgs.cardneed_skill, from) or from:hasSkill("manjuan")) then return null_card end
			--铁索连环的目标没有藤甲->不管
			if trick:isKindOf("IronChain") and not self:isEquip("Vine", to) then return nil end
			if self:isFriend(to) then
				if trick:isKindOf("Dismantlement") then 
					--敌方拆友方威胁牌、价值牌、最后一张手牌->命中
					if self:getDangerousCard(to) or self:getValuableCard(to) then return null_card end
					if to:getHandcardNum() == 1 and not self:needKongcheng(to) then
						if (getKnownCard(to, "TrickCard", false) == 1 or getKnownCard(to, "EquipCard", false) == 1 or getKnownCard(to, "Slash", false) == 1) then
							return nil
						end
						return null_card
					end
				else
					--敌方使用顺手牵羊->命中
					if trick:isKindOf("Snatch") then return null_card end
					--非无言敌方火攻藤甲、狂风、铁索连环友方->命中
					if trick:isKindOf("FireAttack") and (self:isEquip("Vine", to) or to:getMark("@gale") > 0 or (to:isChained() and not self:isGoodChainTarget(to))) 
						and from:objectName() ~= to:objectName() and not from:hasSkill("wuyan") then return null_card end
					if self:isWeak(to)  then
						--非无言敌方决斗虚弱友方->命中
						if trick:isKindOf("Duel") and not from:hasSkill("wuyan") then
							return null_card
						--非无言多手牌敌方火攻虚弱友方->命中
						elseif trick:isKindOf("FireAttack") and not from:hasSkill("wuyan") then
							if from:getHandcardNum() > 2  and from:objectName() ~= to:objectName() then return null_card end
						end
					end
				end
			elseif self:isEnemy(to) then
				--敌方顺手牵羊、过河拆桥敌方判定区延时性锦囊->命中
				if (trick:isKindOf("Snatch") or trick:isKindOf("Dismantlement")) and to:getCards("j"):length() > 0 then
					return null_card
				end
			end
		end

		if self:isFriend(to) then
			if not (to:hasSkill("guanxing") and global_room:alivePlayerCount() > 4) then 
				--无观星友方判定区有乐不思蜀->视“突袭”、“巧变”情形而定
				if trick:isKindOf("Indulgence") then
					if to:getHp() - to:getHandcardNum() >= 2 then return nil end
					if to:hasSkill("tuxi") and to:getHp() > 2 then return nil end
					if to:hasSkill("qiaobian") and not to:isKongcheng() then return nil end
					return null_card
				end
				--无观星友方判定区有兵粮寸断->视“鬼道”、“天妒”、“溃围”、“巧变”情形而定
				if trick:isKindOf("SupplyShortage") then
					if self:hasSkills("guidao|tiandu",to) then return nil end
					if to:getMark("@kuiwei") == 0 then return nil end
					if to:hasSkill("qiaobian") and not to:isKongcheng() then return nil end
					return null_card
				end
			end 
			--非无言来源使用多目标攻击性非延时锦囊
			if trick:isKindOf("AOE") and not (from:hasSkill("wuyan") and not (menghuo and trick:isKindOf("SavageAssault"))) then
				local lord = getLord(self.player)
				local currentplayer = self.room:getCurrent()
				--主公
				if lord and self:isFriend(lord) and self:isWeak(lord) and self:aoeIsEffective(trick, lord) and 
					((lord:getSeat() - currentplayer:getSeat()) % (self.room:alivePlayerCount())) >
					((to:getSeat() - currentplayer:getSeat()) % (self.room:alivePlayerCount()))	and not
					(self.player:objectName() == to:objectName() and self.player:getHp() == 1 and not self:canAvoidAOE(trick)) then
					return nil
				end
				--自己
				if self.player:objectName() == to:objectName() then
					if self:hasSkills("jieming|yiji|guixin", self.player) and 
						(self.player:getHp() > 1 or self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then
						return nil
					elseif not self:canAvoidAOE(trick) then
						return null_card
					end
				end
				--队友
				if self:isWeak(to) and self:aoeIsEffective(trick, to) then
					if ((to:getSeat() - currentplayer:getSeat()) % (self.room:alivePlayerCount())) >
					((self.player:getSeat() - currentplayer:getSeat()) % (self.room:alivePlayerCount())) or null_num > 1 then
						return null_card
					elseif self:canAvoidAOE(trick) or self.player:getHp() > 1 or (isLord(to) and self.role == "loyalist") then
						return null_card
					end
				end
			end
			--非无言来源对自己使用决斗
			if trick:isKindOf("Duel") and not from:hasSkill("wuyan") then
				if self.player:objectName() == to:objectName() then
					if self:hasSkills(sgs.masochism_skill, self.player) and 
						(self.player:getHp() > 1 or self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then
						return nil
					elseif self:getCardsNum("Slash") == 0 then
						return null_card
					end
				end
			end
		end
		--虚弱敌方遇到桃园结义->命中
		if from then
			if self:isEnemy(to) then
				if trick:isKindOf("GodSalvation") and self:isWeak(to) then
					return null_card
				end
			end
		end
		
		--五谷：目前只无邪桃子和无中，其他情况待补充
		if trick:isKindOf("AmazingGrace") and self:isEnemy(to) then
			local NP = to:getNextAlive()
			if self:isFriend(NP) then
				local ag_ids = self.room:getTag("AmazingGrace"):toStringList()
				local peach_num, exnihilo_num, snatch_num, analeptic_num, crossbow_num = 0, 0, 0, 0, 0
				for _, ag_id in ipairs(ag_ids) do
					local ag_card = sgs.Sanguosha:getCard(ag_id)
					if ag_card:isKindOf("Peach") then peach_num = peach_num + 1 end
					if ag_card:isKindOf("ExNihilo") then exnihilo_num = exnihilo_num + 1 end
					if ag_card:isKindOf("Snatch") then snatch_num = snatch_num + 1 end
					if ag_card:isKindOf("Analeptic") then analeptic_num = analeptic_num + 1 end
					if ag_card:isKindOf("Crossbow") then crossbow_num = crossbow_num + 1 end
				end
				if (peach_num == 1 and to:getHp() < getBestHp(to)) or
					(peach_num > 0 and self:isWeak(to)) or
					(NP:getHp() < getBestHp(NP) and self:getOverflow(NP) < 1) then
					return null_card
				end
				if peach_num == 0 and not self:willSkipPlayPhase(NP) then
					if exnihilo_num > 0 then
						if self:hasSkills("jizhi|rende|zhiheng", NP) or NP:hasSkill("jilve") and NP:getMark("@bear") > 0 then return null_card end
					else
						for _, enemy in ipairs(self.enemies) do
							if snatch_num > 0 and to:distanceTo(enemy) == 1 and
								(self:willSkipPlayPhase(enemy, true) or self:willSkipDrawPhase(enemy, true)) then
								return null_card
							elseif analeptic_num > 0 and (self:isEquip("Axe", enemy) or self:getCardsNum("Axe", enemy) > 0) then
								return null_card
							elseif crossbow_num > 0 and getCardsNum("Slash", enemy) >= 3 then
								local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								for _, friend in ipairs(self.friends) do
									if enemy:distanceTo(friend) == 1 and self:slashIsEffective(slash, friend, nil, enemy) then
										return null_card
									end
								end
							end
						end
					end
				end
			end
		end
		
	else
		if from then
			if from:objectName() == to:objectName() then
				if self:isFriend(from) then return null_card else return end
			end
			if not (trick:isKindOf("GlobalEffect") or trick:isKindOf("AOE")) then
				if self:isFriend(from) then
					if ("snatch|dismantlement"):match(trick:objectName()) and to:isNude() then
					elseif trick:isKindOf("FireAttack") and to:isKongcheng() then
					else return null_card end
				end
			end
		else
			if self:isEnemy(to) and (sgs.evaluateRoleTrends(to) ~= "neutral" or sgs.isRolePredictable()) then return null_card else return end
		end
	end
end

function SmartAI:getCardRandomly(who, flags)
	local cards = who:getCards(flags)
	if cards:isEmpty() then return end
	local r = math.random(0, cards:length()-1)
	local card = cards:at(r)
	if who:hasArmorEffect("SilverLion") then
		if self:isEnemy(who) and who:isWounded() and card == who:getArmor() then
			if r ~= (cards:length()-1) then
				card = cards:at(r+1)
			elseif r > 0 then
				card = cards:at(r-1)
			end
		end
	end
	return card:getEffectiveId()
end

function SmartAI:askForCardChosen(who, flags, reason)
	self.room:output(reason)
	local cardchosen = sgs.ai_skill_cardchosen[string.gsub(reason,"%-","_")]
	local card
	if type(cardchosen) == "function" then
		card = cardchosen(self, who, flags)
		if card then return card:getEffectiveId() end
	elseif type(cardchosen) == "number" then
		sgs.ai_skill_cardchosen[string.gsub(reason, "%-", "_")] = nil
		for _, acard in sgs.qlist(who:getCards(flags)) do
			if acard:getEffectiveId() == cardchosen then return cardchosen end
		end
	end
	
	if ("snatch|dismantlement"):match(reason) then
		for _, card in sgs.qlist(who:getCards(flags)) do
			if card:hasFlag(reason) then
				self.room:setCardFlag(card, "-" .. reason)
				return card:getId()
			end
		end
	end	

	if self:isFriend(who) then
		if flags:match("j") and not who:containsTrick("YanxiaoCard") and not (who:hasSkill("qiaobian") and who:getHandcardNum() > 0) then
			local tricks = who:getCards("j")
			local lightning, indulgence, supply_shortage
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Lightning") then
					lightning = trick:getId()
				elseif trick:isKindOf("Indulgence") or trick:getSuit() == sgs.Card_Diamond then
					indulgence = trick:getId()
				elseif not trick:isKindOf("Disaster") then
					supply_shortage = trick:getId()
				end
			end

			if self:hasWizard(self.enemies) and lightning then
				return lightning
			end

			if indulgence and supply_shortage then
				if who:getHp() < who:getHandcardNum() then
					return indulgence
				else
					return supply_shortage
				end
			end

			if indulgence or supply_shortage then
				return indulgence or supply_shortage
			end
		end

		if flags:match("e") then
			if self:needToThrowArmor(who) then return who:getArmor():getId() end
			if self:evaluateArmor(who:getArmor(), who) < -5 then return who:getArmor():getId() end
			if self:hasSkills(sgs.lose_equip_skill, who) then
				if who:getWeapon() then return who:getWeapon():getId() end
				if who:getArmor() and who:getArmor():isKindOf("Vine") then return who:getArmor():getId() end
				if who:getOffensiveHorse() then return who:getOffensiveHorse():getId() end
				if who:getArmor() then return who:getArmor():getId() end
				if who:getDefensiveHorse() then return who:getDefensiveHorse():getId() end
			end
		end
	else
		if flags:match("j") then
			local tricks = who:getCards("j")
			local lightning, yanxiao
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Lightning") then
					lightning = trick:getId()
				elseif trick:isKindOf("YanxiaoCard") then
					yanxiao = trick:getId()
				end
			end
			if self:hasWizard(self.enemies, true) and lightning then
				return lightning
			end
			if yanxiao then
				return yanxiao
			end
		end
		if flags:match("e") and self:getDangerousCard(who) then return self:getDangerousCard(who) end
		if flags:match("e") and who:getArmor() and who:getArmor():isKindOf("EightDiagram") then return who:getArmor():getId() end

		if flags:match("e") and self:hasSkills("jijiu|qingnang|qiaobian|jieyin|nosmiji|beige|fanjian|neofanjian|tuxi|" ..
		  "buyi|weimu|anxu|guzheng|tongxin|xiliang|chouliang|shouye|qixi|yinling|noswuyan|manjuan", who) and not self:doNotDiscard(who, "e") then
			if who:getDefensiveHorse() then return who:getDefensiveHorse():getId() end
			if who:getArmor() and not self:needToThrowArmor(who) then
				return who:getArmor():getId()
			end
			if who:getOffensiveHorse() and ((who:getOffensiveHorse():isRed() and who:hasSkill("jijiu")) or who:hasSkill("beige")) then
				return who:getOffensiveHorse():getId()
			end
			if who:getWeapon() and ((who:getWeapon():isRed() and who:hasSkill("jijiu")) or who:hasSkill("beige")) then
				return who:getWeapon():getId()
			end
		end
		if flags:match("h") then
			if self:hasSkills("jijiu|qingnang|qiaobian|jieyin|beige|buyi|manjuan", who)
			  and not who:isKongcheng() and who:getHandcardNum() <= 2 and not self:doNotDiscard(who, "h") then 
				return self:getCardRandomly(who, "h") 
			end
			local cards = sgs.QList2Table(who:getHandcards())
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), who:objectName())
			if #cards <= 2 and not self:doNotDiscard(who, "h") then
				for _, cc in ipairs(cards) do
					if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
						return self:getCardRandomly(who, "h")
					end
				end
			end
		end

		if flags:match("e") then
			if self:getValuableCard(who) then
				return self:getValuableCard(who)
			end
		end

		if flags:match("h") and not self:doNotDiscard(who, "h") then
			if who:getHandcardNum() == 1 and sgs.getDefenseSlash(who) < 3 and who:getHp() <= 2 then
				return self:getCardRandomly(who, "h")
			end
			if self:hasSkills(sgs.cardneed_skill, who) then
				return self:getCardRandomly(who, "h")
			end
		end	

		if flags:match("e") and not self:doNotDiscard(who, "e") then
			if who:getOffensiveHorse() then return who:getOffensiveHorse():getId() end
			if who:getArmor() and not self:needToThrowArmor(who) then return who:getArmor():getId() end
			if who:getOffensiveHorse() then return who:getOffensiveHorse():getId() end
			if who:getWeapon() then return who:getWeapon():getId() end
		end

		if flags:match("h") then
			if (not who:isKongcheng() and who:getHandcardNum() <= 2) and not self:doNotDiscard(who, "h") then
				return self:getCardRandomly(who, "h")
			end
		end
	end
	local new_flag = ""
	if flags:match("h") then new_flag = "h" end
	if flags:match("e") then new_flag = new_flag.."e" end
	return self:getCardRandomly(who, new_flag) or who:getCards(flags):first():getEffectiveId()
end

function sgs.ai_skill_cardask.nullfilter(self, data, pattern, target)
	local effect = data:toSlashEffect()
	local damage_nature
	if self.player:isDead() then return "." end

	if effect and effect.slash then
		damage_nature = effect.nature
		if effect.slash:hasFlag("nosjiefan-slash") then
			local dying = self.room:getTag("NosJiefanTarget"):toDying()
			local handang = self.room:findPlayerBySkillName("nosjiefan")
			if self:isFriend(dying.who) and not self:isEnemy(handang) then return "." end
		end
	end	
	if effect and self:hasHeavySlashDamage(target, effect.slash, self.player) then return end
	if target and target:hasSkill("jueqing") and self:needToLoseHp() then return "." end
	if target and target:hasSkill("jueqing") then return end
	if effect and effect.from and effect.from:hasSkill("nosqianxi") and effect.from:distanceTo(self.player) == 1 then return end	
	if not self:damageIsEffective(nil, damage_nature, target) then return "." end
	if target and target:hasSkill("guagu") and self.player:isLord() then return "." end
	if effect and target and target:hasWeapon("IceSword") and self.player:getCards("he"):length() > 1 then return end	
	if self:getDamagedEffects() or self:needToLoseHp() then return "." end

	if self:needBear() and self.player:getHp() > 2 then return "." end
	if self.player:hasSkill("zili") and not self.player:hasSkill("paiyi") and self.player:getLostHp() < 2 then return "." end
	if self.player:hasSkill("wumou") and self.player:getMark("@wrath") < 7 and self.player:getHp() > 2 then return "." end
	if self.player:hasSkill("tianxiang") then
		local dmgStr = {damage = 1, nature = damage_nature or sgs.DamageStruct_Normal}
		local willTianxiang = sgs.ai_skill_use["@@tianxiang"](self, dmgStr)
		if willTianxiang ~= "." then return "." end
	elseif self.player:hasSkill("longhun") and self.player:getHp() > 1 then
		return "."
	end
end

function SmartAI:askForCard(pattern, prompt, data)
	self.room:output(prompt)
	local target, target2
	local parsedPrompt = prompt:split(":")
	local players
	if parsedPrompt[2] then
		local players = self.room:getPlayers()
		players = sgs.QList2Table(players)
		for _, player in ipairs(players) do
			if player:getGeneralName() == parsedPrompt[2] or player:objectName() == parsedPrompt[2] then target = player break end
		end
		if parsedPrompt[3] then
			for _, player in ipairs(players) do
				if player:getGeneralName() == parsedPrompt[3] or player:objectName() == parsedPrompt[3] then target2 = player break end
			end
		end
	end
	if self.player:hasSkill("hongyan") then
		local card
		if (pattern == ".S" or pattern == "..S") then return "."
		elseif pattern == "..H" then card = self.lua_ai:askForCard(".|spade,heart", prompt, data)
		elseif pattern == ".H" then card = self.lua_ai:askForCard(".|spade,heart|.|hand", prompt, data) end
		if card then return card:toString() end
	end
	local callback = sgs.ai_skill_cardask[parsedPrompt[1]]
	if type(callback) == "function" then
		local ret = callback(self, data, pattern, target, target2)
		if ret then return ret end
	end
	
	local card
	if pattern == "slash" then
		card= sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) or self:getCardId("Slash") or "."		
		if card=="." then sgs.card_lack[self.player:objectName()]["Slash"] = 1 end
	elseif pattern == "jink" then
		card= sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) or self:getCardId("Jink") or "."
		if card=="." then sgs.card_lack[self.player:objectName()]["Jink"] = 1 end
	end
	return card
end

function SmartAI:askForUseCard(pattern, prompt, method)
	local use_func = sgs.ai_skill_use[pattern]
	if use_func then
		return use_func(self, prompt, method) or "."
	else
		return "."
	end
end

function SmartAI:askForAG(card_ids, refusable, reason)
	if reason == "#guzheng-get" then reason = "guzheng" end
	local cardchosen = sgs.ai_skill_askforag[string.gsub(reason, "%-", "_")]
	if type(cardchosen) == "function" then
		local card_id = cardchosen(self, card_ids)
		if card_id then return card_id end
	end

	if refusable and self:hasSkill("xinzhan") then
		local next_player = self.player:getNextAlive()
		if self:isFriend(next_player) and next_player:containsTrick("indulgence") then
			if #card_ids == 1 then return -1 end
		end
		for _, card_id in ipairs(card_ids) do
			return card_id
		end
		return -1
	end
	local ids = card_ids
	local cards = {}
	for _, id in ipairs(ids) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Peach") then return card:getEffectiveId() end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Indulgence") and not (self:isWeak() and self:getCardsNum("Jink") == 0) then return card:getEffectiveId() end
		if card:isKindOf("AOE") and not (self:isWeak() and self:getCardsNum("Jink", self.player) == 0) then return card:getEffectiveId() end
	end
	self:sortByCardNeed(cards)
	return cards[#cards]:getEffectiveId()
end

function SmartAI:askForCardShow(requestor, reason)
	local func = sgs.ai_cardshow[reason]
	if func then
		return func(self, requestor)
	else
		return self.player:getRandomHandCard()
	end
end

function sgs.ai_cardneed.bignumber(to, card, self)
	if not self:willSkipPlayPhase(to) and self:getUseValue(card) < 6 then
		return card:getNumber() > 10
	end
end

function sgs.ai_cardneed.equip(to, card, self)
	if not self:willSkipPlayPhase(to) then
		return card:getTypeId() == sgs.Card_Equip
	end
end

function sgs.ai_cardneed.weapon(to, card, self)
	if not self:willSkipPlayPhase(to) then
		return card:isKindOf("Weapon")
	end
end

function SmartAI:getEnemyNumBySeat(from, to)
	local players = sgs.QList2Table(self.room:getAlivePlayers())
	local to_seat = (to:getSeat() - from:getSeat()) % #players
	local enemynum = 0
	for _, p in ipairs(players) do
		if self:isEnemy(from, p) and ((p:getSeat() - from:getSeat()) % #players) < to_seat then			 
			enemynum = enemynum + 1 
		end
	end
	return enemynum
end

function SmartAI:getFriendNumBySeat(from, to)
	local players = sgs.QList2Table(self.room:getAlivePlayers())
	local to_seat = (to:getSeat() - from:getSeat()) % #players
	local friendnum = 0
	for _, p in ipairs(players) do
		if self:isFriend(from, p) and ((p:getSeat() - from:getSeat()) % #players) < to_seat then			 
			friendnum = friendnum + 1 
		end
	end
	return friendnum
end

function SmartAI:hasHeavySlashDamage(from, slash, to, getValue)
	from = from or self.room:getCurrent()
	slash = slash or self:getCard("Slash", from)
	to = to or self.player
	if not from or not to then self.room:writeToConsole(debug.traceback()) return false end
	if not from:hasSkill("jueqing") and (to:hasArmorEffect("SilverLion") and not IgnoreArmor(from, to)) then return false end
	local dmg = 1
	local fireSlash = slash and (slash:isKindOf("FireSlash") or 
		(slash:objectName() == "slash" and (from:hasWeapon("Fan") or (from:hasSkill("lihuo") and not self:isWeak(from))))) 
	local thunderSlash = slash and slash:isKindOf("ThunderSlash")
	local jinxuandi = self.room:findPlayerBySkillName("wuling")

	if jinxuandi and jinxuandi:getMark("@fire") > 0 then
		fireSlash = true
		thunderSlash = false
	end

	if (slash and slash:hasFlag("drank")) or from:hasFlag("drank") then dmg = dmg + 1 end
	if from:hasFlag("luoyi") then dmg = dmg + 1 end
	if from:hasFlag("neoluoyi") then dmg = dmg + 1 end	
	if slash and from:hasSkill("jie") and slash:isRed() then dmg = dmg + 1 end
	if slash and from:hasSkill("wenjiu") and slash:isBlack() then dmg = dmg + 1 end
	if slash and from:hasFlag("shenli") and from:getMark("@struggle") > 0 then dmg = dmg + math.min(3, from:getMark("@struggle")) end
	
	if not from:hasSkill("jueqing") then		
		if to:hasArmorEffect("Vine") and not IgnoreArmor(from, to) and fireSlash then dmg = dmg + 1 end
		if to:getMark("@gale") > 0 and fireSlash then dmg = dmg + 1 end
		if fireSlash and jinxuandi and jinxuandi:getMark("@wind") > 0 then dmg = dmg + 1 end
		if thunderSlash and jinxuandi and jinxuandi:getMark("@thunder") > 0 then dmg = dmg + 1 end
		if from:hasWeapon("GudingBlade") and slash and to:isKongcheng() then dmg = dmg + 1 end	
		if from:hasSkill("jieyuan") and to:getHp() >= from:getHp() and from:getHandcardNum() >= 3 then dmg = dmg + 1 end	
		if to:hasSkill("jieyuan") and from:getHp() >= to:getHp()	
			and (to:getHandcardNum() > 3 or (getKnownCard(to, "heart") + getKnownCard(to, "diamond")) > 0)
		then
			dmg = dmg - 1
		end
		if (fireSlash or thunderSlash) and jinxuandi and jinxuandi:getMark("@earth") > 0 and dmg > 1 then dmg = 1 end
	end
	if getValue then return dmg end
	return (dmg > 1)
end

function SmartAI:needKongcheng(player, keep)
	player = player or self.player
	if keep then
		return player:isKongcheng() and (player:hasSkill("kongcheng") or (player:hasSkill("zhiji") and player:getMark("zhiji") == 0))
	end

	if player:hasSkill("beifa") and not player:isKongcheng() then
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, to in ipairs(self:getEnemies(player)) do
			if player:canSlash(to, slash) and not self:slashProhibit(slash, to)
			  and self:slashIsEffective(slash, to) and not self:getDamagedEffects(to, player, true) 
			  and not self:needToLoseHp(to, player, true, true) then
				return true
			end
		end
	end
	if not self:hasLoseHandcardEffective() and not player:isKongcheng() then return true end
	if player:hasSkill("zhiji") and player:getMark("zhiji") == 0 then return true end
	if player:hasSkill("shude") and player:getPhase() == sgs.Player_Play then return true end
	return self:hasSkills(sgs.need_kongcheng, player)
end

function SmartAI:getLeastHandcardNum(player)
	player = player or self.player
	local least = 0
	if player:hasSkill("lianying") and least < 1 then least = 1 end
	if player:hasSkill("shangshi") and least < math.min(2, player:getLostHp()) then least = math.min(2, player:getLostHp()) end
	if player:hasSkill("nosshangshi") and least < player:getLostHp() then least = player:getLostHp() end
	return least
end

function SmartAI:hasLoseHandcardEffective(player)
	player = player or self.player
	return player:getHandcardNum() > self:getLeastHandcardNum(player)
end

function SmartAI:hasCrossbowEffect(player)
	player = player or self.player
	return player:hasWeapon("Crossbow") or player:hasSkill("paoxiao")
end

function SmartAI:getCardNeedPlayer(cards)
	cards = cards or sgs.QList2Table(self.player:getHandcards())

	local cardtogivespecial = {}
	local specialnum = 0
	local keptslash = 0
	local friends={}
	local cmpByAction = function(a,b)
		return a:getRoom():getFront(a, b):objectName() == a:objectName()
	end

	local cmpByNumber = function(a,b)
		return a:getNumber() > b:getNumber()
	end


	for _,player in ipairs(self.friends_noself) do
		local exclude = self:needKongcheng(player, true) or (player:containsTrick("indulgence") and not player:containsTrick("YanxiaoCard"))
		if self:hasSkills("keji|qiaobian|conghui|shensu|jisu",player) or player:getHp() - player:getHandcardNum() >= 3 or (isLord(player) 
				and self:isWeak(player) and self:getEnemyNumBySeat(self.player,player)>=1 ) then
			exclude = false
		end
		if not player:hasSkill("manjuan") and not exclude then
			table.insert(friends, player)
		end
	end

	-- special move between liubei and xunyu and huatuo
	for _,player in ipairs(friends) do		
		if player:hasSkill("jieming") or player:hasSkill("jijiu") then
			specialnum = specialnum + 1
		end
	end
	if specialnum > 1 and #cardtogivespecial == 0 and self.player:hasSkill("rende") and self.player:getPhase() == sgs.Player_Play then
		local xunyu = self.room:findPlayerBySkillName("jieming")
		local huatuo = self.room:findPlayerBySkillName("jijiu")
		local no_distance = self.slash_distance_limit
		local redcardnum = 0
		for _,acard in ipairs(cards) do
			if isCard("Slash",acard, self.player) then
				if self.player:canSlash(xunyu, nil, not no_distance) and self:slashIsEffective(acard, xunyu) then
					keptslash = keptslash + 1
				end
				if keptslash > 0 then
					table.insert(cardtogivespecial,acard)
				end
			elseif isCard("Duel",acard, self.player) then
				table.insert(cardtogivespecial,acard)
			end
		end
		for _, hcard in ipairs(cardtogivespecial) do
			if hcard:isRed() then redcardnum = redcardnum + 1 end
		end
		if self.player:getHandcardNum() > #cardtogivespecial and redcardnum > 0 then
			for _, hcard in ipairs(cardtogivespecial) do
				if hcard:isRed() then return hcard, huatuo end
				return hcard, xunyu
			end
		end
	end

	-- keep a jink
	local cardtogive = {}
	local keptjink = 0
	for _,acard in ipairs(cards) do
		if isCard("Jink",acard, self.player) and keptjink < 1 then
			keptjink = keptjink+1
		else
			table.insert(cardtogive,acard)
		end
	end

	-- weak
	self:sort(friends, "defense")
	for _, friend in ipairs(friends) do		
		if self:isWeak(friend) and friend:getHandcardNum() < 3  then
			for _, hcard in ipairs(cards) do
				if isCard("Peach",hcard,friend) or (isCard("Jink",hcard,friend) and self:getEnemyNumBySeat(self.player,friend)>0) or isCard("Analeptic",hcard,friend) then
					return hcard, friend
				end
			end
		end
	end

	if (self.player:hasSkill("rende") and self.player:isWounded() and self.player:usedTimes("RendeCard") < 2) then 
		if (self.player:getHandcardNum() < 2 and self.player:usedTimes("RendeCard") == 0) then
			return
		end
		if ((self.player:getHandcardNum() == 2 and self.player:usedTimes("RendeCard") == 0) or
			(self.player:getHandcardNum() == 1 and self.player:usedTimes("RendeCard") == 1)) and self:getOverflow() <= 0 then
			for _, enemy in ipairs(self.enemies) do
				if self:isEquip("GudingBlade", enemy) and 
				(enemy:canSlash(self.player) or enemy:hasSkill("shensu") or enemy:hasSkill("wushen") or enemy:hasSkill("jiangchi")) then return end
				if enemy:canSlash(self.player, nil, true) and enemy:hasSkill("nosqianxi") and enemy:distanceTo(self.player) == 1 then return end
			end
						
		end

	end

	-- Armor,DefensiveHorse
	for _, friend in ipairs(friends) do		
		if friend:getHp()<=2 and friend:faceUp() then
			for _, hcard in ipairs(cards) do
				if (hcard:isKindOf("Armor") and not friend:getArmor() and not self:hasSkills("yizhong|bazhen",friend)) 
							or (hcard:isKindOf("DefensiveHorse") and not friend:getDefensiveHorse()) then
					return hcard, friend
				end
			end
		end
	end
	
	-- jijiu, jieyin
	self:sortByUseValue(cards, true)
	for _, friend in ipairs(friends) do
		if self:hasSkills("jijiu|jieyin",friend) and friend:getHandcardNum() < 4 then
			for _, hcard in ipairs(cards) do
				if (hcard:isRed() and friend:hasSkill("jijiu")) or friend:hasSkill("jieyin") then
					return hcard, friend
				end
			end
		end
	end	

	--Crossbow
	for _, friend in ipairs(friends) do
		if self:hasSkills("longdan|wusheng|keji",friend) and not self:hasSkills("paoxiao",friend) and friend:getHandcardNum() >=2 then
			for _, hcard in ipairs(cards) do
				if hcard:isKindOf("Crossbow") then
					return hcard, friend
				end
			end
		end
	end	

	for _, friend in ipairs(friends) do
		if getKnownCard(friend, "Crossbow") then
			for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if self:isEnemy(p) and sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) <= 1 then
					for _, hcard in ipairs(cards) do
						if isCard("Slash", hcard, friend) then
							return hcard, friend
						end
					end
				end
			end
		end
	end

	table.sort(friends, cmpByAction)
	
	for _, friend in ipairs(friends) do
		if friend:faceUp() then
			local can_slash = false
			for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if self:isEnemy(p) and sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) <= friend:getAttackRange() then
					can_slash = true
					break
				end
			end
			local flag =string.format("weapon_done_%s_%s",self.player:objectName(),friend:objectName())
			if not can_slash then
				for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
					if self:isEnemy(p) and sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) > friend:getAttackRange() then
						for _, hcard in ipairs(cardtogive) do
							if hcard:isKindOf("Weapon") and friend:distanceTo(p) <= friend:getAttackRange() + (sgs.weapon_range[hcard:getClassName()] or 0) 
									and not friend:getWeapon() and not friend:hasFlag(flag) then
								self.room:setPlayerFlag(friend, flag)
								return hcard, friend 
							end
							if hcard:isKindOf("OffensiveHorse") and friend:distanceTo(p) <= friend:getAttackRange() + 1 
									and not friend:getOffensiveHorse() and not friend:hasFlag(flag) then
								self.room:setPlayerFlag(friend, flag)
								return hcard, friend 
							end
						end
					end
				end
			end

		end
	end

	
	table.sort(cardtogive, cmpByNumber)

	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend, true) and friend:faceUp() then
			for _, hcard in ipairs(cardtogive) do
				for _, askill in sgs.qlist(friend:getVisibleSkillList()) do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if type(callback)=="function" and callback(friend, hcard, self) then
						return hcard, friend
					end
				end
			end
		end
	end
	
		
	-- slash
	if self.role == "lord" and self.player:hasLordSkill("jijiang") then
		for _, friend in ipairs(friends) do
			if friend:getKingdom() == "shu" and friend:getHandcardNum() < 3  then
				for _, hcard in ipairs(cardtogive) do
					if isCard("Slash", hcard, friend) then
						return hcard, friend
					end
				end
			end
		end
	end


	-- kongcheng
	self:sort(self.enemies, "defense")
	if #self.enemies > 0 and self.enemies[1]:isKongcheng() and self:needKongcheng(self.enemies[1], true)
	  and not self.enemies[1]:hasSkill("manjuan") then
		for _,acard in ipairs(cardtogive) do
			if acard:isKindOf("Lightning") or acard:isKindOf("Collateral") or (acard:isKindOf("Slash") and self.player:getPhase() == sgs.Player_Play)
				or acard:isKindOf("OffensiveHorse") or acard:isKindOf("Weapon") or acard:isKindOf("AmazingGrace") then
				return acard, self.enemies[1]
			end
		end
	end

	self:sort(friends, "defense")
	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(self.friends_noself) do
			if not self:needKongcheng(friend, true) and not friend:hasSkill("manjuan") and not self:willSkipPlayPhase(friend)
					and (self:hasSkills(sgs.priority_skill,friend) or (sgs.ai_chaofeng[self.player:getGeneralName()] or 0) > 2) then
				if (self:getOverflow()>0 or self.player:getHandcardNum() > 3) and friend:getHandcardNum() <= 3 then
					return hcard, friend
				end
			end
		end
	end

	self:sort(friends, "handcard")
	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(self.friends_noself) do
			if not self:needKongcheng(friend, true) and not friend:hasSkill("manjuan") then
				if friend:getHandcardNum() <= 3 and (self:getOverflow() > 0 or self.player:getHandcardNum() > 3 
						or (self.player:hasSkill("rende") and self.player:isWounded() and self.player:usedTimes("RendeCard") < 2)) then
					return hcard, friend
				end
			end
		end
	end
	
	-- 如果所有队友都有3牌以上，刘备情愿弃牌也不仁德
	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(self.friends_noself) do
			if not self:needKongcheng(friend, true) and not friend:hasSkill("manjuan") then
				if (self:getOverflow() > 0 or self.player:getHandcardNum() > 3 
						or (self.player:hasSkill("rende") and self.player:isWounded() and self.player:usedTimes("RendeCard") < 2)) then
					return hcard, friend
				end
			end
		end
	end
	
	if self.player:hasSkill("rende") and self.player:usedTimes("RendeCard") < 2 and #cards>0 then
		local need_rende = (sgs.current_mode_players["rebel"] ==0 and sgs.current_mode_players["loyalist"] > 0 and self.player:isWounded()) or 
				(sgs.current_mode_players["rebel"] >0 and sgs.current_mode_players["renegade"] >0 and sgs.current_mode_players["loyalist"] ==0 and self:isWeak())
		if need_rende then
			local players=sgs.QList2Table(self.room:getOtherPlayers(self.player))
			self:sort(players,"defense")
			self:sortByUseValue(cards, true)
			return cards[1], players[1]
		end
	end

end

function SmartAI:askForYiji(card_ids, reason)
	
	if reason then
		local callback = sgs.ai_skill_askforyiji[string.gsub(reason,"%-","_")]
		if type(callback) == "function" then
			local target, cardid = callback(self, card_ids)
			if target and cardid then return target, cardid end
			return nil, -1
		end
	end
	
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	
	local isLirang = self.player:hasFlag("lirang_InTempMoving")
	
	local Shenfen_user
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if player:hasFlag("ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end

	if not isLirang and not Shenfen_user and self.player:getHandcardNum() <= 2 then
		return nil, -1
	end

	local card, friend = self:getCardNeedPlayer(cards)
	if card and friend and not (isLirang and friend:objectName() == self.player:objectName()) and (not Shenfen_user or friend:getHandcardNum() >=4 ) then
		return friend, card:getId()
	end
	
	if #self.friends > 1 then
		self:sort(self.friends, "handcard")
		for _, afriend in ipairs(self.friends) do
			if not (self:needKongcheng(afriend, true) or afriend:hasSkill("manjuan")) and not (isLirang and afriend:objectName() == self.player:objectName())
				and (not Shenfen_user or afriend:getHandcardNum() >=4) then
				for _, acard_id in ipairs(card_ids) do
					return afriend, acard_id
				end
			end
		end
	end
	
	if Shenfen_user and self:isFriend(Shenfen_user) and (not isLirang or Shenfen_user:objectName() ~= self.player:objectName()) then
		for _, id in ipairs(card_ids) do
			return Shenfen_user, id
		end
	end
	
	--All cards should be given out for LiRang
	if isLirang then
		local tos = {}
		for _, target in ipairs(self.friends_noself) do
			if self:isFriend(target) and not (target:hasSkill("manjuan") and target:getPhase() == sgs.Player_NotActive)
				and not self:needKongcheng(target, true) then
				table.insert(tos, target)
			end
		end

		if #tos == 0 then return end
		self:sort(tos, "defense")
		local afriend = tos[1]
		for _, acard_id in ipairs(card_ids) do
			return afriend, acard_id
		end
	end
end

function SmartAI:askForPindian(requestor, reason)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local compare_func = function(a, b)
		return a:getNumber() < b:getNumber()
	end
	table.sort(cards, compare_func)
	local maxcard, mincard, minusecard
	for _, card in ipairs(cards) do
		if self:getUseValue(card) < 6 then mincard = card break end
	end
	for _, card in ipairs(sgs.reverse(cards)) do
		if self:getUseValue(card) < 6 then maxcard = card break end
	end
	self:sortByUseValue(cards, true)
	minusecard = cards[1]
	maxcard = maxcard or minusecard
	mincard = mincard or minusecard
	local callback = sgs.ai_skill_pindian[reason]
	if type(callback) == "function" then
		local ret = callback(minusecard, self, requestor, maxcard, mincard)
		if ret then return ret end
	end
	if self:isFriend(requestor) then return mincard else return maxcard end
end

sgs.ai_skill_playerchosen.damage = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "hp")
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) then return target end
	end
	return targetlist[#targetlist]
end

function SmartAI:askForPlayerChosen(targets, reason)
	self:log("askForPlayerChosen:"..reason)
	local playerchosen = sgs.ai_skill_playerchosen[string.gsub(reason,"%-","_")]
	local target
	if type(playerchosen) == "function" then
		target = playerchosen(self,targets)
	end
	if target then
		return target
	elseif not targets:isEmpty() then
		local r = math.random(0, targets:length() - 1)
		return targets:at(r)
	end
end

function SmartAI:askForSinglePeach(dying)
	local card_str
	local forbid = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
	if self.player:isDead() then return "." end
	if self.player:isLocked(forbid) or dying:isLocked(forbid) then return "." end
	if not sgs.GetConfig("EnableHegemony", false) and self.role == "renegade" and not (dying:isLord() or dying:objectName() == self.player:objectName()) and 
			(sgs.current_mode_players["loyalist"] == sgs.current_mode_players["rebel"] or self.room:getCurrent():objectName() == self.player:objectName()) then
		return "."
	end
	
	if self:isFriend(dying) then
		if self:needDeath(dying) then return "." end

		local lord = getLord(self.player)
		if not sgs.GetConfig("EnableHegemony", false) and self.player:objectName() ~= dying:objectName() and not dying:isLord() and
		(self.role == "loyalist" or self.role == "renegade" and self.room:alivePlayerCount() > 2) and
			((sgs.LordNeedPeach and self:getCardsNum("Peach") <= sgs.LordNeedPeach) or
			(sgs.lord_in_danger_SA and lord and getCardsNum("Slash", lord) < 1 and self:getCardsNum("Peach") < 2) or
			(sgs.lord_in_danger_AA and lord and getCardsNum("Jink", lord) < 1 and self:getCardsNum("Peach") < 2)) then
			return "."
		end
		
		if sgs.turncount > 1 and not dying:isLord() and dying:objectName() ~= self.player:objectName() then
			local possible_friend = 0
			for _, friend in ipairs(self.friends_noself) do
				if (self:getKnownNum(friend) == friend:getHandcardNum() and getCardsNum("Peach", friend) == 0) or
					(self:playerGetRound(friend) < self:playerGetRound(self.player)) or
					(sgs.card_lack[friend:objectName()]["Peach"] == 1) then
				elseif friend:getHandcardNum() > 0 or getCardsNum("Peach", friend) >= 1 then
					possible_friend = possible_friend + 1
				end
			end
			if possible_friend == 0 and #self:getCards("Peach") < 1 - dying:getHp() then
				return "."
			end
		end
		
		local CP = self.room:getCurrent()
		if dying:objectName() ~= lord:objectName() and dying:objectName() ~= self.player:objectName() and lord:getHp() == 1 and
			self:isFriend(lord) and self:isEnemy(CP) and CP:canSlash(lord, nil, true) and getCardsNum("Peach", lord) == 0 and
			getCardsNum("Analeptic",lord) == 0 and #self.friends_noself <= 2 and self:slashIsAvailable(CP) and
			self:damageIsEffective(CP, nil, lord) and self:getCardsNum("Peach") <= self:getEnemyNumBySeat(CP, lord) + 1 then
			return "."
		end
		
		local buqu = dying:getPile("buqu")
		local weaklord = 0
		if not buqu:isEmpty() then
			local same = false
			for i, card_id in sgs.qlist(buqu) do
				for j, card_id2 in sgs.qlist(buqu) do
					if i ~= j and sgs.Sanguosha:getCard(card_id):getNumber() == sgs.Sanguosha:getCard(card_id2):getNumber() then
						same = true
						break
					end
				end
			end
			if not same then return "." end
		end
		if dying:hasFlag("Kurou_toDie") and (not dying:getWeapon() or dying:getWeapon():objectName()~="Crossbow") then return "." end
		if self.player:objectName() ~= dying:objectName() and dying:hasSkill("jiushi") and dying:faceUp() and dying:getHp()== 0 then
			return "."
		end
		if (self.player:objectName() == dying:objectName()) then
			card_str = self:getCardId("Analeptic")
			if not card_str then 
			 card_str = self:getCardId("Peach") end
		elseif dying:isLord() then
			card_str = self:getCardId("Peach")
		elseif self:doNotSave(dying) then return "." 
		else
			for _, friend in ipairs(self.friends_noself) do
				if friend:getHp() == 1 and friend:isLord() and not friend:hasSkill("buqu") then  weaklord = weaklord + 1 end
			end
			for _, enemy in ipairs(self.enemies) do
				if enemy:getHp() == 1 and enemy:isLord() and not enemy:hasSkill("buqu") and self.player:getRole() == "renegade" then weaklord = weaklord + 1 end
			end
			if weaklord < 1 or self:getAllPeachNum() > 1 then
				card_str = self:getCardId("Peach") 
			end
		end
	end
		return card_str or "."
end

function SmartAI:getTurnUse()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local turnUse = {}
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	local slashAvail = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, slash)
	self.predictedRange = self.player:getAttackRange()
	self.predictNewHorse = false
	self.retain_thresh = 5
	self.slash_targets = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, slash)
	self.slash_distance_limit = (1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50)

	self.weaponUsed = false
	if self.player:isLord() then self.retain_thresh = 6 end

	self:fillSkillCards(cards)
	self:sortByUseValue(cards)

	if self:isEquip("Crossbow") then
		slashAvail = 100
	end

	for _,card in ipairs(cards) do
		local dummy_use = {}
		dummy_use.isDummy = true

		local type = card:getTypeId()
		self["use" .. sgs.ai_type_name[type + 1] .. "Card"](self, card, dummy_use)

		if dummy_use.card then
			if card:isKindOf("Slash") then
				if slashAvail > 0 then
					slashAvail = slashAvail-1
					table.insert(turnUse,card)
				end
			else
				if self.player:hasFlag("InfinityAttackRange") or self.player:getMark("InfinityAttackRange") > 0 then
					self.predictedRange = 10000
				elseif card:isKindOf("Weapon") then
					self.predictedRange = sgs.weapon_range[card:getClassName()]
					self.weaponUsed = true
				else
					self.predictedRange = 1
				end
				if card:isKindOf("OffensiveHorse") then self.predictNewHorse = true end
				if card:objectName() == "Crossbow" then slashAvail = 100 end
				table.insert(turnUse,card)
			end
		end
	end

	return turnUse
end

function SmartAI:activate(use)
	self:updatePlayers()
	self:assignKeep(self.player:getHp(),true)
	self.toUse  = self:getTurnUse()
	self:sortByDynamicUsePriority(self.toUse)
	for _, card in ipairs(self.toUse) do
		if not self.player:isJilei(card) and not self.player:isLocked(card) then
			local type = card:getTypeId()
			self["use" .. sgs.ai_type_name[type + 1] .. "Card"](self, card, use)

			if use:isValid(nil) then
				self.toUse = nil
				return
			end
		end
	end
	self.toUse = nil
end

function SmartAI:getOverflow(player, getMaxCards)
	player = player or self.player
	local kingdom_num = 0
	if player:hasSkill("yongsi") then
		local kingdoms = {}
		for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
			if not kingdoms[ap:getKingdom()] then
				kingdoms[ap:getKingdom()] = true
				kingdom_num = kingdom_num + 1
			end
		end
	end
	if getMaxCards then return player:getMaxCards() - kingdom_num end
	return math.max(player:getHandcardNum() + kingdom_num - player:getMaxCards(), 0)
end

function SmartAI:isWeak(player)
	player = player or self.player
	local hcard = player:getHandcardNum()
	if player:hasSkill("longhun") then hcard = player:getCards("he"):length() end
	return ((player:getHp() <= 2 and hcard <= 2) or (player:getHp() <= 1 and not (player:hasSkill("longhun") and hcard > 2))) and not (player:hasSkill("buqu") and player:getPile("buqu"):length() < 4)
end

function SmartAI:useCardByClassName(card, use)
	if not card then global_room:writeToConsole(debug.traceback()) return end
	local class_name = card:getClassName()
	local use_func = self["useCard" .. class_name]

	if use_func then
		use_func(self, card, use)
	end
end

function sgs.getSkillLists(player)
	local slist = player:getVisibleSkillList()
	local vsnlist = {}
	local fsnlist = {}
	for _, askill in sgs.qlist(player:getVisibleSkillList()) do
		if askill:inherits("ViewAsSkill") then table.insert(vsnlist, askill:objectName()) end
		if askill:inherits("FilterSkill") then table.insert(fsnlist, askill:objectName()) end
	end
	return vsnlist, fsnlist
end

function SmartAI:hasWizard(players,onlyharm)
	local skill
	if onlyharm then skill = sgs.wizard_harm_skill else skill = sgs.wizard_skill end
	for _, player in ipairs(players) do
		if self:hasSkills(skill, player) then
			return true
		end
	end
end

function SmartAI:canRetrial(player, to_retrial)
	player = player or self.player
	to_retrial = to_retrial or self.player
	if player:hasSkill("guidao") then
		local blackequipnum = 0
		for _,equip in sgs.qlist(player:getEquips()) do
			if equip:isBlack() then blackequipnum = blackequipnum+1 end
		end
		return (blackequipnum+player:getHandcardNum()) > 0
	elseif player:hasSkill("guicai") then
		return player:getHandcardNum() > 0
	elseif player:hasSkill("jilve") then
		return player:getHandcardNum() > 0 and player:getMark("@bear") > 0
	elseif player:hasSkill("huanshi") then
		return not player:isNude() and (self:isFriend(player, to_retrial) or player:objectName() == to_retrial:objectName())
	end
end

function SmartAI:getFinalRetrial(player) 
	local maxfriendseat = -1
	local maxenemyseat = -1
	local tmpfriend
	local tmpenemy
	player = player or self.room:getCurrent()
	for _, aplayer in ipairs(self.friends) do
		if self:hasSkills(sgs.wizard_harm_skill, aplayer) and self:canRetrial(aplayer, player) then
			tmpfriend = (aplayer:getSeat() - player:getSeat()) % (global_room:alivePlayerCount())
			if tmpfriend > maxfriendseat then maxfriendseat = tmpfriend end
		end
	end
	for _, aplayer in ipairs(self.enemies) do
		if self:hasSkills(sgs.wizard_harm_skill, aplayer) and self:canRetrial(aplayer, player) then
			tmpenemy = (aplayer:getSeat() - player:getSeat()) % (global_room:alivePlayerCount())
			if tmpenemy > maxenemyseat then maxenemyseat = tmpenemy end
		end
	end
	if maxfriendseat == -1 and maxenemyseat == -1 then return 0
	elseif maxfriendseat>maxenemyseat then return 1
	else return 2 end
end

--- Determine that the current judge is worthy retrial
-- @param judge The JudgeStruct that contains the judge information
-- @return True if it is needed to retrial
function SmartAI:needRetrial(judge)  
	local reason = judge.reason
	local lord = getLord(self.player)
	local who = judge.who
	if reason == "lightning" then  
		if self:hasSkills("wuyan|hongyan",who) then return false end

		if lord and (who:isLord() or (who:isChained() and lord:isChained())) and self:objectiveLevel(lord) <= 3 then
			if lord:hasArmorEffect("SilverLion") and lord:getHp() >= 2 and self:isGoodChainTarget(lord) then return false end
			return self:damageIsEffective(lord, sgs.DamageStruct_Thunder) and not judge:isGood()
		end

		if self:isFriend(who) then
			if who:isChained() and self:isGoodChainTarget(who) then return false end
		else
			if who:isChained() and not self:isGoodChainTarget(who) then return judge:isGood() end
		end		
	end

	if reason == "indulgence" then
		if who:isSkipped(sgs.Player_Draw) and who:isKongcheng() then
			if (who:hasSkill("shenfen") and who:getMark("@wrath") >= 6)
				or (who:hasSkill("kurou") and who:getHp() >= 3) 
				or (who:hasSkill("jixi") and who:getPile("field"):length() > 2)
				or (who:hasSkill("lihun") and self:IsLihunTarget(self:getEnemies(who), 0))
				or (who:hasSkill("xiongyi") and who:getMark("@arise") > 0) then
				if self:isFriend(to) then
					return not judge:isGood()
				else
					return judge:isGood()
				end
			end
		end
		if self:isFriend(who) then
			if who:getHp() - who:getHandcardNum() >= 2 then return false end
			if who:hasSkill("tuxi") and who:getHp() > 2 then return false end
			return not judge:isGood()
		else
			return judge:isGood()
		end
	end

	if reason == "supply_shortage" then
		if self:isFriend(who) then
			if self:hasSkills("guidao|tiandu",who) then return false end
			return not judge:isGood()
		else
			return judge:isGood()
		end
	end

	if reason == "luoshen" then
		if self:isFriend(who) then
			if who:getHandcardNum() > 30 then return false end  
			if self:isEquip("Crossbow", who) or getKnownCard(who, "Crossbow", false) > 0 then return not judge:isGood() end
			if self:getOverflow(who) > 1 and self.player:getHandcardNum() < 3 then return false end
			return not judge:isGood()
		else
			return judge:isGood()
		end
	end
	
	if reason == "tuntian" then
		if not who:hasSkill("zaoxian") and who:getMark("zaoxian") == 0 then return false end
	end
	
	if self:isFriend(who) then
		return not judge:isGood()
	elseif self:isEnemy(who) then
		return judge:isGood()
	else
		return false
	end
end

--- Get the retrial cards with the lowest keep value
-- @param cards the table that contains all cards can use in retrial skill
-- @param judge the JudgeStruct that contains the judge information
-- @return the retrial card id or -1 if not found
function SmartAI:getRetrialCardId(cards, judge)
	local can_use = {}
	--judge.reason:shaoying,nosqianxi,qianxi,beige,baonue,tieji,neoganglie,ganglie,caizhaoji_hujia
	local DontRespondPeach
	if judge.reason == "tuntian" and judge.who:getMark("zaoxian") == 0 and judge.who:getPile("field"):length() < 2 then DontRespondPeach = true
	elseif (judge.reason == "EightDiagram" or judge.reason == "bazhen") and
		self:isFriend(judge.who) and not self:isWeak(judge.who) then DontRespondPeach = true
	elseif judge.reason == "nosmiji" and judge.who:getLostHp() == 1 then DontRespondPeach = true
	end
	
	for _, card in ipairs(cards) do
		if self:isFriend(judge.who) and not (card:isKindOf("Peach") and (self:getFinalRetrial() == 2 or DontRespondPeach)) then
			if self.player:hasSkill("hongyan") and not judge.who:hasSkill("hongyan") and sgs.Sanguosha:getEngineCard(card:getId()):getSuit() == sgs.Card_Spade then
				if judge.reason == "indulgence" or judge.reason == "EightDiagram" then
				elseif judge.reason == "luoshen" then
					table.insert(can_use, card)
				end
			elseif judge.who:hasSkill("hongyan") and sgs.Sanguosha:getEngineCard(card:getId()):getSuit() == sgs.Card_Spade and
				(judge.reason == "indulgence" or judge.reason == "EightDiagram") then
				table.insert(can_use, card)
			elseif judge:isGood(card) then
				table.insert(can_use, card)
			end
		elseif self:isEnemy(judge.who) and not (card:isKindOf("Peach") and (self:getFinalRetrial() == 2 or DontRespondPeach)) then
			if judge.who:hasSkill("hongyan") and sgs.Sanguosha:getEngineCard(card:getId()):getSuit() == sgs.Card_Spade and
				(judge.reason == "indulgence" or judge.reason == "EightDiagram") then
			elseif self.player:hasSkill("hongyan") and not judge.who:hasSkill("hongyan") and sgs.Sanguosha:getEngineCard(card:getId()):getSuit() == sgs.Card_Spade then
				if (judge.reason == "indulgence" or judge.reason == "EightDiagram") then					
					table.insert(can_use, card)
				elseif judge.reason == "luoshen" then
				end
			elseif not judge:isGood(card) then
				table.insert(can_use, card)
			end
		end
	end
	if next(can_use) then
		self:sortByKeepValue(can_use)
		return can_use[1]:getEffectiveId()
	else
		return -1
	end
end

function SmartAI:damageIsEffective(to, nature, from)
	to = to or self.player
	from = from or self.room:getCurrent()
	nature = nature or sgs.DamageStruct_Normal
	
	if from:hasSkill("jueqing") then return true end

	local jinxuandi = self.room:findPlayerBySkillName("wuling")
	if jinxuandi and jinxuandi:getMark("@fire") > 0 then nature = sgs.DamageStruct_Fire end

	if to:hasSkill("shenjun") and to:getGender() ~= from:getGender() and nature ~= sgs.DamageStruct_Thunder then
		return false
	end
	if to:getMark("@fenyong") > 0 and to:hasSkill("fenyong")  then
		return false
	end
	if to:getMark("@fog") > 0 and nature ~= sgs.DamageStruct_Thunder then
		return false
	end
	if to:hasSkill("ayshuiyong") and nature == sgs.DamageStruct_Fire then
		return false
	end
	if to:hasSkill("mingshi") and self:isFriend(to, from) and not from:isKongcheng() and not self:hasHeavySlashDamage(from, nil, to) then
		return false
	end
	return true
end

function SmartAI:getDamagedEffects(to, from, slash)
	from = from or self.room:getCurrent()
	to = to or self.player
	if from:hasSkill("jueqing") then return false end
	
	if slash then
		if from:hasSkill("nosqianxi") and from:distanceTo(player) == 1 and not self:isFriend(from, to) then
			return false
		end
		if from:hasWeapon("IceSword") and to:getCards("he"):length() > 1 and not self:isFriend(from, to) then 
			return false
		end
	end	
	if to:hasLordSkill("shichou") then
		return sgs.ai_need_damaged.shichou(self, from, to) == 1
	end

	if self:hasHeavySlashDamage(from) then return false end
	
	if sgs.isGoodHp(to) then
		for _, askill in sgs.qlist(to:getVisibleSkillList()) do
			local callback = sgs.ai_need_damaged[askill:objectName()]
			if type(callback) == "function" and callback(self, from, to) then return true end
		end
	end
	return false	
end

local function prohibitUseDirectly(card, player)
	if player:isLocked(card) or player:isJilei(card) then return true end
	
	local _, flist = sgs.getSkillLists(player)
	for _, askill in ipairs(flist) do
		local callback = sgs.ai_filterskill_filter[askill]
		local card_place = global_room:getCardPlace(card:getEffectiveId())
		if type(callback) == "function" and callback(card, card_place, player) then return true end
	end
	return false
end

local function cardsView(class_name, player)
	local vlist = sgs.getSkillLists(player)
	for _, askill in ipairs(vlist) do
		if player:hasSkill(askill) then
			local callback = sgs.ai_cardsview[askill]
			if type(callback) == "function" and callback(class_name, player) then
				return callback(class_name, player)
			end
		end
	end
end

local function getSkillViewCard(card, class_name, player, card_place)
	local vlist = sgs.getSkillLists(player)
	if player:hasSkill("fuhun") then table.insert(vlist, "fuhun") end
	for _, askill in ipairs(vlist) do
		if player:hasSkill(askill) then
			local callback = sgs.ai_view_as[askill]
			if type(callback) == "function" then
				local skill_card_str = callback(card, player, card_place, class_name)
				if skill_card_str then
					local skill_card = sgs.Card_Parse(skill_card_str)
					if skill_card and skill_card:isKindOf(class_name) and not player:isCardLimited(skill_card, skill_card:getHandlingMethod()) then
						return skill_card_str 
					end
				end
			end
		end
	end
end

local function getFilterSkillViewCard(card, player, card_place)
	local vlist = sgs.getSkillLists(player)
	for _, askill in ipairs(vlist) do
		local skill = sgs.Sanguosha:getSkill(askill)
		if player:hasSkill(askill) and skill and skill:inherits("FilterSkill") then
			local callback = sgs.ai_view_as[askill]
			if type(callback) == "function" then
				local skill_card_str = callback(card, player, card_place, class_name)
				if skill_card_str then
					return sgs.Card_Parse(skill_card_str)
				end
			end
		end
	end
end

function isCard(class_name, card, player)
	if not card then global_room:writeToConsole(debug.traceback()) return false end
	if not player then player = global_room:getCurrent() end
	local cardx = getFilterSkillViewCard(card, player, global_room:getCardPlace(card:getEffectiveId()))
	if cardx and not cardx:isKindOf(class_name) then return false end
	return card:isKindOf(class_name) or getSkillViewCard(card, class_name, player, global_room:getCardPlace(card:getEffectiveId()))
end


function SmartAI:getMaxCard(player)
	player = player or self.player

	if player:isKongcheng() then
		return nil
	end

	local cards = player:getHandcards()
	local max_card, max_point = nil, 0
	for _, card in sgs.qlist(cards) do
		--local flag=string.format("%s_%s_%s","visible",global_room:getCurrent():objectName(),player:objectName())
		--if player:objectName() == self.player:objectName() or card:hasFlag("visible") or card:hasFlag(flag) then
			local point = card:getNumber()
			if point > max_point then
				max_point = point
				max_card = card
			end
		--end
	end

	if self:hasSkills("tianyi|dahe|xianzhen") and max_point > 0 then
		for _, card in sgs.qlist(cards) do
			if 	card:getNumber() == max_point and not isCard("Slash", card, self.player) then
				return card
			end
		end
	end

	return max_card
end

function SmartAI:getMinCard(player)
	player = player or self.player

	if player:isKongcheng() then
		return nil
	end

	local cards = player:getHandcards()
	local min_card, min_point = nil, 14
	for _, card in sgs.qlist(cards) do
		--local flag=string.format("%s_%s_%s","visible",global_room:getCurrent():objectName(),player:objectName())
		--if player:objectName() == self.player:objectName() or card:hasFlag("visible") or card:hasFlag(flag) then
			local point = card:getNumber()
			if point < min_point then
				min_point = point
				min_card = card
			end
		--end
	end

	return min_card
end

function SmartAI:getKnownNum(player)
	player = player or self.player
	if not player then
		return self.player:getHandcardNum()
	else
		local cards = player:getHandcards()
		local known = 0
		for _, card in sgs.qlist(cards) do
			local flag=string.format("%s_%s_%s","visible",global_room:getCurrent():objectName(),player:objectName())
			if card:hasFlag("visible") or card:hasFlag(flag) then
				known = known + 1
			end
		end
		return known
	end
end


function getKnownCard(player, class_name, viewas, flags)
	flags = flags or "h"
	local cards = player:getCards(flags)
	local known = 0
	local suits = {["club"] = 1, ["spade"] = 1, ["diamond"] = 1, ["heart"] = 1}
	for _, card in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", global_room:getCurrent():objectName(), player:objectName())
		local card_place = global_room:getCardPlace(card:getEffectiveId())
		if card:hasFlag("visible") or card:hasFlag(flag) or card_place == sgs.Player_PlaceEquip or player:objectName() == global_room:getCurrent():objectName() then
			if (viewas and isCard(class_name, card, player)) or card:isKindOf(class_name) or 
					(suits[class_name] and card:getSuitString() == class_name) or
					(card:isRed() and class_name == "red") or (card:isBlack() and class_name == "black") then
				known = known + 1 
			end
		end
	end
	return known
end


function SmartAI:getCardId(class_name, player, acard)
	player = player or self.player
	local cards = player:getCards("he")
	cards = sgs.QList2Table(cards)
	if acard then cards = {acard} end
	self:sortByUsePriority(cards,player)
	local guhuo_str = self:getGuhuoCard(class_name, player) 
	if guhuo_str then return guhuo_str end

	local viewArr, cardArr = {}, {}

	for _, card in ipairs(cards) do
		local viewas, cardid
		local card_place = self.room:getCardPlace(card:getEffectiveId())
		viewas = getSkillViewCard(card, class_name, player, card_place)
		if viewas then table.insert(viewArr, viewas) end
		if card:isKindOf(class_name) and not prohibitUseDirectly(card, player) then table.insert(cardArr,card:getEffectiveId()) end		
	end

	if #viewArr >0 or #cardArr > 0 then
		local viewas, cardid
		viewas = #viewArr >0 and viewArr[1]
		cardid = #cardArr >0 and cardArr[1]
		return self:hasSkills("chongzhen|jinjiu", player) and (viewas or cardid) or (cardid or viewas)
	end
	return cardsView(class_name, player)
end

function SmartAI:getCard(class_name, player)
	player = player or self.player
	local card_id = self:getCardId(class_name, player)
	if card_id then return sgs.Card_Parse(card_id) end
end

function getCards(class_name, player, room, flag)
	flag = flag or "he"
	local cards = {}
	local card_place, card_str
	if not room then card_place = sgs.Player_PlaceHand end

	for _, card in sgs.qlist(player:getCards(flag)) do
		card_place = card_place or room:getCardPlace(card:getEffectiveId())

		if class_name == "." then table.insert(cards, card)
		elseif card:isKindOf(class_name) and not prohibitUseDirectly(card, player) then table.insert(cards, card)
		elseif getSkillViewCard(card, class_name, player, card_place) then
			card_str = getSkillViewCard(card, class_name, player, card_place)
			card_str = sgs.Card_Parse(card_str)
			table.insert(cards, card_str)
		end
	end
	return cards
end

function SmartAI:getCards(class_name, player, flag)
	player = player or self.player
	return getCards(class_name, player, self.room, flag)
end

function getCardsNum(class_name, player, self)
	if not player then 
		global_room:writeToConsole(debug.traceback()) 
		return 0
	end
	if self and player:objectName() == self.player:objectName() then return self:getCardsNum(class_name, player) end

	local cards = sgs.QList2Table(player:getHandcards())
	local num = 0
	local shownum = 0
	local redpeach = 0
	local redslash = 0
	local blackcard = 0
	local blacknull = 0
	local equipnull = 0
	local equipcard = 0
	local heartslash = 0
	local heartpeach = 0
	local spadenull = 0
	local spadewine = 0
	local spadecard = 0
	local diamondcard = 0
	local clubcard = 0
	local slashjink = 0
	local current = global_room:getCurrent()

	if not player then
		return #getCards(class_name, player)
	else		
		for _, card in ipairs(cards) do
			local flag = string.format("%s_%s_%s", "visible", current:objectName(), player:objectName())
			if card:hasFlag("visible") or card:hasFlag(flag) or current:objectName() == player:objectName() then
				shownum = shownum + 1
				if card:isKindOf(class_name) then
					num = num + 1
				end
				if card:isKindOf("EquipCard") then
					equipcard = equipcard + 1
				end
				if card:isKindOf("Slash") or card:isKindOf("Jink") then
					slashjink = slashjink + 1
				end
				if card:isRed() then
					if not card:isKindOf("Slash") then
						redslash = redslash + 1
					end
					if not card:isKindOf("Peach") then
						redpeach = redpeach + 1
					end
				end
				if card:isBlack() then
					blackcard = blackcard + 1
					if not card:isKindOf("Nullification") then
						blacknull = blacknull + 1
					end
				end
				if card:getSuit() == sgs.Card_Heart then
					if not card:isKindOf("Slash") then
						heartslash = heartslash + 1
					end
					if not card:isKindOf("Peach") then
						heartpeach = heartpeach + 1
					end
				end
				if card:getSuit() == sgs.Card_Spade then
					if not card:isKindOf("Nullification") then
						spadenull = spadenull + 1
					end
					if not card:isKindOf("Analeptic") then
						spadewine = spadewine + 1
					end		
				end
				if card:getSuit() == sgs.Card_Diamond and not card:isKindOf("Slash") then
					diamondcard = diamondcard + 1
				end
				if card:getSuit() == sgs.Card_Club then
					clubcard = clubcard + 1
				end
			end
		end
	end
	local ecards = player:getCards("e")
	for _, card in sgs.qlist(ecards) do
		equipcard = equipcard + 1
		if player:getHandcardNum() > player:getHp() then
			equipnull = equipnull + 1
		end			
		if card:isRed() then 
			redpeach = redpeach + 1
			redslash = redslash + 1 
		end
		if card:getSuit() == sgs.Card_Heart then
			heartpeach = heartpeach + 1
		end
		if card:getSuit() == sgs.Card_Spade then
			spadecard = spadecard + 1
		end
		if card:getSuit() == sgs.Card_Diamond  then
			diamondcard = diamondcard + 1
		end
		if card:getSuit() == sgs.Card_Club then
			clubcard = clubcard + 1
		end
	end

	if class_name == "Slash" then
		local slashnum
		if player:hasSkill("wusheng") then
			slashnum = redslash + num + (player:getHandcardNum() - shownum) * 0.69
		elseif player:hasSkill("wushen") then
			slashnum = heartslash + num + (player:getHandcardNum() - shownum)*0.5
		elseif player:hasSkill("longhun") then
			slashnum = diamondcard + num + (player:getHandcardNum() - shownum)*0.5
		elseif player:hasSkill("nosgongqi") then
			slashnum = equipcard + num + (player:getHandcardNum() - shownum)*0.5
		elseif player:hasSkill("longdan") then
			slashnum = slashjink + (player:getHandcardNum() - shownum)*0.72
		else
			slashnum = num+(player:getHandcardNum() - shownum)*0.35
		end
		return player:hasSkill("wushuang") and slashnum*2 or slashnum
	elseif class_name == "Jink" then
		if player:hasSkill("qingguo") then 
			return blackcard + num + (player:getHandcardNum() - shownum)*0.85
		elseif player:hasSkill("longdan") then
			return slashjink + (player:getHandcardNum() - shownum)*0.72
		elseif player:hasSkill("longhun") then
			return clubcard + num + (player:getHandcardNum() - shownum)*0.65
		else 
			return num + (player:getHandcardNum() - shownum)*0.6
		end
	elseif class_name == "Peach" then
		if player:hasSkill("jijiu") then
			return num + redpeach + (player:getHandcardNum() - shownum)*0.6
		elseif player:hasSkill("longhun") then
			return num + heartpeach + (player:getHandcardNum() - shownum)*0.5
		elseif player:hasSkill("chunlao") then			
			return num + player:getPile("wine"):length()
		else 
			return num
		end 
	elseif class_name == "Analeptic" then
		if player:hasSkill("jiuchi") then
			return num + spadewine + (player:getHandcardNum() - shownum)*0.3
		elseif player:hasSkill("jiushi") then
			return num + 1
		else
			return num
		end
	elseif class_name == "Nullification" then
		if player:hasSkill("kanpo") then
			return num + blacknull + (player:getHandcardNum() - shownum)*0.5
		elseif player:hasSkill("yanzheng") then
			return num + equipnull
		else
			return num
		end
	else
		return num
	end
end

function SmartAI:getCardsNum(class_name, player, flag, selfonly)
	player = player or self.player
	local n = 0
	if type(class_name) == "table" then
		for _, each_class in ipairs(class_name) do
			n = n + #getCards(each_class, player, self.room, flag)
		end
		return n
	end
	n = #getCards(class_name, player, self.room, flag)

	if selfonly then return n end
	if class_name == "Jink" then
		if player:hasLordSkill("hujia") then
			local lieges = self.room:getLieges("wei", player)
			for _, liege in sgs.qlist(lieges) do
				if self:isFriend(liege, player) then
					n = n + self:getCardsNum("Jink", liege, nil, liege:hasLordSkill("hujia"))
				end
			end
		end
	elseif class_name == "Slash" then
		if player:hasSkill("wushuang") then
			n = n * 2
		end
		if player:hasLordSkill("jijiang") then
			local lieges = self.room:getLieges("shu", player)
			for _, liege in sgs.qlist(lieges) do
				if self:isFriend(liege, player) then
				n = n + self:getCardsNum("Slash", liege, nil, liege:hasLordSkill("jijiang"))
				end
			end
		end
	end
	return n
end

function SmartAI:getAllPeachNum(player)
	player = player or self.player
	local n = 0
	for _, friend in ipairs(self:getFriends(player)) do
		n = n + getCardsNum("Peach", friend)
	end
	return n
end

function SmartAI:getCardsFromDiscardPile(class_name)
	sgs.discard_pile = self.room:getDiscardPile()
	local cards = {}
	for _, card_id in sgs.qlist(sgs.discard_pile) do
		local card = sgs.Sanguosha:getCard(card_id)
		if card:isKindOf(class_name) then table.insert(cards, card) end
	end
	
	return cards
end

function SmartAI:getCardsFromDrawPile(class_name)
	sgs.discard_pile = self.room:getDrawPile()
	local cards = {}
	for _, card_id in sgs.qlist(sgs.discard_pile) do
		local card = sgs.Sanguosha:getCard(card_id)
		if card:isKindOf(class_name) then table.insert(cards, card) end
	end
	
	return cards
end

function SmartAI:getCardsFromGame(class_name)
	local ban = sgs.GetConfig("BanPackages", "")
	local cards = {}
	for i=1, sgs.Sanguosha:getCardCount() do
		local card = sgs.Sanguosha:getCard(i-1)
		if card:isKindOf(class_name) and not ban:match(card:getPackage()) then table.insert(cards, card) end
	end
	
	return cards
end

function SmartAI:getRestCardsNum(class_name, yuji)
	yuji = yuji or self.player
	local ban = sgs.GetConfig("BanPackages", "")
	sgs.discard_pile = self.room:getDiscardPile()
	local totalnum = 0
	local discardnum = 0
	local knownnum = 0
	local card
	for i=1, sgs.Sanguosha:getCardCount() do
		card = sgs.Sanguosha:getEngineCard(i-1)
		-- if card:isKindOf(class_name) and not ban:match(card:getPackage()) then totalnum = totalnum+1 end
		if card:isKindOf(class_name) then totalnum = totalnum + 1 end
	end
	for _, card_id in sgs.qlist(sgs.discard_pile) do
		card = sgs.Sanguosha:getEngineCard(card_id)
		if card:isKindOf(class_name) then discardnum = discardnum + 1 end
	end
	for _, player in sgs.qlist(self.room:getOtherPlayers(yuji)) do
		knownnum = knownnum + getKnownCard(player, class_name)
	end
	return totalnum - discardnum - knownnum
end

function SmartAI:evaluatePlayerCardsNum(class_name, player)
	player = player or self.player
	local length = sgs.draw_pile:length()
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		length = length + p:getHandcardNum()
	end
	
	local percentage = (#(self:getCardsFromGame(class_name)) - #(self:getCardsFromDiscardPile(class_name)))/length
	local modified = 1
	if class_name == "Jink" then modified = 1.23
	elseif class_name == "Analeptic" then modified = 1.17
	elseif class_name == "Peach" then modified = 1.19
	elseif class_name == "Slash" then modified = 1.09
	end
	
	return player:getHandcardNum()*percentage*modified
end

function SmartAI:hasSuit(suit_strings, include_equip, player)
	return self:getSuitNum(suit_strings, include_equip, player) > 0
end

function SmartAI:getSuitNum(suit_strings, include_equip, player)
	player = player or self.player
	local n = 0
	local flag = "h"
	if include_equip then flag = "he" end
	local allcards
	local current= self.room:getCurrent()
	if player:objectName() == current:objectName() then
		allcards = sgs.QList2Table(player:getCards(flag))
	else
		allcards = include_equip and sgs.QList2Table(player:getEquips()) or {}
		local handcards = sgs.QList2Table(player:getHandcards())
		local flag=string.format("%s_%s_%s","visible",current:objectName(),player:objectName())
		for i= 1, #handcards, 1 do
			if handcards[i]:hasFlag("visible") or handcards[i]:hasFlag(flag) then
				table.insert(allcards,handcards[i])
			end
		end
	end
	for _, card in ipairs(allcards) do
		for _, suit_string in ipairs(suit_strings:split("|")) do
			if card:getSuitString() == suit_string then
				n = n + 1
			end
		end
	end
	return n
end

function SmartAI:hasSkill(skill)
	local skill_name = skill
	if type(skill) == "table" then
		skill_name = skill.name
	end

	local real_skill = sgs.Sanguosha:getSkill(skill_name)
	if real_skill and real_skill:isLordSkill() then
		return self.player:hasLordSkill(skill_name)
	else
		return self.player:hasSkill(skill_name)
	end
end

function SmartAI:hasSkills(skill_names, player)
	player = player or self.player
	if type(player) == "table" then
		for _, p in ipairs(player) do
			if self:hasSkills(skill_names, p) then return true end
		end
		return false
	end
	if type(skill_names) == "string" then skill_names = skill_names:split("|") end
	for _, skill_name in ipairs(skill_names) do
		if player:hasSkill(skill_name) then
			return true
		end
	end
	return false
end

function SmartAI:fillSkillCards(cards)
	local i = 1
	while i <= #cards do
		if prohibitUseDirectly(cards[i], self.player) then
			table.remove(cards, i)
		else
			i = i + 1
		end
	end
	for _,skill in ipairs(sgs.ai_skills) do
		if self:hasSkill(skill) then
			local skill_card = skill.getTurnUseCard(self)
			if #cards == 0 then skill_card = skill.getTurnUseCard(self,true) end
			if skill_card then table.insert(cards, skill_card) end
		end
	end
end

function SmartAI:useSkillCard(card,use)
	local name
	if card:isKindOf("LuaSkillCard") then
		name = "#" .. card:objectName()
	else
		name = card:getClassName()
	end
	if not sgs.ai_skill_use_func[name] then return end
	sgs.ai_skill_use_func[name](card, use, self)
	if use.to then
		if not use.to:isEmpty() and sgs.dynamic_value.damage_card[name] then
			for _, target in sgs.qlist(use.to) do
				if self:damageIsEffective(target) then return end
			end
			use.card = nil
		end
	end
end

function SmartAI:useBasicCard(card, use)
	if not card then global_room:writeToConsole(debug.traceback()) return end
	if self.player:hasSkill("chengxiang") and self.player:getHandcardNum() < 8 and card:getNumber() < 7 then return end
	if not (card:isKindOf("Peach") and self.player:getLostHp() > 1) and self:needBear() then return end
	if self:needRende() then return end
	self:useCardByClassName(card, use)
end

function SmartAI:aoeIsEffective(card, to, source)
	local players = self.room:getAlivePlayers()
	players = sgs.QList2Table(players)
	source = source or self.room:getCurrent()

	local armor = to:getArmor()
	if armor and armor:isKindOf("Vine") then
		return false
	end
	if self.room:isProhibited(self.player, to, card) then
		return false
	end
	if to:isLocked(card) then
		return false
	end

	if self.player:hasSkill("noswuyan") or to:hasSkill("noswuyan") then
		return false
	end

	if to:hasSkill("wuyan") and not source:hasSkill("jueqing")  then
		return false
	end

	if self.player:hasSkill("wuyan") and not self.player:hasSkill("jueqing")  then
		return false
	end
	
	if card:isKindOf("SavageAssault") then
		if to:hasSkill("huoshou") or to:hasSkill("juxiang") then
			return false
		end
	end

	if (to:hasSkill("zhichi") and self.room:getTag("Zhichi"):toString() == to:objectName()) then
		return false
	end

	if to:hasSkill("danlao") and #players > 2 then
		return false
	end

	if to:hasSkill("huangen") and to:getHp() > 0 and #players > 2 then
		return false
	end
--[[	
	local liuxie = self.room:findPlayerBySkillName("huangen")
	if liuxie and liuxie:getHp() > 1 then
		if self:isFriend(to, liuxie) then
			if #players > 2 then
				return false
			end
		end
	end
]]--
	if not self:damageIsEffective(to, sgs.DamageStruct_Normal, source) then
		return false
	end

	return true
end

function SmartAI:canAvoidAOE(card)
	if not self:aoeIsEffective(card,self.player) then return true end
	if card:isKindOf("SavageAssault") then
		if self:getCardsNum("Slash") > 0 then
			return true
		end
	end
	if card:isKindOf("ArcheryAttack") then
		if self:getCardsNum("Jink") > 0 or (self:isEquip("EightDiagram") and self.player:getHp() > 1) then
			return true
		end
	end
	return false
end

function SmartAI:getDistanceLimit(card, from)
	from = from or self.player
	if card:isKindOf("Snatch") or card:isKindOf("SupplyShortage") then
		return 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, from, card)
	end
end

function SmartAI:exclude(players, card, from)
	from = from or self.player
	local excluded = {}
	local limit = self:getDistanceLimit(card, from)
	local range_fix = 0
	
	if type(players) ~= "table" then players = sgs.QList2Table(players) end	

	if card:isVirtualCard() then
		for _, id in sgs.qlist(card:getSubcards()) do
			if from:getOffensiveHorse() and from:getOffensiveHorse():getEffectiveId() == id then range_fix = range_fix + 1 end
		end
		if card:getSkillName() == "jixi" then range_fix = range_fix + 1 end
	end

	for _, player in ipairs(players) do
		if not self.room:isProhibited(from, player, card) then
			local should_insert = true
			if limit then
				should_insert = from:distanceTo(player, range_fix) <= limit
			end
			if should_insert then
				table.insert(excluded, player)
			end
		end
	end
	return excluded
end


function SmartAI:getJiemingChaofeng(player)
	local max_x , chaofeng = 0 , 0
	for _, friend in ipairs(self:getFriends(player)) do
		local x = math.min(friend:getMaxHp(), 5) - friend:getHandcardNum()
		if x > max_x then
			max_x = x
		end
	end
	if max_x < 2 then
		chaofeng = 5 - max_x * 2
	else
		chaofeng = (-max_x) * 2
	end
	return chaofeng
end

function SmartAI:getAoeValueTo(card, to , from)
	local value, sj_num = 0, 0
	if card:isKindOf("ArcheryAttack") then sj_num = getCardsNum("Jink", to)  end
	if card:isKindOf("SavageAssault") then sj_num = getCardsNum("Slash", to) end

	if self:aoeIsEffective(card, to, from) then
		if card:isKindOf("SavageAssault") and sgs.card_lack[to:objectName()]["Slash"] == 1 
			or card:isKindOf("ArcheryAttack") and sgs.card_lack[to:objectName()]["Jink"] == 1 
			or sj_num < 1 then
			value = -70
		else
			value = -50
		end
		value = value + math.min(20, to:getHp()*5)
		
		if self:getDamagedEffects(to, from) then value = value + 40 end
		
		if card:isKindOf("ArcheryAttack") then
			if to:hasSkill("leiji") and (sj_num >= 1 or self:isEquip("EightDiagram", to)) then
				value = value + 50
				if self:hasSuit("spade", true, to) or to:getHandcardNum() >= 3 then value = value + 50 end
			elseif self:isEquip("EightDiagram", to) then
				value = value + 20
				if self:getFinalRetrial(to) == 2 then
					value = value - 15
				elseif self:getFinalRetrial(to) == 1 then
					value = value + 10
				end
			end
		end
		
		if to:hasSkill("longdan") and to:hasSkill("chongzhen") and self:isEnemy(to) then
			if card:isKindOf("ArcheryAttack") and getCardsNum("Slash", to) >= 1 then
				value = value + 15
			elseif card:isKindOf("SavageAssault") and getCardsNum("Jink", to) >= 1 then
				value = value + 15
			end
		end
		
		local wansha = self.room:getCurrent():hasSkill("wansha")
		if wansha and to:getHp() == 1 and (sgs.card_lack[to:objectName()]["Peach"] == 1 or getCardsNum("Peach", to) == 0) then
			value = value - 30
			if self:isFriend(to) and self:getCardsNum("Peach") >= 1 then
				value = value + 10
			end
		end
		
		if not from:hasSkill("jueqing") then
			
			if self.room:getMode() ~= "06_3v3" then
				if to:getHp() == 1 and isLord(from) and sgs.evaluateRoleTrends(to) == "loyalist" and self:getCardsNum("Peach") == 0 then
					value = value - from:getCardCount(true)*20
				end
			end
			
			if to:getHp() > 1 then
				
				if self:hasSkill("quji", to) then value = value + 10 end
				if to:hasSkill("langgu") and self:isEnemy(to, from) then value = value - 15 end
			
				if to:hasSkill("jianxiong") then
					value = value + ((card:isVirtualCard() and card:subcardsLength()*10) or 10)
				end
			
				if to:hasSkill("fenyong") and to:hasSkill("xuehen") and to:getMark("@fenyong") == 0 then
					value = value + 30
				end
				
				if to:hasSkill("shenfen") and to:hasSkill("kuangbao") then
					value = value + math.min(25, to:getMark("@wrath")*5)
				end
				
				if to:hasSkill("beifa") and to:getHandcardNum() == 1 then
					if sj_num == 1 or getCardsNum("Nullification", to) == 1 then
						value = value + 20
					elseif self:getKnownNum(to) < 1 then
						value = value + 5
					end
				end
				
				if to:hasSkill("tanlan") and self:isEnemy(to) and not from:isKongcheng() then value = value + 10 end
			end
		end
		
	else
		value = value + 10
		if to:hasSkill("juxiang") and not card:isVirtualCard() then value = value + 20 end
		if to:hasSkill("danlao") and self.player:aliveCount() > 2 then value = value + 20 end
	end
	
	return value
end

function getLord(player)	
	if not player then global_room:writeToConsole(debug.traceback()) return end
	
	if sgs.GetConfig("EnableHegemony", false) then return nil end
	local room = global_room
	player = findPlayerByObjectName(room, player:objectName(), true)

	local mode = string.lower(room:getMode())
	if mode == "06_3v3" then
		if player:getRole() == "lord" or player:getRole() == "renegade" then return player end
		if player:getRole() == "loyalist" then return room:getLord() end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getRole() == "renegade" then return p end
		end
	end
	return room:getLord() or player
end

function isLord(player)
	return player and getLord(player) and getLord(player):objectName() == player:objectName()
end

function SmartAI:getAoeValue(card, player)
	local attacker = player or self.player
	local good, bad = 0, 0
	local lord = getLord(self.player)
	
	local canHelpLord =function()
		if not lord or self:isEnemy(lord) then return false end
		if self.player:hasSkill("qice") and card:isVirtualCard() then return false end
		
		local peach_num, null_num, slash_num, jink_num = 0, 0, 0, 0
		if card:isVirtualCard() and card:subcardsLength() > 0 then	
			for _, subcardid in sgs.qlist(card:getSubcards()) do
				local subcard = sgs.Sanguosha:getCard(subcardid)
				if isCard("Peach", subcard, self.player) then peach_num = peach_num - 1 end
				if isCard("Slash", subcard, self.player) then slash_num = slash_num - 1 end
				if isCard("Jink", subcard, self.player) then jink_num = jink_num - 1 end
				if isCard("Nullification", subcard, self.player) then null_num = null_num - 1 end
			end
		end
		
		if card:isKindOf("SavageAssault") and lord:hasLordSkill("jijiang") and self.player:getKingdom() == "shu" and
			self:getCardsNum("Slash") > slash_num then return true end
		
		if card:isKindOf("ArcheryAttack") and lord:hasLordSkill("hujia") and self.player:getKingdom() == "wei" and
			self:getCardsNum("Jink") > jink_num then return true end
		
		if self:getCardsNum("Peach") > peach_num then return true end
		
		local goodnull, badnull = 0, 0
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(lord, p) then 
				goodnull = goodnull +  getCardsNum("Nullification", p) 
			else
				badnull = badnull +  getCardsNum("Nullification", p) 
			end
		end
		return goodnull - null_num - badnull >= 2
	end

	if card:isKindOf("SavageAssault") then
		local menghuo = self.room:findPlayerBySkillName("huoshou")
		attacker = menghuo or attacker
	end	
	
	for _, friend in ipairs(self.friends_noself) do
		good = good + self:getAoeValueTo(card, friend, attacker)
	end
	
	for _, enemy in ipairs(self.enemies) do
		bad = bad + self:getAoeValueTo(card, enemy, attacker)
	end
	
	if not sgs.GetConfig("EnableHegemony", false) then
		if self.role ~= "lord" and sgs.isLordInDanger() and self:aoeIsEffective(card, lord, attacker) and not canHelpLord() then
			if self:isEnemy(lord) then
				good = good + (lord:getHp() == 1 and 200 or 150)
			else
				good = good - (lord:getHp() == 1 and 2013 or 250)
			end
		end
	end
	
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:cantbeHurt(player) and self:aoeIsEffective(card, player, attacker) then
			if player:hasSkill("wuhun") and not self:isWeak(player) and attacker:getMark("@nightmare") == 0 then
				if attacker:objectName() == self.player:objectName() and self.role ~= "renegade" and self.role ~= "lord" then
				elseif attacker:objectName() ~= self.player:objectName() and not (self:isFriend(attacker) and attacker:objectName() == lord:objectName()) then
				else
					bad = bad + 250
				end
			else
				bad = bad + 250
			end
		end

		if player:hasSkill("huangen") then
			if self:isFriend(player) then
				if player:getHp() >= #self.friends_noself then
					good = good + 300
				else
					good = good + player:getHp()*50
				end
			elseif self:isEnemy(player) then
				if player:getHp() >= #self.enemies then
					bad = bad + 300
				else
					bad = bad + player:getHp()*50
				end
			end
		end

		if player:hasSkill("dushi") and not attacker:hasSkill("benghuai") and self:isFriend(attacker) then bad = bad + 40 end
	end

	local forbid_start = true
	if self.player:hasSkill("jizhi") then
		forbid_start = false
		good = good + 25
	end
	
	if self.player:hasSkill("shenfen") and self.player:hasSkill("kuangbao") then
		forbid_start = false
		good = good + 15
		if not self.player:hasSkill("wumou") then
			good = good + 10
		elseif self.player:getMark("@wrath") > 0 then
			good = good + 5
		end
	end
	
	if not sgs.GetConfig("EnableHegemony", false) then
		if forbid_start and sgs.turncount < 2 and self.player:getSeat() <= 3 and card:isKindOf("SavageAssault") then
			if self.role ~= "rebel" then good = good + 50 else bad = bad + 50 end
		end

		if sgs.current_mode_players["rebel"] ==0 and self.role ~= "lord" and sgs.current_mode_players["loyalist"] > 0 and self:isWeak(lord) then
			bad = bad + 300
		end
	end
	
	if self:hasSkills("jianxiong|luanji|qice|manjuan") then good = good + 5 end
	
	-- self.room:writeToConsole(attacker:getGeneralName().." Use:"..card:getClassName().." good:"..good..",bad:"..bad..",value:"..(good-bad))
	return good - bad
end

function SmartAI:hasTrickEffective(card, to, from)
	from = from or self.room:getCurrent()
	to = to or self.player
	if to:objectName() ~= from:objectName() then
		if from:hasSkill("noswuyan") or to:hasSkill("noswuyan") then
			if card:isKindOf("TrickCard") and not card:isKindOf("DelayedTrick") then
				return false
			end
		end
	end
	
	if (from:hasSkill("wuyan") or to:hasSkill("wuyan")) and not from:hasSkill("jueqing") then
		if card:isKindOf("TrickCard") and 
		  (card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault")) then
			return false
		end
	end
	
	if self.room:isProhibited(from, to, card) then return false end

	if (to:hasSkill("zhichi") and self.room:getTag("Zhichi"):toString() == to:objectName()) then
		if card and not card:isKindOf("DelayedTrick") then return false end
	end
	
	local nature = sgs.DamageStruct_Normal
	if card:isKindOf("FireAttack") then nature = sgs.DamageStruct_Fire end

	local jinxuandi = self.room:findPlayerBySkillName("wuling")
	if jinxuandi and jinxuandi:getMark("@fire") > 0 then nature = sgs.DamageStruct_Fire end

	if (card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault")) 
	  and not self:damageIsEffective(to, nature, from) then 
		return false 
	end
	
	if to:hasSkill("zuixiang") and to:isLocked(card) then return false end
	return true
end

function SmartAI:useTrickCard(card, use)
	if not card then global_room:writeToConsole(debug.traceback()) return end
	if self.player:hasSkill("chengxiang") and self.player:getHandcardNum() < 8 and card:getNumber() < 7 then return end
	if self:needBear() and not ("amazing_grace|ex_nihilo|snatch|iron_chain|collateral"):match(card:objectName()) then return end
	if self.player:hasSkill("wumou") and self.player:getMark("@wrath") < 7 then
		if not (card:isKindOf("AOE") or card:isKindOf("DelayedTrick") or card:isKindOf("IronChain")) and not (card:isKindOf("Duel") and self.player:getMark("@wrath") > 0) then return end
	end
	if self:needRende() and not card:isKindOf("ExNihilo") then return end
	if card:isKindOf("AOE") then
		if self.player:hasSkill("wuyan") then return end
		if self.player:hasSkill("noswuyan") then return end
				
		local mode = global_room:getMode()
		if mode:find("p") and mode >= "04p" then
			if self.player:isLord() and sgs.turncount < 2 and card:isKindOf("ArcheryAttack") and self:getOverflow() < 1 then return end
			if self.role == "loyalist" and not self.player:isLord() and sgs.turncount < 2 and card:isKindOf("ArcheryAttack") then return end
			if self.role == "rebel" and sgs.turncount < 2 and card:isKindOf("SavageAssault") then return end
		end

		local others = self.room:getOtherPlayers(self.player)
		others = sgs.QList2Table(others)
		local aval = #others
		for _, other in ipairs(others) do
			if self.room:isProhibited(self.player, other, card) then
				aval = aval -1
			end
		end
		if aval < 1 then return end
		local good = self:getAoeValue(card)
		if good > 0 then
			use.card = card
		end
	else
		self:useCardByClassName(card, use)
	end
	if use.to then
		if not use.to:isEmpty() and sgs.dynamic_value.damage_card[card:getClassName()] then
			local nature = card:isKindOf("FireAttack") and sgs.DamageStruct_Fire or sgs.DamageStruct_Normal
			for _, target in sgs.qlist(use.to) do
				if self:damageIsEffective(target, nature) then return end
			end
			use.card = nil
		end
	end
end

sgs.weapon_range = {}

function SmartAI:hasEquip(card)
	return self.player:hasEquip(card)
end

function SmartAI:isEquip(equip_name, player, isEquipped)
	player = player or self.player
	local cards = player:getCards("e")
	for _, card in sgs.qlist(cards) do
		if card:isKindOf(equip_name) then return true end
	end
	if not isEquipped then
		if equip_name == "EightDiagram" and player:hasSkill("bazhen") and not player:getArmor() then return true end
		if equip_name == "Crossbow" and player:hasSkill("paoxiao") then return true end
	end
	return false
end

sgs.ai_weapon_value = {}

function SmartAI:evaluateWeapon(card)
	local deltaSelfThreat = 0
	local currentRange
	if not card then return -1
	else
		currentRange = sgs.weapon_range[card:getClassName()] or 0
	end
	for _,enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) <= currentRange then
				deltaSelfThreat = deltaSelfThreat+6/sgs.getDefense(enemy)
		end
	end

	if card:isKindOf("Crossbow") and deltaSelfThreat ~= 0 then
		if self.player:hasSkill("kurou") then deltaSelfThreat = deltaSelfThreat*3+10 end
		deltaSelfThreat = deltaSelfThreat + self:getCardsNum("Slash")*3-2
	end
	local callback = sgs.ai_weapon_value[card:objectName()]
	if type(callback) == "function" then
		deltaSelfThreat = deltaSelfThreat + (callback(self) or 0)
		for _, enemy in ipairs(self.enemies) do
			if self.player:distanceTo(enemy) <= currentRange and callback then
				deltaSelfThreat = deltaSelfThreat + (callback(self, enemy) or 0)
			end
		end
	end

	return deltaSelfThreat
end

sgs.ai_armor_value = {}

function SmartAI:evaluateArmor(card, player)
	player = player or self.player
	local ecard = card or player:getArmor()
	for _, askill in sgs.qlist(player:getVisibleSkillList()) do
		local callback = sgs.ai_armor_value[askill:objectName()]
		if type(callback) == "function" then
			return (callback(ecard, player, self) or 0)
		end
	end
	if not ecard then return 0 end
	local callback = sgs.ai_armor_value[ecard:objectName()]
	if type(callback) == "function" then
		return (callback(player, self) or 0)
	end
	return 0.5
end

function SmartAI:getSameEquip(card, player)
	player = player or self.player
	if not card then return end
	if card:isKindOf("Weapon") then return player:getWeapon()
	elseif card:isKindOf("Armor") then return player:getArmor()
	elseif card:isKindOf("DefensiveHorse") then return player:getDefensiveHorse()
	elseif card:isKindOf("OffensiveHorse") then return player:getOffensiveHorse() end
end

function SmartAI:useEquipCard(card, use)
	if not card then global_room:writeToConsole(debug.traceback()) return end
	if self.player:hasSkill("chengxiang") and self.player:getHandcardNum() < 8 and card:getNumber() < 7 and self:getSameEquip(card) then return end
	if self.player:hasSkill("xiaoji") and self:evaluateArmor(card) > -5 then
		use.card = card
		return
	end
	if self:hasSkills(sgs.lose_equip_skill) and self:evaluateArmor(card) > -5 and #self.enemies > 0 then
		use.card = card
		return
	end
	if self.player:getHandcardNum() <= 2 and self:needKongcheng() and self:evaluateArmor(card) > -5 then
		use.card = card
		return
	end
	local same = self:getSameEquip(card)
	if same then
		if (self:hasSkills("rende|qingnang|gongqi|nosgongqi|nosjujian|jujian|shensu|mingce|beige|yuanhu|qingcheng|neoluoyi"))
		or (self.player:hasSkill("yongsi") and self:getOverflow() < 3)
		or (self:hasSkills("renjie") and self:getOverflow() < 2 and not card:isKindOf("Crossbow"))
		or (self:hasSkills("longluo") and self:getOverflow() < 2 and not card:isKindOf("Crossbow") and #self.friends > 1)
		or (self:hasSkills("qixi|duanliang|yinling") and (card:isBlack() or same:isBlack()))
		or (self:hasSkills("guose|yanxiao") and (card:getSuit() == sgs.Card_Diamond or same:getSuit() == sgs.Card_Diamond))
		or (self:hasSkill("longhun") and (card:getSuit() ~= sgs.Card_Diamond or same:getSuit() ~= sgs.Card_Diamond))
		or (self:hasSkill("jijiu") and (card:isRed() or same:isRed()))
		or (self:hasSkill("luanji") and self:getOverflow() == 0)
		then return end
	end
	local canUseSlash = self:getCardId("Slash") and self:slashIsAvailable(self.player)
	self:useCardByClassName(card, use)
	if use.card or use.broken then return end
	if card:isKindOf("Weapon") then
		if self:needBear() then return end
		if self.player:hasSkill("jiehuo") and self.player:getMark("jiehuo") < 0 and card:isRed() then return end
		if self:hasSkill("zhulou") and same then return end
		if self:hasSkill("taichen") and same then
			local dummy_use = { isDummy = true }
			self:useSkillCard(sgs.Card_Parse("@TaichenCard=" .. same:getEffectiveId()), dummy_use)
			if dummy_use.card then return end
		end
		if self:hasSkill("qiangxi") and not self.player:hasUsed("QiangxiCard") and same then
			local dummy_use = { isDummy = true }
			self:useSkillCard(sgs.Card_Parse("@QiangxiCard=" .. same:getEffectiveId()), dummy_use)
			if dummy_use.card then return end
		end
		if self.player:hasSkill("rende") then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:getWeapon() then return end
			end
		end
		if self:hasSkills("paoxiao|nosfuhun", self.player) and card:isKindOf("Crossbow") then return end
		if not self:hasSkills(sgs.lose_equip_skill) and self:getOverflow() <= 0 and not canUseSlash then return end
		if not self.player:getWeapon() or self:evaluateWeapon(card) > self:evaluateWeapon(self.player:getWeapon()) then
			if (not use.to) and self.weaponUsed and (not self:hasSkills(sgs.lose_equip_skill)) then return end
			if (self.player:hasSkill("zhiheng") or self.player:hasSkill("jilve") and self.player:getMark("@bear") > 0) and
				not self.player:hasUsed("ZhihengCard") and self.player:getWeapon() and not card:isKindOf("Crossbow") then return end
			if self.player:getHandcardNum() <= self.player:getHp() - 2 then return end
			use.card = card
			return
		end
	elseif card:isKindOf("Armor") then
		if self:needBear() and self.player:getLostHp() == 0 then return end
		local lion = self:getCard("SilverLion")
		if lion and self.player:isWounded() and not self:isEquip("SilverLion") and not card:isKindOf("SilverLion") and
			not (self:hasSkills("bazhen|yizhong") and not self.player:getArmor() and not card:isKindOf("EightDiagram")) then
			use.card = lion
			return
		end
		if self.player:hasSkill("rende") then
			for _,friend in ipairs(self.friends_noself) do
				if not friend:getArmor() then return end
			end
		end
		if self:evaluateArmor(card) > self:evaluateArmor() then use.card = card end
		return
	elseif self:needBear() then return 
	elseif card:isKindOf("OffensiveHorse") then
		if self.player:hasSkill("jiehuo") and self.player:getMark("jiehuo") < 0 and card:isRed() then return end
		if self.player:hasSkill("rende") then
			for _,friend in ipairs(self.friends_noself) do
				if not friend:getOffensiveHorse() then return end
			end
			use.card = card 
			return
		else
			if not self:hasSkills(sgs.lose_equip_skill) and self:getOverflow()<=0 and not (canUseSlash or self:getCardId("Snatch")) then 
				return
			else
				if self.lua_ai:useCard(card) then 
					use.card = card 
					return
				end
			end
		end
	elseif self.lua_ai:useCard(card) then
		use.card = card
	end
end

function SmartAI:damageMinusHp(self, enemy, type)
		local trick_effectivenum = 0
		local slash_damagenum = 0
		local analepticpowerup = 0
		local effectivefireattacknum = 0
		local basicnum = 0
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		for _, acard in ipairs(cards) do
			if acard:getTypeId() == sgs.Card_Basic and not acard:isKindOf("Peach") then basicnum = basicnum + 1 end
		end
		for _, acard in ipairs(cards) do
			if ((acard:isKindOf("Duel") or acard:isKindOf("SavageAssault") or acard:isKindOf("ArcheryAttack") or acard:isKindOf("FireAttack")) 
			and not self.room:isProhibited(self.player, enemy, acard))
			or ((acard:isKindOf("SavageAssault") or acard:isKindOf("ArcheryAttack")) and self:aoeIsEffective(acard, enemy)) then
				if acard:isKindOf("FireAttack") then
					if not enemy:isKongcheng() then 
					effectivefireattacknum = effectivefireattacknum + 1 
					else
					trick_effectivenum = trick_effectivenum -1
					end
				end
				trick_effectivenum = trick_effectivenum + 1
			elseif acard:isKindOf("Slash") and self:slashIsEffective(acard, enemy) and ( slash_damagenum == 0 or self:isEquip("Crossbow", self.player)) 
				and (self.player:distanceTo(enemy) <= self.player:getAttackRange()) then
				if not (enemy:hasSkill("xiangle") and basicnum < 2) then slash_damagenum = slash_damagenum + 1 end
				if self:getCardsNum("Analeptic") > 0 and analepticpowerup == 0
				  and not (enemy:hasArmorEffect("SilverLion") or self:isEquip("EightDiagram", enemy))
				  and not IgnoreArmor(self.player, enemy) then 
					slash_damagenum = slash_damagenum + 1 
					analepticpowerup = analepticpowerup + 1 
				end
				if self:isEquip("GudingBlade", self.player)
					and (enemy:isKongcheng() or (self.player:hasSkill("lihun") and enemy:isMale() and not enemy:hasSkill("kongcheng")))
					and not (enemy:hasArmorEffect("SilverLion") and not IgnoreArmor(self.player, enemy)) then
					slash_damagenum = slash_damagenum + 1 
				end
			end
		end
		if type == 0 then return (trick_effectivenum + slash_damagenum - effectivefireattacknum - enemy:getHp()) 
		else return  (trick_effectivenum + slash_damagenum - enemy:getHp()) end
	return -10
end

function SmartAI:needRende()
	return self.player:hasSkill("rende") and self.player:getLostHp() > 1 
		and self.player:usedTimes("RendeCard") < 2 and #self.friends > 1
end

function getBestHp(player)
	local arr = {ganlu = 1, yinghun = 2, nosmiji = 1, xueji = 1, baobian = math.max(0, player:getMaxHp() - 3)}
	if player:hasSkill("longhun") and player:getCards("he"):length() > 2 then return 1 end
	if player:hasSkill("hunzi") and player:getMark("hunzi") == 0 then return 1 end
	for skill,dec in pairs(arr) do
		if player:hasSkill(skill) then 
			return math.max( (player:isLord() and 3 or 2) ,player:getMaxHp() - dec)
		end
	end
	if player:hasSkill("renjie") and player:hasSkill("baiyin") and player:getMark("baiyin") == 0 then return (player:getMaxHp() - 1) end
	if player:hasSkill("quanji") and player:hasSkill("zili") and player:getMark("zili") == 0 then return (player:getMaxHp() - 1) end
	return player:getMaxHp()
end

function SmartAI:haveFriendsToDraw(player)
	player = player or self.player
	local friends = self:getFriendsNoself(player)
	if #friends < 1 then return false end
	for _, friend in ipairs(friends) do
		if not friend:hasSkill("manjuan") and not self:needKongcheng(friend, true) then return true end
	end
	return false
end

function SmartAI:needToLoseHp(to, from, isSlash, passive, recover)
	from = from or self.room:getCurrent()
	to = to or self.player
	if isSlash and not from:hasSkill("jueqing") then
		if from:hasSkill("nosqianxi") and from:distanceTo(to) == 1 and not self:isFriend(from, to) then
			return false
		end
		if from:hasWeapon("IceSword") and to:getCards("he"):length() > 1 and not self:isFriend(from, to) then 
			return false
		end
	end
	if self:hasHeavySlashDamage(from) then return false end
	if from:hasSkill("jueqing") and self:hasSkills(sgs.masochism_skill, to) then return false end
	local n = getBestHp(to)

	if not passive then
		if to:getMaxHp() > 2 then
			if self:hasSkills("longluo|miji", to) and self:haveFriendsToDraw(to) then n = math.min(n, to:getMaxHp() - 1) end
			if to:hasSkill("rende") and not self:willSkipPlayPhase(to) and self:haveFriendsToDraw(to) then n = math.min(n, to:getMaxHp() - 1) end
		end
	end

	local friends = self:getFriendsNoself(to)
	local need_jieyin
	local xiangxiang = self.room:findPlayerBySkillName("jieyin")
	if xiangxiang and xiangxiang:isWounded() and self:isFriend(xiangxiang, to) and not to:isWounded() and to:isMale() then
		need_jieyin = true
		self:sort(friends, "hp")
		for _, friend in ipairs(friends) do
			if friend:isMale() and friend:isWounded() then need_jieyin = false end
		end
		if need_jieyin then n = math.min(n, to:getMaxHp() - 1) end
	end
	if recover then return to:getHp() >= n end
	return to:getHp() > n
end

function IgnoreArmor(from, to)
	from = from or self.room:getCurrent()
	to = to or self.player
	if from:hasWeapon("QinggangSword") or to:hasFlag("wuqian") or to:getMark("qinggang") > 0 then
		return true
	end
	return false
end

function SmartAI:needToThrowArmor(player)
	player = player or self.player
	if not player:getArmor() or not player:hasArmorEffect(player:getArmor():objectName()) then return false end
	if self:hasSkills("bazhen|yizhong") and not player:getArmor():isKindOf("EightDiagram") then return true end
	if self:evaluateArmor(player:getArmor(), player) <= -2 then return true end
	if player:hasArmorEffect("SilverLion") and player:isWounded() then
		if self:isFriend(player) then
			if player:objectName() == self.player:objectName() then
				return true
			else
				return self:isWeak(player) and not self:hasSkills(sgs.use_lion_skill, player)
			end
		else
			return true
		end
	end
	return false
end

function SmartAI:doNotDiscard(to, flags, conservative, n, cant_choose)
	if not to then global_room:writeToConsole(debug.traceback()) return end
	n = n or 1
	flags = flags or "he"
	if to:isNude() then return true end
	conservative = conservative or (sgs.turncount <= 2 and self.room:alivePlayerCount() > 2)
	local enemies = self:getEnemies(to)
	if #enemies == 1 and self:hasSkills("noswuyan|qianxun|weimu", enemies[1]) and self.room:alivePlayerCount() == 2 then conservative = false end
	if to:hasSkill("tuntian") and to:hasSkill("zaoxian") and to:getPhase() == sgs.Player_NotActive and (conservative or #self.enemies > 1) then return true end
	
	if cant_choose then
		if to:hasSkill("lirang") and self:haveFriendsToDraw(to) then return true end
		if self:needKongcheng(to) and to:getHandcardNum() <= n then return true end
		if to:hasSkill("shangshi") and (to:getHandcardNum() - n) < math.min(2, to:getLostHp()) then return true end
		if to:hasSkill("nosshangshi") and (to:getHandcardNum() - n) < player:getLostHp() then return true end
		if self:hasSkills(sgs.lose_equip_skill, to) and to:hasEquip() then return true end
		if self:needToThrowArmor(to) then return true end
	else
		if flags:match("e") then
			if to:hasSkill("jieyin") and to:getDefensiveHorse() then return false end
			if to:hasSkill("jieyin") and to:getArmor() and not to:getArmor():isKindOf("SilverLion") then return false end
		end
		if flags == "h" or (flags == "he" and not to:hasEquip()) then
			if to:isKongcheng() then return true end
			if not self:hasLoseHandcardEffective(to) then return true end
			if to:getHandcardNum() == 1 and self:needKongcheng(to) then return true end
			if #self.friends > 1 and to:getHandcardNum() == 1 and to:hasSkill("sijian") then return false end
		elseif flags == "e" or (flags == "he" and to:isKongcheng()) then
			if not to:hasEquip() then return true end
			if self:hasSkills(sgs.lose_equip_skill, to) then return true end	
			if to:getCardCount(true) == 1 and self:needToThrowArmor(to) then return true end
		end
		if flags == "he" and n == 2 then
			if to:getCards("he"):length() < 2 then return true end
			if not to:hasEquip() then
				if not self:hasLoseHandcardEffective(to) then return true end
				if to:getHandcardNum() <= 2 and self:needKongcheng(to) then return true end
			end
			if self:hasSkills(sgs.lose_equip_skill, to) and to:getHandcardNum() < 2 then return true end
			if to:getCardCount(true) <= 2 and self:needToThrowArmor(to) then return true end
		end
	end
	return false
end

function SmartAI:findPlayerToDiscard(flags, prompt, exclude)
	flags = flags or "he"
	local targets, friends, enemies = {}, {}, {}
	if prompt == "noself" then
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do 	
			if not exclude or (player:objectName() ~= exclude:objectName()) then
				table.insert(targets, player)
				if self:isFriend(player) then
					table.insert(friends, player)
				elseif self:isEnemy(player) and not self:doNotDiscard(player) then
					table.insert(enemies, player)
				end
			end
		end	
	elseif prompt == "all" then
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do 	
			if not exclude or (player:objectName() ~= exclude:objectName()) then
				table.insert(targets, player)
				if self:isFriend(player) then
					table.insert(friends, player)
				elseif self:isEnemy(player) and not self:doNotDiscard(player) then
					table.insert(enemies, player)
				end
			end
		end
	else
		global_room:writeToConsole(debug.traceback()) return
	end	

	if #targets == 0 then return end
	self:sort(enemies, "defense")
	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if self:getDangerousCard(enemy) then
				return enemy
			end
		end
	end
	
	if flags:match("j") then
		for _, player in ipairs(targets) do
			if player:containsTrick("lightning") and self:getFinalRetrial(player) == 2 then 
				return player
			end
		end
		for _, friend in ipairs(friends) do
			if ((friend:containsTrick("indulgence") and not friend:hasSkills("keji|conghui")) or friend:containsTrick("supply_shortage"))
			  and not (friend:hasSkill("qiaobian") and not friend:isKongcheng()) and not friend:containsTrick("YanxiaoCard") then
				return friend 
			end
		end
		for _, enemy in ipairs(enemies) do
			if (enemy:containsTrick("indulgence") or enemy:containsTrick("supply_shortage"))
			  and enemy:containsTrick("YanxiaoCard") then
				return enemy 
			end
		end
	end
	if flags:match("e") then
		for _, friend in ipairs(friends) do
			if self:needToThrowArmor(friend) then
				return friend
			end
		end
	end
	if flags:match("h") then
		for _, friend in ipairs(friends) do
			if friend:hasSkill("kongcheng") and friend:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, friend) > 0
			  and friend:getHp() <= 2 then
				return friend
			end
		end
	end
	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if self:hasSkills("jijiu|qingnang|qiaobian|jieyin|nosmiji|beige|fanjian|neofanjian|tuxi|" ..
			  "buyi|weimu|anxu|guzheng|tongxin|xiliang|chouliang|shouye|qixi|yinling|noswuyan|manjuan", enemy) 
			  and not self:doNotDiscard(enemy, "e") then
				if enemy:getDefensiveHorse() then return enemy end
				if enemy:getArmor() and not self:needToThrowArmor(enemy) then return enemy end
				if enemy:getOffensiveHorse() and enemy:hasSkill("jijiu") and enemy:getOffensiveHorse():isRed() then
					return enemy
				end
				if enemy:getWeapon() and enemy:hasSkill("jijiu") and enemy:getWeapon():isRed() then
					return enemy
				end
			end
		end	
	end
	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if enemy:getArmor() and enemy:getArmor():isKindOf("EightDiagram") and not self:doNotDiscard(enemy, "e") then
				return enemy
			end
		end
	end
	if flags:match("h") then
		for _, enemy in ipairs(enemies) do
			local cards = sgs.QList2Table(enemy:getHandcards())
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
			if #cards <= 2 and not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h", true) then
				for _, cc in ipairs(cards) do
					if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
						return enemy
					end
				end
			end

			if self:hasSkills("jijiu|qingnang|qiaobian|jieyin|beige|buyi|manjuan", enemy)
			  and not enemy:isKongcheng() and enemy:getHandcardNum() <= 2 and not self:doNotDiscard(enemy, "h") then 
				return enemy 
			end
		end
	end
	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if self:getValuableCard(enemy) then
				return enemy
			end
		end
	end

	if flags:match("j") then
		for _, enemy in ipairs(enemies) do
			if enemy:containsTrick("YanxiaoCard") then return enemy end
		end
	end

	if flags:match("h") then
		for _, enemy in ipairs(enemies) do
			if self:hasSkills(sgs.cardneed_skill, enemy) and not self:doNotDiscard(enemy, "h") then
				return enemy
			end
		end
	end

	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if not self:doNotDiscard(enemy, "e") then
				return enemy
			end
		end
	end
	
	self:sort(enemies, "handcard")
	if flags:match("h") then
		for _, enemy in ipairs(enemies) do
			if not self:doNotDiscard(enemy, "h") then
				return enemy
			end
		end
	end
	return
end

function SmartAI:findPlayerToDraw(prompt, n)
	n = n or 1
	local friends = {}
	if prompt == "noself" then
		for _, player in ipairs(self.friends_noself) do 	
			if not (player:hasSkill("manjuan") and player:getPhase() == sgs.Player_NotActive)
			  and not (self:needKongcheng(player, true) and n < 3) then
				table.insert(friends, player)
			end
		end	
	elseif prompt == "all" then
		for _, player in ipairs(self.friends) do 	
			if not (player:hasSkill("manjuan") and player:getPhase() == sgs.Player_NotActive)
			  and not (self:needKongcheng(player, true) and n < 3) then
				table.insert(friends, player)
			end
		end
	elseif prompt == "nos_xuanhuo" then
		for _, player in ipairs(self.friends) do 	
			if not player:hasFlag("nosxuanhuo_target") and not (player:hasSkill("manjuan") and player:getPhase() == sgs.Player_NotActive)
			  and not self:needKongcheng(player, true) then
				table.insert(friends, player)
			end
		end
	else
		global_room:writeToConsole(debug.traceback()) return
	end

	if #friends == 0 then return end
	
	self:sort(friends, "defense")	
	for _, friend in ipairs(friends) do
		if friend:getHandcardNum() < 2 and not self:needKongcheng(friend) then
			return friend
		end
	end

	for _, friend in ipairs(friends) do
		if self:hasSkills(sgs.cardneed_skill, friend) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end
	self:sort(friends, "handcard")
	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end
	return friends[1]
end


dofile "lua/ai/debug-ai.lua"
dofile "lua/ai/imagine-ai.lua"
dofile "lua/ai/standard_cards-ai.lua"
dofile "lua/ai/maneuvering-ai.lua"
dofile "lua/ai/classical-ai.lua"
dofile "lua/ai/standard-ai.lua"
dofile "lua/ai/chat-ai.lua"
dofile "lua/ai/basara-ai.lua"
dofile "lua/ai/hegemony-ai.lua"
dofile "lua/ai/hulaoguan-ai.lua"

local loaded = "standard|standard_cards|maneuvering|sp"

local files = table.concat(sgs.GetFileNames("lua/ai"), " ")

for _, aextension in ipairs(sgs.Sanguosha:getExtensions()) do
	if not loaded:match(aextension) and files:match(string.lower(aextension)) then
		dofile("lua/ai/" .. string.lower(aextension) .. "-ai.lua")
	end
end

dofile "lua/ai/sp-ai.lua"
dofile "lua/ai/special3v3-ai.lua"

for _, ascenario in ipairs(sgs.Sanguosha:getModScenarioNames()) do
	if not loaded:match(ascenario) and files:match(string.lower(ascenario)) then
		dofile("lua/ai/" .. string.lower(ascenario) .. "-ai.lua")
	end
end

-- vi:ts=4:
