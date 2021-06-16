-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nodeItem;
local nTotal;
local nUsed;
local bWheel = false;

-- Initialization
function onInit()
	if super and super.onInit then
		super.onInit()
	end

	local nodePower = window.getDatabaseNode();
	nodeItem = DB.getChild(nodePower, "...");
	
	onChargesChanged();
	DB.addHandler(nodeItem.getPath("count"), "onUpdate", onChargesChanged);
	DB.addHandler(nodeItem.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.addHandler(nodeItem.getPath("powers.*.cast"), "onUpdate", onChargesChanged);
end

function onWheel(notches)
	bWheel = true;
	super.onWheel(notches);
	bWheel = false;
end

function onClose()
	if super and super.onClose then
		super.onClose()
	end

	DB.removeHandler(nodeItem.getPath("count"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodeItem.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodeItem.getPath("powers.*.cast"), "onUpdate", onChargesChanged);
end

function onChargesChanged()
	calculateTotal();
	nUsed = ItemPowerManager.countCharges(nodeItem);
	
	local nodePower = getDatabaseNode();
	DB.setValue(nodePower, "prepared", "number", nTotal);
	setVisible(nTotal > 0);
	if super and super.update then
		super.update("standard", true, nTotal, nUsed, nTotal);
	end

	ItemPowerManager.handleItemChargesUsed(nodeItem);
end

function calculateTotal()
	nTotal = DB.getValue(nodeItem, "prepared", 0) * DB.getValue(nodeItem, "count", 1);
end

function getTotalCharges()
	if not nTotal then
		calculateTotal();
	end
	return nTotal;
end

function getChargesUsed()
	if not nUsed then
		nUsed = ItemPowerManager.countCharges(nodeItem);
	end
	return nUsed;
end