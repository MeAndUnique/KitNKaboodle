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
	DB.addHandler(nodePower.getPath("actions"), "onChildDeleted", onActionDeleted);
	DB.addHandler(nodePower.getPath("actions.*.type"), "onUpdate", onTypeChanged);

	window.onMenuSelection = onMenuSelection;

	ensureOrdering()
end

function onClose()
	local nodePower = window.getDatabaseNode();
	DB.removeHandler(nodePower.getPath("actions"), "onChildAdded", onActionAdded);
	DB.removeHandler(nodePower.getPath("actions"), "onChildDeleted", onActionDeleted);
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

function onActionDeleted()
	PowerManagerKNK.fillActionOrderGap(window.getDatabaseNode());
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

	if DB.getValue(nodeAction, "order", 0) == 0 then
		DB.setValue(nodeAction, "order", "number", DB.getChildCount(nodeAction, ".."));
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
	if bReadOnly then
		return;
	end

	local draginfo = Input.getDragData();
	if (not draginfo) or (draginfo.getType() ~= "poweraction") then
		return;
	end
	
	local win = getWindowAt(x, y);

	if not dropWidget then
		dropWidget = addBitmapWidget("tool_right_30");
	end

	local widgetWidth, widgetHeight = dropWidget.getSize();

	local nodeDragged = draginfo.getDatabaseNode();
	local nodeOriginPower = DB.getChild(nodeDragged, "...");
	local nOrder = DB.getValue(nodeDragged, "order", 0);
	local nHeight = 0;
	for nIndex, winChild in ipairs(getWindows()) do
		local _,windowHeight = winChild.getSize();
		if winChild == win then
			if (nIndex > nOrder) or (nodeOriginPower ~= window.getDatabaseNode()) then
				nHeight = nHeight + windowHeight;
			end
			break;
		end
		nHeight = nHeight + windowHeight;
	end

	dropWidget.setPosition("topleft", widgetWidth/2, nHeight);
end

function onDrop(x, y, draginfo)
	if bReadOnly then
		return;
	end

	if dropWidget then
		dropWidget.destroy();
		dropWidget = nil;
	end
	
	if draginfo.getType() ~= "poweraction" then
		return false;
	end

	local win = getWindowAt(x, y);
	local nodeDragged = draginfo.getDatabaseNode();
	local nodeTarget;
	if win then
		nodeTarget = win.getDatabaseNode();
	end
	PowerManagerKNK.moveAction(window.getDatabaseNode(), nodeDragged, nodeTarget);
	applySort();
	return true;
end