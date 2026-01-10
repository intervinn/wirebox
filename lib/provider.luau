local Table = require("./table")
local Collection = require("./collection")

local Provider = {}
Provider.__index = Provider

type Constructor = (...any) -> any

export type Service = {
    name: string,
    lifetime: "transient" | "singleton",
    constructor: Constructor, -- original constructor
    factory: () -> any, -- provider-specific factory
    instance: any?, -- if singleton
    meta: {}
}

export type Provider = typeof(setmetatable({} :: {
    Services: {Service}
}, Provider))

function Provider.new()
    return setmetatable({
        Services = {}
    }, Provider)
end

function buildService(self: Provider, collection: Collection.Collection, service: Collection.ServiceEntry): Service
    local exists = Table.First(self.Services, function(v) return v.constructor == service.constructor end)
    if exists then
        return exists
    end

    local deps = Table.Map(service.dependencies, function(v)
        return buildService(self, collection, v).factory()
    end)

    local result: Service = {
        name = service.name or "<unnamed>",
        lifetime = service.lifetime,
        meta = service.meta,
        constructor = service.constructor,
        factory = function()
            return service.constructor(table.unpack(deps))
        end,
    }

    if result.lifetime == "singleton" then
        result.instance = result.factory()
        result.factory = function()
            return result.instance
        end
    end

    self:AddService(result)

    return result
end

function Provider.FromCollection(collection: Collection.Collection)
    local self = Provider.new()

    collection:AddEntry({
        name = "<_wirebox.provider>",
        constructor = function() return self end,
        lifetime = "singleton"
    })

    collection:ResolveEntries()
    for _, service: Collection.ServiceEntry in collection:GetServices() do
        buildService(self, collection, service)
    end

    return self
end

function Provider:GetService(key: string | Constructor): Service
    if type(key) == "string" then
        return (Table.First(self.Services, function(v) return v.name == key end) :: Service).factory()
    elseif type(key) == "function" then
        return (Table.First(self.Services, function(v) return v.constructor == key end) :: Service).factory()
    else
        error(`Unknown GetService key: {key}`)
    end
end

function Provider:AddService(service: Service)
    if Table.First(self.Services :: {Service}, function(v) return v.constructor == service.constructor end) then
        return
    end

    table.insert(self.Services, service)
end

-- Since Luau is diverse on naming conventions, create methods in other cases
Provider.add_service = Provider.AddService
Provider.addService = Provider.AddService
Provider.from_collection = Provider.FromCollection
Provider.fromCollection = Provider.FromCollection

return Provider
