local git_util = require("gitutil")

------------------------------------------

--[[
    cwd: 
    git:
    lambda:
    machine_name:
]]

local prompt_format = "{machine_name}{cwd}{git}\n{!lambda}"

local custom_lambda_marker = "﬌"

------------------------------------------
-- util --
----------

local util = {
    table = {},
    string = {},
    cmd = {}
}

----------

util.table.contains = function (table, value)
    for _, table_value in ipairs(table) do
        if (table_value == value) then
            return true
        end
    end

    return false
end

util.table.copy_values = function (target_table, range)
    for _, v in ipairs(range) do
        table.insert(target_table, v)
    end
end

util.table.copy_index_values = function (target_table, range)
    for i, v in pairs(range) do
        target_table[i] = v
    end
end

util.table.contains = function (table, value)
    for _, v in ipairs(table) do
        if (v == value) then
            return true
        end
    end

    return false
end

----------

util.string.join = function (sep, table)
    local combined = ""

    for i, value in ipairs(table) do
        combined = combined .. value

        if (i < #table) then
            combined = combined .. sep
        end
    end

    return combined
end

----------

util.cmd.open_get_lines = function (command)
    local lines = {}

    local file = io.popen(command)
    for line in file:lines() do
        table.insert(lines, line)
    end

    file:close()
    return lines
end

------------------------------------------
-- git --
---------
local git = {}

---
 -- Resolves closest .git directory location.
 -- Navigates subsequently up one level and tries to find .git directory
 -- @param  {string} path Path to directory will be checked. If not provided
 --                       current directory will be used
 -- @return {string} Path to .git directory or nil if such dir not found
git.git_dir = function(start_dir)
    return git_util.get_git_dir(start_dir)
end

---
 -- Find out current branch
 -- @return {nil|git branch name}
---
git.branch = function(dir)
    return git_util.get_git_branch(dir)
end

---
-- Get the status of working dir
-- @return {bool}
---
git.status = function ()
    local file = io.popen("git --no-optional-locks status --porcelain 2>nul")
    for line in file:lines() do
        file:close()
        return false
    end
    file:close()

    return true
end

---
-- Gets the conflict status
-- @return {bool} indicating true for conflict, false for no conflicts
---
git.conflict = function ()
    local file = io.popen("git diff --name-only --diff-filter=U 2>nul")
    for line in file:lines() do
        file:close()
        return true;
    end
    file:close()
    return false
end

git.remotes = function ()
    return util.cmd.open_get_lines("git remote")
end

git.branches = function (mode)
    local branches = {}

    if (type(mode) == "nil") then
        -- get all branches
        local all_branches = util.cmd.open_get_lines("git branch --list -a")
        util.table.copy_values(branches, all_branches)
    elseif (type(mode) == "string") then
        if (mode == "remote") then
            local remote_branches = util.cmd.open_get_lines("git branch --list -r")

            for _, v in ipairs(remote_branches) do
                if not string.find(v, "HEAD") then
                    table.insert(branches, v)
                end
            end
        elseif (mode == "local") then
            local local_branches = util.cmd.open_get_lines("git branch --list")
            util.table.copy_values(branches, local_branches)
        elseif (mode ~= "") then
            -- specific remote name
            local remote_branches = util.cmd.open_get_lines("git branch --list -r")

            for _, remote_name in ipairs(remote_branches) do
                local i_begin, i_end = string.find(remote_name, mode)

                if (i_begin ~= nil and (i_end == string.len(remote_name) or remote_name[i_end + 1] == "/")) then
                    table.insert(branches, remote_name)
                end
            end
        end
    end

    return branches
end

git.stagged_filenames = function ()
    return util.cmd.open_get_lines("git diff --name-only --staged")
end

git.contains_commits_not_pushed = function (branch)
    local remote_branches = git.branches("remote")
    local remote_branch = nil

    for _, remote_branch_name in ipairs(remote_branches) do
        if (string.find(remote_branch_name, branch)) then
            remote_branch = remote_branch_name
            break
        end
    end

    if (remote_branch == nil) then
        return false
    end

    local diff = util.cmd.open_get_lines(string.format("git diff %s..%s", branch, remote_branch))
    return #diff > 0
end

--

function get_git_display()
    local display = {
        text = nil,
        foreground = nil,
        background = nil
    }

    local git_dir = git.git_dir()

    if (git_dir) then
        local branch = git.branch(git_dir)

        if (branch) then
            local git_status = git.status()
            local git_conflict = git.conflict()

            if (git_conflict) then
                -- conflict
                display.background = 1 -- red
                display.foreground = 0 -- black
            elseif (git_status) then
                -- nothing to commit
                display.background = 6 -- green
                display.foreground = 0 -- black
            else
                -- changes to folder
                display.background = 3 -- orange
                display.foreground = 0 -- black
            end

            local exists_remote_branch = false
            local branches = git.branches("remote")

            for _, branch_name in ipairs(branches) do
                if (string.find(branch_name, branch, 1, true)) then
                    exists_remote_branch = true
                    break
                end
            end

            local remote_branch_status = ""

            -- brand new local branch
            if (not exists_remote_branch) then
                remote_branch_status = remote_branch_status .. ""
            end

            -- contains some commits not yet pushed
            if (git.contains_commits_not_pushed(branch)) then
                remote_branch_status = remote_branch_status .. "ﰵ"
            end

            -- check if staged files exists
            if (#git.stagged_filenames() > 0) then
                remote_branch_status = remote_branch_status .. ""
            end

            if (string.len(remote_branch_status) > 0) then
                remote_branch_status = " " .. remote_branch_status
            end

            display.text = string.format(" %s%s", branch, remote_branch_status)
        end
    end

    return display
end

------------------------------------------
-- others --
------------

local function lambda_marker()
    if (type(custom_lambda_marker) == "string") then
        return custom_lambda_marker .. " "
    elseif (use_default_lambda) then
        return "λ "
    end

    return ""
end

local function cwd() 
    return string.format("%s", clink.get_cwd())
end

local function machine_name()
    local username = os.getenv("USERNAME")
    local userdomain = os.getenv("USERDOMAIN")

    return string.format("%s@%s", username, userdomain)
end

------------------------------------------
 
local GRAPHICS_MODE = {
    ATTRIBUTES = {
        [0] = { "off", "none" },
        [1] = { "bold" },
        [4] = { "underscore" },
        [5] = { "blink", "blink on" },
        [7] = { "reverse", "reverse video on" },
        [8] = { "concealed", "concealed on" }
    }
}

local function graphics_mode(mode)
    local graphics_mode = {}

    -- convert mode.attributes to number before using it
    if mode.attributes ~= nil then
        for _, attribute in ipairs(mode.attributes) do
            if (type(attribute) == "string") then
                for attr_id, names in pairs(GRAPHICS_MODE.ATTRIBUTES) do
                    if (util.table.contains(names, attribute)) then
                        attribute = attr_id
                    end
                end
            end

            table.insert(graphics_mode, attribute)
        end
    else
        -- all attributes off
        table.insert(graphics_mode, 0)
    end

    if type(mode.foreground) == "number" then
        local foreground = mode.foreground
        if (foreground < 10) then
            foreground = foreground + 30
        end

        table.insert(graphics_mode, foreground)
    else 
        table.insert(graphics_mode, 30) -- black
    end

    if type(mode.background) == "number" then
        local background = mode.background
        if (background < 10) then
            background = background + 40
        end

        table.insert(graphics_mode, background)
    else
        table.insert(graphics_mode, 40) -- black
    end

    local graphics_mode_combined = util.string.join(";", graphics_mode)

    return string.format("\x1b[%sm", graphics_mode_combined)
end

------------------------------------------
-- prompt builder --
--------------------

local items_data = {
    machine_name = {
        data = machine_name,
        format = {
            attributes = {},
            foreground = 4, -- dark grey
            background = 5  -- purple
        }
    },
    cwd = {
        data = cwd,
        format = {
            attributes = { 1 },
            foreground = 6, -- cyan
            background = 4  -- dark grey
        }
    },
    git = {
        data = get_git_display,
        format = {
            attributes = {},
            foreground = nil,
            background = nil
        }
    },
    lambda = {
        data = lambda_marker,
        format = {
            attributes = {},
            foreground = 5,   -- purple
            background = nil  -- black
        }
    }
}

local prompt_builder = {
    separator = ""
}

prompt_builder.begin = function (format)
    prompt_builder.format = format
    prompt_builder.items = {}
end

prompt_builder.finalize = function (lambda_info)
    local prompt_message = prompt_builder.format

    local section = {
        id = 0,
        foreground = nil,
        background = nil,
        attributes = {},
        last_insert_index = nil
    }

    local previous_section = {
        id = -1,
        foreground = nil,
        background = nil,
        attributes = {},
        last_insert_index = nil
    }

    local function separator(current_item_format) 
        local current_background = nil

        if (type(current_item_format) ~= "nil") then
            current_background = current_item_format.background
        end

        local format = graphics_mode({
            foreground = previous_section.background,
            background = current_background,
            attributes = {}
        })

        return string.format(" \x1b[0m%s%s ", format, prompt_builder.separator)
    end

    for i, item_info in ipairs(prompt_builder.items) do
        if (item_info.data ~= nil) then
            local data = item_info.data()
            local item_text = ""

            if ((type(data) == "table" and data.text ~= nil and data.text ~= "") or (type(data) == "string" and data ~= nil and data ~= "")) then
                section.foreground = item_info.format.foreground
                section.background = item_info.format.background
                section.attributes = item_info.format.attributes

                local data_text = data

                -- when data is table type, it can override some values
                if (type(data) == "table") then
                    data_text = data.text

                    if (data.foreground ~= nil) then
                        section.foreground = data.foreground
                    end

                    if (data.background ~= nil) then
                        section.background = data.background
                    end

                    if (data.attributes ~= nil) then
                        section.attributes = data.attributes
                    end
                end

                if (section.id > 0) then
                    item_text = item_text .. separator(section)
                else
                    -- insert a space at the beginning of first item
                    data_text = " " .. data_text
                end

                item_text = item_text .. graphics_mode(section) .. data_text

                local pattern_pos = string.find(prompt_message, item_info.pattern)
                if (pattern_pos ~= nil) then
                    section.last_insert_index = pattern_pos + string.len(item_text)
                end

                --

                previous_section.id = section.id
                previous_section.foreground = section.foreground
                previous_section.background = section.background
                previous_section.attributes = section.attributes
                previous_section.last_insert_index = section.last_insert_index

                --

                section.id = section.id + 1
            end

            prompt_message = string.gsub(prompt_message, item_info.pattern, item_text)
        end
    end

    -- append separator at end of items
    prompt_message = string.sub(prompt_message, 1, section.last_insert_index - 1) .. separator() .. "\x1b[0m" .. string.sub(prompt_message, section.last_insert_index)

    if (lambda_info ~= nil) then
        local lambda_text = graphics_mode(lambda_info.format) .. lambda_info.data() .. "\x1b[0m"
        prompt_message = string.gsub(prompt_message, "{!lambda}", lambda_text)
    end

    -- removes any unused items
    -- prompt_message = string.gsub(prompt_message, "{.-}", "")

    -- clean prompt_builder
    prompt_builder.format = nil
    prompt_builder.items = {}

    return prompt_message  
end

prompt_builder.item = function (name, info)
    local new_item = {
        pattern = string.format("{%s}", name),
        format = info.format or {},
        data = info.data or "?"
    }

    table.insert(prompt_builder.items, new_item)
end

------------------------------------------

function prompt_filter()
    prompt_builder.begin(prompt_format)

    for item_name in string.gmatch(prompt_builder.format, "{(!?.-)}") do
        if (item_name[0] ~= "!") then
            local item_info = items_data[item_name]

            if (item_info ~= nil) then
                prompt_builder.item(item_name, item_info)
            end
        end
    end

    local prompt_message = prompt_builder.finalize(items_data.lambda)
    clink.prompt.value = prompt_message
end

clink.prompt.register_filter(prompt_filter)
