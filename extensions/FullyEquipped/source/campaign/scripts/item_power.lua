-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- aliases for self, used by counter
parentcontrol = nil;
window = nil;

-- Initialization
function onInit()
	parentcontrol = self;
	parentcontrol.window = self;
	for _,nodeAction in pairs(DB.getChildren(getDatabaseNode(), "actions")) do
		showAction(nodeAction);
	end

	update(windowlist.isReadOnly())
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

function createAction(sType)
	local nodePower = getDatabaseNode();
	if nodePower then
		local nodeActions = nodePower.createChild("actions");
		if nodeActions then
			local nodeAction = nodeActions.createChild();
			if nodeAction then
				DB.setValue(nodeAction, "type", "string", sType);
				showAction(nodeAction, sType);
				-- actions.createWindowWithClass("item_action_" .. sType, nodeAction);
			end
		end
	end
end

function showAction(nodeAction, sType)
	if (sType or "") == "" then
		sType = DB.getValue(nodeAction, "type");
	end

	if (sType or "") ~= "" then
		actions.createWindowWithClass("item_action_" .. sType, nodeAction);
	end
end

function toggleDetail()
	local status = (activatedetail.getValue() == 1);
	actions.setVisible(status);
end

function update(bReadOnly, bHideCast)
	name.setReadOnly(bReadOnly);

	if bReadOnly then
		name.setFrame(nil);
		resetMenuItems();
	else
		name.setFrame("fieldlight", 7, 5, 7, 5);

		-- registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
		-- registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);

		registerMenuItem(Interface.getString("power_menu_addaction"), "pointer", 3);
		registerMenuItem(Interface.getString("power_menu_addcast"), "radial_sword", 3, 2);
		registerMenuItem(Interface.getString("power_menu_adddamage"), "radial_damage", 3, 3);
		registerMenuItem(Interface.getString("power_menu_addheal"), "radial_heal", 3, 4);
		registerMenuItem(Interface.getString("power_menu_addeffect"), "radial_effect", 3, 5);
		
		-- registerMenuItem(Interface.getString("power_menu_reparse"), "textlist", 4);
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
	ChatManager.Message(getDescription(bShowFull), true, ActorManager.getActor("pc", node.getChild("...")));
end