-- This module provide a timer widget

-- Standard awesome library
local awful = require("awful")
-- Widget and layout library
local wibox = require("wibox")
-- Notification library
local naughty = require("naughty")

local CompteArebours = {}
CompteArebours.public = {}


-- Notification
function CompteArebours.notification (message)
	message = message or "Compte à rebour terminer"
	naughty.notify({
		text = message,
		timeout = 10, hover_timeout = 0.5,
		--width = 270,
		screen = mouse.screen
	})
end

-- Convertie des seconde en seconde,minute,heure,nbSecTotal
function CompteArebours.convertirTemps (seconde,minute,heure)

	seconde = tonumber(seconde) or 0
	minute = tonumber(minute) or 0
	heure = tonumber(heure) or 0

	local nbSecTotal = seconde + 60*minute + 3600*heure

	seconde = nbSecTotal%60
	minute = math.floor(nbSecTotal/60)%60
	heure = math.floor(nbSecTotal/3600)

	return seconde, minute, heure, nbSecTotal
end

-- Met a jour l'affichage
function CompteArebours:redraw()
	local text = ""

	-- Print time if not null
	if self.tempsRestant > 0 then
		local s,m,h = self.convertirTemps(self.tempsRestant)
		if m == 0 and h == 0 then
			m=''
		else
			m = m .. ":"
		end

		if h == 0 then
			h=''
		else
			h = h .. ":"
		end
		text = text .. h..m..s
	end

	-- Print if timer is paused
	if self.started and not self.running and self.tempsRestant > 0 then
		text = text .. "P"
	end

	-- Print if timer is ringing
	if self.ringing then
		text = text .. "R"
	end

	-- If nothing to print, print default text
	if text == "" then
		text = self.defaultText
	end

	self.widget:set_text(text)
end

function CompteArebours:playRingtone ()
	self:stopRingtone()
	-- self.PIDsonnerie = awful.util.spawn('aplay '.. self.sonnerieFile ..' vlc://quit')
	self.PIDsonnerie = awful.util.spawn('cvlc '.. self.sonnerieFile ..' vlc://quit')
	self.ringing = true
	self:redraw()
end

function CompteArebours:stopRingtone ()
	if self.PIDsonnerie then
		awful.util.spawn("kill " .. self.PIDsonnerie)
		self.PIDsonnerie = nil
	end
	self.ringing = false
	self:redraw()
end

function CompteArebours:changeRingtone()
	awful.prompt.run(
		{prompt = 'Ringtone: '},
		self.widget,
		function (ringtonePath) self:setRingtone(ringtonePath) end,
		awful.completion.shell,
		self.sonneriehistoryFile, -- history_path
		100, -- history_max
		function () self:redraw() end -- done_callback : redraw widget
	)
end

function CompteArebours:setRingtone(ringtonePath)
	self.sonnerieFile = ringtonePath
	local notificationMessage = self.sonnerieFile.." is the new ringtone"
	if self.sonneriePathFile then
		local sonneriePathHandler, message = io.open(self.sonneriePathFile, "w")
		if sonneriePathHandler then
			sonneriePathHandler:write(self.sonnerieFile)
			sonneriePathHandler:close()
			notificationMessage = notificationMessage .. " (saved)"
		else
			notificationMessage = notificationMessage ..
				" (unable to save: " .. message .. ")"
		end
	end
	self.notification(notificationMessage )
end

function CompteArebours:start()
	if self.tempsRestant > 0 then
		if not self.timer.started then
			self.timer:start()
		end
		self.started = true
		self.running = true
		self:decrease()
	end
end

function CompteArebours:pause()
	if self.timer.started then
		self.timer:stop()
	end
	self.running = false
	self:redraw()
end

function CompteArebours:toogle()
	if self.started and self.running then
		self:pause()
	else
		self:start()
	end
end

function CompteArebours:stop ()
	self:pause()
	self.tempsRestant = 0
	self:stopRingtone()
	self.started = false
	self:redraw()
end

function CompteArebours:timerEndNotify()
		self:playRingtone()
		self.notification()
end

function CompteArebours:decrease()
	if self.tempsRestant <= 0 then
		self:pause()
		self:timerEndNotify()
	else
		self.tempsRestant = self.tempsRestant -1
	end
	self:redraw()
end

function CompteArebours:addTime(nbSec)
	self.tempsRestant = self.tempsRestant + nbSec
	if self.tempsRestant < 0 then self.tempsRestant = 0 end
	self:redraw()
end

function CompteArebours:init(args)

	self.defaultText = "T"

	local args = args or {}
	self.sonnerieFile = args["sonnerieFile"]
	self.sonneriePathFile = nil

	if args["saveRingtone"] then
		local sonneriePathFileSuffix = args["sonneriePathFileSuffix"] or "default"
		self.sonneriePathFile = awful.util.getdir("cache") .. "/timerRingtone_" .. sonneriePathFileSuffix
		self.sonneriehistoryFile = awful.util.getdir("cache") .. "/timerRingtoneHistory_" .. sonneriePathFileSuffix

		local sonneriePathFileHandler = io.open(self.sonneriePathFile)
		if sonneriePathFileHandler and not self.sonnerieFile then
			self.sonnerieFile = sonneriePathFileHandler:read("*a")
		end
	end

	self.sonnerieFile = self.sonnerieFile or "/dev/urandom"

	self.periodeUpdate = 1

	self.tempsRestant=0
	self.PIDsonnerie = nil
	self.started = false
	self.running = false
	self.ringing = false

	self.widget = wibox.widget.textbox()
	self.widget:set_text(self.defaultText)

	self.widget:buttons(
		awful.util.table.join(
			awful.button({ }, 4, function () self:addTime(60) end),
			awful.button({ }, 5, function () self:addTime(-60) end),

			awful.button({ "Shift" }, 4, function () self:addTime(1) end),
			awful.button({ "Shift" }, 5, function () self:addTime(-1) end),

			awful.button({ "Control" }, 4, function () self:addTime(3600) end),
			awful.button({ "Control" }, 5, function () self:addTime(-3600) end),

			awful.button({}, 1, function () self:toogle() end),
			awful.button({}, 2, function () self:stop() end),
			awful.button({}, 3, function () self:stopRingtone() end),
			awful.button({ modkey }, 3, function () self:changeRingtone() end)
		)
	)
	self.timer=timer ({timeout = self.periodeUpdate})
	self.timer:connect_signal("timeout",function () self:decrease() end)

	self.timerSonnerie=timer ({timeout = 1})
	self.timerSonnerie:connect_signal("timeout",function () self:recupSonnerie() end)
end

function CompteArebours.public.newWidget(args)

	myCompteArebours = {}
	setmetatable(myCompteArebours, { __index = CompteArebours })

	myCompteArebours:init(args)

	return myCompteArebours.widget
end

return CompteArebours.public
