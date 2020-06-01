#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>

#define MAX_MVP_COUNT 1000

#define PHRASES_FILE "xyg.mvp.phrases"

#define CONFIG_FILE_PATH "configs/xyg_mvp.cfg"

#define PLUGIN_VERSION "1.0"

#define AUTHOR "-=XymenGaming=-"

#pragma newdecls required

int MVPCount;
char g_sMVPName[MAX_MVP_COUNT + 1][1024], g_sMVPFile[MAX_MVP_COUNT + 1][1024];
	
Handle cookie_mvp_name, cookie_mvp_vol;
	
int selectedMVPid[MAXPLAYERS + 1];
char selectedMVPName[MAXPLAYERS + 1][1024];
float selectedMVPvol[MAXPLAYERS + 1];

ConVar g_defaultVolCvar;
ConVar g_defaultMVPCvar;
ConVar g_tagCvar;

char myTAG[1024];

public Plugin myinfo =
{
	name = "[SM] Custom MVP Anthem",
	author = AUTHOR,
	version = PLUGIN_VERSION,
	description = "Custom Sounds at the end of the round for MVP",
	url = "https://github.com/XymenApp/csgo-plugin-custom-mvp"
};

public void OnPluginStart(){
	CreateConVar("sm_mvp_version", PLUGIN_VERSION, "Show the version of the plugin", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("sm_mvp", Command_MVP, "Select Your MVP Anthem");
	RegConsoleCmd("sm_mvpvol", Command_MVPVol, "Select Your MVP Volume");
	cookie_mvp_name = RegClientCookie("mvpname", "Player's MVP Anthem", CookieAccess_Private);
	cookie_mvp_vol = RegClientCookie("mvpvol", "Player MVP volume", CookieAccess_Private);
	g_defaultVolCvar = CreateConVar("sm_mvp_vol_default", "0.4", "Default volume for all music kit sounds");
	g_defaultMVPCvar = CreateConVar("sm_mvp_default", "1", "Default index of music kit for all players");
	g_tagCvar = CreateConVar("sm_mvp_tag", "-=XymenGaming=-", "Default index of music kit for all players");
	g_tagCvar.GetString(myTAG, sizeof(myTAG))
	
	HookEvent("round_mvp", Event_RoundMVP);
	LoadTranslations(PHRASES_FILE);
	
	for(int i = 1; i <= MaxClients; i++){ 
		if(IsValidClient(i) && !IsFakeClient(i) && !AreClientCookiesCached(i))	
			setClientMVP(i);
	}
	PrintToServer("Plugin made with love by %s", AUTHOR);
	AutoExecConfig(true, "xyg_mvp", "sourcemod");
}

public void OnClientPutInServer(int client){
	if (IsValidClient(client) && !IsFakeClient(client))	
		setClientMVP(client);
}

public void setClientMVP(int client){		
	char temp_cookie[1024];
	int defaultMVP = g_defaultMVPCvar.IntValue;
	
	//Get MVP Sound
	GetClientCookie(client, cookie_mvp_name, temp_cookie, sizeof(temp_cookie));
	if(!StrEqual(temp_cookie, "")){
		selectedMVPid[client] = findMVPid(temp_cookie);
		if(selectedMVPid[client] > 0)	
			strcopy(selectedMVPName[client], sizeof(selectedMVPName[]), temp_cookie);
		else{
			selectedMVPName[client] = "";
			SetClientCookie(client, cookie_mvp_name, "");
		}
	}
	else if(StrEqual(temp_cookie,"")){
		selectedMVPName[client] = g_sMVPName[defaultMVP];
		selectedMVPid[client] = defaultMVP;
	}
	
	//Get MVP Volume
	GetClientCookie(client, cookie_mvp_vol, temp_cookie, sizeof(temp_cookie));
	if(!StrEqual(temp_cookie, "")){
		selectedMVPvol[client] = StringToFloat(temp_cookie);
	}
	else if(StrEqual(temp_cookie,""))	
		selectedMVPvol[client] = g_defaultVolCvar.FloatValue;
}


public void OnConfigsExecuted(){
	loadAllMVP();
}

public Action Event_RoundMVP(Handle event, const char[] name, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(StrEqual(selectedMVPName[client], "") || selectedMVPid[client] == 0)	
		return;
	
	char sound[1024];
	int mvp = selectedMVPid[client];
	Format(sound, sizeof(sound), "*/%s", g_sMVPFile[mvp]);
	if (IsValidClient(client) && !IsFakeClient(client)){
		for(int i = 1; i <= MaxClients; i++){
			if (IsValidClient(i) && !IsFakeClient(i)){
				PrintHintText(i, "%T", "AnnounceMVP", client, client, g_sMVPName[mvp]);
				ClientCommand(i, "playgamesound Music.StopAllMusic");
				EmitSoundToClient(i, sound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, selectedMVPvol[i]);
			}	
		}
	}
}	

void loadAllMVP()
{
	char  configFile[1024];
	BuildPath(Path_SM, configFile, 1024, CONFIG_FILE_PATH);
	if(!FileExists(configFile))
		SetFailState("Cannot find config file \"%s\"!", configFile);
	KeyValues kv = CreateKeyValues("MVP");
	kv.ImportFromFile(configFile);
	MVPCount = 1;
	if(kv.GotoFirstSubKey()){
		char name[1024];
		char file[1024];
		do{
			kv.GetSectionName(name, sizeof(name));
			kv.GetString("file", file, sizeof(file));				
			strcopy(g_sMVPName[MVPCount], sizeof(g_sMVPName[]), name);
			strcopy(g_sMVPFile[MVPCount], sizeof(g_sMVPFile[]), file);
	
			char filepath[1024];
			Format(filepath, sizeof(filepath), "sound/%s", g_sMVPFile[MVPCount])
			AddFileToDownloadsTable(filepath);
			
			char soundpath[1024];
			Format(soundpath, sizeof(soundpath), "*/%s", g_sMVPFile[MVPCount]);
			FakePrecacheSound(soundpath);
			MVPCount++;
		}while (kv.GotoNextKey());
	}
	kv.Rewind();
	delete kv;
}

public Action Command_MVP(int client,int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		char name[1024], menutitle[1024], mvpmenu[1024], volmenu[1024];
		Menu settings_menu = new Menu(SettingsMenuHandler);
		
		if(StrEqual(selectedMVPName[client], ""))	
			Format(name, sizeof(name), "%T", "CurrentMVPIfNotSelected", client);
		else 
			Format(name, sizeof(name), selectedMVPName[client]);
		Format(menutitle, sizeof(menutitle), "%T", "MVPMainMenu", client, name, selectedMVPvol[client]);
		Format(mvpmenu, sizeof(mvpmenu), "%T", "SelectMVP", client);
		Format(volmenu, sizeof(volmenu), "%T", "SelectVol", client);
		
		settings_menu.SetTitle(menutitle);
		settings_menu.AddItem("setmvp", mvpmenu);
		settings_menu.AddItem("setvol", volmenu);
		settings_menu.Display(client, 0);
	}
	return Plugin_Handled;
}

public int SettingsMenuHandler(Menu menu, MenuAction action, int client, int param){
	if(action == MenuAction_Select)	{
		char select[1024];
		GetMenuItem(menu, param, select, sizeof(select));		
		if(StrEqual(select, "setmvp")){
			DisplayMVPMenu(client);
		}
		else if(StrEqual(select, "setvol")){
			DisplayVolMenu(client);
		}
	}
}

void DisplayMVPMenu(int client){
	if (IsValidClient(client) && !IsFakeClient(client)){
		char mvpmenutitle[1024], nomvp[1024], name[1024];
		Menu mvp_menu = new Menu(selectMVPMenu);	
		
		if(StrEqual(selectedMVPName[client], ""))
			Format(name, sizeof(name), "%T", "CurrentMVPIfNotSelected", client);
		else 
			Format(name, sizeof(name), selectedMVPName[client]);
		Format(mvpmenutitle, sizeof(mvpmenutitle), "%T", "MVPMenu", client, name);
		Format(nomvp, sizeof(nomvp), "%T", "CurrentMVPIfNotSelected", client);
		
		mvp_menu.SetTitle(mvpmenutitle);
		mvp_menu.AddItem("", nomvp);
		for(int i = 1; i < MVPCount; i++){
			mvp_menu.AddItem(g_sMVPName[i], g_sMVPName[i]);
		}
		mvp_menu.Display(client, 0);
	}
}

public int selectMVPMenu(Menu menu, MenuAction action, int client,int param){
	if(action == MenuAction_Select){
		char mvp_name[1024];
		GetMenuItem(menu, param, mvp_name, sizeof(mvp_name));
		
		if(StrEqual(mvp_name, "")){
			CPrintToChat(client, "%T", "NoMVPSelected", client, myTAG);
			selectedMVPid[client] = 0;
		}
		else{
			CPrintToChat(client, "%T", "MVPSelected", client, myTAG, mvp_name);
			selectedMVPid[client] = findMVPid(mvp_name);
		}
		strcopy(selectedMVPName[client], sizeof(selectedMVPName[]), mvp_name);
		SetClientCookie(client, cookie_mvp_name, mvp_name);
	}
}

void DisplayVolMenu(int client){
	if (IsValidClient(client) && !IsFakeClient(client)){
		Menu vol_menu = new Menu(selectVolMenu);
		char vol[1024], menutitle[1024], mute[1024];
		
		if(selectedMVPvol[client] > 0.00)	
			Format(vol, sizeof(vol), "%s", selectedMVPvol[client]);
		else 
			Format(vol, sizeof(vol), "%T", "Mute", client);	
		Format(menutitle, sizeof(menutitle), "%T", "VolMenu", client, vol);
		Format(mute, sizeof(mute), "%T", "Mute", client);
		
		vol_menu.SetTitle(menutitle);
		vol_menu.AddItem("0", mute);
		vol_menu.AddItem("0.2", "20%");
		vol_menu.AddItem("0.4", "40%");
		vol_menu.AddItem("0.6", "60%");
		vol_menu.AddItem("0.8", "80%");
		vol_menu.AddItem("1.0", "100%");
		vol_menu.Display(client, 0);
	}
}

public int selectVolMenu(Menu menu, MenuAction action, int client, int param){
	if(action == MenuAction_Select)	{
		char vol[1024];
		GetMenuItem(menu, param, vol, sizeof(vol));
		selectedMVPvol[client] = StringToFloat(vol);
		CPrintToChat(client, "%T", "VolSetDone", client, myTAG, selectedMVPvol[client]);
		SetClientCookie(client, cookie_mvp_vol, vol);
	}
}

public Action Command_MVPVol(int client,int args){
	if(IsValidClient(client)){
		char arg[20];
		float volume;
		if(args < 1){
			CPrintToChat(client, "%T", "VolSetFail", client, myTAG);
			return Plugin_Handled;
		}
		GetCmdArg(1, arg, sizeof(arg));
		volume = StringToFloat(arg);
		if (volume < 0.0 || volume > 1.0){
			CPrintToChat(client, "%T", "VolSetFail", client, myTAG);
			return Plugin_Handled;
		}
		selectedMVPvol[client] = StringToFloat(arg);
		CPrintToChat(client, "%T", "VolSetDone", client, myTAG, selectedMVPvol[client]);
		SetClientCookie(client, cookie_mvp_vol, arg);
	}
	return Plugin_Handled;
}

stock bool IsValidClient(int client){
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

stock void FakePrecacheSound(const char[] szPath){
	AddToStringTable(FindStringTable("soundprecache"), szPath);
}

int findMVPid(char [] name){
	int id = 0;
	for(int i = 1; i <= MVPCount; i++){
		if(StrEqual(g_sMVPName[i], name))
			id = i;
	}
	return id;
}