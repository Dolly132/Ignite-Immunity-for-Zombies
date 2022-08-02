#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multicolors>

#define PLUGIN_PREFIX "{green}[SM] {default}"

float g_fEndTime[MAXPLAYERS + 1] = {0.0, ...};
float g_fMaxUses[MAXPLAYERS + 1] = {0.0, ...};

bool g_bIsClientProtected[MAXPLAYERS + 1];

int g_iClientUses[MAXPLAYERS + 1] = {0, ...};

ConVar g_cvImmunityTime;
ConVar g_cvMaxUses;

public Plugin myinfo = 
{
	name = "IgniteImmunity",
	author = "Dolly",
	description = "Gives Zombies Ignite Immunity",
	version = "1.0",
	url = "https://nide.gg"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	
	g_cvImmunityTime = CreateConVar("sm_ignite_immunity_time", "5", "The immunity time that will be given to terrorists of being ignited");
	g_cvMaxUses = CreateConVar("sm_ignite_immunity_maxuses", "3", "The MAX TIMES FOR ZMS TO USE IMMUNITY");
	
	AutoExecConfig();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			ResetValues(i);
	}
}

public void OnClientPutInServer(int client)
{
	ResetValues(client);
}

public void OnClientDisconnect(int client)
{
	ResetValues(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impluse)
{
	if(g_fEndTime[client] != 0.0 && GetGameTime() >= g_fEndTime[client])
	{
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
		g_bIsClientProtected[client] = false;
		g_fEndTime[client] = 0.0;
	}
	
	if(g_bIsClientProtected[client])
	{
		if(g_fEndTime[client] != 0.0 && GetGameTime() < g_fEndTime[client])
		{
			int flags = GetEntityFlags(client);
			if(flags & FL_ONFIRE)
			{
				SetEntityFlags(client, flags & ~FL_ONFIRE);
				int effect = GetEntPropEnt(client, Prop_Send, "m_hEffectEntity");
				if(IsValidEdict(effect))
				{
					char sEffectClassName[20];
					GetEntityClassname(effect, sEffectClassName, 20);
					
					if(StrEqual(sEffectClassName, "entityflame", false))
						RemoveEntity(effect);
				}
			}
		}
	}
	
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && !g_bIsClientProtected[client])
	{
		if(buttons & IN_RELOAD)
		{
			if(g_iClientUses[client] < g_cvMaxUses.IntValue)
			{
				g_bIsClientProtected[client] = true;
				SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
				g_fEndTime[client] = GetGameTime() + g_cvImmunityTime.IntValue;
				SetEntProp(client, Prop_Send, "m_iProgressBarDuration", g_cvImmunityTime.IntValue);
				g_iClientUses[client]++;
				g_fMaxUses[client] = 0.0;
				CPrintToChat(client, "%sYou have used {green}%d{default}/{green}%d {default}times of {green}Ignite Immunity{default}.", PLUGIN_PREFIX, g_iClientUses[client], g_cvMaxUses.IntValue);
			}
			else if(g_iClientUses[client] >= g_cvMaxUses.IntValue)
			{
				if(g_fMaxUses[client] < GetGameTime())
				{
					g_fMaxUses[client] = GetGameTime() + 3;
					CPrintToChat(client, "%sYou have used the {green}maximum{default} number of times of {green}Ignite Immunity{default}.", PLUGIN_PREFIX);
				}
			}
		}
	} 
	
	return Plugin_Continue;
}

void ResetValues(int client)
{
	g_bIsClientProtected[client] = false;
	g_fEndTime[client] = 0.0;
	g_iClientUses[client] = 0;
	g_fMaxUses[client] = 0.0;
}		
