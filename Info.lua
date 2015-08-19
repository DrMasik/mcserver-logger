-------------------------------------------------------------------------------
-- Info.lua
-- Logger
-- http://luaapi.cuberite.org/InfoFile.html
-------------------------------------------------------------------------------

g_PluginInfo = {
        Name = "Logger",
  Version = "2015081901",
        Date = "2015-08-19",
  SourceLocation = "https://github.com/DrMasik/mcserver-logger",
        Description = [[Record all commands on the server console and user's game console.]],

  ConsoleCommands = {
    logger = {
      HelpString = "Execute some of Logger plugin commands",
      Subcommands = {
        count = {
          HelpString = "Database records count",
          Handler = HandleConsoleDBCount,
        },

        clean = {
          HelpString = "Clean database (delete all records).",
          Handler = HandleConsoleDBClean,
        },
        
        show = {
          HelpString = "Show database records, sorted by date in reverse order",
          Handler = HandleConsoleDBShow,
          ParameterCombinations = {
            Params = "count",
            HelpString = "Return last <count> records"
          },
        },
      },
    },
  },
}
