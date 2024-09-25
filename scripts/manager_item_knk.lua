--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ItemManager.setInventoryPaths("charsheet",
	{
		"inventorylist",
		"cohorts.*.inventorylist",
	});
	ItemManager.setInventoryPaths("combattracker.list",
	{
		"inventorylist",
		"cohorts.*.inventorylist",
	});
	ItemManager.setInventoryPaths("npc",
	{
		"inventorylist",
		"cohorts.*.inventorylist",
	});
	ItemManager.setInventoryPaths("reference.npcdata",
	{
		"inventorylist",
		"cohorts.*.inventorylist",
	});
	local tData = {
		tCurrencyPaths = ItemManager.getDefaultCurrencyPaths()
				  };
	ItemManager.setActorTypeInfo("npc", tData);
end

function nodeBelongsToItem(nodePower)
	if not nodePower then
		return false;
	end

	local sPath = nodePower.getPath();
	return (LibraryData.getRecordTypeFromRecordPath(sPath) == "item") or (sPath:match("inventorylist") ~= nil);
end