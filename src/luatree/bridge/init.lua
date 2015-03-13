---------------------------------------------
-- bridge module
-- Tiny module to bridge data structures provided
-- by luametrics and luadb
-- @author: Michael Scholtz
---------------------------------------------

local ast = require("luatree.ast")
local graph = require("luatree.graph")
local utils = require("luatree.utils")

---------------------------------------------
-- Constants & Private methods
---------------------------------------------

---------------------------------------------
-- Public methods
---------------------------------------------

--- Merging luadb graph into luametrics hypergraph.
-- This function merges important data from luadb graph
-- into luametrics hypergraph
-- REMARK: !!! This function only works with luametrics which
-- includes Hypergraph captures !!!
-- NOTE: You can also use luatree to retrieve data_ast
-- and data_graph
-- @param data_ast AST tree provided by luametrics
-- @param data_graph Function call graph provided by luadb
local function merge_graph_into_AST(data_ast, data_graph)
	assert(data_ast.hypergraph ~= nil, "data_ast does not contain 'hypergraph' data")
	return data_ast
end

---------------------------------------------
-- Module definition
---------------------------------------------

return {
    merge_graph_into_AST = merge_graph_into_AST,
}
