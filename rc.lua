-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
	-- Vicious widget library
	--require("vicious")
--to add a calendar
require('calendar2')
--compte a rebour
require('CompteArebour')

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/sky/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "xterm"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    --5
    awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.floating
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {
	names = { "Terminal", "Opera", "Editeur", "Fichiers", "Media",
		 "Skype", "Gimp", 8, 9 },
	layout = { 
		layouts[1], layouts[3], layouts[1], layouts[5], layouts[1], 
		layouts[9], layouts[10], layouts[1], layouts[1] }
	}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag(tags.names, s, tags.layout)
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

myracourciesmenu = {
}
mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Racourcis", myracourciesmenu},
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- start up programe lunching
	function run_once(prg,arg_string,pname,screen)
	    if not prg then
		do return nil end
	    end

	    if not pname then
	       pname = prg
	    end

	    if not arg_string then 
		awful.util.spawn_with_shell("pgrep -u $USER -x '" .. pname .. "' || (" .. prg .. ")",screen)
	    else
		awful.util.spawn_with_shell("pgrep -u $USER -x '" .. pname .. "' || (" .. prg .. " " .. arg_string .. ")",screen)
	    end
	end

	--run_once("xscreensaver","-no-splash")
	--run_once("opera")
	--run_once("xfce4-clipman")
	--run_once("nm-applet")

-- }}}

-- {{{ Wibox


--batterie widget
	battery={}
	battery.defaultAdapter="BAT0"
	function battery.update(battery, adapter)
		spacer = " "
		adapter=adapter or battery.defaultAdapter
		local fcur = io.open("/sys/class/power_supply/"..adapter.."/charge_now")    
		local fcap = io.open("/sys/class/power_supply/"..adapter.."/charge_full")
		local fsta = io.open("/sys/class/power_supply/"..adapter.."/status")
		if fcur and fcap and fsta then
			local cur = fcur:read()
			local cap = fcap:read()
			local sta = fsta:read()
			battery.state = math.floor(cur * 100 / cap)
			if sta:match("Charging") then	--la baterie se charge
				battery.info = "A/C ("..battery.state.."%)"
			elseif sta:match("Discharging") then	--la baterie se décharge
				if tonumber(battery.state) > 75 then
					battery.info = "<span color='green'>" .. battery.state .. "%".."</span>"
				elseif tonumber(battery.state) > 25 then
					battery.info = battery.state.."%"
				elseif tonumber(battery.state) > 15 then
					battery.info = "<span color='orange'>" .. battery.state .. "%".."</span>"
				else
					battery.info = "<span color='red'>" .. battery.state .. "%".."</span>"
					local notification = naughty.notify({ title      = "Battery Warning"
							, text       = "Battery low!"..spacer..battery.state.."%"..spacer.."left!"
							, timeout    = 5
							, position   = "top_right"
							, fg         = beautiful.fg_focus
							, bg         = beautiful.bg_focus
						})
					notification.config.presets="critical"
				end
			elseif sta:match("Full") then --la batterie est completement chargée
				battery.info = "F"
			else	--l'état de la baterie est inconnue
				battery.info = "?"..battery.state.."%?"
			end
			fcur:close()
			fcap:close()
			fsta:close()
			battery.info = "B:"..battery.info
		else
			battery.info=""
		end
		battery.widget.text = battery.info
	end
	battery.widget = widget({type = "textbox", name = "batteryget", align = "right" })
	battery:update()
	battery.timer=timer({timeout=10})
	battery.timer:add_signal("timeout", function() battery:update() end)
	battery.timer:start()
--save object
	function newhistory(taille_history,periode)
		local history = {}
		history.taille_history=taille_history or 100
		history.periode = periode or 1
		history.table = {}
		function history.add(element)
			if type(element)=="number" then 
				table.insert(history.table,element)
				if #history.table>history.taille_history then
					table.remove(history.table,1)
				end
			end
		end
		function history.moy(temps)
			local nbvaleurTotal = #history.table
			local nbvaleur
			if type(temps)=="number" then
				nbvaleur = math.floor(temps/history.periode)
				if nbvaleur <= 0 then nbvaleur = 1 end
				if nbvaleur > nbvaleurTotal then nbvaleur = nbvaleurTotal end
			else nbvaleur = nbvaleurTotal
			end
			local sum = 0
			for i = (nbvaleurTotal - nbvaleur + 1),nbvaleurTotal do
				sum = sum + history.table[i]
			end
			return sum/nbvaleur,sum 
		end
		return history
	end		
-- memory usage widget
	function readable (num,unit)
		num=tonumber(num)
		unit = unit or {"","K","M","G","T"}
		local text
		if type(num) ~="number" then 
			text=type(i)
		else
			local i=1
			while num>=1024 do
				num=num/1024
				i=i+1
			end
			text=(math.floor(num*10)/10)..(unit[i] or "unknown unit")
		end
		return text
	end
	meminfo = {}
	meminfo.stat = {}
	function meminfo.get()
		for line in io.lines("/proc/meminfo") do
			local title, value = string.match(line, "(.+):\ +(%d+)")
			if title and value then
				meminfo.stat[title]=value
			end
		end
	end
	meminfo.widget = widget({ type = "textbox", align = "right"})
	function meminfo.update () 
		meminfo.get()
		local text = ((meminfo.stat["MemTotal"]
				 - meminfo.stat["MemFree"]
				 - meminfo.stat["Buffers"]
				 - meminfo.stat["Cached"])/ meminfo.stat["MemTotal"])*100
		text = string.format("%02d",text)
		meminfo.widget.text="M:"..text.."%"
		
	end
	meminfo.update ()
	
	function meminfo.detailPopup ()
		local info = {"Statistique de la mémoire vive",
			{"utilisée par les programmes" 	, meminfo.stat["MemTotal"]
				 - meminfo.stat["MemFree"]
				 - meminfo.stat["Buffers"]
				 - meminfo.stat["Cached"]
				 },
			{"mémoire libre" 		, meminfo.stat["MemFree"]},
			{"disponible pour être allouée" , meminfo.stat["CommitLimit"]},
			{"mémoire totale" 		, meminfo.stat["MemTotal"]},
			{"buffers" 			, meminfo.stat["Buffers"]},
			{"utilisée comme cache" 	, meminfo.stat["Buffers"]+meminfo.stat["Cached"]},
			
			"\nStatistique des transferts",
			{"cache (ex : transferts vers DD)" , meminfo.stat["Cached"]},
			{"en attente d'être écrite sur le disque" , meminfo.stat["Dirty"]},
			
			"\nStatistique du swap",
			{"swap alloué"		, meminfo.stat["SwapTotal"]-meminfo.stat["SwapFree"]},
			{"swap disponible" 	, meminfo.stat["SwapFree"]},
			{"taille du swap" 	, meminfo.stat["SwapTotal"]},
		}
		local textPopup = ""
		for i,n in pairs(info) do
			if type(n) == "string" then
				textPopup=textPopup..n.." : ".."\n"
			else
				textPopup=textPopup.."  "..n[1].." : "..readable(n[2],{"K","M","G","T"}).."\n"
			end
		end
		textPopup=textPopup.."\nconf : /proc/meminfo"
		meminfo.nautification = naughty.notify({
		        text = textPopup,
		        timeout = 0, hover_timeout = 0.5,
		        width = 270, screen = mouse.screen
                })
	end
	meminfo.widget:add_signal('mouse::enter', function() meminfo.detailPopup() end)
	meminfo.widget:add_signal('mouse::leave', function () 
		naughty.destroy(meminfo.nautification)
		meminfo.nautification=nil
		end)
	
	meminfo.timer = timer({ timeout = 60})
	meminfo.timer:add_signal("timeout", function() 	meminfo.update () end )
	meminfo.timer:start()
	
-- CPU usage widget
	jiffies = {}
	function activecpu()
		local cpustat = {}
		for line in io.lines("/proc/stat") do
			local cpu, newjiffies = string.match(line, "(cpu%d*)\ +(%d+)")
			if cpu and newjiffies then
				if not jiffies[cpu] then
					jiffies[cpu] = newjiffies
				end
				--The string.format prevents your task list from jumping around 
				--when CPU usage goes above/below 10%
				cpustat[cpu] = string.format("%02d", newjiffies-jiffies[cpu]) .. "% "
				jiffies[cpu] = newjiffies
			end
		end
		return cpustat
	end
	function cpufreq()
		local freq = ""
		local numcpu = 0
		for line in io.lines("/proc/cpuinfo") do
			local newnumcpu = string.match(line, "processor.*: (%d)")
			if newnumcpu then 
				numcpu = newnumcpu 
			end
			
			local newfreq = string.match(line, "cpu MHz.*:.(%d*)")
			if newfreq then
				freq = freq.."cpu"..numcpu..": "..newfreq .. "MHz "
				numcpu = numcpu + 1 --si newnumcpu pas trouver
			end
		end
		return freq
	end
	
	function cpugovernor()
		local cpuNames={"cpu0","cpu1"}  --a ameliorer
		local governor = ""
		for num,cpuName in pairs(cpuNames) do
			local fgovernor = io.open("/sys/devices/system/cpu/"..cpuName.."/cpufreq/scaling_governor")
			governor =governor..cpuName.." : ".. fgovernor:read().." "
			fgovernor:close()
		end
		return governor
	end
	
	function cpupopup (cpustat)
		local s = ""
		for key,value in pairs(cpustat) do s=s..key..": "..value.." " end
		s=s.."\n"..cpufreq().."\n"..cpugovernor()
		return s
	end
		
	cpuinfo = widget({ type = "textbox", align = "right"})
	
	cpuinfo_timer = timer({ timeout = 1})
	cpuinfo_timer:add_signal("timeout", function() 
		local cpustat=activecpu()
		cpuinfo.text = "cpu"..":"..(cpustat)["cpu"]
		if cpuMoreInfo 
			then cpuMoreInfo.box.widgets[2].text=cpupopup(cpustat)
			 --cpuinfo.text="POP"
		end
		end)
	cpuinfo_timer:start()
	
  
	cpuinfo:add_signal('mouse::enter', function ()
                local cpustat=activecpu()
                cpuMoreInfo= naughty.notify({
                text = cpupopup(cpustat),
                timeout = 0, hover_timeout = 0.5,
                width = 270, screen = mouse.screen
                })end
        )
	cpuinfo:add_signal('mouse::leave', function () 
		naughty.destroy(cpuMoreInfo)
		cpuMoreInfo=nil
		end
	)
--check lua config widget
	--fonctions
		function isLuaFileValid(path)
			local f=awful.util.checkfile (path)
			local valid = true
			if type(f) == "string" then
				valid = false
			end
			return valid, f
		end
		function bool2char(bool)
			local listChar = {[true]="✔",[false]="✘"}
			return listChar[bool]
		end
		function io.cat(path)
			local tableauLigne = {}
			for ligne in io.lines(path) do
				table.insert(tableauLigne,ligne)
			end
			return tableauLigne
		end
	--configure widget
		luaConfigFile = {}
		luaConfigFile.widget = widget({ type = "textbox", name = "config", align = "right" })
		--update
		luaConfigFile.configFilePath = awful.util.getdir("config").."/rc.lua"
		luaConfigFile.debugFilePath = os.getenv("PWD") .. "/.xsession-errors"
		
		luaConfigFile.update = function (notificationDemandee)
			notificationDemandee= notificationDemandee or false
			local valid,f=isLuaFileValid(luaConfigFile.configFilePath)
			luaConfigFile.widget.text=bool2char(valid)
			
			local message = f
			if valid then
				local tableauLigne =  io.cat(luaConfigFile.debugFilePath)
				local startLine=#tableauLigne-10
				if startLine<1 then startLine=1 end
				message = table.concat(tableauLigne,"\n",startLine)
				if message=="" then message = 
					"Tout est OK ;)\n"..
					"Commande :\n"..
					"clic1 \t\t\t\t: actualisation\n"..
					"modkey+clic1 \t\t: ouvre rc.lua dans l'éditeur\n"..
					"modkey+shift+clic1 \t: ouvre *.lua dans l'éditeur\n"..
					"clic2 \t\t\t\t: restart si pas d'erreur\n"..
					"clic3 \t\t\t\t: efface log et affiche ce message" 
				end
			end
			
			if luaConfigFile.notification then
				luaConfigFile.notification.box.widgets[2].text = message
			elseif not luaConfigFile.notification and notificationDemandee then
				luaConfigFile.notification = naughty.notify({
					text = message,
					timeout = 0, hover_timeout = 0.5,
					width = 450, screen = mouse.screen
		        	})
			end
		end
		luaConfigFile.update()
		luaConfigFile.clear= function ()
			io.open(luaConfigFile.debugFilePath,"w+"):close()
		end
		--timer
		luaConfigFile.timer = timer({ timeout = 30})
		luaConfigFile.timer:add_signal("timeout", function () luaConfigFile.update() end)
		luaConfigFile.timer:start()
	--signals
		luaConfigFile.widget:add_signal('mouse::enter', function ()
			luaConfigFile.update(true)
			end
		)
		luaConfigFile.widget:add_signal('mouse::leave', function () 
					naughty.destroy(luaConfigFile.notification)
					luaConfigFile.notification=nil
			end
		)
	--mouse bouton
		luaConfigFile.widget:buttons(awful.util.table.join(
				awful.button({ }, 1, function () luaConfigFile.update() end),
				awful.button({ modkey }, 1, function () 
					awful.util.spawn(
						editor .. " " .. awful.util.getdir("config") .. "/rc.lua",false,mouse.screen )
					end),
				awful.button({ modkey , "Shift" }, 1, function () 
					awful.util.spawn_with_shell(
						editor .. " " .. awful.util.getdir("config") .. "/*.lua",false,mouse.screen )
					end),
				awful.button({ }, 2, function () 
					if isLuaFileValid(luaConfigFile.configFilePath) then 
						awesome.restart() 
					end 
				end),
				awful.button({ }, 3, function () luaConfigFile.clear() luaConfigFile.update() end)
			))
		
--temperature widget
		temperature = {}
		temperature.update_periode=5
	--fonction definition
		function temperature.get()
			fs=io.popen("sensors")
			s=fs:read("*all")
			fs:close()
			local temperature = {}
			for m,t in string.gmatch(s,"([%a%d\ ]+):\ *\([\+\-]%d+.%d+)°C") do
				temperature[m] = t
			end
			return temperature
		end
		function temperature.temptostring (temp,format,color)
			temp,format=temp or 0,format or "%02d"
			if temp > 65 then color = "orange" 	end
			if temp > 80 then color = "red" 	end
			if color then
				return "<span color='"..color.."'>"..string.format(format,temp).."</span>"
			else
				return string.format(format,temp)
			end
		end
		function temperature.textPopup()
			local text = ""
			for m,t in pairs(temperature.history) do
				text=text.."T("..m..")=\t"..
					temperature.temptostring ((t.moy(0))).."°C\t"..
					temperature.temptostring ((t.moy(60))).."°C\t"..
					temperature.temptostring ((t.moy(5*60))).."°C\t"..
					temperature.temptostring ((t.moy(10*60))).."°C\n"
			end
			return "\t\t\tnow\t1m\t\t5m\t\t10m\n"..text.."conf : «sensors»"
		end
		temperature.history = {}
		function temperature.update(widget,widget_popup)
			local temp = temperature.get()
			for m,t in pairs(temp) do
				if not (temperature.history[m]) then
					temperature.history[m] = newhistory(
						10*60/temperature.update_periode,
						temperature.update_periode)
				end
				temperature.history[m].add(tonumber(t))
			end
			local m,t = next(temperature.history)
			t = t.moy(0) or "err"
			widget.text = "T:"..temperature.temptostring (t).."°C"
			if widget_popup then
				widget_popup.box.widgets[2].text= temperature.textPopup()
			end
		end
	--widget definition
		temperature.widget = widget({ type = "textbox", name = "tb_volume", align = "right" })
		--temperature.update(temperature.widget)
	--add button
		temperature.widget:add_signal('mouse::enter', function ()
				temperature.popup = naughty.notify({
					text = temperature.textPopup(temperature.temperatures),
					timeout = 0, hover_timeout = 0.5,
					width = 270, screen = mouse.screen
		        	})
		        end
		)
		temperature.widget:add_signal('mouse::leave', function () 
				naughty.destroy(temperature.popup)
				temperature.popup=nil
			end
		)
	--update timer
		temperature.timer = timer({ timeout = temperature.update_periode})
		temperature.timer:add_signal("timeout", function() temperature.update(temperature.widget,temperature.popup) end)
		--temperature.timer:start()
	
-- Volume widget
	--fonction definition
		cardid  = 0
		channel = "Master"
		function volume (mode, widget)
			if mode == "update" then
				local fd = io.popen("amixer -c " .. cardid .. " -- sget " .. channel)
				local status = fd:read("*all")
				fd:close()
		 		
		 		local volume = string.match(status, "(%d?%d?%d)%%")
		 		volume = string.format("% 3d", volume)
		 
		 		status = string.match(status, "%[(o[^%]]*)%]")
		 
		 		if string.find(status, "on", 1, true) then
		 			volume = "V:" .. volume .. "%"
		 		else
		 			volume = "V:" .. volume .. "M"
		 		end
		 		widget.text = volume
		 	elseif mode == "up" then
		 		io.popen("amixer -q -c " .. cardid .. " sset " .. channel .. " 5%+"):read("*all")
		 		volume("update", widget)
		 	elseif mode == "down" then
		 		io.popen("amixer -q -c " .. cardid .. " sset " .. channel .. " 5%-"):read("*all")
		 		volume("update", widget)
		 	else
		 		io.popen("amixer -c " .. cardid .. " sset " .. channel .. " toggle"):read("*all")
		 		volume("update", widget)
		 	end
		end
	--update timer
		tb_volume_timer = timer({ timeout = 10})
		tb_volume_timer:add_signal("timeout", function() volume("update", tb_volume) end)
		tb_volume_timer:start()
	--widget definition
		tb_volume = widget({ type = "textbox", name = "tb_volume", align = "right" })
		--tb_volume.text = "volume"
		tb_volume:buttons(awful.util.table.join(
			awful.button({ }, 4, function () volume("up", tb_volume) end),
			awful.button({ }, 5, function () volume("down", tb_volume) end),
			awful.button({ }, 1, function () volume("mute", tb_volume) end),
			awful.button({ }, 3, function () awful.util.spawn("xfce4-mixer",false,mouse.screen) end)
		))
		volume("update", tb_volume)

--timer widget
	CaR = CompteArebour()
	
-- Keyboard map indicator and changer
	kbdcfg = {}
	kbdcfg.cmd = "setxkbmap"
	kbdcfg.layout = { "fr bepo", "fr" }
	kbdcfg.layoutNames = { "bépo", "azerty" }
	kbdcfg.current = 1  --  bépo is our default layout
	kbdcfg.widget = widget({ type = "textbox", align = "right" })
	kbdcfg.widget.text = " " .. kbdcfg.layoutNames[kbdcfg.current] .. " "
	kbdcfg.switch = function (num)
		kbdcfg.current = num or kbdcfg.current % #(kbdcfg.layout) + 1
		kbdcfg.widget.text = " " .. kbdcfg.layoutNames[kbdcfg.current] .. " "
		awful.util.spawn( kbdcfg.cmd .. " " .. kbdcfg.layout[kbdcfg.current] .. " " )
	end
	kbdcfg.switch(kbdcfg.current)
	-- Mouse bindings
	kbdcfg.widget:buttons(awful.util.table.join(
		awful.button({ }, 1, function () kbdcfg.switch() end)
	))

-- vpnc map indicator and changer
	vpnccfg = {}
	vpnccfg.codeErreur={[0]="OK"}
	vpnccfg.cmd = { "usvpnc", "usvpnc-disconnect" }
	vpnccfg.cmdNames = { "VPN", "[VPN]" }
	vpnccfg.current = 2
	vpnccfg.widget = widget({ type = "textbox", align = "right" })
	vpnccfg.widget.text = " " .. vpnccfg.cmdNames[vpnccfg.current] .. " "
	vpnccfg.switch = function ()
		vpnccfg.current = vpnccfg.current % #(vpnccfg.cmd) + 1
		vpnccfg.widget.text = " " .. vpnccfg.cmdNames[vpnccfg.current] .. " "
		local pid = awful.util.spawn(vpnccfg.cmd[vpnccfg.current])
		--[[
		naughty.notify({	text = tostring(err).."\t".. vpnccf.gcodeErreur[err] or "erreur indefinie",
					timeout = 3, hover_timeout = 0.5,
					width = 270, screen = mouse.screen
		        	})--]]
	end

	-- Mouse bindings
	vpnccfg.widget:buttons(awful.util.table.join(
	awful.button({ }, 1, function () vpnccfg.switch() end)
	))

-- Create a textclock widget
	mytextclock = awful.widget.textclock({ align = "right" })
	--add calendar
	calendar2.addCalendarToWidget(mytextclock, "<span color='orange'>%s</span>")
-- test 
	mygraph = awful.widget.graph.new({ align = "right" })
	mygraph:set_background_color("blue")
	mygraph:set_color("red")
	mygraph:set_width (20)
	mygraph:set_scale(true)
	--mygraph:set_stack(true)
	mygraph:add_value(0.1)
	mygraph:add_value(0.5)
	mygraph:add_value(1)
-- create separator
	separator = widget({ type = "textbox" })
	separator.text = " "

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },

        mylayoutbox[s],
        mytextclock,
--      luaConfigFile.widget,
--      separator,
--      cpuinfo,
--      separator,
--      meminfo.widget,
--      separator,
--      battery.widget,
--      separator,
--      temperature.widget,
--      separator,
--      tb_volume,
--      kbdcfg.widget,
--      CaR,
--      vpnccfg.widget,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "b",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "a",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "b", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "a", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "b", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "a", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- awful.key({ 	}, "XF86Calculator",  function () awful.util.spawn("gcalctool")    end),
    -- awful.key({ 	}, "XF86AudioMedia",  function () awful.util.spawn("gmusicbrowser")    end),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    --widget key
    awful.key({},"XF86AudioRaiseVolume",     function () volume("up", tb_volume) 	end),
    awful.key({},"XF86AudioLowerVolume",     function () volume("down", tb_volume) 	end),
    awful.key({},"XF86AudioMute",	     function () volume("mute", tb_volume) 	end),
    awful.key({modkey,"Shift"  },"Tab"	,    function () kbdcfg.switch()		end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "k",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true, tag = tags[1][7] } },
    -- Set Firefox to always map on tags number 2 of screen 1.
     { rule = { class = "Firefox" },
       properties = { tag = tags[1][2] } },
    { rule = { class = "skype" },
      properties = { tag = tags[1][6] , floating = false,  } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
