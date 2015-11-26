-- Standard awesome library
local awful = require("awful")
-- Widget and layout library
local wibox = require("wibox")
-- Notification library
local naughty = require("naughty")


watch = {}
function watch:init(id, executable)
	self.id = id
	self.executable = executable
	self.widget = wibox.widget.textbox()
	self:updateText("Unknown")

	self.widget:connect_signal('mouse::enter', function()
		self.notification = naughty.notify({
			text = self.text .. "\n" .. os.date("Update:\n%M:%S ago", os.time() - self.time),
			timeout = 0,
			screen = mouse.screen})
		end)
	self.widget:connect_signal('mouse::leave', function ()
		naughty.destroy(self.notification)
		self.notification=nil
		end)

	self.timer = timer({ timeout = 200 })
	self.timer:connect_signal("timeout", function() self:asyncUpdate() end)
	self.timer:emit_signal("timeout")
	self.timer:start()

end

function watch:asyncUpdate(text)
	os.execute(self.executable .. [[ |
			xargs -0 printf 'watch.updateCb(]] .. self.id .. [[, [=[%s]=])' |
			awesome-client &
	]])
end

function watch:updateText(text)
	self.time = os.time()
	if text == ""
		then self.text = "No bus"
		else self.text = text
	end
-- Set the first line as the widget text
	self.widget:set_text(string.gmatch(text, '[^\n]*')())
end

function watch.updateCb(id, text)
	local instance = watch.instances[id]
	if instance == nil then
		io.stderr:write("Can not update watch widget " .. id.. "as it no longer exists.")
		return
	end
	instance:updateText(text)
end

function watch.newWidget(executable)
	local instance = {}
	setmetatable(instance, { __index = watch })
	table.insert(watch.instances, instance)
	instance:init(#watch.instances, executable)
	return instance.widget
end

-- Array of all instance to give them universal ids for callback from bash
watch.instances = {}
-- Instance tracking should not prevent them from being garbage collected
setmetatable(watch.instances, { __mode = "v" })

return watch
