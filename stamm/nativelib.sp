/**
 * -----------------------------------------------------
 * File        nativelib.sp
 * Authors     David <popoklopsi> Ordnung
 * License     GPLv3
 * Web         http://popoklopsi.de
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2013 David <popoklopsi> Ordnung
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


// Use semicolon
#pragma semicolon 1


// Forwards
new Handle:nativelib_player_stamm;
new Handle:nativelib_stamm_get;
new Handle:nativelib_stamm_ready;
new Handle:nativelib_client_ready;
new Handle:nativelib_client_save;
new Handle:nativelib_happy_start;
new Handle:nativelib_happy_end;


// Init. Nativelib
public nativelib_Start()
{

	// compatiblity to old sourcemod versions
	MarkNativeAsOptional("GetUserMessageType");


	// Create all the natives here, puh!
	CreateNative("STAMM_GetBasename", nativelib_GetFeatureBasename);
	CreateNative("STAMM_IsMyFeature", nativelib_IsMyFeature);
	CreateNative("STAMM_GetLevel", nativelib_GetLevel);
	CreateNative("STAMM_GetClientPoints", nativelib_GetClientStammPoints);
	CreateNative("STAMM_GetClientLevel", nativelib_GetClientStammLevel);
	CreateNative("STAMM_GetLevelPoints", nativelib_GetStammLevelPoints);
	CreateNative("STAMM_GetLevelName", nativelib_GetStammLevelName);
	CreateNative("STAMM_GetLevelNumber", nativelib_GetStammLevelNumber);
	CreateNative("STAMM_GetBlockCount", nativelib_GetBlockCount);
	CreateNative("STAMM_GetBlockOfName", nativelib_GetBlockOfName);
	CreateNative("STAMM_GetType", nativelib_GetStammType);
	CreateNative("STAMM_GetGame", nativelib_GetStammGame);
	CreateNative("STAMM_AutoUpdate", nativelib_AutoUpdate);
	CreateNative("STAMM_GetLevelCount", nativelib_GetStammLevelCount);
	CreateNative("STAMM_AddClientPoints", nativelib_AddClientStammPoints);
	CreateNative("STAMM_DelClientPoints", nativelib_DelClientStammPoints);
	CreateNative("STAMM_SetClientPoints", nativelib_SetClientStammPoints);
	CreateNative("STAMM_IsClientVip", nativelib_IsClientVip);
	CreateNative("STAMM_HaveClientFeature", nativelib_HaveClientFeature);
	CreateNative("STAMM_AddFeature", nativelib_AddFeature);
	CreateNative("STAMM_AddFeatureText", nativelib_AddFeatureText);
	CreateNative("STAMM_IsClientValid", nativelib_IsClientValid);
	CreateNative("STAMM_IsLoaded", nativelib_IsLoaded);
	CreateNative("STAMM_IsClientAdmin", nativelib_IsClientStammAdmin);
	CreateNative("STAMM_WantClientFeature", nativelib_ClientWantStammFeature);
	CreateNative("STAMM_StartHappyHour", nativelib_StartHappyHour);
	CreateNative("STAMM_EndHappyHour", nativelib_EndHappyHour);
	CreateNative("STAMM_LoadFeature", nativelib_LoadFeature);
	CreateNative("STAMM_UnloadFeature", nativelib_UnloadFeature);
	CreateNative("STAMM_WriteToLog", nativelib_WriteToStammLog);
	

	// And create all the global forwards
	nativelib_stamm_ready = CreateGlobalForward("STAMM_OnReady", ET_Ignore);
	nativelib_client_ready = CreateGlobalForward("STAMM_OnClientReady", ET_Ignore, Param_Cell);
	nativelib_client_save = CreateGlobalForward("STAMM_OnSaveClient", ET_Ignore, Param_Cell);
	nativelib_player_stamm = CreateGlobalForward("STAMM_OnClientBecomeVip", ET_Ignore, Param_Cell);
	nativelib_stamm_get = CreateGlobalForward("STAMM_OnClientGetPoints", ET_Ignore, Param_Cell, Param_Cell);
	nativelib_happy_start = CreateGlobalForward("STAMM_OnHappyHourStart", ET_Ignore, Param_Cell, Param_Cell);
	nativelib_happy_end = CreateGlobalForward("STAMM_OnHappyHourEnd", ET_Ignore);


	// Register stamm library
	RegPluginLibrary("stamm");
}


// Local forwards, let feature notice that it's loaded
public nativelib_startLoaded(Handle:plugin, String:basename[])
{
	// Get function id
	new Function:id = GetFunctionByName(plugin, "STAMM_OnFeatureLoaded");
	

	// Function found?
	if (id != INVALID_FUNCTION)
	{
		// Execute it with param basename
		Call_StartFunction(plugin, id);

		Call_PushString(basename);
		
		Call_Finish();
	}
}


// a local forward for feature to change points a player get
public Action:nativelib_PublicPlayerGetPointsPlugin(Handle:plugin, client, &number)
{
	// Search for the function
	new Action:result = Plugin_Continue;
	new Function:id = GetFunctionByName(plugin, "STAMM_OnClientGetPoints_PRE");

	// Found it?
	if (id != INVALID_FUNCTION)
	{
		// Execute it with param client and points count
		Call_StartFunction(plugin, id);

		Call_PushCell(client);
		Call_PushCellRef(number);
		
		// Save result
		Call_Finish(result);
	}


	// Pushback result
	return result;
}


// Notice to all plugins, that a player got points
public nativelib_PublicPlayerGetPoints(client, number)
{
	Call_StartForward(nativelib_stamm_get);
	
	Call_PushCell(client);
	Call_PushCell(number);
	
	// Call
	Call_Finish();
}



// Notice to all plugins, that a player got VIP
public nativelib_PublicPlayerBecomeVip(client)
{
	Call_StartForward(nativelib_player_stamm);
	
	Call_PushCell(client);
	
	Call_Finish();
}



// Notice to all plugins, that Stamm is ready
public nativelib_StammReady()
{
	Call_StartForward(nativelib_stamm_ready);
	
	Call_Finish();
}



// Notice to all plugins, that a player is ready
public nativelib_ClientReady(client)
{
	Call_StartForward(nativelib_client_ready);
	
	Call_PushCell(client);
	
	Call_Finish();
}



// Notice to all plugins, that a player got save
public nativelib_ClientSave(client)
{
	Call_StartForward(nativelib_client_save);
	
	Call_PushCell(client);
	
	Call_Finish();
}



// Notice to feature, that a player changed the status of him
public nativelib_ClientChanged(client, index, bool:status)
{
	// Search for the function 
	new Handle:plugin = g_FeatureList[index][FEATURE_HANDLE];
	new Function:id = GetFunctionByName(plugin, "STAMM_OnClientChangedFeature");
	
	// Found?
	if (id != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, id);
		
		// Pish with client and new status
		Call_PushCell(client);
		Call_PushCell(status);
		
		Call_Finish();
	}
}


// Notice to all plugins, that happy hour started
public nativelib_HappyStart(time, factor)
{
	Call_StartForward(nativelib_happy_start);
	
	Call_PushCell(time);
	Call_PushCell(factor);

	Call_Finish();
}


// Notice to all plugins, that happy hour ended
public nativelib_HappyEnd()
{
	Call_StartForward(nativelib_happy_end);
	
	Call_Finish();
}



// Checks basename
public nativelib_IsMyFeature(Handle:plugin, numParams)
{
	decl String:basename[64];
	decl String:basename2[64];
	decl String:basename_orig[64];
	

	// Get basename
	GetNativeString(1, basename, sizeof(basename));
	

	// Search for plugins basename
	featurelib_getPluginBaseName(plugin, basename2, sizeof(basename2));
	GetPluginFilename(plugin, basename_orig, sizeof(basename_orig));


	// Check if it's equal
	if (StrEqual(basename, basename2, false) || StrEqual(basename_orig, basename, false))
	{
		return true;
	}

	// Not equal	
	return false;
}


// Get the level of a block
public nativelib_GetLevel(Handle:plugin, numParams)
{
	new feature = featurelib_getFeatureByHandle(plugin);

	// Found feature
	if (feature != -1)
	{
		return g_FeatureList[feature][FEATURE_LEVEL][GetNativeCell(1)-1];
	}

	// no? hm...
	return 0;
}


// Returns the number of blocks found
public nativelib_GetBlockCount(Handle:plugin, numParams)
{
	new found = 0;
	new feature = featurelib_getFeatureByHandle(plugin);


	// Found feature?
	if (feature != -1)
	{
		// Go through all blocks and updated counter
		for (new j=0; j < 20; j++)
		{
			if (g_FeatureList[feature][FEATURE_LEVEL][j] != 0)
			{
				// found one
				found++;
			}
		}
	}

	// Return the found counter
	return found;
}


// Get the block index of a named block
public nativelib_GetBlockOfName(Handle:plugin, numParams)
{
	decl String:name[64];
	new feature = featurelib_getFeatureByHandle(plugin);

	GetNativeString(1, name, sizeof(name));

	// Feature found?
	if (feature != -1)
	{
		// Go through all levels
		for (new j=0; j < MAXLEVELS; j++)
		{
			// Check if name equals
			if (StrEqual(g_FeatureBlocks[feature][j], name))
			{
				return j+1;
			}
		}
	}

	// Not found
	return -1;
}



// Get the basename
public nativelib_GetFeatureBasename(Handle:plugin, numParams)
{
	decl String:basename[64];
	
	// Get basename
	featurelib_getPluginBaseName(plugin, basename, sizeof(basename));

	// save it
	SetNativeString(1, basename, GetNativeCell(2), false);
}


// Get points of a player
public nativelib_GetClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	// Check client is valid
	if (clientlib_isValidClient(client)) 
	{
		return g_playerpoints[client];
	}

	return -1;
}


// Get the level of a client
public nativelib_GetClientStammLevel(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	

	// Client valid?
	if (clientlib_isValidClient(client)) 
	{
		return g_playerlevel[client];
	}

	return -1;
}


// Get the points a level needs
public nativelib_GetStammLevelPoints(Handle:plugin, numParams)
{
	new type = GetNativeCell(1);
	
	// Check if level is valid
	if (type <= g_levels && type > 0) 
	{
		return g_LevelPoints[type-1];
	}

	return -1;
}


// Returns total count of levels
public nativelib_GetStammLevelCount(Handle:plugin, numParams)
{
	return g_levels+g_plevels;
}


// Get the name of a level
public nativelib_GetStammLevelName(Handle:plugin, numParams)
{
	new type = GetNativeCell(1);
	new len = GetNativeCell(3);
	

	// Valid level?
	if (type <= g_levels+g_plevels && type > 0)
	{
		// Save name
		SetNativeString(2, g_LevelName[type-1], len, false);
		
		return true;
	}

	// Not found -> save empty string
	SetNativeString(2, "", len, false);	
	
	return false;
}


// Get the number of a level name
public nativelib_GetStammLevelNumber(Handle:plugin, numParams)
{
	decl String:name[64];
	
	GetNativeString(1, name, sizeof(name));
	
	// Loop through levels
	for (new i=0; i < g_levels+g_plevels; i++)
	{
		// Check name
		if (StrEqual(g_LevelName[i], name, false)) 	
		{
			return i+1;
		}
	}
	
	return 0;
}


// Checks if a level is private
public nativelib_IsLevelPrivate(Handle:plugin, numParams)
{
	new type = GetNativeCell(1);
	
	// greater than normal levels?
	if (type > g_levels)
	{
		return true;
	}

	return false;
}


// Returns how a player get his points
public nativelib_GetStammType(Handle:plugin, numParams)
{
	return g_vip_type;
}


// Returns the game stamm is running on
public nativelib_GetStammGame(Handle:plugin, numParams)
{
	return otherlib_getGame();
}

// Returns if the player want autoupdates
public nativelib_AutoUpdate(Handle:plugin, numParams)
{
	return autoUpdate;
}


// Start happy hour
public nativelib_StartHappyHour(Handle:plugin, numParams)
{
	new time = GetNativeCell(1);
	new factor = GetNativeCell(2);
	
	// Check for valid time and factor
	if (time > 1)
	{
		if (factor > 1)
		{
			// Only when it's not running already
			if (!g_happyhouron)
			{
				// Update global points
				g_points = factor;
				g_happyhouron = 1;

				// Delete old timer and start new
				otherlib_checkTimer(g_HappyTimer);
				g_HappyTimer = CreateTimer(float(time)*60, otherlib_StopHappyHour);
				

				// Notice to all that happy hour sarted
				nativelib_HappyStart(time, factor);
				
				// And announce to players
				CPrintToChatAll("%s %t", g_StammTag, "HappyActive", g_points);
				
				return true;
			}
		}
		else ThrowNativeError(2, "[ Stamm ] Factor must be greater than 1");
	}
	else ThrowNativeError(1, "[ Stamm ] Time must be greater than 1");
	
	return false;
}


// Ends happy hour
public nativelib_EndHappyHour(Handle:plugin, numParams)
{
	// Only when it's running
	if (g_happyhouron)
	{
		// End it
		otherlib_EndHappyHour();
		
		return true;
	}

	return false;
}


// Checks whether a client want the feature
public nativelib_ClientWantStammFeature(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	// Is client valid? 
	if (clientlib_isValidClient(client))
	{
		new feature = featurelib_getFeatureByHandle(plugin);

		// Valid feature
		if (feature != -1)
		{
			// return status
			return g_FeatureList[feature][WANT_FEATURE][client];
		}
	}
	
	return false;
}


// Add points
public nativelib_AddClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new pointschange = GetNativeCell(2);
	

	// Valid client?
	if (clientlib_isValidClient(client)) 
	{
		// Give points
		pointlib_GivePlayerPoints(client, pointschange, false);
		
		return true;
	}

	return false;
}


// Delete Points
public nativelib_DelClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new pointschange = GetNativeCell(2);
	
	// Valid client?
	if (clientlib_isValidClient(client)) 
	{
		// Delete points
		pointlib_GivePlayerPoints(client, pointschange*-1, false);
		
		return true;
	}

	return false;
}


// Set points
public nativelib_SetClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new pointschange = GetNativeCell(2);
	
	// Valid client
	if (clientlib_isValidClient(client)) 
	{
		// musst be higher than zero
		if (pointschange >= 0)
		{
			// get difference
			new diff = pointschange - g_playerpoints[client];

			// Add / Delete difference
			pointlib_GivePlayerPoints(client, diff, false);
			
			return true;
		}
	}

	return false;
}


// Add a Feature
public nativelib_AddFeature(Handle:plugin, numParams)
{
	// Max features reached?
	if (g_features >= MAXFEATURES)
	{
		ThrowNativeError(1, "Attention: Max features of %i reached!", MAXFEATURES);
	}

	decl String:name[64];
	decl String:description[256];
	

	// Get the details
	GetNativeString(1, name, sizeof(name));
	GetNativeString(2, description, sizeof(description));
	
	// Give work to the featurelib
	featurelib_addFeature(plugin, name, description, GetNativeCell(3), GetNativeCell(4));
}


// Add a text to display
public nativelib_AddFeatureText(Handle:plugin, numParams)
{
	decl String:description[256];
	
	// Level to add
	new level = GetNativeCell(1);
	
	// Get the description
	GetNativeString(2, description, sizeof(description));
	
	new feature = featurelib_getFeatureByHandle(plugin);


	// Valid feature?
	if (feature != -1)
	{
		// Save the description to plugin and to level
		new desc = g_FeatureList[feature][FEATURE_DESCS][level];

		Format(g_FeatureHaveDesc[feature][level][desc], sizeof(g_FeatureHaveDesc[][][]), description);

		// Updated level count
		g_FeatureList[feature][FEATURE_DESCS][level]++;

		// For performance only 5 descriptions per level and feature
		if (g_FeatureList[feature][FEATURE_DESCS][level] == 5)
		{
			g_FeatureList[feature][FEATURE_DESCS][level] = 0;
		}

		return true;
	}

	return false;
}


// Checks if the players level is high enough, and he want the feature
public nativelib_HaveClientFeature(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	// Valid client?
	if (clientlib_isValidClient(client))
	{
		new feature = featurelib_getFeatureByHandle(plugin);

		// Found feature und block higher than zero
		if (feature != -1 && GetNativeCell(2) > 0)
		{
			// 
			if (g_playerlevel[client] >= g_FeatureList[feature][FEATURE_LEVEL][GetNativeCell(2)-1] && g_FeatureList[feature][WANT_FEATURE][client])
			{
				return true;
			}
		}
	}

	return false;
}


// Checks if a client is stamm valid
public nativelib_IsClientValid(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	// Return intern function
	return clientlib_isValidClient(client);
}


// Checks if a client has stamm admin flags
public nativelib_IsClientStammAdmin(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	// Intern function
	return clientlib_IsAdmin(client);
}


// Is Client VIP?
public nativelib_IsClientVip(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new type = GetNativeCell(2);
	new bool:min = GetNativeCell(3);
	
	// Client valid?
	if (clientlib_isValidClient(client)) 
	{
		// Just check if VIP
		if (!type)
		{
			// Level higher than zero?
			if (g_playerlevel[client] > 0)
			{ 
				return true;
			}
			else
			{ 
				return false;
			}
		}
		if (min)
		{
			// Level Higher than?
			if (g_playerlevel[client] >= type) 
			{
				return true;
			}
		}
		else
		{
			// Level equal?
			if (g_playerlevel[client] == type) 
			{
				return true;
			}
		}
	}

	return false;
}


// Stamm is loaded?
public nativelib_IsLoaded(Handle:plugin, numParams)
{
	// yeah, just return the value
	return g_pluginStarted;
}


// Load a feature
public nativelib_LoadFeature(Handle:plugin, numParams)
{
	plugin = GetNativeCell(1);

	new feature = featurelib_getFeatureByHandle(plugin);

	// Feature already enabled?
	if (g_FeatureList[feature][FEATURE_ENABLE] == 1) 
	{
		return -1;
	}
	else
	{
		// Load it
		featurelib_loadFeature(plugin);
	}

	return 1;
}


// Unload feature
public nativelib_UnloadFeature(Handle:plugin, numParams)
{
	plugin = GetNativeCell(1);

	new feature = featurelib_getFeatureByHandle(plugin);

	// Is not loaded?
	if (g_FeatureList[feature][FEATURE_ENABLE] == 0) 
	{
		return -1;
	}
	else
	{
		// Unload it
		featurelib_UnloadFeature(plugin);
	}

	return 1;
}


// Write something to the stamm log
public nativelib_WriteToStammLog(Handle:plugin, numParams)
{
	decl String:buffer[1024];
	decl String:basename[64];

	new bool:useDebug = GetNativeCell(1);

	// Get basename
	featurelib_getPluginBaseName(plugin, basename, sizeof(basename));
	

	// Format text parameter
	FormatNativeString(0, 2, 3, sizeof(buffer), _, buffer);

	// Write to debug only if debug is enabled
	if (useDebug && g_debug)
	{
	 	LogToFile(g_DebugFile, "[ STAMM-%s ] %s", basename, buffer);
	}
	else if (!useDebug)
	{
		// Seems to be an error
		LogToFile(g_LogFile, "[ STAMM-%s ] %s", basename, buffer);
	}
}