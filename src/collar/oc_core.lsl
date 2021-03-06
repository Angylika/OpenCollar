  
/*
This file is a part of OpenCollar.
Copyright ©2020


: Contributors :

Aria (Tashia Redrose)
    *June 2020       -       Created oc_core
      * This combines oc_com, oc_auth, and oc_sys
    * July 2020     -       Maintenance fixes, feature implementations
    
    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/

integer NOTIFY_OWNERS=1003;

string g_sParentMenu = ""; 
string g_sSubMenu = "Main";
string COLLAR_VERSION = "8.0.0002"; // Provide enough room
// LEGEND: Major.Minor.Build RC Beta Alpha
integer UPDATE_AVAILABLE=FALSE;
string NEW_VERSION = "";
integer g_iAmNewer=FALSE;
integer g_iChannel=1;
string g_sPrefix;

integer g_iNotifyInfo=FALSE;

string g_sSafeword="RED";
//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;
integer CMD_NOACCESS=599;

integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
string ALL = "ALL";

list g_lMainMenu=["Apps", "Addons", "Access", "Settings", "Help/About"];

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}
integer g_iHide=FALSE;
Settings(key kID, integer iAuth){
    string sPrompt = "OpenCollar\n\n[Settings]";
    list lButtons = ["Print", "Load", "Fix Menus", "Resize", Checkbox(g_iHide, "Hide")];
    Dialog(kID, sPrompt, lButtons, [UPMENU],0,iAuth, "Menu~Settings");
}

integer g_iWelded=FALSE;
// The original idea in #356, was to make this as a app, but i fail to see why we must use an extra app just to create the weld, the extra app or possibly an addon could be made to unweld should the wearer desire it.

list g_lApps;
AppsMenu(key kID, integer iAuth){
    string sPrompt = "\n[Apps]\nYou have "+(string)llGetListLength(g_lApps)+" apps installed";
    Dialog(kID, sPrompt, g_lApps, [UPMENU],0,iAuth, "Menu~Apps");
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\nOpenCollar "+COLLAR_VERSION;
    list lButtons = [Checkbox(g_iLocked, "Lock")];
    
    if(!g_iWelded)lButtons+=g_lMainMenu;
    else lButtons=g_lMainMenu;
    
    if(UPDATE_AVAILABLE ) sPrompt += "\n\nUPDATE AVAILABLE: Your version is: "+COLLAR_VERSION+", The current release version is: "+NEW_VERSION;
    if(g_iAmNewer)sPrompt+="\n\nYour collar version is newer than the public release. This may happen if you are using a beta or pre-release copy.\nNote: Pre-Releases may have bugs. Ensure you report any bugs to [https://github.com/OpenCollarTeam/OpenCollar Github]";

    if(g_iWelded)sPrompt+="\n\n* The Collar is Welded *";
    if(iAuth==CMD_OWNER && g_iLocked && !g_iWelded)lButtons+=["Weld"];
    
    
    list lUtility;
    if(g_iAmNewer)lUtility += ["FEEDBACK", "BUG"];
    
    Dialog(kID, sPrompt, lButtons, lUtility, 0, iAuth, "Menu~Main");
}
key g_kGroup = "";
integer g_iLimitRange=TRUE;
integer g_iPublic=FALSE;
AccessMenu(key kID, integer iAuth){
    string sPrompt = "\nOpenCollar Access Controls";
    list lButtons = ["+ Owner", "+ Trust", "+ Block", "- Owner", "- Trust", "- Block", Checkbox(bool((g_kGroup!="")), "Group"), Checkbox(g_iPublic, "Public")];

    lButtons += [Checkbox(g_iLimitRange, "Limit Range"), "Runaway", "Access List"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Auth");
}

HelpMenu(key kID, integer iAuth){
    string EXTRA_VER_TXT = setor(bool((llGetSubString(COLLAR_VERSION,-1,-1)=="0")), "", " (ALPHA "+llGetSubString(COLLAR_VERSION,-1,-1)+") ");
    EXTRA_VER_TXT += setor(bool((llGetSubString(COLLAR_VERSION,-2,-2)=="0")), "", " (BETA "+llGetSubString(COLLAR_VERSION,-2,-2)+") ");
    EXTRA_VER_TXT += setor(bool((llGetSubString(COLLAR_VERSION,-3,-3) == "0")), "", " (RC "+llGetSubString(COLLAR_VERSION,-3,-3)+") ");
    
    string sPrompt = "\nOpenCollar "+COLLAR_VERSION+" "+EXTRA_VER_TXT+"\nVersion: "+setor(g_iAmNewer, "(Newer than release)", "")+" "+setor(UPDATE_AVAILABLE, "(Update Available)", "(Most current version)");
    sPrompt += "\n\nDocumentation https://opencollar.cc";
    sPrompt += "\nPrefix: "+g_sPrefix+"\nChannel: "+(string)g_iChannel;
    
    if(g_iNotifyInfo){
        g_iNotifyInfo=FALSE;
        llMessageLinked(LINK_SET, NOTIFY, sPrompt, kID);
        return;
    }
    list lButtons = ["Update", "Support", "License"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Help");
}

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}
integer g_iUpdatePin = 0;

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_EVERYONE) return;
    if (iNum == CMD_OWNER && sStr == "runaway") {
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_owner","");
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_trust","");
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_block","");
        return;
    }
    if (sStr==g_sSubMenu || sStr == "menu "+g_sSubMenu || sStr == "menu") Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        integer iWSuccess = 0; 
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        string sText;
        if(sChangetype=="fix"){
            g_lMainMenu=["Apps", "Addons", "Access", "Settings", "Help/About"];
            
            llMessageLinked(LINK_SET,0,"initialize","");
        } else if(sChangetype == "update"){
            if(iNum == CMD_OWNER || iNum == CMD_WEARER){
                g_iUpdatePin = llRound(llFrand(0x7FFFFFFF))+1; // Maximum integer size
                llSetRemoteScriptAccessPin(g_iUpdatePin);
                
                // Now that a pin is set, scan for a updater and chainload
                g_iDiscoveredUpdaters=0;
                g_kUpdater=NULL_KEY;
                g_kUpdateUser=kID;
                llMessageLinked(LINK_SET, NOTIFY, "0Searching for a updater", kID);
                g_iUpdateAuth = iNum;
                llListenRemove(g_iUpdateListener);
                g_iUpdateListener = llListen(g_iUpdateChan, "", "", "");
                llWhisper(g_iUpdateChan, "UPDATE|"+COLLAR_VERSION);
                g_iWaitUpdate = TRUE;
                llSetTimerEvent(5);
            }
        } else if(sChangetype == "safeword"){
            if(sChangevalue!=""){
                if(iNum == CMD_OWNER){
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_safeword="+sChangevalue, "");
                    llMessageLinked(LINK_SET,NOTIFY,"1Safeword is now set to '"+sChangevalue,kID);
                    
                    if(sChangevalue == "RED"){
                        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "global_safeword","");
                    }
                }
            } else {
                if(iNum == CMD_OWNER || iNum == CMD_WEARER){
                    llMessageLinked(LINK_SET, NOTIFY, "0The safeword is current set to: '"+g_sSafeword+"'",kID);
                }
            }
        } else if(sChangetype == "menu"){
            if(llToLower(sChangevalue) == "access"){
                AccessMenu(kID,iNum);
            } else if(llToLower(sChangevalue) == "settings"){
                Settings(kID,iNum);
            } else if(llToLower(sChangevalue) == "apps"){
                AppsMenu(kID,iNum);
            } else if(llToLower(sChangevalue) == "help/about"){
                HelpMenu(kID,iNum);
            }
        } else if(llToLower(sChangetype) == "weld" && iNum == CMD_OWNER){
            g_kWelder=kID;
            llMessageLinked(LINK_SET, NOTIFY, "1secondlife:///app/agent/"+(string)kID+"/about is attempting to weld the collar. Consent is required", kID);
            Dialog(g_kWearer, "[WELD CONSENT REQUIRED]\n\nsecondlife:///app/agent/"+(string)kID+"/about wants to weld your collar. If you agree, you may not be able to unweld it without the use of a plugin or a addon designed to break the weld. If you disagree with this action, press no.", ["Yes", "No"], [], 0, iNum, "weld~consent");
        } else if(llToLower(sChangetype) == "debug-unweld"){
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "intern_weld", "");
            llSay(0, "debug unweld triggered");
        } else if(llToLower(sChangetype) == "info"){
            if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE){
                g_iNotifyInfo = TRUE;
                HelpMenu(kID,iNum);
            }
        } else if(llToLower(sChangetype) == "getauth"){
            llMessageLinked(LINK_SET, NOTIFY, "0Your auth level is: "+(string)iNum, kID);
        } else {
            if(llToLower(sChangetype) == "access")AccessMenu(kID,iNum);
            else if(llToLower(sChangetype) == "settings")Settings(kID,iNum);
            else if(llToLower(sChangetype) == "apps")AppsMenu(kID,iNum);
            else if(llToLower(sChangetype) == "help/about") HelpMenu(kID,iNum);
        }
    }
}

integer g_iUpdateListener;
key g_kUpdater;
integer g_iDiscoveredUpdaters;
key g_kUpdateUser;
integer g_iUpdateAuth;
integer g_iWaitUpdate;
integer g_iUpdateChan = -7483213;
key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
integer g_iLocked=FALSE;
Compare(string V1, string V2){
    NEW_VERSION=V2;
    
    if(V1==V2){
        UPDATE_AVAILABLE=FALSE;
        return;
    }
    V1 = llDumpList2String(llParseString2List(V1, ["."],[]),"");
    V2 = llDumpList2String(llParseString2List(V2, ["."],[]), "");
    integer iV1 = (integer)V1;
    integer iV2 = (integer)V2;
    
    if(iV1 < iV2){
        UPDATE_AVAILABLE=TRUE;
    } else if(iV1 == iV2) return;
    else if(iV1 > iV2){
        UPDATE_AVAILABLE=FALSE;
        g_iAmNewer=TRUE;
        
        llSetText("", <1,0,0>,1);
    }
}

key g_kUpdateCheck = NULL_KEY;
DoCheckUpdate(){
    g_kUpdateCheck = llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/version.txt",[],"");
}

key g_kCheckDev;

DoCheckDevUpdate()
{
    g_kCheckDev = llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/dev_version.txt",[],"");
}

///The setor method is derived from a similar PHP proposed function, though it was denied, 
///https://wiki.php.net/rfc/ifsetor
///The concept is roughly the same though we're not dealing with lists in this method, so is just modified
///The ifsetor proposal would give a function which would be more like
///ifsetor(list[index], sTrue, sFalse)
///LSL can't check if a list item is set without a stack heap if it is out of range, this is significantly easier for us to just check for a integer boolean
string setor(integer iTest, string sTrue, string sFalse){
    if(iTest)return sTrue;
    else return sFalse;
}

list g_lTestReports = ["5556d037-3990-4204-a949-73e56cd3cb06", "1a828b4e-6345-4bb3-8d41-f93e6621ba25"]; // Aria and Roan
// Any other team members please add yourself if you want feedback/bug reports. Or ask to be added if you do not have commit access
// These IDs will only be in here during the testing period to allow for the experimental feedback/bug report system to do its thing
// As most do not post to github, i am experimenting to see if a menu option in the collar of a Alpha/Beta might encourage feedback or bugs to be sent even if it has to be sent through a llInstantMessage

integer g_iDoTriggerUpdate=FALSE;
key g_kWelder = NULL_KEY;
StartUpdate(){
    llRegionSayTo(g_kUpdater, g_iUpdateChan, "ready|"+(string)g_iUpdatePin);
}
default
{
    on_rez(integer t){
        if(llGetOwner()!=g_kWearer) llResetScript();
        
        llSleep(15);
        llMessageLinked(LINK_SET, REBOOT, "reboot", "");// Reboot after 15 seconds
    }
    state_entry()
    {
        g_kWearer = llGetOwner();
        
        llMessageLinked(LINK_SET, 0, "initialize", llGetKey());
    }
    touch_start(integer iNum){
        llMessageLinked(LINK_SET, 0, "menu", llDetectedKey(0)); // Temporary until API v8's implementation is done, use v7 in the meantime
    }
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_RESPONSE){
            list lPara = llParseString2List(sStr, ["|"],[]);
            string sName = llList2String(lPara,0);
            string sMenu = llList2String(lPara,1);
            if(sName == "Main"){
                if(llListFindList(g_lMainMenu, [sMenu])==-1){
                    g_lMainMenu = [sMenu] + g_lMainMenu;
                }
            } else if(sName == "Apps"){
                if(llListFindList(g_lApps,[sMenu])==-1)g_lApps= [sMenu]+g_lApps;
            }
        } else if(iNum == MENUNAME_REMOVE){
            // This is not really used much if at all in 7.x
            
            list lPara = llParseString2List(sStr, ["|"],[]);
            string sName = llList2String(lPara,0);
            string sMenu = llList2String(lPara,1);
            if(sName=="Main"){
                integer loc = llListFindList(g_lMainMenu, [sMenu]);
                if(loc!=-1){
                    g_lMainMenu = llDeleteSubList(g_lMainMenu, loc,loc);
                }
            } else if(sName == "Apps"){
                integer loc = llListFindList(g_lApps,[sMenu]);
                if(loc!=-1)g_lApps = llDeleteSubList(g_lApps, loc,loc);
            }
            
        }
        else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                integer iRespring=TRUE;
                if(sMenu == "Menu~Main"){
                    if(sMsg == Checkbox(g_iLocked,"Lock")){
                        if(iAuth==CMD_OWNER && g_iLocked){
                            g_iLocked=FALSE;
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_locked="+(string)g_iLocked,"");
                            llMessageLinked(LINK_SET, NOTIFY, "1%WEARERNAME%'s collar has been unlocked", kAv);
                        } else if((iAuth == CMD_OWNER || iAuth == CMD_TRUSTED || iAuth == CMD_WEARER )  && !g_iLocked){
                            g_iLocked=TRUE;
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_locked="+(string)g_iLocked,"");
                            llMessageLinked(LINK_SET, NOTIFY, "1%WEARERNAME%'s collar has been locked", kAv);
                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to the lock", kAv);
                        }
                    } else if(sMsg == "Weld"){
                        UserCommand(iAuth, "weld", kAv);
                    } else if(sMsg == "FEEDBACK"){
                        Dialog(kAv, "Please submit your feedback for this alpha/beta/rc", [],[],0,iAuth,"Main~Feedback");
                        iRespring=FALSE;
                    } else if(sMsg == "BUG"){
                        Dialog(kAv, "Please type your bug report, including any reproduction steps. If it is easier, please contact the secondlife:///app/group/c5e0525c-29a9-3b66-e302-34fe1bc1bd43/about group, or submit your bug report on [https://github.com/OpenCollarTeam/OpenCollar GitHub] - or both!", [],[],0,iAuth, "Main~Bug");
                        iRespring=FALSE;
                    }  else {
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, 0,"menu "+ sMsg, kAv); // Recalculate
                    }
                     
                    
                    if(iRespring)Menu(kAv,iAuth);
                } else if(sMenu == "weld~consent"){
                    if(sMsg == "No"){
                        llMessageLinked(LINK_SET, NOTIFY, "1%NOACCESS% to welding the collar.", g_kWelder);
                    } else {
                        // do weld
                        llMessageLinked(LINK_SET, NOTIFY, "1Please wait...", g_kWelder);
                        llMessageLinked(LINK_SET, NOTIFY_OWNERS, "%WEARERNAME%'s collar has been welded", g_kWelder);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "intern_weld=1", "");
                        g_iWelded=TRUE;
                        
                        llMessageLinked(LINK_SET, NOTIFY, "1Weld completed", g_kWelder);
                    }
                } else if(sMenu=="Menu~Auth"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv,iAuth);
                    } else if(llGetSubString(sMsg,0,0) == "+"){
                        if(iAuth == CMD_OWNER){
                            iRespring=FALSE;
                            llMessageLinked(LINK_SET, iAuth, "add "+llToLower(llGetSubString(sMsg,2,-1)), kAv);
                        }
                        else
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to adding a person", kAv);
                    } else if(llGetSubString(sMsg,0,0)=="-"){
                        if(iAuth == CMD_OWNER){
                            iRespring=FALSE;
                            llMessageLinked(LINK_SET, iAuth, "rem "+llToLower(llGetSubString(sMsg,2,-1)), kAv);
                        } else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to removing a person", kAv);
                    } else if(sMsg == "Access List"){
                        llMessageLinked(LINK_SET, iAuth, "print auth", kAv);
                    } else if(sMsg == Checkbox(bool((g_kGroup!="")), "Group")){
                        if(g_kGroup!=""){
                            g_kGroup="";
                            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_group", "");
                        }else{
                            g_kGroup = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]),0);
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_group="+(string)g_kGroup, "");
                        }
                    } else if(sMsg == Checkbox(g_iPublic, "Public")){
                        g_iPublic=1-g_iPublic;
                        
                        if(g_iPublic)llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_public=1", "");
                        else llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_public","");
                    } else if(sMsg == Checkbox(g_iLimitRange, "Limit Range")){
                        g_iLimitRange=1-g_iLimitRange;
                        
                        if(!g_iLimitRange)llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_limitrange=0","");
                        else llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_limitrange", "");
                    }
                    
                    
                    if(iRespring)AccessMenu(kAv,iAuth);
                } else if(sMenu == "Menu~Settings"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv, iAuth);
                    } else if(sMsg == "Print"){
                        llMessageLinked(LINK_SET, iAuth, "print settings", kAv);
                    } else if(sMsg == "Fix Menus"){
                        llMessageLinked(LINK_SET, iAuth, "fix", kAv);
                        llMessageLinked(LINK_SET, NOTIFY, "0Menus have been fixed", kAv);
                    } else if(sMsg == Checkbox(g_iHide,"Hide")){
                        g_iHide=1-g_iHide;
                        llMessageLinked(LINK_SET, iAuth, setor(g_iHide, "hide", "show"), kAv);
                    } else if(sMsg == "Load"){
                        llMessageLinked(LINK_SET, iAuth, sMsg, kAv);
                    } else if(sMsg == "Resize"){
                        // Resizer!!
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, iAuth, "menu Size/Position", kAv);
                    }
                    
                    
                    
                    if(iRespring)Settings(kAv,iAuth);
                } else if(sMenu == "Menu~Help"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv,iAuth);
                    } else if(sMsg == "License"){
                        llGiveInventory(kAv, ".license");
                    } else if(sMsg == "Support"){
                        llMessageLinked(LINK_SET, NOTIFY, "0You can get support for OpenCollar in the following group: secondlife:///app/group/45d71cc1-17fc-8ee4-8799-7164ee264811/about or for scripting related questions or beta versions: secondlife:///app/group/c5e0525c-29a9-3b66-e302-34fe1bc1bd43/about", kAv);
                    } else if(sMsg == "Update"){
                        UserCommand(iAuth, "update", kAv);
                    }
                    
                    if(iRespring)HelpMenu(kAv,iAuth);
                } else if(sMenu == "Menu~Apps"){
                    if(sMsg == UPMENU){
                        Menu(kAv, iAuth);
                    }else{
                        llMessageLinked(LINK_SET, iAuth, "menu "+sMsg, kAv);
                    }
                } else if(sMenu == "Main~Feedback" || sMenu == "Main~Bug"){
                    integer iStart=0;
                    integer iEnd = llGetListLength(g_lTestReports);
                    if(!g_iAmNewer){
                        llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% due to: Testing period has ended for this version", kAv);
                        return;
                    }
                    for(iStart=0;iStart<iEnd;iStart++){
                        llInstantMessage((key)llList2String(g_lTestReports, iStart), "T:"+sMenu+":"+COLLAR_VERSION+"\nFROM: "+llKey2Name(kAv)+"\nBODY: "+sMsg);
                    }
                    
                    llMessageLinked(LINK_SET, NOTIFY, "0Thank you. Your report has been sent. Please do not abuse this tool, it is intended to send feedback or bug reports during a testing period", kAv);
                    Menu(kAv,iAuth);
                }
            }
        } else if(iNum == LM_SETTING_RESPONSE){
            list lPar = llParseString2List(sStr, ["_","="],[]);
            string sToken = llList2String(lPar,0);
            string sVar = llList2String(lPar,1);
            string sVal = llList2String(lPar,2);
            
            
            if(sToken=="global"){
                if(sVar=="locked"){
                    g_iLocked=(integer)sVal;
                    
                    if(g_iLocked){
                        llOwnerSay("@detach=n");
                    }else{
                        llOwnerSay("@detach=y");
                    }
                } else if(sVar == "safeword"){
                    g_sSafeword = sVal;
                    if(g_sSafeword == "0"){
                        llMessageLinked(LINK_SET, CMD_OWNER, "safeword-disabled","");
                    }
                } else if(sVar == "prefix"){
                    g_sPrefix = sVal;
                } else if(sVar == "channel"){
                    g_iChannel = (integer)sVal;
                }
            } else if(sToken == "auth"){
                if(sVar == "group"){
                    if(sVal==(string)NULL_KEY)sVal="";
                    g_kGroup=(key)sVal;
                } else if(sVar == "public"){
                    g_iPublic = (integer)sVal;
                } else if(sVar == "limitrange"){
                    g_iLimitRange=(integer)sVal;
                }
            } else if(sToken == "intern"){
                if(sVar == "weld"){
                    g_iWelded=TRUE;
                    
                    if(!g_iLocked)llMessageLinked(LINK_SET,LM_SETTING_SAVE, "global_locked=1","");
                }
            }
            
            if(sStr == "settings=sent"){
                if(g_kGroup==(string)NULL_KEY)g_kGroup="";
            }
        } else if(iNum == LM_SETTING_DELETE){
            list lPar = llParseString2List(sStr, ["_"],[]);
            string sToken = llList2String(lPar,0);
            string sVar = llList2String(lPar,1);
            
            if(sToken=="global"){
                if(sVar == "locked") g_iLocked=FALSE;
                else if(sVar == "safeword"){
                    g_sSafeword = "RED";
                    llMessageLinked(LINK_SET, CMD_OWNER, "safeword-enable","");
                } else if(sVar == "prefix"){
                    // revert to default calculation
                    g_sPrefix = llGetSubString(llKey2Name(g_kWearer),0,1);
                } else if(sVar = "channel"){
                    g_iChannel = 1;
                }
            } else if(sToken == "auth"){
                if(sVar == "group"){
                    g_kGroup="";
                }
                else if(sVar == "public")g_iPublic=FALSE;
                else if(sVar == "limitrange")g_iLimitRange=TRUE;
            } else if(sToken == "intern"){
                if(sVar == "weld"){
                    g_iWelded=FALSE;
                    // Unwelded, reboot collar now
                    llMessageLinked(LINK_SET, REBOOT,"reboot","");
                }
            }
        } else if(iNum == REBOOT){
            if(sStr=="reboot"){
                llResetScript();
            }
        
        } else if(iNum == 0){
            // Auth request!
            if(sStr=="initialize"){
                llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
                llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Apps", "");
                
                DoCheckUpdate();
                
                llListenRemove(g_iUpdateListener);
            }
        } else if(iNum == RLV_REFRESH){
            if(g_iLocked){
                llOwnerSay("@detach=n");
            }
            
        }
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
    http_response(key kRequest, integer iStatus, list lMeta, string sBody){
        if(kRequest == g_kUpdateCheck){
            if(iStatus==200){
                Compare(COLLAR_VERSION, sBody);
                if(g_iAmNewer)DoCheckDevUpdate();
            }
            else
                llOwnerSay("Could not check for an update. The server returned a unknown status code");
        } else if(kRequest == g_kCheckDev){
            if(iStatus==200){
                Compare(COLLAR_VERSION, sBody);
            } else llOwnerSay("Could not check the latest development version. The file might not exist or github is not working");
        }
    }
    
    timer(){
        if(g_iWaitUpdate){
            g_iWaitUpdate=FALSE;
            llListenRemove(g_iUpdateListener);
            if(!g_iDiscoveredUpdaters){
                llMessageLinked(LINK_SET,NOTIFY, "0No updater found. Please ensure you are attempting to use a updater obtained from secondlife:///app/group/45d71cc1-17fc-8ee4-8799-7164ee264811/about", g_kWearer);
                llSetRemoteScriptAccessPin(0);
            }else if(g_iDiscoveredUpdaters > 1){
                llMessageLinked(LINK_SET, NOTIFY, "0Error. Too many updaters found nearby. Please ensure only 1 is rezzed out", g_kWearer);
                llSetRemoteScriptAccessPin(0);
            } else {
                // Trigger update
                StartUpdate();
            }
            
            
        }else {
            llSetTimerEvent(0);
        }
    }
    
    listen(integer iChan, string sName, key kID, string sMsg){
        if(iChan == g_iUpdateChan){
            // dont check object owner. But do check if it is using v8 protocol for updates
            list lTemp = llParseStringKeepNulls(sMsg, ["|"],[]);
            string Cmd = llList2String(lTemp,0);
            string sOpt = llList2String(lTemp,1);
            string sImpl = "";
            
            if(llGetListLength(lTemp)>=3){
                sImpl = llList2String(lTemp,2);
                if(sImpl=="8000"){ // v8.0.00
                    // Nothing to do here. Continue
                } else {
                    // Not v8 or above
                    // Require object owner is wearer
                    if(llGetOwnerKey(kID)!=g_kWearer){
                        return;
                    }
                }
            }
            
            if(Cmd == "-.. ---" && sImpl == ""){ //Seriously why the fuck are we using morse code?
                // sOpt is strictly going to be the version string now
                Compare(COLLAR_VERSION, sOpt);
                if((UPDATE_AVAILABLE && !g_iAmNewer) || g_iDoTriggerUpdate){
                    // valid update
                    g_iDiscoveredUpdaters++;
                    g_kUpdater = kID;
                } else {
                    // this updater is older, dont install it
                    llMessageLinked(LINK_SET, NOTIFY, "0The version you are trying to install is older than the currently installed scripts, or it is the same version. To install anyway, trigger the install a second time", g_kUpdateUser);
                    llSay(0, "Current version is newer or the same as the updater. Trigger update a second time to confirm you want to actually do this");
                    g_iDoTriggerUpdate=TRUE;
                }
            }
        }
    }
}
