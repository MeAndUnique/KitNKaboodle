-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local source;
local target;
local roll;
local original;
local interruption;

local rolling = false;

function onClose()
	if not rolling then
		original(source, target, roll);
	end
end

function setData(rSource, rTarget, rRoll, fOriginal, rInterruption)
	source = rSource;
	target = rTarget
	roll = rRoll;
	original = fOriginal;
	interruption = rInterruption;

	total.setValue(ActionsManager.total(rRoll));

	rolltype.setValue(StringManager.capitalize(rRoll.sType));
	
	local sDice = StringManager.convertDiceToString(rRoll.aDice, rRoll.nMod);
	rollexpr.setValue(sDice);
	
	if (rRoll.sDesc or "") ~= "" then
		desc.setValue(rRoll.sDesc);
	else
		desc_label.setVisible(false);
		desc.setVisible(false);
	end
	
	for kDie,vDie in ipairs(rRoll.aDice) do
		local w = list.createWindow();
		w.sort.setValue(kDie);
		if type(vDie) == "table" then
			w.label.setValue(vDie.type);
		else
			w.label.setValue(vDie);
		end
		if kDie == 1 then
			w.value.setFocus();
		end
	end
	list.applySort();
end

function processRoll()
	OneMoment.rollMoment(source, target, roll, original, interruption);
	rolling = true;
	close();
end

function processCancel()
	close();
end
