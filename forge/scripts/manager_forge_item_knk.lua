-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local FORGE_PATH_BASE_ITEMS = "forge.magicitem.baseitems";
local FORGE_PATH_TEMPLATES = "forge.magicitem.templates";

local forgeMagicItemOriginal;
local createMagicItemOriginal;
local addMagicItemToCampaignOriginal;

local winForgeActive;
local nodeJustAdded;
local items = {};
local nItemIndex = 0;
local templates = {};

function onInit()
	forgeMagicItemOriginal = ForgeManagerItem.forgeMagicItem;
	ForgeManagerItem.forgeMagicItem = forgeMagicItem;

	-- createMagicItemOriginal = ForgeManagerItem.createMagicItem;
	-- ForgeManagerItem.createMagicItem = createMagicItem;

	addMagicItemToCampaignOriginal = ForgeManagerItem.addMagicItemToCampaign;
	ForgeManagerItem.addMagicItemToCampaign = addMagicItemToCampaign;

	DB.addHandler("item.*", "onAdd", onAdded)
	DB.addHandler("itemtemplate.*", "onAdd", onAdded)
end

function onClose()
	DB.removeHandler("item.*", "onAdd", onAdded)
	DB.removeHandler("itemtemplate.*", "onAdd", onAdded)
end

function onAdded(nodeAdded)
	if winForgeActive then
		nodeJustAdded = nodeAdded;
	end
end

function forgeMagicItem(winForge)
	winForgeActive = winForge;

	-- Cache item and template nodes
	items = {};
	for _,v in pairs(DB.getChildren(FORGE_PATH_BASE_ITEMS)) do
		table.insert(items, v);
	end
	nItemIndex = 1;

	templates = {};
	for _,v in pairs(DB.getChildren(FORGE_PATH_TEMPLATES)) do
		table.insert(templates, v);
	end

	forgeMagicItemOriginal(winForge);

	winForgeActive = nil;
	nodeJustAdded = nil;
	local items = {};
	local nItemIndex = 0;
	local templates = {};
end

function addMagicItemToCampaign(rMagicItem)
	addMagicItemToCampaignOriginal(rMagicItem)

	if nodeJustAdded then
		rMagicItem.nodeDestination = nodeJustAdded;
		rMagicItem.nodePowers = DB.createChild(nodeJustAdded, "powers");
		rMagicItem.needsChargeData = true;

		if #items ~= 0 then
			local nodeItem = items[nItemIndex];
			nItemIndex = nItemIndex + 1;
			addActionData(nodeItem, rMagicItem);
		end
		for _,nodeTemplate in ipairs(templates) do
			addActionData(nodeTemplate, rMagicItem);
		end

		nodeJustAdded = nil;
	end
end

function addActionData(nodeSource, rMagicItem)
	for _,nodePower in pairs(DB.getChildren(nodeSource, "powers")) do
		local nodeNewPower = DB.createChild(rMagicItem.nodePowers);
		DB.copyNode(nodePower, nodeNewPower);
	end

	if rMagicItem.needsChargeData then
		local nCharges = DB.getValue(nodeSource, "prepared", 0)
		if nCharges > 0 then
			DB.setValue(rMagicItem.nodeDestination, "prepared", "number", nCharges);
			DB.setValue(rMagicItem.nodeDestination, "rechargeperiod", "string", DB.getValue(nodeSource, "rechargeperiod", ""));
			DB.setValue(rMagicItem.nodeDestination, "rechargetime", "string", DB.getValue(nodeSource, "rechargetime", ""));
			DB.setValue(rMagicItem.nodeDestination, "rechargedice", "dice", DB.getValue(nodeSource, "rechargedice", {}));
			DB.setValue(rMagicItem.nodeDestination, "rechargebonus", "number", DB.getValue(nodeSource, "rechargebonus", 0));

			DB.setValue(rMagicItem.nodeDestination, "dischargeaction", "string", DB.getValue(nodeSource, "dischargeaction", ""));
			DB.setValue(rMagicItem.nodeDestination, "dischargedice", "dice", DB.getValue(nodeSource, "dischargedice", {}));
			DB.setValue(rMagicItem.nodeDestination, "destroyon", "number", DB.getValue(nodeSource, "destroyon", 0));
			DB.setValue(rMagicItem.nodeDestination, "rechargeon", "number", DB.getValue(nodeSource, "rechargeon", 0));
			DB.setValue(rMagicItem.nodeDestination, "dischargerechargedice", "dice", DB.getValue(nodeSource, "dischargerechargedice", {}));
			DB.setValue(rMagicItem.nodeDestination, "dischargerechargebonus", "number", DB.getValue(nodeSource, "dischargerechargebonus", 0));

			rMagicItem.needsChargeData = false;
		end
	end
end