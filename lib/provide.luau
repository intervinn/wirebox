local Builder = require("./builder")
local Collection = require("./collection")
local Table = require("./table")

--[[
    Accepts `override` table to extend the builder, refer to the source code for more info
]]
return function(collection: Collection.Collection, overrides: any?)
    return function(constructor: Collection.Constructor)
        local builder = Builder.new(constructor)
        Table.Assign(builder, overrides);
        (builder :: any):Collection(collection)
        return builder
    end
end
