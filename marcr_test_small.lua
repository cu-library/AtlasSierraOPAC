local marcr = require "marcr"
local luaunit = require "luaunit"

function test9781552391624()
    marcr.process([[LEADER 00000nam  22003374a 4500 
008    050929s2006    onca   | bv   000 0 eng|  
016    20059060379 
020    1552391620  
020    9781552391624 
035    (OCoLC)61864469 
040    NLC|beng|cNLC|dGUL|dYDXCP|dOCLCQ|dGWL|dCaOOCC|zKL 
043    n-cn--- 
049    BOPM 
050  4 KZ358.A2|bI58 2006 
090 1  KZ358.A2|bI58 2006 
245 00 International law :|bchiefly as interpreted and applied in
       Canada /|cHugh M. Kindred and Phillip M. Saunders, general
       editors ; Jutta Brunnée ... [et al.]. 
250    7th ed. 
260    Toronto :|bEmond Montgomery Publications,|c2006. 
300    lxxxi, 1221 p. :|bill. ;|c24 cm. +|e1 supplement (v, 156 
       p.). 
500    Edition comprises one volume + documentary supplement. 
504    Includes bibliographical references. 
505 0  The roles of international law and international lawyers -
       -International legal persons -- Creation and ascertainment
       of international law -- National application of 
       international law -- Interstate relations --  
       International dispute settlement -- State jurisdiction 
       over territory -- Nationality -- State jurisdiction over 
       persons -- State responsibility -- International criminal 
       law -- Protection of human rights -- Law of the sea -- 
       Protection of the environment -- Limitation of the use of 
       force. 
650  0 International law|zCanada. 
650  0 International law|zCanada|vCases. 
650  0 International law|vSources. 
650  0 International law|vCases. 
650  0 Government liability (International law) 
650  0 Environmental law, International. 
700 1  Kindred, Hugh M. 
700 1  Saunders, Phillip Martin. 
700 1  Brunnée, Jutta. 
]])
    luaunit.assertEquals(string.lower(marcr.title()), string.lower("International law : chiefly as interpreted and applied in Canada."))
    luaunit.authorAssertEquals(marcr.author(), "Kindred, Hugh M.")
    luaunit.callnumberAssertEquals(marcr.callnumber(), "KZ358.A2 I58 2006 SUP.")
    luaunit.editionAssertEquals(marcr.edition(), "7th ed.")
    luaunit.assertEquals(marcr.pages(), "156")
    luaunit.assertEquals(marcr.year(), "2006")
    luaunit.assertEquals(marcr.editor(), "")
end

os.exit(luaunit.LuaUnit.run())
