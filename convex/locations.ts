import { mutation, query } from './_generated/server';

/**
 * Original generic-venue location set. ~24 locations, each with 8 role
 * suggestions. All names and roles are generic and authored fresh — no
 * card text from any commercial Spyfall product is reused.
 *
 * IMPORTANT: When adding/removing roles, keep the English `roles` array and
 * every locale's `roles` array in lock-step ORDER. The server matches a
 * stored English role string by index in `roles`, then projects the same
 * index from `translations.<locale>.roles`. Reordering English without
 * reordering Turkish (or vice versa) silently swaps role text on read.
 */
type SeedLocation = {
  name: string;
  roles: string[];
  translations: {
    tr: { name: string; roles: string[] };
  };
};

const SEED: SeedLocation[] = [
  {
    name: 'Coastal Beach',
    roles: ['Lifeguard', 'Surfer', 'Sandcastle Builder', 'Tourist', 'Ice Cream Vendor', 'Beach Photographer', 'Volleyball Player', 'Snorkeling Guide'],
    translations: {
      tr: {
        name: 'Sahil',
        roles: ['Cankurtaran', 'Sörfçü', 'Kumdan Kale Yapan', 'Turist', 'Dondurmacı', 'Plaj Fotoğrafçısı', 'Voleybolcu', 'Şnorkel Rehberi'],
      },
    },
  },
  {
    name: 'Mountain Lodge',
    roles: ['Lodge Manager', 'Ski Instructor', 'Hiker', 'Chef', 'Waiter', 'Maintenance Worker', 'Travel Blogger', 'Hot Tub Attendant'],
    translations: {
      tr: {
        name: 'Dağ Evi',
        roles: ['Tesis Müdürü', 'Kayak Hocası', 'Doğa Yürüyüşçüsü', 'Şef', 'Garson', 'Bakım Görevlisi', 'Gezi Bloggeri', 'Jakuzi Görevlisi'],
      },
    },
  },
  {
    name: 'Casino Floor',
    roles: ['Pit Boss', 'Card Dealer', 'High Roller', 'Cocktail Server', 'Security Guard', 'Slot Technician', 'Bartender', 'Lounge Singer'],
    translations: {
      tr: {
        name: 'Kumarhane',
        roles: ['Salon Şefi', 'Kart Krupiyesi', 'Yüksek Bahisçi', 'Kokteyl Garsonu', 'Güvenlik Görevlisi', 'Slot Teknisyeni', 'Barmen', 'Sahne Şarkıcısı'],
      },
    },
  },
  {
    name: 'Cruise Liner',
    roles: ['Captain', 'Cruise Director', 'Bartender', 'Steward', 'Passenger', 'Engineer', 'Entertainer', 'Spa Therapist'],
    translations: {
      tr: {
        name: 'Yolcu Gemisi',
        roles: ['Kaptan', 'Eğlence Müdürü', 'Barmen', 'Kamarot', 'Yolcu', 'Mühendis', 'Şovmen', 'Spa Terapisti'],
      },
    },
  },
  {
    name: 'Submarine',
    roles: ['Commander', 'Sonar Operator', 'Cook', 'Engineer', 'Navigator', 'Medic', 'Radio Officer', 'Torpedo Technician'],
    translations: {
      tr: {
        name: 'Denizaltı',
        roles: ['Komutan', 'Sonar Operatörü', 'Aşçı', 'Mühendis', 'Seyir Subayı', 'Sağlıkçı', 'Telsiz Subayı', 'Torpido Teknisyeni'],
      },
    },
  },
  {
    name: 'Pirate Ship',
    roles: ['Captain', 'First Mate', 'Cook', 'Cabin Boy', 'Lookout', 'Cannon Operator', 'Treasure Map Reader', 'Parrot Trainer'],
    translations: {
      tr: {
        name: 'Korsan Gemisi',
        roles: ['Kaptan', 'Yardımcı Kaptan', 'Aşçı', 'Miço', 'Gözcü', 'Topçu', 'Hazine Haritacısı', 'Papağan Eğiticisi'],
      },
    },
  },
  {
    name: 'Space Station',
    roles: ['Commander', 'Astronaut', 'Engineer', 'Botanist', 'Medical Officer', 'Mission Control Liaison', 'Robotics Specialist', 'Space Tourist'],
    translations: {
      tr: {
        name: 'Uzay İstasyonu',
        roles: ['Komutan', 'Astronot', 'Mühendis', 'Botanikçi', 'Sağlık Subayı', 'Görev Kontrol Bağlantısı', 'Robotik Uzmanı', 'Uzay Turisti'],
      },
    },
  },
  {
    name: 'Day Spa',
    roles: ['Receptionist', 'Massage Therapist', 'Aesthetician', 'Yoga Instructor', 'Manager', 'Customer', 'Sauna Attendant', 'Nail Technician'],
    translations: {
      tr: {
        name: 'Güzellik Merkezi',
        roles: ['Resepsiyonist', 'Masöz', 'Estetisyen', 'Yoga Hocası', 'Müdür', 'Müşteri', 'Sauna Görevlisi', 'Manikürcü'],
      },
    },
  },
  {
    name: 'Hospital',
    roles: ['Surgeon', 'Nurse', 'Patient', 'Anesthesiologist', 'Janitor', 'Pharmacist', 'Receptionist', 'Visitor'],
    translations: {
      tr: {
        name: 'Hastane',
        roles: ['Cerrah', 'Hemşire', 'Hasta', 'Anestezi Uzmanı', 'Temizlikçi', 'Eczacı', 'Resepsiyonist', 'Ziyaretçi'],
      },
    },
  },
  {
    name: 'Hotel Suite',
    roles: ['Concierge', 'Housekeeper', 'Bellhop', 'Front Desk Clerk', 'Room Service Server', 'Manager', 'Guest', 'Security'],
    translations: {
      tr: {
        name: 'Otel',
        roles: ['Konsiyerj', 'Kat Görevlisi', 'Komi', 'Resepsiyonist', 'Oda Servisi', 'Müdür', 'Misafir', 'Güvenlik'],
      },
    },
  },
  {
    name: 'Embassy',
    roles: ['Ambassador', 'Visa Clerk', 'Translator', 'Security Officer', 'Diplomat', 'Cultural Attaché', 'Driver', 'Visitor'],
    translations: {
      tr: {
        name: 'Büyükelçilik',
        roles: ['Büyükelçi', 'Vize Memuru', 'Tercüman', 'Güvenlik Görevlisi', 'Diplomat', 'Kültür Ataşesi', 'Şoför', 'Ziyaretçi'],
      },
    },
  },
  {
    name: 'Polar Research Station',
    roles: ['Lead Researcher', 'Climatologist', 'Cook', 'Mechanic', 'Biologist', 'Pilot', 'Communications Officer', 'Field Assistant'],
    translations: {
      tr: {
        name: 'Kutup Araştırma Üssü',
        roles: ['Başaraştırmacı', 'İklim Bilimci', 'Aşçı', 'Tamirci', 'Biyolog', 'Pilot', 'Telsiz Subayı', 'Saha Asistanı'],
      },
    },
  },
  {
    name: 'Film Studio',
    roles: ['Director', 'Lead Actor', 'Camera Operator', 'Sound Engineer', 'Makeup Artist', 'Producer', 'Stunt Coordinator', 'Set Designer'],
    translations: {
      tr: {
        name: 'Film Stüdyosu',
        roles: ['Yönetmen', 'Başrol Oyuncusu', 'Kameraman', 'Ses Mühendisi', 'Makyöz', 'Yapımcı', 'Dublör Koordinatörü', 'Set Tasarımcısı'],
      },
    },
  },
  {
    name: 'Military Base',
    roles: ['Commanding Officer', 'Sergeant', 'Recruit', 'Mechanic', 'Cook', 'Medic', 'Drill Instructor', 'Communications Specialist'],
    translations: {
      tr: {
        name: 'Askeri Üs',
        roles: ['Komutan', 'Çavuş', 'Acemi Er', 'Tamirci', 'Aşçı', 'Sağlıkçı', 'Talim Eğitmeni', 'Muhabere Uzmanı'],
      },
    },
  },
  {
    name: 'Carnival',
    roles: ['Ride Operator', 'Ticket Seller', 'Cotton Candy Vendor', 'Clown', 'Fortune Teller', 'Game Booth Attendant', 'Performer', 'Visitor'],
    translations: {
      tr: {
        name: 'Lunapark',
        roles: ['Lunapark Görevlisi', 'Bilet Satıcısı', 'Pamuk Şekercisi', 'Palyaço', 'Falcı', 'Stand Görevlisi', 'Sokak Sanatçısı', 'Ziyaretçi'],
      },
    },
  },
  {
    name: 'Bank Vault',
    roles: ['Manager', 'Teller', 'Security Guard', 'Customer', 'Auditor', 'Loan Officer', 'Vault Technician', 'Janitor'],
    translations: {
      tr: {
        name: 'Banka Kasası',
        roles: ['Müdür', 'Veznedar', 'Güvenlik Görevlisi', 'Müşteri', 'Müfettiş', 'Kredi Uzmanı', 'Kasa Teknisyeni', 'Temizlikçi'],
      },
    },
  },
  {
    name: 'Airliner Cabin',
    roles: ['Captain', 'Co-Pilot', 'Flight Attendant', 'Passenger', 'Air Marshal', 'Frequent Flyer', 'Crying Baby Wrangler', 'Tired Business Traveler'],
    translations: {
      tr: {
        name: 'Uçak Kabini',
        roles: ['Kaptan Pilot', 'Yardımcı Pilot', 'Hostes', 'Yolcu', 'Hava Polisi', 'Sık Uçan Yolcu', 'Ağlayan Bebek Sahibi', 'Yorgun İş İnsanı'],
      },
    },
  },
  {
    name: 'University Campus',
    roles: ['Professor', 'Student', 'Librarian', 'Janitor', 'Dean', 'Teaching Assistant', 'Cafeteria Worker', 'Visitor'],
    translations: {
      tr: {
        name: 'Üniversite Kampüsü',
        roles: ['Profesör', 'Öğrenci', 'Kütüphaneci', 'Temizlikçi', 'Dekan', 'Asistan', 'Yemekhane Görevlisi', 'Ziyaretçi'],
      },
    },
  },
  {
    name: 'Stage Theater',
    roles: ['Director', 'Lead Actor', 'Stagehand', 'Lighting Technician', 'Audience Member', 'Usher', 'Costume Designer', 'Box Office Clerk'],
    translations: {
      tr: {
        name: 'Tiyatro Sahnesi',
        roles: ['Yönetmen', 'Başrol Oyuncusu', 'Sahne Görevlisi', 'Işık Teknisyeni', 'Seyirci', 'Yer Gösterici', 'Kostüm Tasarımcısı', 'Gişe Görevlisi'],
      },
    },
  },
  {
    name: 'Subway Train',
    roles: ['Conductor', 'Commuter', 'Tourist', 'Busker', 'Pickpocket Watcher', 'Off-Duty Worker', 'Student', 'Transit Officer'],
    translations: {
      tr: {
        name: 'Metro',
        roles: ['Vatman', 'Yolcu', 'Turist', 'Sokak Müzisyeni', 'Yankesici Avcısı', 'Mesai Sonrası Yolcu', 'Öğrenci', 'Metro Görevlisi'],
      },
    },
  },
  {
    name: 'Race Track',
    roles: ['Driver', 'Pit Crew Chief', 'Mechanic', 'Announcer', 'Spectator', 'Track Marshal', 'Sponsor Rep', 'Trophy Presenter'],
    translations: {
      tr: {
        name: 'Yarış Pisti',
        roles: ['Pilot', 'Pit Şefi', 'Tamirci', 'Spiker', 'Seyirci', 'Pist Görevlisi', 'Sponsor Temsilcisi', 'Kupa Takdimcisi'],
      },
    },
  },
  {
    name: 'Police Precinct',
    roles: ['Detective', 'Patrol Officer', 'Sergeant', 'Forensic Tech', 'Receptionist', 'Suspect', 'Lawyer', 'Witness'],
    translations: {
      tr: {
        name: 'Karakol',
        roles: ['Dedektif', 'Devriye Polisi', 'Başçavuş', 'Olay Yeri Uzmanı', 'Santral Memuru', 'Şüpheli', 'Avukat', 'Tanık'],
      },
    },
  },
  {
    name: 'Restaurant Kitchen',
    roles: ['Head Chef', 'Sous Chef', 'Line Cook', 'Dishwasher', 'Server', 'Pastry Chef', 'Food Critic', 'Owner'],
    translations: {
      tr: {
        name: 'Restoran Mutfağı',
        roles: ['Şef', 'Yardımcı Şef', 'Aşçı', 'Bulaşıkçı', 'Garson', 'Pasta Şefi', 'Yemek Eleştirmeni', 'Patron'],
      },
    },
  },
  {
    name: 'Service Garage',
    roles: ['Mechanic', 'Service Advisor', 'Apprentice', 'Customer', 'Parts Manager', 'Tow Driver', 'Inspector', 'Detailer'],
    translations: {
      tr: {
        name: 'Tamirhane',
        roles: ['Tamirci', 'Servis Danışmanı', 'Çırak', 'Müşteri', 'Parça Sorumlusu', 'Çekici Şoförü', 'Eksper', 'Detaycı'],
      },
    },
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

/**
 * One-shot, re-runnable migration. For every SEED entry that exists in the
 * DB by canonical English name but lacks a `translations.tr` block, patch
 * it in. No-op for rows that already have Turkish.
 *
 * Run after deploying schema + new SEED:
 *   npx convex run locations:backfillTranslations
 */
export const backfillTranslations = mutation({
  args: {},
  handler: async (ctx) => {
    let patched = 0;
    const all = await ctx.db.query('locations').collect();
    for (const seed of SEED) {
      const match = all.find((l) => l.name === seed.name);
      if (!match) continue;
      if (match.translations?.tr) continue;
      await ctx.db.patch(match._id, { translations: seed.translations });
      patched++;
    }
    return { patched };
  },
});

export const list = query({
  args: {},
  handler: async (ctx) => {
    const all = await ctx.db.query('locations').collect();
    return all.map((l) => ({ _id: l._id, name: l.name }));
  },
});
