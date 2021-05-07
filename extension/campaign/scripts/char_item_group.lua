-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local itemPowers = {};
local visibleItems = {};

-- Initialization
function onInit()
	Debug.chat("init group", getDatabaseNode(), DB.getValue(getDatabaseNode(), "name", ""));
	powerlist.onFilter = onFilter;
	-- windowlist.initializeItemGroup(self);
end

function onClose()
	for nodeItem,_ in pairs(itemPowers) do
		removeHandlers(nodeItem);
	end
end

function addItem(nodeItem)
	Debug.chat("adding", nodeItem);
	if itemPowers[nodeItem] then
		return;
	end

	-- local bShow = ItemPowerManager.shouldShowItemPowers(nodeItem);
	-- visibleItems[nodeItem] = bShow;
	-- local aPowers = {};
	-- itemPowers[nodeItem] = aPowers;
	-- for _,nodePower in pairs(DB.getChildren(nodeItem, "powers")) do
	-- 	local windowPower = powerlist.createWindow(nodePower);
	-- 	table.insert(aPowers, windowPower);
	-- end
	addHandlers(nodeItem);
	rebuildItemPowers(nodeItem);
	updateItem(nodeItem);
end

function removeItem(nodeItem)
	Debug.chat("removing item", name.getValue(), nodeItem);
	if itemPowers[nodeItem] then
		visibleItems[nodeItem] = nil;
		for _,powerWindow in ipairs(itemPowers[nodeItem]) do
			powerWindow.close();
		end
		removeHandlers(nodeItem);
		itemPowers[nodeItem] = nil;

		local nCount = 0;
		for _,_ in pairs(itemPowers) do
			nCount = nCount + 1;
		end
		if (nCount == 0) and (name.getValue() ~= "<< Unnamed Items >>") then
			getDatabaseNode().delete();
		else
			updateLink();
		end
	end
end

function updateItem(nodeItem)
	Debug.chat("updating item", nodeItem);
	local bShow = ItemPowerManager.shouldShowItemPowers(nodeItem);
	visibleItems[nodeItem] = bShow;
	powerlist.applyFilter();
	windowlist.applyFilter();
	updateLink();
end

function rebuildItemPowers(nodeItem)
	local knownPowers = {};
	local aPowers = itemPowers[nodeItem];
	Debug.chat("rebuilding", nodeItem, aPowers);
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
		if not windowPower then
			windowPower = powerlist.createWindow(nodePower);
		end
		table.insert(aPowers, windowPower);
	end
	itemPowers[nodeItem] = aPowers;
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

	Debug.chat("updating link", nCount);
	if nCount == 1 then
		shortcut.setValue("item", nodeVisibleItem.getPath());
		Debug.chat("shortcut", shortcut.getValue());
	else
		-- TODO
	end
end

function shouldBeShown()
	Debug.chat("checking group visibility", itemPowers)
	for nodeItem,_ in pairs(itemPowers) do
		Debug.chat("checking item visibility", nodeItem);
		if ItemPowerManager.shouldShowItemPowers(nodeItem) then
			Debug.chat("group should be shown");
			return true;
		end
	end
	Debug.chat("group should not be shown");
	return false;
end

function onFilter(instance)
	Debug.chat("filtering power", instance, visibleItems);
	return visibleItems[instance.getDatabaseNode().getChild("...")];
end

function addHandlers(nodeItem)
	DB.addHandler(nodeItem.getPath("carried"), "onUpdate", onFilteredValueChanged);
	DB.addHandler(nodeItem.getPath("isidentified"), "onUpdate", onFilteredValueChanged);
	DB.addHandler(nodeItem.getPath("powers.*.name"), "onAdd", onPowerListChanged);
	DB.addHandler(nodeItem.getPath("powers.*.name"), "onDelete", onPowerListChanged);
end

function removeHandlers(nodeItem)
	if type(nodeItem) == "databasenode" then
		DB.removeHandler(nodeItem.getPath("carried"), "onUpdate", onFilteredValueChanged);
		DB.removeHandler(nodeItem.getPath("isidentified"), "onUpdate", onFilteredValueChanged);
		DB.removeHandler(nodeItem.getPath("powers.*.name"), "onAdd", onPowerListChanged);
		DB.removeHandler(nodeItem.getPath("powers.*.name"), "onDelete", onPowerListChanged);
	end
end

function onFilteredValueChanged(node)
	local nodeItem = DB.getChild(node, "..");
	updateItem(nodeItem);
end

function onPowerListChanged(node)
	local nodeItem = DB.getChild(node, "....");
	rebuildItemPowers(nodeItem);
	updateItem(nodeItem);
end