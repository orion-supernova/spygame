import { mutation, query } from './_generated/server';

/**
 * Original generic-venue location set. ~24 locations, each with 8 role
 * suggestions. All names and roles are generic and authored fresh — no
 * card text from any commercial Spyfall product is reused.
 */
const SEED: Array<{ name: string; roles: string[] }> = [
  {
    name: 'Coastal Beach',
    roles: ['Lifeguard', 'Surfer', 'Sandcastle Builder', 'Tourist', 'Ice Cream Vendor', 'Beach Photographer', 'Volleyball Player', 'Snorkeling Guide'],
  },
  {
    name: 'Mountain Lodge',
    roles: ['Lodge Manager', 'Ski Instructor', 'Hiker', 'Chef', 'Waiter', 'Maintenance Worker', 'Travel Blogger', 'Hot Tub Attendant'],
  },
  {
    name: 'Casino Floor',
    roles: ['Pit Boss', 'Card Dealer', 'High Roller', 'Cocktail Server', 'Security Guard', 'Slot Technician', 'Bartender', 'Lounge Singer'],
  },
  {
    name: 'Cruise Liner',
    roles: ['Captain', 'Cruise Director', 'Bartender', 'Steward', 'Passenger', 'Engineer', 'Entertainer', 'Spa Therapist'],
  },
  {
    name: 'Submarine',
    roles: ['Commander', 'Sonar Operator', 'Cook', 'Engineer', 'Navigator', 'Medic', 'Radio Officer', 'Torpedo Technician'],
  },
  {
    name: 'Pirate Ship',
    roles: ['Captain', 'First Mate', 'Cook', 'Cabin Boy', 'Lookout', 'Cannon Operator', 'Treasure Map Reader', 'Parrot Trainer'],
  },
  {
    name: 'Space Station',
    roles: ['Commander', 'Astronaut', 'Engineer', 'Botanist', 'Medical Officer', 'Mission Control Liaison', 'Robotics Specialist', 'Space Tourist'],
  },
  {
    name: 'Day Spa',
    roles: ['Receptionist', 'Massage Therapist', 'Aesthetician', 'Yoga Instructor', 'Manager', 'Customer', 'Sauna Attendant', 'Nail Technician'],
  },
  {
    name: 'Hospital',
    roles: ['Surgeon', 'Nurse', 'Patient', 'Anesthesiologist', 'Janitor', 'Pharmacist', 'Receptionist', 'Visitor'],
  },
  {
    name: 'Hotel Suite',
    roles: ['Concierge', 'Housekeeper', 'Bellhop', 'Front Desk Clerk', 'Room Service Server', 'Manager', 'Guest', 'Security'],
  },
  {
    name: 'Embassy',
    roles: ['Ambassador', 'Visa Clerk', 'Translator', 'Security Officer', 'Diplomat', 'Cultural Attaché', 'Driver', 'Visitor'],
  },
  {
    name: 'Polar Research Station',
    roles: ['Lead Researcher', 'Climatologist', 'Cook', 'Mechanic', 'Biologist', 'Pilot', 'Communications Officer', 'Field Assistant'],
  },
  {
    name: 'Film Studio',
    roles: ['Director', 'Lead Actor', 'Camera Operator', 'Sound Engineer', 'Makeup Artist', 'Producer', 'Stunt Coordinator', 'Set Designer'],
  },
  {
    name: 'Military Base',
    roles: ['Commanding Officer', 'Sergeant', 'Recruit', 'Mechanic', 'Cook', 'Medic', 'Drill Instructor', 'Communications Specialist'],
  },
  {
    name: 'Carnival',
    roles: ['Ride Operator', 'Ticket Seller', 'Cotton Candy Vendor', 'Clown', 'Fortune Teller', 'Game Booth Attendant', 'Performer', 'Visitor'],
  },
  {
    name: 'Bank Vault',
    roles: ['Manager', 'Teller', 'Security Guard', 'Customer', 'Auditor', 'Loan Officer', 'Vault Technician', 'Janitor'],
  },
  {
    name: 'Airliner Cabin',
    roles: ['Captain', 'Co-Pilot', 'Flight Attendant', 'Passenger', 'Air Marshal', 'Frequent Flyer', 'Crying Baby Wrangler', 'Tired Business Traveler'],
  },
  {
    name: 'University Campus',
    roles: ['Professor', 'Student', 'Librarian', 'Janitor', 'Dean', 'Teaching Assistant', 'Cafeteria Worker', 'Visitor'],
  },
  {
    name: 'Stage Theater',
    roles: ['Director', 'Lead Actor', 'Stagehand', 'Lighting Technician', 'Audience Member', 'Usher', 'Costume Designer', 'Box Office Clerk'],
  },
  {
    name: 'Subway Train',
    roles: ['Conductor', 'Commuter', 'Tourist', 'Busker', 'Pickpocket Watcher', 'Off-Duty Worker', 'Student', 'Transit Officer'],
  },
  {
    name: 'Race Track',
    roles: ['Driver', 'Pit Crew Chief', 'Mechanic', 'Announcer', 'Spectator', 'Track Marshal', 'Sponsor Rep', 'Trophy Presenter'],
  },
  {
    name: 'Police Precinct',
    roles: ['Detective', 'Patrol Officer', 'Sergeant', 'Forensic Tech', 'Receptionist', 'Suspect', 'Lawyer', 'Witness'],
  },
  {
    name: 'Restaurant Kitchen',
    roles: ['Head Chef', 'Sous Chef', 'Line Cook', 'Dishwasher', 'Server', 'Pastry Chef', 'Food Critic', 'Owner'],
  },
  {
    name: 'Service Garage',
    roles: ['Mechanic', 'Service Advisor', 'Apprentice', 'Customer', 'Parts Manager', 'Tow Driver', 'Inspector', 'Detailer'],
  },
];

// Idempotent: returns { inserted: 0 } if locations already exist. Public so
// the CLI can call `npx convex run locations:seed`.
export const seed = mutation({
  args: {},
  handler: async (ctx) => {
    const existing = await ctx.db.query('locations').collect();
    if (existing.length > 0) return { inserted: 0 };
    for (const loc of SEED) {
      await ctx.db.insert('locations', loc);
    }
    return { inserted: SEED.length };
  },
});

export const list = query({
  args: {},
  handler: async (ctx) => {
    const all = await ctx.db.query('locations').collect();
    return all.map((l) => ({ _id: l._id, name: l.name }));
  },
});
