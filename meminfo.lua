
-- memory usage widget

	meminfo = {}
	
	function meminfo.humanReadable (num,unit)
		num=tonumber(num)
		unit = unit or {"","K","M","G","T"}
		local text
		local i=1
		while num>=1024 do
			num=num/1024
			i=i+1
		end
		text=(math.floor(num*10)/10)..(unit[i] or "unknown unit")
		return text
	end

	function meminfo:getInfo()
		for line in io.lines("/proc/meminfo") do
			local title, value = string.match(line, "(.+):\ +(%d+)")
			if title and value then
				self.stat[title] = value
			end
		end
	end
	function meminfo:update ()
		self:getInfo()
		local text = ((self.stat["MemTotal"]
				 - self.stat["MemFree"]
				 - self.stat["Buffers"]
				 - self.stat["Cached"])/ self.stat["MemTotal"])*100
		text = string.format("%02d",text)
		self.widget.text="M:"..text.."%"

	end

	function meminfo:detailPopup()
		local info = {
			{"Statistique de la mémoire vive", nil},
			{"utilisée par les programmes", self.stat["MemTotal"]
				 - self.stat["MemFree"]
				 - self.stat["Buffers"]
				 - self.stat["Cached"]
			},
			{"mémoire libre" 		, self.stat["MemFree"]},
			{"disponible pour ètre allouée" , self.stat["CommitLimit"]},
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
				textPopup = textPopup.."  "..pair[1].." : "..meminfo.humanReadable(pair[2],{"K","M","G","T"}).."\n"
			else
				textPopup = textPopup .. pair[1].." : \n"
			end
		end
		textPopup = textPopup.."\nconf : /proc/meminfo"

		self.nautification = naughty.notify({
		        text = textPopup,
		        timeout = 0, hover_timeout = 0.5,
		        width = 270, screen = mouse.screen
                })
	end

	function meminfo.newWidget()	
		myMeminfo = {}

		setmetatable(myMeminfo, { __index = meminfo })

		myMeminfo:init()

		return myMeminfo.widget
	end

	function meminfo:init ()
	
		self.stat = {}

		self.widget = widget({ type = "textbox", align = "right",text = 'init...'})
		self.widget:add_signal('mouse::enter', function() self:detailPopup() end)
		self.widget:add_signal('mouse::leave', function ()
			naughty.destroy(self.nautification)
			self.nautification=nil
			end)

		self.timer = timer({ timeout = 60})
		self.timer:add_signal("timeout", function() self:update () end )
		self.timer:start()

		self:update ()
	end
