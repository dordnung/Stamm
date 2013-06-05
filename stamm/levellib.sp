/**
 * -----------------------------------------------------
 * File        levellib.sp
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


// Use semicolon
#pragma semicolon 1





// Load all levels
public levellib_LoadLevels()
{
	// Create the keyvalue
	new Handle:all_levels = CreateKeyValues("StammLevels");
	decl String:flagTest[64];




	// Didn't find the stamm level file -> Stop plugin, we can't do anything here
	if (!FileExists("cfg/stamm/StammLevels.txt"))
	{
		LogToFile(g_sLogFile, "Attention: Couldn't load cfg/stamm/StammLevels.txt. File doesn't exist!");

		return;
	}




	// Load the file to keyvalue
	FileToKeyValues(all_levels, "cfg/stamm/StammLevels.txt");
	



	// First go through all non private levels
	if (KvGotoFirstSubKey(all_levels))
	{
		do
		{
			// Check if it's a non private level
			KvGetString(all_levels, "flag", flagTest, sizeof(flagTest), "");



			// Check now, and check if we under the maxlevels line
			if (StrEqual(flagTest, "") && g_iLevels < MAXLEVELS)
			{
				// Get point count
				new points = KvGetNum(all_levels, "points");
				


				// Check for duplicate
				for (new i=0; i < g_iLevels; i++)
				{
					// if found duplicate, skip this level
					if (points == g_iLevelPoints[i])
					{
						// But first say it 
						LogToFile(g_sLogFile, "[ STAMM ] Stamm Level with %i Points duplicated!!", points);

						continue;
					}
				}
				


				// Save this level
				g_iLevelPoints[g_iLevels] = points;
				


				// Get the name of this level
				KvGetSectionName(all_levels, g_sLevelKey[g_iLevels], sizeof(g_sLevelKey[]));
				KvGetString(all_levels, "name", g_sLevelName[g_iLevels], sizeof(g_sLevelName[]));



				// save on debug
				if (g_bDebug) 
				{
					LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Added non priavte Level %s", g_sLevelName[g_iLevels]);
				}


				// Update level counter
				g_iLevels++;
			}
		} 
		while (KvGotoNextKey(all_levels));
		


		// Sort the levels
		levellib_sortLevels();
	}



	// Rewind to start
	KvRewind(all_levels);



	// Now search for all privat levels
	if (KvGotoFirstSubKey(all_levels))
	{
		do
		{
			// Check if flag tag exists
			KvGetString(all_levels, "flag", flagTest, sizeof(flagTest), "");



			// Yes it exists
			if (!StrEqual(flagTest, "") && g_iLevels + g_iPLevels < MAXLEVELS)
			{
				// Get the flag
				Format(g_sLevelFlag[g_iPLevels], sizeof(g_sLevelFlag[]), flagTest);


				// Get the name
				KvGetSectionName(all_levels, g_sLevelKey[g_iLevels+g_iPLevels], sizeof(g_sLevelKey[]));
				KvGetString(all_levels, "name", g_sLevelName[g_iLevels+g_iPLevels], sizeof(g_sLevelName[]));




				// Notice that it loaded the level
				if (g_bDebug) 
				{
					LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Added priavte Level %s", g_sLevelName[g_iLevels+g_iPLevels]);
				}




				// Update privat counter
				g_iPLevels++;
			}
		} 
		while (KvGotoNextKey(all_levels));
	}
}





// Sort levels ASC
public levellib_sortLevels()
{
	for (new i=0; i < g_iLevels; i++)
	{
		for (new j=0; j < g_iLevels-1; j++)
		{
			// Check if next item is less than current item
			if (g_iLevelPoints[j+1] < g_iLevelPoints[j])
			{
				// helper value
				new save = g_iLevelPoints[j];
				

				// Change them
				g_iLevelPoints[j] = g_iLevelPoints[j+1];
				g_iLevelPoints[j+1] = save;
			}
		}
	}
}






// Find the level of clients points
public levellib_PointsToID(client, points)
{
	// First check if he's a special vip
	new spec = clientlib_IsSpecialVIP(client);



	// if so, just give it's level back
	if (spec != -1)
	{
		return g_iLevels+spec+1;
	}



	// Do we have levels?
	if (g_iLevels > 0)
	{
		// Loop through all levels
		for (new i=0; i < g_iLevels; i++)
		{
			// helper var
			new l_points = g_iLevelPoints[i];
			



			// Are we at the end?
			if (i == g_iLevels-1)
			{
				// Does the player is higher than the point level
				if (points >= l_points) 
				{
					// Return index
					return i+1;
				}
			}
			else
			{
				// helper var for next point level
				new n_points = g_iLevelPoints[i+1];
				


				// Check if players points between current and next point level
				if (l_points <= points && points < n_points) 
				{
					// return index
					return i+1;
				}
			}
		}
		


		// No VIP
		return 0;
	}
	


	// Something went terrible wrong
	return -1;
}