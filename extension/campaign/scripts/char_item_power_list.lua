-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nodeChar;
local bIsDefault = false;
local loadedItems = {};
local groupsForItems = {};
local pendingItemGroups = {};

-- Initialization
function onInit()
	if isdefault then
		bIsDefault = true;
	end

	nodeChar = window.getDatabaseNode();
	-- Debug.chat(nodeChar)
	DB.addHandler(nodeChar.getPath("inventorylist.*"), "onAdd", onItemAdded);
	DB.addHandler(nodeChar.getPath("inventorylist.*"), "onDelete", onItemDeleted);

	DB.addHandler(nodeChar.getPath("inventorylist.*.name"), "onUpdate", onNameChanged);
	DB.addHandler(nodeChar.getPath("inventorylist.*.displayGroup"), "onUpdate", onDisplayGroupChanged);

	-- DB.addHandler(nodeChar.getPath("inventorylist.*.carried"), "onUpdate", onFilteredValueChanged);
	-- DB.addHandler(nodeChar.getPath("inventorylist.*.isIdentified"), "onUpdate", onFilteredValueChanged);
	-- DB.addHandler(nodeChar.getPath("inventorylist.*.powers.*.name"), "onAdd", onFilteredValueChanged);
	-- DB.addHandler(nodeChar.getPath("inventorylist.*.powers.*.name"), "onDelete", onFilteredValueChanged);

	-- DB.addHandler(nodePower.getPath("name"), "onUpdate", onPowerUpdate);
	-- DB.addHandler(nodePower.getPath("group"), "onUpdate", onPowerUpdate);
	-- DB.addHandler(nodePower.getPath("actions"), "onChildUpdate", onActionUpdate);
	-- DB.addHandler(nodePower.getPath("actions"), "onChildDeleted", onActionUpdate);
	-- processPower();

	for _,nodeItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		onItemAdded(nodeItem);
	end
end

function onFilter(instance)
	local sClass = instance.getClass();
	if "char_direct_item_group" == sClass then
		filterDirectItem(instance);
	elseif "char_grouped_item_group" == sClass then
		filterItemGroup(instance);
	end
end

function filterDirectItem(instance)
	local nodeItem = instance.getDatabaseNode();
	return ItemPowerManager.shouldShowItemPowers(nodeItem) and (DB.getValue(nodeItem, "displaygroup", "") == "");
end

function filterItemGroup(instance)
	return instance.shouldBeShown();
end

function onItemAdded(nodeItem)
	Debug.chat("added", nodeItem);
	local sGroup = getItemGroupName(nodeItem);
	setItemGroup(nodeItem, sGroup);
	-- loadedItems[nodeItem] = createWindow(nodeItem);
end

function onItemDeleted(nodeItem)
	local windowGroup = groupsForItems[nodeItem];
	Debug.chat("deleted", windowGroup);
	if windowGroup then
		windowGroup.removeItem(nodeItem);
		groupsForItems[nodeItem] = nil;
	end
	-- if loadedItems[nodeItem] then
	-- 	loadedItems[nodeItem] = nil;
	-- end
end

function onFilteredValueChanged(node)
	applyFilter();
end

function onNameChanged(nodeName)
	Debug.chat("name", nodeName);
	local nodeItem = nodeName.getChild("..");
	local sGroup = getItemGroupName(nodeItem);
	setItemGroup(nodeItem, sGroup);
end

function onDisplayGroupChanged(nodeDisplayGroup)
	Debug.chat("display", nodeDisplayGroup);
	local nodeItem = nodeDisplayGroup.getChild("..");
	local sGroup = getItemGroupName(nodeItem);
	setItemGroup(nodeItem, sGroup);
end

function getLoadedGroups()
	if not window.parentcontrol.window.itemGroups then
		window.parentcontrol.window.itemGroups = {};
	end
	return window.parentcontrol.window.itemGroups;
end

function getItemGroupName(nodeItem)
	local sGroup = DB.getValue(nodeItem, "displaygroup", "");
	if sGroup == "" then
		sGroup = DB.getValue(nodeItem, "name", "");
	end
	return sGroup;
end

function setItemGroup(nodeItem, sGroup)
	local windowGroup = groupsForItems[sGroup];
	if windowGroup then
		if windowGroup.name.getValue() == sGroup then
			return; -- Already in the correct group
		else
			windowGroup.removeItem(nodeItem);
		end
	end

	windowGroup = getLoadedGroups()[sGroup];
	if windowGroup then
		windowGroup.addItem(nodeItem);
		groupsForItems[nodeItem] = windowGroup;
	else
		Debug.chat("pending", nodeItem);
		-- TODO top vs bottom
		local pendingItems = pendingItemGroups[sGroup];
		if not pendingItems then
			pendingItems = {};
			pendingItemGroups[sGroup] = pendingItems;
		end
		table.insert(pendingItems, nodeItem);
		ItemPowerManager.beginCreatingItemGroup(nodeItem.getChild("...").getPath(), sGroup);
	end
end

function initializeItemGroup(windowGroup)
	local sGroup = DB.getValue(getDatabaseNode(), "name", "");
	pendingItemGroups[sGroup] = nil;
	local pendingItems = pendingItemGroups[sGroup];

	Debug.chat(pendingItems);
	if pendingItems then
		for _,itemNode in ipairs(pendingItems) do
			windowGroup.addItem(nodeItem);
		end
	end

	getLoadedGroups()[sGroup] = windowGroup;
end