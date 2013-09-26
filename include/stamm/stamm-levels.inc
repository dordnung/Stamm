#if defined _stamm_levels_included
  #endinput
#endif
#define _stamm_levels_included





/**
 * Max. features supported by Stamm.
 */
#define STAMM_MAX_FEATURES 100





/**
 * Returns the name of a specific Level.
 *
 * @param level			x = Level.
 * @param name			String to save name in.
 * @param maxlength		Maxlength of string.
 * @return				False on error, true on success.
 * @error 				Level is invalid.
 */
native bool:STAMM_GetLevelName(level, String:name[], maxlength);


/**
 * Returns whether the level is a private level or not.
 *
 * @param level			x = Level.
 * @return				True=pivate, false=point based.
 * @error 				Level is invalid.
 */
native bool:STAMM_IsLevelPrivate(level);


/**
 * Returns the level number of a specific level name.
 *
 * @param name			Name of the level.
 * @return				0 = not found, x = level number.
 */
native STAMM_GetLevelNumber(const String:name[]);


/**
 * Returns how much points a player need for a specific Level.
 *
 * @param level			x = Level.
 * @return				How much points a client need, or -1 on error.
 * @error 				Level is invalid.
 */
native STAMM_GetLevelPoints(level);


/**
 * Returns how much levels are set.
 *
 * @return				How much levels are set.
 */
native STAMM_GetLevelCount();