---------------------------------------------
-- Hyprgraph module
-- Hypergraph toolkit for Lua
-- @author: Michael Scholtz
---------------------------------------------

local utils = require("luatree.utils")

---------------------------------------------
-- Constants & Private methods
---------------------------------------------

--- Get group parent
-- This function will find the parent of a group.
-- For example: AssignGroup, FunctionGroup or OthersGroup.
-- @param hypergraph Hypergraph provided by luametrics.
-- @param node Group node.
-- @return Parent node.
local function get_group_parent(hypergraph, node)
    for incidence, edge in pairs(hypergraph[node]) do
        if incidence.label == "groupRoot" and edge.label == "groups" then
            for incidence, node in pairs(hypergraph[edge]) do
                if incidence.label == "groupParent" then
                    return node
                end
            end
        end
    end

    return nil
end

---------------------------------------------
-- Public methods
---------------------------------------------

--- Patch text function
-- This function will patch the text contained in the hypergraph.
-- @param hypergraph Hypergraph provided by luametrics.
-- @param vertexid ID of the vertex that has been modified.
-- @param text Modified text.
-- @return Patched text.
local function patch_text(hypergraph, vertexid, text)
    local start_node = utils.get_hypergraph_nodes_by_label(hypergraph, "STARTPOINT")[1] -- node that contains the complete source code
    local full_text = start_node.data.str -- complete source code (before re-parsing)

    local modified_node = hypergraph[vertexid] -- node that is being modified
    local original_text = modified_node.data.str -- node text (before re-parsing)

    local start, stop = modified_node.data.position - 1, modified_node.data.position + #original_text

    -- Final text consists of:
    -- full_text beginning + current text + full_text ending
    local final_text = string.sub(full_text, 1, start)
    final_text = final_text .. text
    final_text = final_text .. string.sub(full_text, stop, #full_text)

    return final_text
end

--- Find node pairs function
-- This function will properly identify nodes in the new tree.
-- @param old_hypergraph Old hypergraph provided by luametrics.
-- @param new_hypergraph New hypergraph provided by luametrics.
-- @param vertex_list List of vertexes that needs to be identified.
-- @return Table of pairs where key = old ID and value = new ID.
local function find_node_pairs(old_hypergraph, new_hypergraph, vertex_list)
    local new_vertex_list = {}

    for _, vid in ipairs(vertex_list) do
        local old_node = old_hypergraph[vid]

        if old_node.label == "STARTPOINT" then
            for node in pairs(new_hypergraph.Nodes) do
                if old_node.label == node.label and old_node.data.position == node.data.position then
                    new_vertex_list[vid] = node.id
                    break
                end
            end
        elseif old_node.label == "LocalFunction" or
               old_node.label == "GlobalFunction" or
               old_node.label == "FunctionCall" or
               old_node.label == "LocalAssign" or
               old_node.label == "Assign" then
            local best_candidate = nil
            for node in pairs(new_hypergraph.Nodes) do
                if old_node.label == node.label then
                    if old_node.data.str == node.data.str then
                        best_candidate = node.id
                        break
                    end

                    if old_node.data.position == node.data.position then
                        best_candidate = node.id
                    end
                end
            end

            new_vertex_list[vid] = best_candidate   
        elseif old_node.label == "eGlobalFunction" then
            for node in pairs(new_hypergraph.Nodes) do
                if old_node.label == node.label and old_node.data.name == node.data.name then
                    new_vertex_list[vid] = node.id
                    break
                end
            end
        elseif old_node.label == "FunctionGroup" or
               old_node.label == "AssignGroup" or
               old_node.label == "OthersGroup" then
            local old_parent = get_group_parent(hypergraph, old_node)

            for node in pairs(new_hypergraph.Nodes) do
                if node.label == old_node.label then
                    local new_parent = get_group_parent(new_hypergraph, node)

                    if old_parent.label == new_parent.label then
                        new_vertex_list[vid] = node.id
                        break
                    end
                end
            end
        end
    end

    return new_vertex_list
end

---------------------------------------------
-- Module definition
---------------------------------------------

return {
    patch_text = patch_text,
    find_node_pairs = find_node_pairs
}
