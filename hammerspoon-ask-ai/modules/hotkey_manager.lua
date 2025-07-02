-- Hotkey Manager Module
-- Handles global hotkey registration and management
-- Updated to support action-based hotkey system

local HotkeyManager = {}
HotkeyManager.__index = HotkeyManager

function HotkeyManager:new()
    local instance = setmetatable({}, HotkeyManager)
    instance.hotkeys = {}
    instance.registeredKeys = {}
    return instance
end

function HotkeyManager:bind(hotkeyConfig, callback)
    if not hotkeyConfig or not hotkeyConfig.key or not hotkeyConfig.modifiers then
        return false, "Invalid hotkey configuration"
    end
    
    local key = hotkeyConfig.key
    local modifiers = hotkeyConfig.modifiers
    
    -- Create unique identifier for this hotkey
    local hotkeyId = self:createHotkeyId(modifiers, key)
    
    -- Check if hotkey is already registered
    if self.registeredKeys[hotkeyId] then
        return false, "Hotkey already registered: " .. hotkeyId
    end
    
    -- Create and register the hotkey
    local hotkey = hs.hotkey.bind(modifiers, key, callback)
    
    if hotkey then
        self.hotkeys[hotkeyId] = hotkey
        self.registeredKeys[hotkeyId] = {
            key = key,
            modifiers = modifiers,
            callback = callback,
            config = hotkeyConfig
        }
        return true, hotkeyId
    else
        return false, "Failed to register hotkey: " .. hotkeyId
    end
end

-- Bind action-based hotkeys from new configuration format
function HotkeyManager:bindActionHotkeys(hotkeyArray, actionRegistry, createContextCallback)
    local results = {}
    
    for i, hotkeyConfig in ipairs(hotkeyArray) do
        local name = hotkeyConfig.name or ("hotkey_" .. i)
        local actions = hotkeyConfig.actions or {}
        
        print("🤖 Binding action hotkey: " .. name)
        
        -- Create callback that executes action chain
        local callback = function()
            print("🤖 Action hotkey triggered: " .. name)
            
            -- Create execution context
            local context = createContextCallback()
            
            -- Validate input
            local success, error = pcall(function()
                context:validateInput()
            end)
            
            if not success then
                hs.alert.show("Error: " .. error)
                return
            end
            
            -- Execute action chain
            success, error = pcall(function()
                context:executeActions(actions)
            end)
            
            if not success then
                print("🤖 ✗ Action chain failed: " .. error)
                hs.alert.show("Action failed: " .. error)
            else
                print("🤖 ✓ Action chain completed: " .. name)
            end
        end
        
        -- Bind the hotkey
        local success, message = self:bindWithValidation(hotkeyConfig, callback)
        results[name] = {
            success = success,
            message = message,
            config = hotkeyConfig,
            actions = actions
        }
        
        if success then
            print("🤖 ✓ Action hotkey bound: " .. name .. " (" .. self:formatHotkeyDisplay(hotkeyConfig.modifiers, hotkeyConfig.key) .. ")")
        else
            print("🤖 ✗ Failed to bind action hotkey: " .. name .. " - " .. message)
        end
    end
    
    return results
end

function HotkeyManager:unbind(hotkeyId)
    if self.hotkeys[hotkeyId] then
        self.hotkeys[hotkeyId]:delete()
        self.hotkeys[hotkeyId] = nil
        self.registeredKeys[hotkeyId] = nil
        return true
    end
    return false
end

function HotkeyManager:unbindAll()
    for hotkeyId, hotkey in pairs(self.hotkeys) do
        hotkey:delete()
    end
    self.hotkeys = {}
    self.registeredKeys = {}
end

function HotkeyManager:createHotkeyId(modifiers, key)
    -- Sort modifiers for consistent ID
    local sortedModifiers = {}
    for _, mod in ipairs(modifiers) do
        table.insert(sortedModifiers, mod)
    end
    table.sort(sortedModifiers)
    
    return table.concat(sortedModifiers, "+") .. "+" .. key
end

function HotkeyManager:isHotkeyRegistered(modifiers, key)
    local hotkeyId = self:createHotkeyId(modifiers, key)
    return self.registeredKeys[hotkeyId] ~= nil
end

function HotkeyManager:getRegisteredHotkeys()
    local result = {}
    for hotkeyId, config in pairs(self.registeredKeys) do
        table.insert(result, {
            id = hotkeyId,
            key = config.key,
            modifiers = config.modifiers,
            display = self:formatHotkeyDisplay(config.modifiers, config.key),
            name = config.config.name or "unnamed",
            description = config.config.description or "No description",
            actions = config.config.actions or {}
        })
    end
    return result
end

function HotkeyManager:formatHotkeyDisplay(modifiers, key)
    local modifierSymbols = {
        cmd = "⌘",
        alt = "⌥",
        opt = "⌥",  -- Support both alt and opt
        ctrl = "⌃",
        shift = "⇧"
    }
    
    local displayParts = {}
    
    -- Add modifiers in standard order
    local standardOrder = {"ctrl", "alt", "opt", "shift", "cmd"}
    for _, mod in ipairs(standardOrder) do
        if self:tableContains(modifiers, mod) then
            table.insert(displayParts, modifierSymbols[mod] or mod)
        end
    end
    
    -- Add key
    table.insert(displayParts, key:upper())
    
    return table.concat(displayParts, "")
end

function HotkeyManager:tableContains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function HotkeyManager:validateHotkeyConfig(config)
    if not config then
        return false, "No hotkey configuration provided"
    end
    
    if not config.key or config.key == "" then
        return false, "Hotkey key is required"
    end
    
    if not config.modifiers or type(config.modifiers) ~= "table" or #config.modifiers == 0 then
        return false, "Hotkey modifiers are required"
    end
    
    -- Validate modifier names
    local validModifiers = {"cmd", "alt", "opt", "ctrl", "shift"}
    for _, modifier in ipairs(config.modifiers) do
        if not self:tableContains(validModifiers, modifier) then
            return false, "Invalid modifier: " .. modifier
        end
    end
    
    -- Validate key
    if string.len(config.key) > 1 then
        -- Special keys validation
        local validSpecialKeys = {
            "return", "tab", "space", "delete", "escape", "help", "home", "pageup",
            "forwarddelete", "end", "pagedown", "left", "right", "down", "up",
            "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12"
        }
        
        if not self:tableContains(validSpecialKeys, config.key:lower()) then
            return false, "Invalid special key: " .. config.key
        end
    end
    
    return true, "Valid hotkey configuration"
end

function HotkeyManager:checkConflicts(modifiers, key)
    -- Check for conflicts with system hotkeys
    local systemHotkeys = {
        {modifiers = {"cmd"}, key = "space", description = "Spotlight"},
        {modifiers = {"cmd"}, key = "tab", description = "App Switcher"},
        {modifiers = {"cmd", "shift"}, key = "3", description = "Screenshot"},
        {modifiers = {"cmd", "shift"}, key = "4", description = "Screenshot Area"},
        {modifiers = {"cmd", "shift"}, key = "5", description = "Screenshot/Recording"},
        {modifiers = {"cmd"}, key = "h", description = "Hide Application"},
        {modifiers = {"cmd"}, key = "m", description = "Minimize Window"},
        {modifiers = {"cmd"}, key = "q", description = "Quit Application"},
        {modifiers = {"cmd"}, key = "w", description = "Close Window"},
    }
    
    local hotkeyId = self:createHotkeyId(modifiers, key)
    
    for _, systemHotkey in ipairs(systemHotkeys) do
        local systemHotkeyId = self:createHotkeyId(systemHotkey.modifiers, systemHotkey.key)
        if hotkeyId == systemHotkeyId then
            return true, "Conflicts with system hotkey: " .. systemHotkey.description
        end
    end
    
    return false, "No conflicts detected"
end

function HotkeyManager:suggestAlternatives(modifiers, key)
    -- Suggest alternative hotkey combinations
    local alternatives = {}
    
    -- Try different modifier combinations
    local modifierCombinations = {
        {"cmd", "shift"},
        {"cmd", "alt"},
        {"cmd", "opt"},
        {"cmd", "ctrl"},
        {"alt", "shift"},
        {"opt", "shift"},
        {"ctrl", "shift"},
        {"cmd", "alt", "shift"},
        {"cmd", "opt", "shift"}
    }
    
    for _, altModifiers in ipairs(modifierCombinations) do
        local altHotkeyId = self:createHotkeyId(altModifiers, key)
        if not self.registeredKeys[altHotkeyId] then
            local hasConflict, _ = self:checkConflicts(altModifiers, key)
            if not hasConflict then
                table.insert(alternatives, {
                    modifiers = altModifiers,
                    key = key,
                    display = self:formatHotkeyDisplay(altModifiers, key)
                })
            end
        end
    end
    
    return alternatives
end

function HotkeyManager:bindWithValidation(hotkeyConfig, callback)
    -- Validate configuration
    local isValid, validationMessage = self:validateHotkeyConfig(hotkeyConfig)
    if not isValid then
        return false, validationMessage
    end
    
    -- Check for conflicts
    local hasConflict, conflictMessage = self:checkConflicts(hotkeyConfig.modifiers, hotkeyConfig.key)
    if hasConflict then
        return false, conflictMessage
    end
    
    -- Check if already registered
    if self:isHotkeyRegistered(hotkeyConfig.modifiers, hotkeyConfig.key) then
        return false, "Hotkey already registered"
    end
    
    -- Bind the hotkey
    return self:bind(hotkeyConfig, callback)
end

-- Legacy support for old hotkey format
function HotkeyManager:reloadHotkeys(hotkeyConfigs, callbacks)
    -- Unbind all existing hotkeys
    self:unbindAll()
    
    -- Bind new hotkeys
    local results = {}
    for name, config in pairs(hotkeyConfigs) do
        if callbacks[name] then
            local success, message = self:bindWithValidation(config, callbacks[name])
            results[name] = {
                success = success,
                message = message,
                config = config
            }
        end
    end
    
    return results
end

-- Get debug information about registered hotkeys
function HotkeyManager:debug()
    print("🤖 Hotkey Manager Debug:")
    print("  Total registered hotkeys: " .. #self:getRegisteredHotkeys())
    
    for hotkeyId, config in pairs(self.registeredKeys) do
        local display = self:formatHotkeyDisplay(config.modifiers, config.key)
        local name = config.config.name or "unnamed"
        local actionsCount = config.config.actions and #config.config.actions or 0
        print("    " .. display .. " (" .. name .. ") - " .. actionsCount .. " actions")
    end
end

return HotkeyManager