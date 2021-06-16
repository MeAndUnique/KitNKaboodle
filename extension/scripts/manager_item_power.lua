-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_RECHARGE_ITEM = "rechargeitem";
OOB_MSGTYPE_CREATE_ITEM_GROUP = "createitemgroup";
OOB_MSGTYPE_ROLL_DISCHARGED_ITEM = "rolldischargeditem";

RECHARGE_NONE = 0;
RECHARGE_NORMAL = 1;
RECHARGE_FULL = 2;

DAWN_TIME_OF_DAY = 0.25;
NOON_TIME_OF_DAY = 0.5;
DUSK_TIME_OF_DAY = 0.75;
MIDNIGHT_TIME_OF_DAY = 0;

FULL_RECHARGE_DAY_THRESHOLD = 5; -- Only a few items could potentially be missing charges after 5 days, and even for those it would be extremely unlikely.

local getItemSourceTypeOriginal;
local resetPowersOriginal;
local resetHealthOriginal;

local addEquippedSpellPCOriginal;
local nodeItemBeingEquiped = nil;

-- Initialization
function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_RECHARGE_ITEM, handleItemRecharge);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_CREATE_ITEM_GROUP, handleItemGroupCreation);
	ActionsManager.registerResultHandler("rechargeitem", onRechargeRoll);
	ActionsManager.registerResultHandler("dischargeitem", onDischargeRoll);

	if Session.IsHost then
		getItemSourceTypeOriginal = ItemManager.getItemSourceType;
		ItemManager.getItemSourceType = getItemSourceType;
		
		resetPowersOriginal = PowerManager.resetPowers;
		PowerManager.resetPowers = resetPowers;

		resetHealthOriginal = CombatManager2.resetHealth;
		CombatManager2.resetHealth = resetHealth;

		if LongTermEffects then
			DB.addHandler('calendar.dateinminutes', 'onUpdate', onTimeChanged);
		end

		if EquippedEffectsManager then
			addEquippedSpellPCOriginal = EquippedEffectsManager.addEquippedSpellPC;
			EquippedEffectsManager.addEquippedSpellPC = addEquippedSpellPC;
		end
	end
end

function onClose()
	ItemManager.getItemSourceType = getItemSourceTypeOriginal;
	PowerManager.resetPowers = resetPowersOriginal
	CombatManager2.resetHealth = resetHealthOriginal;

	if LongTermEffects then
		DB.removeHandler('calendar.dateinminutes', 'onUpdate', onTimeChanged);
	end

	if EquippedEffectsManager then
		addEquippedSpellPCOriginal = EquippedEffectsManager.addEquippedSpellPC;
	end
end

-- Overrides
function getItemSourceType(vNode)
	local sResult = getItemSourceTypeOriginal(vNode);
	if (sResult or "") == "" then
		local sNodePath = nil;
		if type(vNode) == "databasenode" then
			sNodePath = vNode.getPath();
		elseif type(vNode) == "string" then
			sNodePath = vNode;
		end

		if sNodePath then
			if StringManager.startsWith(sNodePath, "combattracker") then
				return "charsheet";
			end
			for _,vMapping in ipairs(LibraryData.getMappings("npc")) do
				if StringManager.startsWith(sNodePath, vMapping) then
					return "charsheet";
				end
			end
		end
	end
	return sResult;
end

function addEquippedSpellPC(nodeActor, nodeCarriedItem, nodeSpell, sName)
	-- Add the new power if the item has not already been configured.
	if DB.getChildCount(nodeCarriedItem, "powers") == 0 then
		nodeItemBeingEquiped = nodeCarriedItem; -- Track that the item is being processed

		-- Grab charge info
		DB.setValue(nodeCarriedItem, "prepared", "number", DB.getValue(nodeSpell, "prepared", 0));
		DB.setValue(nodeCarriedItem, "rechargeperiod", "string", DB.getValue(nodeSpell, "rechargeperiod", ""));
		DB.setValue(nodeCarriedItem, "rechargetime", "string", DB.getValue(nodeSpell, "rechargetime", ""));
		DB.setValue(nodeCarriedItem, "rechargedice", "dice", DB.getValue(nodeSpell, "rechargedice", {}));
		DB.setValue(nodeCarriedItem, "rechargebonus", "number", DB.getValue(nodeSpell, "rechargebonus", 0));

		-- Check to see if it should be grouped.
		local sSource = DB.getValue(nodeSpell, "source", "");
		if (sSource == "Potion") or (sSource == "Scroll") or (sSource == "Wand") then
			DB.setValue(nodeCarriedItem, "displaygroup", "string", sSource .. "s");
		end

		-- Add the power
		PowerManager.addPower("power", nodeSpell, nodeCarriedItem);
		
		nodeItemBeingEquiped = nil; -- No longer tracking
	end
end

-- Recharging
function resetPowers(nodeCaster, bLong)
	resetPowersOriginal(nodeCaster, bLong);
	beginRecharging(nodeCaster, bLong);
end

function resetHealth(nodeCT, bLong)
	resetHealthOriginal(nodeCT, bLong);
	beginRecharging(nodeCT, bLong);
end

function beginRecharging(nodeActor, bLong)
	local sPeriod = "short";
	if ExtendedRest and ExtendedRest.isExtended() then
		sPeriod = "extended";
	elseif bLong then
		sPeriod = "long";
	end

	for _,nodeItem in pairs(DB.getChildren(nodeActor.getPath("inventorylist"))) do
		rechargeItemPowers(nodeItem, sPeriod);
	end
end

function onTimeChanged(nodeDateInMinutes)
	local nNewDateInMinutes = nodeDateInMinutes.getValue();
	local nPreviousDateInMinutes = tonumber(DB.getValue("calendar.dateinminutesstring", ""));

	if not nNewDateInMinutes or not nPreviousDateInMinutes or nNewDateInMinutes <= nPreviousDateInMinutes then
		return;
	end
	local nElapsedDays = TimeManager.convertMinutestoDays(nNewDateInMinutes - nPreviousDateInMinutes);
	local _,nCurrentTimeOfDay = math.modf(TimeManager.convertMinutestoDays(nNewDateInMinutes));

	for _,nodeCombatant in pairs(CombatManager.getCombatantNodes()) do
		local sClass, sRecord = DB.getValue(nodeCombatant, "link", "", "");
		if sClass == "charsheet" and sRecord ~= "" then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				nodeCombatant = nodePC;
			end
		end
		for _,nodeItem in pairs(DB.getChildren(nodeCombatant.getPath("inventorylist"))) do
			rechargeItemPowers(nodeItem, "daily", nCurrentTimeOfDay, nElapsedDays);
		end
	end
end

function rechargeItemPowers(nodeItem, sPeriod, nCurrentTimeOfDay, nElapsedDays)
	if not canRecharge(nodeItem) then
		return;
	end

	local nRechargeAmount, nRechargeCount = getRechargeAmount(nodeItem, sPeriod, nCurrentTimeOfDay, nElapsedDays);
	if nRechargeAmount == RECHARGE_NONE then
		return;
	end

	local messageOOB = {type=OOB_MSGTYPE_RECHARGE_ITEM, sItem=nodeItem.getPath(), sRechargeAmount=tostring(nRechargeAmount), sRechargeCount=tostring(nRechargeCount)};

	if Session.IsHost then
		local sOwner = DB.getOwner(nodeItem);
		if sOwner ~= "" then
			for _,vUser in ipairs(User.getActiveUsers()) do
				if vUser == sOwner then
					Comm.deliverOOBMessage(messageOOB, sOwner);
					return;
				end
			end
		end
		handleItemRecharge(messageOOB);
	end
end

function canRecharge(nodeItem)
	if (DB.getValue(nodeItem, "prepared", 0) > 0)
	and (DB.getValue(nodeItem, "rechargeperiod", "") ~= "")
	and (DB.getValue(nodeItem, "isidentified", 1) == 1)
	and (DB.getValue(nodeItem, "count", 0) > 0) then
		for _,nodePower in pairs(DB.getChildren(nodeItem, "powers")) do
			if DB.getValue(nodePower, "cast", 0) > 0 then
				return true;
			end
		end
	end

	return false;
end

function getRechargeAmount(nodeItem, sPeriod, nCurrentTimeOfDay, nElapsedDays)
	local sItemPeriod = DB.getValue(nodeItem, "rechargeperiod", "");
	if sPeriod == sItemPeriod then
		if sPeriod == "daily" then
			return calculateDailyRecharge(nodeItem, nCurrentTimeOfDay, nElapsedDays);
		end
		return RECHARGE_NORMAL;
	elseif sPeriod == "extended" then
		return RECHARGE_FULL;
	elseif (sPeriod == "long") and (sItemPeriod == "short") then
		return RECHARGE_NORMAL;
	end
	return RECHARGE_NONE;
end

function calculateDailyRecharge(nodeItem, nCurrentTimeOfDay, nElapsedDays)
	if nElapsedDays >= FULL_RECHARGE_DAY_THRESHOLD then
		return RECHARGE_FULL;
	end

	local sRechargeTime = DB.getValue(nodeItem, "rechargetime", "");
	local nRechargeTimeOfDay = DAWN_TIME_OF_DAY;
	if sRechargeTime == "noon" then
		local nRechargeTimeOfDay = NOON_TIME_OF_DAY;
	elseif sRechargeTime == "dusk" then
		local nRechargeTimeOfDay = DUSK_TIME_OF_DAY;
	elseif sRechargeTime == "midnight" then
		local nRechargeTimeOfDay = MIDNIGHT_TIME_OF_DAY;
	end

	local nTolerance = 1e-10; -- Less than a thousandth of a seccond by Earth measure
	local nCount, nElapsedRemainder = math.modf(nElapsedDays); -- Recharge at least once for each full day that has past
	nElapsedRemainder = nElapsedRemainder - nTolerance; -- Account for the previous time being the recharge time.
	if math.abs(nCurrentTimeOfDay - nRechargeTimeOfDay) < nTolerance then
		-- Advancing 1 minute to the recharge time should trigger a single recharge.
		-- Advancing 1 day and 1 minute to the recharge time should trigger two recharges
		-- Advancing exactly 1 day to the recharge time should trigger a single recharge.
		if (nElapsedRemainder > 0) then
			nCount = nCount + 1;
		end
	else
		if nRechargeTimeOfDay > nCurrentTimeOfDay then
			-- Handle wrapping around midnight into a new day.
			nCurrentTimeOfDay = nCurrentTimeOfDay + 1;
		end
		if nRechargeTimeOfDay > (nCurrentTimeOfDay - nElapsedRemainder) then
			-- Increment the number of recharges if the previous time was before the recharge time and the current time is after.
			nCount = nCount + 1;
		end
	end

	if nCount > 0 then
		return RECHARGE_NORMAL, nCount;
	else
		return RECHARGE_NONE;
	end
end

function handleItemRecharge(msgOOB)
	local nodeItem = DB.findNode(msgOOB.sItem);
	if nodeItem then
		local aDice = {};
		local nMod = 0;
		local nRechargeAmount = tonumber(msgOOB.sRechargeAmount);
		if nRechargeAmount == RECHARGE_NORMAL then
			aDice = DB.getValue(nodeItem, "rechargedice", {});
			nMod = DB.getValue(nodeItem, "rechargebonus");
		elseif nRechargeAmount == RECHARGE_FULL then
			nMod = DB.getValue(nodeItem, "prepared");
		end
		local sDescription = DB.getValue(nodeItem, "name", "Unnamed Item") .. " [RECHARGE]";
		local rechargeRoll = {sType="rechargeitem", sDesc=sDescription, aDice=aDice, nMod=nMod, sItem=nodeItem.getPath()};
		for index=1,DB.getValue(nodeItem, "count", 0) do
			for count=1,(tonumber(msgOOB.sRechargeCount) or 1) do
				ActionsManager.roll(nodeItem.getChild("..."), nil, rechargeRoll, false);
			end
		end
	end
end

function onRechargeRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nodeItem = DB.findNode(rRoll.sItem);
	if nodeItem then
		local nResult = ActionsManager.total(rRoll);
		distributeCharges(nodeItem, nResult)
		updateDischargeCount(nodeItem, DB.getValue(nodeItem, "prepared", 1));
	end
	
	-- Deliver roll message
	Comm.deliverChatMessage(rMessage);
end

function distributeCharges(nodeItem, nChargesToAdd)
	for _,nodePower in pairs(DB.getChildren(nodeItem, "powers")) do
		if nChargesToAdd == 0 then
			break;
		end

		local nCast = DB.getValue(nodePower, "cast", 0);
		if nCast > nChargesToAdd then
			nCast = nCast - nChargesToAdd;
			nChargesToAdd = 0;
			DB.setValue(nodePower, "cast", "number", nCast);
		elseif nCast > 0 then
			nChargesToAdd = nChargesToAdd - nCast;
			DB.setValue(nodePower, "cast", "number", 0);
		end
	end
end

-- Discharging
function handleItemChargesUsed(nodeItem)
	local nChargeCount = DB.getValue(nodeItem, "prepared", 1);
	local nChargesUsed = countCharges(nodeItem);
	local nCurrentDischargeCount = DB.getValue(nodeItem, "discharged", 0);
	local nDischargeCount = math.floor(nChargesUsed / nChargeCount);
	if nDischargeCount > nCurrentDischargeCount then
		local sOnDischarge = "roll"; -- TODO get real value
		if sOnDischarge == "destory" then
			destroyDischargedItem(nodeItem, nChargeCount);
		elseif sOnDischarge == "roll" then
			beginRollDischargedItem(nodeItem);
		end
	end

	updateDischargeCount(nodeItem, nChargeCount);
end

function destroyDischargedItem(nodeItem, nChargeCount)
	distributeCharges(nodeItem, nChargeCount);
	local nCount = DB.getValue(nodeItem, "count", 1) - 1;
	DB.setValue(nodeItem, "count", "number", nCount);
end

function beginRollDischargedItem(nodeItem)
	local messageOOB = {type=OOB_MSGTYPE_ROLL_DISCHARGED_ITEM, sItem=nodeItem.getPath()};

	if Session.IsHost then
		local sOwner = DB.getOwner(nodeItem);
		if sOwner ~= "" then
			for _,vUser in ipairs(User.getActiveUsers()) do
				if vUser == sOwner then
					Comm.deliverOOBMessage(messageOOB, sOwner);
					return;
				end
			end
		end
		handleRollDischargedItem(messageOOB);
	end
end

function handleRollDischargedItem(messageOOB)
	local nodeItem = DB.findNode(messageOOB.sItem);
	if nodeItem then
		local aDice = { "d20" };
		local nMod = 0;
		local sDescription = DB.getValue(nodeItem, "name", "Unnamed Item") .. " [DISCHARGE]";
		local dischargeRoll = {sType="dischargeitem", sDesc=sDescription, aDice=aDice, nMod=nMod, sItem=nodeItem.getPath()};
		ActionsManager.roll(nodeItem.getChild("..."), nil, dischargeRoll, false);
	end
end

function onDischargeRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nodeItem = DB.findNode(rRoll.sItem);
	if nodeItem then
		local nDestroyUnder = 1; -- TODO get value
		local nRechargeOver = 20; -- TODO get value
		local nResult = ActionsManager.total(rRoll);
		if nResult <= nDestroyUnder then
			destroyDischargedItem(nodeItem, DB.getValue(nodeItem, "prepared"));
		elseif nResult >= nRechargeOver then
			rechargeDischargedItem(nodeItem);
		else
			updateDischargeCount(nodeItem, DB.getValue(nodeItem, "prepared", 1));
		end
	end
	
	-- Deliver roll message
	Comm.deliverChatMessage(rMessage);
end

function rechargeDischargedItem(nodeItem)
	local aDice = { "d4" }; -- TODO get value
	local nMod = 1; -- TODO get value
	local sDescription = DB.getValue(nodeItem, "name", "Unnamed Item") .. " [RECHARGE]";
	local rechargeRoll = {sType="rechargeitem", sDesc=sDescription, aDice=aDice, nMod=nMod, sItem=nodeItem.getPath()};
	ActionsManager.roll(nodeItem.getChild("..."), nil, rechargeRoll, false);
end

function updateDischargeCount(nodeItem, nChargeCount)
	DB.setValue(nodeItem, "discharged", "number", math.floor(countCharges(nodeItem) / nChargeCount));
end

-- Utility functions
function shouldShowItemPowers(nodeItem)
	return DB.getValue(nodeItem, "count", 0) > 0 and
		DB.getValue(nodeItem, "carried", 0) == 2 and
		DB.getValue(nodeItem, "isidentified", 1) == 1 and
		((DB.getValue(nodeItem, "attune", 0) == 1) or not CharAttunementManager.doesItemAllowAttunement(nodeItem)) and
		DB.getChildCount(nodeItem, "powers") ~= 0;
end

function getItemGroupName(nodeItem)
	local sGroup = DB.getValue(nodeItem, "displaygroup", "");
	if sGroup == "" then
		sGroup = DB.getValue(nodeItem, "name", "");
	end
	return sGroup;
end

function isItemBeingEquipped(nodeItem)
	return nodeItem == nodeItemBeingEquipped;
end

function beginCreatingItemGroup(sCharPath, sGroup)
	local messageOOB = {type=OOB_MSGTYPE_CREATE_ITEM_GROUP, sChar=sCharPath, sGroup=sGroup};
	if not Session.IsHost then
		Comm.deliverOOBMessage(messageOOB, sOwner);
	else
		handleItemGroupCreation(messageOOB)
	end
end

function handleItemGroupCreation(msgOOB)
	local nodeChar = DB.findNode(msgOOB.sChar);
	if not nodeChar then
		return;
	end

	local nodeGroups = nodeChar.getChild("itemgroups");
	if nodeGroups then
		for _,nodeGroup in pairs(nodeGroups.getChildren()) do
			if DB.getValue(nodeGroup, "name", "") == msgOOB.sGroup then
				return;
			end
		end
	else
		nodeGroups = nodeChar.createChild("itemgroups");
	end

	local nodeGroup = nodeGroups.createChild();
	if nodeGroup then
		DB.setValue(nodeGroup, "name", "string", msgOOB.sGroup);
	end
end

function countCharges(nodeItem)
	local nCount = 0;
	for _,powerNode in pairs(DB.getChildren(nodeItem.getPath("powers"))) do
		nCount = nCount + DB.getValue(powerNode, "cast", 0);
	end
	return nCount;
end