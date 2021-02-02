-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aWindows = {}

function onInit()
	Debug.console("init");
	Interface.onWindowOpened = onWindowOpened;
	Interface.onWindowClosed = onWindowClosed;
	Comm.registerSlashHandler("wys", onCommand);
end

function onWindowOpened(win)
	table.insert(aWindows, win);
	Debug.chat(aWindows);
	-- Debug.chat(win);
	-- for _,control in ipairs(win.getControls()) do
	-- 	Debug.chat(control, type(control));
	-- end
end

function onWindowClosed(win)
	local aKeptWindows = {}
	for _,iter in ipairs(aWindows) do
		if win ~= iter then
			table.insert(aKeptWindows, iter);
		end
	end
	aWindows = aKeptWindows;
	Debug.chat(aWindows);
end

function onCommand(sCommands, sParams)
	Interface.openWindow("window_viewer", "")
end

function getOpenWindows()
	return aWindows;
end