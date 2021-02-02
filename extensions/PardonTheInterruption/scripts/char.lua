-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Initialization
function onInit()
    super.onInit();
    if User.isHost() then
        registerMenuItem("Interruption Effects", "bell", 3);
    end
end

function onMenuSelection(selection, subselection)
    super.onMenuSelection(selection, subselection);
    if User.isHost() then
        if selection == 3 then
            local nodeChar = getDatabaseNode();
            Interface.openWindow("interruption_preferences", nodeChar);
        end
    end
end