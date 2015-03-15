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
    assert(data_ast.hypergraph ~= nil, "param data_ast does not contain 'hypergraph' data")

    local hypergraph = data_ast.hypergraph

    for node in pairs(hypergraph.Nodes) do
        for incidence, edge in pairs(hypergraph[node]) do
            if incidence.label == 'definer' and edge.label == 'defines' then
                for incidence, node in pairs(hypergraph[edge]) do
                    if incidence.label == 'function' then
                        local edges = graph.get_edges_by_position(data_graph, node.data.position)
                        if #edges > 0 then
                            node.luadbinfo = edges
                        end
                    end
                end
            end
        end
    end
end

--- Soft merging luadb graph into luametrics output.
-- @param data_ast AST tree provided by luametrics
-- @param data_graph Function call graph provided by luadb
local function merge_graph_into_AST_soft(data_ast, data_graph)
	data_ast.luadbgraph = data_graph
end

---------------------------------------------
-- Module definition
---------------------------------------------

return {
    merge_graph_into_AST = merge_graph_into_AST,
    merge_graph_into_AST_soft = merge_graph_into_AST_soft
}
