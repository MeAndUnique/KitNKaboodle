--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local bReadOnly;
local bHideCast;

-- Initialization
function onInit()
	bHideCast = windowlist.window.bHideCast;
	update(windowlist.isReadOnly(), bHideCast);

	local nodePower = getDatabaseNode();
	DB.addHandler(nodePower.getPath("actions"), "onChildAdded", onActionAdded);
	DB.addHandler(nodePower.getPath("actions"), "onChildDeleted", onActionDeleted);
end

function onClose()
	local nodePower = getDatabaseNode();
	DB.removeHandler(nodePower.getPath("actions"), "onChildAdded", onActionAdded);
	DB.removeHandler(nodePower.getPath("actions"), "onChildDeleted", onActionDeleted);
end

function onActionAdded()
	updateToggle();
end

function onActionDeleted()
	updateToggle();
end

function shouldShowToggle(nodePower)
	return DB.getChildCount(nodePower, "actions") > 0;
end

function updateToggle()
	local bShow = shouldShowToggle(getDatabaseNode());
	if bShow then
		activatedetail.setValue(1);
		activatedetail.setVisible(true);
	else
		activatedetail.setValue(0);
		activatedetail.setVisible(false);
	end
end

function toggleDetail()
	local status = (activatedetail.getValue() == 1);
	actions.setVisible(status);
end

function update(bNewReadOnly, bNewHideCast)
	bReadOnly = bNewReadOnly;
	bHideCast = bNewHideCast;
	local nodePower = getDatabaseNode();
	header.subwindow.name.setReadOnly(bReadOnly);
	activatedetail.setVisible(shouldShowToggle(nodePower));

	if bReadOnly then
		header.subwindow.name.setFrame(nil);
		resetMenuItems();
	else
		header.subwindow.name.setFrame("fieldlight", 7, 5, 9, 5);

		if self.parentcontrol then
			self.windowlist = self.parentcontrol;
		end
		PowerManagerCore.registerDefaultPowerMenu(self);
		if self.parentcontrol then
			self.windowlist = nil;
		end
	end

	actions.update(bReadOnly, bHideCast);
end

function onMenuSelection(...)
	PowerManagerCore.onDefaultPowerMenuSelection(self, ...)
end