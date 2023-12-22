
local Wasx = {
	_VERSION     = 'Wasx v2.0.0',
	_DESCRIPTION = 'A very versatile input manager for LÖVE (love2d)',
	_URL         = 'https://github.com/PhytoEpidemic/WASX_2.0',
	_LICENSE     = [[
MIT LICENSE

Copyright (c) 2023 PhytoEpidemic

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]],
	pathToThisFile = (...):gsub("%.", "/") .. ".lua",
}
Wasx.keyboardJoystickId = "1"
Wasx.PositionScale = {x=1,y=1}
function Wasx.setKeyboardID(id)
	Wasx.keyboardJoystickId = tostring(id) or "1"
end
function Wasx.setScale(x,y)
	Wasx.PositionScale.x, Wasx.PositionScale.y = x, y
end
function Wasx.AABB(interactionType,x1,y1,x2,y2)
	local positionIndex = interactionType.."Position"
	local workingPos = Wasx[positionIndex]
	if workingPos then
		workingPos.Checked = true
		local noCollision = false
		if workingPos.x < x1 or workingPos.x > x2 or workingPos.y < y1 or workingPos.y > y2 then
			
			noCollision = true
		end

		return not noCollision
	else
		return false
	end
end
local InputFunctions = {}
local allInputObjects = {}
local allCapturedJoysticks = {}
local function contains(t,v)
	for _,tv in ipairs(t) do
		if v == tv then return true end
	end
	return false
end
local function containsAny(t,vt)
	for _,tv in ipairs(vt) do
		if contains(t,tv) then
			return true
		end
	end
	return false
end

local function containsAll(t,vt)
	for _,tv in ipairs(vt) do
		if not contains(t,tv) then
			return false
		end
	end
	return true
end

local defaultValues = {}
defaultValues.axes = {x = 0,y = 0}
defaultValues.angle = false
defaultValues.trigger = 0
defaultValues.button = false
defaultValues.buttonOnce = false
defaultValues.buttonToggle = false
defaultValues.textinput = ""

local KeyboardInteraction = {
	"keypressed",
	"keyreleased",
	"textinput"
}


local validInteractionGroups = {}
local function updateData(j,interactionType,...)
	local userInput = {...}
	local function updateThisInput(inputObject,useGamepad)
		
		local function updateThisData(var,info)
			if not inputObject.data[var] then inputObject.data[var] = {Checked = false, State = defaultValues[info.type]} end
			if contains(validInteractionGroups[info.type],interactionType) then
				local buttons = info.buttons or {}
				local keys = info.keys or {}
				
				if (not contains(KeyboardInteraction,interactionType) and containsAny(buttons,userInput)) or containsAny(keys,userInput) or contains(userInput,info.type) then
					
					local function setDataState(val)
						inputObject.data[var]["State"] = val
					end
					
					if info.type == "button" then
						setDataState(inputObject:button(info))
					elseif info.type == "buttonOnce" then
						setDataState(inputObject:buttonOnce(info))
					elseif info.type == "buttonToggle" then
						setDataState(inputObject:buttonToggle(info))
					elseif info.type == "angle" then
						setDataState(inputObject:angle(info))
					elseif info.type == "axes" then
						setDataState(inputObject:axes(info))
					elseif info.type == "trigger" then
						setDataState(inputObject:trigger(info))
					elseif info.type == "textinput" then
						setDataState(userInput[1](inputObject))
					end
					
					inputObject.data[var]["Checked"] = false
				end
			end
		end
		
		
		for var,info in pairs(inputObject.keyMappings.data) do
			updateThisData(var,info)
			if info.subindex then
				for _,info in ipairs(info.subindex) do
					updateThisData(var,info)
				end
			end
		end
	end
	for id,joy in pairs(allInputObjects) do
		joy:isConnected()
		if joy.joystick == j then
			joy.useGamepad = true
			j = joy
		else joy.useGamepad = false end
		if joy == j then
			
			if interactionType == "mousemoved" or interactionType == "mousepressed" or interactionType == "mousereleased" then
				local positionIndex = interactionType.."Position"
				Wasx[positionIndex] = {x=userInput[1],y=userInput[2]}
				joy[positionIndex] = Wasx[positionIndex]
			end
			
			updateThisInput(joy)
			
			break
		end
	end
end


validInteractionGroups.axes = {"joystickaxis","keypressed","keyreleased"}
validInteractionGroups.angle = {"joystickaxis"}
validInteractionGroups.trigger = {"joystickaxis","keypressed","keyreleased","mousepressed","mousereleased"}
validInteractionGroups.button = {"joystickpressed","joystickreleased","keypressed","keyreleased","mousepressed","mousereleased"}
validInteractionGroups.buttonOnce = {"joystickpressed","keypressed","mousepressed"}
validInteractionGroups.buttonToggle = {"joystickpressed","keypressed","mousepressed"}
validInteractionGroups.textinput = {"textinput"}
function love.gamepadpressed(joystick,button)
	updateData(joystick,"joystickpressed",button)
end
function love.gamepadreleased( joystick, button )
	updateData(joystick,"joystickreleased",button)
end
function love.joystickaxis( joystick, axis, value )
	updateData(joystick,"joystickaxis","axes","trigger","angle")
end
function love.joystickremoved( joystick )
	updateData(joystick,"joystickremoved")
end
function love.joystickadded( joystick )
	updateData(joystick,"joystickadded")
end


function love.mousemoved(x,y)
	updateData(allInputObjects[Wasx.keyboardJoystickId],"mousemoved",x*Wasx.PositionScale.x,y*Wasx.PositionScale.y)
end
function love.mousepressed(x,y,b)
	updateData(allInputObjects[Wasx.keyboardJoystickId],"mousepressed",x*Wasx.PositionScale.x,y*Wasx.PositionScale.y,b)
end
function love.mousereleased(x,y,b)
	updateData(allInputObjects[Wasx.keyboardJoystickId],"mousereleased",x*Wasx.PositionScale.x,y*Wasx.PositionScale.y,b)
end
function love.keypressed(key)
	updateData(allInputObjects[Wasx.keyboardJoystickId],"keypressed",key)
end
function love.keyreleased(key)
	updateData(allInputObjects[Wasx.keyboardJoystickId],"keyreleased",key)
end

function love.textinput( text )
	updateData(allInputObjects[Wasx.keyboardJoystickId],"textinput",setmetatable({},
	{__call = function(t,self)
		table.insert(self.pastTextinputs, text)
		return text
	end,
	}),"textinput")
end

local buttonsKeysMT = {
	__eq = function(o1, o2) 
		for key,item in ipairs(o1) do
			if not o2[key] then
				return false
			elseif not o2[key] == item then
				return false
			end
		end
		for key,item in ipairs(o2) do
			if not o1[key] then
				return false
			elseif not o1[key] == item then
				return false
			end
		end
		return true
	end,
	__tostring = function(o)
		local st = ""
		for _,item in ipairs(o) do
			st = st..item
		end
		return st
	end,
}



local vec2mt = {
	__add = function(o1, o2)
		local new = {x = 0, y = 0}
		local length = math.sqrt((o1.x + o2.x)^2 + (o1.y + o2.y)^2)
		local scale = 1
		if length > 1 then
			scale = 1 / length
		end
		new.x = (o1.x + o2.x) * scale
		new.y = (o1.y + o2.y) * scale
		
		return new
	end,
}

local keyMapMT = {
	__tostring = function(t)
		local cart
		local autoref
		local string_format = string.format
		local table_insert = table.insert
		local function isemptytable(t) return next(t) == nil end
		local function basicSerialize (o)
			local so = tostring(o)
			if type(o) == "function" then
				local info = debug.getinfo(o, "S")
				-- info.name is nil because o is not a calling level
				if info.what == "C" then
					return string_format("%q", so .. ", C function")
				else
					-- the information is defined through lines
					return string_format("%q", so .. ", defined in (" ..
					info.linedefined .. "-" .. info.lastlinedefined ..
					")" .. info.source)
				end
			elseif type(o) == "number" or type(o) == "boolean" then
				return so
			else
				return string_format("%q", so)
			end
		end
		local function addtocart (value, name, indent, saved, field)
			indent = indent or ""
			saved = saved or {}
			field = field or name
			local item = indent .. field
			if type(value) ~= "table" then
				table_insert(cart, item .. " = " .. basicSerialize(value) .. ";")
			else
				if saved[value] then
					table_insert(cart, item .. " = {}; -- " .. saved[value] .. " (self reference)")
					table_insert(autoref, name .. " = " .. saved[value] .. ";")	
				else
					saved[value] = name
					if isemptytable(value) then
						table_insert(cart, item .. " = {};")
					else
						table_insert(cart, item .. " = {")
						for k, v in pairs(value) do
							k = basicSerialize(k)
							local fname = string_format("%s[%s]", name, k)
							field = string_format("[%s]", k)
							addtocart(v, fname, indent .. "\t", saved, field)
						end
						table_insert(cart, indent .. "};")
					end
				end
			end
		end
		name = "Mappings"
		if type(t) ~= "table" then
			return name .. " = " .. basicSerialize(t)
		end
		cart, autoref = {}, {}
		addtocart(t, name, indent)
		for _, line in ipairs(autoref) do
			table_insert(cart, line)
		end
		table_insert(cart, "")
		return table.concat(cart, "\n")
	end,
}

function Wasx.new(id)
	id = tonumber(id) or error("Bad argument #1. Expected number or number string, got: type: "..type(id).." | val: "..tostring(id))
	local self = {}
	
	self.data = setmetatable({},
		{__call = function(t,v,overrideValue,notypecheck)
			if not overrideValue then
				t[v]["Checked"] = true
				return t[v]["State"]
			else
				local function compareTypesAndReturnNewIfSameType(old,new)
					if type(old) == type(new) then
						return new else return old
					end
				end
				
				if type(overrideValue) == "table" then
					if overrideValue.type then return nil end
					for index,oldVal in pairs(t[v]["State"]) do
						if notypecheck then
							t[v]["State"][index] = overrideValue[index]
						else


							t[v]["State"][index] = compareTypesAndReturnNewIfSameType(oldVal,overrideValue[index])
						end
					end
				else
					if notypecheck then

						t[v]["State"] = overrideValue
					else

						t[v]["State"] = compareTypesAndReturnNewIfSameType(t[v]["State"],overrideValue)
					end
				end
				return t[v]["State"]
			end
		end})
	
	self.activeVibrations = {}
	self.pastTextinputs = {}
	self.keyMappings = {
		data = {textinput = {type = "textinput"}},
		buttons = {},
		angle = {left = {}, right = {}},
		analog = {trigger = {left = {}, right = {}}, stick = {left = {}, right = {}}},
	}
	
	setmetatable(self.keyMappings, keyMapMT)
	
	self.id = id
	
	self.useGamepad = false
	
	local joysticks = love.joystick.getJoysticks()
	self.joystick = joysticks[id] or false
	
	if self.joystick then
		allCapturedJoysticks[self.joystick] = true
	end
	
	for key,item in pairs(InputFunctions) do
		if not self[key] then
			self[key] = item
		end
	end
	
	self.__index = self
	
	setmetatable(self,{
		__call = function(o1, ...)
			if o1.data[...] then
				local theData = o1.data(...)
				if theData ~= nil then return theData
				else o1:index(...) end
			else
				return o1:index(...)
			end
		end,
	})
	allInputObjects[tostring(self.id)] = self
	return self
end

function InputFunctions:isConnected()
	if self.joystick then
		if self.joystick:isConnected( ) then
			return true
		else
			allCapturedJoysticks[self.joystick] = nil
			self.joystick = false
			return false
		end
	else
		local joysticks = love.joystick.getJoysticks()
		local joystickToCapture = self.id
		local start = false
		while allCapturedJoysticks[joysticks[joystickToCapture]] do
			joystickToCapture = (joystickToCapture%#joysticks)+1
			if start then if start == joystickToCapture then return false end end
			start = start or joystickToCapture
		end
		if joysticks[joystickToCapture] then
			self.joystick = joysticks[joystickToCapture]
			return true
		else
			return false
		end
	end
end

function InputFunctions:mapKey(buttonIndex,keys)
	if type(buttonIndex) ~= "string" then
		return error("Bad argument #1. Expected string, got: "..type(buttonIndex))
	end
	if type(keys) ~= "table" then
		return error("Bad argument #2. Expected table, got: "..type(keys))
	end
	if not keys[1] then
		return error("Bad argument #2. Must be a numbered table.")
	end
	for index,key in ipairs(keys) do
		if type(key) ~= "string" then
			return error("Bad argument #2. Must be a numbered table filled with only strings. Index: "..tostring(index).." Expected string, got: "..type(key))
		end
	end
	self.keyMappings["buttons"][buttonIndex] = keys
	
end

function InputFunctions:mapKeyAnalog(TorS,side,output,keys)
	if type(TorS) ~= "string" then
		return error("Bad argument #1. Expected string, got: "..type(TorS))
	end
	if TorS ~= "trigger" and TorS ~= "stick" then
		return error([[Bad argument #1. Expected "trigger" or "stick", got: "]]..TorS..[["]])
	end
	if type(side) ~= "string" then
		return error("Bad argument #2. Expected string, got: "..type(side))
	end
	if TorS == "stick" then
		if type(output) ~= "table" then
			return error("Bad argument #3. Expected table, got: "..type(output))
		end
		if not output["x"] or not output["x"] then
			return error([[Bad argument #3. Expected table with indexes "x" and "y".]])
		end
		if type(output["x"]) ~= "number" then
			return error([[Bad argument #3. Expected number for index "x", got: ]]..type(output["x"]))
		end
		if type(output["y"]) ~= "number" then
			return error([[Bad argument #3. Expected number for index "y", got: ]]..type(output["y"]))
		end
		setmetatable(output,vec2mt)
	end
	if TorS == "trigger" then
		if type(output) ~= "number" then
			return error("Bad argument #3. Expected number, got: "..type(output))
		end
	end
	if type(keys) ~= "table" then
		return error("Bad argument #4. Expected table, got: "..type(keys))
	end
	local pass = false
	for _,key in ipairs(keys) do
		pass = true
	end
	if not pass then
		return error("Bad argument #4. Must be a numbered table.")
	end
	for index,key in ipairs(keys) do
		if type(key) ~= "string" and type(key) ~= "number" then
			return error("Bad argument #4. Must be a numbered table filled with only strings and/or numbers. Index: "..tostring(index).." Expected string, got: "..type(key))
		end
	end
	setmetatable(keys,buttonsKeysMT)
	self.keyMappings["analog"][TorS][side][tostring(keys)] = {keys = keys,output = output}
end

function InputFunctions:save(path,name)
	local data = tostring(self.keyMappings)
	name = name or "default"
	if path then
		if type(path) ~= "string" then
			return error("Bad argument #1. Expected string or nil, got: "..type(path))
		end
		if not love.filesystem.getInfo(path, "directory") then
			if not love.filesystem.createDirectory(path) then
				return error([[Bad argument #1. Unable to create directory: "]]..path..[["]])
			end
		end
		love.filesystem.write(path.."/"..name, "local "..data.."return Mappings")
	else
		return data
	end
end

function InputFunctions:load(path,name)
	if type(path) ~= "string" then
		return error("Bad argument #1. Expected string, got: "..type(path))
	end
	if not love.filesystem.getInfo(path, "directory") then
		return error([[Bad argument #1. Could not find directory: "]]..path..[["]])
	end
	if type(name) ~= "string" then
		return error("Bad argument #2. Expected string, got: "..type(name))
	end
	if not love.filesystem.getInfo(path.."/"..name, "file") then
		return error([[Bad argument #2. Could not find file: "]]..path.."/"..name..[["]])
	end
	local dataChunk, err = love.filesystem.load(path.."/"..name)
	if err then
		return error(err)
	end
	self.keyMappings = dataChunk()
	setmetatable(self.keyMappings, keyMapMT)
	for lr,LR in pairs(self.keyMappings["analog"]["stick"]) do
		for i,index in pairs(LR) do
			setmetatable(index["output"], vec2mt)
		end
	end
	updateData(self)
end

function InputFunctions:isDown(buttonIndex,info)
	local isDown = false
	if self:isConnected() then
		isDown = self.joystick:isGamepadDown(unpack(info.buttons))
	end
	if self.keyMappings["buttons"][buttonIndex] then
		for _,key in ipairs(self.keyMappings["buttons"][buttonIndex]) do
			if type(key) == "string" then
				if love.keyboard.isDown(key) then
					return true
				end
			else
				if love.mouse.isDown(key) then
					return true
				end
			end
		end
	end
	return isDown
end

function InputFunctions:keyOverride(TorS,side)
	if self.keyMappings["analog"][TorS][side] then	
		local move = false
		for _,map in pairs(self.keyMappings["analog"][TorS][side]) do
			local keyDown = false
			for _,key in ipairs(map["keys"]) do
				if type(key) == "string" then
					if love.keyboard.isDown(key) then
						keyDown = true
					end
				else
					if love.mouse.isDown(key) then
						keyDown = true
					end
				end
			end
			if keyDown then
				if move then
					move = move+map["output"]
					break
				else
					move = map["output"]
				end
			end
		end
		return move
	else
		return false
	end
end

function InputFunctions:axes(info)
	local side = info.side
	if type(side) ~= "string" then
		return error("Bad argument #1. Expected string, got: "..type(side))
	end
	local deadzone = info.deadzone or 0.25
	if type(deadzone) ~= "number" then
		return error("Bad argument #2. Expected number, got: "..type(deadzone))
	end
	local keyOverride = self:keyOverride("stick",side)
	if keyOverride then
		return keyOverride
	end
	if self:isConnected() then
		local s = {
			x = self.joystick:getGamepadAxis(side.."x"),
			y = self.joystick:getGamepadAxis(side.."y")
		}
		local extent = math.sqrt(math.abs(s.x * s.x) + math.abs(s.y * s.y))
		local angle = math.atan2(s.y, s.x)
		if (extent < deadzone) then
			s.x, s.y = 0, 0
		else
			extent = math.min(1, (extent - deadzone) / (1 - deadzone))
			s.x, s.y = extent * math.cos(angle), extent * math.sin(angle)
		end
		return s
	else
		return {x = 0, y = 0}
	end
end

function InputFunctions:angle(info)
	local side = info.side
	if type(side) ~= "string" then
		return error("Bad argument #1. Expected string, got: "..type(side))
	end
	local deadzone = info.deadzone or 0.25
	if type(deadzone) ~= "number" then
		return error("Bad argument #2. Expected number, got: "..type(deadzone))
	end
	if not self:isConnected() then
		return false
	end
	local ax = self.joystick:getGamepadAxis(side.."x")
	local ay = self.joystick:getGamepadAxis(side.."y")
	local extent = math.sqrt(math.abs(ax * ax) + math.abs(ay * ay))
	local angle = math.atan2(ay, ax)
	if (extent < deadzone) then
		return false
	else
		return angle
	end
end

function InputFunctions:trigger(info)
	local side = info.side
	if type(side) ~= "string" then
		return error("Bad argument #1. Expected string, got: "..type(side))
	end
	local keyOverride = self:keyOverride("trigger",side)
	if keyOverride then
		return keyOverride
	end
	if self:isConnected() then
		local deadzone = info.deadzone or 0.0
		local extent = math.max(self.joystick:getGamepadAxis("trigger"..side),deadzone)-deadzone
		return (extent) / (1 - deadzone)
	else
		return 0
	end
end

function InputFunctions:button(info)
	local buttons = info.buttons
	for index,key in ipairs(buttons) do
		if type(key) ~= "string" then
			return error("Bad argument #"..tostring(index)..". Expected string, got: "..type(key))
		end
	end
	setmetatable(buttons,buttonsKeysMT)
	local buttonIndex = tostring(buttons)
	local isDown = self:isDown(buttonIndex,info)
	return isDown
end

function InputFunctions:buttonOnce(info)
	if self.data(info.index) ~= nil then
		return true else return false end
end

function InputFunctions:buttonToggle(info)
	local currentData = self.data(info.index)
	if currentData ~= nil then
		return not currentData
	else return false end
end

function InputFunctions:textinput(dontPop)
	if dontPop then
		return self.pastTextinputs[1]
	else
		table.remove(self.pastTextinputs,1)
	end
end

function InputFunctions:AABB(interactionType,x1,y1,x2,y2)
	local positionIndex = interactionType.."Position"
	local workingPos = self[positionIndex]
	if workingPos then
		workingPos.Checked = true
		local noCollision = true
		if workingPos.x < x1 or workingPos.x > x2 or workingPos.y < y1 or workingPos.y > y1 then
			noCollision = false
		end
		self[positionIndex] = nil
		return not noCollision
	else
		return false
	end
end


function InputFunctions:vibrate(left,right,tag)
	if type(left) == "string" then
		self.activeVibrations[left] = nil
		return
	elseif not left then
		self.activeVibrations = {}
		return
	end
	left = left or {0,0,0}
	right = right or {0,0,0}
	local v = {}
	v.left = {}
	for i,n in ipairs(left) do
		v.left[i] = n
	end
	v.left[4] = v.left[3]
	v.right = {}
	for i,n in ipairs(right) do
		v.right[i] = n
	end
	v.right[4] = v.right[3]
	self.activeVibrations[tag or #self.activeVibrations+1] = v
end

local indexInputs = {
	"button",
	"buttonOnce",
	"buttonToggle",
	"trigger",
	"angle",
	"axes",
}

local indexMT = {
	__index = function(t,i)
		for _,item in ipairs(t) do
			if item == i then
				return true
			end
		end
		return false
	end,
	__tostring = function(o)
		local st = ""
		for i,item in ipairs(o) do
			local spacer = [[]]
			if i == #o then
				spacer = [[ or ]]
			elseif i > 1 then
				spacer = [[, ]]
			end
			st = st..spacer..[["]]..item..[["]]
		end
		return st
	end,
}

setmetatable(indexInputs,indexMT)

function InputFunctions:index(var,info)
	if type(info) ~= "table" then
		return error("Bad argument #2. Expected table, got: "..type(info))
	elseif type(info.type) ~= "string" then
		return error([[Bad argument #2, index["type"]. Expected string, got: ]]..type(info.type))
	end
	if not indexInputs[info.type] then
		return error([[Bad argument #2, index["type"]. Expected string (]]..tostring(indexInputs)..[[) got: "]]..info.type..[["]])
	end
	info.index = var
	if info.buttons then
		info.buttonGroupings = {}
		while type(info.buttons[#info.buttons]) == "number" do
			local endOfGrouping = table.remove(info.buttons)
			if endOfGrouping < 1 then endOfGrouping = 1 end
			local startOfGrouping = table.remove(info.buttons)
			if type(startOfGrouping) ~= "number" then
				table.insert(info.buttons,startOfGrouping)
			elseif startOfGrouping > endOfGrouping then
				startOfGrouping = endOfGrouping
			elseif startOfGrouping < 1 then
				startOfGrouping = 1
			end
			table.insert(info.buttonGroupings, startOfGrouping)
			table.insert(info.buttonGroupings, endOfGrouping)
		end
		setmetatable(info.buttons, buttonsKeysMT)
		info.buttonIndex = tostring(info.buttons)
	end
	if not self.keyMappings.data[var] or info.replace then
		self.keyMappings.data[var] = info
		
	else
		self.keyMappings.data[var]["subindex"] = self.keyMappings.data[var]["subindex"] or {}
		table.insert(self.keyMappings.data[var]["subindex"],info)
	end
	updateData(self)
	if info.keys and info.buttons then
		return self:mapKey(info.buttonIndex, info.keys)
	elseif info.keys and info.output then
		if info.type == "trigger" then
			if not info.side then
				return error([[When useing type = "trigger" you must include side = "left or "right".]])
			elseif type(info.side) ~= "string" then
				return error([[Bad argument #2, index["side"]. Expected string, got: ]]..type(info.side))
			elseif info.side ~= "left" and info.side ~= "right" then
				return error([[Bad argument #2 index["side"]. Expected string "right" or "left", got: "]]..info.side..[["]])
			end
			return self:mapKeyAnalog("trigger", info.side, info.output, info.keys)
		elseif info.type == "axes" then
			if not info.side then
				return error([[When useing type = "axes" you must include side = "left or "right".]])
			elseif type(info.side) ~= "string" then
				return error([[Bad argument #2, index["side"]. Expected string, got: ]]..type(info.side))
			elseif info.side ~= "left" and info.side ~= "right" then
				return error([[Bad argument #2, index["side"]. Expected string "right" or "left", got: "]]..info.side..[["]])
			end
			return self:mapKeyAnalog("stick", info.side, info.output, info.keys)
		end
	elseif info.keys then
		return self:mapKey(var, info.keys)
	elseif info.type == "angle" then
		if not info.side then
			return error([[When useing type = "angle" you must include side = "left or "right".]])
		elseif type(info.side) ~= "string" then
			return error([[Bad argument #2, index["side"]. Expected string, got: ]]..type(info.side))
		elseif info.side ~= "left" and info.side ~= "right" then
			return error([[Bad argument #2, index["side"]. Expected string "right" or "left", got: "]]..info.side..[["]])
		end
		self.keyMappings.angle[info.side][var] = true
	elseif info.type == "axes" then
		if not info.side then
			return error([[When useing type = "axes" you must include side = "left or "right".]])
		elseif type(info.side) ~= "string" then
			return error([[Bad argument #2, index["side"]. Expected string, got: ]]..type(info.side))
		elseif info.side ~= "left" and info.side ~= "right" then
			return error([[Bad argument #2, index["side"]. Expected string "right" or "left", got: "]]..info.side..[["]])
		end
	else
		return error([[NO MAPPINGS!!! See Wasx.help("index")]])
	end
end
local inputPositionIndexList = {"mousepressedPosition"}
function Wasx.update(dt)
	dt = dt or 0.016
	local function updateActiveVibrations(self)
		if self.joystick and self.joystick:isVibrationSupported( ) then
			local vibrateLeft = 0
			local vibrateRight = 0
			for i,v in pairs(self.activeVibrations) do
				local function updateAndGetValuFromSide(side)
					if v[side][3] > 0 then
						local x = v[side][4]-v[side][3]
						local m = (v[side][1]-v[side][2])/(0-v[side][4])
						
						v[side][3] = v[side][3]-dt
						return (m*x+v[side][1])
					else return 0
					end
				end
				vibrateLeft = vibrateLeft+updateAndGetValuFromSide("left")
				vibrateRight = vibrateRight+updateAndGetValuFromSide("right")
				if v.left[3] <= 0 and v.right[3] <= 0 then
					table.remove(self.activeVibrations,i)
				end
			end
			local maxStrength = 0.5 -- This should be 1 but I think LOVE has a bug ¯\_(ツ)_/¯
			self.joystick:setVibration( math.min(maxStrength,vibrateLeft*maxStrength), math.min(maxStrength,vibrateRight*maxStrength) )
		end
	end
	local function setButtonOnceDataToFalseIfChecked(self)
		for index,data in pairs(self.data) do
			local info = self.keyMappings.data[index]
			if info.type == "buttonOnce" and data["Checked"] then
				data.State = false
			end
		end
	end
	
	for id,joy in pairs(allInputObjects) do
		updateActiveVibrations(joy)
		setButtonOnceDataToFalseIfChecked(joy)
	end
	
	for _,positionIndex in ipairs(inputPositionIndexList) do
		local workingPos = Wasx[positionIndex]
		if workingPos and workingPos.Checked then
			Wasx[positionIndex] = nil
		end
	end
	
end

return Wasx
