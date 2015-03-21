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
-- into luametrics hypergraph.
-- REMARK: !!! This function only works with luametrics which
-- includes Hypergraph captures !!!
-- NOTE: You can also use luatree to retrieve data_ast
-- and data_graph
-- @param data_ast AST tree provided by luametrics
-- @param data_graph Function call graph provided by luadb
local function merge_graph_into_AST(data_ast, data_graph)
    assert(data_ast.hypergraph ~= nil, "param data_ast does not containt 'hypergraph' data")

    local hypergraph = data_ast.hypergraph

    for _, edge in ipairs(data_graph.edges) do
        local from_position = edge.from[1].data.position
        local call_position = edge.data.position
        local to_position = nil

        -- "To" might be empty for global functions defined elsewhere
        if edge.to ~= nil and #edge.to > 0 then
            to_position = edge.to[1].data.position
        end

        -- These will be actual hypergraph nodes
        local from = nil
        local to = nil
        local actual_call = nil

        for node in pairs(hypergraph.Nodes) do
            if node.label == "LocalFunction" or node.label == "GlobalFunction"  then
                if node.data.position == from_position then
                    from = node
                elseif node.data.position == to_position then
                    to = node
                end
            elseif node.label == "FunctionCall" then
                if node.data.position == call_position then
                    actual_call = node
                end
            end

            -- Break if we have all the info necessary
            if from ~= nil and (to ~= nil or to_position == nil) and actual_call ~= nil then
                break
            end
        end

        -- Add new incidence data to edges and nodes
        local new_edge = HG.E'call'

        hypergraph:AddEdgesFromNodeData(from, { [HG.I'caller'] = new_edge })
        hypergraph:AddNodesFromEdgeData(new_edge, { [HG.I'caller'] = from })

        hypergraph:AddEdgesFromNodeData(actual_call, { [HG.I'callpoint'] = new_edge })
        hypergraph:AddNodesFromEdgeData(new_edge, { [HG.I'callpoint'] = actual_call })

        if to ~= nil then
            hypergraph:AddEdgesFromNodeData(to, { [HG.I'callee'] = new_edge })
            hypergraph:AddNodesFromEdgeData(new_edge, { [HG.I'callee'] = to })
        end
    end
end

--- Similar to merge_graph_into_AST
-- This function merges important data from luadb graph
-- into luametrics hypergraph - as metadata.
-- @param data_ast AST tree provided by luametrics
-- @param data_graph Function call graph provided by luadb
local function merge_graph_into_AST_meta(data_ast, data_graph)
    assert(data_ast.hypergraph ~= nil, "param data_ast does not contain 'hypergraph' data")

    local hypergraph = data_ast.hypergraph

    for node in pairs(hypergraph.Nodes) do
        for incidence, edge in pairs(hypergraph[node]) do
            if incidence.label == "definer" and edge.label == "defines" then
                for incidence, node in pairs(hypergraph[edge]) do
                    if incidence.label == "function" then
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
    merge_graph_into_AST_meta = merge_graph_into_AST_meta,
    merge_graph_into_AST_soft = merge_graph_into_AST_soft
}
