local Table = require("./table")

local builder = {
    entry = {
        dependencies = {},
        name = "",
        constructor = nil,
        lifetime = ""
    },

    with = function(self, constructor: (...any) -> any): Builder
        table.insert(self.entry.dependencies, {
            constructor = constructor,
        })
        return self
    end,

    withSingleton = function(self, constructor: (...any) -> any): Builder
        table.insert(self.entry.dependencies, {
            constructor = constructor,
            lifetime = "singleton"
        })
        return self
    end,

    withTransient = function(self, constructor: (...any) -> any): Builder
        table.insert(self.entry.dependencies, {
            constructor = constructor,
            lifetime = "transient"
        })
        return self
    end,

    asSingleton = function(self): Builder
        self.entry.lifetime = "singleton"
        return self
    end,

    asTransient = function(self): Builder
        self.entry.lifetime = "transient"
        return self
    end,

    name = function(self, name: string): Builder
        self.entry.name = name
        return self
    end
}

export type Builder = typeof(builder)

function createInjector(collection): ((...any) -> any) -> Builder
    return function(constructor)
        local b = Table.DeepCopy(builder)
        b.entry.constructor = constructor

        collection:AddEntry(b.entry)
        return b
    end
end

-- FIXME: types aren't working and the code breaks
function createInjectorExtendBuilder<T>(collection, builderExtender: T): ((...any) -> any) -> Builder & T
    return function(constructor)
        local b = Table.DeepCopy(builder)
        Table.Assign(Table.DeepCopy(builderExtender), b)

        collection:AddEntry(b.entry)
        return b
    end
end

return {
    createInjector = createInjector,
    createInjectorExtendBuilder = createInjectorExtendBuilder
}
