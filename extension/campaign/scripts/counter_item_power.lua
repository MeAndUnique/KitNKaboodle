-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nodeItem;

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

function onClose()
	if super and super.onClose then
		super.onClose()
	end

	DB.removeHandler(nodeItem.getPath("count"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodeItem.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodeItem.getPath("powers.*.cast"), "onUpdate", onChargesChanged);
end

function onChargesChanged()
	local nTotal = DB.getValue(nodeItem, "prepared", 0) * DB.getValue(nodeItem, "count", 1);
	local nUsed = countCharges();
	
	local nodePower = getDatabaseNode();
	DB.setValue(nodePower, "prepared", "number", nTotal);
	setVisible(nTotal > 0);
	if super and super.update then
		super.update("standard", true, nTotal, nUsed, nTotal);
	end
end

function countCharges()
	local nCount = 0;
	for _,powerNode in pairs(DB.getChildren(nodeItem.getPath("powers"))) do
		nCount = nCount + DB.getValue(powerNode, "cast", 0);
	end
	return nCount;
end