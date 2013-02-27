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
#define STAMM_MAX_FEATURES 120

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
 * Executes when your feature is loaded by stamm
 *
 * @param level			Level needed for your feature.
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
 * Executes when a player gets Stamm Points
 *
 * @param client		Client.
 * @param number		The number of points, the player gets.
 */
forward STAMM_OnClientGetPoints(client, number);

/**
 * Executes before a player gets Stamm Points (Only for added features)
 *
 * @param client		Client.
 * @param number		The number of points, the player gets.
 * @return  			Plugin_Continue, Plugin_Changed to give points, anything else to prevent it.
 */
forward Action:STAMM_OnClientGetPoints_PRE(client, &number);

/**
 * Executes when Happy Hour starts
 *
 * @param time			runtime in seconds 
 * @param factor		factor.
 */
forward STAMM_OnHappyHourStart(time, factor);

/**
 * Executes when Happy Hour ends
 *
 */
forward STAMM_OnHappyHourEnd();

/**
 * Adds a new Stamm Feature
 *
 * @param name			Short Name of the Plugin.
 * @param description	What Feature it is (this will be added on the Feature list, so start with: VIP's get... or similar and add it to the stamm-feature Phrase!).
 * @param allowChange	true = Player can switch Feature on/off, false = he can't
 * @param standard		true = Plugin is standardly enabled, false = Player has to enable it first.
 * @noreturn
 */
native STAMM_AddFeature(String:name[], String:description[], bool:allowChange=true, bool:standard=true);

/**
 * Adds information about what a player gets on a specific level with this feature (will be shown in the !sme list)
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
 * Returns the basename for your Plugin
 *
 * @param basename		String to store basename in.
 * @param size			Size of the basename.
 * @noreturn
 */
native STAMM_GetBasename(String:basename[], size);

/**
 * Returns the level a block needs in this Feature
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
 * @return 				The blocks.
 */
native STAMM_GetBlockCount();

/**
 * Return the Number of a clients level
 *
 * @param client		Client.
 * @return				-1=invalid client, 0=no VIP, x=Level
 */
native STAMM_GetClientLevel(client);

/**
 * Return the Number of Points of a player
 *
 * @param client		Client.
 * @return				Points of Player or -1 on error.
 */
native STAMM_GetClientPoints(client);

/**
 * Return the name of a specific Level
 *
 * @param level			x = Level.
 * @param name			String to save name in
 * @param maxlength		maxlength of string
 * @return				false on error, true on success
 */
native bool:STAMM_GetLevelName(level, String:name[], maxlength);

/**
 * Return whether the level is private or not
 *
 * @param level			x = Level.
 * @return				true=pivate, false=point based
 */
native STAMM_IsLevelPrivate(level);

/**
 * Return the number of a specific Level
 *
 * @param name			Name of the level.
 * @return				0 = not found, x = level number.
 */
native STAMM_GetLevelNumber(String:name[]);

/**
 * Return how much Points a player need for a specific Level
 *
 * @param level			x = Level.
 * @return				How much Points a Client needs, or -1 on Error.
 */
native STAMM_GetLevelPoints(level);

/**
 * Return how much levels are set
 *
 * @return				How much levels are set
 */
native STAMM_GetLevelCount();

/**
 * Return how to get Points
 *
 * @return					KILLS, ROUNDS, TIME, KILLS_ROUNDS, KILLS_TIME, ROUNDS_TIME, KILLS_ROUNDS_TIME
 */
native StammType:STAMM_GetType();

/**
 * Return the game stamm is running on
 *
 * @return					GameOTHER, GameCSS, GameCSGO, GameTF2, GameDOD
 */
native StammGame:STAMM_GetGame();

/**
 * Add Points to a player
 *
 * @param client		Client.
 * @param number		Number of Points to add.
 * @return				true = Success, false = Fail
 */
native bool:STAMM_AddClientPoints(client, number);

/**
 * Delete Points from a player
 *
 * @param client		Client.
 * @param number		Number of Points to delete.
 * @return				true = Success, false = Fail
 */
native bool:STAMM_DelClientPoints(client, number);

/**
 * Set Points of a player
 *
 * @param client		Client.
 * @param number		Number of Points to set.
 * @return				true = Success, false = Fail
 */
native bool:STAMM_SetClientPoints(client, number);

/**
 * Return true when the specific player is VIP, otherwise false
 *
 * @param client		Client.
 * @param type			x = Level.
 * @param min			true = Minimum rang, false = Exact Rang.
 * @return				true if Client is VIP, otherwise false.
 */
native bool:STAMM_IsClientVip(client, type, bool:min=true);

/**
 * Return true when the clients level is high enough for the feature and wants it.
 *
 * @param client		Client.
 * @return				true if allowed, otherwise false.
 */
native bool:STAMM_HaveClientFeature(client, block=1);

/**
 * Return true when the specific player is complete loaded by Stamm, otherwise false
 *
 * @param client		Client.
 * @return				true if fully loaded, otherwise false.
 */
native bool:STAMM_IsClientValid(client);

/**
 * Return true when the specific player is a Stamm admin, otherwise false
 *
 * @param client		Client.
 * @return				true if admin, otherwise false.
 */
native bool:STAMM_IsClientAdmin(client);

/**
 * Return true when the specific player enabled this feature, false otherwise
 *
 * @param client		Client.
 * @return				true if the player wants, otherwise false.
 */
native bool:STAMM_WantClientFeature(client);

/**
 * Return true when stamm is fully loaded.
 *
 * @return				true if yes, otherwise false.
 */
native bool:STAMM_IsLoaded();

/**
 * Starts Happy Hour
 *
 * @param time			Time in minutes (> 1).
 * @param factor		factor.
 * @return				false = Happy Hour already on, true = success.
 * @error				time, factor invalid.
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
 * @return				-1 = already loaded, 0 = no such Feature, 1 = success
 */
native STAMM_LoadFeature(Handle:plugin);

/**
 * Unloads a Stamm Feature
 *
 * @param plugin		Handle of the plugin.
 * @return				-1 = already unloaded, 0 = no such Feature, 1 = success
 */
native STAMM_UnloadFeature(Handle:plugin);

/**
 * Logs a Message to the Stamm Log File
 *
 * @param debug		  Write to debug, or normal log file
 * @param fmt         Format string.
 * @param ...         Format arguments.
 *
 * @noreturn
 */
native STAMM_WriteToLog(bool:debug, const String:fmt[], any:...);

/**
 * Load the translation file of your feature in stamm/languages
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
}
#endif
