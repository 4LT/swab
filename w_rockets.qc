/*
===============

ROCKETS

===============
*/

void(vector org, float rad) T_GibDownedZombies =
{
	if (rad < 72) return;	// not a big enough blast
	entity head;
	
	// look a little too high since we'll assume zombies are lower than their 
	// actual origin, which is 24u off the ground
	head = findradiusplus(org + '0 0 16', rad, type, "zombie");
	
	while(head)
	{
		if ( head.customflags & CFL_KNOCKEDDOWN &&	// on ground
			 head.solid == SOLID_NOT && // can't be hurt otherwise
			CanDamage(head, org) &&	// in sight
			rad - vlen(head.origin - org) > 0.5 * head.health	// close enough to hurt
			)
		{
			T_Damage (head, self, self.trueowner, head.health + 10);
		}
		head = head.chain;
	}
}


// =======================================================

void() T_ExplosiveTouch =
{
	if (other.classname == "monster_shambler")
		BecomeWeakExplosion();
	else
		BecomeExplosion();
}

void() T_MissileExplode =
{
	local float	damg, dmgtype;
	damg = 100 + random()*20;
	
	if (other.health)
	{
        // so ogre rockets kill zombies despite being too weak
        // drills embedded in shamblers deal full damage
        dmgtype = ((self.classname != "drill") * DMGTYPE_EXPLOSION) | DMGTYPE_ZKILL;
		T_Damage (other, self, self.trueowner, damg, dmgtype);	
	}

	// don't do radius damage to other, because all damage will be done in the impact
	T_RadiusDamage (self, self.trueowner, 120, other, DMGTYPE_EXPLOSION);
}

void() T_MissileTouch =
{
	if (other == self.owner) return;		// don't explode on owner
	if (CheckProjectilePassthru()) return;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

    if (self.classname == "drill" && (other.flags & (FL_MONSTER | FL_CLIENT))) {
        T_DrillTouch();
    } else {
        T_MissileExplode();

        self.origin = self.origin - 8*normalize(self.velocity);
        T_ExplosiveTouch();
    }
}

static vector(entity e) center = {
    return (e.absmin + e.absmax) / 2;
}

void() T_DrillTouch = {
    vector ctr;
    self.count = 7;
    self.modelindex = 0;
    self.movetype = MOVETYPE_NONE;
    self.solid = SOLID_NOT;
    self.speed = vlen(self.velocity);
    self.type = "drill_implanted";
    self.buddy = other;
    // cache location and yaw of other
    self.dest1 = other.origin;
    self.ideal_yaw = other.angles.y;

    ctr = center(other);
    // place on bounding-box-sized ellipsoid centered on other
    setorigin(self, cwisemul(normalize(self.origin - ctr), other.size) / 2 + ctr);
	sound (self, CHAN_WEAPON, "drill/loop.wav", 1, ATTN_NORM);

    DrillThink();
}

void() DrillThink = {
    vector norm, relpos, vel;
    
    self.count-= 1;
    DrillOffsetPosition();
    norm = normalize(self.origin - center(self.buddy));

    // if even, deal damage
    if ((!(self.count & 1)) && self.count > 0) {
        T_Damage(self.buddy, self, self.trueowner, self.dmg);
        relpos = self.origin - self.buddy.origin;
        SpawnBlood(relpos + norm * 8, norm * 40, self.dmg);
        vel = norm * 300 + [
            random() * 40 - 20,
            random() * 40 - 20,
            0
        ];
        vel_z+= random() * 20 + 30;
        if (self.buddy.maxs_x > VEC_HULL_MAX_x) {
            ThrowGib("progs/gib3.mdl", vel);
        } else {
            ThrowGib("progs/zom_gib.mdl", vel);
        }
    }

    if (self.count <= 0) {
        if (self.buddy.health > 0) {
            other = self.buddy;
            T_MissileExplode();
            self.origin+= norm * 8;
            BecomeExplosion();
        } else {
            // return to missile
            SUB_ChangeModel(self, "progs/missile.mdl");
            self.movetype = MOVETYPE_FLYMISSILE;
            self.solid = SOLID_BBOX;
            self.type = "missile";
            self.velocity = self.speed * -norm;
            self.groundentity = world;
            self.flags = (~FL_ONGROUND) & self.flags;
            self.angles = vectoangles(-norm);
        }
	    sound (self, CHAN_WEAPON, "misc/null.wav", 0, ATTN_NORM);
    } else {
        self.think = DrillThink;
        self.nextthink = time + 0.1;
    }
}

void DrillOffsetPosition() {
    vector relpos, hpos, newpos, ang;
    float r;

    relpos = self.origin - self.dest1;
    hpos = relpos;
    hpos_z = 0;
    r = vlen(hpos);
    ang = vectoangles(hpos);
    ang_y+= self.buddy.angles_y - self.ideal_yaw;
    makevectors(ang);
    newpos = v_forward * r;
    newpos_z = relpos_z;
    newpos+= self.buddy.origin;

    setorigin(self, newpos);
    self.dest1 = self.buddy.origin;
    self.ideal_yaw = self.buddy.angles.y;
}

/*
================
W_FireRocket
player rocket launch inherited from generic launch_rocket
================
*/
void() W_FireRocket =
{
	local vector loc;
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	self.punchangle_x = -2;
	
	makevectors (self.v_angle);
	loc = self.origin + v_forward * 8 + '0 0 16';
	
    if (self.items & IT_DRILLER) {
        sound (self, CHAN_WEAPON, "drill/shot.wav", 1, ATTN_NORM);
        launch_drill(loc, v_forward * 1000);
    } else {
        sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
        launch_rocket( loc, v_forward * 1000 );
    }

	self.attack_finished = time + 0.8;
}

//=============================================================================

/*
===============

GERNADES

===============
*/

void() GrenadeExplode =
{
	T_RadiusDamage (self, self.trueowner, 120, world, DMGTYPE_EXPLOSION);
	//T_GibDownedZombies (self, 120);
	
	BecomeExplosion ();
}

void() GrenadeHandlePhysics;

void() GrenadeTouch =
{
	if (other == self.owner ) return;		// don't explode on owner
	if (CheckProjectilePassthru()) return;
	if (other.takedamage == DAMAGE_AIM)
	{
		self.velocity = '0 0 0';
		T_MissileExplode();
		T_ExplosiveTouch();
		return;
	}

	GrenadeHandlePhysics();

	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);	// bounce sound
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
}

/*
================
W_FireGrenade
================
*/
void() W_FireGrenade =
{
	entity g;
	float base;
	vector gvel;
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	self.punchangle_x = -2;

	// set grenade speed	
	makevectors (self.v_angle);
	base = 200;
	if (self.v_angle_x)
		gvel = v_forward * base * 3 + v_up * base + crandom() * v_right * 10 + crandom() * v_up * 10;
	else
	{
		gvel = aim(self, AUTOAIM_DIST);
		gvel = gvel * base * 3;
		gvel_z = base;
	}
	
	g = launch_grenade(self.origin, gvel);
	self.attack_finished = time + 0.6;
	g.touch = GrenadeTouch;
	g.th_die = GrenadeExplode;
}
