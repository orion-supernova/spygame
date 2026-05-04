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

const SEED: SeedLocation[] = [...FREE, ...ISTANBUL, ...CYBERPUNK, ...PARIS, ...TOKYO, ...STOCKHOLM];

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
