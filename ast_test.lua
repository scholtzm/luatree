local luatree = require("ast")
local utils = require("utils")

local code_old = "local a"
local code_new = "local b"
local code_file = "ast_test.lua"

local tree_old = luatree.get_tree(code_old)
local tree_new = luatree.get_tree(code_new)
local tree_file = luatree.get_tree_from_file(code_file)

luatree.compare(tree_old, tree_new)

--utils.print_tree(tree_new)

--utils.print_table(tree_old)
--utils.print_table(tree_new)

utils.print_tree_flags(tree_new)
print(utils.get_tree_flag_count(tree_new, "identical"))
print(utils.get_tree_flag_count(tree_new, "modified"))
