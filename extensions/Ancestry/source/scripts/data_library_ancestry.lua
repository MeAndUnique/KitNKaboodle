-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local recordInfo = LibraryData.getRecordTypeInfo("race");
	if recordInfo and Interface.isIcon("button_ancestries") and Interface.isIcon("button_ancestries_down") then
		recordInfo.aDisplayIcon = { "button_ancestries", "button_ancestries_down" }
		LibraryData.setRecordTypeInfo("race", recordInfo);
	end
end