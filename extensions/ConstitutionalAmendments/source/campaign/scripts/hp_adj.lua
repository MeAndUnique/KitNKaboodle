-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local node;
local bUpdating;

function onInit()
    if super and super.onInit then
        super.onInit();
    end

    node = DB.createChild(window.getDatabaseNode(), source[1], "number");
    node.onUpdate = onNodeUpdate;
end

function onClosed()
    node.onUpdate = nil;
end

function onNodeUpdate()
    if bUpdating then
        return;
    end

    bUpdating = true;
    setValue(node.getValue());
    window.onHealthChanged();
    bUpdating = false;
end

function onValueChanged()
    if bUpdating then
        return;
    end

    bUpdating = true;
    node.setValue(getValue());
    HpManager.recalculateTotal(window.getDatabaseNode());
    window.onHealthChanged();
    bUpdating = false;
end

function onDrop(x, y, draginfo)
    if draginfo.isType("number") then
        setValue(getValue() + draginfo.getNumberData());
        return true;
    end
end