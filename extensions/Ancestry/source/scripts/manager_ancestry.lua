-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local replacement = {
	["Race"] = "Ancestry",
	["Races"] = "Ancestries",
	["Racial"] = "Ancestral",
	["race"] = "ancestry",
	["races"] = "ancestries",
	["racial"] = "ancestral",
	["A Race"] = "An Ancestry",
	["A race"] = "An ancestry",
	["a Race"] = "an Ancestry",
	["a race"] = "an ancestry",
	["A Racial"] = "An Ancestral",
	["A racial"] = "An ancestral",
	["a Racial"] = "an Ancestral",
	["a racial"] = "an ancestral",
	["Subrace"] = "Heritage",
	["Subraces"] = "Heritages",
	["Sub-race"] = "Heritage",
	["Sub-races"] = "Heritages",
	["subrace"] = "heritage",
	["subraces"] = "heritages",
	["sub-race"] = "heritage",
	["sub-races"] = "heritages"
};

local exclusions = {
	["reference.refmanualdata.refpage_racing@DD Tomb of Annihilation"] = true,
	["reference.refmanualdata.refpage_dinosaurracing@DD Tomb of Annihilation"] = true
};

function sanitizeText(sText, nodeContext)
	if nodeContext then
		if type(nodeContext) == "databasenode" then
			nodeContext = nodeContext.getPath();
		end
		if exclusions[nodeContext] then
			return sText;
		end
	end

	-- TODO write a custom substitution algorithm to avoid multiple passes
	return sText:gsub("a [-%.%a]+", replacement):gsub("[%._]?[-%a]+", replacement);
end