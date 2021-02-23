-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local getItemSourceTypeOriginal;
local addNPCOriginal;

-- Initialization
function onInit()
	getItemSourceTypeOriginal = ItemManager.getItemSourceType;
	ItemManager.getItemSourceType = getItemSourceType;
end

function getItemSourceType(vNode)
	local sResult = getItemSourceTypeOriginal(vNode);
	if (sResult or "") == "" then
		local sNodePath = nil;
		if type(vNode) == "databasenode" then
			sNodePath = vNode.getPath();
		elseif type(vNode) == "string" then
			sNodePath = vNode;
		end

		if sNodePath then
			if StringManager.startsWith(sNodePath, "combattracker") then
				return "charsheet";
			end
			for _,vMapping in ipairs(LibraryData.getMappings("npc")) do
				if StringManager.startsWith(sNodePath, vMapping) then
					return "charsheet";
				end
			end
		end
	end
	return sResult;
end

function shouldShowItemPowers(itemNode)
	return DB.getValue(itemNode, "carried", 0) == 2 and
		DB.getValue(itemNode, "isidentified", 1) == 1 and
		DB.getChildCount(itemNode, "powers") ~= 0;
end