#pragma semicolon 1

new Handle:sqllib_db;
new sqllib_convert = -1;

public sqllib_Start()
{
	Format(g_viplist_f, sizeof(g_viplist_f), g_viplist);
	Format(g_viprank_f, sizeof(g_viprank_f), g_viprank);

	if (!StrContains(g_viplist, "sm_"))
	{
		RegConsoleCmd(g_viplist, sqllib_GetVipTop);
		
		ReplaceString(g_viplist_f, sizeof(g_viplist_f), "sm_", "!");
	}
	
	if (!StrContains(g_viprank, "sm_"))
	{
		RegConsoleCmd(g_viprank, sqllib_GetVipRank);
	
		ReplaceString(g_viprank_f, sizeof(g_viprank_f), "sm_", "!");
	}
}

public sqllib_LoadDB()
{
	decl String:sqlError[255];

	if (!SQL_CheckConfig("stamm_sql")) 
	{
		new Handle:keys = sqllib_createDB();

		sqllib_db = SQL_ConnectCustom(keys, sqlError, sizeof(sqlError), true);

		CloseHandle(keys);
	}
	else
		sqllib_db = SQL_Connect("stamm_sql", true, sqlError, sizeof(sqlError));
	
	if (sqllib_db == INVALID_HANDLE)
	{
		LogToFile(g_LogFile, "[ STAMM DEBUG ] Stamm couldn't connect to the Database!! Error: %s", sqlError);

		SetFailState("[ STAMM ] Stamm couldn't connect to the Database!! Error: %s", sqlError);
	}
	else 
	{
		decl String:query[620];
		
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `%s` (`steamid` VARCHAR(21) NOT NULL DEFAULT '', `level` INT NOT NULL DEFAULT 0, `points` INT NOT NULL DEFAULT 0, `name` VARCHAR(64) NOT NULL DEFAULT '', `version` FLOAT NOT NULL DEFAULT 0.0, `last_visit` INT UNSIGNED NOT NULL DEFAULT %i, PRIMARY KEY (`steamid`))", g_tablename, GetTime());
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		if (!SQL_FastQuery(sqllib_db, query))
		{
			SQL_GetError(sqllib_db, sqlError, sizeof(sqlError));
			
			LogToFile(g_LogFile, "[ STAMM ] Couldn't create Table. Error: %s", sqlError);
		}

		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `%s_happy` (`end` INT UNSIGNED NOT NULL DEFAULT 2, `factor` TINYINT UNSIGNED NOT NULL DEFAULT 2)", g_tablename);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		if (!SQL_FastQuery(sqllib_db, query))
		{
			SQL_GetError(sqllib_db, sqlError, sizeof(sqlError));
			
			LogToFile(g_LogFile, "[ STAMM ] Couldn't create Happy Table. Error: %s", sqlError);
		}
		
		else if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Connected to Database successfully");
	}
}

public Handle:sqllib_createDB()
{
	new Handle:dbHandle = CreateKeyValues("Databases");
	
	KvSetString(dbHandle, "driver", "sqlite");
	KvSetString(dbHandle, "host", "localhost");
	KvSetString(dbHandle, "database", "Stamm-DB");
	KvSetString(dbHandle, "user", "root");
	
	return dbHandle;
}

public sqllib_InsertPlayer(client)
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[4024];
		decl String:steamid[64];
		
		clientlib_getSteamid(client, steamid, sizeof(steamid));
		
		Format(query, sizeof(query), "SELECT `points`, `level`, `version`");
		
		for (new i=0; i < g_features; i++) 
			Format(query, sizeof(query), "%s, `%s`", query, g_FeatureList[i][FEATURE_BASE]);

		Format(query, sizeof(query), "%s FROM `%s` WHERE steamid = '%s'", query, g_tablename, steamid);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);

		SQL_TQuery(sqllib_db, sqllib_InsertHandler, query, client);
	}
}

public sqllib_AddColumn(String:name[], bool:standard)
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[256];
		
		if (standard)
			Format(query, sizeof(query), "ALTER TABLE `%s` ADD `%s` INT NOT NULL DEFAULT 1", g_tablename, name);
		else
			Format(query, sizeof(query), "ALTER TABLE `%s` ADD `%s` INT NOT NULL DEFAULT 0", g_tablename, name);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);

		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
	}
}

public sqllib_InsertHandler(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl != INVALID_HANDLE)
	{
		decl String:name[MAX_NAME_LENGTH + 1];
		decl String:name2[2 * MAX_NAME_LENGTH + 2];
		decl String:steamid[64];
		decl String:query[512];
		
		if (clientlib_isValidClient_PRE(client))
		{
			g_pointsnumber[client] = 0;
			g_happynumber[client] = 0;
			g_happyfactor[client] = 0;
			g_ClientReady[client] = false;

			clientlib_getSteamid(client, steamid, sizeof(steamid));
			GetClientName(client, name, sizeof(name));
			
			SQL_EscapeString(sqllib_db, name, name2, sizeof(name2));

			if (!SQL_FetchRow(hndl))
			{
				Format(query, sizeof(query), "INSERT INTO `%s` (`steamid`, `name`, `version`, `last_visit`) VALUES ('%s', '%s', %s, %i)", g_tablename, steamid, name2, g_Plugin_Version, GetTime());
				
				if (g_debug) 
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
				
				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				
				g_playerpoints[client] = 0;
				g_playerlevel[client] = 0;
				
				for (new i=0; i < g_features; i++) 
					g_FeatureList[i][WANT_FEATURE][client] = g_FeatureList[i][FEATURE_STANDARD];

				sqlback_syncSteamid(client, 0.0);
			}
			else
			{
				g_playerlevel[client] = SQL_FetchInt(hndl, 1);
				
				for (new i=0; i < g_features; i++)
				{
					if (SQL_FetchInt(hndl, 3+i) == 1)
						g_FeatureList[i][WANT_FEATURE][client] = true;
					else
						g_FeatureList[i][WANT_FEATURE][client] = false;
				}
				
				g_playerpoints[client] = SQL_FetchInt(hndl, 0);
				
				Format(query, sizeof(query), "UPDATE `%s` SET `name`='%s', `version`=%s, `last_visit`=%i WHERE `steamid`='%s'", g_tablename, name2, g_Plugin_Version, GetTime(), steamid);
				
				if (g_debug) 
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
				
				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);

				if (!sqlback_syncSteamid(client, SQL_FetchFloat(hndl, 2)))
					clientlib_ClientReady(client);
			}
		}
	}
	else
		LogToFile(g_LogFile, "[ STAMM ] Error checking Player %N:   %s", client, error);
}

public Action:sqllib_GetVipTop(client, args)
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[128];
		
		Format(query, sizeof(query), "SELECT `name`, `points` FROM `%s` WHERE `level` > 0 ORDER BY `points` DESC LIMIT 10", g_tablename);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
	
		SQL_TQuery(sqllib_db, sqllib_GetVIPTopQuery, query, client);
	}
	
	return Plugin_Handled;
}

public Action:sqllib_GetVipRank(client, args)
{
	if (g_playerlevel[client] <= 0)
	{
		CPrintToChat(client, "%s %t", g_StammTag, "NoVIP");
		
		return Plugin_Handled;
	}
	
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[128];
		
		Format(query, sizeof(query), "SELECT COUNT(*) FROM `%s` WHERE `points` >= %i", g_tablename, g_playerpoints[client]);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		SQL_TQuery(sqllib_db, sqllib_GetVIPRankQuery, query, client);
	}
	
	return Plugin_Handled;
}

public sqllib_GetVIPTopQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl != INVALID_HANDLE)
	{
		if (clientlib_isValidClient(client))
		{
			new Handle:Top10Menu = CreatePanel();
			new index = 0;

			decl String:top_text[128];
			decl String:steamid[64];
			
			clientlib_getSteamid(client, steamid, sizeof(steamid));
			SetPanelTitle(Top10Menu, "TOP VIP's");

			DrawPanelText(Top10Menu, "------------------------------------");

			while (SQL_FetchRow(hndl))
			{
				decl String:name[MAX_NAME_LENGTH+1];
				SQL_FetchString(hndl, 0, name, sizeof(name));
				
				new top_points = SQL_FetchInt(hndl, 1);
				
				Format(top_text, sizeof(top_text), "%i. %s - %i %T", ++index, name, top_points, "Points", client);
				
				DrawPanelText(Top10Menu, top_text);
			}
			
			if (!index)
			{
				CPrintToChat(client, "%s %t", g_StammTag, "NoVips");
				
				return;
			}
			else
			{
				DrawPanelText(Top10Menu, "------------------------------------");

				Format(top_text, sizeof(top_text), "%T", "Close", client);

				DrawPanelItem(Top10Menu, top_text);
			}

			SendPanelToClient(Top10Menu, client, panellib_FeatureHandler, 60);
		}
	}
	else
		LogToFile(g_LogFile, "[ STAMM ] Database Error:   %s", error);
}

public sqllib_GetVIPRankQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl != INVALID_HANDLE)
	{
		if (clientlib_isValidClient(client))
			CPrintToChat(client, "%s %t", g_StammTag, "Rank", SQL_FetchInt(hndl, 0), g_playerpoints[client]);
	}
	else
		LogToFile(g_LogFile, "[ STAMM ] Database Error:   %s", error);
}

public sqllib_SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
		LogToFile(g_LogFile, "[ STAMM ] Database Error: %s", error);
}

public sqllib_SQLErrorCheckCallback2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		if (g_debug)
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Maybe VALID Database Error: %s", error);
	}
}

public Action:sqllib_convertDB(args)
{
	decl String:mysqlString[12];

	if (GetCmdArgs() != 1)
	{
		ReplyToCommand(0, "Usage: stamm_convert_db <mysql>");

		return Plugin_Handled;
	}

	if (sqllib_convert > -1)
	{
		ReplyToCommand(0, "You are already converting the database. Please Wait.");

		return Plugin_Handled;
	}

	GetCmdArg(1, mysqlString, sizeof(mysqlString));

	if (StringToInt(mysqlString) > 1 || StringToInt(mysqlString) < 0)
	{
		ReplyToCommand(0, "Usage: stamm_convert_db <mysql>");

		return Plugin_Handled;
	}

	sqllib_convert = StringToInt(mysqlString);

	decl String:query[128];

	Format(query, sizeof(query), "SELECT `steamid`, `level`, `points`, `name`, `version` FROM `%s`", g_tablename);

	SQL_TQuery(sqllib_db, sqllib_SQLConvertDatabaseToFile, query);

	ReplyToCommand(0, "Converting now Stamm database to a file. Please wait. This could take a bit!");

	return Plugin_Handled;
}

public sqllib_SQLConvertDatabaseToFile(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE && SQL_FetchRow(hndl))
	{
		new String:filename[64];

		new counter = 0;

		Format(filename, sizeof(filename), "%s.sql", g_tablename);

		new Handle:file = OpenFile(filename, "wb");

		if (file != INVALID_HANDLE)
		{
			if (sqllib_convert == 0)
				WriteFileLine(file, "BEGIN TRANSACTION;");

			WriteFileLine(file, "CREATE TABLE IF NOT EXISTS `%s` (`steamid` VARCHAR(21) NOT NULL DEFAULT '', `level` INT NOT NULL DEFAULT 0, `points` INT NOT NULL DEFAULT 0, `name` VARCHAR(64) NOT NULL DEFAULT '', `version` FLOAT NOT NULL DEFAULT 0.0, PRIMARY KEY (`steamid`));", g_tablename);

			do
			{
				new level;
				new points;
				new Float:version;

				decl String:steamid[64];
				decl String:name[128];
				decl String:name2[256];
				decl String:versionS[12];

				level = SQL_FetchInt(hndl, 1);
				points = SQL_FetchInt(hndl, 2);
				version = SQL_FetchFloat(hndl, 4);

				FloatToString(version, versionS, sizeof(versionS));

				SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
				SQL_FetchString(hndl, 3, name, sizeof(name));

				sqllib_escapeString(name, name2, sizeof(name2), sqllib_convert);

				if (sqllib_convert == 0)
					WriteFileLine(file, "INSERT INTO `%s` (`steamid`, `level`, `points`, `name`, `version`) VALUES ('%s', %i, %i, '%s', %s);", g_tablename, steamid, level, points, name2, versionS);
				else
				{
					if (counter == 0)
						WriteFileLine(file, "INSERT INTO `%s` (`steamid`, `level`, `points`, `name`, `version`) VALUES", g_tablename);

					if (++counter == 1000 || !SQL_MoreRows(hndl))
					{
						WriteFileLine(file, "('%s', %i, %i, '%s', %s);", steamid, level, points, name2, versionS);

						counter = 0;
					}
					else
						WriteFileLine(file, "('%s', %i, %i, '%s', %s),", steamid, level, points, name2, versionS);
				}

			} 
			while (SQL_FetchRow(hndl) && sqllib_convert > -1);

			if (sqllib_convert == 0)
				WriteFileLine(file, "COMMIT;");

			CloseHandle(file);

			PrintToServer("Converted Database to file %s successfully", filename);
		}
		else
			PrintToServer("Couldn't convert database to file. Couldn't create file %s", filename);
	}
	else
		PrintToServer("Couldn't convert database to file. Error: ", error);

	sqllib_convert = -1;
}

public sqllib_escapeString(String:input[], String:output[], maxlen, mysql)
{
	new len = strlen(input);
	new count = 0;

	Format(output, maxlen, "");

	if (mysql == 1)
	{
		for (new offset=0; offset < len; offset++)
		{
			new ch = input[offset];

			switch(ch)
			{
				case '\'':
				{
					if (count % 2 == 0)
						Format(output, maxlen, "%s\\", output);

					count = 0;
					Format(output, maxlen, "%s%c", output, ch);
				}
				case '\\':
				{
					count++;
					Format(output, maxlen, "%s%c", output, ch);
				}
				default:
				{
					count = 0;
					Format(output, maxlen, "%s%c", output, ch);
				}
			}
		}

		if (count != 0)
		{
			if (count % 2 == 1)
				Format(output, maxlen, "%s\\", output);
		}
	}
	else	
	{
		for (new offset=0; offset < len; offset++)
		{
			new ch = input[offset];

			switch(ch)
			{
				case '\'':
				{
					count++;

					Format(output, maxlen, "%s%c", output, ch);
				}
				default:
				{
					if (count % 2 == 1)
						Format(output, maxlen, "%s'", output);

					count = 0;
					Format(output, maxlen, "%s%c", output, ch);
				}
			}
		}

		if (count != 0)
		{
			if (count % 2 == 1)
				Format(output, maxlen, "%s'", output);
		}
	}
}