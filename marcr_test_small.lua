local marcr = require "marcr"
local luaunit = require "luaunit"

function test013805326X()
       marcr.process([[LEADER 00000pam  2200000 a 4500 
001    54206350 
003    CaOEAGC 
005    19990519114500.6 
008    991201s1999    njua     b    001 0 eng   
010    98050525 
020    013805326X (pbk.) 
035    1189957 
040    DLC|cDLC|dDLC 
050 00 QC680|b.G74 1999 
090 1  QC680.G74 1999 
100 1  Griffiths, David J.|q(David Jeffrey),|d1942- 
245 10 Introduction to electrodynamics /|cDavid J. Griffiths. 
250    3rd ed. 
260    Upper Saddle River, N.J. :|bPrentice Hall,|cc1999. 
300    xv, 576 p. :|bill. ;|c25 cm. 
504    Includes bibliographical references and index. 
650  0 Electrodynamics. 
]])
       luaunit.assertEquals(string.lower(marcr.title()), string.lower("Introduction to electrodynamics."))
       luaunit.authorAssertEquals(marcr.author(), " Griffiths, David J. (David Jeffrey), 1942-")
       luaunit.callnumberAssertEquals(marcr.callnumber(), "QC680.G74 1999")
       luaunit.editionAssertEquals(marcr.edition(), "3rd ed.")
       luaunit.assertEquals(marcr.pages(), "576")
       luaunit.assertEquals(marcr.year(), "1999")
       luaunit.assertEquals(marcr.editor(), "")
end

os.exit(luaunit.LuaUnit.run())
