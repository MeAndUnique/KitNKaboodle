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

	addNPCOriginal = CombatManager2.addNPC;
	CombatManager2.addNPC = addNPC;
	CombatManager.setCustomAddNPC(addNPC);
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
			for _,vMapping in ipairs(LibraryData.getMappings("npc")) do
				if StringManager.startsWith(sNodePath, vMapping) then
					sResult = "charsheet";
				end
			end
		end
	end
	return sResult;
end

function addNPC(sClass, nodeNPC, sName)
	local nodeEntry = addNPCOriginal(sClass, nodeNPC, sName);
end