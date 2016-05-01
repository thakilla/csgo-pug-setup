#include <cstrike>
#include <sourcemod>
#include <socket>
#include "include/pugsetup.inc"
#include "pugsetup/generic.sp"

#pragma semicolon 1
//#pragma newdecls required

#define TEAMSPEAK_ALIAS_FILE "configs/pugsetup/teamspeak_aliases.cfg"

char alias[29];

public Plugin myinfo = {
    name = "CS:GO PugSetup: create relation between steamid and teamspeak user",
    author = "ThaKilla",
    description = "Connect STEAMID to TS User and move them to seperate channels during match.",
    version = PLUGIN_VERSION,
    url = "https://github.com/thakilla/csgo-pug-setup"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_ts", Command_TS, "Show/Sets player's teamspeak relation.");
    PugSetup_AddChatAlias(".ts", "sm_ts");
}

public void PugSetup_OnReadyToStart() {
	moveAllPlayers();
}

public void PugSetup_OnMatchOver() {
	moveAllPlayers(true);
}

public Action Command_TS(int client, int args)
{
    if(client == 0) {
        PugSetup_Message(client, "You can't use this command on the console.");
        return Plugin_Handled;
    }

    char steamID[32];
    GetClientAuthId(client, AuthId_Engine, steamID, sizeof(steamID));

    char arg1[29];
    if (args >= 1 && GetCmdArg(1, arg1, sizeof(arg1))) {

    	if(StrEqual(arg1, "clear")) {
    		bool cleared = clearAliasForSteamID(steamID);
    		if(cleared) {
    			PugSetup_Message(client, "Your TeamSpeak realtion was successfully removed.");
    		}
    		return Plugin_Handled;
    	}

        if(StrEqual(arg1, "move")) {
            bool moved = moveAllPlayers();
            if(moved) {
                PugSetup_Message(client, "All players with TeamSpeak relation were moved.");
            }
            return Plugin_Handled;
    	}

        bool success = setAliasForSteamID(steamID, arg1);
        if(success) {
			PugSetup_Message(client, "Your UID = \"%s\" was successfully saved.", arg1);
        } else {
        	PugSetup_Message(client, "Couldn't save your UID, try again.");
        }
    } else {
    	alias = getAliasForSteamID(steamID);
        if(strlen(alias)) {
            PugSetup_Message(client, "You have already an TS relation set. Your UID = \"%s\"", alias);
            PugSetup_Message(client, "You can reset your relation with \".ts <TeamSpeak UniqueID>\"");
        } else {
            PugSetup_Message(client, "Usage: .ts <TeamSpeak UniqueID> to save your teamspeak relation.");
        }
    }

    return Plugin_Handled;
}

char getAliasForSteamID(const char[] steamid)
{
    char aliasFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, aliasFile, sizeof(aliasFile), TEAMSPEAK_ALIAS_FILE);

    KeyValues kv = new KeyValues("TeamspeakAliases");
    kv.ImportFromFile(aliasFile);
    kv.JumpToKey(steamid);

    char tsAlias[29];
    kv.GetString("uid", tsAlias, sizeof(tsAlias));
    delete kv;

    return tsAlias;
}

bool setAliasForSteamID(const char[] steamID, const char[] uid)
{
    char aliasFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, aliasFile, sizeof(aliasFile), TEAMSPEAK_ALIAS_FILE);

    KeyValues kv = new KeyValues("TeamspeakAliases");
    kv.ImportFromFile(aliasFile);
    kv.JumpToKey(steamID, true);
    kv.SetString("uid", uid);
    kv.Rewind();
    bool success = kv.ExportToFile(aliasFile);
    delete kv;

    return success;
}

bool clearAliasForSteamID(const char[] steamID)
{
    char aliasFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, aliasFile, sizeof(aliasFile), TEAMSPEAK_ALIAS_FILE);

    KeyValues kv = new KeyValues("TeamspeakAliases");
    kv.ImportFromFile(aliasFile);
    if (!kv.JumpToKey(steamID)) {
        return false;
    }
    kv.DeleteThis();
    kv.Rewind();
    bool success = kv.ExportToFile(aliasFile);
    delete kv;

    return success;
}

bool moveAllPlayers(bool:moveBack = false)
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsPlayer(i)) {
			int team = GetClientTeam(i);

			if (team == CS_TEAM_CT || team == CS_TEAM_T)
			{
				DataPack pack = new DataPack();

				decl String:channel[4];
				if(team == CS_TEAM_CT) {
					channel = "363";
				}
				if(team == CS_TEAM_T) {
					channel = "364";
				}
				if(moveBack) {
					channel = "365";
				}

				WritePackString(pack, channel);

				char steamID[32];
				GetClientAuthId(i, AuthId_Engine, steamID, sizeof(steamID));

				char tsUID[29];
				tsUID = getAliasForSteamID(steamID);

				WritePackString(pack, tsUID);

				new Handle:socket=SocketCreate(SOCKET_TCP, OnSocketError);
				SocketSetArg(socket, pack);
				SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "game.ifaultier.de", 80);
			}
		}
	}

	return true;
}

public OnSocketConnected(Handle:socket, any:pack)
{
	// socket is connected, send the http request
	ResetPack(pack);

	decl String:channel[4];
	ReadPackString(pack, channel, sizeof(channel));

	char tsUID[29];
	ReadPackString(pack, tsUID, sizeof(tsUID));

	decl String:urlStr[100];
	Format(urlStr, sizeof(urlStr), "switchChannel.php?u[]=%s&c=%s&key=%s", tsUID, channel, "kommetrinn");

	decl String:requestStr[1000];
	Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", urlStr, "game.ifaultier.de");

	SocketSend(socket, requestStr);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile) {
	// receive another chunk and write it to <modfolder>/dl.htm
	// we could strip the http response header here, but for example's sake we'll leave it in
}

public OnSocketDisconnected(Handle:socket, any:hFile) {
	// Connection: close advises the webserver to close the connection when the transfer is finished
	// we're done here
	CloseHandle(socket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile) {
	// a socket error occured

	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}