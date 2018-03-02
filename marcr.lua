-- marcr is a MARC processing library.

local marcr = {}

marcr["m"] = {}

-- Remove whitespace from the beginning and ending of a string.
local function trim(s)
	return(s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Flip a name from First Last to Last, First
local function flipName(name)
	return(name:gsub("^(.-) ([^ ]*)$", "%2, %1"))
end

-- Remove any subfield markers. If that leaves double spaces, remove those as well.
local function removeSubFieldMarkers(s)
	local subsDone = s:gsub("|[a-zA-Z0-9]", " ")
	return(subsDone:gsub("  ", " "))
end

function marcr.process(rawMARC)
	marcr["m"] = {}
	local lastTag = ""

	-- Process the raw MARC line by line.
	for line in rawMARC:gmatch("[^\r\n]+") do
		local tag, value = line:match("^(...)....(.*)$")
		tag = trim(tag)
		value = trim(value)
		-- If the tag is LEA, we're on the first line. Skip to the next line.
		if tag == "LEA" then
		-- If the tag is empty, we're still processing a multi-line value. Add it to the previous tag.
		elseif tag == "" then
			lastAddedIndex = #marcr["m"][lastTag]
			marcr["m"][lastTag][lastAddedIndex] = marcr["m"][lastTag][lastAddedIndex] .. " " .. value
		else
			if marcr["m"][tag] == nil then marcr["m"][tag] = {} end
			table.insert(marcr["m"][tag], value)
			lastTag = tag
		end
	end
end

function marcr.title()
	local title = ""
	if marcr["m"]["245"] ~= nil then
		-- Strip out anything past the /
		title = marcr["m"]["245"][1]:match("^(.-) ?/ ?.*$")
		-- If the match failed, we have a title with no /. 
		if title == nil then
			title = marcr["m"]["245"][1]
		else
			-- The match succeeded, add back the . at the end of the title.
			title = title .. "."
		end
		title = title:gsub("&amp;", "&")
		title = title:gsub("not-for- profit", "not-for-profit")
		title = title:gsub("not- for-profit", "not-for-profit")
		title = removeSubFieldMarkers(title)
	end
	return title
end

function marcr.author()
	local author = ""
	-- Use the 100, 110, or 111 fields. 
	if marcr["m"]["100"] ~= nil then
		author = marcr["m"]["100"][1]
		author = author:gsub(",?%|e.*$", ".")
		author = author:gsub("%)%.$", ")")
		author = author:gsub("%-%.$", "-")
		author = author:gsub("%.%.$", ".")
	elseif marcr["m"]["110 "] ~= nil then
		author = marcr["m"]["110"][1]
	elseif marcr["m"]["111 "] ~= nil then
		author = marcr["m"]["111"][1]
	end

	-- We couldn't find an author in the 100 field. Fall back to title. 
	if (author == "" and marcr["m"]["245"] ~= nil) then
		if marcr["m"]["245"][1]:find("%|cedited by") == nil then
	
			author = marcr["m"]["245"][1]:match("^.*%|c(.-) %.%.%. %[et al%.%]%.")
			if author ~= nil then
				author = flipName(author)
			end

			if author == nil then
				author = marcr["m"]["245"][1]:match("^.*%|c(.- Inc%.).*$")
			end

			if author == nil then
				author = marcr["m"]["245"][1]:match("^.*%|c(.-),.*$")
				if author ~= nil then
					author = flipName(author)
				end
			end

			if author == nil then
				author = ""
			else
				author = author:gsub("&amp;", "&")
			end
		end
	end

	return removeSubFieldMarkers(author)
end

function marcr.callnumber()
	local callnumber = ""
	if marcr["m"]["090"] ~= nil then
		callnumber = marcr["m"]["090"][1]
	end
	return removeSubFieldMarkers(callnumber)
end

function marcr.isxn()
	local isxn = ""
	if marcr["m"]["020"] ~= nil then
		-- Try to match on an isxn number
		isxn = marcr["m"]["020"][1]:match("^([a-zA-Z0-9]+).*$")
		if isxn == nil then
			-- Strip out a leading subfield
			isxn = marcr["m"]["020"][1]:match("^|[a-z]([a-zA-Z0-9]+).*$")
		end
		-- Throw up our hands. Just return the 020.
		if isxn == nil then
			isxn = marcr["m"]["020"][1]
		end
	end
	return removeSubFieldMarkers(isxn)
end

function marcr.edition()
	local edition = ""
	if marcr["m"]["250"] ~= nil then
		-- Strip out anything past the /
		edition = marcr["m"]["250"][1]:match("^(.-) ?/ ?.*$")
		-- If the match failed, we have a edition with no /. 
		if edition == nil then
			edition = marcr["m"]["250"][1]
		end
		edition = edition:gsub("^%[", "")
		edition = edition:gsub("^%[", "")
		edition = edition:gsub("%]$", "")
		edition = edition:gsub(" %-$", "")
		edition = edition:gsub("edition$", "edition.")
		edition = edition:gsub("ed$", "ed.")
	end
	return removeSubFieldMarkers(edition)
end

function marcr.pages()
	local pages = ""
	if marcr["m"]["300"] ~= nil then
		-- If there are volumes, don't guess the number of pages
		if (marcr["m"]["300"][1]:find("v%.") == nil and marcr["m"]["300"][1]:find("volume") == nil) then

			-- If the pages contain an "added pages" section...
			if marcr["m"]["300"][1]:find("^.-%[%d-%] p%.") ~= nil then
				pages = marcr["m"]["300"][1]:match("^.-([0-9]-) ?p?%.?, %[.*$")
			else 
				pages = marcr["m"]["300"][1]:match("^.-([0-9]-)%]? ?p%.?.*$")
			end

			if pages == nil then
				pages = marcr["m"]["300"][1]:match("^.-([0-9]-)%]? ?pages.*$")
			end
			if pages == nil then
				pages = marcr["m"]["300"][1]
			end
		end
	end
	return removeSubFieldMarkers(pages)
end

function marcr.year()
	local year = ""
	if marcr["m"]["008"] ~= nil  then
		year =  marcr["m"]["008"][1]:sub(8, 11)
	end
	return removeSubFieldMarkers(year)
end

function marcr.editor()
	local editor = ""
	if marcr["m"]["245"] ~= nil then
		editor = marcr["m"]["245"][1]:match("^.-|c.-[eE]dited by ([^,;]*) and .*$")
		if editor == nil then
			editor = marcr["m"]["245"][1]:match("^.-|c.-[eE]dited by ([^,;]*) &amp; .*%.$")
		end
		if editor == nil then
			editor = marcr["m"]["245"][1]:match("^.-|c.-[eE]dited by ([^,;]*).*%.$")
		end
		if editor == nil then
			editor = marcr["m"]["245"][1]:match("^.-|c.-[eE]dited and introduced by ([^,;]*).*%.$")
		end
		if editor == nil then
			editor = marcr["m"]["245"][1]:match("^.-|c.-[eE]dited and with an introduction by ([^,;]*).*%.$")
		end
		if editor == nil then
			editor = marcr["m"]["245"][1]:match("^.-|c.-[eE]dited and with introductions by ([^,;]*).*%.$")
		end
		if editor == nil then
			editor = marcr["m"]["245"][1]:match("^.-|c.-[eE]dited with introductions by ([^,;]*).*%.$")
		end
		if editor == nil then
			editor = marcr["m"]["245"][1]:match("^.-|c.-[eE]dited and transcribed by ([^,;]*).*%.$")
		end
		if editor == nil then
			editor = ""
		end
	end

	if editor ~= "" then
		editor = flipName(editor)
		editor = editor:gsub("([^%.])$", "%1.")
	end


	return removeSubFieldMarkers(trim(editor))
end

return marcr