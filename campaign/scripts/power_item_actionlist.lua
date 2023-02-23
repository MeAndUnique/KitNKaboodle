--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local bReadOnly = true;
local bHideCast = true;

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	local nodePower = window.getDatabaseNode();
	DB.addHandler(nodePower.getPath("actions"), "onChildDeleted", onActionDeleted);

	PowerManagerKNK.fillActionOrderGap(window.getDatabaseNode());
end

function onClose()
	local nodePower = window.getDatabaseNode();
	DB.removeHandler(nodePower.getPath("actions"), "onChildDeleted", onActionDeleted);

	if super and super.onClose then
		super.onClose();
	end
end

function onActionDeleted()
	PowerManagerKNK.fillActionOrderGap(window.getDatabaseNode());
end

function update(bNewReadOnly, bNewHideCast)
	bReadOnly = bNewReadOnly;
	bHideCast = bNewHideCast;
	-- TODO check for drag reording on readonly
	for _,win in ipairs(getWindows()) do
		win.update(bReadOnly, bHideCast);
	end
end