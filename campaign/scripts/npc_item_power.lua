-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nodePower;

-- Initialization
function onInit()
	nodePower = getDatabaseNode();
	DB.addHandler(nodePower.getPath("name"), "onUpdate", onPowerUpdate);
	DB.addHandler(nodePower.getPath("group"), "onUpdate", onPowerUpdate);
	DB.addHandler(nodePower.getPath("actions"), "onChildUpdate", onActionUpdate);
	DB.addHandler(nodePower.getPath("actions"), "onChildDeleted", onActionUpdate);
	processPower();
end

function onClose()
	DB.removeHandler(nodePower.getPath("name"), "onUpdate", onPowerUpdate);
	DB.removeHandler(nodePower.getPath("group"), "onUpdate", onPowerUpdate);
	DB.removeHandler(nodePower.getPath("actions"), "onChildUpdate", onActionUpdate);
	DB.removeHandler(nodePower.getPath("actions"), "onChildDeleted", onActionUpdate);
end

function onPowerUpdate()
	processPower();
end

function onActionUpdate(_, bChildUpdated)
	if not bChildUpdated then
		processPower();
	end
end

function processPower()
	local nodeNPC = nodePower.getChild(".....");
	ActorManagerKNK.beginResolvingItem(nodePower.getChild("....."));
	local aActions = {}
	for _,nodeAction in pairs(DB.getChildren(nodePower, "actions")) do
		local rAction = PowerManager.getPCPowerAction(nodeAction);
		PowerManager.evalAction(nodeNPC, nodePower, rAction);
		if rAction.type == "cast" then
			table.insert(aActions, getCastValue(rAction));
		elseif rAction.type == "damage" then
			table.insert(aActions, getDamageValue(rAction));
		elseif rAction.type == "heal" then
			table.insert(aActions, getHealValue(rAction));
		elseif rAction.type == "effect" then
			table.insert(aActions, getEffectValue(rAction));
		end
	end
	ActorManagerKNK.endResolvingItem();

	local sValue = DB.getValue(nodePower, "name", "");
	if #aActions > 0 then
		sValue = sValue .. table.concat(aActions, " ");
	end
	DB.setValue(nodePower, "value", "string", sValue);
end

function getCastValue(rAction)
	local aValues = {};
	if (rAction.range or "") ~= "" then
		table.insert(aValues, string.format("[%s]", rAction.range));
		if rAction.rangedist and rAction.rangedist ~= "5" then
			table.insert(aValues, string.format("[RNG: %s]", rAction.rangedist));
		end
		table.insert(aValues, string.format("[ATK: %+d]", rAction.modifier or 0));
	end

	if rAction.save ~= "" then
		local sSaveVs = string.format("[SAVEVS: %s", rAction.save);
		sSaveVs = sSaveVs .. " " .. (rAction.savemod or 0);

		if rAction.onmissdamage == "half" then
			sSaveVs = sSaveVs .. " (H)";
		end
		if rAction.magic then
			sSaveVs = sSaveVs .. " (magic)";
		end
		sSaveVs = sSaveVs .. "]";
		table.insert(aValues, sSaveVs);
	end

	return table.concat(aValues, " ");
end

function getDamageValue(rAction)
	local aValues = {};
	for _,vClause in ipairs(rAction.clauses) do
		local sValue = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
		if (vClause.dmgtype or "") ~=  "" then
			sValue = sValue .. " " .. vClause.dmgtype;
		end
		table.insert(aValues, sValue);
	end
	return string.format("[DMG: %s]", table.concat(aValues, " + "));
end

function getHealValue(rAction)
	local aValues = {};
	for _,vClause in ipairs(rAction.clauses) do
		local sValue = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
		table.insert(aValues, sValue);
	end
	return string.format("[HEAL: %s]", table.concat(aValues, " + "));
end

function getEffectValue(rAction)
	return EffectManager5E.encodeEffectForCT(rAction);
end