--module("CompteArebours")

local CompteArebours = {}
CompteArebours.public = {}


--notification de fin de timer
function CompteArebours.notification (message)
	message = message or "Compte à rebour terminer"
	naughty.notify({
		text = message,
		timeout = 10, hover_timeout = 0.5,
		--width = 270,
		screen = mouse.screen
	})
end

function CompteArebours:playRingtone ()

	self:stopRingtone()
	self.PIDsonnerie = awful.util.spawn('aplay '.. self.sonnerieFile ..' vlc://quit')
end

function CompteArebours:stopRingtone ()

	if self.PIDsonnerie then
		awful.util.spawn("kill " .. self.PIDsonnerie)
		self.PIDsonnerie = nil
	end
end

--convertie des seconde en seconde,minute,heure,nbSecTotal
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

function CompteArebours:changeRingtone()
	--self.adrrSonnerie = io.popen("zenity --title='Choisir le fichier sonnerie'  --file-selection ; echo fin","r")
	self.adrrSonnerie = os.tmpname ()
	awful.util.spawn_with_shell("zenity --title='Choisir le fichier sonnerie'  --file-selection>"..self.adrrSonnerie)
	self.timerSonnerie:start()
	-- dialog --fselect "" $(( $(tput lines) - 10 )) $(( $(tput cols) - 2 ))
	-- dialog  --fselect "" $(dialog --print-maxsize  2>&1 > /dev/null | grep -oe "[0-9]*")
end

function CompteArebours:recupSonnerie()

	local file = io.open(self.adrrSonnerie)
	if file then 
		local son = file:read()
			if son then 
			--local mimetype = os.execute("mimetype -b "..son)
			--local mediatype = string.match(mimetype, "\n(.+)/")
			--if mediatype == "audio" then
				self.notification(self.sonnerieFile.." est la nouvelle sonnerie")
				print(self.sonnerieFile.." est la nouvelle sonnerie")
			--else
			--	self.notification(son.." est de type : "..mimetype.." et non de type audio")
			--end
			file:close ()
			self.timerSonnerie:stop()
			os.execute("rm "..self.adrrSonnerie)
		end
	end
end

--met a jour l'affichage
function CompteArebours:redraw()

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

	self.widget.text = h..m..s
end

function CompteArebours:reset () 

	self.tempsRestant = 0
	self.timer:stop()
	self.widget.text = self.defaultText
	self:stopRingtone()
end

function CompteArebours:update ()

	if self.tempsRestant <= 0 then
		self.timer:stop()
		self:playRingtone()
		self.notification()
		self:redraw()
	else 
		self.tempsRestant = self.tempsRestant -1
		self:redraw()
	end
end

function CompteArebours:start()

	if  not self.timer.started then
		self.timer:start()
		self:update()
	end
end

function CompteArebours:ajouter(nbSec)

	self.tempsRestant = self.tempsRestant + nbSec
	if self.tempsRestant < 0 then self.tempsRestant = 0 end
	self:redraw()
end

function CompteArebours.public.newWidget()

	myCompteArebours = {}
	setmetatable(myCompteArebours, { __index = CompteArebours })

	myCompteArebours:init()

	return myCompteArebours.widget
end

function CompteArebours:init(sonnerieFile)

	self.defaultText = "T"
	self.sonnerieFile = sonnerieFile or "\"/dev/urandom\""
	self.periodeUpdate = 1

	self.tempsRestant=0
	self.PIDsonnerie = nil

	self.widget = widget ({type = "textbox",align = "right" })
	self.widget.text= self.defaultText

	self.widget:buttons(
		awful.util.table.join(
			awful.button({ }, 4, function () self:ajouter(60) end),
			awful.button({ }, 5, function () self:ajouter(-60) end),
			
			awful.button({ "Shift" }, 4, function () self:ajouter(1) end),
			awful.button({ "Shift" }, 5, function () self:ajouter(-1) end),
			
			awful.button({ "Control" }, 4, function () self:ajouter(3600) end),
			awful.button({ "Control" }, 5, function () self:ajouter(-3600) end),
			
			awful.button({}, 1, function () self:start() end),
			awful.button({}, 2, function () self:reset() end),
			awful.button({}, 3, function () self:stopRingtone() end),
			awful.button({ modkey }, 3, function () self:changeRingtone() end)
		)
	)

	self.timer=timer ({timeout = self.periodeUpdate})
	self.timer:add_signal("timeout",function () self:update() end)

	self.timerSonnerie=timer ({timeout = 1})
	self.timerSonnerie:add_signal("timeout",function () self:recupSonnerie() end)
end

return CompteArebours.public
