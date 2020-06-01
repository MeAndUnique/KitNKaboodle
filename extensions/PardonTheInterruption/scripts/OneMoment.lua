-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--TODO
	-- disable when manul
	-- other roll types
	-- different modifiers (add die, add static, reroll, advantage)

local originalAttackRoll;
local originalCheckRoll;
local originalConcentrationRoll;
local originalDeathRoll;
local originalSaveRoll;
local originalSkillRoll;

local originalDecodeAdvantage;

local functionMap;

local id = 0;
local queue = {};

local alreadyDecoded = false;

local effectsByCTActor = {}
local effectsByNode = {}

-- Initialization
function onInit()
	originalAttackRoll = ActionAttack.onAttack;
	originalCheckRoll = ActionCheck.onRoll;
	originalConcentrationRoll = ActionSave.onConcentrationRoll;
	originalDeathRoll = ActionSave.onDeathRoll;
	originalSaveRoll = ActionSave.onSave;
	originalSkillRoll = ActionSkill.onRoll;
	
	originalDecodeAdvantage = ActionsManager2.decodeAdvantage;
	ActionsManager2.decodeAdvantage = decodeAdvantage;

	functionMap = {
		attack = Interruptions.getAttackingInterruptions,
		save = Interruptions.getSavingInterruptions,
	}

	ActionsManager.registerResultHandler("attack", onAttackRoll);
	ActionsManager.registerResultHandler("check", onCheckRoll);
	ActionsManager.registerResultHandler("concentration", onConcentrationRoll);
	ActionsManager.registerResultHandler("death", onDeathRoll);
	ActionsManager.registerResultHandler("save", onSaveRoll);
	ActionsManager.registerResultHandler("skill", onSkillRoll);
	
	ActionsManager.registerResultHandler("moment", onMomentRoll);

	initializeEffects();
	CombatManager.setCustomAddCombatantEffectHandler(onEffectAdded)
	-- CombatManager.setCustomDeleteCombatantEffectHandler(debugremoved)
end

function initializeEffects()
	for _,nodeActor in pairs(CombatManager.getCombatantNodes()) do
		for _,nodeEffect in pairs(DB.getChildren(nodeActor, "effects")) do
			onEffectAdded(nodeActor, nodeEffect);
			onEffectUpdated(nodeEffect, false);
		end
	end
end

function onEffectAdded(nodeActor, nodeEffect)
	nodeActor.onDelete = onActorDeleted;
	nodeEffect.onDelete = onEffectDelected;
	nodeEffect.onChildUpdate = onEffectUpdated;

	local effect = {
		nodeActor = nodeActor,
		nodeEffect = nodeEffect
	};

	effectsByNode[nodeEffect] = effect;

	local actorEffects = effectsByCTActor[nodeActor];
	if not actorEffects then
		actorEffects = {};
		effectsByCTActor[nodeActor] = actorEffects;
	end
	actorEffects[nodeEffect] = effect;
end

function onActorDeleted(nodeActor)
	effectsByCTActor[nodeActor] = nil;
end

function onEffectDelected(nodeEffect)
	local effect = effectsByNode[nodeEffect];
	if effect and effect.nodeActor and effectsByCTActor[effect.nodeActor] then
		effectsByCTActor[effect.nodeActor][nodeEffect] = nil;
	end
	effectsByNode[nodeEffect] = nil;
end

function onEffectUpdated(nodeEffect, bChildListUpdated)
	if not bChildListUpdated then
		local effect = effectsByNode[nodeEffect];
		if effect then
			effect.isActive = DB.getValue(nodeEffect, "isactive", 0) == 1;
			effect.label = DB.getValue(nodeEffect, "label");
		end
	end
end

-- Public methods
function setAlreadyDecoded()
	alreadyDecoded = true;
end

function clearAlreadyDecoded()
	alreadyDecoded = false;
end

function rollMoment(rSource, rTarget, rRoll, fOriginal, rInterruption)
	local sId = getId(rRoll);

	-- ActionsManager2.decodeAdvantage(rRoll);

	Debug.chat(rRoll);

	aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {rInterruption.name}, false, nil);
	local modifierRoll = {
		sType = "moment",
		aDice = {},
		nMod = nAddMod,
		sDesc = " ["..rInterruption.name.." "..StringManager.convertDiceToString(aAddDice, nAddMod, true).."]",
		sId = tostring(id)
	};
	for _,vDie in ipairs(aAddDice) do
		if vDie:sub(1,1) == "-" then
			table.insert(modifierRoll.aDice, "-b" .. vDie:sub(3));
		else
			table.insert(modifierRoll.aDice, "b" .. vDie:sub(2));
		end
	end

	if queue[modifierRoll.sId] then
		queue[modifierRoll.sId].aUsedInterruptions[rInterruption.id] = true;
	else
		rRoll.sId = sId;
		queue[modifierRoll.sId] = {
			rSource = rSource,
			rTarget = rTarget,
			rRoll = rRoll,
			fOriginal = fOriginal,
			aUsedInterruptions = {[rInterruption.id] = true}};
	end

	-- local modifierRoll = {sType="moment", aDice={"b8"}, id=id};
	ActionsManager.roll(nil, nil, modifierRoll, false);
end

-- Handlers
function onAttackRoll(rSource, rTarget, rRoll)
	checkResult(rSource, rTarget, rRoll, originalAttackRoll);
end

function onCheckRoll(rSource, rTarget, rRoll)
	checkResult(rSource, rTarget, rRoll, originalCheckRoll);
end

function onConcentrationRoll(rSource, rTarget, rRoll)
	checkResult(rSource, rTarget, rRoll, originalConcentrationRoll);
end

function onDeathRoll(rSource, rTarget, rRoll)
	checkResult(rSource, rTarget, rRoll, originalDeathRoll);
end

function onSaveRoll(rSource, rTarget, rRoll)
	checkResult(rSource, rTarget, rRoll, originalSaveRoll);
end

function onSkillRoll(rSource, rTarget, rRoll)
	checkResult(rSource, rTarget, rRoll, originalSkillRoll);
end

function onMomentRoll(rSource, rTarget, rRoll)
	-- Debug.chat(rRoll);
	
	local data = queue[rRoll.sId];
	-- Debug.chat(data);
	data.rRoll.sDesc = data.rRoll.sDesc .. rRoll.sDesc;
	-- data.rRoll.aDice[#data.rRoll.aDice+1] = momentDie;
	if rRoll.aDice.expr then
		rRoll.aDice.expr = nil;
	end
	if data.rRoll.aDice.expr then
		data.rRoll.aDice.expr = nil;
	end

	-- Debug.chat(rRoll.aDice);
	-- Debug.chat(data.rRoll.aDice);

	for _,die in ipairs(rRoll.aDice) do
		-- Debug.chat(die);
		table.insert(data.rRoll.aDice, die);
	end
	data.rRoll.nMod = data.rRoll.nMod + rRoll.nMod;

	-- alreadyDecoded = true;
	if not checkResult(data.rSource, data.rTarget, data.rRoll, data.fOriginal, data.aUsedInterruptions) then
		queue[rRoll.sId] = nil;
	end
	-- alreadyDecoded = false;
end

-- Overrides
function decodeAdvantage(rRoll)
	if not alreadyDecoded then
		originalDecodeAdvantage(rRoll);
	end
end

-- Utility
function checkResult(rSource, rTarget, rRoll, fOriginal, aUsedInterruptions)
	-- TODO (dis)advantage handling.....

	if rRoll.bSecret then
		fOriginal(rSource, rTarget, rRoll);
		return false;
	end

	if not aUsedInterruptions then
		aUsedInterruptions = {};
	end

	local actor = ActorManager.getCTNode(rSource);
	local success = false;
	if rRoll.nTarget then
		-- success function map?
		success = ActionsManager.total(rRoll) >= rRoll.nTarget;
	end
	local interruptions = {};
	if actor and effectsByCTActor[actor] then
		for _, effect in pairs(effectsByCTActor[actor]) do
			if effect.isActive and (effect.label or "") ~= "" and effect.label:match("%([iI]%)") then
				for _,interruption in ipairs(Interruptions.getInterruptions(effect.label, rRoll, success)) do
					if not aUsedInterruptions[interruption.id] then
						table.insert(interruptions, interruption);
					end
				end
			end
		end
	end

	-- local switch = functionMap[rRoll.sType];
	-- local interruptions = type(switch) == "function" and switch();
	-- local bfoundInterruption = false;
	-- if interruptions then
	-- 	for _,interruption in pairs(interruptions) do
	-- 		local raw = rRoll.aDice[1].result;
	-- 		local total = ActionsManager.total(rRoll);
	-- 		if (interruption.attacking.sAuto == "total" and total > interruption.attacking.nAutoAbove and total < interruption.attacking.nAutoBelow) or
	-- 			(interruption.attacking.sAuto == "raw" and raw > interruption.attacking.nAutoAbove and raw < interruption.attacking.nAutoBelow) then
	-- 			rollMoment(rSource, rTarget, rRoll, fOriginal);
	-- 			return;
	-- 		elseif (interruption.attacking.sPrompt == "total" and total > interruption.attacking.nPromptAbove and total < interruption.attacking.nPromptBelow) or
	-- 			(interruption.attacking.sPrompt == "raw" and raw > interruption.attacking.nPromptAbove and raw < interruption.attacking.nPromptBelow) then
	-- 			bfoundInterruption = true;
	-- 		end
	-- 	end
	-- end

	local bfoundInterruption = #interruptions > 0;

	if #interruptions > 0 then
		local window = Interface.openWindow("onemoment", "");
		window.addRoll(rSource, rTarget, rRoll, fOriginal, interruptions[1]);
	else
		fOriginal(rSource, rTarget, rRoll);
	end

	return bfoundInterruption;
end

function getId(rRoll)
	local sId;
	if (rRoll.sId or "") == "" then
		id = id + 1;
		if id > 1000 then
			id = 1;
		end
		sId = tostring(id);
	else
		sId = rRoll.sId;
	end
	return sId;
end
