---/Street Fighter: The Movie training lua v.0.1.4 (2021/06/21)/---
---/This works correctly on Fightcade FBNeo v.0.2.97.44 and NOT on mame-rr/---

-- *issue -> things to be solved, *comment -> stuff worth writing but not critical --

---preamble---*important
local gamename = "Street Fighter: The Movie"
local scriptver = "v.0.1.4"
local rb, rbs, rw, rws, rd = memory.readbyte, memory.readbytesigned, memory.readword, memory.readwordsigned, memory.readdword
local wb, wbs, ww, wws, wd = memory.writebyte, memory.writebytesigned, memory.writeword, memory.writewordsigned, memory.writedword
local function readcurrentframe() -- read the current frame
	return emu.framecount()
end
local sw,sh = emu.screenwidth(), emu.screenheight() -- read the screen width/height
function lccalc(count, max, add) --calculate loop counter (count: the counter, max: the maximum value, add: the value to add)
	if (count+add)%max == 0 then
		return max
	else
		return (count+add)%max
	end
end
function tblconcat(tbl1, tbl2) -- concatenate two tables (the former table: tbl1, the latter table: tbl2)
	for i = 1, #tbl2 do
		tbl1[#tbl1+1] = tbl2[i]
	end
	return tbl1
end
function elmdetect(tbl, elm) --detect whether a ceartain element exists in the table (table: tbl, element: elm)
	for _,v in pairs(tbl) do
		if elm == v then
			return true
		end
	end
	return false
end
function basenconvert(cnvnum, cnvbase) -- convert positive decimal integer into base-n number (integer: cnvnum, base: cnvbase)
	local a, b, c = cnvnum, cnvbase, ""
	if type(a) ~= "number" then
		print("string is not supported.")
	elseif a%1 ~= 0 then
		print("float is not supported.")
	elseif a < 0 then
		print("negative value is not supported.")
	elseif a == 0 then
		return 0
	else
		while a > 0 do
			c = "".. (a%b)..c
			a = math.floor(a/b)
		end
		return c
	end
end

local games = {"sftm","sftm110","sftm111","sftmj114"} -- the games this script supports
local addr = { -- list of addresses
	---address P1
	P1health = 0x7169,
	P1meter = 0x717B,
	P1dizzyvalue = 0x7178,
	P1dizzy = 0x7187,
	P1armor = 0x714B,
	P1prjinv = 0x7236,
	P1combocounter = 0x73D8,
	P1chargever = 0x7246,
	P1chargehol = 0x7247,
	P1chargeLP = 0x7258,
	P1chargeMP = 0x7259,
	P1chargeHP = 0x725A,
	P1chargeLK = 0x725B,
	P1chargeMK = 0x725C,
	P1chargeHK = 0x725D,
	P1releasebutton = 0x725E,
	---address P2 (P1+0x1C2)
	P2health = 0x732B,
	P2meter = 0x733D,
	P2dizzyvalue =  0x733A,
	P2dizzy = 0x7349,
	P2armor = 0x730D,
	P2prjinv = 0x73F8,
	P2combocounter = 0x7216,
	P2chargever = 0x7408,
	P2chargehol = 0x7409,
	P2chargeLP = 0x741A,
	P2chargeMP = 0x741B,
	P2chargeHP = 0x741C,
	P2chargeLK = 0x741D,
	P2chargeMK = 0x741E,
	P2chargeHK = 0x741F,
	P2releasebutton = 0x7420,
	---address misc
	timer = 0x715F,
	distance = 0x747A
}

local P1status = {
	health = 0,
	meter = 0,
	dizzyvalue = 0,
	ifdizzy = {{true, false}, 2},
	dizzystate = {{"none", "evil eye", "dizzy", "?"}, 1},
	previousdizzy = 0,
	combocounter = {0, 0},
	combodamage = {0, 0},
	healthbeforecomboed = {128, 128},
	ifrefillhealth = {{true, false}, 2},
	refillcount = 0,
	refillcountstartframe = 0,
	prjinvstate = {{"none", "reflect", "invul", "?"}, 1},
	armorstate = {{"no", "yes", "?"}, 1}
}
local P2status = {
	health = 0,
	meter = 0,
	dizzyvalue = 0,
	ifdizzy = {{true, false}, 2},
	dizzystate = {{"none", "evil eye", "dizzy", "?"}, 1},
	previousdizzy = 0,
	combocounter = {0, 0},
	combodamage = {0, 0},
	healthbeforecomboed = {128, 128},
	ifrefillhealth = {{true, false}, 2},
	refillcount = 0,
	refillcountstartframe = 0,
	prjinvstate = {{"none", "reflect", "invul", "?"}, 1},
	armorstate = {{"no", "yes", "?"}, 1}
}

local luaconfig = {
	showmenu = {{true, false}, 2},
	showhud = {{true, false}, 1},
	showinput = {{true, false}, 1},
	availablecheat = {{true, false}, 1}
}
local inputconfig = {
	ifswapinput = {{true, false}, 2},
	ifdisableinputset = {{true, false}, 2},
	disableinputplayer = {{"none", "P1", "P2", "both"}, 1},
	ifholdinputset = {{true, false}, 2},
	holdinputplayer = {{"none", "P1", "P2", "both"}, 1},
	holddirection = {{"down left", "down", "down right", "left", "neutral", "right", "up left", "up", "up right"}, 5}
}
local menuconfig = {
	menupage = {},
	currentmenuselection = {page = 1, option = 1, subpage = 0, suboption = 1},
	menuinput = {P1 = {holdstartframe = 0, currentinput = {}, previousinput = {}}, P2 = {holdstartframe = 0, currentinput = {}, previousinput = {}}},
	ifswapped = inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]]
}
local hudconfig = {
	hudstyle = {{"detailed", "simple", "input only", "debug"}, 1}
}
local cheatconfig = {
	time = {{"normal", "infinite"}, 2},
	P1health = {{"normal", "refill", "infinite", "red"}, 2},
	P1meter = {{"normal", "infinite"}, 1},
	P1stun = {{"normal", "never"}, 1},
	P2health = {{"normal", "refill", "infinite", "red"}, 2},
	P2meter = {{"normal", "infinite"}, 1},
	P2stun = {{"normal", "never"}, 1},
	ifdisablemusic = {{"on", "off"}, 1},
	selectstage = {{"normal", "Bison's Lair", "Komande Centre", "Tong Warehouse", "Dhalsim's Lab", "Dungeon", "Temple Ruins"}, 1},
	selectmusic = {{"normal", "Ryu", "Vega", "Guile", "Sagat", "Ken", "Honda", "Chun Li", "Cammy", "Fei Long", "Balrog", "Blanka", "M. Bison", "Akuma", "Zangief"}, 1},
	secretcode = {
		ifsecretcode = {{"on", "off"}, 2},
		hidemeters = {{"P1", "P2", "both", "off"}, 4},
		invisotag = {{"P1", "P2", "both", "off"}, 4},
		nothrows = {{"P1", "P2", "both", "off"}, 4},
		nospecials = {{"P1", "P2", "both", "off"}, 4},
		specialonly = {{"P1", "P2", "both", "off"}, 4},
		tagteam = {{"on", "off"}, 2},
		doubledamage = {{"P1", "P2", "both", "off"}, 4},
		speedselect = {{"normal", "turbo", "slow"}, 1},
		noblocking = {{"P1", "P2", "both", "off"}, 4},
		combomode = {{"P1", "P2", "both", "off"}, 4},
		nokicks = {{"P1", "P2", "both", "off"}, 4},
		nopunches = {{"P1", "P2", "both", "off"}, 4},
		strobemode = {{"on", "off"}, 2},
		invisibility = {{"P1", "P2", "both", "off"}, 4},
		classicthrows = {{"P1", "P2", "both", "off"}, 4},
		programmerlevel = {{"on", "off"}, 2},
		inverted = {{"on", "off"}, 2},
		reversecontrols = {{"P1", "P2", "both", "off"}, 4},
		swapplayers = {{"on", "off"}, 2},
	}
}


---input---*important
function getinput()
	local input = {P1 = {}, P2 = {}}
	local player, inp
	for i,v in pairs(joypad.get()) do
		player, inp = i:sub(1,2), i:sub(4)
		if i == "1 Player Start" then
			input.P1["Start"] = v
		end
		if i == "2 Players Start" then
			input.P2["Start"] = v
		end
		if player == "P1" then
			input.P1[inp] = v -- get P1's inputs (be sure to check the inside of joypad.get() and correct the name of input(s) such as menuinput.P1[this])
		end
		if player == "P2" then
			input.P2[inp] = v -- get P2's inputs (be sure to check the inside of joypad.get() and correct the name of input(s) such as menuinput.P1[this])
		end
	end
	return input
end

function setinputs()
	local tempinput = joypad.get()
	--disable input
	function disableinputs(input)
		if not inputconfig.ifdisableinputset[1][inputconfig.ifdisableinputset[2]] then
			return input
		elseif inputconfig.ifdisableinputset[1][inputconfig.ifdisableinputset[2]] then
			local player, inp
			if inputconfig.disableinputplayer[1][inputconfig.disableinputplayer[2]] == "P1" then
				local disableP1input = input
				for i,v in pairs(input) do
					player, inp = i:sub(1,2), i:sub(4)
					if i == "1 Player Start" then
						disableP1input["1 Player Start"] = false
					elseif player == "P1" then
						disableP1input["P1 "..inp] = false
					end
				end
				input = disableP1input
			elseif inputconfig.disableinputplayer[1][inputconfig.disableinputplayer[2]] == "P2" then
				local disableP2input = input
				for i,v in pairs(input) do
					player, inp = i:sub(1,2), i:sub(4)
					if i == "2 Players Start" then
						disableP2input["2 Players Start"] = false
					elseif player == "P2" then
						disableP2input["P2 "..inp] = false
					end
				end
				input = disableP2input
			elseif inputconfig.disableinputplayer[1][inputconfig.disableinputplayer[2]] == "both" then
				local disablebothinput = input
				for i,v in pairs(input) do
					disablebothinput[i] = false
				end
				input = disablebothinput
			end
			return input
		end
	end

	function holdinputs(input)
		if not inputconfig.ifholdinputset[1][inputconfig.ifholdinputset[2]] or inputconfig.holdinputplayer[1][inputconfig.holdinputplayer[2]] == "none"
		or inputconfig.holddirection[1][inputconfig.holddirection[2]] == "neutral" then
			return input
		elseif inputconfig.ifholdinputset[1][inputconfig.ifholdinputset[2]] then
			local holdinput = input
			local inp
			if inputconfig.holddirection[1][inputconfig.holddirection[2]] == "down left" then
				inp = {"Down", "Left"}
			elseif inputconfig.holddirection[1][inputconfig.holddirection[2]] == "down" then
				inp = {"Down"}
			elseif inputconfig.holddirection[1][inputconfig.holddirection[2]] == "down right" then
				inp = {"Down", "Right"}
			elseif inputconfig.holddirection[1][inputconfig.holddirection[2]] == "left" then
				inp = {"Left"}
			elseif inputconfig.holddirection[1][inputconfig.holddirection[2]] == "right" then
				inp = {"Right"}
			elseif inputconfig.holddirection[1][inputconfig.holddirection[2]] == "up left" then
				inp = {"Up", "Left"}
			elseif inputconfig.holddirection[1][inputconfig.holddirection[2]] == "up" then
				inp = {"Up"}
			elseif inputconfig.holddirection[1][inputconfig.holddirection[2]] == "up right" then
				inp = {"Up", "Right"}
			end
			if inputconfig.holdinputplayer[1][inputconfig.holdinputplayer[2]] == "P1" then
				for i = 1, #inp do
					holdinput["P1 "..inp[i]] = true
				end
			elseif inputconfig.holdinputplayer[1][inputconfig.holdinputplayer[2]] == "P2" then
				for i = 1, #inp do
					holdinput["P2 "..inp[i]] = true
				end
			elseif inputconfig.holdinputplayer[1][inputconfig.holdinputplayer[2]] == "both" then
				for i = 1, #inp do
					holdinput["P1 "..inp[i]] = true
					holdinput["P2 "..inp[i]] = true
				end
			end
			input = holdinput
			return input
		end
	end

	function swapinputs(input)
		local swapinput = {}
		if not inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] then
			return input
		elseif inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] then
			local player, inp
			for i,v in pairs(input) do
				player, inp = i:sub(1,2), i:sub(4)
				if i == "1 Player Start" then
					swapinput["2 Players Start"] = v
				elseif i == "2 Players Start" then
					swapinput["1 Player Start"] = v
				elseif player == "P1" then
					swapinput["P2 "..inp] = v
				elseif player == "P2" then
					swapinput["P1 "..inp] = v
				end
			end
			input = swapinput
			return input
		end
	end

	tempinput = disableinputs(tempinput)
	tempinput = holdinputs(tempinput)
	tempinput = swapinputs(tempinput)
	joypad.set(tempinput)
end

---record---*important
--[[under construction...]]

---menu---*important
local function drawmenu()
	local menu, submenu
	if menuconfig.currentmenuselection.page > 0 then
		menu = menuconfig.menupage[menuconfig.currentmenuselection.page]
		if menuconfig.currentmenuselection.subpage > 0 then
			submenu = menuconfig.menupage[menuconfig.currentmenuselection.page].submenupage[menuconfig.currentmenuselection.subpage]
		end
	end
	if menu then
		gui.box(
			menu.boxconfig.boxleft, menu.boxconfig.boxtop, menu.boxconfig.boxleft+menu.boxconfig.boxwidth, menu.boxconfig.boxtop+menu.boxconfig.boxheight,
			menu.boxconfig.bgcolor, menu.boxconfig.frcolor) --draw menu box
		if menu.menutext then
			for i = 1, #menu.menutext do
				gui.text(menu.menutext[i].x, menu.menutext[i].y, menu.menutext[i].text, menu.menutext[i].textcol1, menu.menutext[i].textcol2) -- draw every text in menu table
			end
		end
		if menu.menuoption then
			for i = 1, #menu.menuoption do
				if i == menuconfig.currentmenuselection.option then
					gui.text(menu.menuoption[i].x, menu.menuoption[i].y, menu.menuoption[i].text, menu.menuoption[i].textselectedcol1,  menu.menuoption[i].textselectedcol2) --draw the selected option in menu table
					if menu.menuoption[i].note then
						gui.box((sw-4*#menu.menuoption[i].note-16)/2, menu.boxconfig.boxtop+menu.boxconfig.boxheight+8, (sw+4*#menu.menuoption[i].note+16)/2, menu.boxconfig.boxtop+menu.boxconfig.boxheight+24, menu.boxconfig.notebgcolor, menu.boxconfig.notefrcolor)
						gui.text((sw-4*#menu.menuoption[i].note)/2, menu.boxconfig.boxtop+menu.boxconfig.boxheight+14, menu.menuoption[i].note,  menu.menuoption[i].textnotecol1,  menu.menuoption[i].textnotecol2) --draw the note of the selected option
					end
				else
					gui.text(menu.menuoption[i].x, menu.menuoption[i].y, menu.menuoption[i].text,  menu.menuoption[i].textcol1,  menu.menuoption[i].textcol2) --draw the other option(s) in menu table
				end
			end
		end
		if submenu then
			gui.box(
				submenu.boxconfig.boxleft, submenu.boxconfig.boxtop, submenu.boxconfig.boxleft+submenu.boxconfig.boxwidth,submenu.boxconfig.boxtop+submenu.boxconfig.boxheight, submenu.boxconfig.bgcolor, submenu.boxconfig.frcolor) -- draw submenu box
			if submenu.submenutext then
				for i = 1, #submenu.submenutext do
					gui.text(submenu.submenutext[i].x, submenu.submenutext[i].y, submenu.submenutext[i].text, submenu.submenutext[i].textcol1, submenu.submenutext[i].textcol2) -- draw every text in submenu table
				end
			end
			if submenu.submenuoption then
				for i = 1, #submenu.submenuoption do
					if i == menuconfig.currentmenuselection.suboption then
						gui.text(submenu.submenuoption[i].x, submenu.submenuoption[i].y, submenu.submenuoption[i].text, submenu.submenuoption[i].textselectedcol1, submenu.submenuoption[i].textselectedcol2) --draw the selected option in submenu table
						if submenu.submenuoption[i].note then
							gui.box((sw-4*#submenu.submenuoption[i].note-16)/2, menu.boxconfig.boxtop+menu.boxconfig.boxheight+8, (sw+4*#submenu.submenuoption[i].note+16)/2, menu.boxconfig.boxtop+menu.boxconfig.boxheight+24, submenu.boxconfig.notebgcolor, submenu.boxconfig.notefrcolor)
							gui.text((sw-4*#submenu.submenuoption[i].note)/2, menu.boxconfig.boxtop+menu.boxconfig.boxheight+14, submenu.submenuoption[i].note, submenu.submenuoption[i].textnotecol1, submenu.submenuoption[i].textnotecol2) --draw the note of the selected suboption
						end
					else
						gui.text(submenu.submenuoption[i].x, submenu.submenuoption[i].y, submenu.submenuoption[i].text, submenu.submenuoption[i].textcol1, submenu.submenuoption[i].textcol2) --draw the other option(s) in submenu table
					end
				end
			end
		end
	end
end

local function getmenuinput()
	--get current menu
	local menu, submenu
	if menuconfig.currentmenuselection.page > 0 then
		menu = menuconfig.menupage[menuconfig.currentmenuselection.page]
		if menuconfig.currentmenuselection.subpage > 0 then
			submenu = menuconfig.menupage[menuconfig.currentmenuselection.page].submenupage[menuconfig.currentmenuselection.subpage]
		end
	end
	--get current inputs
	menuconfig.menuinput.P1.currentinput = getinput().P1
	menuconfig.menuinput.P2.currentinput = getinput().P2
	if inputconfig.ifholdinputset[1][inputconfig.ifholdinputset[2]] then
		if not inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] then
			if inputconfig.holdinputplayer[1][inputconfig.holdinputplayer[2]] == "P1" then
				menuconfig.menuinput.P1.currentinput["Up"] = false
				menuconfig.menuinput.P1.currentinput["Down"] = false
				menuconfig.menuinput.P1.currentinput["Left"] = false
				menuconfig.menuinput.P1.currentinput["Right"] = false
			elseif inputconfig.holdinputplayer[1][inputconfig.holdinputplayer[2]] == "P2" then
				menuconfig.menuinput.P2.currentinput["Up"] = false
				menuconfig.menuinput.P2.currentinput["Down"] = false
				menuconfig.menuinput.P2.currentinput["Left"] = false
				menuconfig.menuinput.P2.currentinput["Right"] = false
			end
		elseif inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] then
			if inputconfig.holdinputplayer[1][inputconfig.holdinputplayer[2]] == "P1" then
				menuconfig.menuinput.P2.currentinput["Up"] = false
				menuconfig.menuinput.P2.currentinput["Down"] = false
				menuconfig.menuinput.P2.currentinput["Left"] = false
				menuconfig.menuinput.P2.currentinput["Right"] = false
			elseif inputconfig.holdinputplayer[1][inputconfig.holdinputplayer[2]] == "P2" then
				menuconfig.menuinput.P1.currentinput["Up"] = false
				menuconfig.menuinput.P1.currentinput["Down"] = false
				menuconfig.menuinput.P1.currentinput["Left"] = false
				menuconfig.menuinput.P1.currentinput["Right"] = false
			end
		end
	end
	--menu inputs (open)
	if luaconfig.showmenu[1][luaconfig.showmenu[2]] then
		menuconfig.menuinput.P1.holdstartframe = 0
		menuconfig.menuinput.P2.holdstartframe = 0
		--P1 inputs (open)
		if (menuconfig.menuinput.P1.currentinput["Weak Punch"] and not menuconfig.menuinput.P1.previousinput["Weak Punch"]) or (menuconfig.menuinput.P1.currentinput["Button 1"] and not menuconfig.menuinput.P1.previousinput["Button 1"])
		 or (menuconfig.menuinput.P2.currentinput["Weak Punch"] and not menuconfig.menuinput.P2.previousinput["Weak Punch"]) or (menuconfig.menuinput.P2.currentinput["Button 1"] and not menuconfig.menuinput.P2.previousinput["Button 1"]) then --set the function of button1 in menu page
			if menuconfig.currentmenuselection.subpage == 0 then
				if menu.menuoption then
					if menu.menuoption[menuconfig.currentmenuselection.option].buttonfunc then
						menu.menuoption[menuconfig.currentmenuselection.option].buttonfunc() -- execute the selected option in menu table
					end
				end
			else
				if submenu.submenuoption then
					if submenu.submenuoption[menuconfig.currentmenuselection.suboption].buttonfunc then
						submenu.submenuoption[menuconfig.currentmenuselection.suboption].buttonfunc() -- execute the selected option in submenu table
					end
				end
			end
		end
		if (menuconfig.menuinput.P1.currentinput["Medium Punch"] and not menuconfig.menuinput.P1.previousinput["Medium Punch"]) or (menuconfig.menuinput.P1.currentinput["Button 2"] and not menuconfig.menuinput.P1.previousinput["Button 2"])
		 or (menuconfig.menuinput.P2.currentinput["Medium Punch"] and not menuconfig.menuinput.P2.previousinput["Medium Punch"]) or (menuconfig.menuinput.P2.currentinput["Button 2"] and not menuconfig.menuinput.P2.previousinput["Button 2"]) then --set the function of button1 in menu page
			if menuconfig.currentmenuselection.subpage ~= 0 then
				menuconfig.currentmenuselection.subpage = 0 -- close submenu
			else
				menuconfig.currentmenuselection.option = 1 --close menu
				luaconfig.showmenu[2] = 2
			end
		end
		if (menuconfig.menuinput.P1.currentinput["Start"] and not menuconfig.menuinput.P1.previousinput["Start"]) or (menuconfig.menuinput.P2.currentinput["Start"] and not menuconfig.menuinput.P2.previousinput["Start"]) then --set the function of start in menu page
			if menuconfig.currentmenuselection.subpage == 0 then
				if menu.menuoption then
					if menu.menuoption[menuconfig.currentmenuselection.option].buttonfunc then
						menu.menuoption[menuconfig.currentmenuselection.option].buttonfunc() -- execute the selected option in menu table
					end
				end
			else
				if submenu.submenuoption then
					if submenu.submenuoption[menuconfig.currentmenuselection.suboption].buttonfunc then
						submenu.submenuoption[menuconfig.currentmenuselection.suboption].buttonfunc() -- execute the selected option in submenu table
					end
				end
			end
		end
		if (menuconfig.menuinput.P1.currentinput["Up"] and not menuconfig.menuinput.P1.previousinput["Up"])
		 or (menuconfig.menuinput.P2.currentinput["Up"] and not menuconfig.menuinput.P2.previousinput["Up"]) then --set the function of up in menu page (change the selection of the option)
			if menuconfig.currentmenuselection.subpage == 0 then
				if menu.menuoption then
					menuconfig.currentmenuselection.option = lccalc(menuconfig.currentmenuselection.option, #menu.menuoption, -1)
				end
			else
				if submenu.submenuoption then
					menuconfig.currentmenuselection.suboption = lccalc(menuconfig.currentmenuselection.suboption, #submenu.submenuoption, -1)
				end
			end
		end
		if (menuconfig.menuinput.P1.currentinput["Down"] and not menuconfig.menuinput.P1.previousinput["Down"])
		 or (menuconfig.menuinput.P2.currentinput["Down"] and not menuconfig.menuinput.P2.previousinput["Down"]) then --set the function of up in menu page (change the selection of the option)
			if menuconfig.currentmenuselection.subpage == 0 then
				if menu.menuoption then
					menuconfig.currentmenuselection.option = lccalc(menuconfig.currentmenuselection.option, #menu.menuoption, 1)
				end
			else
				if submenu.submenuoption then
					menuconfig.currentmenuselection.suboption = lccalc(menuconfig.currentmenuselection.suboption, #submenu.submenuoption, 1)
				end
			end
		end
		if (menuconfig.menuinput.P1.currentinput["Left"] and not menuconfig.menuinput.P1.previousinput["Left"])
		 or (menuconfig.menuinput.P2.currentinput["Left"] and not menuconfig.menuinput.P2.previousinput["Left"]) then --set the function of up in menu page (change the selection of the option)
			if menuconfig.currentmenuselection.subpage == 0 then
				if menu.menuoption then
					if menu.menuoption[menuconfig.currentmenuselection.option].leftfunc then
						menu.menuoption[menuconfig.currentmenuselection.option].leftfunc() -- execute the selected option in menu table
					end
				end
			else
				if submenu.submenuoption then
					if submenu.submenuoption[menuconfig.currentmenuselection.suboption].leftfunc then
						submenu.submenuoption[menuconfig.currentmenuselection.suboption].leftfunc() -- execute the selected option in submenu table
					end
				end
			end
		end
		if (menuconfig.menuinput.P1.currentinput["Right"] and not menuconfig.menuinput.P1.previousinput["Right"])
		 or (menuconfig.menuinput.P2.currentinput["Right"] and not menuconfig.menuinput.P2.previousinput["Right"]) then --set the function of up in menu page (change the selection of the option)
			if menuconfig.currentmenuselection.subpage == 0 then
				if menu.menuoption then
					if menu.menuoption[menuconfig.currentmenuselection.option].rightfunc then
						menu.menuoption[menuconfig.currentmenuselection.option].rightfunc() -- execute the selected option in menu table
					end
				end
			else
				if submenu.submenuoption then
					if submenu.submenuoption[menuconfig.currentmenuselection.suboption].rightfunc then
						submenu.submenuoption[menuconfig.currentmenuselection.suboption].rightfunc() -- execute the selected option in submenu table
					end
				end
			end
		end
	--menu inputs (close)
	elseif not luaconfig.showmenu[1][luaconfig.showmenu[2]] then
		--P1 inputs (close)
		if menuconfig.menuinput.P1.currentinput["Start"] and menuconfig.menuinput.P1.previousinput["Start"] then --set the function of holding start
			if menuconfig.menuinput.P1.holdstartframe < 25 then
				menuconfig.menuinput.P1.holdstartframe = menuconfig.menuinput.P1.holdstartframe + 1
			elseif menuconfig.menuinput.P1.holdstartframe == 25 then
				menuconfig.menuinput.P1.holdstartframe = 0
				luaconfig.showmenu[2] = 1
			end
		elseif not menuconfig.menuinput.P1.currentinput["Start"] and menuconfig.menuinput.P1.previousinput["Start"] then
			menuconfig.menuinput.P1.holdstartframe = 0
		end
		--P2 inputs (close)
		if menuconfig.menuinput.P2.currentinput["Start"] and menuconfig.menuinput.P2.previousinput["Start"] then --set the function of holding start
			if menuconfig.menuinput.P2.holdstartframe < 25 then
				menuconfig.menuinput.P2.holdstartframe = menuconfig.menuinput.P2.holdstartframe + 1
			elseif menuconfig.menuinput.P2.holdstartframe == 25 then
				menuconfig.menuinput.P2.holdstartframe = 0
				luaconfig.showmenu[2] = 1
			end
		elseif not menuconfig.menuinput.P2.currentinput["Start"] and menuconfig.menuinput.P2.previousinput["Start"] then
			menuconfig.menuinput.P2.holdstartframe = 0
		end
	end
	--get previous inputs
	menuconfig.menuinput.P1.previousinput = menuconfig.menuinput.P1.currentinput
	menuconfig.menuinput.P2.previousinput = menuconfig.menuinput.P2.currentinput
	--swap previous inputs if needed
	if menuconfig.ifswapped ~= inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] then
		local tempinput = menuconfig.menuinput.P1.previousinput
		menuconfig.menuinput.P1.previousinput = menuconfig.menuinput.P2.previousinput
		menuconfig.menuinput.P2.previousinput = tempinput
	end
	menuconfig.ifswapped = inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]]
end

function displaymenu()
	local cd
	---page 1 (main menu)
	menuconfig.menupage[1] = {}
	cd = menuconfig.menupage[1]
	menuconfig.menupage[1].submenupage = {} --set submenu (if exists)
	menuconfig.menupage[1].boxconfig = { --menu box config
		bgcolor = 0xababbaee,
		frcolor = 0x3d3d5cff,
		notebgcolor = 0xabbabaee,
		notefrcolor = 0x3d5c5cff,
		boxwidth = sw*0.75,
		boxheight = sh*0.75,
		boxleft = (sw-sw*0.75)*0.5,
		boxtop = (sh-sh*0.75)*0.5
	}
	menuconfig.menupage[1].textconfig = { --menu text config
		textleft = cd.boxconfig.boxleft+16,
		texttop = cd.boxconfig.boxtop+16,
		textcol1 = 0xffffffff,
		textcol2 = 0x000000ff,
		textselectedcol1 = 0xb3d9ffff,
		textselectedcol2 = 0x000000ff,
		textnotecol1 = 0xffffffff,
		textnotecol2 = 0x000000ff
	}
	menuconfig.menupage[1].menutext = { -- set menu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "Welcome to Street Fighther: The Movie training lua "..scriptver, textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+16, text = "current ROM: "..emu.gamename().." - "..emu.romname(), textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+32, text = "- manual -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+40, text = " up/down - move the cursor", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+48, text = " left/right - change the selected option", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+56, text = " button1/Start - execute an option", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+64, text = " Start (hold) - open main menu when it is closed", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+72, text = " button2 - close menu / back to main manu", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+88, text = "- menu -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2}
	}
	menuconfig.menupage[1].menuoption = { -- set menu option(s)
		{
			x = cd.textconfig.textleft, y = cd.menutext[#cd.menutext].y+8, text = " basic setting",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 1
				menuconfig.currentmenuselection.subpage = 1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.menutext[#cd.menutext].y+16, text = " cheat setting",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 1
				menuconfig.currentmenuselection.subpage = 3
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.menutext[#cd.menutext].y+32, text = " HUD setting",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 1
				menuconfig.currentmenuselection.subpage = 6
			end
		},
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-32, text = " credit",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 1
				menuconfig.currentmenuselection.subpage = 7
			end
		},
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-24, text = " close menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 1
				luaconfig.showmenu[2] = 2
			end
		}
	}

	---page 1-1 (basic setting 1)
	menuconfig.menupage[1].submenupage[1] = {}
	cd = menuconfig.menupage[1].submenupage[1]
	menuconfig.menupage[1].submenupage[1].boxconfig = { --submenu box config
		bgcolor = 0xc7c7d1ee,
		frcolor = 0x52527aff,
		notebgcolor = 0xc7d1d1ee,
		notefrcolor = 0x527a7aff,
		boxwidth = sw*0.35,
		boxheight = sh*0.60,
		boxleft = (sw-sw*0.35)*0.5+sw*0.10,
		boxtop = (sh-sh*0.60)*0.5
	}
	menuconfig.menupage[1].submenupage[1].textconfig = { --submenu text config
		textleft = cd.boxconfig.boxleft+16,
		texttop = cd.boxconfig.boxtop+8,
		textcol1 = 0xffffffff,
		textcol2 = 0x000000ff,
		textselectedcol1 = 0xb3d9ffff,
		textselectedcol2 = 0x000000ff,
		textnotecol1 = 0xffffffff,
		textnotecol2 = 0x000000ff
	}
	menuconfig.menupage[1].submenupage[1].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- basic setting -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+16, text = "* general", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+40, text = "* Player 1", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+80, text = "* Player 2", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2}
	}
	menuconfig.menupage[1].submenupage[1].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+24, text = "time: "..cheatconfig.time[1][cheatconfig.time[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.time[2] = lccalc(cheatconfig.time[2], #cheatconfig.time[1], -1)
			end,
			rightfunc = function()
				cheatconfig.time[2] = lccalc(cheatconfig.time[2], #cheatconfig.time[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+48, text = "P1health: "..cheatconfig.P1health[1][cheatconfig.P1health[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.P1health[2] = lccalc(cheatconfig.P1health[2], #cheatconfig.P1health[1], -1)
			end,
			rightfunc = function()
				cheatconfig.P1health[2] = lccalc(cheatconfig.P1health[2], #cheatconfig.P1health[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+56, text = "P1meter: "..cheatconfig.P1meter[1][cheatconfig.P1meter[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.P1meter[2] = lccalc(cheatconfig.P1meter[2], #cheatconfig.P1meter[1], -1)
			end,
			rightfunc = function()
				cheatconfig.P1meter[2] = lccalc(cheatconfig.P1meter[2], #cheatconfig.P1meter[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+64, text = "P1stun: "..cheatconfig.P1stun[1][cheatconfig.P1stun[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.P1stun[2] = lccalc(cheatconfig.P1stun[2], #cheatconfig.P1stun[1], -1)
			end,
			rightfunc = function()
				cheatconfig.P1stun[2] = lccalc(cheatconfig.P1stun[2], #cheatconfig.P1stun[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+88, text = "P2health: "..cheatconfig.P2health[1][cheatconfig.P2health[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.P2health[2] = lccalc(cheatconfig.P2health[2], #cheatconfig.P2health[1], -1)
			end,
			rightfunc = function()
				cheatconfig.P2health[2] = lccalc(cheatconfig.P2health[2], #cheatconfig.P2health[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+96, text = "P2meter: "..cheatconfig.P2meter[1][cheatconfig.P2meter[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.P2meter[2] = lccalc(cheatconfig.P2meter[2], #cheatconfig.P2meter[1], -1)
			end,
			rightfunc = function()
				cheatconfig.P2meter[2] = lccalc(cheatconfig.P2meter[2], #cheatconfig.P2meter[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+104, text = "P2stun: "..cheatconfig.P2stun[1][cheatconfig.P2stun[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.P2stun[2] = lccalc(cheatconfig.P2stun[2], #cheatconfig.P2stun[1], -1)
			end,
			rightfunc = function()
				cheatconfig.P2stun[2] = lccalc(cheatconfig.P2stun[2], #cheatconfig.P2stun[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-24, text = "next page",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 7
				menuconfig.currentmenuselection.subpage = 2
			end
		},
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-16, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 1
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	---page 1-2 (basic setting 2)
	menuconfig.menupage[1].submenupage[2] = {}
	cd = menuconfig.menupage[1].submenupage[2]
	menuconfig.menupage[1].submenupage[2].boxconfig = { --submenu box config
		bgcolor = 0xc7c7d1ee,
		frcolor = 0x52527aff,
		notebgcolor = 0xc7d1d1ee,
		notefrcolor = 0x527a7aff,
		boxwidth = sw*0.45,
		boxheight = sh*0.55,
		boxleft = (sw-sw*0.45)*0.5+sw*0.10,
		boxtop = (sh-sh*0.55)*0.5
	}
	menuconfig.menupage[1].submenupage[2].textconfig = { --submenu text config
		textleft = cd.boxconfig.boxleft+16,
		texttop = cd.boxconfig.boxtop+8,
		textcol1 = 0xffffffff,
		textcol2 = 0x000000ff,
		textselectedcol1 = 0xb3d9ffff,
		textselectedcol2 = 0x000000ff,
		textnotecol1 = 0xffffffff,
		textnotecol2 = 0x000000ff
	}
	local menuifswapinput, menuifdisableinput, menuifholdinput = {{"yes", "no"}, 1}, {{"yes", "no"}, 1}, {{"yes", "no"}, 1}
	if inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] == true then
		menuifswapinput[2] = 1
	elseif inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] == false then
		menuifswapinput[2] = 2
	end
	if inputconfig.ifdisableinputset[1][inputconfig.ifdisableinputset[2]] == true then
		menuifdisableinput[2] = 1
	elseif inputconfig.ifdisableinputset[1][inputconfig.ifdisableinputset[2]] == false then
		menuifdisableinput[2] = 2
	end
	if inputconfig.ifholdinputset[1][inputconfig.ifholdinputset[2]] == true then
		menuifholdinput[2] = 1
	elseif inputconfig.ifholdinputset[1][inputconfig.ifholdinputset[2]] == false then
		menuifholdinput[2] = 2
	end
	menuconfig.menupage[1].submenupage[2].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- basic setting -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+16, text = "* input", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
	}
	menuconfig.menupage[1].submenupage[2].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+24, text = "set disable input: "..menuifdisableinput[1][menuifdisableinput[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				inputconfig.ifdisableinputset[2] = lccalc(inputconfig.ifdisableinputset[2], #inputconfig.ifdisableinputset[1], -1)
			end,
			rightfunc = function()
				inputconfig.ifdisableinputset[2] = lccalc(inputconfig.ifdisableinputset[2], #inputconfig.ifdisableinputset[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+32, text = "set player disable input: "..inputconfig.disableinputplayer[1][inputconfig.disableinputplayer[2]], note = "You can't use the selected port to move cursor in menu.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				inputconfig.disableinputplayer[2] = lccalc(inputconfig.disableinputplayer[2], 3, -1)
			end,
			rightfunc = function()
				inputconfig.disableinputplayer[2] = lccalc(inputconfig.disableinputplayer[2], 3, 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+48, text = "set hold input: "..menuifholdinput[1][menuifholdinput[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				inputconfig.ifholdinputset[2] = lccalc(inputconfig.ifholdinputset[2], #inputconfig.ifholdinputset[1], -1)
			end,
			rightfunc = function()
				inputconfig.ifholdinputset[2] = lccalc(inputconfig.ifholdinputset[2], #inputconfig.ifholdinputset[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+56, text = "set player holding input: "..inputconfig.holdinputplayer[1][inputconfig.holdinputplayer[2]], note = "You can't use the selected port to move cursor in menu.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				inputconfig.holdinputplayer[2] = lccalc(inputconfig.holdinputplayer[2], 3, -1)
			end,
			rightfunc = function()
				inputconfig.holdinputplayer[2] = lccalc(inputconfig.holdinputplayer[2], 3, 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+64, text = "set holding direction: "..inputconfig.holddirection[1][inputconfig.holddirection[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				inputconfig.holddirection[2] = lccalc(inputconfig.holddirection[2], #inputconfig.holddirection[1], -1)
			end,
			rightfunc = function()
				inputconfig.holddirection[2] = lccalc(inputconfig.holddirection[2], #inputconfig.holddirection[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+80, text = "swap input: "..menuifswapinput[1][menuifswapinput[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				inputconfig.ifswapinput[2] = lccalc(inputconfig.ifswapinput[2], #inputconfig.ifswapinput[1], -1)
			end,
			rightfunc = function()
				inputconfig.ifswapinput[2] = lccalc(inputconfig.ifswapinput[2], #inputconfig.ifswapinput[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-24, text = "previous page",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 8
				menuconfig.currentmenuselection.subpage = 1
			end
		},
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-16, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 1
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	---page 1-3 (cheat setting 1)
	menuconfig.menupage[1].submenupage[3] = {}
	cd = menuconfig.menupage[1].submenupage[3]
	menuconfig.menupage[1].submenupage[3].boxconfig = { --submenu box config
		bgcolor = 0xc7c7d1ee,
		frcolor = 0x52527aff,
		notebgcolor = 0xc7d1d1ee,
		notefrcolor = 0x527a7aff,
		boxwidth = sw*0.45,
		boxheight = sh*0.40,
		boxleft = (sw-sw*0.45)*0.5+sw*0.05,
		boxtop = (sh-sh*0.40)*0.5
	}
	menuconfig.menupage[1].submenupage[3].textconfig = { --submenu text config
		textleft = cd.boxconfig.boxleft+16,
		texttop = cd.boxconfig.boxtop+8,
		textcol1 = 0xffffffff,
		textcol2 = 0x000000ff,
		textselectedcol1 = 0xb3d9ffff,
		textselectedcol2 = 0x000000ff,
		textnotecol1 = 0xffffffff,
		textnotecol2 = 0x000000ff
	}
	menuconfig.menupage[1].submenupage[3].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- cheat setting 1 -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2}
	}
	menuconfig.menupage[1].submenupage[3].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+16, text = "Disable music: set", note = "Press button1/Start to disable music.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				wb(0x0407, 00)
				wb(0x0408, 02)
				wb(0x0409, 00)
				ww(0x040A, 0000)
				wd(0x040C, 00000000)
				wd(0x0410, 00000000)
				wd(0x0414, 00000000)
				wd(0x0418, 00000000)
				wd(0x041C, 00000000)
				wd(0x0420, 00000000)
				wd(0x0424, 00000000)
			end
		},
		{ --stage modifier (*isuue: "Temple Ruins (Night)",  "Test Stage", and "A.N. Headquarters (Day)" doesn't work correctly)
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+24, text = "Music Modifier: "..cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]], note = "Choose an option in character select screen.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.selectmusic[2] = lccalc(cheatconfig.selectmusic[2], #cheatconfig.selectmusic[1], -1)
			end,
			rightfunc = function()
				cheatconfig.selectmusic[2] = lccalc(cheatconfig.selectmusic[2], #cheatconfig.selectmusic[1], 1)
			end
		},
		{ --stage modifier (*isuue: "Temple Ruins (Night)",  "Test Stage", and "A.N. Headquarters (Day)" doesn't work correctly)
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+40, text = "Stage Modifier: "..cheatconfig.selectstage[1][cheatconfig.selectstage[2]], note = "Choose an option in character select screen.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.selectstage[2] = lccalc(cheatconfig.selectstage[2], #cheatconfig.selectstage[1], -1)
			end,
			rightfunc = function()
				cheatconfig.selectstage[2] = lccalc(cheatconfig.selectstage[2], #cheatconfig.selectstage[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-24, text = "next page",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 21
				menuconfig.currentmenuselection.subpage = 4
			end
		},
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-16, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 2
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	---page 1-4 (cheat setting 2)
	menuconfig.menupage[1].submenupage[4] = {}
	cd = menuconfig.menupage[1].submenupage[4]
	menuconfig.menupage[1].submenupage[4].boxconfig = { --submenu box config
		bgcolor = 0xc7c7d1ee,
		frcolor = 0x52527aff,
		notebgcolor = 0xc7d1d1ee,
		notefrcolor = 0x527a7aff,
		boxwidth = sw*0.60,
		boxheight = sh*0.65,
		boxleft = (sw-sw*0.60)*0.5+sw*0.05,
		boxtop = (sh-sh*0.65)*0.5
	}
	menuconfig.menupage[1].submenupage[4].textconfig = { --submenu text config
		textleft = cd.boxconfig.boxleft+16,
		texttop = cd.boxconfig.boxtop+8,
		textcol1 = 0xffffffff,
		textcol2 = 0x000000ff,
		textselectedcol1 = 0xb3d9ffff,
		textselectedcol2 = 0x000000ff,
		textnotecol1 = 0xffffffff,
		textnotecol2 = 0x000000ff
	}
	menuconfig.menupage[1].submenupage[4].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- cheat setting 2 -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+8, text = "( secret code modifier )", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2}
	}
	menuconfig.menupage[1].submenupage[4].submenuoption = { --set submenu option(s) --editing
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+8, text = "available secret code(s): "..cheatconfig.secretcode.ifsecretcode[1][cheatconfig.secretcode.ifsecretcode[2]], note = "Recommended to change the options in chacacter select screen. (not well tested yet.)",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.ifsecretcode[2] = lccalc(cheatconfig.secretcode.ifsecretcode[2], #cheatconfig.secretcode.ifsecretcode[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.ifsecretcode[2] = lccalc(cheatconfig.secretcode.ifsecretcode[2], #cheatconfig.secretcode.ifsecretcode[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+24, text = "hide meters: "..cheatconfig.secretcode.hidemeters[1][cheatconfig.secretcode.hidemeters[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.hidemeters[2] = lccalc(cheatconfig.secretcode.hidemeters[2], #cheatconfig.secretcode.hidemeters[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.hidemeters[2] = lccalc(cheatconfig.secretcode.hidemeters[2], #cheatconfig.secretcode.hidemeters[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+32, text = "inviso tag: "..cheatconfig.secretcode.invisotag[1][cheatconfig.secretcode.invisotag[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.invisotag[2] = lccalc(cheatconfig.secretcode.invisotag[2], #cheatconfig.secretcode.invisotag[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.invisotag[2] = lccalc(cheatconfig.secretcode.invisotag[2], #cheatconfig.secretcode.invisotag[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+40, text = "no throws: "..cheatconfig.secretcode.nothrows[1][cheatconfig.secretcode.nothrows[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.nothrows[2] = lccalc(cheatconfig.secretcode.nothrows[2], #cheatconfig.secretcode.nothrows[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.nothrows[2] = lccalc(cheatconfig.secretcode.nothrows[2], #cheatconfig.secretcode.nothrows[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+48, text = "no specials: "..cheatconfig.secretcode.nospecials[1][cheatconfig.secretcode.nospecials[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.nospecials[2] = lccalc(cheatconfig.secretcode.nospecials[2], #cheatconfig.secretcode.nospecials[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.nospecials[2] = lccalc(cheatconfig.secretcode.nospecials[2], #cheatconfig.secretcode.nospecials[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+56, text = "special only: "..cheatconfig.secretcode.nospecials[1][cheatconfig.secretcode.specialonly[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.specialonly[2] = lccalc(cheatconfig.secretcode.specialonly[2], #cheatconfig.secretcode.specialonly[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.specialonly[2] = lccalc(cheatconfig.secretcode.specialonly[2], #cheatconfig.secretcode.specialonly[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+64, text = "tag team: "..cheatconfig.secretcode.tagteam[1][cheatconfig.secretcode.tagteam[2]], note = "Only works in character select screen for now.", --(*issue: perhaps setting the rear characters is required.)
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.tagteam[2] = lccalc(cheatconfig.secretcode.tagteam[2], #cheatconfig.secretcode.tagteam[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.tagteam[2] = lccalc(cheatconfig.secretcode.tagteam[2], #cheatconfig.secretcode.tagteam[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+72, text = "double damage: "..cheatconfig.secretcode.doubledamage[1][cheatconfig.secretcode.doubledamage[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.doubledamage[2] = lccalc(cheatconfig.secretcode.doubledamage[2], #cheatconfig.secretcode.doubledamage[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.doubledamage[2] = lccalc(cheatconfig.secretcode.doubledamage[2], #cheatconfig.secretcode.doubledamage[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+80, text = "speed select: "..cheatconfig.secretcode.speedselect[1][cheatconfig.secretcode.speedselect[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.speedselect[2] = lccalc(cheatconfig.secretcode.speedselect[2], #cheatconfig.secretcode.speedselect[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.speedselect[2] = lccalc(cheatconfig.secretcode.speedselect[2], #cheatconfig.secretcode.speedselect[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+88, text = "no blocking: "..cheatconfig.secretcode.noblocking[1][cheatconfig.secretcode.noblocking[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.noblocking[2] = lccalc(cheatconfig.secretcode.noblocking[2], #cheatconfig.secretcode.noblocking[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.noblocking[2] = lccalc(cheatconfig.secretcode.noblocking[2], #cheatconfig.secretcode.noblocking[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+96, text = "combo mode: "..cheatconfig.secretcode.combomode[1][cheatconfig.secretcode.combomode[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.combomode[2] = lccalc(cheatconfig.secretcode.combomode[2], #cheatconfig.secretcode.combomode[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.combomode[2] = lccalc(cheatconfig.secretcode.combomode[2], #cheatconfig.secretcode.combomode[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.5, y = cd.submenutext[#cd.submenutext].y+24, text = "no kicks: "..cheatconfig.secretcode.nokicks[1][cheatconfig.secretcode.nokicks[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.nokicks[2] = lccalc(cheatconfig.secretcode.nokicks[2], #cheatconfig.secretcode.nokicks[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.nokicks[2] = lccalc(cheatconfig.secretcode.nokicks[2], #cheatconfig.secretcode.nokicks[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.5, y = cd.submenutext[#cd.submenutext].y+32, text = "no punches: "..cheatconfig.secretcode.nopunches[1][cheatconfig.secretcode.nopunches[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.nopunches[2] = lccalc(cheatconfig.secretcode.nopunches[2], #cheatconfig.secretcode.nopunches[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.nopunches[2] = lccalc(cheatconfig.secretcode.nopunches[2], #cheatconfig.secretcode.nopunches[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.5, y = cd.submenutext[#cd.submenutext].y+40, text = "strobe mode: "..cheatconfig.secretcode.strobemode[1][cheatconfig.secretcode.strobemode[2]], note = "NOT recommended to turn this on. (causing awful flashing)",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.strobemode[2] = lccalc(cheatconfig.secretcode.strobemode[2], #cheatconfig.secretcode.strobemode[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.strobemode[2] = lccalc(cheatconfig.secretcode.strobemode[2], #cheatconfig.secretcode.strobemode[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.5, y = cd.submenutext[#cd.submenutext].y+48, text = "invisibility: "..cheatconfig.secretcode.invisibility[1][cheatconfig.secretcode.invisibility[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.invisibility[2] = lccalc(cheatconfig.secretcode.invisibility[2], #cheatconfig.secretcode.invisibility[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.invisibility[2] = lccalc(cheatconfig.secretcode.invisibility[2], #cheatconfig.secretcode.invisibility[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.5, y = cd.submenutext[#cd.submenutext].y+56, text = "classic throws: "..cheatconfig.secretcode.classicthrows[1][cheatconfig.secretcode.classicthrows[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.classicthrows[2] = lccalc(cheatconfig.secretcode.classicthrows[2], #cheatconfig.secretcode.classicthrows[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.classicthrows[2] = lccalc(cheatconfig.secretcode.classicthrows[2], #cheatconfig.secretcode.classicthrows[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.5, y = cd.submenutext[#cd.submenutext].y+64, text = "programmer level: "..cheatconfig.secretcode.programmerlevel[1][cheatconfig.secretcode.programmerlevel[2]], note = "Only works in character select screen.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.programmerlevel[2] = lccalc(cheatconfig.secretcode.programmerlevel[2], #cheatconfig.secretcode.programmerlevel[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.programmerlevel[2] = lccalc(cheatconfig.secretcode.programmerlevel[2], #cheatconfig.secretcode.programmerlevel[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.5, y = cd.submenutext[#cd.submenutext].y+72, text = "inverted: "..cheatconfig.secretcode.inverted[1][cheatconfig.secretcode.inverted[2]], note = "Only works in character select screen.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.inverted[2] = lccalc(cheatconfig.secretcode.inverted[2], #cheatconfig.secretcode.inverted[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.inverted[2] = lccalc(cheatconfig.secretcode.inverted[2], #cheatconfig.secretcode.inverted[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.5, y = cd.submenutext[#cd.submenutext].y+80, text = "reverse controls: "..cheatconfig.secretcode.reversecontrols[1][cheatconfig.secretcode.reversecontrols[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.reversecontrols[2] = lccalc(cheatconfig.secretcode.reversecontrols[2], #cheatconfig.secretcode.reversecontrols[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.reversecontrols[2] = lccalc(cheatconfig.secretcode.reversecontrols[2], #cheatconfig.secretcode.reversecontrols[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.5, y = cd.submenutext[#cd.submenutext].y+88, text = "swap players: "..cheatconfig.secretcode.swapplayers[1][cheatconfig.secretcode.swapplayers[2]], note = "Only works in character select screen.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.secretcode.swapplayers[2] = lccalc(cheatconfig.secretcode.swapplayers[2], #cheatconfig.secretcode.swapplayers[1], -1)
			end,
			rightfunc = function()
				cheatconfig.secretcode.swapplayers[2] = lccalc(cheatconfig.secretcode.swapplayers[2], #cheatconfig.secretcode.swapplayers[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-24, text = "previous page",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 4
				menuconfig.currentmenuselection.subpage = 3
			end
		},
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-16, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 2
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	---page 1-5 (record setting)
	menuconfig.menupage[1].submenupage[5] = {}
	cd = menuconfig.menupage[1].submenupage[5]
	menuconfig.menupage[1].submenupage[5].boxconfig = { --submenu box config
		bgcolor = 0xc7c7d1ee,
		frcolor = 0x52527aff,
		notebgcolor = 0xc7d1d1ee,
		notefrcolor = 0x527a7aff,
		boxwidth = sw*0.40,
		boxheight = sh*0.65,
		boxleft = (sw-sw*0.40)*0.5+sw*0.05,
		boxtop = (sh-sh*0.65)*0.5
	}
	menuconfig.menupage[1].submenupage[5].textconfig = { --submenu text config
		textleft = cd.boxconfig.boxleft+16,
		texttop = cd.boxconfig.boxtop+8,
		textcol1 = 0xffffffff,
		textcol2 = 0x000000ff,
		textselectedcol1 = 0xb3d9ffff,
		textselectedcol2 = 0x000000ff,
		textnotecol1 = 0xffffffff,
		textnotecol2 = 0x000000ff
	}
	menuconfig.menupage[1].submenupage[5].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- record setting -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+8, text = "* under construction...", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2}
	}
	menuconfig.menupage[1].submenupage[5].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-16, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 3
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	---page 1-6 (HUD setting)
	menuconfig.menupage[1].submenupage[6] = {}
	cd = menuconfig.menupage[1].submenupage[6]
	menuconfig.menupage[1].submenupage[6].boxconfig = { --submenu box config
		bgcolor = 0xc7c7d1ee,
		frcolor = 0x52527aff,
		notebgcolor = 0xc7d1d1ee,
		notefrcolor = 0x527a7aff,
		boxwidth = sw*0.35,
		boxheight = sh*0.35,
		boxleft = (sw-sw*0.40)*0.5+sw*0.10,
		boxtop = (sh-sh*0.35)*0.5
	}
	menuconfig.menupage[1].submenupage[6].textconfig = { --submenu text config
		textleft = cd.boxconfig.boxleft+16,
		texttop = cd.boxconfig.boxtop+8,
		textcol1 = 0xffffffff,
		textcol2 = 0x000000ff,
		textselectedcol1 = 0xb3d9ffff,
		textselectedcol2 = 0x000000ff,
		textnotecol1 = 0xffffffff,
		textnotecol2 = 0x000000ff
	}
	local menuifshowhud, menuifshowinput = {{"yes", "no"}, 1}, {{"yes", "no"}, 1}
	if luaconfig.showhud[1][luaconfig.showhud[2]] == true then
		menuifshowhud[2] = 1
	elseif luaconfig.showhud[1][luaconfig.showhud[2]] == false then
		menuifshowhud[2] = 2
	end
	if luaconfig.showinput[1][luaconfig.showinput[2]] == true then
		menuifshowinput[2] = 1
	elseif luaconfig.showinput[1][luaconfig.showinput[2]] == false then
		menuifshowinput[2] = 2
	end
	menuconfig.menupage[1].submenupage[6].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- HUD setting -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
	}
	menuconfig.menupage[1].submenupage[6].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+16, text = "show HUD: "..menuifshowhud[1][menuifshowhud[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				luaconfig.showhud[2] = lccalc(luaconfig.showhud[2], #luaconfig.showhud[1], -1)
			end,
			rightfunc = function()
				luaconfig.showhud[2] = lccalc(luaconfig.showhud[2], #luaconfig.showhud[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+32, text = "show input: "..menuifshowinput[1][menuifshowinput[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				luaconfig.showinput[2] = lccalc(luaconfig.showinput[2], #luaconfig.showinput[1], -1)
			end,
			rightfunc = function()
				luaconfig.showinput[2] = lccalc(luaconfig.showinput[2], #luaconfig.showinput[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+40, text = "HUD style: "..hudconfig.hudstyle[1][hudconfig.hudstyle[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				hudconfig.hudstyle[2] = lccalc(hudconfig.hudstyle[2], #hudconfig.hudstyle[1], -1)
			end,
			rightfunc = function()
				hudconfig.hudstyle[2] = lccalc(hudconfig.hudstyle[2], #hudconfig.hudstyle[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-16, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 3
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	---page 1-7 (credit)
	menuconfig.menupage[1].submenupage[7] = {}
	cd = menuconfig.menupage[1].submenupage[7]
	menuconfig.menupage[1].submenupage[7].boxconfig = { --subpage box config
		bgcolor = 0xc7c7d1ee,
		frcolor = 0x52527aff,
		notebgcolor = 0xc7d1d1ee,
		notefrcolor = 0x527a7aff,
		boxwidth = sw*0.70,
		boxheight = sh*0.50,
		boxleft = (sw-sw*0.70)*0.5,
		boxtop = (sh-sh*0.50)*0.5
	}
	menuconfig.menupage[1].submenupage[7].textconfig = { --subpage text config
		textleft = cd.boxconfig.boxleft+16,
		texttop = cd.boxconfig.boxtop+16,
		textcol1 = 0xffffffff,
		textcol2 = 0x000000ff,
		textselectedcol1 = 0xb3d9ffff,
		textselectedcol2 = 0x000000ff,
		textnotecol1 = 0xffffffff,
		textnotecol2 = 0x000000ff
	}
	menuconfig.menupage[1].submenupage[7].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- credit -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+8, text = "This script is written by invitroFG.", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+24, text = "I am deeply grateful to the scripts and writers inspire me.", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+32, text = "- fbneo-training-mode by Peon2", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+40, text = "- input-display by Dammit", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+56, text = "Shout out to SFTM discord for their dedication to this game.", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+64, text = "(URL - https://discord.io/SFTM)", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
	}
	menuconfig.menupage[1].submenupage[7].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-24, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 4
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	---page 1-9 (lua setting) *for debug
	menuconfig.menupage[1].submenupage[9] = {}
	cd = menuconfig.menupage[1].submenupage[9]
	menuconfig.menupage[1].submenupage[9].boxconfig = { --subpage box config
		bgcolor = 0xc7c7d1ee,
		frcolor = 0x52527aff,
		notebgcolor = 0xc7d1d1ee,
		notefrcolor = 0x527a7aff,
		boxwidth = sw*0.30,
		boxheight = sh*0.35,
		boxleft = (sw-sw*0.30)*0.5,
		boxtop = (sh-sh*0.35)*0.5
	}
	menuconfig.menupage[1].submenupage[9].textconfig = { --subpage text config
		textleft = cd.boxconfig.boxleft+16,
		texttop = cd.boxconfig.boxtop+8,
		textcol1 = 0xffffffff,
		textcol2 = 0x000000ff,
		textselectedcol1 = 0xb3d9ffff,
		textselectedcol2 = 0x000000ff,
		textnotecol1 = 0xffffffff,
		textnotecol2 = 0x000000ff
	}
	menuconfig.menupage[1].submenupage[9].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- lua config -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+8, text = "* for debug", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2}
	}
	menuconfig.menupage[1].submenupage[9].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+16, text = "showhud: "..tostring(luaconfig.showhud[1][luaconfig.showhud[2]]),
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				luaconfig.showhud[2] = lccalc(luaconfig.showhud[2], #luaconfig.showhud[1], -1)
			end,
			rightfunc = function()
				luaconfig.showhud[2] = lccalc(luaconfig.showhud[2], #luaconfig.showhud[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+24, text = "showinput: "..tostring(luaconfig.showinput[1][luaconfig.showinput[2]]),
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				luaconfig.showinput[2] = lccalc(luaconfig.showinput[2], #luaconfig.showinput[1], -1)
			end,
			rightfunc = function()
				luaconfig.showinput[2] = lccalc(luaconfig.showinput[2], #luaconfig.showinput[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+32, text = "availablecheat: "..tostring(luaconfig.availablecheat[1][luaconfig.availablecheat[2]]),
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				luaconfig.availablecheat[2] = lccalc(luaconfig.availablecheat[2], #luaconfig.availablecheat[1], -1)
			end,
			rightfunc = function()
				luaconfig.availablecheat[2] = lccalc(luaconfig.availablecheat[2], #luaconfig.availablecheat[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-16, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 1
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	---drawing
	getmenuinput()
	if luaconfig.showmenu[1][luaconfig.showmenu[2]] then
		drawmenu()
	end
end

---HUD---*important
function displayhud()
	--address viewer
	local addrcol = { --colors for drawing address
		on1  = 0xeeeeeedd, --color_on_inside
		on2  = 0x101010dd, --colo_on_border
		off1 = 0xa0a0a0c0, --color_off_inside
		off2 = 0x101010c0, --color_off_border
	}
	if not luaconfig.showhud[1][luaconfig.showhud[2]] then
		return
	end
	local addrtext = {simple = {}, detailed = {}, debug = {}}
	--setting for simple style
	if hudconfig.hudstyle[1][hudconfig.hudstyle[2]] == "detailed" or hudconfig.hudstyle[1][hudconfig.hudstyle[2]] == "simple" or hudconfig.hudstyle[1][hudconfig.hudstyle[2]] == "debug" then
		--P1 texts for simple style
		if rb(addr.P1health) ==255 then --simple: P1 health (death state should be added)
			P1status.health = -1
		else
			P1status.health = rb(addr.P1health)
		end
		table.insert(addrtext.simple, #addrtext.simple+1, {x=94, y=34, text = "P1 health: "..P1status.health, textcol1 = addrcol.on1, textcol2 = addrcol.on2})
		P1status.meter = rb(addr.P1meter) --simple: P1 meter
		table.insert(addrtext.simple, #addrtext.simple+1, {x=94, y=42, text = "P1 meter: "..P1status.meter, textcol1 = addrcol.on1, textcol2 = addrcol.on2})
		P1status.dizzyvalue = rbs(addr.P1dizzyvalue) --simple: P1 stun
		if rb(addr.P1dizzy) == 0 then
			P1status.dizzystate[2] = 1
			table.insert(addrtext.simple, #addrtext.simple+1, {x=94, y=50, text = "P1 stun: "..P1status.dizzyvalue, textcol1 = addrcol.on1, textcol2 = addrcol.on2})
		else
			if rb(addr.P1dizzy) == 1 then
				P1status.dizzystate[2] = 2
			elseif rb(addr.P1dizzy) == 2 then
				P1status.dizzystate[2] = 3
			else
			P1status.dizzystate[2] = 4
			end
			table.insert(addrtext.simple, #addrtext.simple+1, {x=94, y=50, text = "P1 stun: "..P1status.dizzyvalue.." ("..P1status.dizzystate[1][P1status.dizzystate[2]]..")", textcol1 = addrcol.on1, textcol2 = addrcol.on2})
		end
		--P2 texts for simple style
		if rb(addr.P2health) ==255 then --simple: P2 health (death state should be added)
			P2status.health = -1
		else
			P2status.health = rb(addr.P2health)
		end
		table.insert(addrtext.simple, #addrtext.simple+1, {x=236, y=34, text = "P2 health: "..P2status.health, textcol1 = addrcol.on1, textcol2 = addrcol.on2})
		P2status.meter = rb(addr.P2meter) --simple: P2 meter
		table.insert(addrtext.simple, #addrtext.simple+1, {x=236, y=42, text = "P2 meter: "..P2status.meter, textcol1 = addrcol.on1, textcol2 = addrcol.on2})
		P2status.dizzyvalue = rbs(addr.P2dizzyvalue) --simple: P2 stun
		if rb(addr.P2dizzy) == 0 then
			P2status.dizzystate[2] = 1
			table.insert(addrtext.simple, #addrtext.simple+1, {x=236, y=50, text = "P2 stun: "..P2status.dizzyvalue, textcol1 = addrcol.on1, textcol2 = addrcol.on2})
		else
			if rb(addr.P2dizzy) == 1 then
				P2status.dizzystate[2] = 2
			elseif rb(addr.P2dizzy) == 2 then
				P2status.dizzystate[2] = 3
			else
			P2status.dizzystate[2] = 4
			end
			table.insert(addrtext.simple, #addrtext.simple+1, {x=236, y=50, text = "P2 stun: "..P2status.dizzyvalue.." ("..P2status.dizzystate[1][P2status.dizzystate[2]]..")", textcol1 = addrcol.on1, textcol2 = addrcol.on2})
		end
		--draw the texts for simple style
		if addrtext.simple then
			for i = 1, #addrtext.simple do
				gui.text(addrtext.simple[i].x, addrtext.simple[i].y, addrtext.simple[i].text, addrtext.simple[i].textcol1, addrtext.simple[i].textcol2) -- draw every text in simple table
			end
		end
		--setting for detailed style
		if hudconfig.hudstyle[1][hudconfig.hudstyle[2]] == "detailed" or hudconfig.hudstyle[1][hudconfig.hudstyle[2]] == "debug" then
			--general text for detailed style
			table.insert(addrtext.detailed, #addrtext.detailed+1, {x=4, y=72, text = "distance: "..rw(0x747A), textcol1 = addrcol.on1, textcol2 = addrcol.on2})
			--P1 texts for detailed style
			if P2status.previousdizzy == 0 and rb(addr.P2dizzy) == 2 then --detailed: P1 combo counter
				P2status.ifdizzy[2] = 1
			elseif rb(addr.P1combocounter) == 0 and rb(addr.P2dizzy) == 0 and P2status.ifdizzy[1][P2status.ifdizzy[2]] == true then
				P2status.ifdizzy[2] = 2
			end
			if P2status.health ~= -1 then
				if rb(addr.P1combocounter) == 0 and rb(addr.P2dizzy) ~= 2 and P2status.ifdizzy[1][P2status.ifdizzy[2]] == false then
					P2status.healthbeforecomboed[1], P2status.healthbeforecomboed[2] = P2status.health, P2status.health
				elseif rb(addr.P1combocounter) ~= 0 and rb(addr.P2dizzy) ~= 2 and P2status.ifdizzy[1][P2status.ifdizzy[2]] == false then
					P1status.combocounter[2], P1status.combodamage[2] = 0, 0
					P1status.combocounter[1] = rb(addr.P1combocounter)
				  P1status.combodamage[1] = P2status.healthbeforecomboed[1] - P2status.health
				elseif rb(addr.P1combocounter) ~= 0 and rb(addr.P2dizzy) == 2 and P2status.ifdizzy[1][P2status.ifdizzy[2]] == true then
					P1status.combocounter[1] = rb(addr.P1combocounter)
					P1status.combodamage[1] = P2status.healthbeforecomboed[1] - P2status.health
				elseif rb(addr.P1combocounter) == 0 and rb(addr.P2dizzy) == 2 and P2status.ifdizzy[1][P2status.ifdizzy[2]] then
					P2status.healthbeforecomboed[2] = P2status.health
				  P1status.combodamage[1] = P2status.healthbeforecomboed[1] - P2status.health
				elseif rb(addr.P1combocounter) ~= 0 and rb(addr.P2dizzy) == 0 and P2status.ifdizzy[1][P2status.ifdizzy[2]] == true then
					P1status.combocounter[2] = rb(addr.P1combocounter)
					P1status.combodamage[2] = P2status.healthbeforecomboed[2] - P2status.health
				end
			elseif P2status.health == -1 then -- (*issue: the address showing dizzy+stand stete is required to polish this)
				if P1status.combocounter[2]  == 0 then
					P1status.combocounter[1] = rb(addr.P1combocounter)
					P1status.combodamage[1] = P2status.healthbeforecomboed[1] - P2status.health
				elseif P1status.combocounter[2]  ~= 0 then
					P1status.combocounter[2] = rb(addr.P1combocounter)
					P1status.combodamage[2] = P2status.healthbeforecomboed[2] - P2status.health
				end
			end
			table.insert(addrtext.detailed, #addrtext.detailed+1, {x=4, y=88, text = "P1 combo: "..P1status.combocounter[1].."+"..P1status.combocounter[2].." (dmg: "..P1status.combodamage[1].."+"..P1status.combodamage[2]..")", textcol1 = addrcol.on1, textcol2 = addrcol.on2})
			P2status.previousdizzy = rb(addr.P2dizzy)
			if rb(addr.P1prjinv) == 0 then --detailed: P1 reflect/invul against prjectiles
				P1status.prjinvstate[2] = 1
			elseif rb(addr.P1prjinv) == 1 then
				P1status.prjinvstate[2] = 2
			elseif rb(addr.P1prjinv) == 2 then
				P1status.prjinvstate[2] = 3
			else
				P1status.prjinvstate[2] = 4
			end
			table.insert(addrtext.detailed, #addrtext.detailed+1, {x=4, y=96, text = "P1 vs. prj: "..P1status.prjinvstate[1][P1status.prjinvstate[2]], textcol1 = addrcol.on1, textcol2 = addrcol.on2})
			if rb(addr.P1armor) == 0 then --detailed: P1 armor
				P1status.armorstate[2] = 1
			elseif rb(addr.P1armor) == 1 or 2 then
				P1status.armorstate[2] = 2
			else
				P1status.armorstate[2] = 3
			end
			table.insert(addrtext.detailed, #addrtext.detailed+1, {x=4, y=104, text = "P1 armor: "..P1status.armorstate[1][P1status.armorstate[2]], textcol1 = addrcol.on1, textcol2 = addrcol.on2})
			local P1charge = { --P1 charge (not polished, esp some value only CPU uses)
				{"LP", addr.P1chargeLP, 0, 0}, {"MP", addr.P1chargeMP, 8, 0}, {"HP", addr.P1chargeHP, 16, 0},
				{"LK", addr.P1chargeLK, 0, 8}, {"MK", addr.P1chargeMK, 8, 8}, {"HK", addr.P1chargeHK, 16, 8},
				{"h", addr.P1chargehol, 24, 0}, {"v", addr.P1chargever, 24, 8}}
			table.insert(addrtext.detailed, #addrtext.detailed+1, {x=4, y=112, text = "P1 charge: ", textcol1 = addrcol.on1, textcol2 = addrcol.on2})
			for v=1,8 do
				if v <= 6 then
					if math.floor((basenconvert(rb(addr.P1releasebutton),2)/(10^(v-1)))%10) == 1 then
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P1charge[v][3], y=112+P1charge[v][4], text = P1charge[v][1], textcol1 = 0x80ffffd0, textcol2 = addrcol.on2})
					elseif rb(P1charge[v][2]) < 60 then
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P1charge[v][3], y=112+P1charge[v][4], text = P1charge[v][1], textcol1 = addrcol.off1, textcol2 = addrcol.off2})
					elseif rb(P1charge[v][2]) == 60 then
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P1charge[v][3], y=112+P1charge[v][4], text = P1charge[v][1], textcol1 = 0x66ffb3c0, textcol2 = addrcol.on2})
					else
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P1charge[v][3], y=112+P1charge[v][4], text = "? ", textcol1 = addrcol.off1, textcol2 = addrcol.off2})
					end
				elseif v > 6 then
					if rb(P1charge[v][2]) < 41 then
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P1charge[v][3], y=112+P1charge[v][4], text = P1charge[v][1], textcol1 = addrcol.off1, textcol2 = addrcol.off2})
					elseif rb(P1charge[v][2]) == 41 then
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P1charge[v][3], y=112+P1charge[v][4], text = P1charge[v][1], textcol1 = 0x66ffb3c0, textcol2 = addrcol.on2})
					else
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P1charge[v][3], y=112+P1charge[v][4], text = "? ", textcol1 = addrcol.off1, textcol2 = addrcol.off2})
					end
				end
			end
			--P2 texts for detailed style
			if P1status.previousdizzy == 0 and rb(addr.P1dizzy) == 2 then --detailed: P2 combo counter
				P1status.ifdizzy[2] = 1
			elseif rb(addr.P2combocounter) == 0 and rb(addr.P1dizzy) == 0 and P1status.ifdizzy[1][P1status.ifdizzy[2]] == true then
				P1status.ifdizzy[2] = 2
			end
			if P1status.health ~= -1 then
				if rb(addr.P2combocounter) == 0 and rb(addr.P1dizzy) ~= 2 and P1status.ifdizzy[1][P1status.ifdizzy[2]] == false then
					P1status.healthbeforecomboed[1], P1status.healthbeforecomboed[2] = P1status.health, P1status.health
				elseif rb(addr.P2combocounter) ~= 0 and rb(addr.P1dizzy) ~= 2 and P1status.ifdizzy[1][P1status.ifdizzy[2]] == false then
					P2status.combocounter[2], P2status.combodamage[2] = 0, 0
					P2status.combocounter[1] = rb(addr.P2combocounter)
					P2status.combodamage[1] = P1status.healthbeforecomboed[1] - P1status.health
				elseif rb(addr.P2combocounter) ~= 0 and rb(addr.P1dizzy) == 2 and P1status.ifdizzy[1][P1status.ifdizzy[2]] == true then
					P2status.combocounter[1] = rb(addr.P2combocounter)
					P2status.combodamage[1] = P1status.healthbeforecomboed[1] - P1status.health
				elseif rb(addr.P2combocounter) == 0 and rb(addr.P1dizzy) == 2 and P1status.ifdizzy[1][P1status.ifdizzy[2]] == true then
					P1status.healthbeforecomboed[2] = P1status.health
					P2status.combodamage[1] = P1status.healthbeforecomboed[1] - P1status.health
				elseif rb(addr.P2combocounter) ~= 0 and rb(addr.P1dizzy) == 0 and P1status.ifdizzy[1][P1status.ifdizzy[2]] == true then
					P2status.combocounter[2] = rb(addr.P2combocounter)
					P2status.combodamage[2] = P1status.healthbeforecomboed[2] - P1status.health
				end
			elseif P1status.health == -1 then -- (*issue: the address showing dizzy+stand stete is required to polish this)
				if P1status.combocounter[2]  == 0 then
					P1status.combocounter[1] = rb(addr.P1combocounter)
					P1status.combodamage[1] = P2status.healthbeforecomboed[1] - P2status.health
				elseif P1status.combocounter[2]  ~= 0 then
					P1status.combocounter[2] = rb(addr.P1combocounter)
					P1status.combodamage[2] = P2status.healthbeforecomboed[2] - P2status.health
				end
			end
			table.insert(addrtext.detailed, #addrtext.detailed+1, {x=4, y=136, text = "P2 combo: "..P2status.combocounter[1].."+"..P2status.combocounter[2].." (dmg: "..P2status.combodamage[1].."+"..P2status.combodamage[2]..")", textcol1 = addrcol.on1, textcol2 = addrcol.on2})
			P1status.previousdizzy = rb(addr.P1dizzy)
			if rb(addr.P2prjinv) == 0 then --detailed: P2 reflect/invul against prjectiles
				P2status.prjinvstate[2] = 1
			elseif rb(addr.P2prjinv) == 1 then
				P2status.prjinvstate[2] = 2
			elseif rb(addr.P2prjinv) == 2 then
				P2status.prjinvstate[2] = 3
			else
				P2status.prjinvstate[2] = 4
			end
			table.insert(addrtext.detailed, #addrtext.detailed+1, {x=4, y=144, text = "P2 vs. prj: "..P2status.prjinvstate[1][P2status.prjinvstate[2]], textcol1 = addrcol.on1, textcol2 = addrcol.on2})
			if rb(addr.P2armor) == 0 then --detailed: P2 armor
				P2status.armorstate[2] = 1
			elseif rb(addr.P2armor) == 1 or 2 then
				P2status.armorstate[2] = 2
			else
				P2status.armorstate[2] = 3
			end
			table.insert(addrtext.detailed, #addrtext.detailed+1, {x=4, y=152, text = "P2 armor: "..P2status.armorstate[1][P2status.armorstate[2]], textcol1 = addrcol.on1, textcol2 = addrcol.on2})
			local P2charge = { --P2 charge (not polished, esp some value only CPU uses)
				{"LP", addr.P2chargeLP, 0, 0}, {"MP", addr.P2chargeMP, 8, 0}, {"HP", addr.P2chargeHP, 16, 0},
				{"LK", addr.P2chargeLK, 0, 8}, {"MK", addr.P2chargeMK, 8, 8}, {"HK", addr.P2chargeHK, 16, 8},
				{"h", addr.P2chargehol, 24, 0}, {"v", addr.P2chargever, 24, 8}}
			table.insert(addrtext.detailed, #addrtext.detailed+1, {x=4, y=160, text = "P2 charge: ", textcol1 = addrcol.on1, textcol2 = addrcol.on2})
			for v=1,8 do
				if v <= 6 then
					if math.floor((basenconvert(rb(addr.P2releasebutton),2)/(10^(v-1)))%10) == 1 then
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P2charge[v][3], y=160+P2charge[v][4], text = P2charge[v][1], textcol1 = 0x80ffffd0, textcol2 = addrcol.on2})
					elseif rb(P2charge[v][2]) < 60 then
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P2charge[v][3], y=160+P2charge[v][4], text = P2charge[v][1], textcol1 = addrcol.off1, textcol2 = addrcol.off2})
					elseif rb(P2charge[v][2]) == 60 then
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P2charge[v][3], y=160+P2charge[v][4], text = P2charge[v][1], textcol1 = 0x66ffb3c0, textcol2 = addrcol.on2})
					else
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P2charge[v][3], y=160+P2charge[v][4], text = "? ", textcol1 = addrcol.off1, textcol2 = addrcol.off2})
					end
				elseif v > 6 then
					if rb(P2charge[v][2]) < 41 then
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P2charge[v][3], y=160+P2charge[v][4], text = P2charge[v][1], textcol1 = addrcol.off1, textcol2 = addrcol.off2})
					elseif rb(P2charge[v][2]) == 41 then
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P2charge[v][3], y=160+P2charge[v][4], text = P2charge[v][1], textcol1 = 0x66ffb3c0, textcol2 = addrcol.on2})
					else
						table.insert(addrtext.detailed, #addrtext.detailed+1, {x=46+P2charge[v][3], y=160+P2charge[v][4], text = "? ", textcol1 = addrcol.off1, textcol2 = addrcol.off2})
					end
				end
			end
			--draw the texts for detailed style
			if addrtext.detailed then
				for i = 1, #addrtext.detailed do
					gui.text(addrtext.detailed[i].x, addrtext.detailed[i].y, addrtext.detailed[i].text, addrtext.detailed[i].textcol1, addrtext.detailed[i].textcol2) -- draw every text in detailed table
				end
			end
			--setting for debug style
			if hudconfig.hudstyle[1][hudconfig.hudstyle[2]] == "debug" then
				--texts for debug style
				table.insert(addrtext.debug, #addrtext.debug+1, {x=4, y=184, text = "0x70EE_0x70EF: "..rbs(0x70EE).."_"..rbs(0x70EF), textcol1 = addrcol.on1, textcol2 = addrcol.on2}) --P1 animation
				table.insert(addrtext.debug, #addrtext.debug+1, {x=4, y=192, text = "0x72B0_0x72B1: "..rbs(0x72B0).."_"..rbs(0x72B1), textcol1 = addrcol.on1, textcol2 = addrcol.on2}) --P2 animation
				--draw the texts for detbug style
				if addrtext.debug then
					for i = 1, #addrtext.debug do
						gui.text(addrtext.debug[i].x, addrtext.debug[i].y, addrtext.debug[i].text, addrtext.debug[i].textcol1, addrtext.debug[i].textcol2) -- draw every text in detailed table
					end
				end
			end
		end
	end
	--input viewer(from input-display.lua by Dammit)
	local inp = {}
	local x, dx, y, dy = 0x08, 0x128, 0xE0, 0x0
	for n = 1, 2 do
		inp[n.."^" ] = {x+dx*(n-1)+0x18, y+dy*(n-1)+0x0, "P"..n.." Up"}
		inp[n.."v" ] = {x+dx*(n-1)+0x18, y+dy*(n-1)+0x8, "P"..n.." Down"}
		inp[n.."<" ] = {x+dx*(n-1)+0x10, y+dy*(n-1)+0x4, "P"..n.." Left"}
		inp[n..">" ] = {x+dx*(n-1)+0x20, y+dy*(n-1)+0x4, "P"..n.." Right"}
		inp[n.."LP"] = {x+dx*(n-1)+0x30, y+dy*(n-1)+0x0, "P"..n.." Weak Punch",   "P"..n.." Button 1"}
		inp[n.."MP"] = {x+dx*(n-1)+0x38, y+dy*(n-1)+0x0, "P"..n.." Medium Punch", "P"..n.." Button 2"}
		inp[n.."HP"] = {x+dx*(n-1)+0x40, y+dy*(n-1)+0x0, "P"..n.." Strong Punch", "P"..n.." Button 3"}
		inp[n.."LK"] = {x+dx*(n-1)+0x30, y+dy*(n-1)+0x8, "P"..n.." Weak Kick",    "P"..n.." Button 4"}
		inp[n.."MK"] = {x+dx*(n-1)+0x38, y+dy*(n-1)+0x8, "P"..n.." Medium Kick",  "P"..n.." Button 5"}
		inp[n.."HK"] = {x+dx*(n-1)+0x40, y+dy*(n-1)+0x8, "P"..n.." Strong Kick",  "P"..n.." Button 6"}
		inp[n.."S" ] = {x+dx*(n-1)+0x00, y+dy*(n-1)+0x0, "P"..n.." Start",        n..(n==1 and " Player" or " Players").." Start"}
		inp[n.."c" ] = {x+dx*(n-1)+0x00, y+dy*(n-1)+0x8, "P"..n.." Coin",         "Coin "..n}
	end
	local inpcol = { --colors for drawing input
		on1  = 0xccff33d0, --pressed: yellow inside
		on2  = 0x000000d0, --pressed: black border
		off1 = 0xffffff60, --unpressed: mostly clear inside
		off2 = 0x00000060, --unpressed: mostly clear black border
	}
	if not luaconfig.showinput[1][luaconfig.showinput[2]] then
		return
	end
	for k,v in pairs(inp) do
		local color1,color2 = inpcol.on1,inpcol.on2
		if v[5] and v[6] then --analog control
			gui.text(v[1]+v[5], v[2]+v[6], tostring(joypad.get()[v[3]]), color1, color2) --display analog value
		elseif joypad.get()[v[3]] == false or joypad.get()[v[4]] == false then --digital control, unpressed
			color1,color2 = inpcol.off1,inpcol.off2
		end --(otherwise digital control, pressed)
		gui.text(v[1], v[2], string.sub(k, 2), color1, color2)
	end
end

---cheat---*important
function activatecheat()
	local currentframe = readcurrentframe()
	if luaconfig.availablecheat[1][luaconfig.availablecheat[2]] then
		---general
		if cheatconfig.time[1][cheatconfig.time[2]] == "infinite" then --infinite time
			ww(0x76A8, 0000)
		end
		if cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] ~= "normal" then
			local musicaddr
			if cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Ryu" then
				musicaddr = 0x00
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Vega" then
				musicaddr = 0x01
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Guile" then
				musicaddr = 0x02
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Sagat" then
				musicaddr = 0x03
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Ken" then
				musicaddr = 0x04
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Honda" then
				musicaddr = 0x05
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Chun Li" then
				musicaddr = 0x06
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Cammy" then
				musicaddr = 0x07
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Fei Long" then
				musicaddr = 0x08
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Balrog" then
				musicaddr = 0x09
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Blanka" then
				musicaddr = 0x0A
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "M. Bison" then
				musicaddr = 0x0B
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Akuma" then
				musicaddr = 0x0C
			elseif cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]] == "Zangief" then
				musicaddr = 0x0D
			end
			wb(0x7730, musicaddr)
		end
		if cheatconfig.selectstage[1][cheatconfig.selectstage[2]] ~= "normal" then
			local stageaddr
			if cheatconfig.selectstage[1][cheatconfig.selectstage[2]] == "Bison's Lair" then
				stageaddr = 0x00
			elseif cheatconfig.selectstage[1][cheatconfig.selectstage[2]] == "Komande Centre" then
				stageaddr = 0x01
			elseif cheatconfig.selectstage[1][cheatconfig.selectstage[2]] == "Tong Warehouse" then
				stageaddr = 0x02
			elseif cheatconfig.selectstage[1][cheatconfig.selectstage[2]] == "Dhalsim's Lab" then
				stageaddr = 0x03
			elseif cheatconfig.selectstage[1][cheatconfig.selectstage[2]] == "Dungeon" then
				stageaddr = 0x04
			elseif cheatconfig.selectstage[1][cheatconfig.selectstage[2]] == "Temple Ruins" then
				stageaddr = 0x05
			elseif cheatconfig.selectstage[1][cheatconfig.selectstage[2]] == "A.N. Headquarters (Night)" then
				stageaddr = 0x06
			end
			wb(0x76BB, stageaddr)
			wb(0x78D3, stageaddr)
		end
		if cheatconfig.secretcode.ifsecretcode[1][cheatconfig.secretcode.ifsecretcode[2]] == "on" then
			if cheatconfig.secretcode.hidemeters[1][cheatconfig.secretcode.hidemeters[2]] == "P1" then
				wb(0x7298, 2)
				wb(0x745A, 0)
			elseif cheatconfig.secretcode.hidemeters[1][cheatconfig.secretcode.hidemeters[2]] == "P2" then
				wb(0x7298, 0)
				wb(0x745A, 2)
			elseif cheatconfig.secretcode.hidemeters[1][cheatconfig.secretcode.hidemeters[2]] == "both" then
				wb(0x7298, 2)
				wb(0x745A, 2)
			elseif cheatconfig.secretcode.hidemeters[1][cheatconfig.secretcode.hidemeters[2]] == "off" then
				wb(0x7298, 0)
				wb(0x745A, 0)
			end
			if cheatconfig.secretcode.invisotag[1][cheatconfig.secretcode.invisotag[2]] == "P1" then
				wb(0x72A3, 2)
				wb(0x7465, 0)
			elseif cheatconfig.secretcode.invisotag[1][cheatconfig.secretcode.invisotag[2]] == "P2" then
				wb(0x72A3, 0)
				wb(0x7465, 2)
			elseif cheatconfig.secretcode.invisotag[1][cheatconfig.secretcode.invisotag[2]] == "both" then
				wb(0x72A3, 2)
				wb(0x7465, 2)
			elseif cheatconfig.secretcode.invisotag[1][cheatconfig.secretcode.invisotag[2]] == "off" then
				wb(0x72A3, 0)
				wb(0x7465, 0)
			end
			if cheatconfig.secretcode.nothrows[1][cheatconfig.secretcode.nothrows[2]] == "P1" then
				wb(0x7294, 2)
				wb(0x7456, 0)
			elseif cheatconfig.secretcode.nothrows[1][cheatconfig.secretcode.nothrows[2]] == "P2" then
				wb(0x7294, 0)
				wb(0x7456, 2)
			elseif cheatconfig.secretcode.nothrows[1][cheatconfig.secretcode.nothrows[2]] == "both" then
				wb(0x7294, 2)
				wb(0x7456, 2)
			elseif cheatconfig.secretcode.nothrows[1][cheatconfig.secretcode.nothrows[2]] == "off" then
				wb(0x7294, 0)
				wb(0x7456, 0)
			end
			if cheatconfig.secretcode.nospecials[1][cheatconfig.secretcode.nospecials[2]] == "P1" then
				wb(0x7295, 2)
				wb(0x7457, 0)
			elseif cheatconfig.secretcode.nospecials[1][cheatconfig.secretcode.nospecials[2]] == "P2" then
				wb(0x7295, 0)
				wb(0x7457, 2)
			elseif cheatconfig.secretcode.nospecials[1][cheatconfig.secretcode.nospecials[2]] == "both" then
				wb(0x7295, 2)
				wb(0x7457, 2)
			elseif cheatconfig.secretcode.nospecials[1][cheatconfig.secretcode.nospecials[2]] == "off" then
				wb(0x7295, 0)
				wb(0x7457, 0)
			end
			if cheatconfig.secretcode.specialonly[1][cheatconfig.secretcode.specialonly[2]] == "P1" then
				wb(0x7296, 2)
				wb(0x7458, 0)
			elseif cheatconfig.secretcode.specialonly[1][cheatconfig.secretcode.specialonly[2]] == "P2" then
				wb(0x7296, 0)
				wb(0x7458, 2)
			elseif cheatconfig.secretcode.specialonly[1][cheatconfig.secretcode.specialonly[2]] == "both" then
				wb(0x7296, 2)
				wb(0x7458, 2)
			elseif cheatconfig.secretcode.specialonly[1][cheatconfig.secretcode.specialonly[2]] == "off" then
				wb(0x7296, 0)
				wb(0x7458, 0)
			end
			if cheatconfig.secretcode.tagteam[1][cheatconfig.secretcode.tagteam[2]] == "on" then
				wb(0x7292, 2)
				wb(0x7454, 2)
			elseif cheatconfig.secretcode.tagteam[1][cheatconfig.secretcode.tagteam[2]] == "off" then
				wb(0x7292, 0)
				wb(0x7454, 0)
			end
			if cheatconfig.secretcode.doubledamage[1][cheatconfig.secretcode.doubledamage[2]] == "P1" then
				wb(0x729B, 2)
				wb(0x745D, 0)
			elseif cheatconfig.secretcode.doubledamage[1][cheatconfig.secretcode.doubledamage[2]] == "P2" then
				wb(0x729B, 0)
				wb(0x745D, 2)
			elseif cheatconfig.secretcode.doubledamage[1][cheatconfig.secretcode.doubledamage[2]] == "both" then
				wb(0x729B, 2)
				wb(0x745D, 2)
			elseif cheatconfig.secretcode.doubledamage[1][cheatconfig.secretcode.doubledamage[2]] == "off" then
				wb(0x729B, 0)
				wb(0x745D, 0)
			end
			if cheatconfig.secretcode.speedselect[1][cheatconfig.secretcode.speedselect[2]] == "normal" then --(*comment: it's actually possible to activate a setting such like P1 = turbo and P2 = slow, I don't implement that for now though.)
				wb(0x72A5, 0)
				wb(0x7467, 0)
			elseif cheatconfig.secretcode.speedselect[1][cheatconfig.secretcode.speedselect[2]] == "turbo" then
				wb(0x72A5, 1)
				wb(0x7467, 1)
			elseif cheatconfig.secretcode.speedselect[1][cheatconfig.secretcode.speedselect[2]] == "slow" then
				wb(0x72A5, 2)
				wb(0x7467, 2)
			end
			if cheatconfig.secretcode.noblocking[1][cheatconfig.secretcode.noblocking[2]] == "P1" then
				wb(0x7299, 2)
				wb(0x745B, 0)
			elseif cheatconfig.secretcode.noblocking[1][cheatconfig.secretcode.noblocking[2]] == "P2" then
				wb(0x7299, 0)
				wb(0x745B, 2)
			elseif cheatconfig.secretcode.noblocking[1][cheatconfig.secretcode.noblocking[2]] == "both" then
				wb(0x7299, 2)
				wb(0x745B, 2)
			elseif cheatconfig.secretcode.noblocking[1][cheatconfig.secretcode.noblocking[2]] == "off" then
				wb(0x7299, 0)
				wb(0x745B, 0)
			end
			if cheatconfig.secretcode.combomode[1][cheatconfig.secretcode.combomode[2]] == "P1" then
				wb(0x7297, 2)
				wb(0x7459, 0)
			elseif cheatconfig.secretcode.combomode[1][cheatconfig.secretcode.combomode[2]] == "P2" then
				wb(0x7297, 0)
				wb(0x7459, 2)
			elseif cheatconfig.secretcode.combomode[1][cheatconfig.secretcode.combomode[2]] == "both" then
				wb(0x7297, 2)
				wb(0x7459, 2)
			elseif cheatconfig.secretcode.combomode[1][cheatconfig.secretcode.combomode[2]] == "off" then
				wb(0x7297, 0)
				wb(0x7459, 0)
			end
			if cheatconfig.secretcode.nokicks[1][cheatconfig.secretcode.nokicks[2]] == "P1" then
				wb(0x729E, 2)
				wb(0x7460, 0)
			elseif cheatconfig.secretcode.nokicks[1][cheatconfig.secretcode.nokicks[2]] == "P2" then
				wb(0x729E, 0)
				wb(0x7460, 2)
			elseif cheatconfig.secretcode.nokicks[1][cheatconfig.secretcode.nokicks[2]] == "both" then
				wb(0x729E, 2)
				wb(0x7460, 2)
			elseif cheatconfig.secretcode.nokicks[1][cheatconfig.secretcode.nokicks[2]] == "off" then
				wb(0x729E, 0)
				wb(0x7460, 0)
			end
			if cheatconfig.secretcode.nopunches[1][cheatconfig.secretcode.nopunches[2]] == "P1" then
				wb(0x729F, 2)
				wb(0x7461, 0)
			elseif cheatconfig.secretcode.nopunches[1][cheatconfig.secretcode.nopunches[2]] == "P2" then
				wb(0x729F, 0)
				wb(0x7461, 2)
			elseif cheatconfig.secretcode.nopunches[1][cheatconfig.secretcode.nopunches[2]] == "both" then
				wb(0x729F, 2)
				wb(0x7461, 2)
			elseif cheatconfig.secretcode.nopunches[1][cheatconfig.secretcode.nopunches[2]] == "off" then
				wb(0x729F, 0)
				wb(0x7461, 0)
			end
			if cheatconfig.secretcode.strobemode[1][cheatconfig.secretcode.strobemode[2]] == "on" then
				wb(0x72A0, 2)
				wb(0x7462, 2)
			elseif cheatconfig.secretcode.strobemode[1][cheatconfig.secretcode.strobemode[2]] == "off" then
				wb(0x72A0, 0)
				wb(0x7462, 0)
			end
			if cheatconfig.secretcode.invisibility[1][cheatconfig.secretcode.invisibility[2]] == "P1" then
				wb(0x72A1, 2)
				wb(0x7463, 0)
			elseif cheatconfig.secretcode.invisibility[1][cheatconfig.secretcode.invisibility[2]] == "P2" then
				wb(0x72A1, 0)
				wb(0x7463, 2)
			elseif cheatconfig.secretcode.invisibility[1][cheatconfig.secretcode.invisibility[2]] == "both" then
				wb(0x72A1, 2)
				wb(0x7463, 2)
			elseif cheatconfig.secretcode.invisibility[1][cheatconfig.secretcode.invisibility[2]] == "off" then
				wb(0x72A1, 0)
				wb(0x7463, 0)
			end
			if cheatconfig.secretcode.classicthrows[1][cheatconfig.secretcode.classicthrows[2]] == "P1" then
				wb(0x72A4, 2)
				wb(0x7466, 0)
			elseif cheatconfig.secretcode.classicthrows[1][cheatconfig.secretcode.classicthrows[2]] == "P2" then
				wb(0x72A4, 0)
				wb(0x7466, 2)
			elseif cheatconfig.secretcode.classicthrows[1][cheatconfig.secretcode.classicthrows[2]] == "both" then
				wb(0x72A4, 2)
				wb(0x7466, 2)
			elseif cheatconfig.secretcode.classicthrows[1][cheatconfig.secretcode.classicthrows[2]] == "off" then
				wb(0x72A4, 0)
				wb(0x7466, 0)
			end
			if cheatconfig.secretcode.programmerlevel[1][cheatconfig.secretcode.programmerlevel[2]] == "on" then --(*comment: I don't know what each value manages.)
				wb(0x775E, 0)
				wb(0x775F, 8)
			elseif cheatconfig.secretcode.programmerlevel[1][cheatconfig.secretcode.programmerlevel[2]] == "off" then
				wb(0x775E, 255)
				wb(0x775F, 255)
			end
			if cheatconfig.secretcode.inverted[1][cheatconfig.secretcode.inverted[2]] == "on" then
				wb(0x729D, 2)
				wb(0x745F, 2)
			elseif cheatconfig.secretcode.inverted[1][cheatconfig.secretcode.inverted[2]] == "off" then
				wb(0x729D, 0)
				wb(0x745F, 0)
			end
			if cheatconfig.secretcode.reversecontrols[1][cheatconfig.secretcode.reversecontrols[2]] == "P1" then
				wb(0x729A, 2)
				wb(0x745C, 0)
			elseif cheatconfig.secretcode.reversecontrols[1][cheatconfig.secretcode.reversecontrols[2]] == "P2" then
				wb(0x729A, 0)
				wb(0x745C, 2)
			elseif cheatconfig.secretcode.reversecontrols[1][cheatconfig.secretcode.reversecontrols[2]] == "both" then
				wb(0x729A, 2)
				wb(0x745C, 2)
			elseif cheatconfig.secretcode.reversecontrols[1][cheatconfig.secretcode.reversecontrols[2]] == "off" then
				wb(0x729A, 0)
				wb(0x745C, 0)
			end
			if cheatconfig.secretcode.swapplayers[1][cheatconfig.secretcode.swapplayers[2]] == "on" then
				wb(0x72A2, 2)
				wb(0x7464, 2)
			elseif cheatconfig.secretcode.swapplayers[1][cheatconfig.secretcode.swapplayers[2]] == "off" then
				wb(0x72A2, 0)
				wb(0x7464, 0)
			end
		end

		---P1
		if cheatconfig.P1health[1][cheatconfig.P1health[2]] == "infinite" then --P1 health (128=max, 10=red)
			wb(addr.P1health, 128)
		elseif cheatconfig.P1health[1][cheatconfig.P1health[2]] == "red" then
			wb(addr.P1health, 10)
		elseif cheatconfig.P1health[1][cheatconfig.P1health[2]] == "refill" then
			if P1status.ifrefillhealth[1][P1status.ifrefillhealth[2]] == false then
				if rb(addr.P1health) < 128 then
					if rb(addr.P2combocounter) == 0 and rb(addr.P1dizzy) == 0 then
						if P1status.refillcount < 50 and P1status.refillcount >= 0 then
							P1status.refillcount = currentframe - P1status.refillcountstartframe
						elseif P1status.refillcount >= 50 then
							P1status.ifrefillhealth[2] = 1
							P1status.refillcount = 0
							P1status.refillcountstartframe = currentframe
						elseif P1status.refillcount < 0 then
							P1status.refillcount = 0
							P1status.refillcountstartframe = currentframe
						end
					else
						P1status.refillcount = 0
						P1status.refillcountstartframe = currentframe
					end
				elseif rb(addr.P1health) >= 128 then
					P1status.refillcount = 0
					P1status.refillcountstartframe = currentframe
				end
			elseif P1status.ifrefillhealth[1][P1status.ifrefillhealth[2]] == true then
				if rb(addr.P2combocounter) == 0 and rb(addr.P1dizzy) == 0 then
					if rb(addr.P1health) < 128 then
						wb(addr.P1health, math.min(rb(addr.P1health)+1, 128))
					elseif rb(addr.P1health) == 128 then
						P1status.ifrefillhealth[2] = 2
					end
				else
					P1status.ifrefillhealth[2] = 2
					P1status.refillcount = 0
					P1status.refillcountstartframe = currentframe
				end
			end
		end
		if cheatconfig.P1meter[1][cheatconfig.P1meter[2]] == "infinite" then -- P2 meter(67=max)
			wb(addr.P1meter, 67)
		end
		if cheatconfig.P1stun[1][cheatconfig.P1stun[2]] == "never" then -- P2 meter(67=max)
			wb(addr.P1dizzyvalue, 85)
		end
		---P2
		if cheatconfig.P2health[1][cheatconfig.P2health[2]] == "infinite" then --P2 health (128=max, 10=red)
			wb(addr.P2health, 128)
		elseif cheatconfig.P2health[1][cheatconfig.P2health[2]] == "red" then
			wb(addr.P2health, 10)
		elseif cheatconfig.P2health[1][cheatconfig.P2health[2]] == "refill" then
			if P2status.ifrefillhealth[1][P2status.ifrefillhealth[2]] == false then
				if rb(addr.P2health) < 128 then
					if rb(addr.P1combocounter) == 0 and rb(addr.P2dizzy) == 0 then
						if P2status.refillcount < 50 and P2status.refillcount >= 0 then
							P2status.refillcount = currentframe - P2status.refillcountstartframe
						elseif P2status.refillcount >= 50 then
							P2status.ifrefillhealth[2] = 1
							P2status.refillcount = 0
							P2status.refillcountstartframe = currentframe
						elseif P2status.refillcount < 0 then
							P2status.refillcount = 0
							P2status.refillcountstartframe = currentframe
						end
					else
						P2status.refillcount = 0
						P2status.refillcountstartframe = currentframe
					end
				elseif rb(addr.P2health) >= 128 then
					P2status.refillcount = 0
					P2status.refillcountstartframe = currentframe
				end
			elseif P2status.ifrefillhealth[1][P2status.ifrefillhealth[2]] == true then
				if rb(addr.P1combocounter) == 0 and rb(addr.P2dizzy) == 0 then
					if rb(addr.P2health) < 128 then
						wb(addr.P2health, math.min(rb(addr.P2health)+1, 128))
					elseif rb(addr.P2health) == 128 then
						P2status.ifrefillhealth[2] = 2
					end
				else
					P2status.ifrefillhealth[2] = 2
					P2status.refillcount = 0
					P2status.refillcountstartframe = currentframe
				end
			end
		end
		if cheatconfig.P2meter[1][cheatconfig.P2meter[2]] == "infinite" then -- P2 meter(67=max)
			wb(addr.P2meter, 67)
		end
		if cheatconfig.P2stun[1][cheatconfig.P2stun[2]] == "never" then -- P2 meter(67=max)
			wb(addr.P2dizzyvalue, 85)
		end
	end
end

---function---*important
if not elmdetect(games, emu.romname()) then
	print("This game is not SFTM...")
	return
else
	print("--- SFTM training lua ("..scriptver..") ---")
	print("This script works correctly on Fightcade FBNeo v.0.2.97.44.")
	print()
	emu.registerbefore(function()
		setinputs()
		activatecheat()
	end)
	gui.register(function()
		displayhud()
		displaymenu()
	end)
end

print("* Hold P1's or P2's Start to open training menu.")
--input.registerhotkey(1, function() luaconfig.showmenu[2] = lccalc(luaconfig.showmenu[2], #luaconfig.showmenu[1], 1) if not luaconfig.showmenu[1][luaconfig.showmenu[2]] then gui.clearuncommitted() end end)
