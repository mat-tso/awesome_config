-- This module provide a widget that monitor the cpu consuption

-- Standard awesome library
local awful = require("awful")
local gears = require("gears")
-- Widget and layout library
local wibox = require("wibox")
-- Notification library
local naughty = require("naughty")

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

	cpuinfo = wibox.widget.textbox()

	cpuinfo_timer = timer({ timeout = 1})
	cpuinfo_timer:connect_signal("timeout", function()
		local cpustat=activecpu()
		cpuinfo:set_text("cpu"..":"..(cpustat)["cpu"])
		if cpuMoreInfo
			then cpuMoreInfo.box.widgets[2]:set_text(cpupopup(cpustat))
			 --cpuinfo:set_text("POP")
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
