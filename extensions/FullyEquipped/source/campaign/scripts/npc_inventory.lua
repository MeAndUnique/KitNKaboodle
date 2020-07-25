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
end

function onDrop(x, y, draginfo)
	local nodeRecord = getDatabaseNode();
	if not WindowManager.getReadOnlyState(nodeRecord) then
		return ItemManager.handleAnyDrop(nodeRecord, draginfo);
	end
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