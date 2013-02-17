-- This module will provide a widget that can switch between multiple states
-- TODO: make a generic widget for any switch command

-- Standard awesome library
local awful = require("awful")
local gears = require("gears")
-- Widget and layout library
local wibox = require("wibox")
-- Notification library
local naughty = require("naughty")

-- Keyboard map indicator and changer
	kbdcfg = {}
	kbdcfg.cmd = "setxkbmap"
	kbdcfg.layout = { "fr bepo", "fr", "us"}
	kbdcfg.layoutNames = { "bepo", "azerty", "qwerty"}
	kbdcfg.current = 1  --  bépo is our default layout

	function kbdcfg:switch (num)
		self.current = num or self.current % #(self.layout) + 1
		self.widget:set_text(" " .. self.layoutNames[self.current] .. " ")
		awful.util.spawn( self.cmd .. " " .. self.layout[self.current] .. " " )
	end

	function kbdcfg:getWidget ()
		if not self.widget then

			self.widget = wibox.widget.textbox()
			self.widget:set_text(" " .. self.layoutNames[self.current] .. " ")

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
	vpnccfg.widget = wibox.widget.textbox()
	vpnccfg.widget:set_text(" " .. vpnccfg.cmdNames[vpnccfg.current] .. " ")
	vpnccfg.switch = function ()
		vpnccfg.current = vpnccfg.current % #(vpnccfg.cmd) + 1
		vpnccfg.widget:set_text(" " .. vpnccfg.cmdNames[vpnccfg.current] .. " ")
		local pid = awful.util.spawn(vpnccfg.cmd[vpnccfg.current])
		--[[
		naughty.notify({text = tostring(err).."\t".. vpnccf.gcodeErreur[err] or "erreur indefinie",
					timeout = 3, hover_timeout = 0.5,
					width = 270, screen = mouse.screen
		        	})--]]
	end

	-- Mouse bindings
	vpnccfg.widget:buttons(awful.util.table.join(
	awful.button({ }, 1, function () vpnccfg.switch() end)
	))
