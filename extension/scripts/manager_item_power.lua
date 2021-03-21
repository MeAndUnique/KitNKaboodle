-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_RECHARGE_ITEM = "rechargeitem";

RECHARGE_NONE = 0;
RECHARGE_NORMAL = 1;
RECHARGE_FULL = 2;

local getItemSourceTypeOriginal;
local resetPowersOriginal;

-- Initialization
function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_RECHARGE_ITEM, handleItemRecharge);
	ActionsManager.registerResultHandler("recharge", onRechargeRoll);

	getItemSourceTypeOriginal = ItemManager.getItemSourceType;
	ItemManager.getItemSourceType = getItemSourceType;
	
	resetPowersOriginal = PowerManager.resetPowers;
	PowerManager.resetPowers = resetPowers;
end

function onClose()
	ItemManager.getItemSourceType = getItemSourceTypeOriginal;
	PowerManager.resetPowers = resetPowersOriginal
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

-- Recharging
function resetPowers(nodeCaster, bLong)
	resetPowersOriginal(nodeCaster, bLong);

	-- Match the rest values from the recharge cycler
	-- TODO Consider time of day handling.
	local sPeriod = ((ExtendedRest and ExtendedRest.isExtended()) and "extended") or
		(bLong and "daily");
	for _,nodeItem in pairs(DB.getChildren(nodeCaster.getPath("inventorylist"))) do
		rechargeItemPowers(nodeItem, sPeriod);
	end
end

function rechargeItemPowers(nodeItem, sPeriod)
	if not canRecharge(nodeItem) then
		return;
	end

	local nRechargeAmount = getRechargeAmount(nodeItem, sPeriod);
	Debug.chat(nRechargeAmount);
	if nRechargeAmount == RECHARGE_NONE then
		return;
	end

	local messageOOB = {type=OOB_MSGTYPE_RECHARGE_ITEM, sItem=nodeItem.getPath(), nRechargeAmount=nRechargeAmount};

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
	end
	
	handleItemRecharge(messageOOB);
end

function canRecharge(nodeItem)
	local bItemExists = DB.getValue(nodeItem, "count", 0) > 0;
	local isIdentified = DB.getValue(nodeItem, "isidentified", 1) == 1;
	local hasCharges = DB.getValue(nodeItem, "prepared", 0) > 0;
	local bFinitePeriod = DB.getValue(nodeItem, "rechargeperiod", "") ~= "";
	Debug.chat(bItemExists, isIdentified, hasCharges, bFinitePeriod);
	return bItemExists and isIdentified and hasCharges and bFinitePeriod;
end

function getRechargeAmount(nodeItem, sPeriod)
	Debug.chat(sPeriod, DB.getValue(nodeItem, "rechargeperiod", ""));
	if (sPeriod == DB.getValue(nodeItem, "rechargeperiod", "")) then
		Debug.chat("nani", RECHARGE_NORMAL);
		return RECHARGE_NORMAL;
	elseif sPeriod == "extended" then
		return RECHARGE_FULL;
	end
	return RECHARGE_NONE;
end

function handleItemRecharge(msgOOB)
	local nodeItem = DB.findNode(msgOOB.sItem);
	if nodeItem then
		Debug.chat("about to iter", msgOOB);
		for index=1,DB.getValue(nodeItem, "count", 0) do
			local aDice = {};
			local nMod = 0;
			if msgOOB.nRechargeAmount == RECHARGE_NORMAL then
				aDice = DB.getValue(nodeItem, "rechargedice");
				nMod = DB.getValue(nodeItem, "rechargebonus");
			elseif msgOOB.nRechargeAmount == RECHARGE_FULL then
				nMod = DB.getValue(nodeItem, "prepared");
			end
			local sDescription = DB.getValue(nodeItem, "name", "Unnamed Item") .. " [RECHARGE]";
			local rechargeRoll = {sType="recharge", sDesc=sDescription, aDice=aDice, nMod=nMod, sItem=nodeItem.getPath()};
			ActionsManager.roll(nodeItem.getChild("..."), nil, rechargeRoll, false);
		end
	end
end

function onRechargeRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nodeItem = DB.findNode(rRoll.sItem);
	Debug.chat(rRoll.sItem, nodeItem);
	if nodeItem then
		local nResult = ActionsManager.total(rRoll);
		Debug.chat(rRoll, nResult);
		for _,nodePower in pairs(DB.getChildren(nodeItem, "powers")) do
			if nResult == 0 then
				break;
			end

			local nCast = DB.getValue(nodePower, "cast", 0);
			if nCast > nResult then
				nCast = nCast - nResult;
				nResult = 0;
				DB.setValue(nodePower, "cast", "number", nCast);
			elseif nCast > 0 then
				nResult = nResult - nCast;
				DB.setValue(nodePower, "cast", "number", 0);
			end
		end
	end
	
	-- Deliver roll message
	Comm.deliverChatMessage(rMessage);
end

--Utility functions
function shouldShowItemPowers(itemNode)
	return DB.getValue(itemNode, "carried", 0) == 2 and
		DB.getValue(itemNode, "isidentified", 1) == 1 and
		DB.getChildCount(itemNode, "powers") ~= 0;
end