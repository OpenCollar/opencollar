key Owner_key;//Our Key
list Owners; //list of full collar Owners
key g_kWearer;//my UUID
string status;//store for on-line status
string on; //if we have an online owner when we poll them
string off; //if we have an offline owner
integer COMMAND_NOAUTH = 0; //lets grab the owners list when it's sent during reset
integer n = 0;//our point in the owners list during polling
integer T; //the polling time based on number of full Collar Owners

list rlvcmd=["fly=y","sendchat=y","chatnormal=y","chatwhisper=y","recvchat=y","emote=y","sendim=y","startim=y","recvim=y","tplm=y","tploc=y","tplure=y","showinv=y","viewnote=y","viewscript=y","viewtexture=y","edit=y","rez=y","touchfar=y","touchall=y","touchworld=y","touchattach=y","showworldmap=y","showminimap=y","showloc=y","setgroup=y"];

setrestrictions()
{
    if ((on == "on") && (status != "online")) //if we have an owner online AND they have not been maked as Online from last pass
    {
        status = "online";//store the fact our Owner has just logged in
        llMessageLinked(LINK_THIS, COMMAND_NOAUTH, "rlvon", Owner_key);//turn RLV on
        llOwnerSay("You have an Owner online, you are now RLV restricted");
        integer stop = llGetListLength(Owners);
        for (n = 0; n < stop; n += 2)
        {
            Owner_key = (key)llList2String(Owners, n);
            if (Owner_key != g_kWearer)
            {
                llInstantMessage(Owner_key, llKey2Name(g_kWearer) + " is logged in and is now RLV restricted");
            }
        }
    }
    if ((off == "off") && (on != "on") && (status != "offline"))//if we have at least 1 owner off line AND no Owners online AND not marked as offline from last pass
    {
        status = "offline";//store the fact they are offline so we know on next pass
        llMessageLinked(LINK_THIS, COMMAND_NOAUTH, "rlvoff", Owner_key);//turn off RLV
        llOwnerSay("Your Owners are offline, you are RLV free for now.");
        integer stop = llGetListLength(Owners);
        for (n = 0; n < stop; n += 2)
        {
            Owner_key = (key)llList2String(Owners, n);//lets get the next owner key
            if (Owner_key != g_kWearer)//we don't want to send to ourself
            {
                llInstantMessage(Owner_key, llKey2Name(g_kWearer) + " has just logged in and is RLV free.");
            }
        }   
    }
}

default
{
    state_entry()
    {
        g_kWearer = llGetOwner();
        llSetTimerEvent(2);//How often we will poll the owners
    }
     link_message(integer sender, integer num, string str, key id)
    {
        string str1;
        string str2;
        list lParam = llParseString2List(str, ["="], []);
        integer h = llGetListLength(lParam);
        str1= llList2String(lParam, 0);
        str2= llList2String(lParam, 1);
        if ((str1=="auth_owner") && (str2 !="")) //ok we have the owner list!
        {
            Owners = llParseString2List(str2, [","], []);
        }
    }
    
    on_rez(integer n)
    {
        llSleep(10);//wait for the collar to finish waking up
        status ="?";//I don't know the online status of my Owners
    }
     
    timer()
    {
        integer stop = llGetListLength(Owners);
        n += 2;//add 2 on each timer pass (2 as ownes list is key,dispayname format)
        if (n<= stop) //if we having reached the end of the owners list
        {
            Owner_key = (key)llList2String(Owners, n); //get the next Owners key from the list
            if (Owner_key != g_kWearer) //we don't want to waste checking if we are online
            {
                llRequestAgentData( Owner_key, DATA_ONLINE);
            }
        }
        else
        {
            setrestrictions();//lets adjust restrictions
            T =  20/(stop-2); //lets adjust the pole time acording how many Owners we have
            if (T<2) T=2; //stop this time going negative when the owner list is empty
            if (T>10) T=10; //Stop the delay being to long if only 1 owner, total pole time to check all owners 10s unless more then 5 owners
            llSetTimerEvent(T);//How often we will poll the owners
            n=0;      //reset back to start of Owners list
            on = "?"; //reset on status to unknown ready for next pass
            off = "?"; //reset off status to unknown ready for next pass
        }
    }

    dataserver(key queryid, string data)
    {
        if ( data == "1" ) //we have an online owner
        {
            on = "on";
        }
        else if ((data == "0"))//This owner is offline
        {
            off = "off";
        }
    }
}