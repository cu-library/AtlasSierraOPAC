-- About SierraWebOPAC.lua
--
-- This addon allows for importing data from the Sierra Web OPAC to the item form. 
-- The MARC display for an item must be open before importing will work.
-- scriptActive must be set to true for the script to run.
-- autoSearch (boolean) determines whether the search is performed automatically when a request is opened or not.
-- catalogueURL (string) determines the URL for the Sierra Web OPAC to use. 

local autoSearch = GetSetting("AutoSearch")
local catalogueURL = GetSetting("CatalogueURL")
local interfaceMngr = nil
local form = nil
local ribbonPage = nil
local browser = nil

function Init()
	if GetFieldValue("Item", "ItemType") == "MON" then
		interfaceMngr = GetInterfaceManager()

		-- Create a form
		form = interfaceMngr:CreateForm("Sierra", "Script")

		-- Add a browser
		browser = form:CreateBrowser("Sierra", "Sierra", "Sierra")

		-- Hide the text label
		browser.TextVisible = false

		-- Since we didn't create a ribbon explicitly before creating our browser, it will have created one using the name we passed the CreateBrowser method.  We can retrieve that one and add our buttons to it.
		ribbonPage = form:GetRibbonPage("Sierra")

		-- Create the search and import buttons.  We are storing the import button so we can enable it and disable it as needed.
		ribbonPage:CreateButton("Search", GetClientImage("Search32"), "Search", "Sierra")
		ribbonPage:CreateButton("Import Data", GetClientImage("ImportData32"), "ImportData", "Sierra")

		-- After we add all of our buttons and form elements, we can show the form.
		form:LoadLayout("SierraWebOPACLayout.xml")
		form:Show()

		if autoSearch then
			Search()
		end
	end
end

function Search()
	local isxn = GetFieldValue("Item", "ISXN")
	local title = GetFieldValue("Item", "Title")
	local callNumber = GetFieldValue("Item", "Callnumber")

	local url = ""

	if isxn ~= nil and isxn ~= "" then
		url = "search/?searchtype=i&SORT=D&searcharg=" .. urlEncode(isxn) .. "&searchscope=9&submit=Submit"
	elseif callNumber ~= nil and callNumber ~= "" then
		url = "search/?searchtype=c&SORT=D&searcharg=" .. urlEncode(callNumber) .. "&searchscope=9&submit=Submit"
	elseif title ~= nil and title ~= "" then
		url = "search/?searchtype=t&SORT=D&searcharg=" .. urlEncode(title) .. "&searchscope=9&submit=Submit"
	end

	browser:Navigate(catalogueURL .. url)
end

function ImportData()
	local maincontent = browser:GetElementInFrame(nil, "main-content")

	if maincontent == nil then
		return
	end

	local pre = maincontent:GetElementsByTagName("pre")
	if pre == nil then
		return
	end

	local unprocessedMarc = pre:get_Item(0)
	if unprocessedMarc == nil then
		return
	end

	unprocessedMarc = unprocessedMarc.InnerText

	-- The marc table holds the marc text from the web page, broken down by tag and subtag.
	local marc = {}
	local lastTag = ""

	-- Process the raw MARC line by line.
	for line in unprocessedMarc:gmatch("[^\r\n]+") do
		local tag, value = line:match("^(...)....(.*)$")
		tag = trim(tag)
		value = trim(value)
		-- If the tag is LEA, we're on the first line. Skip to the next line.
		if tag == "LEA" then
		-- If the tag is empty, we're still processing a multi-line value. Add it to the previous tag.
		elseif tag == "" then
			lastAddedIndex = #marc[lastTag]
			marc[lastTag][lastAddedIndex] = marc[lastTag][lastAddedIndex] .. " " .. value
		else
			if marc[tag] == nil then marc[tag] = {} end
			table.insert(marc[tag], value)
			lastTag = tag
		end
	end

	-- Title
	if marc["245"] ~= nil then
		-- Strip out anything past the /
		local finalTitle = marc["245"][1]:match("^(.-) ?/ ?.*$")
		-- If the match failed, we have a title with no /. 
		if finalTitle == nil then
			finalTitle = marc["245"][1]
		else
			-- The match succeeded, add back the . at the end of the title.
			finalTitle = finalTitle .. "."
		end
		SetFieldValue("Item", "Title", removeSubFieldMarkers(finalTitle))
	end

	-- Author
	-- Use the 100, 110, or 111 fields. 
	if marc["100"] ~= nil then
		SetFieldValue("Item", "Author", removeSubFieldMarkers(marc["100"][1]))
	elseif marc["110 "] ~= nil then
		SetFieldValue("Item", "Author", removeSubFieldMarkers(marc["110"][1]))
	elseif marc["111 "] ~= nil then
		SetFieldValue("Item", "Author", removeSubFieldMarkers(marc["111"][1]))
	end

	-- Call Number
	if marc["090"] ~= nil then
		SetFieldValue("Item", "Callnumber", removeSubFieldMarkers(marc["090"][1]))
	end

	-- ISXN
	if marc["020"] ~= nil then
		local startWithSubField = marc["020"]:find("^|[a-z].*")
		if startWithSubField == nil then
			local isxn = marc["020"][1]:match("^([a-zA-Z0-9]+).*$")
		else
			local isxn = marc["020"][1]:match("^|[a-z]([a-zA-Z0-9]+).*$")
		end
		SetFieldValue("Item", "ISXN", removeSubFieldMarkers(isxn))
	end

	-- Edition
	if marc["250"] ~= nil then
		SetFieldValue("Item", "Edition", removeSubFieldMarkers(marc["250"][1]))
	end

	-- Pages
	if marc["300"] ~= nil then
		-- If there are volumes, don't guess the number of pages
		if (marc["300"][1]:find("v%.") == nil or marc["300"][1]:find("volume") == nil) then
			pages = marc["300"][1]:match("^.-([0-9]-)%]? ?p\..*$")
			if pages == nil then
				pages = marc["300"][1]:match("^.-([0-9]-)%]? ?pages.*$")
			end
			if pages ~= nil then
				SetFieldValue("Item", "PagesEntireWork", pages)
			end
		end
	end

	-- Year
	if marc["008"] ~= nil  then
		SetFieldValue("Item", "JournalYear", marc["008"][1]:sub(8, 11))
	end

	-- Editor
	if marc["245"] ~= nil then
		local editor = marc["245"][1]:match("^.-|c.-[eE]dited by ([^,]*) and .*$")
		if editor == nil then
			editor = marc["245"][1]:match("^.-|c.-[eE]dited by ([^,]*).*%.$")
		end
		if editor == nil then
			editor = marc["245"][1]:match("^.-|c.-[eE]dited and introduced by ([^,]*).*%.$")
		end
		if editor == nil then
			editor = marc["245"][1]:match("^.-|c.-[eE]dited and with an introduction by ([^,]*).*%.$")
		end
		if editor == nil then
			editor = marc["245"][1]:match("^.-|c.-[eE]dited and with introductions by ([^,]*).*%.$")
		end
		if editor == nil then
			editor = marc["245"][1]:match("^.-|c.-[eE]dited with introductions by ([^,]*).*%.$")
		end
		if editor == nil then
			editor = marc["245"][1]:match("^.-|c.-[eE]dited and transcribed by ([^,]*).*%.$")
		end
		SetFieldValue("Item", "Editor", editor)
	end

	ExecuteCommand("SwitchTab", {"Details"})
end

-- Remove whitespace from the beginning and ending of a string.
function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Remove any subfield markers. If that leaves double spaces, remove those as well.
function removeSubFieldMarkers(s)
	local subsDone = s:gsub("|[a-zA-Z0-9]", " ")
	return (subsDone:gsub("  ", " "))
end

-- URL Encode values for the catalogue search. 
function urlEncode(str)
	str = str:gsub("\n", "\r\n")
	str = str:gsub("([^%w ])",
			function (c) return string.format ("%%%02X", string.byte(c)) end)
	return (str:gsub(" ", "+"))
end