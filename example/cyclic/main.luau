local wirebox = require("../../lib")

local collection = wirebox.Collection.new()
local inject = wirebox.createInjector(collection)

----------------------- logger
local Logger = {}
Logger.__index = Logger

function Logger.new(store)
    print("BUILDING LOGGER", store)
    return setmetatable({
        store = store
    }, Logger)
end

function Logger:log(message)
    print(message)
end

----------------------- store
local Store = {}
Store.__index = Store

function Store.new(logger)
    print("BUILDING STORE", logger)
    return setmetatable({
        logger = logger,
        store = {}
    }, Store)
end

function Store:Put(key, value)
    self.logger:log(`putting {key}-{value}`)
    self.store[key] = value
end

function Store:Get(key, value)
    self.logger:log(`getting {key}-{value}`)
    return self.store[key]
end

inject(Store.new)
    :with(Logger.new)
    :asSingleton()
    :name("Store")

inject(Logger.new)
    :asSingleton()
    :with(Store.new)
    :name("Logger")

local provider = collection:BuildProvider()
