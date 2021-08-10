-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeItem = getDatabaseNode();
	onChargesChanged(nodeItem.getChild("prepared")); -- Calls results in the whole chain being called, no need to call individually.
	DB.addHandler(nodeItem.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.addHandler(nodeItem.getPath("rechargeperiod"), "onUpdate", onRechargePeriodChanged);
	DB.addHandler(nodeItem.getPath("dischargeaction"), "onUpdate", onDischargeActionChanged);
	DB.addHandler(nodeItem.getPath("rechargeon"), "onUpdate", onRechargeOnChanged);
end

function onClose()
	local nodeItem = getDatabaseNode();
	DB.removeHandler(nodeItem.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodeItem.getPath("rechargeperiod"), "onUpdate", onRechargePeriodChanged);
	DB.removeHandler(nodeItem.getPath("dischargeaction"), "onUpdate", onDischargeActionChanged);
	DB.removeHandler(nodeItem.getPath("rechargeon"), "onUpdate", onRechargeOnChanged);
end

function update(bLocked)
	prepared.setReadOnly(bLocked);
	rechargeperiod.setReadOnly(bLocked);
	rechargetime.setReadOnly(bLocked);
	rechargedice.setReadOnly(bLocked);
	rechargebonus.setReadOnly(bLocked);
	dischargeaction.setReadOnly(bLocked);

	if bLocked then
		prepared.setFrame(nil);
		rechargedice.setFrame(nil);
		rechargebonus.setFrame(nil);
		dischargeaction.setFrame(nil);
		dischargedice.setFrame(nil);
		destroyon.setFrame(nil);
		rechargeon.setFrame(nil);
		dischargerechargedice.setFrame(nil);
		dischargerechargebonus.setFrame(nil);
	else
		prepared.setFrame("fielddark", 7, 5, 7, 5);
		rechargedice.onValueChanged(); -- basicdice sets the frame when the value changes.
		rechargebonus.setFrame("fielddark", 7, 5, 7, 5);
		dischargeaction.setFrame("fielddark", 7, 5, 7, 5);
		dischargedice.onValueChanged(); -- basicdice sets the frame when the value changes.
		destroyon.setFrame("fielddark", 7, 5, 7, 5);
		rechargeon.setFrame("fielddark", 7, 5, 7, 5);
		dischargerechargedice.onValueChanged(); -- basicdice sets the frame when the value changes.
		dischargerechargebonus.setFrame("fielddark", 7, 5, 7, 5);
	end
end

function onChargesChanged(nodeCharges)
	local hasCharges = DB.getValue(nodeCharges, "", 0) > 0;
	rechargeperiod.setVisible(hasCharges);
	onRechargePeriodChanged(DB.getChild(nodeCharges, "..rechargeperiod"), hasCharges);
end

function onRechargePeriodChanged(nodeRechargePeriod, hasCharges)
	if hasCharges == nil then
		hasCharges = DB.getValue(nodeRechargePeriod, "..prepared", 0) > 0;
	end

	local sRechargePeriod = DB.getValue(nodeRechargePeriod, "", "");
	rechargetime.setVisible((sRechargePeriod == "daily") and hasCharges);

	local canRecharge = hasCharges and (sRechargePeriod ~= "");
	rechargeLabel.setVisible(canRecharge);
	rechargedice.setVisible(canRecharge);
	label_plus.setVisible(canRecharge);
	rechargebonus.setVisible(canRecharge);

	dischargelabel.setVisible(hasCharges);
	dischargeaction.setVisible(hasCharges);

	onDischargeActionChanged(DB.getChild(nodeRechargePeriod, "..dischargeaction"), hasCharges);
end

function onDischargeActionChanged(nodeDischargeAction, hasCharges)
	if hasCharges == nil then
		hasCharges = DB.getValue(nodeDischargeAction, "..prepared", 0) > 0;
	end

	local bRollOnDischarge = hasCharges and (DB.getValue(nodeDischargeAction, "", "") == "roll");
	dischargedice.setVisible(bRollOnDischarge);
	destroyonlabel.setVisible(bRollOnDischarge);
	destroyon.setVisible(bRollOnDischarge);
	rechargeonlabel.setVisible(bRollOnDischarge);
	rechargeon.setVisible(bRollOnDischarge);

	onRechargeOnChanged(DB.getChild(nodeDischargeAction, "..rechargeon"), bRollOnDischarge);
end

function onRechargeOnChanged(nodeRechargeOn, bRollOnDischarge)
	if bRollOnDischarge == nil then
		bRollOnDischarge = (DB.getValue(nodeRechargeOn, "..prepared", 0) > 0) and
			(DB.getValue(nodeRechargeOn, "..dischargeaction", "") == "roll");
	end

	local canRecharge = bRollOnDischarge and (DB.getValue(nodeRechargeOn, "", 0) > 0);
	label_divider.setVisible(canRecharge);
	dischargerechargedice.setVisible(canRecharge);
	label_plus2.setVisible(canRecharge);
	dischargerechargebonus.setVisible(canRecharge);
end