-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

-- aliases for self, used by counter
parentcontrol = nil;
window = nil;

local bAdding = false;
local bReadOnly;
local bHideCast;

local rKnownActions = {
	["cast"] = true,
	["damage"] = true,
	["effect"] = true,
	["heal"] = true,
};

-- Initialization
function onInit()
	parentcontrol = self;
	parentcontrol.window = self;
	bHideCast = windowlist.window.bHideCast;
	refreshActions();
	update(windowlist.isReadOnly(), bHideCast);

	local nodePower = getDatabaseNode();
	DB.addHandler(nodePower.getChild("...").getPath("prepared"), "onUpdate", onChargesChanged);
	DB.addHandler(nodePower.getPath("group"), "onUpdate", onGroupChanged);
	DB.addHandler(nodePower.getPath("actions"), "onChildAdded", onActionAdded);
	DB.addHandler(nodePower.getPath("actions"), "onChildDeleted", onActionDeleted);
	DB.addHandler(nodePower.getPath("actions.*.type"), "onUpdate", onTypeChanged);
end

function onClose()
	local nodePower = getDatabaseNode();
	DB.removeHandler(nodePower.getChild("...").getPath("prepared"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodePower.getPath("group"), "onUpdate", onGroupChanged);
	DB.removeHandler(nodePower.getPath("actions"), "onChildAdded", onActionAdded);
	DB.removeHandler(nodePower.getPath("actions"), "onChildDeleted", onActionDeleted);
	DB.removeHandler(nodePower.getPath("actions.*.type"), "onUpdate", onTypeChanged);
end

function refreshActions()
	actions.closeAll()
	for _,nodeAction in pairs(DB.getChildren(getDatabaseNode(), "actions")) do
		showAction(nodeAction);
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
		end
		activatedetail.setValue(1);
	end
end

function onChargesChanged(nodePrepared)
	local nodePower = getDatabaseNode();
	activatedetail.setVisible(shouldShowToggle(nodePower));
	metadata.setVisible(shouldShowMetaData(nodePower));
end

function onGroupChanged()
	for _,win in ipairs(actions.getWindows()) do
		win.onDataChanged();
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
	updateToggle();
end

function onActionDeleted()
	updateToggle();
end

function createAction(sType)
	local nodePower = getDatabaseNode();
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

function showAction(nodeAction, sType)
	if (sType or "") == "" then
		sType = DB.getValue(nodeAction, "type");
	end

	if ((sType or "") ~= "") and (rKnownActions[sType] ~= nil) then
		local win = actions.createWindowWithClass("item_action_" .. sType, nodeAction);
		win.update(bReadOnly, bHideCast);
	end
	bAdding = false;
end

function shouldShowToggle(nodePower)
	return (DB.getChildCount(nodePower, "actions") > 0) or (bHideCast and (DB.getValue(nodePower, "...prepared", 0) > 0));
end

function shouldShowMetaData(nodePower)
	return bHideCast and (activatedetail.getValue() == 1) and (DB.getValue(nodePower, "...prepared", 0) > 0);
end

function updateToggle()
	if (DB.getChildCount(getDatabaseNode(), "actions") > 0) or
		(bHideCast and (DB.getValue(nodePower, "...prepared", 0) > 0)) then
		activatedetail.setValue(1);
		activatedetail.setVisible(true);
	else
		activatedetail.setValue(0);
		activatedetail.setVisible(false);
	end
end

function toggleDetail()
	local status = (activatedetail.getValue() == 1);
	metadata.setVisible(status and bHideCast and (DB.getValue(getDatabaseNode(), "...prepared", 0) > 0));
	actions.setVisible(status);
end

function update(bNewReadOnly, bNewHideCast)
	bReadOnly = bNewReadOnly;
	bHideCast = bNewHideCast;
	local nodePower = getDatabaseNode();
	nameandactions.subwindow.name.setReadOnly(bReadOnly);
	nameandactions.subwindow.actionsmini.setVisible(not bHideCast);
	activatedetail.setVisible(shouldShowToggle(nodePower));
	metadata.subwindow.charges.setReadOnly(bReadOnly);
	metadata.setVisible(shouldShowMetaData(nodePower));

	if bReadOnly then
		nameandactions.subwindow.name.setFrame(nil);
		metadata.subwindow.charges.setFrame(nil);
		resetMenuItems();
	else
		nameandactions.subwindow.name.setFrame("fieldlight", 7, 5, 9, 5);
		metadata.subwindow.charges.setFrame("fieldlight", 7, 5, 9, 5);
		
		registerMenuItem(Interface.getString("power_menu_addaction"), "radial_create_action", 3);
		registerMenuItem(Interface.getString("power_menu_addcast"), "radial_sword", 3, 2);
		registerMenuItem(Interface.getString("power_menu_adddamage"), "radial_damage", 3, 3);
		registerMenuItem(Interface.getString("power_menu_addheal"), "radial_heal", 3, 4);
		registerMenuItem(Interface.getString("power_menu_addeffect"), "radial_effect", 3, 5);
		
		registerMenuItem(Interface.getString("power_menu_reparse"), "radial_reparse_spell", 4);
	end

	for _,win in ipairs(actions.getWindows()) do
		win.update(bReadOnly, bHideCast);
	end
end

function getDescription(nodePower, bShowFull)
	local s = DB.getValue(nodePower, "name", "");
	
	if bShowFull then
		local sShort = DB.getValue(nodePower, "shortdescription", "");
		if sShort ~= "" then
			s = s .. " - " .. sShort;
		end
	end

	return s;
end

function usePower(bShowFull)
	local nodePower = getDatabaseNode();
	local nodeItem = nodePower.getChild("...");
	ChatManager.Message(getDescription(nodePower, bShowFull), true, ActorManager.resolveActor(nodeItem));
end