new Handle:otherlib_inftimer;

public otherlib_PrepareFiles()
{
	if (!StrEqual(g_lvl_up_sound, "0")) otherlib_DownloadLevel();	
	if (!StrEqual(g_lvl_up_sound, "0")) PrecacheSound(g_lvl_up_sound, true);
}

public otherlib_DownloadLevel()
{
	new String:downloadfile[PLATFORM_MAX_PATH + 1];
	
	Format(downloadfile, sizeof(downloadfile), "sound/%s", g_lvl_up_sound);
	
	AddFileToDownloadsTable(downloadfile);
}

public otherlib_getGame()
{
	new String:GameName[64];
	
	GetGameFolderName(GameName, sizeof(GameName));
	
	if (StrEqual(GameName, "cstrike")) return 1;
	if (StrEqual(GameName, "csgo")) return 2;
	if (StrEqual(GameName, "tf")) return 3;
	
	return 0;
}

public otherlib_createDB()
{
	new String:dbPath[PLATFORM_MAX_PATH + 1];
	
	BuildPath(Path_SM, dbPath, sizeof(dbPath), "configs/databases.cfg");
	
	new Handle:dbHandle = CreateKeyValues("Databases");
	FileToKeyValues(dbHandle, dbPath);
	
	if (!KvJumpToKey(dbHandle, "stamm_sql"))
	{
		KvJumpToKey(dbHandle, "stamm_sql", true);
		
		KvSetString(dbHandle, "driver", "sqlite");
		KvSetString(dbHandle, "host", "localhost");
		KvSetString(dbHandle, "database", "Stamm-DB");
		KvSetString(dbHandle, "user", "root");
		
		KvGoBack(dbHandle);
		
		KeyValuesToFile(dbHandle, dbPath);
		
		for (new i=0; i <= 20; i++) PrintToServer("Created Stamm DB. To use Stamm, please restart your Server now!!");
	}
}

public Action:otherlib_PlayerInfoTimer(Handle:timer)
{
	CPrintToChatAll("%s %T", g_StammTag, "InfoTyp", LANG_SERVER, g_texttowrite_f);
	
	CPrintToChatAll("%s %T", g_StammTag, "InfoTypInfo", LANG_SERVER, g_sinfo_f);
	
	return Plugin_Continue;
}

public otherlib_MakeHappyHour(client)
{
	g_happynumber[client] = 1;
	CPrintToChat(client, "%s %T", g_StammTag, "WriteHappyTime", LANG_SERVER);
	CPrintToChat(client, "%s %T", g_StammTag, "WriteHappyTimeInfo", LANG_SERVER);
}

public otherlib_EndHappyHour()
{
	if (g_happyhouron)
	{
		g_points = 1;
		g_happyhouron = 0;
		
		if (g_HappyTimer != INVALID_HANDLE) KillTimer(g_HappyTimer);
		
		g_HappyTimer = INVALID_HANDLE;
		
		CPrintToChatAll("%s %T", g_StammTag, "HappyEnded", LANG_SERVER);
		
		nativelib_HappyEnd();
		
		clientlib_CheckPlayers();
	}
}

public Action:otherlib_StopHappyHour(Handle:timer)
{
	if (g_happyhouron)
	{
		g_happyhouron = 0;
		g_points = 1;
		g_HappyTimer = INVALID_HANDLE;
		
		CPrintToChatAll("%s %T", g_StammTag, "HappyEnded", LANG_SERVER);
		
		nativelib_HappyEnd();
		
		clientlib_CheckPlayers();
	}
}

public Action:otherlib_StartHappy(args)
{
	if (GetCmdArgs() == 2 && !g_happyhouron)
	{
		new String:timeString[25];
		new String:factorString[25];
		
		GetCmdArg(1, timeString, sizeof(timeString));
		GetCmdArg(2, factorString, sizeof(factorString));
		
		new time = StringToInt(timeString);
		g_points = StringToInt(factorString);
		
		g_happyhouron = 1;
		
		CPrintToChatAll("%s %T", g_StammTag, "HappyActive", LANG_SERVER, g_points);
	
		g_HappyTimer = CreateTimer(float(time)*60, otherlib_StopHappyHour);
		
		nativelib_HappyStart(time, g_points);
	}
}

public Action:otherlib_StopHappy(args)
{
	if (g_happyhouron)
	{
		g_points = 1;
		g_happyhouron = 0;
		
		if (g_HappyTimer != INVALID_HANDLE) KillTimer(g_HappyTimer);
		
		g_HappyTimer = INVALID_HANDLE;
		
		CPrintToChatAll("%s %T", g_StammTag, "HappyEnded", LANG_SERVER);
		
		nativelib_HappyEnd();
		
		clientlib_CheckPlayers();
	}
}
