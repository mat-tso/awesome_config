-- This module provide a widget that print and control the sound volume

-- Standard awesome library
local awful = require("awful")
-- Widget and layout library
local wibox = require("wibox")

-- Volume widget

	--fonction definition
	tb_volume = {}

	function tb_volume:update ()
		local fd = io.popen("amixer " .. self.cardid .. " -- sget " .. self.channel)
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
		self.widget:set_text(volume)
	end

	function tb_volume:setVolume (newVolume)
		io.popen("amixer " .. self.cardid .. " sset " .. self.channel .. " " .. newVolume):read("*all")
		self:update()
	end

	function tb_volume:up ()
		self:setVolume("5%+")
	end

	function tb_volume:down ()
		self:setVolume("5%-")
	end

	function tb_volume:mute ()
		 self:setVolume("toggle")
	end

	function tb_volume.newWidget (cardid, channel)

		mytb_volume = {}
		setmetatable(mytb_volume, { __index = tb_volume })

		mytb_volume:init (cardid, channel)

		return mytb_volume.widget
	end

	function tb_volume:init(cardid, channel)

		if cardid then
			self.cardid = "-c " .. cardid
		else
			self.cardid = ""
		end

		self.channel = channel or "Master"

		--update timer
		self.timer = timer({ timeout = 10})
		self.timer:connect_signal("timeout", function() self:update() end)
		self.timer:start()

		--widget definition
		self.widget = wibox.widget.textbox()
		--tb_volume:set_text("volume")
		self.widget:buttons(
			awful.util.table.join(
				awful.button({ }, 4, function () self:up() end),
				awful.button({ }, 5, function () self:down() end),
				awful.button({ }, 1, function () self:mute () end),
				awful.button({ }, 3, function ()
					awful.util.spawn(terminal .. "-e alsamixer",false,mouse.screen)
					end
				)
			)
		)
		self:update()

		-- add keys
		root.addKeys(awful.util.table.join(
			awful.key({},"XF86AudioRaiseVolume", function () self:up()   end),
			awful.key({},"XF86AudioLowerVolume", function () self:down() end),
			awful.key({},"XF86AudioMute",        function () self:mute() end)
		))
	end

return tb_volume
