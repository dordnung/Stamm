public levellib_LoadLevels()
{
	new Handle:all_levels = CreateKeyValues("StammLevels");
	FileToKeyValues(all_levels, "cfg/stamm/StammLevels.txt");
	
	if (KvGotoFirstSubKey(all_levels))
	{
		do
		{
			new points = KvGetNum(all_levels, "points");
			
			for (new i=0; i < g_levels; i++)
			{
				if (points == g_LevelPoints[i])
				{
					LogToFile(g_LogFile, "[ STAMM ] Stamm Level Points %i duplicated!!!", points);
					return;
				}
			}
			
			g_LevelPoints[g_levels] = points;
			
			KvGetString(all_levels, "name", g_LevelName[g_levels], 129);
			
			g_levels++;
		} 
		while (KvGotoNextKey(all_levels));
		
		levellib_sortLevels();
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

public levellib_PointsToID(points)
{
	if (g_levels > 0)
	{
		for (new i=0; i < g_levels; i++)
		{
			new l_points = g_LevelPoints[i];
			
			if (i == g_levels-1)
			{
				if (points >= l_points) return i+1;
			}
			else
			{
				new n_points = g_LevelPoints[i+1];
				if (l_points <= points && points < n_points) return i+1;
			}
		}
	}
	else return -1;
	
	return 0;
}