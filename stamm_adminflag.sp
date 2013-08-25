#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Admin Flags",
	author = "Popoklopsi",
	version = "1.2",
	description = "Give VIP's admin flags",
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
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];
	new String:theflags[64];
	
	Format(description, sizeof(description), "%T", "GetAdminFlags", LANG_SERVER, "");
	
	AddStammFeature(basename, "VIP Admin Flags", description);
	
	for (new i=1; i <= GetStammLevelCount(); i++)
	{
		Format(theflags, sizeof(theflags), "");
		
		getLevelFlag(theflags, sizeof(theflags), i);
		
		if (!StrEqual(theflags, ""))
		{
			Format(description, sizeof(description), "%T", "YouGetAdminFlags", LANG_SERVER, theflags);
			AddStammFeatureInfo(basename, i, description);
		}
	}
}

public OnStammClientReady(client)
{
	if (IsStammClientValid(client))
	{
		new String:steamid[64];
		new String:File[PLATFORM_MAX_PATH + 1];
		new String:File2[PLATFORM_MAX_PATH + 1];
		new String:Line[1024];
		new String:theflags[64];
		new Handle:hFile;
		new Handle:hFile2;
		
		BuildPath(Path_SM, File, sizeof(File), "configs/admins_simple.ini");
		BuildPath(Path_SM, File2, sizeof(File2), "configs/admins_simple_2.ini");
		GetClientAuthString(client, steamid, sizeof(steamid));
		
		hFile = OpenFile(File, "rb");
		if (hFile == INVALID_HANDLE) return;
		hFile2 = OpenFile(File2, "wb");
		if (hFile2 == INVALID_HANDLE) return;
		
		Format(theflags, sizeof(theflags), "");
		
		getLevelFlag(theflags, sizeof(theflags), GetClientStammLevel(client));
		
		while (ReadFileLine(hFile, Line, sizeof(Line)))
		{
			ReplaceString(Line, sizeof(Line), "\n", "");
			
			if (StrContains(Line, steamid) != -1) continue;
			
			WriteFileLine(hFile2, Line);
		}
		if (!StrEqual(theflags, "")) WriteFileLine(hFile2, "\"%s\" \"%s\" \"\"", steamid, theflags);
		
		CloseHandle(hFile);
		CloseHandle(hFile2);
		
		DeleteFile(File);
		RenameFile(File, File2);
	}
}

public getLevelFlag(String:theflags[], size, level)
{
	new Handle:flagvalue = CreateKeyValues("AdminFlags");
	
	FileToKeyValues(flagvalue, "cfg/stamm/features/adminflags.txt");
	
	if (KvGotoFirstSubKey(flagvalue, false))
	{
		do
		{
			decl String:section[64];
			
			KvGetSectionName(flagvalue, section, sizeof(section));

			if (GetStammLevelNumber(section) == level)
			{
				KvGoBack(flagvalue);
				KvGetString(flagvalue, section, theflags, size);

				break;
			}
		}
		while (KvGotoNextKey(flagvalue, false));
	}
	
	CloseHandle(flagvalue);
}