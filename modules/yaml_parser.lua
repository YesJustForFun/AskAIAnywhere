-- YAML Parser for Ask AI Anywhere
-- Simple YAML parser for configuration files
-- Supports basic YAML features needed for configuration

local YamlParser = {}
YamlParser.__index = YamlParser

function YamlParser:new()
    local instance = setmetatable({}, YamlParser)
    return instance
end

-- Parse YAML content to Lua table
function YamlParser:parse(content)
    if not content or content == "" then
        return {}
    end
    
    local lines = self:splitLines(content)
    local result = {}
    local stack = {{table = result, indent = -1}}
    local currentIndent = 0
    
    for i, line in ipairs(lines) do
        local processedLine = self:processLine(line, i, stack)
        if processedLine then
            self:parseLine(processedLine, stack)
        end
    end
    
    return result
end

-- Split content into lines
function YamlParser:splitLines(content)
    local lines = {}
    for line in content:gmatch("[^\r\n]*") do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    return lines
end

-- Process individual line (handle comments, empty lines, etc.)
function YamlParser:processLine(line, lineNumber, stack)
    -- Skip empty lines
    if line:match("^%s*$") then
        return nil
    end
    
    -- Skip comments
    if line:match("^%s*#") then
        return nil
    end
    
    -- Calculate indentation
    local indent = 0
    for char in line:gmatch(".") do
        if char == " " then
            indent = indent + 1
        elseif char == "\t" then
            indent = indent + 4  -- Treat tab as 4 spaces
        else
            break
        end
    end
    
    return {
        content = line:match("^%s*(.*)$"),  -- Remove leading whitespace
        indent = indent,
        lineNumber = lineNumber
    }
end

-- Parse a processed line
function YamlParser:parseLine(processedLine, stack)
    local content = processedLine.content
    local indent = processedLine.indent
    
    -- Adjust stack based on indentation
    self:adjustStack(indent, stack)
    
    -- Handle different line types
    if content:match("^%-") then
        -- Array item
        self:parseArrayItem(content, indent, stack)
    elseif content:match(":") then
        -- Key-value pair
        self:parseKeyValue(content, indent, stack)
    else
        -- Continuation or malformed line
        print("Warning: Unexpected line format: " .. content)
    end
end

-- Adjust stack based on indentation level
function YamlParser:adjustStack(indent, stack)
    -- Pop stack until we find appropriate parent level
    while #stack > 1 and stack[#stack].indent >= indent do
        table.remove(stack)
    end
end

-- Parse array item (starts with -)
function YamlParser:parseArrayItem(content, indent, stack)
    local itemContent = content:match("^%-%s*(.*)$")
    local currentTable = stack[#stack].table
    
    -- Ensure current table is an array
    if not currentTable then
        currentTable = {}
        stack[#stack].table = currentTable
    end
    
    if itemContent and itemContent ~= "" then
        if itemContent:match(":") then
            -- Complex array item (object)
            local newItem = {}
            table.insert(currentTable, newItem)
            table.insert(stack, {table = newItem, indent = indent})
            self:parseKeyValue(itemContent, indent, stack)
        else
            -- Simple array item
            local value = self:parseValue(itemContent)
            table.insert(currentTable, value)
        end
    else
        -- Array item without content (will be filled by subsequent lines)
        local newItem = {}
        table.insert(currentTable, newItem)
        table.insert(stack, {table = newItem, indent = indent})
    end
end

-- Parse key-value pair
function YamlParser:parseKeyValue(content, indent, stack)
    local key, value = content:match("^([^:]+):%s*(.*)$")
    
    if not key then
        print("Warning: Could not parse key-value: " .. content)
        return
    end
    
    key = key:match("^%s*(.-)%s*$")  -- Trim whitespace
    local currentTable = stack[#stack].table
    
    if value and value ~= "" then
        -- Inline value
        if value:match("^%[.*%]$") then
            -- Inline array
            currentTable[key] = self:parseInlineArray(value)
        elseif value:match("^{.*}$") then
            -- Inline object
            currentTable[key] = self:parseInlineObject(value)
        elseif value:match("^[|>]") then
            -- Multi-line string (simplified - just remove the indicator)
            currentTable[key] = value:gsub("^[|>]%s*", "")
        else
            -- Simple value
            currentTable[key] = self:parseValue(value)
        end
    else
        -- Complex value (will be filled by subsequent lines)
        currentTable[key] = {}
        table.insert(stack, {table = currentTable[key], indent = indent, key = key})
    end
end

-- Parse inline array [item1, item2, item3]
function YamlParser:parseInlineArray(value)
    local content = value:match("^%[(.*)%]$")
    if not content then return {} end
    
    local items = {}
    for item in content:gmatch("[^,]+") do
        local trimmed = item:match("^%s*(.-)%s*$")
        table.insert(items, self:parseValue(trimmed))
    end
    return items
end

-- Parse inline object {key1: value1, key2: value2}
function YamlParser:parseInlineObject(value)
    local content = value:match("^{(.*)}$")
    if not content then return {} end
    
    local obj = {}
    for pair in content:gmatch("[^,]+") do
        local key, val = pair:match("^%s*([^:]+):%s*(.-)%s*$")
        if key and val then
            obj[key:match("^%s*(.-)%s*$")] = self:parseValue(val)
        end
    end
    return obj
end

-- Parse and convert value to appropriate Lua type
function YamlParser:parseValue(value)
    if not value then return nil end
    
    value = value:match("^%s*(.-)%s*$")  -- Trim whitespace
    
    -- Handle quoted strings
    if value:match('^".*"$') or value:match("^'.*'$") then
        return value:sub(2, -2)  -- Remove quotes
    end
    
    -- Handle boolean values
    if value:lower() == "true" then return true end
    if value:lower() == "false" then return false end
    
    -- Handle null/nil
    if value:lower() == "null" or value:lower() == "nil" or value == "~" then
        return nil
    end
    
    -- Handle numbers
    local num = tonumber(value)
    if num then return num end
    
    -- Handle multi-line strings with escape sequences
    value = value:gsub("\\n", "\n")
    value = value:gsub("\\t", "\t")
    value = value:gsub("\\r", "\r")
    
    -- Return as string
    return value
end

-- Convert Lua table to YAML (for saving configurations)
function YamlParser:toYaml(data, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    local result = {}
    
    if type(data) == "table" then
        -- Check if it's an array
        local isArray = self:isArray(data)
        
        if isArray then
            for _, value in ipairs(data) do
                if type(value) == "table" then
                    table.insert(result, indentStr .. "-")
                    local subYaml = self:toYaml(value, indent + 1)
                    for line in subYaml:gmatch("[^\n]+") do
                        if line:match("^%s*$") then
                            -- Skip empty lines
                        else
                            table.insert(result, "  " .. line)
                        end
                    end
                else
                    table.insert(result, indentStr .. "- " .. self:formatValue(value))
                end
            end
        else
            for key, value in pairs(data) do
                if type(value) == "table" then
                    table.insert(result, indentStr .. key .. ":")
                    local subYaml = self:toYaml(value, indent + 1)
                    table.insert(result, subYaml)
                else
                    table.insert(result, indentStr .. key .. ": " .. self:formatValue(value))
                end
            end
        end
    else
        return self:formatValue(data)
    end
    
    return table.concat(result, "\n")
end

-- Check if table is an array
function YamlParser:isArray(t)
    if type(t) ~= "table" then return false end
    
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
        if type(k) ~= "number" or k ~= count then
            return false
        end
    end
    return true
end

-- Format value for YAML output
function YamlParser:formatValue(value)
    if type(value) == "string" then
        -- Quote strings that need it
        if value:match("[:\n\r\t]") or value:match("^[%d%.%-]") then
            return '"' .. value:gsub('"', '\\"') .. '"'
        else
            return value
        end
    elseif type(value) == "boolean" then
        return value and "true" or "false"
    elseif type(value) == "number" then
        return tostring(value)
    elseif value == nil then
        return "null"
    else
        return tostring(value)
    end
end

return YamlParser