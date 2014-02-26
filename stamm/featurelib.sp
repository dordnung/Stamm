/**
 * -----------------------------------------------------
 * File        featurelib.sp
 * Authors     David <popoklopsi> Ordnung
 * License     GPLv3
 * Web         http://popoklopsi.de
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2014 David <popoklopsi> Ordnung
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>
 */


// Use semicolons
#pragma semicolon 1







// Add a new Feature
featurelib_addFeature(Handle:plugin, String:name[], bool:allowChange, bool:standard)
{
	// Detail strings
	decl String:basename[64];
	decl String:levelPath[PLATFORM_MAX_PATH + 1];
	decl String:Svalue[128];
	decl String:Svalue2[128];

	// sure we want to go on
	new bool:goON = true;

	new bool:found = false;



	// Get the short basename and the real basename
	featurelib_getPluginBaseName(plugin, basename, sizeof(basename));
	GetPluginFilename(plugin, g_FeatureList[g_iFeatures][FEATURE_BASEREAL], sizeof(basename));


	// Cut out .smx
	ReplaceString(g_FeatureList[g_iFeatures][FEATURE_BASEREAL], sizeof(basename), ".smx", "", false);



	// Search for duplicates
	for (new i=0; i < g_iFeatures; i++)
	{
		if (StrEqual(g_FeatureList[i][FEATURE_BASE], basename, false))
		{
			if (!StrEqual(g_FeatureList[i][FEATURE_BASEREAL], g_FeatureList[g_iFeatures][FEATURE_BASEREAL], false))
			{
				StammLog(false, "Found duplicate Feature. First Plugin at: %s. Second Plugin at: %s", g_FeatureList[i][FEATURE_BASEREAL], g_FeatureList[g_iFeatures][FEATURE_BASEREAL]);

				return;
			}


			// Duplicate found, assign new values
			g_FeatureList[i][FEATURE_ENABLE] = true;
			g_FeatureList[i][FEATURE_HANDLE] = plugin;
			g_FeatureList[i][FEATURE_CHANGE] = allowChange;
			g_FeatureList[i][FEATURE_STANDARD] = standard;


			// if plugin already started load the feature
			if (g_bPluginStarted)
			{
				CreateTimer(0.5, featurelib_loadFeatures, i);
			}


			// Announce new feature if debug is on
			StammLog(true, "Loaded Feature %s again", basename);


			// Thats enough for a duplicate
			return;
		}
	}
	

	// Backwards compatiblity, search in old path
	BuildPath(Path_SM, levelPath, sizeof(levelPath), "stamm/levels/%s.txt", basename);
			

	// Assign values of the new feature
	Format(g_FeatureList[g_iFeatures][FEATURE_BASE], sizeof(basename), basename);
	Format(g_FeatureList[g_iFeatures][FEATURE_NAME], sizeof(basename), name);
	

	g_FeatureList[g_iFeatures][FEATURE_HANDLE] = plugin;
	g_FeatureList[g_iFeatures][FEATURE_ENABLE] = true;
	g_FeatureList[g_iFeatures][FEATURE_CHANGE] = allowChange;
	g_FeatureList[g_iFeatures][FEATURE_STANDARD] = standard;
	g_FeatureList[g_iFeatures][FEATURE_BLOCKS] = 0;


	// Check if level File exists
	if (!FileExists(levelPath))
	{
		// Backwards compatiblity, search in old path
		Format(levelPath, sizeof(levelPath), "cfg/stamm/levels/%s.txt", basename);
			

		// If this doesnt exist, stop here, but don't abort, because maybe it needs no level config
		if (!FileExists(levelPath))
		{
			// Mark feature as zero level
			goON = false;
			g_FeatureList[g_iFeatures][FEATURE_LEVEL][0] = 0;

			/* TODO: IMPLEMENT
			g_FeatureList[g_iFeatures][FEATURE_POINTS][0] = 0; */

			// Debug
			StammLog(true, "Found no Configfile for %s. Switch to Zero level", g_FeatureList[g_iFeatures][FEATURE_BASE]);
		}
	}


	// If we have a level config, parse it
	if (goON)
	{
		// Open file
		new Handle:level_settings = CreateKeyValues("LevelSettings");

		// Load Keyvalues
		FileToKeyValues(level_settings, levelPath);



		// File is invalid, mark level as zero
		if (!KvGotoFirstSubKey(level_settings, false))
		{
			g_FeatureList[g_iFeatures][FEATURE_LEVEL][0] = 0;

			/* TODO: IMPLEMENT
			g_FeatureList[g_iFeatures][FEATURE_POINTS][0] = 0; */

			// Debug
			StammLog(true, "Found invalid Configfile for %s. Switch to Zero level", g_FeatureList[g_iFeatures][FEATURE_BASE]);
		}
		else
		{
			// Start to parse it
			new start = g_FeatureList[g_iFeatures][FEATURE_BLOCKS];

			// Loop for keyvalues
			do
			{
				// Get the Section name
				KvGetSectionName(level_settings, Svalue, sizeof(Svalue));

				// Get level of the section
				KvGetString(level_settings, NULL_STRING, Svalue2, sizeof(Svalue2));


				// Save Block
				if (g_hFeatureBlocks[g_iFeatures] == INVALID_HANDLE)
				{
					g_hFeatureBlocks[g_iFeatures] = CreateArray(32, MAXLEVELS);
				}


				SetArrayString(g_hFeatureBlocks[g_iFeatures], start, Svalue);


				/* TODO: IMPLEMENT
				// When it's a int, we have a shop feature
				if (StringToInt(Svalue2) > 0)
				{
					g_FeatureList[g_iFeatures][FEATURE_POINTS][start] = StringToInt(Svalue2);
					g_FeatureList[g_iFeatures][FEATURE_LEVEL][start] = 0;

					found = true;
				}
				else*/
				// Else search for the value of the level name with this loop
				for (new i=0; i < g_iLevels+g_iPLevels; i++)
				{
					// Name or key equals
					if (StrEqual(Svalue2, g_sLevelName[i], false) || StrEqual(Svalue2, g_sLevelKey[i], false))
					{
						found = true; 


						g_FeatureList[g_iFeatures][FEATURE_LEVEL][start] = i + 1;

						/* TODO: IMPLEMENT
						g_FeatureList[g_iFeatures][FEATURE_POINTS][start] = 0; */

						// Break
						break;
					}
				}


				// Found an invalid value?
				if (!found)
				{
					// Mark as disabled
					g_FeatureList[g_iFeatures][FEATURE_ENABLE] = false;

					// Unload it
					ServerCommand("sm plugins unload %s stamm", g_FeatureList[g_iFeatures][FEATURE_BASEREAL]);
					

					// Log the error
					StammLog(false, "Invalid Level for Feature: %s", g_FeatureList[g_iFeatures][FEATURE_BASEREAL]);


					// Stop here
					return;
				}


				// Update start
				start++;

			} 
			// Next Block
			while (KvGotoNextKey(level_settings, false));


			// Update count
			g_FeatureList[g_iFeatures][FEATURE_BLOCKS] = start;
		}
		

		// Close Keyvalue
		CloseHandle(level_settings);
	}


	// Update feature count
	g_iFeatures++;


	// Load feature if plugin already started
	if (g_bPluginStarted)
	{
		CreateTimer(0.5, featurelib_loadFeatures, g_iFeatures - 1);
	}
}






// Load a feature or all features
public Action:featurelib_loadFeatures(Handle:timer, any:featureIndex)
{
	// Only load one feature
	if (featureIndex != -1)
	{
		// Announce if debug
		StammLog(true, "Loaded Feature %s successfully", g_FeatureList[featureIndex][FEATURE_BASE]);

		// Add new Column for this feature
		sqllib_AddColumn(g_FeatureList[featureIndex][FEATURE_BASE], g_FeatureList[featureIndex][FEATURE_STANDARD]);


		// Notice to feature, that it's loaded now
		nativelib_startLoaded(g_FeatureList[featureIndex][FEATURE_HANDLE], g_FeatureList[featureIndex][FEATURE_BASE]);
	}
	else
	{
		// Finally stamm is loaded
		g_bPluginStarted = true;
		

		// Loop through all feature and load them
		for (new i = 0; i < g_iFeatures; i++)
		{
			// Add column
			sqllib_AddColumn(g_FeatureList[i][FEATURE_BASE], g_FeatureList[i][FEATURE_STANDARD]);
			

			// Notice to feature, that it's loaded now
			nativelib_startLoaded(g_FeatureList[i][FEATURE_HANDLE], g_FeatureList[i][FEATURE_BASE]);
			


			// Notice to all if debug
			StammLog(true, "Loaded Feature %s successfully", g_FeatureList[i][FEATURE_BASE]);
		}
		

		// Notice API that stamm is ready to use
		nativelib_StammReady();
		

		// Handle late load
		if (g_bIsLate)
		{
			// Insert all players on the Server
			for (new i=1; i <= MaxClients; i++)
			{
				// Mark client as invalid
				g_bClientReady[i] = false;


				// Check valid PRE
				if (clientlib_isValidClient_PRE(i))
				{
					// Insert player
					sqllib_InsertPlayer(i);
				}
			}
		}
	}
	
	return Plugin_Stop;
}






// Return short basename
featurelib_getPluginBaseName(Handle:plugin, String:name[], size)
{
	new retrieve;
	

	// Explore the real basename
	decl String:basename[64];
	decl String:explodedBasename[10][64];
	

	// But before load the basename ;)
	GetPluginFilename(plugin, basename, sizeof(basename));
	
	// Cut out .smx
	ReplaceString(basename, sizeof(basename), ".smx", "");
	

	// Now explore it (Linux style)
	retrieve = ExplodeString(basename, "/", explodedBasename, sizeof(explodedBasename), sizeof(explodedBasename[]));
	
	// Found nothig? Maybe Windows server?
	if (retrieve <= 1)
	{
		// Explore it again (Windows Style)
		retrieve = ExplodeString(basename, "\\", explodedBasename, sizeof(explodedBasename), sizeof(explodedBasename[]));
	}


	// Save the short path (filename hehe^^)
	Format(name, size, explodedBasename[retrieve - 1]);
}






// Unload a Feature
featurelib_UnloadFeature(Handle:plugin)
{
	// Get intern index of the plugin
	new index = featurelib_getFeatureByHandle(plugin);


	// Unlload it
	ServerCommand("sm plugins unload %s stamm", g_FeatureList[index][FEATURE_BASEREAL]);

	// Mark as disabled
	g_FeatureList[index][FEATURE_ENABLE] = false;



	// Announce unload
	if (!g_bMoreColors)
	{
		CPrintToChatAll("%s %t", g_sStammTag, "UnloadedFeature", g_FeatureList[index][FEATURE_NAME]);
	}
	else
	{
		MCPrintToChatAll("%s %t", g_sStammTag, "UnloadedFeature", g_FeatureList[index][FEATURE_NAME]);
	}
}







// Load a Feautre
featurelib_loadFeature(Handle:plugin)
{
	// Intern index
	new index = featurelib_getFeatureByHandle(plugin);

	// Load it 
	ServerCommand("sm plugins load %s stamm", g_FeatureList[index][FEATURE_BASEREAL]);


	// Mark as enabled, and announce it
	g_FeatureList[index][FEATURE_ENABLE] = true;


	if (!g_bMoreColors)
	{
		CPrintToChatAll("%s %t", g_sStammTag, "LoadedFeature", g_FeatureList[index][FEATURE_NAME]);
	}
	else
	{
		MCPrintToChatAll("%s %t", g_sStammTag, "LoadedFeature", g_FeatureList[index][FEATURE_NAME]);
	}
}





// Reloads a feature
featurelib_ReloadFeature(Handle:plugin)
{
	// Just unload and reload^^
	featurelib_UnloadFeature(plugin);
	featurelib_loadFeature(plugin);
}






// Load feature for console
public Action:featurelib_Load(args)
{
	// Only one arg needed
	if (GetCmdArgs() == 1)
	{
		decl String:basename[64];
		
		// Get basename
		GetCmdArg(1, basename, sizeof(basename));


		// Find the feature
		for (new i=0; i < g_iFeatures; i++)
		{
			if (!g_FeatureList[i][FEATURE_ENABLE] && StrEqual(basename, g_FeatureList[i][FEATURE_BASE], false))
			{
				// Load it
				featurelib_loadFeature(g_FeatureList[i][FEATURE_HANDLE]);

				// Finish
				return Plugin_Handled;
			}
		}
		

		// Not found, search with real Basename
		for (new i=0; i < g_iFeatures; i++)
		{
			if (!g_FeatureList[i][FEATURE_ENABLE] && StrEqual(basename, g_FeatureList[i][FEATURE_BASEREAL], false))
			{
				// Load it
				featurelib_loadFeature(g_FeatureList[i][FEATURE_HANDLE]);

				return Plugin_Handled;
			}
		}


		// Not found, load it with sm
		PrintToServer("Feature %s was not loaded before, try to load it via SM...", basename);

		ServerCommand("sm plugins load %s stamm", basename);
	}
	else
	{
		// So it's correct ->
		ReplyToCommand(0, "Usage: stamm_load_feature <basename>");
	}


	return Plugin_Handled;
}






// And console unload
public Action:featurelib_UnLoad(args)
{
	// Also one one cmd arg is needed
	if (GetCmdArgs() == 1)
	{
		decl String:basename[64];
	
		// Get basename	
		GetCmdArg(1, basename, sizeof(basename));


		// Search it
		for (new i=0; i < g_iFeatures; i++)
		{
			if (g_FeatureList[i][FEATURE_ENABLE] && StrEqual(basename, g_FeatureList[i][FEATURE_BASE], false))
			{
				// Unload it
				featurelib_UnloadFeature(g_FeatureList[i][FEATURE_HANDLE]);

				return Plugin_Handled;
			}
		}
		

		// search with real basename
		for (new i=0; i < g_iFeatures; i++)
		{
			if (g_FeatureList[i][FEATURE_ENABLE] && StrEqual(basename, g_FeatureList[i][FEATURE_BASEREAL], false))
			{
				// Unload on found
				featurelib_UnloadFeature(g_FeatureList[i][FEATURE_HANDLE]);

				return Plugin_Handled;
			}
		}


		// Doesn't found or already loaded
		ReplyToCommand(0, "Error. Feature not found or already unloaded.");
	}
	else
	{
		// So it's correct ->
		ReplyToCommand(0, "Usage: stamm_unload_feature <basename>");
	}


	return Plugin_Handled;
}






// And also reload ;)
public Action:featurelib_ReLoad(args)
{

	// Also here just 1 arg
	if (GetCmdArgs() == 1)
	{
		decl String:basename[64];
		

		// Basename
		GetCmdArg(1, basename, sizeof(basename));


		// Loops again, see above!
		for (new i=0; i < g_iFeatures; i++)
		{
			if (StrEqual(basename, g_FeatureList[i][FEATURE_BASE], false))
			{
				featurelib_ReloadFeature(g_FeatureList[i][FEATURE_HANDLE]);

				return Plugin_Handled;
			}
		}
		

		for (new i=0; i < g_iFeatures; i++)
		{
			if (StrEqual(basename, g_FeatureList[i][FEATURE_BASEREAL], false))
			{
				featurelib_ReloadFeature(g_FeatureList[i][FEATURE_HANDLE]);

				return Plugin_Handled;
			}	
		}

		// Not Found it
		ReplyToCommand(0, "Error. Feature not found.");
	}
	else
	{
		ReplyToCommand(0, "Usage: stamm_reload_feature <basename>");
	}

	return Plugin_Handled;
}







// List all features
public Action:featurelib_List(args)
{
	// Header
	PrintToServer("[STAMM] Listing %d Feature(s):", g_iFeatures);


	// Go through all Features
	for (new i=0; i < g_iFeatures; i++)
	{
		// Print with enabled and disabled mark
		if (g_FeatureList[i][FEATURE_ENABLE])
		{
			PrintToServer("  %02d \"%s\" <%s>", i+1, g_FeatureList[i][FEATURE_NAME], g_FeatureList[i][FEATURE_BASEREAL]);
		}
		else
		{
			PrintToServer("  %02d Disabled - \"%s\" <%s>", i+1, g_FeatureList[i][FEATURE_NAME], g_FeatureList[i][FEATURE_BASEREAL]);
		}
	}
	
	return Plugin_Handled;
}






// returns the index by given Handle
featurelib_getFeatureByHandle(Handle:plugin)
{
	// Go through all features
	for (new i=0; i < g_iFeatures; i++)
	{
		// Handle the same?
		if (g_FeatureList[i][FEATURE_HANDLE] == plugin)
		{
			// Return the intern index
			return i;
		}
	}


	// -1 when not found
	return -1;
}