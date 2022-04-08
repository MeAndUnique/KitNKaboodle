-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local enableCharCurrencyHandlersOriginal;
local disableCharCurrencyHandlersOriginal;
local updateAllCharactersOriginal

function onInit()
	enableCharCurrencyHandlersOriginal = CharEncumbranceManager.enableCharCurrencyHandlers;
	CharEncumbranceManager.enableCharCurrencyHandlers = enableCharCurrencyHandlers;

	disableCharCurrencyHandlersOriginal = CharEncumbranceManager.disableCharCurrencyHandlers;
	CharEncumbranceManager.disableCharCurrencyHandlers = disableCharCurrencyHandlers;

	updateAllCharactersOriginal = CharEncumbranceManager.updateAllCharacters;
	CharEncumbranceManager.updateAllCharacters = updateAllCharacters;
end

function enableCharCurrencyHandlers()
	enableCharCurrencyHandlersOriginal();
	enableCurrencyHandlers("combattracker.list");
	enableCurrencyHandlers("npc");
	enableCurrencyHandlers("reference.npcdata");
end

function disableCharCurrencyHandlers()
	disableCharCurrencyHandlersOriginal();
	disableCurrencyHandlers("combattracker.list");
	disableCurrencyHandlers("npc");
	disableCurrencyHandlers("reference.npcdata");
end

function enableCurrencyHandlers(sRoot)
	local tItemLists = ItemManager.getInventoryPaths(sRoot);
	local tItemFields = ItemManager.getEncumbranceFields(sRoot);
	for _,sList in ipairs(tItemLists) do
		local sListPath = sRoot .. ".*." .. sList;
		for _,sField in ipairs(tItemFields) do
			DB.addHandler(sListPath .. ".*." .. sField, "onUpdate", CharEncumbranceManager.onCharItemFieldUpdate);
		end
		DB.addHandler(sListPath, "onChildDeleted", CharEncumbranceManager.onCharItemDelete);
	end

	local tCurrencyPaths = CurrencyManager.getCurrencyPaths(sRoot);
	local tCurrencyFields = CurrencyManager.getEncumbranceFields(sRoot);
	for _,sList in ipairs(tCurrencyPaths) do
		local sListPath = sRoot .. ".*." .. sList;
		for _,sField in ipairs(tCurrencyFields) do
			DB.addHandler(sListPath .. ".*." .. sField, "onUpdate", CharEncumbranceManager.onCharItemFieldUpdate);
		end
		DB.addHandler(sListPath, "onChildDeleted", CharEncumbranceManager.onCharItemDelete);
	end
end

function disableCurrencyHandlers(sRoot)
	local tItemLists = ItemManager.getInventoryPaths(sRoot);
	local tItemFields = ItemManager.getEncumbranceFields(sRoot);
	for _,sList in ipairs(tItemLists) do
		local sListPath = sRoot .. ".*." .. sList;
		for _,sField in ipairs(tItemFields) do
			DB.removeHandler(sListPath .. ".*." .. sField, "onUpdate", CharEncumbranceManager.onCharItemFieldUpdate);
		end
		DB.removeHandler(sListPath, "onChildDeleted", CharEncumbranceManager.onCharItemDelete);
	end

	local tCurrencyPaths = CurrencyManager.getCurrencyPaths(sRoot);
	local tCurrencyFields = CurrencyManager.getEncumbranceFields(sRoot);
	for _,sList in ipairs(tCurrencyPaths) do
		local sListPath = sRoot .. ".*." .. sList;
		for _,sField in ipairs(tCurrencyFields) do
			DB.removeHandler(sListPath .. ".*." .. sField, "onUpdate", CharEncumbranceManager.onCharItemFieldUpdate);
		end
		DB.removeHandler(sListPath, "onChildDeleted", CharEncumbranceManager.onCharItemDelete);
	end
end

function updateAllCharacters()
	updateAllCharactersOriginal();
	for _,nodeCombatant in pairs(CombatManager.getCombatantNodes()) do
		CharEncumbranceManager.updateEncumbrance(nodeCombatant);
	end
end