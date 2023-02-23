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
	DB.addHandler(nodePower.getChild("...").getPath("prepared"), "onUpdate", onChargesChanged);
	DB.addHandler(nodePower.getPath("group"), "onUpdate", onGroupChanged);
	DB.addHandler(nodePower.getPath("actions"), "onChildAdded", onActionAdded);
	DB.addHandler(nodePower.getPath("actions"), "onChildDeleted", onActionDeleted);
end

function onClose()
	local nodePower = getDatabaseNode();
	DB.removeHandler(nodePower.getChild("...").getPath("prepared"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodePower.getPath("group"), "onUpdate", onGroupChanged);
	DB.removeHandler(nodePower.getPath("actions"), "onChildAdded", onActionAdded);
	DB.removeHandler(nodePower.getPath("actions"), "onChildDeleted", onActionDeleted);
end

function onChargesChanged(nodePrepared)
	local nodePower = getDatabaseNode();
	activatedetail.setVisible(shouldShowToggle(nodePower));
	metadata.setVisible(shouldShowMetaData(nodePower));
end

function onGroupChanged()
	for _,win in ipairs(actions.getWindows()) do
		win.onDataChanged();
	end
end

function onActionAdded()
	updateToggle();
end

function onActionDeleted()
	updateToggle();
end

function shouldShowToggle(nodePower)
	return (DB.getChildCount(nodePower, "actions") > 0) or bHideCast;
end

function shouldShowMetaData(nodePower)
	return bHideCast and (activatedetail.getValue() == 1);
end

function updateToggle()
	local nodePower = getDatabaseNode();
	local bShouldShowToggle = shouldShowToggle(nodePower);
	if bShouldShowToggle then
		activatedetail.setValue(1);
		activatedetail.setVisible(true);
	else
		activatedetail.setValue(0);
		activatedetail.setVisible(false);
	end
end

function toggleDetail()
	local status = (activatedetail.getValue() == 1);
	metadata.setVisible(status and bHideCast);
	actions.setVisible(status);
end

function update(bNewReadOnly, bNewHideCast)
	bReadOnly = bNewReadOnly;
	bHideCast = bNewHideCast;
	local nodePower = getDatabaseNode();
	header.subwindow.nameandactions.subwindow.name.setReadOnly(bReadOnly);
	header.subwindow.nameandactions.subwindow.actionsmini.setVisible(not bHideCast);
	activatedetail.setVisible(shouldShowToggle(nodePower));
	metadata.subwindow.charges.setReadOnly(bReadOnly);
	metadata.subwindow.chargeperiod.setReadOnly(bReadOnly);
	metadata.setVisible(shouldShowMetaData(nodePower));

	if bReadOnly then
		header.subwindow.nameandactions.subwindow.name.setFrame(nil);
		metadata.subwindow.charges.setFrame(nil);
		metadata.subwindow.chargeperiod.setFrame(nil);
		resetMenuItems();
	else
		header.subwindow.nameandactions.subwindow.name.setFrame("fieldlight", 7, 5, 9, 5);
		metadata.subwindow.charges.setFrame("fieldlight", 7, 5, 9, 5);
		metadata.subwindow.chargeperiod.setFrame("fieldlight", 7, 5, 9, 5);

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

function getDescription(nodePower, bShowFull)
	local s = DB.getValue(nodePower, "name", "");

	if bShowFull then
		local sShort = DB.getValue(nodePower, "shortdescription", "");
		if sShort ~= "" then
			s = s .. " - " .. sShort;
		end
	end

	return s;
end

function usePower(bShowFull)
	local nodePower = getDatabaseNode();
	local nodeItem = nodePower.getChild("...");
	ChatManager.Message(getDescription(nodePower, bShowFull), true, ActorManager.resolveActor(nodeItem));
end