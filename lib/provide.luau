local Builder = require("./builder")
local Collection = require("./collection")

return function(collection: Collection.Collection)
    return function(constructor: Collection.Constructor)
        local builder = Builder.new(constructor);
        (builder :: any):Collection(collection)
        return builder
    end
end