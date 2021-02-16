-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- aliases for self, used by counter
parentcontrol = nil;
window = nil;

local bAdding = false;
local bReadOnly;
local bHideCast;

-- Initialization
function onInit()
	parentcontrol = self;
	parentcontrol.window = self;
	refreshActions();
	update(windowlist.isReadOnly())

	local node = getDatabaseNode();
	DB.addHandler(node.getPath("group"), "onUpdate", onGroupChanged);
	DB.addHandler(node.getPath("actions"), "onChildAdded", onActionAdded);
	DB.addHandler(node.getPath("actions.*.type"), "onUpdate", onTypeChanged);
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(node.getPath("group"), "onUpdate", onGroupChanged);
	DB.removeHandler(node.getPath("actions"), "onChildAdded", onActionAdded);
	DB.removeHandler(node.getPath("actions.*.type"), "onUpdate", onTypeChanged);
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

function onActionAdded(nodePower, nodeAction)
	bAdding = true;
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

	if (sType or "") ~= "" then
		local win = actions.createWindowWithClass("item_action_" .. sType, nodeAction);
		win.update(bReadOnly, bHideCast);
	end
	bAdding = false;
end

function toggleDetail()
	local status = (activatedetail.getValue() == 1);
	effectivegroup.setVisible(status and not bReadOnly);
	actions.setVisible(status);
end

function update(bNewReadOnly, bNewHideCast)
	bReadOnly = bNewReadOnly;
	bHideCast = bNewHideCast;
	name.setReadOnly(bReadOnly);
	effectivegroup.subwindow.group.setVisible((bHideCast ~= nil) and bHideCast or true);
	effectivegroup.subwindow.group.setReadOnly(bReadOnly);

	if bReadOnly then
		name.setFrame(nil);
		effectivegroup.subwindow.group.setFrame(nil);
		resetMenuItems();
	else
		name.setFrame("fieldlight", 7, 5, 7, 5);
		effectivegroup.subwindow.group.setFrame("fieldlight", 7, 5, 7, 5);
		
		registerMenuItem(Interface.getString("power_menu_addaction"), "pointer", 3);
		registerMenuItem(Interface.getString("power_menu_addcast"), "radial_sword", 3, 2);
		registerMenuItem(Interface.getString("power_menu_adddamage"), "radial_damage", 3, 3);
		registerMenuItem(Interface.getString("power_menu_addheal"), "radial_heal", 3, 4);
		registerMenuItem(Interface.getString("power_menu_addeffect"), "radial_effect", 3, 5);
		
		registerMenuItem(Interface.getString("power_menu_reparse"), "textlist", 4);
	end

	for _,win in ipairs(actions.getWindows()) do
		win.update(bReadOnly, bHideCast);
	end
end

function updateUses(nTotal, nUsed)
	local node = getDatabaseNode();
	DB.setValue(node, "prepared", "number", nTotal);
	counter.setVisible(nTotal > 0);
	counter.update("standard", true, nTotal, nUsed, nTotal);
end

function getDescription(bShowFull)
	local node = getDatabaseNode();
	
	local s = DB.getValue(node, "name", "");
	
	if bShowFull then
		local sShort = DB.getValue(node, "shortdescription", "");
		if sShort ~= "" then
			s = s .. " - " .. sShort;
		end
	end

	return s;
end

function usePower(bShowFull)
	local node = getDatabaseNode();
	ChatManager.Message(getDescription(bShowFull), true, ActorManager.resolveActor(node.getChild("...")));
end