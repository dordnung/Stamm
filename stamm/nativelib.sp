new Handle:nativelib_player_stamm;
new Handle:nativelib_stamm_get;
new Handle:nativelib_stamm_ready;
new Handle:nativelib_client_ready;
new Handle:nativelib_client_save;
new Handle:nativelib_happy_start;
new Handle:nativelib_happy_end;
new Handle:nativelib_client_change;

public nativelib_Start()
{
	CreateNative("GetClientStammPoints", nativelib_GetClientStammPoints);
	CreateNative("GetClientStammLevel", nativelib_GetClientStammLevel);
	CreateNative("GetStammLevelPoints", nativelib_GetStammLevelPoints);
	CreateNative("GetStammLevelName", nativelib_GetStammLevelName);
	CreateNative("GetStammLevelNumber", nativelib_GetStammLevelNumber);
	CreateNative("GetStammType", nativelib_GetStammType);
	CreateNative("GetStammGame", nativelib_GetStammGame);
	CreateNative("GetStammLevelCount", nativelib_GetStammLevelCount);
	CreateNative("SetClientStammPoints", nativelib_SetClientStammPoints);
	CreateNative("AddClientStammPoints", nativelib_AddClientStammPoints);
	CreateNative("DelClientStammPoints", nativelib_DelClientStammPoints);
	CreateNative("IsClientVip", nativelib_IsClientVip);
	CreateNative("AddStammFeature", nativelib_AddFeature);
	CreateNative("AddStammFeatureInfo", nativelib_AddFeatureInfo);
	CreateNative("IsStammClientValid", nativelib_IsClientValid);
	CreateNative("IsClientStammAdmin", nativelib_IsClientStammAdmin);
	CreateNative("ClientWantStammFeature", nativelib_ClientWantStammFeature);
	CreateNative("StartHappyHour", nativelib_StartHappyHour);
	CreateNative("EndHappyHour", nativelib_EndHappyHour);
	CreateNative("LoadFeature", nativelib_LoadFeature);
	CreateNative("UnloadFeature", nativelib_UnloadFeature);
	CreateNative("WriteToStammLog", nativelib_WriteToStammLog);
	
	nativelib_stamm_ready = CreateGlobalForward("OnStammReady", ET_Event);
	nativelib_client_ready = CreateGlobalForward("OnStammClientReady", ET_Event, Param_Cell);
	nativelib_client_save = CreateGlobalForward("OnStammSaveClient", ET_Event, Param_Cell);
	nativelib_player_stamm = CreateGlobalForward("OnClientBecomeVip", ET_Event, Param_Cell);
	nativelib_client_change = CreateGlobalForward("OnClientChangeStammFeature", ET_Event, Param_Cell, Param_String, Param_Cell);
	nativelib_stamm_get = CreateGlobalForward("OnClientGetStammPoints", ET_Event, Param_Cell, Param_Cell);
	nativelib_happy_start = CreateGlobalForward("OnHappyHourStart", ET_Event, Param_Cell, Param_Cell);
	nativelib_happy_end = CreateGlobalForward("OnHappyHourEnd", ET_Event);
	
	RegPluginLibrary("stamm");
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

public nativelib_ClientChanged(client, String:basename[], status)
{
	Call_StartForward(nativelib_client_change);
	
	Call_PushCell(client);
	Call_PushString(basename);
	Call_PushCell(status);
	
	Call_Finish();
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

public nativelib_GetClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (clientlib_isValidClient(client)) return g_playerpoints[client];
	
	return -1;
}

public nativelib_GetClientStammLevel(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (clientlib_isValidClient(client)) return g_playerlevel[client];
	
	return -1;
}

public nativelib_GetStammLevelPoints(Handle:plugin, numParams)
{
	new type = GetNativeCell(1);
	
	if (type <= g_levels && type > 0) return g_LevelPoints[type-1];
	
	return -1;
}

public nativelib_GetStammLevelCount(Handle:plugin, numParams)
{
	return g_levels;
}

public nativelib_GetStammLevelName(Handle:plugin, numParams)
{
	new type = GetNativeCell(1);
	new len = GetNativeCell(3);
	
	if (type <= g_levels && type > 0)
	{
		SetNativeString(2, g_LevelName[type-1], len, false);
		return 1;
	}
	
	return 0;
}

public nativelib_GetStammLevelNumber(Handle:plugin, numParams)
{
	new String:name[64];
	
	GetNativeString(1, name, sizeof(name));
	
	for (new i=0; i < g_levels; i++)
	{
		if (StrEqual(g_LevelName[i], name, false)) return i+1;
	}
	
	return 0;
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
				
				g_HappyTimer = CreateTimer(float(time)*60, otherlib_StopHappyHour);
				
				nativelib_HappyStart(time, factor);
				
				CPrintToChatAll("%s %T", g_StammTag, "HappyActive", LANG_SERVER, g_points);
				
				return 1;
			}
		}
		else ThrowNativeError(2, "[ Stamm ] Factor is invalid");
	}
	else ThrowNativeError(1, "[ Stamm ] Time is invalid");
	
	return 0;
}

public nativelib_EndHappyHour(Handle:plugin, numParams)
{
	if (g_happyhouron)
	{
		otherlib_EndHappyHour();
		
		return 1;
	}
	return 0;
}

public nativelib_ClientWantStammFeature(Handle:plugin, numParams)
{
	new String:basename[64];
	
	new client = GetNativeCell(1);
	GetNativeString(2, basename, sizeof(basename));

	if (clientlib_isValidClient(client))
	{
		for (new i=0; i < g_features; i++)
		{
			if (StrEqual(g_FeatureBase[i], basename, false)) return g_WantFeature[i][client];
		}

	}
	return -1;
}


public nativelib_SetClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new pointschange = GetNativeCell(2);
	
	if (clientlib_isValidClient(client)) 
	{
		if (pointschange >= 0)
		{
			if (pointschange < 0) pointschange = 0;
			
			g_playerpoints[client] = pointschange;
			clientlib_CheckVip(client);
			
			return 1;
		}
	}
	return 0;
}

public nativelib_AddClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new pointschange = GetNativeCell(2);
	
	if (clientlib_isValidClient(client)) 
	{
		if (pointschange > 0)
		{
			g_playerpoints[client] = g_playerpoints[client] + pointschange;
			nativelib_PublicPlayerGetPoints(client, pointschange);
			clientlib_CheckVip(client);
			
			return 1;
		}
	}
	return 0;
}

public nativelib_DelClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new pointschange = GetNativeCell(2);
	
	if (clientlib_isValidClient(client)) 
	{
		if (pointschange > 0)
		{
			g_playerpoints[client] = g_playerpoints[client] - pointschange;
			if (g_playerpoints[client] < 0) g_playerpoints[client] = 0;
			
			nativelib_PublicPlayerGetPoints(client, pointschange*-1);
			clientlib_CheckVip(client);
			
			return 1;
		}
	}
	return 0;
}

public nativelib_AddFeature(Handle:plugin, numParams)
{
	new String:basename[64];
	new String:name[64];
	new String:description[256];
	
	GetNativeString(1, basename, sizeof(basename));
	GetNativeString(2, name, sizeof(name));
	GetNativeString(3, description, sizeof(description));
	new bool:allowChange = GetNativeCell(4);
	
	return featurelib_addFeature(basename, name, description, allowChange);
}

public nativelib_AddFeatureInfo(Handle:plugin, numParams)
{
	new String:basename[64];
	new level = GetNativeCell(2);
	new String:description[256];
	
	GetNativeString(1, basename, sizeof(basename));
	GetNativeString(3, description, sizeof(description));
	
	for (new i=0; i < g_features; i++)
	{
		if (StrEqual(g_FeatureBase[i], basename, false))
		{
			Format(g_FeatureHaveDesc[i][level], 256, description);
			
			return 1;
		}
	}
	return 0;
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
			if (g_playerlevel[client] > 0) return true;
			else return false;
		}
		if (min)
		{
			if (g_playerlevel[client] >= type) return true;
			else return false;
		}
		else
		{
			if (g_playerlevel[client] == type) return true;
			else return false;
		}
	}

	return false;
}

public nativelib_LoadFeature(Handle:plugin, numParams)
{
	new String:basename[64];

	GetNativeString(1, basename, sizeof(basename));

	for (new i=0; i < g_features; i++)
	{
		if (StrEqual(g_FeatureBase[i], basename, false))
		{
			if (g_FeatureEnable[i] == 1) return -1;
			else
			{
				featurlib_loadFeature(basename);
				return 1;
			}
		}
	}
	return 0;
}

public nativelib_UnloadFeature(Handle:plugin, numParams)
{
	new String:basename[64];

	GetNativeString(1, basename, sizeof(basename));

	for (new i=0; i < g_features; i++)
	{
		if (StrEqual(g_FeatureBase[i], basename, false))
		{
			if (g_FeatureEnable[i] == 0) return -1;
			else
			{
				featurlib_UnloadFeature(basename);
				return 1;
			}
		}
	}
	return 0;
}

public nativelib_WriteToStammLog(Handle:plugin, numParams)
{
	new String:buffer[1024];
	new written;
	
	FormatNativeString(0, 1, 2, sizeof(buffer), written, buffer);
	  
	LogToFile(g_LogFile, "[ STAMM ] %s", buffer);
}