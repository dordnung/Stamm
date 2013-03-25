/**
 * -----------------------------------------------------
 * File        sqllib.sp
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


// Semicolon
#pragma semicolon 1

new Handle:sqllib_db;
new sqllib_convert = -1;


// Init. sqllib
public sqllib_Start()
{
	Format(g_viplist_f, sizeof(g_viplist_f), g_viplist);
	Format(g_viprank_f, sizeof(g_viprank_f), g_viprank);

	// Register viplist and viprank command
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

// Load the database
public sqllib_LoadDB()
{
	decl String:sqlError[255];

	// Do we have a stamm database config?
	if (!SQL_CheckConfig("stamm_sql")) 
	{
		new Handle:keys = sqllib_createDB();

		// If not load a default one
		sqllib_db = SQL_ConnectCustom(keys, sqlError, sizeof(sqlError), true);

		CloseHandle(keys);
	}
	else
	{
		// if so, load the connection out of the config
		sqllib_db = SQL_Connect("stamm_sql", true, sqlError, sizeof(sqlError));
	}

	// Not connected?
	if (sqllib_db == INVALID_HANDLE)
	{
		// Log error and stop plugin
		LogToFile(g_LogFile, "[ STAMM DEBUG ] Stamm couldn't connect to the Database!! Error: %s", sqlError);

		SetFailState("[ STAMM ] Stamm couldn't connect to the Database!! Error: %s", sqlError);
	}
	else 
	{
		decl String:query[620];
		
		// Create table if it's not exists
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `%s` (`steamid` VARCHAR(21) NOT NULL DEFAULT '', `level` INT NOT NULL DEFAULT 0, `points` INT NOT NULL DEFAULT 0, `name` VARCHAR(64) NOT NULL DEFAULT '', `version` FLOAT NOT NULL DEFAULT 0.0, `last_visit` INT UNSIGNED NOT NULL DEFAULT %i, PRIMARY KEY (`steamid`))", g_tablename, GetTime());
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		// Fast query
		if (!SQL_FastQuery(sqllib_db, query))
		{
			SQL_GetError(sqllib_db, sqlError, sizeof(sqlError));
			
			LogToFile(g_LogFile, "[ STAMM ] Couldn't create Table. Error: %s", sqlError);
		}

		// Create happy hour table
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `%s_happy` (`end` INT UNSIGNED NOT NULL DEFAULT 2, `factor` TINYINT UNSIGNED NOT NULL DEFAULT 2)", g_tablename);
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		// Create fasst
		if (!SQL_FastQuery(sqllib_db, query))
		{
			SQL_GetError(sqllib_db, sqlError, sizeof(sqlError));
			
			LogToFile(g_LogFile, "[ STAMM ] Couldn't create Happy Table. Error: %s", sqlError);
		}
		
		else if (g_debug)
		{ 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Connected to Database successfully");
		}
	}
}


// Create database config
public Handle:sqllib_createDB()
{
	new Handle:dbHandle = CreateKeyValues("Databases");
	
	KvSetString(dbHandle, "driver", "sqlite");
	KvSetString(dbHandle, "host", "localhost");
	KvSetString(dbHandle, "database", "Stamm-DB");
	KvSetString(dbHandle, "user", "root");
	
	return dbHandle;
}


// Insert new Player
public sqllib_InsertPlayer(client)
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[4024];
		decl String:steamid[64];
		
		clientlib_getSteamid(client, steamid, sizeof(steamid));
		
		// Select points of the player
		Format(query, sizeof(query), "SELECT `points`, `level`, `version`");
		
		// And state of all features
		for (new i=0; i < g_features; i++)
		{ 
			Format(query, sizeof(query), "%s, `%s`", query, g_FeatureList[i][FEATURE_BASE]);
		}

		Format(query, sizeof(query), "%s FROM `%s` WHERE steamid = '%s'", query, g_tablename, steamid);
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		// Get it
		SQL_TQuery(sqllib_db, sqllib_InsertHandler, query, client);
	}
}


// Add new column for a feature
public sqllib_AddColumn(String:name[], bool:standard)
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[256];
		
		// Standard off or on?
		if (standard)
		{
			Format(query, sizeof(query), "ALTER TABLE `%s` ADD `%s` INT NOT NULL DEFAULT 1", g_tablename, name);
		}
		else
		{
			Format(query, sizeof(query), "ALTER TABLE `%s` ADD `%s` INT NOT NULL DEFAULT 0", g_tablename, name);
		}


		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		// Add column
		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
	}
}


// Clint insert handler
public sqllib_InsertHandler(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl != INVALID_HANDLE)
	{
		decl String:versionSteamid[12];
		decl String:name[MAX_NAME_LENGTH + 1];
		decl String:name2[2 * MAX_NAME_LENGTH + 2];
		decl String:steamid[64];
		decl String:query[512];
		

		// Only valid clients
		if (clientlib_isValidClient_PRE(client))
		{
			g_pointsnumber[client] = 0;
			g_happynumber[client] = 0;
			g_happyfactor[client] = 0;
			g_ClientReady[client] = false;

			// Get name and steamid
			clientlib_getSteamid(client, steamid, sizeof(steamid));
			GetClientName(client, name, sizeof(name));
			
			// escape bad names
			SQL_EscapeString(sqllib_db, name, name2, sizeof(name2));

			// Found no entry?
			if (!SQL_FetchRow(hndl))
			{
				// Insert the player 
				Format(query, sizeof(query), "INSERT INTO `%s` (`steamid`, `name`, `version`, `last_visit`) VALUES ('%s', '%s', %s, %i)", g_tablename, steamid, name2, g_Plugin_Version, GetTime());
				
				if (g_debug) 
				{
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
				}

				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				
				// Set level and points to zero
				g_playerpoints[client] = 0;
				g_playerlevel[client] = 0;
				
				// set feature state to standard
				for (new i=0; i < g_features; i++)
				{ 
					g_FeatureList[i][WANT_FEATURE][client] = g_FeatureList[i][FEATURE_STANDARD];
				}

				// Sync the steamid with version 0.0
				sqlback_syncSteamid(client, "0.0");
			}
			else
			{
				// Get all values from the database
				g_playerlevel[client] = SQL_FetchInt(hndl, 1);
				
				// Also all feature state
				for (new i=0; i < g_features; i++)
				{
					if (SQL_FetchInt(hndl, 3+i) == 1)
					{
						g_FeatureList[i][WANT_FEATURE][client] = true;
					}
					else
					{
						g_FeatureList[i][WANT_FEATURE][client] = false;
					}
				}
				
				// Get points
				g_playerpoints[client] = SQL_FetchInt(hndl, 0);
				

				// Update version, name and last visit
				Format(query, sizeof(query), "UPDATE `%s` SET `name`='%s', `version`=%s, `last_visit`=%i WHERE `steamid`='%s'", g_tablename, name2, g_Plugin_Version, GetTime(), steamid);
				
				if (g_debug) 
				{
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
				}

				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);

				// Get the version of this client
				SQL_FetchString(hndl, 2, versionSteamid, sizeof(versionSteamid));

				// Sync old STEAM_1:
				if (!sqlback_syncSteamid(client, versionSteamid))
				{
					clientlib_ClientReady(client);
				}
			}
		}
	}
	else
	{
		// Couldn't check
		LogToFile(g_LogFile, "[ STAMM ] Error checking Player %N:   %s", client, error);
	}
}


// Get the vip top 10
public Action:sqllib_GetVipTop(client, args)
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[128];
		
		// Select all vips DESC by points
		Format(query, sizeof(query), "SELECT `name`, `points` FROM `%s` WHERE `level` > 0 ORDER BY `points` DESC LIMIT 10", g_tablename);
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		SQL_TQuery(sqllib_db, sqllib_GetVIPTopQuery, query, client);
	}
	
	return Plugin_Handled;
}


// Get the rank of the client
public Action:sqllib_GetVipRank(client, args)
{
	// No VIP ?
	if (g_playerlevel[client] <= 0)
	{
		CPrintToChat(client, "%s %t", g_StammTag, "NoVIP");
		
		return Plugin_Handled;
	}
	
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[128];
		
		// Get the count of players with points higher than that of the client
		Format(query, sizeof(query), "SELECT COUNT(*) FROM `%s` WHERE `points` >= %i", g_tablename, g_playerpoints[client]);
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		SQL_TQuery(sqllib_db, sqllib_GetVIPRankQuery, query, client);
	}
	
	return Plugin_Handled;
}


// Vip Top query handle
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

			// Fetch all founded
			while (SQL_FetchRow(hndl))
			{
				decl String:name[MAX_NAME_LENGTH+1];
				SQL_FetchString(hndl, 0, name, sizeof(name));
				
				new top_points = SQL_FetchInt(hndl, 1);
				
				// Add to menu
				Format(top_text, sizeof(top_text), "%i. %s - %i %T", ++index, name, top_points, "Points", client);
				
				DrawPanelText(Top10Menu, top_text);
			}
			
			// Found something?
			if (!index)
			{
				// There are no vips
				CPrintToChat(client, "%s %t", g_StammTag, "NoVips");
				
				return;
			}
			else
			{
				DrawPanelText(Top10Menu, "------------------------------------");

				Format(top_text, sizeof(top_text), "%T", "Close", client);

				DrawPanelItem(Top10Menu, top_text);
			}

			// Send the menu
			SendPanelToClient(Top10Menu, client, panellib_FeatureHandler, 60);
		}
	}
	else
	{
		LogToFile(g_LogFile, "[ STAMM ] Database Error:   %s", error);
	}
}

// VIP rank handler
public sqllib_GetVIPRankQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	// Found somehing valid?
	if (hndl != INVALID_HANDLE)
	{
		if (clientlib_isValidClient(client))
		{
			// print rank
			CPrintToChat(client, "%s %t", g_StammTag, "Rank", SQL_FetchInt(hndl, 0), g_playerpoints[client]);
		}
	}
	else
	{
		LogToFile(g_LogFile, "[ STAMM ] Database Error:   %s", error);
	}
}


// Error check callback
public sqllib_SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		// Save error
		LogToFile(g_LogFile, "[ STAMM ] Database Error: %s", error);
	}
}

// For maybe vali database errors
public sqllib_SQLErrorCheckCallback2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// Duplicate column is fine
	if (!StrEqual("", error) && StrContains(error, "Duplicate column name", false) == -1)
	{
		if (g_debug)
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Maybe VALID Database Error: %s", error);
		}
	}
}

// Convert the database to a file
public Action:sqllib_convertDB(args)
{
	decl String:mysqlString[12];
	decl String:query[128];

	// Right use
	if (GetCmdArgs() != 1)
	{
		ReplyToCommand(0, "Usage: stamm_convert_db <mysql>");

		return Plugin_Handled;
	}

	// Not converting right now?
	if (sqllib_convert > -1)
	{
		ReplyToCommand(0, "You are already converting the database. Please Wait.");

		return Plugin_Handled;
	}

	GetCmdArg(1, mysqlString, sizeof(mysqlString));

	// Valid argument?
	if (StringToInt(mysqlString) > 1 || StringToInt(mysqlString) < 0)
	{
		ReplyToCommand(0, "Usage: stamm_convert_db <mysql>");

		return Plugin_Handled;
	}

	sqllib_convert = StringToInt(mysqlString);

	
	// Select data from database
	Format(query, sizeof(query), "SELECT `steamid`, `level`, `points`, `name`, `version` FROM `%s`", g_tablename);

	// Execute
	SQL_TQuery(sqllib_db, sqllib_SQLConvertDatabaseToFile, query);

	// Notice status
	ReplyToCommand(0, "Converting now Stamm database to a file. Please wait. This could take a bit!");

	return Plugin_Handled;
}


// Convert Handler
public sqllib_SQLConvertDatabaseToFile(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// Found someting?
	if (hndl != INVALID_HANDLE && SQL_FetchRow(hndl))
	{
		new String:filename[64];
		new counter = 0;

		// Format filename
		Format(filename, sizeof(filename), "%s.sql", g_tablename);

		new Handle:file = OpenFile(filename, "wb");

		// Could open file?
		if (file != INVALID_HANDLE)
		{
			// For sqlite we need a start
			if (sqllib_convert == 0)
			{
				WriteFileLine(file, "BEGIN TRANSACTION;");
			}

			// Write create statement
			WriteFileLine(file, "CREATE TABLE IF NOT EXISTS `%s` (`steamid` VARCHAR(21) NOT NULL DEFAULT '', `level` INT NOT NULL DEFAULT 0, `points` INT NOT NULL DEFAULT 0, `name` VARCHAR(64) NOT NULL DEFAULT '', `version` FLOAT NOT NULL DEFAULT 0.0, PRIMARY KEY (`steamid`));", g_tablename);

			// Parse all database data
			do
			{
				new level;
				new points;
				new Float:version;

				decl String:steamid[64];
				decl String:name[128];
				decl String:name2[256];
				decl String:versionS[12];

				// Get values
				level = SQL_FetchInt(hndl, 1);
				points = SQL_FetchInt(hndl, 2);
				version = SQL_FetchFloat(hndl, 4);

				// Convert version to string
				FloatToString(version, versionS, sizeof(versionS));

				// Fetch steamid and name
				SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
				SQL_FetchString(hndl, 3, name, sizeof(name));

				// Escape the name
				sqllib_escapeString(name, name2, sizeof(name2), sqllib_convert);

				// For sqlite just add a insert into line
				if (sqllib_convert == 0)
				{
					WriteFileLine(file, "INSERT INTO `%s` (`steamid`, `level`, `points`, `name`, `version`) VALUES ('%s', %i, %i, '%s', %s);", g_tablename, steamid, level, points, name2, versionS);
				}
				else
				{
					// For mysql we insert up to 1000 users with one call
					if (counter == 0)
					{
						// new line
						WriteFileLine(file, "INSERT INTO `%s` (`steamid`, `level`, `points`, `name`, `version`) VALUES", g_tablename);
					}

					// Check if 1000 reached
					if (++counter == 1000 || !SQL_MoreRows(hndl))
					{
						WriteFileLine(file, "('%s', %i, %i, '%s', %s);", steamid, level, points, name2, versionS);

						counter = 0;
					}
					else
					{
						WriteFileLine(file, "('%s', %i, %i, '%s', %s),", steamid, level, points, name2, versionS);
					}
				}

			} 
			while (SQL_FetchRow(hndl));

			// And we need a end for sqlite
			if (sqllib_convert == 0)
			{
				WriteFileLine(file, "COMMIT;");
			}

			// Close file
			CloseHandle(file);

			// Notice finish
			PrintToServer("Converted Database to file %s successfully", filename);
		}
		else
		{
			// Couldn't create file
			PrintToServer("Couldn't convert database to file. Couldn't create file %s", filename);
		}
	}
	else
	{
		PrintToServer("Couldn't convert database to file. Error: ", error);
	}

	// Reset state
	sqllib_convert = -1;
}

// Escape a string
public sqllib_escapeString(String:input[], String:output[], maxlen, mysql)
{
	new len = strlen(input);
	new count = 0;

	Format(output, maxlen, "");

	// For mysql we need a different operation
	if (mysql == 1)
	{
		// For each char in the string
		for (new offset=0; offset < len; offset++)
		{
			new ch = input[offset];

			// Switch the char
			switch(ch)
			{
				// Found a '
				case '\'':
				{
					// If we have it not a even time, replace with \'
					if (count % 2 == 0)
					{
						Format(output, maxlen, "%s\\", output);
					}
					
					count = 0;

					// add it again
					Format(output, maxlen, "%s%c", output, ch);
				}
				case '\\':
				{
					count++;

					Format(output, maxlen, "%s%c", output, ch);
				}
				default:
				{
					// Other value -> reset counter
					count = 0;

					Format(output, maxlen, "%s%c", output, ch);
				}
			}
		}

		if (count != 0)
		{
			if (count % 2 == 1)
			{
				Format(output, maxlen, "%s\\", output);
			}
		}
	}
	else	
	{
		// For sqlite
		for (new offset=0; offset < len; offset++)
		{
			new ch = input[offset];

			switch(ch)
			{
				// Found a '
				case '\'':
				{
					count++;

					Format(output, maxlen, "%s%c", output, ch);
				}
				default:
				{
					// Found odd times of ' replace with ''
					if (count % 2 == 1)
					{
						Format(output, maxlen, "%s'", output);
					}

					count = 0;

					Format(output, maxlen, "%s%c", output, ch);
				}
			}
		}

		if (count != 0)
		{
			// End with '
			if (count % 2 == 1)
			{
				Format(output, maxlen, "%s'", output);
			}
		}
	}
}