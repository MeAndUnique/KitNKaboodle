--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	if EffectManagerADND then
		local sSub, sDisplay = getTab(1);
		if sSub and window[sSub] and (type(window[sSub]) ~= "subwindow") then
			setTab(1, sSub .. ",advanced_effects_contents", sDisplay);
		end
	end
end