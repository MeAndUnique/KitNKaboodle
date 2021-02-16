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
		-- savebutton.setAnchor("left", "", "center", bHideCast and 0 or 20);
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
	
	if sType == "cast" then
		onCastChanged(nodeAction);
	elseif sType == "damage" then
		onDamageChanged(nodeAction);
	elseif sType == "heal" then
		onHealChanged(nodeAction);
	elseif sType == "effect" then
		onEffectChanged(nodeAction);
	end
end

function onCastChanged(nodeAction)
	local sAttack = "";
	local sSave = "";

	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	rActor = ActorManager.resolveActor(nodeAction.getChild("......."));
	if rAction then
		PowerManager.evalAction(rActor, nodeAction.getChild("..."), rAction);
		
		if (rAction.range or "") ~= "" then
			if rAction.range == "R" then
				sAttack = Interface.getString("ranged");
			else
				sAttack = Interface.getString("melee");
			end
			if rAction.modifier ~= 0 then
				sAttack = string.format("%s %+d", sAttack, rAction.modifier);
			end
		end
		if (rAction.save or "") ~= "" then
			sSave = StringManager.capitalize(rAction.save:sub(1,3)) .. " DC " .. rAction.savemod;
			if rAction.onmissdamage == "half" then
				sSave = sSave .. " (H)";
			end
		end
	end

	attackview.setValue(sAttack);
	saveview.setValue(sSave);
end

function onDamageChanged(nodeAction)
	local aOutput = {};
	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	rActor = ActorManager.resolveActor(nodeAction.getChild("......."));
	if rAction then
		PowerManager.evalAction(rActor, nodeAction.getChild("..."), rAction);
		
		local aDamage = ActionDamage.getDamageStrings(rAction.clauses);
		for _,rDamage in ipairs(aDamage) do
			local sDice = StringManager.convertDiceToString(rDamage.aDice, rDamage.nMod);
			if rDamage.sType ~= "" then
				table.insert(aOutput, string.format("%s %s", sDice, rDamage.sType));
			else
				table.insert(aOutput, sDice);
			end
		end
	end

	damageview.setValue(table.concat(aOutput, " + "));
end

function onHealChanged(nodeAction)
	local sHeal = "";
	
	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	rActor = ActorManager.resolveActor(nodeAction.getChild("......."));
	if rAction then
		PowerManager.evalAction(rActor, nodeAction.getChild("..."), rAction);
		
		local aHealDice = {};
		local nHealMod = 0;
		for _,vClause in ipairs(rAction.clauses) do
			for _,vDie in ipairs(vClause.dice) do
				table.insert(aHealDice, vDie);
			end
			nHealMod = nHealMod + vClause.modifier;
		end
		
		sHeal = StringManager.convertDiceToString(aHealDice, nHealMod);
		if DB.getValue(nodeAction, "healtype", "") == "temp" then
			sHeal = sHeal .. " temporary";
		end
		if DB.getValue(nodeAction, "healtargeting", "") == "self" then
			sHeal = sHeal .. " [SELF]";
		end
	end

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