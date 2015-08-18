-------------------------------------------------------------------------------
-- Chat logger main file
--
-- Record all commands on the server console and user's game console
-- http://forum.mc-server.org/showthread.php?tid=2085
-------------------------------------------------------------------------------
-- History
--[[

v.2015081802
  - Register commands into MCServer

v.2015081801
  - Add more security. SQL injection.

v.2015081701
  - First release.


Future:
  - Show records in database

--]]
-------------------------------------------------------------------------------

PLUGIN = nil
LOG_DB = nil

-------------------------------------------------------------------------------

function Initialize(Plugin)
  Plugin:SetName("Logger")
  Plugin:SetVersion(2015081802)

  PLUGIN = Plugin

  LOG("Logger: Begin " .. Plugin:GetName() .. " initialize...")

  -- Setup hooks
  cPluginManager.AddHook(cPluginManager.HOOK_CHAT, OnMessageSend)
  cPluginManager:AddHook(cPluginManager.HOOK_EXECUTE_COMMAND, MyOnExecuteCommand);

  -- Load the InfoReg shared library:
  dofile(cPluginManager:GetPluginsPath() .. "/InfoReg.lua")

  -- Bind all the console commands:
  RegisterPluginInfoConsoleCommands()

  -- Create or open database
  LOG("Logger: Open database logger.sqlite3...")
  LOG_DB = sqlite3.open("logger.sqlite3")

  LOG("Logger: Create database if not exists")
  create_database()

  -- Nice message :)
  LOG("Logger: Initialized " .. Plugin:GetName() .. " v." .. Plugin:GetVersion())

  return true
end

-------------------------------------------------------------------------------

function OnDisable()

 LOG(PLUGIN:GetName() .. " is shutting down...")

end

-------------------------------------------------------------------------------

function OnMessageSend(Player, Message)
 -- Player:GetName()
 -- Player:GetIP()
 -- Message

  local stmt = LOG_DB:prepare("INSERT INTO data (login, message, date) VALUES (?, ?, ?)")
  local ret = stmt:bind_values(Player:GetName(), Message, os.time())

  if ret ~= 0 then
    LOG("Logger: Can\'t execute stmt:bind_values. Error code :" .. ret)
    return 1
  end

  ret = stmt:step()
  if ret ~= 0 and ret ~=101 then
    LOG("Logger: Can\'t execute stmt:step(). Error code :" .. ret)
    return 1
  end

  ret = stmt:finalize()
  if ret ~= 0 then
    LOG("Logger: Can\'t execute stmt:finalize(). Error code :" .. ret)
    return 1
  end
end

-------------------------------------------------------------------------------

function create_database()
 -- Check is it database exists. If not - create it
 sql=[=[
  CREATE TABLE IF NOT EXISTS data(login text, message text, date integer);
 ]=]

 LOG_DB:exec(sql)
end

-------------------------------------------------------------------------------

function MyOnExecuteCommand(Player, CommandSplit, EntireCommand)
-- Loggining server console commands

 -- If Player is nil (null) - create custom class. It's console data. Always nil
 if not Player then
  Player = {}
  function Player:GetName()
   return "Server console"
  end
 end

  OnMessageSend(Player, EntireCommand)

  return false
end

-------------------------------------------------------------------------------

function sql_result_process(udata, cols, values, names)
-- Create nice string for SQL record

 LOG("Database records count: " .. values[1])

 return true
end

-------------------------------------------------------------------------------

function  HandleConsoleDBCount()
-- Database records count

  LOG_DB:exec("SELECT count(*) from data;", sql_result_process)

  return true
end

-------------------------------------------------------------------------------

function HandleConsoleDBClean()
-- Delete all database records

  LOG_DB:exec("DELETE from data;")

  HandleConsoleDBCount()

  return true
end

-------------------------------------------------------------------------------
