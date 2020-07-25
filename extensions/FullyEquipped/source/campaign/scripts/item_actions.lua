-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Initialization
function onInit()
	local nodeRecord = getDatabaseNode();
	DB.addHandler(nodeRecord.getPath("locked"), "onUpdate", onLockChanged);

	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	update(bReadOnly);

	onChargesChanged();
	DB.addHandler(nodeRecord.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.addHandler(nodeRecord.getPath("powers.*.cast"), "onUpdate", onChargesChanged);
end

function onClose()
	local node = getDatabaseNode()
	DB.removeHandler(node.getPath("locked"), "onUpdate", onLockChanged);
	DB.removeHandler(node.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.removeHandler(node.getPath("powers.*.cast"), "onUpdate", onChargesChanged);
end

function onLockChanged(nodeLocked)
	local bLocked = nodeLocked.getValue() ~= 0;
	update(bLocked);
end

function update(bLocked)
	prepared.setReadOnly(bLocked);
	if bLocked then
		prepared.setFrame(nil);
	else
		prepared.setFrame("fielddark", 7, 5, 7, 5);
	end

	if bLocked then
		powers_iedit.setValue(0);
	end
	powers_iedit.setVisible(not bLocked);

	powers.setReadOnly(bLocked);
	for _, win in ipairs(powers.getWindows()) do
		win.update(bLocked, true);
	end
end

function onChargesChanged()
	local nTotal = DB.getValue(getDatabaseNode(), "prepared", 0);
	local nUsed = countCharges();
	for _, win in ipairs(powers.getWindows()) do
		win.updateUses(nTotal, nUsed);
	end
end

function countCharges()
	local node = getDatabaseNode();
	local nCount = 0;
	for _,powerNode in pairs(DB.getChildren(node.getPath("powers"))) do
		nCount = nCount + DB.getValue(powerNode, "cast", 0);
	end
	return nCount;
end