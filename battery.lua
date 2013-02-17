-- This module provide a widget that monitor the battery consuption

-- Standard awesome library
local awful = require("awful")
local gears = require("gears")
-- Widget and layout library
local wibox = require("wibox")
-- Notification library
local naughty = require("naughty")

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
		self.widget:set_markup(info)
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

		self.widget = wibox.widget.textbox()

		self.timer=timer({timeout=o.refreshTime})
		self.timer:connect_signal("timeout", function() o:update() end)
		self.timer:start()

		self:update()
	end


