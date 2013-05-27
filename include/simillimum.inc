/**
 * vim: set ts=4 :
 * =============================================================================
 * Simillimum (C)2013-2013 Simillimum Team.  All rights reserved.
 * =============================================================================
 *
 * This file is part of the Simillimum SDK.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#if defined _simillimum_included
 #endinput
#endif
#define _simillimum_included


#include <sourcemod>



/**
 * Enum with possible Handle Errors
 */
enum HandleError
{
	HandleError_None = 0,       /**< No error */
	HandleError_Changed,        /**< The handle has been freed and reassigned */
	HandleError_Type,           /**< The handle has a different type registered */
	HandleError_Freed,          /**< The handle has been freed */
	HandleError_Index,          /**< generic internal indexing error */
	HandleError_Access,         /**< No access permitted to free this handle */
	HandleError_Limit,          /**< The limited number of handles has been reached */
	HandleError_Identity,       /**< The identity token was not usable */
	HandleError_Owner,          /**< Owners do not match for this operation */
	HandleError_Version,        /**< Unrecognized security structure version */
	HandleError_Parameter,      /**< An invalid parameter was passed */
	HandleError_NoInherit,      /**< This type cannot be inherited */
};



/**
 * Checks whether Simillimum is available.
 * Check the first native of Simillimum
 *
 * @return			True if simillimum is available, otherwise false.
 */
stock bool:IsSimillimumAvailable()
{
	return (GetFeatureStatus(FeatureType_Native, "GetHandleStatus") == FeatureStatus_Available)
}


/**
 * Returns the current status of a handle.
 *
 * @param hndl		Handle to get status for.
 * @return			HandleError item.
 */
native HandleError:GetHandleStatus(Handle:hndl);


/**
 * Returns if a supplied command exists.
 *
 * @param command       Command to find.
 * @return              True if command exists, false otherwise.
 */
stock bool:CommandExists(const String:command[])
{
	return (GetCommandFlags(command) != INVALID_FCVAR_FLAGS);
}



/**
 * Awards an achievement to a client.
 *
 * @param client			Client index.
 * @param achievementID		Achievement ID
 * @noreturn
 * @error					Invalid client index, or client not in-game
 */
stock AwardClientAchievement(client, achievementID)
{
	static bool:m_bSupported = false;
	static bool:m_bChecked = false;

	if(!m_bChecked)
	{
		m_bChecked = true;
		
		if(GetUserMessageId("AchievementEvent") != INVALID_MESSAGE_ID)
		{
			m_bSupported = true;
		}
	}

	if(!m_bSupported)
	{
		ThrowError("Game is not supported.");
	}

	if (client < 1 || client > MaxClients)
	{
		ThrowError("Client Index %d out of bounds", client);
	}
	
	if (!IsClientInGame(client))
	{
		ThrowError("Client %d is not in-game");
	}
	
	new Handle:msg = StartMessageOne("AchievementEvent", client, 0);
	
	if(GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(msg, "achievement", achievementID);
		PbSetInt(msg, "count", 0);
		PbSetInt(msg, "user_id", GetClientUserId(client));
	}
	else
	{
		BfWriteShort(msg, achievementID);
	}
	
	EndMessage();
}