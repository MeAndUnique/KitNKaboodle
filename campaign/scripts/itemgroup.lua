-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Initialization
function onInit()
	local nodeGroup = getDatabaseNode();
	local sGroup = DB.getValue(nodeGroup, "name", "");
	for _,nodeItem in pairs(DB.getChildren(nodeGroup, "...inventorylist")) do
		if (ItemPowerManager.getItemGroupName(nodeItem) == sGroup) and ItemPowerManager.shouldShowItemPowers(nodeItem) then
			list.createWindow(nodeItem);
		end
	end
end