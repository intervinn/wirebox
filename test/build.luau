local frktest = require("@pkg/frktest")

local check = frktest.assert.check
local req = frktest.assert.require
local test = frktest.test

return function() 
    test.case("hello equals hello", function() 
        check.is_true("hello" == "hello")

        return nil
    end)
end