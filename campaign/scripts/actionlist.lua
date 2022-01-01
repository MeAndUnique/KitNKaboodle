-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local bReadOnly = true;
local bHideCast = true;
local bAdding = false;

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
end

function onClose()
	local nodePower = window.getDatabaseNode();
	DB.removeHandler(nodePower.getPath("actions"), "onChildAdded", onActionAdded);
	DB.removeHandler(nodePower.getPath("actions.*.type"), "onUpdate", onTypeChanged);
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