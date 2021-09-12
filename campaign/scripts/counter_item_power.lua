-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local nodePower;
local nodeItem;
local nTotal;
local nUsed;
local bWheel = false;

local adjustCounterOriginal;
local getCastValueOriginal;

-- Initialization
function onInit()
	if super and super.onInit then
		super.onInit()
	end

	adjustCounterOriginal = super.adjustCounter;
	super.adjustCounter = adjustCounter;
	getCastValueOriginal = super.getCastValue;
	super.getCastValue = getCastValue;

	nodePower = window.getDatabaseNode();
	nodeItem = DB.getChild(nodePower, "...");
	
	onChargesChanged();
	DB.addHandler(nodeItem.getPath("count"), "onUpdate", onChargesChanged);
	DB.addHandler(nodeItem.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.addHandler(nodePower.getPath("charges"), "onUpdate", onChargesChanged);
	DB.addHandler(nodeItem.getPath("powers.*.cast"), "onUpdate", onChargesChanged);
	DB.addHandler(nodeItem.getPath("powers.*.chargeperiod"), "onUpdate", onChargesChanged);
end

function onClose()
	DB.removeHandler(nodeItem.getPath("count"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodeItem.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodePower.getPath("charges"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodeItem.getPath("powers.*.cast"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodeItem.getPath("powers.*.chargeperiod"), "onUpdate", onChargesChanged);

	if super and super.onClose then
		super.onClose()
	end
end

function getCastValue()
	if type(window) == "windowinstance" then
		return getCastValueOriginal();
	end
	return 0;
end

function onWheel(notches)
	bWheel = true;
	local result = super.onWheel(notches);
	bWheel = false;
	return result;
end

function adjustCounter(val_adj)
	if not bWheel and DB.getValue(nodePower, "chargeperiod", "") == "" then
		if val_adj == 1 then
			val_adj = DB.getValue(nodePower, "charges", 1);
		elseif val_adj == -1 then
			val_adj = val_adj * DB.getValue(nodePower, "charges", 1);
		end
	end
	adjustCounterOriginal(val_adj);
end

function onChargesChanged()
	calculateTotal();
	calculateUsed();
	
	local nodePower = getDatabaseNode();
	DB.setValue(nodePower, "prepared", "number", nTotal);
	-- setVisible(nTotal > 0); --todo cleanup
	if super and super.update then
		super.update("standard", true, nTotal, nUsed, nTotal);
	end
end

function onValueChanged()
	ItemPowerManager.handleItemChargesUsed(nodeItem);
end

function calculateTotal()
	local nCharges = DB.getValue(nodePower, "charges", 0);
	if nCharges > 0 then
		if DB.getValue(nodePower, "chargeperiod", "") == "" then
			nTotal = DB.getValue(nodeItem, "prepared", 0) * DB.getValue(nodeItem, "count", 1);
		else
			nTotal = nCharges;
		end
	else
		nTotal = 0;
	end
end

function calculateUsed()
	if DB.getValue(nodePower, "chargeperiod", "") == "" then
		nUsed = ItemPowerManager.countCharges(nodeItem);
	else
		nUsed = DB.getValue(nodePower, "cast", 0);
	end
end

function getTotalCharges()
	if not nTotal then
		calculateTotal();
	end
	return nTotal;
end

function getChargesUsed()
	if not nUsed then
		calculateUsed();
	end
	return nUsed;
end