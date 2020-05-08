-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Initialization
function onInit()
    super.onInit();
    if User.isHost() then
        registerMenuItem(Interface.getString("menu_restextended"), "pointer_square", 8, 2);
    end
end

function onMenuSelection(selection, subselection)
    super.onMenuSelection(selection, subselection);
    if User.isHost() then
        if selection == 8 and subselection == 2 then
			extendedRest()
        end
    end
end

function extendedRest()
	ChatManager.Message(Interface.getString("message_ct_restextended"), true);
    ExtendedRest.beginExtended();
	CombatManager2.rest(true);
    ExtendedRest.beginExtended();
end