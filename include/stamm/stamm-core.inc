#if defined _stamm_core_included
  #endinput
#endif
#define _stamm_core_included





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
 * Executes when Stamm is fully loaded
 */
forward STAMM_OnReady();


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
 * @error				Time or factor invalid.
 */
native bool:STAMM_StartHappyHour(time, factor);


/**
 * Ends Happy Hour
 *
 * @return				false = Happy Hour already off, true = success.
 */
native bool:STAMM_EndHappyHour();


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
 * Gets the Stamm Chat Tag
 *
 * @param tag			String to save tag in.
 * @param maxlength		Maxlength of string.
 *
 * @noreturn
 */
native STAMM_GetTag(String:tag[], maxlength);


/**
 * Adds a new command to the command list
 *
 * @param command		The command to add.
 * @param name			Name of the command.
 * @param ...         	Name Format arguments.
 * @error				Max Commands reached.
 *
 * @noreturn
 */
native STAMM_AddCommand(const String:command[], const String:name[], any:...);







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
		MarkNativeAsOptional("STAMM_AddBlockDescription");
		MarkNativeAsOptional("STAMM_IsMyFeature");
		MarkNativeAsOptional("STAMM_GetLevel");
		MarkNativeAsOptional("STAMM_GetPoints");
		MarkNativeAsOptional("STAMM_IsShop");
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
		MarkNativeAsOptional("STAMM_GetTag");
	}
#endif