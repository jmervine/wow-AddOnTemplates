
AddOnTemplates = LibStub("AceAddon-3.0"):NewAddon("AddOnTemplates", "AceConsole-3.0")
AddOnTemplates.ADDON_NAME = "AddOnTemplates"
AddOnTemplates.DefaultTemplate = string.format("%s@Default", UnitName("player"))

function AddOnTemplates:OnInitialize()
  if not AddOnTemplatesStore or next(AddOnTemplatesStore) == nil then
    AddOnTemplatesStore = {
      [self.DefaultTemplate] = self:getAddOns()
    }
  end

  if self.LibsUI then
    self:InitializeUI()
  end

  self:Print("Welcome! Type '/addontemplates' to get started.")
end


AddOnTemplates.SlashCommands = "addontemplates"
AddOnTemplates.SlashAliases = { "at", "addons" }

AddOnTemplates.HelpMessages = {
  ["help"] = {
    desc = "Show help message.",
    opts = "[SUBCOMMAND]"
  },
  ["addons"] = {
    desc = "List currently enabled AddOns.",
    opts = ""
  },
  ["show"] = {
    desc = "Show saved template or templates.",
    opts = "[TEMPLATE]"
  },
  ["load"] = {
    desc = "Load saved 'TEMPLATE'.",
    opts = "TEMPLATE"
  },
  ["save"] = {
    desc = "Saved current AddOn state as 'TEMPLATE'.",
    opts = "TEMPLATE"
  },
  ["delete"] = {
    desc = "Delete saved 'TEMPLATE'.",
    opts = "TEMPLATE"
  }
}
table.sort(AddOnTemplates.HelpMessages)

AddOnTemplates:RegisterChatCommand(AddOnTemplates.SlashCommands, "SlashHandler")
for _, c in ipairs(AddOnTemplates.SlashAliases) do
  AddOnTemplates:RegisterChatCommand(c, "SlashHandler")
end

function AddOnTemplates:SlashHandler(input)
  -- handle no input
  if not input or input == "" then
    self:Help()
    return
  end

  -- handle single input
  if input == "help" then
    self:Help()
  elseif input == "show" then
    self:ShowAll()
  elseif input == "addons" then
    self:AddOns()
  elseif input == "save" then
    self:Save(self.DefaultTemplate)
  elseif input == "load" then
    self:Print("'load' requires a template argument.")
  elseif input == "delete" then
    self:Print("'delete' requires a template argument.")
  else

    -- handle multiple input
    local cmd, input = self:GetArgs(input, 2, 1)

    if cmd == "load" then
      self:Load(input)
    elseif cmd == "show" then
      self:ShowOne(input)
    elseif cmd == "save" then
      self:Save(input)
    elseif cmd == "delete" then
      self:Delete(input)
    else
      self:Help()
    end

  end

  return
end

function AddOnTemplates:Help()
  self:OpenOptions()

  return
end

function AddOnTemplates:ShowOne(template)
  local addons = AddOnTemplatesStore[template]

  if addons == nil then
    self:Printf("Template %s not found.", template)
    return
  end

  self:Printf("Template: %s", template)
  local astr = table.concat(addons, ", ")
  self:Printf(" %s", astr)
end

function AddOnTemplates:ShowAll()
  local store = AddOnTemplatesStore
  self:Print("Templates:")

  if store == nil or next(store) == nil then
    self:Print("No saved templates.")
    return
  end

  for tname, _ in pairs(store) do
    self:Printf(" - '%s'", tname)
  end

  return
end

function AddOnTemplates:Load(input)
  local current = self:getAddOns()

  local store = AddOnTemplatesStore
  if store == nil or next(store) == nil then
    self:Print("No saved templates.")
    return
  end

  local requested = store[input]
  if not requested then
    self:Print("ERROR Unknown template.")
    self:Print(" ")
    self:ShowAll()
  end

  if current == requested then
    self:Print("Requested templates is the same as current state.")
    return
  end

  self:Print("DisableAllAddOns()")
  DisableAllAddOns()
  for _, addon in ipairs(requested) do
    EnableAddOn(addon)
  end

  self:Printf("Loaded: '%s': %s", input, table.concat(requested, ", "))
  self:ReloadUI()

  return
end

function AddOnTemplates:getAddOns()
  local addons = {}

  for i=1, GetNumAddOns(), 1 do
    local name, _, _, loadable, _, _, _ = GetAddOnInfo(i)
    local state = GetAddOnEnableState(nil, name)
    if state > 0 or loadable then
      table.insert(addons, name)
    end
  end

  return addons
end

function AddOnTemplates:AddOns()
  self:Print("Enabled AddOns:")
  for _, addon in ipairs(self:getAddOns()) do
    self:Printf(" - %s", addon)
  end

  self:Print(" ")
  self:Print("Go to Game Menu > AddOns to enable additional AddOns.")
end

function AddOnTemplates:saveAddOnTemplate(template, addons)
  if not AddOnTemplatesStore then
    AddOnTemplatesStore = { [template] = addons }
  else
    AddOnTemplatesStore[template] = addons
  end

  return
end

function AddOnTemplates:Save(input)
  self:saveAddOnTemplate(input, self:getAddOns())

  self:Printf("Saved \"%s\": %s", input, table.concat(AddOnTemplatesStore[input], ", "))

  return
end

function AddOnTemplates:deleteTemplate(input)
  local store = AddOnTemplatesStore
  AddOnTemplatesStore = nil
  local removed = false
  for template, addons in pairs(store) do
    if template == input then
      removed = true
      self:Printf("Removed template \"%s\"", input)
    else
      self:saveAddOnTemplate(template, addons)
    end
  end

  return removed
end

function AddOnTemplates:Delete(input)
  local requested = AddOnTemplatesStore[input]
  if not requested then
    self:Print("ERROR Unknown template.")
    self:Print(" ")
    self:ShowAll()
  end

  local removed = self:deleteTemplate(input)

  self:Print(" ")
  if removed then
    self:ShowAll()
  else
    self:Printf("No templates were removed.")
  end

  return
end
