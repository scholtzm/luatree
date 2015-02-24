---------------------------------------------
-- Tests for AST submodule
-- @author: Michael Scholtz
---------------------------------------------

describe("ast submodule", function()
	local ast, utils
  
	setup(function()
		ast = require("ast")
		utils = require("utils")
	end) 
  
	it("gives me ast tree from string", function()
		local code = "local a"
		local tree = ast.get_tree(code)

		assert.is.truthy(tree)
	end)

	it("gives me ast tree from file", function()
		local file = "spec/test_file.lua"
		local tree = ast.get_tree_from_file(file)

		assert.is.truthy(tree)
	end)

	it("generates two different trees", function()
		local a = "local a"
		local b = "local b"

		local tree_a = ast.get_tree(a)
		local tree_b = ast.get_tree(b)

		assert.is_not.same(tree_a, tree_b)
	end)

	it("compares two ast trees", function()
		local a = "local a"
		local b = "local b"

		local tree_a = ast.get_tree(a)
		local tree_b = ast.get_tree(b)

		ast.compare(tree_a, tree_b)

		assert.equals(6, utils.get_tree_flag_count(tree_b, "identical"))
		assert.equals(9, utils.get_tree_flag_count(tree_b, "modified"))
	end)
end)
