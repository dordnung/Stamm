public sqlback_getDatabaseVersion()
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[128];
		
		Format(query, sizeof(query), "SELECT `version` FROM `%s` WHERE version <> '' LIMIT 1", g_tablename);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			
		SQL_TQuery(sqllib_db, sqlback_getVersion, query);
	}
}

public sqlback_getVersion(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE && StrEqual(error, "") && SQL_FetchRow(hndl))
		SQL_FetchString(hndl, 0, g_databaseVersion, sizeof(g_databaseVersion));
	else
		Format(g_databaseVersion, sizeof(g_databaseVersion), "0.0");
		
	if (!StrEqual(g_databaseVersion, g_Plugin_Version))
		sqlback_ModifyTableBackwards();
	else
		stammStarted();
}

public sqlback_syncSteamid(client)
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[128];
		decl String:steamid[64];
		
		clientlib_getSteamid(client, steamid, sizeof(steamid));
		ReplaceString(steamid, sizeof(steamid), "STEAM_0:", "STEAM_1:");
		
		Format(query, sizeof(query), "SELECT `points` FROM `%s` WHERE `steamid`='%s'", g_tablename, steamid);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			
		SQL_TQuery(sqllib_db, sqlback_syncSteamid1, query, client);
	}
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
}

public sqlback_ModifyVersion()
{
	decl String:query[128];
			
	Format(query, sizeof(query), "ALTER TABLE `%s` ADD `version` VARCHAR(30) NOT NULL DEFAULT ''", g_tablename);
	
	if (g_debug) 
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);

	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
	
	Format(query, sizeof(query), "ALTER TABLE `%s` DROP `payed`", g_tablename);
	
	if (g_debug) 
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);

	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
	
	Format(query, sizeof(query), "UPDATE `%s` SET `version` = '%s'", g_tablename, g_Plugin_Version);
	
	if (g_debug) 
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);

	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
}

public sqlback_ModifyTableBackwards()
{
	if (!StrEqual(g_databaseVersion, "2.1"))
	{
		if (sqllib_db != INVALID_HANDLE)
		{
			sqlback_ModifyVersion();
			
			decl String:query[128];
			
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
		
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `%s_backup` (`steamid` VARCHAR(20) NOT NULL DEFAULT '', `level` INT NOT NULL DEFAULT 0, `points` INT NOT NULL DEFAULT 0, `name` VARCHAR(255) NOT NULL DEFAULT '', `version` VARCHAR(30) NOT NULL DEFAULT '%s', PRIMARY KEY (`steamid`))", g_tablename, g_Plugin_Version);
		
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
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`, `version`) SELECT `steamid`, `name`, `level`, `kills`, `version` FROM `%s`", g_tablename, g_tablename);
		else if (g_vip_type == 2) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`, `version`) SELECT `steamid`, `name`, `level`, `rounds`, `version` FROM `%s`", g_tablename, g_tablename);
		else if (g_vip_type == 3) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`, `version`) SELECT `steamid`, `name`, `level`, `time`, `version` FROM `%s`", g_tablename, g_tablename);
		else if (g_vip_type == 4) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`, `version`) SELECT `steamid`, `name`, `level`, `kills`+`rounds`, `version` FROM `%s`", g_tablename, g_tablename);
		else if (g_vip_type == 5) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`, `version`) SELECT `steamid`, `name`, `level`, `kills`+`time`, `version` FROM `%s`", g_tablename, g_tablename);
		else if (g_vip_type == 6) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`, `version`) SELECT `steamid`, `name`, `level`, `rounds`+`time`, `version` FROM `%s`", g_tablename, g_tablename);
		else if (g_vip_type == 7) 
			Format(query, sizeof(query), "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`, `version`) SELECT `steamid`, `name`, `level`, `kills`+`rounds`+`time`, `version` FROM `%s`", g_tablename, g_tablename);
		else 
			return;
			
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			
		SQL_TQuery(sqllib_db, sqlback_SQLModify3, query);
	}
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
}

public sqlback_SQLModify5(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
		stammStarted();
}