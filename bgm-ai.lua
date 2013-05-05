sgs.ai_skill_invoke.chongzhen = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if self.player:hasSkill("manjuan") and self.player:getPhase() == sgs.Player_NotActive then return false end
		if not self:hasLoseHandcardEffective(target) then return true end
		if self:needKongcheng(target) and target:getHandcardNum() == 1 then return true end
		if self:getOverflow(target) > 2 then return true end
		return false
	else
		return not (target:hasSkill("kongcheng") and target:getHandcardNum() == 1)
	end
end

sgs.ai_choicemade_filter.skillInvoke.chongzhen = function(player, promptlist, self)
	if sgs.chongzhen_target then
		local target = sgs.chongzhen_target
		sgs.chongzhen_target = nil
		local intention = 10
		if promptlist[3] == "yes" then
			if not self:hasLoseHandcardEffective(target) or (self:needKongcheng(target) and target:getHandcardNum() == 1) then
				intention = 0
			end
			if self:getOverflow(target) > 2 then intention = 0 end
			sgs.updateIntention(player, target, intention)
		else
			if target:hasSkill("kongcheng") and target:getHandcardNum() == 1 then intention = 0 end
			sgs.updateIntention(player, target, -10)
		end
	end
end

sgs.ai_slash_prohibit.chongzhen = function(self, to, card, from)
	if self:isFriend(to) then return false end
	if from:hasSkill("tieji") or self:canLiegong(to, from) then
		return false
	end
	if to:hasSkill("longdan") and to:getHandcardNum() >= 3 and from:getHandcardNum() > 1 then return true end	
	return false	
end

local lihun_skill = {}
lihun_skill.name = "lihun"
table.insert(sgs.ai_skills, lihun_skill)
lihun_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("LihunCard") or self.player:isNude() then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")

	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then			
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else	
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not acard:isKindOf("Peach") then 
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
				  and not acard:isKindOf("Peach") then 
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	end
	if not card_id then
		return nil
	else
		return sgs.Card_Parse("@LihunCard=" .. card_id)
	end
end

sgs.ai_skill_use_func.LihunCard = function(card,use,self)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	if not self.player:hasUsed("LihunCard") then
		self:sort(self.enemies, "handcard")
		self.enemies = sgs.reverse(self.enemies)
		local target
		for _, enemy in ipairs(self.enemies) do
			if enemy:isMale() and enemy:getHandcardNum() - enemy:getHp() >= 2 then
				target = enemy
				break
			end
		end
		if not self.player:faceUp() and not target then
			for _, enemy in ipairs(self.enemies) do
				if enemy:isMale() and not enemy:isKongcheng() then
					if enemy:getHandcardNum() - enemy:getHp() >= -1 then
						target = enemy
						break
					end
				end
			end
		end
		if not target and (self:isEquip("Crossbow") or self:getCardsNum("Crossbow") > 0) then
			local slash = self:getCard("Slash") or sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, enemy in ipairs(self.enemies) do
				if self:slashIsEffective(slash, enemy) and self.player:distanceTo(enemy) == 1 and
					not self:hasSkills("fenyong|zhichi|fankui|neoganglie|ganglie|enyuan|nosenyuan|langgu|guixin|kongcheng", enemy) and
					self:getCardsNum("Slash") + getKnownCard(enemy, "Slash") >= 3 then
						target = enemy
					break
				end
			end
		end
		if target then
			use.card = card
			if use.to then use.to:append(target) end
		end
	end
end

sgs.ai_skill_discard.lihun = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local card_ids = {}
	for _,card in ipairs(cards) do
		table.insert(card_ids, card:getEffectiveId())
	end
	
	local temp = table.copyFrom(card_ids)
	for i = 1, #temp, 1 do
		local card = sgs.Sanguosha:getCard(temp[i])
		if (self.player:hasArmorEffect("SilverLion") and self.player:isWounded()) and card:isKindOf("SilverLion") then
			table.insert(to_discard, temp[i])
			table.removeOne(card_ids, temp[i])
			if #to_discard == discard_num then
				return to_discard
			end
		end
	end
	
	temp = table.copyFrom(card_ids)

	for i = 1, #card_ids, 1 do
		local card = sgs.Sanguosha:getCard(card_ids[i])
		table.insert(to_discard, card_ids[i])
		if #to_discard == discard_num then
			return to_discard
		end
	end
	
	if #to_discard < discard_num then return {} end
end

sgs.ai_use_value.LihunCard = 8.5
sgs.ai_use_priority.LihunCard = 6
sgs.ai_card_intention.LihunCard = 80

function sgs.ai_skill_invoke.kuiwei(self, data)
	local weapon = 0
	if not self.player:faceUp() then return true end
	for _, friend in ipairs(self.friends) do
		if self:hasSkills("fangzhu|jilve", friend) then return true end
	end
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:getWeapon() then weapon = weapon + 1 end
	end
	if weapon >1 then return true end
	return self:isWeak()
end

sgs.ai_view_as.yanzheng = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceEquip and player:getHandcardNum() > player:getHp() then
		return ("nullification:yanzheng[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_chaofeng.bgm_pangtong = 10

sgs.ai_skill_invoke.manjuan = true
sgs.ai_skill_invoke.zuixiang = true

sgs.ai_skill_askforag.manjuan = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("ExNihilo") then return card:getEffectiveId() end
		if card:isKindOf("IronChain") then return card:getEffectiveId() end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Snatch") and #self.enemies > 0 then
				self:sort(self.enemies,"defense")
				if sgs.getDefense(self.enemies[1]) >= 8 then self:sort(self.enemies, "threat") end
				local enemies = self:exclude(self.enemies, card)
				for _,enemy in ipairs(enemies) do
					if self:hasTrickEffective(card, enemy) then
						return card:getEffectiveId()
					end
				end
			end
		end
	for _, card in ipairs(cards) do
		if card:isKindOf("Peach") and self.player:isWounded() and self:getCardsNum("Peach") < self.player:getLostHp() then return card:getEffectiveId() end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("AOE") and self:getAoeValue(card) > 0 then return card:getEffectiveId() end
	end
	self:sortByCardNeed(cards)
	return cards[#cards]:getEffectiveId()
end

sgs.ai_cardneed.jie = function(to, card)
	return card:isRed() and isCard("Slash", card, to)
end

local dahe_skill = {}
dahe_skill.name = "dahe"
table.insert(sgs.ai_skills,dahe_skill)
dahe_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	if not self.player:hasUsed("DaheCard") and not self.player:isKongcheng() then return sgs.Card_Parse("@DaheCard=.") end
end

sgs.ai_skill_use_func.DaheCard=function(card,use,self)	
	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard(self.player)
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount - 1 end
	if self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				use.card = sgs.Card_Parse("@DaheCard=" .. max_card:getId())
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if slashcount > 0 then
		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = {isDummy = true}
		self:useBasicCard(slash, dummy_use)
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1 and enemy:getHp() > self.player:getHp()) 
				and not enemy:isKongcheng() and self.player:canSlash(enemy, nil, true) then
				local enemy_max_card = self:getMaxCard(enemy)
				local allknown = 0
				if self:getKnownNum(enemy) == enemy:getHandcardNum() then
					allknown = allknown + 1
				end
				if (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown > 0)
					or (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown < 1 and max_point > 10) 
					or (not enemy_max_card and max_point > 10) then
					use.card = sgs.Card_Parse("@DaheCard=" .. max_card:getId())
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

function sgs.ai_skill_pindian.dahe(minusecard, self, requestor)
	if self:isFriend(requestor) then return minusecard end
	return self:getMaxCard(self.player):getId()
end

sgs.ai_skill_choice.dahe = function(self, choices)
	return "yes"
end

sgs.ai_skill_playerchosen.dahe = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if target:hasSkill("kongcheng") and target:isKongcheng() 
			and target:hasFlag("dahe") then 
			return target 
		end 
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) and not self:needKongcheng(target, true) then return target end 
	end
	return targets[1]
end

sgs.ai_skill_cardask["@dahe-jink"] = function(self, data, pattern, target)
	if self.player:hasFlag("dahe") then
		for _, card in ipairs(self:getCards("Jink")) do
			if card:getSuit() == sgs.Card_Heart then
				return card:getId()
			end
		end
			return "."
	end
end

sgs.ai_cardneed.dahe = sgs.ai_cardneed.bignumber
sgs.ai_card_intention.DaheCard = 60
sgs.dynamic_value.control_card.DaheCard = true

sgs.ai_use_value.DaheCard = 8.5
sgs.ai_use_priority.DaheCard = 8

local tanhu_skill = {}
tanhu_skill.name = "tanhu"
table.insert(sgs.ai_skills, tanhu_skill)
tanhu_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	if not self.player:hasUsed("TanhuCard") and not self.player:isKongcheng() then
		local max_card = self:getMaxCard()
		return sgs.Card_Parse("@TanhuCard=" .. max_card:getEffectiveId())
	end
end

sgs.ai_skill_use_func.TanhuCard = function(card, use, self)
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local ptarget = self:getPriorTarget()
	if not ptarget then return end
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount - 1 end
	if not ptarget:isKongcheng() and slashcount > 0 and self.player:canSlash(ptarget, nil, true) 
	and not (ptarget:hasSkill("kongcheng") and ptarget:getHandcardNum() == 1) then
		local card_id = max_card:getEffectiveId()
		local card_str = "@TanhuCard=" .. card_id
		if use.to then
			use.to:append(ptarget)
		end
		use.card = sgs.Card_Parse(card_str)
		return
	end
	self:sort(self.enemies, "defense")

	for _, enemy in ipairs(self.enemies) do
		if self:getCardsNum("Snatch") > 0 and not enemy:isKongcheng() then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy) == enemy:getHandcardNum() then
				allknown = allknown + 1
			end
			if (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown > 0)
				or (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown < 1 and max_point > 10) 
				or (not enemy_max_card and max_point > 10)
				and (self:getDangerousCard(enemy) or self:getValuableCard(enemy)) then
					local card_id = max_card:getEffectiveId()
					local card_str = "@TanhuCard=" .. card_id
					use.card = sgs.Card_Parse(card_str)
					if use.to then use.to:append(enemy)	end
					return
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	if self:getUseValue(cards[1]) >= 6 or self:getKeepValue(cards[1]) >= 6 then return end
	if self:getOverflow() > 0 then
		if not ptarget:isKongcheng() then
			local card_id = max_card:getEffectiveId()
			local card_str = "@TanhuCard=" .. card_id
			if use.to then
				use.to:append(ptarget)
			end
			use.card = sgs.Card_Parse(card_str)
			return
		end
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and not (enemy:hasSkill("tuntian") and enemy:hasSkill("zaoxian")) then
				use.card = sgs.Card_Parse("@TanhuCard=" .. cards[1]:getId())
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_cardneed.tanhu = sgs.ai_cardneed.bignumber
sgs.ai_card_intention.TanhuCard = 30
sgs.dynamic_value.control_card.TanhuCard = true
sgs.ai_use_priority.TanhuCard = 8

function sgs.ai_skill_pindian.tanhu(minusecard, self, requestor)
	if self.player:objectName() == requestor:objectName() then
		if self.tanhu_card then
			return self.tanhu_card
		else
			self.room:writeToConsole("Pindian card not found!!")
			return self:getMaxCard(self.player):getId()
		end
	end
end

local function need_mouduan(self)
	local cardsCount = self.player:getHandcardNum()
	if cardsCount <= 3 then return false end
	local current = self.room:getCurrent()
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	if current:objectName() == self.player:objectName() then
		if (self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0)
			and self:getCardsNum("Slash") >= 3
			and (not self:willSkipPlayPhase() or self.player:hasSkill("dangxian")) then
			local hasTarget = false
			for _, enemy in ipairs(self.enemies) do
				if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then
					hasTarget = true
					break
				end
			end
			return hasTarget
		end
	elseif (cardsCount == 4 or cardsCount == 5) and #self.enemies > 1 then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@mouduan"] = function(self, data)
	if not need_mouduan(self) then return "." end
	local to_discard = self:askForDiscard("mouduan", 1, 1, false, true)
	if #to_discard > 0 then return "$" .. to_discard[1] else return "." end
end


sgs.ai_skill_invoke.mouduan = function(self, data)
	return need_mouduan(self)
end


sgs.ai_skill_invoke.zhaolie = function(self, data)
	for _, enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) <= self.player:getAttackRange() and sgs.isGoodTarget(enemy, self.enemies, self) 
			and self:objectiveLevel(enemy) > 3 and self:damageIsEffective(enemy) then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.zhaolie = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and sgs.isGoodTarget(target, targets, self) and self:objectiveLevel(target) > 3 and self:damageIsEffective(target) then 
			return target 
		end 
	end
	return targets[1]
end

sgs.ai_skill_choice.zhaolie = function(self, choices, data)
	local spliubei = self.room:findPlayerBySkillName("zhaolie")
	if self.player:hasSkill("wuhun") then
		local mark = 0
		local spmark = spliubei and spliubei:isLord() and spliubei:getMark("@nightmare") or 0
		for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
			if ap:getMark("@nightmare") > 0 then
				mark = ap:getMark("@nightmare")
			end
		end
		if mark == 0 and spliubei and spliubei:isLord() then return "damage" end
		if mark < self.player:getHp() + spmark then return "damage" end
	end
	if not self:damageIsEffective() then return "damage" end
	local nobasic = data:toInt()
	if self.player:hasSkill("manjuan") then	return "throw" end
	if nobasic == 0 then return "damage" end
	if self.player:hasArmorEffect("SilverLion") and self.player:getHp() > 1 and not (spliubei and spliubei:hasSkill("jueqing")) then return "damage" end
	if nobasic < 2 and self.player:getHp() > 1 then	return "damage" else return "throw" end
end

sgs.ai_skill_invoke.shichou = function(self, data)
	local enemynum = 0
	local shu = 0
	local first = self.room:getTag("FirstRound"):toBool()
	local players = self.room:getOtherPlayers(self.player)
	local shenguanyu = self.room:findPlayerBySkillName("wuhun")

	if not self.room:getLord() then return false end

	if shenguanyu ~= nil then
		if shenguanyu:getKingdom() == "shu" then return true end
	end
	for _, player in sgs.qlist(players) do
		if player:getKingdom() == "shu" then
			shu = shu + 1
			if self:isEnemy(player) then
				enemynum = enemynum + 1
			end
		end
	end

	if self.role=="rebel" and self.room:getLord():getKingdom()=="shu" then
		return true
	end
	
	if shu ==0 then return false end
	if enemynum >0 or shu == 1 then return true end	

	if first and shu > 1 then return false end
	return self:isWeak() and shu >0
end

sgs.ai_skill_playerchosen.shichou = function(self, targets)
	if not self.room:getLord() then return false end

	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	targets = sgs.reverse(targets)

	if self.role=="rebel" and self.room:getLord():getKingdom()=="shu" then
		return self.room:getLord()
	end

	for _, target in ipairs(targets) do
		if target:hasSkill("wuhun") then 
			return target 
		end 
	end
	for _, target in ipairs(targets) do
		if self:isEnemy(target) then 
			return target 
		end 
	end

	for _, target in ipairs(targets) do
		if self:hasSkills("zaiqi|nosenyuan|kuanggu|enyuan",target) and target:getHp()>=2 then 
			return target 
		end 
	end
	return targets[1]
end


sgs.ai_need_damaged.shichou = function (self, attacker, player)
	if player:hasLordSkill("shichou") and player:getMark("@hate")==0 then
		if player:getTag("ShichouTarget") then
			local victim_role
			local victim = player:getTag("ShichouTarget"):toPlayer()
			if not victim then return false end
			if sgs.isRolePredictable() and sgs.evaluatePlayerRole(victim) == "rebel" then
				victim_role = "rebel"
			elseif sgs.compareRoleEvaluation(victim, "rebel", "loyalist") == "rebel" then 
				victim_role = "rebel"
			end
			local need_damage = false
			local self_role = self.player:objectName() == attacker:objectName() and self.role or sgs.ai_role[attacker:objectName()]
			if (self_role == "loyalist" or self.player:isLord()) and victim_role == "rebel" then need_damage = true end
			if self_role == "rebel" and victim_role ~= "rebel" then need_damage = true end
			if self_role == "renegade" then need_damage =true end

			if victim:isAlive() and need_damage  then
				return victim:hasSkill("wuhun") and 2 or 1
			end
		end
	end
	return false
end

sgs.ai_skill_discard.shichou = sgs.ai_skill_discard.lihun


sgs.ai_event_callback[sgs.ChoiceMade].shichou=function(self,player,data)
	local choices= data:toString():split(":")
	if choices[1] == "playerChosen" and choices[2] == "shichou" then
		local target = findPlayerByObjectName(self.room, choices[3])
		local intention = self:hasSkills("wuhun|zaiqi|nosenyuan|kuanggu|enyuan",target) and 0 or 100
		sgs.updateIntention(player, target, intention)
	end
end


function SmartAI:useCardYanxiaoCard(card, use)
	local players = self.room:getOtherPlayers(self.player)
	local tricks
	self:sort(self.friends_noself, "defense")

	for _, friend in ipairs(self.friends_noself) do
		local judges = friend:getJudgingArea()
		local yanxiao = (friend:containsTrick("lightning") and self:getFinalRetrial(player) ==2) 
					or friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")
		if yanxiao and not friend:containsTrick("YanxiaoCard") then
			use.card = card
			if use.to then
				use.to:append(friend)
			end
			return
		end
	end

	if self:getOverflow() > 0 then
		if not self.player:containsTrick("YanxiaoCard") then
			use.card = card
			if use.to then
				use.to:append(self.player)
			end
			return
		end
		local lord = self.room:getLord()
		if lord and self:isFriend(lord) and not lord:containsTrick("YanxiaoCard") then
			use.card = card
			if use.to then
				use.to:append(lord)
			end
			return
		end

		for _, friend in ipairs(self.friends_noself) do
			local judges = friend:getJudgingArea()
			if not friend:containsTrick("YanxiaoCard") then
				use.card = card
				if use.to then
					use.to:append(friend)
				end
				return
			end
		end
	end
end

sgs.ai_use_priority.YanxiaoCard = 3.9
sgs.ai_card_intention.YanxiaoCard = -80

local yanxiao_skill={}
yanxiao_skill.name="yanxiao"
table.insert(sgs.ai_skills,yanxiao_skill)
yanxiao_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	local diamond_card
	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:getSuit() == sgs.Card_Diamond then
			diamond_card = card
			break
		end
	end

	if diamond_card then
		local suit = diamond_card:getSuitString()
		local number = diamond_card:getNumberString()
		local card_id = diamond_card:getEffectiveId()
		local card_str = ("YanxiaoCard:yanxiao[%s:%s]=%d"):format(suit, number, card_id)
		local yanxiaocard = sgs.Card_Parse(card_str)
		assert(yanxiaocard)
		return yanxiaocard
	end
end

sgs.yanxiao_suit_value = {
	diamond = 3.9
}

function sgs.ai_cardneed.yanxiao(to, card)
	return card:getSuit() == sgs.Card_Diamond
end

sgs.ai_skill_invoke.anxian = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) and not (self:getDamagedEffects(target, self.player) or self:needToLoseHp(target, self.player, nil, true)) then return true end
	if self:hasHeavySlashDamage(self.player, damage.card, damage.to) then return false end
	if self:isEnemy(target) and self:getDamagedEffects(target, self.player) and not self:doNotDiscard(target, "h") then return true end
	return false
end

sgs.ai_skill_cardask["@anxian-discard"] = function(self, data)
	local use = data:toCardUse()
	local from = use.from
	local to = self.player
	if self.player:isKongcheng() then return "." end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)

	if self:hasHeavySlashDamage(from, use.card, self.player) and self:canHit(to, from, true) then
		return "$" .. cards[1]:getEffectiveId()
	end	
	if self:getDamagedEffects(self.player, use.from, true) then
		return "."
	end
	if self:needToLoseHp(self.player, use.from, true) then
		return "."
	end
	if self:isFriend(to, from) then return "$" .. cards[1]:getEffectiveId() end
	if self:needToLoseHp(self.player, use.from, true, true) then
		return "."
	end
	if self:canHit(to, from) then
		for _, card in ipairs(cards) do
			if not isCard("Peach", card, self.player) then
				return "$" .. card:getEffectiveId()
			end
		end
	end
	if self:getCardsNum("Jink") > 0 then
		return "."
	end

	if #cards == self:getCardsNum("Peach") then return "." end
	for _, card in ipairs(cards) do
		if not isCard("Peach", card, self.player) then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end

local yinling_skill = {}
yinling_skill.name = "yinling"
table.insert(sgs.ai_skills, yinling_skill)
yinling_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getPile("brocade"):length() >= 4 then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local black_card
	local has_weapon = false
	
	for _,card in ipairs(cards)  do
		if card:isKindOf("Weapon") and card:isBlack() then has_weapon=true end
	end
	
	for _,card in ipairs(cards)  do
		if card:isBlack()  and ((self:getUseValue(card) < sgs.ai_use_value.YinlingCard) or inclusive or self:getOverflow() > 0) then
			local shouldUse = true

			if card:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false 
				elseif self:hasEquip(card) and not (card:isKindOf("SilverLion") and self.player:isWounded()) then shouldUse = false
				end
			end

			if card:isKindOf("Weapon") then
				if not self.player:getWeapon() then shouldUse = false
				elseif self:hasEquip(card) and not has_weapon then shouldUse=false
				end
			end
			
			if card:isKindOf("Slash") then
				local dummy_use = {isDummy = true}
				if self:getCardsNum("Slash") == 1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.YinlingCard and card:isKindOf("TrickCard") then
				local dummy_use = {isDummy = true}
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse then
				black_card = card
				break
			end
			
		end
	end

	if black_card then
		local card_id = black_card:getEffectiveId()
		local card_str = ("@YinlingCard="..card_id)
		local yinling = sgs.Card_Parse(card_str)
		
		assert(yinling)

		return yinling
	end
end

sgs.ai_skill_use_func.YinlingCard = function(card, use, self)
	if self.player:getPile("brocade"):length() >= 4 then return end
	local target
	target = self:findPlayerToDiscard("he", "noself")
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
			self:speak("hostile", self.player:isFemale())
		end
		return
	end

	local players = self.room:getOtherPlayers(self.player)
	players = self:exclude(players, card)

	local enemies = {}
	if #self.enemies == 0 and self:getOverflow() > 0 then
		for _, player in ipairs(players) do
			if sgs.evaluateRoleTrends(player) ~= "loyalist" and not player:isLord() then table.insert(enemies, player) end
		end
		enemies = self:exclude(enemies, card)
		if sgs.turncount < 3 and #enemies > 0 then enemies = {enemies[1 + (os.time() % #enemies)]} end
		self:sort(enemies, "defenseSlash")
		enemies = sgs.reverse(enemies)
	end
	for _, enemy in ipairs(enemies) do
		if not enemy:isKongcheng() and not self:doNotDiscard(enemy, "he", true)
		  and (enemy:getHandcardNum() > enemy:getHp() - 2 or (enemy:getHandcardNum() == 1 and not self:needKongcheng(enemy))) then
			use.card = card
			if use.to then
				sgs.ai_skill_cardchosen.yinling = enemy:getRandomHandCardId()
				use.to:append(enemy)
			end
			return
		end
	end
	return
end

sgs.ai_use_value.YinlingCard = sgs.ai_use_value.Dismantlement + 1
sgs.ai_use_priority.YinlingCard = sgs.ai_use_priority.Dismantlement + 1

sgs.ai_choicemade_filter.cardChosen.yinling = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_invoke.junwei = function(self, data)
	for _, enemy in ipairs(self.enemies) do
		if not (enemy:hasEquip() and self:doNotDiscard(enemy, "e")) then return true end
	end
end

sgs.ai_playerchosen_intention.junwei = 80

sgs.ai_skill_playerchosen.junwei = function(self, targets)
	local tos = {}
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) and not (target:hasEquip() and self:doNotDiscard(target, "e")) then
			table.insert(tos, target)
		end
	end 

	if #tos > 0 then
		self:sort(tos, "defense")
		return tos[1]
	end
end

sgs.ai_playerchosen_intention.junweigive = -80

sgs.ai_skill_playerchosen.junweigive = function(self, targets)
	local tos = {}
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) and not target:hasSkill("manjuan") and not self:needKongcheng(target, true) then
			table.insert(tos, target) 
		end
	end 

	if #tos > 0 then
		for _, to in ipairs(tos) do
			if to:hasSkill("leiji") and self:isFriend(to) then return to end
		end
		self:sort(tos, "defense")
		return tos[1]
	end
end

sgs.ai_skill_cardchosen.junwei = function(self, who, flags)
	if flags == "e" then
		if who:getArmor() and not self:needToThrowArmor(who) then return who:getArmor() end
		if who:getDefensiveHorse() then return who:getDefensiveHorse() end
		if who:getOffensiveHorse() then return who:getOffensiveHorse() end
		if who:getWeapon() then return who:getWeapon() end
	end
end

sgs.ai_skill_cardask["@junwei-show"] = function(self, data)
	local ganning = data:toPlayer()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	for _,card in ipairs(cards) do
		if card:isKindOf("Jink") then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end

sgs.yinling_suit_value = {
	spade = 3.9,
	club = 3.9
}

sgs.ai_skill_invoke.fenyong = function(self, data)
	self.fenyong_choice = nil
	if sgs.turncount <= 1 and #self.enemies == 0 then return end

	local current = self.room:getCurrent()
	if not current or current:getPhase() >= sgs.Player_Finish then return true end
	if self:isFriend(current) then
		self:sort(self.enemies, "defenseSlash")
		for _, enemy in ipairs(self.enemies) do
			local def = sgs.getDefenseSlash(enemy)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

			if self.player:canSlash(enemy, nil, false) and not self:slashProhibit(nil, enemy) and eff and def < 5 then
				return true
			end
			if self.player:getLostHp() == 1 and self:needToThrowArmor(current) then return true end
		end
		return false
	end

	return true
end

function sgs.ai_slash_prohibit.fenyong(self, to, card, from)
	if from:hasSkill("jueqing") then return false end
	if from:hasFlag("nosjiefanUsed") then return false end
	if from:hasSkill("nosqianxi") and from:distanceTo(to) == 1 then return false end
	return to:getMark("@fenyong") > 0 and to:hasSkill("fenyong")
end

sgs.ai_need_damaged.fenyong = function (self, attacker, player)
	if not player:hasSkill("fenyong") then return false end
	if not player:hasSkill("xuehen") then return false end
	for _, enemy in ipairs(self.enemies) do
		local def = sgs.getDefense(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

		if self.player:canSlash(enemy, nil, false) and not self:slashProhibit(nil, enemy) and eff and def < 6 then
			return true
		end
	end
	return false
end

sgs.ai_skill_choice.xuehen = function(self, choices)
	if self.fenyong_choice then return self.fenyong_choice end
	local current = self.room:getCurrent()
	local n = self.player:getLostHp()
	if self:isEnemy(current) then
		if n >= 3 and current:getCardCount(true) >= 3 and not (self:needKongcheng(current) and current:getCards("e"):length() < 3)
			and not (self:hasSkills(sgs.lose_equip_skill, current) and current:getHandcardNum() < n) then
			return "discard"
		end
		if self:hasSkills("jijiu|tuntian+zaoxian|beige", current) and n >= 2 and current:getCardCount(true) >= 2 then return "discard" end
	end
	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		local def = sgs.getDefense(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

		if self.player:canSlash(enemy, nil, false) and not self:slashProhibit(nil, enemy) and eff and def < 6 then
			self.xuehentarget = enemy
			return "slash"
		end
	end
	if self:isEnemy(current) then
		for _, enemy in ipairs(self.enemies) do
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local eff = self:slashIsEffective(slash, enemy)

			if self.player:canSlash(enemy, nil, false) and not self:slashProhibit(nil, enemy) and self:hasHeavySlashDamage(self.player, slash, enemy) then
				self.xuehentarget = enemy
				return "slash"
			end
		end
		local armor = current:getArmor()
		if armor and self:evaluateArmor(armor, current) >= 3 and not self:doNotDiscard(current, "e") and n <= 2 then return "discard" end		
	end
	if self:isFriend(current) then
		if n == 1 and self:needToThrowArmor(current) then return "discard" end
		for _, enemy in ipairs(self.enemies) do
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local eff = self:slashIsEffective(slash, enemy)

			if self.player:canSlash(enemy, nil, false) and not self:slashProhibit(nil, enemy) then
				self.xuehentarget = enemy
				return "slash"
			end
		end
	end
	return "discard"
end

sgs.ai_skill_playerchosen.xuehen = function(self, targets)
	local to = self.xuehentarget
	if to then 
		self.xuehentarget = nil 
		return to 
	end
	to = sgs.ai_skill_playerchosen.zero_card_as_slash
	return to or targets[1]
end

sgs.ai_suit_priority.jie = "club|spade|diamond|heart"
sgs.ai_suit_priority.yanxiao = "club|spade|heart|diamond"
sgs.ai_suit_priority.yinling = "diamond|heart|club|spade"

--AI for DIY generals
sgs.ai_skill_use["@@zhaoxin"] = function(self, prompt)
	local target
	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
		if eff and self.player:canSlash(enemy) and not self:slashProhibit(nil, enemy) then
			return "@ZhaoxinCard=.->" .. enemy:objectName()
		end
	end
	return "."
end

sgs.ai_card_intention.ZhaoxinCard = 80

sgs.ai_skill_invoke.langgu = function(self, data)
	local damage = data:toDamage()
	return not self:isFriend(damage.from)
end

sgs.ai_choicemade_filter.skillInvoke.langgu = function(player, promptlist, self)
	if sgs.langgu_target and promptlist[3] == "yes" then
		sgs.updateIntention(player, sgs.langgu_target, 10)
	end
	sgs.langgu_target = nil
end

sgs.ai_skill_askforag.langgu = function(self, card_ids)
	return -1
end

sgs.ai_skill_cardask["@langgu-card"] = function(self, data)
	local judge = data:toJudge()

	if self.player:hasFlag("langgu_hongyan") and judge.card:getSuit() ~= sgs.Card_Heart then
		local cards = sgs.QList2Table(self.player:getHandcards())
		for _, card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Heart then
				return "@LangguCard[" .. card:getSuitString() .. ":" .. card:getNumberString() .. "]=" .. card:getId()
			end
		end
		if judge.card:getSuit() == sgs.Card_Spade then
			self:sortByKeepValue(cards)
			local card = cards[1]
			return "@LangguCard[" .. card:getSuitString() .. ":" .. card:getNumberString() .. "]=" .. card:getId()
		end
	end

	return "."
end

local fuluan_skill = {}
fuluan_skill.name = "fuluan"
table.insert(sgs.ai_skills, fuluan_skill)
fuluan_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("FuluanCard") or self.player:hasFlag("ForbidFuluan") then return end
	local first_found, second_found, third_found = false, false, false
	local first_card, second_card, third_card
	if self.player:getCards("he"):length() >= 3 then
		local cards = self.player:getCards("he")
		local same_suit = false
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if not isCard("Peach", fcard, self.player) and not isCard("ExNihilo", fcard, self.player) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not isCard("Peach", scard, self.player) and not isCard("ExNihilo", scard, self.player) then
						second_card = scard
						second_found = true
						for _, tcard in ipairs(cards) do
							if first_card ~= tcard and second_card ~= tcard and tcard:getSuit() == first_card:getSuit()
								and not isCard("Peach", tcard, self.player) and not isCard("ExNihilo", tcard, self.player) then
								third_card = tcard
								third_found = true
								break
							end
						end
					end
					if third_found then break end
				end
			end
			if third_found and second_found then break end
		end
	end

	if first_found and second_found and third_found then
		local card_str = ("@FuluanCard=%d+%d+%d"):format(first_card:getId(), second_card:getId(), third_card:getId())
		assert(card_str)
		return sgs.Card_Parse(card_str)
	end
end

local function can_be_selected_as_target_fuluan(self, card, who)
	local subcards = card:getSubcards()
	if self.player:getWeapon() and subcards:contains(self.player:getWeapon():getId()) then
		local distance_fix = sgs.weapon_range[self.player:getWeapon():getClassName()] - 1
		if self.player:getOffensiveHorse() and subcards:contains(self.player:getOffensiveHorse():getId()) then
			distance_fix = distance_fix + 1
		end
		return self.player:distanceTo(who, distance_fix) <= self.player:getAttackRange()
	elseif self.player:getOffensiveHorse() and subcards:contains(self.player:getOffensiveHorse():getId()) then
		return self.player:distanceTo(who, 1) <= self.player:getAttackRange()
	elseif self.player:inMyAttackRange(who) then
		return true
	end
	return false
end

sgs.ai_skill_use_func.FuluanCard = function(card, use, self)
	local subcards = card:getSubcards()
	self:sort(self.friends_noself)
	for _, friend in ipairs(self.friends_noself) do
		if not friend:faceUp() then
			if can_be_selected_as_target_fuluan(self, card, friend) then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:faceUp() then
			if can_be_selected_as_target_fuluan(self, card, enemy) then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_priority.FuluanCard = 2.3
sgs.ai_card_intention.FuluanCard = function(self, card, from, tos)
	sgs.updateIntention(from, tos[1], tos[1]:faceUp() and 80 or -80)
end

local function need_huangen(self, who)
	local card = sgs.Card_Parse(self.player:getTag("Huangen_user"):toString())
	if card == nil then return false end
	local from = self.room:getCurrent()
	if self:isEnemy(who) then
		if card:isKindOf("GodSalvation") and who:isWounded() and self:hasTrickEffective(card, who, from) then
			if who:hasSkill("manjuan") and who:getPhase() == sgs.Player_NotActive then return true end
			if self:isWeak(who) then return true end
			if self:hasSkills(sgs.masochism_skill, who) then return true end
		end
		return false
	elseif self:isFriend(who) then
		if self:hasSkills("noswuyan", who) and from:objectName() ~= who:objectName() then return true end
		if card:isKindOf("GodSalvation") and not who:isWounded() then
			if who:hasSkill("manjuan") and who:getPhase() == sgs.Player_NotActive then return false end
			if self:needKongcheng(who, true) then return false end
			return true
		end
		if card:isKindOf("GodSalvation") and who:isWounded() and self:hasTrickEffective(card, who, from) then
			if self:needToLoseHp(who, nil, nil, true, true) and not self:needKongcheng(who, true) then return true end
			return false
		end
		if card:isKindOf("IronChain") and (self:needKongcheng(who, true) or (who:isChained() and self:hasTrickEffective(card, who, from))) then
			return false
		end
		if card:isKindOf("AmazingGrace") then return not self:hasTrickEffective(card, who, from) end
		return true
	end
end

sgs.ai_skill_use["@@huangen"] = function(self, prompt)
	local card = sgs.Card_Parse(self.player:getTag("Huangen_user"):toString())
	local first_index, second_index, third_index, forth_index, fifth_index
	local i = 1
	local players = sgs.QList2Table(self.room:getAllPlayers())
	self:sort(players, "defense")
	for _, player in ipairs(players) do
		if player:hasFlag("HuangenTarget") then
			if not first_index and need_huangen(self, player) then
				first_index = i
			elseif not second_index and need_huangen(self, player) then
				second_index = i
			elseif not third_index and need_huangen(self, player) then
				third_index = i
			elseif not forth_index and need_huangen(self, player) then
				forth_index = i
			elseif need_huangen(self, player) then
				fifth_index = i
			end
			if fifth_index then break end
		end
		i = i + 1
	end
	if not first_index then return "." end

	local first, second, third, forth, fifth
	if first_index then
		first = players[first_index]:objectName()
	end
	if second_index then
		second = players[second_index]:objectName()
	end
	if third_index then
		third = players[third_index]:objectName()
	end
	if forth_index then
		forth = players[forth_index]:objectName()
	end
	if fifth_index then
		fifth = players[fifth_index]:objectName()
	end

	local hp = self.player:getHp()
	if fifth_index and hp >= 5 then
		return ("@HuangenCard=.->%s+%s+%s+%s+%s"):format(first, second, third, forth, fifth)
	elseif forth_index and hp >= 4 then
		return ("@HuangenCard=.->%s+%s+%s+%s"):format(first, second, third, forth)
	elseif third_index and hp >= 3 then
		return ("@HuangenCard=.->%s+%s+%s"):format(first, second, third)
	elseif second_index and hp >= 2 then
		return ("@HuangenCard=.->%s+%s"):format(first, second)
	elseif first_index and hp >= 1 then
		return ("@HuangenCard=.->%s"):format(first)
	end
end

sgs.ai_card_intention.HuangenCard = function(self, card, from, tos)
	local cardx = sgs.Card_Parse(from:getTag("Huangen_user"):toString())
	if not cardx then return end
	for _, to in ipairs(tos) do
		local intention = -80
		if cardx:isKindOf("GodSalvation") and to:isWounded() and not self:needToLoseHp(to, nil, nil, true, true) then intention = 50 end
		if self:needKongcheng(to, true) then intention = 0 end
		if cardx:isKindOf("AmazingGrace") and self:hasTrickEffective(cardx, to) then intention = 0 end
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_skill_invoke.hantong = true

sgs.ai_skill_invoke.hantong_acquire = function(self, data)
	local skill = data:toString()
	if skill == "hujia" and not self.player:hasSkill("hujia") then
		local can_invoke = false
		for _, friend in ipairs(self.friends_noself) do
			if friend:getKingdom() == "wei" and getCardsNum("Jink", friend) > 0 then can_invoke = true end
		end
		if can_invoke then return sgs.ai_skill_invoke.hujia end
	elseif skill == "jijiang" and not self.player:hasSkill("jijiang") then
		local can_invoke = false
		for _, friend in ipairs(self.friends_noself) do
			if friend:getKingdom() == "shu" and getCardsNum("Slash", friend) > 0 then can_invoke = true end
		end
		if can_invoke then return sgs.ai_skill_invoke.jijiang end
	elseif skill == "jiuyuan" and not self.player:hasSkill("jiuyuan") then
		return true
	elseif skill == "xueyi" and not self.player:hasSkill("xueyi") then
		local maxcards = self.player:getMaxCards()
		local can_invoke = false
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:getKingdom() == "qun" then can_invoke = true end
		end
		if can_invoke then return self.player:getHandcardNum() > maxcards end
	end
	return false
end

local hantong_skill = {}
hantong_skill.name = "hantong"
table.insert(sgs.ai_skills, hantong_skill)
hantong_skill.getTurnUseCard = function(self)
	if self.player:hasLordSkill("jijiang") or self.player:getPile("edict"):isEmpty() or not self:slashIsAvailable() then return end
	local can_invoke = false
	for _, friend in ipairs(self.friends_noself) do
		if friend:getKingdom() == "shu" and getCardsNum("Slash", friend) > 0 then can_invoke = true end
	end
	if not can_invoke then return end
	return sgs.Card_Parse("@HantongCard=.")
end

sgs.ai_skill_use_func.HantongCard = function(card, use, self)
	local jcard = sgs.Card_Parse("@JijiangCard=.")
	local dummy_use = { isDummy = true }
	self:useSkillCard(jcard, dummy_use)
	if dummy_use.card then use.card = card end
end

sgs.ai_use_value.HantongCard = sgs.ai_use_value.JijiangCard
sgs.ai_use_priority.HantongCard = sgs.ai_use_priority.JijiangCard
sgs.ai_card_intention.HantongCard = sgs.ai_card_intention.JijiangCard
sgs.ai_chaofeng.diy_liuxie = 3

sgs.ai_skill_use["@@diyyicong"] = function(self, prompt)
	local yicongcards = {}
	
	if self:needToThrowArmor() then
		return "@DIYYicongCard=" .. self.player:getArmor():getId() .. "->."
	end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if self:getKeepValue(card) < 6
			and (not self.player:getArmor() or card:getId() ~= self.player:getArmor():getEffectiveId())
			and (not self.player:getDefensiveHorse() or card:getId() ~= self.player:getDefensiveHorse():getEffectiveId()) then
			table.insert(yicongcards, card:getId())
			break
		end
	end
	if #yicongcards > 0 then
		return "@DIYYicongCard=" .. table.concat(yicongcards, "+") .. "->."
	end
	return "."
end
