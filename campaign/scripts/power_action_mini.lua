--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local updateViewsOriginal;
local onResourceChangedOriginal;

local bIsItem;

function onInit()
	bIsItem = getDatabaseNode().getPath():match("inventorylist");

	updateViewsOriginal = super.updateViews;
	super.updateViews = updateViews;

	onResourceChangedOriginal = super.onResourceChanged;
	super.onResourceChanged = onResourceChanged;

	if bIsItem then
		ActorManagerKNK.beginResolvingItem(getDatabaseNode().getChild(".......") or true);
	end

	super.onInit();

	if bIsItem then
		ActorManagerKNK.endResolvingItem();
	end
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

function onResourceChanged()
	if bIsItem then
		ActorManagerKNK.beginResolvingItem(getDatabaseNode().getChild(".......") or true);
	end

	onResourceChangedOriginal();

	if bIsItem then
		ActorManagerKNK.endResolvingItem();
	end
end