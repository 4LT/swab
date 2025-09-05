static const float DRILL_SHIFT = 8;
static const float DRILL_SHIFT_POW = 1<<DRILL_SHIFT;
static const float ROCKET_MASK = DRILL_SHIFT_POW - 1;
static const float DRILL_MASK = ROCKET_MASK << DRILL_SHIFT;

float(float ammo_rockets) get_rockets = {
    return ammo_rockets & ROCKET_MASK;
}

float(float ammo_rockets) get_drills = {
    return (ammo_rockets & DRILL_MASK) / DRILL_SHIFT_POW;
}

float(float ammo_rockets, float rockets) set_rockets = {
    return (ammo_rockets & ~ROCKET_MASK) | (rockets & ROCKET_MASK);
}

float(float ammo_rockets, float drills) set_drills = {
    return (ammo_rockets & ~DRILL_MASK) | ((drills * DRILL_SHIFT_POW) & DRILL_MASK);
}

static float(float rockets, float drills) merge_rockets_drills_unchecked = {
    return (drills * DRILL_SHIFT_POW) | rockets;
}

float(float ammo_rockets) limit_rockets_drills = {
    float rockets, drills;

    rockets = min(MAX_AMMO_ROCKETS, get_rockets(ammo_rockets));
    drills = min(MAX_AMMO_ROCKETS, get_drills(ammo_rockets));
    return merge_rockets_drills_unchecked(rockets, drills);
}

float(
    float ammo_rockets,
    float new_rockets,
    float new_drills
) add_rockets_drills = {
    float rockets, drills;

    rockets = clamp(
        get_rockets(ammo_rockets) + new_rockets,
        0,
        MAX_AMMO_ROCKETS
    );

    drills = clamp(
        get_drills(ammo_rockets) + new_drills,
        0,
        MAX_AMMO_ROCKETS
    );

    return merge_rockets_drills_unchecked(rockets, drills);
}

float(float ammo_rockets1, float ammo_rockets2) combine_rockets_drills =
{
    float rockets1, drills1;

    rockets1 = get_rockets(ammo_rockets1);
    drills1 = get_drills(ammo_rockets1);

    return add_rockets_drills(ammo_rockets2, rockets1, drills1);
}
