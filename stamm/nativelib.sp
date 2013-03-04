#pragma semicolon 1

new Handle:nativelib_player_stamm;
new Handle:nativelib_stamm_get;
new Handle:nativelib_stamm_ready;
new Handle:nativelib_client_ready;
new Handle:nativelib_client_save;
new Handle:nativelib_happy_start;
new Handle:nativelib_happy_end;

public nativelib_Start()
{
	MarkNativeAsOptional("GetUserMessageType");

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
	CreateNative("STAMM_CheckTranslations", nativelib_CheckTranslations);
	
	nativelib_stamm_ready = CreateGlobalForward("STAMM_OnReady", ET_Ignore);
	nativelib_client_ready = CreateGlobalForward("STAMM_OnClientReady", ET_Ignore, Param_Cell);
	nativelib_client_save = CreateGlobalForward("STAMM_OnSaveClient", ET_Ignore, Param_Cell);
	nativelib_player_stamm = CreateGlobalForward("STAMM_OnClientBecomeVip", ET_Ignore, Param_Cell);
	nativelib_stamm_get = CreateGlobalForward("STAMM_OnClientGetPoints", ET_Ignore, Param_Cell, Param_Cell);
	nativelib_happy_start = CreateGlobalForward("STAMM_OnHappyHourStart", ET_Ignore, Param_Cell, Param_Cell);
	nativelib_happy_end = CreateGlobalForward("STAMM_OnHappyHourEnd", ET_Ignore);

	RegPluginLibrary("stamm");
}

public nativelib_startLoaded(Handle:plugin, String:basename[])
{
	new Function:id = GetFunctionByName(plugin, "STAMM_OnFeatureLoaded");
	
	if (id != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, id);

		Call_PushString(basename);
		
		Call_Finish();
	}
}

public Action:nativelib_PublicPlayerGetPointsPlugin(Handle:plugin, client, &number)
{
	new Action:result = Plugin_Continue;
	new Function:id = GetFunctionByName(plugin, "STAMM_OnClientGetPoints_PRE");

	if (id != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, id);

		Call_PushCell(client);
		Call_PushCellRef(number);
		
		Call_Finish(result);
	}

	return result;
}

public nativelib_PublicPlayerGetPoints(client, number)
{
	Call_StartForward(nativelib_stamm_get);
	
	Call_PushCell(client);
	Call_PushCell(number);
	
	Call_Finish();
}

public nativelib_PublicPlayerBecomeVip(client)
{
	Call_StartForward(nativelib_player_stamm);
	
	Call_PushCell(client);
	
	Call_Finish();
}

public nativelib_StammReady()
{
	Call_StartForward(nativelib_stamm_ready);
	
	Call_Finish();
}

public nativelib_ClientReady(client)
{
	Call_StartForward(nativelib_client_ready);
	
	Call_PushCell(client);
	
	Call_Finish();
}

public nativelib_ClientSave(client)
{
	Call_StartForward(nativelib_client_save);
	
	Call_PushCell(client);
	
	Call_Finish();
}

public nativelib_ClientChanged(client, index, bool:status)
{
	new Handle:plugin = g_FeatureList[index][FEATURE_HANDLE];
	new Function:id = GetFunctionByName(plugin, "STAMM_OnClientChangedFeature");
	
	if (id != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, id);
		
		Call_PushCell(client);
		Call_PushCell(status);
		
		Call_Finish();
	}
}

public nativelib_HappyStart(time, factor)
{
	Call_StartForward(nativelib_happy_start);
	
	Call_PushCell(time);
	Call_PushCell(factor);

	Call_Finish();
}

public nativelib_HappyEnd()
{
	Call_StartForward(nativelib_happy_end);
	
	Call_Finish();
}

public nativelib_IsMyFeature(Handle:plugin, numParams)
{
	decl String:basename[64];
	decl String:basename2[64];
	decl String:basename_orig[64];
	
	GetNativeString(1, basename, sizeof(basename));
	
	featurelib_getPluginBaseName(plugin, basename2, sizeof(basename2));
	GetPluginFilename(plugin, basename_orig, sizeof(basename_orig));

	if (StrEqual(basename, basename2, false) || StrEqual(basename_orig, basename, false))
		return true;
		
	return false;
}

public nativelib_GetLevel(Handle:plugin, numParams)
{
	new feature = featurelib_getFeatureByHandle(plugin);

	if (feature != -1)
		return g_FeatureList[feature][FEATURE_LEVEL][GetNativeCell(1)-1];

	return 0;
}

public nativelib_GetBlockCount(Handle:plugin, numParams)
{
	new found = 0;
	new feature = featurelib_getFeatureByHandle(plugin);

	if (feature != -1)
	{
		for (new j=0; j < 20; j++)
		{
			if (g_FeatureList[feature][FEATURE_LEVEL][j] != 0)
				found++;
		}
	}

	return found;
}

public nativelib_GetBlockOfName(Handle:plugin, numParams)
{
	decl String:name[64];
	new feature = featurelib_getFeatureByHandle(plugin);

	GetNativeString(1, name, sizeof(name));

	if (feature != -1)
	{
		for (new j=0; j < 20; j++)
		{
			if (StrEqual(g_FeatureBlocks[feature][j], name))
				return j+1;
		}
	}

	return -1;
}

public nativelib_GetFeatureBasename(Handle:plugin, numParams)
{
	decl String:basename[64];
	
	featurelib_getPluginBaseName(plugin, basename, sizeof(basename));

	SetNativeString(1, basename, GetNativeCell(2), false);
}

public nativelib_GetClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (clientlib_isValidClient(client)) 
		return g_playerpoints[client];
	
	return -1;
}

public nativelib_GetClientStammLevel(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (clientlib_isValidClient(client)) 
		return g_playerlevel[client];
	
	return -1;
}

public nativelib_GetStammLevelPoints(Handle:plugin, numParams)
{
	new type = GetNativeCell(1);
	
	if (type <= g_levels && type > 0) 
		return g_LevelPoints[type-1];
	
	return -1;
}

public nativelib_GetStammLevelCount(Handle:plugin, numParams)
{
	return g_levels+g_plevels;
}

public nativelib_GetStammLevelName(Handle:plugin, numParams)
{
	new type = GetNativeCell(1);
	new len = GetNativeCell(3);
	
	if (type <= g_levels+g_plevels && type > 0)
	{
		SetNativeString(2, g_LevelName[type-1], len, false);
		
		return true;
	}

	SetNativeString(2, "", len, false);	
	
	return false;
}

public nativelib_GetStammLevelNumber(Handle:plugin, numParams)
{
	decl String:name[64];
	
	GetNativeString(1, name, sizeof(name));
	
	for (new i=0; i < g_levels+g_plevels; i++)
	{
		if (StrEqual(g_LevelName[i], name, false)) 	
			return i+1;
	}
	
	return 0;
}

public nativelib_IsLevelPrivate(Handle:plugin, numParams)
{
	new type = GetNativeCell(1);
	
	if (type > g_levels)
		return true;
	
	return false;
}

public nativelib_GetStammType(Handle:plugin, numParams)
{
	return g_vip_type;
}

public nativelib_GetStammGame(Handle:plugin, numParams)
{
	return otherlib_getGame();
}

public nativelib_StartHappyHour(Handle:plugin, numParams)
{
	new time = GetNativeCell(1);
	new factor = GetNativeCell(2);
	
	if (time > 1)
	{
		if (factor > 1)
		{
			if (!g_happyhouron)
			{
				g_points = factor;
				g_happyhouron = 1;
				
				otherlib_checkTimer(g_HappyTimer);
				g_HappyTimer = CreateTimer(float(time)*60, otherlib_StopHappyHour);
				
				nativelib_HappyStart(time, factor);
				
				CPrintToChatAll("%s %t", g_StammTag, "HappyActive", g_points);
				
				return true;
			}
		}
		else ThrowNativeError(2, "[ Stamm ] Factor must be greater than 1");
	}
	else ThrowNativeError(1, "[ Stamm ] Time must be greater than 1");
	
	return false;
}

public nativelib_EndHappyHour(Handle:plugin, numParams)
{
	if (g_happyhouron)
	{
		otherlib_EndHappyHour();
		
		return true;
	}
	return false;
}

public nativelib_ClientWantStammFeature(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (clientlib_isValidClient(client))
	{
		new feature = featurelib_getFeatureByHandle(plugin);

		if (feature != -1)
			return g_FeatureList[feature][WANT_FEATURE][client];
	}
	
	return false;
}

public nativelib_AddClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new pointschange = GetNativeCell(2);
	
	if (clientlib_isValidClient(client)) 
	{
		pointlib_GivePlayerPoints(client, pointschange, false);
		
		return true;
	}

	return false;
}

public nativelib_DelClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new pointschange = GetNativeCell(2);
	
	if (clientlib_isValidClient(client)) 
	{
		pointlib_GivePlayerPoints(client, pointschange*-1, false);
		
		return true;
	}

	return false;
}

public nativelib_SetClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new pointschange = GetNativeCell(2);
	
	if (clientlib_isValidClient(client)) 
	{
		if (pointschange >= 0)
		{
			new diff = pointschange - g_playerpoints[client];

			pointlib_GivePlayerPoints(client, diff, false);
			
			return true;
		}
	}

	return false;
}

public nativelib_AddFeature(Handle:plugin, numParams)
{
	decl String:name[64];
	decl String:description[256];
	
	GetNativeString(1, name, sizeof(name));
	GetNativeString(2, description, sizeof(description));
	
	featurelib_addFeature(plugin, name, description, GetNativeCell(3), GetNativeCell(4));
}

public nativelib_AddFeatureText(Handle:plugin, numParams)
{
	decl String:description[256];
	
	new level = GetNativeCell(1);
	
	GetNativeString(2, description, sizeof(description));
	
	new feature = featurelib_getFeatureByHandle(plugin);

	if (feature != -1)
	{
		Format(g_FeatureHaveDesc[feature][level], sizeof(g_FeatureHaveDesc[][]), description);
		
		return true;
	}

	return false;
}

public nativelib_HaveClientFeature(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (clientlib_isValidClient(client))
	{
		new feature = featurelib_getFeatureByHandle(plugin);

		if (feature != -1)
		{
			if (g_playerlevel[client] >= g_FeatureList[feature][FEATURE_LEVEL][GetNativeCell(2)-1] && g_FeatureList[feature][WANT_FEATURE][client])
				return true;
		}
	}

	return false;
}

public nativelib_IsClientValid(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	return clientlib_isValidClient(client);
}

public nativelib_IsClientStammAdmin(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	return clientlib_IsAdmin(client);
}

public nativelib_IsClientVip(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new type = GetNativeCell(2);
	new bool:min = GetNativeCell(3);
	
	if (clientlib_isValidClient(client)) 
	{
		if (!type)
		{
			if (g_playerlevel[client] > 0) 
				return true;
			else 
				return false;
		}
		if (min)
		{
			if (g_playerlevel[client] >= type) 
				return true;
		}
		else
		{
			if (g_playerlevel[client] == type) 
				return true;
		}
	}

	return false;
}

public nativelib_IsLoaded(Handle:plugin, numParams)
{
	return g_pluginStarted;
}

public nativelib_LoadFeature(Handle:plugin, numParams)
{
	plugin = GetNativeCell(1);

	new feature = featurelib_getFeatureByHandle(plugin);

	if (g_FeatureList[feature][FEATURE_ENABLE] == 1) 
		return -1;
	else
		featurelib_loadFeature(plugin);

	return 1;
}

public nativelib_UnloadFeature(Handle:plugin, numParams)
{
	plugin = GetNativeCell(1);

	new feature = featurelib_getFeatureByHandle(plugin);

	if (g_FeatureList[feature][FEATURE_ENABLE] == 0) 
		return -1;
	else
		featurelib_UnloadFeature(plugin);

	return 1;
}

public nativelib_WriteToStammLog(Handle:plugin, numParams)
{
	decl String:buffer[1024];
	decl String:basename[64];

	new bool:useDebug = GetNativeCell(1);

	featurelib_getPluginBaseName(plugin, basename, sizeof(basename));
	
	FormatNativeString(0, 2, 3, sizeof(buffer), _, buffer);

	if (useDebug && g_debug)
	 	LogToFile(g_DebugFile, "[ STAMM-%s ] %s", basename, buffer);
	else if (!useDebug)
		LogToFile(g_LogFile, "[ STAMM-%s ] %s", basename, buffer);
}

public nativelib_CheckTranslations(Handle:plugin, numParams)
{
	featurelib_LoadTranslations(false);
}