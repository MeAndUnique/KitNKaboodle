--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

CAMPAIGN_INTERRUPTION_LIST = "interruptions";
CAMPAIGN_INTERRUPTION_DEFINITION_LIST = "interruptions.definitions";
CAMPAIGN_INTERRUPTION_COUNT = "interruptions.count";
CAMPAIGN_INTERRUPTION_ID = "id";
CAMPAIGN_INTERRUPTION_NAME = "name";
CAMPAIGN_INTERRUPTION_MODE = "mode";
CAMPAIGN_INTERRUPTION_ATTACKING = "attacking";
CAMPAIGN_INTERRUPTION_SAVING = "saving";

CAMPAIGN_INTERRUPTION_ENABLED = "enabled";
CAMPAIGN_INTERRUPTION_PROMPT = "prompt";
CAMPAIGN_INTERRUPTION_PROMPT_ABOVE = "promptabove";
CAMPAIGN_INTERRUPTION_PROMPT_BELOW = "promptbelow";
CAMPAIGN_INTERRUPTION_AUTO = "auto";
CAMPAIGN_INTERRUPTION_AUTO_ABOVE = "autoabove";
CAMPAIGN_INTERRUPTION_AUTO_BELOW = "autobelow";

local interruptionsById = {}
local interruptionsByNode = {}
local onAdd = {}
local onUpdate = {}
local onRemove = {}

local typeMap = {
	["attack"] = "attacking",
	["save"] = "saving",
	["concentration"] = "saving",
	["death"] = "saving"
}

function onInit()
	-- TODO
	-- 	further group "types" (and find better name)
	-- 		maybe hijack "mode" and use "effect"
	-- 	types supported (auto/prompt for each)
	-- 		raw roll range
	-- 		total roll range
	-- 		success
	-- 		failure
	-- 	figure out handling of tower/hidden rolls/hidden results
	-- 		dont interrupt tower?
	-- 	figure out handling of others' rolls
	-- 		cutting words vs combat inspiration
	-- 	damage
	-- 		adding, rerolling, multiple dice
	-- 		esp. multiple dice when rerolling some and not others (and detecting what is allowed)
	-- 	iterative interruptions
	-- 		only once per interruptor though

	if User.isHost() then
		local interruptionsNode = DB.findNode(CAMPAIGN_INTERRUPTION_LIST);
		if not interruptionsNode then
			interruptionsNode = DB.createNode(CAMPAIGN_INTERRUPTION_LIST);
		end

		local definitionsNode = interruptionsNode.getChild("definitions");
		if not definitionsNode then
			definitionsNode = interruptionsNode.createChild("definitions");
			definitionsNode.setPublic(true);
		end

		refreshCampaignInterruptions();
		DB.addHandler(CAMPAIGN_INTERRUPTION_DEFINITION_LIST, "onChildAdded", addInterruption);
		DB.addHandler(CAMPAIGN_INTERRUPTION_DEFINITION_LIST .. ".*", "onDelete", removeInterruption);
		DB.addHandler(CAMPAIGN_INTERRUPTION_DEFINITION_LIST .. ".*", "onChildAdded", addToInterruption);
		DB.addHandler(CAMPAIGN_INTERRUPTION_DEFINITION_LIST .. ".*", "onChildDeleted", removeFromInterruption);
		DB.addHandler(CAMPAIGN_INTERRUPTION_DEFINITION_LIST .. ".*", "onChildUpdate", updateInterruption);
	end
	
	local wChat = Interface.findWindow("chat", "");
	if wChat then
		cButton = wChat.createControl("button_interruptionrolls", "interruptionrolls");
	end
end

function registerOnAdd(callback)
	table.insert(onAdd, callback);
end

function unregisterOnAdd(callback)
	for index,value in ipairs(onAdd) do
		if value == callback then
			table.remove(onAdd, index);
			return;
		end
	end
end

function registerOnUpdate(callback)
	table.insert(onUpdate, callback);
end

function unregisterOnUpdate(callback)
	for index,value in ipairs(onUpdate) do
		if value == callback then
			table.remove(onUpdate, index);
			return;
		end
	end
end

function registerOnRemove(callback)
	table.insert(onRemove, callback);
end

function unregisterOnRemove(callback)
	for index,value in ipairs(onRemove) do
		if value == callback then
			table.remove(onRemove, index);
			return;
		end
	end
end

function addInterruption(nodeParent, nodeChild)
	local count = DB.getValue(CAMPAIGN_INTERRUPTION_COUNT, 0);
	count = count + 1;
	DB.setValue(CAMPAIGN_INTERRUPTION_COUNT, "number", count);

	local idNode = nodeChild.createChild(CAMPAIGN_INTERRUPTION_ID, "number");
	idNode.setValue(count);
	idNode.setStatic(true);

	DB.setValue(nodeChild, "name", "string", nil);
	DB.setValue(nodeChild, "mode", "string", Interface.getString("interruption_mode_mod"));
	DB.setValue(nodeChild, "applies", "string", nil);

	-- formatType(nodeChild, CAMPAIGN_INTERRUPTION_ATTACKING);
	-- formatType(nodeChild, CAMPAIGN_INTERRUPTION_SAVING);

	-- refreshCampaignInterruptions();

	loadInterruption(nodeChild);
end

function removeInterruption(nodeToBeDeleted)
	local interruption = interruptionsByNode[nodeToBeDeleted];
	if interruption and interruption.nId then
		interruptionsById[interruption.nId] = nil;
	end
	interruptionsByNode[nodeToBeDeleted] = nil;
end

function addToInterruption(nodeParent, nodeChildAdded)
	loadInterruption(nodeParent);
end

function removeFromInterruption(nodeParent)
	loadInterruption(nodeParent);
end

function updateInterruption(nodeParent, nodeChildUpdated)
	if not nodeChildUpdated then
		loadInterruption(nodeParent);
	end
end

function refreshCampaignInterruptions()
	-- local children = DB.getChildren(CAMPAIGN_INTERRUPTION_LIST);
	-- Debug.chat(children);

	-- Rebuild the campaign interruption dictionary for fast lookup
	interruptionsById = {};
	interruptionsByNode = {};
	for _,v in pairs(DB.getChildren(CAMPAIGN_INTERRUPTION_DEFINITION_LIST)) do
		local interruption = loadInterruption(v);

		-- if interruption and interruption.id then
		-- 	interruptionsById[interruption.id] = interruption;
		-- 	interruptionsByNode[v] = interruption;
		-- end
		-- table.insert(interruptionsById, interruption);
	end

	-- Debug.chat(interruptionsById);

	-- for _,callback in ipairs(callbacks) do
	-- 	callback();
	-- end
end

function loadInterruption(node)
	-- local interruption = {
	-- 	nId = DB.getValue(node, CAMPAIGN_INTERRUPTION_ID),
	-- 	rSource = node,
	-- 	sName = StringManager.trim(DB.getValue(node, CAMPAIGN_INTERRUPTION_NAME)),
	-- 	sMode = DB.getValue(node, CAMPAIGN_INTERRUPTION_MODE, ""),
	-- 	-- bAttacking = DB.getValue(node, CAMPAIGN_INTERRUPTION_ATTACKING .. ".applies", "") ~= "",
	-- 	-- bSaving = DB.getValue(node, CAMPAIGN_INTERRUPTION_SAVING .. ".applies", "") ~= "",
	-- 	bAttacking = false,
	-- 	bSaving = false
	-- };

	-- populateInterruptionType(interruption, node, CAMPAIGN_INTERRUPTION_ATTACKING);
	-- populateInterruptionType(interruption, node, CAMPAIGN_INTERRUPTION_SAVING);

	local interruption = {};
	for childName,child in pairs(node.getChildren()) do
		populate(interruption, childName, child);
	end

	interruptionsById[interruption.id] = interruption;
	interruptionsByNode[node] = interruption;

	return interruption;
end

function populate(rData, name, node)
	local value;
	if node.getType() == "node" then
		value = {};
		for childName,child in pairs(node.getChildren()) do
			populate(value, childName, child);
		end
	else
		value = node.getValue();
	end
	rData[name] = value;
end

function populateInterruptionType(interruption, node, type)
	local typeNode = node.getChild(type);
	interruption[type] = {};
	interruption[type].bEnabled = DB.getValue(typeNode, CAMPAIGN_INTERRUPTION_ENABLED, 0) ~= 0;
	interruption[type].sPrompt = DB.getValue(typeNode, CAMPAIGN_INTERRUPTION_PROMPT, "never");
	interruption[type].nPromptAbove = DB.getValue(typeNode, CAMPAIGN_INTERRUPTION_PROMPT_ABOVE, 10);
	interruption[type].nPromptBelow = DB.getValue(typeNode, CAMPAIGN_INTERRUPTION_PROMPT_BELOW, 15);
	interruption[type].sAuto = DB.getValue(typeNode, CAMPAIGN_INTERRUPTION_AUTO, "never");
	interruption[type].nAutoAbove = DB.getValue(typeNode, CAMPAIGN_INTERRUPTION_AUTO_ABOVE, 10);
	interruption[type].nAutoBelow = DB.getValue(typeNode, CAMPAIGN_INTERRUPTION_AUTO_BELOW, 15);
end

function getInterruptionById(nId)
	return interruptionsById[nId];
end

function getInterruptions(sEffect, rRoll, bSuccess)
	local results = {};
	local type = typeMap[rRoll.sType];
	for _,interruption in pairs(interruptionsById) do
		if interruption[type] and (interruption.name or "") ~= "" and StringManager.startsWith(sEffect, interruption.name) then
			local instance;
			if interruption.applies == "result" then
				if bSuccess then
					if interruption[type].auto == "always" or interruption[type].auto == "success" then
						instance = buildInstance(interruption, true, false);
					elseif interruption[type].prompt == "always" or interruption[type].prompt == "success" then
						instance = buildInstance(interruption, true, true);
					end
				else
					if interruption[type].auto == "always" or interruption[type].auto == "fail" then
						instance = buildInstance(interruption, true, false);
					elseif interruption[type].prompt == "always" or interruption[type].prompt == "fail" then
						instance = buildInstance(interruption, true, true);
					end
				end
			else
				local total = ActionsManager.total(rRoll);
				if interruption[type].auto.above < total and total < interruption[type].auto.below then
					instance = buildInstance(interruption, false, false);
				elseif interruption[type].prompt.above < total and total < interruption[type].prompt.below then
					instance = buildInstance(interruption, false, true);
				end
			end

			if instance then
				table.insert(results, instance);
			end
		end
	end

	return results;
end

function buildInstance(rInterruption, bAfterResult, bPrompt)
	return {name=rInterruption.name, id=rInterruption.id, afterResult=bAfterResult, prompt=bPrompt}
end

function getAttackingInterruptions()
	local aInterruptions = {}
	for _,value in pairs(interruptionsById) do
		if value.attacking.bEnabled then
			table.insert(aInterruptions, value);
		end
	end

	return aInterruptions;
end

function getSavingInterruptions()
	local aInterruptions = {}
	for _,value in pairs(interruptionsById) do
		if value.saving.bEnabled then
			table.insert(aInterruptions, value);
		end
	end

	return aInterruptions;
end