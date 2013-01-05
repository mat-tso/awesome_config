-- This module provide a widget that monitor the memory consuption

-- Standard awesome library
local awful = require("awful")
local gears = require("gears")
-- Widget and layout library
local wibox = require("wibox")
-- Notification library
local naughty = require("naughty")

-- memory usage widget

	meminfo = {}

	function meminfo.humanReadable (num,unit)
		num=tonumber(num)
		unit = unit or {"","K","M","G","T"}
		local text
		local i=1
		while num>=1024 and unit[i] do
			num=num/1024
			i=i+1
		end
		text=(math.floor(num*10)/10)..(unit[i] or "unknown unit")
		return text
	end

	function meminfo:getInfo()
		for line in io.lines("/proc/meminfo") do
			local title, value = string.match(line, "(.+): +(%d+)")
			if title and value then
				self.stat[title] = value
			end
		end
	end
	function meminfo:update ()
		self:getInfo()
		local myUsedMemory = ((self.stat["MemTotal"]
				 - self.stat["MemFree"]
				 -- - self.stat["Buffers"]
				 -- - self.stat["Cached"]
				 ))
		self.stat["myUsedMemory"] = myUsedMemory
		local myUsedMemoryFrac = myUsedMemory / self.stat["MemTotal"]
		self.graph:add_value(myUsedMemoryFrac)

	end

	function meminfo:detailPopup()
		local info = {
			{"Statistique de la mémoire vive", nil},
			{"utilisée (prog, buff, cache)" , self.stat["myUsedMemory"]},
			{"utilisée par les programmes"  , self.stat["MemTotal"]
				 - self.stat["MemFree"]
				 - self.stat["Buffers"]
				 - self.stat["Cached"]
			},
			{"mémoire libre" 		, self.stat["MemFree"]},
			{"disponible pour être allouée" , self.stat["CommitLimit"]},
			{"disponible (hors swap)"       , self.stat["CommitLimit"] - self.stat["SwapFree"]},
			{"mémoire totale" 		, self.stat["MemTotal"]},
			{"buffers" 			, self.stat["Buffers"]},
			{"utilisée comme cache" 	, self.stat["Buffers"] + self.stat["Cached"]},

			{"\nStatistique des transferts", nil },
			{"cache (ex : transferts vers DD)" , self.stat["Cached"]},
			{"en attente d'ètre écrite sur le disque" , self.stat["Dirty"]},

			{"\nStatistique du swap", nil},
			{"swap alloué"		, self.stat["SwapTotal"] - self.stat["SwapFree"]},
			{"swap disponible" 	, self.stat["SwapFree"]},
			{"taille du swap" 	, self.stat["SwapTotal"]},
		}
		local textPopup = ""
		for index,pair in pairs(info) do
			if pair[2] then
				textPopup = textPopup.."  "..pair[1].." : "..
					meminfo.humanReadable(pair[2], {"K", "M", "G", "T"}) ..
					" (" ..
					-- round % nunber/total
					math.floor(pair[2]/self.stat["MemTotal"]*100 + 0.5)
					.. "%)"
			else
				textPopup = textPopup .. pair[1].." :"
			end

			textPopup = textPopup .. "\n"
		end
		textPopup = textPopup.."\nconf : /proc/meminfo"

		self.nautification = naughty.notify({
		        text = textPopup,
		        timeout = 0, hover_timeout = 0.5,
		        -- width = 270,
			screen = mouse.screen
                })
	end

	function meminfo.newWidget()
		myMeminfo = {}

		setmetatable(myMeminfo, { __index = meminfo })

		myMeminfo:init()

		return myMeminfo.graph
	end

	function meminfo:init()

		self.stat = {}

		self.graph = awful.widget.graph()
		self.graph:set_width(60)
		self.graph:set_background_color('#808080') -- Gray
		self.graph:set_color('#008000') -- Green

		self.graph:connect_signal(
			'mouse::enter',
			function() self:detailPopup() end
		)
		self.graph:connect_signal(
			'mouse::leave',
			function ()
				naughty.destroy(self.nautification)
				self.nautification=nil
			end
		)

		self.timer = timer({timeout = 10})
		self.timer:connect_signal("timeout", function() self:update () end )
		self.timer:start()

		self:update ()
	end

return meminfo
