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
--compte a rebours
CompteArebours = require('CompteArebours')
--lua config widget
require('luaConfigFile')
-- meminfo widget
require('meminfo')
-- volume management widget
require('tb_volume')

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
    awesome.connect_signal("debug::error", function (err)
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
		layouts[1], layouts[1], layouts[1], layouts[5], layouts[1],
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
   { "edit config", editor_cmd .. " " .. awesome.conffile },
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

	--run_once("xscreensaver", "-no-splash")
	--run_once("opera")
	run_once("firefox")
	run_once("redshift", "-l 43.61:1.45 -m vidmode -t 5700:3690 -r")
	--run_once("xfce4-clipman")
	--run_once("nm-applet")

-- }}}

-- {{{ Wibox


--batterie widget
	battery={}
	battery.defaultAdapter = "BAT0"
	battery.defaultRefreshTime = 10

	function battery:update()

		--open power sys files
		local fcur = io.open("/sys/class/power_supply/"..self.adapter.."/charge_now")
		local fcap = io.open("/sys/class/power_supply/"..self.adapter.."/charge_full")
		local fsta = io.open("/sys/class/power_supply/"..self.adapter.."/status")

		if fcur and fcap and fsta then

			--read them
			local cur = fcur:read()
			local cap = fcap:read()
			local sta = fsta:read()

			local state = math.floor(cur * 100 / cap)
			local info

			if sta:match("Charging") then
				--la baterie se charge
				info = "A/C ("..state.."%)"

			elseif sta:match("Discharging") then
				--la baterie se décharge
				if tonumber(state) > 75 then
					info = "<span color='green'>" .. state .. "%".."</span>"

				elseif tonumber(state) > 25 then
					info = state.."%"

				elseif tonumber(state) > 15 then
					info = "<span color='orange'>" .. state .. "%".."</span>"

				else
					info = "<span color='red'>" .. state .. "%".."</span>"
					local notification = naughty.notify(
						{	title      = "Battery Warning" ,
							text       = "Battery low!" .. spacer .. state .. "%" .. spacer .. "left!" ,
							timeout    = 5 ,
							position   = "top_right" ,
							fg         = beautiful.fg_focus ,
							bg         = beautiful.bg_focus
						}
					)

					notification.config.presets = "critical"
				end

			elseif sta:match("Full") then
				--la batterie est completement chargée
				info = "F"

			else	--l'état de la baterie est inconnue
				info = "?"..state.."%?"

			end

			--close power sys files
			fcur:close()
			fcap:close()
			fsta:close()
			info = "B:"..info
		else
			info = "E"
		end
		self.widget.text = info
	end

	function battery.newWidget(o, adapter, refreshTime)

		myBattery = {}
		setmetatable(myBattery, { __index = battery })

		myBattery:init(adapter, refreshTime)

		return myBattery.widget
	end

	function battery:init(adapter, refreshTime)

		self.adapter = adapter or battery.defaultAdapter
		self.refreshTime = refreshTime or battery.defaultRefreshTime

		self.widget = widget({type = "textbox", name = "batteryget", align = "right" })

		self.timer=timer({timeout=o.refreshTime})
		self.timer:connect_signal("timeout", function() o:update() end)
		self.timer:start()

		self:update()
	end


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

-- CPU usage widget
	jiffies = {}
	function activecpu()
		local cpustat = {}
		for line in io.lines("/proc/stat") do
			local cpu, newjiffies = string.match(line, "(cpu%d*) +(%d+)")
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
	cpuinfo_timer:connect_signal("timeout", function()
		local cpustat=activecpu()
		cpuinfo.text = "cpu"..":"..(cpustat)["cpu"]
		if cpuMoreInfo
			then cpuMoreInfo.box.widgets[2].text=cpupopup(cpustat)
			 --cpuinfo.text="POP"
		end
		end)
	--cpuinfo_timer:start()


	cpuinfo:connect_signal('mouse::enter', function ()
                local cpustat=activecpu()
                cpuMoreInfo= naughty.notify({
                text = cpupopup(cpustat),
                timeout = 0, hover_timeout = 0.5,
                width = 270, screen = mouse.screen
                })end
        )
	cpuinfo:connect_signal('mouse::leave', function ()
		naughty.destroy(cpuMoreInfo)
		cpuMoreInfo=nil
		end
	)

--temperature widget
		temperature = {}
		temperature.update_periode=5
	--fonction definition
		function temperature.get()
			fs=io.popen("sensors")
			s=fs:read("*all")
			fs:close()
			local temperature = {}
			for m,t in string.gmatch(s,"([%a%d ]+): *([+-]%d+.%d+)Â°C") do
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
		temperature.widget = widget({ type = "textbox", name = "temperature", align = "right" })
		--temperature.update(temperature.widget)
	--add button
		temperature.widget:connect_signal('mouse::enter', function ()
				temperature.popup = naughty.notify({
					text = temperature.textPopup(temperature.temperatures),
					timeout = 0, hover_timeout = 0.5,
					width = 270, screen = mouse.screen
		        	})
		        end
		)
		temperature.widget:connect_signal('mouse::leave', function ()
				naughty.destroy(temperature.popup)
				temperature.popup=nil
			end
		)
	--update timer
		temperature.timer = timer({ timeout = temperature.update_periode})
		temperature.timer:connect_signal("timeout", function() temperature.update(temperature.widget,temperature.popup) end)
		--temperature.timer:start()



-- Keyboard map indicator and changer
	kbdcfg = {}
	kbdcfg.cmd = "setxkbmap"
	kbdcfg.layout = { "fr bepo", "fr", "us"}
	kbdcfg.layoutNames = { "bepo", "azerty", "qwerty"}
	kbdcfg.current = 1  --  bépo is our default layout

	function kbdcfg:switch (num)
		self.current = num or self.current % #(self.layout) + 1
		self.widget.text = " " .. self.layoutNames[self.current] .. " "
		awful.util.spawn( self.cmd .. " " .. self.layout[self.current] .. " " )
	end

	function kbdcfg:getWidget ()
		if not self.widget then

			self.widget = widget({ type = "textbox", align = "right" })
			self.widget.text = " " .. self.layoutNames[self.current] .. " "

			-- Mouse bindings
			self.widget:buttons(awful.util.table.join(
				awful.button({ }, 1, function () self:switch() end)
			))
			root.addKeys(
				awful.key(
					{modkey,"Shift"  },
					"Tab",
					function ()	self:switch() end
				)
			)
		end
		return self.widget
	end

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

-- create separator
	separator = widget({ type = "textbox" })
	separator.text = " "

-- Create a systray
mysystray = widget({ type = "systray" })


-- Add a ammend keys fonction to root
function root.addKeys(newKeys)
	root.keys(
		awful.util.table.join(
			root.keys(),
			newKeys
		)
	)
end


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
        luaConfigFile.newWidget(),
--      separator,
--      cpuinfo,
        separator,
        meminfo.newWidget(),
--      separator,
--      battery.widget,
--      separator,
--      temperature.widget,
        separator,
        tb_volume.newWidget(),
        separator,
        kbdcfg:getWidget(),
        separator,
        CompteArebours.newWidget(),
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
              end)
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

-- Add keys
root.addKeys(globalkeys)
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
    -- Display plugin fullsceen
    { rule = { instance = "plugin-container" },
      properties = { floating = true } },
    --set skype to tag 6
    { rule = { class = "skype" },
      properties = { tag = tags[1][6] , floating = false,  } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
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

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
