-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local updateViewsOriginal;

local bIsItem;

function onInit()
	bIsItem = getDatabaseNode().getPath():match("inventorylist");

	updateViewsOriginal = super.updateViews;
	super.updateViews = updateViews;

	super.onInit();
end

function updateViews()
	if bIsItem then
		ActorManagerKNK.beginResolvingItem(getDatabaseNode().getChild(".......") or true);
	end

	updateViewsOriginal();

	if bIsItem then
		ActorManagerKNK.endResolvingItem();
	end
end