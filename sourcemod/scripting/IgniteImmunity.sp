#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multicolors>

#define PLUGIN_PREFIX "{green}[SM] {default}"

Handle g_hClientTimer[MAXPLAYERS + 1] = {null, ...};

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
	version = "2.0",
	url = "https://nide.gg"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_igniteimmu", Command_Ignite);
	
	HookEvent("round_start", Event_RoundStart);
	
	g_cvImmunityTime = CreateConVar("sm_ignite_immunity_time", "5", "The immunity time that will be given to terrorists of being ignited");
	g_cvMaxUses = CreateConVar("sm_ignite_immunity_maxuses", "3", "The MAX TIMES FOR ZMS TO USE IMMUNITY");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
	
	AutoExecConfig(true);
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
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	ResetValues(client);
}

public void OnClientDisconnect(int client)
{
	ResetValues(client);
	
	delete g_hClientTimer[client];
}

public Action Command_Ignite(int client, int args)
{
	if(!client)
		return Plugin_Handled;
	
	if(!IsPlayerAlive(client) || GetClientTeam(client) == 3)
	{
		CReplyToCommand(client, "%sYou have to be an alive {green}Zombie{default} to use the command.", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	if(g_iClientUses[client] < g_cvMaxUses.IntValue)
	{
		GiveImmunity(client);
		return Plugin_Handled;
	}				
	else if(g_iClientUses[client] >= g_cvMaxUses.IntValue)
	{
		CReplyToCommand(client, "%sYou have used the {green}maximum{default} number of times of {green}Ignite Immunity{default}.", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!g_bIsClientProtected[victim])
		return Plugin_Continue;
	
	RequestFrame(DeleteIgnite, GetClientUserId(victim));
	
	return Plugin_Continue;
}

void DeleteIgnite(int userid)
{
	int victim = GetClientOfUserId(userid);
	if(!IsClientInGame(victim))
		return;
	
	int flags = GetEntityFlags(victim);
	if(flags & FL_ONFIRE)
	{
		SetEntityFlags(victim, flags & ~FL_ONFIRE);
		int effect = GetEntPropEnt(victim, Prop_Send, "m_hEffectEntity");
		if(IsValidEdict(effect))
		{
			char sEffectClassName[20];
			GetEntityClassname(effect, sEffectClassName, sizeof(sEffectClassName));
			
			if(StrEqual(sEffectClassName, "entityflame", false))
				RemoveEntity(effect);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impluse)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return Plugin_Continue;
		
	if(!g_bIsClientProtected[client])
	{
		if(buttons & IN_RELOAD)
		{
			if(g_iClientUses[client] < g_cvMaxUses.IntValue)
				GiveImmunity(client);
				
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

public Action TimerHandler_Immunity(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsClientInGame(client))
	{
		g_hClientTimer[client] = null;
		return Plugin_Stop;
	}
	
	g_hClientTimer[client] = null;
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
	g_bIsClientProtected[client] = false;
	g_fEndTime[client] = 0.0;
	return Plugin_Continue;
}

void GiveImmunity(int client)
{
	g_bIsClientProtected[client] = true;
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	g_fEndTime[client] = GetGameTime() + g_cvImmunityTime.IntValue;
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", g_cvImmunityTime.IntValue);
	g_iClientUses[client]++;
	g_fMaxUses[client] = 0.0;
	g_hClientTimer[client] = CreateTimer(g_cvImmunityTime.FloatValue, TimerHandler_Immunity, GetClientUserId(client));
	CPrintToChat(client, "%sYou have used {green}%d{default}/{green}%d {default}times of {green}Ignite Immunity{default}.", PLUGIN_PREFIX, g_iClientUses[client], g_cvMaxUses.IntValue);
}

void ResetValues(int client)
{
	g_bIsClientProtected[client] = false;
	g_fEndTime[client] = 0.0;
	g_iClientUses[client] = 0;
	g_fMaxUses[client] = 0.0;
}
