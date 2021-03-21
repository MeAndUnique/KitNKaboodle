-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeItem = getDatabaseNode();
	DB.addHandler(nodeItem.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.addHandler(nodeItem.getPath("rechargeperiod"), "onUpdate", onRechargePeriodChanged);
end

function onClose()
end

function update(bLocked)
	prepared.setReadOnly(bLocked);
	rechargeperiod.setReadOnly(bLocked);
	rechargedice.setReadOnly(bLocked);
	label_plus.setVisible((rechargebonus.getValue() ~= 0) or (rechargebonus.isVisible() and not bLocked));
	rechargebonus.setReadOnly(bLocked);

	if bLocked then
		prepared.setFrame(nil);
		rechargedice.setFrame(nil);
		rechargebonus.setFrame(nil);
	else
		prepared.setFrame("fielddark", 7, 5, 7, 5);
		rechargedice.onValueChanged(); -- basicdice sets the frame when the value changes.
		rechargebonus.setFrame("fielddark", 7, 5, 7, 5);
	end
end

function onChargesChanged(nodeCharges)
	local hasCharges = nodeCharges.getValue() > 0;
	rechargeperiod.setVisible(hasCharges);
	rechargeLabel.setVisible(hasCharges);
	rechargedice.setVisible(hasCharges);
	label_plus.setVisible(hasCharges);
	rechargebonus.setVisible(hasCharges);
end

function onRechargePeriodChanged(nodeRechargePeriod)
	local canRecharge = (nodeRechargePeriod.getValue() or "") ~= "";
	rechargeLabel.setVisible(canRecharge);
	rechargedice.setVisible(canRecharge);
	label_plus.setVisible(canRecharge);
	rechargebonus.setVisible(canRecharge);
end