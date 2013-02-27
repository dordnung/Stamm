#pragma semicolon 1

public featurelib_addFeature(Handle:plugin, String:name[], String:description[], bool:allowChange, bool:standard)
{
	decl String:basename[64];
	decl String:levelPath[PLATFORM_MAX_PATH + 1];
	decl String:Svalue[128];
	decl String:Svalue2[128];

	new bool:goON = true;

	new value = -1;

	featurelib_getPluginBaseName(plugin, basename, sizeof(basename));
	GetPluginFilename(plugin, g_FeatureList[g_features][FEATURE_BASEREAL], sizeof(basename));

	ReplaceString(g_FeatureList[g_features][FEATURE_BASEREAL], sizeof(basename), ".smx", "", false);

	for (new i=0; i < g_features; i++)
	{
		if (StrEqual(g_FeatureList[i][FEATURE_BASE], basename, false))
		{
			g_FeatureList[i][FEATURE_ENABLE] = 1;
			g_FeatureList[i][FEATURE_HANDLE] = plugin;
			g_FeatureList[i][FEATURE_CHANGE] = allowChange;
			g_FeatureList[i][FEATURE_STANDARD] = standard;

			if (g_pluginStarted)
				CreateTimer(0.5, featurelib_loadFeatures, i);

			if (g_debug)
				LogToFile(g_DebugFile, "[ STAMM DEBUG ] Loaded Feature %s again", basename);

			return;
		}
	}
	
	Format(levelPath, sizeof(levelPath), "cfg/stamm/levels/%s.txt", basename);
	Format(g_FeatureList[g_features][FEATURE_BASE], sizeof(basename), basename);
	Format(g_FeatureList[g_features][FEATURE_NAME], sizeof(basename), name);
	
	g_FeatureList[g_features][FEATURE_HANDLE] = plugin;
	g_FeatureList[g_features][FEATURE_ENABLE] = 1;
	g_FeatureList[g_features][FEATURE_CHANGE] = allowChange;
	g_FeatureList[g_features][FEATURE_STANDARD] = standard;
	
	if (!FileExists(levelPath))
	{
		Format(levelPath, sizeof(levelPath), "%s/levels/%s.txt", g_StammFolder, basename);
			
		if (!FileExists(levelPath))
		{
			goON = false;
			g_FeatureList[g_features][FEATURE_LEVEL][0] = 0;
		}
	}

	if (goON)
	{
		
		new Handle:level_settings = CreateKeyValues("LevelSettings");
		
		FileToKeyValues(level_settings, levelPath);

		if (!KvGotoFirstSubKey(level_settings, false))
			g_FeatureList[g_features][FEATURE_LEVEL][0] = 0;
		else
		{
			new start=0;

			do
			{
				KvGetSectionName(level_settings, Svalue, sizeof(Svalue));
				KvGoBack(level_settings);

				KvGetString(level_settings, Svalue, Svalue2, sizeof(Svalue2));

				Format(g_FeatureBlocks[g_features][start], sizeof(g_FeatureBlocks[][]), Svalue);

				if (StringToInt(Svalue2) > 0)
					value = StringToInt(Svalue2);
				else
				{
					for (new i=0; i < g_levels+g_plevels; i++)
					{
						if (StrEqual(Svalue2, g_LevelName[i]))
						{
							value = i+1; 
							break;
						}
					}
				}

				if (value <= 0 || value > g_levels+g_plevels)
				{
					g_FeatureList[g_features][FEATURE_ENABLE] = 0;

					ServerCommand("sm plugins unload %s", g_FeatureList[g_features][FEATURE_BASEREAL]);
					
					LogToFile(g_LogFile, "[ STAMM ] Invalid Level %i for Feature: %s", value, g_FeatureList[g_features][FEATURE_BASEREAL]);

					return;
				}

				g_FeatureList[g_features][FEATURE_LEVEL][start] = value;
				Format(g_FeatureHaveDesc[g_features][value], sizeof(g_FeatureHaveDesc[]), description);

				start++;

				KvJumpToKey(level_settings, Svalue);

			} 
			while (KvGotoNextKey(level_settings, false));
		}
		
		CloseHandle(level_settings);
	}

	g_features++;

	if (g_pluginStarted)
		CreateTimer(0.5, featurelib_loadFeatures, g_features-1);
}

public Action:featurelib_loadFeatures(Handle:timer, any:featureIndex)
{
	if (featureIndex != -1)
	{
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Loaded Feature %s successfully", g_FeatureList[featureIndex][FEATURE_BASE]);

		sqllib_AddColumn(g_FeatureList[featureIndex][FEATURE_BASE], g_FeatureList[featureIndex][FEATURE_STANDARD]);

		nativelib_startLoaded(g_FeatureList[featureIndex][FEATURE_HANDLE], g_FeatureList[featureIndex][FEATURE_BASE]);
	}
	else
	{
		g_pluginStarted = true;
		
		for (new i = 0; i < g_features; i++)
		{
			sqllib_AddColumn(g_FeatureList[i][FEATURE_BASE], g_FeatureList[i][FEATURE_STANDARD]);
			
			nativelib_startLoaded(g_FeatureList[i][FEATURE_HANDLE], g_FeatureList[i][FEATURE_BASE]);
			
			if (g_debug) 
				LogToFile(g_DebugFile, "[ STAMM DEBUG ] Loaded Feature %s successfully", g_FeatureList[i][FEATURE_BASE]);
		}
		
		nativelib_StammReady();
		
		if (g_isLate)
		{
			for (new i=1; i <= MaxClients; i++)
			{
				g_ClientReady[i] = false;
				
				if (clientlib_isValidClient_PRE(i))
					sqllib_InsertPlayer(i);
			}
		}
	}
	
	return Plugin_Handled;
}

public bool:featurelib_getPluginBaseName(Handle:plugin, String:name[], size)
{
	new retriev;
	
	decl String:basename[64];
	decl String:explodedBasename[10][64];
	
	GetPluginFilename(plugin, basename, sizeof(basename));
	
	ReplaceString(basename, sizeof(basename), ".smx", "");
	
	retriev = ExplodeString(basename, "/", explodedBasename, sizeof(explodedBasename), sizeof(explodedBasename[]));
	
	if (!retriev)
		retriev = ExplodeString(basename, "\\", explodedBasename, sizeof(explodedBasename), sizeof(explodedBasename[]));
		
	if (!retriev)
		Format(name, size, basename);
	else	
		Format(name, size, explodedBasename[retriev-1]);
	
	return true;
}

public featurelib_LoadTranslations()
{
	decl String:LanguagesFolder[PLATFORM_MAX_PATH +1];
	decl String:LanguagesStammFolder[PLATFORM_MAX_PATH +1];
	decl String:FileToOpen[PLATFORM_MAX_PATH +1];
	decl String:PathToFile[PLATFORM_MAX_PATH +1];
	decl String:FileToPath[PLATFORM_MAX_PATH +1];
	
	new Handle:Folder;
	new FileType:type;

	Format(LanguagesFolder, sizeof(LanguagesFolder), "%s/languages", g_StammFolder);
	BuildPath(Path_SM, LanguagesStammFolder, sizeof(LanguagesStammFolder), "translations/stamm");
	
	Folder = OpenDirectory(LanguagesFolder);
	
	while (ReadDirEntry(Folder, FileToOpen, sizeof(FileToOpen), type))
	{
		if (type == FileType_File)
		{
			Format(PathToFile, sizeof(PathToFile), "%s/%s", LanguagesFolder, FileToOpen);
			Format(FileToPath, sizeof(FileToPath), "%s/%s", LanguagesStammFolder, FileToOpen);
			
			new Handle:kv = CreateKeyValues("Phrases");
			
			if (FileToKeyValues(kv, PathToFile))
			{
				KvSetSectionName(kv, "Phrases");
				KeyValuesToFile(kv, FileToPath);
				
				CloseHandle(kv);
			}
		}
	}
}

public featurelib_UnloadFeature(Handle:plugin)
{
	new index = featurelib_getFeatureByHandle(plugin);

	ServerCommand("sm plugins unload %s", g_FeatureList[index][FEATURE_BASEREAL]);

	g_FeatureList[index][FEATURE_ENABLE] = 0;
	CPrintToChatAll("%s %t", g_StammTag, "UnloadedFeature", g_FeatureList[index][FEATURE_NAME]);
}

public featurelib_loadFeature(Handle:plugin)
{
	new index = featurelib_getFeatureByHandle(plugin);

	ServerCommand("sm plugins load %s", g_FeatureList[index][FEATURE_BASEREAL]);

	g_FeatureList[index][FEATURE_ENABLE] = 1;
	CPrintToChatAll("%s %t", g_StammTag, "LoadedFeature", g_FeatureList[index][FEATURE_NAME]);
}

public featurelib_ReloadFeature(Handle:plugin)
{
	featurelib_UnloadFeature(plugin);
	featurelib_loadFeature(plugin);
}

public Action:featurelib_Load(args)
{
	if (GetCmdArgs() == 1)
	{
		decl String:basename[64];
		
		GetCmdArg(1, basename, sizeof(basename));

		for (new i=0; i < g_features; i++)
		{
			if (g_FeatureList[i][FEATURE_ENABLE] == 0 && StrEqual(basename, g_FeatureList[i][FEATURE_BASE], false))
			{
				featurelib_loadFeature(g_FeatureList[i][FEATURE_HANDLE]);

				return Plugin_Handled;
			}
		}
		
		for (new i=0; i < g_features; i++)
		{
			if (g_FeatureList[i][FEATURE_ENABLE] == 0 && StrEqual(basename, g_FeatureList[i][FEATURE_BASEREAL], false))
			{
				featurelib_loadFeature(g_FeatureList[i][FEATURE_HANDLE]);

				return Plugin_Handled;
			}
		}

		PrintToServer("Feature %s was not loaded before, try to load it via SM...", basename);

		ServerCommand("sm plugins load %s", basename);
	}
	else
		ReplyToCommand(0, "Usage: stamm_feature_load <basename>");
	
	return Plugin_Handled;
}

public Action:featurelib_UnLoad(args)
{
	if (GetCmdArgs() == 1)
	{
		decl String:basename[64];
		
		GetCmdArg(1, basename, sizeof(basename));

		for (new i=0; i < g_features; i++)
		{
			if (g_FeatureList[i][FEATURE_ENABLE] == 1 && StrEqual(basename, g_FeatureList[i][FEATURE_BASE], false))
			{
				featurelib_UnloadFeature(g_FeatureList[i][FEATURE_HANDLE]);

				return Plugin_Handled;
			}
		}
		
		for (new i=0; i < g_features; i++)
		{
			if (g_FeatureList[i][FEATURE_ENABLE] == 1 && StrEqual(basename, g_FeatureList[i][FEATURE_BASEREAL], false))
			{
				featurelib_UnloadFeature(g_FeatureList[i][FEATURE_HANDLE]);

				return Plugin_Handled;
			}
		}

		ReplyToCommand(0, "Error. Feature not found or already unloaded.");
	}
	else
		ReplyToCommand(0, "Usage: stamm_feature_unload <basename>");
	
	return Plugin_Handled;
}

public Action:featurelib_ReLoad(args)
{
	if (GetCmdArgs() == 1)
	{
		decl String:basename[64];
		
		GetCmdArg(1, basename, sizeof(basename));

		for (new i=0; i < g_features; i++)
		{
			if (StrEqual(basename, g_FeatureList[i][FEATURE_BASE], false))
			{
				featurelib_ReloadFeature(g_FeatureList[i][FEATURE_HANDLE]);

				return Plugin_Handled;
			}
		}
		
		for (new i=0; i < g_features; i++)
		{
			if (StrEqual(basename, g_FeatureList[i][FEATURE_BASEREAL], false))
			{
				featurelib_ReloadFeature(g_FeatureList[i][FEATURE_HANDLE]);

				return Plugin_Handled;
			}	
		}

		ReplyToCommand(0, "Error. Feature not found.");
	}
	else
		ReplyToCommand(0, "Usage: stamm_feature_reload <basename>");
	
	return Plugin_Handled;
}

public Action:featurelib_List(args)
{
	PrintToServer("[STAMM] Listing %d Plugin(s):", g_features);

	for (new i=0; i < g_features; i++)
	{
		if (g_FeatureList[i][FEATURE_ENABLE])
			PrintToServer("  %02d \"%s\" <%s>", i+1, g_FeatureList[i][FEATURE_NAME], g_FeatureList[i][FEATURE_BASEREAL]);
		else
			PrintToServer("  %02d Disabled - \"%s\" <%s>", i+1, g_FeatureList[i][FEATURE_NAME], g_FeatureList[i][FEATURE_BASEREAL]);
	}
	
	return Plugin_Handled;
}

public featurelib_getFeatureByHandle(Handle:plugin)
{
	for (new i=0; i < g_features; i++)
	{
		if (g_FeatureList[i][FEATURE_HANDLE] == plugin)
			return i;
	}

	return -1;
}