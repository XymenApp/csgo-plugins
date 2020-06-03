#include <sourcemod>
#include <sdktools>
#include <PTaH>
#include<multicolors>

#pragma newdecls required
#pragma semicolon 1

#define AUTHOR "-=XymenGaming=-"
#define PLUGIN_VERSION "1.0.0"

ConVar gPluginEnabled = null;
ConVar gAllowRootAccess = null;
ConVar gContact = null;

char gLogs[PLATFORM_MAX_PATH + 1];

public Plugin myinfo =
{
    name = "SM Commands Blocker",
    description = "Block sourcemod commands",
    author = AUTHOR,
    version = PLUGIN_VERSION,
    url = "https://github.com/XymenApp/csgo-plugin-block-sm"
};

public void OnPluginStart(){
    CreateConVar("sm_blocker_version", PLUGIN_VERSION, "Show the version of the plugin", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    gPluginEnabled = CreateConVar("sm_blocker_enabled", "1", "Enables the plugin");
    gAllowRootAccess = CreateConVar("sm_blocker_root_access", "1", "Enable the root admin to use any sm command");
    gContact = CreateConVar("sm_blocker_contact", "gaming.xymenapps.com", "Contact address for plugins");

    LoadTranslations("sm.blocker.phrases");
    
    PTaH(PTaH_ConsolePrintPre, Hook, myConsolePrintPre);
    PTaH(PTaH_ExecuteStringCommandPre, Hook, myExecuteStringCommandPre);

    PrintToServer("Plugin made with love by %s", AUTHOR);
    AutoExecConfig(true, "sm_blocker", "sourcemod");
}


public Action myExecuteStringCommandPre(int client, char sCommandString[512]){
    if(gPluginEnabled.IntValue == 0)
        return Plugin_Continue;

    if (IsClientValid(client)){
        char stringToExecute[512];
        strcopy(stringToExecute, sizeof(stringToExecute), sCommandString);
        TrimString(stringToExecute);
        if (gAllowRootAccess.IntValue == 1 && CheckCommandAccess(client, "sm_blocker_root", ADMFLAG_ROOT, true)){
                PrintToServer("[%s] Root User Detected", AUTHOR);
                return Plugin_Continue;
            }
        if(StrContains(stringToExecute, "sm ") == 0 || StrEqual(stringToExecute, "sm", false)){
            SMPluginsCommandDetected(client);
            return Plugin_Handled;
        }else if(StrContains(stringToExecute, "meta ") == 0 || StrEqual(stringToExecute, "meta", false)){
            SMPluginsCommandDetected(client);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue; 
}

public Action myConsolePrintPre(int client, char message[1024]){
    if(gPluginEnabled.IntValue == 0)
        return Plugin_Continue;

    char consoleOutput[1024];
    strcopy(consoleOutput, sizeof(consoleOutput), message);
    TrimString(consoleOutput);
    
    if (IsClientConnected(client)){
        if (gAllowRootAccess.IntValue == 1 && CheckCommandAccess(client, "sm_blocker_root", ADMFLAG_ROOT, true)){
            return Plugin_Continue;
        }
        if(consoleOutput[1] == '"' && (StrContains(consoleOutput, "\" (") != -1 || (StrContains(consoleOutput, ".smx\" ") != -1))){
            return Plugin_Handled;
        }
        else if(StrContains(consoleOutput, "To see more, type \"sm plugins", false) != -1 || StrContains(consoleOutput, "To see more, type \"sm exts", false) != -1){
            return Plugin_Handled;
        }        
    }
    return Plugin_Continue;
}

public void SMPluginsCommandDetected(int client){
    PrintToServer("\"%L\" tried to use sm commands", client);
    char date[20];
    FormatTime(date, sizeof(date), "%y-%m-%d");
    BuildPath(Path_SM, gLogs, sizeof(gLogs), "logs/sm-blocker-%s.log", date);

    char contact[100];
    gContact.GetString(contact,  sizeof(contact));
    
    CPrintToChat(client, "%T", "UsedSMCommand", client, AUTHOR, contact);
    CReplyToCommand(client, "%T", "UsedSMCommand", client, AUTHOR, contact);
    LogToFile(gLogs, "\"%L\" tried to use sm commands", client);
}

bool IsClientValid(int client){
    if (client > 0 && client <= MaxClients){
        if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client)){
            return true;
        }
    }
    return false;
}
