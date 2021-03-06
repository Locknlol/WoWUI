-- For Sync controls!
-- Author: Arkaan... aka "TheGenomeWhisperer"
-- Version 8.1.0R1.34
-- To hold all Sync Methods/Functions
GRMsync = {};

-- All Sync Globals
GRMsyncGlobals = {};

GRMsyncGlobals.channelName = "GUILD";
GRMsyncGlobals.DatabaseLoaded = false;
GRMsyncGlobals.RulesSet = false;
GRMsyncGlobals.LeadSyncProcessing = false;
GRMsyncGlobals.SyncOK = true;

-- Establishing leadership controls.
GRMsyncGlobals.IsLeaderRequested = false;
GRMsyncGlobals.LeadershipEstablished = false;
GRMsyncGlobals.IsElectedLeader = false;
GRMsyncGlobals.DesignatedLeader = "";
GRMsyncGlobals.ElectTimeOnlineTable = {};
GRMsyncGlobals.ElectionProcessing = false;
GRMsyncGlobals.AllLeadersNeutral = {};              -- Due to various privilege variation, this collects all leaders of all privilege ranks, then selects the leader at highest index, meaning lowest rank.
GRMsyncGlobals.InitializeTime = 0;                  -- to ensure no crossover talk and double requests for leadership establishment.

-- For players queing to by sync'd to share data!
-- If a player requests a leader sync, they are added to this que. This is so the leader can just add them to que
-- in the case that they may be syncing with another player already. Depending on the amount of data transferring, and the size of the guild, sync can take anywhere from 1-5 seconds
-- Based on server response time, per person. At least, initially. Live Sync updates happen near instantly.
GRMsyncGlobals.SyncQue = {};

-- Collected Tables of Data when received from the player
GRMsyncGlobals.JDReceivedTemp = {};
GRMsyncGlobals.PDReceivedTemp = {};
GRMsyncGlobals.BanReceivedTemp = {};
GRMsyncGlobals.AltReceivedTemp = {};
GRMsyncGlobals.AltRemReceivedTemp = {};
GRMsyncGlobals.MainReceivedTemp = {};
GRMsyncGlobals.CustomNoteReceivedTemp = {};
GRMsyncGlobals.BirthdayReceivedTemp = {};

-- Tables of the changes -- Leader will collect and store them here from all players before broadcasting the changes out, and then resetting them.
-- By compiling all changes first, and THEN checking, it saves an insane amount of resources rather than passing on every new piece received.
GRMsyncGlobals.JDChanges = {};
GRMsyncGlobals.PDChanges = {};
GRMsyncGlobals.BanChanges = {};
GRMsyncGlobals.AltAddChanges = {};
GRMsyncGlobals.AltRemoveChanges = {};
GRMsyncGlobals.AltMainChanges = {};
GRMsyncGlobals.CustomNoteChanges = {};
GRMsyncGlobals.BDayChanges = {};

-- SYNC START AND STOP CONTROLS
-- These are used to verify the expected number of packets of info arrived.
GRMsyncGlobals.ReceivingData = false;
GRMsyncGlobals.NumPlayerDataExpected = 0;

-- SYNC PROCEDURAL ORDERING CONTROLS PER SYNC
GRMsyncGlobals.CurrentSyncPlayer = "";
GRMsyncGlobals.CurrentSyncPlayerRankID = -1;
GRMsyncGlobals.CurrentSyncPlayerRankRequirement = -1;
GRMsyncGlobals.CurrentLeaderRankID = -1;
GRMsyncGlobals.firstSync = true;
GRMsyncGlobals.currentlySyncing = false;
GRMsyncGlobals.JDSyncComplete = false               
GRMsyncGlobals.SyncCount7 = 2;
GRMsyncGlobals.SyncCountBan = 2;              -- For the ban list sync.
GRMsyncGlobals.updateCount = 0;             -- Number of items updated in this sync.
-- For more efficient sync tracking
GRMsyncGlobals.SyncCountJD = 2;             -- For Join Date loop
GRMsyncGlobals.SyncCountPD = 2;             -- For Promo Date loop
GRMsyncGlobals.SyncCountAltAdd = 2;
GRMsyncGlobals.SyncCountAltRem = 2;
GRMsyncGlobals.SyncCountMain = 2;
GRMsyncGlobals.SyncCountCustom = 2;
GRMsyncGlobals.SyncCountBday = 2;
GRMsyncGlobals.BanCount = 2;
GRMsyncGlobals.BanListLongCount = 1;
GRMsyncGlobals.AltSendIsFinished = true;
GRMsyncGlobals.AltSendIsFinished2 = true;
-- error protection escapes
GRMsyncGlobals.SyncJDDelay = 0;
GRMsyncGlobals.SyncPDDelay = 0;
GRMsyncGlobals.SyncAltDelay = 0;
GRMsyncGlobals.SyncBanDelay = 0;
GRMsyncGlobals.SyncMainDelay = 0;
GRMsyncGlobals.SyncCustomDelay = 0;
GRMsyncGlobals.SyncBdayDelay = 0;
GRMsyncGlobals.AnnounceDelay = 0;

GRMsyncGlobals.TimeSinceLastSyncAction = 0; -- Evertime sync action occurs, timer is reset!
GRMsyncGlobals.ErrorCD = 10;                -- 10 seconds delay... if no action detected, sync failed and it will retrigger...
GRMsyncGlobals.numSyncAttempts = 0;         -- If sync fails, it will retry 1 time. This is the counter for attempts.
GRMsyncGlobals.dateSentComplete = false;    -- If player is not designated leader, this boolean is used to exit the error check loop.
GRMsyncGlobals.errorCheckEnabled = false;   -- To know when to reactivate the recursive loop or not.
GRMsyncGlobals.syncTempDelay = false;
GRMsyncGlobals.syncTempDelay2 = false;
GRMsyncGlobals.finalSyncDataCount = 1;
GRMsyncGlobals.finalSyncProgress = { false , false , false , false , false , false , false , false };        -- on each of the tables, if submitted fully
GRMsyncGlobals.numGuildRanks = GuildControlGetNumRanks() - 1;
GRMsyncGlobals.TempRoster = {};
GRMsyncGlobals.altTempRosterCleanedup = false;
GRMsyncGlobals.QuedErrorMessages = {};
GRMsyncGlobals.QuedErrorLive = false;
GRMsyncGlobals.tempListForLongReason = {};

-- Throttle, size, and byte controls
GRMsyncGlobals.sizeModifier = 8;        -- prefix size 8 bytes
GRMsyncGlobals.burstMessage = 1150620   -- Max number of bytes on initial message... it's actually 1.28Mb, but this gives a little head room.  -- 4530 full messages at 254 bytes length ( only possible within the first 15 seconds of logon )
GRMsyncGlobals.normalMessage = 4572     -- Normal message size, when it reaches the limit, it resets... -- 18 full messages at 254 bytes
GRMsyncGlobals.burstSent = false;
GRMsyncGlobals.ThrottleCap = GRMsyncGlobals.burstMessage;
GRMsyncGlobals.minFPS = 20;             -- if the player has low FPS the cut the throttlecap in half.
GRMsyncGlobals.throttleTimerUpdate = 0;
GRMsyncGlobals.timeAtLogin = time();
GRMsyncGlobals.SyncCount = 0;               -- 2 because index begins at 2 in the table, as index 1 is the guild name
GRMsyncGlobals.reloadControl = false;

-- Version check
GRMsyncGlobals.IncompatibleAddonUsers = {};
GRMsyncGlobals.CompatibleAddonUsers = {};

-- For sync control measures on player details, so leader can be determined on who has been online the longest. In other words, for the leadership selecting algorithm
-- when determining the tiers for syncing, it is ideal to select the leader who has been online the longest, as they most-likely have encountered the most current amount of information.
GRMsyncGlobals.firstMessageReceived = false;

-- Prefixes for tagging info as it is sent and picked up across server channel to other players in guild.
GRMsyncGlobals.listOfPrefixes = { 

    -- Main Sync Prefix...  rest will be text form
    "GRM_SYNC"
};

-- Chat/print properties.
local chat = DEFAULT_CHAT_FRAME;

-- SYNC THROTTLING SCRIPT HANDLERS
local InstanceManager = CreateFrame ( "frame" );
InstanceManager.OnUpdateDelay = 0;
InstanceManager.StatusFlip = 1;
InstanceManager.isFirstLoad = true;
InstanceManager:RegisterEvent ( "ZONE_CHANGED_NEW_AREA" );
InstanceManager:SetScript ( "OnEvent" , function()
    if not InstanceManager.isFirstLoad then
        GRMsyncGlobals.ThrottleCap = 500;     -- Throttle it down to about 1/10th the base speed for 5 seconds on entering a new zone, lest it can kick you
        C_Timer.After ( 5 , function()
            if InstanceManager.StatusFlip == 2 then
                GRMsyncGlobals.ThrottleCap = ( GRMsyncGlobals.normalMessage * 0.5 );
            else
                GRMsyncGlobals.ThrottleCap = GRMsyncGlobals.normalMessage;
            end
        end);
    else
        InstanceManager.isFirstLoad = false;        -- This is so it skips the first one upon logging in the game.
    end
end);

-- Keeps track of the framerate as the lower the framerate, as in, less than 20FPS, it can hamper the ability to send messages without disconnecting.
-- This throttles it down by 0.5 or it resets them.
InstanceManager:SetScript ( "OnUpdate" , function ( self , elapsed )
    self.OnUpdateDelay = self.OnUpdateDelay + elapsed;
    if self.OnUpdateDelay < 0.08 then
        return;
    end
    self.OnUpdateDelay = 0;
    local framerate = GetFramerate();
    if framerate < GRMsyncGlobals.minFPS and self.StatusFlip < 2 then
        self.StatusFlip = 2;
        GRMsyncGlobals.ThrottleCap = ( GRMsyncGlobals.ThrottleCap * 0.5 );
    elseif framerate >= GRMsyncGlobals.minFPS and self.StatusFlip > 1 then
        self.StatusFlip = 1;
        GRMsyncGlobals.ThrottleCap = ( GRMsyncGlobals.ThrottleCap * 2 );
    end
end);

-- Method:          GRMsync.MessageThrottleUpdate ( frame , float )
-- What it Does:    Changes the throttle cap to the much lower default cap after the player has entered the world for 15 seconds.
-- Purpose:         This is due to there being a 1.28Mb cap within the first 20 seconds that drops to a tiny 5Kb/s If the player can burst most of the info right away on logon, then sync can be quite fast. Otherwise it needs to be hard throttled to prevent player disconnect
GRMsync.MessageThrottleUpdate = function ( self , elapsed )
    if not GRMsyncGlobals.reloadControl then
        GRMsyncGlobals.throttleTimerUpdate = GRMsyncGlobals.throttleTimerUpdate + elapsed;
        if GRMsyncGlobals.throttleTimerUpdate > 0.8 then
            
            if ( time() - GRMsyncGlobals.timeAtLogin ) >= 15 then
                if InstanceManager.StatusFlip == 2 then
                    GRMsyncGlobals.ThrottleCap = GRMsyncGlobals.normalMessage * 0.5;
                else
                    GRMsyncGlobals.ThrottleCap = GRMsyncGlobals.normalMessage;
                end
                -- Unregister the OnUpdate here...
                self:SetScript ( "OnUpdate" , nil );
            elseif ( time() - GRMsyncGlobals.timeAtLogin ) <= 5 then
                if InstanceManager.StatusFlip == 2 then
                    GRMsyncGlobals.ThrottleCap = GRMsyncGlobals.normalMessage * 0.5;
                else
                    GRMsyncGlobals.ThrottleCap = GRMsyncGlobals.normalMessage;
                end
            else
                GRMsyncGlobals.ThrottleCap = GRMsyncGlobals.burstMessage;
            end
            
            GRMsyncGlobals.throttleTimerUpdate = 0;
        end
    else
        GRMsyncGlobals.ThrottleCap = GRMsyncGlobals.normalMessage * GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][24];
        if InstanceManager.StatusFlip == 2 then
            GRMsyncGlobals.ThrottleCap = GRMsyncGlobals.ThrottleCap * 0.5
        end
        -- Unregister the OnUpdate here...
        self:SetScript ( "OnUpdate" , nil );
    end
end

-- Method:          GRMsync.ResetDefaultValuesOnSyncReEnable()
-- What it Does:    Sets values to default, as if just logging back in.
-- Purpose:         For sync to properly work, default startup values need to be reset.
GRMsync.ResetDefaultValuesOnSyncReEnable = function()
    GRMsyncGlobals.DatabaseLoaded = false;
    GRMsyncGlobals.RulesSet = false;
    GRMsyncGlobals.IsLeaderRequested = false;
    GRMsyncGlobals.LeadershipEstablished = false;
    GRMsyncGlobals.IsElectedLeader = false;
    GRMsyncGlobals.DesignatedLeader = "";
    GRMsyncGlobals.ElectTimeOnlineTable = nil;
    GRMsyncGlobals.ElectTimeOnlineTable = {};
    GRMsyncGlobals.currentlySyncing = false;
    GRMsyncGlobals.ElectionProcessing = false;
    GRMsyncGlobals.SyncQue = {};
    GRMsyncGlobals.AllLeadersNeutral = nil;
    GRMsyncGlobals.AllLeadersNeutral = {};
    GRMsyncGlobals.InitializeTime = 0;
end

-- Resetting after broadcasting the changes.
GRMsync.ResetReportTables = function()
    GRMsyncGlobals.JDChanges = {};
    GRMsyncGlobals.PDChanges = {};
    GRMsyncGlobals.BanChanges = {};
    GRMsyncGlobals.AltAddChanges = {};
    GRMsyncGlobals.AltRemoveChanges = {};
    GRMsyncGlobals.AltMainChanges = {};
    GRMsyncGlobals.CustomNoteChanges = {};
    GRMsyncGlobals.BDayChanges = {};
end

-- In case of mid-cycling reset, this resets all the temp tables.
GRMsync.ResetTempTables = function()
    GRMsyncGlobals.JDReceivedTemp = {};
    GRMsyncGlobals.PDReceivedTemp = {};
    GRMsyncGlobals.BanReceivedTemp = {};
    GRMsyncGlobals.AltReceivedTemp = {};
    GRMsyncGlobals.AltRemReceivedTemp = {};
    GRMsyncGlobals.MainReceivedTemp = {};
    GRMsyncGlobals.CustomNoteReceivedTemp = {};
    GRMsyncGlobals.BirthdayReceivedTemp = {};
end

-- For use on doing a hard reset on sync. This is useful like if the addon user themselves changes rank and permissions change. Things would be wonky without force a hard reset of privileges.
GRMsync.TriggerFullReset = function()
    GRMsync.ResetDefaultValuesOnSyncReEnable();
    GRMsync.ResetReportTables();
    GRMsync.ResetTempTables();
    GRMsyncGlobals.SyncOK = true;
end

--------------------------
----- FUNCTIONS ----------
--------------------------

-- Method:          GRMsync.WaitTilDatabaseLoads()
-- What it Does:    Sets the player's guild ranking by index of rank
-- Purpose:         This is important for addon talk to not get info from ranks too low.
GRMsync.WaitTilDatabaseLoads = function()
    if IsInGuild() and ( GRM_G.saveGID == 0 or GRM_G.FID == 0 or GRM_G.setPID == 0 ) then
        C_Timer.After ( 1 , GRMsync.WaitTilDatabaseLoads );
        return
    else
        GRMsyncGlobals.DatabaseLoaded = true;
    end
    GRMsync.BuildSyncNetwork();
end

-- method:          GRMsync.SlimDate ( string )
-- What it Does:    Returns the string with the hour/min taken off the end.
-- Purpose:         For SYNCing, the only important piece of info on the timestamp is the date, and comparing it is the same. I don't want sync to trigger over and over
--                  Because the hour/min is off on the sync when that is unimportant info, at least in this context.
GRMsync.SlimDate  = function ( date )
    if date == "" then
        return date;
    else
        return string.sub ( date , 1 , string.find( date , " " , -8 ) -1 );
    end
end

-------------------------------------
----- ESTABLISH SYNC LEADERSHIP -----
-----        BY ELECTION        -----
-------------------------------------

-- Method:          GRMsync.InquireLeader()
-- What it Does:    On logon, or activation of sync alg, it requests in the guild channel if a leader is online.
-- Purpose:         Step 1 of sync algorithm in determining leader.
GRMsync.InquireLeader = function()
    GRMsyncGlobals.IsLeaderRequested = true;
    if GRMsyncGlobals.SyncOK then
        GRMsync.SendMessage ( "GRM_SYNC" , GRM_G.PatchDayString .. "?GRM_WHOISLEADER?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. "" , GRMsyncGlobals.channelName );
    end

    -- Check for number of leaders after 3 sec.
    C_Timer.After ( 1 , function()
        if #GRMsyncGlobals.AllLeadersNeutral > 0 then
            if #GRMsyncGlobals.AllLeadersNeutral == 1 then
                GRMsync.SetLeader ( GRMsyncGlobals.AllLeadersNeutral[1] );
            else
                -- Determine the rank now...
                local highestIndex = GRM.GetGuildMemberRankID ( GRMsyncGlobals.AllLeadersNeutral[1] );
                local index = 1;
                local newIndex;
                -- Going to set the sync leader to be the lowest rank'd (highest index).
                -- The reason this is necessary is because it will prevent you from syncing with higher rank officers that might restrict sync
                -- with lower ranks, thus you will not sync with lower rank, then sync with higher rank, bypassing rank restrictions.
                -- You choose to sync with lower ranks, it will default to only sync with lower ranks.
                for i = 2 , #GRMsyncGlobals.AllLeadersNeutral do
                    newIndex = GRM.GetGuildMemberRankID ( GRMsyncGlobals.AllLeadersNeutral[1] );
                    if newIndex > highestIndex then
                        highestIndex = newIndex;
                        index = i;
                    end
                end

                -- Ok, let's set the new leader!
                GRMsync.SetLeader ( GRMsyncGlobals.AllLeadersNeutral[index] );
            end
        end
    end);
end

-- Method:          GRMsync.InquireLeaderRespond ( string )
-- What it Does:    The new leader will respond out "I AM LEADER" and everyone set him as leader. No need to set as leader as it would have already been done at this point.
-- Purpose:         Sync leadership controls.
GRMsync.InquireLeaderRespond = function ()
    GRMsyncGlobals.IsLeaderRequested = true;
    GRMsyncGlobals.LeadershipEstablished = true;
    GRMsyncGlobals.ElectionProcessing = false;
    if GRMsyncGlobals.SyncOK then
        GRMsync.SendMessage ( "GRM_SYNC" , GRM_G.PatchDayString .. "?GRM_IAMLEADER?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. "" , GRMsyncGlobals.channelName );
    end
    if not GRMsyncGlobals.reloadControl then
        C_Timer.After ( 1 , GRMsync.InitiateDataSync );
    else
        GRMsyncGlobals.reloadControl = false;
    end
end

-- Method:          GRMsync.ReviewElectResponses ()
-- What it Does:    Reviews timestamps of all online people with addon, and if there is no leader, it elects a new leader.
-- Purpose:         Leadership needs to be established to ensure clean syncing.
GRMsync.ReviewElectResponses = function()
    if #GRMsyncGlobals.ElectTimeOnlineTable > 1 then
        local highestName = GRM_G.addonPlayerName;
        local highestTime = GRMsyncGlobals.timeAtLogin;
        local time = time();

        -- Let's determine who has been online the longest.
        for i = 1 , #GRMsyncGlobals.ElectTimeOnlineTable do
            if ( time - GRMsyncGlobals.ElectTimeOnlineTable[i][1] ) > ( time - highestTime ) then
                highestTime = GRMsyncGlobals.ElectTimeOnlineTable[i][1];
                highestName = GRMsyncGlobals.ElectTimeOnlineTable[i][2];
            end
        end

        -- Send Message out
        if GRMsyncGlobals.SyncOK then
            GRMsync.SendMessage ( "GRM_SYNC" , GRM_G.PatchDayString .. "?GRM_NEWLEADER?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. highestName , GRMsyncGlobals.channelName );
        end
        -- Establishing leader.
        GRMsync.SetLeader ( highestName );
        

    elseif #GRMsyncGlobals.ElectTimeOnlineTable == 1 then
        -- One result will be established as leader. No need to compare.
        -- Identifying new leader!
        if GRMsyncGlobals.SyncOK then
            GRMsync.SendMessage ( "GRM_SYNC" , GRM_G.PatchDayString .. "?GRM_NEWLEADER?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. GRMsyncGlobals.ElectTimeOnlineTable[1][2] , GRMsyncGlobals.channelName );
        end
        -- Sending message out.
        GRMsync.SetLeader ( GRMsyncGlobals.ElectTimeOnlineTable[1][2] );
        
    else
        -- Abort sync since it was only temporary, and there is no one to sync with.
        if GRM_G.TemporarySync then
            GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][14] = false;
            GRM_G.TemporarySync = false;
            GRMsync.MessageTracking:UnregisterAllEvents()
            GRMsync.ResetDefaultValuesOnSyncReEnable();         -- Reset values to default, so that it resyncs if player re-enables.
            GRM_RosterSyncCheckButton:SetChecked ( false );
            chat:AddMessage ( GRM.L ( "GRM:" ) .. " " .. GRM.L ( "No Players Currently Online to Sync With. Re-Disabling Sync..." ) , 1.0 , 0.84 , 0 );
        else
            -- ZERO RESPONSES! No one else online! -- No need to data sync and go further!
            GRMsyncGlobals.DesignatedLeader = GRM_G.addonPlayerName;
            GRMsyncGlobals.IsElectedLeader = true;
            
            -- if no leader was found, and it is just me, do a random check again within the next 45-90 seconds.
            GRMsyncGlobals.LeadSyncProcessing = true;
            GRMsyncGlobals.IsLeaderRequested = false;
            C_Timer.After ( math.random ( 10 , 45 ) , GRMsync.EstablishLeader );
        end
    end
    
    -- RESET TABLE!
    GRMsyncGlobals.ElectionProcessing = false;
    GRMsyncGlobals.ElectTimeOnlineTable = nil;
    GRMsyncGlobals.ElectTimeOnlineTable = {};

end


-- Method:          GRMsync.RequestElection()
-- What it Does:    To person who just logged in or reactivated syncing, it sends out a request to elect a leader if no leader identified.
-- Purpose:         Need to get time responses from all players to determine who has been online the longest, which will likely have the best data.
GRMsync.RequestElection = function()
    GRMsyncGlobals.ElectionProcessing = true;
    if GRMsyncGlobals.SyncOK then
        GRMsync.SendMessage ( "GRM_SYNC" , GRM_G.PatchDayString .. "?GRM_ELECT?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. "" , GRMsyncGlobals.channelName );
    end
    -- Let's give it a time delay to receive responses. 3 seconds.
    C_Timer.After ( 1.5 , GRMsync.ReviewElectResponses );
end


-- Method:          GRMsync.SendTimeForElection()
-- What it Does:    Sends the time logged in or addon sync was enabled
-- Purpose:         For voting, to determine who was online the longest.
GRMsync.SendTimeForElection = function()
    if not GRMsyncGlobals.ElectionProcessing then
        if GRMsyncGlobals.SyncOK then
            GRMsync.SendMessage ( "GRM_SYNC" , GRM_G.PatchDayString .. "?GRM_TIMEONLINE?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. GRM_G.addonPlayerName .. "?" .. tostring ( GRMsyncGlobals.timeAtLogin ) , GRMsyncGlobals.channelName );
        end
    end
end

-- Method:          GRMsync.RegisterTimeStamps( string )
-- What it Does:    Adds the player's name and timestamp for election
-- Purpose:         Need to aggregate all the player data for voting!
GRMsync.RegisterTimeStamps = function ( msg )
    -- Adding { timestamp , name } to the list of people giving their time... 3 second response time valid only.
    table.insert ( GRMsyncGlobals.ElectTimeOnlineTable , { tonumber ( string.sub ( msg , string.find ( msg , "?" ) + 1 ) ) , string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) } );
end

-- Method:          GRMsync.ElectedLeader ( string )
-- What it Does:    Established the elected leader based on message received.
-- Purpose:         Final step in designating a leader!
GRMsync.ElectedLeader = function ( msg )
    -- Message should just be the name, so no need to parse.
    GRMsync.SetLeader ( msg );
end

-- Method:          GRMsync.EstablishLeader()
-- What it Does:    Controls the algorithm flow for syncing data between players by establishing leader.
-- Purpose:         To have a healthy, lightweight, efficient syncing addon.
GRMsync.EstablishLeader = function()
    if time() - GRMsyncGlobals.InitializeTime > 15 then
        GRMsyncGlobals.InitializeTime = time();
        -- "Who is the leader?"
        if not GRMsyncGlobals.IsLeaderRequested then
            GRMsync.InquireLeader();
        end

        C_Timer.After ( 2 , function ()
            -- No responses, no leader! Setup an election for the leader!
            if not GRMsyncGlobals.LeadershipEstablished then
                GRMsync.RequestElection();
            end    
        end);
    end
end

-- Method:          GRMsync.HookComms()
-- What it Does:    Hooks the SendAddonMessage function so if any other addon uses it I can see
-- Purpose:         Global outgoing data cap is shared among all addons. To prevent disconnects it is important to know how much overhead other addons are using.
GRMsync.HookComms = function()
    hooksecurefunc ( C_ChatInfo , "SendAddonMessage" , function( prefix , msg )
        if prefix ~= "GRM_SYNC" then
            if type ( msg ) == "string" then
                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #msg + #prefix;
            else
                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + 255;
            end
        end
    end);
end

-- Method:          GRMsync.SetLeader ( string )
-- What it Does:    If message received, designates the sender as the leader
-- Purpose:         Need to designate a leader!
GRMsync.SetLeader = function ( leader )
    -- Error protection
    if string.find ( leader , "-" ) == nil then
        if GRM.IsMergedRealmServer() then
            local listOfGuildiesOnline = GRM.GetAllGuildiesOnline( true );
            for i = 1 , #listOfGuildiesOnline do
                if GRM.SlimName ( listOfGuildiesOnline[i] ) == leader then
                    leader = listOfGuildiesOnline[i];
                    break;
                end
            end
        else
            leader = leader .. "-" .. GRM_G.realmName;      -- Not a merged realm, so just add the server, since you are both on it.
        end
    end

    if leader ~= GRM_G.addonPlayerName and leader ~= GRMsyncGlobals.DesignatedLeader then
        GRMsyncGlobals.DesignatedLeader = leader;
        GRMsyncGlobals.LeadershipEstablished = true;
        GRMsyncGlobals.ElectionProcessing = false;

        -- Non leader sends request to sync
        if GRMsyncGlobals.SyncOK and not GRMsyncGlobals.reloadControl then
            GRMsync.SendMessage ( "GRM_SYNC" , GRM_G.PatchDayString .. "?GRM_REQUESTSYNC?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. "" , GRMsyncGlobals.channelName );
            if not GRMsyncGlobals.syncTempDelay then
                -- Disable sync again if necessary!
                if GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline() or ( GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] and GRMsyncGlobals.firstMessageReceived ) then
                    
                    if GRM_G.TemporarySync then
                        chat:AddMessage ( GRM.L ( "GRM:" ) .. " " .. GRM.L ( "Manually Syncing Data With Guildies Now... One Time Only." )  , 1.0 , 0.84 , 0 );
                    elseif GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
                        chat:AddMessage ( GRM.L ( "GRM:" ) .. " " .. GRM.L ( "Syncing Data With Guildies Now..." ) .. "\n" .. GRM.L ( "(Loading screens may cause sync to fail)" )  , 1.0 , 0.84 , 0 );
                    end
                else
                    if not GRMsyncGlobals.firstMessageReceived then
                        GRMsyncGlobals.firstMessageReceived = true;
                        GRM.Report ( GRM.L ( "GRM:" ) .. " " .. GRM.L ( "No Addon Users Currently Compatible for FULL Sync." ) .. "\n" .. GRM.L ( "Check the \"Sync Users\" tab to find out why!" ) );
                        if #GRM_G.currentAddonUsers > 0 and GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] then
                            GRM.Report ( "     " .. GRM.L ( "You will still share some outgoing data with the guild" ) );
                        end
                    end
                end
            end
        else
            GRMsyncGlobals.reloadControl = false;
        end
    elseif leader == GRM_G.addonPlayerName then
        GRMsyncGlobals.DesignatedLeader = leader;
        GRMsyncGlobals.LeadershipEstablished = true;
        GRMsyncGlobals.IsElectedLeader = true;
        GRMsyncGlobals.ElectionProcessing = false;

        -- Initiate data sync
        -- After time delay to receive responses, intiate sync after vote... 3 sec. delay. Everyone else request to sync.
        if not GRMsyncGlobals.reloadControl then
            C_Timer.After ( 1 , GRMsync.InitiateDataSync );
        else
            GRMsyncGlobals.reloadControl = false;
        end
    end    
end

-------------------------------
---- MESSAGE SENDING ----------
-------------------------------

-- Method:          GRMsync.SendMessage ( string , string , string , int )
-- What it Does:    Sends an invisible message over a specified channel that a player cannot see, but an addon can read.
-- Purpose:         Necessary function for cross-talk between players using addon.
GRMsync.SendMessage = function ( prefix , msg , type )
    if GRMsyncGlobals.SyncOK then
        if (#msg + #prefix) >= 255 then
            GRM.Report( GRM.L ( "GRM ERROR:" ) .. " " .. GRM.L ( "Com Message too large for server" ) .. "\n" .. GRM.L ( "Prefix:" ) .. " " .. prefix .. "\n" .. GRM.L ( "Msg:" ) .. " " .. msg );
        elseif msg == "" and prefix == "GRM_SYNC" then
            return
        else
            if GRM_G.DebugEnabled then
                GRM.AddDebugMessage ( msg );
            end
            C_ChatInfo.SendAddonMessage ( prefix , msg , type );
        end
    end
end

--------------------------------
---- LIVE MESSAGE SCRIPTS ------
--------------------------------

-- Method:          GRMsync.CheckJoinDataChange ( string )
-- What it Does:    Parses the details of the message to be usable, and then uses that info to see if it is different than current info, and if it is, then enacts changes.
-- Purpose:         To sync player join dates properly.
GRMsync.CheckJoinDateChange = function( msg , sender , prefix )
    -- To avoid spamminess
    local isSyncUpdate = false;
    if prefix == "GRM_JDSYNCUP" then
        isSyncUpdate = true;
    end

    local playerName = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local joinDate = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local finalTStamp = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local finalEpochStamp = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local epochTimeOfChange = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
    local noteDestination = string.sub ( msg , string.find ( msg , "?" ) + 1 );

    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

    for r = 2 , #guildData do
        if playerName == guildData[r][1] then
            -- Let's see if there was a change
            if guildData[r][2] ~= finalTStamp and guildData[r][35][2] < epochTimeOfChange then
                -- do a null check... will be same as button text
                if guildData[r][20][ #guildData[r][20] ] ~= nil or #guildData[r][20] > 0 then
                    table.remove ( guildData[r][20] , #guildData[r][20] );  -- Removing previous instance to replace
                    table.remove ( guildData[r][21] , #guildData[r][21] ); 
                end
                table.insert( guildData[r][20] , finalTStamp );     -- oldJoinDate
                table.insert( guildData[r][21] , finalEpochStamp ) ;   -- oldJoinDateMeta
                guildData[r][2] = finalTStamp;
                guildData[r][3] = finalEpochStamp;
               
               -- For sync
                guildData[r][35][1] = finalTStamp;
                guildData[r][35][2] = epochTimeOfChange;

                -- Gotta update the event tracker date too!
                local date = GRM.ConvertGenericTimestampToIntValues ( string.sub ( joinDate , 9 ) );
                guildData[r][22][1][1][1] = date[1];
                guildData[r][22][1][1][2] = date[2];
                guildData[r][22][1][1][3] = date[3];
                guildData[r][22][1][2] = false;  -- Gotta Reset the "reported already" boolean!
                GRM.RemoveFromCalendarQue ( guildData[r][1] , 1 , nil );

                -- In case of Unknown
                guildData[r][40] = false;

                -- Report the updates!
                if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] and not isSyncUpdate then
                    
                    chat:AddMessage ( GRM.L ( "{name} updated {name2}'s Join Date." , GRM.GetClassifiedName ( sender , true ) , GRM.GetClassifiedName ( playerName , true ) ) , 1.0 , 0.84 , 0 );
                end

                -- Updating count of changes
                if isSyncUpdate then
                    GRMsyncGlobals.updateCount = GRMsyncGlobals.updateCount + 1;
                end
                
                -- Live update if any frames visible so player does not need to close and reopen for updates.
                if GRM_UI.GRM_MemberDetailMetaData ~= nil and GRM_UI.GRM_MemberDetailMetaData:IsVisible() and GRM_G.currentName == playerName then
                    GRM_UI.GRM_MemberDetailMetaData.GRM_JoinDateText:SetText ( string.sub ( joinDate , 9 ) );
                     if GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailJoinDateButton:IsVisible() then
                        GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailJoinDateButton:Hide();                
                    end
                    GRM_UI.GRM_MemberDetailMetaData.GRM_JoinDateText:Show();

                    if noteDestination == "officer" then
                        GRM_UI.GRM_MemberDetailMetaData.GRM_noteFontString2:SetText ( joinDate );
                        GRM_UI.GRM_MemberDetailMetaData.GRM_PlayerOfficerNoteEditBox:SetText ( joinDate );
                    elseif noteDestination == "public" then
                        GRM_UI.GRM_MemberDetailMetaData.GRM_noteFontString1:SetText ( joinDate );
                        GRM_UI.GRM_MemberDetailMetaData.GRM_PlayerNoteEditBox:SetText ( joinDate );
                    elseif noteDestination == "custom" then
                        GRM_UI.GRM_MemberDetailMetaData.GRM_CustomNoteEditBoxFrame.GRM_CustomNoteEditBox:SetText ( joinDate );
                    end
                end

                if not isSyncUpdate and GRM_UI.GRM_RosterChangeLogFrame.GRM_AuditFrame:IsVisible() then
                    GRM.RefreshAuditFrames( GRM_G.AuditSortType );
                end
                
            end
            break;
        end
    end
end

-- Method           GRMsync.CheckPromotionDateChange ( string , string )
-- What it Does:    Checks if received info is different than current, then updates it
-- Purpose:         Data sharing between guildies carrying the addon
GRMsync.CheckPromotionDateChange = function ( msg , sender , prefix )
    -- To avoid spamminess
    local isSyncUpdate = false;
    if prefix == "GRM_PDSYNCUP" then
        isSyncUpdate = true;
    end

    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local promotionDate = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    local epochTimeOfChange = tonumber ( string.sub ( msg , string.find ( msg , "?" ) + 1 ) );
    local slimDate = string.sub ( promotionDate , 11 );

    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

    for r = 2 , #guildData do
        if guildData[r][1] == name then
            if guildData[r][12] ~= slimDate and guildData[r][36][2] < epochTimeOfChange then
                guildData[r][12] = slimDate;
                guildData[r][25][#guildData[r][25]][2] = slimDate;
                if isSyncUpdate then
                    guildData[r][13] = GRM.TimeStampToEpoch ( promotionDate , true );
                else
                    guildData[r][13] = GRM.TimeStampToEpoch ( promotionDate , false );
                end

                -- For SYNC
                guildData[r][36][1] = slimDate;
                guildData[r][36][2] = epochTimeOfChange;
                guildData[r][41] = false;
                
                -- Report the updates!
                if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] and not isSyncUpdate then
                    chat:AddMessage ( GRM.L ( "{name} updated {name2}'s Promotion Date." , GRM.GetClassifiedName ( sender , true ) , GRM.GetClassifiedName ( name , true ) ) , 1.0 , 0.84 , 0 );
                end

                -- Updating count of changes
                if isSyncUpdate then
                    GRMsyncGlobals.updateCount = GRMsyncGlobals.updateCount + 1;
                end

                -- If the player is on the same frames, update them too!
                if GRM_UI.GRM_MemberDetailMetaData:IsVisible() and GRM_G.currentName == name then
                    if GRM_UI.GRM_MemberDetailMetaData.GRM_SetPromoDateButton:IsVisible() then
                        GRM_UI.GRM_MemberDetailMetaData.GRM_SetPromoDateButton:Hide();
                    end

                    GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailRankDateTxt:SetText ( GRM.L ( "Promoted:" ) .. " " .. GRM.Trim ( string.sub ( guildData[r][12] , 1 , 10) ) );
                    GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailRankDateTxt:Show();
                end

                if not isSyncUpdate and GRM_UI.GRM_RosterChangeLogFrame.GRM_AuditFrame:IsVisible() then
                    GRM.RefreshAuditFrames( GRM_G.AuditSortType );
                end

            end
            break;
        end
    end
end

-- Method:          GRMsync.EventAddedToCalendarCheck ( string , string )
-- What it Does:    Checks to see if player has the event already in que. If it is, then remove it.
-- Purpose:         Cleanliness. If it is removed from one person's list, it is removed from all!
GRMsync.EventAddedToCalendarCheck = function ( msg , sender )
    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local title = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    local index = tonumber ( string.sub ( msg , string.find ( msg , "?" ) + 1 ) );


    if GRM.IsOnAnnouncementList ( name , index , title ) then
        -- Remove from the list
        GRM.RemoveFromCalendarQue ( name , index , title );

        -- Refresh the frame!
        GRM.RefreshAddEventFrame();
        -- Send chat update info.
        if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
            chat:AddMessage ( GRM.L ( "\"{custom1}\" event added to the calendar by {name}" , GRM.GetClassifiedName ( sender , true ) , nil , nil , title ) , 1.0 , 0.84 , 0 );
        end
    end
end

-------------------------------------------
-------- ALT UPDATE COMMS -----------------
-------------------------------------------


-- Method:          GRMsync.CheckAddAltChange ( string , string , string )
-- What it Does:    Adds the alt as well to your list, if it is not already added
-- Purpose:         Additional chcecks required to avoid message spamminess, but basically to sync alt lists on adding.
GRMsync.CheckAddAltChange = function ( msg , sender , prefix )
    -- To avoid spamminess
    local isSyncUpdate = false;
    if prefix == "GRM_ALTSYNCUP" then
        isSyncUpdate = true;
    end

    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local altName = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    local altNameEpochTime = tonumber ( string.sub ( msg , string.find ( msg , "?" ) + 1 ) );
    local abortUpdate = false;

    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];
    
    if name ~= altName then         -- To avoid spam message to all players...
       
        -- Verify player is not already on someone else's list...
        local isFound = false;
        local isFound2 = false;
        for s = 2 , #guildData do
            if guildData[s][1] == altName then

                if #guildData[s][11] > 0 then
                    local listOfAlts = guildData[s][11];
            
                    for m = 1 , #listOfAlts do                                              -- Let's quickly verify that this is not a repeat alt add.
                        if listOfAlts[m][1] == name then                                    
                            isFound = true;
                            break;
                        end
                    end

                    -- Check if removed from list
                    if not isFound then
                        for h = 1 , #guildData[s][37] do
                            if guildData[s][37][h][1] == name then
                                -- match found! Let's see what is more up to date!
                                if altNameEpochTime < guildData[s][37][h][6] then
                                    -- This alt update is OLDER and more outdated... this prevents update!
                                    abortUpdate = true;
                                end
                                break;
                            end
                        end
                    end

                else
                    for r = 2 , #guildData do
                        if guildData[r][1] == name then
                            
                            local listOfAlts = guildData[r][11];
                            if #listOfAlts > 0 then                                                                 -- There is more than 1 alt for new alt to be added to
                                
                                for i = 1 , #listOfAlts do                                                          -- Cycle through previously known alt names to add new on each, one by one.
                                    for j = 2 , #guildData do                             -- Need to now cycle through all toons in the guild to set the alt
                                        if listOfAlts[i][1] == guildData[j][1] then       -- name on current focus altList found in the metadata!
                                            -- Now, make sure it is not a repeat add!
                                            
                                            for m = 1 , #listOfAlts do                                              -- Let's quickly verify that this is not a repeat alt add.
                                                if listOfAlts[m][1] == altName then
                                                    isFound2 = true;
                                                    break;
                                                end
                                            end
                                            break;
                                        end
                                    end
                                    if isFound2 then
                                        break;
                                    end
                                end

                                for h = 1 , #guildData[r][37] do
                                    if guildData[r][37][h][1] == altName then
                                        -- match found! Let's see what is more up to date!
                                        if altNameEpochTime < guildData[r][37][h][6] then
                                            -- This alt update is OLDER and more outdated... this prevents update!
                                            abortUpdate = true;
                                        end
                                        break;
                                    end
                                end
                            end
                            break;
                        end
                    end
                end
                break;
            end
        end

        if not isFound and not isFound2 and not abortUpdate then
            if isSyncUpdate then
                GRM.AddAlt ( name , altName , true , altNameEpochTime );
            else
                GRM.AddAlt ( name , altName , false , 0 );
            end
            GRM.SyncBirthdayWithNewAlt ( altName );

            if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] and not isSyncUpdate then
                chat:AddMessage ( GRM.L ( "{name} updated {name2}'s list of Alts." , GRM.GetClassifiedName ( sender , true ) , GRM.GetClassifiedName ( name , true ) ) , 1.0 , 0.84 , 0 );
            end

            -- Updating count of changes
            if isSyncUpdate then
                GRMsyncGlobals.updateCount = GRMsyncGlobals.updateCount + 1;
            end

            if not isSyncUpdate and GRM_UI.GRM_RosterChangeLogFrame.GRM_AuditFrame:IsVisible() then
                GRM.RefreshAuditFrames( GRM_G.AuditSortType );
            end
        end
    end
end


-- Method:          GRMsync.CheckRemoveAltChange ( string , string , string )
-- What it Does:    Syncs the removal of an alt between all ONLINE players
-- Purpose:         Sync data between online players.
GRMsync.CheckRemoveAltChange = function ( msg , sender , prefix )
    -- To avoid spamminess
    local isSyncUpdate = false;
    if prefix == "GRM_REMSYNCUP" then
        isSyncUpdate = true;
    end

    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local altName = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    local altChangeTimeStamp = tonumber ( string.sub ( msg , string.find ( msg , "?" ) + 1 ) );
    local count = 0;
    local index = 0;
    local abortUpdate = false;

    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

    -- Checking if alt is to be removed... establishing number of alts.
    for i = 2 , #guildData do
        if guildData[i][1] == name then
            count = #guildData[i][11];
            index = i;

            -- determine if need to abort... most recent change. Since we are going through each player sequentially, this ensures the first sync info doesn't override everyone's data if 2 player's have different pieces of info.
            if count > 0 then
                for j = 1 , count do
                    if guildData[i][11][j][1] == altName then
                        if guildData[i][11][j][6] > altChangeTimeStamp then   -- If the player's current info is more recent (greater number = more recent epoch time), no need to remove. Sync will happen soon.
                            abortUpdate = true;
                        end
                        break;
                    end
                end
            end
            break;
        end
    end
    
    if not abortUpdate then
        if isSyncUpdate then
            GRM.RemoveAlt ( name , altName , true , altChangeTimeStamp , false );
        else
            GRM.RemoveAlt ( name , altName , false , 0 , false );
        end
        
        if GRM_UI.GRM_MemberDetailMetaData:IsVisible() and GRM_G.currentName == altName then       -- If the alt being removed is being dumped from the list of alts, but the Sync person is on that frame...
            -- if main, we will hide this.
            GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailMainText:Hide();

            -- Now, let's hide all the alts
            for i = 2 , #guildData do
                if guildData[i][1] == altName then
                    GRM.PopulateAltFrames ( i );
                    break;
                end
            end
        end

        -- if alts are ZERO, it implies the person is going 1 to zero and this player was not sync'd with them in count. If
        -- alts are less, then you are ensuring that one was actually removed.
        if count == 0 or count > #guildData[index][11] then
            if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] and not isSyncUpdate then
                
                chat:AddMessage ( GRM.L ( "{name} removed {name2}'s from {custom1}'s list of Alts." , GRM.GetClassifiedName ( sender , true ) , GRM.GetClassifiedName ( altName , true ) , nil , GRM.GetClassifiedName ( name ) ) , 1.0 , 0.84 , 0 );
            end

            -- Updating count of changes
            if isSyncUpdate then
                GRMsyncGlobals.updateCount = GRMsyncGlobals.updateCount + 1;
            end

            if not isSyncUpdate and GRM_UI.GRM_RosterChangeLogFrame.GRM_AuditFrame:IsVisible() then
                GRM.RefreshAuditFrames( GRM_G.AuditSortType );
            end
        end
    end
end


-- Method:          GRMsync.CheckAltMainChange ( string , string )
-- What it Does:    Syncs Main selection control between players
-- Purpose:         Sync data between players LIVE
GRMsync.CheckAltMainChange = function ( msg , sender )
    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    local mainName = string.sub ( msg , string.find ( msg , "?" ) + 1 );

    GRM.SetMain ( name , mainName , false , 0 );

    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

    -- We need to add the timestamps our selves as well! In the main program, the timestamps are only triggered on manually clicking and adding/removing
    for j = 2 , #guildData do
        if guildData[j][1] == mainName then
            guildData[j][39] = time();
            break;
        end
    end

    -- Need to ensure "main" tag populates correctly.
    if GRM_UI.GRM_MemberDetailMetaData:IsVisible() then
        if not GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailMainText:IsVisible() and GRM_G.currentName == mainName then
            GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailMainText:Show();
        elseif GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailMainText:IsVisible() and GRM_G.currentName ~= mainName then
            GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailMainText:Hide();
        end
    end

    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
        chat:AddMessage ( GRM.L ( "{name} set {name2} to be 'Main'" , GRM.GetClassifiedName ( sender , true ) , GRM.GetClassifiedName ( mainName , true ) ) , 1.0 , 0.84 , 0 );
    end

    if GRM_UI.GRM_RosterChangeLogFrame.GRM_AuditFrame:IsVisible() then
        GRM.RefreshAuditFrames( GRM_G.AuditSortType );
    end
end


-- Method:          GRMsync.CheckMainSyncChange ( string )
-- What it Does:    Syncs the MAIN status among all online guildies who have addon installed and are proper rank
-- Purpose:         Keep player MAINS sync'd properly!
GRMsync.CheckMainSyncChange = function ( msg )
    local mainName = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local mainStatus = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    local mainChangeTimestamp = tonumber ( string.sub ( msg , string.find ( msg , "?" ) + 1 ) );
    local abortMainChange = false;

    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

    for j = 2 , #guildData do
        if guildData[j][1] == mainName then
            if guildData[j][39] > mainChangeTimestamp or tostring ( guildData[j][10] ) == mainStatus then        -- if the most-recent event is my own, I will ignore the sync message.
                abortMainChange = true;
            end
            break;
        end
    end

    if not abortMainChange then 
        if mainStatus == "true" then
            -- Set the player as Main
            GRM.SetMain ( mainName , mainName , true , mainChangeTimestamp );
            -- Need to ensure "main" tag populates correctly if window is open.
            if GRM_UI.GRM_MemberDetailMetaData:IsVisible() then
                if not GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailMainText:IsVisible() and GRM_G.currentName == mainName then
                    GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailMainText:Show();
                end
            end
        else
            -- remove from being main.
            GRM.DemoteFromMain ( mainName , mainName , true , mainChangeTimestamp );
            -- Udate the UI!
            if GRM_UI.GRM_MemberDetailMetaData:IsVisible() and GRM_G.currentName == mainName then
                GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailMainText:Hide();
            end
        end

        -- Updating count of changes
        GRMsyncGlobals.updateCount = GRMsyncGlobals.updateCount + 1;
    end
end


-- Method:          GRMsync.CheckAltMainToAltChange ( string , string )
-- What it Does:    If a player is demoted from main to alt, it syncs that change with everyone
-- Purpose:         Sync data between players LIVE
GRMsync.CheckAltMainToAltChange = function ( msg , sender )
    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    local mainName = string.sub ( msg , string.find ( msg , "?" ) + 1 );

    GRM.DemoteFromMain ( name , mainName , false , 0 );

    if GRM_UI.GRM_MemberDetailMetaData:IsVisible() then
        if GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailMainText:IsVisible() and GRM_G.currentName == mainName then
            GRM_UI.GRM_MemberDetailMetaData.GRM_MemberDetailMainText:Hide();
        end
    end
    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
        chat:AddMessage ( GRM.L ( "{name} has changed {name2} to be listed as an 'alt'" , GRM.GetClassifiedName ( sender , true ) , GRM.GetClassifiedName ( mainName , true ) ) , 1.0 , 0.84 , 0 );
    end

    if GRM_UI.GRM_RosterChangeLogFrame.GRM_AuditFrame:IsVisible() then
        GRM.RefreshAuditFrames( GRM_G.AuditSortType );
    end
end


-- Method:          GRMsync.CheckCustomNoteChange ( string , string , int )
-- What it Does:    It updates the Custom Note as needed, live
-- Purpose:         Sync the information between guildies live, as well as obey the filtering rules between clients.
GRMsync.CheckCustomNoteChange = function ( msg , sender , senderRankID )
    -- No need to do all the work if custom note sync disabled!
    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][38] then
        -- Parse the comm
        local senderControlRankRequirement = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local playerName = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local timeStamp = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        local customNote = string.sub ( msg , string.find ( msg , "?" ) + 1 );

        local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

        -- Check for changes!
        for i = 2 , #guildData do
            if guildData[i][1] == playerName then

                -- No need to check if this one note has sync turned off
                if guildData[i][23][1] then
                    -- Player identified... now we need to find out what sync restriction you have on them.
                    if ( senderRankID > guildData[i][23][4] or senderControlRankRequirement < GRM_G.playerRankID ) then
                        return;
                    else
                        -- Rank restrictions are good, now let's see if the note is different!
                        if customNote ~= guildData[i][23][6] then
                            local oldNote = guildData[i][23][6];
                            guildData[i][23][2] = timeStamp;
                            guildData[i][23][3] = sender;
                            guildData[i][23][6] = customNote;
                            
                            -- Handle Log reporting logic here... 
                            GRM.RecordCustomNoteChanges ( guildData[i][23][6] , oldNote , sender , guildData[i][1] , true )
                        end
            
                        -- Update the UI proper
                        if GRM_UI.GRM_MemberDetailMetaData.GRM_CustomNoteEditBoxFrame.GRM_CustomNoteEditBox:IsVisible() and playerName == GRM_G.currentName then
                            GRM_G.OriginalEditBoxValue = guildData[i][23][6];  -- This needs to be set to handle the OnEditFocusLost logic..
                            if customNote == "" then
                                GRM_UI.GRM_MemberDetailMetaData.GRM_CustomNoteEditBoxFrame.GRM_CustomNoteEditBox:SetText ( GRM.L ( "Click here to set Custom Notes" ) );
                                GRM_G.OriginalEditBoxValue = GRM.L ( "Click here to set Custom Notes" );
                            else
                                GRM_UI.GRM_MemberDetailMetaData.GRM_CustomNoteEditBoxFrame.GRM_CustomNoteEditBox:SetText ( guildData[i][23][6] );
                            end
                            GRM_UI.GRM_MemberDetailMetaData.GRM_CustomNoteEditBoxFrame.GRM_CustomNoteEditBox:ClearFocus();
                        end
                    end
                end
                break;
            end
        end
    end
end

-- Method:          GRMsync.CheckBirthdayChange ( string , string , boolean )
-- What it Does:    Checks the live received change on the Birthday details
-- Purpose:         All birthday info to be shared.
GRMsync.CheckBirthdayChange = function ( msg , sender , isFullSync )
    -- No sense in doing the work if option is disabled...
    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][68] then
        local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local day = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local month = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local date = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        local timestamp = tonumber ( string.sub ( msg , string.find ( msg , "?" ) + 1 ) );

        GRM.SetBirthday ( name , day , month , 1 , date , timestamp , true , sender , isFullSync );
    end
end

-- Method:          GRMsync.CheckCustomNoteSyncChange ( string )
-- What it Does:    For use in the Retroactive non-live sync, it checks and compares custom notes and applies the most current one
-- Purpose:         For updating and syncing the custom notes!!!
GRMsync.CheckCustomNoteSyncChange = function ( msg , senderRankID , isReceivedSync )
    -- No need to check if sync is disable for custo notes :D
    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][38] then
        -- Parse the comm
        local senderControlRankRequirement = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local playerName = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local timeStamp = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local editorName = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        local customNote = string.sub ( msg , string.find ( msg , "?" ) + 1 );

        local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

        -- Check for changes!
        for i = 2 , #guildData do
            if guildData[i][1] == playerName then
                -- Player identified... now we need to find out what sync restriction you have on them.
                if guildData[i][23][1] then
                    if ( isReceivedSync and ( senderRankID > guildData[i][23][4] or senderControlRankRequirement < GRM_G.playerRankID ) ) then
                        return;
                    else
                        if guildData[i][23][2] < timeStamp and timeStamp ~= 0 then
                            -- Rank restrictions are good, now let's see if the note is different!
                            if customNote ~= guildData[i][23][6] then
                                local oldNote = guildData[i][23][6];
                                guildData[i][23][2] = timeStamp;
                                guildData[i][23][3] = editorName;
                                guildData[i][23][6] = customNote;
                                
                                -- Handle Log reporting logic here... 
                                GRM.RecordCustomNoteChanges ( customNote , oldNote , editorName , playerName , false )

                                -- Updating count of changes
                                GRMsyncGlobals.updateCount = GRMsyncGlobals.updateCount + 1;
                            end
                
                            -- Update the UI proper
                            if GRM_UI.GRM_MemberDetailMetaData.GRM_CustomNoteEditBoxFrame.GRM_CustomNoteEditBox:IsVisible() and playerName == GRM_G.currentName then
                                GRM_G.OriginalEditBoxValue = guildData[i][23][6];  -- This needs to be set to handle the OnEditFocusLost logic..
                                if customNote == "" then
                                    GRM_UI.GRM_MemberDetailMetaData.GRM_CustomNoteEditBoxFrame.GRM_CustomNoteEditBox:SetText ( GRM.L ( "Click here to set Custom Notes" ) );
                                    GRM_G.OriginalEditBoxValue = GRM.L ( "Click here to set Custom Notes" );
                                else
                                    GRM_UI.GRM_MemberDetailMetaData.GRM_CustomNoteEditBoxFrame.GRM_CustomNoteEditBox:SetText ( guildData[i][23][6] );
                                end
                                GRM_UI.GRM_MemberDetailMetaData.GRM_CustomNoteEditBoxFrame.GRM_CustomNoteEditBox:ClearFocus();
                            end
                        end
                    end
                end
                break;
            end
        end
    end
end


-- Method:          GRMsync.CheckBanListChange ( string , string )
-- What it Does:    If a player is banned, then it broadcasts the bane to the rest of the players, so they can update their info.
-- Purpose:         It is far more useful if more than one person maintains a BAN list...
GRMsync.CheckBanListChange = function ( msg , sender )
    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local banAlts = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local reason = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    local class = string.upper ( string.sub ( msg , string.find ( msg , "?" ) + 1 ) );
    local timeEpoch = time();

    if reason == GRM.L ( "None Given" ) then
        reason = "";
    end

    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];
    local leftGuildData = GRM_PlayersThatLeftHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

    -- First things first, let's find player!
    local isFound = false;
    for j = 2 , #guildData do
        if guildData[j][1] == name then
            -- The initial ban of the player.
            isFound = true;
            guildData[j][17][1] = true;
            guildData[j][17][2] = timeEpoch;
            guildData[j][17][3] = false;
            guildData[j][18] = reason;

            -- Next thing is IF alts are to be banned, this will ban them all as well!
            if banAlts == "true" then
                local listOfAlts = guildData[j][11];
                if #listOfAlts > 0 then
                    for s = 1 , #listOfAlts do
                        for r = 2 , #guildData do
                            if guildData[r][1] == listOfAlts[s][1] and guildData[r][1] ~= GRM_G.addonPlayerName then

                                -- Banning the alts one by one in the for loop
                                guildData[r][17][1] = true;
                                guildData[r][17][2] = timeEpoch;
                                guildData[r][17][3] = false;
                                guildData[r][18] = reason;

                                break;
                            end
                        end
                    end
                end
            end
            break;
        end
    end

    -- let's check the left player's on live sync
    if not isFound then
        for i = 2 , #leftGuildData do
            if leftGuildData[i][1] == name then
                isFound = true;
                leftGuildData[i][17][1] = true;
                leftGuildData[i][17][2] = timeEpoch;
                leftGuildData[i][17][3] = false;
                leftGuildData[i][18] = reason;
    
                break;
            end
        end
    end

    -- OMG, if player is still not found... this is a brand new name added
    if not isFound then
        -- Add ban of in-guild guildie with notification!!!
        local memberInfoToAdd = {
            name,
            GuildControlGetRankName ( GuildControlGetNumRanks() ),
            GuildControlGetNumRanks() - 1,
            1,
            "",
            "",
            class,
            1,
            "",
            100,
            false,
            1,
            false,
            0
        }
        GRM.AddMemberToLeftPlayers ( memberInfoToAdd , GRM.GetTimestamp() , time() , GRM.GetTimestamp() , time() - 5000 );
        -- Now, let's implement the ban!
        for i = 2 , #leftGuildData do
            if leftGuildData[i][1] == name then
                leftGuildData[i][17][1] = true;
                leftGuildData[i][17][2] = timeEpoch;
                leftGuildData[i][17][3] = false;
                leftGuildData[i][18] = reason;
                break;
            end
        end

    end

    -- Add ban info to the log.
    local logEntry = "";
    local classCode = GRM.GetClassColorRGB ( class , true );
    if banAlts == "true" then
        logEntry = ( GRM.FormatTimeStamp ( GRM.GetTimestamp() , true ) .. " : " .. GRM.L ( "{name} has BANNED {name2} and all linked alts from the guild!" , GRM.GetClassifiedName ( sender , true ) , classCode .. GRM.SlimName ( name ) .. "|r" ) );
    else
        logEntry = ( GRM.FormatTimeStamp ( GRM.GetTimestamp() , true ) .. " : " .. GRM.L ( "{name} has BANNED {name2} from the guild!" , GRM.GetClassifiedName ( sender , true ) , classCode .. GRM.SlimName ( name ) .. "|r" ) );
    end
    
    if reason ~= "" then
        GRM.AddLog ( 18 , GRM.L ( "Reason Banned:" ) .. " " .. reason );
    end
    GRM.AddLog ( 17 , logEntry );

    -- Report the change to chat window...
    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
        if banAlts == "true" then
            chat:AddMessage ( GRM.L ( "{name} has BANNED {name2} and all linked alts from the guild!" , GRM.GetClassifiedName ( sender , true ) , classCode .. GRM.SlimName ( name ) .. "|r" ) , 1.0 , 0 , 0 );
            if reason == "" then
                reason = "< None Stated > ";
            end
            chat:AddMessage ( GRM.L ( "Reason Banned:" ) .. " " .. reason , 1.0 , 1.0 , 1.0 );
        else
            chat:AddMessage ( GRM.L ( "{name} has BANNED {name2} from the guild!" , GRM.GetClassifiedName ( sender , true ) , classCode .. GRM.SlimName ( name ) .. "|r" ) , 1.0 , 0 , 0 );
            if reason == "" then
                reason = "< None Stated > ";
            end
            chat:AddMessage ( GRM.L ( "Reason Banned:" ) .. " " .. reason , 1.0 , 1.0 , 1.0 );
        end
    end

    GRM.BuildLogComplete()

    -- Refresh Frames!
    if GRM_UI.GRM_RosterChangeLogFrame.GRM_CoreBanListFrame:IsVisible() then
        GRM.RefreshBanListFrames();
    end
end

-- Method:          GRMsync.CheckUnbanListChangeLive()
-- What it Does:    Removes the given player from the ban list
-- Purpose:         to sync ban information live. Of note, I NEED to build all the for loops here because the timestamps must be compared.
GRMsync.CheckUnbanListChangeLive = function ( msg , sender )
    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );

    -- The other method is built for all the logic...
    GRM.BanListUnban ( name );

    -- Message
    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
        chat:AddMessage ( GRM.L ( "{name} has Removed {name2} from the Ban List." , GRM.GetClassifiedName ( sender , true ) , GRM.SlimName ( name ) ) , 1.0 , 0.84 , 0 );
    end
end

-- Method:          GRMsync.BanManagementPlayersThatLeft ( string , string )
-- What it Does:    Bans or Unbans a player on the "PlayersThatLeft" global save file
-- Purpose:         Syncing bans and unbans between players...
GRMsync.BanManagementPlayersThatLeft = function ( msg , prefix )
    -- To avoid spamminess
    local isSyncUpdate = false;
    if prefix == "GRM_BANSYNCUP" then
        isSyncUpdate = true;
    end

    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local timeStampEpoch = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local banStatus = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    local reason = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local abortBanChange = false;

    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];
    local leftGuildData = GRM_PlayersThatLeftHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

    if reason == GRM.L ( "No Reason Given" ) then
        reason = "";
    end

    local isFound = false;
    for j = 2 , #leftGuildData do
        if leftGuildData[j][1] == name then
            isFound = true;
            if ( banStatus == "ban" and not leftGuildData[j][17][1] ) or ( banStatus == "unban" and leftGuildData[j][17][1] ) then
                -- Ok, let's see if it is a ban or an unban!
                if banStatus == "ban" then
                    -- if player has been unbanned, let's check timestamps to see which is more recent.
                    if leftGuildData[j][17][3] and leftGuildData[j][17][2] > timeStampEpoch then
                        abortBanChange = true;
                    else
                        leftGuildData[j][17][1] = true;
                        leftGuildData[j][17][2] = timeStampEpoch;
                        leftGuildData[j][17][3] = false;
                        leftGuildData[j][18] = reason;
                    end
                else
                    -- Cool, player is being unbanned! "unban"

                    if leftGuildData[j][17][1] and leftGuildData[j][17][2] > timeStampEpoch then
                        abortBanChange = true;
                    else    
                        if leftGuildData[j][17][1] then
                            leftGuildData[j][17][3] = true;
                        end
                        leftGuildData[j][17][1] = false;
                        leftGuildData[j][17][2] = timeStampEpoch;
                        leftGuildData[j][18] = "";
                    end
                end

                -- Add ban info to the log.
                -- Report the updates!
                if not abortBanChange then
                    local colorCode = GRM.GetClassColorRGB ( leftGuildData[j][9] , true );
                    if banStatus == "ban" then
                        if reason ~= "" then
                            GRM.AddLog ( 18 , GRM.L ( "Reason:" ) .. " " .. reason );
                        end
                        GRM.AddLog ( 17 , ( GRM.FormatTimeStamp ( GRM.GetTimestamp() , true ) .. " : " .. GRM.L ( "{name} has been BANNED from the guild!" , colorCode .. GRM.SlimName ( name ) .. "|r" ) ) );
                    else
                        GRM.AddLog ( 17 , ( GRM.FormatTimeStamp ( GRM.GetTimestamp() , true ) .. " : " .. GRM.L ( "{name} has been UN-BANNED from the guild!" , colorCode .. GRM.SlimName ( name ) .. "|r" ) ) );
                    end
                    
                    -- Send update to chat window!
                    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] and not isSyncUpdate then
                        if banStatus == "ban" then
                            chat:AddMessage ( GRM.L ( "{name} has been BANNED from the guild!" , colorCode .. GRM.SlimName ( name )  .. "|r" )  , 1.0 , 0 , 0 );
                        else
                            chat:AddMessage ( GRM.L ( "{name} has been UN-BANNED from the guild!" , colorCode .. GRM.SlimName ( name ) .. "|r" )  , 1.0 , 0 , 0 );
                        end
                    end
                end
            end
            break;
        end
    end

    -- Player was not found, let's check current in-guild players!
    if not isFound then
        for j = 2 , #guildData do
            if guildData[j][1] == name then
                if ( banStatus == "ban" and not guildData[j][17][1] ) or ( banStatus == "unban" and guildData[j][17][1] ) then
                    -- Ok, let's see if it is a ban or an unban!
                    if banStatus == "ban" then
                        -- if player has been unbanned, let's check timestamps to see which is more recent.
                        if guildData[j][17][3] and guildData[j][17][2] > timeStampEpoch then
                            abortBanChange = true;
                        else
                            guildData[j][17][1] = true;
                            guildData[j][17][2] = timeStampEpoch;
                            guildData[j][17][3] = false;
                            guildData[j][18] = reason;
                        end
                    else
                        -- Cool, player is being unbanned! "unban"

                        if guildData[j][17][1] and guildData[j][17][2] > timeStampEpoch then
                            abortBanChange = true;
                        else    
                            if guildData[j][17][1] then
                                guildData[j][17][3] = true;
                            end
                            guildData[j][17][1] = false;
                            guildData[j][17][2] = timeStampEpoch;
                            guildData[j][18] = "";
                        end
                    end

                    -- Add ban info to the log.
                    -- Report the updates!
                    if not abortBanChange then
                        local colorCode = GRM.GetClassColorRGB ( guildData[j][9] , true );
                        if banStatus == "ban" then
                            if reason ~= "" then
                                GRM.AddLog ( 18 , GRM.L ( "Reason:" ) .. " " .. reason );
                            end
                            GRM.AddLog ( 17 , ( GRM.FormatTimeStamp ( GRM.GetTimestamp() , true ) .. " : " .. GRM.L ( "{name} has been BANNED from the guild!" , colorCode .. GRM.SlimName ( name ) .. "|r" ) ) );
                        else
                            GRM.AddLog ( 17 , ( GRM.FormatTimeStamp ( GRM.GetTimestamp() , true ) .. " : " .. GRM.L ( "{name} has been UN-BANNED from the guild!" , colorCode .. GRM.SlimName ( name ) .. "|r" ) ) );
                        end
                        
                        -- Send update to chat window!
                        if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] and not isSyncUpdate then
                            if banStatus == "ban" then
                                chat:AddMessage ( GRM.L ( "{name} has been BANNED from the guild!" , colorCode .. GRM.SlimName ( name )  .. "|r" ) , 1.0 , 0 , 0 );
                            else
                                chat:AddMessage ( GRM.L ( "{name} has been UN-BANNED from the guild!" , colorCode .. GRM.SlimName ( name ) .. "|r" ) , 1.0 , 0 , 0 );
                            end
                        end
                    end
                end
                break;
            end
        end
    end

    -- Update the live frames too!
    if GRM_UI.GRM_RosterChangeLogFrame.GRM_CoreBanListFrame:IsVisible() then
        GRM.RefreshBanListFrames();
    end

end

--------------------------------
---- Default Mesage Functions --
--------------------------------

-- Method:          GRMsync.RegisterPrefix( string )
-- What it Does:    To do an addon info send over a channel, the prefix first needs to be registered.
-- Purpose:         For player to player addon talk.
GRMsync.RegisterPrefix = function ( prefix )

    -- Prefix can't be more than 16 characters
    if #prefix > 16 then
        error ( GRM.L ( "GRM ERROR:" ) .. " " .. GRM.L ( "Unable to register prefix > 16 characters: {name}" , prefix ) );
    end
    C_ChatInfo.RegisterAddonMessagePrefix ( prefix );
end

-- Method:          GRMsync.RegisterPrefixes()
-- What it Does:    Registers the tages for all of the messages, so the addon recognizes and knows to pick them up
-- Purpose:         Prefixes need to be registered to the server to be usable for addon to addon talk.
GRMsync.RegisterPrefixes = function( listOfPrefixes )
    for i = 1 , #listOfPrefixes do 
        GRMsync.RegisterPrefix ( listOfPrefixes[i] );
    end
end

-- Method:          GRMsync.IsPrefixVerified ( string )
-- What it Does:    Returns true if received prefix is listed in this addon's
-- Purpose:         Control the spam in case of other prefixes received from other addons in guild channel.
GRMsync.IsPrefixVerified = function( prefix )
    local result = false;
    for i = 1 , #GRMsyncGlobals.listOfPrefixes do
        if GRMsyncGlobals.listOfPrefixes[i] == prefix then
            result = true;
            break;
        end
    end
    return result;
end



-------------------------------
-------------------------------
------ SYNC ALGORITHM ---------
-------------------------------
------ RETROACTIVE SYNC -------
-------------------------------
-------------------------------


-------------------------------
------- NON-LEADER FORWARD ----
-------------------------------
-- Method:          GRMsync.SendJDPackets()
-- What it Does:    Broadcasts to the leader all join date information
-- Purpose:         Data sync
GRMsync.SendJDPackets = function()
    if time() - GRMsyncGlobals.SyncJDDelay >= 0.9 then
        GRMsyncGlobals.SyncJDDelay = time();
        -- Initiate Data sending
        GRMsyncGlobals.dateSentComplete = false;
        GRMsyncGlobals.TimeSinceLastSyncAction = time();

        -- Messages need to be throttled, but sending them under controls.
        local syncRankFilter = GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15];
        if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] then
            syncRankFilter = GRMsyncGlobals.numGuildRanks;
        end
        local syncMessage = GRM_G.PatchDayString .. "?GRM_JDSYNC?" .. syncRankFilter;
        local tempMessage = "";
        local messageReady;
        local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];
    
        for i = GRMsyncGlobals.SyncCountJD , #guildData do
            messageReady = false;
            if GRMsyncGlobals.SyncOK then
                
                if guildData[i][35][2] ~= 0 then
                    -- Expand the string more... Fill up the full 255 characters for efficiency.
                    if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                        tempMessage = syncMessage .. "?" .. guildData[i][1] .. "?" .. guildData[i][35][2] .. "?" .. guildData[i][35][1];

                        if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                            syncMessage = tempMessage;
                            if i == #guildData then
                                messageReady = true;
                            end
                        else
                            messageReady = true;
                            -- Hold this value over...
                            tempMessage = GRM_G.PatchDayString .. "?GRM_JDSYNC?" .. syncRankFilter .. "?" .. guildData[i][1] .. "?" .. guildData[i][35][2] .. "?" .. guildData[i][35][1];
                            -- Need to send it out as it will not re-loop
                            if i == #guildData then
                                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMessage + GRMsyncGlobals.sizeModifier;
                                
                                GRMsync.SendMessage ( "GRM_SYNC" , tempMessage , GRMsyncGlobals.channelName );
                            end
                        end
                    end
                end

                -- Send message
                if messageReady then
                    GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #syncMessage + GRMsyncGlobals.sizeModifier;
                    GRMsync.SendMessage ( "GRM_SYNC" , syncMessage , GRMsyncGlobals.channelName );
                    syncMessage = tempMessage;
                end

                -- Check if there needs to be a throttled delay
                if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                    GRMsyncGlobals.syncTempDelay = true;
                    GRMsyncGlobals.SyncCountJD = i;
                    GRMsyncGlobals.SyncCount = 0;
                    C_Timer.After ( 1 , GRMsync.SendJDPackets );       -- Add a 1 second delay on packet sending.
                    return;
                end
            end
        end
        -- Close the Data stream
        GRMsyncGlobals.SyncCountJD = 2;
        GRMsyncGlobals.syncTempDelay = false;
        if GRMsyncGlobals.SyncOK then
            GRMsync.SendPDPackets();
        end
    end
end

-- Method:          GRMsync.SendPDPackets()
-- What it Does:    Broadcasts to the leader all promo date information
-- Purpose:         Data sync
GRMsync.SendPDPackets = function()
    if time() - GRMsyncGlobals.SyncPDDelay >= 0.9 then
        GRMsyncGlobals.SyncPDDelay = time();
        -- Initiate Data sending
        GRMsyncGlobals.TimeSinceLastSyncAction = time();
    
        -- Messages need to be throttled, but sending them under controls.
        local syncRankFilter = GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15];
        if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] then
            syncRankFilter = GRMsyncGlobals.numGuildRanks;
        end
        local syncMessage = GRM_G.PatchDayString .. "?GRM_PDSYNC?" .. syncRankFilter;
        local tempMessage = "";
        local messageReady;
        local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

        for i = GRMsyncGlobals.SyncCountPD , #guildData do
            messageReady = false;
            if GRMsyncGlobals.SyncOK then
                
                -- Expand the string more... Fill up the full 255 characters for efficiency.
                if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                    tempMessage = syncMessage .. "?" .. guildData[i][1] .. "?" .. guildData[i][36][2] .. "?" .. guildData[i][36][1];

                    if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                        syncMessage = tempMessage;
                        if i == #guildData then
                            messageReady = true;
                        end
                    else
                        messageReady = true;
                        -- Hold this value over...
                        tempMessage = GRM_G.PatchDayString .. "?GRM_PDSYNC?" .. syncRankFilter .. "?" .. guildData[i][1] .. "?" .. guildData[i][36][2] .. "?" .. guildData[i][36][1];
                        -- If we are in the last index it won't loop back around, so we need to send it now...
                        if i == #guildData then
                            GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMessage + GRMsyncGlobals.sizeModifier;
                            GRMsync.SendMessage ( "GRM_SYNC" , tempMessage , GRMsyncGlobals.channelName );
                        end
                    end
                end

                -- Send message
                if messageReady then
                    GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #syncMessage + GRMsyncGlobals.sizeModifier;
                    GRMsync.SendMessage ( "GRM_SYNC" , syncMessage , GRMsyncGlobals.channelName );
                    syncMessage = tempMessage;
                end

                -- Check if there needs to be a throttled delay
                if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                    GRMsyncGlobals.syncTempDelay = true;
                    GRMsyncGlobals.SyncCountPD = i;
                    GRMsyncGlobals.SyncCount = 0; 
                    C_Timer.After ( 1 , GRMsync.SendPDPackets );       -- Add a 1 secon delay on packet sending.
                    return;
                end
            end
        end
        
        -- Close the Data stream
        GRMsyncGlobals.SyncCountPD = 2;
        GRMsyncGlobals.syncTempDelay = false;
        if GRMsyncGlobals.SyncOK then
            GRMsync.SendBANPackets();
        end
    end
end


-- Method:          GRMsync.SendBANPackets()
-- What it Does:    Broadcasts to the leader all Ban information
-- Purpose:         Data sync
GRMsync.SendBANPackets = function()
    if time() - GRMsyncGlobals.SyncBanDelay >= 0.9 then
        GRMsyncGlobals.SyncBanDelay = time();
        -- Initiate Data sending
        GRMsyncGlobals.TimeSinceLastSyncAction = time();
        -- For sync error check help
        local tempMsg = GRM_G.PatchDayString .. "?GRM_BANSYNC4?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. " ?";
        local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];
        local leftGuildData = GRM_PlayersThatLeftHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];


        GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMsg + GRMsyncGlobals.sizeModifier;
        GRMsync.SendMessage ( "GRM_SYNC" , tempMsg , GRMsyncGlobals.channelName );    
        if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][21] then
            if GRMsyncGlobals.SyncOK and not GRMsyncGlobals.syncTempDelay then
                local tempMsg2 = GRM_G.PatchDayString .. "?GRM_START?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. tostring ( #leftGuildData - 1 );
                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMsg2 + GRMsyncGlobals.sizeModifier;
                GRMsync.SendMessage ( "GRM_SYNC" , tempMsg2 , GRMsyncGlobals.channelName );         -- MSG = number of expected values to be sent.
            end

                -- Messages need to be throttled, but sending them under controls.
            local syncMessage = GRM_G.PatchDayString .. "?GRM_BANSYNC?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. tostring ( GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][22] );
            local tempMessage = "";
            local tempMessage2 = "";
            local tempMessage3 = "";
            local messageReady;
            local timeStampOfBanChange;
            local msgTag;
            local reason = "";
            for i = GRMsyncGlobals.SyncCountBan , #leftGuildData do
                messageReady = false;

                timeStampOfBanChange = tostring ( leftGuildData[i][17][2] );
                msgTag = "ban";
                -- Let's see if someone was unbanned.
                if leftGuildData[i][17][3] then
                    msgTag = "unban";
                elseif not leftGuildData[i][17][1] and not leftGuildData[i][17][3] then
                    msgTag = "noban";
                end
                
                if GRMsyncGlobals.SyncOK then
                    -- Expand the string more... Fill up the full 255 characters for efficiency.
                    if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then

                        if leftGuildData[i][18] == "" or leftGuildData[i][18] == nil then
                            reason = GRM.L ( "No Reason Given" );
                        else
                            reason = leftGuildData[i][18];
                        end
                        if msgTag == "ban" or msgTag == "unban" then
                            -- % will represent the GRM_BanSync2 - that player needs to be added to the database...]
                            tempMessage3 = "?%" .. leftGuildData[i][1] .. "?" .. leftGuildData[i][4] .. "?" .. tostring ( leftGuildData[i][5] ) .. "?" .. tostring ( leftGuildData[i][6] ) .. "?" .. leftGuildData[i][9] .. "?" .. leftGuildData[i][15][#leftGuildData[i][15]] .. "?" .. tostring ( leftGuildData[i][16][#leftGuildData[i][16]] ) .. "?" .. leftGuildData[i][2] .. "?" .. tostring ( leftGuildData[i][3] ) .. "?" .. msgTag .. "?&" .. leftGuildData[i][1] .. "?" .. timeStampOfBanChange .. "?" .. msgTag .. "?" .. reason;

                            tempMessage = syncMessage .. tempMessage3;

                            -- partial string for carryover without the header
                            tempMessage2 = tempMessage3;
                        else
                            tempMessage = syncMessage .. "?&" .. leftGuildData[i][1] .. "?" .. timeStampOfBanChange .. "?" .. msgTag .. "?" .. reason;

                            tempMessage2 = "?&" .. leftGuildData[i][1] .. "?" .. timeStampOfBanChange .. "?" .. msgTag .. "?" .. reason;                        
                            
                        end

                        if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                            syncMessage = tempMessage;
                            if i == #leftGuildData then
                                messageReady = true;
                            end
                        else
                            messageReady = true;
                            -- Hold this value over...
                            tempMessage = GRM_G.PatchDayString .. "?GRM_BANSYNC?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. tostring ( GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][22] ) .. tempMessage2;
                            -- If we are in the last index it won't loop back around, so we need to send it now...
                            if i == #leftGuildData then
                                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMessage + GRMsyncGlobals.sizeModifier;
                                GRMsync.SendMessage ( "GRM_SYNC" , tempMessage , GRMsyncGlobals.channelName );
                            end
                        end
                    end

                    -- Send message
                    if messageReady then
                        GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #syncMessage + GRMsyncGlobals.sizeModifier;
                        GRMsync.SendMessage ( "GRM_SYNC" , syncMessage , GRMsyncGlobals.channelName );
                        syncMessage = tempMessage;
                    end

                    -- Check if there needs to be a throttled delay
                    if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                        GRMsyncGlobals.syncTempDelay = true;
                        GRMsyncGlobals.SyncCountBan = i;
                        GRMsyncGlobals.SyncCount = 0;
                        C_Timer.After ( 1 , GRMsync.SendBANPackets );       -- Add a 1 second delay on packet sending.
                        return;
                    end
                end
            end
            -- reset values to new list...
            syncMessage = GRM_G.PatchDayString .. "?GRM_BANSYNC2?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. tostring ( GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][22] );
            tempMessage = "";
            -- if I get here... let's do the in-guild sync too!
            for i = GRMsyncGlobals.SyncCount7 , #guildData do
                messageReady = false;
                
                timeStampOfBanChange = tostring ( guildData[i][17][2] );
                msgTag = "ban";
                -- Let's see if someone was unbanned.
                if guildData[i][17][3] then
                    msgTag = "unban";
                elseif not guildData[i][17][1] and not guildData[i][17][3] then
                    msgTag = "noban";
                end

                if GRMsyncGlobals.SyncOK then
                    -- Expand the string more... Fill up the full 255 characters for efficiency.
                    if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then

                        if msgTag == "ban" or msgTag == "unban" then
                            -- % will represent the GRM_BanSync2 - that player needs to be added to the database...]
                            tempMessage = syncMessage .. "?" .. guildData[i][1] .. "?" .. timeStampOfBanChange .. "?" .. msgTag .. "?" .. guildData[i][18];
                        end

                        if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                            syncMessage = tempMessage;
                            if i == #guildData then
                                messageReady = true;
                            end
                        else
                            messageReady = true;
                            -- Hold this value over...
                            tempMessage = GRM_G.PatchDayString .. "?GRM_BANSYNC2?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. tostring ( GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][22] ) .. "?" .. guildData[i][1] .. "?" .. timeStampOfBanChange .. "?" .. msgTag .. "?" .. guildData[i][18];
                            -- If we are in the last index it won't loop back around, so we need to send it now...
                            if i == #guildData then
                                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMessage + GRMsyncGlobals.sizeModifier;
                                GRMsync.SendMessage ( "GRM_SYNC" , tempMessage , GRMsyncGlobals.channelName );
                            end
                        end
                    end
                    -- Send message
                    if messageReady then
                        GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #syncMessage + GRMsyncGlobals.sizeModifier;
                        GRMsync.SendMessage ( "GRM_SYNC" , syncMessage , GRMsyncGlobals.channelName );
                        syncMessage = tempMessage;
                    end

                    -- Check if there needs to be a throttled delay
                    if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                        GRMsyncGlobals.syncTempDelay = true;
                        GRMsyncGlobals.SyncCount7 = i;
                        GRMsyncGlobals.SyncCount = 0;
                        C_Timer.After ( 1 , GRMsync.SendBANPackets );       -- Add a 1 second delay on packet sending.
                        return;
                    end
                end
            end
        end
        -- Close the Data stream
        GRMsyncGlobals.SyncCountBan = 2;
        GRMsyncGlobals.SyncCount7 = 2;
        GRMsyncGlobals.syncTempDelay = false;
        if GRMsyncGlobals.SyncOK then
            GRMsync.SendAltPackets();
        end
    end
end

-- Method:          GRMsync.OptimizeAltForSync ( array )
-- What it Does:    Cleans up the alt list so you don't repeat send all of the alt data for the entire grouping, you only send the alt data for one in the group.
-- Purpose:         Massive efficiency. Imagine if a player has 15 alts. Rather than send the alt data for all 15, you only send the alt data for 1 person, and it builds for all those others in the grouping.
GRMsync.OptimizeAltForSync = function ( altList )
    for i = 1 , #altList do
        for j = 2 , #GRMsyncGlobals.TempRoster do
            if GRMsyncGlobals.TempRoster[j][1] == altList[i][1] then
                table.remove ( GRMsyncGlobals.TempRoster , j );
                break;
            end
        end
    end
end

-- Method:          GRMsync.SendAddAltPackets ( int )
-- What it Does:    Compartmentalizes the Add Alt logorithm to send the data controlled, fills the packets to max characters, and sends and if it hits throttle cap, resets.
-- Purpose:         Control the flow of data to prevent player disconnect on sending sync data
GRMsync.SendAddAltPackets = function( syncRankFilter )
    -- Message controls for throttle considerations and packing them fully...
    local syncMessage = GRM_G.PatchDayString .. "?GRM_ALTADDSYNC?" .. syncRankFilter;
    local tempMessage = "";
    local tempMessage2 = "";
    local tempMessage3 = "";
    local tempMessage4 = "";
    local messageReady;
    local i = GRMsyncGlobals.SyncCountAltAdd;

    -- Set the tables to new memory index to prevent stutter...
    if GRMsyncGlobals.AltSendIsFinished then
        GRMsyncGlobals.TempRoster = GRM.DeepCopyArray ( GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ] );     -- I will be editiing this so needs to be made.
        GRMsyncGlobals.AltSendIsFinished = false;
        C_Timer.After ( 1.5 , GRMsync.SendAltPackets );
        return;
    end

    if not GRMsyncGlobals.syncTempDelay2  then
        -- Messages need to be throttled, but sending them under controls.
        -- Note "&" represents the start of a new toon's alts list in the same string.
        while i <= #GRMsyncGlobals.TempRoster do
            messageReady = false;
            if GRMsyncGlobals.SyncOK then
                if #GRMsyncGlobals.TempRoster[i][11] > 0 then
                    if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                        -- add new player
                        tempMessage = syncMessage .. "?&" .. GRMsyncGlobals.TempRoster[i][1];
                        tempMessage4 = tempMessage .. GRMsyncGlobals.TempRoster[i][11][1][1] .. "?" .. tostring ( GRMsyncGlobals.TempRoster[i][11][1][6] )
                        -- Add all the alts...
                        tempMessage2 = "";
                        for j = 1 , #GRMsyncGlobals.TempRoster[i][11] do
                            if j == 1 and ( #tempMessage4 + GRMsyncGlobals.sizeModifier ) >= 255 then
                                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #syncMessage + GRMsyncGlobals.sizeModifier;
                                GRMsync.SendMessage ( "GRM_SYNC" , syncMessage , GRMsyncGlobals.channelName );
                                tempMessage = GRM_G.PatchDayString .. "?GRM_ALTADDSYNC?" .. syncRankFilter .. "?&" .. GRMsyncGlobals.TempRoster[i][1];
                            else
                                
                                -- To temp store the value;
                                tempMessage3 = tempMessage;

                                -- Add the alt...
                                tempMessage = tempMessage .. "?" .. GRMsyncGlobals.TempRoster[i][11][j][1] .. "?" .. tostring ( GRMsyncGlobals.TempRoster[i][11][j][6] );

                                -- String without the header for carryover.
                                tempMessage2 = tempMessage2 .. "?" .. GRMsyncGlobals.TempRoster[i][11][j][1] .. "?" .. tostring ( GRMsyncGlobals.TempRoster[i][11][j][6] );
                                
                                -- Need to check... One player might have too many alts altogether. That is ok! Just send out, reset!
                                if #tempMessage + GRMsyncGlobals.sizeModifier >= 255 then
                                    GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMessage3 + GRMsyncGlobals.sizeModifier;
                                    GRMsync.SendMessage ( "GRM_SYNC" , tempMessage3 , GRMsyncGlobals.channelName );
                                    -- reset the string
                                    tempMessage = GRM_G.PatchDayString .. "?GRM_ALTADDSYNC?" .. syncRankFilter .. "?&" .. GRMsyncGlobals.TempRoster[i][1] .. "?" .. GRMsyncGlobals.TempRoster[i][11][j][1] .. "?" .. tostring ( GRMsyncGlobals.TempRoster[i][11][j][6] );
                                    tempMessage2 = "";
                                end
                            end
                        end
                        if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                            syncMessage = tempMessage;
                            if i == #GRMsyncGlobals.TempRoster then
                                messageReady = true;
                            end
                        else
                            messageReady = true;
                            -- Hold this value over...
                            tempMessage = GRM_G.PatchDayString .. "?GRM_ALTADDSYNC?" .. syncRankFilter .. "?&" .. GRMsyncGlobals.TempRoster[i][1] .. tempMessage2; -- Don't need the extra "?" divider since no header...
                        end
                        -- GRMsync.OptimizeAltForSync ( GRMsyncGlobals.TempRoster[i][11] );        -- No need to send the alt lists for ALL toons...
                    end
                else
                    if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                        tempMessage = syncMessage .. "?&" .. GRMsyncGlobals.TempRoster[i][1] .. "?0";
                        if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                            syncMessage = tempMessage;
                            if i == #GRMsyncGlobals.TempRoster then
                                messageReady = true;
                            end
                        else
                            messageReady = true;
                            -- Hold this value over...
                            tempMessage = GRM_G.PatchDayString .. "?GRM_ALTADDSYNC?" .. syncRankFilter .. "?&" .. GRMsyncGlobals.TempRoster[i][1] .. "?0";
                        end
                    end
                end

                -- Send message
                if messageReady then
                    GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #syncMessage + GRMsyncGlobals.sizeModifier;
                    GRMsync.SendMessage ( "GRM_SYNC" , syncMessage , GRMsyncGlobals.channelName );
                    syncMessage = tempMessage;
                end

                -- Check if there needs to be a throttled delay
                if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                    GRMsyncGlobals.syncTempDelay = true;
                    GRMsyncGlobals.SyncCountAltAdd = i;
                    GRMsyncGlobals.SyncCount = 0;
                    C_Timer.After ( 1 , GRMsync.SendAltPackets );       -- Add a 1 second delay on packet sending.
                    return;
                end
            end
            -- Progress the while loop
            i = i + 1;
        end
    end
    return true;
end

-- Method:          GRMsync.SendRemoveAltPackets ( int )
-- What it Does:    Compartmentalizes the Remove Alt logorithm to send the data controlled, fills the packets to max characters, and sends and if it hits throttle cap, resets.
-- Purpose:         Control the flow of data to prevent player disconnect on sending sync data
GRMsync.SendRemoveAltPackets = function ( syncRankFilter )
    -- -- Removed Alts Table...
    local syncMessage = GRM_G.PatchDayString .. "?GRM_ALTREMSYNC?" .. syncRankFilter;
    local tempMessage = "";
    local tempMessage2 = "";
    local tempMessage3 = "";
    local tempMessage4 = "";
    local messageReady;

    if GRMsyncGlobals.AltSendIsFinished2 then
        GRMsyncGlobals.TempRoster = nil;
        GRMsyncGlobals.TempRoster = {};
        GRMsyncGlobals.TempRoster = GRM.DeepCopyArray ( GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ] ); -- reset the roster
        GRMsyncGlobals.AltSendIsFinished2 = false;
        C_Timer.After ( 1.5 , GRMsync.SendAltPackets );
        return;
    end

    for i = GRMsyncGlobals.SyncCountAltRem , #GRMsyncGlobals.TempRoster do
        messageReady = false;
        if GRMsyncGlobals.SyncOK then
            if #GRMsyncGlobals.TempRoster[i][37] > 0 then
                if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                    tempMessage = syncMessage .. "?&" .. GRMsyncGlobals.TempRoster[i][1];
                    tempMessage4 = tempMessage .. GRMsyncGlobals.TempRoster[i][37][1][1] .. "?" .. tostring ( GRMsyncGlobals.TempRoster[i][37][1][6] )
                    -- Add all the alts...
                    tempMessage2 = "";
                    for j = 1 , #GRMsyncGlobals.TempRoster[i][37] do
                        if j == 1 and ( #tempMessage4 + GRMsyncGlobals.sizeModifier ) >= 255 then
                            GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #syncMessage + GRMsyncGlobals.sizeModifier;
                            GRMsync.SendMessage ( "GRM_SYNC" , syncMessage , GRMsyncGlobals.channelName );
                            tempMessage = GRM_G.PatchDayString .. "?GRM_ALTREMSYNC?" .. syncRankFilter .. "?&" .. GRMsyncGlobals.TempRoster[i][1];
                        else
                            -- To temp store the value;
                            tempMessage3 = tempMessage;

                            tempMessage = tempMessage .. "?" .. GRMsyncGlobals.TempRoster[i][37][j][1] .. "?" .. tostring ( GRMsyncGlobals.TempRoster[i][37][j][6] );
                            -- String without the header for carryover.
                            tempMessage2 = tempMessage2 .. "?" .. GRMsyncGlobals.TempRoster[i][37][j][1] .. "?" .. tostring ( GRMsyncGlobals.TempRoster[i][37][j][6] );

                            -- Need to check... One player might have too many alts removed. That is ok! Just send out, reset!
                            if #tempMessage + GRMsyncGlobals.sizeModifier >= 255 then
                                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMessage3 + GRMsyncGlobals.sizeModifier;
                                GRMsync.SendMessage ( "GRM_SYNC" , tempMessage3 , GRMsyncGlobals.channelName );
                                -- reset the string
                                tempMessage = GRM_G.PatchDayString .. "?GRM_ALTREMSYNC?" .. syncRankFilter .. "?&" .. GRMsyncGlobals.TempRoster[i][1] .. "?" .. GRMsyncGlobals.TempRoster[i][37][j][1] .. "?" .. tostring ( GRMsyncGlobals.TempRoster[i][37][j][6] );
                                tempMessage2 = "";
                            end
                        end
                    end
                    if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                        syncMessage = tempMessage;
                        if i == #GRMsyncGlobals.TempRoster then
                            messageReady = true;
                        end
                    else
                        messageReady = true;
                        -- Hold this value over...
                        tempMessage = GRM_G.PatchDayString .. "?GRM_ALTREMSYNC?" .. syncRankFilter .. "?&" .. GRMsyncGlobals.TempRoster[i][1] .. tempMessage2; -- Don't need the extra "?" divider since no header...
                    end
                end
            else
                if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                    tempMessage = syncMessage .. "?&" .. GRMsyncGlobals.TempRoster[i][1] .. "?0";
                    if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                        syncMessage = tempMessage;
                        if i == #GRMsyncGlobals.TempRoster then
                            messageReady = true;
                        end
                    else
                        messageReady = true;
                        -- Hold this value over...
                        tempMessage = GRM_G.PatchDayString .. "?GRM_ALTREMSYNC?" .. syncRankFilter .. "?&" .. GRMsyncGlobals.TempRoster[i][1] .. "?0";
                    end
                end
            end

            -- Send message
            if messageReady then
                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #syncMessage + GRMsyncGlobals.sizeModifier;
                GRMsync.SendMessage ( "GRM_SYNC" , syncMessage , GRMsyncGlobals.channelName );
                syncMessage = tempMessage;
            end

            -- Check if there needs to be a throttled delay
            if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                GRMsyncGlobals.syncTempDelay = true;
                GRMsyncGlobals.syncTempDelay2 = true;
                GRMsyncGlobals.SyncCountAltRem = i;
                GRMsyncGlobals.SyncCount = 0;
                C_Timer.After ( 1 , GRMsync.SendAltPackets );       -- Add a 1 second delay on packet sending.
                return;
            end
        end
    end
    return true;
end

-- Method:          GRMsync.SendAltPackets()
-- What it Does:    Broadcasts to the leader all ALT information
-- Purpose:         Data sync
GRMsync.SendAltPackets = function()
    if time() - GRMsyncGlobals.SyncAltDelay >= 0.9 then
        GRMsyncGlobals.SyncAltDelay = time();
        GRMsyncGlobals.TimeSinceLastSyncAction = time();
        
        -- Settings configuration
        local syncRankFilter = GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15];
        if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] then
            syncRankFilter = GRMsyncGlobals.numGuildRanks;
        end

        local goStatus;     -- Gostatus controls the response to prevent it from continuing on if either of these functions returns early.
        goStatus = GRMsync.SendAddAltPackets ( syncRankFilter );
        if goStatus == nil then
            return
        end

        goStatus = GRMsync.SendRemoveAltPackets ( syncRankFilter );
        if goStatus == nil then
            return
        end

        GRMsyncGlobals.SyncCountAltAdd = 2;
        GRMsyncGlobals.SyncCountAltRem = 2;
        GRMsyncGlobals.syncTempDelay = false;
        GRMsyncGlobals.syncTempDelay2 = false;
        GRMsyncGlobals.AltSendIsFinished = true;
        GRMsyncGlobals.AltSendIsFinished2 = true;
        GRMsyncGlobals.TempRoster = nil;
        GRMsyncGlobals.TempRoster = {};
        if GRMsyncGlobals.SyncOK then
            GRMsync.SendMainPackets();
        end
    end
end

-- Method:          GRMsync.SendMainPackets()
-- What it Does:    Broadcasts to the leader all MAIN information
-- Purpose:         Data sync
GRMsync.SendMainPackets = function()
    if time() - GRMsyncGlobals.SyncMainDelay >= 0.9 then
        GRMsyncGlobals.SyncMainDelay = time();
        GRMsyncGlobals.TimeSinceLastSyncAction = time();

        -- Messages need to be throttled, but sending them under controls.
        local syncRankFilter = GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15];
        if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] then
            syncRankFilter = GRMsyncGlobals.numGuildRanks;
        end
        local syncMessage = GRM_G.PatchDayString .. "?GRM_MAINSYNC?" .. syncRankFilter;
        local tempMessage = "";
        local messageReady;
        local isPlayerMain = false;

        local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

        for i = GRMsyncGlobals.SyncCountMain , #guildData do
            messageReady = false;
            if GRMsyncGlobals.SyncOK then
            
                isPlayerMain = "false";       -- Kept as a string rather than a boolean so it can be passed as a comm over the server without needing to cast it to a string.
                if guildData[i][10] then
                    isPlayerMain = "true";
                end
                -- Expand the string more... Fill up the full 255 characters for efficiency.
                if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                    tempMessage = syncMessage .. "?" .. guildData[i][1]  .. "?" .. tostring ( guildData[i][39] ) .. "?" .. isPlayerMain;

                    if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                        syncMessage = tempMessage;
                        if i == #guildData then
                            messageReady = true;
                        end
                    else
                        messageReady = true;
                        -- Hold this value over...
                        tempMessage = GRM_G.PatchDayString .. "?GRM_MAINSYNC?" .. syncRankFilter .. "?" .. guildData[i][1]  .. "?" .. tostring ( guildData[i][39] ) .. "?" .. isPlayerMain;

                        -- If we are in the last index it won't loop back around, so we need to send it now...
                        if i == #guildData then
                            GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMessage + GRMsyncGlobals.sizeModifier;
                            GRMsync.SendMessage ( "GRM_SYNC" , tempMessage , GRMsyncGlobals.channelName );
                        end
                    end
                end

                -- Send message
                if messageReady then
                    GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #syncMessage + GRMsyncGlobals.sizeModifier;
                    GRMsync.SendMessage ( "GRM_SYNC" , syncMessage , GRMsyncGlobals.channelName );
                    syncMessage = tempMessage;
                end

                -- Check if there needs to be a throttled delay
                if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                    GRMsyncGlobals.syncTempDelay = true;
                    GRMsyncGlobals.SyncCountMain = i;
                    GRMsyncGlobals.SyncCount = 0; 
                    C_Timer.After ( 1 , GRMsync.SendMainPackets );       -- Add a 1 second delay on packet sending.
                    return;
                end
            end
        end
        -- Close the Data stream
        GRMsyncGlobals.SyncCountMain = 2;
        GRMsyncGlobals.syncTempDelay = false;
        if GRMsyncGlobals.SyncOK then
            GRMsync.SendCustomNotePackets();
        end
    end
end

-- Method:          GRMsync.SendCustomNotePackets()
-- What it Does:    Broadcasts to the leader all CUSTOM NOTES set to sync
-- Purpose:         Data sync for custom notes!!!!
GRMsync.SendCustomNotePackets = function()
    if time() - GRMsyncGlobals.SyncCustomDelay >= 0.9 then 
        GRMsyncGlobals.SyncCustomDelay = time();
        GRMsyncGlobals.TimeSinceLastSyncAction = time();

        local syncMessage = GRM_G.PatchDayString .. "?GRM_CUSTSYNC?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15];
        local tempMessage = "";
        local messageReady = false;
        local dataShouldBeSent = false;
        local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

        for i = GRMsyncGlobals.SyncCountCustom , #guildData do
            messageReady = false;
            dataShouldBeSent = false;
            if GRMsyncGlobals.SyncOK then
            
                if guildData[i][23][1] and guildData[i][23][2] ~= 0 then
                    dataShouldBeSent = true;
                end
                -- Expand the string more... Fill up the full 255 characters for efficiency.
                if dataShouldBeSent then
                    if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                        tempMessage = syncMessage .. "?" .. guildData[i][23][4] .. "?" .. guildData[i][1] .. "?" .. tostring ( guildData[i][23][2] ) .. "?" .. guildData[i][23][3] .. "?" .. guildData[i][23][6];

                        if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                            syncMessage = tempMessage;
                            if i == #guildData then
                                messageReady = true;
                            end
                        else
                            messageReady = true;
                            -- Hold this value over...
                            tempMessage = GRM_G.PatchDayString .. "?GRM_CUSTSYNC?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?" .. guildData[i][23][4] .. "?" .. guildData[i][1] .. "?" .. tostring ( guildData[i][23][2] ) .. "?" .. guildData[i][23][3] .. "?" .. guildData[i][23][6];

                            -- If we are in the last index it won't loop back around, so we need to send it now...
                            if i == #guildData then
                                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMessage + GRMsyncGlobals.sizeModifier;
                                GRMsync.SendMessage ( "GRM_SYNC" , tempMessage , GRMsyncGlobals.channelName );
                            end
                        end
                    end

                    -- Send message
                    if messageReady and dataShouldBeSent then
                        GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #syncMessage + GRMsyncGlobals.sizeModifier;
                        GRMsync.SendMessage ( "GRM_SYNC" , syncMessage , GRMsyncGlobals.channelName );
                        syncMessage = tempMessage;
                    end

                    -- Check if there needs to be a throttled delay
                    if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                        GRMsyncGlobals.syncTempDelay = true;
                        GRMsyncGlobals.SyncCountCustom = i;
                        GRMsyncGlobals.SyncCount = 0; 
                        C_Timer.After ( 1 , GRMsync.SendCustomNotePackets );       -- Add a 1 second delay on packet sending.
                        return;
                    end
                end
            end
        end
        -- Close the Data stream
        GRMsyncGlobals.SyncCountCustom = 2;
        GRMsyncGlobals.syncTempDelay = false;
        if GRMsyncGlobals.SyncOK then
            GRMsync.SendBDayPackets();
        end
    end
end

-- Method:          GRMsync.RemoveAltGroupingFromList ( miltiD-array , array )
-- What it Does:    Looks at the list of alts given and removes them from the list because they will have their data shared.
-- Purpose:         Only 1 birthday point of an alt grouping needs be shared since they sync. No need to waste resources.
GRMsync.RemoveAltGroupingFromList = function ( name , listOfAlts , list )
    -- Remove name from the list... this is all about process saving.
    for i = #list , 1 , -1 do
        if list[i] == name then
            table.remove ( list , i );
            break;
        end
    end
    for i = 1 , #listOfAlts do
        for j = #list , 1 , -1 do
            if listOfAlts[i][1] == list[j] then
                table.remove ( list , j );
                break;
            end
        end
    end
    return list;
end

-- name , day , month , date , timestamp
-- Method:          GRMsync.SendBDayPackets()
-- What it Does:    Broadcasts to the leader all CUSTOM NOTES set to sync
-- Purpose:         Data sync for custom notes!!!!
GRMsync.SendBDayPackets = function( listOfRemainingToons )
    if time() - GRMsyncGlobals.SyncBdayDelay >= 0.9 then 
        GRMsyncGlobals.SyncBdayDelay = time();
        GRMsyncGlobals.TimeSinceLastSyncAction = time();

        local syncRankFilter = GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15];
        if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] then
            syncRankFilter = GRMsyncGlobals.numGuildRanks;
        end
        local syncMessage = GRM_G.PatchDayString .. "?GRM_BDSYNC?" .. syncRankFilter;
        local tempMessage = "";
        local messageReady;
        local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];
        local list = listOfRemainingToons or GRM.GetAllGuildiesInOrder ( true , true );     -- No need to cycle through them all, just go by alt grouping...
        
        for i = GRMsyncGlobals.SyncCountBday , #guildData do
            for j = 1 , #list do
                if guildData[i][1] == list[j] or ( i == #guildData and j == #list ) then      -- Match to the list... Alt grouping not yet found!
                    messageReady = false;
                    if GRMsyncGlobals.SyncOK then          
                        
                        -- Expand the string more... Fill up the full 255 characters for efficiency.
                        if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                            if guildData[i][22][2][1][1] ~= 0 then
                                tempMessage = syncMessage .. "?" .. guildData[i][1] .. "?" .. tostring ( guildData[i][22][2][1][1] ) .. "?" .. tostring ( guildData[i][22][2][1][2] ) .. "?" .. guildData[i][22][2][3] .. "?" .. tostring ( guildData[i][22][2][4] );
                                -- let's cleanup the alt grouping then shall we!
                                list = GRMsync.RemoveAltGroupingFromList ( guildData[i][1] , guildData[i][11] , list );
                            end

                            if #tempMessage + GRMsyncGlobals.sizeModifier < 255 then
                                if tempMessage ~= "" then
                                    syncMessage = tempMessage;
                                end

                                if i == #guildData and syncMessage ~= ( GRM_G.PatchDayString .. "?GRM_BDSYNC?" .. syncRankFilter ) then
                                    messageReady = true;
                                end
                            else
                                messageReady = true;
                                -- Hold this value over...
                                tempMessage = GRM_G.PatchDayString .. "?GRM_BDSYNC?" .. syncRankFilter .. "?" .. guildData[i][1] .. "?" .. tostring ( guildData[i][22][2][1][1] ) .. "?" .. tostring ( guildData[i][22][2][1][2] ) .. "?" .. guildData[i][22][2][3] .. "?" .. tostring ( guildData[i][22][2][4] );
                                -- Need to send it out as it will not re-loop
                                if i == #guildData then
                                    GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMessage + GRMsyncGlobals.sizeModifier;
                                    GRMsync.SendMessage ( "GRM_SYNC" , tempMessage , GRMsyncGlobals.channelName );
                                end
                            end
                        end

                        -- Send message
                        if messageReady then
                            GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #syncMessage + GRMsyncGlobals.sizeModifier;
                            GRMsync.SendMessage ( "GRM_SYNC" , syncMessage , GRMsyncGlobals.channelName );
                            syncMessage = tempMessage;
                        end

                        -- Check if there needs to be a throttled delay
                        if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                            GRMsyncGlobals.syncTempDelay = true;
                            GRMsyncGlobals.SyncCountBday = i;
                            GRMsyncGlobals.SyncCount = 0;
                            C_Timer.After ( 1 , function()         -- Add a 1 second delay on packet sending.
                                GRMsync.SendBDayPackets ( list )
                            end);
                            return;
                        end
                    end
                    break;
                end
            end
        end

        -- Close the Data stream
        GRMsyncGlobals.SyncCountBday = 2;
        GRMsyncGlobals.syncTempDelay = false;
        if GRMsyncGlobals.SyncOK then
            GRMsync.SendMessage ( "GRM_SYNC" , GRM_G.PatchDayString .. "?GRM_STOP?" .. GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] .. "?CUSTOM" , GRMsyncGlobals.channelName );
            -- Need to Disable error checking now, however, as you will stop communicating with the designated leader
            GRMsyncGlobals.dateSentComplete = true;
        end
    end
end

-- Initiate Data sending
GRMsyncGlobals.dateSentComplete = false;
GRMsyncGlobals.TimeSinceLastSyncAction = time();

-------------------------------
----- LEADER COLLECTION -------
----- AND ANALYSIS ------------ 
-------------------------------

-- Method:          GRMsync.ErrorCheck()
-- What it Does:    On the giver ErrorCD interval, determines if sync has failed by time since last sync action has occcurred. 
-- Purpose:         To exit out the sync attempt and retry in an efficiennt non, time-wasting way.
GRMsync.ErrorCheck = function()
    if not GRM.IsCalendarEventEditOpen() then
        GuildRoster();
    end
    if GRMsyncGlobals.DesignatedLeader == GRM_G.addonPlayerName then
        if GRMsyncGlobals.currentlySyncing and ( time() - GRMsyncGlobals.TimeSinceLastSyncAction ) >= GRMsyncGlobals.ErrorCD then

            -- Check if player is offline...
            local playerIsOnline = GRM.IsGuildieOnline ( GRMsyncGlobals.CurrentSyncPlayer );
            local msg = GRM.L ( "GRM:" ) .. " " .. GRM.L ( "Sync Failed with {name}..." , GRM.GetClassifiedName ( GRMsyncGlobals.CurrentSyncPlayer , true ) );
            -- We already tried to sync, now aboard to 2nd.
            if playerIsOnline then
                if GRMsyncGlobals.numSyncAttempts == 1 then
                    table.remove ( GRMsyncGlobals.SyncQue , 1 );
                    GRMsyncGlobals.numSyncAttempts = 0;
                    GRMsyncGlobals.currentlySyncing = false;
                    GRMsyncGlobals.errorCheckEnabled = false;
                    -- Sync failed, this is 2nd attempt, AND, another person is in que.
                    
                    if #GRMsyncGlobals.SyncQue > 0 then
                        if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
                            if GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline() then
                                chat:AddMessage ( msg .. "\n" .. GRM.L ( "Initiating Sync with {name} Instead!" , GRM.GetClassifiedName ( GRMsyncGlobals.SyncQue[1] ) ) , 1.0 , 0.84 , 0 );
                            end
                        end
                        GRMsync.InitiateDataSync();
                    -- Sync failed, this is 2nd attempt, but no one else is in the que. Just end it.
                    else
                        if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
                            if GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline() then
                                chat:AddMessage ( msg , 1.0 , 0.84 , 0 );
                            end
                        end
                        GRMsyncGlobals.currentlySyncing = false;
                    end   
                elseif #GRMsyncGlobals.SyncQue > 0 then
                    GRMsyncGlobals.numSyncAttempts = GRMsyncGlobals.numSyncAttempts + 1;
                    GRMsyncGlobals.currentlySyncing = false;
                    GRMsyncGlobals.errorCheckEnabled = false;
                    GRMsync.InitiateDataSync();
                end
            else
                table.remove ( GRMsyncGlobals.SyncQue , 1 );
                GRMsyncGlobals.numSyncAttempts = 0;
                GRMsyncGlobals.currentlySyncing = false;
                GRMsyncGlobals.errorCheckEnabled = false;
                if #GRMsyncGlobals.SyncQue > 0 then
                    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
                        if GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline() then
                            chat:AddMessage ( msg .. "\n" .. GRM.L ( "The Player Appears to Be Offline." ) .. "\n" .. GRM.L ( "Initiating Sync with {name} Instead!" , GRM.GetClassifiedName ( GRMsyncGlobals.SyncQue[1] ) ) , 1.0 , 0.84 , 0 );
                        end
                    end
                    GRMsync.InitiateDataSync();
                else
                    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
                        if GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline() then
                            chat:AddMessage ( msg .. "\n" .. GRM.L ( "The Player Appears to Be Offline." ) , 1.0 , 0.84 , 0 );
                        end
                    end
                    GRMsyncGlobals.currentlySyncing = false;
                end
            end
        elseif GRMsyncGlobals.currentlySyncing and #GRMsyncGlobals.SyncQue > 0 then
            C_Timer.After ( GRMsyncGlobals.ErrorCD , GRMsync.ErrorCheck );
        end
    elseif not GRMsyncGlobals.dateSentComplete then
        if GRMsyncGlobals.currentlySyncing and ( time() - GRMsyncGlobals.TimeSinceLastSyncAction ) >= GRMsyncGlobals.ErrorCD then
            local playerIsOnline = GRM.IsGuildieOnline ( GRMsyncGlobals.DesignatedLeader );
            local msg = GRM.L ( "GRM:" ) .. " " .. GRM.L ( "Sync Failed with {name}..." , GRM.GetClassifiedName ( GRMsyncGlobals.DesignatedLeader , true ) );
            if GRMsyncGlobals.numSyncAttempts == 0 then
                if not playerIsOnline then
                    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
                        if GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline() then
                            chat:AddMessage ( msg .. "\n" .. GRM.L ( "The Player Appears to Be Offline." ) , 1.0 , 0.84 , 0 );
                        end
                    end
                else
                    GRMsyncGlobals.numSyncAttempts = GRMsyncGlobals.numSyncAttempts + 1;
                end
                GRMsync.TriggerFullReset();
                -- Now, let's add a brief delay, 11,1 seconds, to trigger sync again
                C_Timer.After ( 11.1 , function()
                    if not GRMsyncGlobals.currentlySyncing then
                        GRMsync.Initialize();
                    end
                end);
            else
                if not playerIsOnline then
                    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
                        if GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline() then
                            chat:AddMessage ( msg .. "\n" .. GRM.L ( "The Player Appears to Be Offline." ) , 1.0 , 0.84 , 0 );
                        end
                    end
                    GRMsync.TriggerFullReset();
                    -- Now, let's add a brief delay, 11,1 seconds, to trigger sync again
                    C_Timer.After ( 11.1 , function()
                        if not GRMsyncGlobals.currentlySyncing then
                            GRMsync.Initialize();
                        end
                    end);
                else
                    GRMsyncGlobals.numSyncAttempts = 0;
                    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
                        if GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline() then
                            chat:AddMessage ( msg .. "\n" .. GRM.L ( "There Might be a Problem With Their Sync" ) .. "\n" .. GRM.L ( "While not ideal, Ask Them to /reload to Fix It and Please Report the Issue to Addon Creator" ) , 1.0 , 0.84 , 0 );
                        end
                        GRMsyncGlobals.currentlySyncing = false;
                    end
                end
            end
        elseif GRMsyncGlobals.currentlySyncing then
            C_Timer.After ( GRMsyncGlobals.ErrorCD , GRMsync.ErrorCheck );  
        end
    else
        -- This condition can occur if the data has been sent, and then the receiving player/leader compiling it and syncing
        -- with other guildies goes offline, you will indefinitely be waiting, and it will say you are indefinitely syncing.
        -- This offers an escape
        local tempTime = ( time() - GRMsyncGlobals.TimeSinceLastSyncAction );
        if tempTime >= GRMsyncGlobals.ErrorCD and tempTime > GRMsyncGlobals.ErrorCD * 2 then
            local playerIsOnline = GRM.IsGuildieOnline ( GRMsyncGlobals.DesignatedLeader );
            if not playerIsOnline then
                if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
                    chat:AddMessage ( GRM.L ( "GRM:" ) .. " " .. GRM.L ( "Sync Failed with {name}..." , GRM.GetClassifiedName ( GRMsyncGlobals.DesignatedLeader ) ) .. "\n" .. GRM.L ( "The Player Appears to Be Offline." ) , 1.0 , 0.84 , 0 );
                end
                GRMsync.TriggerFullReset();
                -- Now, let's add a brief delay, 11,1 seconds, to trigger sync again
                C_Timer.After ( 11.1 , function()
                    if not GRMsyncGlobals.currentlySyncing then
                        GRMsync.Initialize();
                    end
                end);
            end
        end
        GRMsyncGlobals.errorCheckEnabled = false;
        GRMsyncGlobals.currentlySyncing = false;
    end
end

-- Method:          GRMsync.IsPlayerDataSyncCompatible ( string )
-- What it Does:    Returns true if the given player is "Ok!" to sync with
-- Purpose:         Useful in certain occasions to know whether to convey information to user or not.
GRMsync.IsPlayerDataSyncCompatible = function( playerName )
    local result = false;
    
    for i = 1 , #GRM_G.currentAddonUsers do
        if GRM_G.currentAddonUsers[i][1] == playerName then
            if GRM_G.currentAddonUsers[i][2] == "Ok!" then
                result = true;
            end
            break;
        end
    end
    return result;
end

-- Method:          GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline ()
-- What it Does:    Returns true if any user with the addon installed, not specific, is greenlit "Ok!" to sync with
-- Purpose:         Useful in certain occasions to know whether to convey information. Example: Behind the scenes there is a sync leader, if the sync leader is not set
--                  to sync with anyone else, but the other players are sync together, the sync leader still acts as a mediary and participates in the process, but just does not
--                  absorb any of the updates, only passes them on between the players. Well, it will be confusing to the player, who has restricted sync to certain ranks, if they are
--                  told in message that they are now syncing with others, even though they are not (though they are again, mediary processing info behind the scenes for others if elected leader)
GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline = function()
    local result = false;
    for i = 1 , #GRM_G.currentAddonUsers do
        if GRM_G.currentAddonUsers[i][2] == "Ok!" then
            result = true;
            break;
        end
    end
    return result;
end

-- Method:          GRMsync.InitiateDataSync()
-- What it Does:    Begins the sync process going throug hthe sync que
-- Purpose:         To Sync data!
GRMsync.InitiateDataSync = function ()
    if not GRM.IsCalendarEventEditOpen() then
        GuildRoster();
    end
    GRMsyncGlobals.numGuildRanks = GuildControlGetNumRanks() - 1;
    if not GRMsyncGlobals.currentlySyncing then
        GRMsyncGlobals.LeadSyncProcessing = false;
        -- First step, let's check Join Date Changes! Kickstart the fun!
        if #GRMsyncGlobals.SyncQue > 0 then
            -- Let's make sure the currentSyncPlayer is still online, as some time may have passed since we last checked.
            if GRM.IsGuildieOnline ( GRMsyncGlobals.SyncQue[1] ) then
                GRMsyncGlobals.currentlySyncing = true;
                GRMsyncGlobals.CurrentSyncPlayer = GRMsyncGlobals.SyncQue[1];
                GRMsyncGlobals.CurrentSyncPlayerRankID = GRM.GetGuildMemberRankID ( GRMsyncGlobals.SyncQue[1] );
                GRMsyncGlobals.CurrentLeaderRankID = GRM.GetGuildMemberRankID ( GRM_G.addonPlayerName );
                if GRMsyncGlobals.SyncOK then
                    GRMsync.ResetReportTables();
                    GRMsync.ResetTempTables();
                    GRMsyncGlobals.TimeSinceLastSyncAction = time();

                    if GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline() or ( GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] and GRMsyncGlobals.firstMessageReceived ) then
                        
                        if GRM_G.TemporarySync then
                            chat:AddMessage ( GRM.L ( "GRM:" ) .. " " .. GRM.L ( "Manually Syncing Data With Guildies Now... One Time Only." ) , 1.0 , 0.84 , 0 );
                        elseif GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] and GRMsyncGlobals.firstSync then
                            chat:AddMessage ( GRM.L ( "GRM:" ) .. " " .. GRM.L ( "Syncing Data With Guildies Now..." ) .. "\n" .. GRM.L ( "(Loading screens may cause sync to fail)" ) , 1.0 , 0.84 , 0 );
                        end
                    else
                        if not GRMsyncGlobals.firstMessageReceived then
                            GRMsyncGlobals.firstMessageReceived = true;
                            GRM.Report ( GRM.L ( "GRM:" ) .. " " .. GRM.L ( "No Addon Users Currently Compatible for FULL Sync." ) .. "\nCheck the \"Sync Users\" tab to find out why!" );
                            if #GRM_G.currentAddonUsers > 0 and GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] then
                                GRM.Report ( "     " .. GRM.L ( "You will still share some outgoing data with the guild" ) );
                            end
                        end
                    end
                    GRMsyncGlobals.firstSync = false;
                    GRMsync.SendMessage ( "GRM_SYNC" , GRM_G.PatchDayString .. "?GRM_REQJDDATA?" .. GRMsyncGlobals.numGuildRanks .. "?" .. GRMsyncGlobals.SyncQue[1] , GRMsyncGlobals.channelName );
                end
                -- If it fails to sync, after 10 seconds, it retries...
                if not GRM.IsCalendarEventEditOpen() then
                    GuildRoster();
                end
                if not GRMsyncGlobals.errorCheckEnabled then
                    GRMsyncGlobals.errorCheckEnabled = true;
                    C_Timer.After ( GRMsyncGlobals.ErrorCD , GRMsync.ErrorCheck );
                end
            else
                table.remove ( GRMsyncGlobals.SyncQue , 1 );
                GRMsyncGlobals.numSyncAttempts = 0;
                GRMsyncGlobals.currentlySyncing = false;
                GRMsyncGlobals.errorCheckEnabled = false;
                if #GRMsyncGlobals.SyncQue > 0 then
                    GRMsync.InitiateDataSync();
                else
                    GRMsyncGlobals.firstSync = true;
                    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then
                        if GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline() or GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] then
                            chat:AddMessage ( GRM.L ( "GRM:" ) .. " " .. GRM.L ( "Sync With Guildies Complete..." )  , 1.0 , 0.84 , 0 );
                        end
                    end
                    if GRM_UI.GRM_RosterChangeLogFrame.GRM_AuditFrame:IsVisible() then
                        GRM.RefreshAuditFrames( GRM_G.AuditSortType );
                    end
                    if GRM_UI.GRM_RosterChangeLogFrame.GRM_LogFrame:IsVisible() then
                        GRM_G.LogNumbersColorUpdate = true;
                        GRM.BuildLogComplete();
                    end
                end
            end
        end
    end
end

-- Method:          GRMsync.SubmitFinalSyncData()
-- What it Does:    Sends out the mandatory updates to all online (they won't if the change is already there)
-- Purpose:         So leader can send out current, updated sync info.
GRMsync.SubmitFinalSyncData = function()
    GRMsyncGlobals.TimeSinceLastSyncAction = time();
    local msg = "";
    local tempMsg1 = "";
    -- Ok send of the Join Date updates!
    if #GRMsyncGlobals.JDChanges > 0 and not GRMsyncGlobals.finalSyncProgress[1] then
        local joinDate = "";
        local finalTStamp = "";
        local finalEpochStamp = "";
        for i = GRMsyncGlobals.finalSyncDataCount , #GRMsyncGlobals.JDChanges do
            joinDate = ( "Joined: " .. GRMsyncGlobals.JDChanges[i][3] );
            finalTStamp = ( string.sub ( joinDate , 9 ) .. " 12:01am" );
            finalEpochStamp = tostring ( GRM.TimeStampToEpoch ( joinDate , true ) );
            -- Send a change to everyone!
            if GRMsyncGlobals.SyncOK then
                GRMsyncGlobals.finalSyncDataCount = GRMsyncGlobals.finalSyncDataCount + 1;

                msg = GRMsyncGlobals.JDChanges[i][1] .. "?" .. joinDate .. "?" .. finalTStamp .. "?" .. finalEpochStamp .. "?" .. tostring ( GRMsyncGlobals.JDChanges[i][2] ) .. "?none";

                tempMsg1 = GRM_G.PatchDayString .. "?GRM_JDSYNCUP?" .. GRMsyncGlobals.JDChanges[i][4] .. "?" .. tostring ( GRMsyncGlobals.JDChanges[i][5] ) .. "?";

                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMsg1 + #msg + GRMsyncGlobals.sizeModifier;

                GRMsync.SendMessage ( "GRM_SYNC" , tempMsg1 .. msg  , GRMsyncGlobals.channelName );
                -- Do my own changes too if the rank is appropriate...
                if ( GRMsyncGlobals.CurrentSyncPlayerRankID <= GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] and GRMsyncGlobals.CurrentSyncPlayerRankRequirement >= GRMsyncGlobals.CurrentLeaderRankID ) then
                    GRMsync.CheckJoinDateChange ( msg , "" , "GRM_JDSYNCUP" );
                end
                if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                    GRMsyncGlobals.SyncCount = 0;
                    C_Timer.After ( 1 , GRMsync.SubmitFinalSyncData );
                    return;
                end
            end
        end
        GRMsyncGlobals.finalSyncDataCount = 1;
        GRMsyncGlobals.finalSyncProgress[1] = true;
    end
    -- Promo date sync!
    if #GRMsyncGlobals.PDChanges > 0 and not GRMsyncGlobals.finalSyncProgress[2] then
        local promotionDate = "";
        for i = GRMsyncGlobals.finalSyncDataCount , #GRMsyncGlobals.PDChanges do
            promotionDate = ( "Promoted: " .. GRMsyncGlobals.PDChanges[i][3] );
            if GRMsyncGlobals.SyncOK then
                GRMsyncGlobals.finalSyncDataCount = GRMsyncGlobals.finalSyncDataCount + 1;
                
                msg = GRMsyncGlobals.PDChanges[i][1] .. "?" .. promotionDate .. "?" .. tostring ( GRMsyncGlobals.PDChanges[i][2] );

                tempMsg1 = GRM_G.PatchDayString .. "?GRM_PDSYNCUP?" .. GRMsyncGlobals.PDChanges[i][4] .. "?" .. tostring ( GRMsyncGlobals.PDChanges[i][5] ) .. "?";

                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMsg1 + #msg + GRMsyncGlobals.sizeModifier;

                GRMsync.SendMessage ( "GRM_SYNC" , tempMsg1 .. msg , "GUILD"); 
                -- Do my own changes too!
                if ( GRMsyncGlobals.CurrentSyncPlayerRankID <= GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] and GRMsyncGlobals.CurrentSyncPlayerRankRequirement >= GRMsyncGlobals.CurrentLeaderRankID ) then
                    GRMsync.CheckPromotionDateChange ( msg , "" , "GRM_PDSYNCUP" );
                end
                if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                    GRMsyncGlobals.SyncCount = 0;
                    C_Timer.After ( 1 , GRMsync.SubmitFinalSyncData );
                    return;
                end
            end
        end
        GRMsyncGlobals.finalSyncDataCount = 1;
        GRMsyncGlobals.finalSyncProgress[2] = true;
    end
    -- BAN changes sync!
    if #GRMsyncGlobals.BanChanges > 0 and not GRMsyncGlobals.finalSyncProgress[3] then
        for i = GRMsyncGlobals.finalSyncDataCount , #GRMsyncGlobals.BanChanges do
            if GRMsyncGlobals.SyncOK then
                GRMsyncGlobals.finalSyncDataCount = GRMsyncGlobals.finalSyncDataCount + 1;
                
                msg = GRMsyncGlobals.BanChanges[i][1] .. "?" .. tostring ( GRMsyncGlobals.BanChanges[i][2] ) .. "?" .. GRMsyncGlobals.BanChanges[i][3] .. "?" .. GRMsyncGlobals.BanChanges[i][4];

                tempMsg1 = GRM_G.PatchDayString .. "?GRM_BANSYNCUP?" .. GRMsyncGlobals.BanChanges[i][5] .. "?" .. tostring ( GRMsyncGlobals.BanChanges[i][6] ) .. "?" .. tostring ( GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][22] ) .. "?";

                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMsg1 + #msg + GRMsyncGlobals.sizeModifier;

                GRMsync.SendMessage ( "GRM_SYNC" , tempMsg1 .. msg , GRMsyncGlobals.channelName );
                -- Do my own changes too!
                if ( GRMsyncGlobals.CurrentSyncPlayerRankID <= GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] and GRMsyncGlobals.CurrentSyncPlayerRankRequirement >= GRMsyncGlobals.CurrentLeaderRankID ) then                    
                    GRMsync.BanManagementPlayersThatLeft ( msg , "GRM_BANSYNCUP" );
                end
                if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                    GRMsyncGlobals.SyncCount = 0;
                    C_Timer.After ( 1 , GRMsync.SubmitFinalSyncData );
                    return;
                end
            end
        end
        GRMsyncGlobals.finalSyncDataCount = 1;
        GRMsyncGlobals.finalSyncProgress[3] = true;
    end
    -- ALT changes sync for adding alts!
    if #GRMsyncGlobals.AltRemoveChanges > 0 and not GRMsyncGlobals.finalSyncProgress[4] then
        for i = GRMsyncGlobals.finalSyncDataCount , #GRMsyncGlobals.AltRemoveChanges do  -- ( playerName , altName )
            if GRMsyncGlobals.SyncOK then
                GRMsyncGlobals.finalSyncDataCount = GRMsyncGlobals.finalSyncDataCount + 1;

                msg = GRMsyncGlobals.AltRemoveChanges[i][1] .. "?" .. GRMsyncGlobals.AltRemoveChanges[i][2] .. "?" .. tostring ( GRMsyncGlobals.AltRemoveChanges[i][3] );

                tempMsg1 = GRM_G.PatchDayString .. "?GRM_REMSYNCUP?" .. GRMsyncGlobals.AltRemoveChanges[i][4] .. "?" .. tostring ( GRMsyncGlobals.AltRemoveChanges[i][5] ) .. "?";

                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMsg1 + #msg + GRMsyncGlobals.sizeModifier;

                GRMsync.SendMessage ( "GRM_SYNC" , tempMsg1 .. msg , GRMsyncGlobals.channelName );
                -- Do my own changes too!
                if ( GRMsyncGlobals.CurrentSyncPlayerRankID <= GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] and GRMsyncGlobals.CurrentSyncPlayerRankRequirement >= GRMsyncGlobals.CurrentLeaderRankID ) then                    
                    GRMsync.CheckRemoveAltChange ( msg , "" , "GRM_REMSYNCUP" );                    
                end                    
                if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                    GRMsyncGlobals.SyncCount = 0;
                    C_Timer.After ( 1 , GRMsync.SubmitFinalSyncData );
                    return;
                end
            end
        end
        GRMsyncGlobals.finalSyncDataCount = 1;
        GRMsyncGlobals.finalSyncProgress[4] = true;
    end
    -- ALT changes sync for adding alts!
    if #GRMsyncGlobals.AltAddChanges > 0 and not GRMsyncGlobals.finalSyncProgress[5] then
        for i = GRMsyncGlobals.finalSyncDataCount , #GRMsyncGlobals.AltAddChanges do  -- ( playerName , altName )
            if GRMsyncGlobals.SyncOK then
                GRMsyncGlobals.finalSyncDataCount = GRMsyncGlobals.finalSyncDataCount + 1;

                msg = GRMsyncGlobals.AltAddChanges[i][1] .. "?" .. GRMsyncGlobals.AltAddChanges[i][2] .. "?" .. tostring ( GRMsyncGlobals.AltAddChanges[i][3] );

                tempMsg1 = GRM_G.PatchDayString .. "?GRM_ALTSYNCUP?" .. GRMsyncGlobals.AltAddChanges[i][4] .. "?" .. tostring ( GRMsyncGlobals.AltAddChanges[i][5] ) .. "?";

                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMsg1 + #msg + GRMsyncGlobals.sizeModifier;

                GRMsync.SendMessage ( "GRM_SYNC" , tempMsg1 .. msg , GRMsyncGlobals.channelName );
                -- Do my own changes too!
                if ( GRMsyncGlobals.CurrentSyncPlayerRankID <= GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] and GRMsyncGlobals.CurrentSyncPlayerRankRequirement >= GRMsyncGlobals.CurrentLeaderRankID ) then
                    GRMsync.CheckAddAltChange ( msg , "" , "GRM_ALTSYNCUP" );
                end
                if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                    GRMsyncGlobals.SyncCount = 0;
                    C_Timer.After ( 1 , GRMsync.SubmitFinalSyncData );
                    return;
                end
            end
            -- Now my data!
        end
        GRMsyncGlobals.finalSyncDataCount = 1;
        GRMsyncGlobals.finalSyncProgress[5] = true;
    end

    -- MAIN STATUS CHECK!
    if #GRMsyncGlobals.AltMainChanges > 0 and not GRMsyncGlobals.finalSyncProgress[6] then
        for i = GRMsyncGlobals.finalSyncDataCount , #GRMsyncGlobals.AltMainChanges do
            if GRMsyncGlobals.SyncOK then
                GRMsyncGlobals.finalSyncDataCount = GRMsyncGlobals.finalSyncDataCount + 1;

                msg = GRMsyncGlobals.AltMainChanges[i][1] .. "?" .. tostring ( GRMsyncGlobals.AltMainChanges[i][2] ) .. "?" .. tostring ( GRMsyncGlobals.AltMainChanges[i][3] );

                tempMsg1 = GRM_G.PatchDayString .. "?GRM_MAINSYNCUP?" .. GRMsyncGlobals.AltMainChanges[i][4] .. "?" .. tostring ( GRMsyncGlobals.AltMainChanges[i][5] ) .. "?";

                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMsg1 + #msg + GRMsyncGlobals.sizeModifier;

                GRMsync.SendMessage ( "GRM_SYNC" , tempMsg1 .. msg , GRMsyncGlobals.channelName );
                -- Do my own changes too!
                if ( GRMsyncGlobals.CurrentSyncPlayerRankID <= GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] and GRMsyncGlobals.CurrentSyncPlayerRankRequirement >= GRMsyncGlobals.CurrentLeaderRankID ) then
                    GRMsync.CheckMainSyncChange ( msg );
                end
                if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                    GRMsyncGlobals.SyncCount = 0;
                    C_Timer.After ( 1 , GRMsync.SubmitFinalSyncData );
                    return;
                end
            end
        end
        GRMsyncGlobals.finalSyncDataCount = 1;
        GRMsyncGlobals.finalSyncProgress[6] = true;
    end

    -- CUSTOM NOTE CHECK!
    if #GRMsyncGlobals.CustomNoteChanges > 0 and not GRMsyncGlobals.finalSyncProgress[7] then
        for i = GRMsyncGlobals.finalSyncDataCount , #GRMsyncGlobals.CustomNoteChanges do
            if GRMsyncGlobals.SyncOK then
                GRMsyncGlobals.finalSyncDataCount = GRMsyncGlobals.finalSyncDataCount + 1;

                msg = GRMsyncGlobals.CustomNoteChanges[i][4] .. "?" .. GRMsyncGlobals.CustomNoteChanges[i][1] .. "?" .. tostring ( GRMsyncGlobals.CustomNoteChanges[i][2] ) .. "?" .. GRMsyncGlobals.CustomNoteChanges[i][3] .. "?" .. GRMsyncGlobals.CustomNoteChanges[i][5];

                tempMsg1 = GRM_G.PatchDayString .. "?GRM_CUSTSYNCUP?" .. GRMsyncGlobals.CustomNoteChanges[i][6] .. "?" .. tostring ( GRMsyncGlobals.CustomNoteChanges[i][7] ) .. "?";

                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMsg1 + #msg + GRMsyncGlobals.sizeModifier;
                
                GRMsync.SendMessage ( "GRM_SYNC" , tempMsg1 .. msg , GRMsyncGlobals.channelName )
                -- Do my own changes too!
                if ( GRMsyncGlobals.CurrentSyncPlayerRankID <= GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] and GRMsyncGlobals.CurrentSyncPlayerRankRequirement >= GRMsyncGlobals.CurrentLeaderRankID ) then
                    GRMsync.CheckCustomNoteSyncChange ( msg , 0 , false );
                end
                if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                    GRMsyncGlobals.SyncCount = 0;
                    C_Timer.After ( 1 , GRMsync.SubmitFinalSyncData );
                    return;
                end
            end
        end
        GRMsyncGlobals.finalSyncDataCount = 1;
        GRMsyncGlobals.finalSyncProgress[7] = true;
    end

    -- BIRTHDAY CHECK!
    if #GRMsyncGlobals.BDayChanges > 0 and not GRMsyncGlobals.finalSyncProgress[8] then
        for i = GRMsyncGlobals.finalSyncDataCount , #GRMsyncGlobals.BDayChanges do
            if GRMsyncGlobals.SyncOK then
                GRMsyncGlobals.finalSyncDataCount = GRMsyncGlobals.finalSyncDataCount + 1;

                msg = GRMsyncGlobals.BDayChanges[i][1] .. "?" .. tostring ( GRMsyncGlobals.BDayChanges[i][2] ) .. "?" .. tostring ( GRMsyncGlobals.BDayChanges[i][3] ) .. "?" .. GRMsyncGlobals.BDayChanges[i][4] .. "?" .. tostring ( GRMsyncGlobals.BDayChanges[i][5] );

                tempMsg1 = GRM_G.PatchDayString .. "?GRM_BDSYNCUP?" .. GRMsyncGlobals.BDayChanges[i][6] .. "?" .. tostring ( GRMsyncGlobals.BDayChanges[i][7] ) .. "?";

                GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMsg1 + #msg + GRMsyncGlobals.sizeModifier;
                GRMsync.SendMessage ( "GRM_SYNC" , tempMsg1 .. msg , GRMsyncGlobals.channelName )
                -- Do my own changes too!
                if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][68] and ( GRMsyncGlobals.CurrentSyncPlayerRankID <= GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] and GRMsyncGlobals.CurrentSyncPlayerRankRequirement >= GRMsyncGlobals.CurrentLeaderRankID ) then
                    GRMsync.CheckBirthdayChange ( msg , nil , true );
                end
                if GRMsyncGlobals.SyncCount + 254 > GRMsyncGlobals.ThrottleCap then
                    GRMsyncGlobals.SyncCount = 0;
                    C_Timer.After ( 1 , GRMsync.SubmitFinalSyncData );
                    return;
                end
            end
        end
        GRMsyncGlobals.finalSyncDataCount = 1;
        GRMsyncGlobals.finalSyncProgress[8] = true;
    end

    -- Ok all done! Reset the tables!
    GRMsync.ResetReportTables();
    GRMsyncGlobals.finalSyncDataCount = 1;
    GRMsyncGlobals.finalSyncProgress = { false , false , false , false , false , false , false , false };
    -- Do a quick check if anyone else added themselves to the que in the last millisecond, and if so, REPEAT!
    -- Setup repeat here.
    -----------------------------------
    local nameOfCurrentSyncSender = GRMsyncGlobals.SyncQue[1];
    local tempMsg = GRM_G.PatchDayString .. "?GRM_COMPLETE?" .. GRMsyncGlobals.numGuildRanks .. "?" .. nameOfCurrentSyncSender;
    GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMsg + GRMsyncGlobals.sizeModifier;
    GRMsync.SendMessage ( "GRM_SYNC" , tempMsg , GRMsyncGlobals.channelName );

    -- We made it... remove from the syncQue
    table.remove ( GRMsyncGlobals.SyncQue , 1 );
    GRMsyncGlobals.numSyncAttempts = 0;
    if #GRMsyncGlobals.SyncQue > 0 then
        GRMsyncGlobals.currentlySyncing = false;
        GRMsync.InitiateDataSync();
    else
        -- Disable sync again if necessary!
        GRMsync.ReportSyncCompletion ( nameOfCurrentSyncSender , true );
        GRMsyncGlobals.firstSync = true;
    end
end

-- Method:          GRMsync.UpdateLeftPlayerInfo ( string )
-- What it Does:    If a player needs to ban or unban a player, it cannot do so if they are not on their list, as maybe it was a person that left the guild before they had addon installed or before they joined> this fixes the gap
-- Purpose:         To maintain a ban list properly, even for those who installed the addon later, or joined the guild later. The "Left Players" would not have them stored. This syncs that, but ONLY as needed, not all left players
--                  as this prevents left player storage bloat unnecessarily and only syncs the banned or unbanned ones.
GRMsync.UpdateLeftPlayerInfo = function ( msg )
    -- (name , rank, rankID, level , class , leftguilddate, leftguildEpochMeta , oldJoinDate, OldJoinDateMeta)
    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    local leftGuildData = GRM_PlayersThatLeftHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];
    -- Ok, let's check if this player is already known...
    local isFound = false;
    for i = 2 , #leftGuildData do
        if leftGuildData[i][1] == name then
            isFound = true;
            break;
        end
    end

    if not isFound then
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local rank = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local rankID = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local level = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local class = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local leftGuildDate = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local leftGuildMeta = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local oldJoinDate = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        local oldJoinDateMeta = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        local msgTag = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        -- let's build the memberInfoArray!
        -- After class, all info is generic filler info.
        local memberInfo = {
            name,
            rank,
            rankID,
            level,
            "",
            "",
            class,
            1,
            "",
            100,
            false,
            1,
            false,
            0
        }

        GRM.AddMemberToLeftPlayers ( memberInfo , leftGuildDate , leftGuildMeta , oldJoinDate , oldJoinDateMeta , msgTag );
    end
end

-- Method:          GRMsync.UpdateCurrentPlayerInfo ( string )
-- What it Does:    For players that have ban information, and are still currently in the guild, this updates them
-- Purpose:         Some outliers may encounter this situation. This just buttons up the hatches nicely.
GRMsync.UpdateCurrentPlayerInfo = function ( msg )
    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local tag = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
    local timestamp = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
    local reason = string.sub ( msg , string.find ( msg , "?" ) + 1 );

    if tag == "ban" then
        GRM.SyncAddCurrentPlayerBan ( name , timestamp , reason )
    elseif tag == "unban" then
        GRM.SyncRemoveCurrentPlayerBan ( name , timestamp  );
    end

    if GRM_CoreBanListFrame:IsVisible() then
        GRM.RefreshBanListFrames();
    end
end

-- Method:          GRMsync.UpdateCurrentPlayerBanReason ( string )
-- What it Does:    Occasionally a ban reason won't fit on a single string for sync comms, so we send it independently, and this updates it.
-- Purpose:         Sync speed efficiency.
GRMsync.UpdateCurrentPlayerBanReason = function ( msg )
    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    local reason = string.sub ( msg , string.find ( msg , "?" ) + 1 );

    GRM.ChangeCurrentPlayerBanReason ( name , reason );
end

-- Method:          GRMsync.CollectData ( string , string )
-- What it Does:    Collects all of the sync data before analysis.
-- Purpose:         Need to aggregate the data so one only needs to parse through the tables once, rather than on each new piece of info added. Far more efficient.
GRMsync.CollectData = function ( msg , prefix )
    local name = "";
    local timeStampOfChange = 0;
    local addLeftPlayerSubstring = "";
    local banStatus = "";
    local reason = "";

    -- JOIN DATE
    if prefix == "GRM_JDSYNC" then
        local joinDate = "";
        while string.find ( msg , "?" ) ~= nil do
            name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            timeStampOfChange = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );

            if string.find ( msg , "?" ) ~= nil then
                joinDate = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
                msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            else
                joinDate = msg;
            end
            table.insert ( GRMsyncGlobals.JDReceivedTemp , { name , timeStampOfChange , GRMsync.SlimDate ( joinDate ) , GRMsyncGlobals.CurrentSyncPlayer , GRMsyncGlobals.CurrentSyncPlayerRankRequirement } );
        end
    
    -- PROMO DATE
    elseif prefix == "GRM_PDSYNC" then
        local promoDate = "";
        while string.find ( msg , "?" ) ~= nil do
            name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            timeStampOfChange = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );

            if string.find ( msg , "?" ) ~= nil then
                promoDate = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
                msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            else
                promoDate = msg;
            end
            table.insert ( GRMsyncGlobals.PDReceivedTemp , { name , timeStampOfChange , promoDate , GRMsyncGlobals.CurrentSyncPlayer , GRMsyncGlobals.CurrentSyncPlayerRankRequirement } );
        end
    
    -- BAN/UNBAN scan of LEFT players
    elseif prefix == "GRM_BANSYNC" then
        if string.sub( msg , #msg , #msg ) == "?" then
            msg = string.sub ( msg , 1 , #msg - 1 );
        end
        while string.find ( msg , "?" ) ~= nil do
            -- saves me the hassle of debugging that elusive issue... one day.
            if string.sub ( msg , 1 , 1 ) == "?" then
                msg = string.sub ( msg , 2 );
            end
            -- this will be GRM_SYNC2 originally... Need to add the player to left player's list...
            if string.sub ( msg , 1 , 1 ) == "%" then
                addLeftPlayerSubstring = string.sub ( msg , 2 , string.find ( msg , "&" ) - 1 );    -- Starting at 2 eliminates the % symbol.
                GRMsync.UpdateLeftPlayerInfo ( addLeftPlayerSubstring );
                msg = string.sub ( msg , string.find ( msg , "&" ) + 1 );
            end
            if string.sub ( msg , 1 , 1 ) == "&" then
                name = string.sub ( msg , 2 , string.find ( msg , "?" ) - 1 );          -- eliminates the &
            else
                name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
            end
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            timeStampOfChange = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            banStatus = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );

            if string.find ( msg , "?" ) ~= nil then
                reason = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
                msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            else
                reason = msg;
            end
            table.insert ( GRMsyncGlobals.BanReceivedTemp , { name , timeStampOfChange , banStatus , reason , GRMsyncGlobals.CurrentSyncPlayer , GRMsyncGlobals.CurrentSyncPlayerRankRequirement } );
        end

    -- BAN/UNBAN scan of players still in guild.
    elseif prefix == "GRM_BANSYNC2" then
        while string.find ( msg , "?" ) ~= nil do
            name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );          -- eliminates the &
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            timeStampOfChange = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            banStatus = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );

            if string.find ( msg , "?" ) ~= nil then
                reason = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
                msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            else
                reason = msg;
            end
            table.insert ( GRMsyncGlobals.BanReceivedTemp , { name , timeStampOfChange , banStatus , reason , GRMsyncGlobals.CurrentSyncPlayer , GRMsyncGlobals.CurrentSyncPlayerRankRequirement } );
        end

    -- MAIN STATUS
    elseif prefix == "GRM_MAINSYNC" then
        local mainStatus = "";
        local mainResult = false;
        while string.find ( msg , "?" ) ~= nil do
            mainResult = false;
            name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            timeStampOfChange = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );

            if string.find ( msg , "?" ) ~= nil then
                mainStatus = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
                msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            else
                mainStatus = msg;
            end
            -- Let's convert that string to boolean
            if mainStatus == "true" then
                mainResult = true;
            end
            table.insert ( GRMsyncGlobals.MainReceivedTemp , { name , mainResult , timeStampOfChange , GRMsyncGlobals.CurrentSyncPlayer , GRMsyncGlobals.CurrentSyncPlayerRankRequirement } );
        end
    end
end

-- Method:          GRMsync.CollectCustomNoteAction ( string )
-- What it Does:    Collects the custom note sync date from currentsyncplayer
-- Purpose:         To be able to collect for easy parsing the custom note changes on a retroactive sync.
GRMsync.CollectCustomNoteAction = function ( msg )
    local senderControlRankRequirement = 0;
    local playerName = "";
    local timeStampOfChange = 0;
    local noteAuthor = "";
    local customNote = "";

    while string.find ( msg , "?" ) ~= nil and msg ~= "" do
        senderControlRankRequirement = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        if senderControlRankRequirement == nil then
            -- Add DEBUG log here... possible error message...
            return
        end
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        playerName = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        timeStampOfChange = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        noteAuthor = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );

        if string.find ( msg , "?" ) ~= nil then
            customNote = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        else
            customNote = msg;
        end
        table.insert ( GRMsyncGlobals.CustomNoteReceivedTemp , { playerName , timeStampOfChange , noteAuthor , senderControlRankRequirement , customNote , GRMsyncGlobals.CurrentSyncPlayer , GRMsyncGlobals.CurrentSyncPlayerRankRequirement } );
    end    
end

-- Method:          GRMsync.CollectBirthdayData ( string )
-- What it Does:    Collects the Birthday data during a sync
-- Purpose:         For controlling the flow of sync'd data
GRMsync.CollectBirthdayData = function ( msg )
    local name = "";
    local day , month , timestamp;
    local date = "";

    while string.find ( msg , "?" ) ~= nil and msg ~= "" do
        name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        day = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        month = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        date = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );

        if string.find ( msg , "?" ) ~= nil then
            timestamp = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
            msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
        else
            timestamp = tonumber ( msg );
        end

        table.insert ( GRMsyncGlobals.BirthdayReceivedTemp , { name , day , month , date , timestamp , GRMsyncGlobals.CurrentSyncPlayer , GRMsyncGlobals.CurrentSyncPlayerRankRequirement } );
    end
end

-- Method:          GRMsync.CollectAltAddData ( string )
-- What it Does:    Compiles the alt ADD data into a temp file
-- Purpose:         For use of syncing. Need to compile all data from a single player before analyzing it.
GRMsync.CollectAltAddData = function ( msg )
    local name = "";
    local index = -1;
    local timestampResult;
    local altName = "";
    
    -- this is for an edge case...
    if tonumber ( string.sub ( msg , #msg , #msg ) ) == nil then
        msg = msg .. "?0";
    end
    -- First, let's isolate the player...
    while string.find ( msg , "&" ) ~= nil and string.find ( msg , "?" ) ~= nil do -- if only the leader name is sent, but not the alt, we need to break here
        
        if string.sub ( msg , 1 , 1 ) == "&" then
            name = string.sub ( msg , 2 , string.find ( msg , "?" ) - 1 );      -- position 2 eliminates the "&"
        else
            name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        end
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );

        -- Checking to see player is not already added (they shouldn't be, but acts as protection on cross talk on addons in rare circumstances)
        index = -1;
        for i = 1 , #GRMsyncGlobals.AltReceivedTemp do
            if GRMsyncGlobals.AltReceivedTemp[i][1] == name then
                index = i;
                break;
            end
        end

        if index == -1 then
            table.insert ( GRMsyncGlobals.AltReceivedTemp , { name , {} } ); 
        end

        -- Ok, let's see if there are alts to be added!
        if string.sub ( msg , 1 , 1 ) ~= "0" then      
            -- Ok, let's add the alt info!
            -- Player was just added, so you know it is at the end of the table in the last index.
            -- Sets insert point in table.
            if index == -1 then
                index = #GRMsyncGlobals.AltReceivedTemp;
            end

            -- Now parse out the rest of the alts...
            while string.find ( msg , "?" ) ~= nil and string.sub ( msg , 1 , 1 ) ~= "&" do

                
                altName = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
                msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );

                -- This protects against older version from breaking new way alt data is sync'd
                if string.find ( msg , "?" ) == nil then
                    timestampResult = tonumber ( msg );
                else
                    timestampResult = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
                    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
                end
                -- Error Protection
                if timestampResult == nil then
                    timestampResult = 0;
                end
                table.insert ( GRMsyncGlobals.AltReceivedTemp[ index ][2] , { altName , timestampResult } );
            end
        else
            -- No adds, let's move on to the next player...
            if  string.find ( msg , "&" ) ~= nil then
                -- more players are still needed to be parsed from the string.
                -- Parse out the "0?" and leave the "&NAME"
                msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            end
        end
    end
end

-- Method:          GRMsync.CollectAltRemData ( string )
-- What it Does:    Compiles the received data from a player about their alt configurations
-- Purtpose:        For syncing
GRMsync.CollectAltRemData = function ( msg )
    local name = "";
    local index = -1;
    local timestampResult;
    local altName = "";
    if tonumber ( string.sub ( msg , #msg , #msg ) ) == nil then
        msg = msg .. "?0";
    end
    -- First, let's isolate the player...
    while string.find ( msg , "&" ) ~= nil and string.find ( msg , "?" ) ~= nil do
        if string.sub ( msg , 1 , 1 ) == "&" then
            name = string.sub ( msg , 2 , string.find ( msg , "?" ) - 1 );      -- position 2 eliminates the "&"
        else
            name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
        end
        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );

        -- Checking to see player is not already added (they shouldn't be, but acts as protection on cross talk on addons in rare circumstances)
        index = -1;
        for i = 1 , #GRMsyncGlobals.AltRemReceivedTemp do
            if GRMsyncGlobals.AltRemReceivedTemp[i][1] == name then
                index = i;
                break;
            end
        end

        if index == -1 then
            table.insert ( GRMsyncGlobals.AltRemReceivedTemp , { name , {} } ); 
        end

        -- Ok, let's see if there are alts to be added!
        if string.sub ( msg , 1 , 1 ) ~= "0" then      
            -- Ok, let's add the alt info!
            -- Player was just added, so you know it is at the end of the table in the last index.
            -- Sets insert point in table.
            if index == -1 then
                index = #GRMsyncGlobals.AltRemReceivedTemp;
            end

            -- Now parse out the rest of the alts...
            while string.find ( msg , "?" ) ~= nil and string.sub ( msg , 1 , 1 ) ~= "&" do
                altName = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
                msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );

                -- This protects against older version from breaking new way alt data is sync'd
                if string.find ( msg , "?" ) == nil then
                    timestampResult = tonumber ( msg );
                else
                    timestampResult = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
                    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
                end

                -- Error Protection
                if timestampResult == nil then
                    timestampResult = 0;
                end
                table.insert ( GRMsyncGlobals.AltRemReceivedTemp[ index ][2] , { altName , timestampResult } );
            end
        else
            -- No adds, let's move on to the next player...
            if  string.find ( msg , "&" ) ~= nil then
                -- more players are still needed to be parsed from the string.
                -- Parse out the "0?" and leave the "&NAME"
                msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
            end
        end
    end
end

-- PROBLEM -- Removed alt is removing each individual previous alt rather than the alts removing him...
-- Method:          GRMsync.AddToProperAltTable ( string , string , int , boolean )
-- What it Does:    Verifies that the alt needs to be added to the finalized data... or removed.
-- Purpose:         Sync control for alt management.                                                                    ----- HUGE ERROR!!! I AM NOT CHECKING FINAL TABLES< ONLY INITIAL TEMP TABLES!!! NEED TO FIX!!!!!!!
GRMsync.AddToProperAltTable = function ( name , altName , timeStamp , toAddAlt , syncName , syncRankRestrictID )
    local needsAdding = true;
    local isAlreadyAdded = false;
    -- POSSIBLY ADDING!
    if toAddAlt then
    -- If I am going to add it, then make sure it is not on the finalized Remove table, and if it is, compare timestamps
    -- if it IS to be added to the final ADD table, then ensure it is not already there as well!
        if #GRMsyncGlobals.AltRemoveChanges > 0 then
            for i = 1 , #GRMsyncGlobals.AltRemoveChanges do
                if ( GRMsyncGlobals.AltRemoveChanges[i][1] == name and GRMsyncGlobals.AltRemoveChanges[i][2] == altName ) or ( GRMsyncGlobals.AltRemoveChanges[i][1] == altName and GRMsyncGlobals.AltRemoveChanges[i][2] == name ) then
                    -- Ok, match is found! We need to check timestamps now!
                    if timeStamp < GRMsyncGlobals.AltRemoveChanges[i][3] then
                        -- This means that the player set to be added is actually set to be removed by a more recent entry!
                        needsAdding = false;
                    else
                        -- Since it was found in the table, and the incoming data is more recent, then it also needs to be removed from the removeChanges table because it needs to be added...
                        table.remove ( GRMsyncGlobals.AltRemoveChanges , i );
                    end
                    break;
                end
            end
        end

        -- Confirmed, it is definitely a change to be added!
        if needsAdding then
            -- Before we add it, let's first verify it is not already in the table!
            if #GRMsyncGlobals.AltAddChanges > 0 then
                for i = 1 , #GRMsyncGlobals.AltAddChanges do
                    if GRMsyncGlobals.AltAddChanges[i][1] == name and GRMsyncGlobals.AltAddChanges[i][2] == altName then
                        -- Player info has already been determined through scanning another player's update info!
                        isAlreadyAdded = true;
                        break;
                    end
                end
            end

            if not isAlreadyAdded then
                -- Add it here!
                table.insert ( GRMsyncGlobals.AltAddChanges , { name , altName , timeStamp , syncName , syncRankRestrictID } );
            end
        end

    -- POSSIBLY REMOVING!
    else
    -- If it is to be removed, ensure it is not already on the ADD table, and if it is, compare timestamps.
    -- IF it IS certain to be removed, ensure that it is not already on the Remove table to avoid double adds.
        if #GRMsyncGlobals.AltAddChanges > 0 then
            for i = 1 , #GRMsyncGlobals.AltAddChanges do
                if ( GRMsyncGlobals.AltAddChanges[i][1] == name and GRMsyncGlobals.AltAddChanges[i][2] == altName ) or ( GRMsyncGlobals.AltAddChanges[i][1] == altName and GRMsyncGlobals.AltAddChanges[i][2] == name ) then
                    -- Ok, match is found! We need to check timestamps now!
                    if timeStamp < GRMsyncGlobals.AltAddChanges[i][3] then
                        -- This means that the player set to be added is actually set to be removed by a more recent entry!
                        needsAdding = false;
                    else
                        -- Since it was found in the table, and the incoming data is more recent, then it also needs to be removed from the removeChanges table
                        table.remove ( GRMsyncGlobals.AltAddChanges , i );
                    end
                    break;
                end
            end
        end

         -- Confirmed, it is definitely a change to be added to REMOVE table
        if needsAdding then
            -- Before we add it, let's first verify it is not already in the table!
            
            if #GRMsyncGlobals.AltRemoveChanges > 0 then
                for i = 1 , #GRMsyncGlobals.AltRemoveChanges do
                    if GRMsyncGlobals.AltRemoveChanges[i][1] == name and GRMsyncGlobals.AltRemoveChanges[i][2] == altName then
                        -- Player info has already been determined through scannign another player's update info!
                        isAlreadyAdded = true;
                        break;
                    end
                end
            end

            if not isAlreadyAdded then
                -- Add it here!
                table.insert ( GRMsyncGlobals.AltRemoveChanges , { name , altName , timeStamp , syncName , syncRankRestrictID } );
            end
        end
    end
end

-- Method:          GRMsync.CheckingJDChanges ( int , int )
-- What it Does:    After receiving ALL of the Join date data, it parses through and checks for new updates/changes
-- Purpose:         For syncing the data properly to people if update is needed!
GRMsync.CheckingJDChanges = function ( currentTime , syncRankFilter )
    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];
    -- Reminder: GRMsyncGlobals.JDReceivedTemp[i] = { name , timeStampOfChange , GRMsync.SlimDate ( joinDate ) , GRMsyncGlobals.CurrentSyncPlayer , GRMsyncGlobals.CurrentSyncPlayerRankRequirement
    local isFound = false;
    for j = 2 , #guildData do
        isFound = false;
        for i = 1 , #GRMsyncGlobals.JDReceivedTemp do
            if guildData[j][1] == GRMsyncGlobals.JDReceivedTemp[i][1] then
                isFound = true;
                -- Ok player identified, now let's compare data.
                local parsedDate = GRMsync.SlimDate ( guildData[j][35][1] );
                if parsedDate ~= GRMsyncGlobals.JDReceivedTemp[i][3] then
                    -- Player dates don't match! Let's compare timestamps to see how made the most recent change, then sync data to that!
                    
                    local addReceived = false;      -- AM I going to add received data, or my own. One or the other needs to be added for sync
                    if ( currentTime - guildData[j][35][2] ) > ( currentTime - GRMsyncGlobals.JDReceivedTemp[i][2] ) then
                        -- Received Data happened more recently! Need to update change!
                        addReceived = true;         -- In other words, don't add my own data, add the received data.
                    end

                    -- Setting the change data properly.
                    local changeData;
                    -- Adding Received from other player
                    if addReceived then
                        changeData = GRMsyncGlobals.JDReceivedTemp[i];
                    
                    -- Adding my own data, as it is more current
                    else
                        changeData = { guildData[j][1] , guildData[j][35][2] , parsedDate , GRMsyncGlobals.DesignatedLeader , syncRankFilter };
                    end

                    -- Need to check if change has not already been added, or if another player added info that is more recent! (Might need review for increased performance)
                    local needToAdd = true;
                    for r = 1 , #GRMsyncGlobals.JDChanges do
                        if changeData[1] == GRMsyncGlobals.JDChanges[r][1] then
                            -- If dates are the same, no need to change em!
                            if changeData[2] <= GRMsyncGlobals.JDChanges[r][2] then
                                needToAdd = false;
                            end

                            -- If needToAdd is still true, then we need to remove the old index.
                            if needToAdd then
                                table.remove ( GRMsyncGlobals.JDChanges , r );
                            end
                        end
                    end

                    -- Now let's add it!
                    if needToAdd then
                        table.insert ( GRMsyncGlobals.JDChanges , changeData );
                    end
                end
                break;
            end
        end
        if not isFound and guildData[j][35][2] ~= 0 and guildData[j][35][1] ~= "" then
            table.insert ( GRMsyncGlobals.JDChanges , { guildData[j][1] , guildData[j][35][2] , GRMsync.SlimDate ( guildData[j][35][1] ) , GRMsyncGlobals.DesignatedLeader , syncRankFilter } );
        end
    end
    -- Wiping the temp file!
    -- From here, request should be sent out for PDSYNC!
    GRMsyncGlobals.JDReceivedTemp = {};
end

-- Method:          GRMsync.CheckingPDChanges ( int , int )
-- What it Does:    After receiving ALL of the promo date data, it parses through and checks for new updates/changes
-- Purpose:         For syncing the data properly to people if update is needed!
GRMsync.CheckingPDChanges = function ( currentTime , syncRankFilter )
    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

    for i = 1 , #GRMsyncGlobals.PDReceivedTemp do
        for j = 2 , #guildData do
            if guildData[j][1] == GRMsyncGlobals.PDReceivedTemp[i][1] then
                if guildData[j][36][1] ~= GRMsyncGlobals.PDReceivedTemp[i][3] then

                    local addReceived = false;      -- AM I going to add received data, or my own. One or the other needs to be added for sync
                    if ( currentTime - guildData[j][36][2] ) > ( currentTime - GRMsyncGlobals.PDReceivedTemp[i][2] ) then
                        -- Received Data happened more recently! Need to update change!
                        addReceived = true;         -- In other words, don't add my own data, add the received data.
                    end

                    -- Setting the change data properly.
                    local changeData;
                    -- Adding Received from other player
                    if addReceived then
                        changeData = GRMsyncGlobals.PDReceivedTemp[i];
                    
                    -- Adding my own data, as it is more current
                    else
                        changeData = { guildData[j][1] , guildData[j][36][2] , guildData[j][36][1] , GRMsyncGlobals.DesignatedLeader , syncRankFilter };
                    end

                    -- Need to check if change has not already been added, or if another player added info that is more recent! (Might need review for increased performance)
                    local needToAdd = true;
                    for r = 1 , #GRMsyncGlobals.PDChanges do
                        if changeData[1] == GRMsyncGlobals.PDChanges[r][1] then
                            -- If dates are the same, no need to change em!
                            if changeData[2] <= GRMsyncGlobals.PDChanges[r][2] then
                                needToAdd = false;
                            end

                            -- If needToAdd is still true, then we need to remove the old index.
                            if needToAdd then
                                table.remove ( GRMsyncGlobals.PDChanges , r );
                            end
                        end
                    end

                    -- If needToAdd is still true, then we need to remove the old index.
                    if needToAdd then
                        table.insert ( GRMsyncGlobals.PDChanges , changeData );
                    end
                end
                break;
            end
        end
    end
    -- Wipe the data!
    GRMsyncGlobals.PDReceivedTemp = {};
end

-- Method:          GRMsync.CheckingBANChanges ( int , int )
-- What it Does:    After receiving ALL of the Ban info, it parses through and checks for new updates/changes
-- Purpose:         For syncing the data properly to people if update is needed!
GRMsync.CheckingBANChanges = function ( currentTime , syncRankFilter )
    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];
    local leftGuildData = GRM_PlayersThatLeftHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

    -- Skip this all if player restrict ban list sync
    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][21] then -- { name , timeStampOfBanChange , banStatus , reason }
        local isFound;
        -- Let's check my own changes now...
        -- First, left players...
        local tag = "";
        local reason = "";
        local tempReasonForLength = "";
        for i = 2 , #leftGuildData do
            isFound = false;
            if leftGuildData[i][17][1] or leftGuildData[i][17][3] then  -- if banned or unbanned is on my playersThatLeft...
                if leftGuildData[i][17][1] then
                    tag = "ban";
                elseif leftGuildData[i][17][3] then
                    tag = "unban";
                end
                
                for j = 1 , #GRMsyncGlobals.BanReceivedTemp do
                    if leftGuildData[i][1] == GRMsyncGlobals.BanReceivedTemp[j][1] then
                        isFound = true;
                        -- No need to carry on...
                        break;
                    end
                end

                if not isFound then
                    -- Player was not found on the ban list
                    reason = leftGuildData[i][18];
                    if reason == "" then
                        reason = GRM.L ( "No Reason Given" );
                    end
                    if tag == "ban" or tag == "unban" then
                        table.insert ( GRMsyncGlobals.BanReceivedTemp , { leftGuildData[i][1] , 0 , "noban" , reason } );
                    end
                    -- Send request to ADD player w/ban or unban status.
                    local tempMessage = GRM_G.PatchDayString .. "?GRM_ADDLEFT?" .. GRMsyncGlobals.numGuildRanks .. "?" .. leftGuildData[i][1] .. "?" .. leftGuildData[i][4] .. "?" .. tostring ( leftGuildData[i][5] ) .. "?" .. tostring ( leftGuildData[i][6] ) .. "?" .. leftGuildData[i][9] .. "?" .. leftGuildData[i][15][#leftGuildData[i][15]] .. "?" .. tostring ( leftGuildData[i][16][#leftGuildData[i][16]] ) .. "?" .. leftGuildData[i][2] .. "?" .. tostring ( leftGuildData[i][3] .. "?" .. tag );
                    GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMessage + GRMsyncGlobals.sizeModifier + 254;
                    GRMsync.SendMessage ( "GRM_SYNC" , tempMessage , GRMsyncGlobals.channelName );    -- (name , rank, rankID, level , class , leftguilddate, leftguildEpochMeta , oldJoinDate, OldJoinDateMeta , banStatus)
                    
                    if GRMsyncGlobals.SyncCount > GRMsyncGlobals.ThrottleCap then
                        GRMsyncGlobals.SyncCount = 0;      -- Resets this and we will recheck.
                        C_Timer.After ( 1 , function()
                            GRMsync.CheckingBANChanges ( currentTime , syncRankFilter );
                        end);
                        return;
                    end
                end
            end
        end

        -- Now, let's check current players!
        for i = GRMsyncGlobals.BanCount , #guildData do
            isFound = false;
            
            if guildData[i][17][1] or guildData[i][17][3] then  -- if banned or unbanned is on my playersThatLeft...
                if guildData[i][17][1] then
                    tag = "ban";
                elseif guildData[i][17][3] then
                    tag = "unban";
                end
                for j = 1 , #GRMsyncGlobals.BanReceivedTemp do
                    if guildData[i][1] == GRMsyncGlobals.BanReceivedTemp[j][1] then
                        isFound = true;
                        -- No need to carry on...
                        break;
                    end
                end

                if not isFound then
                    reason = guildData[i][18];
                    if reason == "" then
                        reason = GRM.L ( "No Reason Given" );
                    end
                    -- Player was not found on the ban list
                    tempReasonForLength = GRM_G.PatchDayString .. "?GRM_ADDCUR?" .. GRMsyncGlobals.numGuildRanks .. "?" .. tostring ( GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][22] ) .. "?" .. guildData[i][1] .. "?" .. tag .. "?" .. tostring ( guildData[i][17][2] ) .. "?";

                    if ( #tempReasonForLength + #reason + 8 ) >= 255 then -- 8 represents the GRM_SYNC Prefix length
                        -- We need to snip off the reason partially to shorten it...
                        table.insert ( GRMsyncGlobals.tempListForLongReason , GRM_G.PatchDayString .. "?GRM_RSN?" .. GRMsyncGlobals.numGuildRanks .. "?" .. tostring ( GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][22] ) .. "?" .. guildData[i][1] .. reason );

                        -- elminate the reason, we'll send the full one in a moment.
                        reason = GRM.L ( "No Reason Given" );
                    end
                    -- Send request to ADD player w/ban or unban status.
                    
                    local tempMessage = tempReasonForLength .. reason;
                    GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #tempMessage + GRMsyncGlobals.sizeModifier + 254;
                    GRMsync.SendMessage ( "GRM_SYNC" , tempMessage , GRMsyncGlobals.channelName );    -- (name , ban/unban , timestamp of ban change)
                    if GRMsyncGlobals.SyncCount > GRMsyncGlobals.ThrottleCap then
                        GRMsyncGlobals.SyncCount = 254; -- to account for auto sending 1. Little wiggle cushion room here.
                        GRMsyncGlobals.BanCount = i + 1;
                        C_Timer.After ( 1 , function()
                            GRMsync.CheckingBANChanges ( currentTime , syncRankFilter );
                        end);
                        return;
                    end
                end
            end
        end

        -- Ok, now the BanReceivedTemp list is complete, and player properly added to LeftPlayer's list if necessary.
        for i = 1 , #GRMsyncGlobals.BanReceivedTemp do
            isFound = false;
            for j = 2 , #leftGuildData do
                if leftGuildData[j][1] == GRMsyncGlobals.BanReceivedTemp[i][1] then
                    isFound = true;
                    -- Let's first check if they have diff. info.
                    if GRMsyncGlobals.BanReceivedTemp[i][3] ~= "noban" or ( GRMsyncGlobals.BanReceivedTemp[i][3] == "noban" and ( leftGuildData[j][17][1] or leftGuildData[j][17][3] ) ) then
                        local banStatus = false;
                        if GRMsyncGlobals.BanReceivedTemp[i][3] == "ban" then
                            banStatus = true;
                        end
                        if banStatus ~= leftGuildData[j][17][1] then
                            
                            local addReceived = false;      -- AM I going to add received data, or my own. One or the other needs to be added for sync
                            if leftGuildData[j][17][2] < GRMsyncGlobals.BanReceivedTemp[i][2] then
                                -- Received Data happened more recently! Need to update change!
                                addReceived = true;         -- In other words, don't add my own data, add the received data.
                            end

                            local changeData;
                            -- Adding Received from other playerZ--[[z]]
                            if addReceived then
                                changeData = GRMsyncGlobals.BanReceivedTemp[i];
                            
                            -- Adding my own data, as it is more current
                            else
                                local msgTag = "ban";
                                if leftGuildData[j][17][3] then
                                    msgTag = "unban"
                                end
                                changeData = { leftGuildData[j][1] , leftGuildData[j][17][2] , msgTag , leftGuildData[j][18] , GRMsyncGlobals.DesignatedLeader , syncRankFilter };
                            end
                            
                            -- Let's see if already indexed by another player!
                            local needToAdd = true;
                            for r = 1 , #GRMsyncGlobals.BanChanges do
                                if changeData[1] == GRMsyncGlobals.BanChanges[r][1] then
                                    -- If bans are going to be the same, no need to change!
                                    if changeData[3] == GRMsyncGlobals.BanChanges[r][3] or ( currentTime - changeData[2] ) > ( currentTime - GRMsyncGlobals.BanChanges[2] ) then -- If difference found, but the other change was more recent, no need to add.
                                        needToAdd = false;
                                    end

                                    -- If needToAdd is still true, then we need to remove the old index.
                                    if needToAdd then
                                        table.remove ( GRMsyncGlobals.BanChanges , r );
                                    end
                                end
                            end
                            
                            -- If needToAdd is still true, then we need to remove the old index.
                            if needToAdd then
                                table.insert ( GRMsyncGlobals.BanChanges , changeData );
                            end
                        end
                    end
                    break;
                end
            end

            -- if not IsFound then...
            if not isFound then
                for j = 2 , #guildData do
                    if guildData[j][1] == GRMsyncGlobals.BanReceivedTemp[i][1] then
                        isFound = true;
                        -- Let's first check if they have diff. info.
                        if GRMsyncGlobals.BanReceivedTemp[i][3] ~= "noban" or ( GRMsyncGlobals.BanReceivedTemp[i][3] == "noban" and ( guildData[j][17][1] or guildData[j][17][3] ) ) then
                            local banStatus = false;
                            if GRMsyncGlobals.BanReceivedTemp[i][3] == "ban" then
                                banStatus = true;
                            end

                            if banStatus ~= guildData[j][17][1] then
                                local addReceived = false;      -- AM I going to add received data, or my own. One or the other needs to be added for sync
                                if ( currentTime - guildData[j][17][2] ) > ( currentTime - GRMsyncGlobals.BanReceivedTemp[i][2] ) then
                                    -- Received Data happened more recently! Need to update change!
                                    addReceived = true;         -- In other words, don't add my own data, add the received data.
                                end

                                local changeData;
                                -- Adding Received from other playerZ--[[z]]
                                if addReceived then
                                    changeData = GRMsyncGlobals.BanReceivedTemp[i];
                                
                                -- Adding my own data, as it is more current
                                else
                                    local msgTag = "ban";
                                    if guildData[j][17][3] then
                                        msgTag = "unban"
                                    end
                                    changeData = { guildData[j][1] , guildData[j][17][2] , msgTag , guildData[j][18] , GRMsyncGlobals.DesignatedLeader , syncRankFilter };
                                end
                                -- Let's see if already indexed by another player!
                                local needToAdd = true;
                                for r = 1 , #GRMsyncGlobals.BanChanges do
                                    if changeData[1] == GRMsyncGlobals.BanChanges[r][1] then
                                        -- If bans are going to be the same, no need to change!
                                        if changeData[3] == GRMsyncGlobals.BanChanges[r][3] or ( currentTime - changeData[2] ) > ( currentTime - GRMsyncGlobals.BanChanges[2] ) then -- If difference found, but the other change was more recent, no need to add.
                                            needToAdd = false;
                                        end

                                        -- If needToAdd is still true, then we need to remove the old index.
                                        if needToAdd then
                                            table.remove ( GRMsyncGlobals.BanChanges , r );
                                        end
                                    end
                                end

                                -- If needToAdd is still true, then we need to remove the old index.
                                if needToAdd then
                                    table.insert ( GRMsyncGlobals.BanChanges , changeData );
                                end
                            end
                        end
                        break;
                    end
                end
            end
        end

        -- Ok send comms for the lengthy reasons...
        GRMsync.tempListLongReasonManagement();

        GRMsyncGlobals.BanReceivedTemp = {};
        GRMsyncGlobals.BanCount = 2;
    else
        GRMsyncGlobals.BanReceivedTemp = {};
    end
end

-- Method:          GRMsync.tempListLongReasonManagement()
-- What it Does:    For lengthy comms, due to the limit, they are broken up into this array and sent at the end
-- Purpose:         To allow lengthy input on the Ban reasons...
GRMsync.tempListLongReasonManagement = function()
    for i = GRMsyncGlobals.BanListLongCount , #GRMsyncGlobals.tempListForLongReason do
        GRMsyncGlobals.SyncCount = GRMsyncGlobals.SyncCount + #GRMsyncGlobals.tempListForLongReason[i] + GRMsyncGlobals.sizeModifier;
        if GRMsyncGlobals.SyncCount > GRMsyncGlobals.ThrottleCap then
            GRMsyncGlobals.SyncCount = 0;
            GRMsyncGlobals.BanListLongCount = i;
            C_Timer.After ( 1 , function()
                GRMsync.tempListLongReasonManagement();
            end);
            return;
        else
            GRMsync.SendMessage ( "GRM_SYNC" , GRMsyncGlobals.tempListForLongReason[i] , GRMsyncGlobals.channelName );
        end
    end
    GRMsyncGlobals.BanListLongCount = 1;
    GRMsyncGlobals.tempListForLongReason = {};
end

-- Method:          GRMsync.CheckingMAINChanges ( int , int )
-- What it Does:    After receiving ALL of the Main info, it parses through and checks for new updates/changes
-- Purpose:         For syncing the data properly to people if update is needed!
GRMsync.CheckingMAINChanges = function ( currentTime , syncRankFilter )
    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

    for i = 1 , #GRMsyncGlobals.MainReceivedTemp do
        for j = 2 , #guildData do
            if guildData[j][1] == GRMsyncGlobals.MainReceivedTemp[i][1] then
                -- Alright, now let's see if our data matches up!
                if guildData[j][10] ~= GRMsyncGlobals.MainReceivedTemp[i][2] then
                    -- If it does, then do nothing... however, if it does, do the following...
                    local addReceived = false;      -- AM I going to add received data, or my own. One or the other needs to be added for sync

                    if ( currentTime - guildData[j][39] ) > ( currentTime - GRMsyncGlobals.MainReceivedTemp[i][3] ) then
                        addReceived = true;         -- In other words, don't add my own data, add the received data.
                    end

                    local changeData;
                    -- Adding Received from other player
                    if addReceived then
                        changeData = GRMsyncGlobals.MainReceivedTemp[i];
                        -- Adding my own data, as it is more current
                    else
                        changeData = { guildData[j][1] , guildData[j][10] , guildData[j][39] , GRMsyncGlobals.DesignatedLeader , syncRankFilter };
                    end

                    -- Need to check if change has not already been added, or if another player added info that is more recent! (Might need review for increased performance)
                    local needToAdd = true;
                    for r = 1 , #GRMsyncGlobals.AltMainChanges do
                        if changeData[1] == GRMsyncGlobals.AltMainChanges[r][1] then        -- Player matched! Already added to the "Main" table!
                            -- If main status is the same, no need to change em!
                            if changeData[2] == GRMsyncGlobals.AltMainChanges[r][2] or ( currentTime - changeData[3] ) > ( currentTime - GRMsyncGlobals.AltMainChanges[3] ) then
                                needToAdd = false;
                            end

                            -- If needToAdd is still true, then we need to remove the old index.
                            if needToAdd then
                                table.remove ( GRMsyncGlobals.AltMainChanges , r );
                            end
                        end
                    end

                    -- Now let's add it!
                    if needToAdd then
                        table.insert ( GRMsyncGlobals.AltMainChanges , changeData );
                    end
                end                        
                break;
            end
        end
    end

    -- Now, let's purge repeats, as only 1 of an alt-grouping needs to be modified.
    local listToRemove = {};

    for i = 1 , #GRMsyncGlobals.AltMainChanges do                                                                                                                                       -- Cycle through all results.
        if GRMsyncGlobals.AltMainChanges[i][2] then                -- Only need to cycle through the alts where they are set to be listed as main, not demoted.
            for j = 2 , #guildData do                                                                             -- Let's cycle through the metadata!
                if guildData[j][1] == GRMsyncGlobals.AltMainChanges[i][1] then                                    -- player found!
                    local altList = guildData[j][11];
                    -- Now that I have the altList, I should see if any of them match this main
                    for r = 1 , #altList do
                        for s = 1 , #GRMsyncGlobals.AltMainChanges do
                            if altList[r][1] == GRMsyncGlobals.AltMainChanges[s][1] then
                                table.insert ( listToRemove , altList[r][1] );

                                break;
                            end
                        end
                    end
                    
                    break;
                end
            end
        end
    end
    -- Let's purge the changes!
    while #listToRemove > 0 do
        for i = 1 , #GRMsyncGlobals.AltMainChanges do
            if GRMsyncGlobals.AltMainChanges[i][1] == listToRemove[1] then
                table.remove ( GRMsyncGlobals.AltMainChanges , i );
                break;
            end
        end
        table.remove ( listToRemove , 1 );
    end
    
    -- Resetting the temp tables!
    GRMsyncGlobals.MainReceivedTemp = {};
end


-- Method:          GRMsync.CheckingCustomNoteChanges ( int , int )
-- What it Does:    After receiving ALL of the CustomNote info, it parses through and checks for new updates/changes
-- Purpose:         For syncing the data properly to people if update is needed!
GRMsync.CheckingCustomNoteChanges = function ( syncRankFilter )
    local tempGuild = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

    for i = 1 , #GRMsyncGlobals.CustomNoteReceivedTemp  do
        for j = 2 , #tempGuild do
            if tempGuild[j][1] == GRMsyncGlobals.CustomNoteReceivedTemp[i][1] then
                if tempGuild[j][23][6] ~= GRMsyncGlobals.CustomNoteReceivedTemp[i][3] then

            
                    local addReceived = false;      -- AM I going to add received data, or my own. One or the other needs to be added for sync
                    if ( tempGuild[j][23][2] > GRMsyncGlobals.CustomNoteReceivedTemp[i][2] ) or not tempGuild[j][23][1] then
                        -- Received Data happened more recently! Need to update change!
                        addReceived = true;         -- In other words, don't add my own data, add the received data.
                    end

                    -- Setting the change data properly.
                    local changeData;
                    -- Adding Received from other player
                    -- 
                    if addReceived then
                        changeData = GRMsyncGlobals.CustomNoteReceivedTemp[i];
                    -- Adding my own data, as it is more current
                    else
                        changeData = { tempGuild[j][1] , tempGuild[j][23][2] , tempGuild[j][23][3] , tempGuild[j][23][4] , tempGuild[j][23][6] , GRMsyncGlobals.DesignatedLeader , syncRankFilter };
                    end

                    -- Need to check if change has not already been added, or if another player added info that is more recent! (Might need review for increased performance)
                    local needToAdd = true;
                    for r = 1 , #GRMsyncGlobals.CustomNoteChanges do
                        if changeData[1] == GRMsyncGlobals.CustomNoteChanges[r][1] then
                            -- If dates are the same, no need to change em!
                            if changeData[2] <= GRMsyncGlobals.CustomNoteChanges[r][2] then
                                needToAdd = false;
                            end

                            -- If needToAdd is still true, then we need to remove the old index.
                            if needToAdd then
                                table.remove ( GRMsyncGlobals.CustomNoteChanges , r );
                            end
                        end
                    end

                    -- If needToAdd is still true, then we need to remove the old index.
                    if needToAdd then
                        table.insert ( GRMsyncGlobals.CustomNoteChanges , changeData );
                    end
                end
                break;
            end
        end
    end
    -- Now, let's add my own data.
    local isFound;
    for j = 2 , #tempGuild do
        -- ensure this data should be shared in the first place
        if tempGuild[j][23][1] and tempGuild[j][23][2] ~= 0 then
            isFound = false;
            -- Let's see if the player is already in there...
            for i = 1 , #GRMsyncGlobals.CustomNoteChanges do
                if tempGuild[j][1] == GRMsyncGlobals.CustomNoteChanges[i][1] then
                    isFound = true;
                    break;
                end
            end

            -- If player was not already added, then let's go ahead and add right here.
            if not isFound then
                table.insert ( GRMsyncGlobals.CustomNoteChanges , { tempGuild[j][1] , tempGuild[j][23][2] , tempGuild[j][23][3] , tempGuild[j][23][4] , tempGuild[j][23][6] , GRMsyncGlobals.DesignatedLeader , syncRankFilter } );
            end
        end
    end
    -- guildData = tempGuild;
    GRMsyncGlobals.CustomNoteReceivedTemp = {};
end

-- Method:          GRMsync.CheckingBdayChanges ( int )
-- What it Does:    Establishes what needs to be kept and what needs to be removed
-- Purpose:         Controlling the flow of the sync info!
GRMsync.CheckingBdayChanges = function ( syncRankFilter )
    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];
    local changeData = {};
    local isFound = false;
    local needToAddMyData = false;
    local list = GRM.GetAllGuildiesInOrder ( true , true );

    -- No need to check my data if I am not going to share it. I must just accept their data and pass it along. I just wont' absorb it and then people will rely on their filters.
    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][68] then
        -- Just checking my own data first...
        for j = 2 , #guildData do
            for i = 1 , #list do
                if guildData[j][1] == list[i] then
                    if guildData[j][22][2][1][1] ~= 0 then       -- Birthday set!
                        -- Cleanup the list to save on additional parses
                        list = GRMsync.RemoveAltGroupingFromList ( guildData[j][1] , guildData[j][11] , list );
                        -- Reset this data for the loop find.
                        changeData = {};
                        isFound = false;
                        needToAddMyData = false;
                        -- Now, let's see what is best data. Mine, or received player's
                        for i = 1 , #GRMsyncGlobals.BirthdayReceivedTemp do
                            if guildData[j][1] == GRMsyncGlobals.BirthdayReceivedTemp[i][1] then
                                -- Let's check who has more current data...
                                isFound = true;
                                if guildData[j][22][2][4] >= GRMsyncGlobals.BirthdayReceivedTemp[i][5] then     -- syncLeader Data more current, though both had birthdays set...
                                    if guildData[j][22][2][4] > GRMsyncGlobals.BirthdayReceivedTemp[i][5] then
                                        needToAddMyData = true;
                                    end
                                else
                                    changeData = GRMsyncGlobals.BirthdayReceivedTemp[i];
                                end
                                table.remove ( GRMsyncGlobals.BirthdayReceivedTemp , i );-- We've dealt with this now and it can be removed.
                                break;
                            end
                        end
                        -- If my data has a birthdate, but I have not seen any from other players...
                        if not isFound or needToAddMyData then
                            -- Do an altName check
                            local isFound = false;
                            for k = 1 , #guildData[j][11] do
                                isFound = false;
                                for m = 1 , #GRMsyncGlobals.BirthdayReceivedTemp do
                                    if guildData[j][11][k][1] == GRMsyncGlobals.BirthdayReceivedTemp[m][1] then
                                        -- Alt Name Found in temp database!
                                        isFound = true;
                                        break;
                                    end
                                end
                                if isFound then
                                    break;
                                end
                            end
                            if not isFound then
                                changeData = { guildData[j][1] , guildData[j][22][2][1][1] , guildData[j][22][2][1][2] , guildData[j][22][2][3] , guildData[j][22][2][4] , GRMsyncGlobals.DesignatedLeader , syncRankFilter };
                            end
                        end

                        if #changeData ~= 0 then
                            table.insert ( GRMsyncGlobals.BDayChanges , changeData );
                        end
                    end

                    break;
                end
            end
        end

        -- Now check the received
        for i = 1 , #GRMsyncGlobals.BirthdayReceivedTemp do
            for j = 2 , #guildData do
                if guildData[j][1] == GRMsyncGlobals.BirthdayReceivedTemp[i][1] then
                    needToAddMyData = false;
                    changeData = {};

                    if guildData[j][22][2][1][1] ~= 0 and guildData[j][22][2][4] >= GRMsyncGlobals.BirthdayReceivedTemp[i][5] then
                        if guildData[j][22][2][4] > GRMsyncGlobals.BirthdayReceivedTemp[i][5] then
                            changeData = { guildData[j][1] , guildData[j][22][2][1][1] , guildData[j][22][2][1][2] , guildData[j][22][2][3] , guildData[j][22][2][4] , GRMsyncGlobals.DesignatedLeader , syncRankFilter };
                        end
                    else
                        changeData = GRMsyncGlobals.BirthdayReceivedTemp[i];
                    end
    
                    if #changeData ~= 0 then
                        table.insert ( GRMsyncGlobals.BDayChanges , changeData );
                    end

                    break;
                end
            end
        end

        local count = #GRMsyncGlobals.BDayChanges;
        -- One last cleanup - no need to include events that happened on same day. This occurrs when someone sends alt groupings of different names
        while count > 0 do
            for j = 1 , #GRMsyncGlobals.BDayChanges do
                if GRMsyncGlobals.BDayChanges[j][1] ~= GRMsyncGlobals.BDayChanges[count][1] and GRMsyncGlobals.BDayChanges[j][5] == GRMsyncGlobals.BDayChanges[count][5] then  -- make sure not same name, don't want to remove oneself.
                    -- Epoch timestamps are exactly the same... no need to keep both. There is almost no chance that someone changed a bday in a guild for multiple players all at the exact same moment.
                    table.remove ( GRMsyncGlobals.BDayChanges , j );
                    count = count - 1;      -- and extra count down...
                    break;
                end
            end
            count = count - 1;
        end
    else
        -- Just accept all the changes since you are not comparing to your own data...
        GRMsyncGlobals.BDayChanges = GRMsyncGlobals.BirthdayReceivedTemp;
    end

    -- Wipe the data!
    -- Final step of the sync process! Let's submit the final changes!!!
    GRMsyncGlobals.BirthdayReceivedTemp = {};
    GRMsync.SubmitFinalSyncData();
end

-- Method:          GRMsync.CheckChanges ( string , string )
-- What it Does:    Checks to see if the received data and the leader's data is different and then adds the most recent changes to update que
-- Purpose:         Retroactive Sync Procedure fully defined here in this method. MUCH WORK!
GRMsync.CheckChanges = function ( msg )
    local currentTime = time();

    local syncRankFilter = GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15];
    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] then
        syncRankFilter = GuildControlGetNumRanks() - 1;
    end

    -----------------------------
    -- For Join Date checking!
    -----------------------------
    if msg == "JD" then
        GRMsync.CheckingJDChanges ( currentTime , syncRankFilter );

    -----------------------------
    -- For Promo Date checking!
    -----------------------------
    elseif msg == "PD" then
        GRMsync.CheckingPDChanges ( currentTime , syncRankFilter );

    -----------------------------
    --- FOR BAN STATUS CHECK ----
    -----------------------------
    elseif msg == "BAN" then
        GRMsync.CheckingBANChanges ( currentTime , syncRankFilter );

    -----------------------------
    -- For Main Change checking!
    -----------------------------
    elseif msg == "MAIN" then
        GRMsync.CheckingMAINChanges ( currentTime , syncRankFilter );

    -----------------------------
    -- For Custom Note checking!
    -----------------------------
    elseif msg == "CUSTOM" then
        GRMsync.CheckingCustomNoteChanges ( syncRankFilter );
    
    -----------------------------
    -- For BIRTHDAY checking!
    -----------------------------
    elseif msg == "BDAY" then
        GRMsync.CheckingBdayChanges ( syncRankFilter );
    end
end

-- Method:          GRMsync.CheckAltChanges()
-- What it Does:    Compares the Leader's data to the received's data
-- Purpose:         Let's analyze the alt lists!
GRMsync.CheckAltChanges = function()
-- Ok, first things first, I need to compile both tables
    local leaderListOfAlts = {};
    local leaderListOfRemovedAlts = {};

    local syncRankFilter = GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15];
    if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] then
        syncRankFilter = GuildControlGetNumRanks() - 1;
    end

    local guildData = GRM_GuildMemberHistory_Save[ GRM_G.FID ][ GRM_G.saveGID ];

    -- Let's first get the leader's alt data to compare.
    for j = 2 , #guildData do

        -- initializing empty tables for each of the leader's players
        table.insert ( leaderListOfAlts , { guildData[j][1] , {} } );
        table.insert ( leaderListOfRemovedAlts , { guildData[j][1] , {} } );

        -- Build leader alt Tables for easier coding
        for i = 1 , #guildData[j][11] do
            table.insert ( leaderListOfAlts[ #leaderListOfAlts ][2] , { guildData[j][11][i][1] , guildData[j][11][i][6] } ); -- AN extra step, but easier to follow in the code.
        end
                
        -- Building leader removed alt tables.
        for i = 1 , #guildData[j][37] do
            table.insert ( leaderListOfRemovedAlts[ #leaderListOfRemovedAlts ][2] , { guildData[j][37][i][1] , guildData[j][37][i][6] } ); -- AN extra step, but easier to follow in the code.
        end
    end
    -- Now we can compare!!!
    
    ----------------------------------------------
    ----- CHECKING AGAINST LEADER'S DATA  --------
    ----------------------------------------------
    for i = 1 , #leaderListOfAlts do                                                                -- Cycling through every single player in the guild in leader's database
        for j = 1 , #GRMsyncGlobals.AltReceivedTemp do                                              -- Cycling through the alt list of guildie to receive comparative info!
            if leaderListOfAlts[i][1] == GRMsyncGlobals.AltReceivedTemp[j][1] then                  -- We have a match! Let's compare the alt tables of both players now.

                -- First, check if any missing.
                -- Checking if all of leader's data is found in received's
                local altIsMatched = false;

                -- STEP 1: LEADER DATA!!!!
                -- Comparing alt lists held by leader...
                for r = 1 , #leaderListOfAlts[i][2] do
                    altIsMatched = false;
                    for s = 1 , #GRMsyncGlobals.AltReceivedTemp[j][2] do
                        if leaderListOfAlts[i][2][r][1] == GRMsyncGlobals.AltReceivedTemp[j][2][s][1] then
                            altIsMatched = true;
                            -- if true, it's a match, move on!
                            break;
                        end
                    end

                    -- No match, potentially need to add to Received, or be removed from leader! Must compare timestamps!
                    if not altIsMatched then            -- No match was found. In other words, the leader has an alt listed, but the received player does not!

                        -- Ok, the ONLY way to know what is the correct course of action:
                        -- If I am going to ADD this, I must do 2 things. First, check if the receiving player has them on the removed list, and if so, Second, compare timestamps to know proper action
                        local addLeadersData = false;
                        local syncPlayerEpoch = -1;
                        for m = 1 , #GRMsyncGlobals.AltRemReceivedTemp do
                            if GRMsyncGlobals.AltRemReceivedTemp[m][1] == leaderListOfAlts[i][1] then -- Ok, an alt has been removed by the receiving player "currentSyncPlayer" - we don't yet know if the alt we are looking for is the removed one

                                -- If there are no added values, no need to do extra work!
                                if #GRMsyncGlobals.AltRemReceivedTemp[m][2] > 0 then

                                    local altRemMatched = false;
                                    for n = 1 , #GRMsyncGlobals.AltRemReceivedTemp[m][2] do
                                        if GRMsyncGlobals.AltRemReceivedTemp[m][2][n][1] == leaderListOfAlts[i][2][r][1] then           -- Leader's alt DID match the removed!!! Must compare timestamps!!!
                                            altRemMatched = true;
                                            -- We have a match! Must see which was the more current event!!!
                                            if GRMsyncGlobals.AltRemReceivedTemp[m][2][n][2] < leaderListOfAlts[i][2][r][2] then
                                                -- Leader's time is most recent!!!
                                                addLeadersData = true;
                                            else
                                                addLeadersData = false;
                                                syncPlayerEpoch = GRMsyncGlobals.AltRemReceivedTemp[m][2][n][2];
                                            end
                                            break;
                                        end
                                    end

                                    if not altRemMatched then           -- Leader's alt was not found among received's removed data.
                                        addLeadersData = true;
                                    end
                                else
                                    addLeadersData = true;              -- No need to do any work if the received's data has ZERO removed players to begin with!
                                end

                                    break;
                            end
                        end

                        if addLeadersData then
                            -- Alt is to be added.
                            GRMsync.AddToProperAltTable ( leaderListOfAlts[i][1] , leaderListOfAlts[i][2][r][1] , leaderListOfAlts[i][2][r][2] , true , GRMsyncGlobals.DesignatedLeader , syncRankFilter );
                        else
                            -- Alt is to be removed.
                            GRMsync.AddToProperAltTable ( leaderListOfAlts[i][1] , leaderListOfAlts[i][2][r][1] , syncPlayerEpoch , false , GRMsyncGlobals.CurrentSyncPlayer , GRMsyncGlobals.CurrentSyncPlayerRankRequirement );
                        end
                    end

                end
                altIsMatched = false;
                -- STEP2: RECEIVED DATA
                -- Comparing alt lists held by received...
                for r = 1 , #GRMsyncGlobals.AltReceivedTemp[j][2] do
                    altIsMatched = false;
                    for s = 1 , #leaderListOfAlts[i][2] do
                        if leaderListOfAlts[i][2][s][1] == GRMsyncGlobals.AltReceivedTemp[j][2][r][1] then
                            altIsMatched = true;
                            -- if true, it's a match, move on!
                            break;
                        end
                    end

                    -- No match, potentially need to add to leader, or be removed from received! Must compare timestamps!
                    if not altIsMatched then            -- No match was found. In other words, the received has an alt listed, but the leader does not!
                
                        local addReceivedAltData = false;
                        local epochStampLeader = -1;
                        -- Ok, the ONLY way to know what is the correct course of action:
                        -- If I am going to ADD this, I must do 2 things. First, check if the leader has them on the removed list, and if so, Second, compare timestamps to know proper action (whichever was most recent.)
                        for m = 1 , #leaderListOfRemovedAlts do
                            if leaderListOfRemovedAlts[m][1] == GRMsyncGlobals.AltReceivedTemp[j][1] then -- Ok, an alt has been removed by leader... we know this now. We don't yet know if the alt we are looking for is the one removed

                                -- If there are no added values, no need to do extra work!
                                if #leaderListOfRemovedAlts[m][2] > 0 then

                                    local altRemMatched = false;
                                    for n = 1 , #leaderListOfRemovedAlts[m][2] do
                                        if leaderListOfRemovedAlts[m][2][n][1] == GRMsyncGlobals.AltReceivedTemp[j][2][r][1] then           -- Received's alt DID match the removed!!! Must compare timestamps!!!
                                            
                                            altRemMatched = true;
                                            -- We have a match! Must see which was the more current event!!!
                                            if GRMsyncGlobals.AltReceivedTemp[j][2][r][2] < leaderListOfRemovedAlts[m][2][n][2] then
                                                -- Alt's time is most recent!!!
                                                addReceivedAltData = false;
                                                epochStampLeader = leaderListOfRemovedAlts[m][2][n][2];
                                            else
                                                addReceivedAltData = true;
                                            end
                                            break;
                                        end
                                    end

                                    if not altRemMatched then           -- Leader's alt was not found among received's removed data.
                                        addReceivedAltData = true;
                                    end

                                else
                                    addReceivedAltData = true;              -- No need to do any work if the received's data has ZERO removed players to begin with!                                            
                                end

                                break;
                            end
                        end
                        if addReceivedAltData then
                            GRMsync.AddToProperAltTable ( GRMsyncGlobals.AltReceivedTemp[j][1] , GRMsyncGlobals.AltReceivedTemp[j][2][r][1] , GRMsyncGlobals.AltReceivedTemp[j][2][r][2] , true , GRMsyncGlobals.CurrentSyncPlayer , GRMsyncGlobals.CurrentSyncPlayerRankRequirement );
                        else
                            GRMsync.AddToProperAltTable ( GRMsyncGlobals.AltReceivedTemp[j][1] , GRMsyncGlobals.AltReceivedTemp[j][2][r][1] , epochStampLeader , false , GRMsyncGlobals.DesignatedLeader , syncRankFilter );
                        end                                
                    end
                end

                break;
            end
        end
    end

    GRMsyncGlobals.AltReceivedTemp = {};
    GRMsyncGlobals.AltRemReceivedTemp = {};
end

-- Method:          GRMsync.ReportSyncCompletion ( string , boolean )
-- What it Does:    Reports to the chat that the sync is complete a more custom sync message, with the player's name, or more specifically, of all guildies.
-- Purpose:         Cleaner reporting.
GRMsync.ReportSyncCompletion = function ( currentSyncer , finalAnnounce )
    if time() - GRMsyncGlobals.AnnounceDelay > 5 then
        if ( GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] or GRM_G.TemporarySync ) and ( GRMsync.IsPlayerDataSyncCompatibleWithAnyOnline() or GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][35] ) then
            local announce = "";
            
            if GRM_G.TemporarySync and finalAnnounce then
                GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][14] = false;
                GRM_G.TemporarySync = false;
                GRMsync.MessageTracking:UnregisterAllEvents();
                GRMsync.ResetDefaultValuesOnSyncReEnable();         -- Reset values to default, so that it resyncs if player re-enables.
                GRM_UI.GRM_RosterChangeLogFrame.GRM_OptionsFrame.GRM_SyncOptionsFrame.GRM_RosterSyncCheckButton:SetChecked ( false );
                announce = GRM.L ( "GRM:" ) .. " " .. GRM.L ( "Manual Sync With Guildies Complete..." );
            elseif GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][16] then

                if finalAnnounce then
                    announce = GRM.L ( "GRM:" ) .. " " .. GRM.L ( "Sync With Guildies Complete..." , currentSyncer );
                else
                    announce = GRM.L ( "GRM:" ) .. " " .. GRM.L ( "Sync With {name} is Complete..." , currentSyncer );
                end
            end

            if GRMsyncGlobals.updateCount > 0 then
                announce = announce .. " (" .. GRM.L ( "{num} Items Updated" , nil , nil , GRMsyncGlobals.updateCount ) .. ")";
            end
            GRM.Report ( announce );
        end

        if GRM_UI.GRM_RosterChangeLogFrame.GRM_AuditFrame:IsVisible() then
            GRM.RefreshAuditFrames( GRM_G.AuditSortType );
        end
        if GRM_UI.GRM_RosterChangeLogFrame.GRM_LogFrame:IsVisible() then
            GRM_G.LogNumbersColorUpdate = true;
            GRM.BuildLogComplete();
        end

        GRMsyncGlobals.updateCount = 0;
        GRMsyncGlobals.errorCheckEnabled = false;
        GRMsyncGlobals.currentlySyncing = false;

        GRMsyncGlobals.AnnounceDelay = time();
    end
end

-----------------------------------
---- ERROR PROTECTIONS ON SYNC ----
-----------------------------------

-- Method:          GRMsync.RemoveAltErrorFix( string )
-- What it Does:    Sends a remove main exception, in case player sends info telling them to add an alt, yet the alt does not exist.
-- Purpose:         Information control from corrupted, bad, or nefarious data, jarbled old verison. This is to keep me from asking players to reset their data in case it happens.
--                  I COULD ask them to just reset it, but I gave my word I would never do that once the addon went live. This is just backup so I can stick to my word.
GRMsync.RemoveAltErrorFix = function( msg )
    local name = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
    local altName = string.sub ( msg , string.find ( msg , "?" ) + 1 );

    GRM.RemoveAlt ( name , altName , false , 0 , true )
end

-------------------------------
------ INITIALIZING -----------
-------------------------------

-- Method:          GRMsync.RegisterCommunicationProtocols()
-- What it Does:    Establishes the channel communication rules for sending and receiving
-- Purpose:         Need to make rules to get this to behave properly!
GRMsync.RegisterCommunicationProtocols = function()
    GRMsync.MessageTracking:RegisterEvent ( "CHAT_MSG_ADDON" );
    GRMsync.MessageTracking:SetScript ( "OnUpdate" , GRMsync.MessageThrottleUpdate );
    -- Register used prefixes!
    GRMsync.RegisterPrefixes ( GRMsyncGlobals.listOfPrefixes );

    -- Setup tracking...
    GRMsync.MessageTracking:SetScript ( "OnEvent" , function( self , event , prefix , msg , channel , sender )
        if not GRMsyncGlobals.SyncOK or not IsInGuild() then
            self:UnregisterAllEvents();
        else

            if event == "CHAT_MSG_ADDON" and channel == GRMsyncGlobals.channelName and GRMsync.IsPrefixVerified ( prefix ) then     -- Don't need to register my own sends.

                -- Sender must not equal themselves...
                if sender ~= GRM_G.addonPlayerName then
                    
                    -- Version Control Check First....
                    -- First, see if they are on compatible list.
                    local isFound = false;
                    for i = 1 , #GRMsyncGlobals.CompatibleAddonUsers do
                        if GRMsyncGlobals.CompatibleAddonUsers[i] == sender then
                            isFound = true;
                            break;
                        end
                    end

                    -- See if they are on the incompatible list.
                    local abortSync = false;
                    local versionCheckEpoch = 0;
                    if not isFound then
                        for i = 1 , #GRMsyncGlobals.IncompatibleAddonUsers do
                            if GRMsyncGlobals.IncompatibleAddonUsers[i] == sender then
                                return;
                            end
                        end

                        -- If you make it to this point, it means the player is not on the compatible list, and they are not on the incompatible list, they have never been checked...
                        -- Let's do it now!
                        -- Due to older verisons... need to check if this is nil. It will be nil for many. To prevent Lua error/crash.
                        if tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) ) ~= nil then
                            versionCheckEpoch = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
                            if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][19] and versionCheckEpoch < GRM_G.PatchDay then                   -- if the player sending data to you has an older version (smaller epoch number)                       
                                abortSync = true;
                            end
                        else
                            -- Older versions are incompatible, regardless of setting...
                            abortSync = true;
                        end                            
                    end
                    
                    -- Let's strip out the version timestamp of the sender, as well as the custom prefix.
                    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
                    local prefix2 = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );

                    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
                    -- Determine if this is a retroactive sync message, or a live sync.
                    if prefix2 == "GRM_JDSYNCUP" or prefix2 == "GRM_PDSYNCUP" or prefix2 == "GRM_ALTSYNCUP" or prefix2 == "GRM_REMSYNCUP" or prefix2 == "GRM_MAINSYNCUP" or prefix2 == "GRM_CUSTSYNCUP" or prefix2 == "GRM_BDSYNCUP" then
                        sender = string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 );
                        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
                    end
                    -- To cleanup Lua errors from very old versions trying to communicate...
                    local senderRankRequirement = nil;
                    if string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) ~= nil then

                        senderRankRequirement = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
                        if senderRankRequirement == nil then
                            -- ABORT

                            return
                        end
                        if sender == GRMsyncGlobals.CurrentSyncPlayer then
                            GRMsyncGlobals.CurrentSyncPlayerRankRequirement = senderRankRequirement;
                        end
                    else
                        -- If this is nil, you are getting spammed from player with VERY old version
                        chat:AddMessage ( "|cff00c8ff" .. GRM.L ( "GRM:" ) .. " |cffffffff" .. GRM.L ( "{name} tried to Sync with you, but their addon is outdated." , GRM.GetClassifiedName ( sender , true ) ) .. "\n|cffff0044" .. GRM.L ( "Remind them to update!" ) );
                        return;
                    end
                    local senderRankID = GRM.GetGuildMemberRankID ( sender );
                    -- Sender is not the designatedleader then return... Higher means lower in-game... 1 = guild leader; 10 = lowest initiate rank. So, if rank is higher than the restricted, it won't work. -- if the senderRankRequirement is lower than the receiving player, then that means it won't sync either.
                    -- of note, leadership role will not be rank restricted, but it will send out restricted data with rank tags on it so others know not to sync it or not. In the meantime the leader will build a temporary database to parry against during sync
                    -- This allows all sync information to be shared, but capable of being restricted by the sending party.
                    if ( prefix2 == "GRM_JD" or prefix2 == "GRM_PD" or prefix2 == "GRM_ADDALT" or prefix2 == "GRM_AC" or prefix2 == "GRM_RMVALT" or prefix2 == "GRM_MAIN" or prefix2 == "GRM_RMVMAIN" or prefix2 == "GRM_CNOTE" or prefix2 == "GRM_JDSYNCUP" or prefix2 == "GRM_PDSYNCUP" or prefix2 == "GRM_ALTSYNCUP" or prefix2 == "GRM_REMSYNCUP" or prefix2 == "GRM_MAINSYNCUP" or prefix2 == "GRM_CUSTSYNCUP" or prefix2 == "GRM_BDSYNCUP" ) and ( senderRankRequirement < GRM_G.playerRankID or senderRankID > GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] ) then
                        return

                    elseif ( not GRMsyncGlobals.IsElectedLeader and ( prefix2 ~= "GRM_WHOISLEADER" and prefix2 ~= "GRM_IAMLEADER" and prefix2 ~= "GRM_ELECT" and prefix2 ~= "GRM_TIMEONLINE" and prefix2 ~= "GRM_NEWLEADER" ) and sender ~= GRMsyncGlobals.DesignatedLeader ) and ( senderRankID > GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][15] or senderRankRequirement < GRM_G.playerRankID ) then        -- If player's rank is below settings threshold, ignore message.
                        return
                    
                    elseif abortSync and not isFound then
                        -- placing the abortSync notification AFTER the rank check to avoid confusion and not get the error message if someone is not proper sync rank.
                        table.insert ( GRMsyncGlobals.IncompatibleAddonUsers , sender );
                        chat:AddMessage ( "|cff00c8ff" .. GRM.L ( "GRM:" ) .. " |cffffffff" .. GRM.L ( "{name} tried to Sync with you, but their addon is outdated." , GRM.GetClassifiedName ( sender , true ) ) .. "\n|cffff0044" .. GRM.L ( "Remind them to update!" ) );
                        return;
                    elseif not abortSync and not isFound then
                        table.insert ( GRMsyncGlobals.CompatibleAddonUsers , sender );
                    end
                    -- parsing out the rankRequirementOfSender
                    msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
                    ------------------------------------------
                    ----------- LIVE UPDATE TRACKING ---------
                    ------------------------------------------
                    -- Varuious Prefix Logic handling now...
                    if prefix2 == "GRM_JD" then
                        GRMsync.CheckJoinDateChange ( msg , sender , prefix2 );
                    
                    -- On a Promotion Date Edit
                    elseif prefix2 == "GRM_PD" then
                        GRMsync.CheckPromotionDateChange ( msg , sender , prefix2 );

                    -- If person added to Calendar... this event occurs.
                    elseif prefix2 == "GRM_AC" then
                        GRMsync.EventAddedToCalendarCheck ( msg , sender );
                    
                    -- For adding an alt!
                    elseif prefix2 == "GRM_ADDALT" then
                        GRMsync.CheckAddAltChange ( msg , sender , prefix2 );
                
                    -- For Removing an alt!
                    elseif prefix2 == "GRM_RMVALT" then
                        GRMsync.CheckRemoveAltChange ( msg , sender , prefix2 );
                
                    -- For declaring who is to be "main"
                    elseif prefix2 == "GRM_MAIN" then
                        GRMsync.CheckAltMainChange ( msg , sender );
                
                    -- For demoting from main -- basically to set as no mains.
                    elseif prefix2 == "GRM_RMVMAIN" then
                        GRMsync.CheckAltMainToAltChange ( msg , sender );

                    elseif prefix2 == "GRM_CNOTE" then
                        GRMsync.CheckCustomNoteChange ( msg , sender , senderRankID );

                    elseif prefix2 == "GRM_BDAY" then
                        GRMsync.CheckBirthdayChange ( msg )
                
                    -- For ensuring ban information is controlled!
                    elseif ( prefix2 == "GRM_BAN" or prefix2 == "GRM_UNBAN" or prefix2 == "GRM_BANSYNCUP" or prefix2 == "GRM_BANSYNC" or prefix2 == "GRM_BANSYNC2" or prefix2 == "GRM_ADDCUR" or prefix2 == "GRM_RSN") and GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][21] then
                        local senderBanControlRankRequirement = tonumber ( string.sub ( msg , 1 , string.find ( msg , "?" ) - 1 ) );
                        msg = string.sub ( msg , string.find ( msg , "?" ) + 1 );
                        -- Should that be the player name, or should it be a name parsed from the sender??? -- Might need to investigate
                        if ( senderRankID > GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][22] or senderBanControlRankRequirement < GRM.GetGuildMemberRankID ( GRM_G.addonPlayerName ) ) then
                            -- Abort
                            return;
                        else
                            if prefix2 == "GRM_BAN" then
                                GRMsync.CheckBanListChange ( msg , sender );                        -- For live ban occurences
                            elseif prefix2 == "GRM_UNBAN" then
                                GRMsync.CheckUnbanListChangeLive ( msg , sender );                  -- For live unban occurrences
                            elseif prefix2 == "GRM_BANSYNCUP" then
                                GRMsync.BanManagementPlayersThatLeft ( msg , prefix2 );    -- For sync analysis final report changes!
                                GRMsyncGlobals.TimeSinceLastSyncAction = time();
                            elseif prefix2 == "GRM_BANSYNC" then
                                GRMsyncGlobals.TimeSinceLastSyncAction = time();                    -- For collecting sync data...
                                GRMsync.CollectData ( msg , prefix2 );
                            elseif prefix2 == "GRM_BANSYNC2" then
                                GRMsyncGlobals.TimeSinceLastSyncAction = time();                    -- For collecting sync data...
                                GRMsync.CollectData ( msg , prefix2 );
                            elseif prefix2 == "GRM_ADDCUR" then
                                GRMsyncGlobals.TimeSinceLastSyncAction = time();
                                GRMsync.UpdateCurrentPlayerInfo ( msg );                            -- For some outlier circumstances of people that have rejoined, or been manually made as banned but are still in guild.
                            elseif prefix2 == "GRM_RSN" then
                                GRMsyncGlobals.TimeSinceLastSyncAction = time();
                                GRMsync.UpdateCurrentPlayerBanReason ( msg );
                            end
                        end
                    elseif prefix2 == "GRM_BANSYNC4" and GRMsyncGlobals.IsElectedLeader and sender == GRMsyncGlobals.CurrentSyncPlayer then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();                    -- In case lots of data to cycle through, this is just a checkin with the sync leader to let you know its still sending data.                        
                    elseif prefix2 == "GRM_ADDLEFT" then
                        GRMsync.UpdateLeftPlayerInfo ( msg );
                                       
                    --------------------------------------------
                    -------- RETROACTIVE SYNC TRACKING ---------
                    --------------------------------------------

                    -- In response to asking "Who is the leader" then ONLY THE LEADER will respond.
                    elseif prefix2 == "GRM_WHOISLEADER" and GRMsyncGlobals.IsElectedLeader then
                            GRMsync.InquireLeaderRespond();

                    -- Updates who is the LEADER to sync with!
                    elseif prefix2 == "GRM_IAMLEADER" then
                        table.insert ( GRMsyncGlobals.AllLeadersNeutral , sender );
                        GRMsync.SetLeader ( GRMsyncGlobals.AllLeadersNeutral[1] );
                        -- This is a case when a player is not a leader, then becomes a leader, this should be cleared after a moment to keep that open.
                        C_Timer.After ( 5 , function()
                            GRMsyncGlobals.AllLeadersNeutral = nil;
                            GRMsyncGlobals.AllLeadersNeutral = {};
                        end);
                    -- For an election...
                    elseif prefix2 == "GRM_ELECT" then
                        GRMsync.SendTimeForElection ();

                    -- For sending timestamps out!
                    elseif prefix2 == "GRM_TIMEONLINE" and not GRMsyncGlobals.LeadershipEstablished then -- Only the person who sent the inquiry will bother reading these... flow control...
                        GRMsync.RegisterTimeStamps ( msg );
                        
                    -- For establishing the new leader after an election
                    elseif prefix2 == "GRM_NEWLEADER" then
                        GRMsync.ElectedLeader ( msg )
                    
                    -- LEADERSHIP ESTABLISHED, NOW LET'S SYNC COMMS!

                    -- Only the leader will hear this message!
                    elseif prefix2 == "GRM_REQUESTSYNC" and GRMsyncGlobals.IsElectedLeader then
                        -- Ensure it is not a double add...
                        isFound = false;
                        for i = 1 , #GRMsyncGlobals.SyncQue do
                            if GRMsyncGlobals.SyncQue[i] == sender then
                                isFound = true;
                                break;
                            end
                        end
                        if not isFound then
                            table.insert ( GRMsyncGlobals.SyncQue , sender );
                        end
                    
                        -- Redundancies... for some cleanup of edge cases where leader sync failed, or got trapped.
                        C_Timer.After ( 12.5 , function()
                            if ( GRMsyncGlobals.currentlySyncing and ( time() - GRMsyncGlobals.TimeSinceLastSyncAction ) >= 12.5 ) or ( not GRMsyncGlobals.currentlySyncing and #GRMsyncGlobals.SyncQue > 0 ) then
                                GRMsyncGlobals.currentlySyncing = false;
                                GRMsyncGlobals.errorCheckEnabled = false;
                                if GRMsync ~= nil then
                                    GRMsync.InitiateDataSync();
                                end
                            end
                        end)
                            
                    -- PLAYER DATA REQ FROM LEADERS
                    -- Leader has requesated your Join Date Data!
                    elseif prefix2 == "GRM_REQJDDATA" and msg == GRM_G.addonPlayerName and not GRMsyncGlobals.currentlySyncing then
                        -- Start forwarding Join Date data...
                        GRMsyncGlobals.currentlySyncing = true;
                        -- Initialize the error check now as you are now the front of the que being currently sync'd
                        if not GRM.IsCalendarEventEditOpen() then
                            GuildRoster();
                        end
                        C_Timer.After ( GRMsyncGlobals.ErrorCD , GRMsync.ErrorCheck );
                        GRMsyncGlobals.numGuildRanks = GuildControlGetNumRanks() - 1;
                        GRMsync.SendJDPackets();

                    elseif prefix2 == "GRM_REQPDDATA" and msg == GRM_G.addonPlayerName then
                        -- Start forwarding Promo Date data
                        GRMsync.SendPDPackets();

                    elseif prefix2 == "GRM_REQBANDATA" and msg == GRM_G.addonPlayerName then
                        -- Forwarding ban/unban data request.
                        GRMsync.SendBANPackets();
                    elseif prefix2 == "GRM_REQALTDATA" and msg == GRM_G.addonPlayerName then
                        -- Checking for new alts that have been added!
                        GRMsync.SendAltPackets();
                        -- forwarding player MAIN status.
                    elseif prefix2 == "GRM_REQMAIN" and msg == GRM_G.addonPlayerName then
                        GRMsync.SendMainPackets();
                        -- Custom Note
                    elseif prefix2 == "GRM_REQCUST" and msg == GRM_G.addonPlayerName then
                        GRMsync.SendCustomNotePackets();

                    -- DATA FLOW INITIATION AND STOP CONTROLS
                    -- Initializes the starting value
                    elseif prefix2 == "GRM_START" and GRMsyncGlobals.IsElectedLeader and sender == GRMsyncGlobals.CurrentSyncPlayer then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsyncGlobals.NumPlayerDataExpected = tonumber ( msg );

                    -- Stop collecting, start processing!
                    elseif prefix2 == "GRM_STOP" and GRMsyncGlobals.IsElectedLeader and sender == GRMsyncGlobals.CurrentSyncPlayer then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CheckChanges ( "JD" );
                        GRMsync.CheckChanges ( "PD" );
                        GRMsync.CheckChanges ( "BAN" );
                        GRMsync.CheckChanges ( "MAIN" );
                        GRMsync.CheckAltChanges ();
                        GRMsync.CheckChanges ( "CUSTOM" );
                        GRMsync.CheckChanges ( "BDAY" );

                    -- Collect all data before checking for changes!
                    elseif ( prefix2 == "GRM_JDSYNC" or prefix2 == "GRM_PDSYNC" or prefix2 == "GRM_MAINSYNC" ) and GRMsyncGlobals.IsElectedLeader and sender == GRMsyncGlobals.CurrentSyncPlayer then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CollectData ( msg , prefix2 );      

                    -- For ALT ADD DATA
                    elseif prefix2 == "GRM_ALTADDSYNC" and GRMsyncGlobals.IsElectedLeader and sender == GRMsyncGlobals.CurrentSyncPlayer then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CollectAltAddData ( msg );

                    -- For ALT REMOVE DATA
                    elseif prefix2 == "GRM_ALTREMSYNC" and GRMsyncGlobals.IsElectedLeader and sender == GRMsyncGlobals.CurrentSyncPlayer then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CollectAltRemData ( msg );
                    -- for CUSTOM NOTE Data
                    elseif prefix2 == "GRM_CUSTSYNC" and GRMsyncGlobals.IsElectedLeader and sender == GRMsyncGlobals.CurrentSyncPlayer then 
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CollectCustomNoteAction ( msg );
                    -- Birthday Data
                    elseif prefix2 == "GRM_BDSYNC" and GRMsyncGlobals.IsElectedLeader and sender == GRMsyncGlobals.CurrentSyncPlayer then 
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CollectBirthdayData ( msg )

                    -- AFTER DATA RECEIVED AND ANALYZED, SEND UPDATES!!!
                    -- THESE WILL HEAD TO THE SAME METHODS AS LIVE SYNC, WITH A COUPLE CHANGES BASED ON UNIQUE MESSAGE HEADER.
                    -- Sync the Join Dates!
                    elseif prefix2 == "GRM_JDSYNCUP" then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CheckJoinDateChange ( msg , sender , prefix2 );

                    -- Sync the Promo Dates!
                    elseif prefix2 == "GRM_PDSYNCUP" then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CheckPromotionDateChange ( msg , sender , prefix2 );

                    -- Final sync of ALT player info
                    elseif prefix2 == "GRM_ALTSYNCUP" then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CheckAddAltChange ( msg , sender , prefix2 );

                    -- Final sync of Removing alts
                    elseif prefix2 == "GRM_REMSYNCUP" then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CheckRemoveAltChange ( msg , sender , prefix2 );
                    
                    -- Final sync on Main Status
                    elseif prefix2 == "GRM_MAINSYNCUP" then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CheckMainSyncChange ( msg );

                    -- Final sync on Custom Note Changes
                    elseif prefix2 == "GRM_CUSTSYNCUP" then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CheckCustomNoteSyncChange ( msg , senderRankID , true );

                    -- Final sync on Birthdays
                    elseif prefix2 == "GRM_BDSYNCUP" then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.CheckBirthdayChange ( msg , nil , true );

                    -- Final Announce!!!
                    elseif prefix2 == "GRM_COMPLETE" then
                        if msg == GRM_G.addonPlayerName then
                            GRMsyncGlobals.TimeSinceLastSyncAction = time();
                            GRMsyncGlobals.currentlySyncing = false;
                            GRMsync.ReportSyncCompletion ( GRMsyncGlobals.DesignatedLeader , true );
                        end

                    -- ERROR PROTECTIONS!!
                    elseif prefix2 == "GRM_RMVERR" then
                        GRMsyncGlobals.TimeSinceLastSyncAction = time();
                        GRMsync.RemoveAltErrorFix( msg );
                    end
                end
            end
        end
    end);

    GRMsyncGlobals.RulesSet = true;
end

-- Method:          GRMsync.BuildSyncNetwork()
-- What it Does:    Step by step of my in-house sync algorithm custom built for this addon. Step by step it goes!
-- Purpose:         Control the work-flow of establishing the sync infrastructure. This will not maintain it, just builds the initial rules
--                  and the server-side channel of communication between players using the addon. Furthermore, by compartmentalizing it, it controls the flow of actions
--                  allowing a recursive check over the algorithm for flawless timing, and not moving ahead until the proper parameters are first met.
GRMsync.BuildSyncNetwork = function()
    -- Rank necessary to be established to keep'
    if IsInGuild() then
        if not GRMsyncGlobals.DatabaseLoaded then
            GRMsync.WaitTilDatabaseLoads();
        end

        -- Let's get the party started! Establishing rules then communication should be good to go!
        if GRMsyncGlobals.DatabaseLoaded and not GRMsyncGlobals.RulesSet then
            GRMsync.RegisterCommunicationProtocols();
        end

        -- Redundancy in case it fails to load.
        if GRMsyncGlobals.DatabaseLoaded and not GRMsyncGlobals.RulesSet then
            C_Timer.After ( 0.5 , GRMsync.BuildSyncNetwork );
        end
        
        -- We need to set leadership at this point.
        if GRMsyncGlobals.DatabaseLoaded and GRMsyncGlobals.RulesSet and not GRMsyncGlobals.LeadershipEstablished and not GRMsyncGlobals.LeadSyncProcessing then
            GRMsyncGlobals.LeadSyncProcessing = true;
            GRMsync.EstablishLeader();
            -- Reset the reload control blocker...
            if GRMsyncGlobals.reloadControl then
                C_Timer.After ( 5 , function()
                    GRMsyncGlobals.reloadControl = false;
                end);
            end
        end
    end
end

-- ON LOADING!!!!!!!
-- Event Tracking
GRMsync.Initialize = function()
    if GRMsyncGlobals.SyncOK then
        if GRM_AddonSettings_Save[GRM_G.FID][GRM_G.setPID][2][14] and IsInGuild() and GRM_G.HasAccessToGuildChat then
            GRMsync.TriggerFullReset();
            GRMsyncGlobals.LeadSyncProcessing = false;
            GRMsyncGlobals.errorCheckEnabled = false;
            GRMsync.MessageTracking = GRMsync.MessageTracking or CreateFrame ( "Frame" , "GRMsyncMessageTracking" );
            GRM_G.playerRankID = GRM.GetGuildMemberRankID ( GRM_G.addonPlayerName );
            GRMsync.BuildSyncNetwork();
        end
    end
end

GRMsync.HookComms();

