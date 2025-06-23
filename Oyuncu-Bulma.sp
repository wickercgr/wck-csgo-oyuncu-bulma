#include <sourcemod>
#include <sdktools>
#include <warden>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "", 
	author = "wck", 
	description = "", 
	version = "1.0"
};

int BeaconColor[4] =  { 255, 75, 75, 255 }, BeaconColor2[4] =  { 128, 128, 128, 255 };
int g_Halo = -1, g_Beam = -1, Global = 0;
float maxbounds[3];
char g_BlipSound[256];
bool Block = false;
ConVar Blockdelay = null, Sure = null;
#define LoopClients(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsClientInGame(%1) && IsPlayerAlive(%1) && GetClientTeam(%1) == 2)

public void OnPluginStart()
{
	HookEvent("round_start", RoundStartEnd);
	HookEvent("round_end", RoundStartEnd);
	Sure = CreateConVar("sm_bulma_sure", "5", "Tnin etrafındaki daire kaç saniye sonra gitsin.", 0, true, 1.0);
	Blockdelay = CreateConVar("sm_bulma_delay", "15", "Komutçu !bul komutunu kaç saniye arayla kullansın", 0, true, 1.0);
	AutoExecConfig(true, "Oyuncu-Bulma", "WCK");
	RegConsoleCmd("sm_bul", Command_Bul, "");
}

public Action Command_Bul(int client, int args)
{
	if (warden_iswarden(client))
	{
		if (!Block)
		{
			LoopClients(i)
			{
				CreateTimer(1.0, Simple, _, TIMER_REPEAT);
				CreateTimer(1.0, Timer_Beacon, GetClientUserId(i), TIMER_REPEAT);
			}
			Block = true;
			Global = Sure.IntValue;
			CreateTimer(Blockdelay.FloatValue, BlockKaldir, _, TIMER_FLAG_NO_MAPCHANGE);
			PrintToChatAll("[SM] CT \x04%d saniye \x01boyunca \x0ETyi görebiliyor.", Sure.IntValue);
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "[SM] %d Saniye sonra tekrar dene.", Blockdelay.IntValue);
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
}

public void OnMapStart()
{
	GameData gameConfig = new GameData("funcommands.games");
	if (gameConfig == null)
	{
		SetFailState("Unable to load game config funcommands.games");
		return;
	}
	
	if (gameConfig.GetKeyValue("SoundBlip", g_BlipSound, sizeof(g_BlipSound)) && g_BlipSound[0])
	{
		PrecacheSound(g_BlipSound, true);
	}
	
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", maxbounds);
	
	while (TR_PointOutsideWorld(maxbounds))
	{
		maxbounds[0]--;
		maxbounds[1]--;
		maxbounds[2]--;
	}
	
	g_Halo = PrecacheModel("materials/sprites/light_glow02.vmt");
	g_Beam = PrecacheModel("materials/sprites/white.vmt");
	
	Block = false;
}

public Action RoundStartEnd(Event evt, const char[] nm, bool dB)
{
	Block = false;
}

public Action BlockKaldir(Handle timer)
{
	Block = false;
	return Plugin_Stop;
}

public Action Simple(Handle timer)
{
	Global--;
	if (Global <= 0)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Timer_Beacon(Handle timer, int userid)
{
	if (Global <= 0)
	{
		return Plugin_Stop;
	}
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{
		return Plugin_Stop;
	}
	
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	
	if (g_Beam > -1 && g_Halo > -1)
	{
		TE_SetupBeamRingPoint(vec, 10.0, 500.0, g_Beam, g_Halo, 0, 15, 0.5, 5.0, 0.0, BeaconColor2, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 10.0, 500.0, g_Beam, g_Halo, 0, 10, 0.6, 12.0, 0.0, BeaconColor, 10, 0);
		TE_SendToAll();
	}
	
	if (g_BlipSound[0])
	{
		GetClientEyePosition(client, vec);
		EmitAmbientSound(g_BlipSound, vec, client, SNDLEVEL_RAIDSIREN);
	}
	return Plugin_Continue;
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
} 