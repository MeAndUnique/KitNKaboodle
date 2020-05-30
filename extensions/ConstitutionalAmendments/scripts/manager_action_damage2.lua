-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local applyDamageOriginal;
local decodeDamageTextOriginal;
local getDamageAdjustOriginal;
local messageDamageOriginal;

local decodeResult;

function onInit()
	applyDamageOriginal = ActionDamage.applyDamage;
	ActionDamage.applyDamage = applyDamage;

	decodeDamageTextOriginal = ActionDamage.decodeDamageText;
	ActionDamage.decodeDamageText = decodeDamageText;

	getDamageAdjustOriginal = ActionDamage.getDamageAdjust;
	ActionDamage.getDamageAdjust = getDamageAdjust;

	messageDamageOriginal = ActionDamage.messageDamage;
	ActionDamage.messageDamage = messageDamage;
end

function applyDamage(rSource, rTarget, bSecret, sDamage, nTotal)
	applyDamageOriginal(rSource, rTarget, bSecret, sDamage, nTotal);
end

function decodeDamageText(nDamage, sDamageDesc)
	decodeResult = decodeDamageTextOriginal(nDamage, sDamageDesc);
	return decodeResult;
end

function messageDamage(rSource, rTarget, bSecret, sDamageType, sDamageDesc, sTotal, sExtraResult)
	local nStolen = 0;
	local bStealTemp = false;
	if decodeResult and decodeResult.sType == "damage" then
		local sTargetType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
		for sTypes,nDamage in pairs(decodeResult.aDamageTypes) do
			local aTemp = StringManager.split(sTypes, ",", true);
			local bMax = false;
			local nSteal = 0;
			for _,type in ipairs(aTemp) do
				bMax = bMax or type == "max";
				if type == "steal" then
					nSteal = 1;
				elseif type == "hsteal" then
					nSteal = 0.5;
				end
				if type == "stealtemp" then
					nSteal = 1;
					bStealTemp = true;
				elseif type == "hstealtemp" then
					nSteal = 0.5;
					bStealTemp = true;
				end
			end

			if bMax or (nSteal > 0) then
				local rDamageOutput = {aDamageTypes={[sTypes]=nDamage}};
				local nDamageAdjust = getDamageAdjust(rSource, rTarget, nDamage, rDamageOutput);
				nDamageAdjust = nDamageAdjust + nDamage;
				nStolen = math.floor(nDamageAdjust * nSteal);

				if bMax and (nDamageAdjust > 0) then
					sExtraResult = sExtraResult .. " [MAX REDUCED]";
					if sTargetType == "pc" then
						local nWounds = DB.getValue(nodeTarget, "hp.wounds", 0);
						DB.setValue(nodeTarget, "hp.wounds", "number", math.max(0, nWounds - nDamageAdjust));

						local nAdjust = DB.getValue(nodeTarget, "hp.adjust", 0) - nDamageAdjust;
						DB.setValue(nodeTarget, "hp.adjust", "number", nAdjust);
						HpManager.recalculateTotal(nodeTarget);
						
						local nTotal = DB.getValue(nodeTarget, "hp.total", 0);
						if nTotal <= 0 then
							if not string.match(sExtraResult, "%[INSTANT DEATH%]") then
								sExtraResult = sExtraResult .. " [INSTANT DEATH]";
							end
							nAdjust = nAdjust - nTotal;
							DB.setValue(nodeTarget, "hp.total", "number", 0);
							DB.setValue(nodeTarget, "hp.adjust", "number", nAdjust);
							DB.setValue(nodeTarget, "hp.deathsavefail", "number", 3);
						end
					else
						local nTotal = DB.getValue(nodeTarget, "hptotal", 0) - nDamageAdjust;
						if nTotal < 0 then
							if not string.match(sExtraResult, "%[INSTANT DEATH%]") then
								sExtraResult = sExtraResult .. " [INSTANT DEATH]";
							end
							nTotal = 0;
						end
						DB.setValue(nodeTarget, "hptotal", "number", nTotal);

						local nWounds = DB.getValue(nodeTarget, "wounds", 0);
						DB.setValue(nodeTarget, "wounds", "number", math.max(0, nWounds - nDamageAdjust));
					end
				end
			end
		end
	elseif string.match(sDamageDesc, "%[STOLEN%]") then
		sExtraResult = sExtraResult .. " [STOLEN]";
	end
	decodeResult = nil;

	messageDamageOriginal(rSource, rTarget, bSecret, sDamageType, sDamageDesc, sTotal, sExtraResult);

	if nStolen > 0 then
		local sDamage = "[HEAL][STOLEN]";
		if bStealTemp then
			sDamage = sDamage .. "[TEMP]";
		end
		applyDamageOriginal(rSource, rSource, bSecret, sDamage, nStolen);
	end
end

function getDamageAdjust(rSource, rTarget, nTotal, rDamageOutput)
	local nDamageAdjust, bVulnerable, bResist = getDamageAdjustOriginal(rSource, rTarget, nTotal, rDamageOutput);
	return nDamageAdjust, bVulnerable, bResist;
end