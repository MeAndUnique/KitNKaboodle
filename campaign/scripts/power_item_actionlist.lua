--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local dropWidget;

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

function onHover(bOnControl)
	if super and super.onHover then
		super.onHover(bOnControl);
	end

	if (not bOnControl) and dropWidget then
		dropWidget.destroy();
		dropWidget = nil;
	end
end

function onHoverUpdate(x, y)
	if super and super.onHoverUpdate then
		super.onHoverUpdate(x, y);
	end

	if bReadOnly then
		return;
	end

	local draginfo = Input.getDragData();
	if (not draginfo) or (draginfo.getType() ~= "poweraction") then
		return;
	end

	local win = getWindowAt(x, y);

	if not dropWidget then
		dropWidget = addBitmapWidget("tool_right_30");
	end

	local widgetWidth, widgetHeight = dropWidget.getSize();

	local nodeDragged = draginfo.getDatabaseNode();
	local nodeOriginPower = DB.getChild(nodeDragged, "...");
	local nOrder = DB.getValue(nodeDragged, "order", 0);
	local nHeight = 0;
	for nIndex, winChild in ipairs(getWindows()) do
		local _,windowHeight = winChild.getSize();
		if winChild == win then
			if (nIndex > nOrder) or (nodeOriginPower ~= window.getDatabaseNode()) then
				nHeight = nHeight + windowHeight;
			end
			break;
		end
		nHeight = nHeight + windowHeight;
	end

	dropWidget.setPosition("topleft", 20 + widgetWidth/2, nHeight);
end

function onDrop(x, y, draginfo)
	local result = false;
	if super and super.onDrop then
		result = super.onDrop(x, y, draginfo);
	end

	if bReadOnly then
		return result;
	end

	if dropWidget then
		dropWidget.destroy();
		dropWidget = nil;
	end

	if draginfo.getType() ~= "poweraction" then
		return result;
	end

	local win = getWindowAt(x, y);
	local nodeDragged = draginfo.getDatabaseNode();
	local nodeTarget;
	if win then
		nodeTarget = win.getDatabaseNode();
	end
	PowerManagerKNK.moveAction(window.getDatabaseNode(), nodeDragged, nodeTarget);
	applySort();
	return true;
end