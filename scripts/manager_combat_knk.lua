-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local resetHealthOriginal;

function onInit()
	resetHealthOriginal = CombatManager2.resetHealth;
	CombatManager2.resetHealth = resetHealth;
end

function resetHealth(nodeCT, bLong)
	resetHealthOriginal(nodeCT, bLong);
	ItemPowerManager.beginRecharging(nodeCT, bLong);
end