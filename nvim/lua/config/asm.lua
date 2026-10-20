-- ARM assembly uses '@' for comments, but nvim-treesitter's asm grammar only
-- knows '#', ';', '//' and '/* */'. The parser therefore emits ERROR nodes for
-- every '@' comment and leaves the comment text unstyled.
--
-- Keep tree-sitter for the code, overlay '@' comments with a high-priority
-- extmark, and make Comment.nvim / 'formatoptions' use the file's comment style.

local M = {}

local ns = vim.api.nvim_create_namespace("asm-arm-comments")
local pending = {}

---Return the 0-based byte column where an ARM '@' comment starts, if any.
---@param line string
---@return integer?
local function at_comment_col(line)
	local first = line:find("%S")
	if first and line:sub(first, first) == "@" then
		return first - 1
	end

	local init = 1
	while true do
		local s = line:find("%s@%s", init) or line:find("%s@$", init)
		if not s then
			return nil
		end

		-- Ignore '@' inside an existing line comment (x86 @PLT operands do not
		-- match anyway, because they are not preceded by whitespace).
		local prefix = line:sub(1, s)
		if not (prefix:find(";", 1, true) or prefix:find("//", 1, true) or prefix:find("/*", 1, true)) then
			return s
		end

		init = s + 1
	end
end

---@param lines string[]
---@return boolean
local function is_arm_asm(lines)
	for _, line in ipairs(lines) do
		if
			line:match("^%s*%.syntax%s+unified")
			or line:match("^%s*%.thumb%f[%s]")
			or line:match("^%s*%.arm%f[%s]")
			or line:match("^%s*%.cpu%s+cortex")
			or line:match(",%s*%%function")
			or line:match(",%s*%%progbits")
			or line:match("%s[rR][0-7]%f[%W]")
		then
			return true
		end
	end

	for _, line in ipairs(lines) do
		if at_comment_col(line) then
			return true
		end
	end

	return false
end

---@param buf integer
local function refresh(buf)
	if not vim.b[buf].asm_arm then
		return
	end

	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	for row, line in ipairs(lines) do
		local col = at_comment_col(line)
		if col then
			vim.api.nvim_buf_set_extmark(buf, ns, row - 1, col, {
				end_col = #line,
				hl_group = "Comment",
				priority = 110,
				spell = true,
			})
		end
	end
end

function M.setup()
	local group = vim.api.nvim_create_augroup("asm-arm", { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		callback = function(args)
			if vim.bo[args.buf].filetype ~= "asm" then
				vim.b[args.buf].asm_arm = nil
				vim.api.nvim_buf_clear_namespace(args.buf, ns, 0, -1)
			end
		end,
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = "asm",
		callback = function(args)
			local buf = args.buf
			local lines = vim.api.nvim_buf_get_lines(buf, 0, 300, false)
			if not is_arm_asm(lines) then
				return
			end

			vim.b[buf].asm_arm = true

			-- Follow the comment style already used by the file.
			local at_comments, slash_comments, block_comments = 0, 0, 0
			for _, line in ipairs(lines) do
				if at_comment_col(line) then
					at_comments = at_comments + 1
				end
				if line:match("^%s*//") then
					slash_comments = slash_comments + 1
				end
				if line:match("/%*") then
					block_comments = block_comments + 1
				end
			end

			-- Make 'gq'/'J' treat '@' as a comment leader even if this file
			-- currently uses another style.
			if not vim.bo[buf].comments:find("@", 1, true) then
				vim.bo[buf].comments = vim.bo[buf].comments .. ",:@"
			end

			if at_comments > 0 then
				vim.bo[buf].commentstring = "@ %s"
			elseif slash_comments > 0 and slash_comments >= block_comments then
				vim.bo[buf].commentstring = "// %s"
			elseif block_comments > 0 then
				vim.bo[buf].commentstring = "/* %s */"
			else
				vim.bo[buf].commentstring = "@ %s"
			end

			refresh(buf)

			if not vim.b[buf].asm_arm_attached then
				vim.b[buf].asm_arm_attached = true
				vim.api.nvim_buf_attach(buf, false, {
					on_lines = function()
						if pending[buf] then
							return
						end
						pending[buf] = true
						vim.schedule(function()
							pending[buf] = nil
							if vim.api.nvim_buf_is_valid(buf) then
								refresh(buf)
							end
						end)
					end,
				})
			end
		end,
	})
end

return M
