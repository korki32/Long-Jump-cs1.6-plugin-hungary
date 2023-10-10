#include <amxmodx>
#include <fun>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>

#define PLUGIN "LONGJUMP"
#define VERSION "1.0"
#define AUTHOR "s1mpla"

#define LONGJUMP_READY 0
#define LONGJUMP_COUNTDOWN 1

new g_LongJump_status[33]
new Float:g_LongJump_countdown_time[33]

new bool:g_hasLongJump[33]
new Float:g_last_LongJump_time[33]
new g_LongJump_force, g_LongJump_height, g_LongJump_cooldown

new const g_szLongJump_Model[] = "models/longjump_s1mpla/longjump_s1mpla.mdl";
new g_iWing[33];

//*ColorChat Inc*//
enum Color
{
	NORMAL = 1, // clients scr_concolor cvar color
	GREEN, // Green Color
	TEAM_COLOR, // Red, grey, blue
	GREY, // grey
	RED, // Red
	BLUE, // Blue
}

new TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	new message[256];

	switch(type)
	{
		case NORMAL: // clients scr_concolor cvar color
		{
			message[0] = 0x01;
		}
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}

	vformat(message[1], 251, msg, 4);

	// Make sure message is not longer than 192 character. Will crash the server.
	message[192] = '^0';

	new team, ColorChange, index, MSG_Type;
	
	if(id)
	{
		MSG_Type = MSG_ONE;
		index = id;
	} else {
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	}
	
	team = get_user_team(index);
	ColorChange = ColorSelection(index, MSG_Type, type);

	ShowColorMessage(index, MSG_Type, message);
		
	if(ColorChange)
	{
		Team_Info(index, MSG_Type, TeamName[team]);
	}
}

ShowColorMessage(id, type, message[])
{
	static bool:saytext_used;
	static get_user_msgid_saytext;
	if(!saytext_used)
	{
		get_user_msgid_saytext = get_user_msgid("SayText");
		saytext_used = true;
	}
	message_begin(type, get_user_msgid_saytext, _, id);
	write_byte(id)		
	write_string(message);
	message_end();	
}

Team_Info(id, type, team[])
{
	static bool:teaminfo_used;
	static get_user_msgid_teaminfo;
	if(!teaminfo_used)
	{
		get_user_msgid_teaminfo = get_user_msgid("TeamInfo");
		teaminfo_used = true;
	}
	message_begin(type, get_user_msgid_teaminfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}

ColorSelection(index, type, Color:Type)
{
	switch(Type)
	{
		case RED:
		{
			return Team_Info(index, type, TeamName[1]);
		}
		case BLUE:
		{
			return Team_Info(index, type, TeamName[2]);
		}
		case GREY:
		{
			return Team_Info(index, type, TeamName[0]);
		}
	}

	return 0;
}

FindPlayer()
{
	new i = -1;

	while(i <= get_maxplayers())
	{
		if(is_user_connected(++i))
			return i;
	}

	return -1;
}
//**PLUGIN**//
public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    g_LongJump_force = register_cvar("longjump_force", "590");
    g_LongJump_height = register_cvar("longjump_height", "330");
    g_LongJump_cooldown = register_cvar("longjump_cooldown", "5.0");
    register_cvar("longjump_cost", "20");

    register_clcmd("say /blj", "buy_longjump");
    
    register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
    
    register_event("DeathMsg", "death", "a");
    register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
    set_task(300.0, "hirdetes")

}
public plugin_precache()
{
	precache_model(g_szLongJump_Model);
}
public hirdetes(id)
{
	ColorChat(id, GREEN, "^3[^4LongJump^3]^1Longjump képesség vásárlásához használd a ^4/blj ^1parancsot.")
}
public client_disconnected(id)
{
    g_hasLongJump[id] = false
}

public death()
{
    g_hasLongJump[read_data(2)] = false
}

public event_round_start()
{
    for (new i = 1; i <= 32; i++)
        g_hasLongJump[i] = false
}

public  buy_longjump(id)
{     
	if (!is_user_alive(id)) {
	ColorChat(id, GREEN, "^3[^4LongJump^3]^1Nem vagy életben, így nem veheted meg a ^3Longjump ^1képességet.")
	return;
	}
	if (g_hasLongJump[id]) {
	ColorChat(id, GREEN, "^3[^4LongJump^3]^1Már rendelkezel a ^3Longjump ^1képességgel.")
	return;
	}
	new koltseg = get_cvar_num("longjump_cost")
	new Health = get_user_health (id);
	if(Health >= koltseg)
	{
		set_user_health(id,Health-koltseg)
		g_hasLongJump[id] = true
		ColorChat(id, GREEN, "^3[^4LongJump^3]^1Sikeresen megvetted a ^3Longjump ^1képességet, most már tudsz hosszúakat ugrani.")
		ColorChat(id, GREEN, "^3[^4LongJump^3]^1Használathoz nyomd meg a ^3guggolás ^1gombot, és ^3ugorj, ^1miközben elöre haladsz.")

	}
	else
	{
		ColorChat(id, GREEN, "^3[^4LongJump^3]^1Nincs elég ^3HP-d, ^1hogy megvedd:^3Longjump")
	}
} 


public fw_PlayerPreThink(id)
{
    if (!is_user_alive(id))
        return FMRES_IGNORED

    static prev_buttons[33]

    if (prev_buttons[id] & IN_JUMP && !(pev(id, pev_button) & IN_JUMP)) {

        if (is_valid_ent(g_iWing[id])) {
            remove_entity(g_iWing[id]);
        }
    }
    else if (!(prev_buttons[id] & IN_JUMP) && (pev(id, pev_button) & IN_JUMP) && g_hasLongJump[id]) {

        new iEntity = g_iWing[id];
        if (!is_valid_ent(iEntity)) {
            if (!(iEntity = g_iWing[id] = create_entity("info_target"))) {
                return FMRES_IGNORED;
            }

            entity_set_model(iEntity, g_szLongJump_Model);
            entity_set_int(iEntity, EV_INT_movetype, MOVETYPE_FOLLOW);
            entity_set_edict(iEntity, EV_ENT_aiment, id);
        }
    }

    prev_buttons[id] = pev(id, pev_button);

	
    if (allow_LongJump(id))
    {
        static Float:velocity[3]
        velocity_by_aim(id, get_pcvar_num(g_LongJump_force), velocity)
        
        velocity[2] = get_pcvar_float(g_LongJump_height)
        
        set_pev(id, pev_velocity, velocity)
        
        g_last_LongJump_time[id] = get_gametime()
        
        g_LongJump_status[id] = LONGJUMP_COUNTDOWN
        g_LongJump_countdown_time[id] = get_gametime() + get_pcvar_float(g_LongJump_cooldown)
    }
    
    if (g_LongJump_status[id] == LONGJUMP_COUNTDOWN && get_gametime() >= g_LongJump_countdown_time[id])
    {
        g_LongJump_status[id] = LONGJUMP_READY
        set_hudmessage(0, 255, 0, -1.0, -1.0)
        show_hudmessage(id, "LONGJUMP Betöltve")
    }
    
    return FMRES_IGNORED; 
}


allow_LongJump(id)
{
    if (!g_hasLongJump[id])
        return false
    
    if (!(pev(id, pev_flags) & FL_ONGROUND) || fm_get_speed(id) < 80)
        return false
    
    static buttons
    buttons = pev(id, pev_button)
    
    if (!is_user_bot(id) && (!(buttons & IN_JUMP) || !(buttons & IN_DUCK)))
        return false
    
    if (g_LongJump_status[id] == LONGJUMP_COUNTDOWN)
        return false
    
    return true
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
