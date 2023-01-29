--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	detail.onDragStart = onDetailsDragStart;
end

function onDetailsDragStart(button, x, y, draginfo)
	draginfo.setType("poweraction");
	draginfo.setIcon("action_roll");
	draginfo.setDatabaseNode(getDatabaseNode());
	return true;
end