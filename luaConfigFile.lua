
--check lua config widget

luaConfigFile = {}
luaConfigFile.configFilePath = awful.util.getdir("config").."/rc.lua"
luaConfigFile.debugFilePath = os.getenv("PWD") .. "/.xsession-errors"

--methodes
function luaConfigFile.isLuaFileValid(path)
	local f=awful.util.checkfile(path)
	local valid = true
	if type(f) == "string" then
		valid = false
	end
	return valid, f
end

function luaConfigFile.bool2char(bool)
	local listChar = {[true]="✔",[false]="✘"}
	return listChar[bool]
end

function luaConfigFile.tail(path, nbLine)
	local nbLine = nbLine or 10
	local fullFile = {}
	for ligne in io.lines(path) do
		table.insert(fullFile,ligne)
	end

	local lastLines = {}
	for num = (#fullFile - nbLine),#fullFile do
		table.insert(lastLines, fullFile[num])
	end

	return lastLines
end

function luaConfigFile.clear(path)
	local path = path or luaConfigFile.debugFilePath
	io.open(path,"w+"):close()
end

function luaConfigFile:update (notificationDemandee)
	notificationDemandee = notificationDemandee or false

	local valid, message = self.isLuaFileValid(self.configFilePath)
	self.widget.text = self.bool2char(valid)

	if valid then

		local tableauLigne = self.tail(self.debugFilePath)
		local nbligne = #tableauLigne

		if nbligne < 1 then nbligne = 1 end

		message = table.concat(tableauLigne,"\n")

		if message == "" then
			message =
				"Tout est OK ;)\n"..
				"Commande :\n"..
				"clic1              : actualisation\n"..
				"modkey+clic1       : ouvre rc.lua dans l'editeur\n"..
				"modkey+ctl+clic1   : ouvre *.lua dans l'éditeur\n"..
				"modkey+shift+clic1 : ouvre $(dirname rc.lua) dans l'editeur\n"..
				"clic2              : restart si pas d'erreur\n"..
				"clic3              : efface log et affiche ce message"
		end
	end

	if notificationDemandee then
		--destroy previous notification
		if  self.notification then
			 naughty.destroy(self.notification)
		end

		self.notification = naughty.notify({
			text = message,
			timeout = 0, hover_timeout = 0.5,
			screen = mouse.screen, --width = 450
		})
	end
end

function luaConfigFile.openConfigFile(file)

	local command = terminal .. ' -e "' ..
			editor .. ' -p "' .. awful.util.getdir("config") .. "/" .. file .. '" ' ..
			" -c '" ..
				'cd "' .. awful.util.getdir("config") .. '"' ..
			"'"..
		'"'

	awful.util.spawn(command, false, mouse.screen)
end

--create widget
function luaConfigFile:addWidget()

	self.widget = widget({ type = "textbox", name = "config", align = "right" })

	self:update()
	--timer
	self.timer = timer({ timeout = 30})
	self.timer:connect_signal("timeout", function () self:update() end)
	self.timer:start()

	--signals
	self.widget:connect_signal('mouse::enter', function ()
		self:update(true)
		end
	)
	self.widget:connect_signal('mouse::leave', function ()
				naughty.destroy(self.notification)
				self.notification=nil
		end
	)

	--mouse bouton
	self.widget:buttons(awful.util.table.join(

		--update when left clic
		awful.button({ }, 1, function () self:update(true) end),

		--open editor mod left clic
		awful.button({ modkey }, 1, function ()
				luaConfigFile.openConfigFile("rc.lua")
			end),

		awful.button({ modkey , "Shift" }, 1, function ()
				luaConfigFile.openConfigFile("")
			end),

		awful.button({ modkey , "Control" }, 1,
			function ()
				luaConfigFile.openConfigFile("*.lua")
--				awful.util.spawn_with_shell(
--					"cd '"..awful.util.getdir("config") .. "' && " ..
--					"find  . " ..
--						" \\( -name .git -prune \\) -o " ..
--						"-name '*.lua' -print0 | " ..
--					"xargs --null -n1 -P5 ".. editor_cmd .. )
--					editor_cmd .. "*.lua" )
			end
		),

		--restart on midle clic
		awful.button({ }, 2, function ()
			if self.isLuaFileValid(self.configFilePath) then
				awesome.restart()
			end
		end),

		--clean on right clic
		awful.button({ }, 3, function () self.clear() self:update(true) end)
	))
end

--constructor
function luaConfigFile.newWidget()
	myluaConfigFile = {}
	setmetatable(myluaConfigFile, { __index = luaConfigFile })

	myluaConfigFile:addWidget()
	return myluaConfigFile.widget
end

