public featurelib_addFeature(String:basename[], String:name[], String:description[], bool:allowChange)
{
	new String:levelPath[PLATFORM_MAX_PATH + 1];
	new String:Svalue[128];
	new value = -1;
	new mode = -1;
	
	for (new i=0; i < g_features; i++)
	{
		if (StrEqual(g_FeatureBase[i], basename))
		{
			g_FeatureEnable[g_features] = 0;
			ServerCommand("sm plugins unload stamm/%s", basename);

			LogToFile(g_LogFile, "[ STAMM ] Feature %s invalid or duplicated!!", basename);
			
			return -1;
		}
	}
	
	Format(levelPath, sizeof(levelPath), "%s/levels/%s.txt", g_StammFolder, basename);
	Format(g_FeatureBase[g_features], 64, basename);
	Format(g_FeatureName[g_features], 64, name);
	Format(g_FeatureDesc[g_features], 256, description);
	
	g_FeatureEnable[g_features] = 1;
	g_FeatureChange[g_features] = allowChange;
	
	sqllib_AddColumn(basename);
	
	if (!FileExists(levelPath))
	{
		Format(levelPath, sizeof(levelPath), "cfg/stamm/LevelSettings.txt");
		mode = 1;
		
		if (!FileExists(levelPath))
		{
			g_FeatureEnable[g_features] = 0;
			ServerCommand("sm plugins unload stamm/%s", basename);

			LogToFile(g_LogFile, "[ STAMM ] Didn't find level config for %s", basename);
			
			return -1;
		}
	}
	
	new Handle:level_settings = CreateKeyValues("LevelSettings");
	
	FileToKeyValues(level_settings, levelPath);
	
	if (mode == -1) KvGetString(level_settings, "level", Svalue, sizeof(Svalue));
	else KvGetString(level_settings, basename, Svalue, sizeof(Svalue));
	
	if (StringToInt(Svalue) != 0) value = StringToInt(Svalue);
	else
	{
		for (new i=0; i < g_levels; i++)
		{
			if (StrEqual(Svalue, g_LevelName[i])) value = i+1; 
		}
	}
	
	CloseHandle(level_settings);
	
	if (value != -1)
	{
		if (value > 0 && value <= g_levels)
		{
			if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Loaded Feature %s", basename);
		}
		else
		{
			g_FeatureEnable[g_features] = 0;
			ServerCommand("sm plugins unload stamm/%s", basename);
			
			LogToFile(g_LogFile, "[ STAMM ] Invalid Level for %s", basename);
		}
	}

	g_FeatureLevel[g_features] = value;
	
	g_features++;
	
	return value;
}

public featurelib_LoadTranslations()
{
	new Handle:Folder;
	new String:LanguagesFolder[PLATFORM_MAX_PATH +1];
	new String:PhraseFile[PLATFORM_MAX_PATH +1];
	new String:FileToOpen[PLATFORM_MAX_PATH +1];
	new FileType:type;
	
	Format(LanguagesFolder, sizeof(LanguagesFolder), "%s/languages", g_StammFolder);
	
	Folder = OpenDirectory(LanguagesFolder);
	
	while (ReadDirEntry(Folder, FileToOpen, sizeof(FileToOpen), type))
	{
		if (type == FileType_File)
		{
			new Handle:kv = CreateKeyValues("StammLanguage");
			new String:PathToFile[PLATFORM_MAX_PATH +1];
			
			Format(PathToFile, sizeof(PathToFile), "%s/%s", LanguagesFolder, FileToOpen);
			
			if (FileToKeyValues(kv, PathToFile))
			{
				if (KvGotoFirstSubKey(kv))
				{
					do
					{
						decl String:PhraseString[128];
						decl String:language[128];
						
						KvGetSectionName(kv, PhraseString, sizeof(PhraseString));

						if (KvGotoFirstSubKey(kv, false))
						{
							new index = 0;
							decl String:value[1024];
							
							do
							{
								KvGetSectionName(kv, language, sizeof(language));
								featurelib_CheckLanguageFolder(language);
								
								KvGoBack(kv);

								if (!StrEqual(language, "en") && !StrEqual(language, "#format")) BuildPath(Path_SM, PhraseFile, sizeof(PhraseFile), "translations/%s/stamm-features.phrases.txt", language);
								else BuildPath(Path_SM, PhraseFile, sizeof(PhraseFile), "translations/stamm-features.phrases.txt");
								
								new Handle:Phrase = CreateKeyValues("Phrases");
								
								FileToKeyValues(Phrase, PhraseFile);
								
								if (KvJumpToKey(Phrase, PhraseString, true))
								{
									KvGetString(Phrase, language, value, sizeof(value), "");

									if (StrEqual(value, "") || g_replacePhrases)
									{
										KvGetString(kv, language, value, sizeof(value));
										KvSetString(Phrase, language, value);
									}
									
									KvGoBack(Phrase);
								}
								
								KeyValuesToFile(Phrase, PhraseFile);
								
								CloseHandle(Phrase);
								
								KvGotoFirstSubKey(kv, false);
								for (new i=0; i < index; i++) KvGotoNextKey(kv, false);
								index++;
								
							}
							while (KvGotoNextKey(kv, false));
							
							KvGoBack(kv);
						}
					}
					while (KvGotoNextKey(kv));

					KvGoBack(kv);
				}
				CloseHandle(kv);
			}
		}
	}
}

public featurelib_CheckLanguageFolder(String:language[])
{
	new String:PhraseFile[PLATFORM_MAX_PATH +1];
	new String:PhraseFolder[PLATFORM_MAX_PATH +1];
	
	if (!StrEqual(language, "en") && !StrEqual(language, "#format"))
	{
		BuildPath(Path_SM, PhraseFolder, sizeof(PhraseFolder), "translations/%s", language);
		if (!DirExists(PhraseFolder)) CreateDirectory(PhraseFolder, 511);
		
		BuildPath(Path_SM, PhraseFile, sizeof(PhraseFile), "translations/%s/stamm-features.phrases.txt", language);
	}
	else BuildPath(Path_SM, PhraseFile, sizeof(PhraseFile), "translations/stamm-features.phrases.txt");
	
	if (!FileExists(PhraseFile))
	{
		new Handle:createFile = OpenFile(PhraseFile, "wb");
		new Handle:Phrase = CreateKeyValues("Phrases");
		
		KeyValuesToFile(Phrase, PhraseFile);
		
		CloseHandle(Phrase);
		CloseHandle(createFile);
	}
}

public featurlib_UnloadFeature(String:basename[])
{
	ServerCommand("sm plugins unload stamm/%s", basename);
	
	for (new i=0; i < g_features; i++)
	{
		if (StrEqual(g_FeatureBase[i], basename))
		{
			g_FeatureEnable[i] = 0;
			CPrintToChatAll("%s %T", g_StammTag, "UnloadedFeature", LANG_SERVER, g_FeatureName[i]);
			
			break;
		}
	}
}

public featurlib_loadFeature(String:basename[])
{
	ServerCommand("sm plugins load stamm/%s", basename);
	
	for (new i=0; i < g_features; i++)
	{
		if (StrEqual(g_FeatureBase[i], basename))
		{
			g_FeatureEnable[i] = 1;
			CPrintToChatAll("%s %T", g_StammTag, "LoadedFeature", LANG_SERVER, g_FeatureName[i]);
			
			break;
		}
	}
}