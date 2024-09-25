-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local _tDefaultCurrencyPaths = { "coins" };

function onInit()
	if isRecord then
		onCurrencyUpdate();
		OptionsManager.registerCallback("CURR", onCurrencyUpdate);
		CurrencyManager.registerCallback(onCurrencyUpdate);
	end
end

function onClose()
	if isRecord then
		OptionsManager.unregisterCallback("CURR", onCurrencyUpdate);
		CurrencyManager.unregisterCallback(onCurrencyUpdate);
	end
end

function isRecord()
	local sPath = getDatabaseNode.getPath();
	return StringManager.startsWith("npc") or StringManager.startsWith("reference");
end

function onCurrencyUpdate()
	CharEncumbranceManager.updateEncumbrance(getDatabaseNode());
end