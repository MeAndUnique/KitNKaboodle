-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local bReadOnly = true;
local bHideCast = true;
local bAdding = false;
local dropWidget;

local rKnownActions = {
	["cast"] = true,
	["damage"] = true,
	["effect"] = true,
	["heal"] = true,
};

function onInit()
	if PowerManagerCg then
		rKnownActions["resource"] = true;
	end
	if KingdomsAndWarfare then
		rKnownActions["test"] = true;
	end

	refreshActions();

	local nodePower = window.getDatabaseNode();
	DB.addHandler(nodePower.getPath("actions"), "onChildAdded", onActionAdded);
	DB.addHandler(nodePower.getPath("actions.*.type"), "onUpdate", onTypeChanged);

	window.onMenuSelection = onMenuSelection;

	ensureOrdering()
end

function onClose()
	local nodePower = window.getDatabaseNode();
	DB.removeHandler(nodePower.getPath("actions"), "onChildAdded", onActionAdded);
	DB.removeHandler(nodePower.getPath("actions.*.type"), "onUpdate", onTypeChanged);
end

function ensureOrdering()
	local bUnordered = false;
	for _,nodeAction in pairs(DB.getChildren(window.getDatabaseNode(), "actions")) do
		if not DB.getChild(nodeAction, "order") then
			bUnordered = true;
			break;
		end
	end

	if bUnordered then
		local nOrder = 1;
		for _,nodeAction in pairs(DB.getChildren(window.getDatabaseNode(), "actions")) do
			DB.setValue(nodeAction, "order", "number", nOrder);
			nOrder = nOrder + 1;
		end
	end
end

function onMenuSelection(selection, subselection)
	if selection == 3 then
		if subselection == 2 then
			createAction("cast");
		elseif subselection == 3 then
			createAction("damage");
		elseif subselection == 4 then
			createAction("heal");
		elseif subselection == 5 then
			createAction("effect");
		elseif subselection == 6 then
			createAction("resource");
		elseif subselection == 8 then
			createAction("test");
		end
	end
end

function onTypeChanged(nodeType)
	if bAdding then
		local sType = nodeType.getValue();
		local nodeAction = DB.getChild(nodeType, "..");
		showAction(nodeAction, sType);
	end
end

function onActionAdded()
	bAdding = true;
end

function refreshActions()
	closeAll()
	for _,nodeAction in pairs(DB.getChildren(window.getDatabaseNode(), "actions")) do
		showAction(nodeAction);
	end
end

function showAction(nodeAction, sType)
	if (sType or "") == "" then
		sType = DB.getValue(nodeAction, "type");
	end

	if ((sType or "") ~= "") and (rKnownActions[sType] ~= nil) then
		local win = createWindowWithClass("item_action_" .. sType, nodeAction);
		win.update(bReadOnly, bHideCast);
	end
	bAdding = false;
end

function createAction(sType)
	local nodePower = window.getDatabaseNode();
	if nodePower then
		local nodeActions = nodePower.createChild("actions");
		if nodeActions then
			local nodeAction = nodeActions.createChild();
			if nodeAction then
				DB.setValue(nodeAction, "type", "string", sType);
			end
		end
	end
end

function update(bNewReadOnly, bNewHideCast)
	bReadOnly = bNewReadOnly;
	bHideCast = bNewHideCast;
	if bReadOnly then
		window.resetMenuItems();
	else
		window.registerMenuItem(Interface.getString("power_menu_addaction"), "radial_create_action", 3);
		window.registerMenuItem(Interface.getString("power_menu_addcast"), "radial_sword", 3, 2);
		window.registerMenuItem(Interface.getString("power_menu_adddamage"), "radial_damage", 3, 3);
		window.registerMenuItem(Interface.getString("power_menu_addheal"), "radial_heal", 3, 4);
		window.registerMenuItem(Interface.getString("power_menu_addeffect"), "radial_effect", 3, 5);

		if PowerManagerCg then
			window.registerMenuItem(Interface.getString("power_menu_addresource"), "coins", 3, 6);
		end
		if KingdomsAndWarfare then
			window.registerMenuItem(Interface.getString("power_menu_addetest"), "radial_sword", 3, 8);
		end
		
		window.registerMenuItem(Interface.getString("power_menu_reparse"), "radial_reparse_spell", 4);
	end

	for _,win in ipairs(getWindows()) do
		win.update(bReadOnly, bHideCast);
	end
end

function onHover(bOnControl)
	if (not bOnControl) and dropWidget then
		dropWidget.destroy();
		dropWidget = nil;
	end
end

function onHoverUpdate(x, y)
	local draginfo = Input.getDragData();
	if (not draginfo) or (draginfo.getType() ~= "poweraction") then
		return;
	end
	
	local win = getWindowAt(x, y);
	if not win then
		return;
	end

	if not dropWidget then
		dropWidget = addBitmapWidget("tool_right_30");
		-- todo color
	end

	local windowWidth, windowHeight = win.getSize();
	local widgetWidth, widgetHeight = dropWidget.getSize();

	local nHoverIndex = 0;
	for nIndex, winChild in ipairs(getWindows()) do
		if winChild == win then
			nHoverIndex = nIndex - 1;
		end
	end

	dropWidget.setPosition("topleft", widgetWidth/2, nHoverIndex * windowHeight);
end

function onDrop(x, y, draginfo)
	if dropWidget then
		dropWidget.destroy();
		dropWidget = nil;
	end

	if draginfo.getType() ~= "poweraction" then
		return false;
	end

	local win = getWindowAt(x, y);
	if not win then
		return;
	end

	local nodeDragged = draginfo.getDatabaseNode();
	local nodeTarget = win.getDatabaseNode();
	if nodeDragged == nodeTarget then
		return;
	end

	-- todo account for cross-power dragging
	local nodePower = DB.getChild(nodeDragged, "...");
	local nDragOrder = DB.getValue(nodeDragged, "order");
	local nTargetOrder = DB.getValue(nodeTarget, "order");

	local nAdjust, nMin, nMax;
	if nDragOrder > nTargetOrder then
		nAdjust = 1;
		nMin = nTargetOrder;
		nMax = nDragOrder;
	else
		nAdjust = -1;
		nMin = nDragOrder;
		nMax = nTargetOrder;
	end

	for _,nodeAction in pairs(DB.getChildren(nodePower, "actions")) do
		local nOrder = DB.getValue(nodeAction, "order", 0);
		if (nMin < nOrder) and (nOrder < nMax) then
			DB.setValue(nodeAction, "order", "number", nOrder + nAdjust);
		end
	end

	DB.setValue(nodeTarget, "order", "number", nTargetOrder + nAdjust);
	DB.setValue(nodeDragged, "order", "number", nTargetOrder);

	applySort();
end