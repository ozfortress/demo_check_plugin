/**
 * demorecorder_check.sp
 *
 * Plugin to check if a player is recording a demo.
 */

/**
 * DEV NOTES
 *
 *  https://sourcemod.dev/#/convars/function.QueryClientConVar
 *
 * ds_enable 0/1/2 - if set to one of these, boot with config on, warn with config off
 * ds_enable 3 - if this is on, a ok
 * ds_autodelete 1 instant boot with config on, prompt player to turn it off
 */

#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define DEMOCHECK_TAG "{lime}[{red}Demo Check{lime}]{white} "

public Plugin:myinfo =
{
    name = "Demo Check",
    author = "Shigbeard",
    description = "Checks if a player is recording a demo",
    version = "1.0.1",
    url = "https://ozfortress.com/"
};

ConVar g_bDemoCheckEnabled;
ConVar g_bDemoCheckOnReadyUp; // Requires SoapDM

public void OnPluginStart()
{
    LoadTranslations("demo_check.phrases");

    g_bDemoCheckEnabled = CreateConVar("sm_democheck_enabled", "1", "Enable demo check", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_bDemoCheckOnReadyUp = CreateConVar("sm_democheck_onreadyup", "0", "Check if all players are recording a demo when both teams ready up - requires SoapDM", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    RegServerCmd("sm_democheck", Cmd_DemoCheck_Console, "Check if a player is recording a demo", 0);
    RegServerCmd("sm_democheck_enable", Cmd_DemoCheckEnable_Console, "Enable demo check", 0);
    RegServerCmd("sm_democheck_disable", Cmd_DemoCheckDisable_Console, "Disable demo check", 0);
    RegServerCmd("sm_democheck_all", Cmd_DemoCheckAll_Console, "Check if all players are recording a demo", 0);

    HookConVarChange(g_bDemoCheckEnabled, OnDemoCheckEnabledChange)

}

public void SOAP_StopDeathMatching()
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
        CPrintToChatAll(DEMOCHECK_TAG ... "%t", "enabled");
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
        CPrintToChatAll(DEMOCHECK_TAG ... "%t", "disabled");
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
        CPrintToChat(client, DEMOCHECK_TAG ... "%t", "ds_enabled 3");
    }
    else if(StrEqual(value, "0"))
    {
        PrintToConsole(client, "[Demo Check] %t", "ds_enabled 1 or 2");
        PrintToConsole(client, "[Demo Check] %t", "docs");
        char sName[64];
        GetClientName(client, sName, sizeof(sName));
        CreateTimer(2.0, Timer_KickClient, client);
        CPrintToChatAll(DEMOCHECK_TAG ... "%t", "kicked_announce", sName);
    }
    else
    {
        PrintToConsole(client, "[Demo Check] %t", "ds_enabled 0");
        PrintToConsole(client, "[Demo Check] %t", "docs");
        char sName[64];
        GetClientName(client, sName, sizeof(sName));
        CreateTimer(2.0, Timer_KickClient, client);
        CPrintToChatAll(DEMOCHECK_TAG ... "%t", "kicked_announce", sName);
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
        CreateTimer(2.0, Timer_KickClient, client);
        CPrintToChatAll(DEMOCHECK_TAG ... "%t", "kicked_announce", sName);
    }
    else
    {
        CPrintToChat(client, DEMOCHECK_TAG ... "%t", "ds_autodelete 0");
    }
}

public Action Timer_KickClient(Handle timer, int client)
{
    KickClient(client, "[Demo Check] %t", "kicked");
    return Plugin_Stop;
}
