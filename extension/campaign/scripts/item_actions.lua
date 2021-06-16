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

function onClose()
	local nodeRecord = getDatabaseNode()
	DB.removeHandler(nodeRecord.getPath("locked"), "onUpdate", onLockChanged);
end

function onLockChanged(nodeLocked)
	local bLocked = nodeLocked.getValue() ~= 0;
	update(bLocked);
end

function update(bLocked)
	charges.subwindow.update(bLocked);
	miscellaneous.subwindow.update(bLocked);

	if bLocked then
		powerlist_iedit.setValue(0);
	end
	powerlist_iedit.setVisible(not bLocked);

	powerlist.setReadOnly(bLocked);
	for _, win in ipairs(powerlist.getWindows()) do
		win.update(bLocked, true);
	end
end

function onDrop(x, y, draginfo)
	local node = getDatabaseNode();
	if draginfo.isType("shortcut") and not WindowManager.getReadOnlyState(node) then
		local sClass = draginfo.getShortcutData();
		if sClass == "reference_spell" or
		sClass == "power" or
		sClass == "reference_classfeature" or
		sClass == "reference_racialtrait" or
		sClass == "reference_feat" or
		sClass == "ref_ability" then
			PowerManager.addPower(sClass, draginfo.getDatabaseNode(), node);
		end
	end
end