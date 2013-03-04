#include <sourcemod>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Stamm Feature Admin Flags",
	author = "Popoklopsi",
	version = "1.3",
	description = "Give VIP's admin flags",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm"))
		SetFailState("Can't Load Feature, Stamm is not installed!");
		
	STAMM_LoadTranslation();

	STAMM_AddFeature("VIP Admin Flags", "");
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	new String:theflags[64];

	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.couch-fighter.de/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);

	for (new i=1; i <= STAMM_GetLevelCount(); i++)
	{
		Format(theflags, sizeof(theflags), "");
		
		getLevelFlag(theflags, sizeof(theflags), i);
		
		if (!StrEqual(theflags, ""))
		{
			Format(description, sizeof(description), "%T", "GetAdminFlags", LANG_SERVER, theflags);
			STAMM_AddFeatureText(i, description);
		}
	}
}

public STAMM_OnClientReady(client)
{
	if (STAMM_IsClientValid(client))
	{
		decl String:steamid[64];
		decl String:File[PLATFORM_MAX_PATH + 1];
		decl String:File2[PLATFORM_MAX_PATH + 1];
		decl String:Line[1024];
		decl String:theflags[64];
		
		new Handle:hFile;
		new Handle:hFile2;
		
		BuildPath(Path_SM, File, sizeof(File), "configs/admins_simple.ini");
		BuildPath(Path_SM, File2, sizeof(File2), "configs/admins_simple_2.ini");
		GetClientAuthString(client, steamid, sizeof(steamid));
		
		hFile = OpenFile(File, "rb");
		
		if (hFile == INVALID_HANDLE) 
			return;
			
		hFile2 = OpenFile(File2, "wb");
		
		if (hFile2 == INVALID_HANDLE)
			return;
		
		Format(theflags, sizeof(theflags), "");
		
		getLevelFlag(theflags, sizeof(theflags), STAMM_GetClientLevel(client));
		
		while (ReadFileLine(hFile, Line, sizeof(Line)))
		{
			ReplaceString(Line, sizeof(Line), "\n", "");
			
			if (StrContains(Line, steamid) != -1) 
				continue;
			
			WriteFileLine(hFile2, Line);
		}
		
		if (!StrEqual(theflags, "")) 
			WriteFileLine(hFile2, "\"%s\" \"%s\" \"\"", steamid, theflags);
		
		CloseHandle(hFile);
		CloseHandle(hFile2);
		
		DeleteFile(File);
		RenameFile(File, File2);
	}
}

public getLevelFlag(String:theflags[], size, level)
{
	new Handle:flagvalue = CreateKeyValues("AdminFlags");

	if (!FileExists("cfg/stamm/features/adminflags.txt"))
	{
		STAMM_WriteToLog(false, "Didn't find cfg/stamm/features/adminflags.txt!");
		return;
	}
	
	FileToKeyValues(flagvalue, "cfg/stamm/features/adminflags.txt");
	
	if (KvGotoFirstSubKey(flagvalue, false))
	{
		do
		{
			decl String:section[64];
			
			KvGetSectionName(flagvalue, section, sizeof(section));

			if (STAMM_GetLevelNumber(section) == level)
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