local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.is_vim(pane)
	local process_name = pane:get_foreground_process_name()
	return process_name and (process_name:find("vim") or process_name:find("nvim"))
end

function M.vim_aware_navigation(direction, vim_key)
	return wezterm.action_callback(function(window, pane)
		if not M.is_vim(pane) then
			window:perform_action(act.ActivatePaneDirection(direction), pane)
		else
			pane:send_text(vim_key)
		end
	end)
end

function M.open_url()
	return wezterm.action.QuickSelectArgs({
		label = "open url",
		patterns = {
			"https?://\\S+",
		},
		skip_action_on_paste = true,
		action = wezterm.action_callback(function(window, pane)
			local url = window:get_selection_text_for_pane(pane)
			wezterm.log_info("opening: " .. url)
			wezterm.open_with(url)
		end),
	})
end

function M.manage_workspaces()
	return wezterm.action_callback(function(window, pane)
		local home = os.getenv("HOME")
		local paths = {
			home .. "/workspace",
			home .. "/workspace/work",
			home .. "/workspace/personal",
			home .. "/.config",
			home .. "/Documents/Obsidian",
		}

		local find_cmd = "find " .. table.concat(paths, " ") .. " -mindepth 1 -maxdepth 1 -type d 2>/dev/null"

		local success, stdout = wezterm.run_child_process({
			"bash",
			"-c",
			find_cmd,
		})

		if success then
			local entries = {}
			local name_count = {}
			for line in stdout:gmatch("[^\r\n]+") do
				local name = line:match("([^/]+)$")
				table.insert(entries, { path = line, name = name })
				name_count[name] = (name_count[name] or 0) + 1
			end

			local choices = {}
			for _, entry in ipairs(entries) do
				local label = entry.name
				if name_count[entry.name] > 1 then
					local parent = entry.path:match("([^/]+)/[^/]+$")
					label = entry.name .. "  (" .. parent .. ")"
				end
				table.insert(choices, {
					id = entry.path,
					label = label,
				})
			end

			window:perform_action(
				act.InputSelector({
					title = "Select Project",
					choices = choices,
					fuzzy = true,
					action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
						if id and label then
							inner_window:perform_action(
								act.SwitchToWorkspace({
									name = label,
									spawn = { cwd = id },
								}),
								inner_pane
							)
						end
					end),
				}),
				pane
			)
		end
	end)
end

return M
