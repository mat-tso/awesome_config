--module("CompteArebour")
function CompteArebour ()
	local CaR={}
	CaR.defaultText = "T"
	CaR.sonnerieFile = "\"Musique/Q10 - Tetris - Type A.mp3\""
	CaR.periodeUpdate = 1
	CaR.tempsRestant=0
	CaR.widget = widget ({type = "textbox",align = "right" })
	CaR.widget.text= CaR.defaultText
	CaR.PIDsonnerie = -1
	
	CaR.timer=timer ({timeout = CaR.periodeUpdate})
	CaR.timer:add_signal("timeout",function () CaR:update() end)
	
	CaR.timerSonnerie=timer ({timeout = 1})
	CaR.timerSonnerie:add_signal("timeout",function () CaR:recupSonnerie() end)
	
	--notification de fin de timer
	CaR.notification = function (message)
			message = message or "Compte à rebour terminer"
			naughty.notify({
			text = message,
			timeout = 10, hover_timeout = 0.5,
			--width = 270,
			screen = mouse.screen
		   	})
    end
    CaR.sonnerie = function (CaR)
    	CaR:stopSonnerie()
		CaR.PIDsonnerie = awful.util.spawn('cvlc '.. CaR.sonnerieFile ..' vlc://quit')
	end
	CaR.stopSonnerie = function (CaR)
		if CaR.PIDsonnerie ~= -1 then
			awful.util.spawn("kill " .. CaR.PIDsonnerie)
			CaR.PIDsonnerie = -1
		end
	end
	--convertie des seconde en seconde,minute,heure,nbSecTotal
	CaR.convertirTemps = function (seconde,minute,heure)
		seconde = tonumber(seconde) or 0
		minute = tonumber(minute) or 0
		heure = tonumber(heure) or 0
		local nbSecTotal = seconde + 60*minute + 3600*heure
		seconde = nbSecTotal%60
		minute = math.floor(nbSecTotal/60)%60
		heure = math.floor(nbSecTotal/3600)
	return seconde, minute, heure, nbSecTotal
	end
	
	CaR.changeSonnerie = function(CaR)
		--CaR.adrrSonnerie = io.popen("zenity --title='Choisir le fichier sonnerie'  --file-selection ; echo fin","r")
		CaR.adrrSonnerie = os.tmpname ()
		awful.util.spawn_with_shell("zenity --title='Choisir le fichier sonnerie'  --file-selection>"..CaR.adrrSonnerie)
		CaR.timerSonnerie:start()
	end
	CaR.recupSonnerie = function(Car)
		local file = io.open(CaR.adrrSonnerie)
		if file ~=nil then 
			local son = file:read()
				if son ~=nil then 
				--local mimetype = os.execute("mimetype -b "..son)
				--local mediatype = string.match(mimetype, "\n(.+)/")
				--if mediatype == "audio" then
					CaR.sonnerieFile='\"'..son..'\"'
					CaR.notification(CaR.sonnerieFile.." est la nouvelle sonnerie")
					print(CaR.sonnerieFile.." est la nouvelle sonnerie")
				--else
				--	CaR.notification(son.." est de type : "..mimetype.." et non de type audio")
				--end
				file:close ()
				CaR.timerSonnerie:stop()
				os.execute("rm "..CaR.adrrSonnerie)
			end
		end
	end
	
	--met a jour l'affichage
	CaR.redraw= function (CaR) 
		local s,m,h = CaR.convertirTemps(CaR.tempsRestant)
		if m == 0 then m=''
		else m = m..":" end
		if h == 0 then h=''
		else h = h..":" end
		CaR.widget.text = h..m..s
	end
	CaR.reset = function (CaR) 
		CaR.tempsRestant = 0
		CaR.timer:stop()
		CaR.widget.text = CaR.defaultText
		CaR:stopSonnerie()
	end

	CaR.update = function (CaR)
		if CaR.tempsRestant <= 0 then
			CaR.timer:stop()
			CaR:sonnerie()
			CaR.notification()
			CaR:redraw()
		else 
			CaR.tempsRestant = CaR.tempsRestant -1
			CaR:redraw()
		end
	end
	CaR.start = function (CaR) 
		if  not CaR.timer.started then
			CaR.timer:start()
			CaR:update()
		end
	end
	CaR.ajouter = function(CaR,nbSec)
		CaR.tempsRestant = CaR.tempsRestant + nbSec
		if CaR.tempsRestant < 0 then CaR.tempsRestant = 0 end
		CaR:redraw()
	end
	
	CaR.widget:buttons(awful.util.table.join(
		awful.button({ }, 4, function () CaR:ajouter(60) end),
		awful.button({ }, 5, function () CaR:ajouter(-60) end),
		
		awful.button({ "Shift" }, 4, function () CaR:ajouter(1) end),
		awful.button({ "Shift" }, 5, function () CaR:ajouter(-1) end),
		
		awful.button({ "Control" }, 4, function () CaR:ajouter(3600) end),
		awful.button({ "Control" }, 5, function () CaR:ajouter(-3600) end),
		
		awful.button({}, 1, function () CaR:start() end),
		awful.button({}, 2, function () CaR:reset() end),
		awful.button({}, 3, function () CaR:stopSonnerie() end),
		awful.button({ modkey }, 3, function () CaR:changeSonnerie() end)
	))
	return CaR.widget
end
