-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeRecord = getDatabaseNode();
	DB.addHandler(nodeRecord.getPath("locked"), "onUpdate", onLockChanged);

	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	update(bReadOnly);
end

function onLockChanged(nodeLocked)
	local bLocked = nodeLocked.getValue() ~= 0;
	update(bLocked);
end

function update(bReadOnly)
	prepared.setReadOnly(bReadOnly);
	usesperiod.setReadOnly(bReadOnly);
	actions.update(bReadOnly, true);

	if bReadOnly then
		prepared.setFrame(nil);
	else
		prepared.setFrame("fielddark", 7, 5, 7, 5);
	end
end