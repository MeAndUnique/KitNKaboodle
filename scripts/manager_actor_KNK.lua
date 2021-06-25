-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local vToResolve;
local resolveActorOriginal;
local getActorRecordTypeFromPathOriginal;

-- Initialization
function onInit()
	resolveActorOriginal = ActorManager.resolveActor;
	ActorManager.resolveActor = resolveActor;

	getActorRecordTypeFromPathOriginal = ActorManager.getActorRecordTypeFromPath;
	ActorManager.getActorRecordTypeFromPath = getActorRecordTypeFromPath;
end

function onClose()
	ActorManager.resolveActor = resolveActorOriginal;
end

function beginResolvingItem(v)
	vToResolve = v;
end

function endResolvingItem()
	vToResolve = nil;
end

function resolveActor(v)
	local rActor = resolveActorOriginal(v);
	if not rActor and vToResolve then
		rActor = resolveActorOriginal(vToResolve) or {sName = ""};
	end
	return rActor;
end

-- Internal use only
function getActorRecordTypeFromPath(sActorNodePath)
	local delimiterCount = select(2, string.gsub(sActorNodePath, "%.", ""));
	if(delimiterCount > 2) then
		return nil;
	else
		return getActorRecordTypeFromPathOriginal(sActorNodePath);
	end
end