#pragma semicolon 1

public sqlback_getDatabaseVersion()
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[128];
		
		Format(query, sizeof(query), "SELECT `version` FROM `%s` ORDER BY `version` DESC LIMIT 1", g_tablename);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			
		SQL_TQuery(sqllib_db, sqlback_getVersion, query);

		Format(query, sizeof(query), "SELECT `end`, `factor` FROM `%s_happy` WHERE `end` > %i LIMIT 1", g_tablename, GetTime());
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			
		SQL_TQuery(sqllib_db, sqlback_getHappy, query);
	}
}

public sqlback_getVersion(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE && StrEqual(error, "") && SQL_FetchRow(hndl))
		SQL_FetchString(hndl, 0, g_databaseVersion, sizeof(g_databaseVersion));
	else
		Format(g_databaseVersion, sizeof(g_databaseVersion), "0.0");

	if (StringToFloat(g_databaseVersion) < StringToFloat(g_Plugin_Version))
		sqlback_ModifyTableBackwards();
	else
		stammStarted();
}

public sqlback_getHappy(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE && StrEqual(error, "") && SQL_FetchRow(hndl))
	{
		new end = SQL_FetchInt(hndl, 0);
		new factor = SQL_FetchInt(hndl, 1);

		new time = GetTime();

		if (end > time)
			otherlib_StartHappyHour(end-time, factor);
	}
}

public bool:sqlback_syncSteamid(client, Float:version)
{
	if (sqllib_db != INVALID_HANDLE && version < 2.1)
	{
		decl String:query[128];
		decl String:steamid[64];
		
		clientlib_getSteamid(client, steamid, sizeof(steamid));
		ReplaceString(steamid, sizeof(steamid), "STEAM_0:", "STEAM_1:");
		
		Format(query, sizeof(query), "SELECT `points` FROM `%s` WHERE `steamid`='%s'", g_tablename, steamid);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			
		SQL_TQuery(sqllib_db, sqlback_syncSteamid1, query, client);

		return true;
	}

	return false;
}

public sqlback_syncSteamid1(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl != INVALID_HANDLE && StrEqual(error, "") && SQL_FetchRow(hndl) && clientlib_isValidClient_PRE(client))
	{
		decl String:query[128];
		decl String:steamid[64];
		
		clientlib_getSteamid(client, steamid, sizeof(steamid));
		ReplaceString(steamid, sizeof(steamid), "STEAM_0:", "STEAM_1:");
		
		pointlib_GivePlayerPoints(client, SQL_FetchInt(hndl, 0));

		Format(query, sizeof(query), "DELETE FROM `%s` WHERE `steamid`='%s'", g_tablename, steamid);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
	}

	clientlib_ClientReady(client);
}

public sqlback_ModifyVersion()
{
	decl String:query[128];
			
	Format(query, sizeof(query), "ALTER TABLE `%s` ADD `version` FLOAT NOT NULL DEFAULT 0.0", g_tablename);
	
	if (g_debug) 
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);

	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
	
	Format(query, sizeof(query), "ALTER TABLE `%s` DROP `payed`", g_tablename);
	
	if (g_debug) 
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);

	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
}

public sqlback_ModifyTableBackwards()
{
	decl String:query[128];

	if (StringToFloat(g_databaseVersion) < 2.1)
	{
		if (sqllib_db != INVALID_HANDLE)
		{
			sqlback_ModifyVersion();
			
			Format(query, sizeof(query), "SELECT `points` FROM `%s`", g_tablename);
			
			if (g_debug) 
				LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
				
			SQL_TQuery(sqllib_db, sqlback_SQLModify1, query);
		}
	}
}

public sqlback_SQLModify1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE || !StrEqual(error, ""))
	{
		decl String:query[600];
		
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `%s_backup` (`steamid` VARCHAR(20) NOT NULL DEFAULT '', `level` INT NOT NULL DEFAULT 0, `points` INT NOT NULL DEFAULT 0, `name` VARCHAR(255) NOT NULL DEFAULT '', `version` FLOAT NOT NULL DEFAULT 0.0, PRIMARY KEY (`steamid`))", g_tablename, g_Plugin_Version);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		SQL_TQuery(sqllib_db, sqlback_SQLModify2, query);
	}
	else
		stammStarted();
}

public sqlback_SQLModify2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		decl String:query[600];
		
		if (g_vip_type == 1) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`) SELECT `steamid`, `name`, `level`, `kills` FROM `%s`", g_tablename, g_tablename);
		else if (g_vip_type == 2) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`) SELECT `steamid`, `name`, `level`, `rounds` FROM `%s`", g_tablename, g_tablename);
		else if (g_vip_type == 3) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`) SELECT `steamid`, `name`, `level`, `time` FROM `%s`", g_tablename, g_tablename);
		else if (g_vip_type == 4) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`) SELECT `steamid`, `name`, `level`, `kills`+`rounds` FROM `%s`", g_tablename, g_tablename);
		else if (g_vip_type == 5) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`) SELECT `steamid`, `name`, `level`, `kills`+`time` FROM `%s`", g_tablename, g_tablename);
		else if (g_vip_type == 6) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`) SELECT `steamid`, `name`, `level`, `rounds`+`time` FROM `%s`", g_tablename, g_tablename);
		else if (g_vip_type == 7) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`) SELECT `steamid`, `name`, `level`, `kills`+`rounds`+`time` FROM `%s`", g_tablename, g_tablename);
		else 
			return;
			
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			
		SQL_TQuery(sqllib_db, sqlback_SQLModify3, query);
	}
	else
		SetFailState("Error converting Stamm to the newest database structur. Error:   %s", error);
}

public sqlback_SQLModify3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		decl String:query[128];
		
		Format(query, sizeof(query), "ALTER TABLE `%s` RENAME TO `%s_old`", g_tablename, g_tablename);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			
		SQL_TQuery(sqllib_db, sqlback_SQLModify4, query);
	}
	else
		SetFailState("Error converting Stamm to the newest database structur. Error:   %s", error);
}

public sqlback_SQLModify4(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		decl String:query[128];
		
		Format(query, sizeof(query), "ALTER TABLE `%s_backup` RENAME TO `%s`", g_tablename, g_tablename);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		SQL_TQuery(sqllib_db, sqlback_SQLModify5, query);
	}
	else
		SetFailState("Error converting Stamm to the newest database structur. Error:   %s", error);
}

public sqlback_SQLModify5(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
		stammStarted();
	else
		SetFailState("Error converting Stamm to the newest database structur. Error:   %s", error);
}