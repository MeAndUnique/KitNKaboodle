-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Initialization
function onInit()
	local nodeRecord = getDatabaseNode();
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

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	for _, window in pairs(powers.getWindows()) do
		window.update(bReadOnly);
	end
end