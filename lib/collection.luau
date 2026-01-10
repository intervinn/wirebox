local Table = require("./table")

export type ServiceEntry = {
    lifetime: "transient" | "singleton",
    constructor: (...any) -> any,
    dependencies: {ServiceEntry},
    name: string?,
    meta: {}
}

export type Constructor = (...any) -> any

export type PartialEntry = {
    lifetime: "transient" | "singleton",
    constructor: Constructor,
    dependencies: {PartialDependency},
    name: string?,
    meta: {}
}

export type PartialDependency = {
    constructor: Constructor,
    name: string?
}

export type CollectionOptions = {
    debugMessages: boolean,
    requireServiceNames: boolean,
    panicOnCyclicDependencies: boolean
}

local Collection = {}
Collection.__index = Collection

export type Collection = typeof(setmetatable({}, Collection))

function Collection.new()
    return setmetatable({
        Entries = {},
        Partials = {},
        Options = {
            debugMessages = true,
            requireServiceNames = false,
            panicOnCyclicDependencies = true,
        }
    }, Collection)
end

--[[
    The entries added to collections are partial,
    as their dependencies haven't been resolved yet
]]
function Collection:AddEntry(entry: PartialEntry)
    table.insert(self.Partials, entry)
end

--[[
    Start with resolving all partials' dependencies, create a proper table of entries.
    Then check for any cyclic dependencies, finally construct entries by making sure their dependencies
    are already constructed.
]]

--[[
    Check if a service entry is present in collection
]]
function Collection:IsEntryPresent(identifier: string | Constructor): boolean
    if type(identifier) == "string" then
        return Table.First(self.Entries, function(v: ServiceEntry) return v.name == identifier end) ~= nil
    elseif type(identifier) == "function" then
        return Table.First(self.Entries, function(v: ServiceEntry) return v.constructor == identifier end) ~= nil
    end
    return false
end

--[[
    Check if a partial entry is present in collection
]]
function Collection:IsPartialPresent(identifier: string | Constructor) : boolean
    if type(identifier) == "string" then
        return Table.First(self.Partials, function(v: ServiceEntry) return v.name == identifier end) ~= nil
    elseif type(identifier) == "function" then
        return Table.First(self.Partials, function(v: ServiceEntry) return v.constructor == identifier end) ~= nil
    end
    return false
end

--[[
    Resolves partial entries, provided to collection at pre-build stage
    Resolves dependencies and adds them as complete entries
    Checks for possible cyclic dependencies (TODO)
]]
function Collection:ResolveEntry(entry: PartialEntry): ServiceEntry?
    local exist = Table.First(self.Entries, function(v) return v.constructor == entry.constructor end)
    if exist then return exist end

    local dependencies: {ServiceEntry} = {}

    if entry.dependencies then
        dependencies = Table.Map(entry.dependencies, function(v)
            return self:ResolveEntry(v) :: any
        end) 
    end

    local result: ServiceEntry = {
        lifetime = entry.lifetime,
        constructor = entry.constructor,
        dependencies = dependencies :: {ServiceEntry},
        name = entry.name,
        meta = entry.meta
    }

    table.insert(self.Entries, result)

    return result
end

function Collection:ResolveEntries()
    Table.ForEach(self.Partials, function(_, v) 
        self:ResolveEntry(v)
    end)
end

function Collection:GetServices()
    return self.Entries
end

return Collection :: Collection