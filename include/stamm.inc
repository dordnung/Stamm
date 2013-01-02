#if defined _stamm_included
  #endinput
#endif
#define _stamm_included

/**
 * Max. levels supported by Stamm
 */
#define MAX_STAMM_LEVELS 100

/**
 * Max. features supported by Stamm
 */
#define MAX_STAMM_FEATURES 120

/**
 * Return of function getStammGame()
 */
enum StammGame
{
	GameOTHER = 0,
	GameCSS,
	GameCSGO,
	GameTF2
};

/**
 * Return of function getStammType()
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
 * Executes when a player becomes VIP
 *
 * @param client		Client.
 */
forward OnClientBecomeVip(client);

/**
 * Executes when Stamm is fully loaded
 */
forward OnStammReady();

/**
 * Executes when a player is fully initialized by Stamm after connecting
 *
 * @param client		Client.
 */
forward OnStammClientReady(client);

/**
 * Executes when a player is saved
 *
 * @param client		Client.
 */
forward OnStammSaveClient(client);

/**
 * Executes when a player switched a Feature on/off
 *
 * @param client		Client.
 * @param basename		Basename of the Feature he changed.
 * @param mode			1 = Switched on, 0 = Switched off.
 */
forward OnClientChangeStammFeature(client, String:basename[], mode);

/**
 * Executes when a player gets Stamm Points
 *
 * @param client		Client.
 * @param number		The number of points, the player gets.
 */
forward OnClientGetStammPoints(client, number);

/**
 * Executes when Happy Hour starts
 *
 * @param time			runtime in seconds 
 * @param factor		factor.
 */
forward OnHappyHourStart(time, factor);

/**
 * Executes when Happy Hour ends
 *
 */
forward OnHappyHourEnd();


/**
 * Adds a new Stamm Feature
 *
 * @param basename		Your Plugin basename, without .smx.
 * @param name			Short Name of the Plugin.
 * @param description	What Feature it is (this will be added on the Feature list, so start with: VIP's get... or similar and add it to the stamm-feature Phrase!).
 * @param allowChange	true = Player can switch Feature on/off, false = he can't
 * @return				level need for this Feature, -1 = fail, x = level
 */
native AddStammFeature(String:basename[], String:name[], String:description[], bool:allowChange=true);

/**
 * Adds information about what a player get on his level with this feature (will be shown in the !sme list)
 *
 * @param basename		Your Plugin basename, without .smx.
 * @param level			The level, 0=No VIP, x=Level
 * @param description	What a player get on this level.
 * @return				1=success, 0=error.
 */
native AddStammFeatureInfo(String:basename[], level, String:description[]);

/**
 * Return the Number of a clients level
 *
 * @param client		Client.
 * @return				-1=invalid client, 0=no VIP, x=Level
 */
native GetClientStammLevel(client);

/**
 * Return the Number of Points of a player
 *
 * @param client		Client.
 * @return				Points of Player or -1 on error.
 */
native GetClientStammPoints(client);

/**
 * Return the name of a specific Level
 *
 * @param level			x = Level.
 * @param name			String to save name in
 * @param maxlength		maxlength of string
 * @return				0 on error, 1 on success
 */
native GetStammLevelName(level, String:name[], maxlength);

/**
 * Return the number of a specific Level
 *
 * @param name			Name of the level.
 * @return				0 = not found, x = level number.
 */
native GetStammLevelNumber(String:name[]);

/**
 * Return how much Points a player need for a specific Level
 *
 * @param level			x = Level.
 * @return				How much Points a Client needs, or -1 on Error.
 */
native GetStammLevelPoints(level);

/**
 * Return how much levels are set
 *
 * @return				How much levels are set
 */
native GetStammLevelCount();

/**
 * Return how to get Points
 *
 * @return					KILLS, ROUNDS, TIME, KILLS_ROUNDS, KILLS_TIME, ROUNDS_TIME, KILLS_ROUNDS_TIME
 */
native StammType:GetStammType();

/**
 * Return the game stamm is running on
 *
 * @return					GameOTHER, GameCSS, GameCSGO, GameTF2
 */
native StammGame:GetStammGame();

/**
 * Set Points of a player
 *
 * @param client		Client.
 * @param number		Number of Points to set.
 * @noreturn
 * @return				1 = Success, 0 = Fail
 */
native SetClientStammPoints(client, number);

/**
 * Add Points to a player
 *
 * @param client		Client.
 * @param number		Number of Points to add.
 * @noreturn
 * @return				1 = Success, 0 = Fail
 */
native AddClientStammPoints(client, number);

/**
 * Delete Points from a player
 *
 * @param client		Client.
 * @param number		Number of Points to delete.
 * @return				1 = Success, 0 = Fail
 */
native DelClientStammPoints(client, number);

/**
 * Return true when the specific player is VIP, otherwise false
 *
 * @param client		Client.
 * @param type			x = Level.
 * @param min			true = Minimum rang, false = Exact Rang.
 * @return				true if Client is VIP, otherwise false.
 */
native bool:IsClientVip(client, type, bool:min=true);

/**
 * Return true when the specific player is complete loaded by Stamm, otherwise false
 *
 * @param client		Client.
 * @return				true if fully loaded, otherwise false.
 */
native bool:IsStammClientValid(client);

/**
 * Return true when the specific player is a Stamm admin, otherwise false
 *
 * @param client		Client.
 * @return				true if admin, otherwise false.
 */
native bool:IsClientStammAdmin(client);

/**
 * Return true when the specific player enabled this feature, false otherwise
 *
 * @param client		Client.
 * @param basename		Your Plugin Basename.
 * @return				true if the player wants, otherwise false.
 */
native bool:ClientWantStammFeature(client, String:basename[]);

/**
 * Starts Happy Hour
 *
 * @param time			Time in minutes (> 1).
 * @param factor		factor.
 * @return				0 = Happy Hour already on, 1 = success.
 * @error				time, factor invalid.
 */
native StartHappyHour(time, factor);

/**
 * Ends Happy Hour
 *
 * @return				0 = Happy Hour already off, 1 = success.
 */
native EndHappyHour();

/**
 * Loads a Stamm Feature
 *
 * @param basename		Basename of the Feature
 * @return				-1 = already loaded, 0 = no such Feature, 1 = success
 */
native LoadFeature(String:basename[]);

/**
 * Unloads a Stamm Feature
 *
 * @param basename		Basename of the Feature
 * @return				-1 = already unloaded, 0 = no such Feature, 1 = success
 */
native UnloadFeature(String:basename[]);

/**
 * Logs a Message to the Stamm Log File
 *
 * @param fmt         Format string.
 * @param ...         Format arguments.
 *
 * @noreturn
 */
native WriteToStammLog(const String:fmt[], any:...);

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
	MarkNativeAsOptional("AddStammFeature");
	MarkNativeAsOptional("AddStammFeatureInfo");
	MarkNativeAsOptional("GetClientStammPoints");
	MarkNativeAsOptional("GetClientStammLevel");
	MarkNativeAsOptional("GetStammLevelName");
	MarkNativeAsOptional("GetStammLevelNumber");
	MarkNativeAsOptional("GetStammLevelPoints");
	MarkNativeAsOptional("GetStammLevelCount");
	MarkNativeAsOptional("GetStammType");
	MarkNativeAsOptional("GetStammGame");
	MarkNativeAsOptional("SetClientStammPoints");
	MarkNativeAsOptional("AddClientStammPoints");
	MarkNativeAsOptional("DelClientStammPoints");
	MarkNativeAsOptional("IsClientVip");
	MarkNativeAsOptional("IsStammClientValid");
	MarkNativeAsOptional("IsClientStammAdmin");
	MarkNativeAsOptional("ClientWantStammFeature");
	MarkNativeAsOptional("StartHappyHour");
	MarkNativeAsOptional("EndHappyHour");
	MarkNativeAsOptional("LoadFeature");
	MarkNativeAsOptional("UnloadFeature");
	MarkNativeAsOptional("WriteToStammLog");
}
#endif
