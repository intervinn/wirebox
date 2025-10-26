local Provider = require("./provider")
local Table = require("./table")

export type ServiceEntry = {
    lifetime: "transient" | "singleton",
    constructor: (...any) -> any,
    dependencies: {ServiceEntry},
    name: string?
}

export type PartialEntry = {
    lifetime: "transient" | "singleton",
    constructor: (...any) -> any,
    dependencies: {{
        lifetime: "transient" | "singleton",
        constructor: (...any) -> any
    }},
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
    The entries that are added are partial, as they contain a list of dependencies with just a lifetime and constructor
    We have to add the dependencies as another entries, and reensure that no copies are made
]]
function Collection:AddEntry(entry)
    table.insert(self.Partials, entry)
end

function Collection:GetEntry(constructor)
    for _,v in self.Entries do
        if v.constructor == constructor then
            return v
        end
    end
    return nil
end

local function debugPrint(collection: Collection, message: any)
    if collection.Options.debugMessages then
        print(message)
    end
end

local function checkCyclicDependencies(entry: PartialEntry, collection: Collection)

    local left = entry
    local right = Table.First(collection.Partials, function(partial)
        return Table.First(partial.dependencies, function(dependency)
            return dependency.constructor == left.constructor
        end) ~= nil
    end)

    if right and Table.First(left.dependencies, function(v) return v.constructor == right.constructor  end) then
        debugPrint(collection, "wirebox: assign names to services for better debugging")
        if collection.Options.panicOnCyclicDependencies then
            error(`wirebox: cyclic dependencies: {left.name or left.constructor} <-> {right.name or right.constructor}`)
        else
            debugPrint(collection, `wirebox: cyclic dependencies: {left.name or left.constructor} <-> {right.name or right.constructor}`)
        end
    end
end

--[[
    receive partial entires (lifetime, constructor, dependencies with just constructors)
    resolve dependencies as full entries without copies
]]
local function resolveEntry(entry: PartialEntry, collection: Collection): ServiceEntry
    local exists = collection:GetEntry(entry.constructor)
    if exists then return exists end

    local serviceEntry = {
        constructor = entry.constructor,
        lifetime = entry.lifetime,
        dependencies = {},
        name = entry.name
    }

    if entry.dependencies then
        for _, d in entry.dependencies do
            table.insert(serviceEntry.dependencies, resolveEntry(d, collection))
        end
    end

    table.insert(collection.Entries, serviceEntry)

    return serviceEntry
end

--[[
    build services aswell as their dependencies
]]
local function buildService(entry: ServiceEntry, provider: Provider.Provider, collection: Collection): Provider.Service
    local exists = provider:GetEntry(entry.constructor)
    if exists then
        debugPrint(collection, `wirebox: built service already exists ({entry.name}):`)
        debugPrint(collection, exists)
        return exists
    end

    debugPrint(collection, `wirebox: building service ({entry.name})`)

    local dependencies = {}
    for _, dependency in entry.dependencies do
        local service = buildService(dependency, provider, collection)
        table.insert(dependencies, service)
    end

    local service: Provider.Service = {
        constructor = entry.constructor,
        lifetime = entry.lifetime,
        factory = function()
            local args = {}
            for _, d in dependencies do
                table.insert(args, d.factory())
            end

            return entry.constructor(table.unpack(args))
        end,
        name = entry.name
    }

    if service.lifetime == "singleton" then
        service.instance = service.factory()
        service.factory = function() return service.instance end
    end
    debugPrint(collection, "wirebox: inserting service:")
    debugPrint(collection, service :: any)
    table.insert(provider.Services, service)

    return service
end

function Collection:BuildProvider(): Provider.Provider
    debugPrint(self, "wirebox: checking cyclic dependencies...")
    for _, v in self.Partials do
        debugPrint(self, v)
        checkCyclicDependencies(v, self)
    end

    debugPrint(self, "wirebox: resolving partials...")
    for _, v in self.Partials do
        resolveEntry(v, self)
    end

    local provider = Provider.new()
    debugPrint(self, `wirebox: building {#self.Entries} services...`)
    for _, entry in self.Entries do
        buildService(entry, provider, self)
    end

    return provider
end

function Collection:Configure(callback)
    callback(self.Options)
end

return Collection
