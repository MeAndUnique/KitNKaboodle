--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local bReadOnly = true;
local bHideCast = true;

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	local nodePower = window.getDatabaseNode();
	DB.addHandler(nodePower.getPath("actions"), "onChildDeleted", onActionDeleted);

	local nodeChar = PowerManagerCore.getPowerActorNode(nodePower);
	DB.addHandler(DB.getPath(nodeChar, "level"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(nodeChar, "powergroup.*.stat"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(nodeChar, "powergroup.*.atkstat"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(nodeChar, "powergroup.*.atkprof"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(nodeChar, "powergroup.*.atkmod"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(nodeChar, "powergroup.*.savestat"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(nodeChar, "powergroup.*.saveprof"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(nodeChar, "powergroup.*.savemod"), "onUpdate", onAbilityChanged);
	DB.addHandler(DB.getPath(nodeChar, "powergroup"), "onChildAdded", onAbilityChanged);
	DB.addHandler(DB.getPath(nodeChar, "powergroup"), "onChildDeleted", onAbilityChanged);
	DB.addHandler(DB.getPath(nodeChar, "powergroup.*.name"), "onUpdate", onAbilityChanged);

	PowerManagerKNK.fillActionOrderGap(window.getDatabaseNode());
end

function onClose()
	local nodePower = window.getDatabaseNode();
	DB.removeHandler(nodePower.getPath("actions"), "onChildDeleted", onActionDeleted);
	
	local nodeChar = PowerManagerCore.getPowerActorNode(nodePower);
	DB.removeHandler(DB.getPath(nodeChar, "level"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(nodeChar, "powergroup.*.stat"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(nodeChar, "powergroup.*.atkstat"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(nodeChar, "powergroup.*.atkprof"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(nodeChar, "powergroup.*.atkmod"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(nodeChar, "powergroup.*.savestat"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(nodeChar, "powergroup.*.saveprof"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(nodeChar, "powergroup.*.savemod"), "onUpdate", onAbilityChanged);
	DB.removeHandler(DB.getPath(nodeChar, "powergroup"), "onChildAdded", onAbilityChanged);
	DB.removeHandler(DB.getPath(nodeChar, "powergroup"), "onChildDeleted", onAbilityChanged);
	DB.removeHandler(DB.getPath(nodeChar, "powergroup.*.name"), "onUpdate", onAbilityChanged);

	if super and super.onClose then
		super.onClose();
	end
end

function onActionDeleted()
	PowerManagerKNK.fillActionOrderGap(window.getDatabaseNode());
end

function update(bNewReadOnly, bNewHideCast)
	bReadOnly = bNewReadOnly;
	bHideCast = bNewHideCast;
	-- TODO check for drag reording on readonly
	for _,win in ipairs(getWindows()) do
		win.update(bReadOnly, bHideCast);
	end
end

function onAbilityChanged()
	WindowManager.callInnerFunction(self, "onDataChanged");
end