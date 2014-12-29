/**
 * Parses the pugsetup config file, populating the
 * gametype / map files / config files
 * arrays that specify options for each game type.
 */
public void Config_MapStart() {
    g_GameTypes = new ArrayList(CONFIG_STRING_LENGTH);
    g_GameConfigFiles = new ArrayList(CONFIG_STRING_LENGTH);
    g_GameMapLists = new ArrayList();

    g_GameTypeHidden = new ArrayList();
    g_GameTypeTeamSize = new ArrayList();
    g_GameTypeMapTypes = new ArrayList();
    g_GameTypeTeamTypes = new ArrayList();

    char configFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, configFile, sizeof(configFile), "configs/pugsetup/gametypes.cfg");

    if (!FileExists(configFile)) {
        LogError("The pugsetup config file does not exist");
        LoadBackupConfig();
        GameTypeForward();
        return;
    }

    KeyValues kv = new KeyValues("GameTypes");
    kv.ImportFromFile(configFile);
    if (!kv.GotoFirstSubKey()) {
        LogError("The pugsetup config file was empty");
        delete kv;
        LoadBackupConfig();
        GameTypeForward();
        return;
    }

    char name[CONFIG_STRING_LENGTH];
    char config[CONFIG_STRING_LENGTH];
    char maplist[CONFIG_STRING_LENGTH];
    char teamTypeString[CONFIG_STRING_LENGTH];
    char mapTypeString[CONFIG_STRING_LENGTH];

    // setup any workshop cache information
    BuildPath(Path_SM, g_DataDir, sizeof(g_DataDir), "data/pugsetup");

    if (!DirExists(g_DataDir)) {
        CreateDirectory(g_DataDir, 511);
    }

    Format(g_CacheFile, sizeof(g_CacheFile), "%s/cache.cfg", g_DataDir);

    g_WorkshopCache = new KeyValues("Workshop");
    g_WorkshopCache.ImportFromFile(g_CacheFile);

    int gameTypeIndex = 0;
    do {
        kv.GetSectionName(name, sizeof(name));
        kv.GetString("config", config, sizeof(config), "gamemode_competitive.cfg");
        kv.GetString("maplist", maplist, sizeof(maplist));
        bool visible = !kv.GetNum("hidden", 0);
        int teamsize = kv.GetNum("teamsize", -1);

        kv.GetString("teamtype", teamTypeString, sizeof(teamTypeString), "unspecified");
        kv.GetString("maptype", mapTypeString, sizeof(mapTypeString), "unspecified");
        TeamType teamType = TeamTypeFromString(teamTypeString, TeamType_Unspecified, true, true);
        MapType mapType = MapTypeFromString(mapTypeString, MapType_Unspecified, true, true);

        // now we read the actual maps
        ArrayList maps = new ArrayList(PLATFORM_MAX_PATH);

        // first, the optional "maps" section in the config file
        // kv.SavePosition();
        if (kv.JumpToKey("maps")) {
            if (kv.GotoFirstSubKey(false)) {
                char map[PLATFORM_MAX_PATH];
                do {
                    kv.GetSectionName(map, sizeof(map));
                    PushArrayString(maps, map);
                } while (kv.GotoNextKey(false));
                kv.GoBack();
            }
            kv.GoBack();
        }

        // second, any maps in the maplist if it was given
        if (!StrEqual(maplist, ""))
            GetMapList(maplist, maps);

        // third, fetch workshop map info
        char collection[64];
        kv.GetString("collection", collection, sizeof(collection), "");
        if (!StrEqual(collection, "")) {
            UpdateWorkshopCache(collection, gameTypeIndex);
        }

        AddGameType(name, config, maps, visible, teamsize, teamType, mapType);
        gameTypeIndex++;

        delete maps;
    } while (KvGotoNextKey(kv));

    delete kv;

    GameTypeForward();
}

static void GameTypeForward() {
    Call_StartForward(g_OnGameTypesAdded);
    Call_Finish();
}

static void LoadBackupConfig() {
    LogError("Falling back to builtin backup config");
    ArrayList maps = new ArrayList(PLATFORM_MAX_PATH);
    AddBackupMaps(maps);
    AddGameType("Normal", "gamemode_competitive.cfg", maps);
    delete maps;
}

public void Config_MapEnd() {
    delete g_GameTypes;
    delete g_GameConfigFiles;
    CloseNestedArray(g_GameMapLists);

    delete g_GameTypeHidden;
    delete g_GameTypeTeamSize;
    delete g_GameTypeMapTypes;
    delete g_GameTypeTeamTypes;

    g_WorkshopCache.Rewind();
    g_WorkshopCache.ExportToFile(g_CacheFile);
    delete g_WorkshopCache;
}
