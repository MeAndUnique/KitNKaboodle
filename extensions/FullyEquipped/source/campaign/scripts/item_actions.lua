-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Initialization
function onInit()
	local nodeRecord = getDatabaseNode();
	DB.addHandler(nodeRecord.getPath("locked"), "onUpdate", onLockChanged);
	-- TODO cleanup
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local nodePowers = nodeRecord.getChild("powers");
	if not bReadOnly then
		local text = DB.getValue(nodeRecord, "description", "crap")
		if type(text) == "string" and StringManager.contains({"spell"}, text) then
			Debug.chat("success");
		else
			Debug.chat(text);
		end
	end
end

function onClose()
	local nodeRecord = getDatabaseNode();
	DB.removeHandler(nodeRecord.getPath("locked"), "onUpdate", onLockChanged);
end

function onLockChanged(nodeLocked)
	local bLocked = nodeLocked.getValue() ~= 0;
	powers.setReadOnly(bLocked);
	for _, win in ipairs(powers.getWindows()) do
		win.update(bLocked);
	end
end