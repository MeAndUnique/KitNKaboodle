-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local itemPowers = {};
local visiblePowers = {};

-- Initialization
function onInit()
	Debug.chat("init group", getDatabaseNode(), DB.getValue(getDatabaseNode(), "name", ""));
	powerlist.onFilter = onFilter;
	windowlist.initializeItemGroup(self);
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

	local bShow = ItemPowerManager.shouldShowItemPowers(nodeItem);
	local aPowers = {};
	itemPowers[nodeItem] = aPowers;
	for _,nodePower in pairs(DB.getChildren(nodeItem, "powers")) do
		local windowPower = powerlist.createWindow(nodePower);
		table.insert(aPowers, windowPower);
		visiblePowers[nodePower] = bShow;
		addHandler(nodeItem);
	end
end

function removeItem(nodeItem)
	if itemPowers[nodeItem] then
		for _,powerWindow in ipairs(itemPowers[nodeItem]) do
			powerWindow.close();
			visiblePowers[powerWindow.getDatabaseNode()] = nil;
		end
		removeHandlers(nodeItem);
		itemPowers[nodeItem] = nil;

		if #itemPowers == 0 then
			getDatabaseNode().delete();
		end
	end
end

function updateItem(nodeItem)
	local bShow = ItemPowerManager.shouldShowItemPowers(nodeItem);
	for _,nodePower in pairs(DB.getChildren(nodeItem, "powers")) do
		visiblePowers[nodePower] = bShow;
	end
	powerlist.applyFilter();
end


function shouldBeShown()
	for nodeItem,_ in pairs(itemPowers) do
		if ItemPowerManager.shouldShowItemPowers(nodeItem) then
			return true;
		end
	end
	return false;
end

function onFilter(instance)
	return visiblePowers[instance.getDatabaseNode()];
end

function addHandlers(nodeItem)
	DB.addHandler(nodeItem.getPath("carried"), "onUpdate", onFilteredValueChanged);
	DB.addHandler(nodeItem.getPath("isIdentified"), "onUpdate", onFilteredValueChanged);
	DB.addHandler(nodeItem.getPath("powers.*.name"), "onAdd", onPowerListChanged);
	DB.addHandler(nodeItem.getPath("powers.*.name"), "onDelete", onPowerListChanged);
end

function removeHandlers(nodeItem)
	DB.removeHandler(nodeItem.getPath("carried"), "onUpdate", onFilteredValueChanged);
	DB.removeHandler(nodeItem.getPath("isIdentified"), "onUpdate", onFilteredValueChanged);
	DB.removeHandler(nodeItem.getPath("powers.*.name"), "onAdd", onPowerListChanged);
	DB.removeHandler(nodeItem.getPath("powers.*.name"), "onDelete", onPowerListChanged);
end

function onFilteredValueChanged(node)
	local nodeItem = DB.findNode(DB.getPath(node, ".."));
	updateItem(nodeItem);
end

function onPowerListChanged(node)
	local nodeItem = DB.findNode(DB.getPath(node, "...."));
	Debug.chat(node, nodeItem);
	updateItem(nodeItem);
end