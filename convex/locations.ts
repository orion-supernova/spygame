import { v } from 'convex/values';

import { mutation, query } from './_generated/server';

const LOCALE_VALIDATOR = v.optional(v.union(v.literal('en'), v.literal('tr')));

/**
 * Original generic-venue location set + paid bundle packs. Each location
 * has 11 role suggestions so a 12-player room (min 1 spy = 11 civilians)
 * always assigns unique roles. All names and roles are authored fresh —
 * no card text from any commercial Spyfall product is reused.
 *
 * IMPORTANT: When adding/removing roles, keep the English `roles` array
 * and every locale's `roles` array in lock-step ORDER. The server matches
 * a stored English role string by index in `roles`, then projects the
 * same index from `translations.<locale>.roles`. Reordering English
 * without reordering Turkish (or vice versa) silently swaps role text on
 * read.
 *
 * `bundleSlug` is undefined for the free 24-location set and set to a
 * bundle slug for paid-pack locations. The location pool at game start =
 * free + locations whose bundleSlug is in the host's owned set.
 */
type SeedLocation = {
  name: string;
  roles: string[];
  bundleSlug?: string;
  translations: {
    tr: { name: string; roles: string[] };
  };
};

// Free set — always available regardless of bundle ownership.
const FREE: SeedLocation[] = [
  {
    name: 'Coastal Beach',
    roles: ['Lifeguard', 'Surfer', 'Sandcastle Builder', 'Tourist', 'Ice Cream Vendor', 'Beach Photographer', 'Volleyball Player', 'Snorkeling Guide', 'Metal Detectorist', 'Sunburned Tourist', "Lifeguard's Crush"],
    translations: {
      tr: {
        name: 'Sahil',
        roles: ['Cankurtaran', 'Sörfçü', 'Kumdan Kale Yapan', 'Turist', 'Dondurmacı', 'Plaj Fotoğrafçısı', 'Voleybolcu', 'Şnorkel Rehberi', 'Metal Dedektörcüsü', 'Yanmış Turist', 'Cankurtaranın Sevgilisi'],
      },
    },
  },
  {
    name: 'Mountain Lodge',
    roles: ['Lodge Manager', 'Ski Instructor', 'Hiker', 'Chef', 'Waiter', 'Maintenance Worker', 'Travel Blogger', 'Hot Tub Attendant', 'Snow Plow Driver', 'Lost Skier', 'Après-Ski Bartender'],
    translations: {
      tr: {
        name: 'Dağ Evi',
        roles: ['Tesis Müdürü', 'Kayak Hocası', 'Doğa Yürüyüşçüsü', 'Şef', 'Garson', 'Bakım Görevlisi', 'Gezi Bloggeri', 'Jakuzi Görevlisi', 'Kar Küreyici', 'Kaybolmuş Kayakçı', 'Apre-Ski Barmeni'],
      },
    },
  },
  {
    name: 'Casino Floor',
    roles: ['Pit Boss', 'Card Dealer', 'High Roller', 'Cocktail Server', 'Security Guard', 'Slot Technician', 'Bartender', 'Lounge Singer', 'Card Counter', 'Off-Duty Detective', "Whale's Bodyguard"],
    translations: {
      tr: {
        name: 'Kumarhane',
        roles: ['Salon Şefi', 'Kart Krupiyesi', 'Yüksek Bahisçi', 'Kokteyl Garsonu', 'Güvenlik Görevlisi', 'Slot Teknisyeni', 'Barmen', 'Sahne Şarkıcısı', 'Kart Sayıcı', 'İzinli Dedektif', 'Yüksek Bahisçinin Koruması'],
      },
    },
  },
  {
    name: 'Cruise Liner',
    roles: ['Captain', 'Cruise Director', 'Bartender', 'Steward', 'Passenger', 'Engineer', 'Entertainer', 'Spa Therapist', 'Magician', 'Honeymooner', 'Stowaway'],
    translations: {
      tr: {
        name: 'Yolcu Gemisi',
        roles: ['Kaptan', 'Eğlence Müdürü', 'Barmen', 'Kamarot', 'Yolcu', 'Mühendis', 'Şovmen', 'Spa Terapisti', 'Sihirbaz', 'Balayı Çifti', 'Kaçak Yolcu'],
      },
    },
  },
  {
    name: 'Cold War Sub',
    roles: ['Commander', 'Sonar Operator', 'Cook', 'Engineer', 'Navigator', 'Medic', 'Radio Officer', 'Torpedo Technician', 'Executive Officer', 'Stowaway Reporter', 'Sleep-Deprived Watch Officer'],
    translations: {
      tr: {
        name: 'Soğuk Savaş Denizaltısı',
        roles: ['Komutan', 'Sonar Operatörü', 'Aşçı', 'Mühendis', 'Seyir Subayı', 'Sağlıkçı', 'Telsiz Subayı', 'Torpido Teknisyeni', 'İkinci Komutan', 'Kaçak Muhabir', 'Uykusuz Vardiya Subayı'],
      },
    },
  },
  {
    name: 'Buccaneer Galleon',
    roles: ['Captain', 'First Mate', 'Cook', 'Cabin Boy', 'Lookout', 'Cannon Operator', 'Treasure Map Reader', 'Parrot Trainer', 'Quartermaster', 'Stowaway Cabin Cat', 'Drunk Bosun'],
    translations: {
      tr: {
        name: 'Korsan Kalyonu',
        roles: ['Kaptan', 'Yardımcı Kaptan', 'Aşçı', 'Miço', 'Gözcü', 'Topçu', 'Hazine Haritacısı', 'Papağan Eğiticisi', 'Levazımcı', 'Kaçak Gemi Kedisi', 'Sarhoş Lostromo'],
      },
    },
  },
  {
    name: 'Orbital Outpost',
    roles: ['Commander', 'Astronaut', 'Engineer', 'Botanist', 'Medical Officer', 'Mission Control Liaison', 'Robotics Specialist', 'Space Tourist', 'Stowaway Alien', 'Souvenir Hawker', 'Microgravity Influencer'],
    translations: {
      tr: {
        name: 'Yörünge Üssü',
        roles: ['Komutan', 'Astronot', 'Mühendis', 'Botanikçi', 'Sağlık Subayı', 'Görev Kontrol Bağlantısı', 'Robotik Uzmanı', 'Uzay Turisti', 'Kaçak Uzaylı', 'Hatıra Eşyası Satıcısı', 'Mikro-Yerçekimi Influencer’ı'],
      },
    },
  },
  {
    name: 'Wellness Retreat',
    roles: ['Receptionist', 'Massage Therapist', 'Aesthetician', 'Yoga Instructor', 'Manager', 'Customer', 'Sauna Attendant', 'Nail Technician', 'Sound-Healing Guide', 'Hungover Guest', 'Detox-Smoothie Bartender'],
    translations: {
      tr: {
        name: 'Wellness Tatili',
        roles: ['Resepsiyonist', 'Masöz', 'Estetisyen', 'Yoga Hocası', 'Müdür', 'Müşteri', 'Sauna Görevlisi', 'Manikürcü', 'Ses Terapisti', 'Akşamdan Kalma Misafir', 'Detoks Smoothie Barmeni'],
      },
    },
  },
  {
    name: 'Trauma Ward',
    roles: ['Surgeon', 'Nurse', 'Patient', 'Anesthesiologist', 'Janitor', 'Pharmacist', 'Receptionist', 'Visitor', 'Hypochondriac Patient', 'Lost Visitor', 'Vending Machine Hoverer'],
    translations: {
      tr: {
        name: 'Travma Servisi',
        roles: ['Cerrah', 'Hemşire', 'Hasta', 'Anestezi Uzmanı', 'Temizlikçi', 'Eczacı', 'Resepsiyonist', 'Ziyaretçi', 'Hipokondriyak Hasta', 'Kaybolmuş Ziyaretçi', 'Otomatın Önündeki'],
      },
    },
  },
  {
    name: 'Hotel Suite',
    roles: ['Concierge', 'Housekeeper', 'Bellhop', 'Front Desk Clerk', 'Room Service Server', 'Manager', 'Guest', 'Security', 'Wedding Crasher', 'Lost Cleaner', 'Influencer Demanding Comp'],
    translations: {
      tr: {
        name: 'Otel',
        roles: ['Konsiyerj', 'Kat Görevlisi', 'Komi', 'Resepsiyonist', 'Oda Servisi', 'Müdür', 'Misafir', 'Güvenlik', 'Davetsiz Düğün Misafiri', 'Kaybolmuş Temizlikçi', 'Bedava İsteyen Influencer'],
      },
    },
  },
  {
    name: 'Consulate',
    roles: ['Ambassador', 'Visa Clerk', 'Translator', 'Security Officer', 'Diplomat', 'Cultural Attaché', 'Driver', 'Visitor', 'Defecting Spy', 'Visa Applicant in Tears', 'Cultural Event Caterer'],
    translations: {
      tr: {
        name: 'Konsolosluk',
        roles: ['Büyükelçi', 'Vize Memuru', 'Tercüman', 'Güvenlik Görevlisi', 'Diplomat', 'Kültür Ataşesi', 'Şoför', 'Ziyaretçi', 'Sığınmacı Casus', 'Ağlayan Vize Başvurusu', 'Kültür Etkinliği Catering’cisi'],
      },
    },
  },
  {
    name: 'Polar Research Station',
    roles: ['Lead Researcher', 'Climatologist', 'Cook', 'Mechanic', 'Biologist', 'Pilot', 'Communications Officer', 'Field Assistant', 'Penguin Counter', 'Cabin-Fever Mathematician', 'Resupply Pilot'],
    translations: {
      tr: {
        name: 'Kutup Araştırma Üssü',
        roles: ['Başaraştırmacı', 'İklim Bilimci', 'Aşçı', 'Tamirci', 'Biyolog', 'Pilot', 'Telsiz Subayı', 'Saha Asistanı', 'Penguen Sayıcısı', 'Çıldıran Matematikçi', 'İkmal Pilotu'],
      },
    },
  },
  {
    name: 'Film Studio',
    roles: ['Director', 'Lead Actor', 'Camera Operator', 'Sound Engineer', 'Makeup Artist', 'Producer', 'Stunt Coordinator', 'Set Designer', 'Continuity Supervisor', 'Demanding Method Actor', 'Craft Services Cook'],
    translations: {
      tr: {
        name: 'Film Stüdyosu',
        roles: ['Yönetmen', 'Başrol Oyuncusu', 'Kameraman', 'Ses Mühendisi', 'Makyöz', 'Yapımcı', 'Dublör Koordinatörü', 'Set Tasarımcısı', 'Süreklilik Sorumlusu', 'Zor Beğenen Method Oyuncu', 'Set Yemekçisi'],
      },
    },
  },
  {
    name: 'Military Base',
    roles: ['Commanding Officer', 'Sergeant', 'Recruit', 'Mechanic', 'Cook', 'Medic', 'Drill Instructor', 'Communications Specialist', 'Military Police', 'Guardhouse Detainee', 'Press Liaison'],
    translations: {
      tr: {
        name: 'Askeri Üs',
        roles: ['Komutan', 'Çavuş', 'Acemi Er', 'Tamirci', 'Aşçı', 'Sağlıkçı', 'Talim Eğitmeni', 'Muhabere Uzmanı', 'İnzibat', 'Karargah Hapis Eri', 'Basın Sözcüsü'],
      },
    },
  },
  {
    name: 'Carnival',
    roles: ['Ride Operator', 'Ticket Seller', 'Cotton Candy Vendor', 'Clown', 'Fortune Teller', 'Game Booth Attendant', 'Performer', 'Visitor', 'Lost Child', 'Funnel Cake Addict', 'Ride Inspector'],
    translations: {
      tr: {
        name: 'Lunapark',
        roles: ['Lunapark Görevlisi', 'Bilet Satıcısı', 'Pamuk Şekercisi', 'Palyaço', 'Falcı', 'Stand Görevlisi', 'Sokak Sanatçısı', 'Ziyaretçi', 'Kayıp Çocuk', 'Şekerci Bağımlısı', 'Lunapark Müfettişi'],
      },
    },
  },
  {
    name: 'Bank Vault',
    roles: ['Manager', 'Teller', 'Security Guard', 'Customer', 'Auditor', 'Loan Officer', 'Vault Technician', 'Janitor', 'Surveillance Operator', 'Suspicious Withdrawer', 'IT Contractor'],
    translations: {
      tr: {
        name: 'Banka Kasası',
        roles: ['Müdür', 'Veznedar', 'Güvenlik Görevlisi', 'Müşteri', 'Müfettiş', 'Kredi Uzmanı', 'Kasa Teknisyeni', 'Temizlikçi', 'Kamera Operatörü', 'Şüpheli Para Çeken', 'BT Yüklenicisi'],
      },
    },
  },
  {
    name: 'Airliner Cabin',
    roles: ['Captain', 'Co-Pilot', 'Flight Attendant', 'Passenger', 'Air Marshal', 'Frequent Flyer', 'Crying Baby Wrangler', 'Tired Business Traveler', 'Aviation Hobbyist', 'Anxious First-Time Flyer', 'Off-Duty Pilot'],
    translations: {
      tr: {
        name: 'Uçak Kabini',
        roles: ['Kaptan Pilot', 'Yardımcı Pilot', 'Hostes', 'Yolcu', 'Hava Polisi', 'Sık Uçan Yolcu', 'Ağlayan Bebek Sahibi', 'Yorgun İş İnsanı', 'Havacılık Meraklısı', 'Endişeli İlk Defa Uçan', 'İzinli Pilot'],
      },
    },
  },
  {
    name: 'University Campus',
    roles: ['Professor', 'Student', 'Librarian', 'Janitor', 'Dean', 'Teaching Assistant', 'Cafeteria Worker', 'Visitor', 'Campus Tour Guide', 'Sleeping All-Nighter', 'Activist with Megaphone'],
    translations: {
      tr: {
        name: 'Üniversite Kampüsü',
        roles: ['Profesör', 'Öğrenci', 'Kütüphaneci', 'Temizlikçi', 'Dekan', 'Asistan', 'Yemekhane Görevlisi', 'Ziyaretçi', 'Kampüs Tur Rehberi', 'Sabaha Kadar Çalışan', 'Megafonlu Aktivist'],
      },
    },
  },
  {
    name: 'Stage Theater',
    roles: ['Director', 'Lead Actor', 'Stagehand', 'Lighting Technician', 'Audience Member', 'Usher', 'Costume Designer', 'Box Office Clerk', 'Prompter', 'Late-Arriving VIP', 'Theater Critic'],
    translations: {
      tr: {
        name: 'Tiyatro Sahnesi',
        roles: ['Yönetmen', 'Başrol Oyuncusu', 'Sahne Görevlisi', 'Işık Teknisyeni', 'Seyirci', 'Yer Gösterici', 'Kostüm Tasarımcısı', 'Gişe Görevlisi', 'Suflör', 'Geç Gelen VIP', 'Tiyatro Eleştirmeni'],
      },
    },
  },
  {
    name: 'Subway Train',
    roles: ['Conductor', 'Commuter', 'Tourist', 'Busker', 'Pickpocket Watcher', 'Off-Duty Worker', 'Student', 'Transit Officer', 'Sleeping Commuter', 'Conspiracy Pamphleteer', 'Phone Loud-Talker'],
    translations: {
      tr: {
        name: 'Metro',
        roles: ['Vatman', 'Yolcu', 'Turist', 'Sokak Müzisyeni', 'Yankesici Avcısı', 'Mesai Sonrası Yolcu', 'Öğrenci', 'Metro Görevlisi', 'Uyuyan Yolcu', 'Komplo Broşürcüsü', 'Telefonda Bağıran'],
      },
    },
  },
  {
    name: 'Race Track',
    roles: ['Driver', 'Pit Crew Chief', 'Mechanic', 'Announcer', 'Spectator', 'Track Marshal', 'Sponsor Rep', 'Trophy Presenter', 'Tire Engineer', 'Drone Camera Operator', 'Pre-Race Anthem Singer'],
    translations: {
      tr: {
        name: 'Yarış Pisti',
        roles: ['Pilot', 'Pit Şefi', 'Tamirci', 'Spiker', 'Seyirci', 'Pist Görevlisi', 'Sponsor Temsilcisi', 'Kupa Takdimcisi', 'Lastik Mühendisi', 'Drone Kamera Operatörü', 'Marş Şarkıcısı'],
      },
    },
  },
  {
    name: 'Police Precinct',
    roles: ['Detective', 'Patrol Officer', 'Sergeant', 'Forensic Tech', 'Receptionist', 'Suspect', 'Lawyer', 'Witness', 'Night-Shift Janitor', 'Loud Drunk in Holding', 'Internal Affairs Officer'],
    translations: {
      tr: {
        name: 'Karakol',
        roles: ['Dedektif', 'Devriye Polisi', 'Başçavuş', 'Olay Yeri Uzmanı', 'Santral Memuru', 'Şüpheli', 'Avukat', 'Tanık', 'Gece Vardiyası Temizlikçisi', 'Nezarette Sarhoş', 'İç İşleri Müfettişi'],
      },
    },
  },
  {
    name: 'Restaurant Kitchen',
    roles: ['Head Chef', 'Sous Chef', 'Line Cook', 'Dishwasher', 'Server', 'Pastry Chef', 'Food Critic', 'Owner', 'Hangry Server', 'Visiting Food-Truck Vendor', 'Health Inspector'],
    translations: {
      tr: {
        name: 'Restoran Mutfağı',
        roles: ['Şef', 'Yardımcı Şef', 'Aşçı', 'Bulaşıkçı', 'Garson', 'Pasta Şefi', 'Yemek Eleştirmeni', 'Patron', 'Aç Garson', 'Misafir Yemek Arabası Ustası', 'Sağlık Müfettişi'],
      },
    },
  },
  {
    name: 'Service Garage',
    roles: ['Mechanic', 'Service Advisor', 'Apprentice', 'Customer', 'Parts Manager', 'Tow Driver', 'Inspector', 'Detailer', 'Welder', 'Anxious Customer', 'Vending Machine Repair Guy'],
    translations: {
      tr: {
        name: 'Tamirhane',
        roles: ['Tamirci', 'Servis Danışmanı', 'Çırak', 'Müşteri', 'Parça Sorumlusu', 'Çekici Şoförü', 'Eksper', 'Detaycı', 'Kaynakçı', 'Endişeli Müşteri', 'Otomat Tamircisi'],
      },
    },
  },
];

// Bundle: Istanbul (city pack)
const ISTANBUL: SeedLocation[] = [
  {
    name: 'Galata Tower',
    bundleSlug: 'istanbul',
    roles: ['Tour Guide', 'Souvenir Vendor', 'Selfie Tourist', 'Astronomer', 'Rooftop Bar Bartender', 'Drone Photographer', 'Honeymooners', 'Pickpocket', 'Restaurant Host', 'Lost Tourist', 'Stair-Counter Tourist'],
    translations: {
      tr: {
        name: 'Galata Kulesi',
        roles: ['Tur Rehberi', 'Hatıra Eşyası Satıcısı', 'Selfie Çeken Turist', 'Astronom', 'Çatı Bar Barmeni', 'Drone Fotoğrafçısı', 'Balayı Çifti', 'Yankesici', 'Restoran Garsonu', 'Kaybolmuş Turist', 'Merdiven Sayan Turist'],
      },
    },
  },
  {
    name: 'Grand Bazaar',
    bundleSlug: 'istanbul',
    roles: ['Carpet Seller', 'Spice Trader', 'Jewelry Haggler', 'Tourist', 'Pickpocket', 'Tea Server', 'Goldsmith', 'Antique Forger', 'Lost Tourist', 'Lantern Vendor', 'Translator'],
    translations: {
      tr: {
        name: 'Kapalıçarşı',
        roles: ['Halıcı', 'Baharatçı', 'Kuyumcu Pazarlıkçısı', 'Turist', 'Yankesici', 'Çaycı', 'Kuyumcu', 'Antika Sahtekarı', 'Kaybolmuş Turist', 'Lambacı', 'Tercüman'],
      },
    },
  },
  {
    name: 'Hamam',
    bundleSlug: 'istanbul',
    roles: ['Tellak (Masseur)', 'Bather', 'Cashier', 'Tea Server', 'First-Time Visitor', 'Local Regular', 'Honeymooner', 'Apprentice', 'Loofah Vendor', 'Sleeping Patron', 'Cleric on Break'],
    translations: {
      tr: {
        name: 'Hamam',
        roles: ['Tellak', 'Yıkanan Müşteri', 'Kasiyer', 'Çaycı', 'İlk Defa Gelen', 'Sürekli Müşteri', 'Balayı Çifti', 'Çırak', 'Lif Satıcısı', 'Uyuyan Müşteri', 'Mola Veren İmam'],
      },
    },
  },
  {
    name: 'Bosphorus Ferry',
    bundleSlug: 'istanbul',
    roles: ['Captain', 'Tea Server (Çaycı)', 'Simit Vendor', 'Seagull Feeder', 'Tourist', 'Commuter', 'Photographer', 'Live Music Performer', 'Honeymooners', 'Sleeping Passenger', 'Hungry Stray Cat'],
    translations: {
      tr: {
        name: 'Boğaz Vapuru',
        roles: ['Kaptan', 'Çaycı', 'Simitçi', 'Martı Besleyen', 'Turist', 'Yolcu', 'Fotoğrafçı', 'Canlı Müzik Sanatçısı', 'Balayı Çifti', 'Uyuyan Yolcu', 'Aç Sokak Kedisi'],
      },
    },
  },
  {
    name: 'İstiklal Street',
    bundleSlug: 'istanbul',
    roles: ['Street Performer', 'Hungry Stray Cat', 'Pickpocket', 'Nostalgic Tram Conductor', 'Simit Vendor', 'Tourist', 'Window Shopper', 'Protest Photographer', 'Off-Duty Police', 'Lost Foreigner', 'Backgammon Player'],
    translations: {
      tr: {
        name: 'İstiklal Caddesi',
        roles: ['Sokak Sanatçısı', 'Aç Sokak Kedisi', 'Yankesici', 'Nostaljik Tramvay Vatmanı', 'Simitçi', 'Turist', 'Vitrin Bakıcısı', 'Eylem Fotoğrafçısı', 'Sivil Polis', 'Kaybolmuş Yabancı', 'Tavla Oynayan'],
      },
    },
  },
  {
    name: 'Sultanahmet Square',
    bundleSlug: 'istanbul',
    roles: ['Tour Guide', 'Souvenir Vendor', 'Roasted Chestnut Vendor', 'Tourist', 'Hungry Stray Cat', 'Calligrapher', 'Honeymooner', 'Drone Photographer', 'Pigeon Feeder', 'Lost Tourist', 'Cleric'],
    translations: {
      tr: {
        name: 'Sultanahmet Meydanı',
        roles: ['Tur Rehberi', 'Hatıra Eşyası Satıcısı', 'Kestaneci', 'Turist', 'Aç Sokak Kedisi', 'Hattat', 'Balayı Çifti', 'Drone Fotoğrafçısı', 'Güvercin Besleyen', 'Kaybolmuş Turist', 'İmam'],
      },
    },
  },
  {
    name: 'Asian-Side Tea Garden',
    bundleSlug: 'istanbul',
    roles: ['Tea Server', 'Backgammon Player', 'Stray Cat', 'Newspaper Reader', 'Hookah Operator', 'Retiree', 'Reluctant Date', 'Crossword Solver', 'Sketch Artist', 'Off-Duty Ferry Captain', 'Loud-Argument Pair'],
    translations: {
      tr: {
        name: 'Çay Bahçesi',
        roles: ['Çaycı', 'Tavla Oyuncusu', 'Sokak Kedisi', 'Gazete Okuyucu', 'Nargileci', 'Emekli', 'İsteksiz Buluşma Eşi', 'Bulmaca Çözen', 'Karakalemci', 'İzinli Vapur Kaptanı', 'Yüksek Sesle Tartışan İkili'],
      },
    },
  },
  {
    name: 'Beyoğlu Meyhane',
    bundleSlug: 'istanbul',
    roles: ['Waiter', 'Rakı Pourer', 'Mezze Chef', 'Live Saz Player', 'Singing Stranger', 'Birthday Group', 'Honeymooners', 'First-Time Tourist', 'Off-Duty Journalist', 'Late-Night Regular', 'Cat Under the Table'],
    translations: {
      tr: {
        name: 'Beyoğlu Meyhanesi',
        roles: ['Garson', 'Rakı Servisçisi', 'Meze Şefi', 'Saz Sanatçısı', 'Şarkı Söyleyen Yabancı', 'Doğum Günü Grubu', 'Balayı Çifti', 'İlk Defa Gelen Turist', 'İzinli Gazeteci', 'Geç Saat Müdavimi', 'Masa Altındaki Kedi'],
      },
    },
  },
  {
    name: 'Kadıköy Bar Street',
    bundleSlug: 'istanbul',
    roles: ['Bartender', 'Indie Band Drummer', 'Promoter', 'Bouncer', 'Tipsy Local', 'Erasmus Student', 'Stray Dog', 'Street Food Vendor', 'Photographer', 'Off-Duty Police', 'Lost Tourist'],
    translations: {
      tr: {
        name: 'Kadıköy Barlar Sokağı',
        roles: ['Barmen', 'Indie Grup Davulcusu', 'Organizatör', 'Fedai', 'Çakırkeyif Yerli', 'Erasmus Öğrencisi', 'Sokak Köpeği', 'Sokak Yemekçisi', 'Fotoğrafçı', 'Sivil Polis', 'Kaybolmuş Turist'],
      },
    },
  },
  {
    name: "Princes' Islands Phaeton",
    bundleSlug: 'istanbul',
    roles: ['Tour Guide', 'Tourist Family', 'Photographer', 'Honeymooners', 'Bicycle Renter', 'Stray Cat', 'Mansion Caretaker', 'Off-Duty Boat Captain', 'Iced Coffee Vendor', 'Pickpocket', 'Lost Day-Tripper'],
    translations: {
      tr: {
        name: 'Adalar Faytonu',
        roles: ['Tur Rehberi', 'Turist Aile', 'Fotoğrafçı', 'Balayı Çifti', 'Bisiklet Kiracısı', 'Sokak Kedisi', 'Köşk Bakıcısı', 'İzinli Tekne Kaptanı', 'Soğuk Kahve Satıcısı', 'Yankesici', 'Kaybolmuş Günübirlikçi'],
      },
    },
  },
];

// Bundle: Cyberpunk (theme pack)
const CYBERPUNK: SeedLocation[] = [
  {
    name: 'Neon Arcade',
    bundleSlug: 'cyberpunk',
    roles: ['Hacker', 'Bouncer', 'Cosplayer', 'Glitch Artist', 'Bartender', 'Underage Smuggler', 'Tourist', 'Game Tester', 'Vintage Console Collector', 'Bot Operator', 'Pro Gamer'],
    translations: {
      tr: {
        name: 'Neon Salonu',
        roles: ['Hacker', 'Fedai', 'Kostümlü Oyuncu', 'Glitch Sanatçısı', 'Barmen', 'Reşit Olmayan Kaçakçı', 'Turist', 'Oyun Testçisi', 'Eski Konsol Koleksiyoncusu', 'Bot Operatörü', 'Profesyonel Oyuncu'],
      },
    },
  },
  {
    name: 'Black Market Clinic',
    bundleSlug: 'cyberpunk',
    roles: ['Underground Doc', 'Cybernetics Patient', 'Shady Dealer', 'Bouncer', 'Bone Saw Tech', 'Anesthetist', 'Lab Tech', 'Cleaner', 'Witness Protection Client', 'Spare-Parts Smuggler', 'Receptionist'],
    translations: {
      tr: {
        name: 'Karaborsa Kliniği',
        roles: ['Yeraltı Doktoru', 'Sibernetik Hastası', 'Karaborsacı', 'Fedai', 'Kemik Testeri Teknisyeni', 'Anestezist', 'Laboratuvar Teknisyeni', 'Temizlikçi', 'Tanık Koruma Müşterisi', 'Yedek Parça Kaçakçısı', 'Resepsiyonist'],
      },
    },
  },
  {
    name: 'Megacorp HQ',
    bundleSlug: 'cyberpunk',
    roles: ['CEO', 'Janitor With A Secret', 'Security Drone Operator', 'Whistleblower Intern', 'Lobby Receptionist', 'Marketing Director', 'Chief Hacker', 'IT Helpdesk', 'Coffee Cart Operator', 'Visitor', 'Boardroom Spy'],
    translations: {
      tr: {
        name: 'Megakorporasyon Merkezi',
        roles: ['CEO', 'Sırrı Olan Temizlikçi', 'Drone Güvenlik Operatörü', 'İhbarcı Stajyer', 'Lobi Resepsiyonisti', 'Pazarlama Müdürü', 'Baş Hacker', 'BT Destek', 'Kahveci', 'Ziyaretçi', 'Toplantı Odası Casusu'],
      },
    },
  },
  {
    name: 'Hacker Den',
    bundleSlug: 'cyberpunk',
    roles: ['Cracker', 'Coffee Maker', 'Pizza-Delivery Cracker', 'Sysadmin', 'Crypto Trader', 'Streamer', 'Doxxer', 'AR Tinkerer', 'Newbie Skid', 'Bug Hunter', 'Lurker'],
    translations: {
      tr: {
        name: 'Hacker İni',
        roles: ['Cracker', 'Kahveci', 'Pizzacı Cracker', 'Sistem Yöneticisi', 'Kripto Trader', 'Yayıncı', 'Doxxer', 'AR Tasarımcısı', 'Acemi', 'Bug Avcısı', 'Sessiz İzleyici'],
      },
    },
  },
  {
    name: 'Server Farm',
    bundleSlug: 'cyberpunk',
    roles: ['Shift Tech', 'Power Engineer', 'Cooling Specialist', 'Security Officer', 'Janitor', 'Cable Manager', 'Auditor', 'On-Call Engineer', 'Vendor Rep', 'Tour Guide', 'Sleeping Operator'],
    translations: {
      tr: {
        name: 'Sunucu Çiftliği',
        roles: ['Vardiya Teknisyeni', 'Enerji Mühendisi', 'Soğutma Uzmanı', 'Güvenlik Görevlisi', 'Temizlikçi', 'Kablo Sorumlusu', 'Denetçi', 'Nöbetçi Mühendis', 'Tedarikçi Temsilcisi', 'Tur Rehberi', 'Uyuyan Operatör'],
      },
    },
  },
  {
    name: 'Skyway Bar',
    bundleSlug: 'cyberpunk',
    roles: ['Bartender', 'Replicant', 'Off-Duty Cop', 'Holo-DJ', 'Bouncer', 'Mercenary', 'Tourist', 'Karaoke Singer', 'Smuggler', 'High Roller', 'Drone Bouncer'],
    translations: {
      tr: {
        name: 'Gökyolu Barı',
        roles: ['Barmen', 'Replikant', 'İzinli Polis', 'Holo-DJ', 'Fedai', 'Paralı Asker', 'Turist', 'Karaoke Şarkıcısı', 'Kaçakçı', 'Yüksek Bahisçi', 'Drone Fedai'],
      },
    },
  },
  {
    name: 'Drone Racing Pit',
    bundleSlug: 'cyberpunk',
    roles: ['Pilot', 'Spotter', 'Pit Crew', 'Sponsor Rep', 'Bookie', 'Drone Repair Tech', 'Heckler', 'Camera Drone Operator', 'Tipsy Spectator', 'Underage Smuggler', 'Race Marshal'],
    translations: {
      tr: {
        name: 'Drone Yarış Pisti',
        roles: ['Pilot', 'Gözcü', 'Pit Ekibi', 'Sponsor Temsilcisi', 'Bahis Aracısı', 'Drone Tamircisi', 'Laf Atan', 'Kamera Drone Operatörü', 'Çakırkeyif Seyirci', 'Reşit Olmayan Kaçakçı', 'Yarış Görevlisi'],
      },
    },
  },
  {
    name: 'Vat-Grown Meat Diner',
    bundleSlug: 'cyberpunk',
    roles: ['Synth-Cook', 'Waiter', 'Health Inspector', 'Off-Duty Replicant', 'Late-Night Trucker', 'Influencer Reviewer', 'Bouncer', 'Coffee Cart Operator', 'Janitor With A Secret', 'Suspicious Health Nut', 'Owner'],
    translations: {
      tr: {
        name: 'Suni Et Lokantası',
        roles: ['Sentetik Aşçı', 'Garson', 'Sağlık Müfettişi', 'İzinli Replikant', 'Gece Tırcısı', 'Influencer Eleştirmen', 'Fedai', 'Kahveci', 'Sırrı Olan Temizlikçi', 'Şüpheli Sağlık Manyağı', 'Patron'],
      },
    },
  },
  {
    name: 'Underground Casino',
    bundleSlug: 'cyberpunk',
    roles: ['Croupier', 'High Roller', 'Bouncer', 'Cocktail Server', 'Lookout', 'Off-Duty Cop', 'Card Counter', 'Loan Shark', 'Tourist', 'Money Launderer', 'Cleaner'],
    translations: {
      tr: {
        name: 'Yeraltı Kumarhanesi',
        roles: ['Krupiye', 'Yüksek Bahisçi', 'Fedai', 'Kokteyl Garsonu', 'Gözcü', 'İzinli Polis', 'Kart Sayıcı', 'Tefeci', 'Turist', 'Kara Para Aklayıcı', 'Temizlikçi'],
      },
    },
  },
  {
    name: 'AR Cathedral',
    bundleSlug: 'cyberpunk',
    roles: ['Holo-Priest', 'Pilgrim', 'Tourist', 'AR Engineer', 'Choir Hologram', 'Glitching Confessor', 'Server Tech', 'Janitor', 'Bouncer', 'Sleeping Devotee', 'Streamer'],
    translations: {
      tr: {
        name: 'AR Katedrali',
        roles: ['Holo-Rahip', 'Hacı', 'Turist', 'AR Mühendisi', 'Koro Hologramı', 'Glitch Atan İtirafçı', 'Sunucu Teknisyeni', 'Temizlikçi', 'Fedai', 'Uyuyan Mümin', 'Yayıncı'],
      },
    },
  },
];

// Bundle: Paris (city pack)
const PARIS: SeedLocation[] = [
  {
    name: 'Eiffel Tower',
    bundleSlug: 'paris',
    roles: ['Tour Guide', 'Souvenir Vendor', 'Selfie Tourist', "Restaurant Maître d'", 'Pickpocket', 'Honeymooners', 'Lost American', 'Mime in Striped Shirt', 'Sketch Artist', 'Off-Duty Gendarme', 'Acrobat'],
    translations: {
      tr: {
        name: 'Eyfel Kulesi',
        roles: ['Tur Rehberi', 'Hediyelik Eşyacı', 'Selfie Çeken Turist', 'Restoran Maître\'i', 'Yankesici', 'Balayı Çifti', 'Kaybolmuş Amerikalı', 'Çizgili Tişörtlü Pandomimci', 'Karakalemci', 'İzinli Jandarma', 'Akrobat'],
      },
    },
  },
  {
    name: 'Louvre Museum',
    bundleSlug: 'paris',
    roles: ['Curator', 'Security Guard', 'Art Student', 'Tourist', 'Audio Guide Renter', 'Selfie Tourist', 'Restorationist', 'Janitor', 'Pickpocket', 'Lost Schoolchild', 'Off-Duty Forger'],
    translations: {
      tr: {
        name: 'Louvre Müzesi',
        roles: ['Küratör', 'Güvenlik Görevlisi', 'Sanat Öğrencisi', 'Turist', 'Sesli Rehber Kiracısı', 'Selfie Çeken Turist', 'Restoratör', 'Temizlikçi', 'Yankesici', 'Kaybolmuş Okul Çocuğu', 'İzinli Sahteci'],
      },
    },
  },
  {
    name: 'Métro Station',
    bundleSlug: 'paris',
    roles: ['Conductor', 'Busker', 'Commuter', 'Tourist with Map', 'Pickpocket', 'Off-Duty Worker', 'Student', 'Transit Officer', 'Sleeping Passenger', 'Stray Cat', 'Magazine Vendor'],
    translations: {
      tr: {
        name: 'Metro İstasyonu',
        roles: ['Vatman', 'Sokak Müzisyeni', 'Yolcu', 'Haritalı Turist', 'Yankesici', 'Mesai Sonrası Yolcu', 'Öğrenci', 'Metro Görevlisi', 'Uyuyan Yolcu', 'Sokak Kedisi', 'Dergi Satıcısı'],
      },
    },
  },
  {
    name: 'Café Terrasse',
    bundleSlug: 'paris',
    roles: ['Waiter', 'Espresso Drinker', 'Philosopher', 'Smoking Writer', 'Tourist', 'Newspaper Reader', 'Pickpocket', 'Off-Duty Chef', 'Beggar', 'Honeymooners', 'Stray Cat'],
    translations: {
      tr: {
        name: 'Kafe Terası',
        roles: ['Garson', 'Espresso İçicisi', 'Filozof', 'Sigara İçen Yazar', 'Turist', 'Gazete Okuyucu', 'Yankesici', 'İzinli Şef', 'Dilenci', 'Balayı Çifti', 'Sokak Kedisi'],
      },
    },
  },
  {
    name: 'Catacombs',
    bundleSlug: 'paris',
    roles: ['Tour Guide', 'Wide-Eyed Tourist', 'Skeptical Skeptic', 'Photographer', 'Janitor', 'Lost Tour Group', 'Off-Duty Archaeologist', 'Catacomb Mapper', 'Goth Honeymooners', 'Trespasser', 'Audio Guide Renter'],
    translations: {
      tr: {
        name: 'Katakomplar',
        roles: ['Tur Rehberi', 'Şaşkın Turist', 'Şüpheci', 'Fotoğrafçı', 'Temizlikçi', 'Kaybolmuş Tur Grubu', 'İzinli Arkeolog', 'Katakomp Haritacısı', 'Goth Balayı Çifti', 'İzinsiz Giren', 'Sesli Rehber Kiracısı'],
      },
    },
  },
  {
    name: 'Père Lachaise',
    bundleSlug: 'paris',
    roles: ['Tour Guide', 'Jim Morrison Pilgrim', 'Florist', 'Caretaker', 'Mourner', 'Sketch Artist', 'Lost Tourist', 'Photographer', 'Stray Cat', 'Off-Duty Gendarme', 'Conspiracy Theorist'],
    translations: {
      tr: {
        name: 'Père Lachaise Mezarlığı',
        roles: ['Tur Rehberi', 'Jim Morrison Hacısı', 'Çiçekçi', 'Bakıcı', 'Yas Tutan', 'Karakalemci', 'Kaybolmuş Turist', 'Fotoğrafçı', 'Sokak Kedisi', 'İzinli Jandarma', 'Komplo Teorisyeni'],
      },
    },
  },
  {
    name: 'Notre-Dame',
    bundleSlug: 'paris',
    roles: ['Tour Guide', 'Pilgrim', 'Restoration Worker', 'Photographer', 'Choir Member', 'Tourist', 'Pickpocket', 'Sketch Artist', 'Off-Duty Gendarme', 'Lost American', 'Cathedral Cat'],
    translations: {
      tr: {
        name: 'Notre Dame',
        roles: ['Tur Rehberi', 'Hacı', 'Restorasyon İşçisi', 'Fotoğrafçı', 'Koro Üyesi', 'Turist', 'Yankesici', 'Karakalemci', 'İzinli Jandarma', 'Kaybolmuş Amerikalı', 'Katedral Kedisi'],
      },
    },
  },
  {
    name: 'Boulangerie',
    bundleSlug: 'paris',
    roles: ['Baker', 'Apprentice', 'Cashier', 'Local Regular', 'Tourist', 'Pickpocket', 'School Kid', 'Health Inspector', 'Late-for-Work Office Worker', 'Boulangerie Cat', 'Croissant Critic'],
    translations: {
      tr: {
        name: 'Fırın',
        roles: ['Fırıncı', 'Çırak', 'Kasiyer', 'Sürekli Müşteri', 'Turist', 'Yankesici', 'Okul Çocuğu', 'Sağlık Müfettişi', 'İşe Geç Kalan Memur', 'Fırın Kedisi', 'Kruvasan Eleştirmeni'],
      },
    },
  },
  {
    name: 'Champs-Élysées',
    bundleSlug: 'paris',
    roles: ['Luxury Boutique Greeter', 'Tourist', 'Pickpocket', 'Honeymooners', 'Street Performer', 'Off-Duty Gendarme', 'Photographer', 'Lost American', 'Souvenir Vendor', 'Café Waiter', 'Influencer'],
    translations: {
      tr: {
        name: 'Champs-Élysées',
        roles: ['Lüks Butik Karşılayıcısı', 'Turist', 'Yankesici', 'Balayı Çifti', 'Sokak Sanatçısı', 'İzinli Jandarma', 'Fotoğrafçı', 'Kaybolmuş Amerikalı', 'Hediyelik Eşyacı', 'Kafe Garsonu', 'Influencer'],
      },
    },
  },
  {
    name: "Musée d'Orsay",
    bundleSlug: 'paris',
    roles: ['Curator', 'Security Guard', 'Art Student', 'Tourist', 'Sketch Artist', 'Audio Guide Renter', 'Restorationist', 'Pickpocket', 'Lost Schoolchild', 'Janitor', 'Honeymooners'],
    translations: {
      tr: {
        name: 'Orsay Müzesi',
        roles: ['Küratör', 'Güvenlik Görevlisi', 'Sanat Öğrencisi', 'Turist', 'Karakalemci', 'Sesli Rehber Kiracısı', 'Restoratör', 'Yankesici', 'Kaybolmuş Okul Çocuğu', 'Temizlikçi', 'Balayı Çifti'],
      },
    },
  },
];

// Bundle: Tokyo (city pack)
const TOKYO: SeedLocation[] = [
  {
    name: 'Shibuya Crossing',
    bundleSlug: 'tokyo',
    roles: ['Salaryman', 'Cosplayer', 'Tourist', 'Pickpocket', 'Lost American', 'Live Streamer', 'Hachiko Selfie-Taker', 'Off-Duty Cop', 'Costumed Mascot', 'Promoter', 'Photographer'],
    translations: {
      tr: {
        name: 'Shibuya Kavşağı',
        roles: ['Salaryman', 'Kostümlü Oyuncu', 'Turist', 'Yankesici', 'Kaybolmuş Amerikalı', 'Canlı Yayıncı', 'Hachiko\'da Selfie Çeken', 'İzinli Polis', 'Kostümlü Maskot', 'Organizatör', 'Fotoğrafçı'],
      },
    },
  },
  {
    name: 'Capsule Hotel',
    bundleSlug: 'tokyo',
    roles: ['Front Desk Clerk', 'Drunk Salaryman', 'Backpacker', 'Janitor', 'Snoring Guest', 'Late-Night Arriver', 'Off-Duty Pilot', 'Manager', 'Sauna Attendant', 'Tourist with Suitcase', 'Late Checkout Negotiator'],
    translations: {
      tr: {
        name: 'Kapsül Otel',
        roles: ['Resepsiyon Görevlisi', 'Sarhoş Salaryman', 'Sırt Çantalı Gezgin', 'Temizlikçi', 'Horlayan Misafir', 'Geç Saatte Gelen', 'İzinli Pilot', 'Müdür', 'Sauna Görevlisi', 'Bavullu Turist', 'Geç Çıkış İçin Pazarlık Eden'],
      },
    },
  },
  {
    name: 'Karaoke Box',
    bundleSlug: 'tokyo',
    roles: ['Microphone Hog', 'Off-Key Singer', 'Birthday Star', 'Snack Server', 'Drunk Salaryman', 'Bachelorette Group', 'Tour Guide', 'Late Arriver', 'Tone-Deaf Tourist', 'Tambourine Hero', 'Manager'],
    translations: {
      tr: {
        name: 'Karaoke Odası',
        roles: ['Mikrofon Sahibi', 'Akortsuz Şarkıcı', 'Doğum Günü Yıldızı', 'Aperatif Garsonu', 'Sarhoş Salaryman', 'Bekarlığa Veda Grubu', 'Tur Rehberi', 'Geç Gelen', 'Tonsuz Turist', 'Tef Kahramanı', 'Müdür'],
      },
    },
  },
  {
    name: 'Tsukiji Fish Market',
    bundleSlug: 'tokyo',
    roles: ['Tuna Auctioneer', 'Sushi Chef', 'Wholesale Buyer', 'Tourist', 'Forklift Driver', 'Photographer', 'Knife Sharpener', 'Fish Market Cat', 'Off-Duty Coast Guard', 'Lost American', 'Apprentice'],
    translations: {
      tr: {
        name: 'Tsukiji Balık Pazarı',
        roles: ['Ton Balığı Mezatçısı', 'Suşi Şefi', 'Toptancı', 'Turist', 'Forklift Şoförü', 'Fotoğrafçı', 'Bıçak Bileyici', 'Pazar Kedisi', 'İzinli Sahil Güvenlik', 'Kaybolmuş Amerikalı', 'Çırak'],
      },
    },
  },
  {
    name: 'Shinjuku Bar Alley',
    bundleSlug: 'tokyo',
    roles: ['Bartender', 'Salaryman Sleeping Standing Up', 'Sake Sommelier', 'Tourist', 'Bouncer', 'Lost Foreigner', 'Off-Duty Cop', 'Karaoke Singer Spillover', 'Late-Night Cook', 'Stray Cat', 'Tout'],
    translations: {
      tr: {
        name: 'Shinjuku Bar Sokağı',
        roles: ['Barmen', 'Ayakta Uyuyan Salaryman', 'Sake Sommelier', 'Turist', 'Fedai', 'Kaybolmuş Yabancı', 'İzinli Polis', 'Karaoke\'den Taşan Şarkıcı', 'Gece Aşçısı', 'Sokak Kedisi', 'Kapı Çağırıcısı'],
      },
    },
  },
  {
    name: 'Akihabara Maid Café',
    bundleSlug: 'tokyo',
    roles: ['Maid Server', 'Regular Otaku', 'Tourist', 'Photographer', 'Manager', 'Confused Salaryman', 'Stage Performer', 'Cosplayer', 'First-Time Visitor', 'Off-Duty Mangaka', 'Birthday Group'],
    translations: {
      tr: {
        name: 'Akihabara Maid Kafe',
        roles: ['Maid Garsonu', 'Müdavim Otaku', 'Turist', 'Fotoğrafçı', 'Müdür', 'Şaşkın Salaryman', 'Sahne Sanatçısı', 'Kostümlü Oyuncu', 'İlk Defa Gelen', 'İzinli Mangaka', 'Doğum Günü Grubu'],
      },
    },
  },
  {
    name: 'Robot Restaurant',
    bundleSlug: 'tokyo',
    roles: ['Robot Operator', 'Server', 'MC', 'Tourist', 'Photographer', 'Off-Duty Mecha Designer', 'Stunt Performer', 'Confused Local', 'Birthday Group', 'Lost American', 'Manager'],
    translations: {
      tr: {
        name: 'Robot Restoranı',
        roles: ['Robot Operatörü', 'Garson', 'Sunucu', 'Turist', 'Fotoğrafçı', 'İzinli Meka Tasarımcısı', 'Dublör', 'Şaşkın Yerli', 'Doğum Günü Grubu', 'Kaybolmuş Amerikalı', 'Müdür'],
      },
    },
  },
  {
    name: 'Ramen Stall',
    bundleSlug: 'tokyo',
    roles: ['Itamae', 'Late-Night Salaryman', 'Slurping Tourist', 'Apprentice', 'Regular', 'Off-Duty Cop', 'Drunk Local', 'Health Inspector', 'Photographer', 'Stray Cat', 'Lost Foreigner'],
    translations: {
      tr: {
        name: 'Ramen Tezgahı',
        roles: ['Itamae', 'Gece Salaryman\'i', 'Höpürdeten Turist', 'Çırak', 'Müdavim', 'İzinli Polis', 'Sarhoş Yerli', 'Sağlık Müfettişi', 'Fotoğrafçı', 'Sokak Kedisi', 'Kaybolmuş Yabancı'],
      },
    },
  },
  {
    name: 'Onsen',
    bundleSlug: 'tokyo',
    roles: ['Bath Attendant', 'Manager', 'Local Regular', 'Shy First-Timer', 'Honeymooners', 'Tourist', 'Towel Vendor', 'Off-Duty Sumo', 'Old-Friend Gossiper', 'Sleeping Bather', 'Sauna-Loving Salaryman'],
    translations: {
      tr: {
        name: 'Kaplıca',
        roles: ['Hamam Görevlisi', 'Müdür', 'Yerli Müdavim', 'Utangaç İlk Gelen', 'Balayı Çifti', 'Turist', 'Havlu Satıcısı', 'İzinli Sumo', 'Dedikodu Yapan Eski Dost', 'Uyuyan Yıkanan', 'Sauna Sever Salaryman'],
      },
    },
  },
  {
    name: 'Vending-Machine Alley',
    bundleSlug: 'tokyo',
    roles: ['Restocker', 'Lost Tourist', 'Late-Night Office Worker', 'Photography Hobbyist', 'Drunk Salaryman', 'Stray Cat', 'Off-Duty Cop', 'Mystery Shopper', 'Coin Hoarder', 'Kid with Pocket Money', 'Vandal'],
    translations: {
      tr: {
        name: 'Otomat Sokağı',
        roles: ['Stok Yenileyici', 'Kaybolmuş Turist', 'Gece Memuru', 'Fotoğraf Meraklısı', 'Sarhoş Salaryman', 'Sokak Kedisi', 'İzinli Polis', 'Gizli Müşteri', 'Bozuk Para Biriktirici', 'Harçlıklı Çocuk', 'Vandal'],
      },
    },
  },
];

// Bundle: Stockholm (city pack)
const STOCKHOLM: SeedLocation[] = [
  {
    name: 'Vasa Museum',
    bundleSlug: 'stockholm',
    roles: ['Tour Guide', 'Marine Archaeologist', 'School Class Teacher', 'Bewildered American', 'Photographer', 'Souvenir Vendor', 'Audio Guide Renter', 'Off-Duty Sailor', 'Sketch Artist', 'Sleeping Toddler in Stroller', 'Restoration Specialist'],
    translations: {
      tr: {
        name: 'Vasa Müzesi',
        roles: ['Tur Rehberi', 'Sualtı Arkeoloğu', 'Sınıf Öğretmeni', 'Şaşkın Amerikalı', 'Fotoğrafçı', 'Hediyelik Eşyacı', 'Sesli Rehber Kiracısı', 'İzinli Denizci', 'Karakalemci', 'Bebek Arabasında Uyuyan Çocuk', 'Restorasyon Uzmanı'],
      },
    },
  },
  {
    name: 'ABBA Museum',
    bundleSlug: 'stockholm',
    roles: ['Tour Guide', 'Singing Tour Guide', 'Tribute Singer', 'Bewildered American', 'Honeymooners', 'Souvenir Vendor', 'Reluctant Husband', 'Disco-Floor Solo Dancer', 'Photographer', 'Karaoke Booth Operator', 'Birthday Group'],
    translations: {
      tr: {
        name: 'ABBA Müzesi',
        roles: ['Tur Rehberi', 'Şarkı Söyleyen Tur Rehberi', 'Tribute Şarkıcı', 'Şaşkın Amerikalı', 'Balayı Çifti', 'Hediyelik Eşyacı', 'İsteksiz Koca', 'Disco Solo Dansçı', 'Fotoğrafçı', 'Karaoke Operatörü', 'Doğum Günü Grubu'],
      },
    },
  },
  {
    name: 'Gamla Stan',
    bundleSlug: 'stockholm',
    roles: ['Tour Guide', 'Reindeer-Sweater Vendor', "Off-Duty King's Guard", 'Bewildered American', 'Pickpocket', 'Photographer', 'Honeymooners', 'Antique Shop Owner', 'Sketch Artist', 'Lost Cruise-Ship Tourist', 'Cobblestone-Stumbling Tourist'],
    translations: {
      tr: {
        name: 'Gamla Stan',
        roles: ['Tur Rehberi', 'Ren Geyiği Kazaklı Satıcı', 'İzinli Saray Muhafızı', 'Şaşkın Amerikalı', 'Yankesici', 'Fotoğrafçı', 'Balayı Çifti', 'Antikacı', 'Karakalemci', 'Kaybolmuş Yolcu Gemisi Turisti', 'Arnavut Kaldırımında Tökezleyen Turist'],
      },
    },
  },
  {
    name: 'Stockholm Sauna',
    bundleSlug: 'stockholm',
    roles: ['Bath Attendant', 'Naked Sauna Regular', 'Shy First-Timer', 'Birch-Branch Whisker', 'Tourist', 'Honeymooners', 'Manager', 'Cold Plunge Show-Off', 'Off-Duty Hockey Player', 'Sauna Philosopher', 'Towel Folder'],
    translations: {
      tr: {
        name: 'İskandinav Sauna',
        roles: ['Hamam Görevlisi', 'Çıplak Sauna Müdavimi', 'Utangaç İlk Gelen', 'Huş Dalı Vurucusu', 'Turist', 'Balayı Çifti', 'Müdür', 'Soğuk Suya Atlayan Hava Atan', 'İzinli Hokey Oyuncusu', 'Sauna Filozofu', 'Havlu Katlayan'],
      },
    },
  },
  {
    name: 'Archipelago Ferry',
    bundleSlug: 'stockholm',
    roles: ['Captain', 'Deckhand', 'Coffee Cart Operator', 'Commuter', 'Tourist', 'Bewildered American', 'Photographer', 'Honeymooners', 'Picnic Family', 'Off-Duty Coast Guard', 'Seasick Toddler'],
    translations: {
      tr: {
        name: 'Takımada Vapuru',
        roles: ['Kaptan', 'Tayfa', 'Kahveci', 'Yolcu', 'Turist', 'Şaşkın Amerikalı', 'Fotoğrafçı', 'Balayı Çifti', 'Piknik Yapan Aile', 'İzinli Sahil Güvenlik', 'Deniz Tutmuş Çocuk'],
      },
    },
  },
  {
    name: 'Skansen Museum',
    bundleSlug: 'stockholm',
    roles: ['Tour Guide', 'Costumed Reenactor', 'Reindeer Handler', 'Glassblower', 'Bewildered American', 'Photographer', 'School Class Teacher', 'Folk Musician', 'Cinnamon Bun Vendor', 'Off-Duty Park Ranger', 'Lost Toddler'],
    translations: {
      tr: {
        name: 'Skansen Müzesi',
        roles: ['Tur Rehberi', 'Kostümlü Canlandırmacı', 'Ren Geyiği Bakıcısı', 'Cam Üfleyici', 'Şaşkın Amerikalı', 'Fotoğrafçı', 'Sınıf Öğretmeni', 'Halk Müzisyeni', 'Tarçınlı Çörekçi', 'İzinli Park Korucusu', 'Kaybolmuş Çocuk'],
      },
    },
  },
  {
    name: 'Ice Bar',
    bundleSlug: 'stockholm',
    roles: ['Bartender', 'Bewildered American', 'Honeymooners', 'Photographer', 'Birthday Group', 'Coat Attendant', 'Ice Sculptor', 'Tourist', 'Off-Duty Hockey Player', 'Manager', 'Tipsy Brit'],
    translations: {
      tr: {
        name: 'Buz Bar',
        roles: ['Barmen', 'Şaşkın Amerikalı', 'Balayı Çifti', 'Fotoğrafçı', 'Doğum Günü Grubu', 'Palto Görevlisi', 'Buz Heykeltıraşı', 'Turist', 'İzinli Hokey Oyuncusu', 'Müdür', 'Çakırkeyif İngiliz'],
      },
    },
  },
  {
    name: 'Royal Palace',
    bundleSlug: 'stockholm',
    roles: ["King's Guard", 'Tour Guide', 'Tourist', 'Bewildered American', 'Photographer', 'Souvenir Vendor', 'Off-Duty Diplomat', 'Pickpocket', 'Curator', 'Sketch Artist', 'Lost Cruise-Ship Tourist'],
    translations: {
      tr: {
        name: 'Kraliyet Sarayı',
        roles: ['Saray Muhafızı', 'Tur Rehberi', 'Turist', 'Şaşkın Amerikalı', 'Fotoğrafçı', 'Hediyelik Eşyacı', 'İzinli Diplomat', 'Yankesici', 'Küratör', 'Karakalemci', 'Kaybolmuş Yolcu Gemisi Turisti'],
      },
    },
  },
  {
    name: 'Herring Buffet',
    bundleSlug: 'stockholm',
    roles: ['Buffet Server', 'Picky Bewildered American', 'Schnapps Pourer', 'Local Regular', 'Honeymooners', 'Tourist', 'Off-Duty Chef', 'Photographer', 'Picky Toddler', 'Reluctant Vegetarian', 'Manager'],
    translations: {
      tr: {
        name: 'Ringa Büfesi',
        roles: ['Büfe Garsonu', 'Burnu Havada Şaşkın Amerikalı', 'Snaps Servisçisi', 'Yerli Müdavim', 'Balayı Çifti', 'Turist', 'İzinli Şef', 'Fotoğrafçı', 'Mızmız Çocuk', 'İsteksiz Vejetaryen', 'Müdür'],
      },
    },
  },
  {
    name: 'T-Bana Station',
    bundleSlug: 'stockholm',
    roles: ['Conductor', 'Busker', 'Commuter', 'Tourist with Map', 'Pickpocket', 'Off-Duty Worker', 'Student', 'Transit Officer', 'Sleeping Passenger', 'Sketch Artist', 'Reindeer-Sweater Tourist'],
    translations: {
      tr: {
        name: 'T-Bana İstasyonu',
        roles: ['Vatman', 'Sokak Müzisyeni', 'Yolcu', 'Haritalı Turist', 'Yankesici', 'Mesai Sonrası Yolcu', 'Öğrenci', 'Metro Görevlisi', 'Uyuyan Yolcu', 'Karakalemci', 'Ren Geyiği Kazaklı Turist'],
      },
    },
  },
];

const NEW_YORK: SeedLocation[] = [
  {
    name: 'Times Square',
    bundleSlug: 'new-york',
    roles: ['Costumed Character', 'Street Performer', 'Billboard Operator', 'Tourist', 'Hot Dog Vendor', 'Police Officer', 'Souvenir Seller', 'Bike Tour Guide', 'News Reporter', 'Pickpocket', 'Confused Out-of-Towner'],
    translations: {
      tr: {
        name: 'Times Meydanı',
        roles: ['Kostümlü Karakter', 'Sokak Sanatçısı', 'Reklam Panosu Görevlisi', 'Turist', 'Sosisçi', 'Polis Memuru', 'Hediyelik Eşya Satıcısı', 'Bisiklet Turu Rehberi', 'Haber Muhabiri', 'Yankesici', 'Şaşkın Taşralı'],
      },
    },
  },
  {
    name: 'Brooklyn Bridge',
    bundleSlug: 'new-york',
    roles: ['Maintenance Worker', 'Cyclist', 'Jogger', 'Tourist', 'Street Artist', 'Photographer', 'Pretzel Vendor', 'Park Ranger', 'Engineer', 'Marriage Proposer', 'Lost Tour Group'],
    translations: {
      tr: {
        name: 'Brooklyn Köprüsü',
        roles: ['Bakım İşçisi', 'Bisikletçi', 'Koşucu', 'Turist', 'Sokak Ressamı', 'Fotoğrafçı', 'Simitçi', 'Park Görevlisi', 'Mühendis', 'Evlilik Teklif Eden', 'Kaybolmuş Tur Grubu'],
      },
    },
  },
  {
    name: 'Museum of Modern Art',
    bundleSlug: 'new-york',
    roles: ['Curator', 'Tour Guide', 'Security Guard', 'Art Student', 'Gift Shop Clerk', 'Restorer', 'Docent', 'Wealthy Collector', 'Photographer', 'Coat Check Attendant', 'Confused Modern Art Critic'],
    translations: {
      tr: {
        name: 'Modern Sanat Müzesi',
        roles: ['Küratör', 'Tur Rehberi', 'Güvenlik Görevlisi', 'Sanat Öğrencisi', 'Hediyelik Eşya Görevlisi', 'Restoratör', 'Müze Rehberi', 'Varlıklı Koleksiyoncu', 'Fotoğrafçı', 'Vestiyer Görevlisi', 'Kafası Karışmış Sanat Eleştirmeni'],
      },
    },
  },
  {
    name: 'Wall Street Trading Floor',
    bundleSlug: 'new-york',
    roles: ['Stock Trader', 'Broker', 'Financial Analyst', 'Compliance Officer', 'Intern', 'IT Technician', 'Floor Manager', 'Investor', 'Risk Manager', 'Janitor', 'Panicking Day Trader'],
    translations: {
      tr: {
        name: 'Wall Street Borsa Salonu',
        roles: ['Borsacı', 'Komisyoncu', 'Finansal Analist', 'Uyum Görevlisi', 'Stajyer', 'BT Teknisyeni', 'Salon Müdürü', 'Yatırımcı', 'Risk Yöneticisi', 'Temizlikçi', 'Panikleyen Günlük İşlemci'],
      },
    },
  },
  {
    name: 'Yellow Cab',
    bundleSlug: 'new-york',
    roles: ['Taxi Driver', 'Passenger', 'Dispatcher', 'Mechanic', 'Tourist', 'Late Commuter', 'Backseat Navigator', 'Meter Inspector', 'Lost Wallet Owner', 'Chatty Rider', 'Carsick Visitor'],
    translations: {
      tr: {
        name: 'Sarı Taksi',
        roles: ['Taksi Şoförü', 'Yolcu', 'Telsiz Operatörü', 'Tamirci', 'Turist', 'Geç Kalmış Çalışan', 'Arka Koltuk Navigatörü', 'Taksimetre Denetçisi', 'Cüzdanını Kaybeden', 'Çenesi Düşük Yolcu', 'Aracı Tutmuş Ziyaretçi'],
      },
    },
  },
  {
    name: 'Central Park',
    bundleSlug: 'new-york',
    roles: ['Park Ranger', 'Dog Walker', 'Hot Dog Vendor', 'Jogger', 'Street Musician', 'Carriage Driver', 'Picnicker', 'Birdwatcher', 'Rollerblader', 'Tourist', 'Squirrel Whisperer'],
    translations: {
      tr: {
        name: 'Central Park',
        roles: ['Park Görevlisi', 'Köpek Gezdiren', 'Sosisçi', 'Koşucu', 'Sokak Müzisyeni', 'Fayton Sürücüsü', 'Piknikçi', 'Kuş Gözlemcisi', 'Patenci', 'Turist', 'Sincap Fısıldayan'],
      },
    },
  },
  {
    name: 'Broadway Theater',
    bundleSlug: 'new-york',
    roles: ['Lead Actor', 'Director', 'Usher', 'Stagehand', 'Ticket Seller', 'Costume Designer', 'Orchestra Conductor', 'Theater Critic', 'Spotlight Operator', 'Playwright', 'Actor Who Forgot His Lines'],
    translations: {
      tr: {
        name: 'Broadway Tiyatrosu',
        roles: ['Başrol Oyuncusu', 'Yönetmen', 'Yer Gösterici', 'Sahne Görevlisi', 'Bilet Satıcısı', 'Kostüm Tasarımcısı', 'Orkestra Şefi', 'Tiyatro Eleştirmeni', 'Işıkçı', 'Oyun Yazarı', 'Repliğini Unutan Oyuncu'],
      },
    },
  },
  {
    name: 'Coney Island',
    bundleSlug: 'new-york',
    roles: ['Ride Operator', 'Lifeguard', 'Hot Dog Eating Champion', 'Carnival Barker', 'Fortune Teller', 'Boardwalk Vendor', 'Roller Coaster Mechanic', 'Beachgoer', 'Arcade Attendant', 'Tourist', 'Queasy Funnel Cake Eater'],
    translations: {
      tr: {
        name: 'Coney Island',
        roles: ['Salıncak Görevlisi', 'Cankurtaran', 'Sosisli Yeme Şampiyonu', 'Lunapark Çığırtkanı', 'Falcı', 'Sahil Satıcısı', 'Hız Treni Tamircisi', 'Plaja Gelen', 'Atari Salonu Görevlisi', 'Turist', 'Midesi Bulanan Tatlı Yiyici'],
      },
    },
  },
  {
    name: 'Subway Car',
    bundleSlug: 'new-york',
    roles: ['Train Conductor', 'Commuter', 'Busker', 'Transit Officer', 'Pole Dancer Performer', 'Sleeping Passenger', 'Tourist', 'Newspaper Reader', 'Maintenance Worker', 'Panhandler', 'Person Who Missed Their Stop'],
    translations: {
      tr: {
        name: 'Metro Vagonu',
        roles: ['Tren Sürücüsü', 'Yolcu', 'Vagon Müzisyeni', 'Ulaşım Görevlisi', 'Direk Akrobatı', 'Uyuyan Yolcu', 'Turist', 'Gazete Okuyan', 'Bakım İşçisi', 'Dilenci', 'Durağını Kaçıran Kişi'],
      },
    },
  },
  {
    name: 'Statue of Liberty Ferry',
    bundleSlug: 'new-york',
    roles: ['Ferry Captain', 'Deckhand', 'Tour Guide', 'Souvenir Vendor', 'Photographer', 'Park Ranger', 'Ticket Inspector', 'Tourist', 'Seagull Feeder', 'History Buff', 'Seasick Passenger'],
    translations: {
      tr: {
        name: 'Özgürlük Heykeli Vapuru',
        roles: ['Vapur Kaptanı', 'Güverteci', 'Tur Rehberi', 'Hediyelik Eşya Satıcısı', 'Fotoğrafçı', 'Park Görevlisi', 'Bilet Kontrolörü', 'Turist', 'Martı Besleyen', 'Tarih Meraklısı', 'Deniz Tutan Yolcu'],
      },
    },
  },
];

const LONDON: SeedLocation[] = [
  {
    name: 'Big Ben',
    bundleSlug: 'london',
    roles: ['Clock Keeper', 'Tour Guide', 'Tourist', 'Street Photographer', 'Police Officer', 'Maintenance Engineer', 'Souvenir Seller', 'Historian', 'Bagpiper', 'Pigeon Feeder', 'Tourist Blocking the Photo'],
    translations: {
      tr: {
        name: 'Big Ben',
        roles: ['Saat Bakıcısı', 'Tur Rehberi', 'Turist', 'Sokak Fotoğrafçısı', 'Polis Memuru', 'Bakım Mühendisi', 'Hediyelik Eşya Satıcısı', 'Tarihçi', 'Gaydacı', 'Güvercin Besleyen', 'Fotoğrafı Engelleyen Turist'],
      },
    },
  },
  {
    name: 'London Underground',
    bundleSlug: 'london',
    roles: ['Train Driver', 'Station Master', 'Commuter', 'Busker', 'Ticket Inspector', 'Cleaner', 'Lost Tourist', 'Maintenance Worker', 'Transport Officer', 'Newspaper Vendor', 'Person Who Forgot to Mind the Gap'],
    translations: {
      tr: {
        name: 'Londra Metrosu',
        roles: ['Tren Sürücüsü', 'İstasyon Şefi', 'Yolcu', 'Vagon Müzisyeni', 'Bilet Kontrolörü', 'Temizlikçi', 'Kaybolmuş Turist', 'Bakım İşçisi', 'Ulaşım Görevlisi', 'Gazete Satıcısı', 'Boşluğu Atlamayı Unutan Kişi'],
      },
    },
  },
  {
    name: 'Tower of London',
    bundleSlug: 'london',
    roles: ['Beefeater', 'Crown Jewels Guard', 'Tour Guide', 'Historian', 'Raven Master', 'Tourist', 'Souvenir Seller', 'Archaeologist', 'Ticket Clerk', 'Photographer', 'Ghost Hunter'],
    translations: {
      tr: {
        name: 'Londra Kalesi',
        roles: ['Kale Muhafızı', 'Taç Mücevherleri Bekçisi', 'Tur Rehberi', 'Tarihçi', 'Kuzgun Bakıcısı', 'Turist', 'Hediyelik Eşya Satıcısı', 'Arkeolog', 'Bilet Görevlisi', 'Fotoğrafçı', 'Hayalet Avcısı'],
      },
    },
  },
  {
    name: 'Buckingham Palace',
    bundleSlug: 'london',
    roles: ['Royal Guard', 'Butler', 'Tour Guide', 'Royal Chef', 'Gardener', 'Tourist', 'Footman', 'Press Photographer', 'Equerry', 'Housekeeper', 'Tourist Trying to Make a Guard Laugh'],
    translations: {
      tr: {
        name: 'Buckingham Sarayı',
        roles: ['Saray Muhafızı', 'Kahya', 'Tur Rehberi', 'Saray Aşçısı', 'Bahçıvan', 'Turist', 'Uşak', 'Basın Fotoğrafçısı', 'Saray Görevlisi', 'Hizmetçi', 'Muhafızı Güldürmeye Çalışan Turist'],
      },
    },
  },
  {
    name: 'British Museum',
    bundleSlug: 'london',
    roles: ['Curator', 'Egyptologist', 'Security Guard', 'Tour Guide', 'Researcher', 'Gift Shop Clerk', 'Conservator', 'School Group Teacher', 'Photographer', 'Donor', 'Visitor Lost in the Mummy Room'],
    translations: {
      tr: {
        name: 'British Museum',
        roles: ['Küratör', 'Mısır Bilimci', 'Güvenlik Görevlisi', 'Tur Rehberi', 'Araştırmacı', 'Hediyelik Eşya Görevlisi', 'Eser Koruyucu', 'Okul Grubu Öğretmeni', 'Fotoğrafçı', 'Bağışçı', 'Mumya Odasında Kaybolan Ziyaretçi'],
      },
    },
  },
  {
    name: 'West End Pub',
    bundleSlug: 'london',
    roles: ['Bartender', 'Landlord', 'Regular Patron', 'Dart Player', 'Waitress', 'Chef', 'Pub Quiz Host', 'Tourist', 'Live Band Singer', 'Cellar Man', 'Patron Who Has Had One Too Many'],
    translations: {
      tr: {
        name: 'West End Birahanesi',
        roles: ['Barmen', 'İşletme Sahibi', 'Müdavim', 'Dart Oyuncusu', 'Garson Kız', 'Aşçı', 'Bilgi Yarışması Sunucusu', 'Turist', 'Canlı Müzik Solisti', 'Mahzen Görevlisi', 'Fazla Kaçırmış Müşteri'],
      },
    },
  },
  {
    name: 'Double-Decker Bus',
    bundleSlug: 'london',
    roles: ['Bus Driver', 'Conductor', 'Commuter', 'Tourist', 'Schoolchild', 'Sightseeing Guide', 'Inspector', 'Top-Deck Sleeper', 'Shopper', 'Pram-Pushing Parent', 'Tourist Sitting at the Very Front Top'],
    translations: {
      tr: {
        name: 'Çift Katlı Otobüs',
        roles: ['Otobüs Şoförü', 'Biletçi', 'Yolcu', 'Turist', 'Okul Çocuğu', 'Tur Rehberi', 'Müfettiş', 'Üst Katta Uyuyan', 'Alışverişçi', 'Bebek Arabalı Ebeveyn', 'En Ön Üst Katta Oturan Turist'],
      },
    },
  },
  {
    name: 'Camden Market',
    bundleSlug: 'london',
    roles: ['Stall Vendor', 'Street Food Cook', 'Vintage Clothes Seller', 'Busker', 'Tourist', 'Tattoo Artist', 'Record Shop Owner', 'Punk Rocker', 'Jewellery Maker', 'Pickpocket', 'Bargain Hunter Who Overpaid'],
    translations: {
      tr: {
        name: 'Camden Pazarı',
        roles: ['Tezgah Satıcısı', 'Sokak Yemeği Aşçısı', 'İkinci El Kıyafet Satıcısı', 'Sokak Müzisyeni', 'Turist', 'Dövme Sanatçısı', 'Plak Dükkânı Sahibi', 'Punk Rockçı', 'Takı Tasarımcısı', 'Yankesici', 'Fazla Para Ödeyen Pazarlıkçı'],
      },
    },
  },
  {
    name: 'Tower Bridge',
    bundleSlug: 'london',
    roles: ['Bridge Operator', 'Tour Guide', 'Tourist', 'Cyclist', 'Maintenance Engineer', 'Photographer', 'Boat Captain', 'Street Vendor', 'Historian', 'Jogger', 'Driver Stuck While the Bridge Lifts'],
    translations: {
      tr: {
        name: 'Tower Köprüsü',
        roles: ['Köprü Operatörü', 'Tur Rehberi', 'Turist', 'Bisikletçi', 'Bakım Mühendisi', 'Fotoğrafçı', 'Tekne Kaptanı', 'Sokak Satıcısı', 'Tarihçi', 'Koşucu', 'Köprü Kalkarken Mahsur Kalan Sürücü'],
      },
    },
  },
  {
    name: 'Wimbledon Court',
    bundleSlug: 'london',
    roles: ['Tennis Player', 'Umpire', 'Ball Boy', 'Line Judge', 'Strawberries Vendor', 'Coach', 'Sports Commentator', 'Spectator', 'Groundskeeper', 'Royal Box Guest', 'Fan Who Keeps Shouting Mid-Serve'],
    translations: {
      tr: {
        name: 'Wimbledon Kortu',
        roles: ['Tenisçi', 'Hakem', 'Top Toplayıcı', 'Çizgi Hakemi', 'Çilek Satıcısı', 'Antrenör', 'Spor Yorumcusu', 'Seyirci', 'Saha Bakıcısı', 'Kraliyet Locası Konuğu', 'Servis Sırasında Bağıran Taraftar'],
      },
    },
  },
];

const ROME: SeedLocation[] = [
  {
    name: 'Colosseum',
    bundleSlug: 'rome',
    roles: ['Tour Guide', 'Archaeologist', 'Gladiator Reenactor', 'Tourist', 'Ticket Seller', 'Security Guard', 'Historian', 'Souvenir Vendor', 'Photographer', 'Restoration Worker', 'Tourist Posing as a Gladiator'],
    translations: {
      tr: {
        name: 'Kolezyum',
        roles: ['Tur Rehberi', 'Arkeolog', 'Gladyatör Canlandırıcısı', 'Turist', 'Bilet Satıcısı', 'Güvenlik Görevlisi', 'Tarihçi', 'Hediyelik Eşya Satıcısı', 'Fotoğrafçı', 'Restorasyon İşçisi', 'Gladyatör Gibi Poz Veren Turist'],
      },
    },
  },
  {
    name: 'Vatican Museums',
    bundleSlug: 'rome',
    roles: ['Curator', 'Swiss Guard', 'Tour Guide', 'Art Restorer', 'Pilgrim', 'Priest', 'Photographer', 'Historian', 'Ticket Clerk', 'Choir Singer', 'Tourist Craning at the Ceiling'],
    translations: {
      tr: {
        name: 'Vatikan Müzeleri',
        roles: ['Küratör', 'İsviçreli Muhafız', 'Tur Rehberi', 'Sanat Restoratörü', 'Hacı', 'Rahip', 'Fotoğrafçı', 'Tarihçi', 'Bilet Görevlisi', 'Koro Şarkıcısı', 'Tavana Bakmaktan Boynu Tutulan Turist'],
      },
    },
  },
  {
    name: 'Trevi Fountain',
    bundleSlug: 'rome',
    roles: ['Tour Guide', 'Coin Collector', 'Tourist', 'Street Artist', 'Gelato Vendor', 'Police Officer', 'Photographer', 'Pickpocket', 'Wish Maker', 'Fountain Cleaner', 'Tourist Who Dropped Their Phone In'],
    translations: {
      tr: {
        name: 'Aşk Çeşmesi',
        roles: ['Tur Rehberi', 'Bozuk Para Toplayan', 'Turist', 'Sokak Sanatçısı', 'Dondurmacı', 'Polis Memuru', 'Fotoğrafçı', 'Yankesici', 'Dilek Tutan', 'Çeşme Temizleyicisi', 'Telefonunu Suya Düşüren Turist'],
      },
    },
  },
  {
    name: 'Trastevere Trattoria',
    bundleSlug: 'rome',
    roles: ['Chef', 'Waiter', 'Sommelier', 'Pasta Maker', 'Owner', 'Dishwasher', 'Regular Diner', 'Tourist', 'Wine Supplier', 'Accordion Player', 'Diner Who Ordered Too Much'],
    translations: {
      tr: {
        name: 'Trastevere Lokantası',
        roles: ['Aşçı', 'Garson', 'Şarap Uzmanı', 'Makarna Ustası', 'İşletme Sahibi', 'Bulaşıkçı', 'Müdavim', 'Turist', 'Şarap Tedarikçisi', 'Akordeon Çalan', 'Fazla Sipariş Veren Müşteri'],
      },
    },
  },
  {
    name: 'Roman Forum',
    bundleSlug: 'rome',
    roles: ['Archaeologist', 'Tour Guide', 'Historian', 'Tourist', 'Excavation Worker', 'Sketch Artist', 'Photographer', 'Site Manager', 'Student', 'Souvenir Vendor', 'Tourist Who Wandered Off the Path'],
    translations: {
      tr: {
        name: 'Roma Forumu',
        roles: ['Arkeolog', 'Tur Rehberi', 'Tarihçi', 'Turist', 'Kazı İşçisi', 'Eskiz Sanatçısı', 'Fotoğrafçı', 'Saha Yöneticisi', 'Öğrenci', 'Hediyelik Eşya Satıcısı', 'Patikadan Sapan Turist'],
      },
    },
  },
  {
    name: 'Spanish Steps',
    bundleSlug: 'rome',
    roles: ['Tour Guide', 'Flower Vendor', 'Tourist', 'Street Musician', 'Fashion Photographer', 'Police Officer', 'Sketch Artist', 'Gelato Vendor', 'Local Resident', 'Bride', 'Tourist Who Sat Down Despite the Ban'],
    translations: {
      tr: {
        name: 'İspanyol Merdivenleri',
        roles: ['Tur Rehberi', 'Çiçek Satıcısı', 'Turist', 'Sokak Müzisyeni', 'Moda Fotoğrafçısı', 'Polis Memuru', 'Eskiz Sanatçısı', 'Dondurmacı', 'Mahalle Sakini', 'Gelin', 'Yasağa Rağmen Oturan Turist'],
      },
    },
  },
  {
    name: 'Roman Gelateria',
    bundleSlug: 'rome',
    roles: ['Gelato Maker', 'Cashier', 'Flavor Taster', 'Customer', 'Owner', 'Supplier', 'Tourist', 'Cone Stacker', 'Cleaner', 'Indecisive Kid', 'Customer Who Asked for Too Many Samples'],
    translations: {
      tr: {
        name: 'Roma Dondurmacısı',
        roles: ['Dondurma Ustası', 'Kasiyer', 'Aroma Tadımcısı', 'Müşteri', 'İşletme Sahibi', 'Tedarikçi', 'Turist', 'Külah Dizen', 'Temizlikçi', 'Kararsız Çocuk', 'Çok Fazla Tatma İsteyen Müşteri'],
      },
    },
  },
  {
    name: 'Vespa Repair Shop',
    bundleSlug: 'rome',
    roles: ['Mechanic', 'Shop Owner', 'Apprentice', 'Parts Supplier', 'Customer', 'Vintage Collector', 'Delivery Rider', 'Cashier', 'Tourist Renter', 'Test Rider', "Customer Whose Vespa Won't Start"],
    translations: {
      tr: {
        name: 'Vespa Tamir Dükkânı',
        roles: ['Tamirci', 'Dükkân Sahibi', 'Çırak', 'Parça Tedarikçisi', 'Müşteri', 'Klasik Araç Koleksiyoncusu', 'Kurye', 'Kasiyer', 'Turist Kiracı', 'Test Sürücüsü', 'Vespası Çalışmayan Müşteri'],
      },
    },
  },
  {
    name: 'Roman Catacombs',
    bundleSlug: 'rome',
    roles: ['Tour Guide', 'Archaeologist', 'Historian', 'Tourist', 'Lantern Bearer', 'Conservator', 'Priest', 'Ticket Seller', 'Researcher', 'Photographer', 'Tourist Who Got Separated in the Dark'],
    translations: {
      tr: {
        name: 'Katakomplar',
        roles: ['Tur Rehberi', 'Arkeolog', 'Tarihçi', 'Turist', 'Fener Taşıyan', 'Eser Koruyucu', 'Rahip', 'Bilet Satıcısı', 'Araştırmacı', 'Fotoğrafçı', 'Karanlıkta Grubundan Ayrı Düşen Turist'],
      },
    },
  },
  {
    name: 'Termini Station',
    bundleSlug: 'rome',
    roles: ['Train Conductor', 'Station Master', 'Commuter', 'Ticket Agent', 'Porter', 'Café Barista', 'Tourist', 'Pickpocket', 'Newsstand Owner', 'Cleaner', 'Traveler Who Missed the Last Train'],
    translations: {
      tr: {
        name: 'Termini Garı',
        roles: ['Tren Şefi', 'İstasyon Şefi', 'Yolcu', 'Bilet Görevlisi', 'Hamal', 'Kafe Baristası', 'Turist', 'Yankesici', 'Gazete Bayii Sahibi', 'Temizlikçi', 'Son Treni Kaçıran Yolcu'],
      },
    },
  },
];

const CAIRO: SeedLocation[] = [
  {
    name: 'Pyramids of Giza',
    bundleSlug: 'cairo',
    roles: ['Archaeologist', 'Camel Guide', 'Tour Guide', 'Souvenir Seller', 'Egyptologist', 'Sphinx Cleaner', 'Backpacker', 'Site Security Guard', 'Postcard Photographer', 'Ticket Inspector', 'Lost Mummy'],
    translations: {
      tr: {
        name: 'Giza Piramitleri',
        roles: ['Arkeolog', 'Deve Rehberi', 'Tur Rehberi', 'Hediyelik Eşya Satıcısı', 'Mısırbilimci', 'Sfenks Temizleyicisi', 'Sırt Çantalı Gezgin', 'Saha Güvenliği', 'Kartpostal Fotoğrafçısı', 'Bilet Kontrolörü', 'Kayıp Mumya'],
      },
    },
  },
  {
    name: 'Egyptian Museum',
    bundleSlug: 'cairo',
    roles: ['Curator', 'Restoration Expert', 'Tour Guide', 'School Group Teacher', 'Security Guard', 'Hieroglyph Translator', 'Gift Shop Clerk', 'Visiting Historian', 'Cleaner', 'Photographer', 'Pharaoh Statue Admirer'],
    translations: {
      tr: {
        name: 'Mısır Müzesi',
        roles: ['Müze Müdürü', 'Restorasyon Uzmanı', 'Tur Rehberi', 'Okul Gezisi Öğretmeni', 'Güvenlik Görevlisi', 'Hiyeroglif Çevirmeni', 'Hediyelik Eşya Görevlisi', 'Ziyaretçi Tarihçi', 'Temizlikçi', 'Fotoğrafçı', 'Firavun Heykeli Hayranı'],
      },
    },
  },
  {
    name: 'Khan el-Khalili Bazaar',
    bundleSlug: 'cairo',
    roles: ['Spice Merchant', 'Coppersmith', 'Haggling Tourist', 'Tea Carrier', 'Carpet Seller', 'Lantern Maker', 'Pickpocket', 'Jewelry Dealer', 'Street Musician', 'Perfume Vendor', 'Hopelessly Lost Shopper'],
    translations: {
      tr: {
        name: 'Han El-Halili Çarşısı',
        roles: ['Baharatçı', 'Bakırcı', 'Pazarlık Yapan Turist', 'Çay Taşıyıcısı', 'Halı Satıcısı', 'Fener Ustası', 'Yankesici', 'Mücevher Satıcısı', 'Sokak Müzisyeni', 'Parfümcü', 'Yolunu Tamamen Kaybetmiş Müşteri'],
      },
    },
  },
  {
    name: 'Nile Felucca',
    bundleSlug: 'cairo',
    roles: ['Boat Captain', 'Sail Handler', 'Sunset Tourist', 'Onboard Musician', 'Fisherman', 'Honeymoon Couple', 'Drink Server', 'River Navigator', 'Photographer', 'Seasick Passenger', 'Overboard Hat'],
    translations: {
      tr: {
        name: 'Nil Feluka Teknesi',
        roles: ['Tekne Kaptanı', 'Yelken Görevlisi', 'Gün Batımı Turisti', 'Tekne Müzisyeni', 'Balıkçı', 'Balayı Çifti', 'İçecek Servisi', 'Nehir Dümencisi', 'Fotoğrafçı', 'Deniz Tutan Yolcu', 'Suya Düşen Şapka'],
      },
    },
  },
  {
    name: 'Al-Azhar Mosque',
    bundleSlug: 'cairo',
    roles: ['Imam', 'Muezzin', 'Theology Student', 'Pilgrim', 'Caretaker', 'Calligraphy Teacher', 'Shoe Keeper', 'Quran Reciter', 'Visiting Scholar', 'Carpet Sweeper', 'Nervous First-Time Visitor'],
    translations: {
      tr: {
        name: 'El-Ezher Camii',
        roles: ['İmam', 'Müezzin', 'İlahiyat Öğrencisi', 'Hacı', 'Bakıcı', 'Hat Öğretmeni', 'Ayakkabıcı', 'Kuran Okuyucusu', 'Ziyaretçi Âlim', 'Halı Süpürücüsü', 'Tedirgin İlk Kez Gelen Ziyaretçi'],
      },
    },
  },
  {
    name: 'Coptic Cairo',
    bundleSlug: 'cairo',
    roles: ['Priest', 'Church Historian', 'Icon Painter', 'Pilgrim', 'Choir Singer', 'Manuscript Keeper', 'Tour Guide', 'Candle Seller', 'Bell Ringer', 'Photographer', 'Wandering Stray Cat'],
    translations: {
      tr: {
        name: 'Kıpti Kahire',
        roles: ['Rahip', 'Kilise Tarihçisi', 'İkona Ressamı', 'Hacı', 'Koro Şarkıcısı', 'El Yazması Bekçisi', 'Tur Rehberi', 'Mum Satıcısı', 'Çan Çalan', 'Fotoğrafçı', 'Avare Sokak Kedisi'],
      },
    },
  },
  {
    name: 'Shisha Cafe',
    bundleSlug: 'cairo',
    roles: ['Hookah Master', 'Waiter', 'Backgammon Player', 'Coal Boy', 'Regular Customer', 'Tea Brewer', 'Domino Champion', 'Newspaper Reader', 'Card Player', 'Football Fan', 'Coughing First-Timer'],
    translations: {
      tr: {
        name: 'Nargile Kahvesi',
        roles: ['Nargileci', 'Garson', 'Tavla Oyuncusu', 'Köz Çocuğu', 'Sabit Müşteri', 'Çay Demleyici', 'Domino Şampiyonu', 'Gazete Okuyucusu', 'Kâğıt Oyuncusu', 'Futbol Taraftarı', 'Öksüren Acemi'],
      },
    },
  },
  {
    name: 'Camel Market',
    bundleSlug: 'cairo',
    roles: ['Camel Trader', 'Veterinarian', 'Auctioneer', 'Buyer from the Desert', 'Stable Boy', 'Hay Seller', 'Branding Expert', 'Tourist Onlooker', 'Water Carrier', 'Negotiator', 'Spitting Camel'],
    translations: {
      tr: {
        name: 'Deve Pazarı',
        roles: ['Deve Tüccarı', 'Veteriner', 'Mezatçı', 'Çölden Gelen Alıcı', 'Ahır Çocuğu', 'Saman Satıcısı', 'Damgalama Uzmanı', 'Turist İzleyici', 'Su Taşıyıcısı', 'Pazarlıkçı', 'Tüküren Deve'],
      },
    },
  },
  {
    name: 'Citadel of Saladin',
    bundleSlug: 'cairo',
    roles: ['Fortress Guard', 'History Tour Guide', 'Cannon Caretaker', 'Military Museum Curator', 'Stonemason', 'Watchtower Lookout', 'School Field Trip Kid', 'Souvenir Vendor', 'Restoration Worker', 'Panorama Photographer', 'Lost Time Traveler'],
    translations: {
      tr: {
        name: 'Selahaddin Kalesi',
        roles: ['Kale Muhafızı', 'Tarih Tur Rehberi', 'Top Bakıcısı', 'Askeri Müze Müdürü', 'Taş Ustası', 'Gözetleme Kulesi Nöbetçisi', 'Okul Gezisi Çocuğu', 'Hediyelik Satıcısı', 'Restorasyon İşçisi', 'Manzara Fotoğrafçısı', 'Kaybolmuş Zaman Yolcusu'],
      },
    },
  },
  {
    name: 'Cairo Metro',
    bundleSlug: 'cairo',
    roles: ['Train Driver', 'Ticket Seller', 'Commuter', 'Station Guard', 'Snack Vendor', 'Busker', 'Women-Only Car Rider', 'Maintenance Worker', 'Map Reader', 'Pickpocket', 'Sleeping Passenger'],
    translations: {
      tr: {
        name: 'Kahire Metrosu',
        roles: ['Tren Sürücüsü', 'Bilet Satıcısı', 'Yolcu', 'İstasyon Görevlisi', 'Atıştırmalık Satıcısı', 'Sokak Çalgıcısı', 'Kadın Vagonu Yolcusu', 'Bakım İşçisi', 'Harita Okuyan', 'Yankesici', 'Uyuyan Yolcu'],
      },
    },
  },
];

const RIO: SeedLocation[] = [
  {
    name: 'Christ the Redeemer',
    bundleSlug: 'rio',
    roles: ['Tour Guide', 'Pilgrim', 'Selfie Tourist', 'Maintenance Climber', 'Souvenir Seller', 'Cog Train Operator', 'Drone Pilot', 'Wedding Photographer', 'Park Ranger', 'Ice Cream Vendor', 'Vertigo Sufferer'],
    translations: {
      tr: {
        name: 'Kurtarıcı İsa Heykeli',
        roles: ['Tur Rehberi', 'Hacı', 'Selfie Çeken Turist', 'Bakım Tırmanıcısı', 'Hediyelik Satıcısı', 'Dişli Tren Operatörü', 'Drone Pilotu', 'Düğün Fotoğrafçısı', 'Park Görevlisi', 'Dondurmacı', 'Yükseklik Korkusu Olan'],
      },
    },
  },
  {
    name: 'Copacabana Beach',
    bundleSlug: 'rio',
    roles: ['Lifeguard', 'Beach Volleyball Player', 'Caipirinha Vendor', 'Sunbather', 'Surfer', 'Sand Sculptor', 'Bikini Seller', 'Capoeira Performer', 'Coconut Water Seller', 'Footvolley Star', 'Sunburned Gringo'],
    translations: {
      tr: {
        name: 'Copacabana Plajı',
        roles: ['Cankurtaran', 'Plaj Voleybolcusu', 'Caipirinha Satıcısı', 'Güneşlenen', 'Sörfçü', 'Kum Heykeltıraşı', 'Bikini Satıcısı', 'Capoeira Gösterici', 'Hindistan Cevizi Suyu Satıcısı', 'Footvolley Yıldızı', 'Güneşten Yanmış Yabancı'],
      },
    },
  },
  {
    name: 'Sugarloaf Cable Car',
    bundleSlug: 'rio',
    roles: ['Cable Car Operator', 'Ticket Clerk', 'Thrilled Tourist', 'Safety Engineer', 'Panorama Photographer', 'Souvenir Vendor', 'Cafe Barista', 'Marmoset Watcher', 'Hiking Guide', 'Honeymooner', 'White-Knuckled Passenger'],
    translations: {
      tr: {
        name: 'Şeker Somunu Teleferiği',
        roles: ['Teleferik Operatörü', 'Bilet Görevlisi', 'Heyecanlı Turist', 'Güvenlik Mühendisi', 'Manzara Fotoğrafçısı', 'Hediyelik Satıcısı', 'Kafe Baristası', 'Maymun Gözlemcisi', 'Yürüyüş Rehberi', 'Balayı Çifti', 'Korkudan Donakalmış Yolcu'],
      },
    },
  },
  {
    name: 'Maracanã Stadium',
    bundleSlug: 'rio',
    roles: ['Star Striker', 'Goalkeeper', 'Referee', 'Die-Hard Fan', 'Stadium Announcer', 'Beer Vendor', 'Groundskeeper', 'Sports Journalist', 'Team Coach', 'Security Steward', 'Streaker on the Pitch'],
    translations: {
      tr: {
        name: 'Maracanã Stadyumu',
        roles: ['Yıldız Forvet', 'Kaleci', 'Hakem', 'Fanatik Taraftar', 'Stadyum Spikeri', 'Bira Satıcısı', 'Saha Bakıcısı', 'Spor Muhabiri', 'Takım Antrenörü', 'Güvenlik Görevlisi', 'Sahaya Atlayan Çılgın'],
      },
    },
  },
  {
    name: 'Samba School',
    bundleSlug: 'rio',
    roles: ['Dance Instructor', 'Percussionist', 'Costume Designer', 'Flag Bearer', 'Rookie Dancer', 'Choreographer', 'Float Builder', 'Rehearsal Singer', 'Drum Section Leader', 'Sequin Supplier', 'Hopelessly Off-Beat Beginner'],
    translations: {
      tr: {
        name: 'Samba Okulu',
        roles: ['Dans Eğitmeni', 'Perküsyoncu', 'Kostüm Tasarımcısı', 'Bayrak Taşıyıcı', 'Acemi Dansçı', 'Koreograf', 'Platform Yapımcısı', 'Prova Şarkıcısı', 'Davul Grubu Lideri', 'Pul Tedarikçisi', 'Tempo Tutturamayan Acemi'],
      },
    },
  },
  {
    name: 'Favela Tour',
    bundleSlug: 'rio',
    roles: ['Local Guide', 'Curious Tourist', 'Street Artist', 'Community Leader', 'Photographer', 'Kite-Flying Kid', 'Snack Stall Owner', 'Motorcycle Taxi Driver', 'Documentary Filmmaker', 'Rooftop Bar Owner', 'Tourist Who Took a Wrong Turn'],
    translations: {
      tr: {
        name: 'Favela Turu',
        roles: ['Yerel Rehber', 'Meraklı Turist', 'Sokak Sanatçısı', 'Mahalle Lideri', 'Fotoğrafçı', 'Uçurtma Uçuran Çocuk', 'Atıştırmalık Tezgâhı Sahibi', 'Motosiklet Taksi Sürücüsü', 'Belgesel Yapımcısı', 'Çatı Barı Sahibi', 'Yanlış Yola Sapan Turist'],
      },
    },
  },
  {
    name: 'Selarón Steps',
    bundleSlug: 'rio',
    roles: ['Tile Artist', 'Street Photographer', 'Music Video Director', 'Souvenir Hawker', 'Tour Guide', 'Backpacker', 'Sketch Artist', 'Influencer', 'Restoration Volunteer', 'Busking Guitarist', 'Tile Thief'],
    translations: {
      tr: {
        name: 'Selarón Merdivenleri',
        roles: ['Çini Sanatçısı', 'Sokak Fotoğrafçısı', 'Klip Yönetmeni', 'Hediyelik Seyyar Satıcısı', 'Tur Rehberi', 'Sırt Çantalı Gezgin', 'Eskiz Sanatçısı', 'Sosyal Medya Fenomeni', 'Restorasyon Gönüllüsü', 'Sokak Gitaristi', 'Çini Hırsızı'],
      },
    },
  },
  {
    name: 'Botafogo Bar',
    bundleSlug: 'rio',
    roles: ['Bartender', 'Chopp Pourer', 'Live Samba Singer', 'Regular Patron', 'Waiter', 'Pão de Queijo Cook', 'Football Watcher', 'Bouncer', 'Dart Player', 'First Date Couple', 'Tab-Dodging Customer'],
    translations: {
      tr: {
        name: 'Botafogo Barı',
        roles: ['Barmen', 'Fıçı Bira Dolduran', 'Canlı Samba Şarkıcısı', 'Sabit Müşteri', 'Garson', 'Pão de Queijo Aşçısı', 'Maç İzleyen', 'Fedai', 'Dart Oyuncusu', 'İlk Buluşma Çifti', 'Hesabı Ödemeden Kaçan Müşteri'],
      },
    },
  },
  {
    name: 'Carnival Parade',
    bundleSlug: 'rio',
    roles: ['Parade Queen', 'Drum Major', 'Float Driver', 'TV Commentator', 'Costumed Dancer', 'Judge', 'Confetti Cannon Operator', 'Street Vendor', 'Stilt Walker', 'Feather Headdress Maker', 'Lost Drunk Reveler'],
    translations: {
      tr: {
        name: 'Karnaval Geçidi',
        roles: ['Geçit Kraliçesi', 'Davul Şefi', 'Platform Sürücüsü', 'TV Yorumcusu', 'Kostümlü Dansçı', 'Jüri Üyesi', 'Konfeti Topu Operatörü', 'Sokak Satıcısı', 'Cambaz', 'Tüy Başlık Yapımcısı', 'Kaybolmuş Sarhoş Eğlenceci'],
      },
    },
  },
  {
    name: 'Tijuca Rainforest',
    bundleSlug: 'rio',
    roles: ['Park Ranger', 'Waterfall Hiker', 'Bird Watcher', 'Botanist', 'Jeep Tour Driver', 'Monkey Researcher', 'Trail Runner', 'Nature Photographer', 'Picnicking Family', 'Forest Firefighter', 'Tourist Who Lost the Trail'],
    translations: {
      tr: {
        name: 'Tijuca Yağmur Ormanı',
        roles: ['Park Görevlisi', 'Şelale Yürüyüşçüsü', 'Kuş Gözlemcisi', 'Botanikçi', 'Jeep Tur Sürücüsü', 'Maymun Araştırmacısı', 'Patika Koşucusu', 'Doğa Fotoğrafçısı', 'Piknik Yapan Aile', 'Orman İtfaiyecisi', 'Patikayı Kaybeden Turist'],
      },
    },
  },
];

const BERLIN: SeedLocation[] = [
  {
    name: 'Brandenburg Gate',
    bundleSlug: 'berlin',
    roles: ['Tour Guide', 'History Buff', 'Street Performer', 'Bratwurst Vendor', 'Selfie Tourist', 'Bicycle Rickshaw Driver', 'Protest Organizer', 'Pigeon Feeder', 'News Reporter', 'Mounted Police Officer', 'Costumed Soldier Photo Hustler'],
    translations: {
      tr: {
        name: 'Brandenburg Kapısı',
        roles: ['Tur Rehberi', 'Tarih Meraklısı', 'Sokak Sanatçısı', 'Sosis Satıcısı', 'Selfie Çeken Turist', 'Bisiklet Rikşa Sürücüsü', 'Protesto Organizatörü', 'Güvercin Besleyen', 'Haber Muhabiri', 'Atlı Polis', 'Kostümlü Asker Fotoğraf Avcısı'],
      },
    },
  },
  {
    name: 'Berghain Nightclub',
    bundleSlug: 'berlin',
    roles: ['Door Bouncer', 'Techno DJ', 'Cloakroom Attendant', 'Sweaty Raver', 'Bartender', 'Sound Engineer', 'Glow Stick Dancer', 'Drink Runner', 'Lost Tourist', 'After-Hours Regular', 'Person Who Got Rejected at the Door'],
    translations: {
      tr: {
        name: 'Berghain Gece Kulübü',
        roles: ['Kapı Fedaisi', 'Tekno DJ', 'Vestiyer Görevlisi', 'Terli Partici', 'Barmen', 'Ses Mühendisi', 'Fosforlu Çubukla Dans Eden', 'İçecek Taşıyıcısı', 'Kaybolmuş Turist', 'Sabah Saatleri Müdavimi', 'Kapıdan Geri Çevrilen Kişi'],
      },
    },
  },
  {
    name: 'Berlin Wall Memorial',
    bundleSlug: 'berlin',
    roles: ['History Teacher', 'Graffiti Artist', 'Tour Guide', 'Former East Berliner', 'Documentary Crew', 'Memorial Caretaker', 'School Group Student', 'Photographer', 'Souvenir Stand Owner', 'Visiting Diplomat', 'Tourist Posing on a Fake Checkpoint'],
    translations: {
      tr: {
        name: 'Berlin Duvarı Anıtı',
        roles: ['Tarih Öğretmeni', 'Grafiti Sanatçısı', 'Tur Rehberi', 'Eski Doğu Berlinli', 'Belgesel Ekibi', 'Anıt Bakıcısı', 'Okul Gezisi Öğrencisi', 'Fotoğrafçı', 'Hediyelik Tezgâhı Sahibi', 'Ziyaretçi Diplomat', 'Sahte Kontrol Noktasında Poz Veren Turist'],
      },
    },
  },
  {
    name: 'Currywurst Stand',
    bundleSlug: 'berlin',
    roles: ['Sausage Griller', 'Sauce Mixer', 'Hungry Construction Worker', 'Late-Night Reveler', 'Cashier', 'Fry Cook', 'Loyal Regular', 'Tourist Trying Currywurst', 'Delivery Driver', 'Napkin Hoarder', 'Ketchup Spiller'],
    translations: {
      tr: {
        name: 'Currywurst Büfesi',
        roles: ['Sosis Izgaracısı', 'Sos Karıştırıcı', 'Aç İnşaat İşçisi', 'Gece Geç Saat Eğlencecisi', 'Kasiyer', 'Patates Kızartmacısı', 'Sadık Müdavim', 'Currywurst Deneyen Turist', 'Kurye', 'Peçete İstifçisi', 'Ketçap Döken'],
      },
    },
  },
  {
    name: 'Berlin U-Bahn',
    bundleSlug: 'berlin',
    roles: ['Train Conductor', 'Ticket Inspector', 'Daily Commuter', 'Accordion Busker', 'Station Cleaner', 'Map-Confused Tourist', 'Bicycle Carrier', 'Pretzel Vendor', 'Graffiti Tagger', 'Sleeping Passenger', 'Fare Dodger'],
    translations: {
      tr: {
        name: 'Berlin Metrosu',
        roles: ['Tren Şoförü', 'Bilet Kontrolörü', 'Günlük Yolcu', 'Akordeoncu Sokak Çalgıcısı', 'İstasyon Temizlikçisi', 'Haritaya Şaşıran Turist', 'Bisiklet Taşıyan', 'Simit Satıcısı', 'Grafiti Çizen', 'Uyuyan Yolcu', 'Kaçak Yolcu'],
      },
    },
  },
  {
    name: 'Reichstag Building',
    bundleSlug: 'berlin',
    roles: ['Member of Parliament', 'Tour Guide', 'Glass Dome Visitor', 'Security Officer', 'Political Journalist', 'Rooftop Restaurant Waiter', 'Architecture Student', 'Protester Outside', 'Parliamentary Aide', 'Photographer', 'Tourist Who Forgot Their Reservation'],
    translations: {
      tr: {
        name: 'Reichstag Binası',
        roles: ['Milletvekili', 'Tur Rehberi', 'Cam Kubbe Ziyaretçisi', 'Güvenlik Görevlisi', 'Siyasi Gazeteci', 'Çatı Restoranı Garsonu', 'Mimarlık Öğrencisi', 'Dışarıdaki Protestocu', 'Meclis Yardımcısı', 'Fotoğrafçı', 'Rezervasyonunu Unutan Turist'],
      },
    },
  },
  {
    name: 'Museum Island',
    bundleSlug: 'berlin',
    roles: ['Art Curator', 'Antiquities Guide', 'Restoration Specialist', 'Ticket Clerk', 'Security Guard', 'Art Student Sketching', 'School Field Trip Teacher', 'Audio Guide Narrator', 'Cloakroom Attendant', 'Photographer', 'Person Looking for the Toilet'],
    translations: {
      tr: {
        name: 'Müze Adası',
        roles: ['Sanat Küratörü', 'Antik Eser Rehberi', 'Restorasyon Uzmanı', 'Bilet Görevlisi', 'Güvenlik Görevlisi', 'Eskiz Çizen Sanat Öğrencisi', 'Okul Gezisi Öğretmeni', 'Sesli Rehber Anlatıcısı', 'Vestiyer Görevlisi', 'Fotoğrafçı', 'Tuvalet Arayan Kişi'],
      },
    },
  },
  {
    name: 'Beer Garden',
    bundleSlug: 'berlin',
    roles: ['Beer Maid', 'Brewmaster', 'Oompah Band Player', 'Thirsty Regular', 'Pretzel Seller', 'Picnic Table Sharer', 'Tipsy Tourist', 'Grill Master', 'Stein Collector', 'Birthday Group Leader', 'Wasp-Battling Patron'],
    translations: {
      tr: {
        name: 'Bira Bahçesi',
        roles: ['Bira Servisçisi', 'Bira Ustası', 'Oompah Bando Üyesi', 'Susamış Müdavim', 'Simit Satıcısı', 'Masa Paylaşan', 'Çakırkeyf Turist', 'Izgara Ustası', 'Bira Bardağı Koleksiyoncusu', 'Doğum Günü Grubu Lideri', 'Eşekarısıyla Savaşan Müşteri'],
      },
    },
  },
  {
    name: 'Tempelhof Field',
    bundleSlug: 'berlin',
    roles: ['Kite Surfer', 'Urban Gardener', 'Roller Skater', 'Jogger', 'Picnicking Family', 'Wind-Cart Rider', 'Aviation History Guide', 'Dog Walker', 'Cyclist', 'Frisbee Player', 'Tourist Who Thought It Was Still an Airport'],
    translations: {
      tr: {
        name: 'Tempelhof Meydanı',
        roles: ['Uçurtma Sörfçüsü', 'Kent Bahçıvanı', 'Paten Kayan', 'Koşucu', 'Piknik Yapan Aile', 'Rüzgâr Arabası Süren', 'Havacılık Tarihi Rehberi', 'Köpek Gezdiren', 'Bisikletçi', 'Frizbi Oyuncusu', 'Hâlâ Havaalanı Sanan Turist'],
      },
    },
  },
  {
    name: 'Techno Record Store',
    bundleSlug: 'berlin',
    roles: ['Vinyl Clerk', 'Crate-Digging DJ', 'Store Owner', 'Indie Producer', 'Headphone Tester', 'Music Collector', 'Label Rep', 'Turntable Repairman', 'Curious Browser', 'Flyer Distributor', 'Person Who Just Wants the Wi-Fi Password'],
    translations: {
      tr: {
        name: 'Tekno Plak Dükkânı',
        roles: ['Plak Görevlisi', 'Plak Karıştıran DJ', 'Dükkân Sahibi', 'Bağımsız Yapımcı', 'Kulaklık Deneyen', 'Müzik Koleksiyoncusu', 'Plak Şirketi Temsilcisi', 'Pikap Tamircisi', 'Meraklı Müşteri', 'Broşür Dağıtan', 'Sadece Wi-Fi Şifresini İsteyen Kişi'],
      },
    },
  },
];

const DUBAI: SeedLocation[] = [
  {
    name: 'Burj Khalifa',
    bundleSlug: 'dubai',
    roles: ['Observation Deck Guide', 'Elevator Operator', 'Window Cleaner', 'Architect', 'Tourist', 'Security Guard', 'Souvenir Vendor', 'Photographer', 'VIP Lounge Host', 'Maintenance Engineer', 'Acrophobic Tourist'],
    translations: {
      tr: {
        name: 'Burç Halife',
        roles: ['Seyir Terası Rehberi', 'Asansör Görevlisi', 'Cam Temizleyici', 'Mimar', 'Turist', 'Güvenlik Görevlisi', 'Hediyelik Eşya Satıcısı', 'Fotoğrafçı', 'VIP Salon Görevlisi', 'Bakım Mühendisi', 'Yükseklik Korkusu Olan Turist'],
      },
    },
  },
  {
    name: 'Dubai Mall',
    bundleSlug: 'dubai',
    roles: ['Mall Cop', 'Luxury Boutique Clerk', 'Aquarium Diver', 'Personal Shopper', 'Window Display Designer', 'Food Court Cashier', 'Ice Rink Attendant', 'Tourist', 'Valet Driver', 'Cleaning Crew', 'Lost Toddler'],
    translations: {
      tr: {
        name: 'Dubai Alışveriş Merkezi',
        roles: ['Site Güvenliği', 'Lüks Butik Görevlisi', 'Akvaryum Dalgıcı', 'Kişisel Alışveriş Danışmanı', 'Vitrin Tasarımcısı', 'Yemek Katı Kasiyeri', 'Buz Pisti Görevlisi', 'Turist', 'Vale Şoförü', 'Temizlik Ekibi', 'Kaybolmuş Çocuk'],
      },
    },
  },
  {
    name: 'Gold Souk',
    bundleSlug: 'dubai',
    roles: ['Gold Trader', 'Jewelry Appraiser', 'Goldsmith', 'Haggling Tourist', 'Security Guard', 'Money Changer', 'Necklace Designer', 'Shop Owner', 'Porter', 'Window Shopper', 'Pickpocket'],
    translations: {
      tr: {
        name: 'Altın Çarşısı',
        roles: ['Altın Tüccarı', 'Mücevher Eksperi', 'Kuyumcu', 'Pazarlık Yapan Turist', 'Güvenlik Görevlisi', 'Döviz Bozdurucu', 'Kolye Tasarımcısı', 'Dükkan Sahibi', 'Hamal', 'Vitrin Gezgini', 'Yankesici'],
      },
    },
  },
  {
    name: 'Desert Safari Camp',
    bundleSlug: 'dubai',
    roles: ['Dune Bashing Driver', 'Falconer', 'Belly Dancer', 'Camel Handler', 'Henna Artist', 'Shisha Server', 'Bonfire Tender', 'Tour Guide', 'Sandboarder', 'Quad Bike Renter', 'Carsick Tourist'],
    translations: {
      tr: {
        name: 'Çöl Safari Kampı',
        roles: ['Kum Tepesi Sürücüsü', 'Doğancı', 'Göbek Dansçısı', 'Deve Bakıcısı', 'Kına Sanatçısı', 'Nargile Garsonu', 'Şenlik Ateşi Görevlisi', 'Tur Rehberi', 'Kum Kayakçısı', 'ATV Kiralayan', 'Aracı Tutan Turist'],
      },
    },
  },
  {
    name: 'Palm Jumeirah Resort',
    bundleSlug: 'dubai',
    roles: ['Pool Bartender', 'Cabana Attendant', 'Concierge', 'Jet Ski Instructor', 'Spa Therapist', 'Honeymooning Guest', 'Lifeguard', 'Beach DJ', 'Towel Boy', 'Resort Manager', 'Sunburned Influencer'],
    translations: {
      tr: {
        name: 'Palm Jumeirah Tatil Köyü',
        roles: ['Havuz Barmeni', 'Kabana Görevlisi', 'Konsiyerj', 'Jet Ski Eğitmeni', 'Spa Terapisti', 'Balayındaki Misafir', 'Cankurtaran', 'Plaj DJ\'i', 'Havlu Görevlisi', 'Tesis Müdürü', 'Yanmış Influencer'],
      },
    },
  },
  {
    name: 'Dubai Marina Yacht',
    bundleSlug: 'dubai',
    roles: ['Yacht Captain', 'Deckhand', 'Champagne Server', 'Wealthy Charterer', 'Sunbathing Guest', 'Navigator', 'Onboard Chef', 'Photographer', 'Wakeboarder', 'Marina Dockmaster', 'Seasick Guest'],
    translations: {
      tr: {
        name: 'Dubai Marina Yatı',
        roles: ['Yat Kaptanı', 'Güverte Görevlisi', 'Şampanya Garsonu', 'Zengin Kiralayan', 'Güneşlenen Misafir', 'Dümenci', 'Tekne Aşçısı', 'Fotoğrafçı', 'Wakeboardçu', 'Marina Liman Şefi', 'Deniz Tutan Misafir'],
      },
    },
  },
  {
    name: 'Ski Dubai',
    bundleSlug: 'dubai',
    roles: ['Ski Instructor', 'Penguin Keeper', 'Snowboarder', 'Chairlift Operator', 'Equipment Rental Clerk', 'Hot Chocolate Vendor', 'Toboggan Rider', 'Slope Groomer', 'First-Time Skier', 'Snowball Fighter', 'Freezing Tourist in Shorts'],
    translations: {
      tr: {
        name: 'Ski Dubai',
        roles: ['Kayak Eğitmeni', 'Penguen Bakıcısı', 'Snowboardçu', 'Telesiyej Görevlisi', 'Ekipman Kiralama Görevlisi', 'Sıcak Çikolata Satıcısı', 'Kızakçı', 'Pist Bakımcısı', 'İlk Kez Kayan', 'Kar Topu Savaşçısı', 'Şortla Donan Turist'],
      },
    },
  },
  {
    name: 'Spice Souk',
    bundleSlug: 'dubai',
    roles: ['Spice Merchant', 'Saffron Seller', 'Tea Blender', 'Curious Tourist', 'Aroma Expert', 'Sack Porter', 'Incense Vendor', 'Shop Owner', 'Bargain Hunter', 'Recipe Collector', 'Sneezing Customer'],
    translations: {
      tr: {
        name: 'Baharat Çarşısı',
        roles: ['Baharat Tüccarı', 'Safran Satıcısı', 'Çay Harmancısı', 'Meraklı Turist', 'Aroma Uzmanı', 'Çuval Hamalı', 'Tütsü Satıcısı', 'Dükkan Sahibi', 'Pazarlıkçı', 'Tarif Toplayıcısı', 'Hapşıran Müşteri'],
      },
    },
  },
  {
    name: 'Abra Water Taxi',
    bundleSlug: 'dubai',
    roles: ['Abra Boatman', 'Fare Collector', 'Commuting Local', 'Sightseeing Tourist', 'Creek Fisherman', 'Cargo Loader', 'Dock Attendant', 'Photographer', 'Spice Trader Passenger', 'Tour Guide', 'Passenger Who Lost His Phone Overboard'],
    translations: {
      tr: {
        name: 'Abra Su Taksisi',
        roles: ['Abra Kayıkçısı', 'Ücret Toplayıcısı', 'İşe Giden Yerli', 'Gezen Turist', 'Haliç Balıkçısı', 'Yük Yükleyici', 'İskele Görevlisi', 'Fotoğrafçı', 'Baharat Tüccarı Yolcu', 'Tur Rehberi', 'Telefonunu Suya Düşüren Yolcu'],
      },
    },
  },
  {
    name: 'Burj Al Arab Lobby',
    bundleSlug: 'dubai',
    roles: ['Butler', 'Gold-Trimmed Doorman', 'Royal Suite Guest', 'Pianist', 'Concierge', 'Afternoon Tea Server', 'Chauffeur', 'Floral Designer', 'Security Detail', 'Celebrity Guest', 'Tourist Sneaking In for Photos'],
    translations: {
      tr: {
        name: 'Burj Al Arab Lobisi',
        roles: ['Uşak', 'Altın Süslü Kapı Görevlisi', 'Kraliyet Süiti Misafiri', 'Piyanist', 'Konsiyerj', 'İkindi Çayı Garsonu', 'Şoför', 'Çiçek Tasarımcısı', 'Özel Güvenlik', 'Ünlü Misafir', 'Fotoğraf İçin Gizlice Giren Turist'],
      },
    },
  },
];

const BANGKOK: SeedLocation[] = [
  {
    name: 'Grand Palace',
    bundleSlug: 'bangkok',
    roles: ['Royal Guard', 'Temple Monk', 'Tour Guide', 'Gilding Artisan', 'Reverent Pilgrim', 'Souvenir Vendor', 'Palace Historian', 'Photographer', 'Ticket Inspector', 'Garden Keeper', 'Tourist in Improper Attire'],
    translations: {
      tr: {
        name: 'Büyük Saray',
        roles: ['Kraliyet Muhafızı', 'Tapınak Keşişi', 'Tur Rehberi', 'Yaldız Ustası', 'Saygılı Hacı', 'Hediyelik Eşya Satıcısı', 'Saray Tarihçisi', 'Fotoğrafçı', 'Bilet Kontrolörü', 'Bahçıvan', 'Uygunsuz Kıyafetli Turist'],
      },
    },
  },
  {
    name: 'Floating Market',
    bundleSlug: 'bangkok',
    roles: ['Boat Vendor', 'Fruit Seller', 'Noodle Cook', 'Coconut Carver', 'Haggling Tourist', 'Paddle Rower', 'Souvenir Trader', 'Photographer', 'Fishmonger', 'Canal Guide', 'Tourist Who Dropped His Wallet in the Canal'],
    translations: {
      tr: {
        name: 'Yüzen Pazar',
        roles: ['Tekne Satıcısı', 'Meyve Satıcısı', 'Erişte Aşçısı', 'Hindistan Cevizi Oymacısı', 'Pazarlık Yapan Turist', 'Kürekçi', 'Hediyelik Eşya Tüccarı', 'Fotoğrafçı', 'Balıkçı', 'Kanal Rehberi', 'Cüzdanını Kanala Düşüren Turist'],
      },
    },
  },
  {
    name: 'Khao San Road',
    bundleSlug: 'bangkok',
    roles: ['Backpacker', 'Bar Promoter', 'Pad Thai Vendor', 'Tattoo Artist', 'Hostel Owner', 'Street Musician', 'Scorpion Snack Seller', 'Tuk-Tuk Driver', 'DJ', 'Souvenir Hawker', 'Hungover Traveler'],
    translations: {
      tr: {
        name: 'Khao San Yolu',
        roles: ['Sırt Çantalı Gezgin', 'Bar Tanıtımcısı', 'Pad Thai Satıcısı', 'Dövme Sanatçısı', 'Hostel Sahibi', 'Sokak Müzisyeni', 'Akrep Atıştırmalık Satıcısı', 'Tuk-Tuk Şoförü', 'DJ', 'Hediyelik Eşya Satıcısı', 'Akşamdan Kalma Gezgin'],
      },
    },
  },
  {
    name: 'Wat Arun Temple',
    bundleSlug: 'bangkok',
    roles: ['Buddhist Monk', 'Incense Seller', 'Spire Climber', 'Devout Worshipper', 'Tour Guide', 'Porcelain Restorer', 'Alms Collector', 'Photographer', 'Bell Ringer', 'Lotus Flower Vendor', 'Exhausted Tourist Climbing the Steep Stairs'],
    translations: {
      tr: {
        name: 'Wat Arun Tapınağı',
        roles: ['Budist Keşiş', 'Tütsü Satıcısı', 'Kule Tırmanıcısı', 'Dindar İbadetçi', 'Tur Rehberi', 'Porselen Restoratörü', 'Sadaka Toplayıcısı', 'Fotoğrafçı', 'Çan Çalan', 'Nilüfer Satıcısı', 'Dik Merdivenleri Çıkarken Bitkin Düşen Turist'],
      },
    },
  },
  {
    name: 'Tuk-Tuk',
    bundleSlug: 'bangkok',
    roles: ['Tuk-Tuk Driver', 'Bargaining Passenger', 'Traffic Cop', 'Street Food Lover', 'Lost Tourist', 'Local Commuter', 'Mechanic', 'Sightseer', 'Gem Shop Shill', 'Backpacker', 'Passenger Clutching the Bar for Dear Life'],
    translations: {
      tr: {
        name: 'Tuk-Tuk',
        roles: ['Tuk-Tuk Şoförü', 'Pazarlık Eden Yolcu', 'Trafik Polisi', 'Sokak Yemeği Tutkunu', 'Kaybolmuş Turist', 'Yerli Yolcu', 'Tamirci', 'Manzara İzleyen', 'Mücevher Dükkanı Yönlendiricisi', 'Sırt Çantalı Gezgin', 'Korkudan Tutamağa Yapışan Yolcu'],
      },
    },
  },
  {
    name: 'Chatuchak Market',
    bundleSlug: 'bangkok',
    roles: ['Antique Dealer', 'Pet Stall Owner', 'Vintage Clothes Seller', 'Plant Vendor', 'Bargain Hunter', 'Food Stall Cook', 'Art Vendor', 'Lost Shopper', 'Porter', 'Handicraft Maker', 'Tourist Who Lost His Friends in the Maze'],
    translations: {
      tr: {
        name: 'Chatuchak Pazarı',
        roles: ['Antikacı', 'Evcil Hayvan Standı Sahibi', 'İkinci El Giysi Satıcısı', 'Bitki Satıcısı', 'Pazarlıkçı', 'Yemek Standı Aşçısı', 'Sanat Eseri Satıcısı', 'Kaybolmuş Müşteri', 'Hamal', 'El Sanatları Ustası', 'Labirentte Arkadaşlarını Kaybeden Turist'],
      },
    },
  },
  {
    name: 'Rooftop Sky Bar',
    bundleSlug: 'bangkok',
    roles: ['Mixologist', 'VIP Guest', 'Jazz Singer', 'Cocktail Waitress', 'Skyline Photographer', 'Bouncer', 'Sommelier', 'Marriage Proposer', 'Lounge DJ', 'Bar Manager', 'Guest Terrified of the Glass Edge'],
    translations: {
      tr: {
        name: 'Çatı Katı Sky Bar',
        roles: ['Kokteyl Ustası', 'VIP Misafir', 'Caz Şarkıcısı', 'Kokteyl Garsonu', 'Şehir Manzarası Fotoğrafçısı', 'Fedai', 'Şarap Uzmanı', 'Evlenme Teklifi Eden', 'Lounge DJ', 'Bar Müdürü', 'Cam Kenardan Ödü Kopan Misafir'],
      },
    },
  },
  {
    name: 'Muay Thai Stadium',
    bundleSlug: 'bangkok',
    roles: ['Muay Thai Fighter', 'Ringside Referee', 'Trainer', 'Gambling Bettor', 'Ring Announcer', 'Cornerman', 'Ticket Seller', 'Excited Spectator', 'Sports Reporter', 'Cutman', 'Tourist Who Bet His Entire Budget'],
    translations: {
      tr: {
        name: 'Muay Thai Stadyumu',
        roles: ['Muay Thai Dövüşçüsü', 'Ring Hakemi', 'Antrenör', 'Bahisçi', 'Ring Spikeri', 'Köşe Görevlisi', 'Bilet Satıcısı', 'Heyecanlı Seyirci', 'Spor Muhabiri', 'Yara Bakıcısı', 'Tüm Bütçesini Bahse Yatıran Turist'],
      },
    },
  },
  {
    name: 'Street Food Stall',
    bundleSlug: 'bangkok',
    roles: ['Wok Chef', 'Skewer Griller', 'Mango Sticky Rice Maker', 'Hungry Local', 'Adventurous Foodie', 'Drink Pourer', 'Plastic Stool Sitter', 'Spice Level Tester', 'Night Market Stroller', 'Dishwasher', 'Tourist Sweating from the Chili'],
    translations: {
      tr: {
        name: 'Sokak Yemeği Tezgahı',
        roles: ['Wok Aşçısı', 'Şiş Izgaracısı', 'Mangolu Yapışkan Pirinç Ustası', 'Aç Yerli', 'Maceracı Gurme', 'İçecek Dolduran', 'Plastik Tabureye Oturan', 'Acı Seviyesi Test Eden', 'Gece Pazarı Gezgini', 'Bulaşıkçı', 'Acıdan Terleyen Turist'],
      },
    },
  },
  {
    name: 'Chao Phraya River Ferry',
    bundleSlug: 'bangkok',
    roles: ['Ferry Captain', 'Ticket Conductor', 'Commuting Office Worker', 'Sightseeing Tourist', 'Deckhand', 'River Photographer', 'Snack Vendor', 'Schoolkid Passenger', 'Pier Attendant', 'Tour Guide', 'Passenger Splashed by the Wake'],
    translations: {
      tr: {
        name: 'Chao Phraya Nehir Vapuru',
        roles: ['Vapur Kaptanı', 'Bilet Görevlisi', 'İşe Giden Memur', 'Gezen Turist', 'Güverte Görevlisi', 'Nehir Fotoğrafçısı', 'Atıştırmalık Satıcısı', 'Öğrenci Yolcu', 'İskele Görevlisi', 'Tur Rehberi', 'Dalga Suyuyla Islanan Yolcu'],
      },
    },
  },
];

const VICTORIAN: SeedLocation[] = [
  {
    name: "Gentlemen's Club",
    bundleSlug: 'victorian-1800s',
    roles: ['Club Steward', 'Aristocrat Member', 'Brandy Connoisseur', 'Cigar Attendant', 'Retired Colonel', 'Card Player', 'Newspaper Reader', 'Club Secretary', 'Visiting Diplomat', 'Hat-Check Boy', 'Snoring Old Earl'],
    translations: {
      tr: {
        name: 'Beyefendiler Kulübü',
        roles: ['Kulüp Kahyası', 'Aristokrat Üye', 'Konyak Uzmanı', 'Puro Görevlisi', 'Emekli Albay', 'Kâğıt Oyuncusu', 'Gazete Okuyan', 'Kulüp Sekreteri', 'Ziyaretçi Diplomat', 'Şapka Vestiyer Çocuğu', 'Horlayan Yaşlı Kont'],
      },
    },
  },
  {
    name: 'Opium Den',
    bundleSlug: 'victorian-1800s',
    roles: ['Den Keeper', 'Lascar Attendant', 'Addicted Poet', 'Wealthy Patron', 'Pipe Tender', 'Undercover Inspector', 'Fallen Gentleman', 'Money Lender', 'Lookout Boy', 'Distressed Wife', 'Hallucinating Sailor'],
    translations: {
      tr: {
        name: 'Afyon Batakhanesi',
        roles: ['Batakhane Sahibi', 'Lascar Görevlisi', 'Bağımlı Şair', 'Zengin Müşteri', 'Pipo Hazırlayan', 'Gizli Müfettiş', 'Düşmüş Beyefendi', 'Tefeci', 'Gözcü Çocuk', 'Endişeli Eş', 'Sayıklayan Denizci'],
      },
    },
  },
  {
    name: 'Royal Opera House',
    bundleSlug: 'victorian-1800s',
    roles: ['Prima Donna', 'Conductor', 'Box Usher', 'Opera Critic', 'Stage Carpenter', 'Costume Mistress', 'Wealthy Patroness', 'Orchestra Violinist', 'Stage Door Keeper', 'Aspiring Tenor', 'Sobbing Theatre Ghost'],
    translations: {
      tr: {
        name: 'Kraliyet Opera Binası',
        roles: ['Başrol Sopranosu', 'Orkestra Şefi', 'Loca Yer Göstericisi', 'Opera Eleştirmeni', 'Sahne Marangozu', 'Kostüm Sorumlusu', 'Zengin Hamiye', 'Orkestra Kemancısı', 'Sahne Kapı Görevlisi', 'Hevesli Tenor', 'Hıçkıran Tiyatro Hayaleti'],
      },
    },
  },
  {
    name: 'Steam Locomotive',
    bundleSlug: 'victorian-1800s',
    roles: ['Engine Driver', 'Fireman Stoker', 'Ticket Conductor', 'First-Class Passenger', 'Telegraph Boy', 'Station Master', 'Luggage Porter', 'Dining Car Waiter', 'Railway Engineer', 'Stowaway Urchin', 'Seasick Duchess'],
    translations: {
      tr: {
        name: 'Buharlı Lokomotif',
        roles: ['Lokomotif Makinisti', 'Kömür Atan Ateşçi', 'Bilet Kondüktörü', 'Birinci Mevki Yolcusu', 'Telgraf Çocuğu', 'İstasyon Şefi', 'Bagaj Hamalı', 'Vagon Restoran Garsonu', 'Demiryolu Mühendisi', 'Kaçak Sokak Çocuğu', 'Yol Tutan Düşes'],
      },
    },
  },
  {
    name: 'Foggy Docks',
    bundleSlug: 'victorian-1800s',
    roles: ['Dockworker', 'Ship Captain', 'Customs Officer', 'Fishmonger', 'Smuggler', 'Lamplighter', 'Net Mender', 'Harbour Master', 'Press-Gang Recruiter', 'Lost Tourist', 'One-Legged Old Sailor'],
    translations: {
      tr: {
        name: 'Sisli Limanlar',
        roles: ['Liman İşçisi', 'Gemi Kaptanı', 'Gümrük Memuru', 'Balıkçı Esnafı', 'Kaçakçı', 'Fenerci', 'Ağ Tamircisi', 'Liman Reisi', 'Zorla Asker Toplayan', 'Kaybolmuş Turist', 'Tek Bacaklı Yaşlı Denizci'],
      },
    },
  },
  {
    name: 'Scotland Yard',
    bundleSlug: 'victorian-1800s',
    roles: ['Inspector', 'Constable', 'Detective', 'Pickpocket', 'Forensic Photographer', 'Magistrate', 'Street Informant', 'Coroner', 'Desk Sergeant', 'Falsely Accused Gentleman', 'Nervous Witness'],
    translations: {
      tr: {
        name: 'Scotland Yard',
        roles: ['Müfettiş', 'Polis Memuru', 'Dedektif', 'Yankesici', 'Adli Fotoğrafçı', 'Sulh Hâkimi', 'Sokak Muhbiri', 'Adli Tabip', 'Masa Başı Çavuşu', 'Haksız Yere Suçlanan Beyefendi', 'Tedirgin Tanık'],
      },
    },
  },
  {
    name: 'Apothecary',
    bundleSlug: 'victorian-1800s',
    roles: ['Apothecary', 'Herbalist', 'Sickly Customer', 'Leech Collector', 'Pharmacy Apprentice', 'Travelling Quack', 'Worried Mother', 'Tincture Mixer', 'Tooth Puller', 'Curious Chemist', 'Hypochondriac Lord'],
    translations: {
      tr: {
        name: 'Aktar Dükkânı',
        roles: ['Eczacı Aktar', 'Şifalı Ot Uzmanı', 'Hastalıklı Müşteri', 'Sülük Toplayıcı', 'Eczane Çırağı', 'Gezgin Şarlatan', 'Endişeli Anne', 'Tentür Karıştırıcı', 'Diş Çeken', 'Meraklı Kimyager', 'Hastalık Hastası Lort'],
      },
    },
  },
  {
    name: 'Grand Ballroom',
    bundleSlug: 'victorian-1800s',
    roles: ['Debutante', 'Master of Ceremonies', 'Waltz Partner', 'Chaperone', 'String Quartet Player', 'Champagne Footman', 'Matchmaking Dowager', 'Eligible Bachelor', 'Gossiping Countess', 'Dance Card Keeper', 'Clumsy Wallflower'],
    translations: {
      tr: {
        name: 'Büyük Balo Salonu',
        roles: ['Sosyeteye İlk Çıkan Genç Kız', 'Tören Şefi', 'Vals Eşi', 'Refakatçi', 'Yaylı Dörtlü Üyesi', 'Şampanya Uşağı', 'Çöpçatan Dul Leydi', 'Uygun Bekâr Bey', 'Dedikoducu Kontes', 'Dans Kartı Sorumlusu', 'Sakar Köşe Süsü'],
      },
    },
  },
  {
    name: 'Workhouse',
    bundleSlug: 'victorian-1800s',
    roles: ['Workhouse Master', 'Matron', 'Orphan Child', 'Oakum Picker', 'Parish Beadle', 'Pauper Widow', 'Gruel Cook', 'Infirmary Nurse', 'Debt-Ridden Labourer', 'Charity Inspector', 'Porridge-Stealing Scamp'],
    translations: {
      tr: {
        name: 'Düşkünler Evi',
        roles: ['Düşkünler Evi Müdürü', 'Başhemşire', 'Yetim Çocuk', 'Halat Lifi Ayıklayan', 'Mahalle Mübaşiri', 'Yoksul Dul', 'Lapa Aşçısı', 'Revir Hemşiresi', 'Borç Batağındaki İşçi', 'Hayır Müfettişi', 'Yulaf Lapası Çalan Afacan'],
      },
    },
  },
  {
    name: 'Séance Parlour',
    bundleSlug: 'victorian-1800s',
    roles: ['Spirit Medium', 'Grieving Widow', 'Skeptical Investigator', 'Table-Rapping Assistant', 'Gullible Heiress', 'Crystal Gazer', 'Hidden Trickster', 'Devoted Believer', 'Ectoplasm Faker', 'Curious Journalist', 'Terrified Maid'],
    translations: {
      tr: {
        name: 'Ruh Çağırma Salonu',
        roles: ['Ruh Medyumu', 'Yaslı Dul', 'Şüpheci Araştırmacı', 'Masa Tıkırdatma Yardımcısı', 'Saf Mirasçı', 'Kristal Küre Bakıcısı', 'Gizli Hilebaz', 'Sadık İnanan', 'Ektoplazma Sahtekârı', 'Meraklı Gazeteci', 'Dehşete Düşmüş Hizmetçi'],
      },
    },
  },
];

const WILD_WEST: SeedLocation[] = [
  {
    name: 'Saloon',
    bundleSlug: 'wild-west',
    roles: ['Bartender', 'Saloon Singer', 'Card Sharp', 'Gunslinger', 'Sheriff', 'Piano Player', 'Drunk Cowboy', 'Bounty Hunter', 'Bar Maid', 'Traveling Salesman', 'Town Drunk'],
    translations: {
      tr: {
        name: 'Meyhane',
        roles: ['Barmen', 'Meyhane Şarkıcısı', 'Kâğıt Hilebazı', 'Silahşör', 'Şerif', 'Piyanist', 'Sarhoş Kovboy', 'Ödül Avcısı', 'Bar Garson Kızı', 'Gezgin Satıcı', 'Kasabanın Ayyaşı'],
      },
    },
  },
  {
    name: 'Gold Mine',
    bundleSlug: 'wild-west',
    roles: ['Prospector', 'Mine Foreman', 'Dynamite Handler', 'Claim Jumper', 'Pickaxe Miner', 'Assayer', 'Mule Driver', 'Mine Owner', 'Canary Keeper', 'Greedy Investor', 'Lucky Old Coot'],
    translations: {
      tr: {
        name: 'Altın Madeni',
        roles: ['Altın Arayıcısı', 'Maden Ustabaşı', 'Dinamit Uzmanı', 'Maden Gaspçısı', 'Kazma Madencisi', 'Maden Eksperi', 'Katır Sürücüsü', 'Maden Sahibi', 'Kanarya Bakıcısı', 'Açgözlü Yatırımcı', 'Şanslı Yaşlı Bunak'],
      },
    },
  },
  {
    name: 'Stagecoach',
    bundleSlug: 'wild-west',
    roles: ['Stagecoach Driver', 'Shotgun Guard', 'Wealthy Passenger', 'Mail Courier', 'Masked Bandit', 'Nervous Schoolteacher', 'Cattle Baron', 'Runaway Bride', 'Whip Cracker', 'Snake Oil Peddler', 'Travel-Sick Greenhorn'],
    translations: {
      tr: {
        name: 'Posta Arabası',
        roles: ['Posta Arabası Sürücüsü', 'Tüfekli Muhafız', 'Zengin Yolcu', 'Posta Kuryesi', 'Maskeli Haydut', 'Tedirgin Öğretmen', 'Sığır Baronu', 'Kaçak Gelin', 'Kamçı Şaklatan', 'Yılan Yağı Satıcısı', 'Yol Tutan Acemi'],
      },
    },
  },
  {
    name: "Sheriff's Office",
    bundleSlug: 'wild-west',
    roles: ['Town Sheriff', 'Loyal Deputy', 'Jailed Outlaw', 'Wanted Poster Artist', 'Visiting Marshal', 'Frightened Townsfolk', 'Gun Cleaner', 'Bail Bondsman', 'Telegraph Operator', 'Snitching Prisoner', 'Sleepy Old Jailer'],
    translations: {
      tr: {
        name: 'Şerif Karakolu',
        roles: ['Kasaba Şerifi', 'Sadık Yardımcı Şerif', 'Hapisteki Haydut', 'Aranıyor Afişi Çizeri', 'Ziyaretçi Mareşal', 'Korkmuş Kasabalı', 'Silah Temizleyici', 'Kefalet Aracısı', 'Telgraf Operatörü', 'Gammazlayan Mahkûm', 'Uykucu Yaşlı Gardiyan'],
      },
    },
  },
  {
    name: 'Cattle Ranch',
    bundleSlug: 'wild-west',
    roles: ['Ranch Owner', 'Cowhand', 'Branding Iron Man', 'Cattle Rustler', 'Ranch Cook', 'Horse Wrangler', 'Fence Mender', 'Trail Boss', 'Lasso Roper', 'Hired Gun', 'Spooked Greenhorn'],
    translations: {
      tr: {
        name: 'Sığır Çiftliği',
        roles: ['Çiftlik Sahibi', 'Çiftlik Eli', 'Damga Vuran', 'Sığır Hırsızı', 'Çiftlik Aşçısı', 'At Terbiyecisi', 'Çit Tamircisi', 'Sürü Şefi', 'Kement Atan', 'Kiralık Silahşör', 'Ürkmüş Acemi'],
      },
    },
  },
  {
    name: 'Train Robbery',
    bundleSlug: 'wild-west',
    roles: ['Outlaw Leader', 'Dynamite Bandit', 'Train Engineer', 'Armed Express Guard', 'Panicked Passenger', 'Pinkerton Detective', 'Safe Cracker', 'Horse Holder', 'Lookout Rider', 'Hidden Federal Agent', 'Fainting Heiress'],
    translations: {
      tr: {
        name: 'Tren Soygunu',
        roles: ['Haydut Reisi', 'Dinamitçi Haydut', 'Tren Makinisti', 'Silahlı Yük Muhafızı', 'Panikleyen Yolcu', 'Pinkerton Dedektifi', 'Kasa Açıcı', 'At Tutucu', 'Gözcü Atlı', 'Gizli Federal Ajan', 'Bayılan Mirasçı'],
      },
    },
  },
  {
    name: 'Frontier Bank',
    bundleSlug: 'wild-west',
    roles: ['Bank Manager', 'Teller Clerk', 'Armed Guard', 'Masked Robber', 'Wealthy Depositor', 'Vault Keeper', 'Loan Officer', 'Nervous Customer', 'Gold Weigher', 'Undercover Lawman', 'Forgetful Old Rancher'],
    translations: {
      tr: {
        name: 'Sınır Kasabası Bankası',
        roles: ['Banka Müdürü', 'Vezne Memuru', 'Silahlı Muhafız', 'Maskeli Soyguncu', 'Zengin Mevduat Sahibi', 'Kasa Bekçisi', 'Kredi Memuru', 'Tedirgin Müşteri', 'Altın Tartıcısı', 'Kılık Değiştirmiş Kanun Adamı', 'Unutkan Yaşlı Çiftçi'],
      },
    },
  },
  {
    name: 'Trading Post',
    bundleSlug: 'wild-west',
    roles: ['General Storekeeper', 'Fur Trapper', 'Native Trader', 'Wagon Pioneer', 'Supply Clerk', 'Gunsmith', 'Penny-Pinching Widow', 'Pack Mule Owner', 'Whiskey Trader', 'Wandering Drifter', 'Pickle-Barrel Loiterer'],
    translations: {
      tr: {
        name: 'Ticaret Merkezi',
        roles: ['Bakkal Dükkâncısı', 'Kürk Avcısı', 'Yerli Tüccar', 'At Arabalı Göçmen', 'Erzak Memuru', 'Silah Ustası', 'Cimri Dul', 'Yük Katırı Sahibi', 'Viski Tüccarı', 'Gezgin Serseri', 'Turşu Fıçısı Başında Aylaklık Eden'],
      },
    },
  },
  {
    name: 'Gambling Hall',
    bundleSlug: 'wild-west',
    roles: ['Faro Dealer', 'High-Stakes Gambler', 'Roulette Croupier', 'Cheating Cardsharp', 'House Pit Boss', 'Lucky Drifter', 'Cigar Girl', 'Loan Shark', 'Sore Loser', 'Whiskey Server', 'Superstitious Old Gambler'],
    translations: {
      tr: {
        name: 'Kumarhane Salonu',
        roles: ['Faro Krupiyesi', 'Yüksek Bahis Kumarbazı', 'Rulet Krupiyesi', 'Hile Yapan Kâğıtçı', 'Salon Şefi', 'Şanslı Serseri', 'Puro Satan Kız', 'Tefeci', 'Hırçın Kaybeden', 'Viski Servisi Yapan', 'Boş İnançlı Yaşlı Kumarbaz'],
      },
    },
  },
  {
    name: 'Boomtown Jail',
    bundleSlug: 'wild-west',
    roles: ['Jailer', 'Convicted Cattle Thief', 'Hanging Judge', 'Visiting Preacher', 'Drunk Disorderly', 'Lynch Mob Leader', 'Prison Cook', 'Defense Lawyer', 'Escape Plotter', 'Worried Sweetheart', 'Harmonica-Playing Prisoner'],
    translations: {
      tr: {
        name: 'Maden Kasabası Hapishanesi',
        roles: ['Gardiyan', 'Mahkûm Sığır Hırsızı', 'Acımasız Yargıç', 'Ziyaretçi Vaiz', 'Sarhoş Kabadayı', 'Linç Çetesi Lideri', 'Hapishane Aşçısı', 'Savunma Avukatı', 'Firar Planlayan', 'Endişeli Sevgili', 'Mızıka Çalan Mahkûm'],
      },
    },
  },
];

const SEED: SeedLocation[] = [
  ...FREE,
  ...ISTANBUL,
  ...CYBERPUNK,
  ...PARIS,
  ...TOKYO,
  ...STOCKHOLM,
  ...NEW_YORK,
  ...LONDON,
  ...ROME,
  ...CAIRO,
  ...RIO,
  ...BERLIN,
  ...DUBAI,
  ...BANGKOK,
  ...VICTORIAN,
  ...WILD_WEST,
];

/**
 * Dev-only sanity check over the static SEED table. Verifies the
 * EN/TR lock-step invariant (every location has exactly 11 English roles
 * and 11 Turkish roles) and that English names are unique. Returns the
 * offenders so `npx convex run locations:validateSeed` fails loudly when
 * content is added incorrectly.
 */
export const validateSeed = query({
  args: {},
  handler: async () => {
    const roleCountErrors: string[] = [];
    const dupeNames: string[] = [];
    const seen = new Set<string>();
    for (const loc of SEED) {
      const en = loc.roles.length;
      const tr = loc.translations.tr.roles.length;
      if (en !== 11 || tr !== 11) {
        roleCountErrors.push(`${loc.name}: EN=${en} TR=${tr}`);
      }
      if (seen.has(loc.name)) dupeNames.push(loc.name);
      seen.add(loc.name);
    }
    return {
      total: SEED.length,
      ok: roleCountErrors.length === 0 && dupeNames.length === 0,
      roleCountErrors,
      dupeNames,
    };
  },
});

/**
 * Idempotent: returns { inserted: 0 } if locations already exist. Public
 * so the CLI can call `npx convex run locations:seed` on a fresh DB.
 */
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
 * One-shot, re-runnable migration. For every SEED entry that exists in
 * the DB by canonical English name but lacks a `translations.tr` block,
 * patch it in. No-op for rows that already have Turkish.
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

/**
 * One-shot, re-runnable migration to:
 *  - Pad existing free-set locations to 11 roles (EN + TR in lock-step)
 *    by appending the missing tail from SEED.
 *  - Apply the SEED renames (Submarine → Cold War Sub, etc.).
 *  - Insert any SEED rows that are missing entirely (e.g. new bundle
 *    locations on a previously-seeded DB).
 *
 * Matches existing rows by EITHER current English name OR the previous
 * pre-rename name (hard-coded mapping below). Idempotent.
 */
const RENAME_MAP: Record<string, string> = {
  Submarine: 'Cold War Sub',
  'Pirate Ship': 'Buccaneer Galleon',
  'Space Station': 'Orbital Outpost',
  'Day Spa': 'Wellness Retreat',
  Hospital: 'Trauma Ward',
  Embassy: 'Consulate',
};

export const padFreeLocationsToEleven = mutation({
  args: {},
  handler: async (ctx) => {
    const all = await ctx.db.query('locations').collect();
    const byName = new Map(all.map((l) => [l.name, l]));
    let patched = 0;
    let inserted = 0;
    let renamed = 0;

    for (const seed of SEED) {
      // Find by current name first; fall back to old-name mapping.
      let row = byName.get(seed.name);
      if (!row) {
        const oldName = Object.entries(RENAME_MAP).find(
          ([, neu]) => neu === seed.name,
        )?.[0];
        if (oldName) row = byName.get(oldName);
      }

      if (!row) {
        await ctx.db.insert('locations', seed);
        inserted++;
        continue;
      }

      const patch: Record<string, unknown> = {};

      if (row.name !== seed.name) {
        patch.name = seed.name;
        renamed++;
      }
      if (row.roles.length < seed.roles.length) {
        patch.roles = seed.roles;
      }
      if (
        seed.translations?.tr &&
        (row.translations?.tr?.roles?.length ?? 0) <
          seed.translations.tr.roles.length
      ) {
        patch.translations = seed.translations;
      }
      if (
        seed.bundleSlug !== undefined &&
        row.bundleSlug !== seed.bundleSlug
      ) {
        patch.bundleSlug = seed.bundleSlug;
      }

      if (Object.keys(patch).length > 0) {
        await ctx.db.patch(row._id, patch);
        patched++;
      }
    }

    return { patched, inserted, renamed };
  },
});

export const list = query({
  args: {},
  handler: async (ctx) => {
    const all = await ctx.db.query('locations').collect();
    return all.map((l) => ({
      _id: l._id,
      name: l.name,
      bundleSlug: l.bundleSlug ?? null,
    }));
  },
});

/**
 * Locale-projected list for the lobby's locations picker. Returns every
 * row that's eligible to show up in this room — free locations plus any
 * row whose bundle is in the host's `ownedBundleSlugs` set. Each row
 * carries its `bundleSlug` so the client can group by bundle title using
 * data already cached in `bundlesProvider`.
 */
export const listForPicker = query({
  args: {
    locale: LOCALE_VALIDATOR,
    ownedBundleSlugs: v.optional(v.array(v.string())),
  },
  handler: async (ctx, args) => {
    const owned = new Set(args.ownedBundleSlugs ?? []);
    const all = await ctx.db.query('locations').collect();
    const eligible = all.filter(
      (l) => l.bundleSlug == null || owned.has(l.bundleSlug),
    );
    return eligible.map((l) => {
      const localized =
        args.locale === 'tr' && l.translations?.tr
          ? l.translations.tr.name
          : l.name;
      return {
        _id: l._id,
        name: localized,
        bundleSlug: l.bundleSlug ?? null,
      };
    });
  },
});
