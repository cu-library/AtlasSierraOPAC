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
	elseif title ~= nil and title ~= "" then
		url = "search/?searchtype=t&SORT=D&searcharg=" .. urlEncode(title) .. "&searchscope=9&submit=Submit"
	elseif callNumber ~= nil and callNumber ~= "" then
		url = "search/?searchtype=c&SORT=D&searcharg=" .. urlEncode(callNumber) .. "&searchscope=9&submit=Submit"
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
	local lastSubtag = ""

	-- Process the raw MARC line by line.
	for line in unprocessedMarc:gmatch("[^\r\n]+") do
		local tag, subtag, value = line:match("^(...).(..).(.*)$")
		tag = trim(tag)
		subtag = trim(subtag)
		value = trim(value)
		-- If the tag is LEA, we're on the first line. Skip to the next line.
		if tag == "LEA" then
		-- If the tag is empty, we're still processing a multi-line value. Add it to the previous tag.
		elseif tag == "" then
			lastAddedIndex = #marc[lastTag][lastSubtag]
			marc[lastTag][lastSubtag][lastAddedIndex] = marc[lastTag][lastSubtag][lastAddedIndex] .. " " .. value
		else
			if marc[tag] == nil then marc[tag] = {} end
			if marc[tag][subtag] == nil then marc[tag][subtag] = {} end
			table.insert(marc[tag][subtag], value)
			lastTag = tag
			lastSubtag = subtag
		end
	end

	-- Title
	if marc["245"] ~= nil then
		local title = ""
		if     marc["245"]["00"] ~= nil then title = marc["245"]["00"][1]
		elseif marc["245"]["10"] ~= nil then title = marc["245"]["10"][1]
		elseif marc["245"]["13"] ~= nil then title = marc["245"]["13"][1] end
		if title ~= "" then
			local finalTitle = title:match("^(.-) ?/ ?.*$")
			if finalTitle == nil then
				finalTitle = title
			else
				finalTitle = finalTitle .. "."
			end
			SetFieldValue("Item", "Title", removeSubFieldMarkers(finalTitle))
		end
	end

	-- Author
	if (marc["100"] ~= nil and marc["100"]["1"] ~= nil) then
		SetFieldValue("Item", "Author", removeSubFieldMarkers(marc["100"]["1"][1]))
	end

	-- Call Number
	if (marc["090"] ~= nil and marc["090"]["1"] ~= nil) then
		SetFieldValue("Item", "Callnumber", removeSubFieldMarkers(marc["090"]["1"][1]))
	end

	-- ISXN
	if (marc["020"] ~= nil and marc["020"][""] ~= nil) then
		isxn = marc["020"][""][1]:match("^([a-zA-Z0-9]+).*$")
		SetFieldValue("Item", "ISXN", removeSubFieldMarkers(isxn))
	end

	-- Edition
	if (marc["250"] ~= nil and marc["250"][""] ~= nil) then
		SetFieldValue("Item", "Edition", removeSubFieldMarkers(marc["250"][""][1]))
	end

	-- Pages
	if (marc["300"] ~= nil and marc["300"][""] ~= nil) then
		pages = marc["300"][""][1]:match("^.-([0-9]-)]? p\..*$")
		SetFieldValue("Item", "PagesEntireWork", pages)
	end

	-- Year
	if (marc["260"] ~= nil and marc["260"][""] ~= nil) then
		SetFieldValue("Item", "JournalYear", getYear(marc["260"][""][1]))
	end
	if (marc["264"] ~= nil and marc["264"][""] ~= nil) then
		SetFieldValue("Item", "JournalYear", getYear(marc["264"][""][1]))
	end

	-- Editor
	if (marc["700"] ~= nil and marc["700"]["10"] ~= nil) then
		SetFieldValue("Item", "Editor", removeSubFieldMarkers(marc["700"]["10"][1]))
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

-- Get the year from a 260 or 264 field. 
function getYear(value)
	year = value:match("^.-|c%[?([0-9][0-9][0-9][0-9])%]?%.?$")
	if year == nil then year = value:match("^.-%[?([0-9][0-9][0-9][0-9])%]?$") end
	return year
end