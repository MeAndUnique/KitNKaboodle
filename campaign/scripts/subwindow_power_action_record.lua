-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit()
	end
	if (text or textres) and menuicon and target and tabicon then
		if textres then
			registerMenuItem(Interface.getString("menu_switch_to_powers"), menuicon[1], 5);
		else
			registerMenuItem(text[1], menuicon[1], 5);
		end
	end
	local bHasMultiple = DB.getValue(window.getDatabaseNode(), "hasmultiplepowers") == 1;
	update(bHasMultiple);
end

function update(bHasMultiple)
	resetMenuItems();
	if bHasMultiple then
		registerMenuItem(Interface.getString("menu_switch_to_actions"), "refresh", 7);
		setValue("ability_powers", window.getDatabaseNode());
	else
		registerMenuItem(Interface.getString("menu_switch_to_powers"), "refresh", 7);
		setValue("power_actions", window.getDatabaseNode());
	end
end

function onMenuSelection(selection)
	if selection == 7 then
		local node  = window.getDatabaseNode();
		local nHasMultiple = DB.getValue(node, "hasmultiplepowers", 0);
		local bHasMultiple = nHasMultiple == 1;

		if bHasMultiple then
			if DB.getChildCount(node, "powers") > 1 then
				ChatManager.SystemMessage(Interface.getString("multiple_powers_to_actions_error"));
				return;
			end

			local nodePower;
			for _,nodeChild in pairs(DB.getChildren(node, "powers")) do
				nodePower = nodeChild;
			end
			if nodePower then
				DB.setValue(node, "prepared", "number", DB.getValue(nodePower, "prepared", 0));
				DB.setValue(node, "usesperiod", "string", DB.getValue(nodePower, "usesperiod", ""));
				DB.copyNode(DB.createChild(nodePower, "actions"), DB.createChild(node, "actions"));
			end
		else
			local nodePower = DB.createChild(DB.createChild(node, "powers"));
			DB.setValue(nodePower, "name", "string", DB.getValue(node, "name", ""));
			DB.setValue(nodePower, "prepared", "number", DB.getValue(node, "prepared", 0));
			DB.setValue(nodePower, "usesperiod", "string", DB.getValue(node, "usesperiod", ""));
			DB.copyNode(DB.createChild(node, "actions"), DB.createChild(nodePower, "actions"));
		end

		nHasMultiple = 1 - nHasMultiple;
		DB.setValue(node, "hasmultiplepowers", "number", nHasMultiple);
		bHasMultiple = not bHasMultiple
		update(bHasMultiple);

		if bHasMultiple then
			DB.deleteChild(node, "actions");
			DB.deleteChild(node, "prepared");
			DB.deleteChild(node, "usesperiod");
		else
			DB.deleteChild(node, "powers");
		end
	end
end