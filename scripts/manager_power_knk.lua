--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local addPowerOriginal;
local resetPowersOriginal;
local getPowerActorNodeOriginal;
local resetIntriguePowersOriginal;

function onInit()
	addPowerOriginal = PowerManager.addPower;
	PowerManager.addPower = addPower;

	resetPowersOriginal = PowerManager.resetPowers;
	PowerManager.resetPowers = resetPowers;

	getPowerActorNodeOriginal = PowerManager5E.getPowerActorNode;
	PowerManager5E.getPowerActorNode = getPowerActorNode;

	if PowerManagerKw then
		resetIntriguePowersOriginal = PowerManagerKw.resetIntriguePowers;
		PowerManagerKw.resetIntriguePowers = resetIntriguePowers;
	end

	local tPowerHandlers = {
		fnGetActorNode = PowerManager5E.getPowerActorNode,
		fnParse = PowerManager5E.parsePower,
		fnUpdateDisplay = PowerManager5E.updatePowerDisplay,
	};
	PowerManagerCore.registerPowerHandlers(tPowerHandlers);
end

function addPower(sClass, nodeSource, nodeCreature, sGroup)
	if StringManager.contains({"ref_ability", "reference_classfeature", "reference_feat", "reference_racialtrait"}, sClass)
	and DB.getValue(nodeSource, "hasmultiplepowers") == 1 then
		for _,nodePower in pairs(DB.getChildren(nodeSource, "powers")) do
			addPowerOriginal("power", nodePower, nodeCreature, sGroup);
		end
	else
		addPowerOriginal(sClass, nodeSource, nodeCreature, sGroup)
	end
end

function resetPowers(nodeCaster, bLong)
	resetPowersOriginal(nodeCaster, bLong);
	ItemPowerManager.beginRecharging(nodeCaster, bLong);
end

function resetIntriguePowers(nodeCaster)
	resetIntriguePowersOriginal(nodeCaster);
	for _,nodeItem in pairs(DB.getChildren(nodeCaster.getPath("inventorylist"))) do
		ItemPowerManager.rechargeItemPowers(nodeItem, "intrigue");
	end
end

function getPowerActorNode(node)
	if node.getPath():match("inventorylist") then
		return DB.getChild(node, ".....");
	else
		return getPowerActorNodeOriginal(node);
	end
end

function fillActionOrderGap(nodePower)
	local tExistingOrders = {};
	local nCount = 0;
	for _,nodeAction in pairs(DB.getChildren(nodePower, "actions")) do
		tExistingOrders[DB.getValue(nodeAction, "order", 0)] = true;
		nCount = nCount + 1;
	end
	for nOrder=1,nCount do
		if not tExistingOrders[nOrder] then
			adjustActionOrder(nodePower, nOrder, 1000, -1);

			for nInnerOrder=nOrder+1,nCount do
				if tExistingOrders[nInnerOrder] then
					tExistingOrders[nInnerOrder-1] = true;
					tExistingOrders[nInnerOrder] = false;
				end
			end
			nOrder = nOrder - 1; -- repeat since everything just shifted down
			nCount = nCount - 1;
		end
	end
end

function moveAction(nodeTargetPower, nodeDragged, nodeTargetAction, bForceCopy, bCanDelete)
	if bForceCopy == nil then
		bForceCopy = Input.isControlPressed();
	end
	if bCanDelete == nil then
		bCanDelete = Input.isShiftPressed();
	end

	if nodeDragged == nodeTargetAction and not bForceCopy then
		return;
	end

	local nodeOriginPower = DB.getChild(nodeDragged, "...");
	if nodeOriginPower == nodeTargetPower then
		moveActionWithinPower(nodeTargetPower, nodeDragged, nodeTargetAction, bForceCopy);
	else
		moveActionToNewPower(nodeOriginPower, nodeTargetPower, nodeDragged, nodeTargetAction, bCanDelete);
	end
end

function moveActionWithinPower(nodePower, nodeDragged, nodeTarget, bForceCopy)
	local nDragOrder = DB.getValue(nodeDragged, "order");
	local nTargetOrder = DB.getValue(nodeTarget, "order");

	local nAdjust, nMin, nMax;
	if bForceCopy then
		nAdjust = 1;
		nMax = 1000;
		if nDragOrder > nTargetOrder then
			nMin = nTargetOrder - 1;
		else
			nMin = nTargetOrder;
			nTargetOrder = nTargetOrder + 1;
		end
	else
		if nDragOrder > nTargetOrder then
			nAdjust = 1;
			nMin = nTargetOrder - 1;
			nMax = nDragOrder;
		else
			nAdjust = -1;
			nMin = nDragOrder;
			nMax = nTargetOrder + 1;
		end
	end

	adjustActionOrder(nodePower, nMin, nMax, nAdjust);

	if bForceCopy then
		local nodeCopy = DB.createChild(DB.createChild(nodePower, "actions"));
		DB.copyNode(nodeDragged, nodeCopy);
		nodeDragged = nodeCopy;
	end
	DB.setValue(nodeDragged, "order", "number", nTargetOrder);
end

function moveActionToNewPower(nodeOriginPower, nodeTargetPower, nodeDragged, nodeTarget, bCanDelete)
	-- Increase by 1 to add after
	local nTargetOrder = 0;
	if nodeTarget then
		nTargetOrder = DB.getValue(nodeTarget, "order");
	end
	adjustActionOrder(nodeTargetPower, nTargetOrder, 1000, 1);

	local nodeNewAction = DB.createChild(DB.createChild(nodeTargetPower, "actions"));
	DB.copyNode(nodeDragged, nodeNewAction);
	DB.setValue(nodeNewAction, "order", "number", nTargetOrder + 1);

	if bCanDelete then
		local nDragOrder = DB.getValue(nodeDragged, "order");
		adjustActionOrder(nodeOriginPower, nDragOrder, 1000, -1);
		DB.deleteNode(nodeDragged);
	end
end

function adjustActionOrder(nodePower, nMin, nMax, nAdjust)
	for _,nodeAction in pairs(DB.getChildren(nodePower, "actions")) do
		local nOrder = DB.getValue(nodeAction, "order", 0);
		if (nMin < nOrder) and (nOrder < nMax) then
			DB.setValue(nodeAction, "order", "number", nOrder + nAdjust);
		end
	end
end