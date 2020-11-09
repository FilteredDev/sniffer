--env proxy

local _ENV = getfenv()
local actual_print = print

local real_tables = {}
local sniffer = {}
local f_over = {}
locsal mutes = {}

local function v(t)
	for i, v in ipairs(t) do
		local typ = type(v)
		if typ == "function" then
			t[i] = sniffer.functionproxy(v)
		elseif typ == "table" or typ == "userdata" then
			t[i] = sniffer.tableproxy(v) --changed this to correctly wrap proxies to match their specified type, this may overcome the table.insert problem
		end
	end
end

local function output(SnifferCallType, tab, fName, ...)
	if mutes[fName] then return end
	actual_print(SnifferCallType, tab, fName, ...)
end

function sniffer.functionproxy(func, tab, actualName) --if we have the actual name of the function, we use that, otherwise the function name will just be 'Function'
	--returns a callable function that is proxied, how this works on objects will remain a mystery
	return function(...)
		local args = {...}

		--quickly go through the args to convert them to their real counterparts, this wont break the sandbox since the conversion is local
		for i, v in ipairs(args) do
			local r = real_tables[v]
			if r then --we found a proxied object, quickly convert it to what it should be
				args[i] = r
			end
		end

		local fOutput = func
		if actualName then
			fOutput = "function: " .. actualName
		end

		output("[Sniffer call]:", tab, fOutput, ...)
		local toVer
		if f_over[fOutput] then
			toVer = table.pack(f_over[fOutput](table.unpack(args)))
		else
			toVer = table.pack(func(table.unpack(args)))
		end
		--this is a shallow verify, someone will probs make this work with a deep table but until then:
		v(toVer)
		return table.unpack(toVer)
	end
end

--finaliser
function sniffer.tableproxy(tab)
	if real_tables[tab] then
		tab = real_tables[tab]
	end
	local o
	if type(tab) == "userdata" then
		o = newproxy(true) --we now want O to operate as a userdata here, probably doesn't matter but is useful when creating wrappers
	else
		o = setmetatable({}, {})
	end
	
	local o_mt = getmetatable(o)
	o_mt.__index = function(self, k)
		local index = tab[k]
		local typ = type(index) --type, not typeof since handling roblox instances can be a right pain otherwise
		if typ == "function" then
			--create function wrapper, this is because we need to check the returns of the function to make sure no tables, functions or userdatas slip past
			return sniffer.functionproxy(index, self, k)
		else
			output("[Sniffer index]:", self, k)
			if typ == "table" or typ == "userdata" then
				--userdatas and tables are quite similar, so we'll use the same proxy for them
				return sniffer.tableproxy(index)
			else
				--just return the object since we cant proxy them
				return index
			end
		end
	end

	o_mt.__newindex = function(self, k, v) --new declarations
		output("[Sniffer newindex]:", self, k, v)
		tab[k] = v
	end

	o_mt.__metatable = "The metatable is locked",
	o_mt.__tostring = function()
		if tab == _ENV then
			return "_ENV" --i think returning _ENV instead of some random hex code is better ux, this is the only place where this'll happen
		else
			return tostring(tab)
		end
	end

	real_tables[o] = tab
	return o
end

sniffer._ENV = sniffer.tableproxy(_ENV)

function sniffer.setFunctionOverride(name, f)
	f_over[name] = f
end

function sniffer.mute(name)
	mutes[name] = true
end

return function(fenvOverrides) --for fenv overriding, will not be immune from proxying however
	--handle fenv overrides
	for k, v in pairs(fenvOverrides) do
		_ENV[k] = v
	end

	return sniffer
end
