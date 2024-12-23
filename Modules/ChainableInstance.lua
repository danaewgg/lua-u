--[[
	ChainableInstance | r2-202410061215
	
	I didn't like having to localize instances for property
	changes when using Instance.new(), so I made this.
	It allows you to chain changes of properties onto
	the end of constructor calls (also called method cascading).
	
	Usage:
		• ChainableInstance.new(className : string, parent : Instance?)
			.Name(value : string)
			...
			.Parent(value : Instance) -- It's important for .Parent to be the last call, because the module returns the instance there
		• ChainableInstance.fromExisting(existingInstance : Instance)
			...
	----------------------------------------------------------------------------------------------------
	
	Authored by: Danaew
	Inspired by: https://devforum.roblox.com/t/30296/13
]]

local metatable = {
	__index = function(self, property)
		-- I didn't want to create a new function, but it's inevitable since I need the passed value
		-- On a second note, this is a really interesting way of doing it
		return function(value)
			assert(property ~= "Parent" or typeof(value) == "Instance", "Parent must be an instance")

			--print(`Setting .{property} of {instance} to '{value}'`)
			self.instance[property] = value

			return property == "Parent" and self.instance or self
		end
    end
}

local CachedInstanceDotNew = Instance.new

local ChainableInstance = {}

function ChainableInstance.new(className, parent)
	assert(typeof(className) == "string", "1st argument (className) must be a string")
	assert(typeof(parent) == "Instance", "2nd argument (parent) must be an instance")

	local instance = CachedInstanceDotNew(className, parent)

	return setmetatable({instance = instance}, metatable)
end

function ChainableInstance.fromExisting(existingInstance)
	assert(typeof(existingInstance) == "Instance", "1st argument (existingInstance) must be an instance")

	local instance = existingInstance:Clone()
	
	task.defer(function()
		for _, child in instance:GetChildren() do
			child:Destroy()
		end
	end)

	return setmetatable({instance = instance}, metatable)
end

return ChainableInstance
