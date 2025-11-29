local fs = require("@lune/fs")
local process = require("@lune/process")
local frktest = require("@pkg/frktest")
local Table = require("../lib/table")

function load_tests()
    Table.ForEach(fs.readDir("./test"), function(i: number, v: string)  
        if v == "_run.luau" then return end

        local path = `@test/{string.split(v, ".")[1]}`
        (require :: any)(path)()
    end)
end

function run_tests()
    frktest.reporters.console_reporter.init()
    return frktest.run()
end

load_tests()
run_tests()