 /*

 Copyright (c) 2017 virtualdisgrace.com

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. 
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 */


// # --------------------------------------------------------------------- v1.2 #
// # ---------------- Here is some stuff that you should edit! ---------------- #
// # ------ Always write in between the quotation marks "just like that" ------ #


string headline = "";
// Example: string headline = "Property of House Lannister";

string about = "";
// Example: string about = "This collar was forged by the mighty duergar of Undrendark!";

string version = "";
// Example: string version = "1.0";

string group = "";  // Group URI
// Example: string group = "secondlife:///app/group/19657888-576f-83e9-2580-7c3da7c0e4ca/about";

string landmark = ""; // SLURL
// Example: string landmark = "http://maps.secondlife.com/secondlife/Hippo%20Hollow/128/128/2";

string locking = "dec9fb53-0fef-29ae-a21d-b3047525d312"; // key of the lock sound
string unlocking = "82fa6d06-b494-f97c-2908-84009380c8d1"; // key of the unlock sound


// # ----- Everything below this line should only by edited by scripters! ----- #
// # -------------------------------------------------------------------------- #


// This plugin creates the root (or main), apps and settings menus,
// and has the default LOCK/UNLOCK button. It can also dispense the help
// and license files (if present in contents) and can print info/version.

// It also includes code for the tiny steam-engine behind the LOCK/UNLOCK
// button and can play different noises depending on lock/unlock action,
// and reveal or hide a lock element on the device. There is also dedicated
// logic for a stealth function that can optionally hide the whole device.

// Finally there is logic to optionally allow the installation of updates.

integer CMD_OWNER = 500;
integer CMD_WEARER = 503;
integer NOTIFY = 1002;
integer REBOOT = -1000;
integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;
integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;
integer RLV_CLEAR = 6002;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

key wearer;

string that_token = "global_";
string dist;
string safeword = "RED";
integer locked;
integer hidden;
integer looks;

//lock
list closed_locks;
list open_locks;
list closed_locks_glows;
list open_locks_glows;

show_hide_lock() {
    if (hidden) return;
    integer i;
    integer links = llGetListLength(open_locks);
    for (;i < links; ++i) {
        llSetLinkAlpha(llList2Integer(open_locks,i),!locked,ALL_SIDES);
        update_glows(llList2Integer(open_locks,i),!locked);
    }
    links = llGetListLength(closed_locks);
    for (i=0; i < links; ++i) {
        llSetLinkAlpha(llList2Integer(closed_locks,i),locked,ALL_SIDES);
        update_glows(llList2Integer(closed_locks,i),locked);
    }
}

update_glows(integer link, integer alpha) {
    list glows;
    integer index;
    if (alpha) {
        glows = open_locks_glows;
        if (locked) glows = closed_locks_glows;
        index = llListFindList(glows,[link]);
        if (!~index) llSetLinkPrimitiveParamsFast(link,[PRIM_GLOW,ALL_SIDES,llList2Float(glows,index+1)]);
    } else {
        float glow = llList2Float(llGetLinkPrimitiveParams(link,[PRIM_GLOW,0]),0);
        glows = closed_locks_glows;
        if (locked) glows = open_locks_glows;
        index = llListFindList(glows,[link]);
        if (~index && glow > 0) glows = llListReplaceList(glows,[glow],index+1,index+1);
        if (~index && glow == 0) glows = llDeleteSubList(glows,index,index+1);
        if (!~index && glow > 0) glows += [link,glow];
        if (locked) open_locks_glows = glows;
        else closed_locks_glows = glows;
        llSetLinkPrimitiveParamsFast(link,[PRIM_GLOW,ALL_SIDES,0.0]);
    }
}

get_locks() {
    open_locks = [];
    closed_locks = [];
    integer i = llGetNumberOfPrims();
    string prim_name;
    for (;i > 1; --i) {
        prim_name = (string)llGetLinkPrimitiveParams(i,[PRIM_NAME]);
        if (prim_name == "Lock" || prim_name == "ClosedLock")
            closed_locks += i;
        else if (prim_name == "OpenLock")
            open_locks += i;
    }
}

//stealth
list glowy;
stealth (string str) {
    if (str == "hide") hidden = TRUE;
    else if (str == "show") hidden = FALSE;
    else hidden = !hidden;
    llSetLinkAlpha(LINK_SET,(float)(!hidden),ALL_SIDES);
    integer count;
    if (hidden) {
        count = llGetNumberOfPrims();
        float glow;
        for (;count > 0; --count) {
            glow = llList2Float(llGetLinkPrimitiveParams(count,[PRIM_GLOW,0]),0);
            if (glow > 0) glowy += [count,glow];
        }
        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_GLOW,ALL_SIDES,0.0]);
    } else {
        integer i;
        count = llGetListLength(glowy);
        for (;i < count;i += 2)
            llSetLinkPrimitiveParamsFast(llList2Integer(glowy,i),[PRIM_GLOW,ALL_SIDES,llList2Float(glowy,i+1)]);
        glowy = [];
    }
    show_hide_lock();
}

//update
integer update = FALSE;
key id_installer;

doupdate() {
    integer pin = (integer)llFrand(99999998.0) + 1;
    llSetRemoteScriptAccessPin(pin);
    integer chan_installer = -7484213;
    llRegionSayTo(id_installer,chan_installer,"ready|"+(string)pin);
}

//menus
list these_menus;

dialog(key id, string context, list buttons, list arrows, integer page, integer auth, string name) {
    key that_menu = llGenerateKey();
    llMessageLinked(LINK_DIALOG,DIALOG,(string)id+"|"+context+"|"+(string)page+"|"+llDumpList2String(buttons,"`")+"|"+llDumpList2String(arrows,"`")+"|"+(string)auth,that_menu);
    integer index = llListFindList(these_menus,[id]);
    if (~index) 
        these_menus = llListReplaceList(these_menus,[id,that_menu,name],index,index + 2);
    else 
        these_menus += [id,that_menu,name];
}

list apps;
list adjusters;
integer menu_anim;
integer menu_rlv;
integer menu_kidnap;

menu_root(key id, integer auth) {
    string context = "\n"+headline;
    context += "\n\nPrefix: %PREFIX%";
    context += "\nChannel: /%CHANNEL%";
    if (safeword) context += "\nSafeword: "+safeword;
    list these_buttons = ["Apps"];
    if (menu_anim) these_buttons += "Animations";
    else these_buttons += "-";
    if (menu_kidnap) these_buttons += "Capture";
    else these_buttons += "-";
    these_buttons += ["Leash"];
    if (menu_rlv) these_buttons += "RLV";
    else these_buttons += "-";
    these_buttons += ["Access","Settings","About"];
    if (locked) these_buttons = "UNLOCK" + these_buttons;
    else these_buttons = "LOCK" + these_buttons;
    dialog(id,context,these_buttons,[],0,auth,"Main");
}

menu_settings(key id, integer auth) {
    string context = "\nSettings";
    list these_buttons = ["Print","Load","Fix"];
    these_buttons += adjusters;
    if (hidden) these_buttons += ["☑ Stealth"];
    else these_buttons += ["☐ Stealth"];
    if (looks) these_buttons += "Looks";
    else if (llGetInventoryType("oc_themes") == INVENTORY_SCRIPT)
        these_buttons += "Themes";
    dialog(id,context,these_buttons,["BACK"],0,auth,"Settings");
}

menu_apps(key id, integer auth) {
    string context="\nApps & Plugins";
    dialog(id,context,apps,["BACK"],0,auth,"Apps");
}

menu_about(key id) {
    string context = "\nVersion: "+(string)version+"\nOrigin: ";
    if (dist) context += uri("agent/"+dist);
    else context += "";
    context += "\n\n“"+about+"”";
    context += "\n\n"+group;
    context += "\n"+landmark;
    context += "\n\nOpenCollar scripts were used in this product to an unknown extent. Relevant [https://raw.githubusercontent.com/OpenCollar/opencollar/master/LICENSE license terms] still apply.";
    llDialog(id,context,["OK"],-12345);
}

commands(integer auth, string str, key id) {
    list params = llParseString2List(str,[" "],[]);
    string cmd = llToLower(llList2String(params,0));
    str = llToLower(str);
    if (cmd == "menu") {
        string submenu = llToLower(llList2String(params,1));
        if (submenu == "main" || submenu == "") menu_root(id,auth);
        else if (submenu == "apps") menu_apps(id,auth);
        else if (submenu == "settings") {
            if (auth != CMD_OWNER && auth != CMD_WEARER) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",id);
                menu_root(id,auth);
            } else menu_settings(id,auth);
        }
    } else if (str == "info" || str == "version") {
        string message = "\n\nModel: "+llGetObjectName();
        message += "\nVersion: "+(string)version+"\nOrigin: ";
        if (dist) message += uri("agent/"+dist);
        else message += "Unknown";
        message += "\nUser: "+llGetUsername(wearer);
        message += "\nPrefix: %PREFIX%\nChannel: %CHANNEL%\nSafeword: "+safeword+"\n";
        llMessageLinked(LINK_DIALOG,NOTIFY,"1"+message,id);
    } else if (str == "license") {
        if (llGetInventoryType(".license") == INVENTORY_NOTECARD) llGiveInventory(id,".license");
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"There is no license file in this %DEVICETYPE%. Please request one directly from "+uri("agent/"+dist)+"!",id);
    } else if (str == "help") {
        if (llGetInventoryType(".help") == INVENTORY_NOTECARD) llGiveInventory(id,".help");
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"There is no help file in this %DEVICETYPE%. Please request one directly from "+uri("agent/"+dist)+"!",id);
    } else if (str == "about") menu_about(id);
    else if (str == "apps") menu_apps(id,auth);
    else if (str == "settings") {
        if (auth == CMD_OWNER || auth == CMD_WEARER) menu_settings(id,auth);
    } else if (cmd == "fix") {
        if (id == wearer) {
            make_menus();
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"I've fixed the menus.",id);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",id);
    } else if (!llSubStringIndex(str,".- ... -.-") && id == wearer) {
        if (update) {
            id_installer = (key)llGetSubString(str,-36,-1);
            dialog(id,"\nReady to install?",["Yes","No"],["Cancel"],0,auth,"update");
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Updates are disabled on this collar. In case of doubt, please contact "+uri("agent/"+dist),id);
    } else if (str == "hide" || str == "show" || str == "stealth") {
        if (auth == CMD_OWNER || auth == CMD_WEARER) stealth(str);
        else if ((key)id) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",id);
    } else if (str == "lock") {
        if (auth == CMD_OWNER || id == wearer ) {
            locked = TRUE;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,that_token+"locked=1","");
            llMessageLinked(LINK_ROOT,LM_SETTING_RESPONSE,that_token+"locked=1","");
            llOwnerSay("@detach=n");
            llMessageLinked(LINK_RLV,RLV_CMD,"detach=n","main");
            llPlaySound(locking,1.0);
            show_hide_lock();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"/me is locked.",id);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",id);;
    } else if (str == "runaway" || str == "unlock") {
        if (auth == CMD_OWNER) {
            locked = FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,that_token+"locked","");
            llMessageLinked(LINK_ROOT,LM_SETTING_RESPONSE,that_token+"locked=0","");
            llOwnerSay("@detach=y");
            llMessageLinked(LINK_RLV,RLV_CMD,"detach=y","main");
            llPlaySound(unlocking,1.0);
            show_hide_lock();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"/me is unlocked.",id);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",id);
    }
}

failsafe() {
    string name = llGetScriptName();
    if((key)name) return;
    if (name != "oc_root") {
        llOwnerSay("\n\nYour script \""+name+"\" has to be named \"oc_root\" or it might cause compatiblity issues, please rename and add your script again to your artwork.\n");
        llRemoveInventory(name);
    }
    // this version of oc_root is a combo, we don't need those other plugins
    if (llGetInventoryType("oc_lock") == INVENTORY_SCRIPT) llRemoveInventory("oc_lock");
    if (llGetInventoryType("oc_stealth") == INVENTORY_SCRIPT) llRemoveInventory("oc_stealth");
    if (llGetInventoryType("oc_update") == INVENTORY_SCRIPT) llRemoveInventory("oc_update");
}

make_menus() {
    menu_anim = FALSE;
    menu_rlv = FALSE;
    menu_kidnap = FALSE;
    adjusters = [];
    apps = [] ;
    llMessageLinked(LINK_SET,MENUNAME_REQUEST,"Main","");
    llMessageLinked(LINK_SET,MENUNAME_REQUEST,"Apps","");
    llMessageLinked(LINK_SET,MENUNAME_REQUEST,"Settings","");
    llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_REQUEST","");
}

init() {
    get_locks();
    hidden = !(integer)llGetAlpha(ALL_SIDES);
    failsafe();
    llSetTimerEvent(1.0);
}

string uri(string str) {
    return "secondlife:///app/"+str+"/inspect";
}

default {
    state_entry() {
        //llSetMemoryLimit(32768);
        wearer = llGetOwner();
        init();
    }
    on_rez(integer iStart) {
        init();
    }
    link_message(integer sender, integer num, string str, key id) {
        list params;
        if (num == MENUNAME_RESPONSE) {
            params = llParseString2List(str,["|"],[]);
            string parentmenu = llList2String(params,0);
            string submenu = llList2String(params,1);
            if (parentmenu == "Apps") {
                if (!~llListFindList(apps, [submenu])) {
                    apps += [submenu];
                    apps = llListSort(apps,1,TRUE);
                }
            } else if (str == "Main|Animations") menu_anim = TRUE;
            else if (str == "Main|RLV") menu_rlv = TRUE;
            else if (str == "Main|Capture") menu_kidnap = TRUE;
            else if (str == "Settings|Size/Position") adjusters = ["Position","Rotation","Size"];
        } else if (num == MENUNAME_REMOVE) {
            params = llParseString2List(str,["|"],[]);
            string parentmenu = llList2String(params,0);
            string submenu = llList2String(params,1);
            if (parentmenu == "Apps") {
                integer index = llListFindList(apps,[submenu]);
                if (~index) apps = llDeleteSubList(apps,index,index);
            } else if (submenu == "Size/Position") adjusters = [];
        } else if (num == LINK_UPDATE) {
            if (str == "LINK_DIALOG") LINK_DIALOG = sender;
            else if (str == "LINK_RLV") LINK_RLV = sender;
            else if (str == "LINK_SAVE") LINK_SAVE = sender;
        } else if (num == DIALOG_RESPONSE) {
            integer menuindex = llListFindList(these_menus,[id]);
            if (~menuindex) {
                params = llParseString2List(str,["|"],[]);
                id = (key)llList2String(params,0);
                string button = llList2String(params,1);
                //integer page = (integer)llList2String(params,2);
                integer auth = (integer)llList2String(params,3);
                string menu = llList2String(these_menus,menuindex + 1);
                these_menus = llDeleteSubList(these_menus,menuindex - 1,menuindex + 1);
                if (menu == "Main") {
                    if (button == "LOCK" || button== "UNLOCK")
                        llMessageLinked(LINK_ROOT,auth,button,id);
                    else if (button == "About") menu_about(id);
                    else if (button == "Apps") menu_apps(id,auth);
                    else llMessageLinked(LINK_SET,auth,"menu "+button,id);
                } else if (menu == "Apps") {
                    if (button == "BACK") menu_root(id,auth);
                    else llMessageLinked(LINK_SET,auth,"menu "+button,id);
                } else if (menu == "Settings") {
                     if (button == "Print") llMessageLinked(LINK_SAVE,auth,"print settings",id);
                     else if (button == "Load") llMessageLinked(LINK_SAVE,auth,button,id);
                     else if (button == "Fix") {
                         commands(auth,button,id);
                         return;
                    } else if (button == "☐ Stealth") {
                         llMessageLinked(LINK_ROOT,auth,"hide",id);
                         hidden = TRUE;
                    } else if (button == "☑ Stealth") {
                        llMessageLinked(LINK_ROOT,auth,"show",id);
                        hidden = FALSE;
                    } else if (button == "Themes") {
                        llMessageLinked(LINK_ROOT,auth,"menu Themes",id);
                        return;
                    } else if (button == "Looks") {
                        llMessageLinked(LINK_ROOT,auth,"looks",id);
                        return;
                    } else if (button == "BACK") {
                        menu_root(id,auth);
                        return;
                    } else if (button == "Position" || button == "Rotation" || button == "Size") {
                        llMessageLinked(LINK_ROOT,auth,llToLower(button),id);
                        return;
                    }
                    menu_settings(id,auth);
                } else if (menu == "update") {
                    if (button == "Yes") doupdate();
                    else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"cancelled",id);
                }
            }
        } else if (num >= CMD_OWNER && num <= CMD_WEARER) commands(num,str,id);
        else if (num == RLV_REFRESH || num == RLV_CLEAR) {
            if (locked) llMessageLinked(LINK_RLV, RLV_CMD,"detach=n","main");
            else llMessageLinked(LINK_RLV,RLV_CMD,"detach=y","main");
        } else if (num == LM_SETTING_RESPONSE) {
            params = llParseString2List(str,["="],[]);
            string this_token = llList2String(params,0);
            string value = llList2String(params,1);
            if (this_token == that_token+"locked") {
                locked = (integer)value;
                if (locked) llOwnerSay("@detach=n");
                show_hide_lock();
            } else if (this_token == that_token+"safeword") safeword = value;
            else if (this_token == "intern_dist") dist = value;
            else if (this_token == "intern_looks") looks = (integer)value;
        } else if (num == DIALOG_TIMEOUT) {
            integer menuindex = llListFindList(these_menus,[id]);
            these_menus = llDeleteSubList(these_menus,menuindex - 1,menuindex + 1);
        } else if (num == REBOOT && str == "reboot") llResetScript();
    }
    changed(integer changes) {
        if (changes & CHANGED_OWNER) llResetScript();
        if ((changes & CHANGED_INVENTORY) && !llGetStartParameter()) {
            failsafe();
            llSetTimerEvent(1.0);
            llMessageLinked(LINK_ALL_OTHERS,LM_SETTING_REQUEST,"ALL","");
        }
        if (changes & CHANGED_COLOR)
            hidden = !(integer)llGetAlpha(ALL_SIDES);
        if (changes & CHANGED_LINK) {
            get_locks();
            llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_REQUEST","");
        }
    }
    timer() {
        make_menus();
        llSetTimerEvent(0.0);
    }
}
