#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:j_path;

new bool:MapTimer = true;

new String:path[PLATFORM_MAX_PATH + 1];

public Plugin:myinfo =
{
	name = "Stamm Feature Joinsound",
	author = "Popoklopsi",
	version = "1.3",
	description = "Give VIP's a Joinsound",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetJoinsound", LANG_SERVER);
	
	STAMM_AddFeature("VIP Joinsound", description);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("stamm/features/joinsound");

	j_path = AutoExecConfig_CreateConVar("joinsound_path", "music/stamm/vip_sound.mp3", "Path to joinsound, after sound/");
	
	AutoExecConfig(true, "joinsound", "stamm/features");
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	new String:downloadfile[PLATFORM_MAX_PATH + 1];
	
	GetConVarString(j_path, path, sizeof(path));
	
	PrecacheSound(path, true);
	
	Format(downloadfile, sizeof(downloadfile), "sound/%s", path);
	AddFileToDownloadsTable(downloadfile);
}

public STAMM_OnClientReady(client)
{
	if (STAMM_HaveClientFeature(client) && MapTimer) 
		CreateTimer(4.0, StartSound);
}

public OnMapStart()
{
	MapTimer = false;
	
	CreateTimer(60.0, MapTimer_Change);
}

public Action:MapTimer_Change(Handle:timer)
{
	MapTimer = true;
}

public Action:StartSound(Handle:timer)
{
	if (STAMM_GetGame() != GameCSGO) 
		EmitSoundToAll(path);
	else
	{
		for (new i=0; i <= MaxClients; i++)
		{
			if (STAMM_IsClientValid(i)) 
				ClientCommand(i, "play %s", path);
		}
	}
}