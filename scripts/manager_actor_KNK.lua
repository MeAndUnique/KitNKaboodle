-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local getActorRecordTypeFromPathOriginal;

-- Initialization
function onInit()
	getActorRecordTypeFromPathOriginal = ActorManager.getActorRecordTypeFromPath;
	ActorManager.getActorRecordTypeFromPath = getActorRecordTypeFromPath;
end

-- Internal use only
function getActorRecordTypeFromPath(sActorNodePath)
	if sActorNodePath:match("%.inventorylist%.") then
		return nil;
	else
		return getActorRecordTypeFromPathOriginal(sActorNodePath);
	end
end