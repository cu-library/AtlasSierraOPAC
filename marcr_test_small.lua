local marcr = require "marcr"
local luaunit = require "luaunit"

function test9781118343289()
  marcr.process([[LEADER 00000nam  22020414i 4500 
008    141201s2015    njuabf   b    001 0 eng d 
010    2014046641 
020    9781118343289 (paperback) 
040    DLC|beng|cDLC|erda|dCaOOCC|zALH 
050 00 G70.4|b.L54 2015 
090 1  G70.4|b.L54 2015 
100 1  Lillesand, Thomas M.,|eauthor. 
245 10 Remote sensing and image interpretation /|cThomas M. 
       Lillesand, Ralph W. Kiefer, Jonathan W. Chipman. 
250    Seventh edition. 
264  1 Hoboken, N.J. :|bJohn Wiley &amp; Sons, Inc.,|c[2015] 
264  4 |c©2015 
300    xii, 720 pages, [36] pages of plates :|billustrations 
       (some colour), maps (some colour) ;|c25 cm. 
336    text|btxt|2rdacontent 
336    cartographic image|bcri|2rdacontent 
337    unmediated|bn|2rdamedia 
338    volume|bnc|2rdacarrier 
504    Includes bibliographical references (pages 699-708) and 
       index. 
650  0 Remote sensing. 
700 1  Kiefer, Ralph W.,|eauthor. 
700 1  Chipman, Jonathan W.,|eauthor. 
939    20150801-Carleton-University-Library 
939    20150804-cuybp.01aug15.r116.pro 
]])
  luaunit.assertEquals(string.lower(marcr.title()), string.lower("Remote sensing and image interpretation."))
  luaunit.authorAssertEquals(marcr.author(), "Lillesand, Thomas M.")
  luaunit.callnumberAssertEquals(marcr.callnumber(), "G70.4 .L54 2015")
  luaunit.editionAssertEquals(marcr.edition(), "7th ed.")
  luaunit.assertEquals(marcr.pages(), "720")
  luaunit.assertEquals(marcr.year(), "2015")
  luaunit.assertEquals(marcr.editor(), "")
end

os.exit(luaunit.LuaUnit.run())
