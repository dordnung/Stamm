#if defined _stamm_included
  #endinput
#endif
#define _stamm_included





/**
 * Max. levels supported by Stamm
 */
#define STAMM_MAX_LEVELS 100

/**
 * Max. features supported by Stamm
 */
#define STAMM_MAX_FEATURES 100








/**
 * Return of function STAMM_GetGame()
 */
enum StammGame
{
	GameOTHER = 0,
	GameCSS,
	GameCSGO,
	GameTF2,
	GameDOD
};


/**
 * Return of function STAMM_GetType()
 */
enum StammType
{
	KILLS = 1,
	ROUNDS,
	TIME,
	KILLS_ROUNDS,
	KILLS_TIME,
	ROUNDS_TIME,
	KILLS_ROUNDS_TIME
};







/**
 * Executes when your feature is loaded by Stamm
 *
 * @param basename 		Basename of your feature.
 */
forward STAMM_OnFeatureLoaded(String:basename[]);


/**
 * Executes when a player becomes VIP
 *
 * @param client		Client.
 */
forward STAMM_OnClientBecomeVip(client);


/**
 * Executes when Stamm is fully loaded
 */
forward STAMM_OnReady();


/**
 * Executes when a player is fully initialized by Stamm after connecting
 *
 * @param client		Client.
 */
forward STAMM_OnClientReady(client);


/**
 * Executes when a player is saved
 *
 * @param client		Client.
 */
forward STAMM_OnSaveClient(client);


/**
 * Executes when a player switched your feature on or off
 *
 * @param client		Client.
 * @param mode			true = Switched on, false = Switched off.
 */
forward STAMM_OnClientChangedFeature(client, bool:mode);


/**
 * Executes when a player gets Stamm points
 *
 * @param client		Client.
 * @param number		The number of points, the player get.
 */
forward STAMM_OnClientGetPoints(client, number);


/**
 * Executes before a player get Stamm points
 *
 * @param client		Client.
 * @param number		The number of points the player get.
 * @return  			Plugin_Continue, Plugin_Changed to give points, anything else to prevent it.
 */
forward Action:STAMM_OnClientGetPoints_PRE(client, &number);


/**
 * Executes when Happy Hour starts
 *
 * @param time			Runtime in seconds.
 * @param factor		Factor.
 */
forward STAMM_OnHappyHourStart(time, factor);


/**
 * Executes when Happy Hour ends.
 *
 */
forward STAMM_OnHappyHourEnd();






/**
 * Registers a new Stamm Feature
 *
 * @param name			Short Name of the Plugin.
 * @param description	Feature description.
 * @param allowChange	true = Player can switch Feature on/off, false = he can't
 * @param standard		true = Plugin is standardly enabled, false = Player have to enable it first.
 * @noreturn
 * @error            	Max features reached.
 */
native STAMM_AddFeature(String:name[], String:description[] = "", bool:allowChange=true, bool:standard=true);


/**
 * Adds information about what a player get on a specific level with this feature (will be shown in the !sme list)
 *
 * @param level			The level, 0=No VIP, x=Level
 * @param description	What a player get on this level.
 * @return				true = success, false = error.
 */
native bool:STAMM_AddFeatureText(level, String:description[]);


/**
 * Returns whether the basename is the basename of your plugin
 *
 * @param basename		Basename to look for.
 * @return				true = your feature, false = other feature.
 */
native bool:STAMM_IsMyFeature(String:basename[]);


/**
 * Returns the basename for your plugin
 *
 * @param basename		String to store basename in.
 * @param size			Size of the basename.
 * @noreturn
 */
native STAMM_GetBasename(String:basename[], size);


/**
 * Returns the level a block needs
 *
 * @param block			Block to search for.
 * @return 				The level.
 */
native STAMM_GetLevel(block=1);


/**
 * Returns the number of a block by name
 *
 * @param name 			The name.
 * @return 				The block number.
 */
native STAMM_GetBlockOfName(String:name[]);


/**
 * Returns the number of blocks found in LevelSettings
 *
 * @return 				Number of blocks.
 */
native STAMM_GetBlockCount();


/**
 * Returns the highest block a client is in
 *
 * @param client		Client.
 * @return				0 = no block, x = block.
 */
native STAMM_GetClientBlock(client);


/**
 * Returns the level of a client
 *
 * @param client		Client.
 * @return				-1=invalid client, 0=no VIP, x=Level
 */
native STAMM_GetClientLevel(client);


/**
 * Returns the points of a player
 *
 * @param client		Client.
 * @return				Points of player or -1 on error.
 */
native STAMM_GetClientPoints(client);


/**
 * Returns the name of a specific Level
 *
 * @param level			x = Level.
 * @param name			String to save name in.
 * @param maxlength		Maxlength of string.
 * @return				False on error, true on success.
 */
native bool:STAMM_GetLevelName(level, String:name[], maxlength);


/**
 * Returns whether the level is a private level or not
 *
 * @param level			x = Level.
 * @return				True=pivate, false=point based.
 */
native bool:STAMM_IsLevelPrivate(level);


/**
 * Returns the level number of a specific level name
 *
 * @param name			Name of the level.
 * @return				0 = not found, x = level number.
 */
native STAMM_GetLevelNumber(String:name[]);


/**
 * Returns how much points a player need for a specific Level
 *
 * @param level			x = Level.
 * @return				How much points a client need, or -1 on error.
 */
native STAMM_GetLevelPoints(level);


/**
 * Returns how much levels are set
 *
 * @return				How much levels are set.
 */
native STAMM_GetLevelCount();


/**
 * Returns how to get points
 *
 * @return					KILLS, ROUNDS, TIME, KILLS_ROUNDS, KILLS_TIME, ROUNDS_TIME, KILLS_ROUNDS_TIME
 */
native StammType:STAMM_GetType();


/**
 * Returns the game Stamm is running on
 *
 * @return					GameOTHER, GameCSS, GameCSGO, GameTF2, GameDOD
 */
native StammGame:STAMM_GetGame();


/**
 * Returns whether the server admin want auto updates for Stamm
 *
 * @return					True if he want, false otherwise.
 */
native bool:STAMM_AutoUpdate();


/**
 * Adds points to a player
 *
 * @param client		Client.
 * @param number		Number of points to add.
 * @return				true = Success, false = fail.
 */
native bool:STAMM_AddClientPoints(client, number);


/**
 * Deletes points from a player
 *
 * @param client		Client.
 * @param number		Number of points to delete.
 * @return				true = Success, false = Fail.
 */
native bool:STAMM_DelClientPoints(client, number);


/**
 * Sets points of a player
 *
 * @param client		Client.
 * @param number		Number of points to set.
 * @return				true = Success, false = Fail.
 */
native bool:STAMM_SetClientPoints(client, number);


/**
 * Returns true when the specific player is VIP, otherwise false
 *
 * @param client		Client.
 * @param type			x = Level.
 * @param min			true = Minimum rang, false = Exact Rang.
 * @return				true if Client is VIP, otherwise false.
 */
native bool:STAMM_IsClientVip(client, type, bool:min=true);


/**
 * Returns true when the clients level is high enough for your feature and wants it.
 *
 * @param client		Client.
 * @return				true if client have feature, otherwise false.
 */
native bool:STAMM_HaveClientFeature(client, block=1);


/**
 * Returns true when the specific player is completely loaded by Stamm, otherwise false
 *
 * @param client		Client.
 * @return				true if fully loaded, otherwise false.
 */
native bool:STAMM_IsClientValid(client);


/**
 * Returns true when the specific player is a Stamm admin, otherwise false
 *
 * @param client		Client.
 * @return				true if admin, otherwise false.
 */
native bool:STAMM_IsClientAdmin(client);


/**
 * Returns true when the specific player enabled this feature, false otherwise
 *
 * @param client		Client.
 * @return				true if the player enabled it, otherwise false.
 */
native bool:STAMM_WantClientFeature(client);


/**
 * Returns true when Stamm is fully loaded.
 *
 * @return				true if fully loaded, otherwise false.
 */
native bool:STAMM_IsLoaded();


/**
 * Starts Happy Hour
 *
 * @param time			Time in minutes (> 1).
 * @param factor		Factor.
 * @return				false = Happy Hour already on, true = success.
 * @error				Time, factor invalid.
 */
native bool:STAMM_StartHappyHour(time, factor);


/**
 * Ends Happy Hour
 *
 * @return				false = Happy Hour already off, true = success.
 */
native bool:STAMM_EndHappyHour();


/**
 * Loads a Stamm Feature
 *
 * @param plugin		Handle of the plugin.
 * @return				-1 = already loaded, 0 = no such Feature, 1 = success.
 */
native STAMM_LoadFeature(Handle:plugin);


/**
 * Unloads a Stamm Feature
 *
 * @param plugin		Handle of the plugin.
 * @return				-1 = already unloaded, 0 = no such Feature, 1 = success.
 */
native STAMM_UnloadFeature(Handle:plugin);


/**
 * Logs a Message to the Stamm Log File
 *
 * @param debug		  Write to debug, or normal log file.
 * @param fmt         Format string.
 * @param ...         Format arguments.
 *
 * @noreturn
 */
native STAMM_WriteToLog(bool:debug, const String:fmt[], any:...);





/**
 * Loads the translation file of your feature in stamm/languages
 *
 * @noreturn
 */
stock STAMM_LoadTranslation()
{
	decl String:basename[64];
	
	
	STAMM_GetBasename(basename, sizeof(basename));
	

	Format(basename, sizeof(basename), "stamm/%s", basename);
	
	LoadTranslations(basename);
}







public SharedPlugin:__pl_stamm = 
{
	name = "stamm",
	file = "stamm.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN




public __pl_stamm_SetNTVOptional()
{
	MarkNativeAsOptional("STAMM_AddFeature");
	MarkNativeAsOptional("STAMM_AddFeatureText");
	MarkNativeAsOptional("STAMM_IsMyFeature");
	MarkNativeAsOptional("STAMM_GetLevel");
	MarkNativeAsOptional("STAMM_GetBlockCount");
	MarkNativeAsOptional("STAMM_GetBasename");
	MarkNativeAsOptional("STAMM_GetClientPoints");
	MarkNativeAsOptional("STAMM_GetClientLevel");
	MarkNativeAsOptional("STAMM_GetLevelName");
	MarkNativeAsOptional("STAMM_IsLevelPrivate");
	MarkNativeAsOptional("STAMM_GetLevelNumber");
	MarkNativeAsOptional("STAMM_GetLevelPoints");
	MarkNativeAsOptional("STAMM_GetLevelCount");
	MarkNativeAsOptional("STAMM_GetType");
	MarkNativeAsOptional("STAMM_GetGame");
	MarkNativeAsOptional("STAMM_GetClientBlock");
	MarkNativeAsOptional("STAMM_AddClientPoints");
	MarkNativeAsOptional("STAMM_DelClientPoints");
	MarkNativeAsOptional("STAMM_SetClientPoints");
	MarkNativeAsOptional("STAMM_HaveClientFeature");
	MarkNativeAsOptional("STAMM_IsClientVip");
	MarkNativeAsOptional("STAMM_IsClientValid");
	MarkNativeAsOptional("STAMM_IsClientAdmin");
	MarkNativeAsOptional("STAMM_IsLoaded");
	MarkNativeAsOptional("STAMM_WantClientFeature");
	MarkNativeAsOptional("STAMM_StartHappyHour");
	MarkNativeAsOptional("STAMM_EndHappyHour");
	MarkNativeAsOptional("STAMM_LoadFeature");
	MarkNativeAsOptional("STAMM_UnloadFeature");
	MarkNativeAsOptional("STAMM_WriteToLog");
	MarkNativeAsOptional("STAMM_AutoUpdate");
}
#endif