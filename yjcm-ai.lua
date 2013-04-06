function sgs.ai_cardsview.jiushi(class_name, player)
	if class_name == "Analeptic" then
		if player:hasSkill("jiushi") and player:faceUp() then
			return ("analeptic:jiushi[no_suit:0]=.")
		end
	end
end

function sgs.ai_skill_invoke.jiushi(self, data)
	return not self.player:faceUp()
end

sgs.ai_skill_askforag.luoying = function(self, card_ids)
	return -1
end

sgs.ai_skill_use["@@jujian"] = function(self, prompt)
	local needfriend = 0
	local nobasiccard = -1
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if self:needToThrowArmor() then
		nobasiccard = self.player:getArmor():getId()
	else
		self:sortByKeepValue(cards)
		for _,card in ipairs(cards) do
			if card:getTypeId() ~= sgs.Card_Basic then nobasiccard = card:getEffectiveId() end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) or friend:getHandcardNum() < 2 or not friend:faceUp() 
		or (friend:getArmor() and friend:getArmor():objectName() == "Vine" and (friend:isChained() and not self:isGoodChainPartner(friend))) then
			needfriend = needfriend + 1
		end
	end
	if nobasiccard < 0 or needfriend < 1 then return "." end
	self:sort(self.friends_noself,"defense")
	for _, friend in ipairs(self.friends_noself) do
		if not friend:faceUp() then
			return "@JujianCard="..nobasiccard.."->"..friend:objectName()
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getArmor() and friend:getArmor():objectName() == "Vine" and (friend:isChained() and not self:isGoodChainPartner(friend)) then
			return "@JujianCard="..nobasiccard.."->"..friend:objectName()
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			return "@JujianCard="..nobasiccard.."->"..friend:objectName()
		end
	end
	return "@JujianCard="..nobasiccard.."->"..self.friends_noself[1]:objectName()
end

sgs.ai_skill_choice.jujian = function(self, choices)
	if not self.player:faceUp() then return "reset" end
	if self:isEquip("Vine") and self.player:isChained() and not self:isGoodChainPartner() then 
		return "reset"
	end
	if self:isWeak() and self.player:isWounded() then return "recover" end
	if self.player:hasSkill("manjuan") then
		if self.player:isWounded() then return "recover" end
		if self.player:isChained() then return "reset" end
	end
	return "draw"
end

sgs.ai_card_intention.JujianCard = -100
sgs.ai_use_priority.JujianCard = 4.5

sgs.jujian_keep_value = {
	Peach = 6,
	Jink = 5,
	EquipCard = 5,
	Duel = 5,
	FireAttack = 5,
	ArcheryAttack = 5,
	SavageAssault = 5
}

function sgs.ai_armor_value.yizhong(card)
	if not card then return 4 end
end

local xinzhan_skill={}
xinzhan_skill.name="xinzhan"
table.insert(sgs.ai_skills,xinzhan_skill)
xinzhan_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("XinzhanCard") and self.player:getHandcardNum() > self.player:getMaxHp() then
		return sgs.Card_Parse("@XinzhanCard=.")
	end
end

sgs.ai_skill_use_func.XinzhanCard=function(card,use,self)
	use.card = card
end

sgs.ai_use_value.XinzhanCard = 4.4
sgs.ai_use_priority.XinzhanCard = 9.4

function sgs.ai_slash_prohibit.huilei(self, to, card, from)
	if from:hasSkill("jueqing") then return false end
	if from:hasFlag("nosjiefanUsed") then return false end
	if self:isFriend(to) and self:isWeak(to) then return true end
	return #self.enemies>1 and self:isWeak(to) and from:getHandcardNum()>3
end

sgs.ai_chaofeng.masu = -4

sgs.ai_skill_invoke.enyuan = function(self, data)
	local move = data:toMoveOneTime()
	if move and move.from and move.card_ids and move.card_ids:length() > 0 then
		local from = findPlayerByObjectName(self.room, move.from:objectName())
		if from then return self:isFriend(from) and not self:needKongcheng(from, true) end
	end
	local damage = data:toDamage()
	if damage.from and damage.from:isAlive() then
		if self:isFriend(damage.from) then 
			if self:getOverflow(damage.from) > 2 then return true end
			if self:needToLoseHp(damage.from, self.player, nil, true) and not self:hasSkills(sgs.masochism_skill, damage.from) then return true end
			if not self:hasLoseHandcardEffective(damage.from) and not damage.from:isKongcheng() then return true end
			return false
		else
			return true
		end
	end		
	return
end

sgs.ai_choicemade_filter.skillInvoke.enyuan = function(player, promptlist, self)
	local invoked = (promptlist[3] == "yes")
	local intention = 0

	if sgs.enyuan_damage_target then
		if not invoked then
			intention = -10
		elseif self:needToLoseHp(sgs.enyuan_damage_target, player, nil, true) then
			intention = 0
		elseif not self:hasLoseHandcardEffective(sgs.enyuan_damage_target) and not sgs.enyuan_damage_target:isKongcheng() then
			intention = 0
		elseif self:getOverflow(sgs.enyuan_damage_target) <= 2 then
			intention = 10
		end
		sgs.updateIntention(player, sgs.enyuan_damage_target, intention)
	elseif sgs.enyuan_drawcard_target then
		if not invoked and not self:needKongcheng(sgs.enyuan_drawcard_target, true) then
			intention = 10
		elseif not self:needKongcheng(from, true) then
			intention = -10
		end
		sgs.updateIntention(player, sgs.enyuan_drawcard_target, intention)
	end

	sgs.enyuan_damage_target = nil
	sgs.enyuan_drawcard_target = nil
end

sgs.ai_skill_discard.enyuan = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = self.player:getHandcards()
	local fazheng = self.room:findPlayerBySkillName("enyuan")
	cards = sgs.QList2Table(cards)
	if self:needToLoseHp(self.player, fazheng, nil, true) and not self:hasSkills(sgs.masochism_skill) then return {} end
	if self:isFriend(fazheng) then
		for _, card in ipairs(cards) do
			if isCard("Peach", card, fazheng) and ((not self:isWeak() and self:getCardsNum("Peach") > 0) or self:getCardsNum("Peach") > 1) then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
			if isCard("Analeptic", card, fazheng) and self:getCardsNum("Analeptic") > 1 then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
			if isCard("Jink", card, fazheng) and self:getCardsNum("Jink") > 1 then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
		end
	end
	
	if self:needToLoseHp() and not self:hasSkills(sgs.masochism_skill) then return {} end
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then
			table.insert(to_discard, card:getEffectiveId())
			return to_discard
		end
	end
	
	return {}
end

function sgs.ai_slash_prohibit.enyuan(self, to, card, from)
	if self:isFriend(to) then return false end
	if from:hasSkill("jueqing") then return false end
	if from:hasSkill("nosqianxi") and from:distanceTo(to) == 1 then return false end
	if from:hasFlag("nosjiefanUsed") then return false end
	if self:needToLoseHp(from) and not self:hasSkills(sgs.masochism_skill, from) then return false end
	local num = from:getHandcardNum()
	if num >= 3 or self:hasSkills("lianying|shangshi|nosshangshi", from) or (from:hasSkill("kongcheng") and num == 2) then return false end
	return true
end

sgs.ai_need_damaged.enyuan = function (self, attacker, player)
	if not player:hasSkill("enyuan") then return false end
	if self:isEnemy(attacker, player) and self:isWeak(attacker) and attacker:getHandcardNum() < 3 
	  and not self:hasSkills("lianying|shangshi|nosshangshi", attacker)
	  and not (attacker:hasSkill("kongcheng") and attacker:getHandcardNum() > 0)
	  and not (self:needToLoseHp(attacker) and not self:hasSkills(sgs.masochism_skill, attacker)) then
		return true
	end
	return false
end

function sgs.ai_cardneed.enyuan(to, card)
	return getKnownCard(to, "Card", false) < 2
end

sgs.ai_skill_use["@@xuanhuo"] = function(self, prompt)
	local lord = self.room:getLord()
	self:sort(self.enemies, "defense")
	if lord and self:isEnemy(lord) then  --killloyal
		for _, enemy in ipairs(self.enemies) do
			if (self:getDangerousCard(lord) or self:getValuableCard(lord)) 
				and not self:hasSkills(sgs.lose_equip_skill, enemy) and not (enemy:hasSkill("tuntian") and enemy:hasSkill("zaoxian"))
				and lord:canSlash(enemy) and (enemy:getHp() < 2 and not enemy:hasSkill("buqu"))
				and sgs.getDefense(enemy) < 2 then
					lord:setFlags("xuanhuo_target")
					return "@XuanhuoCard=.->"..lord:objectName()
			end
		end
	end
	
	for _, enemy in ipairs(self.enemies) do --robequip
		for _, enemy2 in ipairs(self.enemies) do	
			if enemy:canSlash(enemy2) and (self:getDangerousCard(enemy) or self:getValuableCard(enemy)) 
				and not self:hasSkills(sgs.lose_equip_skill, enemy) and not (enemy:hasSkill("tuntian") and enemy:hasSkill("zaoxian"))
				and not self:needLeiji(enemy2, enemy) and not self:getDamagedEffects(enemy2, enemy)
				and not self:needToLoseHp(enemy2, enemy, nil, true)
				or (enemy:hasSkill("manjuan") and enemy:getCards("he"):length() > 1 and getCardsNum("Slash", enemy) == 0) then
					enemy:setFlags("xuanhuo_target")
					return "@XuanhuoCard=.->"..enemy:objectName()
			end
		end
	end
		
	if #self.friends_noself == 0 then return "." end
	self:sort(self.friends_noself, "defense")

	for _, friend in ipairs(self.friends_noself) do
		if self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty() and not friend:hasSkill("manjuan") then
			friend:setFlags("xuanhuo_target")
			return "@XuanhuoCard=.->"..friend:objectName()
		end
		
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("tuntian") and friend:hasSkill("zaoxian") and not friend:hasSkill("manjuan") then
			friend:setFlags("xuanhuo_target")
			return "@XuanhuoCard=.->"..friend:objectName()
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		for _, enemy in ipairs(self.enemies) do
			if friend:canSlash(enemy) and (enemy:getHp() < 2 and not enemy:hasSkill("buqu"))
			  and sgs.getDefense(enemy) < 2 and not friend:hasSkill("manjuan") then
				friend:setFlags("xuanhuo_target")
				return "@XuanhuoCard=.->"..friend:objectName()
			end
		end
	end
	if not self.player:hasSkill("enyuan") then return "." end
	for _, friend in ipairs(self.friends_noself) do
		if not friend:hasSkill("manjuan") then
			friend:setFlags("xuanhuo_target")
			return "@XuanhuoCard=.->"..friend:objectName()
		end
	end
	return "."
end

sgs.ai_skill_playerchosen.xuanhuo = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_skill_cardask["xuanhuo-slash"] = function(self, data, pattern, target, target2)
	local fazheng = self.player:getRoom():getCurrent()
	if target and target2 then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:isFriend(target2) and self:slashIsEffective(slash, target2) then
				if self:needLeiji(target2, self.player) then return slash:toString() end
				if self:getDamagedEffects(target2, self.player) then return slash:toString() end
				if not self:isFriend(fazheng) and self:needToLoseHp(target2, self.player) then return slash:toString() end
			end
			
			if self:isFriend(target2) and not self:isFriend(fazheng) and not self:slashIsEffective(slash, target2) then
				return slash:toString()
			end

			if self:isEnemy(target2) and self:slashIsEffective(slash, target2) 
				and not self:getDamagedEffects(target2, self.player, true) and not self:needLeiji(target2, self.player) then
					return slash:toString()
			end
		end
		
		if self:hasSkills(sgs.lose_equip_skill) and not self.player:getEquips():isEmpty() and not self.player:hasSkill("manjuan") then return "." end
		
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:isFriend(target2) and not self:isFriend(fazheng) then
				if (target2:getHp() > 3 or not self:canHit(target2, self.player, self:hasHeavySlashDamage(self.player, slash, target2)))
					and not target2:getRole() == "lord" then
						return slash:toString()
				end
				if self:needToLoseHp(target2, self.player) then return slash:toString() end
			end
			
			if not self:isFriend(target2) and not self:isFriend(fazheng) then
				if not self:needLeiji(target2, self.player) then return slash:toString() end
				if not self:slashIsEffective(slash, target2) then return slash:toString() end			
			end
		end
	end
	return "."
end

sgs.ai_playerchosen_intention.xuanhuo = 10
sgs.ai_card_intention.XuanhuoCard = 0

sgs.ai_chaofeng.fazheng = -3

sgs.ai_skill_choice.xuanfeng = function(self, choices)
	local erzhang = self.room:findPlayerBySkillName("guzheng")
	if erzhang and self:isEnemy(erzhang) and self.room:getCurrent():getPhase() == sgs.Player_Discard then return "nothing" end
	return "throw"
end

sgs.ai_skill_use["@@xuanfeng"] = function(self, prompt)
	local first
	local second	
	first = self:findPlayerToDiscard("he", "noself")
	second = self:findPlayerToDiscard("he", "noself", first)

	if first then
		if first and not second then
			if self:isFriend(first) then return "." end
			return ("@XuanfengCard=.->%s"):format(first:objectName())
		else
			return ("@XuanfengCard=.->%s+%s"):format(first:objectName(), second:objectName())
		end
	end
	return "."
end

sgs.ai_card_intention.XuanfengCard = function(self, card, from, tos)
	local intention = 80
	for i=1, #tos do
		local to = tos[i]
		if to:hasSkill("kongcheng") and to:getHandcardNum() == 1 and to:getHp() <= 2 then
			intention = 0
		end
		if self:needToThrowArmor(to) then
			  intention = 0
		end
		sgs.updateIntention(from, tos[i], intention)
	end
end
sgs.xuanfeng_keep_value = sgs.xiaoji_keep_value

sgs.ai_skill_playerchosen.xuanfeng = function(self, targets)	
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defense")
	for _, enemy in ipairs(self.enemies) do
		if (not self:doNotDiscard(enemy) or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() and
		not (enemy:hasSkill("guzheng") and self.room:getCurrent():getPhase() == sgs.Player_Discard) then
			return enemy
		end
	end
end

sgs.ai_skill_invoke.pojun = function(self, data)
	local damage = data:toDamage()

	if not damage.to:faceUp() then
		return self:isFriend(damage.to)
	end

	local good = damage.to:getHp() > 2
	if self:isFriend(damage.to) then
		return good
	elseif self:isEnemy(damage.to) then
		return not good
	end
end

ganlu_skill={}
ganlu_skill.name="ganlu"
table.insert(sgs.ai_skills,ganlu_skill)
ganlu_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("GanluCard") then
		return sgs.Card_Parse("@GanluCard=.")
	end
end

sgs.ai_skill_use_func.GanluCard = function(card, use, self)
	local lost_hp = self.player:getLostHp()
	local target, min_friend, max_enemy
	
	local compare_func = function(a, b)
		return a:getEquips():length() > b:getEquips():length()
	end
	table.sort(self.enemies, compare_func)
	table.sort(self.friends, compare_func)
	
	self.friends = sgs.reverse(self.friends)
	
	for _, friend in ipairs(self.friends) do
		for _, enemy in ipairs(self.enemies) do
			if not self:hasSkills(sgs.lose_equip_skill, enemy) then
				local ee = enemy:getEquips():length()
				local fe = friend:getEquips():length()
				local value = self:evaluateArmor(enemy:getArmor(),friend) - self:evaluateArmor(friend:getArmor(),enemy)
					- self:evaluateArmor(friend:getArmor(),friend) + self:evaluateArmor(enemy:getArmor(),enemy)
				if math.abs(ee - fe) <= lost_hp and ee > 0 and (ee > fe or ee == fe and value>0) then
					if self:hasSkills(sgs.lose_equip_skill, friend) then
						use.card = sgs.Card_Parse("@GanluCard=.")
						if use.to then
							use.to:append(friend)
							use.to:append(enemy)
						end
						return
					elseif not min_friend and not max_enemy then
						min_friend = friend
						max_enemy = enemy
					end
				end
			end
		end
	end	
	if min_friend and max_enemy then
		use.card = sgs.Card_Parse("@GanluCard=.")
		if use.to then 
			use.to:append(min_friend)
			use.to:append(max_enemy)
		end
		return
	end
	
	target = nil
	for _,friend in ipairs(self.friends) do
		if (friend:hasArmorEffect("SilverLion") and friend:isWounded()) or (self:hasSkills(sgs.lose_equip_skill, friend)
			and not friend:getEquips():isEmpty()) then target = friend break end
	end
	if not target then return end
	for _,friend in ipairs(self.friends) do
		if friend:objectName() ~= target:objectName() and math.abs(friend:getEquips():length() - target:getEquips():length()) <= lost_hp then
			use.card = sgs.Card_Parse("@GanluCard=.")			
			if use.to then
				use.to:append(friend)
				use.to:append(target)
			end
			return
		end
	end
end

sgs.ai_use_priority.GanluCard = sgs.ai_use_priority.Dismantlement + 0.1
sgs.dynamic_value.control_card.GanluCard = true

sgs.ai_card_intention.GanluCard = function(self,card, from, to)
	local compare_func = function(a, b)
		return a:getEquips():length() < b:getEquips():length()
	end
	table.sort(to, compare_func)

	if to[1]:getEquips():length() < to[2]:getEquips():length() then
		sgs.updateIntention(from, to[1], -80)
	end
end

sgs.ai_skill_invoke.buyi = function(self, data)
	local dying = data:toDying()
	local isFriend = false
	local allBasicCard = true
	if dying.who:isKongcheng() then return false end

	isFriend = not self:isEnemy(dying.who)
	if not sgs.GetConfig("EnableHegemony", false) and self.role == "renegade" and not (dying.who:isLord() or dying.who:objectName() == self.player:objectName()) and 
			(sgs.current_mode_players["loyalist"] == sgs.current_mode_players["rebel"] or self.room:getCurrent():objectName() == self.player:objectName()) then
		isFriend = false
	end
	
	local knownNum = 0
	local cards = dying.who:getHandcards()
	for _, card in sgs.qlist(cards) do
		local flag=string.format("%s_%s_%s","visible",self.player:objectName(),dying.who:objectName())
		if dying.who:objectName() == self.player:objectName() or card:hasFlag("visible") or card:hasFlag(flag) then
			knownNum = knownNum + 1
			if card:getTypeId() ~= sgs.Card_Basic then allBasicCard = false	end
		end
	end
	if knownNum < dying.who:getHandcardNum() then allBasicCard = false end
	
	local ret = isFriend and (not allBasicCard)
	-- if ret and dying.who:objectName() ~= self.player:objectName() then sgs.updateIntention(self.player, dying.who, -80) end
	return ret
end

sgs.ai_cardshow.buyi = function(self, requestor)
	assert(self.player:objectName() == requestor:objectName())

	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:getTypeId() ~= sgs.Card_Basic then
			return card
		end
	end

	return self.player:getRandomHandCard()
end

sgs.ai_choicemade_filter.cardChosen.buyi = function(player, promptlist, self)
	for _, ap in sgs.qlist(self.room:getOtherPlayers(player)) do
		if ap:hasFlag("dying") and ap:getHp() < 1 then
			sgs.updateIntention(player, ap, -10)
			break
		end
	end
end

mingce_skill={}
mingce_skill.name="mingce"
table.insert(sgs.ai_skills,mingce_skill)
mingce_skill.getTurnUseCard=function(self)
	if self.player:hasUsed("MingceCard") then return end

	local card
	if self:needToThrowArmor() then
		card = self.player:getArmor()
	end
	if not card then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:isKindOf("Slash") or hcard:isKindOf("EquipCard") then
				card = hcard
				break
			end
		end
	end
	if not card then
		local ecards = self.player:getCards("e")
		ecards = sgs.QList2Table(ecards)

		for _, ecard in ipairs(ecards) do
			if ecard:isKindOf("Weapon") or ecard:isKindOf("OffensiveHorse") then
				card = ecard
				break
			end
		end
	end
	if card then
		card = sgs.Card_Parse("@MingceCard=" .. card:getEffectiveId())
		return card
	end

	return nil
end

sgs.ai_skill_use_func.MingceCard=function(card,use,self)
	local target
	local friends = self.friends_noself
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)

	local canMingceTo = function(player)
		local canGive = not (player:hasSkill("kongcheng") and player:isKongcheng())
		return canGive or (not canGive and self:getEnemyNumBySeat(self.player,player) == 0)
	end

	self:sort(self.enemies, "defense")
	for _, friend in ipairs(friends) do
		if canMingceTo(friend) then
			for _, enemy in ipairs(self.enemies) do
				if friend:canSlash(enemy) and not self:slashProhibit(slash ,enemy) and sgs.getDefenseSlash(enemy) <= 2
						and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
						and enemy:objectName() ~= self.player:objectName() then
					target = friend
					self.room:setPlayerFlag(enemy, "mingceTarget")
					break
				end
			end
		end
		if target then break end
	end

	if not target then
		self:sort(friends, "defense")
		for _, friend in ipairs(friends) do
			if canMingceTo(friend) then
				target = friend
				break
			end
		end
	end

	if target then
		use.card=card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_event_callback[sgs.ChoiceMade].mingce=function(self, player, data)
	if self.player:getState() ~= "online" then return end

	local choices= data:toString():split(":")
	if choices[1]=="playerChosen"  and  choices[2]=="mingce" and choices[3] then
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:objectName() == choices[3] and not p:hasFlag("mingceTarget") then 
				 self.room:setPlayerFlag(p, "mingceTarget")
			end
		end		
	end	
end


sgs.ai_skill_choice.mingce = function(self, choices)
	local chengong = self.room:getCurrent()
	if not self:isFriend(chengong) then return "draw" end
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if player:hasFlag("mingceTarget") then 
			self.room:setPlayerFlag(player, "-mingceTarget")
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if not self:slashProhibit(slash ,player) then return "use" end
		end
	end
	return "draw"
end

sgs.ai_skill_playerchosen.mingce = function(self, targets)
	for _, player in sgs.qlist(targets) do
		if player:hasFlag("mingceTarget") then return player end
	end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

sgs.ai_playerchosen_intention.mingce = 80

sgs.ai_use_value.MingceCard = 5.9
sgs.ai_use_priority.MingceCard = 4

sgs.ai_card_intention.MingceCard = -70

sgs.ai_cardneed.mingce = sgs.ai_cardneed.equip
local jinjiu_skill={}
jinjiu_skill.name="jinjiu"
table.insert(sgs.ai_skills,jinjiu_skill)
jinjiu_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local anal_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:isKindOf("Analeptic") then
			anal_card = card
			break
		end
	end

	if anal_card then
		local suit = anal_card:getSuitString()
		local number = anal_card:getNumberString()
		local card_id = anal_card:getEffectiveId()
		local card_str = ("slash:jinjiu[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		return slash
	end
end

sgs.ai_filterskill_filter.jinjiu = function(card, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isKindOf("Analeptic") then return ("slash:jinjiu[%s:%s]=%d"):format(suit, number, card_id) end
end

local xianzhen_skill = {}
xianzhen_skill.name = "xianzhen"
table.insert(sgs.ai_skills, xianzhen_skill)
xianzhen_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	if not self.player:hasUsed("XianzhenCard") and not self.player:isKongcheng() then return sgs.Card_Parse("@XianzhenCard=.") 
	elseif self.player:hasUsed("XianzhenCard") and self.player:hasFlag("xianzhen_success") then
		local card_str = "@XianzhenSlashCard=."
		local card = sgs.Card_Parse(card_str)
		return card
	end
end

sgs.ai_skill_use_func.XianzhenSlashCard = function(card,use,self)
	local target = self.player:getTag("XianzhenTarget"):toPlayer()
	if self:askForCard("slash", "@xianzhen-slash") == "." then return end
	if self:getCard("Slash") and self.player:canSlash(target, nil, false) and target:isAlive() then
		use.card = card
	end
end

sgs.ai_skill_use_func.XianzhenCard = function(card, use, self)
	self:sort(self.enemies, "defense")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount - 1 end

	if slashcount > 0  then
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasFlag("AI_HuangtianPindian") and enemy:getHandcardNum() == 1 then
				use.card = sgs.Card_Parse("@XianzhenCard=" .. max_card:getId())
				if use.to then
					use.to:append(enemy)
					enemy:setFlags("-AI_HuangtianPindian")
				end
				return
			end
		end

		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = {isDummy = true}
		self:useBasicCard(slash, dummy_use)

		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self:canAttack(enemy, self.player) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point =enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point > enemy_max_point then
					use.card = sgs.Card_Parse("@XianzhenCard=" .. max_card:getId())
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self:canAttack(enemy, self.player) then
				if max_point >= 10 then
					use.card = sgs.Card_Parse("@XianzhenCard=" .. max_card:getId())
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end		
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	if self:getUseValue(cards[1]) >= 6 or self:getKeepValue(cards[1]) >= 6 then return end
	local shouldUse = self:getOverflow() > 0
	if shouldUse then
		for _, enemy in ipairs(self.enemies) do
			if not self:doNotDiscard(enemy, "h", true) and not enemy:isKongcheng() then
				use.card = sgs.Card_Parse("@XianzhenCard=" .. cards[1]:getId())
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_cardneed.xianzhen = function(to, card, self)
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s","visible",self.room:getCurrent():objectName(),to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber()>10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10 
	else
		return card:isKindOf("Slash") or card:isKindOf("Analeptic")
	end
end

function sgs.ai_skill_pindian.xianzhen(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	if requestor:getHandcardNum() <= 2 then return minusecard end
	return self:isFriend(requestor) and minusecard or ( maxcard:getNumber() < 6 and  minusecard or maxcard )
end

sgs.ai_card_intention.XianzhenCard = 70

sgs.dynamic_value.control_card.XianzhenCard = true

sgs.ai_use_value.XianzhenCard = 9.2
sgs.ai_use_priority.XianzhenCard = 9.2

sgs.ai_skill_cardask["@xianzhen-slash"] = function(self)
	local target = self.player:getTag("XianzhenTarget"):toPlayer()
	local slashes = self:getCards("Slash")
	for _, slash in ipairs(slashes) do
		if self:slashIsEffective(slash, target) then return slash:toString() end
	end
	return "."
end

sgs.ai_use_value.XianzhenSlashCard = 9.2
sgs.ai_use_priority.XianzhenSlashCard = 2.45

sgs.ai_skill_invoke.shangshi = function(self, data)	
	if self.player:getLostHp() == 1 then return sgs.ai_skill_invoke.lianying(self, data) end	
	return true	
end

sgs.ai_skill_invoke.quanji = true

sgs.ai_skill_discard.quanji = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	
	table.insert(to_discard, cards[1]:getEffectiveId())
	
	return to_discard
end

sgs.ai_skill_choice.zili = function(self, choice)
	if self.player:getHp() < self.player:getMaxHp()-1 then return "recover" end
	return "draw"
end

local paiyi_skill = {}
paiyi_skill.name = "paiyi"
table.insert(sgs.ai_skills, paiyi_skill)
paiyi_skill.getTurnUseCard = function(self)
	if not (self.player:getPile("power"):isEmpty()
		or self.player:hasUsed("PaiyiCard")) then
		return sgs.Card_Parse("@PaiyiCard=.")
	end
end

sgs.ai_skill_use_func.PaiyiCard = function(card, use, self)
	local target
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHandcardNum() < 2 and friend:getHandcardNum() + 1 < self.player:getHandcardNum() 
		  and not self:needKongcheng(friend, true) and not friend:hasSkill("manjuan") then
			target = friend
		end
		if target then break end
	end
	if not target then
		if self.player:getHandcardNum() < self.player:getHp() + self.player:getPile("power"):length() - 1 then
			target = self.player
		end
	end
	self:sort(self.friends_noself, "hp")
	self.friends_noself = sgs.reverse(self.friends_noself)
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHandcardNum() + 2 > self.player:getHandcardNum() 
			  and (self:getDamagedEffects(friend, self.player) or self:needToLoseHp(friend, self.player, nil, true))
			  and not friend:hasSkill("manjuan") then
				target = friend
			end
			if target then break end
		end
	end
	self:sort(self.enemies, "defense")
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if not (self:hasSkills(sgs.masochism_skill, enemy) and not self.player:hasSkill("jueqing")) 
			  and not self:hasSkills(sgs.cardneed_skill, enemy)
			  and not self:hasSkills("jijiu|tianxiang|buyi", enemy)
			  and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player)
			  and not (self:getDamagedEffects(enemy, self.player) or self:needToLoseHp(enemy, self.player))
			  and enemy:getHandcardNum() + 2 > self.player:getHandcardNum()
			  and not enemy:hasSkill("manjuan") then
				target = enemy
			end
			if target then break end
		end
	end

	if target then
		use.card = sgs.Card_Parse("@PaiyiCard=.")
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_askforag.paiyi = function(self, card_ids)
	self.paiyi = card_ids[math.random(1, #card_ids)]
	return self.paiyi
end