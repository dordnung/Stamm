#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "FastLadder",
	author = "Bara",
	description = "Prohibit non VIP's the fast go up on ladders",
	version = "1.0",
	url = "www.bara.in"
};

public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
		SetFailState("Can't Load Feature, not Supported for your game!");
		
	STAMM_LoadTranslation();

	Format(description, sizeof(description), "%T", "GetFastLadder", LANG_SERVER);

	STAMM_AddFeature("VIP FastLadder", description, false);
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (STAMM_IsClientValid(client) && !STAMM_HaveClientFeature(client))
	{
		if (GetEntityMoveType(client) == MOVETYPE_LADDER)
		{
			if (buttons & IN_FORWARD || buttons & IN_BACK)
			{
				if (buttons & IN_MOVELEFT)
					buttons &= ~IN_MOVELEFT;

				if (buttons & IN_MOVERIGHT)
					buttons &= ~IN_MOVERIGHT;
			}
		}
	}
}