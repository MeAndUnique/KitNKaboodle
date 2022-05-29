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
end