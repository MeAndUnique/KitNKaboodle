-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bDropping = false;
local nodeAddedItem;

-- Initialization
function onInit()
	local nodeRecord = getDatabaseNode();
	DB.addHandler(nodeRecord.getPath("locked"), "onUpdate", onLockChanged);

	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	update(bReadOnly);

	DB.addHandler(nodeRecord.getPath("inventorylist"), "onChildAdded", onItemAdded);
	DB.addHandler(nodeRecord.getPath("inventorylist.*.powers.*"), "onChildUpdate", onPowerUpdate);
end

function onClose()
	local nodeRecord = getDatabaseNode();
	DB.removeHandler(nodeRecord.getPath("locked"), "onUpdate", onLockChanged);
	DB.removeHandler(nodeRecord.getPath("inventorylist"), "onChildAdded", onItemAdded)
	DB.removeHandler(nodeRecord.getPath("inventorylist.*.powers.*"), "onChildUpdate", onPowerUpdate);
end

function onDrop(x, y, draginfo)
	local nodeRecord = getDatabaseNode();
	if not WindowManager.getReadOnlyState(nodeRecord) then
		bDropping = true;
		local bResult = ItemManager.handleAnyDrop(nodeRecord, draginfo);
		if bResult and nodeAddedItem then
			processItem(nodeRecord, nodeAddedItem);
		end

		nodeAddedItem = nil;
		bDropping = false;
		return bResult;
	end

	return false;
end

function onLockChanged(nodeLocked)
	local bLocked = nodeLocked.getValue() ~= 0;
	update(bLocked);
end

function update(bLocked)
	if bLocked then
		inventorylist_iedit.setValue(0);
	end
	inventorylist_iedit.setVisible(not bLocked);

	inventorylist.setReadOnly(bLocked);
	for _, win in ipairs(inventorylist.getWindows()) do
		win.update(bLocked);
	end
end

function onItemAdded(nodeNPC, nodeItem)
	if bDropping then
		nodeAddedItem = nodeItem;
	end
end

function onPowerUpdate(nodePower, bChildUpdated)
	if not bChildUpdated and not nodeAddedItem then
		processPower(getDatabaseNode(), nodePower);
	end
end

function processItem(nodeNPC, nodeItem)
	for _,nodePower in pairs(DB.getChildren(nodeItem, "powers")) do
		processPower(nodeNPC, nodePower);
	end
end

function processPower(nodeNPC, nodePower)
	local sValue = DB.getValue(nodePower, "name", "");

	if DB.getChildCount(nodePower, "actions") > 0 then
		sValue = sValue .. " - ";
	end

	local aActions = {}
	for _,nodeAction in pairs(DB.getChildren(nodePower, "actions")) do
		local rAction = PowerManager.getPCPowerAction(nodeAction);
		PowerManager.evalAction(nodeNPC, nodePower, rAction);
		if rAction.type == "cast" then
			table.insert(aActions, getCastValue(nodeNPC, rAction));
		elseif rAction.type == "damage" then
			table.insert(aActions, getDamageValue(nodeNPC, rAction));
		elseif rAction.type == "heal" then
			table.insert(aActions, getHealValue(nodeNPC, rAction));
		elseif rAction.type == "effect" then
			table.insert(aActions, getEffectValue(nodeNPC, rAction));
		end
	end

	if #aActions > 0 then
		sValue = sValue .. table.concat(aActions, " ");
	end
	DB.setValue(nodePower, "value", "string", sValue);
end

function getCastValue(nodeNPC, rAction)
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

function getDamageValue(nodeNPC, rAction)
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

function getHealValue(nodeNPC, rAction)
	local aValues = {};
	for _,vClause in ipairs(rAction.clauses) do
		local sValue = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
		table.insert(aValues, sValue);
	end
	return string.format("[HEAL: %s]", table.concat(aValues, " + "));
end

function getEffectValue(nodeNPC, rAction)
	return EffectManager5E.encodeEffectForCT(rAction);
end