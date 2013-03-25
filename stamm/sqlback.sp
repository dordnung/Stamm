/**
 * -----------------------------------------------------
 * File        sqlback.sp
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


// Get current databe version
public sqlback_getDatabaseVersion()
{
	if (sqllib_db != INVALID_HANDLE)
	{
		decl String:query[128];
		
		// Get highest version
		Format(query, sizeof(query), "SELECT `version` FROM `%s` ORDER BY `version` DESC LIMIT 1", g_tablename);
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		SQL_TQuery(sqllib_db, sqlback_getVersion, query);

		// Get running happy hour
		Format(query, sizeof(query), "SELECT `end`, `factor` FROM `%s_happy` WHERE `end` > %i LIMIT 1", g_tablename, GetTime());
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		SQL_TQuery(sqllib_db, sqlback_getHappy, query);
	}
}

// get the version
public sqlback_getVersion(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// Found a value?
	if (hndl != INVALID_HANDLE && StrEqual(error, "") && SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, g_databaseVersion, sizeof(g_databaseVersion));
	}
	else
	{
		// Not found -> set to 0.0
		Format(g_databaseVersion, sizeof(g_databaseVersion), "0.0");
	}

	// We need only 3 numbers
	g_databaseVersion[4] = '\0';

	// Check if we need to modify
	sqlback_ModifyTableBackwards();
}

// Get running happy hour
public sqlback_getHappy(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// find something?
	if (hndl != INVALID_HANDLE && StrEqual(error, "") && SQL_FetchRow(hndl))
	{
		// End time and factor
		new end = SQL_FetchInt(hndl, 0);
		new factor = SQL_FetchInt(hndl, 1);

		new time = GetTime();

		// is end in future?
		if (end > time)
		{
			otherlib_StartHappyHour(end-time, factor);
		}
	}
}


// Sync steamid game indepentend
public bool:sqlback_syncSteamid(client, const String:version[])
{
	// Only for versions < 2.1
	if (sqllib_db != INVALID_HANDLE && !StrEqual(version, "2.10") && !StrEqual(version, "2.13"))
	{
		decl String:query[128];
		decl String:steamid[64];
		
		// Get new steamid and replace
		clientlib_getSteamid(client, steamid, sizeof(steamid));
		ReplaceString(steamid, sizeof(steamid), "STEAM_0:", "STEAM_1:");
		
		// get points of maybe existing STEAM_1: entry
		Format(query, sizeof(query), "SELECT `points` FROM `%s` WHERE `steamid`='%s'", g_tablename, steamid);
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		SQL_TQuery(sqllib_db, sqlback_syncSteamid1, query, client);

		return true;
	}

	return false;
}

// SQL handler
public sqlback_syncSteamid1(Handle:owner, Handle:hndl, const String:error[], any:client)
{
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
		Format(query, sizeof(query), "DELETE FROM `%s` WHERE `steamid`='%s'", g_tablename, steamid);
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
	}

	// Client is ready
	clientlib_ClientReady(client);
}

// Version < 2.1
public sqlback_ModifyVersion()
{
	decl String:query[128];
			
	// Add version column
	Format(query, sizeof(query), "ALTER TABLE `%s` ADD `version` FLOAT NOT NULL DEFAULT 0.0", g_tablename);
	
	if (g_debug) 
	{
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
	}

	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);

	// Add last visit
	Format(query, sizeof(query), "ALTER TABLE `%s` ADD `last_visit` INT UNSIGNED NOT NULL DEFAULT %i", g_tablename, GetTime());
	
	if (g_debug) 
	{
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
	}

	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);


	// Drop payed	
	Format(query, sizeof(query), "ALTER TABLE `%s` DROP `payed`", g_tablename);
	
	if (g_debug) 
	{
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
	}

	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);
}


// Check for needed modify
public sqlback_ModifyTableBackwards()
{
	decl String:query[128];

	// Version < 2.1 ?
	if (!StrEqual(g_databaseVersion, "2.10") && !StrEqual(g_databaseVersion, "2.13"))
	{
		if (sqllib_db != INVALID_HANDLE)
		{
			// Modify
			sqlback_ModifyVersion();
			
			// Maybe we came from and old 1. version?
			Format(query, sizeof(query), "SELECT `points` FROM `%s`", g_tablename);
			
			if (g_debug) 
			{
				LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			}

			SQL_TQuery(sqllib_db, sqlback_SQLModify1, query);
		}
	}

	// Version is 2.10
	else if (StrEqual(g_databaseVersion, "2.10"))
	{
		// Add last visit
		Format(query, sizeof(query), "ALTER TABLE `%s` ADD `last_visit` INT UNSIGNED NOT NULL DEFAULT %i", g_tablename, GetTime());
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback2, query);

		// Start stamm
		stammStarted();
	}
	// No modify needed so start stamm now
	else
	{
		stammStarted();
	}
}

// Check for very old version
public sqlback_SQLModify1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE || !StrEqual(error, ""))
	{
		decl String:query[600];
		
		// Create new table as backup
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `%s_backup` (`steamid` VARCHAR(20) NOT NULL DEFAULT '', `level` INT NOT NULL DEFAULT 0, `points` INT NOT NULL DEFAULT 0, `name` VARCHAR(255) NOT NULL DEFAULT '', `version` FLOAT NOT NULL DEFAULT 0.0, `last_visit` INT UNSIGNED NOT NULL DEFAULT %i, PRIMARY KEY (`steamid`))", g_tablename, GetTime());
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

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
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

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
		Format(query, sizeof(query), "ALTER TABLE `%s` RENAME TO `%s_old`", g_tablename, g_tablename);
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

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
		Format(query, sizeof(query), "ALTER TABLE `%s_backup` RENAME TO `%s`", g_tablename, g_tablename);
		
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

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