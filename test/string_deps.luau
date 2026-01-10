local lib = require("../lib")

local c = lib.Collection.new()
local provide = lib.provide(c)

local Logger = {}
Logger.__index = Logger
Logger.new = function(store) print("store", store); return setmetatable({}, Logger) end
Logger.log = function(self, msg) print(msg) end

local Store = {}
Store.__index = Store
Store.new = function(logger) print("logger", logger); return setmetatable({Data = {}, Logger = logger}, Store) end
Store.put = function(self, key, value) self.Logger:log("set"); self.Data[key] = value end
Store.get = function(self, key) self.Logger:log("get"); return self.Data[key] end

provide(Store.new):Name("Store"):With("Logger"):Singleton()
provide(Logger.new):Name("Logger"):Transient()

local p = lib.Provider.FromCollection(c)
local store = p:GetService("Store")
store:put("key", "value")