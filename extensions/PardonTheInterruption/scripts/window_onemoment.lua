-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local source;
local target;
local roll;
local original;

local rolling = false;

-- Initialization
function onInit()
end

function onClose()
	if not rolling then
		original(source, target, roll);
	end
end

function addRoll(rSource, rTarget, rRoll, fOriginal)
	source = rSource;
	target = rTarget
	roll = rRoll;
	original = fOriginal;
end

function processRoll()
	ActionsManager2.decodeAdvantage(roll);
	local modifierRoll = {sType="moment", aDice={"b8"}, id=id};
	ActionsManager.roll(nil, nil, modifierRoll, false);
	rolling  = true;
	close();
end

function processCancel()
	close();
end

function onMoment(rSource, rTarget, rRoll)
	local momentDie = rRoll.aDice[1];
	roll.sDesc = roll.sDesc .. " [+1d8]";
	-- roll.aDice[#roll.aDice+1] = momentDie;
	table.insert(roll.aDice, momentDie);

	OneMoment.setAlreadyDecoded();
	original(source, target, roll);
	OneMoment.clearAlreadyDecoded();
end
