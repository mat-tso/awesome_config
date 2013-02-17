-- This module provide a widget that monitor the temperature

-- Standard awesome library
local awful = require("awful")
local gears = require("gears")
-- Widget and layout library
local wibox = require("wibox")
-- Notification library
local naughty = require("naughty")


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
			widget:set_text("T:"..temperature.temptostring (t).."°C")
			if widget_popup then
				widget_popup.box.widgets[2]:set_text(temperature.textPopup())
			end
		end
	--widget definition
		temperature.widget = wibox.widget.textbox()
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


