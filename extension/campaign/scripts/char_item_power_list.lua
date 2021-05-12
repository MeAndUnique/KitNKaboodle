-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nodeChar;
local bIsDefault = false;
local groupsForItems = {};
local pendingItemsByGroupName = {};
local pendingItemsByItemNode = {};

-- Initialization
function onInit()
	if isdefault then
		bIsDefault = true;
	end

	nodeChar = window.getDatabaseNode();
	DB.addHandler(nodeChar.getPath("inventorylist.*"), "onAdd", onItemAdded);
	DB.addHandler(nodeChar.getPath("inventorylist.*"), "onDelete", onItemDeleted);

	DB.addHandler(nodeChar.getPath("inventorylist.*.name"), "onUpdate", onNameChanged);
	DB.addHandler(nodeChar.getPath("inventorylist.*.displaygroup"), "onUpdate", onDisplayGroupChanged);

	DB.addHandler(nodeChar.getPath("itemgroups.*.name"), "onUpdate", onGroupNamed);

	for _,nodeGroup in pairs(DB.getChildren(nodeChar, "itemgroups")) do
		local sName = DB.getValue(nodeGroup, "name", "");
		if sName ~= "" then
			local windowGroup = createWindow(nodeGroup);
			initializeItemGroup(windowGroup, sName);
		end
	end

	for _,nodeItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		onItemAdded(nodeItem);
	end
end

function onClose()
	DB.removeHandler(nodeChar.getPath("inventorylist.*"), "onAdd", onItemAdded);
	DB.removeHandler(nodeChar.getPath("inventorylist.*"), "onDelete", onItemDeleted);

	DB.removeHandler(nodeChar.getPath("inventorylist.*.name"), "onUpdate", onNameChanged);
	DB.removeHandler(nodeChar.getPath("inventorylist.*.displaygroup"), "onUpdate", onDisplayGroupChanged);
	
	DB.removeHandler(nodeChar.getPath("itemgroups.*.name"), "onAdd", onGroupNamed);
end

function onFilter(instance)
	return instance.shouldBeShown();
end

function onGroupNamed(nodeName)
	local nodeGroup = nodeName.getChild("..");
	local windowGroup = createWindow(nodeGroup);
	initializeItemGroup(windowGroup, nodeName.getValue());
end

function onItemAdded(nodeItem)
	local sGroup = ItemPowerManager.getItemGroupName(nodeItem);
	setItemGroup(nodeItem, sGroup);
end

function onItemDeleted(nodeItem)
	local windowGroup = groupsForItems[nodeItem];
	if type(windowGroup) == "windowinstance" then
		windowGroup.removeItem(nodeItem);
	end
	groupsForItems[nodeItem] = nil;
end

function onFilteredValueChanged(node)
	applyFilter();
end

function onNameChanged(nodeName)
	local nodeItem = nodeName.getChild("..");
	local sGroup = ItemPowerManager.getItemGroupName(nodeItem);
	setItemGroup(nodeItem, sGroup);
end

function onDisplayGroupChanged(nodeDisplayGroup)
	local nodeItem = nodeDisplayGroup.getChild("..");
	local sGroup = ItemPowerManager.getItemGroupName(nodeItem);
	setItemGroup(nodeItem, sGroup);
end

function getLoadedGroups()
	if not window.parentcontrol.window.itemGroups then
		window.parentcontrol.window.itemGroups = {};
	end
	return window.parentcontrol.window.itemGroups;
end

function setItemGroup(nodeItem, sGroup)
	if sGroup == "" then
		sGroup = "<< Unnamed Items >>";
	end

	local windowGroup = groupsForItems[nodeItem];
	if type(windowGroup) == "windowinstance" then
		if windowGroup.name.getValue() == sGroup then
			return; -- Already in the correct group
		else
			windowGroup.removeItem(nodeItem);
		end
	end

	local rPreviouslyPending = pendingItemsByItemNode[nodeItem];
	if rPreviouslyPending then
		table.remove(pendingItemsByGroupName[rPreviouslyPending.sGroup], rPreviouslyPending.nIndex);
	end

	windowGroup = getLoadedGroups()[sGroup];
	if type(windowGroup) == "windowinstance" then
		groupsForItems[nodeItem] = windowGroup;
		windowGroup.addItem(nodeItem);
	else
		-- TODO top vs bottom
		local pendingItems = pendingItemsByGroupName[sGroup];
		if not pendingItems then
			pendingItems = {};
			pendingItemsByGroupName[sGroup] = pendingItems;
		end
		table.insert(pendingItems, nodeItem);
		pendingItemsByItemNode[nodeItem] = {sGroup = sGroup, nIndex = #pendingItems};
		ItemPowerManager.beginCreatingItemGroup(nodeItem.getChild("...").getPath(), sGroup);
	end
end

function initializeItemGroup(windowGroup, sGroup)
	local pendingItems = pendingItemsByGroupName[sGroup];
	pendingItemsByGroupName[sGroup] = nil;

	if pendingItems then
		for _,nodeItem in ipairs(pendingItems) do
			windowGroup.addItem(nodeItem);
			pendingItemsByItemNode[nodeItem] = nil;
			groupsForItems[nodeItem] = windowGroup;
		end
	end

	getLoadedGroups()[sGroup] = windowGroup;
end