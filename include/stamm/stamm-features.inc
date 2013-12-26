#if defined _stamm_features_included
	#endinput
#endif
#define _stamm_features_included





/**
 * Max. levels supported by Stamm
 */
#define STAMM_MAX_LEVELS 100







/**
 * Executes when your feature is loaded by Stamm.
 * Here you can begin to work with your feature.
 *
 * @param basename      Basename of your feature.
 */
forward STAMM_OnFeatureLoaded(const String:basename[]);







/**
 * Registers a new Stamm Feature.
 *
 * @param name          Short Name of the Feature.
 * @param description   Feature description.
 * @param allowChange   true = Player can switch Feature on/off, false = he can't
 * @param standard      true = Plugin is default enabled, false = Player have to enable it first.
 * @noreturn
 * @error               Max features reached.
 */
native STAMM_AddFeature(const String:name[], const String:description[]="", bool:allowChange=true, bool:standard=true);


/**
 * DEPRECATED! USE STAMM_AddBlockDescription INSTEAD!
 *
 * Adds information about what a player get on a specific level with this feature.
 *
 * @param level         The level, 0=No VIP, x=Level.
 * @param description   What a player get on this level.
 * @return              true = success, false = error.
 * @error               Level or feature is invalid.
 */
#pragma deprecated Use STAMM_AddBlockDescription instead!
native bool:STAMM_AddFeatureText(level, const String:description[]);


/**
 * Returns whether the basename is the basename of your plugin
 *
 * @param basename      Basename to look for.
 * @return              Returns true when the basename is your feature, otherwise false.
 * @error               Feature is invalid.
 */
native bool:STAMM_IsMyFeature(const String:basename[]);


/**
 * Returns the basename of your plugin.
 *
 * @param basename      String to store basename in.
 * @param maxlength     Maxlength of the basename.
 * @noreturn
 * @error               Feature is invalid.
 */
native STAMM_GetBasename(String:basename[], maxlength);


/**
 * Loads a Stamm Feature.
 *
 * @param plugin        Handle of the plugin.
 * @return              -1 = already loaded, 0 = no such Feature, 1 = success.
 */
native STAMM_LoadFeature(Handle:plugin);


/**
 * Unloads a Stamm Feature.
 *
 * @param plugin        Handle of the plugin.
 * @return              -1 = already unloaded, 0 = no such Feature, 1 = success.
 */
native STAMM_UnloadFeature(Handle:plugin);


/**
 * Loads the translation file of your feature in languages/stamm.
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


/**
 * Registers a new Stamm Feature with allowing to change and default enabled.
 *
 * @param name          Short Name of the Feature.
 * @param description   Feature description.
 * @param ...           Description format arguments.
 * @noreturn
 * @error               Max features reached.
 */
stock STAMM_AddFastFeature(const String:name[], const String:description[], any:...)
{
	new String:formatedDescription[256];
	
	VFormat(formatedDescription, sizeof(formatedDescription), description, 3);
 
	STAMM_AddFeature(name, formatedDescription, true, true);
}