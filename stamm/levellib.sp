#pragma semicolon 1

public levellib_LoadLevels()
{
	new Handle:all_levels = CreateKeyValues("StammLevels");
	decl String:flagTest[64];

	if (!FileExists("cfg/stamm/StammLevels.txt"))
		SetFailState("Attention: Couldn't load cfg/stamm/StammLevels.txt. File doesn't exist!");

	FileToKeyValues(all_levels, "cfg/stamm/StammLevels.txt");
	
	if (KvGotoFirstSubKey(all_levels))
	{
		do
		{
			KvGetString(all_levels, "flag", flagTest, sizeof(flagTest), "");

			if (StrEqual(flagTest, "") && g_levels < MAXLEVELS)
			{
				new points = KvGetNum(all_levels, "points");
				
				for (new i=0; i < g_levels; i++)
				{
					if (points == g_LevelPoints[i])
						SetFailState("[ STAMM ] Stamm Level with %i Points duplicated!!", points);
				}
				
				g_LevelPoints[g_levels] = points;
				
				KvGetString(all_levels, "name", g_LevelName[g_levels], sizeof(g_LevelName[]));

				if (g_debug) 
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Added non priavte Level %s", g_LevelName[g_levels]);
				
				g_levels++;
			}
		} 
		while (KvGotoNextKey(all_levels));
		
		levellib_sortLevels();
	}

	KvRewind(all_levels);

	if (KvGotoFirstSubKey(all_levels))
	{
		do
		{
			KvGetString(all_levels, "flag", flagTest, sizeof(flagTest), "");

			if (!StrEqual(flagTest, "") && g_levels + g_plevels < MAXLEVELS)
			{
				Format(g_LevelFlag[g_plevels], sizeof(g_LevelFlag[]), flagTest);

				KvGetString(all_levels, "name", g_LevelName[g_levels+g_plevels], sizeof(g_LevelName[]));

				if (g_debug) 
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Added priavte Level %s", g_LevelName[g_levels+g_plevels]);
				
				g_plevels++;
			}
		} 
		while (KvGotoNextKey(all_levels));
	}
}

public levellib_sortLevels()
{
	for (new i=0; i < g_levels; i++)
	{
		for (new j=0; j < g_levels-1; j++)
		{
			if (g_LevelPoints[j+1] < g_LevelPoints[j])
			{
				new save = g_LevelPoints[j];
				
				g_LevelPoints[j] = g_LevelPoints[j+1];
				g_LevelPoints[j+1] = save;
			}
		}
	}
}

public levellib_PointsToID(client, points)
{
	new spec = clientlib_IsSpecialVIP(client);

	if (spec != -1)
		return g_levels+spec+1;

	if (g_levels > 0)
	{
		for (new i=0; i < g_levels; i++)
		{
			new l_points = g_LevelPoints[i];
			
			if (i == g_levels-1)
			{
				if (points >= l_points) 
					return i+1;
			}
			else
			{
				new n_points = g_LevelPoints[i+1];
				
				if (l_points <= points && points < n_points) 
					return i+1;
			}
		}
		
		return 0;
	}
	
	return -1;
}