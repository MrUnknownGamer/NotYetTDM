--[[ User rights. 

	Everyone can open the logs to view the logs of the previous rounds.

	The default level is 1 if your rank isn't here.
	
	1 and 2 : Can't view logs of the active rounds
	3 : Can view the logs of the active rounds as a spectator
	4 : Can always view the logs of the active ranks
	
	The third argument is the RDM Manager access. Set it to true or false.
]]--

Damagelog:AddUser("superadmin", 4, true)
Damagelog:AddUser("admin", 4, true)
Damagelog:AddUser("operator", 3, false)
Damagelog:AddUser("user", 1, false)
Damagelog:AddUser("guest", 1, false)

-- The F-key

-- Damagelog.Key = KEY_F8
CreateConVar("Damagelog_OpenKey", KEY_F8, {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "The key to be bound to Damagelog")

--[[ Is a message shown when an alive player opens the menu?
	0 : if you want to only show it to superadmins
	1 : to let others see that you have abusive admins
]]--

-- Damagelog.AbuseMessageMode = 1
CreateConVar("Damagelog_AbuseMessageMode", "0", {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Whether a message is shown to others when an alive player opens the Damagelog menu")

-- true to enable the RDM Manager, false to disable it

-- Damagelog.RDM_Manager_Enabled = true
CreateConVar("Damagelog_RDMManagerEnabled", "1", {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Whether the RDM Manager is enabled or not")

-- Command to open the report menu. Don't forget the quotation marks

-- Damagelog.RDM_Manager_Command = "!report"
CreateConVar("Damagelog_RDMReportCommand", "!report", {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "The command to open the report menu")

-- Command to open the respond menu while you're alive

-- Damagelog.Respond_Command = "!respond"
CreateConVar("Damagelog_RDMRespondCommand", "!respond", {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "The command to open the respond menu while being alive")

--[[ Set to true if you want to enable MySQL (it needs to be configured on config/mysqloo.lua)
	Setting it to false will make the logs use SQLite (garrysmod/sv.db)
]]--

-- Damagelog.Use_MySQL = false
CreateConVar("Damagelog_UseMySQL", "0", {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Whether to use MySQL or the bultin SQLite")


-- You can enable every command or no command

--[[ Enables the !aslay and !aslayid command for ULX, designed to work with the logs.
Works like that : !aslay target number_of_slays reason
Example : !aslay tommy228 2 RDMing a traitor
Example : !aslayid STEAM_0:0:1234567 2 RDMing a traitor
]]--

-- Damagelog.Enable_Autoslay = false
CreateConVar("Damagelog_EnableAutoslay", "0", {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Enable the !aslay commands for ULX")

-- Force autoslain players to be innocents (overrides SelectRoles)

-- Damagelog.Autoslay_ForceRole = false
CreateConVar("Damagelog_AutoslayForceRole", "0", {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Force autoslain players to be innocents")


CreateConVar("Damagelog_EnableAutojail", "0", {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Enable the !ajail commands for ULX")

CreateConVar("Damagelog_AutojailForceRespond", "1", {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Forces the jailed player to respond")

CreateConVar("Damagelog_AutojailAutounjail", "1", {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Unjails player after responding. Only works when ForceRespond activated")


CreateConVar("Damagelog_EnableAutokarma", "0", {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Enable the !akarma commands for ULX")


-- Default autoslay reason

-- Can be the default language reason: "Damagelog.DefaultReason"
-- english: "No reason specified"
-- german: "Keinen Grund angegeben"

CreateConVar("Damagelog_DefaultReason", "#Damagelog.DefaultReason", {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "The default reason")


-- The number of days the logs last on the database (to avoid lags when opening the menu)

-- Damagelog.LogDays = 31

CreateConVar("Damagelog_LogDays", 31, {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "The number of days the logs last in the database")