-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sSource;
local bUpdating;
local previousValue;

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	previousValue = getValue();
	if source and type(source[1]) == "string" then
		setSource(window.getDatabaseNode().getPath(source[1]));
	elseif not nosource then
		setSource(window.getDatabaseNode().getPath(getName()));
	end
end

function onClosed()
	if sSource then
		DB.removeHandler(sSource, "onUpdate", onSourceUpdate);
	end
end

function setSource(sNewSource)
	if sSource then
		DB.removeHandler(sSource, "onUpdate", onSourceUpdate);
	end

	if sNewSource then
		local node = DB.createNode(sNewSource, fieldtype[1]);
		if node then
			sSource = sNewSource;
			DB.addHandler(sSource, "onUpdate", onSourceUpdate);
			previousValue = node.getValue();
		end
	end
end

function onSourceUpdate()
	if bUpdating then
		return;
	end

	bUpdating = true;
	local newValue = DB.getValue(sSource);
	setValue(newValue);
	if self.onUpdated then
		self.onUpdated(false, previousValue, newValue);
	end
	previousValue = newValue;
	bUpdating = false;
end

function onValueChanged()
	if bUpdating then
		return;
	end

	bUpdating = true;
	local newValue = getValue();
	if sSource then
		DB.setValue(sSource, fieldtype[1], newValue);
	end
	if self.onUpdated then
		self.onUpdated(true, previousValue, newValue);
	end
	previousValue = newValue;
	bUpdating = false;
end