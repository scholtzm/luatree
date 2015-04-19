---------------------------------------------
-- luatree ast
-- simple toolkit for luametrics
-- @author: Michael Scholtz
---------------------------------------------

-- Return a single table which contains all the luatree.ast submodules
return {
    tree = require("luatree.ast.tree"),
    hypergraph = require("luatree.ast.hypergraph")
}
