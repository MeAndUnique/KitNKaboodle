-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local itemPowers = {};
local visibleItems = {};
local bClosing = false;

-- Initialization
function onInit()
	powerlist.onFilter = onFilter;

	local nodeChar = DB.getChild(getDatabaseNode(), "...");
	DB.addHandler(nodeChar.getPath("inventorylist.*.attune"), "onUpdate", onFilteredValueChanged);
	DB.addHandler(nodeChar.getPath("inventorylist.*.carried"), "onUpdate", onFilteredValueChanged);
	DB.addHandler(nodeChar.getPath("inventorylist.*.count"), "onUpdate", onFilteredValueChanged);
	DB.addHandler(nodeChar.getPath("inventorylist.*.isidentified"), "onUpdate", onFilteredValueChanged);
	DB.addHandler(nodeChar.getPath("inventorylist.*.powers.*.name"), "onAdd", onPowerListChanged);
	DB.addHandler(nodeChar.getPath("inventorylist.*.powers.*.name"), "onDelete", onPowerListChanged);
end

function onClose()
	local nodeChar = DB.getChild(getDatabaseNode(), "...");
	DB.removeHandler(nodeChar.getPath("inventorylist.*.attune"), "onUpdate", onFilteredValueChanged);
	DB.removeHandler(nodeChar.getPath("inventorylist.*.carried"), "onUpdate", onFilteredValueChanged);
	DB.removeHandler(nodeChar.getPath("inventorylist.*.count"), "onUpdate", onFilteredValueChanged);
	DB.removeHandler(nodeChar.getPath("inventorylist.*.isidentified"), "onUpdate", onFilteredValueChanged);
	DB.removeHandler(nodeChar.getPath("inventorylist.*.powers.*.name"), "onAdd", onPowerListChanged);
	DB.removeHandler(nodeChar.getPath("inventorylist.*.powers.*.name"), "onDelete", onPowerListChanged);
end

function setListId(nListId)
	if nListId == 1 then
		registerMenuItem(Interface.getString("item_group_send_to_bottom"), "send", 5);
	else
		registerMenuItem(Interface.getString("item_group_send_to_top"), "send", 5);
	end
end

function onMenuSelection(selection)
	if selection == 5 then
		local nodeGroup = getDatabaseNode();
		DB.setValue(nodeGroup, "listid", "number", 1 - DB.getValue(nodeGroup, "listid", 0));
	end
end

function addItem(nodeItem)
	if itemPowers[nodeItem] then
		return;
	end

	rebuildItemPowers(nodeItem);
	updateItem(nodeItem);
end

function removeItem(nodeItem)
	if itemPowers[nodeItem] then
		visibleItems[nodeItem] = nil;
		for _,powerWindow in ipairs(itemPowers[nodeItem]) do
			powerWindow.close();
		end
		itemPowers[nodeItem] = nil;

		local nCount = 0;
		for _,_ in pairs(itemPowers) do
			nCount = nCount + 1;
		end
		if (nCount == 0) and (name.getValue() ~= "<< Unnamed Items >>") then
			getDatabaseNode().delete();
			bClosing  = true;
		else
			updateLink();
		end
	end
end

function updateItem(nodeItem)
	if type(nodeItem) == "databasenode" then
		local bShow = ItemPowerManager.shouldShowItemPowers(nodeItem);
		visibleItems[nodeItem] = bShow;
		powerlist.applyFilter();
		windowlist.applyFilter();
		updateLink();
	end
end

function rebuildItemPowers(nodeItem)
	local knownPowers = {};
	local aPowers = itemPowers[nodeItem];
	if aPowers then
		for _,windowPower in ipairs(aPowers) do
			if type(windowPower) == "windowinstance" then
				knownPowers[windowPower.getDatabaseNode()] = windowPower;
			end
		end
	end

	aPowers = {}
	for _,nodePower in pairs(DB.getChildren(nodeItem, "powers")) do
		local windowPower = knownPowers[nodePower];
		if windowPower then
			knownPowers[nodePower] = nil;
		else
			windowPower = powerlist.createWindow(nodePower);
		end
		table.insert(aPowers, windowPower);
	end
	itemPowers[nodeItem] = aPowers;

	for _,windowPower in pairs(knownPowers) do
		windowPower.close();
	end
end

function updateLink()
	local nCount = 0;
	local nodeVisibleItem;
	for nodeItem,bShown in pairs(visibleItems) do
		if bShown then
			nodeVisibleItem = nodeItem;
			nCount = nCount + 1;
		end
	end

	if nCount == 1 then
		shortcut.setValue("item", nodeVisibleItem.getPath());
	else
		shortcut.setValue("itemgroup", getDatabaseNode());
	end
end

function shouldBeShown(nListId)
	if DB.getValue(getDatabaseNode(), "listid", 0) ~= nListId then
		return false;
	end

	for nodeItem,_ in pairs(itemPowers) do
		if (type(nodeItem) == "databasenode") and ItemPowerManager.shouldShowItemPowers(nodeItem) then
			return true;
		end
	end

	return false;
end

function onFilter(instance)
	return visibleItems[instance.getDatabaseNode().getChild("...")];
end

function onFilteredValueChanged(node)
	if type(self) ~= "windowinstance" then
		-- Occasionally this function can get called in a scenario where the FG context isn't populated.
		-- In such a situation pretty much nothing will work as expected anyway, so best to return and try again later.
		return;
	end

	if bClosing then
		return;
	end

	local nodeItem = DB.getChild(node, "..");
	if name.getValue() == ItemPowerManager.getItemGroupName(nodeItem) then
		updateItem(nodeItem);
	end
end

function onPowerListChanged(node)
	local nodeItem = DB.getChild(node, "....");
	if name.getValue() == ItemPowerManager.getItemGroupName(nodeItem) then
		rebuildItemPowers(nodeItem);
		updateItem(nodeItem);
	end
end