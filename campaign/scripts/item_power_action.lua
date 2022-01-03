-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local onDragStartOriginal;

-- Initialization
function onInit()
	getDatabaseNode().onChildUpdate = onDataChanged;
	onDataChanged();

	onDragStartOriginal = details.onDragStart;
end

function onClose()
	getDatabaseNode().onChildUpdate = nil;
end

function update(bReadOnly, bHideCast)
	if bReadOnly then
		resetMenuItems();
		details.onDragStart = onDragStartOriginal;
	else
		registerMenuItem(Interface.getString("power_menu_actiondelete"), "radial_delete_action", 4);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "radial_delete_action_confirm", 4, 3);
		details.onDragStart = onDetailsDragStart;
	end

	details.setVisible(not bReadOnly);
	if castbutton then
		castbutton.setVisible(not bHideCast);
	end

	-- Cast fields
	if castlabel then
		castlabel.setVisible(not bHideCast);
	end
	if attackbutton then
		attackbutton.setVisible(not bHideCast);
	end
	if savebutton then
		savebutton.setVisible(not bHideCast);
	end
	if testbutton then
		testbutton.setVisible(not bHideCast);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 4 and subselection == 3 then
		getDatabaseNode().delete();
	end
end

function onDataChanged()
	local nodeAction = getDatabaseNode();
	local sType = DB.getValue(getDatabaseNode(), "type", "");
	ActorManagerKNK.beginResolvingItem(nodeAction.getChild(".......") or true);
	if sType == "cast" then
		onCastChanged(nodeAction);
	elseif sType == "damage" then
		onDamageChanged(nodeAction);
	elseif sType == "heal" then
		onHealChanged(nodeAction);
	elseif sType == "effect" then
		onEffectChanged(nodeAction);
	elseif sType == "test" then
		onTestChanged(nodeAction);
	elseif sType == "resource" then
		onResourceChanged(nodeAction);
	end
	ActorManagerKNK.endResolvingItem();
end

function onCastChanged(nodeAction)
	local sAttack, sSave = PowerManager.getPCPowerCastActionText(nodeAction);
	attackview.setValue(sAttack);
	saveview.setValue(sSave);
end

function onDamageChanged(nodeAction)
	local sDamage = PowerManager.getPCPowerDamageActionText(nodeAction);
	damageview.setValue(sDamage);
end

function onHealChanged(nodeAction)
	local sHeal = PowerManager.getPCPowerHealActionText(nodeAction);
	healview.setValue(sHeal);
end

function onEffectChanged(nodeAction)	
	local sLabel = DB.getValue(nodeAction, "label", "");
	
	local sApply = DB.getValue(nodeAction, "apply", "");
	if sApply == "action" then
		sLabel = sLabel .. "; [ACTION]";
	elseif sApply == "roll" then
		sLabel = sLabel .. "; [ROLL]";
	elseif sApply == "single" then
		sLabel = sLabel .. "; [SINGLES]";
	end
	
	local sTargeting = DB.getValue(nodeAction, "targeting", "");
	if sTargeting == "self" then
		sLabel = sLabel .. "; [SELF]";
	end

	local sDuration = "" .. DB.getValue(nodeAction, "durmod", 0);
	
	local sUnits = DB.getValue(nodeAction, "durunit", "");
	if sDuration ~= "" then
		if sUnits == "minute" then
			sDuration = sDuration .. " min";
		elseif sUnits == "hour" then
			sDuration = sDuration .. " hr";
		elseif sUnits == "day" then
			sDuration = sDuration .. " dy";
		else
			sDuration = sDuration .. " rd";
		end
	end
	
	effectview.setValue(sLabel);
	durationview.setValue(sDuration);
end

function onTestChanged(nodeAction)
	local sTest = PowerManagerKw.getPCPowerTestActionText(nodeAction);
	testview.setValue(sTest);
end

function onResourceChanged()
	local sResource = PowerManagerCg.getPCPowerResourceActionText(getDatabaseNode());
	resourceview.setValue(sResource);
end

function onDetailsDragStart(button, x, y, draginfo)
	draginfo.setType("poweraction");
	draginfo.setIcon("action_roll");
	draginfo.setDatabaseNode(getDatabaseNode());
	return true;
end