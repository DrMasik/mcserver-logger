-------------------------------------------------------------------------------
-- Chat logger main file
--
-- Record all commands on the server console and user's game console
-- http://forum.mc-server.org/showthread.php?tid=2085
-------------------------------------------------------------------------------
-- History
--[[

v.2015081902
  - Add index login and login_date                                                                                                                      

v.2015081901
  - Show records in database

v.2015081802
  - Register commands into MCServer

v.2015081801
  - Add more security. SQL injection.

v.2015081701
  - First release.


Future:
  - Your suggestions

--]]
-------------------------------------------------------------------------------

PLUGIN = nil
LOG_DB = nil

-------------------------------------------------------------------------------

function Initialize(Plugin)
  Plugin:SetName("Logger")
  Plugin:SetVersion(2015081902)
 
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
  CREATE INDEX IF NOT EXISTS data_login on data(login);
  CREATE INDEX IF NOT EXISTS data_login_date on data(login, date); 
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

  -- Server console message
 LOG("Database records count: " .. values[1])
 
 return true, "Database records count: " .. values[1]
end

-------------------------------------------------------------------------------

function HandleConsoleDBCount()
-- Database records count

  LOG_DB:exec("SELECT count(*) from data;", sql_result_process)

  return true
end

-------------------------------------------------------------------------------

function HandleConsoleDBClean()
-- Delete all database records

  LOG_DB:exec("DELETE FROM data;")

  HandleConsoleDBCount()

  return true, "The database is cleared"
end

-------------------------------------------------------------------------------

function HandleConsoleDBShow(Split)
-- Show database record

  local split_count = 0
  local ret_rows_count = ";"
  local rcon_output = ""

  -- The number of params
  for i in pairs(Split) do
    split_count = split_count + 1
  end

  -- The number of output lines
  if split_count > 2 then
    if tonumber(Split[3]) ~= nil then
      ret_rows_count = " LIMIT " .. math.floor(Split[3]) .. ";"
    end
  end

  -- Display the database
  for row in LOG_DB:nrows("SELECT date, login, message from data order by date desc" .. ret_rows_count) do
    tmp_str = row.date .. " | " .. row.login .. " | " .. row.message
    print (tmp_str)                                                                                                                                     

    -- Create string for RCON
    rcon_output = rcon_output .. tmp_str .. "\n"
  end

  return true, rcon_output
end

-------------------------------------------------------------------------------
