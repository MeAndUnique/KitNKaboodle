-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ItemManager.setInventoryPaths("charsheet",
	{
		"inventorylist",
		"cohorts.*.inventorylist",
		"...ct.list.*.inventorylist",
		"...npc.*.inventorylist",
		"...reference.npcdata.*.inventorylist",
	});
end