-- About SierraWebOPAC.lua
--
-- This Addon does an ISBN or Title search using the Sierra Web OPAC for Carleton University Library.
-- ISBN will be run if one is available.
-- scriptActive must be set to true for the script to run.
-- autoSearch (boolean) determines whether the search is performed automatically when a request is opened or not.
-- catalogueURL (string) determines the URL for the Sierra Web OPAC to use. 

-- set autoSearch to true for this script to automatically run the search when the request is opened.

--interfaceMngr:ShowMessage("debug", "debug title")
local autoSearch = GetSetting("AutoSearch")
local catalogueURL = GetSetting("CatalogueURL")
local interfaceMngr = nil
local form = nil
local ribbonPage = nil
local browser = nil

require "Atlas.AtlasHelpers"

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
	
	local marc = pre:get_Item(0)
	if marc == nil then
		return
	end

	marc = marc.InnerText

	local combinedTitle = ""
	local processingTitle = false
	local foundISXN = false

	for s in marc:gmatch("[^\r\n]+") do

		-- Title
		local firstLine = false
		local title = s:match("^245 .. (.+)$")
		if (title ~= nil and processingTitle == false) then
			combinedTitle = title
			processingTitle = true
			firstLine = true
		end

		local continuedTitle = s:match("^       (.+)$")
		if (continuedTitle ~= nil and processingTitle == true) then 
			combinedTitle = combinedTitle .. continuedTitle
		end

		local hasField = s:find("^%d%d%d .*$")
		if (hasField ~= nil and processingTitle == true and firstLine == false) then
			SetFieldValue("Item", "Title", trim(removeSubFieldMarkers(combinedTitle)))
			processingTitle = false
		end

		-- Author
		local author = s:match("^100 1  (.-)$")
		if author ~= nil then 
			SetFieldValue("Item", "Author", trim(removeSubFieldMarkers(author)))
		end

		-- Call Number
		local callNumber = s:match("^090 1  (.+)$")
		if callNumber ~= nil then 
			SetFieldValue("Item", "Callnumber", trim(removeSubFieldMarkers(callNumber)))
		end

		-- ISXN
		local isxn = s:match("^020    ([a-zA-Z0-9]+) .*$")
		if (isxn ~= nil and foundISXN == false) then 
			SetFieldValue("Item", "ISXN", trim(removeSubFieldMarkers(isxn)))
			foundISXN = true
		end

		-- Edition
		local edition = s:match("^250    (.+)$")
		if edition ~= nil then
			SetFieldValue("Item", "Edition", trim(removeSubFieldMarkers(edition)))
		end

		-- Pages
		local pages = s:match("300    (.-):?|b.*$")
		if pages ~= nil then
			pages = pages:gsub("p.", " ")
			SetFieldValue("Item", "Pages", trim(pages))
		end
	end

	ExecuteCommand("SwitchTab", {"Details"})
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function removeSubFieldMarkers(s)
  return (s:gsub("|[a-zA-Z0-9]", " "))
end

function urlEncode(str)
	str = string.gsub (str, "\n", "\r\n");
	str = string.gsub (str, "([^%w ])",
			function (c) return string.format ("%%%02X", string.byte(c)) end);
	str = string.gsub (str, " ", "+");
	return str;
end
