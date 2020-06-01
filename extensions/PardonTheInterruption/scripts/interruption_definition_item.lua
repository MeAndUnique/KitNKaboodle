-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nodes = {};

function onInit()
	local modeChoices = {
		Interface.getString("interruption_mode_mod"),
		Interface.getString("interruption_mode_reroll_keep"),
		Interface.getString("interruption_mode_replace")
	};
	mode.addItems(modeChoices);
	buildMenu();
	updateVisibility();
end

function buildMenu()
	resetMenuItems();
	
	-- registerMenuItem(Interface.getString("interruption_menu_application"), "pointer", 3);

	local node = getDatabaseNode();
	-- buildSubMenu(Interface.getString("interruption_menu_attacking"), "radial_sword", 2, node.getChild("attacking"));
	-- buildSubMenu(Interface.getString("interruption_menu_saving"), "radial_effect", 3, node.getChild("saving"));

	-- local bAny = false;

	-- if node.getChild("attacking") then
	-- 	registerMenuItem(Interface.getString("interruption_remove_menu"), "crossed", 4);
	-- 	registerMenuItem(Interface.getString("interruption_menu_attacking"), "radial_sword", 4, 3);
	-- 	bAny = true;
	-- else
	-- 	registerMenuItem(Interface.getString("interruption_add_menu"), "pointer", 3);
	-- 	registerMenuItem(Interface.getString("interruption_menu_attacking"), "radial_sword", 3, 3);
	-- end

	-- if node.getChild("saving") then
	-- 	registerMenuItem(Interface.getString("interruption_remove_menu"), "crossed", 4);
	-- 	registerMenuItem(Interface.getString("interruption_menu_saving"), "radial_effect", 4, 4);
	-- 	bAny = true;
	-- else
	-- 	registerMenuItem(Interface.getString("interruption_add_menu"), "pointer", 3);
	-- 	registerMenuItem(Interface.getString("interruption_menu_saving"), "radial_effect", 3, 4);
	-- end

	local bAny = addMenuItem(node.getChild("attacking"), Interface.getString("interruption_menu_attacking"), "radial_sword", 3);
	bAnys = bAny or addMenuItem(node.getChild("saving"), Interface.getString("interruption_menu_saving"), "radial_effect", 4);

	applies.setReadOnly(bAny);

	-- buildSubMenu(Interface.getString("interruption_menu_attacking"), "radial_sword", 2, DB.getValue(node, "attacking.applies", ""));
	-- buildSubMenu(Interface.getString("interruption_menu_saving"), "radial_effect", 3, DB.getValue(node, "saving.applies", ""));
end

function addMenuItem(node, sLabel, sIcon, nPosition)
	local bAny = false;
	if node then
		registerMenuItem(Interface.getString("interruption_remove_menu"), "crossed", 4);
		registerMenuItem(sLabel, sIcon, 4, nPosition);
		bAny = true;
	else
		registerMenuItem(Interface.getString("interruption_add_menu"), "pointer", 3);
		registerMenuItem(sLabel, sIcon, 3, nPosition);
	end
	return bAny
end

-- function buildSubMenu(sName, sIcon, nPosition, rNode)
-- 	registerMenuItem(sName, sIcon, 3, nPosition);

-- 	local sApplies;
-- 	if rNode and rNode.getChildCount() == 1 then
-- 		for name,_ in pairs(rNode.getChildren()) do
-- 			sApplies = name;
-- 		end
-- 	end

-- 	if sApplies ~= "result" then
-- 		registerMenuItem(Interface.getString("interruption_menu_result"), "send", 3, nPosition, 3);
-- 	end
-- 	if sApplies ~= "roll" then
-- 		registerMenuItem(Interface.getString("interruption_menu_roll"), "customdice", 3, nPosition, 4);
-- 	end
-- 	if (sApplies or "") ~= "" then
-- 		registerMenuItem(Interface.getString("interruption_menu_never"), "crossed", 3, nPosition, 5);
-- 	end
-- end

local secondSwitch = {
	[3] = "attacking",
	[4] = "saving"
};
-- local thirdSwitch = {
-- 	[3] = "result",
-- 	[4] = "roll"
-- }
function onMenuSelection(first, second, third)
	local node = getDatabaseNode();
	local group = secondSwitch[second];
	if first == 3 then
		local value;
		if (applies.getStringValue() or "" ) == "" then
			value = "roll";
		else
			value = "result";
		end
		-- local value = thirdSwitch[third];

		if (group or "") ~= "" then
			-- local toDelete = node.getChild(group);

			-- if toDelete then
			-- 	toDelete.delete();
			-- end
			-- if not value then
			if value then
				-- toDelete = nodes[group];
				-- Debug.chat(type(toDelete));

				-- if toDelete and toDelete.getName and toDelete.getName() == value then
				-- 	toDelete = nil;
				-- end

				-- DB.setValue(node, group .. ".applies", "string", value);
				-- updateGroupVisibility(group, value);

				-- local node = getDatabaseNode();
				local child = node.createChild(group);
				-- local child = node.createChild(group .. "." .. value);
				list.createWindowWithClass(group .. "_" .. value, child);
			end

			-- if value then
			-- 	DB.setValue(node, group .. ".applies", "string", value);
			-- 	updateGroupVisibility(group, value);
			-- else
			-- 	node.getChild(group).delete();
			-- end
		end

		-- if second == 2 then
		-- 	if third == 3 then
		-- 		DB.setValue(getDatabaseNode(), "attacking.applies", "string", "result");
		-- 		-- attacking_roll.setVisible(false);
		-- 		-- attacking_result.setVisible(true);
		-- 	elseif third == 4 then
		-- 		DB.setValue(getDatabaseNode(), "attacking.applies", "string", "roll");
		-- 		-- attacking_roll.setVisible(true);
		-- 		-- attacking_result.setVisible(false);
		-- 	else
		-- 		DB.setValue(getDatabaseNode(), "attacking.applies", "string", nil);
		-- 		-- attacking_roll.setVisible(false);
		-- 		-- attacking_result.setVisible(false);
		-- 	end
		-- end
	else
		local toDelete = node.getChild(group);
		if toDelete then
			toDelete.delete();
		end
	end

	buildMenu();

	-- updateVisibility();
end

function updateVisibility()
	-- local node = getDatabaseNode();
	
	-- local child = node.getChild("attacking");
	-- local roll = (applies.getStringValue() or "") == "";
	-- if child then
	-- 	if roll then
	-- 		list.createWindowWithClass("attacking_roll", child);
	-- 	else
	-- 		list.createWindowWithClass("attacking_result", child);
	-- 	end
	-- end

	-- child = node.getChild("saving");
	-- if child then
	-- 	if roll then
	-- 		list.createWindowWithClass("saving_roll", child);
	-- 	else
	-- 		list.createWindowWithClass("saving_result", child);
	-- 	end
	-- end

	local roll = (applies.getStringValue() or "") == "";
	updateGroupVisibility("attacking", roll);
	updateGroupVisibility("saving", roll);
	
	-- local child = node.getChild("attacking.roll");
	-- if child then
	-- 	list.createWindowWithClass("attacking_roll", child);
	-- end

	-- child = node.getChild("attacking.result");
	-- if child then
	-- 	list.createWindowWithClass("attacking_result", child);
	-- end
	
	-- local child = node.getChild("saving.roll");
	-- if child then
	-- 	list.createWindowWithClass("saving_roll", child);
	-- end

	-- child = node.getChild("saving.result");
	-- if child then
	-- 	list.createWindowWithClass("saving_result", child);
	-- end
	
	-- updateGroupVisibility("attacking", DB.getValue(node, ".attacking.applies"))
	-- updateGroupVisibility("saving", DB.getValue(node, ".saving.applies"))
end

function updateGroupVisibility(sGroup, bRoll)
	local node = getDatabaseNode();
	local child = node.getChild(sGroup);
	if child then
		if bRoll then
			list.createWindowWithClass(sGroup .. "_roll", child);
		else
			list.createWindowWithClass(sGroup .. "_result", child);
		end
	end

	-- if (sValue or "") ~= "" then
	-- 	local node = getDatabaseNode();
	-- 	local child = node.createChild(sGroup .. "." .. sValue);
	-- 	-- nodes[sGroup] = child;
	-- 	list.createWindowWithClass(sGroup .. "_" .. sValue, child);
	-- end
end