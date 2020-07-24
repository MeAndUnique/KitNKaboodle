-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local onCharItemAddOriginal;
local onCharItemDeleteOriginal;

-- Initialization
function onInit()
	onCharItemAddOriginal = CharManager.onCharItemAdd;
	ItemManager.setCustomCharAdd(onCharItemAdd);
	onCharItemDeleteOriginal = CharManager.onCharItemDelete;
	ItemManager.setCustomCharRemove(onCharItemDelete);
end

function onCharItemAdd(nodeItem)
	onCharItemAddOriginal(nodeItem);
	if true then return end

	-- Get the power list we are going to add to
	local nodeChar = nodeItem.getChild("...");
	local nodePowers = nodeChar.createChild("powers");
	if not nodePowers then
		return;
	end

	if DB.getChildCount(nodeItem, "powers") == 0 then
		return;
	end
	
	-- Set new items as equipped
	DB.setValue(nodeItem, "carried", "number", 2);

	-- Determine identification
	local nItemID = 0;
	if not LibraryData.getIDState("item", nodeItem, true) then
		return
	end

	local sItemId = nodeItem.getName();
	local sItemName = DB.getValue(nodeItem, "name");
	for _,nodePower in pairs(DB.getChildren(nodeItem, "powers")) do
		local nodeDestination = DB.createChild(nodePowers);
		DB.copyNode(nodePower, nodeDestination);
		DB.setValue(nodeDestination, "itemsource", "string", sItemId);
		DB.setValue(nodeDestination, "group", "string", sItemName);

		DB.setStatic(nodeDestination, true);
		DB.setStatic(DB.getPath(nodeDestination, "name"), true);
		DB.setStatic(DB.getPath(nodeDestination, "group"), true);
	end
end

function onCharItemDelete(nodeItem)
	onCharItemDeleteOriginal(nodeItem);

	local sItemId = nodeItem.getName();
	local nodeChar = nodeItem.getChild("...");
	for _,nodePower in pairs(DB.getChildren(nodeChar, "powers")) do
		if DB.getValue(nodePower, "itemsource") == sItemId then
			DB.deleteNode(nodePower);
		end
	end
end