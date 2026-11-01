-- Workspace rules wiki https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Add your workspace rules here. Increment the workspace number as you go. Do not have duplicate workspaces.
for i = 1, 10 do
    hl.workspace_rule({ workspace = tostring(i), default = (i == 1), persistent = true })
end
hl.workspace_rule({ workspace = "name:gaming", monitor = PRIMARY_MONITOR, default = true })

-- For other layouts such as scrolling, see example below
-- 