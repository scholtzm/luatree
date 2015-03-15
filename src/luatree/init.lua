---------------------------------------------
-- luatree
-- simple toolkit for luametrics and luadb
-- @author: Michael Scholtz
---------------------------------------------

-- Return a single table which contains all the luatree submodules
return {
    ast = require("luatree.ast"),
    graph = require("luatree.graph"),
    bridge = require("luatree.bridge"),
    utils = require("luatree.utils")
}
