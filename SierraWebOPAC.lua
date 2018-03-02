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

local marcr = require "marcr"

-- URL Encode values for the catalogue search. 
local function urlEncode(str)
	str = str:gsub("\n", "\r\n")
	str = str:gsub("([^%w ])",
			function (c) return string.format ("%%%02X", string.byte(c)) end)
	return (str:gsub(" ", "+"))
end

local function useIfNotEmpty(fieldName, value)
	if value ~= "" then
		SetFieldValue("Item", fieldName, value)
	end
end

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
	marcr.process(unprocessedMarc)
	useIfNotEmpty("Title", marcr.title())
	useIfNotEmpty("Author", marcr.author())
	useIfNotEmpty("Callnumber", marcr.callnumber())
	useIfNotEmpty("ISXN", marcr.isxn())
	useIfNotEmpty("Edition", marcr.edition())
	useIfNotEmpty("PagesEntireWork", marcr.pages())
	useIfNotEmpty("JournalYear", marcr.year())
	useIfNotEmpty("Editor", marcr.editor())

	ExecuteCommand("SwitchTab", {"Details"})
end