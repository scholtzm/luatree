---------------------------------------------
-- AST module
-- AST toolkit for Lua
-- @author: Michael Scholtz
---------------------------------------------

local metrics = require("metrics")
local utils = require("luatree.utils")

---------------------------------------------
-- Constants & Private methods
---------------------------------------------

--- Deep node comparator function.
-- Compares 2 nodes and and all the data inside.
-- @param node1 Node 1 to be compared
-- @param node2 Node 2 to be compared
-- @return a boolean value
local function equal_nodes_deep(node1, node2)
    for k, v in pairs(node1) do

        -- skip parent and children (oddly named as data)
        if k ~= "parent" and k ~= "data" then

            -- it must contain the same key
            if node2[k] == nil then
                return false
            end

            -- value is a table
            if type(node1[k]) == "table" then
                local result = equal_nodes_deep(node1[k], node2[k])
                if not result then
                    return false
                end
            else
                if node1[k] ~= node2[k] then
                    return false
                end
            end

        end

    end

    return true
end

--- Marking function
-- Marks the whole subtree as created
-- @param node Subtree root
local function mark_node_deep(node)
    node.flag = "created"

    for i = 1, #node.data do
        mark_node_deep(node.data[i])
    end
end

--- Shallow node comparator function.
-- Compares 2 nodes, but only "key" and "str"
-- @param node1 Node 1 to be compared
-- @param node2 Node 2 to be compared
-- @return a boolean value
local function equal_nodes_shallow(node1, node2)
    if node1 == nil or node2 == nil then
        return false
    end

    return node1.key == node2.key and node1.str == node2.str
end

--- Node type comparator function.
-- Compares 2 nodes types (keys).
-- @param node1 Node 1 to be compared
-- @param node2 Node 2 to be compared
-- @return a boolean value
local function equal_type(node1, node2)
    if node1 == nil or node2 == nil then
        return false
    end

    return node1.key == node2.key
end

---------------------------------------------
-- Public methods
---------------------------------------------

--- Function to get AST tree from string.
-- @param string Source code
-- @return tree structure
local function get_tree(string)
    return metrics.processText(string)
end

--- Function to get AST tree from file.
-- @param file File path
-- @return tree structure
local function get_tree_from_file(file)
    local code = utils.read_file(file)

    return get_tree(code)
end

--- Function to compare 2 AST trees.
-- This function compares 2 trees - new and old tree.
-- Iteration is done according to new tree which takes precedence.
-- New tree is slightly modified, some nodes may be tagged as "modified" or "created".
-- @param tree_new New AST tree returned from `get_tree` function
-- @param tree_old Old AST tree returned from `get_tree` function
local function compare(tree_old, tree_new)
    local is_equal_type = tree_new.key == tree_old.key
    local is_equal_text = tree_new.str == tree_old.str

    -- Set flags "created", "modified" and "identical"
    if is_equal_type then
        if not is_equal_text then
            tree_new.flag = "modified"
        else
            tree_new.flag = "identical"
        end
    else
        tree_new.flag = "created"
    end

    -- We are in a leaf, return
    if tree_new.data == nil or #tree_new.data == 0 then
        return
    end

    -- Initial forward iterator value
    local iterator = 1

    -- Iterate forward until types are not equal
    while equal_type(tree_new.data[iterator], tree_old.data[iterator]) do
        compare(tree_old.data[iterator], tree_new.data[iterator])

        iterator = iterator + 1
    end

    -- Number of children may vary --> we have 2 backtracking indexes
    local back_iterator_new = #tree_new.data or 0
    local back_iterator_old = #tree_old.data or 0

    -- Iterate backwards if possible
    while true do
        if back_iterator_new < iterator or back_iterator_old < iterator then
            break
        end

        compare(tree_old.data[back_iterator_old], tree_new.data[back_iterator_new])

        back_iterator_new = back_iterator_new - 1
        back_iterator_old = back_iterator_old - 1
    end

    -- We need to mark all other nodes as new
    while iterator <= back_iterator_new do
        mark_node_deep(tree_new.data[iterator])

        iterator = iterator + 1
    end

end

---------------------------------------------
-- Module definition
---------------------------------------------

return {
    get_tree = get_tree,
    get_tree_from_file = get_tree_from_file,
    compare = compare
}
