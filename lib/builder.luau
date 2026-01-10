local Table = require("./table")
local Collection = require("./collection")

local Builder = {}
Builder.__index = Builder

export type Builder = typeof(setmetatable({} :: {
    Result: Collection.PartialEntry
}, Builder))

function Builder.new(constructor: Collection.Constructor)
    return setmetatable({
        Result = {
            name = "<unnamed>",
            dependencies = {},
            constructor = constructor
        }
    }, Builder)
end

function Builder:Transient(): Builder
    self.Result.lifetime = "transient"
    return self
end

function Builder:Singleton(): Builder
    self.Result.lifetime = "singleton"
    return self
end

function Builder:With(dependency: Collection.Constructor): Builder
    local entry = {
        constructor = dependency
    }
    table.insert(self.Result.dependencies, entry)
    return self
end

function Builder:Collection(collection: Collection.Collection): Builder
    (collection :: any):AddEntry(self.Result :: Collection.PartialEntry)
    return self
end

function Builder:Name(name: string) : Builder
    self.Result.name = name
    return self
end

function Builder:WithProvider()
    table.insert(self.Result.dependencies, {
        name = "<_wirebox.provider>"
    })
    return self
end

return Builder
