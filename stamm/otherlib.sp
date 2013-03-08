#pragma semicolon 1

new Handle:otherlib_inftimer;

public otherlib_PrepareFiles()
{
	if (!StrEqual(g_lvl_up_sound, "0")) 
	{
		otherlib_DownloadLevel();	
		PrecacheSound(g_lvl_up_sound, true);
	}
}

public otherlib_DownloadLevel()
{
	decl String:downloadfile[PLATFORM_MAX_PATH + 1];
	
	Format(downloadfile, sizeof(downloadfile), "sound/%s", g_lvl_up_sound);
	
	AddFileToDownloadsTable(downloadfile);
}

public otherlib_getGame()
{
	return g_gameID;
}

public otherlib_saveGame()
{
	new String:GameName[12];
	g_gameID = 0;
	
	GetGameFolderName(GameName, sizeof(GameName));
	
	if (StrEqual(GameName, "cstrike")) 
		g_gameID = 1;
	if (StrEqual(GameName, "csgo")) 
		g_gameID = 2;
	if (StrEqual(GameName, "tf")) 
		g_gameID = 3;
	if (StrEqual(GameName, "dod"))
		g_gameID = 4;
}

public Action:otherlib_commandListener(client, const String:command[], argc)
{
	decl String:arg[128];
	new mode = 0;

	if (argc == 3 && client == 0 && StrEqual(command, "sm", false))
	{
		GetCmdArg(1, arg, sizeof(arg));

		if (StrEqual(arg, "plugins", false))
		{
			GetCmdArg(2, arg, sizeof(arg));

			if (StrEqual(arg, "load", false))
				mode = 1;

			if (StrEqual(arg, "unload", false))
				mode = 2;

			if (StrEqual(arg, "reload", false))
				mode = 3;

			if (mode != 0)
			{
				GetCmdArgString(arg, sizeof(arg));

				GetCmdArg(3, arg, sizeof(arg));

				for (new i=0; i < g_features; i++)
				{
					if (StrEqual(arg, g_FeatureList[i][FEATURE_BASE], false) || StrEqual(arg, g_FeatureList[i][FEATURE_BASEREAL], false))
					{
						if (mode == 1)
							featurelib_loadFeature(g_FeatureList[i][FEATURE_HANDLE]);

						if (mode == 2)
							featurelib_UnloadFeature(g_FeatureList[i][FEATURE_HANDLE]);

						if (mode == 3)
							featurelib_ReloadFeature(g_FeatureList[i][FEATURE_HANDLE]);

						PrintToServer("Attention: Found Stamm Feature! Action will transmit to Stamm");

						return Plugin_Handled;
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:otherlib_PlayerInfoTimer(Handle:timer, any:data)
{
	CPrintToChatAll("%s %t", g_StammTag, "InfoTyp", g_texttowrite_f);
	CPrintToChatAll("%s %t", g_StammTag, "InfoTypInfo", g_sinfo_f);
	
	return Plugin_Continue;
}

public otherlib_MakeHappyHour(client)
{
	g_happynumber[client] = 1;
	
	CPrintToChat(client, "%s %t", g_StammTag, "WriteHappyTime");
	CPrintToChat(client, "%s %t", g_StammTag, "WriteHappyTimeInfo");
}

public otherlib_EndHappyHour()
{
	if (g_happyhouron)
	{
		decl String:query[128];

		Format(query, sizeof(query), "DELETE FROM `%s_happy`", g_tablename);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);

		g_points = 1;
		g_happyhouron = 0;
		
		otherlib_checkTimer(g_HappyTimer);
		
		CPrintToChatAll("%s %t", g_StammTag, "HappyEnded");
		
		nativelib_HappyEnd();
		
		clientlib_CheckPlayers();
	}
}

public otherlib_StartHappyHour(time, factor)
{
	decl String:query[128];

	Format(query, sizeof(query), "INSERT INTO `%s_happy` (`end`, `factor`) VALUES (%i, %i)", g_tablename, GetTime() + time, factor);
	
	if (g_debug) 
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
	
	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);

	g_points = factor;

	g_happyhouron = 1;
	
	CPrintToChatAll("%s %t", g_StammTag, "HappyActive", g_points);
	
	otherlib_checkTimer(g_HappyTimer);

	g_HappyTimer = CreateTimer(float(time), otherlib_StopHappyHour);
	
	nativelib_HappyStart(time/60, g_points);
}

public Action:otherlib_StopHappyHour(Handle:timer)
{
	otherlib_EndHappyHour();
}

public Action:otherlib_StartHappy(args)
{
	if (GetCmdArgs() == 2 && !g_happyhouron)
	{
		decl String:timeString[25];
		decl String:factorString[25];
		
		GetCmdArg(1, timeString, sizeof(timeString));
		GetCmdArg(2, factorString, sizeof(factorString));
		
		new time = StringToInt(timeString);

		if (time > 1 && StringToInt(factorString) > 1)
			otherlib_StartHappyHour(time*60, StringToInt(factorString));
		else
			ReplyToCommand(0, "[ STAMM ] Time and Factor have to be greater than 1 !");
	}
	else
		ReplyToCommand(0, "Usage: stamm_start_happyhour <time> <factor>");
}

public Action:otherlib_StopHappy(args)
{
	otherlib_EndHappyHour();
}

public otherlib_checkTimer(Handle:timer)
{
	if (timer != INVALID_HANDLE)
		CloseHandle(timer);

	timer = INVALID_HANDLE;
}