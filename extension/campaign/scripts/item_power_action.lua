-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Initialization
function onInit()
	getDatabaseNode().onChildUpdate = onDataChanged;
	onDataChanged();
end

function onClose()
	getDatabaseNode().onChildUpdate = nil;
end

function update(bReadOnly, bHideCast)
	if bReadOnly then
		resetMenuItems();
	else
		registerMenuItem(Interface.getString("power_menu_actiondelete"), "deletepointer", 4);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 4, 3);
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
	if attackview then
		attackview.setEnabled(not bHideCast);
	end
	if savebutton then
		savebutton.setVisible(not bHideCast);
	end
	if saveview then
		saveview.setEnabled(not bHideCast);
	end

	-- Damage fields
	if damageview then
		damageview.setEnabled(not bHideCast);
	end

	-- Heal fields
	if healview then
		healview.setEnabled(not bHideCast);
	end

	-- Effect fields
	if effectview then
		effectview.setEnabled(not bHideCast);
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
	ActorManagerKNK.beginResolvingItem(nodeAction.getChild("......."));
	if sType == "cast" then
		onCastChanged(nodeAction);
	elseif sType == "damage" then
		onDamageChanged(nodeAction);
	elseif sType == "heal" then
		onHealChanged(nodeAction);
	elseif sType == "effect" then
		onEffectChanged(nodeAction);
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