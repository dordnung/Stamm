#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:j_path;

new bool:MapTimer = true;

new v_level;

new String:path[PLATFORM_MAX_PATH + 1];
new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Joinsound",
	author = "Popoklopsi",
	version = "1.2",
	description = "Give VIP's a Joinsound",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
}

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
	
	j_path = CreateConVar("joinsound_path", "music/stamm/vip_sound.mp3", "Path to joinsound, after sound/");
	
	AutoExecConfig(true, "joinsound", "stamm/features");
}

public OnConfigsExecuted()
{
	new String:downloadfile[PLATFORM_MAX_PATH + 1];
	
	GetConVarString(j_path, path, sizeof(path));
	
	PrecacheSound(path, true);
	
	Format(downloadfile, sizeof(downloadfile), "sound/%s", path);
	AddFileToDownloadsTable(downloadfile);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetJoinsound", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP Joinsound", description);
	
	Format(description, sizeof(description), "%T", "YouGetJoinsound", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}

public OnStammClientReady(client)
{
	if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename) && MapTimer) CreateTimer(4.0, StartSound);
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
	if (GetStammGame() != GameCSGO) EmitSoundToAll(path);
	else
	{
		for (new i=0; i <= MaxClients; i++)
		{
			if (IsStammClientValid(i)) ClientCommand(i, "play %s", path);
		}
	}
}