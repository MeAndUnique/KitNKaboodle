-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeItem = getDatabaseNode();
	onChargesChanged(nodeItem.getChild("prepared")); -- Calls onRechargePeriodChanged()
	DB.addHandler(nodeItem.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.addHandler(nodeItem.getPath("rechargeperiod"), "onUpdate", onRechargePeriodChanged);
end

function onClose()
	local nodeItem = getDatabaseNode();
	DB.removeHandler(nodeItem.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodeItem.getPath("rechargeperiod"), "onUpdate", onRechargePeriodChanged);
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
		label_plus.setVisible(not rechargedice.isEmpty() and (rechargebonus.getValue() ~= 0));
		rechargebonus.setFrame(nil);
		dischargeaction.setFrame(nil);
	else
		prepared.setFrame("fielddark", 7, 5, 7, 5);
		rechargedice.onValueChanged(); -- basicdice sets the frame when the value changes.
		label_plus.setVisible((prepared.getValue() > 0) and ((rechargeperiod.getStringValue() or "") ~= ""));
		rechargebonus.setFrame("fielddark", 7, 5, 7, 5);
		dischargeaction.setFrame("fielddark", 7, 5, 7, 5);
	end
end

function onChargesChanged(nodeCharges)
	local hasCharges = nodeCharges.getValue() > 0;
	rechargeperiod.setVisible(hasCharges);
	onRechargePeriodChanged(DB.getChild(nodeCharges, "..rechargeperiod"), hasCharges);
end

function onRechargePeriodChanged(nodeRechargePeriod, hasCharges)
	if hasCharges == nil then
		hasCharges = DB.getValue(nodeRechargePeriod, "..prepared", 0) > 0;
	end
	local sRechargePeriod = nodeRechargePeriod.getValue() or "";
	rechargetime.setVisible((sRechargePeriod == "daily") and hasCharges);
	local canRecharge = sRechargePeriod ~= "";
	rechargeLabel.setVisible(canRecharge and hasCharges);
	rechargedice.setVisible(canRecharge and hasCharges);
	label_plus.setVisible(canRecharge and hasCharges);
	rechargebonus.setVisible(canRecharge and hasCharges);
end