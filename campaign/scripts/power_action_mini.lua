-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local updateViewsOriginal;

function onInit()
	if getDatabaseNode().getPath():match("inventorylist") then
		updateViewsOriginal = super.updateViews;
		super.updateViews = updateViews;
	end

	super.onInit();
end

function updateViews()
	ActorManagerKNK.beginResolvingItem(getDatabaseNode().getChild(".......") or true);
	updateViewsOriginal();
	ActorManagerKNK.endResolvingItem();
end