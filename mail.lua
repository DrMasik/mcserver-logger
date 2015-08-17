-------------------------------------------------------------------------------
-- Chat logger main file
--
-- Record all commands on the server console and user's game console
-------------------------------------------------------------------------------

PLUGIN = nil
LOG_DB = nil

-------------------------------------------------------------------------------

function Initialize(Plugin)
 Plugin:SetName("Logger")
 Plugin:SetVersion(2015081701)

 PLUGIN = Plugin

 LOG("Logger: Begin " .. Plugin:GetName() .. " initialize...")

 -- Setup hooks
 cPluginManager.AddHook(cPluginManager.HOOK_CHAT, OnMessageSend)
 cPluginManager:AddHook(cPluginManager.HOOK_EXECUTE_COMMAND, MyOnExecuteCommand);

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

 sql="INSERT INTO data VALUES('".. Player:GetName() .. "', '" .. Message .. "', " .. os.time() .. ");"

 LOG_DB:exec(sql)
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
-- Loggining user's command line in game
-- Loggining server console commands
-- Add new commands into server console or log it

 help_string=[[


  logger count - show count of database records
  logger backup - create backup file
  logger clean - clean database data. Not settings. Do not create backup file
  logger shrink - rename current database file and create new
 ]]

 -- If Player is nil (null) - create custom class. It's console data
 if not Player then
  Player = {}
  function Player:GetName()
   return "Server console"
  end
 end

 -- Check exists commands
 if EntireCommand == "logger count" then
  LOG_DB:exec("SELECT count(*) from data;", sql_result_process)

 elseif EntireCommand == "logger clean" then
  LOG_DB:exec("DELETE from data;")

 elseif EntireCommand == "logger backup" or EntireCommand == "logger shrink" then
  LOG("Logger: Under cunstruction :)")

 elseif EntireCommand == "logger" or EntireCommand == "logger help" then
  LOG(help_string)

 else
  -- Unknown command for logger. Log it
  LOG("Logger: Save console command")
  OnMessageSend(Player, EntireCommand)

 end

 return true
end

-------------------------------------------------------------------------------

function sql_result_process(udata, cols, values, names)
-- Create nice string for SQL record

 LOG("Database records count: " .. values[1])

 return 0
end

-------------------------------------------------------------------------------
