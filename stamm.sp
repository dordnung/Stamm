#include <sourcemod>
#include <sdktools>
#include <colors>
#include <autoexecconfig>

#include "stamm/globals.sp"
#include "stamm/configlib.sp"
#include "stamm/levellib.sp"
#include "stamm/sqllib.sp"
#include "stamm/sqlback.sp"
#include "stamm/pointlib.sp"
#include "stamm/clientlib.sp"
#include "stamm/nativelib.sp"
#include "stamm/panellib.sp"
#include "stamm/eventlib.sp"
#include "stamm/featurelib.sp"
#include "stamm/otherlib.sp"

#undef REQUIRE_PLUGIN
#include <updater>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Stamm",
	author = "Popoklopsi",
	version = g_Plugin_Version2,
	description = "A powerful VIP Addon with a lot of features",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	nativelib_Start();
	
	g_isLate = late;
	
	return APLRes_Success;
}

public OnPluginStart()
{
	CheckStammFolders();
	featurelib_LoadTranslations(true);

	if (!CColorAllowed(Color_Lightgreen))
	{
		if (CColorAllowed(Color_Lime))
			CReplaceColor(Color_Lightgreen, Color_Lime);
		else if (CColorAllowed(Color_Olive))
			CReplaceColor(Color_Lightgreen, Color_Olive);
	}

	LoadTranslations("stamm.phrases");

	g_points = 1;
	g_happyhouron = 0;
	
	Format(g_StammTag, sizeof(g_StammTag), "{lightgreen}[ {green}Stamm {lightgreen}]");
	
	RegConsoleCmd("say", clientlib_CmdSay);

	RegServerCmd("stamm_start_happyhour", otherlib_StartHappy, "Starts happy hour: stamm_start_happyhour <time> <factor>");
	RegServerCmd("stamm_stop_happyhour", otherlib_StopHappy, "Stops happy hour");

	RegServerCmd("stamm_load_feature", featurelib_Load, "Loads a feature: stamm_load_feature <basename>");
	RegServerCmd("stamm_unload_feature", featurelib_UnLoad, "Unloads a feature: stamm_unload_feature <basename>");
	RegServerCmd("stamm_reload_feature", featurelib_ReLoad, "Reloads a feature: stamm_reload_feature <basename>");

	RegServerCmd("stamm_feature_list", featurelib_List, "List all features.");

	RegServerCmd("stamm_convert_db", sqllib_convertDB, "Converts the stamm database to a file");
	
	otherlib_saveGame();
	levellib_LoadLevels();
	configlib_CreateConfig();
	eventlib_Start();
	
	g_pluginStarted = false;
}

public OnPluginEnd()
{
	for (new i=0; i < g_features; i++)
	{
		if (g_FeatureList[i][FEATURE_ENABLE] == 1)
			featurelib_UnloadFeature(g_FeatureList[i][FEATURE_HANDLE]);
	}
}

public OnPluginPauseChange(bool:pause)
{
	if (pause)
		OnPluginEnd();
	else
	{
		for (new i=0; i < g_features; i++)
		{
			if (g_FeatureList[i][FEATURE_ENABLE] == 1)
				featurelib_loadFeature(g_FeatureList[i][FEATURE_HANDLE]);
		}
	}
}

public CheckStammFolders()
{
	decl String:LogFolder[PLATFORM_MAX_PATH +1];
	decl String:LanguagesFolder[PLATFORM_MAX_PATH +1];
	decl String:LanguagesStammFolder[PLATFORM_MAX_PATH +1];
	decl String:LevelFolder[PLATFORM_MAX_PATH +1];
	decl String:CurrentDate[20];
	
	FormatTime(CurrentDate, sizeof(CurrentDate), "%d-%m-%y");
	
	BuildPath(Path_SM, g_StammFolder, sizeof(g_StammFolder), "Stamm");
	BuildPath(Path_SM, g_LogFile, sizeof(g_LogFile), "Stamm/logs/Stamm_Logs (%s).log", CurrentDate);
	BuildPath(Path_SM, LanguagesStammFolder, sizeof(LanguagesStammFolder), "translations/stamm");
	BuildPath(Path_SM, g_DebugFile, sizeof(g_DebugFile), "Stamm/logs/Stamm_Debugs (%s).log", CurrentDate);
	
	Format(LogFolder, sizeof(LogFolder), "%s/logs", g_StammFolder);
	Format(LanguagesFolder, sizeof(LanguagesFolder), "%s/languages", g_StammFolder);
	Format(LevelFolder, sizeof(LevelFolder), "%s/levels", g_StammFolder);
	
	if (!DirExists(LanguagesStammFolder)) 
		CreateDirectory(LanguagesStammFolder, 511);
	
	if (DirExists(g_StammFolder))
	{
		if (!DirExists(LogFolder)) 
			CreateDirectory(LogFolder, 511);
			
		if (!DirExists(LanguagesFolder)) 
			CreateDirectory(LanguagesFolder, 511);
			
		if (!DirExists(LevelFolder)) 
			CreateDirectory(LevelFolder, 511);
	}
	else
	{
		CreateDirectory(g_StammFolder, 511);
		CreateDirectory(LogFolder, 511);
		CreateDirectory(LanguagesFolder, 511);
		CreateDirectory(LevelFolder, 511);
	}
}

public OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
		Updater_AddPlugin("http://popoklopsi.de/stamm/updater/update.php?plugin=stamm");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
		Updater_AddPlugin("http://popoklopsi.de/stamm/updater/update.php?plugin=stamm");
}

public OnConfigsExecuted()
{
	configlib_LoadConfig();
	
	if (!g_pluginStarted)
	{	
		sqllib_Start();
		pointlib_Start();
		sqllib_LoadDB();
	
		panellib_Start();
		
		sqlback_getDatabaseVersion();
	}
	
	otherlib_checkTimer(pointlib_timetimer);
	otherlib_checkTimer(pointlib_showpointer);
	otherlib_checkTimer(otherlib_inftimer);
	otherlib_checkTimer(clientlib_olddelete);
	
	if (g_vip_type == 3 || g_vip_type == 5 || g_vip_type == 6 ||  g_vip_type == 7)
		pointlib_timetimer = CreateTimer((60.0*g_time_point), pointlib_PlayerTime, _, TIMER_REPEAT);
		
	if (g_showpoints && g_see_text == 0) 
		pointlib_showpointer = CreateTimer(float(g_showpoints), pointlib_PointShower, _, TIMER_REPEAT);
		
	if (g_infotime > 0.0) 
		otherlib_inftimer = CreateTimer(g_infotime, otherlib_PlayerInfoTimer, _, TIMER_REPEAT);

	if (g_delete) 
		clientlib_olddelete = CreateTimer(36000.0, clientlib_deleteOlds, _, TIMER_REPEAT);
	
	otherlib_PrepareFiles();
}

public stammStarted()
{	
	if (!g_isLate)
		CreateTimer(0.5, featurelib_loadFeatures, -1);
	else 
	{
		decl String:pathdir[PLATFORM_MAX_PATH + 1];
		decl String:buffer[PLATFORM_MAX_PATH + 1];

		new FileType:typs;

		BuildPath(Path_SM, pathdir, sizeof(pathdir), "plugins/stamm");

		new Handle:dir = OpenDirectory(pathdir);

		if (dir != INVALID_HANDLE)
		{
			while (ReadDirEntry(dir, buffer, sizeof(buffer), typs))
			{
				if (typs == FileType_File)
				{
					if (StrContains(buffer, ".smx", false) > 0)
					{
						ReplaceString(buffer, sizeof(buffer), ".smx", "", false);

						ServerCommand("sm plugins load stamm/%s", buffer);
					}
				}
			}

			CloseHandle(dir);
		}

		CreateTimer(2.0, featurelib_loadFeatures, -1);
	}

	if (g_debug)
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Stamm successfully loaded");
}