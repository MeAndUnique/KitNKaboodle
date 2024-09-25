--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	contentframe.setAnchor("right", "", "right", "absolute", -30);
	if text then
		text.setAnchor("right", "contentframe", "right", "absolute", 0);
	end
end