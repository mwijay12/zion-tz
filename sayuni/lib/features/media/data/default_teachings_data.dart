import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sermon_media_item.dart';

class DefaultTeachingsData {
  static final List<SermonMediaItem> items = [
    SermonMediaItem(
      id: 'teach-upendo-kristo',
      title: 'Upendo wa Kristo: Msingi na Amri Kuu ya Kanisa',
      preacher: 'Mchungaji na Askofu Mercy James',
      scripture: 'Yoh 13:34-35 • 1 Kor 13:1-6 • 1 Yoh 4:7 • 1 Pet 4:8',
      date: 'Ibada Kuu ya Jumapili',
      duration: 'Dakika 5 kusoma',
      type: 'text',
      category: 'Mafundisho',
      readTime: 'Dakika 5 kusoma',
      keyVerse:
          '"Amri mpya nawapa, Mpendane. Kama vile nilivyowapenda ninyi, nanyi mpendane vivyo hivyo. Hivyo watu wote watatambua ya kuwa ninyi mmekuwa wanafunzi wangu, mkiwa na upendo ninyi kwa ninyi." — Yohana 13:34-35',
      scriptureList: [
        'Yohana 13:34-35',
        'Yohana 15:12',
        '1 Yohana 3:11',
        'Marko 12:31',
        '1 Petro 4:8',
        '1 Wakorintho 13:1-6',
        '1 Yohana 4:7',
      ],
      description:
          'Amri mpya nawapa, mpendane kama vile nilivyowapenda ninyi (Yohana 13:34-35, 15:12). Huu ndio ujumbe mliousikia tangu mwanzo kwamba tupendane (1 Yohana 3:11, Marko 12:31). Upendo huvumilia, hufadhili, hauhusudu na husitiri wingi wa dhambi (1 Petro 4:8, 1 Wakorintho 13:1-6). Mungu ni pendo naye akaaye katika pendo hukaa ndani ya Mungu (1 Yohana 4:7).',
      imageUrl: 'assets/images/church_front.jpg',
      fullArticle: '''
### Utangulizi: Alama ya Kweli ya Mwanafunzi wa Yesu
Katika ulimwengu uliojaa utengano, ubinafsi na migogoro, Bwana wetu Yesu Kristo alitupa kitambulisho kikuu kinachomtofautisha mkristo wa kweli na mtu wa ulimwengu. Kitambulisho hicho si mavazi, cheo wala ukubwa wa maneno, bali ni **UPENDO WA MATENDO**. 

Yesu alisema: *"Hivyo watu wote watatambua ya kuwa ninyi mmekuwa wanafunzi wangu, mkiwa na upendo ninyi kwa ninyi"* (Yohana 13:35). Huu ndio msingi na uti wa mgongo wa huduma ya Sayuni Jerusalem tangu mwanzo.

---

### 1. Amri Mpya: Kiwango cha Msalaba (Yohana 13:34-35, 15:12)
Katika Agano la Kale, amri ilikuwa: *"Mpende jirani yako kama nafsi yako"* (Marko 12:31). Lakini Yesu anapofika, anaweka kiwango kipya cha juu zaidi: *"Mpendane KAMA VILE NILIVYOWAPENDA NINYI"* (Yohana 15:12).
• Kristo alitupenda tulipokuwa bado wenye dhambi na wasiostahili.
• Hakupenda kwa masharti wala kwa manufaa binafsi.
• Upendo wa agape ni upendo wa kujitoa muhanga, kusamehe kabla ya kuombwa msamaha, na kuinua walioanguka.

---

### 2. Upendo Usio na Matendo Ni Kelele Tupu (1 Wakorintho 13:1-6)
Mtume Paulo anafundisha kwa ujasiri kuwa tunaweza kuwa na vipawa vikubwa vya unabii, tukasema kwa lugha za malaika, tukatoa sadaka kubwa, lakini kama hatuna upendo, sisi ni sawa na **shaba iliayo au upatu uvumao**:
• **Upendo huvumilia**: Haupati hasira upesi wala kulipiza kisasi.
• **Upendo hufadhili**: Unatafuta ustawi na kuinuliwa kwa mwingine.
• **Upendo hauhusudu**: Haufurahii kuanguka kwa mwenzako wala kuonea wivu baraka zake.
• **Upendo hautakabari**: Haujivuni wala kukosa adabu.

---

### 3. Upendo Husitiri Wingi wa Dhambi (1 Petro 4:8)
Mtume Petro anatusihi: *"Zaidi ya yote iweni na juhudi nyingi katika kupendana; kwa sababu upendano husitiri wingi wa dhambi."*
Kusitiri dhambi si kuficha uovu au unafiki; bali ni moyo wa kichungaji unaomkinga ndugu asiaibike hadharani, bali unamrejesha kwa upole, maombi na staha. Jamii na kanisa linapopata changamoto, jibu letu la kwanza linapaswa kuwa upendo na maombi badala ya maneno mitaani.

---

### 4. Asili Yetu: Mungu Mwenyewe Ni Upendo (1 Yohana 4:7)
*"Wapenzi, na mpendane; kwa kuwa pendo latoka kwa Mungu, na kila apendaye amezaliwa na Mungu, naye anamjua Mungu."*
Mtu anayedai kumjua Mungu lakini anawachukia ndugu zake, anajidanganya mwenyewe. Upendo ndio hewa safi ya Ufalme wa Mbinguni na nguzo thabiti ya madhabahu ya Sayuni.
''',
      takeaways: [
        'Upendo ni amri si hiari — ndio alama ya pekee inayothibitisha uanafunzi wa Kristo.',
        'Vipawa vya kiroho bila upendo ni kelele tupu na upatu uvumao (1 Kor 13:1-3).',
        'Tusitiri udhaifu wa wenzetu kwa maombi na ushauri wa upole badala ya kusengenya (1 Pet 4:8).',
        'Piga simu au mtembelee ndugu mmoja wiki hii kufungua ukurasa wa msamaha na amani.',
      ],
      pastoralPrayer:
          'Ee Bwana Mungu wetu, Baba wa Bwana wetu Yesu Kristo, tunakushukuru kwa upendo wako mkuu uliodhihirika msalabani. Ondoa ndani ya mioyo yetu kila aina ya kinyongo, uchungu, ubinafsi na wivu. Tujaze Roho Mtakatifu ili tuweze kupendana kwa moyo safi na kwa dhati. Bariki familia zote za Sayuni Jerusalem na kanisa lako lote nchini Tanzania. Katika jina takatifu la Yesu Kristo, Amen!',
    ),

    SermonMediaItem(
      id: 'teach-uchumi-mkristo',
      title: 'Uchumi na Maendeleo ya Mkristo: Hekima na Kibali',
      preacher: 'Mchungaji Alex',
      scripture:
          'Mathayo 19:27-29 • Mhubiri 10:10 • Malaki 3:7-12 • Kutoka 33:14-19',
      date: 'Semina ya Uchumi na Maendeleo',
      duration: 'Dakika 6 kusoma',
      type: 'text',
      category: 'Mafundisho',
      readTime: 'Dakika 6 kusoma',
      keyVerse:
          '"Chuma kikiwa butu, wala asikinoe makali, ndipo hana budi kutumia nguvu zaidi; lakini hekima yafaa kuelekeza." — Mhubiri 10:10',
      scriptureList: [
        'Mathayo 19:27-29',
        'Mhubiri 10:10',
        'Malaki 3:7-12',
        'Kutoka 33:14-19',
        '1 Samweli 2:7',
        'Mwanzo 30:25-32',
      ],
      description:
          'Mch. Alex alifafanua swali la Petro: "Tazama, sisi tumeacha vyote; tutapata nini basi?" Yesu akajibu atapokea mara mia sasa duniani na uzima wa milele mbinguni. Mfano wa Ayubu: kumcha Mungu na kurejeshewa mara mbili. Kibali cha Mungu huleta mafanikio (Kutoka 33:14-19, 1 Samweli 2:7, Malaki 3:7-12, Mwanzo 30:25-32). Chuma kikiwa butu hutumia nguvu zaidi bali hekima yafaa kuelekeza (Mhubiri 10:10). Watu wapende kujifunza, kujiendeleza, na kuwa na nidhamu ya kifedha.',
      imageUrl: 'assets/images/church_men_fellowship.jpg',
      fullArticle: '''
### Utangulizi: Mtazamo wa Kiungu Kuhusu Mali na Ustawi
Kuna dhana potofu iliyowapoteza baadhi ya wakristo kwamba umaskini ndio utakatifu. Lakini Biblia inatufundisha kuwa fedha na dhahabu ni mali ya Bwana (Hagai 2:8), naye hutupa uwezo wa kupata utajiri ili alithibitishe agano lake (Kumbukumbu 8:18). 

Katika semina hii maalum, Mchungaji Alex alifafanua nguzo za kibiblia za uchumi imara unaotegemea **Kibali cha Mungu**, **Maarifa ya Kazi**, na **Hekima ya Kunoa Shoka**.

---

### 1. Swali la Petro na Ahadi ya Yesu (Mathayo 19:27-29)
Petro alimuuliza Yesu kwa uwazi: *"Tazama, sisi tumeacha vyote tukakufuata; tutapata nini basi?"*
Yesu hakumkemea Petro wala kumwambia anapenda fedha. Badala yake, Yesu alimjibu:
• Yeyote aliyeacha nyumba, mashamba au ndugu kwa ajili ya jina lake, **atapokea mara mia sasa katika wakati huu wa duniani**, na katika ulimwengu ujao atapokea uzima wa milele.
• Mungu anataka mtoto wake abarikiwe duniani kwanza kama ushuhuda hai, kabla hata ya kuingia mbinguni!

---

### 2. Somo la Ayubu: Uaminifu na Kurejeshewa Mara Mbili
Ayubu alipitia mtihani mzito, lakini hakumwacha Mungu wala kukufuru. Mwisho wa jaribu lake:
• Mungu alimbariki Ayubu zaidi ya mwanzo wake.
• Alipewa mifugo mara mbili, ngamia mara mbili, na fedha tele.
• Uaminifu wakati wa ukame ndio unalinda milango ya baraka za kiuchumi za kesho.

---

### 3. Kibali cha Mungu Huleta Pumziko (Kutoka 33:14-19, 1 Samweli 2:7)
Musa alimwambia Mungu: *"Uso wako usipoenda nasi, usitutoe hapa."*
• Mungu akamwambia: *"Uso wangu utakwenda pamoja nawe, nami nitakupa pumziko."*
• 1 Samweli 2:7: *"Bwana humpa mtu umaskini, naye humtajirisha; hushusha chini, tena huinua juu."*
• Malaki 3:10: Uaminifu katika zaka na sadaka unamfunga yule alaye (the devourer) na kufungua madirisha ya mbinguni ya mawazo ya kibiashara.
• Siri ya Yakobo na Labani (Mwanzo 30:25-32): Yakobo alitumia maarifa na ufunuo wa kiungu kuboresha uzazi wa mifugo yenye madoadoa hata akawa tajiri mkubwa sana katikati ya changamoto za Labani.

---

### 4. Hekima ya Kunoa Shoka (Mhubiri 10:10)
*"Chuma kikiwa butu, wala asikinoe makali, ndipo hana budi kutumia nguvu zaidi; lakini hekima yafaa kuelekeza."*
Mch. Alex alisisitiza sana sehemu hii:
• **Kutumia nguvu nyingi bila akili kunachosha**: Mtu anaweza kufanya kazi masaa 16 kwa siku lakini anapata hasara kwa sababu "shoka lake ni butu".
• **Kunoa shoka kunamaanisha nini?**
  1. **Kujifunza na kupata maarifa mapya**: soma vitabu vya fedha, hudhuria semina, jifunze mifumo ya kisasa ya kidijitali.
  2. **Kupata uzoefu na ushauri**: usianzishe biashara kwa kufuata mkumbo; ongea na waliofanikiwa katika sekta hiyo.
  3. **Kutunza kumbukumbu za fedha**: weka daftari la mapato na matumizi, tenga fedha ya biashara na fedha ya matumizi ya nyumbani.
''',
      takeaways: [
        'Mungu anataka ubarikiwe mara mia hapa duniani na uzima wa milele mbinguni (Mathayo 19:29).',
        'Kibali cha Mungu huambatana na maarifa — chuma butu kinatumia nguvu bila matokeo (Mhubiri 10:10).',
        'Tenganisha akaunti ya biashara na fedha za nyumbani; nidhamu ya fedha ndiyo inayohifadhi miujiza ya kiuchumi.',
        'Zaka na sadaka za uaminifu hufungua madirisha ya mbinguni na kumkemea mharibifu wa biashara zako (Malaki 3:10).',
      ],
      pastoralPrayer:
          'Mungu Mwenye Enzi, Mmiliki wa fedha na dhahabu yote, tunakuomba umwage kibali chako juu ya kazi, biashara na ajira za wana wa Sayuni. Wape hekima ya kunoa mashoka yao ili wasipoteze nguvu bure bila matunda. Fungua akili zao kuona fursa za kiuchumi, na uwabariki kwa hekima ya Yakobo na Ayubu. Katika jina la Yesu Kristo mkombozi wetu, Amen!',
    ),

    SermonMediaItem(
      id: 'teach-bidii-kazini',
      title: 'Bidii Kazini: Mkristo Kusimama Mbele ya Wafalme',
      preacher: 'Mchungaji na Askofu Mercy James',
      scripture: 'Mithali 22:26, 29',
      date: 'Neno la Jumapili',
      duration: 'Dakika 4 kusoma',
      type: 'text',
      category: 'Mahubiri',
      readTime: 'Dakika 4 kusoma',
      keyVerse:
          '"Je! Wamwona mtu mwenye bidii katika kazi yake? Yeye atasimama mbele ya wafalme; hatasimama mbele ya watu wasio na vyeo." — Mithali 22:29',
      scriptureList: [
        'Mithali 22:29',
        'Mithali 22:26',
        'Wakolosai 3:23-24',
        'Mithali 10:4',
        '2 Wathesalonike 3:10',
      ],
      description:
          'Je! Wamwona mtu mwenye bidii katika kazi yake? Yeye atasimama mbele ya wafalme; hatasimama mbele ya watu wasio na vyeo (Mithali 22:29). Usiwe mmoja wa wawekao rehani mikono yao au walio wadhamini wa madeni (Mithali 22:26). Bidii iliyoambatana na maombi ndio siri ya heshima na mafanikio ya mkristo.',
      imageUrl: 'assets/images/pastoral_leadership_1788577468703.jpg',
      fullArticle: '''
### Utangulizi: Kazi Kama Madhabahu ya Ibada
Imani ya mkristo haionekani tu anapokuwa amepiga magoti madhabahuni Jumapili; inaonekana pia anaposhika jembe, anapoingia ofisini, anapohudumia wateja sokoni, na anapoandika taarifa kazini. 

Mungu wetu ni mfanyakazi (Yohana 5:17), naye anawaita watoto wake kuwa mfano wa ubora na uadilifu katika kazi za mikono yao.

---

### 1. Siri ya Kusimama Mbele ya Wafalme (Mithali 22:29)
Mfalme Sulemani anauliza swali zito: *"Je! Wamwona mtu mwenye bidii katika kazi yake? Yeye atasimama mbele ya wafalme; hatasimama mbele ya watu wasio na vyeo."*
• **Bidii inaleta heshima**: Haijalishi umeanza na mtaji mdogo kiasi gani au una cheo cha chini kazini; ukifanya kwa umakini wa hali ya juu, Mungu anakuza kazi yako.
• Mfano wa Yusufu gerezani: Kwa sababu ya bidii na uaminifu, Farao alimwinua kuwa waziri mkuu wa Misri.
• Mfano wa Danieli Babiloni: Alikuwa na roho bora (excellent spirit) kuliko mawaziri wote, na wafalme wanne tofauti walimtegemea.

---

### 2. Tahadhari Dhidi ya Madeni na Rehani Haramu (Mithali 22:26)
*"Usiwe mmoja wao wawekao rehani, au walio wadhamini kwa madeni."*
• Biblia inatufundisha kuwa na hekima na nidhamu ya kifedha. Usikubali kuingia kwenye mikataba ya udhamini wa mihemko au kukopa mikopo yenye riba kandamizi inayofilisi amani ya familia yako.
• Mkristo anapaswa kuishi kwa kiasi, kupanga bajeti, na kutafuta baraka za Mungu kupitia jasho halali, si kwa njia za mkato zinazoleta aibu.

---

### 3. Fanya Kazi Kama Unamtumikia Kristo (Wakolosai 3:23-24)
*"Lo lote mfanyalo, lifanyeni kwa moyo, kama kwa Bwana, wala si kwa wanadamu."*
• Usifanye kazi kwa macho ya bosi tu anapokuangalia. 
• Fika kazini kwa wakati, linda rasilimali za mwajiri wako, toa thamani halisi kwa kila shilingi unayolipwa. Hiyo ndiyo injili inayowavutia watu kumpokea Yesu!
''',
      takeaways: [
        'Bidii na ubora wa kazi ndiyo daraja la kuinuliwa mbele ya watu wakuu na wafalme (Mithali 22:29).',
        'Mkristo halisi hafanyi kazi kwa kuangaliwa na bosi, bali anamtumikia Mungu aliye mbinguni.',
        'Jiepushe na udhamini wa ovyo na rehani za haraka zinazovuruga uchumi wa nyumba yako (Mithali 22:26).',
        'Kamilisha kazi uliyoiahirisha kwa muda mrefu — pambana na tabia ya kughairisha mambo.',
      ],
      pastoralPrayer:
          'Bwana Yesu Kristo, tunabariki kazi za mikono ya waumini wako wote wa Sayuni. Wape hekima, nguvu za kuamka asubuhi na akili za kubuni mbinu bora za kibiashara na kikazi. Mungu wetu, waondolee roho ya uchovu, uvivu na madeni yasiyo na tija. Wafungulie milango ya kusimama mbele ya wafalme na viongozi kwa utukufu wa jina lako. Katika jina la Yesu, Amen!',
    ),

    SermonMediaItem(
      id: 'teach-sunday-school-utasitasita',
      title: 'Utasitasita Mpaka Lini? Chagua Hivi Leo Utakaye Mtumikia',
      preacher: 'Mwl. Emmanuel Majaliwa (Sunday School)',
      scripture: '1 Wafalme 18:21 • Yoshua 24:15 • Matendo 7:58',
      date: 'Sunday School (Saa 03:00 - 04:00 Asubuhi)',
      duration: 'Dakika 4 kusoma',
      type: 'text',
      category: 'Sunday School',
      readTime: 'Dakika 4 kusoma',
      keyVerse:
          '"Eliya akawakaribia watu wote, akasema, Mtasita-sita katikati ya mawazo mawili hata lini? Bwana akiwa ndiye Mungu, mfuateni; bali ikiwa Baali ni Mungu, mfuateni yeye." — 1 Wafalme 18:21',
      scriptureList: [
        '1 Wafalme 18:21',
        'Yoshua 24:15',
        'Matendo ya Mitume 7:58',
        'Yakobo 1:6-8',
        'Ufunuo 3:15-16',
      ],
      description:
          'Eliya aliwauliza watu: "Mtasita-sita katikati ya mawazo mawili hata lini? Bwana akiwa ndiye Mungu, mfuateni" (1 Wafalme 18:21). Yoshua aliweka msimamo wazi: "Chagueni hivi leo mtakayemtumikia... lakini mimi na nyumba yangu tutamtumikia Bwana" (Yoshua 24:15). Stefano alisimama imara hata kifo (Matendo 7:58). Mkristo anahitaji msimamo thabiti usioyumbishwa na upepo wa dunia.',
      imageUrl: 'assets/images/3d_bible.png',
      fullArticle: '''
### Utangulizi: Somo la Asubuhi ya Sunday School (Saa 03:00 - 04:00)
Katika darasa la Sunday School asubuhi ya leo, Mwalimu Emmanuel Majaliwa alisimama na kuwakumbusha waumini na vijana umuhimu wa kuwa na msimamo thabiti katika kumfuata Bwana. 

Watu wengi leo wanajaribu kuwa na mguu mmoja kanisani na mguu mwingine kwenye anasa za ulimwengu. Matokeo yake ni maisha ya mkanganyiko, hofu na kukosa amani ya roho.

---

### 1. Swali la Eliya Mlimani Karmeli (1 Wafalme 18:21)
Nabii Eliya alipowakabili watu wote wa Israeli waliokuwa wakichanganya ibada ya Mungu na miungu ya Baali, aliwauliza swali la kishindo:
*"Mtasita-sita katikati ya mawazo mawili hata lini? Bwana akiwa ndiye Mungu, mfuateni; bali ikiwa Baali ni Mungu, mfuateni yeye."*
• Watu walinyamaza kimya kwa sababu walijua wanakosea.
• Huwezi kumtumikia Mungu nusu nusu. Mungu hawezi kupokea ibada vuguvugu (Ufunuo 3:15-16).
• Msimamo wa kweli unahitaji ujasiri wa kukataa mikumbo ya marafiki wasiomcha Mungu.

---

### 2. Kauli ya Ujasiri ya Yoshua (Yoshua 24:15)
Yoshua alipokuwa anakaribia mwisho wa safari yake ya uongozi, aliwakusanya makabila yote ya Israeli huko Shekemu na kusema maneno ya kihistoria:
*"Nanyi kama mkiona ni vibaya kumtumikia Bwana, chagueni hivi leo mtakayemtumikia... lakini mimi na nyumba yangu, tutamtumikia Bwana."*
• Yoshua hakungoja kuona majirani wataamua nini.
• Hakungoja mtindo wa dunia; alisimama kama kichwa cha familia na kiongozi wa kiroho akitangaza uamuzi wa kudumu.
• Kila kijana na kila mzazi wa Sayuni anapaswa kutamka kauli hii kwa dhati moyoni mwake!

---

### 3. Ushuhuda wa Stefano: Kusimama Mpaka Mwisho (Matendo 7:58)
Mwalimu Majaliwa alikumbusha jinsi Stefano alivyosimama akihubiri neno la kweli mbele ya baraza la Sanhedrini bila woga.
• Hata pale walipompiga mawe nje ya mji, hakurudi nyuma wala kukanusha imani yake.
• Alimwona Yesu akiwa amesimama mkono wa kuume wa Mungu kumlaki!
• Ukisimama upande wa Yesu, Yesu naye anasimama upande wako katika magumu yote.
''',
      takeaways: [
        'Mtu mwenye nia mbili husita-sita katika njia zake zote na hawezi kupokea kitu kwa Bwana (Yakobo 1:6-8).',
        'Uamuzi wa kumtumikia Kristo ni uamuzi thabiti wa kibinafsi na wa kifamilia.',
        'Usiogope kutengwa na marafiki wa dunia unaposimamia kweli ya Neno la Mungu.',
        'Hudhuria Sunday School kila Jumapili saa tatu asubuhi kujenga misingi imara ya Biblia.',
      ],
      pastoralPrayer:
          'Bwana Yesu, tunakuomba uimarishe nia za vijana wetu, wamama na wababa wa Sayuni Jerusalem. Waondolee roho ya kusitasita na kutikiswa na maneno ya watu. Wape ujasiri kama wa Nabii Eliya na mtumishi wako Yoshua ili watangaze wazi kwamba wao na nyumba zao wanakutumikia wewe pekee. Katika jina la Yesu, Amen!',
    ),

    SermonMediaItem(
      id: 'teach-mwombaji-wakili',
      title: 'Nafasi ya Mwombaji Kama Wakili wa Siri za Mungu',
      preacher: 'Mchungaji na Askofu Mercy James',
      scripture: 'Ezekieli 22:30 • 1 Wakorintho 4:1-2',
      date: 'War Room • Semina ya Maombi',
      duration: 'Dakika 5 kusoma',
      type: 'text',
      category: 'Mafundisho',
      readTime: 'Dakika 5 kusoma',
      keyVerse:
          '"Nami nikatafuta mtu miongoni mwao atakayetengeneza boma, na kusimama mbele zangu mahali palipobomoka kwa ajili ya nchi, nisije nikaiharibu; lakini sikuona mtu." — Ezekieli 22:30',
      scriptureList: [
        'Ezekieli 22:30',
        '1 Wakorintho 4:1-2',
        'Ezekieli 3:17',
        'Luka 18:1',
        'Waefeso 6:18',
      ],
      description:
          'Wakili ni msimamizi mwenye mamlaka na dhamana ya kulinda na kusimamia maslahi ya Bwana wake (1 Wakorintho 4:1-2). Mungu anatafuta mtu wa kusimama kwenye pengo na kulitengeneza boma kwa ajili ya kanisa na taifa (Ezekieli 22:30). Mwombaji ni wakili wa kiroho anayebeba mahitaji ya wengine mbele za kiti cha rehema.',
      imageUrl: 'assets/images/3d_intercession.png',
      fullArticle: '''
### Utangulizi: War Room na Chumba cha Siri cha Sayuni
Katika semina hii kuu ya maombi na maombezi (Intercession), Askofu Mercy James alifundisha kwa kina kuhusu hadhi na mamlaka ya mwombaji. 

Watu wengi wanadhania kuwa kuomba ni jukumu la watu wasio na kazi au wazee pekee. Lakini katika ufalme wa Mungu, **mwombaji ni WAKILI MKUU WA SIRI ZA MBINGUNI** anayeamua mwelekeo wa vita vya kiroho duniani.

---

### 1. Maana ya Kuwa "Wakili" (1 Wakorintho 4:1-2)
Mtume Paulo anasema: *"Mtu na atuhesabu hivi, kuwa tu watumishi wa Kristo, na mawakili wa siri za Mungu. Hapo tena inayotakiwa katika mawakili, ndiyo mtu aonekane kuwa mwaminifu."*
• **Wakili ni nani?** Ni mtu aliyepewa dhamana, mamlaka na funguo za kusimamia mali ya mwenye nyumba.
• Mwombaji amekabidhiwa siri za kiroho: anajua namna ya kuingia Patakatifu pa Patakatifu kupitia damu ya Yesu.
• Uaminifu ndio sifa kuu ya wakili: anatakiwa kuwa msiri wa mahitaji ya watu wanaomwomba msaada wa maombi, asiyesengenya wala kufichua udhaifu wa aliowaombea.

---

### 2. Mungu Anatafuta Mtu wa Kusimama Kwenye Boma (Ezekieli 22:30)
Katika kitabu cha Ezekieli, Mungu anatoa kilio chenye huzuni:
*"Nami nikatafuta mtu miongoni mwao atakayetengeneza boma, na kusimama mbele zangu mahali palipobomoka kwa ajili ya nchi, nisije nikaiharibu; lakini sikuona mtu."*
• Boma linapovunjika, adui anapata mwanya wa kuingiza magonjwa, mifarakano, umaskini na vifo vya mapema.
• Mwombaji ndiye fundi boma (wall-builder) anayeziba mapengo hayo kwa toba, kufunga na maombezi ya usiku.
• Sayuni inahitaji mawakili wanaoamka usiku wa manane kuombea amani ya Tanzania, afya ya wachungaji, na usalama wa watoto wote.

---

### 3. Silaha na Nidhamu ya Chumba cha Maombi (War Room)
• **Maombi ya Bila Kukoma (Luka 18:1)**: Yesu aliwaambia mfano kwamba imewapasa kumwomba Mungu sikuzote wala wasikate tamaa.
• **Kutembea katika Usafi wa Moyo (Zaburi 24:3-4)**: Ni nani atakayepanda katika mlima wa Bwana? Ni yeye aliye na mikono safi na moyo mweupe.
• **Kutumia Neno la Mungu Kama Upanga**: Unapoomba, usirudie tu malalamiko; mkumbushe Mungu ahadi zake zilizopo kwenye maandiko matakatifu.
''',
      takeaways: [
        'Mwombaji si mlalamikaji, bali ni wakili mwaminifu wa siri za Mungu mwenye mamlaka ya kifalme (1 Kor 4:1-2).',
        'Mungu anatafuta mtu mmoja tu wa kusimama kwenye pengo ili kuokoa familia na taifa (Ezekieli 22:30).',
        'Uaminifu na usiri ni nguzo za chumba cha maombi; mambo ya maombezi hayafanywi umbea mitaani.',
        'Tenga angalau dakika 30 kila siku kuombea wengine, kanisa na viongozi wa nchi.',
      ],
      pastoralPrayer:
          'Mungu Baba mwenye uweza wote, utupe roho ya neema na kuomba kama ulivyoahidi kupitia Nabii Zekaria. Inua mawakili waaminifu ndani ya kanisa la Sayuni Jerusalem watakaosimama kwenye boma usiku na mchana. Walinde waombezi wetu, linda afya zao na familia zao. Kila pigo lililokusudiwa na ibilisi livunjwe na sala za watakatifu. Katika jina la Yesu Kristo, Amen!',
    ),

    SermonMediaItem(
      id: 'teach-ukombozi-kwa-mungu',
      title: 'Ukombozi Wetu Upo kwa Mungu Pekee',
      preacher: 'Mchungaji na Askofu Mercy James',
      scripture: 'Zaburi 3:8 • Kutoka 14:13-14 • Warumi 8:31-39',
      date: 'Mkesha wa Ushindi na Uponyaji',
      duration: 'Dakika 5 kusoma',
      type: 'text',
      category: 'Mahubiri',
      readTime: 'Dakika 5 kusoma',
      keyVerse:
          '"Musa akawaambia watu, Msiogope, simameni tu, mkauone wokovu wa Bwana atakaowafanyia leo; kwa maana hao Wamisri mliowaona leo hamtawaona tena milele." — Kutoka 14:13',
      scriptureList: [
        'Zaburi 3:8',
        'Kutoka 14:13-14',
        'Warumi 8:31-39',
        'Isaya 43:1-2',
        'Yohana 8:36',
      ],
      description:
          'Wokovu na ukombozi unatoka kwa Bwana pekee, na baraka yake i juu ya watu wake (Zaburi 3:8). Musa aliwaambia watu: "Msiogope, simameni tu, mkauone wokovu wa Bwana atakaowafanyia leo" (Kutoka 14:13). Kama Mungu akiwa upande wetu, ni nani aliye juu yetu? Hakuna nguvu ya giza inayoweza kushinda kanisa la Sayuni.',
      imageUrl: 'assets/images/church_women_fellowship.jpg',
      fullArticle: '''
### Utangulizi: Hali ya Vita na Ushindi wa Msalaba
Hakuna mwanadamu anayeweza kujiokoa mwenyewe kwa akili zake, uwezo wake wa kiuchumi au waganga wa kienyeji. Ukombozi wa kweli wa roho, nafsi na mwili unatoka kwa Muumba wa mbingu na nchi pekee. 

Katika mkesha huu mkuu wa ushindi na uponyaji, Askofu Mercy James alitangaza ujumbe wa kufariji kuwa siku za utumwa na machozi zimekoma mbele ya nguvu ya Yesu Kristo!

---

### 1. Wokovu Hutoka kwa Bwana (Zaburi 3:8)
Mfalme Daudi anapokimbia mwanae Absalomu, anasema maneno haya ya kiimani:
*"Wokovu hutoka kwa Bwana; baraka yako na iwe juu ya watu wako."*
• Hata kama jeshi zima limezunguka maisha yako, usikate tamaa.
• Mungu ndiye ngao yako, utukufu wako na mwinua kichwa chako (Zaburi 3:3).
• Ukombozi si jambo la kubahatisha; ni ahadi ya agano la damu ya Yesu msalabani.

---

### 2. "Simameni Tu Mkauone Wokovu wa Bwana" (Kutoka 14:13-14)
Wana wa Israeli walipofika Bahari ya Shamu, walikuwa na bahari mbele yao na majeshi ya Farao nyuma yao. Walipoanza kulia kwa hofu, Musa alitoa agizo la kiungu:
*"Msiogope, simameni tu, mkauone wokovu wa Bwana atakaowafanyia leo; kwa maana hao Wamisri mliowaona leo hamtawaona tena milele. Bwana atawapigania ninyi, nanyi mtanyamaza kimya."*
• Mungu alipasua Bahari ya Shamu katikati!
• Vita yako haipiganwi kwa nguvu za mwili; unapomkabidhi Bwana vita yako, Yeye mwenyewe anawatuliza maadui zako.

---

### 3. Zaidi ya Washindi Katika Kristo (Warumi 8:31-39)
Mtume Paulo anapiga muhuri ushindi wetu:
*"Ikiwa Mungu yuko upande wetu, ni nani aliye juu yetu?"*
• Hakuna dhiki, shida, njaa, upanga wala uchawi unaoweza kututenga na upendo wa Mungu ulio katika Kristo Yesu.
• Katika mambo haya yote sisi ni **ZAIDI YA WASHINDI** kwa yeye aliyetupenda.
• Kama Mwana amekuweka huru, umekuwa huru kweli kweli (Yohana 8:36).
''',
      takeaways: [
        'Wokovu na ukombozi hautoki kwa wanadamu wala waganga, bali unatoka kwa Bwana pekee (Zaburi 3:8).',
        'Simama tu kwa utulivu; Bwana anapigana vita yako na maadui wako watanyamazishwa (Kutoka 14:13-14).',
        'Hakuna silaha itakayofanikiwa dhidi ya mteule wa Mungu; sisi ni zaidi ya washindi katika Kristo Yesu (Warumi 8:37).',
        'Uhuru wa kweli unapatikana unapomruhusu Yesu kuwa Bwana na Mwokozi wa maisha yako.',
      ],
      pastoralPrayer:
          'Ee Bwana Mungu Mkombozi wetu, tunakushukuru kwa kuwa umetuokoa kutoka kwenye giza totoro na kutuingiza katika nuru ya Mwanao mpendwa. Tangaza ukombozi leo kwa kila anayesoma ujumbe huu: fungua vifungo vya magonjwa, umaskini, hofu na kukata tamaa. Wamisri waliowatesa jana wasionekane tena maishani mwao. Baraka na ulinzi wa damu ya Yesu vifunike Sayuni yote. Katika jina la Yesu Kristo, Amen!',
    ),

    // Real Audio Choir Songs (Bundled Upendo Choir MP3s)
    SermonMediaItem(
      id: 'choir-upendo-neno-media',
      title: 'Neno la Mungu (Upendo Choir)',
      preacher: 'Kwaya ya Upendo (Mwl. Emmanuel Majaliwa)',
      scripture: 'Zaburi 119:105 • Isaya 40:8',
      date: 'Albamu ya Upendo Vol. 1',
      duration: '05:32',
      type: 'audio',
      category: 'Kwaya',
      readTime: '05:32 dakika',
      description:
          'Wimbo halisi wa sifa na kuabudu kutoka Kwaya ya Upendo ukisisitiza kuwa Neno la Bwana linadumu milele na ni taa ya miguu yetu.',
      imageUrl: 'assets/images/zion_worship_choir_1788577423671.jpg',
      audioUrl: 'assets/audio/upendo_choir_neno.mp3',
      isAdminUpload: false,
    ),

    SermonMediaItem(
      id: 'choir-upendo-vitabu-media',
      title: 'Vitabu vya Biblia (Upendo Choir)',
      preacher: 'Kwaya ya Upendo (Mwl. Emmanuel Majaliwa)',
      scripture: '2 Timotheo 3:16 • Zaburi 1:1-3',
      date: 'Albamu ya Upendo Vol. 1',
      duration: '04:25',
      type: 'audio',
      category: 'Kwaya',
      readTime: '04:25 dakika',
      description:
          'Wimbo halisi unaoelezea na kuimba vitabu vyote vya Biblia kuanzia Mwanzo hadi Ufunuo, ukitia moyo usomaji wa Maandiko Matakatifu.',
      imageUrl: 'assets/images/3d_bible.png',
      audioUrl: 'assets/audio/upendo_choir_vitabu.mp3',
      isAdminUpload: false,
    ),
  ];

  /// Persists article/teaching updates locally and in memory
  static Future<void> saveTeachingUpdate(SermonMediaItem updated) async {
    final idx = items.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      items[idx] = updated;
    } else {
      items.insert(0, updated);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('zion_admin_uploaded_media');
      List<dynamic> list = [];
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) list = decoded;
        } catch (_) {}
      }

      final existingIdx =
          list.indexWhere((e) => e is Map && e['id'] == updated.id);
      if (existingIdx != -1) {
        list[existingIdx] = updated.toJson();
      } else {
        list.insert(0, updated.toJson());
      }
      await prefs.setString('zion_admin_uploaded_media', jsonEncode(list));
    } catch (e) {
      debugPrint('Error persisting teaching update: $e');
    }
  }
}
