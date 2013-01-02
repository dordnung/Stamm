new Handle:sqllib_db;

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
	new String:sqlError[255];
	
	sqllib_db = SQL_Connect("stamm_sql", true, sqlError, sizeof(sqlError));
	
	if (sqllib_db == INVALID_HANDLE)
	{
		LogToFile(g_LogFile, "[ STAMM ] Stamm couldn't connect to the Database!! Error: %s", sqlError);
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Stamm couldn't connect to the Database!! Error: %s", sqlError);
	}
	else 
	{
		new String:query[620];
		
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s (steamid VARCHAR( 20 ) NOT NULL DEFAULT '', level INT(3) NOT NULL DEFAULT 0, points INT( 255 ) NOT NULL DEFAULT 0, name VARCHAR( 255 ) NOT NULL DEFAULT '', payed INT(255) NOT NULL DEFAULT 0, PRIMARY KEY (steamid))", g_tablename);
		
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		if (!SQL_FastQuery(sqllib_db, query))
		{
			SQL_GetError(sqllib_db, sqlError, sizeof(sqlError));
			LogToFile(g_LogFile, "[ STAMM ] Error in sqllib! Error: %s", sqlError);
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Error in sqllib! Error: %s", sqlError);
		}
		
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Connected to Database");
	}
}

public sqllib_InsertPlayer(client)
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[2024];
		new String:steamid[64];
		
		GetClientAuthString(client, steamid, sizeof(steamid));
		
		Format(query, sizeof(query), "SELECT points, level");
		
		for (new i=0; i < g_features; i++) Format(query, sizeof(query), "%s, %s", query, g_FeatureBase[i]);

		Format(query, sizeof(query), "%s FROM %s WHERE steamid = '%s'", query, g_tablename, steamid);
		
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);

		SQL_TQuery(sqllib_db, sqllib_InsertHandler, query, client);
	}
}

public sqllib_AddColumn(String:name[])
{
	if (sqllib_db != INVALID_HANDLE)
	{
		new String:query[256];

		Format(query, sizeof(query), "ALTER TABLE %s ADD %s INT(1) NOT NULL DEFAULT 1", g_tablename, name);
		
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);

		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
	}
}

public sqllib_ModifyTableBackwards()
{
	if (sqllib_db != INVALID_HANDLE)
	{
		new String:query[64];
		
		Format(query, sizeof(query), "SELECT points FROM %s", g_tablename);
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		SQL_TQuery(sqllib_db, sqllib_SQLModify1, query);
	}
}

public sqllib_SQLModify1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE || !StrEqual(error, ""))
	{
		new String:query[600];
		
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s_backup (steamid VARCHAR( 20 ) NOT NULL DEFAULT '', level INT(3) NOT NULL DEFAULT 0, points INT( 255 ) NOT NULL DEFAULT 0, name VARCHAR( 255 ) NOT NULL DEFAULT '', payed INT(255) NOT NULL DEFAULT 0, PRIMARY KEY (steamid))", g_tablename);
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		SQL_TQuery(sqllib_db, sqllib_SQLModify2, query);
	}
	else
	{
		nativelib_StammReady();
		
		g_Pluginstarted = true;
		
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Stamm successfully loaded");
	}
}

public sqllib_SQLModify2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		new String:query[512];
		
		if (g_vip_type == 1) Format(query, sizeof(query), "INSERT INTO %s_backup (steamid, name, level, points) SELECT steamid, name, level, kills FROM %s", g_tablename, g_tablename);
		else if (g_vip_type == 2) Format(query, sizeof(query), "INSERT INTO %s_backup (steamid, name, level, points) SELECT steamid, name, level, rounds FROM %s", g_tablename, g_tablename);
		else if (g_vip_type == 3) Format(query, sizeof(query), "INSERT INTO %s_backup (steamid, name, level, points) SELECT steamid, name, level, time FROM %s", g_tablename, g_tablename);
		else if (g_vip_type == 4) Format(query, sizeof(query), "INSERT INTO %s_backup (steamid, name, level, points) SELECT steamid, name, level, kills+rounds FROM %s", g_tablename, g_tablename);
		else if (g_vip_type == 5) Format(query, sizeof(query), "INSERT INTO %s_backup (steamid, name, level, points) SELECT steamid, name, level, kills+time FROM %s", g_tablename, g_tablename);
		else if (g_vip_type == 6) Format(query, sizeof(query), "INSERT INTO %s_backup (steamid, name, level, points) SELECT steamid, name, level, rounds+time FROM %s", g_tablename, g_tablename);
		else if (g_vip_type == 7) Format(query, sizeof(query), "INSERT INTO %s_backup (steamid, name, level, points) SELECT steamid, name, level, kills+rounds+time FROM %s", g_tablename, g_tablename);
		else return;
			
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		SQL_TQuery(sqllib_db, sqllib_SQLModify3, query);
	}
}

public sqllib_SQLModify3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		new String:query[128];
		
		Format(query, sizeof(query), "ALTER TABLE %s RENAME TO %s_old", g_tablename, g_tablename);
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		SQL_TQuery(sqllib_db, sqllib_SQLModify4, query);
	}
}

public sqllib_SQLModify4(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		new String:query[128];
		
		Format(query, sizeof(query), "ALTER TABLE %s_backup RENAME TO %s", g_tablename, g_tablename);
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		SQL_TQuery(sqllib_db, sqllib_SQLModify5, query);
	}
}

public sqllib_SQLModify5(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		nativelib_StammReady();
		
		g_Pluginstarted = true;
		
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Stamm successfully loaded");
	}
}

public sqllib_InsertHandler(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl != INVALID_HANDLE)
	{
		new String:name[MAX_NAME_LENGTH + 1];
		new String:name2[2 * MAX_NAME_LENGTH + 2];
		new String:steamid[64];
		new String:query[256];
		
		if (clientlib_isValidClient_PRE(client))
		{
			
			GetClientAuthString(client, steamid, sizeof(steamid));
			GetClientName(client, name, sizeof(name));
			
			SQL_EscapeString(sqllib_db, name, name2, sizeof(name2));

			if(!SQL_FetchRow(hndl))
			{
				Format(query, sizeof(query), "INSERT INTO %s (steamid, name) VALUES ('%s', '%s')", g_tablename, steamid, name2);
				
				if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
				
				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				
				g_playerpoints[client] = 0;
				g_playerlevel[client] = 0;
				
				for (new i=0; i < g_features; i++) g_WantFeature[i][client] = 1;
			}
			else
			{
				g_playerlevel[client] = SQL_FetchInt(hndl, 1);
				
				for (new i=0; i < g_features; i++)
				{
					g_WantFeature[i][client] = SQL_FetchInt(hndl, 2+i);
				}
				
				g_playerpoints[client] = SQL_FetchInt(hndl, 0);
				
				Format(query, sizeof(query), "UPDATE %s SET name='%s', payed=0 WHERE steamid='%s'", g_tablename, name2, steamid);
				
				if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
				
				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
			}
			
			if (!g_allow_change)
			{
				for (new i=0; i < g_features; i++) g_WantFeature[i][client] = 1;
			}
			
			g_pointsnumber[client] = 0;
			g_happynumber[client] = 0;
			g_happyfactor[client] = 0;
			g_ClientReady[client] = false;
			
			clientlib_ClientReady(client);
		}
	}
	else
	{
		LogToFile(g_LogFile, "[ STAMM ] Database Error:   %s", error);
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Database Error:   %s", error);
	}
}


public sqllib_CheckPayed(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl != INVALID_HANDLE)
	{
		new String:steamid[64];
		new String:query[256];
		
		if (clientlib_isValidClient(client))
		{
			GetClientAuthString(client, steamid, sizeof(steamid));

			if(SQL_FetchRow(hndl))
			{
				new payed = SQL_FetchInt(hndl, 0);
				
				if (payed > 0)
				{
					g_playerpoints[client] = g_playerpoints[client] + payed;
					
					Format(query, sizeof(query), "UPDATE %s SET payed=0 WHERE steamid='%s'", g_tablename, steamid);
					
					if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
				
					SQL_TQuery(sqllib_db, sqllib_PayedSuccess, query, client);
				}
				else clientlib_CheckVip_Post(client);
			}
		}
	}
	else
	{
		LogToFile(g_LogFile, "[ STAMM ] Database Error:   %s", error);
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Database Error:   %s", error);
	}
}

public sqllib_PayedSuccess(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl != INVALID_HANDLE)
	{
		if (clientlib_isValidClient(client)) clientlib_CheckVip_Post(client);
	}
	else
	{
		LogToFile(g_LogFile, "[ STAMM ] Database Error:   %s", error);
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Database Error:   %s", error);
	}
}


public sqllib_DeleteDatabaseHandler(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl != INVALID_HANDLE)
	{
		new String:query[620];
		
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s (steamid VARCHAR( 20 ) NOT NULL DEFAULT '', level INT(3) NOT NULL DEFAULT 0, points INT( 255 ) NOT NULL DEFAULT 0, name VARCHAR( 255 ) NOT NULL DEFAULT '', payed INT(255) NOT NULL DEFAULT 0, PRIMARY KEY (steamid))", g_tablename);		
		
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
		
		for (new i=0; i < g_features; i++) sqllib_AddColumn(g_FeatureName[i]);
		
		for (new i=1; i <= MaxClients; i++)
		{
			if (clientlib_isValidClient(i))
			{
				new client = i;
				
				g_playerpoints[client] = 0;
				g_playerlevel[client] = 0;
			}
		}
		
		CPrintToChatAll("%s %T", g_StammTag, "DeletedDB", LANG_SERVER);
	}
	else
	{
		LogToFile(g_LogFile, "[ STAMM ] Database Error:   %s", error);
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Database Error:   %s", error);
	}
}


public Action:sqllib_GetVipTop(client, args)
{
	if (sqllib_db != INVALID_HANDLE)
	{
		new String:query[128];
		
		Format(query, sizeof(query), "SELECT name, points FROM %s WHERE level > 0 ORDER BY points DESC LIMIT 100", g_tablename);
		
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
	
		SQL_TQuery(sqllib_db, sqllib_GetVIPTopQuery, query, client);
	}
	
	return Plugin_Handled;
}

public Action:sqllib_GetVipRank(client, args)
{
	if (sqllib_db != INVALID_HANDLE)
	{
		new String:query[128];
		
		Format(query, sizeof(query), "SELECT points, steamid FROM %s WHERE level > 0 ORDER BY points DESC", g_tablename);
		
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
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
			new Handle:Top10Menu = CreateMenu(panellib_FeatureHandler);
			new index = 0;
			new String:top_text[128];
			new String:steamid[64];
			
			GetClientAuthString(client, steamid, sizeof(steamid));
			
			SetMenuTitle(Top10Menu, "TOP VIP's");

			while (SQL_FetchRow(hndl))
			{
				decl String:name[MAX_NAME_LENGTH+1];
				SQL_FetchString(hndl, 0, name, sizeof(name));
				
				index = 1; 
				new top_points = SQL_FetchInt(hndl, 1);
				
				Format(top_text, sizeof(top_text), "%s - %i %T", name, top_points, "Points", LANG_SERVER);
				
				AddMenuItem(Top10Menu, "", top_text, ITEMDRAW_DISABLED);
			}
			
			if (!index)
			{
				CPrintToChat(client, "%s %T", g_StammTag, "NoVips", LANG_SERVER);
				return;
			}
			
			DisplayMenu(Top10Menu, client, 60);
		}
	}
	else
	{
		LogToFile(g_LogFile, "[ STAMM ] Database Error:   %s", error);
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Database Error:   %s", error);
	}
}

public sqllib_GetVIPRankQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl != INVALID_HANDLE)
	{
		if (clientlib_isValidClient(client))
		{
			new String:steamid[64];
			
			new counter = 0;
			new end = 0;
			
			GetClientAuthString(client, steamid, sizeof(steamid));
			
			while (SQL_FetchRow(hndl))
			{
				counter++;
				
				decl String:steamid_query[64];
				new top_points = SQL_FetchInt(hndl, 0);
				
				SQL_FetchString(hndl, 1, steamid_query, sizeof(steamid_query));
				
				if (StrEqual(steamid_query, steamid))
				{
					CPrintToChat(client, "%s %T", g_StammTag, "Rank", LANG_SERVER, counter, top_points);
					
					end = 1;
					break;
				}
			}
			
			if (end) return;
			
			CPrintToChat(client, "%s %T", g_StammTag, "NoVIP", LANG_SERVER);
		}
	}
	else
	{
		LogToFile(g_LogFile, "[ STAMM ] Database Error:   %s", error);
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Database Error:   %s", error);
	}
}

public sqllib_SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogToFile(g_LogFile, "[ STAMM ] Database Error: %s", error);
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Database Error: %s", error);
	}
}

public sqllib_SQLErrorCheckCallback2(Handle:owner, Handle:hndl, const String:error[], any:data){}