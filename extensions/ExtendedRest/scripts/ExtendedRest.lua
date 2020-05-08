-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local originalReset;
local bIsExtended = false;

-- Initialization
function onInit()
    originalReset = PowerManager.resetPowers;
    PowerManager.resetPowers = newPowerReset;
end

function beginExtended()
   bIsExtended = true;
end

function endExtended()
    bIsExtended = false;
end

-- Copied lookup logic from manager_power.lua
function newPowerReset(nodeCaster, bLong)
    -- Short rests aren't the bad guy and long rests normally do what we want an extended rest to.
    if bIsExtended or not bLong then
        originalReset(nodeCaster, bLong);
        return nil;
    end

	local aListGroups = {};
	
	-- Build list of power groups
	for _,vGroup in pairs(DB.getChildren(nodeCaster, "powergroup")) do
		local sGroup = DB.getValue(vGroup, "name", "");
		if not aListGroups[sGroup] then
			local rGroup = {};
			rGroup.sName = sGroup;
			rGroup.sType = DB.getValue(vGroup, "castertype", "");
			rGroup.nUses = DB.getValue(vGroup, "uses", 0);
			rGroup.sUsesPeriod = DB.getValue(vGroup, "usesperiod", "");
			rGroup.nodeGroup = vGroup;
			
			aListGroups[sGroup] = rGroup;
		end
	end
	
    -- Get original extended rest uses.
    local powerUses = {};
	for _,vPower in pairs(DB.getChildren(nodeCaster, "powers")) do
		local bReset = true;

		local sGroup = DB.getValue(vPower, "group", "");
		local rGroup = aListGroups[sGroup];
		local bCaster = (rGroup and rGroup.sType ~= "");
		
		if not bCaster then
			if rGroup and (rGroup.nUses > 0) then
				if rGroup.sUsesPeriod == "extended" then
					powerUses[vPower] = DB.getValue(vPower, "cast", "number");
				end
			else
				local sPowerUsesPeriod = DB.getValue(vPower, "usesperiod", "");
				if sPowerUsesPeriod == "once" then
					powerUses[vPower] = DB.getValue(vPower, "cast", "number");
				end
			end
		end
    end
    
    originalReset(nodeCaster, bLong)

    for power,uses in pairs(powerUses) do
        DB.setValue(power, "cast", "number", uses);
    end

end
