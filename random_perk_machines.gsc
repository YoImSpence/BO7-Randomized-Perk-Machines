// Paradox Junction Randomized Perk Machine Spawns for all BO7 Maps (Made by Spence)
// Forces all perk machines to randomize on load in of each zombie game played just like in Paradox Junction
// Works on all maps besides Paradox Junction (feature already exist)
// This mod uses some code from Taylor's (@aspect.ofautumn) zm_classic_perks to allow the mods to work together without issues, this mod can be used without the "zm_classic_perks" mod if wanted!

#using scripts\common\system;
#using scripts\common\utility;
#using scripts\common\callbacks;

#namespace random_perk_machines;

function private autoexec __init__system__()
{
    level thread init();
}

function init()
{
    level endon( #"game_ended" );

    if ( isdefined( level.mapname ) )
    {
        if ( level.mapname == "zm_sat_mantis" || issubstr( level.mapname, "doa" ) || issubstr( level.mapname, "deadops" ) )
        {
            return;
        }
    }

    level thread randomize_perk_locations();
}

function randomize_perk_locations()
{
    level endon( #"game_ended" );

    n_tries = 0;
    while ( n_tries < 30 )
    {
        if ( isdefined( level.a_s_perk_machines ) && level.a_s_perk_machines.size > 1 && isdefined( level._custom_perks ) )
        {
            break;
        }
        n_tries++;
        wait 0.5;
    }

    if ( !isdefined( level.a_s_perk_machines ) || level.a_s_perk_machines.size < 2 || !isdefined( level._custom_perks ) )
    {
        return;
    }

    // Initial perk randomize on map load
    wait 2;
    do_shuffle();

    // Secondary perk randomize to cleanup any bugged or missed perk machines (Helps make sure every perk machine gets randomized but stil allows for some original spawns)
    wait 1;
    do_shuffle();

    // Utility for applying and reapplying perk machine triggers/interactions (Helps fix most cases of perks losing their interaction message / trigger to buy the perk)
    wait 4;
    reapply_interacts_only();
}

function do_shuffle()
{
    machines = level.a_s_perk_machines;
    if ( !isdefined( machines ) || machines.size < 2 )
    {
        return;
    }

    aliases = [];
    aliases["a_mod"] = 1;
    aliases["d_mod"] = 1;
    aliases["m_mod"] = 1;
    aliases["w_mod"] = 1;
    aliases["y_mod"] = 1;
    aliases["z_mod"] = 1;
    aliases["vulture"] = 1;

    perk_to_scriptable = [];
    foreach ( perk_name, perk_data in level._custom_perks )
    {
        if ( isdefined( perk_data ) && isdefined( perk_data.str_scriptable ) )
        {
            perk_to_scriptable[ perk_name ] = perk_data.str_scriptable;
        }
    }

    a_machines = [];
    a_models = [];
    a_interacts = [];
    a_origins = [];
    a_angles = [];

    foreach ( machine in machines )
    {
        if ( !isdefined( machine ) || !isdefined( machine.mdl_perk_machine ) || !isdefined( machine.origin ) )
        {
            continue;
        }

        model = machine.mdl_perk_machine.model;
        if ( !isdefined( model ) )
        {
            continue;
        }

        matched = 0;
        foreach ( perk_name, scriptable in perk_to_scriptable )
        {
            if ( issubstr( model, scriptable ) )
            {
                matched = 1;
                break;
            }
        }

        if ( !matched )
        {
            foreach ( alias, _ in aliases )
            {
                if ( issubstr( model, alias ) )
                {
                    matched = 1;
                    break;
                }
            }
        }

        if ( !matched )
        {
            continue;
        }

        a_machines[ a_machines.size ] = machine;
        a_models[ a_models.size ] = machine.mdl_perk_machine;
        a_interacts[ a_interacts.size ] = isdefined( machine.mdl_perk_machine.interact ) ? machine.mdl_perk_machine.interact : undefined;
        a_origins[ a_origins.size ] = machine.origin;
        a_angles[ a_angles.size ] = isdefined( machine.angles ) ? machine.angles : ( 0, 0, 0 );
    }

    if ( a_machines.size < 2 )
    {
        return;
    }

    order = [];
    for ( i = 0; i < a_machines.size; i++ )
    {
        order[ i ] = i;
    }

    max_attempts = 15;
    for ( attempt = 0; attempt < max_attempts; attempt++ )
    {
        for ( i = order.size - 1; i > 0; i-- )
        {
            j = randomint( i + 1 );
            temp = order[ i ];
            order[ i ] = order[ j ];
            order[ j ] = temp;
        }

        fixed = 0;
        for ( i = 0; i < order.size; i++ )
        {
            if ( order[ i ] == i )
            {
                fixed++;
            }
        }

        if ( fixed == 0 )
        {
            break;
        }
    }

    for ( i = 0; i < a_machines.size; i++ )
    {
        src = order[ i ];
        mdl = a_models[ src ];
        interact = a_interacts[ src ];

        if ( !isdefined( mdl ) )
        {
            continue;
        }

        mdl.origin = a_origins[ i ];
        mdl.angles = a_angles[ i ];

        if ( isdefined( interact ) && isent( interact ) )
        {
            interact.origin = a_origins[ i ];
            interact.angles = a_angles[ i ];
        }

        a_machines[ i ].mdl_perk_machine = mdl;
    }
}

function reapply_interacts_only()
{
    if ( !isdefined( level.a_s_perk_machines ) )
    {
        return;
    }

    foreach ( machine in level.a_s_perk_machines )
    {
        if ( !isdefined( machine ) || !isdefined( machine.mdl_perk_machine ) )
        {
            continue;
        }

        mdl = machine.mdl_perk_machine;

        if ( isdefined( mdl.interact ) && isent( mdl.interact ) )
        {
            mdl.interact.origin = mdl.origin;
            mdl.interact.angles = isdefined( mdl.angles ) ? mdl.angles : ( 0, 0, 0 );
        }
    }
}