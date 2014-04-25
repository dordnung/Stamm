/**
 * -----------------------------------------------------
 * File        levellib.sp
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


// Use semicolon
#pragma semicolon 1





// Load all levels
levellib_LoadLevels()
{
	// Create the keyvalue
	decl String:flagTest[64];
	decl String:flagTest2[64];
	new bool:duplicate;


	// Didn't find the stamm level file -> Stop plugin, we can't do anything here
	if (!FileExists("cfg/stamm/StammLevels.txt"))
	{
		SetFailState("Fatal Error: Couldn't load \"cfg/stamm/StammLevels.txt\". File doesn't exist!");

		return;
	}


	new Handle:all_levels = CreateKeyValues("StammLevels");


	// Load the file to keyvalue
	FileToKeyValues(all_levels, "cfg/stamm/StammLevels.txt");


	// First go through all non private levels
	if (KvGotoFirstSubKey(all_levels))
	{
		do
		{
			duplicate = false;

			// Check if it's a non private level
			KvGetString(all_levels, "flag", flagTest, sizeof(flagTest), "");
			KvGetString(all_levels, "flags", flagTest2, sizeof(flagTest2), "");


			// Check now, and check if we under the maxlevels line
			if (strlen(flagTest) < 1 && strlen(flagTest2) < 1 && g_iLevels < MAXLEVELS)
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
						StammLog(false, "Level with %i Points is duplicated!", points);

						duplicate = true;
					}
				}
				

				if (duplicate)
				{
					continue;
				}


				// Save this level
				g_iLevelPoints[g_iLevels] = points;
				


				// Get the name of this level
				KvGetSectionName(all_levels, g_sLevelKey[g_iLevels], sizeof(g_sLevelKey[]));
				KvGetString(all_levels, "name", g_sLevelName[g_iLevels], sizeof(g_sLevelName[]));



				// save on debug
				StammLog(true, "Added non priavte Level %s", g_sLevelName[g_iLevels]);

				// Update level counter
				g_iLevels++;
			}
		} 
		while (KvGotoNextKey(all_levels));
		


		// Sort the levels
		levellib_sortLevels();
	}
	else
	{
		SetFailState("Fatal Error: Couldn't parse \"cfg/stamm/StammLevels.txt\". File contains invalid content!");

		return;
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

			if (strlen(flagTest) <= 0)
			{
				KvGetString(all_levels, "flags", flagTest, sizeof(flagTest), "");
			}

			// Yes it exists
			if (strlen(flagTest) > 0 && g_iLevels + g_iPLevels < MAXLEVELS)
			{
				// Get the flag
				Format(g_sLevelFlag[g_iPLevels], sizeof(g_sLevelFlag[]), flagTest);


				// Get the name
				KvGetSectionName(all_levels, g_sLevelKey[g_iLevels+g_iPLevels], sizeof(g_sLevelKey[]));
				KvGetString(all_levels, "name", g_sLevelName[g_iLevels+g_iPLevels], sizeof(g_sLevelName[]));



				// Notice that it loaded the level
				StammLog(true, "Added priavte Level %s", g_sLevelName[g_iLevels+g_iPLevels]);


				// Update privat counter
				g_iPLevels++;
			}
		} 
		while (KvGotoNextKey(all_levels));
	}
}




// Sort levels ASC
levellib_sortLevels()
{
	for (new i=0; i < g_iLevels; i++)
	{
		for (new j=0; j < g_iLevels-1; j++)
		{
			// Check if next item is less than current item
			if (g_iLevelPoints[j + 1] < g_iLevelPoints[j])
			{
				// helper value
				new save = g_iLevelPoints[j];
				

				// Change them
				g_iLevelPoints[j] = g_iLevelPoints[j + 1];
				g_iLevelPoints[j + 1] = save;
			}
		}
	}
}





// Find the level of clients points
levellib_ClientPointsToID(client)
{
	// First check if he's a special vip
	new spec = clientlib_IsSpecialVIP(client);
	new points = g_iPlayerPoints[client];


	// if so, just give it's level back
	if (spec != -1)
	{
		return g_iLevels + spec + 1;
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
			if (i == g_iLevels - 1)
			{
				// Does the player is higher than the point level
				if (points >= l_points) 
				{
					// Return index
					return i + 1;
				}
			}
			else
			{
				// helper var for next point level
				new n_points = g_iLevelPoints[i + 1];


				// Check if players points between current and next point level
				if (l_points <= points && points < n_points) 
				{
					// return index
					return i + 1;
				}
			}
		}


		// No VIP
		return 0;
	}
	

	// Something went terrible wrong
	return -1;
}