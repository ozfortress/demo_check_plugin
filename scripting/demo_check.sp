/**
 * demorecorder_check.sp
 *
 * Plugin to check if a player is recording a demo.
 */

#include <sourcemod>
#include <sdktools>
#include <morecolors>
#if !defined NO_DISCORD
#include <SteamWorks>
#include <discord>
#endif

#define DEMOCHECK_TAG "{lime}[{red}Demo Check{lime}]{white} "

public Plugin:myinfo =
{
    #if !defined NO_DISCORD
    name = "Demo Check",
    #else
    name = "Demo Check (No Discord)",
    #endif
    author = "Shigbeard",
    description = "Checks if a player is recording a demo",
    version = "1.1.3",
    url = "https://ozfortress.com/"
};

ConVar g_bDemoCheckEnabled;
ConVar g_bDemoCheckOnReadyUp; // Requires SoapDM
ConVar g_bDemoCheckWarn;
ConVar g_bDemoCheckAnnounce;
#if !defined NO_DISCORD
ConVar g_bDemoCheckAnnounceDiscord; // Requires Discord
ConVar g_HostName;
ConVar g_HostPort;
#endif
ConVar g_bDemoCheckAnnounceTextFile; // Dumps to a text file

public void OnPluginStart()
{
    LoadTranslations("demo_check.phrases");

    g_bDemoCheckEnabled = CreateConVar("sm_democheck_enabled", "1", "Enable demo check", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_bDemoCheckOnReadyUp = CreateConVar("sm_democheck_onreadyup", "0", "Check if all players are recording a demo when both teams ready up - requires SoapDM", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    g_bDemoCheckWarn = CreateConVar("sm_democheck_warn", "0", " Set the plugin into warning only mode.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_bDemoCheckAnnounce = CreateConVar("sm_democheck_announce", "1", "Announce passed demo checks to chat", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    #if !defined NO_DISCORD
        g_bDemoCheckAnnounceDiscord = CreateConVar("sm_democheck_announce_discord", "0", "Announce failed demo checks to discord", FCVAR_NOTIFY, true, 0.0, true, 1.0);
        g_HostName = FindConVar("hostname");
        g_HostPort = FindConVar("hostport");
    #endif
    g_bDemoCheckAnnounceTextFile = CreateConVar("sm_democheck_announce_textfile", "0", "Dump failed demo checks to a text file", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    AutoExecConfig(true, "democheck");

    RegServerCmd("sm_democheck", Cmd_DemoCheck_Console, "Check if a player is recording a demo", 0);
    RegServerCmd("sm_democheck_enable", Cmd_DemoCheckEnable_Console, "Enable demo check", 0);
    RegServerCmd("sm_democheck_disable", Cmd_DemoCheckDisable_Console, "Disable demo check", 0);
    RegServerCmd("sm_democheck_all", Cmd_DemoCheckAll_Console, "Check if all players are recording a demo", 0);

    HookConVarChange(g_bDemoCheckEnabled, OnDemoCheckEnabledChange)

    // Perform a check on all players when the plugin is loaded
    if (GetConVarBool(g_bDemoCheckEnabled))
    {
        PrintToChatAll(DEMOCHECK_TAG ... "%t", "plugin_start_check_all");
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                CheckDemoRecording(i);
            }
        }
    }
}

public void SOAP_StopDeathMatching()
// This forward is called by SoapDM_Tournament whenever both teams have readied up
// SoapDM uses it as an opportunity to execute a config file to unload a series of plugins
// We use it as an opportunity to check demo settings.
{
    if (GetConVarBool(g_bDemoCheckOnReadyUp))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                CheckDemoRecording(i);
            }
        }
    }
}

public void OnClientPutInServer(int client)
// Check a player once they've joined the game. We wait until they've fully connected.
{
    if (IsClientInGame(client))
    {
        if (GetConVarBool(g_bDemoCheckEnabled))
        {
            CheckDemoRecording(client);
        }
    }
}

public void OnDemoCheckEnabledChange(ConVar convar, const char[] oldValue, const char[] oldFloatValue)
{
    if (GetConVarBool(g_bDemoCheckEnabled))
    {
        if (GetConVarBool(g_bDemoCheckAnnounce))
        {
            CPrintToChatAll(DEMOCHECK_TAG ... "%t", "enabled");
        }
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                CheckDemoRecording(i);
            }
        }
    }
    else
    {
        if (GetConVarBool(g_bDemoCheckAnnounce))
        {
            CPrintToChatAll(DEMOCHECK_TAG ... "%t", "disabled");
        }
    }
}

public Action Cmd_DemoCheck_Console(int args)
{
    if (args < 1)
    {
        PrintToServer("[Demo Check] Usage: sm_democheck <userid>");
        return Plugin_Handled;
    }

    int target = GetCmdArgInt(1);
    if (target == 0)
    {
        PrintToServer("[Demo Check] Invalid target.");
        return Plugin_Handled;
    }

    if (!IsClientInGame(target))
    {
        PrintToServer("[Demo Check] Target is not in game.");
        return Plugin_Handled;
    }

    CheckDemoRecording(target);
    return Plugin_Handled;
}

public Action Cmd_DemoCheckEnable_Console(int args)
{
    SetConVarBool(g_bDemoCheckEnabled, true);
    PrintToServer("[Demo Check] Demo check enabled.");
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            CheckDemoRecording(i);
        }
    }
    return Plugin_Handled;
}

public Action Cmd_DemoCheckDisable_Console(int args)
{
    SetConVarBool(g_bDemoCheckEnabled, false);
    PrintToServer("[Demo Check] Demo check disabled.");
    return Plugin_Handled;
}

public Action Cmd_DemoCheckAll_Console(int args)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            CheckDemoRecording(i);
        }
    }
    return Plugin_Handled;
}


public Action CheckDemoRecording(int client)
{
    if (!IsClientInGame(client))
    {
        return Plugin_Stop;
    }
    if (!GetConVarBool(g_bDemoCheckEnabled))
    {
        return Plugin_Stop;
    }

    QueryClientConVar(client, "ds_enable", OnDSEnableCheck);
    QueryClientConVar(client, "ds_autodelete", OnDSAutoDeleteCheck);
    return Plugin_Continue;
}

public void OnDSEnableCheck(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] value)
{
    if (StrEqual(value, "3"))
    {
        if (GetConVarBool(g_bDemoCheckAnnounce))
        {
            CPrintToChat(client, DEMOCHECK_TAG ... "%t", "ds_enabled 3");
        }
    }
    else if(StrEqual(value, "0"))
    {
        PrintToConsole(client, "[Demo Check] %t", "ds_enabled 1 or 2");
        PrintToConsole(client, "[Demo Check] %t", "docs");
        char sName[64];
        GetClientName(client, sName, sizeof(sName));

        if (GetConVarBool(g_bDemoCheckWarn))
        {
            if (GetConVarBool(g_bDemoCheckAnnounce))
            {
                CPrintToChatAll(DEMOCHECK_TAG ... "%t", "kicked_announce_disabled", sName);
            }
        } else {
            CreateTimer(2.0, Timer_KickClient, client);
            CPrintToChatAll(DEMOCHECK_TAG ... "%t", "kicked_announce", sName);
        }
    }
    else
    {
        PrintToConsole(client, "[Demo Check] %t", "ds_enabled 0");
        PrintToConsole(client, "[Demo Check] %t", "docs");
        char sName[64];
        if (GetConVarBool(g_bDemoCheckWarn))
        {
            if (GetConVarBool(g_bDemoCheckAnnounce))
            {
                CPrintToChatAll(DEMOCHECK_TAG ... "%t", "kicked_announce_disabled", sName);
            }
        } else {
            CreateTimer(2.0, Timer_KickClient, client);
            CPrintToChatAll(DEMOCHECK_TAG ... "%t", "kicked_announce", sName);
        }
    }
}

public void OnDSAutoDeleteCheck(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] value)
{
    if (StrEqual(value, "1"))
    {
        PrintToConsole(client, "[Demo Check] %t", "ds_autodelete 1");
        PrintToConsole(client, "[Demo Check] %t", "docs");
        char sName[64];
        GetClientName(client, sName, sizeof(sName));
        if (GetConVarBool(g_bDemoCheckWarn))
        {
            if (GetConVarBool(g_bDemoCheckAnnounce))
            {
                CPrintToChatAll(DEMOCHECK_TAG ... "%t", "kicked_announce_disabled", sName);
            }
        } else {
            CreateTimer(2.0, Timer_KickClient, client);
            CPrintToChatAll(DEMOCHECK_TAG ... "%t", "kicked_announce", sName);
        }
    }
    else
    {
        if (GetConVarBool(g_bDemoCheckAnnounce))
        {
            CPrintToChat(client, DEMOCHECK_TAG ... "%t", "ds_autodelete 0");
        }
    }
}

public Action Timer_KickClient(Handle timer, int client)
{
    if (!IsClientInGame(client))
    {
        return Plugin_Stop;
    }
#if !defined NO_DISCORD
    if (GetConVarBool(g_bDemoCheckAnnounceDiscord))
    {
        char sName[64];
        char sSteamID[64];
        char sProfileURL[64];
        char sServerName[64];
        int iServerIP[4];
        int iServerPort;
        char sServerIP[64];
        GetClientName(client, sName, sizeof(sName));
        GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
        GetClientAuthId(client, AuthId_SteamID64, sProfileURL, sizeof(sProfileURL));
        Format(sProfileURL, sizeof(sProfileURL), "https://steamcommunity.com/profiles/%s", sProfileURL);
        char sMsg[512];
        if (g_HostName == INVALID_HANDLE)
        {
            g_HostName = FindConVar("hostname");
            if (g_HostName == INVALID_HANDLE)
            {
                Format(sServerName, sizeof(sServerName), "Unknown Server");
            }
        }
        if (g_HostPort == INVALID_HANDLE)
        {
            g_HostPort = FindConVar("hostport");
            if (g_HostPort == INVALID_HANDLE)
            {
                iServerPort = 27015;
            }
        }
        GetConVarString(g_HostName, sServerName, sizeof(sServerName));
        iServerPort = GetConVarInt(g_HostPort);
        SteamWorks_GetPublicIP(iServerIP);
        Format(sServerIP, sizeof(sServerIP), "%i.%i.%i.%i:%i", iServerIP[0], iServerIP[1], iServerIP[2], iServerIP[3], iServerPort);
        Format(sMsg, sizeof(sMsg), "[Demo Check] %t", "discord_democheck", sName, sSteamID, sProfileURL, sServerName, sServerIP);
        Discord_SendMessage("democheck", sMsg);
    }
#endif
    if (GetConVarBool(g_bDemoCheckAnnounceTextFile))
    {
        char sName[64];
        char sSteamID[64];
        char sProfileURL[64];
        char sDateTime[64];
        FormatTime(sDateTime, sizeof(sDateTime), "%Y-%m-%d %H:%M:%S");
        GetClientName(client, sName, sizeof(sName));
        GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
        GetClientAuthId(client, AuthId_SteamID64, sProfileURL, sizeof(sProfileURL));
        Format(sProfileURL, sizeof(sProfileURL), "https://steamcommunity.com/profiles/%s", sProfileURL);
        GetClientName(client, sName, sizeof(sName));
        char sMsg[512];
        Format(sMsg, sizeof(sMsg), "[Demo Check] %t", sName, sSteamID, sProfileURL, sDateTime);
        Handle file = OpenFile("democheck.log", "a");
        WriteFileLine(file, sMsg);
        CloseHandle(file);
    }
    KickClient(client, "[Demo Check] %t", "kicked");
    return Plugin_Stop;
}
