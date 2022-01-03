-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerOptions();
end

function registerOptions()
	-- Remove item from inventory when destoyed
	OptionsManager.registerOption2("IDLU", true, "option_header_knk", "option_label_IDLU", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
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
			 -- increment by two in order to account for both inclusivity and the previous count.
			adjustActionOrder(nodePower, nOrder, nCount + 2, -1);
			break;
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