import { mutation, query } from './_generated/server';

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
];

const SEED: SeedLocation[] = [...FREE, ...ISTANBUL, ...CYBERPUNK];

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
