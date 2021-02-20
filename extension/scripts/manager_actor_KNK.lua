-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local vToResolve;
local resolveActorOriginal;

-- Initialization
function onInit()
	resolveActorOriginal = ActorManager.resolveActor;
	ActorManager.resolveActor = resolveActor;
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
	if not rActor then
		rActor = resolveActorOriginal(vToResolve) or {};
	end
	return rActor;
end