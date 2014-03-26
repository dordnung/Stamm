/**
 * -----------------------------------------------------
 * File        sqlback.sp
 * Authors     David <popoklopsi> Ordnung
 * License     GPLv3
 * Web         http://popoklopsi.de
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2014 David <popoklopsi> Ordnung
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





// Get current databe version
sqlback_getDatabaseVersion()
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[128];

		
		// Get highest version
		Format(query, sizeof(query), g_sSelectVersionQuery, g_sTableName);
		
		StammLog(true, "Execute %s", query);

		SQL_TQuery(sqllib_db, sqlback_getVersion, query);
	}
}





// check version
bool:sqlback_isVersionNewer(String:version[])
{
	new String:version2[strlen(version) + 1];

	// Replace dot
	strcopy(version2, strlen(version) + 1, version);
	ReplaceString(version2, strlen(version) + 1, ".", "");

	// Check
	return (strcmp(g_sDatabaseVersion, version2, false) < 0);
}





// get the version
public sqlback_getVersion(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// Found a value?
	if (hndl != INVALID_HANDLE && StrEqual(error, "") && SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, g_sDatabaseVersion, sizeof(g_sDatabaseVersion));
	}
	else
	{
		Format(g_sDatabaseVersion, sizeof(g_sDatabaseVersion), "000");
	}


	// Check if we need to modify
	sqlback_ModifyTableBackwards();
}




// Sync steamid game indepentend
sqlback_syncSteamid(client, const String:version[])
{
	// Only for versions < 2.1
	if (sqllib_db != INVALID_HANDLE && StringToInt(version[0]) <= 2 && StringToInt(version[2]) < 1 && StringToInt(version[3]) <= 9)
	{
		decl String:query[128];
		decl String:steamid[64];
		

		// Get new steamid and replace
		clientlib_getSteamid(client, steamid, sizeof(steamid));
		ReplaceString(steamid, sizeof(steamid), "STEAM_0:", "STEAM_1:");
		


		// get points of maybe existing STEAM_1: entry
		Format(query, sizeof(query), g_sSelectPointsQuery, g_sTableName, steamid);
		

		StammLog(true, "Execute %s", query);


		SQL_TQuery(sqllib_db, sqlback_syncSteamid1, query, GetClientUserId(client));
	}
}





// SQL handler
public sqlback_syncSteamid1(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);
	

	// Found a entry?
	if (hndl != INVALID_HANDLE && StrEqual(error, "") && SQL_FetchRow(hndl) && clientlib_isValidClient_PRE(client))
	{
		decl String:query[128];
		decl String:steamid[64];
		

		// Updated client points of STEAM_1: entry
		clientlib_getSteamid(client, steamid, sizeof(steamid));
		ReplaceString(steamid, sizeof(steamid), "STEAM_0:", "STEAM_1:");
		

		pointlib_GivePlayerPoints(client, SQL_FetchInt(hndl, 0), false);


		// Delete STEAM_1: entry
		Format(query, sizeof(query), g_sDeletePlayerQuery, g_sTableName, steamid);
		
		StammLog(true, "Execute %s", query);

		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
	}
}






// Check for needed modify
sqlback_ModifyTableBackwards()
{
	decl String:query[256];


	// Version <= 2.2
	if (sqlback_isVersionNewer("2.20"))
	{
		// Remove Happy table
		Format(query, sizeof(query), g_sDropHappyTable, g_sTableName);
		
		StammLog(true, "Execute %s", query);

		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
	}

	// Version <= 2.15
	if (sqlback_isVersionNewer("2.16"))
	{
		// Add admin
		Format(query, sizeof(query), g_sAlterAdminQuery, g_sTableName);
		
		StammLog(true, "Execute %s", query);

		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
	}


	// Version <= 2.10
	if (sqlback_isVersionNewer("2.11"))
	{
		// Add last visit
		Format(query, sizeof(query), g_sAlterLastVisitQuery, g_sTableName, GetTime());
		
		StammLog(true, "Execute %s", query);

		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
	}



	// Version < 2.1
	if (sqlback_isVersionNewer("2.10"))
	{
		if (sqllib_db != INVALID_HANDLE)
		{
			// Add version column
			Format(query, sizeof(query), g_sAlterVersionQuery, g_sTableName);
			
			StammLog(true, "Execute %s", query);

			SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);



			// Drop payed	
			Format(query, sizeof(query), g_sAlterPayedQuery, g_sTableName);
			
			StammLog(true, "Execute %s", query);

			SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
			


			// Maybe we came from and old 1. version?
			Format(query, sizeof(query), g_sSelectAllPointsQuery, g_sTableName);
			
			StammLog(true, "Execute %s", query);

			SQL_TQuery(sqllib_db, sqlback_SQLModify1, query);
		}
	}
	else
	{
		// Start stamm
		stammStarted();
	}
}







// Check for very old version
public sqlback_SQLModify1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE && StrEqual(error, "") && SQL_FetchRow(hndl))
	{
		decl String:query[600];
		decl String:ident[32];


		// Get Driver
		new Handle:driver = SQL_ReadDriver(sqllib_db, ident, sizeof(ident));

		// Create new table as backup
		if (driver != INVALID_HANDLE && StrEqual(ident, "mysql"))
		{
			Format(query, sizeof(query), g_sCreateBackupQueryMySQL, g_sTableName, GetTime());
		}
		else
		{
			Format(query, sizeof(query), g_sCreateBackupQuery, g_sTableName, GetTime());
		}
		

		StammLog(true, "Execute %s", query);

		SQL_TQuery(sqllib_db, sqlback_SQLModify2, query);
	}
	else
	{
		// No old version -> Stamm start
		stammStarted();
	}
}




// Convert from old database
public sqlback_SQLModify2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		decl String:query[600];
		
		// Insert from old database
		Format(query, sizeof(query), g_sInsertBackupQuery, g_sTableName, g_sTableName);
	

		StammLog(true, "Execute %s", query);

		SQL_TQuery(sqllib_db, sqlback_SQLModify3, query);
	}
	else
	{
		// Terrible error
		SetFailState("Error converting Stamm to the newest database structur. Error:   %s", error);
	}
}






// Next step
public sqlback_SQLModify3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		decl String:query[128];


		// Rename old database to old
		Format(query, sizeof(query), g_sAlterRenameQuery, g_sTableName, g_sTableName);
		
		StammLog(true, "Execute %s", query);

		SQL_TQuery(sqllib_db, sqlback_SQLModify4, query);
	}
	else
	{
		SetFailState("Error converting Stamm to the newest database structur. Error:   %s", error);
	}
}







// Next step
public sqlback_SQLModify4(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		decl String:query[128];
		


		// Make new database to main
		Format(query, sizeof(query), g_sAlterRename2Query, g_sTableName, g_sTableName);
		
		StammLog(true, "Execute %s", query);

		SQL_TQuery(sqllib_db, sqlback_SQLModify5, query);
	}
	else
	{
		SetFailState("Error converting Stamm to the newest database structur. Error:   %s", error);
	}
}






public sqlback_SQLModify5(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		// Start stamm now
		stammStarted();
	}
	else
	{
		SetFailState("Error converting Stamm to the newest database structur. Error:   %s", error);
	}
}