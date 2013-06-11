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
new sqllib_convert_cur = 2;




// Init. sqllib
public sqllib_Start()
{
	Format(g_sVipListF, sizeof(g_sVipListF), g_sVipList);
	Format(g_sVipRankF, sizeof(g_sVipRankF), g_sVipRank);



	// Register viplist and viprank command
	if (!StrContains(g_sVipList, "sm_"))
	{
		RegConsoleCmd(g_sVipList, sqllib_GetVipTop);
		
		ReplaceString(g_sVipListF, sizeof(g_sVipListF), "sm_", "!");
	}
	
	if (!StrContains(g_sVipRank, "sm_"))
	{
		RegConsoleCmd(g_sVipRank, sqllib_GetVipRank);
	
		ReplaceString(g_sVipRankF, sizeof(g_sVipRankF), "sm_", "!");
	}
}






// Load the database
public sqllib_LoadDB()
{
	decl String:sqlError[255];
	decl String:ident[32];


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
		LogToFile(g_sLogFile, "[ STAMM ] Stamm couldn't connect to the Database!! Error: %s", sqlError);

		SetFailState("[ STAMM ] Stamm couldn't connect to the Database!! Error: %s", sqlError);
	}
	else 
	{
		decl String:query[620];
		

		// Get Driver
		new Handle:driver = SQL_ReadDriver(sqllib_db, ident, sizeof(ident));


		// Create new table 
		if (driver != INVALID_HANDLE && StrEqual(ident, "mysql"))
		{
			Format(query, sizeof(query), g_sCreateTableQuery, g_sTableName, GetTime());
		}
		else
		{
			Format(query, sizeof(query), g_sCreateTableQueryMySQL, g_sTableName, GetTime());
		}


		if (g_bDebug) 
		{
			LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}




		// Lock DB
		SQL_LockDatabase(sqllib_db);


		// Fast query
		if (!SQL_FastQuery(sqllib_db, query))
		{
			SQL_GetError(sqllib_db, sqlError, sizeof(sqlError));
			
			LogToFile(g_sLogFile, "[ STAMM ] Couldn't create Table. Error: %s", sqlError);
		}




		// Create feature table
		Format(query, sizeof(query), g_sCreateFeatureQuery, g_sTableName);
		
		if (g_bDebug) 
		{
			LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		// Fast query
		if (!SQL_FastQuery(sqllib_db, query))
		{
			SQL_GetError(sqllib_db, sqlError, sizeof(sqlError));
			
			LogToFile(g_sLogFile, "[ STAMM ] Couldn't create Feature Table. Error: %s", sqlError);
		}




		// Create happy hour table
		Format(query, sizeof(query), g_sCreatHappyQuery, g_sTableName);
		
		if (g_bDebug) 
		{
			LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}



		// Create fast
		if (!SQL_FastQuery(sqllib_db, query))
		{
			SQL_GetError(sqllib_db, sqlError, sizeof(sqlError));
			
			LogToFile(g_sLogFile, "[ STAMM ] Couldn't create Happy Table. Error: %s", sqlError);
		}
		
		else if (g_bDebug)
		{ 
			LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Connected to Database successfully");
		}


		// unLock DB
		SQL_UnlockDatabase(sqllib_db);
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
	g_bClientReady[client] = false;

	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[4024];
		decl String:steamid[64];
		


		clientlib_getSteamid(client, steamid, sizeof(steamid));
		
		// Select points of the player
		Format(query, sizeof(query), g_sSelectPlayerStartQuery);
		



		// And state of all features
		for (new i=0; i < g_iFeatures; i++)
		{ 
			Format(query, sizeof(query), "%s, `%s`", query, g_FeatureList[i][FEATURE_BASE]);
		}



		Format(query, sizeof(query), g_sInsertMiddleQuery, query, g_sTableName, steamid);
		
		if (g_bDebug) 
		{
			LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}


		// Get it
		SQL_TQuery(sqllib_db, sqllib_InsertHandler, query, GetClientUserId(client));
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
			Format(query, sizeof(query), g_sAlterFeatureQuery, g_sTableName, name, 1);
		}
		else
		{
			Format(query, sizeof(query), g_sAlterFeatureQuery, g_sTableName, name, 0);
		}



		if (g_bDebug) 
		{
			LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		// Add column
		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
	}
}








// Clint insert handler
public sqllib_InsertHandler(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (hndl != INVALID_HANDLE)
	{
		decl String:versionSteamid[12];
		decl String:name[MAX_NAME_LENGTH + 1];
		decl String:name2[2 * MAX_NAME_LENGTH + 2];
		decl String:steamid[64];
		decl String:query[1024];
		



		// Only valid clients
		if (clientlib_isValidClient_PRE(client))
		{
			g_iPointsNumber[client] = 0;
			g_iHappyNumber[client] = 0;
			g_iHappyFactor[client] = 0;



			// Get name and steamid
			clientlib_getSteamid(client, steamid, sizeof(steamid));
			GetClientName(client, name, sizeof(name));
			
			// escape bad names
			SQL_EscapeString(sqllib_db, name, name2, sizeof(name2));




			// Found no entry?
			if (!SQL_FetchRow(hndl))
			{
				// Insert the player 
				Format(query, sizeof(query), g_sInsertPlayerQuery, g_sTableName, steamid, name2, (clientlib_IsAdmin(client) ? 1 : 0), GetTime());
				
				if (g_bDebug) 
				{
					LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
				}

				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				



				// Set level and points to zero
				g_iPlayerPoints[client] = 0;
				g_iPlayerLevel[client] = 0;
				

				// set feature state to standard
				for (new i=0; i < g_iFeatures; i++)
				{ 
					g_FeatureList[i][WANT_FEATURE][client] = g_FeatureList[i][FEATURE_STANDARD];
				}



				// Sync the steamid with version 0.00
				sqlback_syncSteamid(client, "0.00");
			}
			else
			{
				// Get all values from the database
				g_iPlayerLevel[client] = SQL_FetchInt(hndl, 1);
				



				// Also all feature state
				for (new i=0; i < g_iFeatures; i++)
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
				g_iPlayerPoints[client] = SQL_FetchInt(hndl, 0);
				


				// Update version, name and last visit
				Format(query, sizeof(query), g_sUpdatePlayer2Query, g_sTableName, name2, (clientlib_IsAdmin(client) ? 1 : 0), g_sPluginVersion, GetTime(), steamid);
				
				if (g_bDebug) 
				{
					LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
				}

				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);





				// Get the version of this client
				SQL_FetchString(hndl, 2, versionSteamid, sizeof(versionSteamid));


				// Sync old STEAM_1:
				sqlback_syncSteamid(client, versionSteamid);
			}



			// Get Feature of the player
			Format(query, sizeof(query), g_sSelectPlayerShopQuery, g_sTableName, steamid);
			
			if (g_bDebug) 
			{
				LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
			}


			// Get it
			SQL_TQuery(sqllib_db, sqllib_InsertHandler2, query, GetClientUserId(client));
		}
	}
	else
	{
		// Couldn't check
		LogToFile(g_sLogFile, "[ STAMM ] Error checking Player %N:   %s", client, error);
	}
}








// Clint insert handler 2
public sqllib_InsertHandler2(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);
	

	if (hndl != INVALID_HANDLE)
	{
		decl String:feature[64];
		decl String:block[64];
		decl String:steamid[64];
		


		// Only valid clients
		if (clientlib_isValidClient_PRE(client))
		{
			// Get steamid
			clientlib_getSteamid(client, steamid, sizeof(steamid));



			// Found no entry?
			if (!SQL_FetchRow(hndl))
			{
				// Set all features to false
				for (new i=0; i < MAXLEVELS; i++)
				{
					for (new j=0; j < MAXLEVELS; j++)
					{
						g_bBoughtBlock[client][i][j] = false;
					}
				}


				// Client is ready
				clientlib_ClientReady(client);
			}
			else
			{
				new index = -1;
				new indexBlock = -1;


				// Parse all database data
				do
				{
					// Get features and blocks of client
					SQL_FetchString(hndl, 0, feature, sizeof(feature));
					SQL_FetchString(hndl, 1, block, sizeof(block));


					// Find the feature
					for (new i=0; i < g_iFeatures; i++)
					{
						// Basename equals?
						if (StrEqual(g_FeatureList[i][FEATURE_BASE], feature, false))
						{
							index = i;

							break;
						}
					}


					// Found it
					if (index != -1)
					{
						// Find the block
						for (new j=0; j < g_FeatureList[index][FEATURE_BLOCKS]; j++)
						{
							// Check if name equals
							if (StrEqual(g_sFeatureBlocks[index][j], block, false))
							{
								indexBlock = j;

								break;
							}
						}


						// Found it
						if (indexBlock != -1)
						{
							g_bBoughtBlock[client][index][indexBlock] = true;
						}
					}

				} 
				while (SQL_FetchRow(hndl));



				// Client is ready
				clientlib_ClientReady(client);
			}
		}
	}
	else
	{
		// Couldn't check
		LogToFile(g_sLogFile, "[ STAMM ] Error checking Player Shop %N:   %s", client, error);
	}
}







// Get the vip top 10
public Action:sqllib_GetVipTop(client, args)
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[128];
		

		// Select all vips DESC by points
		Format(query, sizeof(query), g_sSelectTop10Query, g_sTableName);
		
		if (g_bDebug) 
		{
			LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		SQL_TQuery(sqllib_db, sqllib_GetVIPTopQuery, query, GetClientUserId(client));
	}
	
	return Plugin_Handled;
}







// Get the rank of the client
public Action:sqllib_GetVipRank(client, args)
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[128];
		


		// Get the count of players with points higher than that of the client
		Format(query, sizeof(query), g_sSelectRankQuery, g_sTableName, g_iPlayerPoints[client]);
		
		if (g_bDebug) 
		{
			LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		SQL_TQuery(sqllib_db, sqllib_GetVIPRankQuery, query, GetClientUserId(client));
	}
	


	return Plugin_Handled;
}








// Vip Top query handle
public sqllib_GetVIPTopQuery(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);

	if (hndl != INVALID_HANDLE)
	{
		if (clientlib_isValidClient(client))
		{
			new Handle:Top10Menu = CreatePanel();
			new index = 0;

			decl String:top_text[128];
			decl String:steamid[64];
			




			clientlib_getSteamid(client, steamid, sizeof(steamid));

			Format(top_text, sizeof(top_text), "%T", "StammTop", client);
			SetPanelTitle(Top10Menu, top_text);

			DrawPanelText(Top10Menu, "------------------------------------");




			// Fetch all founded
			while (SQL_FetchRow(hndl))
			{
				decl String:name[MAX_NAME_LENGTH+1];
				new top_points;


				SQL_FetchString(hndl, 0, name, sizeof(name));
				top_points = SQL_FetchInt(hndl, 1);
				

				// Add to menu
				Format(top_text, sizeof(top_text), "%i. %s - %i %T", ++index, name, top_points, "Points", client);
				
				DrawPanelText(Top10Menu, top_text);
			}
			



			// Found something?
			if (!index)
			{
				// There are no players
				if (!g_bMoreColors)
				{
					CPrintToChat(client, "%s %t", g_sStammTag, "NoRanks");
				}
				else
				{
					MCPrintToChat(client, "%s %t", g_sStammTag, "NoRanks");
				}
				
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
		LogToFile(g_sLogFile, "[ STAMM ] Database Error:   %s", error);
	}
}







// VIP rank handler
public sqllib_GetVIPRankQuery(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);

	// Found somehing valid?
	if (hndl != INVALID_HANDLE)
	{
		if (clientlib_isValidClient(client) && SQL_FetchRow(hndl))
		{
			// print rank
			if (!g_bMoreColors)
			{
				CPrintToChat(client, "%s %t", g_sStammTag, "Rank", SQL_FetchInt(hndl, 0), g_iPlayerPoints[client]);
			}
			else
			{
				MCPrintToChat(client, "%s %t", g_sStammTag, "Rank", SQL_FetchInt(hndl, 0), g_iPlayerPoints[client]);
			}
		}
	}
	else
	{
		LogToFile(g_sLogFile, "[ STAMM ] Database Error:   %s", error);
	}
}






// Error check callback
public sqllib_SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		// Save error
		LogToFile(g_sLogFile, "[ STAMM ] Database Error: %s", error);
	}
}





// For maybe vali database errors
public sqllib_SQLErrorCheckCallback2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// Duplicate column is fine
	if (!StrEqual("", error) && StrContains(error, "Duplicate column name", false) == -1)
	{
		if (g_bDebug)
		{
			LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Maybe VALID Database Error: %s", error);
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
	if (sqllib_convert_cur != 2)
	{
		ReplyToCommand(0, "You are already converting the database. Please Wait.");

		return Plugin_Handled;
	}


	// Reset sqllib_convert_cur
	sqllib_convert_cur = 0;


	GetCmdArg(1, mysqlString, sizeof(mysqlString));



	// Valid argument?
	if (StringToInt(mysqlString) > 1 || StringToInt(mysqlString) < 0)
	{
		ReplyToCommand(0, "Usage: stamm_convert_db <mysql>");

		return Plugin_Handled;
	}




	sqllib_convert = StringToInt(mysqlString);

	

	// Select data from database
	Format(query, sizeof(query), g_sSelectPlayerQuery, g_sTableName);

	// Execute
	SQL_TQuery(sqllib_db, sqllib_SQLConvertDatabaseToFile, query);




	// Select data from database
	Format(query, sizeof(query), g_sSelectPlayerShopAllQuery, g_sTableName);

	// Execute
	SQL_TQuery(sqllib_db, sqllib_SQLConvertDatabaseToFile2, query);



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
		Format(filename, sizeof(filename), "%s.sql", g_sTableName);

		new Handle:file = OpenFile(filename, "wb");




		// Could open file?
		if (file != INVALID_HANDLE)
		{
			// For sqlite we need a start
			if (sqllib_convert == 0)
			{
				WriteFileLine(file, "BEGIN TRANSACTION;");


				// Write create statement
				WriteFileLine(file, g_sCreateTableQuery, g_sTableName, GetTime());
			}
			else
			{
				// Write create statement
				WriteFileLine(file, g_sCreateTableQueryMySQL, g_sTableName, GetTime());
			}



			// Parse all database data
			do
			{
				new level;
				new points;
				new last;

				decl String:steamid[64];
				decl String:name[128];
				decl String:name2[256];
				decl String:versionS[12];

				// Get values
				level = SQL_FetchInt(hndl, 1);
				points = SQL_FetchInt(hndl, 2);
				last = SQL_FetchInt(hndl, 5);



				// Fetch steamid and name
				SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
				SQL_FetchString(hndl, 3, name, sizeof(name));
				SQL_FetchString(hndl, 4, versionS, sizeof(versionS));

				

				// For sqlite just add a insert into line
				if (sqllib_convert == 0)
				{
					// Escape Sqlite
					EscapeStringSQLite(name, name2, sizeof(name2), true);


					WriteFileLine(file, g_sInsertPlayerSaveQuery, g_sTableName, steamid, level, points, name2, versionS, last);
				}
				else
				{
					// Escape Mysql
					EscapeStringMySQL(name, name2, sizeof(name2), true);


					// For mysql we insert up to 1000 users with one call
					if (counter == 0)
					{
						// new line
						WriteFileLine(file, g_sInsertPlayerSave2Query, g_sTableName);
					}


					// Check if 1000 reached
					if (++counter == 1000 || !SQL_MoreRows(hndl))
					{
						WriteFileLine(file, g_sInsertPlayerSave2DataQuery, steamid, level, points, name2, versionS, last);

						counter = 0;
					}
					else
					{
						WriteFileLine(file, g_sInsertPlayerSave2Data2Query, steamid, level, points, name2, versionS, last);
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
	sqllib_convert_cur++;
}




// Convert Handler
public sqllib_SQLConvertDatabaseToFile2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// Found someting?
	if (hndl != INVALID_HANDLE && SQL_FetchRow(hndl))
	{
		new String:filename[64];
		new counter = 0;



		// Format filename
		Format(filename, sizeof(filename), "%s_shop.sql", g_sTableName);

		new Handle:file = OpenFile(filename, "wb");




		// Could open file?
		if (file != INVALID_HANDLE)
		{
			// For sqlite we need a start
			if (sqllib_convert == 0)
			{
				WriteFileLine(file, "BEGIN TRANSACTION;");
			}


			// Shop table
			WriteFileLine(file, g_sCreateFeatureQuery, g_sTableName);



			// Parse all database data
			do
			{
				decl String:steamid[64];
				decl String:feature[128];
				decl String:feature2[256];
				decl String:block[128];
				decl String:block2[256];


				// Fetch steamid and name
				SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
				SQL_FetchString(hndl, 1, feature, sizeof(feature));
				SQL_FetchString(hndl, 2, block, sizeof(block));

				

				// For sqlite just add a insert into line
				if (sqllib_convert == 0)
				{
					// Escape Sqlite
					EscapeStringSQLite(feature, feature2, sizeof(feature2), true);
					EscapeStringSQLite(block, block2, sizeof(block2), true);

					WriteFileLine(file, g_sInsertPlayerShopQuery, g_sTableName, feature2, block2);
				}
				else
				{
					// Escape Mysql
					EscapeStringMySQL(feature, feature2, sizeof(feature2), true);
					EscapeStringMySQL(block, block2, sizeof(block2), true);


					// For mysql we insert up to 1000 users with one call
					if (counter == 0)
					{
						// new line
						WriteFileLine(file, g_sInsertPlayerSave2QueryShop, g_sTableName);
					}


					// Check if 1000 reached
					if (++counter == 1000 || !SQL_MoreRows(hndl))
					{
						WriteFileLine(file, g_sInsertPlayerSave2DataQueryShop, feature2, block2);

						counter = 0;
					}
					else
					{
						WriteFileLine(file, g_sInsertPlayerSave2Data2QueryShop, feature2, block2);
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
			PrintToServer("Converted Shop Database to file %s successfully", filename);
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
	sqllib_convert_cur++;
}