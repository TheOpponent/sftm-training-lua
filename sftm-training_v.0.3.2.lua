---/Street Fighter: The Movie training lua v.0.3.2 (2022/03/24)/---
---/This works correctly on Fightcade FBNeo v.0.2.97.44 and NOT on mame-rr/---

-- *issue -> things to be solved, *comment -> stuff worth writing but not critical --

---preamble---*important
local gamename = "Street Fighter: The Movie"
local scriptver = "v.0.3.2"
local rb, rbs, rw, rws, rd = memory.readbyte, memory.readbytesigned, memory.readword, memory.readwordsigned, memory.readdword
local wb, wbs, ww, wws, wd = memory.writebyte, memory.writebytesigned, memory.writeword, memory.writewordsigned, memory.writedword
local function readcurrentframe() -- read the current frame
	return emu.framecount()
end
local sw,sh = emu.screenwidth(), emu.screenheight() -- read the screen width/height
local function iffileexist(name) --check if the file exists (name: the file name)
 local f = io.open(name, "r")
 if f ~= nil then
	 io.close(f)
	 return true
 else
	 return false
 end
end
local function any_true(condition)
	for n = 1, #condition do
		if condition[n] == true then return true end
	end
end
local function lccalc(count, max, add) --calculate loop counter (count: the counter, max: the maximum value, add: the value to add)
	if (count+add)%max == 0 then
		return max
	else
		return (count+add)%max
	end
end
local function tblconcat(tbl1, tbl2) -- concatenate two tables (the former table: tbl1, the latter table: tbl2)
	for i = 1, #tbl2 do
		tbl1[#tbl1+1] = tbl2[i]
	end
	return tbl1
end
local function strsplit(str, sep) -- split a string by a certain patterm (str: string to split, sep: patterm)
	if str == nil then
		return {}
	end
	sep = sep or '%s'
	local t={}
	for _,s in string.gmatch(str, "([^"..sep.."]*)("..sep.."?)") do
		table.insert(t, _)
		if s == "" then
			return t
		end
	end
end
local function elmdetect(tbl, elm) --detect whether a ceartain element exists in the table (table: tbl, element: elm)
	for i,v in pairs(tbl) do
		if elm == v then
			return i
		end
	end
	return false
end
local function getfilelist(prefix, suffix) --get the list of files in source code's directory (prefix: the phrase at the beginning of file name, suffix: the phrase at the end of file name)
	local filelist, filename = {}, ""
	local path = debug.getinfo(1).source:sub(2):match("(.*[/\\])")
	if prefix == nil then
		if suffix == nil then
			filename = path.."*"
		else
			filename = path.."*"..suffix
		end
	else
		if suffix == nil then
			filename = path..prefix.."*"
		else
			filename = path..prefix.."*"..suffix
		end
	end
  for filename in io.popen('dir "'..filename..'" /b'):lines() do
		table.insert(filelist, #filelist+1, filename)
	end
	return filelist
end
local function basenconvert(cnvnum, cnvbase) -- convert positive decimal integer into base-n number (integer: cnvnum, base: cnvbase)
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

games = {"sftm","sftm110","sftm111","sftmj114"} -- the games this script supports
buttons = {
	{"Weak Punch", "LP"},
	{"Medium Punch", "MP"},
	{"Strong Punch", "HP"},
	{"Weak Kick", "LK"},
	{"Medium Kick", "MK"},
	{"Strong Kick", "HK"}
}

addr = { -- list of addresses
	---address P1
	P1x = 0x70F0,
	P1y = 0x70F2,
	P1dir = 0x7133,
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
	P2x = 0x740E,
	P2y = 0x7410,
	P2dir = 0x72F5,
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

P1status = {
	x = 0, y = 0, dir = "",
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
P2status = {
	x = 0, y = 0, dir = "",
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
local function updatestatus()
	sw,sh = emu.screenwidth(), emu.screenheight()
	P1status.x, P1status.y = rws(addr.P1x), rws(addr.P1y)
	P2status.x, P2status.y = rws(addr.P2x), rws(addr.P2y)
	if rbs(addr.P1dir) == 2 then
		P1status.dir = "left"
	elseif rbs(addr.P1dir) == 0 then
		P1status.dir = "right"
	end
	if rbs(addr.P2dir) == 2 then
		P2status.dir = "left"
	elseif rbs(addr.P2dir) == 0 then
		P2status.dir = "right"
	end
end

local luaconfig = {
	availablemenu = {{true, false}, 1},
	showmenu = {{true, false}, 2},
	showhud = {{true, false}, 1},
	availablecheat = {{true, false}, 1},
	updatefilelist = {{true, false}, 1},
	showcautionmessage = {{true, false}, 2}
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
local recordconfig = {
	ifrecording = {{true, false}, 2},
	ifplayback = {{true, false}, 2},
	slot = {{}, {} ,{}, {}, {}},
	recordslot = 1,
	ifslotrecorded = {false, false, false, false, false},
	recordstartframe = readcurrentframe(),
	framebeforerecording = 40,
	timerbeforerecording = 0,
	timerafterrecording = 0,
	recordinginput = {},
	ifrecordend = {{true, false}, 2},
	deleteslot = 1,
	playbackslot = 1,
	playbackstyle = {{"once", "repeat", "sequence", "random"}, 2},
	playbacktime = 1,
	playbackinput = {},
	previousrecordstate = false,
	previousplaybackstate = false,
	ifshowplayback = {{true, false}, 1},
	ifloadstatebefore = {{"yes", "no"}, 1}
}
local macroconfig = {
	macrolist = {},
	macrolistsorted = {},
	playbackslot = 0,
	savestatelist = {},
	loadstateslot = 0,
	game = {
		player = 2,
		keymap = {
			{"U", "P# Up"},
			{"D", "P# Down"},
			{"L", "P# Left"},
			{"R", "P# Right"},
			{"F", "P# Forward"},
			{"B", "P# Backward"},
			{"S", "P# Start"},
			{"X", "P# Disable"}
		}
	},
	ifplayback = {{true, false}, 2},
	previousplaybackstate = false,
	playbackstyle = {{"once", "repeat", "sequence", "random"}, 1},
	ifloadedmacro = {{true, false}, 2},
	playbackinput = {},
	playbacktime = 1,
	waitframebefore = 0,
	waitframeafter = 0,
	waitcountbefore = 1,
	waitcountafter = 1,
	ifloadstatebefore = {{"yes", "no"}, 1},
	ifloadedstate = {{true, false}, 2},
	ifshowplayback = {{true, false}, 1},
	ifsortmacrofile = {{true, false}, 2}
}
for i = 1, #buttons do
	table.insert(macroconfig.game.keymap, #macroconfig.game.keymap+1, {tostring(i), "P# "..buttons[i][1]})
end
local hudconfig = {
	hudstyle = {{"detailed", "simple", "debug", "hide"}, 1},
	ifshowdarklayer = {{true, false}, 2},
	darklayertransparency = 63,
	ifshowinput = {{true, false}, 1},
	inputstyle = {{"type1", "type2"}, 2},
}
local cheatconfig = {
	time = {{"normal", "infinite"}, 2},
	P1health = {{"normal", "refill", "infinite", "red"}, 2},
	P1meter = {{"normal", "infinite", "empty"}, 1},
	P1stun = {{"normal", "never"}, 1},
	P2health = {{"normal", "refill", "infinite", "red"}, 2},
	P2meter = {{"normal", "infinite", "empty"}, 1},
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
local footsiesconfig = {
	iffootsies = {{true, false}, 2},
	ifshowinfo = {{"yes", "no"}, 1},
	distance = {},
	movegoaldistance = 150,
	allowwalkrangeforward = 30,
	allowwalkrangebackward = 30,
	allowneutralrangeforward = 0,
	allowneutralrangebackward = 20,
	reactiondelay = 12,
	previousreactiondelay = 12,
	ifallowneutral = {{true, false}, 1},
	ifallowprewalk = {{true, false}, 1},
	movemode = {{"walk", "stand", "crouch"}, 1},
	attackmode = {{"normal", "playback"}, 1},
	movetype = {{"fwalk", "bwalk", "prewalk", "neutral", "crouch", "attack", "block"}, 1},
	premovetype = {{"fwalk", "bwalk", "prewalk", "neutral", "crouch", "attack", "block"}, 1},
	attack1stick = {{"db", "d", "df", "b", "n", "f"}, 1},
	attack1button = {{}, 1},
	attack1distance = 80,
	allowattack1range = 40,
	attack1holdframe = 2,
	attack1blockframe = 30,
	attack1probratio = 1,
	attack2stick = {{"db", "d", "df", "b", "n", "f"}, 1},
	attack2button = {{}, 2},
	attack2distance = 170,
	allowattack2range = 10,
	attack2holdframe = 2,
	attack2blockframe = 30,
	attack2probratio = 0.5,
	attackstick = {},
	attackbutton = {},
	holdattackframe = 0,
	blockframe = 0,
	blocktype = {{"stand", "crouch", "jump"}, 2},
	baseprobattack = 0.05,
	baseprobfwalktogoal = 0.4,
	baseprobbwalktogoal = 0.5,
	probprewalk = 0.6,
	probneutral = 0.02,
	probkeepneutral = 0.8,
	walklimitfloor = 3,
	neutrallimitfloor = 5,
	beforeattackframe = 0,
	walkcount = 0,
	prewalkcount = 0,
	neutralcount = 0,
	attackcount = 0,
	blockcount = 0,
	playbackcount = 0,
	prewalkdir = 0
}
for i = 1, #buttons do
	footsiesconfig.attack1button[1][i] = buttons[i][2]
	footsiesconfig.attack2button[1][i] = buttons[i][2]
end
for i = 1, #recordconfig.slot do
	table.insert(footsiesconfig.attack1button[1], #footsiesconfig.attack1button[1]+1, "slot"..i)
	table.insert(footsiesconfig.attack2button[1], #footsiesconfig.attack2button[1]+1, "slot"..i)
end
for i = 1, footsiesconfig.reactiondelay+1 do
	footsiesconfig.distance[i] = math.abs(P1status.x - P2status.x)
end

local replayviewmode = {{true, false}, 2}
if replayviewmode[1][replayviewmode[2]] then
	luaconfig.availablemenu[2] = 2
	luaconfig.availablecheat[2] = 2
	hudconfig.hudstyle[2] = 2
	hudconfig.inputstyle[2] = 2
end

local function getfilelist()
	if luaconfig.updatefilelist[1][luaconfig.updatefilelist[2]] then
		local macrolist, savestatelist = {}, {}
		macroconfig.playbackslot, macroconfig.loadstateslot = 0, 0
		local path = debug.getinfo(1).source:sub(2):match("(.*[\\])")
		if path == nil then
			luaconfig.showcautionmessage[2] = 1
		else
		  for filename in io.popen('dir "'..path..emu.romname()..'_macro_*.mis" /b'):lines() do
				table.insert(macrolist, #macrolist+1, filename)
			end
			for filename in io.popen('dir "'..path..emu.romname()..'_macro_*.fs" /b'):lines() do
				table.insert(savestatelist, #savestatelist+1, filename)
			end
			if #macrolist ~= 0 then
				macroconfig.playbackslot = 1
			end
			if #savestatelist ~= 0 then
				macroconfig.loadstateslot = 1
			end
			macroconfig.macrolist = macrolist
			macroconfig.savestatelist = savestatelist
			if elmdetect(macroconfig.savestatelist, emu.romname().."_macro_default.fs") then
				table.remove(macroconfig.savestatelist, elmdetect(macroconfig.savestatelist, emu.romname().."_macro_default.fs"))
				table.insert(macroconfig.savestatelist, 1, emu.romname().."_macro_default.fs")
			end
			if elmdetect(macroconfig.savestatelist, emu.romname().."_macro_default_backup.fs") then
				table.remove(macroconfig.savestatelist, elmdetect(macroconfig.savestatelist, emu.romname().."_macro_default_backup.fs"))
				table.insert(macroconfig.savestatelist, 2, emu.romname().."_macro_default_backup.fs")
			end
			luaconfig.updatefilelist[2] = 2
		end
	end
	if macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] then
		local macrolistsorted = {}
		if macroconfig.loadstateslot == 0 then
			macrolistsorted = macroconfig.macrolist
		else
			if #macroconfig.macrolist ~= 0 then
				for i, v in ipairs(macroconfig.macrolist) do
					if v:find(macroconfig.savestatelist[macroconfig.loadstateslot]:sub(1, -4), 1, true) then
						table.insert(macrolistsorted, #macrolistsorted+1, v)
					end
				end
			end
			if #macrolistsorted == 0 then
				macroconfig.playbackslot = 0
			end
		end
		macroconfig.macrolistsorted = macrolistsorted
	end
end

---input---*important
local function getinput()
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

local function setinputs()
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

local function freezeplayer()
	if not luaconfig.showmenu[1][luaconfig.showmenu[2]] then
		return input
	elseif luaconfig.showmenu[1][luaconfig.showmenu[2]] then
		local player, inp
		local freezeinput = joypad.get()
		for i,v in pairs(freezeinput) do
			freezeinput[i] = false
		end
		joypad.set(freezeinput)
	end
end

---record---*important
local function togglerecord()
	if not recordconfig.ifrecording[1][recordconfig.ifrecording[2]] then
		recordconfig.previousrecordstate = false
	elseif recordconfig.ifrecording[1][recordconfig.ifrecording[2]] then
		if recordconfig.previousrecordstate == false then
			luaconfig.showmenu[2] = 2
		end
		recordconfig.previousrecordstate = true
		if recordconfig.timerbeforerecording < recordconfig.framebeforerecording - 1 then
			if recordconfig.timerbeforerecording == 0 then
				if recordconfig.ifloadstatebefore[1][recordconfig.ifloadstatebefore[2]] == "yes" then
					if iffileexist(emu.romname().."_recording.fs") then
						savestate.load(savestate.create(emu.romname().."_recording.fs"))
					end
				end
			end
			inputconfig.ifdisableinputset[2] = 1
			inputconfig.disableinputplayer[2] = 4
			recordconfig.timerbeforerecording = recordconfig.timerbeforerecording + 1
		elseif recordconfig.timerbeforerecording == recordconfig.framebeforerecording -1 then
			inputconfig.ifdisableinputset[2] = 1
			inputconfig.disableinputplayer[2] = 4
			inputconfig.ifswapinput[2] = lccalc(inputconfig.ifswapinput[2], #inputconfig.ifswapinput[1], 1)
			recordconfig.slot[recordconfig.recordslot] = {}
			recordconfig.timerbeforerecording = recordconfig.timerbeforerecording + 1
			recordconfig.timerafterrecording = 0
		elseif recordconfig.timerbeforerecording == recordconfig.framebeforerecording then
			if not recordconfig.ifrecordend[1][recordconfig.ifrecordend[2]] then
				inputconfig.ifdisableinputset[2] = 2
				inputconfig.disableinputplayer[2] = 1
				table.insert(recordconfig.slot[recordconfig.recordslot], #recordconfig.slot[recordconfig.recordslot]+1, swapinputs(joypad.getdown()))
				recordconfig.slot[recordconfig.recordslot][#recordconfig.slot[recordconfig.recordslot]]["P1 Coin"] = false
				recordconfig.slot[recordconfig.recordslot][#recordconfig.slot[recordconfig.recordslot]]["P2 Coin"] = false
				recordconfig.timerafterrecording = recordconfig.timerafterrecording + 1
				if recordconfig.timerafterrecording == 600 then
					recordconfig.ifrecordend[2] = 1
				end
			elseif recordconfig.ifrecordend[1][recordconfig.ifrecordend[2]] then
				inputconfig.ifswapinput[2] = lccalc(inputconfig.ifswapinput[2], #inputconfig.ifswapinput[1], 1)
				luaconfig.showmenu[2] = 1
				recordconfig.ifslotrecorded[recordconfig.recordslot] = true
				recordconfig.timerbeforerecording = 0
				recordconfig.timerafterrecording = 0
				recordconfig.ifrecording[2], recordconfig.ifrecordend[2] = 2, 2
			end
		end
	end
end

local function toggleplayback()
	if recordconfig.ifrecording[1][recordconfig.ifrecording[2]] then
		return
	end
	if not recordconfig.ifplayback[1][recordconfig.ifplayback[2]] then
		recordconfig.previousplaybackstate = false
	elseif recordconfig.ifplayback[1][recordconfig.ifplayback[2]] then
		if #recordconfig.slot[recordconfig.playbackslot] == 0 then
			recordconfig.ifplayback[2] = 2
			return
		end
		if recordconfig.previousplaybackstate == false then
			luaconfig.showmenu[2] = 2
		end
		recordconfig.previousplaybackstate = true
		if recordconfig.playbacktime <= #recordconfig.slot[recordconfig.playbackslot] then
			if recordconfig.playbacktime == 1 then
				if recordconfig.ifloadstatebefore[1][recordconfig.ifloadstatebefore[2]] == "yes" then
					if iffileexist(emu.romname().."_recording.fs") then
						savestate.load(savestate.create(emu.romname().."_recording.fs"))
					end
				end
			end
			recordconfig.playbackinput = joypad.get()
			local player, inp
			for i,v in pairs(recordconfig.slot[recordconfig.playbackslot][recordconfig.playbacktime]) do
				if recordconfig.slot[recordconfig.playbackslot][recordconfig.playbacktime][i] == true then
					recordconfig.playbackinput[i] = true
				end
			end
			joypad.set(recordconfig.playbackinput)
			recordconfig.playbacktime = recordconfig.playbacktime + 1
		elseif recordconfig.playbacktime > #recordconfig.slot[recordconfig.playbackslot] then
			recordconfig.playbacktime = 1
			if recordconfig.playbackstyle[1][recordconfig.playbackstyle[2]] == "once" then
				luaconfig.showmenu[2] = 1
				recordconfig.ifplayback[2] = 2
			elseif recordconfig.playbackstyle[1][recordconfig.playbackstyle[2]] == "sequence" then
				local recordedslotnum, playbackslot = {}, 0
				for i = 1, #recordconfig.ifslotrecorded do
					if recordconfig.ifslotrecorded[i] then
						recordedslotnum[#recordedslotnum+1] = i
					end
				end
				for i = 1, #recordedslotnum do
					if recordconfig.playbackslot == recordedslotnum[i]  then
						playbackslot = i
					end
				end
				recordconfig.playbackslot = recordedslotnum[lccalc(playbackslot, #recordedslotnum, 1)]
			elseif recordconfig.playbackstyle[1][recordconfig.playbackstyle[2]] == "random" then
				local recordedslotnum = {}
				for i = 1, #recordconfig.ifslotrecorded do
					if recordconfig.ifslotrecorded[i] then
						recordedslotnum[#recordedslotnum+1] = i
					end
				end
				recordconfig.playbackslot = recordedslotnum[math.random(#recordedslotnum)]
			end
		end
	end
end

local function playbackmacro()
	if not macroconfig.ifplayback[1][macroconfig.ifplayback[2]] then
		macroconfig.previousplaybackstate = false
	elseif macroconfig.ifplayback[1][macroconfig.ifplayback[2]] then
		if macroconfig.previousplaybackstate == false then
			luaconfig.showmenu[2] = 2
			macroconfig.playbackinput = {{}}
			if macroconfig.playbackslot == 0 then
				macroconfig.ifplayback[2] = 2
				luaconfig.showmenu[2] = 1
				return
			else
				if not io.open(macroconfig.macrolist[macroconfig.playbackslot], "r") then
					print("Error: unable to open '" .. macroconfig.macrolist[macroconfig.playbackslot] .. "'")
					macroconfig.ifplayback[2] = 2
					luaconfig.showmenu[2] = 1
					return
				end
			end
			--macro to input (from macro.lua by Dammit)
			local file = io.input(macroconfig.macrolist[macroconfig.playbackslot])
			if macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] then
				file = io.input(macroconfig.macrolistsorted[macroconfig.playbackslot])
			end
			local m = "\n" .. file:read("*a") .. "\n" --Open and read the file.
			file:close() --Close the file.
			m = m:gsub("([\n\r][^#]-)!.*", "%1") --Remove everything after the first uncommented "!".
			m = m:sub(2) --Remove initial linebreak that was inserted
			m = m:gsub("#.-[\n\r]", "\n") --Remove lines commented with "#".
			m = m:gsub("[wW] ?(%d+)", function(n) return string.rep(".", n) end) --Expand waits into dots.
			while m:find("%b() ?%d+") do --Recursively..
			  m = m:gsub("(%b()) ?(%d+)", function(s, n) --..expand ()n loops..
			    s = s:sub(2, -2) .. "," --..and remove the parentheses.
			    return s:rep(n)
			  end)
			end
			while m:find("%b()%?%[%d+%-%d+%]") do --Recursively..
			  m = m:gsub("(%b())%?%[(%d+)%-(%d+)%]", function(s, n1, n2) --..expand ()n loops..
			    s = s:sub(2, -2) .. "," --..and remove the parentheses.
			    return s:rep(math.random(math.min(n1, n2), math.max(n1, n2)))
			  end)
			end
			m = m:gsub("%|", "}%|{")
			while m:find("%b{}%|%b{}") do --Recursively..
			  m = m:gsub("(%b{})%|(%b{})", function(s1, s2) --..expand ()n loops..
			    s1 = s1:sub(2, -2).."," --..and remove the parentheses.
			    s2 = s2:sub(2, -2).."," --..and remove the parentheses.
			    if math.random(1,2) == 1 then
			      return s1
			    else
			      return s2
			    end
			  end)
			end
			for _,space in pairs({" ",",","\t","\n","\r"}) do --Remove commas, spaces, tabs, and linebreaks.
			  m = m:gsub(space, "")
			end
			m = m:sub(m:find("<")+1, m:len())
			m = m:sub(1, m:find(">")-1)
			m = strsplit(m, "/")
			for i = 1, macroconfig.game.player do
				if m[i] then
					m[i] = strsplit(m[i], ".")
				else
					m[i] = {}
				end
				if m[i][#m[i]] == "" then
					table.remove(m[i], #m[i])
				end
			end
			local maxframe = 0
			for i = 1, macroconfig.game.player do
				maxframe = math.max(maxframe, #m[i])
			end
			if maxframe == 0 then
				print("Error: no input is coded in the macro file.")
				macroconfig.ifplayback[2] = 2
				luaconfig.showmenu[2] = 1
				return
			else
				for i = 1, maxframe do
					table.insert(macroconfig.playbackinput, i, {})
				end
				for p = 1, macroconfig.game.player do
					if #m[p] < maxframe then
						for i = #m[p]+1, maxframe do
							table.insert(m[p], i, "")
						end
					end
				end
			end
			local holdkey = ""
			for p = 1, macroconfig.game.player do
				holdkey = ""
				for f = 1, #m[p] do
					v = "P"..tostring(p).."status"
					while string.len(m[p][f]) > 0 do
						if string.sub(m[p][f], 1,1) == "_" then
							m[p][f] = string.sub(m[p][f], 2)
							for _,input in ipairs(macroconfig.game.keymap) do
								if string.sub(m[p][f], 1,1) == input[1] then
									holdkey = holdkey..string.sub(m[p][f], 1,1)
								end
							end
						elseif string.sub(m[p][f], 1,1) == "^" then
							m[p][f] = string.sub(m[p][f], 2)
							for _,input in ipairs(macroconfig.game.keymap) do
								if string.sub(m[p][f], 1,1) == input[1] then
									holdkey = holdkey:gsub(string.sub(m[p][f], 1,1), "")
								end
							end
						else
							for _,input in ipairs(macroconfig.game.keymap) do
								if string.sub(m[p][f], 1,1) == input[1] then
									macroconfig.playbackinput[f]["P"..p.." "..input[2]:sub(4)] = true
								end
							end
						end
						m[p][f] = string.sub(m[p][f], 2)
					end
					if holdkey:len() > 0 then
						for i = 1, holdkey:len() do
							for _,input in ipairs(macroconfig.game.keymap) do
								if holdkey:sub(i,i) == input[1] then
									macroconfig.playbackinput[f]["P"..p.." "..input[2]:sub(4)] = true
								end
							end
						end
					end
				end
			end
			if macroconfig.playbackinput[#macroconfig.playbackinput][1] == nil then
				table.remove(macroconfig.playbackinput)
			end
		end
		macroconfig.previousplaybackstate = true
		if macroconfig.ifloadstatebefore[1][macroconfig.ifloadstatebefore[2]] == "yes" then
			if not macroconfig.ifloadedstate[1][macroconfig.ifloadedstate[2]] then
				if macroconfig.loadstateslot ~= 0 then
					if iffileexist(macroconfig.savestatelist[macroconfig.loadstateslot]) then
						savestate.load(savestate.create(macroconfig.savestatelist[macroconfig.loadstateslot]))
					end
				end
			end
			macroconfig.ifloadedstate[2] = 1
		end
		if macroconfig.waitcountbefore <= macroconfig.waitframebefore then
			macroconfig.waitcountbefore = macroconfig.waitcountbefore + 1
		elseif macroconfig.playbacktime <= #macroconfig.playbackinput then
			for p = 1,2 do
				s = "P"..tostring(p).."status"
				for i,v in pairs(macroconfig.playbackinput[macroconfig.playbacktime]) do
					if i == "P"..p.." Forward" then
						if _G[s].dir == "left" then
							macroconfig.playbackinput[macroconfig.playbacktime]["P"..p.." Left"] = true
						elseif _G[s].dir == "right" then
							macroconfig.playbackinput[macroconfig.playbacktime]["P"..p.." Right"] = true
						end
					end
					if i == "P"..p.." Backward" then
						if _G[s].dir == "left" then
							macroconfig.playbackinput[macroconfig.playbacktime]["P"..p.." Right"] = true
						elseif _G[s].dir == "right" then
							macroconfig.playbackinput[macroconfig.playbacktime]["P"..p.." Left"] = true
						end
					end
					if i == "P"..p.." Disable" then
						local player, inp
						for i,v in pairs(joypad.get()) do
							player, inp = i:sub(1,2), i:sub(4)
							if player == "P"..p then
								if not (macroconfig.playbackinput[macroconfig.playbacktime][i] == true) then
									macroconfig.playbackinput[macroconfig.playbacktime][i] = false
								end
							end
						end
					end
				end
			end
			joypad.set(macroconfig.playbackinput[macroconfig.playbacktime])
			macroconfig.playbacktime = macroconfig.playbacktime + 1
			if macroconfig.playbacktime == #macroconfig.playbackinput + 1 then
				if (macroconfig.playbackstyle[1][macroconfig.playbackstyle[2]] ~= "once") and (macroconfig.waitframeafter == 0) then
					macroconfig.playbacktime = 1
					macroconfig.waitcountbefore = 1
					macroconfig.ifloadedstate[2] = 2
					macroconfig.previousplaybackstate = false
					if macroconfig.playbackstyle[1][macroconfig.playbackstyle[2]] == "sequence" then
						if macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] then
							macroconfig.playbackslot = lccalc(macroconfig.playbackslot, #macroconfig.macrolistsorted, 1)
						else
							macroconfig.playbackslot = lccalc(macroconfig.playbackslot, #macroconfig.macrolist, 1)
						end
					elseif macroconfig.playbackstyle[1][macroconfig.playbackstyle[2]] == "random" then
						if macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] then
							macroconfig.playbackslot = math.random(#macroconfig.macrolistsorted)
						else
							macroconfig.playbackslot = math.random(#macroconfig.macrolist)
						end
					end
				end
			end
		elseif macroconfig.waitcountafter <= macroconfig.waitframeafter then
			macroconfig.waitcountafter = macroconfig.waitcountafter + 1
			if macroconfig.waitcountafter == macroconfig.waitframeafter + 1 then
				if macroconfig.playbackstyle[1][macroconfig.playbackstyle[2]] ~= "once" then
					macroconfig.playbacktime = 1
					macroconfig.waitcountbefore = 1
					macroconfig.waitcountafter = 1
					macroconfig.ifloadedstate[2] = 2
					macroconfig.previousplaybackstate = false
					if macroconfig.playbackstyle[1][macroconfig.playbackstyle[2]] == "sequence" then
						if macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] then
							macroconfig.playbackslot = lccalc(macroconfig.playbackslot, #macroconfig.macrolistsorted, 1)
						else
							macroconfig.playbackslot = lccalc(macroconfig.playbackslot, #macroconfig.macrolist, 1)
						end
					elseif macroconfig.playbackstyle[1][macroconfig.playbackstyle[2]] == "random" then
						if macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] then
							macroconfig.playbackslot = math.random(#macroconfig.macrolistsorted)
						else
							macroconfig.playbackslot = math.random(#macroconfig.macrolist)
						end
					end
				end
			end
		else
			macroconfig.playbacktime = 1
			macroconfig.waitcountbefore = 1
			macroconfig.waitcountafter = 1
			macroconfig.ifloadedstate[2] = 2
			macroconfig.previousplaybackstate = false
			if macroconfig.playbackstyle[1][macroconfig.playbackstyle[2]] == "once" then
				macroconfig.ifplayback[2] = 2
				luaconfig.showmenu[2] = 1
			end
		end
	end
end

---footsies---*important
local function footsies()
	if not footsiesconfig.iffootsies[1][footsiesconfig.iffootsies[2]] then
		return
	end
	luaconfig.showmenu[2] = 2
	--get status
	if footsiesconfig.previousreactiondelay ~= footsiesconfig.reactiondelay then
		for i = 1, footsiesconfig.reactiondelay+1 do
			footsiesconfig.distance = {}
			footsiesconfig.distance[i] = math.abs(P1status.x - P2status.x)
			footsiesconfig.previousreactiondelay = footsiesconfig.reactiondelay
		end
	end
	if footsiesconfig.reactiondelay ~= 0 then
		for i = 1, footsiesconfig.reactiondelay do
			footsiesconfig.distance[i+1] = footsiesconfig.distance[i]
		end
	end
	footsiesconfig.distance[1] = math.abs(P1status.x - P2status.x)
	local distance = footsiesconfig.distance[#footsiesconfig.distance]
	--decide opponent's move
	if footsiesconfig.movemode[1][footsiesconfig.movemode[2]] == "walk" then
		local walklimitnoise = math.random(-1, 6)
		if footsiesconfig.walkcount == 0 then
			if distance > footsiesconfig.movegoaldistance then
				if math.random() > footsiesconfig.baseprobfwalktogoal + (math.abs(distance - footsiesconfig.movegoaldistance)/footsiesconfig.allowwalkrangebackward)^2*(1-footsiesconfig.baseprobfwalktogoal) then
					footsiesconfig.movetype[2] = 2
				else
					footsiesconfig.movetype[2] = 1
				end
			elseif distance <= footsiesconfig.movegoaldistance then
				if math.random() > footsiesconfig.baseprobbwalktogoal + (math.abs(distance - footsiesconfig.movegoaldistance)/footsiesconfig.allowwalkrangeforward)^2*(1-footsiesconfig.baseprobbwalktogoal) then
					footsiesconfig.movetype[2] = 1
				else
					footsiesconfig.movetype[2] = 2
				end
			end
			footsiesconfig.walkcount = 1
		elseif footsiesconfig.walkcount < (footsiesconfig.walklimitfloor+walklimitnoise) then
			footsiesconfig.walkcount = footsiesconfig.walkcount + 1
		elseif footsiesconfig.walkcount >= (footsiesconfig.walklimitfloor+walklimitnoise) then
			footsiesconfig.walkcount = 0
		end
		if (distance > footsiesconfig.movegoaldistance) and (math.abs(distance - footsiesconfig.movegoaldistance) > footsiesconfig.allowwalkrangebackward) then
			footsiesconfig.movetype[2] = 1
			footsiesconfig.walkcount = footsiesconfig.walklimitfloor - 2
		elseif (distance <= footsiesconfig.movegoaldistance) and (math.abs(distance - footsiesconfig.movegoaldistance) > footsiesconfig.allowwalkrangeforward) then
			footsiesconfig.movetype[2] = 2
			footsiesconfig.walkcount = footsiesconfig.walklimitfloor - 2
		end
		if footsiesconfig.ifallowprewalk[1][footsiesconfig.ifallowprewalk[2]] then
			if footsiesconfig.prewalkcount == 0 then
				if (footsiesconfig.premovetype[2] == 1 and footsiesconfig.movetype[2] == 2) or (footsiesconfig.premovetype[2] == 2 and footsiesconfig.movetype[2] == 1) then
					if math.random() >= footsiesconfig.probprewalk then
						footsiesconfig.prewalkdir = footsiesconfig.movetype[2]
						footsiesconfig.movetype[2] = 3
						footsiesconfig.prewalkcount, footsiesconfig.walkcount = 1, 0
					end
				end
			elseif footsiesconfig.prewalkcount == 1 then
				footsiesconfig.movetype[2] = footsiesconfig.prewalkdir
				footsiesconfig.prewalkcount, footsiesconfig.walkcount = 0, 1
			end
		end
		if footsiesconfig.ifallowneutral[1][footsiesconfig.ifallowneutral[2]] then
			if footsiesconfig.neutralcount == 0 then
				if ((distance >= footsiesconfig.movegoaldistance) and (math.abs(distance-footsiesconfig.movegoaldistance) <= footsiesconfig.allowneutralrangebackward))
				or ((distance < footsiesconfig.movegoaldistance) and (math.abs(distance-footsiesconfig.movegoaldistance) <= footsiesconfig.allowneutralrangeforward)) then
					if math.random() <= footsiesconfig.probneutral then
						footsiesconfig.movetype[2] = 4
						footsiesconfig.neutralcount, footsiesconfig.walkcount = 1, 0
					end
				end
			elseif footsiesconfig.neutralcount < footsiesconfig.neutrallimitfloor then
				footsiesconfig.movetype[2] = 4
				footsiesconfig.neutralcount, footsiesconfig.walkcount = footsiesconfig.neutralcount + 1, 0
			elseif footsiesconfig.neutralcount >= footsiesconfig.neutrallimitfloor then
				if math.random() <= footsiesconfig.probkeepneutral then
					footsiesconfig.movetype[2] = 4
					footsiesconfig.neutralcount, footsiesconfig.walkcount = footsiesconfig.neutralcount + 1, 0
				else
					footsiesconfig.neutralcount = 0
				end
			end
		end
	elseif footsiesconfig.movemode[1][footsiesconfig.movemode[2]] == "stand" then
		footsiesconfig.movetype[2] = 4
	elseif footsiesconfig.movemode[1][footsiesconfig.movemode[2]] == "crouch" then
		footsiesconfig.movetype[2] = 5
	end
	if footsiesconfig.attackcount == 0 then
		if (math.abs(distance - footsiesconfig.attack1distance) <= footsiesconfig.allowattack1range) and (math.abs(distance - footsiesconfig.attack2distance) <= footsiesconfig.allowattack2range) then
			if math.random() <= footsiesconfig.baseprobattack*(footsiesconfig.attack1probratio+footsiesconfig.attack2probratio) then
				if math.random() > footsiesconfig.attack1probratio/(footsiesconfig.attack1probratio+footsiesconfig.attack2probratio) then
					footsiesconfig.attackstick, footsiesconfig.attackbutton, footsiesconfig.holdattackframe, footsiesconfig.blockframe = footsiesconfig.attack2stick, footsiesconfig.attack2button, footsiesconfig.attack2holdframe, footsiesconfig.attack2blockframe
				else
					footsiesconfig.attackstick, footsiesconfig.attackbutton, footsiesconfig.holdattackframe, footsiesconfig.blockframe = footsiesconfig.attack1stick, footsiesconfig.attack1button, footsiesconfig.attack1holdframe, footsiesconfig.attack1blockframe
				end
				if footsiesconfig.attackbutton[2] <= #buttons then
					footsiesconfig.movetype[2] = 6
					footsiesconfig.attackmode[2] = 1
					footsiesconfig.attackcount, footsiesconfig.walkcount = 1, 0
				else
					if #recordconfig.slot[footsiesconfig.attackbutton[2]-#buttons] > 0 then
						footsiesconfig.movetype[2] = 6
						footsiesconfig.attackmode[2] = 2
						footsiesconfig.attackcount, footsiesconfig.walkcount = 1, 0
					end
				end
			end
		elseif (math.abs(distance - footsiesconfig.attack1distance) <= footsiesconfig.allowattack1range) and (math.abs(distance - footsiesconfig.attack2distance) > footsiesconfig.allowattack2range) then
			if math.random() <= footsiesconfig.baseprobattack*footsiesconfig.attack1probratio then
				footsiesconfig.attackstick, footsiesconfig.attackbutton, footsiesconfig.holdattackframe, footsiesconfig.blockframe = footsiesconfig.attack1stick, footsiesconfig.attack1button, footsiesconfig.attack1holdframe, footsiesconfig.attack1blockframe
				if footsiesconfig.attackbutton[2] <= #buttons then
					footsiesconfig.movetype[2] = 6
					footsiesconfig.attackmode[2] = 1
					footsiesconfig.attackcount, footsiesconfig.walkcount = 1, 0
				else
					if #recordconfig.slot[footsiesconfig.attackbutton[2]-#buttons] > 0 then
						footsiesconfig.movetype[2] = 6
						footsiesconfig.attackmode[2] = 2
						footsiesconfig.attackcount, footsiesconfig.walkcount = 1, 0
					end
				end
			end
		elseif (math.abs(distance - footsiesconfig.attack1distance) > footsiesconfig.allowattack1range) and (math.abs(distance - footsiesconfig.attack2distance) <= footsiesconfig.allowattack2range) then
			if math.random() <= footsiesconfig.baseprobattack*footsiesconfig.attack2probratio then
				footsiesconfig.attackstick, footsiesconfig.attackbutton, footsiesconfig.holdattackframe, footsiesconfig.blockframe = footsiesconfig.attack2stick, footsiesconfig.attack2button, footsiesconfig.attack2holdframe, footsiesconfig.attack2blockframe
				if footsiesconfig.attackbutton[2] <= #buttons then
					footsiesconfig.movetype[2] = 6
					footsiesconfig.attackmode[2] = 1
					footsiesconfig.attackcount, footsiesconfig.walkcount = 1, 0
				else
					if #recordconfig.slot[footsiesconfig.attackbutton[2]-#buttons] > 0 then
						footsiesconfig.movetype[2] = 6
						footsiesconfig.attackmode[2] = 2
						footsiesconfig.attackcount, footsiesconfig.walkcount = 1, 0
					end
				end
			end
		end
	end
	if footsiesconfig.attackcount > 0 then
		if footsiesconfig.attackmode[1][footsiesconfig.attackmode[2]] == "normal" then
			if footsiesconfig.attackcount < footsiesconfig.holdattackframe then
				footsiesconfig.movetype[2] = 6
				footsiesconfig.attackcount, footsiesconfig.walkcount = footsiesconfig.attackcount + 1, 0
			elseif footsiesconfig.attackcount == footsiesconfig.holdattackframe then
				footsiesconfig.movetype[2] = 7
				footsiesconfig.blockcount = footsiesconfig.attackcount
				footsiesconfig.attackcount, footsiesconfig.walkcount = footsiesconfig.attackcount + 1, 0
			elseif footsiesconfig.blockcount ~= 0 then
				if footsiesconfig.blockcount < footsiesconfig.blockframe then
					footsiesconfig.movetype[2] = 7
					footsiesconfig.blockcount, footsiesconfig.walkcount = footsiesconfig.blockcount + 1, 0
				elseif footsiesconfig.blockcount >= footsiesconfig.blockframe then
					footsiesconfig.attackcount, footsiesconfig.blockcount = 0, 0
				end
			end
		elseif footsiesconfig.attackmode[1][footsiesconfig.attackmode[2]] == "playback" then
			if footsiesconfig.attackcount <= #recordconfig.slot[footsiesconfig.attackbutton[2]-6] then
				footsiesconfig.movetype[2] = 6
				footsiesconfig.attackcount, footsiesconfig.playbackcount, footsiesconfig.walkcount = footsiesconfig.attackcount + 1, footsiesconfig.playbackcount + 1, 0
			elseif footsiesconfig.attackcount > #recordconfig.slot[footsiesconfig.attackbutton[2]-6] then
				footsiesconfig.attackcount, footsiesconfig.playbackcount, footsiesconfig.blockcount = 0, 0, 0
			end
		end
	end
	footsiesconfig.premovetype[2] = footsiesconfig.movetype[2]
	--input opponent's move
	local input = joypad.get()
	if inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] then
		local swapinput = {}
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
	end
	local inp = {}
	local charadir = 0
	if not inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] then
		charadir = P2status.dir
	elseif inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] then
		charadir = P1status.dir
	end
	if footsiesconfig.movetype[1][footsiesconfig.movetype[2]] == "fwalk" then
		if charadir == "left" then
			inp = {"Left"}
		elseif charadir == "right" then
			inp = {"Right"}
		end
	elseif footsiesconfig.movetype[1][footsiesconfig.movetype[2]] == "bwalk" then
		if charadir == "left" then
			inp = {"Right"}
		elseif charadir == "right" then
			inp = {"Left"}
		end
	elseif footsiesconfig.movetype[1][footsiesconfig.movetype[2]] == "crouch" then
		if charadir == "left" then
			inp = {"Right", "Down"}
		elseif charadir == "right" then
			inp = {"Left", "Down"}
		end
	elseif footsiesconfig.movetype[1][footsiesconfig.movetype[2]] == "attack" then
		if footsiesconfig.attackmode[1][footsiesconfig.attackmode[2]] == "normal" then
			if charadir == "left" then
				if footsiesconfig.attackstick[1][footsiesconfig.attackstick[2]] == "db" then
					inp = {"Down", "Right"}
				elseif footsiesconfig.attackstick[1][footsiesconfig.attackstick[2]] == "d" then
					inp = {"Down"}
				elseif footsiesconfig.attackstick[1][footsiesconfig.attackstick[2]] == "df" then
					inp = {"Down", "Left"}
				elseif footsiesconfig.attackstick[1][footsiesconfig.attackstick[2]] == "b" then
					inp = {"Right"}
				elseif footsiesconfig.attackstick[1][footsiesconfig.attackstick[2]] == "f" then
					inp = {"Left"}
				end
			elseif charadir == "right" then
				if footsiesconfig.attackstick[1][footsiesconfig.attackstick[2]] == "db" then
					inp = {"Down", "Left"}
				elseif footsiesconfig.attackstick[1][footsiesconfig.attackstick[2]] == "d" then
					inp = {"Down"}
				elseif footsiesconfig.attackstick[1][footsiesconfig.attackstick[2]] == "df" then
					inp = {"Down", "Right"}
				elseif footsiesconfig.attackstick[1][footsiesconfig.attackstick[2]] == "b" then
					inp = {"Left"}
				elseif footsiesconfig.attackstick[1][footsiesconfig.attackstick[2]] == "f" then
					inp = {"Right"}
				end
			end
			for i = 1, #buttons do
				if footsiesconfig.attackbutton[1][footsiesconfig.attackbutton[2]] == buttons[i][2] then
					table.insert(inp, #inp+1, buttons[i][1])
				end
			end
		elseif footsiesconfig.attackmode[1][footsiesconfig.attackmode[2]] == "playback" then
			local playbackplayer, playbackinput
			for i,v in pairs(recordconfig.slot[footsiesconfig.attackbutton[2]-6][footsiesconfig.playbackcount]) do
				playbackplayer, playbackinput = i:sub(1,2), i:sub(4)
				if not inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] then
					if (playbackplayer == "P2") and (playbackinput ~= "Coin") then
						table.insert(inp, #inp+1, playbackinput)
					end
				elseif inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] then
					if (playbackplayer == "P1") and (playbackinput ~= "Coin") then
						table.insert(inp, #inp+1, playbackinput)
					end
				end
			end
			if charadir == "right" then
				for i,v in ipairs(inp) do
					if v == "Right" then
						table.remove(inp, i)
						table.insert(inp, i, "Left")
					elseif v == "Left" then
						table.remove(inp, i)
						table.insert(inp, i, "Right")
					end
				end
			end
		end
	elseif footsiesconfig.movetype[1][footsiesconfig.movetype[2]] == "block" then
		if footsiesconfig.blocktype[1][footsiesconfig.blocktype[2]] == "stand" then
			if charadir == "left" then
				inp = {"Right"}
			elseif charadir == "right" then
				inp = {"Left"}
			end
		elseif footsiesconfig.blocktype[1][footsiesconfig.blocktype[2]] == "crouch" then
			if charadir == "left" then
				inp = {"Down", "Right"}
			elseif charadir == "right" then
				inp = {"Down", "Left"}
			end
		elseif footsiesconfig.blocktype[1][footsiesconfig.blocktype[2]] == "jump" then
			if charadir == "left" then
				inp = {"Up", "Right"}
			elseif charadir == "right" then
				inp = {"Up", "Left"}
			end
		end
	end
	if not inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] then
		for i = 1, #inp do
			input["P2 "..inp[i]] = true
		end
	elseif inputconfig.ifswapinput[1][inputconfig.ifswapinput[2]] then
		for i = 1, #inp do
			input["P1 "..inp[i]] = true
		end
	end
	joypad.set(input)
end

---menu---*important
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

	if recordconfig.previousrecordstate then
		menuconfig.menuinput.P1.currentinput[buttons[1][1]] = true
		menuconfig.menuinput.P1.currentinput[buttons[2][1]] = true
		menuconfig.menuinput.P1.currentinput[buttons[3][1]] = true
		menuconfig.menuinput.P1.currentinput["Start"] = true
		menuconfig.menuinput.P1.currentinput["Up"] = true
		menuconfig.menuinput.P1.currentinput["Down"] = true
		menuconfig.menuinput.P1.currentinput["Left"] = true
		menuconfig.menuinput.P1.currentinput["Right"] = true
		menuconfig.menuinput.P2.currentinput[buttons[1][1]] = true
		menuconfig.menuinput.P2.currentinput[buttons[2][1]] = true
		menuconfig.menuinput.P2.currentinput[buttons[3][1]] = true
		menuconfig.menuinput.P2.currentinput["Start"] = true
		menuconfig.menuinput.P2.currentinput["Up"] = true
		menuconfig.menuinput.P2.currentinput["Down"] = true
		menuconfig.menuinput.P2.currentinput["Left"] = true
		menuconfig.menuinput.P2.currentinput["Right"] = true
	end
	--menu inputs (open)
	if luaconfig.showmenu[1][luaconfig.showmenu[2]] then
		menuconfig.menuinput.P1.holdstartframe = 0
		menuconfig.menuinput.P2.holdstartframe = 0
		--menu inputs (open)
		if not recordconfig.previousrecordstate then --not works after recording
			if (menuconfig.menuinput.P1.currentinput[buttons[1][1]] and not menuconfig.menuinput.P1.previousinput[buttons[1][1]])
			 or (menuconfig.menuinput.P2.currentinput[buttons[1][1]] and not menuconfig.menuinput.P2.previousinput[buttons[1][1]]) then --set the function of button1 in menu page
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
			if (menuconfig.menuinput.P1.currentinput[buttons[2][1]] and not menuconfig.menuinput.P1.previousinput[buttons[2][1]])
			 or (menuconfig.menuinput.P2.currentinput[buttons[2][1]] and not menuconfig.menuinput.P2.previousinput[buttons[2][1]]) then --set the function of button1 in menu page
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
						elseif menu.menuoption[menuconfig.currentmenuselection.option].buttonstartfunc then
							menu.menuoption[menuconfig.currentmenuselection.option].buttonstartfunc() -- execute the selected option in menu table
						end
					end
				else
					if submenu.submenuoption then
						if submenu.submenuoption[menuconfig.currentmenuselection.suboption].buttonfunc then
							submenu.submenuoption[menuconfig.currentmenuselection.suboption].buttonfunc() -- execute the selected option in submenu table
						elseif submenu.submenuoption[menuconfig.currentmenuselection.suboption].buttonstartfunc then
							submenu.submenuoption[menuconfig.currentmenuselection.suboption].buttonstartfunc() -- execute the selected option in submenu table
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
			if menuconfig.menuinput.P1.currentinput[buttons[3][1]]  or menuconfig.menuinput.P1.currentinput["Button 3"] or menuconfig.menuinput.P2.currentinput[buttons[3][1]] or menuconfig.menuinput.P2.currentinput["Button 3"] then
				if (menuconfig.menuinput.P1.currentinput["Left"] and not menuconfig.menuinput.P1.previousinput["Left"])
				 or (menuconfig.menuinput.P2.currentinput["Left"] and not menuconfig.menuinput.P2.previousinput["Left"]) then --set the function of up in menu page (change the selection of the option)
					if menuconfig.currentmenuselection.subpage == 0 then
						if menu.menuoption then
							if menu.menuoption[menuconfig.currentmenuselection.option].leftfuncfast then
								menu.menuoption[menuconfig.currentmenuselection.option].leftfuncfast() -- execute the selected option in menu table
							end
						end
					else
						if submenu.submenuoption then
							if submenu.submenuoption[menuconfig.currentmenuselection.suboption].leftfuncfast then
								submenu.submenuoption[menuconfig.currentmenuselection.suboption].leftfuncfast() -- execute the selected option in submenu table
							end
						end
					end
				end
				if (menuconfig.menuinput.P1.currentinput["Right"] and not menuconfig.menuinput.P1.previousinput["Right"])
				 or (menuconfig.menuinput.P2.currentinput["Right"] and not menuconfig.menuinput.P2.previousinput["Right"]) then --set the function of up in menu page (change the selection of the option)
					if menuconfig.currentmenuselection.subpage == 0 then
						if menu.menuoption then
							if menu.menuoption[menuconfig.currentmenuselection.option].rightfuncfast then
								menu.menuoption[menuconfig.currentmenuselection.option].rightfuncfast() -- execute the selected option in menu table
							end
						end
					else
						if submenu.submenuoption then
							if submenu.submenuoption[menuconfig.currentmenuselection.suboption].rightfuncfast then
								submenu.submenuoption[menuconfig.currentmenuselection.suboption].rightfuncfast() -- execute the selected option in submenu table
							end
						end
					end
				end
			else
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
			end
		end
	--menu inputs (close)
	elseif not luaconfig.showmenu[1][luaconfig.showmenu[2]] then
		if not recordconfig.ifrecording[1][recordconfig.ifrecording[2]] and not recordconfig.ifplayback[1][recordconfig.ifplayback[2]]
		 and not macroconfig.ifplayback[1][macroconfig.ifplayback[2]] and not footsiesconfig.iffootsies[1][footsiesconfig.iffootsies[2]] then --works when not recording, playback, macro and footsies
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
			if (menuconfig.menuinput.P1.currentinput["Coin"] and not menuconfig.menuinput.P1.previousinput["Coin"]) or (menuconfig.menuinput.P2.currentinput["Coin"] and not menuconfig.menuinput.P2.previousinput["Coin"]) then --set the function of coin in menu page
				P1status.ifrefillhealth[2] = 1
				P2status.ifrefillhealth[2] = 1
			end
			---hotkey
			input.registerhotkey(1, function()
				if not luaconfig.showmenu[1][luaconfig.showmenu[2]] then
					if (not recordconfig.ifrecording[1][recordconfig.ifrecording[2]]) and (not recordconfig.ifplayback[1][recordconfig.ifplayback[2]]) and (not macroconfig.ifplayback[1][macroconfig.ifplayback[2]]) and not (footsiesconfig.iffootsies[1][footsiesconfig.iffootsies[2]]) then
						menuconfig.menuinput.P1.holdstartframe = 0
						luaconfig.showmenu[2] = 1
					end
				end
			end)
		end
	end
	--menu input (recording)
	if recordconfig.ifrecording[1][recordconfig.ifrecording[2]] and recordconfig.timerbeforerecording ~= 0 then
		if (menuconfig.menuinput.P1.currentinput["Coin"] and not menuconfig.menuinput.P1.previousinput["Coin"]) or (menuconfig.menuinput.P2.currentinput["Coin"] and not menuconfig.menuinput.P2.previousinput["Coin"]) then --set the function of coin in menu page
			recordconfig.ifrecordend[2] = 1
		end
		input.registerhotkey(1, function()
			if recordconfig.ifrecording[1][recordconfig.ifrecording[2]] and recordconfig.timerbeforerecording ~= 0 then
				recordconfig.ifrecordend[2] = 1
			end
		end)
	end
	--menu input (playback)
	if recordconfig.ifplayback[1][recordconfig.ifplayback[2]] then
		if (menuconfig.menuinput.P1.currentinput["Coin"] and not menuconfig.menuinput.P1.previousinput["Coin"]) or (menuconfig.menuinput.P2.currentinput["Coin"] and not menuconfig.menuinput.P2.previousinput["Coin"]) then --set the function of coin in menu page
			recordconfig.ifplayback[2] = 2
			recordconfig.playbacktime = 1
			luaconfig.showmenu[2] = 1
		end
		input.registerhotkey(1, function()
			if recordconfig.ifplayback[1][recordconfig.ifplayback[2]] then
				recordconfig.ifplayback[2] = 2
				recordconfig.playbacktime = 1
				luaconfig.showmenu[2] = 1
			end
		end)
	end
	if macroconfig.ifplayback[1][macroconfig.ifplayback[2]] then
		if (menuconfig.menuinput.P1.currentinput["Coin"] and not menuconfig.menuinput.P1.previousinput["Coin"]) or (menuconfig.menuinput.P2.currentinput["Coin"] and not menuconfig.menuinput.P2.previousinput["Coin"]) then --set the function of coin in menu page
			macroconfig.ifplayback[2] = 2
			macroconfig.previousplaybackstate = false
			macroconfig.ifloadedstate[2] = 2
			macroconfig.playbacktime = 1
			macroconfig.waitcountbefore = 1
			macroconfig.waitcountafter = 1
			luaconfig.showmenu[2] = 1
		end
		input.registerhotkey(1, function()
			if macroconfig.ifplayback[1][macroconfig.ifplayback[2]] then
				macroconfig.ifplayback[2] = 2
				macroconfig.previousplaybackstate = false
				macroconfig.ifloadedstate[2] = 2
				macroconfig.playbacktime = 1
				macroconfig.waitcountbefore = 1
				macroconfig.waitcountafter = 1
				luaconfig.showmenu[2] = 1
			end
		end)
	end
	if footsiesconfig.iffootsies[1][footsiesconfig.iffootsies[2]] then
		if (menuconfig.menuinput.P1.currentinput["Coin"] and not menuconfig.menuinput.P1.previousinput["Coin"]) or (menuconfig.menuinput.P2.currentinput["Coin"] and not menuconfig.menuinput.P2.previousinput["Coin"]) then --set the function of coin in menu page
			footsiesconfig.iffootsies[2] = 2
			luaconfig.showmenu[2] = 1
		end
		input.registerhotkey(1, function()
			if footsiesconfig.iffootsies[1][footsiesconfig.iffootsies[2]] then
				footsiesconfig.iffootsies[2] = 2
				luaconfig.showmenu[2] = 1
			end
		end)
	end
	--get previous inputs
	menuconfig.menuinput.P1.previousinput = menuconfig.menuinput.P1.currentinput
	menuconfig.menuinput.P2.previousinput = menuconfig.menuinput.P2.currentinput
end

local function updatemenu()
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
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "Welcome to "..gamename.." training lua "..scriptver, textcol1 =  cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+16, text = "current ROM: "..emu.romname(), textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+32, text = "- manual -", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+40, text = " up/down - move the cursor", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+48, text = " left/right - change the selected option", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+56, text = " button1/Start - execute the selected option", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+64, text = " Start (hold) / hotkey 1 - open main menu", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+72, text = " button2 - close menu / back to main manu", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+80, text = " button3 (hold) - change the option value fast", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+96, text = "- menu -", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2}
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
			x = cd.textconfig.textleft, y = cd.menutext[#cd.menutext].y+24, text = " record setting",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 1
				menuconfig.currentmenuselection.subpage = 5
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.menutext[#cd.menutext].y+32, text = " HUD setting",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 1
				menuconfig.currentmenuselection.subpage = 7
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.menutext[#cd.menutext].y+40, text = " misc.", note = "This menu may includes an ongoing or messy porject.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 1
				menuconfig.currentmenuselection.subpage = 8
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.menutext[#cd.menutext].y+56, text = " credit",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 1
				menuconfig.currentmenuselection.subpage = 9
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.menutext[#cd.menutext].y+64, text = " close menu",
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
		boxheight = sh*0.55,
		boxleft = (sw-sw*0.35)*0.5+sw*0.10,
		boxtop = (sh-sh*0.55)*0.5
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
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+8, text = "* general", textcol1 =  0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+32, text = "* Player 1", textcol1 =  0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+72, text = "* Player 2", textcol1 =  0xb6fbd8ff, textcol2 = cd.textconfig.textcol2}
	}
	menuconfig.menupage[1].submenupage[1].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+16, text = "time: "..cheatconfig.time[1][cheatconfig.time[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.time[2] = lccalc(cheatconfig.time[2], #cheatconfig.time[1], -1)
			end,
			rightfunc = function()
				cheatconfig.time[2] = lccalc(cheatconfig.time[2], #cheatconfig.time[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+40, text = "P1health: "..cheatconfig.P1health[1][cheatconfig.P1health[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.P1health[2] = lccalc(cheatconfig.P1health[2], #cheatconfig.P1health[1], -1)
			end,
			rightfunc = function()
				cheatconfig.P1health[2] = lccalc(cheatconfig.P1health[2], #cheatconfig.P1health[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+48, text = "P1meter: "..cheatconfig.P1meter[1][cheatconfig.P1meter[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.P1meter[2] = lccalc(cheatconfig.P1meter[2], #cheatconfig.P1meter[1], -1)
			end,
			rightfunc = function()
				cheatconfig.P1meter[2] = lccalc(cheatconfig.P1meter[2], #cheatconfig.P1meter[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+56, text = "P1stun: "..cheatconfig.P1stun[1][cheatconfig.P1stun[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.P1stun[2] = lccalc(cheatconfig.P1stun[2], #cheatconfig.P1stun[1], -1)
			end,
			rightfunc = function()
				cheatconfig.P1stun[2] = lccalc(cheatconfig.P1stun[2], #cheatconfig.P1stun[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+80, text = "P2health: "..cheatconfig.P2health[1][cheatconfig.P2health[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.P2health[2] = lccalc(cheatconfig.P2health[2], #cheatconfig.P2health[1], -1)
			end,
			rightfunc = function()
				cheatconfig.P2health[2] = lccalc(cheatconfig.P2health[2], #cheatconfig.P2health[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+88, text = "P2meter: "..cheatconfig.P2meter[1][cheatconfig.P2meter[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.P2meter[2] = lccalc(cheatconfig.P2meter[2], #cheatconfig.P2meter[1], -1)
			end,
			rightfunc = function()
				cheatconfig.P2meter[2] = lccalc(cheatconfig.P2meter[2], #cheatconfig.P2meter[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+96, text = "P2stun: "..cheatconfig.P2stun[1][cheatconfig.P2stun[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.P2stun[2] = lccalc(cheatconfig.P2stun[2], #cheatconfig.P2stun[1], -1)
			end,
			rightfunc = function()
				cheatconfig.P2stun[2] = lccalc(cheatconfig.P2stun[2], #cheatconfig.P2stun[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+112, text = "next page",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 7
				menuconfig.currentmenuselection.subpage = 2
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+120, text = "back to main menu",
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
		boxheight = sh*0.45,
		boxleft = (sw-sw*0.45)*0.5+sw*0.10,
		boxtop = (sh-sh*0.45)*0.5
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
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+8, text = "* input", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
	}
	menuconfig.menupage[1].submenupage[2].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+16, text = "set disable input: "..menuifdisableinput[1][menuifdisableinput[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				inputconfig.ifdisableinputset[2] = lccalc(inputconfig.ifdisableinputset[2], #inputconfig.ifdisableinputset[1], -1)
			end,
			rightfunc = function()
				inputconfig.ifdisableinputset[2] = lccalc(inputconfig.ifdisableinputset[2], #inputconfig.ifdisableinputset[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+24, text = "set player disable input: "..inputconfig.disableinputplayer[1][inputconfig.disableinputplayer[2]], note = "You can't use the selected port to move cursor in menu.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				inputconfig.disableinputplayer[2] = lccalc(inputconfig.disableinputplayer[2], 3, -1)
			end,
			rightfunc = function()
				inputconfig.disableinputplayer[2] = lccalc(inputconfig.disableinputplayer[2], 3, 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+40, text = "set hold input: "..menuifholdinput[1][menuifholdinput[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				inputconfig.ifholdinputset[2] = lccalc(inputconfig.ifholdinputset[2], #inputconfig.ifholdinputset[1], -1)
			end,
			rightfunc = function()
				inputconfig.ifholdinputset[2] = lccalc(inputconfig.ifholdinputset[2], #inputconfig.ifholdinputset[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+48, text = "set player holding input: "..inputconfig.holdinputplayer[1][inputconfig.holdinputplayer[2]], note = "You can't use the selected port to move cursor in menu.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				inputconfig.holdinputplayer[2] = lccalc(inputconfig.holdinputplayer[2], 3, -1)
			end,
			rightfunc = function()
				inputconfig.holdinputplayer[2] = lccalc(inputconfig.holdinputplayer[2], 3, 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+56, text = "set holding direction: "..inputconfig.holddirection[1][inputconfig.holddirection[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				inputconfig.holddirection[2] = lccalc(inputconfig.holddirection[2], #inputconfig.holddirection[1], -1)
			end,
			rightfunc = function()
				inputconfig.holddirection[2] = lccalc(inputconfig.holddirection[2], #inputconfig.holddirection[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+72, text = "swap input: "..menuifswapinput[1][menuifswapinput[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				inputconfig.ifswapinput[2] = lccalc(inputconfig.ifswapinput[2], #inputconfig.ifswapinput[1], -1)
			end,
			rightfunc = function()
				inputconfig.ifswapinput[2] = lccalc(inputconfig.ifswapinput[2], #inputconfig.ifswapinput[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+88, text = "previous page",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 8
				menuconfig.currentmenuselection.subpage = 1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+96, text = "back to main menu",
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
		boxheight = sh*0.30,
		boxleft = (sw-sw*0.45)*0.5+sw*0.05,
		boxtop = (sh-sh*0.30)*0.5
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
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+8, text = "Disable music: set", note = "Press button1/Start to disable music.",
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
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+16, text = "Music Modifier: "..cheatconfig.selectmusic[1][cheatconfig.selectmusic[2]], note = "Choose an option in character select screen.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.selectmusic[2] = lccalc(cheatconfig.selectmusic[2], #cheatconfig.selectmusic[1], -1)
			end,
			rightfunc = function()
				cheatconfig.selectmusic[2] = lccalc(cheatconfig.selectmusic[2], #cheatconfig.selectmusic[1], 1)
			end
		},
		{ --stage modifier (*isuue: "Temple Ruins (Night)",  "Test Stage", and "A.N. Headquarters (Day)" doesn't work correctly)
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+32, text = "Stage Modifier: "..cheatconfig.selectstage[1][cheatconfig.selectstage[2]], note = "Choose an option in character select screen.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				cheatconfig.selectstage[2] = lccalc(cheatconfig.selectstage[2], #cheatconfig.selectstage[1], -1)
			end,
			rightfunc = function()
				cheatconfig.selectstage[2] = lccalc(cheatconfig.selectstage[2], #cheatconfig.selectstage[1], 1)
			end,
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+48, text = "next page",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.subpage, menuconfig.currentmenuselection.suboption = 4, 21
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+56, text = "back to main menu",
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
		boxheight = sh*0.60,
		boxleft = (sw-sw*0.60)*0.5+sw*0.05,
		boxtop = (sh-sh*0.60)*0.5
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
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+112, text = "previous page",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.suboption = 4
				menuconfig.currentmenuselection.subpage = 3
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.submenutext[#cd.submenutext].y+120, text = "back to main menu",
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
		boxwidth = sw*0.60,
		boxheight = sh*0.70,
		boxleft = (sw-sw*0.60)*0.5,
		boxtop = (sh-sh*0.70)*0.5
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
	local menurecordedslot =  {}
	for i = 1, 5 do
		if recordconfig.ifslotrecorded[i] then
			menurecordedslot[#menurecordedslot+1] = i
		end
	end
	if #menurecordedslot == 0 then
		menurecordedslot = {"none"}
	end
	local menuifshowrecordplayback = {{"yes", "no"}, 1}
	if recordconfig.ifshowplayback[1][recordconfig.ifshowplayback[2]] == true then
		menuifshowrecordplayback[2] = 1
	elseif recordconfig.ifshowplayback[1][recordconfig.ifshowplayback[2]] == false then
		menuifshowrecordplayback[2] = 2
	end
	local menuifsavestateexist = {{"[save file exists.]", "[not saved yet.]"}, 1}
	if iffileexist(emu.romname().."_recording.fs") == true then
		menuifsavestateexist[2] = 1
	else
		menuifsavestateexist[2] = 2
	end
	menuconfig.menupage[1].submenupage[5].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- record setting -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+8, text = "* savestate", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+56, text = "* recording", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+64, text = "[ recorded slot(s): "..table.concat(menurecordedslot, ", ").." ]", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+104, text = "* playback", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2}
	}
	menuconfig.menupage[1].submenupage[5].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+16, text = "save the current state "..menuifsavestateexist[1][menuifsavestateexist[2]], note = "Press Start to save.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonstartfunc = function()
				if iffileexist(emu.romname().."_recording.fs") then
					os.rename(emu.romname().."_recording.fs", emu.romname().."_recording_backup.fs")
				end
				savestate.save(savestate.create(emu.romname().."_recording.fs"))
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+24, text = "load the saved state", note = "Press Start to load.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonstartfunc = function()
				if iffileexist(emu.romname().."_recording.fs") then
					savestate.load(savestate.create(emu.romname().."_recording.fs"))
				end
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+32, text = "delete the saved state", note = "Press Start to delete.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonstartfunc = function()
				if iffileexist(emu.romname().."_recording.fs") then
					os.rename(emu.romname().."_recording.fs", emu.romname().."_recording_.backup.fs")
					os.remove(emu.romname().."_recording.fs")
				end
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+40, text = "load the state before recording/playback: "..recordconfig.ifloadstatebefore[1][recordconfig.ifloadstatebefore[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				recordconfig.ifloadstatebefore[2] = lccalc(recordconfig.ifloadstatebefore[2], #recordconfig.ifloadstatebefore[1], -1)
			end,
			rightfunc = function()
				recordconfig.ifloadstatebefore[2] = lccalc(recordconfig.ifloadstatebefore[2], #recordconfig.ifloadstatebefore[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+72, text = "frame(s) before recording: "..recordconfig.framebeforerecording,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				recordconfig.framebeforerecording = lccalc(recordconfig.framebeforerecording -19, 41, -1) + 19
			end,
			rightfunc = function()
				recordconfig.framebeforerecording = lccalc(recordconfig.framebeforerecording -19, 41, 1) + 19
			end,
			leftfuncfast = function()
				recordconfig.framebeforerecording = lccalc(recordconfig.framebeforerecording -19, 41, -10) + 19
			end,
			rightfuncfast = function()
				recordconfig.framebeforerecording = lccalc(recordconfig.framebeforerecording -19, 41, 10) + 19
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+80, text = "record slot: "..recordconfig.recordslot, note = "Press button1/Start to start recording. Press coin to stop recording",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
					recordconfig.recordslot = lccalc(recordconfig.recordslot, #recordconfig.slot, -1)
			end,
			rightfunc = function()
				recordconfig.recordslot = lccalc(recordconfig.recordslot, #recordconfig.slot, 1)
			end,
			buttonfunc = function()
				recordconfig.ifrecording[2] = 1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+88, text = "delete recorded slot: "..recordconfig.deleteslot, note = "Press button1/Start to delete recording.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				recordconfig.deleteslot = lccalc(recordconfig.deleteslot, #recordconfig.slot, -1)
			end,
			rightfunc = function()
				recordconfig.deleteslot = lccalc(recordconfig.deleteslot, #recordconfig.slot, 1)
			end,
			buttonfunc = function()
				recordconfig.slot[recordconfig.deleteslot] = {}
				recordconfig.ifslotrecorded[recordconfig.deleteslot] = false
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+112, text = "playback style: "..recordconfig.playbackstyle[1][recordconfig.playbackstyle[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				recordconfig.playbackstyle[2] = lccalc(recordconfig.playbackstyle[2], #recordconfig.playbackstyle[1], -1)
			end,
			rightfunc = function()
				recordconfig.playbackstyle[2] = lccalc(recordconfig.playbackstyle[2], #recordconfig.playbackstyle[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+120, text = "display playback: "..menuifshowrecordplayback[1][menuifshowrecordplayback[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				recordconfig.ifshowplayback[2] = lccalc(recordconfig.ifshowplayback[2], #recordconfig.ifshowplayback[1], -1)
			end,
			rightfunc = function()
				recordconfig.ifshowplayback[2] = lccalc(recordconfig.ifshowplayback[2], #recordconfig.ifshowplayback[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+128, text = "playback slot: "..recordconfig.playbackslot, note = "Press button1/Start to start playback. Press coin to stop playback",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				recordconfig.playbackslot = lccalc(recordconfig.playbackslot, #recordconfig.slot, -1)
			end,
			rightfunc = function()
				recordconfig.playbackslot = lccalc(recordconfig.playbackslot, #recordconfig.slot, 1)
			end,
			buttonfunc = function()
					recordconfig.ifplayback[2] = 1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+144, text = "next page",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.subpage, menuconfig.currentmenuselection.suboption = 6, 14
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+152, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 3
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	---page 1-6 (macro setting)
	menuconfig.menupage[1].submenupage[6] = {}
	cd = menuconfig.menupage[1].submenupage[6]
	menuconfig.menupage[1].submenupage[6].boxconfig = { --submenu box config
		bgcolor = 0xc7c7d1ee,
		frcolor = 0x52527aff,
		notebgcolor = 0xc7d1d1ee,
		notefrcolor = 0x527a7aff,
		boxwidth = sw*0.70,
		boxheight = sh*0.75,
		boxleft = (sw-sw*0.70)*0.5,
		boxtop = (sh-sh*0.75)*0.5-sh*0.025
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
	local menuifdefaultsavestateexist = {{"[default.fs already exists.]", "[default.fs is not created yet.]"}, 1}
	if iffileexist(emu.romname().."_macro_default.fs") == true then
		menuifdefaultsavestateexist[2] = 1
	else
		menuifdefaultsavestateexist[2] = 2
	end
	local menusavestatefile = {{macroconfig.savestatelist[macroconfig.loadstateslot], "[no macro file found.]"}, 1}
	if macroconfig.loadstateslot == 0 then
		menusavestatefile[2] = 2
	else
		menusavestatefile[2] = 1
		menusavestatefile[1][1] = menusavestatefile[1][1]:match("(.*[.])")
		menusavestatefile[1][1] = menusavestatefile[1][1]:sub(1, #menusavestatefile[1][1]-1)
		if #menusavestatefile[1][1] > 36 then
			menusavestatefile[1][1] = menusavestatefile[1][1]:sub(1, 36).."..."
		end
	end
	local menumacrofile = {{macroconfig.macrolist[macroconfig.playbackslot], "[no macro file found.]"}, 1}
	if macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] then
		menumacrofile = {{macroconfig.macrolistsorted[macroconfig.playbackslot], "[no macro file found.]"}, 1}
	end
	if macroconfig.playbackslot == 0 then
		menumacrofile[2] = 2
	else
		menumacrofile[2] = 1
		menumacrofile[1][1] = menumacrofile[1][1]:match("(.*[.])")
		menumacrofile[1][1] = menumacrofile[1][1]:sub(1, #menumacrofile[1][1]-1)
		if #menumacrofile[1][1] > 36 then
			menumacrofile[1][1] = menumacrofile[1][1]:sub(1, 36).."..."
		end
	end
	local menuifsortmacrofile = {{"yes", "no"}, 2}
	if macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] == true then
		menuifsortmacrofile[2] = 1
	elseif macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] == false then
		menuifsortmacrofile[2] = 2
	end
	local menuifshowmacroplayback = {{"yes", "no"}, 1}
	if macroconfig.ifshowplayback[1][macroconfig.ifshowplayback[2]] == true then
		menuifshowmacroplayback[2] = 1
	elseif macroconfig.ifshowplayback[1][macroconfig.ifshowplayback[2]] == false then
		menuifshowmacroplayback[2] = 2
	end
	menuconfig.menupage[1].submenupage[6].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- macro setting -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+8, text = "* general", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+48, text = "* savestate", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+96, text = "* macro", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2}
	}
	menuconfig.menupage[1].submenupage[6].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+16, text = "update the file list: set", note = "Press Start to check the list of the directory this script exists in.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonstartfunc = function()
				luaconfig.updatefilelist[2] = 1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+24, text = "search macro file(s) start with the savestate name: "..menuifsortmacrofile[1][menuifsortmacrofile[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				macroconfig.playbackslot = 1
				macroconfig.ifsortmacrofile[2] = lccalc(macroconfig.ifsortmacrofile[2], #macroconfig.ifsortmacrofile[1], -1)
			end,
			rightfunc = function()
				macroconfig.playbackslot = 1
				macroconfig.ifsortmacrofile[2] = lccalc(macroconfig.ifsortmacrofile[2], #macroconfig.ifsortmacrofile[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+32, text = "display playback: "..menuifshowmacroplayback[1][menuifshowmacroplayback[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				macroconfig.ifshowplayback[2] = lccalc(macroconfig.ifshowplayback[2], #macroconfig.ifshowplayback[1], -1)
			end,
			rightfunc = function()
				macroconfig.ifshowplayback[2] = lccalc(macroconfig.ifshowplayback[2], #macroconfig.ifshowplayback[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+56, text = "save the current state "..menuifdefaultsavestateexist[1][menuifdefaultsavestateexist[2]], note = "Press Start to create "..emu.romname().."_macro_default.fs",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonstartfunc = function()
				if iffileexist(emu.romname().."_macro_default.fs") then
					if iffileexist(emu.romname().."_macro_default_backup.fs") then
						os.remove(emu.romname().."_macro_default_backup.fs")
					end
					os.rename(emu.romname().."_macro_default.fs", emu.romname().."_macro_default_backup.fs")
				end
				savestate.save(savestate.create(emu.romname().."_macro_default.fs"))
				luaconfig.updatefilelist[2] = 1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+64, text = "load the state: "..menusavestatefile[1][menusavestatefile[2]], note = "Press Start to load.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonstartfunc = function()
				if macroconfig.loadstateslot ~= 0 then
					if iffileexist(macroconfig.savestatelist[macroconfig.loadstateslot]) then
						savestate.load(savestate.create(macroconfig.savestatelist[macroconfig.loadstateslot]))
					end
				end
			end,
			leftfunc = function()
				if macroconfig.loadstateslot ~= 0 then
					macroconfig.loadstateslot = lccalc(macroconfig.loadstateslot, #macroconfig.savestatelist, -1)
					if macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] then
						macroconfig.playbackslot = 1
					end
				end
			end,
			rightfunc = function()
				if macroconfig.loadstateslot ~= 0 then
					macroconfig.loadstateslot = lccalc(macroconfig.loadstateslot, #macroconfig.savestatelist, 1)
					if macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] then
						macroconfig.playbackslot = 1
					end
				end
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+72, text = "delete the default saved state", note = "Press Start to delete "..emu.romname().."_macro_default.fs",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonstartfunc = function()
				if iffileexist(emu.romname().."_macro_default.fs") then
					os.rename(emu.romname().."_macro_default.fs", emu.romname().."_macro_default_backup.fs")
					os.remove(emu.romname().."_macro_default.fs")
					luaconfig.updatefilelist[2] = 1
				end
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+80, text = "load the state before playback: "..macroconfig.ifloadstatebefore[1][macroconfig.ifloadstatebefore[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				macroconfig.ifloadstatebefore[2] = lccalc(macroconfig.ifloadstatebefore[2], #macroconfig.ifloadstatebefore[1], -1)
			end,
			rightfunc = function()
				macroconfig.ifloadstatebefore[2] = lccalc(macroconfig.ifloadstatebefore[2], #macroconfig.ifloadstatebefore[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+104, text = "create a new macro file: set", note = "Press Start to create "..emu.romname().."_macro_default_(time).mis",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonstartfunc = function()
				local currenttime = os.date("%Y%m%d%H%M%S")
				if iffileexist(emu.romname().."_macro_default_"..currenttime..".mis") then
					os.rename(emu.romname().."_macro_default_"..currenttime..".mis", emu.romname().."_macro_default_"..currenttime.."_backup.mis")
				end
				f = io.open(emu.romname().."_macro_default_"..currenttime..".mis", "w")
				f:write("#"..emu.romname().." - "..currenttime.."\n\n")
				f:write("#U: up, D: down, L: left, R: right\n#")
				for i,v in ipairs(buttons) do
					f:write(i..": "..v[2]..", ")
				end
				f:write("S: Start\n")
				f:write("#X: not receive any input from the controller\n")
				f:write("#_@: hold @, ^@: release @, (@)n: repeat @ n times\n")
				f:write("#(@)?[m-n]: repeat @ a random number of times between m and n\n")
				f:write("#{A|B}: choose A or B at random\n")
				f:write("#period(.): advance one frame, Wn: advance n frame(s)\n")
				f:write("#commas, whitespaces, tabs and newlines can be used for spacing\n\n")
				f:write("<\n#Player1\n\n/#Player2\n\n>")
				f:close()
				luaconfig.updatefilelist[2] = 1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+112, text = "playback macro: "..menumacrofile[1][menumacrofile[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				if macroconfig.playbackslot ~= 0 then
					if macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] then
						macroconfig.playbackslot = lccalc(macroconfig.playbackslot, #macroconfig.macrolistsorted, -1)
					else
						macroconfig.playbackslot = lccalc(macroconfig.playbackslot, #macroconfig.macrolist, -1)
					end
				end
			end,
			rightfunc = function()
				if macroconfig.playbackslot ~= 0 then
					if macroconfig.ifsortmacrofile[1][macroconfig.ifsortmacrofile[2]] then
						macroconfig.playbackslot = lccalc(macroconfig.playbackslot, #macroconfig.macrolistsorted, 1)
					else
						macroconfig.playbackslot = lccalc(macroconfig.playbackslot, #macroconfig.macrolist, 1)
					end
				end
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+120, text = "playback style: "..macroconfig.playbackstyle[1][macroconfig.playbackstyle[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				macroconfig.playbackstyle[2] = lccalc(macroconfig.playbackstyle[2], #macroconfig.playbackstyle[1], -1)
			end,
			rightfunc = function()
				macroconfig.playbackstyle[2] = lccalc(macroconfig.playbackstyle[2], #macroconfig.playbackstyle[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+128, text = "frame(s) before playback: "..macroconfig.waitframebefore,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				macroconfig.waitframebefore = lccalc(macroconfig.waitframebefore +1, 301, -1) - 1
			end,
			rightfunc = function()
				macroconfig.waitframebefore = lccalc(macroconfig.waitframebefore +1, 301, 1) - 1
			end,
			leftfuncfast = function()
				macroconfig.waitframebefore = lccalc(macroconfig.waitframebefore +1, 301, -10) - 1
			end,
			rightfuncfast = function()
				macroconfig.waitframebefore = lccalc(macroconfig.waitframebefore +1, 301, 10) - 1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+136, text = "frame(s) after playback: "..macroconfig.waitframeafter,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				macroconfig.waitframeafter = lccalc(macroconfig.waitframeafter +1, 901, -1) - 1
			end,
			rightfunc = function()
				macroconfig.waitframeafter = lccalc(macroconfig.waitframeafter +1, 901, 1) - 1
			end,
			leftfuncfast = function()
				macroconfig.waitframeafter = lccalc(macroconfig.waitframeafter +1, 901, -10) - 1
			end,
			rightfuncfast = function()
				macroconfig.waitframeafter = lccalc(macroconfig.waitframeafter +1, 901, 10) - 1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+144, text = "playback: set", note = "Press button1/Start to start playback. Press coin to stop playback",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
					macroconfig.ifplayback[2] = 1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+160, text = "previous page",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.subpage, menuconfig.currentmenuselection.suboption = 5, 11
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+168, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 2
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	---page 1-7 (HUD setting)
	menuconfig.menupage[1].submenupage[7] = {}
	cd = menuconfig.menupage[1].submenupage[7]
	menuconfig.menupage[1].submenupage[7].boxconfig = { --submenu box config
		bgcolor = 0xc7c7d1ee,
		frcolor = 0x52527aff,
		notebgcolor = 0xc7d1d1ee,
		notefrcolor = 0x527a7aff,
		boxwidth = sw*0.40,
		boxheight = sh*0.45,
		boxleft = (sw-sw*0.40)*0.5+sw*0.05,
		boxtop = (sh-sh*0.45)*0.5
	}
	menuconfig.menupage[1].submenupage[7].textconfig = { --submenu text config
		textleft = cd.boxconfig.boxleft+16,
		texttop = cd.boxconfig.boxtop+8,
		textcol1 = 0xffffffff,
		textcol2 = 0x000000ff,
		textselectedcol1 = 0xb3d9ffff,
		textselectedcol2 = 0x000000ff,
		textnotecol1 = 0xffffffff,
		textnotecol2 = 0x000000ff
	}
	local menuifshowhud, menuifshowdarklayer, menuifshowinput = {{"yes", "no"}, 1}, {{"yes", "no"}, 1}, {{"yes", "no"}, 1}
	if luaconfig.showhud[1][luaconfig.showhud[2]] == true then
		menuifshowhud[2] = 1
	elseif luaconfig.showhud[1][luaconfig.showhud[2]] == false then
		menuifshowhud[2] = 2
	end
	if hudconfig.ifshowdarklayer[1][hudconfig.ifshowdarklayer[2]] == true then
		menuifshowdarklayer[2] = 1
	elseif hudconfig.ifshowdarklayer[1][hudconfig.ifshowdarklayer[2]] == false then
		menuifshowdarklayer[2] = 2
	end
	if hudconfig.ifshowinput[1][hudconfig.ifshowinput[2]] == true then
		menuifshowinput[2] = 1
	elseif hudconfig.ifshowinput[1][hudconfig.ifshowinput[2]] == false then
		menuifshowinput[2] = 2
	end
	menuconfig.menupage[1].submenupage[7].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- HUD setting -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+8, text = "* general", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+56, text = "* input", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2}
	}
	menuconfig.menupage[1].submenupage[7].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+16, text = "show HUD: "..menuifshowhud[1][menuifshowhud[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				luaconfig.showhud[2] = lccalc(luaconfig.showhud[2], #luaconfig.showhud[1], -1)
			end,
			rightfunc = function()
				luaconfig.showhud[2] = lccalc(luaconfig.showhud[2], #luaconfig.showhud[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+24, text = "HUD style: "..hudconfig.hudstyle[1][hudconfig.hudstyle[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				hudconfig.hudstyle[2] = lccalc(hudconfig.hudstyle[2], #hudconfig.hudstyle[1], -1)
			end,
			rightfunc = function()
				hudconfig.hudstyle[2] = lccalc(hudconfig.hudstyle[2], #hudconfig.hudstyle[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+32, text = "show dark layer: "..menuifshowdarklayer[1][menuifshowdarklayer[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				hudconfig.ifshowdarklayer[2] = lccalc(hudconfig.ifshowdarklayer[2], #hudconfig.ifshowdarklayer[1], -1) --#hudconfig.hudstyle[1]
			end,
			rightfunc = function()
				hudconfig.ifshowdarklayer[2] = lccalc(hudconfig.ifshowdarklayer[2], #hudconfig.ifshowdarklayer[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+40, text = "dark layer transparency: "..tostring(hudconfig.darklayertransparency),
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				hudconfig.darklayertransparency = lccalc(hudconfig.darklayertransparency +1, 256, -1) - 1
			end,
			rightfunc = function()
				hudconfig.darklayertransparency = lccalc(hudconfig.darklayertransparency +1, 256, 1) - 1
			end,
			leftfuncfast = function()
				hudconfig.darklayertransparency = lccalc(hudconfig.darklayertransparency +1, 256, -10) - 1
			end,
			rightfuncfast = function()
				hudconfig.darklayertransparency = lccalc(hudconfig.darklayertransparency +1, 256, 10) - 1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+64, text = "show input: "..menuifshowinput[1][menuifshowinput[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				hudconfig.ifshowinput[2] = lccalc(hudconfig.ifshowinput[2], #hudconfig.ifshowinput[1], -1)
			end,
			rightfunc = function()
				hudconfig.ifshowinput[2] = lccalc(hudconfig.ifshowinput[2], #hudconfig.ifshowinput[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+72, text = "input style: "..hudconfig.inputstyle[1][hudconfig.inputstyle[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				hudconfig.inputstyle[2] = lccalc(hudconfig.inputstyle[2], #hudconfig.inputstyle[1], -1)
			end,
			rightfunc = function()
				hudconfig.inputstyle[2] = lccalc(hudconfig.inputstyle[2], #hudconfig.inputstyle[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+88, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 4
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	---page 1-8 (misc.)
	menuconfig.menupage[1].submenupage[8] = {}
	cd = menuconfig.menupage[1].submenupage[8]
	menuconfig.menupage[1].submenupage[8].boxconfig = { --submenu box config
		bgcolor = 0xc7c7d1ee,
		frcolor = 0x52527aff,
		notebgcolor = 0xc7d1d1ee,
		notefrcolor = 0x527a7aff,
		boxwidth = sw*0.70,
		boxheight = sh*0.80,
		boxleft = (sw-sw*0.70)*0.5+sw*0.05,
		boxtop = (sh-sh*0.80)*0.5-sh*0.01
	}
	menuconfig.menupage[1].submenupage[8].textconfig = { --submenu text config
		textleft = cd.boxconfig.boxleft+16,
		texttop = cd.boxconfig.boxtop+8,
		textcol1 = 0xffffffff,
		textcol2 = 0x000000ff,
		textselectedcol1 = 0xb3d9ffff,
		textselectedcol2 = 0x000000ff,
		textnotecol1 = 0xffffffff,
		textnotecol2 = 0x000000ff
	}
	local menuifallowprewalk, menuifallowneutral = {{"yes", "no"}, 1}, {{"yes", "no"}, 1}
	if footsiesconfig.ifallowprewalk[1][footsiesconfig.ifallowprewalk[2]] == true then
		menuifallowprewalk[2] = 1
	elseif footsiesconfig.ifallowprewalk[1][footsiesconfig.ifallowprewalk[2]] == false then
		menuifallowprewalk[2] = 2
	end
	if footsiesconfig.ifallowneutral[1][footsiesconfig.ifallowneutral[2]] == true then
		menuifallowneutral[2] = 1
	elseif footsiesconfig.ifallowneutral[1][footsiesconfig.ifallowneutral[2]] == false then
		menuifallowneutral[2] = 2
	end
	menuconfig.menupage[1].submenupage[8].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- Footsies! -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+24, text = "* general", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+56, text = "* attack", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+24, text = "* block", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+56, text = "* walk", textcol1 = 0xb6fbd8ff, textcol2 = cd.textconfig.textcol2},
	}
	menuconfig.menupage[1].submenupage[8].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+8, text = "play foosies: set", note = "Press button1/Start to start footsies. Press coin to end foosies.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				footsiesconfig.iffootsies[2] = 1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+32, text = "move mode: "..footsiesconfig.movemode[1][footsiesconfig.movemode[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.movemode[2] = lccalc(footsiesconfig.movemode[2], #footsiesconfig.movemode[1], -1)
			end,
			rightfunc = function()
				footsiesconfig.movemode[2] = lccalc(footsiesconfig.movemode[2], #footsiesconfig.movemode[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+40, text = "reaction delay: "..footsiesconfig.reactiondelay,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.previousreactiondelay = footsiesconfig.reactiondelay
				footsiesconfig.reactiondelay = lccalc(footsiesconfig.reactiondelay + 1, 31, -1) -1
			end,
			rightfunc = function()
				footsiesconfig.previousreactiondelay = footsiesconfig.reactiondelay
				footsiesconfig.reactiondelay = lccalc(footsiesconfig.reactiondelay + 1, 31, 1) -1
			end,
			leftfuncfast= function()
				footsiesconfig.previousreactiondelay = footsiesconfig.reactiondelay
				footsiesconfig.reactiondelay = lccalc(footsiesconfig.reactiondelay + 1, 31, -10) -1
			end,
			rightfuncfast = function()
				footsiesconfig.previousreactiondelay = footsiesconfig.reactiondelay
				footsiesconfig.reactiondelay = lccalc(footsiesconfig.reactiondelay + 1, 31, 10) -1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+48, text = "show infomation: "..footsiesconfig.ifshowinfo[1][footsiesconfig.ifshowinfo[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.ifshowinfo[2] = lccalc(footsiesconfig.ifshowinfo[2], #footsiesconfig.ifshowinfo[1], -1)
			end,
			rightfunc = function()
				footsiesconfig.ifshowinfo[2] = lccalc(footsiesconfig.ifshowinfo[2], #footsiesconfig.ifshowinfo[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+64, text = "attack prob.: "..footsiesconfig.baseprobattack,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.baseprobattack = (lccalc(footsiesconfig.baseprobattack*100 + 1, 101, -1) -1)/100
			end,
			rightfunc = function()
				footsiesconfig.baseprobattack = (lccalc(footsiesconfig.baseprobattack*100 + 1, 101, 1) -1)/100
			end,
			leftfuncfast = function()
				footsiesconfig.baseprobattack = (lccalc(footsiesconfig.baseprobattack*100 + 1, 101, -10) -1)/100
			end,
			rightfuncfast = function()
				footsiesconfig.baseprobattack = (lccalc(footsiesconfig.baseprobattack*100 + 1, 101, 10) -1)/100
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+72, text = "attack1 input (stick): "..footsiesconfig.attack1stick[1][footsiesconfig.attack1stick[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.attack1stick[2] = lccalc(footsiesconfig.attack1stick[2], #footsiesconfig.attack1stick[1], -1)
			end,
			rightfunc = function()
				footsiesconfig.attack1stick[2] = lccalc(footsiesconfig.attack1stick[2], #footsiesconfig.attack1stick[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+80, text = "attack1 input (button): "..footsiesconfig.attack1button[1][footsiesconfig.attack1button[2]], note = "record when the dummy is on the right side to make the 'slot' options work correctly.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.attack1button[2] = lccalc(footsiesconfig.attack1button[2], #footsiesconfig.attack1button[1], -1)
			end,
			rightfunc = function()
				footsiesconfig.attack1button[2] = lccalc(footsiesconfig.attack1button[2], #footsiesconfig.attack1button[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+88, text = "attack1 distance: "..footsiesconfig.attack1distance,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.attack1distance = lccalc(footsiesconfig.attack1distance +1, 301, -1) -1
			end,
			rightfunc = function()
				footsiesconfig.attack1distance = lccalc(footsiesconfig.attack1distance +1, 301, 1) -1
			end,
			leftfuncfast = function()
				footsiesconfig.attack1distance = lccalc(footsiesconfig.attack1distance +1, 301, -10) -1
			end,
			rightfuncfast = function()
				footsiesconfig.attack1distance = lccalc(footsiesconfig.attack1distance +1, 301, 10) -1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+96, text = "range allows attack1: +/-"..footsiesconfig.allowattack1range,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.allowattack1range = lccalc(footsiesconfig.allowattack1range, 100, -1)
			end,
			rightfunc = function()
				footsiesconfig.allowattack1range = lccalc(footsiesconfig.allowattack1range, 100, 1)
			end,
			leftfuncfast = function()
				footsiesconfig.allowattack1range = lccalc(footsiesconfig.allowattack1range, 100, -10)
			end,
			rightfuncfast = function()
				footsiesconfig.allowattack1range = lccalc(footsiesconfig.allowattack1range, 100, 10)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+104, text = "attack1 hold frame: "..footsiesconfig.attack1holdframe,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.attack1holdframe = lccalc(footsiesconfig.attack1holdframe, 60, -1)
			end,
			rightfunc = function()
				footsiesconfig.attack1holdframe = lccalc(footsiesconfig.attack1holdframe, 60, 1)
			end,
			leftfuncfast = function()
				footsiesconfig.attack1holdframe = lccalc(footsiesconfig.attack1holdframe, 60, -10)
			end,
			rightfuncfast = function()
				footsiesconfig.attack1holdframe = lccalc(footsiesconfig.attack1holdframe, 60, 10)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+112, text = "attack1 prob. ratio: "..footsiesconfig.attack1probratio,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.attack1probratio = (lccalc(footsiesconfig.attack1probratio*100 + 1, 101, -1) -1)/100
			end,
			rightfunc = function()
				footsiesconfig.attack1probratio = (lccalc(footsiesconfig.attack1probratio*100 + 1, 101, 1) -1)/100
			end,
			leftfuncfast = function()
				footsiesconfig.attack1probratio = (lccalc(footsiesconfig.attack1probratio*100 + 1, 101, -10) -1)/100
			end,
			rightfuncfast = function()
				footsiesconfig.attack1probratio = (lccalc(footsiesconfig.attack1probratio*100 + 1, 101, 10) -1)/100
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+120, text = "attack2 input (stick): "..footsiesconfig.attack2stick[1][footsiesconfig.attack2stick[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.attack2stick[2] = lccalc(footsiesconfig.attack2stick[2], #footsiesconfig.attack2stick[1], -1)
			end,
			rightfunc = function()
				footsiesconfig.attack2stick[2] = lccalc(footsiesconfig.attack2stick[2], #footsiesconfig.attack2stick[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+128, text = "attack2 input (button): "..footsiesconfig.attack2button[1][footsiesconfig.attack2button[2]], note = "record when the dummy is on the right side to make the 'slot' options work correctly.",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.attack2button[2] = lccalc(footsiesconfig.attack2button[2], #footsiesconfig.attack2button[1], -1)
			end,
			rightfunc = function()
				footsiesconfig.attack2button[2] = lccalc(footsiesconfig.attack2button[2], #footsiesconfig.attack2button[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+136, text = "attack2 distance: "..footsiesconfig.attack2distance,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.attack2distance = lccalc(footsiesconfig.attack2distance +1, 301, -1) -1
			end,
			rightfunc = function()
				footsiesconfig.attack2distance = lccalc(footsiesconfig.attack2distance +1, 301, 1) -1
			end,
			leftfuncfast = function()
				footsiesconfig.attack2distance = lccalc(footsiesconfig.attack2distance +1, 301, -10) -1
			end,
			rightfuncfast = function()
				footsiesconfig.attack2distance = lccalc(footsiesconfig.attack2distance +1, 301, 10) -1
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+144, text = "range allows attack2: +/-"..footsiesconfig.allowattack2range,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.allowattack2range = lccalc(footsiesconfig.allowattack2range, 100, -1)
			end,
			rightfunc = function()
				footsiesconfig.allowattack2range = lccalc(footsiesconfig.allowattack2range, 100, 1)
			end,
			leftfuncfast = function()
				footsiesconfig.allowattack2range = lccalc(footsiesconfig.allowattack2range, 100, -10)
			end,
			rightfuncfast = function()
				footsiesconfig.allowattack2range = lccalc(footsiesconfig.allowattack2range, 100, 10)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+152, text = "attack2 hold frame: "..footsiesconfig.attack2holdframe,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.attack2holdframe = lccalc(footsiesconfig.attack2holdframe, 60, -1)
			end,
			rightfunc = function()
				footsiesconfig.attack2holdframe = lccalc(footsiesconfig.attack2holdframe, 60, 1)
			end,
			leftfuncfast = function()
				footsiesconfig.attack2holdframe = lccalc(footsiesconfig.attack2holdframe, 60, -10)
			end,
			rightfuncfast = function()
				footsiesconfig.attack2holdframe = lccalc(footsiesconfig.attack2holdframe, 60, 10)
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+160, text = "attack2 prob. ratio: "..footsiesconfig.attack2probratio,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.attack2probratio = (lccalc(footsiesconfig.attack2probratio*100 + 1, 101, -1) -1)/100
			end,
			rightfunc = function()
				footsiesconfig.attack2probratio = (lccalc(footsiesconfig.attack2probratio*100 + 1, 101, 1) -1)/100
			end,
			leftfuncfast = function()
				footsiesconfig.attack2probratio = (lccalc(footsiesconfig.attack2probratio*100 + 1, 101, -10) -1)/100
			end,
			rightfuncfast = function()
				footsiesconfig.attack2probratio = (lccalc(footsiesconfig.attack2probratio*100 + 1, 101, 10) -1)/100
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+32, text = "block type: "..footsiesconfig.blocktype[1][footsiesconfig.blocktype[2]],
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.blocktype[2] = lccalc(footsiesconfig.blocktype[2], #footsiesconfig.blocktype[1], -1)
			end,
			rightfunc = function()
				footsiesconfig.blocktype[2] = lccalc(footsiesconfig.blocktype[2], #footsiesconfig.blocktype[1], 1)
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+40, text = "block frame (attack1): "..footsiesconfig.attack1blockframe,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.attack1blockframe = lccalc(footsiesconfig.attack1blockframe, 120, -1)
			end,
			rightfunc = function()
				footsiesconfig.attack1blockframe = lccalc(footsiesconfig.attack1blockframe, 120, 1)
			end,
			leftfuncfast = function()
				footsiesconfig.attack1blockframe = lccalc(footsiesconfig.attack1blockframe, 120, -10)
			end,
			rightfuncfast = function()
				footsiesconfig.attack1blockframe = lccalc(footsiesconfig.attack1blockframe, 120, 10)
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+48, text = "block frame (attack2): "..footsiesconfig.attack2blockframe,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.attack2blockframe = lccalc(footsiesconfig.attack2blockframe, 120, -1)
			end,
			rightfunc = function()
				footsiesconfig.attack2blockframe = lccalc(footsiesconfig.attack2blockframe, 120, 1)
			end,
			leftfuncfast = function()
				footsiesconfig.attack2blockframe = lccalc(footsiesconfig.attack2blockframe, 120, -10)
			end,
			rightfuncfast = function()
				footsiesconfig.attack2blockframe = lccalc(footsiesconfig.attack2blockframe, 120, 10)
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+64, text = "destination distance: "..footsiesconfig.movegoaldistance,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.movegoaldistance = lccalc(footsiesconfig.movegoaldistance +1, 301, -1) -1
			end,
			rightfunc = function()
				footsiesconfig.movegoaldistance = lccalc(footsiesconfig.movegoaldistance +1, 301, 1) -1
			end,
			leftfuncfast = function()
				footsiesconfig.movegoaldistance = lccalc(footsiesconfig.movegoaldistance +1, 301, -10) -1
			end,
			rightfuncfast = function()
				footsiesconfig.movegoaldistance = lccalc(footsiesconfig.movegoaldistance +1, 301, 10) -1
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+72, text = "walk range forward: "..footsiesconfig.allowwalkrangeforward,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.allowwalkrangeforward = lccalc(footsiesconfig.allowwalkrangeforward +1, 301, -1) -1
			end,
			rightfunc = function()
				footsiesconfig.allowwalkrangeforward = lccalc(footsiesconfig.allowwalkrangeforward +1, 301, 1) -1
			end,
			leftfuncfast = function()
				footsiesconfig.allowwalkrangeforward = lccalc(footsiesconfig.allowwalkrangeforward +1, 301, -10) -1
			end,
			rightfuncfast = function()
				footsiesconfig.allowwalkrangeforward = lccalc(footsiesconfig.allowwalkrangeforward +1, 301, 10) -1
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+80, text = "walk range backward: "..footsiesconfig.allowwalkrangebackward,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.allowwalkrangebackward = lccalc(footsiesconfig.allowwalkrangebackward +1, 301, -1) -1
			end,
			rightfunc = function()
				footsiesconfig.allowwalkrangebackward = lccalc(footsiesconfig.allowwalkrangebackward +1, 301, 1) -1
			end,
			leftfuncfast = function()
				footsiesconfig.allowwalkrangebackward = lccalc(footsiesconfig.allowwalkrangebackward +1, 301, -10) -1
			end,
			rightfuncfast = function()
				footsiesconfig.allowwalkrangebackward = lccalc(footsiesconfig.allowwalkrangebackward +1, 301, 10) -1
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+88, text = "base prob.(fw to dest.): "..footsiesconfig.baseprobfwalktogoal,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.baseprobfwalktogoal = (lccalc(footsiesconfig.baseprobfwalktogoal*10 + 1, 11, -1) -1)/10
			end,
			rightfunc = function()
				footsiesconfig.baseprobfwalktogoal = (lccalc(footsiesconfig.baseprobfwalktogoal*10 + 1, 11, 1) -1)/10
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+96, text = "base prob.(bw to dest.): "..footsiesconfig.baseprobbwalktogoal,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.baseprobbwalktogoal = (lccalc(footsiesconfig.baseprobbwalktogoal*10 + 1, 11, -1) -1)/10
			end,
			rightfunc = function()
				footsiesconfig.baseprobbwalktogoal = (lccalc(footsiesconfig.baseprobbwalktogoal*10 + 1, 11, 1) -1)/10
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+104, text = "prewalk prob.: "..footsiesconfig.probprewalk,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.probprewalk = (lccalc(footsiesconfig.probprewalk*100 + 1, 101, -1) -1)/100
			end,
			rightfunc = function()
				footsiesconfig.probprewalk = (lccalc(footsiesconfig.probprewalk*100 + 1, 101, 1) -1)/100
			end,
			leftfuncfast = function()
				footsiesconfig.probprewalk = (lccalc(footsiesconfig.probprewalk*100 + 1, 101, -10) -1)/100
			end,
			rightfuncfast = function()
				footsiesconfig.probprewalk = (lccalc(footsiesconfig.probprewalk*100 + 1, 101, 10) -1)/100
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+112, text = "neutral range forward: "..footsiesconfig.allowneutralrangeforward,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.allowneutralrangeforward = lccalc(footsiesconfig.allowneutralrangeforward +1, 301, -1) -1
			end,
			rightfunc = function()
				footsiesconfig.allowneutralrangeforward = lccalc(footsiesconfig.allowneutralrangeforward +1, 301, 1) -1
			end,
			leftfuncfast = function()
				footsiesconfig.allowneutralrangeforward = lccalc(footsiesconfig.allowneutralrangeforward +1, 301, -10) -1
			end,
			rightfuncfast = function()
				footsiesconfig.allowneutralrangeforward = lccalc(footsiesconfig.allowneutralrangeforward +1, 301, 10) -1
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+120, text = "neutral range backward: "..footsiesconfig.allowneutralrangebackward,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.allowneutralrangebackward = lccalc(footsiesconfig.allowneutralrangebackward +1, 301, -1) -1
			end,
			rightfunc = function()
				footsiesconfig.allowneutralrangebackward = lccalc(footsiesconfig.allowneutralrangebackward +1, 301, 1) -1
			end,
			leftfuncfast = function()
				footsiesconfig.allowneutralrangebackward = lccalc(footsiesconfig.allowneutralrangebackward +1, 301, -10) -1
			end,
			rightfuncfast = function()
				footsiesconfig.allowneutralrangebackward = lccalc(footsiesconfig.allowneutralrangebackward +1, 301, 10) -1
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+128, text = "minimum neutral frame: "..footsiesconfig.neutrallimitfloor,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.neutrallimitfloor = lccalc(footsiesconfig.neutrallimitfloor, 60, -1)
			end,
			rightfunc = function()
				footsiesconfig.neutrallimitfloor = lccalc(footsiesconfig.neutrallimitfloor, 60, 1)
			end,
			leftfuncfast = function()
				footsiesconfig.neutrallimitfloor = lccalc(footsiesconfig.neutrallimitfloor, 60, -10)
			end,
			rightfuncfast = function()
				footsiesconfig.neutrallimitfloor = lccalc(footsiesconfig.neutrallimitfloor, 60, 10)
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+136, text = "neutral prob.: "..footsiesconfig.probneutral,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.probneutral = (lccalc(footsiesconfig.probneutral*100 + 1, 101, -1) -1)/100
			end,
			rightfunc = function()
				footsiesconfig.probneutral = (lccalc(footsiesconfig.probneutral*100 + 1, 101, 1) -1)/100
			end,
			leftfuncfast = function()
				footsiesconfig.probneutral = (lccalc(footsiesconfig.probneutral*100 + 1, 101, -10) -1)/100
			end,
			rightfuncfast = function()
				footsiesconfig.probneutral = (lccalc(footsiesconfig.probneutral*100 + 1, 101, 10) -1)/100
			end
		},
		{
			x = cd.textconfig.textleft+cd.boxconfig.boxwidth*0.45, y = cd.textconfig.texttop+144, text = "keep neutral prob.: "..footsiesconfig.probkeepneutral,
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			leftfunc = function()
				footsiesconfig.probkeepneutral = (lccalc(footsiesconfig.probkeepneutral*100 + 1, 101, -1) -1)/100
			end,
			rightfunc = function()
				footsiesconfig.probkeepneutral = (lccalc(footsiesconfig.probkeepneutral*100 + 1, 101, 1) -1)/100
			end,
			leftfuncfast = function()
				footsiesconfig.probkeepneutral = (lccalc(footsiesconfig.probkeepneutral*100 + 1, 101, -10) -1)/100
			end,
			rightfuncfast = function()
				footsiesconfig.probkeepneutral = (lccalc(footsiesconfig.probkeepneutral*100 + 1, 101, 10) -1)/100
			end
		},
		{
			x = cd.textconfig.textleft, y = cd.textconfig.texttop+176, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 5
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	---page 1-9 (credit)
	menuconfig.menupage[1].submenupage[9] = {}
	cd = menuconfig.menupage[1].submenupage[9]
	menuconfig.menupage[1].submenupage[9].boxconfig = { --subpage box config
		bgcolor = 0xc7c7d1ee,
		frcolor = 0x52527aff,
		notebgcolor = 0xc7d1d1ee,
		notefrcolor = 0x527a7aff,
		boxwidth = sw*0.70,
		boxheight = sh*0.50,
		boxleft = (sw-sw*0.70)*0.5,
		boxtop = (sh-sh*0.50)*0.5
	}
	menuconfig.menupage[1].submenupage[9].textconfig = { --subpage text config
		textleft = cd.boxconfig.boxleft+16,
		texttop = cd.boxconfig.boxtop+16,
		textcol1 = 0xffffffff,
		textcol2 = 0x000000ff,
		textselectedcol1 = 0xb3d9ffff,
		textselectedcol2 = 0x000000ff,
		textnotecol1 = 0xffffffff,
		textnotecol2 = 0x000000ff
	}
	menuconfig.menupage[1].submenupage[9].submenutext = { --set submenu text(s)
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop, text = "- credit -", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+8, text = "This script is written by invitroFG.", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+24, text = "I am deeply grateful to the scripts and writers inspire me.", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+32, text = "- fbneo-training-mode by Peon2", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+40, text = "- input-display by Dammit", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+48, text = "- macro by Dammit", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+64, text = "Shout out to SFTM discord for their dedication to this game.", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
		{x = cd.textconfig.textleft, y = cd.textconfig.texttop+72, text = "(URL - https://discord.io/SFTM)", textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2},
	}
	menuconfig.menupage[1].submenupage[9].submenuoption = { --set submenu option(s)
		{
			x = cd.textconfig.textleft, y = (cd.boxconfig.boxtop+cd.boxconfig.boxheight)-24, text = "back to main menu",
			textcol1 = cd.textconfig.textcol1, textcol2 = cd.textconfig.textcol2, textselectedcol1 = cd.textconfig.textselectedcol1, textselectedcol2 = cd.textconfig.textselectedcol2, textnotecol1 = cd.textconfig.textnotecol1, textnotecol2 = cd.textconfig.textnotecol2,
			buttonfunc = function()
				menuconfig.currentmenuselection.option = 6
				menuconfig.currentmenuselection.subpage = 0
			end
		}
	}

	if luaconfig.availablemenu[1][luaconfig.availablemenu[2]] then
		getmenuinput()
	end
end

local function displaymenu()
	if luaconfig.showmenu[1][luaconfig.showmenu[2]] then
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
						if menuconfig.currentmenuselection.subpage == 0 then
							if menu.menuoption[i].note then
								gui.box((sw-4*#menu.menuoption[i].note-16)/2, menu.boxconfig.boxtop+menu.boxconfig.boxheight+8, (sw+4*#menu.menuoption[i].note+16)/2, menu.boxconfig.boxtop+menu.boxconfig.boxheight+24, menu.boxconfig.notebgcolor, menu.boxconfig.notefrcolor)
								gui.text((sw-4*#menu.menuoption[i].note)/2, menu.boxconfig.boxtop+menu.boxconfig.boxheight+14, menu.menuoption[i].note,  menu.menuoption[i].textnotecol1,  menu.menuoption[i].textnotecol2) --draw the note of the selected option
							end
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
							if menuconfig.currentmenuselection.subpage ~= 0 then
								if submenu.submenuoption[i].note then
									gui.box((sw-4*#submenu.submenuoption[i].note-16)/2, menu.boxconfig.boxtop+menu.boxconfig.boxheight+8, (sw+4*#submenu.submenuoption[i].note+16)/2, menu.boxconfig.boxtop+menu.boxconfig.boxheight+24, submenu.boxconfig.notebgcolor, submenu.boxconfig.notefrcolor)
									gui.text((sw-4*#submenu.submenuoption[i].note)/2, menu.boxconfig.boxtop+menu.boxconfig.boxheight+14, submenu.submenuoption[i].note, submenu.submenuoption[i].textnotecol1, submenu.submenuoption[i].textnotecol2) --draw the note of the selected suboption
								end
							end
						else
							gui.text(submenu.submenuoption[i].x, submenu.submenuoption[i].y, submenu.submenuoption[i].text, submenu.submenuoption[i].textcol1, submenu.submenuoption[i].textcol2) --draw the other option(s) in submenu table
						end
					end
				end
			end
		end
	end
end

---HUD---*important
local function displayhud()
	gui.box(0, 0, sw, sh, 0x00000000, 0x00000000)
	if luaconfig.showcautionmessage[1][luaconfig.showcautionmessage[2]] then
		gui.text(0, 0, "Caution: Please restart the script from Lua Script Window.", 0xffff00ff, 0x000000ff)
	end
	--drawing dark layer
	if hudconfig.ifshowdarklayer[1][hudconfig.ifshowdarklayer[2]] then
		gui.box(0, 0, sw, sh, 0x00000000+tonumber("0x"..string.format("%x", hudconfig.darklayertransparency)), 0x00000000+tonumber("0x"..string.format("%x", hudconfig.darklayertransparency)))
	end
	--drawing for record function
	local recordcol = { --colors for drawing input
		on1  = 0x33ff66d0, --pressed: yellow inside
		on2  = 0x000000d0, --pressed: black border
		off1 = 0xffffff60, --unpressed: mostly clear inside
		off2 = 0x00000060, --unpressed: mostly clear black border
	}
	if recordconfig.ifrecording[1][recordconfig.ifrecording[2]] then
		if recordconfig.timerbeforerecording < recordconfig.framebeforerecording then
			gui.text((sw-28)/2, 64, "ready: "..recordconfig.framebeforerecording-recordconfig.timerbeforerecording, recordcol.on1, recordcol.on2)
			gui.line((sw+56)/2, 65, (sw+56)/2, 71, 0x33ff66ff)
			gui.line((sw+56)/2, 68, (sw+56)/2+recordconfig.framebeforerecording-recordconfig.timerbeforerecording, 68, 0x33ff66ff)
			gui.line((sw+56)/2+recordconfig.framebeforerecording-recordconfig.timerbeforerecording, 65, (sw+56)/2+recordconfig.framebeforerecording-recordconfig.timerbeforerecording, 71, 0x33ff66ff)
		elseif recordconfig.timerbeforerecording == recordconfig.framebeforerecording then
			gui.text((sw-72)/2, 64, "now recording... "..(10-math.floor(recordconfig.timerafterrecording/60)), recordcol.on1, recordcol.on2)
		end
	end
	if recordconfig.ifshowplayback[1][recordconfig.ifshowplayback[2]] then
		if recordconfig.ifplayback[1][recordconfig.ifplayback[2]] then
			gui.text((sw-#"now playbacking..."*4)/2, 64, "now playbacking...", recordcol.on1, recordcol.on2)
		end
	end
	--drawing for macro function
	if macroconfig.ifshowplayback[1][macroconfig.ifshowplayback[2]] then
		if macroconfig.ifplayback[1][macroconfig.ifplayback[2]] then
			gui.text((sw-68)/2, 64, "now playbacking...", recordcol.on1, recordcol.on2)
			if macroconfig.playbacktime < #macroconfig.playbackinput + 1 then
				gui.text((sw-(#tostring(macroconfig.playbacktime-1)+#tostring(#macroconfig.playbackinput)+1)*4)/2, 72, (macroconfig.playbacktime-1).."/"..#macroconfig.playbackinput, recordcol.on1, recordcol.on2)
			elseif macroconfig.playbacktime >= #macroconfig.playbackinput + 1 then
				gui.text((sw-(#tostring(#macroconfig.playbackinput)+#tostring(#macroconfig.playbackinput)+1)*4)/2, 72, #macroconfig.playbackinput.."/"..#macroconfig.playbackinput, recordcol.on1, recordcol.on2)
			end
		end
	end
	---drawing for foosies function
	local foosiescol = { --colors for drawing input
		on1  = 0x33ff66d0, --pressed: yellow inside
		on2  = 0x000000d0, --pressed: black border
		off1 = 0xffffff60, --unpressed: mostly clear inside
		off2 = 0x00000060, --unpressed: mostly clear black border
	}
	if footsiesconfig.iffootsies[1][footsiesconfig.iffootsies[2]] then
		if footsiesconfig.ifshowinfo[1][footsiesconfig.ifshowinfo[2]] == "yes" then
			gui.text(150, 64, "movetype: "..footsiesconfig.movetype[1][footsiesconfig.movetype[2]], foosiescol.on1, foosiescol.on2)
			if (footsiesconfig.distance[#footsiesconfig.distance] - footsiesconfig.movegoaldistance) >= 0 then
				gui.text(150, 72, "distance: "..footsiesconfig.distance[#footsiesconfig.distance].." (+"..(footsiesconfig.distance[#footsiesconfig.distance] - footsiesconfig.movegoaldistance)..")", foosiescol.on1, foosiescol.on2)
			elseif (footsiesconfig.distance[#footsiesconfig.distance] - footsiesconfig.movegoaldistance) < 0 then
				gui.text(150, 72, "distance: "..footsiesconfig.distance[#footsiesconfig.distance].." ("..(footsiesconfig.distance[#footsiesconfig.distance] - footsiesconfig.movegoaldistance)..")", foosiescol.on1, foosiescol.on2)
			end
			gui.text(150, 80, "blockcount: "..footsiesconfig.blockcount.."/"..footsiesconfig.blockframe, foosiescol.on1, foosiescol.on2)
		end
	end
	--address viewer
	local addrcol = { --colors for drawing address
		on1  = 0xeeeeeecc, --color_on_inside
		on2  = 0x101010cc, --colo_on_border
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
				table.insert(addrtext.debug, #addrtext.debug+1, {x=296, y=72, text = "P1 coord: ("..P1status.x..", "..P1status.y..")", textcol1 = addrcol.on1, textcol2 = addrcol.on2}) --P1 coordinate
				table.insert(addrtext.debug, #addrtext.debug+1, {x=296, y=80, text = "P1 anim: "..string.format("%x", rb(0x70EE)).."_"..string.format("%x", rb(0x70EF)), textcol1 = addrcol.on1, textcol2 = addrcol.on2}) --P1 animation
				table.insert(addrtext.debug, #addrtext.debug+1, {x=296, y=96, text = "P2 coord: ("..P2status.x..", "..P2status.y..")", textcol1 = addrcol.on1, textcol2 = addrcol.on2}) --P2 coordinate
				table.insert(addrtext.debug, #addrtext.debug+1, {x=296, y=104, text = "P2 anim: "..string.format("%x", rb(0x72B0)).."_"..string.format("%x", rb(0x72B1)), textcol1 = addrcol.on1, textcol2 = addrcol.on2}) --P2 animation
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
	if hudconfig.ifshowinput[1][hudconfig.ifshowinput[2]] then
		if hudconfig.inputstyle[1][hudconfig.inputstyle[2]] == "type1" then
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
			if not hudconfig.ifshowinput[1][hudconfig.ifshowinput[2]] then
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
		elseif hudconfig.inputstyle[1][hudconfig.inputstyle[2]] == "type2" then
			local inputappearance = {
				boardcolor1 = 0xffffff80,
				boardcolor2 = 0x80808080,
				boardwidth = 64,
				boardheight = 20,
				stickcolor1 = 0x8cfd4aff,
				stickcolor2 = 0x202020ff,
				outlinecolor = 0x808080b0,
				stickradius = 3,
				holeradius = 5,
				stickdir = {0, 0},
				stickcenter = {10, 0},
				buttononcolor1 = 0x8cfd4ae0,
				buttononcolor2 = 0x202020ff,
				buttonoffcolor1 = 0x808080e0,
				buttonoffcolor2 = 0x202020ff,
				buttonradius = 3,
				button1center = {28, -4}
			}
			local x, y = 20, 242
			local dx,dy = sw-x*2-inputappearance.boardwidth, 0
			local inpget = joypad.get()
			for p = 1, 2 do
				gui.box(x+dx*(p-1), y-inputappearance.boardheight/2+dy*(p-1), x+inputappearance.boardwidth+dx*(p-1), y+inputappearance.boardheight/2+dy*(p-1), inputappearance.boardcolor1, inputappearance.boardcolor2)
				for i =0, 7 do
					gui.line(x+inputappearance.stickcenter[1]+dx*(p-1)+inputappearance.holeradius*math.cos(math.pi*i/4), y+inputappearance.stickcenter[2]+dy*(p-1)+inputappearance.holeradius*math.sin(math.pi*i/4), x+inputappearance.stickcenter[1]+dx*(p-1)+inputappearance.holeradius*math.cos(math.pi*(i+1)/4), y+inputappearance.stickcenter[2]+dy*(p-1)+inputappearance.holeradius*math.sin(math.pi*(i+1)/4), inputappearance.outlinecolor)
				end
				if (inpget["P"..p.." Right"] == true and inpget["P"..p.." Left"] == true) or (inpget["P"..p.." Up"] == true and inpget["P"..p.." Down"] == true) then
					inputappearance.stickdir[p] = -1
				elseif inpget["P"..p.." Down"] == true and inpget["P"..p.." Left"] == true then
					inputappearance.stickdir[p] = 5
				elseif inpget["P"..p.." Down"] == true and inpget["P"..p.." Right"] == true then
					inputappearance.stickdir[p] = 7
				elseif inpget["P"..p.." Up"] == true and inpget["P"..p.." Left"] == true then
					inputappearance.stickdir[p] = 3
				elseif inpget["P"..p.." Up"] == true and inpget["P"..p.." Right"] == true then
					inputappearance.stickdir[p] = 1
				elseif inpget["P"..p.." Down"] == true then
					inputappearance.stickdir[p] = 6
				elseif inpget["P"..p.." Left"] == true then
					inputappearance.stickdir[p] = 4
				elseif inpget["P"..p.." Right"] == true then
					inputappearance.stickdir[p] = 8
				elseif inpget["P"..p.." Up"] == true then
					inputappearance.stickdir[p] = 2
				else
					inputappearance.stickdir[p] = 0
				end
				if inputappearance.stickdir[p] == -1 then
					gui.box(x+inputappearance.stickcenter[1]+dx*(p-1)-inputappearance.stickradius, y+inputappearance.stickcenter[2]+dy*(p-1)-inputappearance.stickradius, x+inputappearance.stickcenter[1]+dx*(p-1)+inputappearance.stickradius, y+inputappearance.stickcenter[2]+dy*(p-1)+inputappearance.stickradius, inputappearance.stickcolor1, inputappearance.stickcolor2)
					gui.text(x+inputappearance.stickcenter[1]+dx*(p-1)-1, y+inputappearance.stickcenter[2]+dy*(p-1)-3, "?", inputappearance.stickcolor1, inputappearance.stickcolor2)
				elseif inputappearance.stickdir[p] == 0 then
					gui.box(x+inputappearance.stickcenter[1]+dx*(p-1)-inputappearance.stickradius, y+inputappearance.stickcenter[2]+dy*(p-1)-inputappearance.stickradius, x+inputappearance.stickcenter[1]+dx*(p-1)+inputappearance.stickradius, y+inputappearance.stickcenter[2]+dy*(p-1)+inputappearance.stickradius, inputappearance.stickcolor1, inputappearance.stickcolor2)
				else
					gui.box(x+inputappearance.stickcenter[1]+dx*(p-1)+inputappearance.holeradius*math.cos(math.pi*inputappearance.stickdir[p]/4)-inputappearance.stickradius, y+inputappearance.stickcenter[2]+dy*(p-1)-inputappearance.holeradius*math.sin(math.pi*inputappearance.stickdir[p]/4)-inputappearance.stickradius, x+inputappearance.stickcenter[1]+dx*(p-1)+inputappearance.holeradius*math.cos(math.pi*inputappearance.stickdir[p]/4)+inputappearance.stickradius, y+inputappearance.stickcenter[2]+dy*(p-1)-inputappearance.holeradius*math.sin(math.pi*inputappearance.stickdir[p]/4)+inputappearance.stickradius, inputappearance.stickcolor1, inputappearance.stickcolor2)
				end
				for i = 1, #buttons do
					if i <= 3 then
						if inpget["P"..p.." "..buttons[i][1]] == true then
							gui.box(x+inputappearance.button1center[1]+dx*(p-1)+inputappearance.buttonradius*2*(i-1)-inputappearance.buttonradius, y+inputappearance.button1center[2]+dy*(p-1)-inputappearance.buttonradius, x+inputappearance.button1center[1]+dx*(p-1)+inputappearance.buttonradius+inputappearance.buttonradius*2*(i-1), y+inputappearance.button1center[2]+dy*(p-1)+inputappearance.buttonradius, inputappearance.buttononcolor1, inputappearance.buttononcolor2)
						else
							gui.box(x+inputappearance.button1center[1]+dx*(p-1)+inputappearance.buttonradius*2*(i-1)-inputappearance.buttonradius, y+inputappearance.button1center[2]+dy*(p-1)-inputappearance.buttonradius, x+inputappearance.button1center[1]+dx*(p-1)+inputappearance.buttonradius+inputappearance.buttonradius*2*(i-1), y+inputappearance.button1center[2]+dy*(p-1)+inputappearance.buttonradius, inputappearance.buttonoffcolor1, inputappearance.buttonoffcolor2)
						end
					elseif i >= 4 then
						if inpget["P"..p.." "..buttons[i][1]] == true then
							gui.box(x+inputappearance.button1center[1]+dx*(p-1)+inputappearance.buttonradius*2*(i-4)-inputappearance.buttonradius, y+inputappearance.button1center[2]+inputappearance.buttonradius*2+dy*(p-1)-inputappearance.buttonradius, x+inputappearance.button1center[1]+dx*(p-1)+inputappearance.buttonradius+inputappearance.buttonradius*2*(i-4), y+inputappearance.button1center[2]+inputappearance.buttonradius*2+dy*(p-1)+inputappearance.buttonradius, inputappearance.buttononcolor1, inputappearance.buttononcolor2)
						else
							gui.box(x+inputappearance.button1center[1]+dx*(p-1)+inputappearance.buttonradius*2*(i-4)-inputappearance.buttonradius, y+inputappearance.button1center[2]+inputappearance.buttonradius*2+dy*(p-1)-inputappearance.buttonradius, x+inputappearance.button1center[1]+dx*(p-1)+inputappearance.buttonradius+inputappearance.buttonradius*2*(i-4), y+inputappearance.button1center[2]+inputappearance.buttonradius*2+dy*(p-1)+inputappearance.buttonradius, inputappearance.buttonoffcolor1, inputappearance.buttonoffcolor2)
						end
					end
				end
				if inpget["P"..p.." Start"] == true then
					gui.box(x+inputappearance.button1center[1]+inputappearance.buttonradius*2*4+dx*(p-1)-inputappearance.buttonradius, y+inputappearance.button1center[2]+dy*(p-1)-inputappearance.buttonradius, x+inputappearance.button1center[1]+inputappearance.buttonradius*2*4+dx*(p-1)+inputappearance.buttonradius, y+inputappearance.button1center[2]+dy*(p-1)+inputappearance.buttonradius, inputappearance.buttononcolor1, inputappearance.buttononcolor2)
				else
					gui.box(x+inputappearance.button1center[1]+inputappearance.buttonradius*2*4+dx*(p-1)-inputappearance.buttonradius, y+inputappearance.button1center[2]+dy*(p-1)-inputappearance.buttonradius, x+inputappearance.button1center[1]+inputappearance.buttonradius*2*4+dx*(p-1)+inputappearance.buttonradius, y+inputappearance.button1center[2]+dy*(p-1)+inputappearance.buttonradius, inputappearance.buttonoffcolor1, inputappearance.buttonoffcolor2)
				end
				if inpget["P"..p.." Coin"] == true then
					gui.box(x+inputappearance.button1center[1]+inputappearance.buttonradius*2*4+dx*(p-1)-inputappearance.buttonradius, y+inputappearance.button1center[2]+2*inputappearance.buttonradius+dy*(p-1)-inputappearance.buttonradius, x+inputappearance.button1center[1]+inputappearance.buttonradius*2*4+dx*(p-1)+inputappearance.buttonradius, y+inputappearance.button1center[2]+2*inputappearance.buttonradius+dy*(p-1)+inputappearance.buttonradius, inputappearance.buttononcolor1, inputappearance.buttononcolor2)
				else
					gui.box(x+inputappearance.button1center[1]+inputappearance.buttonradius*2*4+dx*(p-1)-inputappearance.buttonradius, y+inputappearance.button1center[2]+2*inputappearance.buttonradius+dy*(p-1)-inputappearance.buttonradius, x+inputappearance.button1center[1]+inputappearance.buttonradius*2*4+dx*(p-1)+inputappearance.buttonradius, y+inputappearance.button1center[2]+2*inputappearance.buttonradius+dy*(p-1)+inputappearance.buttonradius, inputappearance.buttonoffcolor1, inputappearance.buttonoffcolor2)
				end
			end
		end
	end
end

---cheat---*important
local function activatecheat()
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
		elseif cheatconfig.P1meter[1][cheatconfig.P1meter[2]] == "empty" then -- P2 meter(67=max)
			wb(addr.P1meter, 0)
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
		elseif cheatconfig.P2meter[1][cheatconfig.P2meter[2]] == "empty" then -- P2 meter(67=max)
			wb(addr.P2meter, 0)
		end
		if cheatconfig.P2stun[1][cheatconfig.P2stun[2]] == "never" then -- P2 meter(67=max)
			wb(addr.P2dizzyvalue, 85)
		end
	end
end

---function---*important
if not fba then
	print("This script supports only Fightcade FBNeo for now...")
	return
elseif not elmdetect(games, emu.romname()) then
	print("This game is not SFTM...")
	return
else
	print("--- SFTM training lua ("..scriptver..") ---")
	print("This script works correctly on Fightcade FBNeo v.0.2.97.44.")
	print()
	print("* Hold P1's / P2's Start or press hotkey 1 to open training menu.")
	emu.registerstart(function()
		luaconfig.updatefilelist[2] = 1
	end)
	emu.registerbefore(function()
		getfilelist()
		updatestatus()
		togglerecord()
		setinputs()
		updatemenu()
		footsies()
		toggleplayback()
		playbackmacro()
		activatecheat()
		freezeplayer()
	end)
	gui.register(function()
		displayhud()
		displaymenu()
	end)
end
