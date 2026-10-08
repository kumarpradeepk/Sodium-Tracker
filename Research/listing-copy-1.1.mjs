// Localized listing copy; does not claim that the app binary is fully translated.
const legal=(terms,privacy)=>'\n\n'+terms+': https://www.apple.com/legal/internet-services/itunes/dev/stdeula/\nPinch: https://tinkersmithstudio.com/pinch/terms.html\n'+privacy+': https://tinkersmithstudio.com/pinch/privacy.html';
const entry=(name,subtitle,keywords,folder,paragraphs,terms,privacy)=>({name,subtitle,keywords,folder,description:paragraphs.join('\n\n')+legal(terms,privacy)});
const en=entry('Sodium Tracker: Pinch Daily','Salt Counter & Intake','food,diary,nutrition,meal,log,milligrams,budget,reminder,low,diet,dash,habits','en-US',[
'See your sodium, one day at a time. Pinch helps you log meals and see how much remains in your daily sodium budget.',
'YOUR DAY AT A GLANCE\n• Set a daily target and log amounts in milligrams.\n• Find favourite foods and frequently logged meals.\n• Compare foods with your remaining budget.\n• Choose optional meal reminders.\n• Review weekly trends and streaks of logged days.\n• Convert between salt and sodium.',
'PINCH PLUS\nA subscription unlocks FatSecret food search and logging, four-week trends and calendar, unlimited custom foods, CSV export and the Home Screen widget. Prices and any eligible introductory offer appear before purchase. Subscriptions renew automatically unless cancelled in your Apple Account settings.',
'Your totals reflect what you log; unlogged meals are not included. Food data is provided by FatSecret where available. Pinch supports personal tracking, not medical diagnosis or treatment. Ask a qualified healthcare professional which sodium target is right for you.'
],'Terms of Use','Privacy Policy');
const fr=entry('Suivi Sodium : Pinch','Compteur de sel quotidien','journal,alimentaire,repas,apport,nutrition,régime,pauvre,dash,habitudes,rappel','fr-FR',[
'Votre sodium, un jour à la fois. Pinch vous aide à noter vos repas et à voir ce qu’il reste dans votre budget quotidien de sodium.',
'VOTRE JOURNÉE EN UN COUP D’ŒIL\n• Définissez votre objectif et saisissez les quantités en milligrammes.\n• Retrouvez vos favoris et les aliments souvent enregistrés.\n• Comparez les aliments à votre budget restant.\n• Choisissez des rappels de repas facultatifs.\n• Consultez les tendances hebdomadaires et les séries de jours enregistrés.\n• Convertissez le sel en sodium et inversement.',
'PINCH PLUS\nUn abonnement débloque la recherche et l’enregistrement d’aliments FatSecret, les tendances et le calendrier sur quatre semaines, les aliments personnalisés illimités, l’export CSV et le widget. Les prix et toute offre de bienvenue applicable sont affichés avant l’achat. L’abonnement se renouvelle automatiquement, sauf résiliation dans les réglages de votre compte Apple.',
'Les résultats reposent sur vos saisies : les repas non enregistrés sont exclus. Données alimentaires de FatSecret selon disponibilité. Pinch ne remplace pas un avis médical. Demandez à un professionnel de santé quel objectif vous convient.'
],'Conditions d’utilisation','Confidentialité');
export const copy={
'en-US':{...en,description:en.description.replace('favourite','favorite')},'en-GB':en,'en-AU':en,'en-CA':en,'fr-FR':fr,'fr-CA':{...fr},
'de-DE':entry('Natrium Tracker: Pinch','Salz Zähler & Tagesprotokoll','sodium,salzarm,ernährung,lebensmittel,tagebuch,mahlzeit,budget,erinnerung,dash','de-DE',[
'Dein Natrium, Tag für Tag im Blick. Mit Pinch erfasst du Mahlzeiten und siehst, wie viel von deinem täglichen Natrium-Budget übrig ist.',
'DEIN TAG AUF EINEN BLICK\n• Tagesziel festlegen und Mengen in Milligramm eintragen.\n• Favoriten und häufig erfasste Lebensmittel wiederfinden.\n• Lebensmittel mit dem verbleibenden Budget vergleichen.\n• Freiwillige Mahlzeitenerinnerungen auswählen.\n• Wochentrends und Serien erfasster Tage ansehen.\n• Salz und Natrium umrechnen.',
'PINCH PLUS\nEin Abonnement bietet die FatSecret-Lebensmittelsuche und Erfassung, Vier-Wochen-Trends und Kalender, unbegrenzte eigene Lebensmittel, CSV-Export und das Widget. Preise und verfügbare Einführungsangebote werden vor dem Kauf angezeigt. Das Abonnement verlängert sich automatisch, sofern du es nicht in den Einstellungen deines Apple Accounts kündigst.',
'Die Auswertung basiert auf deinen Einträgen; nicht erfasste Mahlzeiten fehlen. Lebensmitteldaten von FatSecret, soweit verfügbar. Pinch ersetzt keine medizinische Beratung. Besprich ein passendes Natriumziel mit medizinischem Fachpersonal.'
],'Nutzungsbedingungen','Datenschutz'),
'nl-NL':entry('Natrium Tracker: Pinch','Zout Teller & Voedingslog','zoutarm,dieet,zoutinname,dagboek,maaltijd,voeding,budget,herinnering,dash','nl-NL',[
'Je natrium, dag voor dag in beeld. Met Pinch registreer je maaltijden en zie je hoeveel ruimte er nog is binnen je dagelijkse natriumbudget.',
'JE DAG IN ÉÉN OOGOPSLAG\n• Stel je dagdoel in en voer hoeveelheden in milligram in.\n• Vind favorieten en vaak geregistreerde voedingsmiddelen terug.\n• Vergelijk voeding met je resterende budget.\n• Kies optionele herinneringen voor maaltijden.\n• Bekijk weektrends en reeksen geregistreerde dagen.\n• Reken zout en natrium om.',
'PINCH PLUS\nEen abonnement biedt zoeken en registreren via FatSecret, trends en een kalender over vier weken, onbeperkte eigen voedingsmiddelen, CSV-export en de widget. Prijzen en eventuele introductieaanbiedingen staan vóór aankoop in de app. Het abonnement wordt automatisch verlengd tenzij je het opzegt via je Apple Account-instellingen.',
'De resultaten zijn gebaseerd op je invoer; niet-geregistreerde maaltijden tellen niet mee. Voedingsgegevens van FatSecret, waar beschikbaar. Pinch geeft geen medisch advies. Bespreek een passend natriumdoel met een zorgprofessional.'
],'Gebruiksvoorwaarden','Privacybeleid'),
'it':entry('Monitor Sodio: Pinch','Dieta iposodica e diario','sale,alimentare,pasti,apporto,nutrizione,registro,promemoria,abitudini,dash','it-IT',[
'Il tuo sodio, un giorno alla volta. Pinch ti aiuta a registrare i pasti e a vedere quanto resta del tuo limite giornaliero di sodio.',
'LA TUA GIORNATA A COLPO D’OCCHIO\n• Imposta un obiettivo e registra le quantità in milligrammi.\n• Ritrova i preferiti e gli alimenti registrati più spesso.\n• Confronta gli alimenti con il limite residuo.\n• Scegli promemoria facoltativi per i pasti.\n• Consulta tendenze settimanali e serie di giorni registrati.\n• Converti sale e sodio.',
'PINCH PLUS\nL’abbonamento include ricerca e registrazione degli alimenti FatSecret, tendenze e calendario su quattro settimane, alimenti personalizzati illimitati, esportazione CSV e widget. Prezzi ed eventuali offerte introduttive idonee sono indicati prima dell’acquisto. L’abbonamento si rinnova automaticamente salvo disdetta nelle impostazioni dell’Apple Account.',
'I risultati riflettono ciò che registri; i pasti non registrati sono esclusi. Dati alimentari di FatSecret, dove disponibili. Pinch non offre consulenza medica. Chiedi a un professionista sanitario quale obiettivo di sodio è adatto a te.'
],'Condizioni d’uso','Privacy'),
'ja':entry('塩分・ナトリウム管理 Pinch','毎日の塩分記録と減塩サポート','食事,日記,栄養,食塩,摂取量,食品,リマインダー,習慣','ja-JP',[
'毎日のナトリウム摂取量を、ひと目で。Pinchで食事を記録すると、設定した1日の目標量まであと何mgかを確認できます。',
'毎日の記録をシンプルに\n• 目標量を設定し、ミリグラム単位で入力。\n• お気に入りや、よく記録する食品をすぐに表示。\n• 食品のナトリウム量と、今日の残りの目標量を比較。\n• 希望する食事のリマインダーを設定。\n• 週ごとの傾向や連続記録を確認。\n• 食塩相当量とナトリウム量を換算。',
'PINCH PLUS\nサブスクリプションで、FatSecretの食品検索と記録、4週間の傾向とカレンダー、カスタム食品の無制限登録、CSV書き出し、ウィジェットをご利用いただけます。価格および対象となる初回限定オファーは購入前にアプリ内で表示されます。Apple Accountの設定で解約しない限り、自動更新されます。',
'集計は記録した食品に基づき、未記録の食事は含みません。食品データは利用可能な範囲でFatSecretが提供します。Pinchは医療上の診断や治療を行いません。適切な目標量は医療の専門家にご相談ください。'
],'利用規約','プライバシーポリシー'),
'es-ES':entry('Control de sodio: Pinch','Registro diario de sal','dieta,baja,alimentos,comidas,nutrición,ingesta,recordatorio,hábitos,dash','es-ES',[
'Tu sodio, día a día. Pinch te ayuda a registrar comidas y ver cuánto queda de tu objetivo diario de sodio.',
'TU DÍA DE UN VISTAZO\n• Define un objetivo y registra cantidades en miligramos.\n• Encuentra tus favoritos y los alimentos que más registras.\n• Compara alimentos con tu cantidad diaria restante.\n• Elige recordatorios de comidas opcionales.\n• Revisa tendencias semanales y rachas de días registrados.\n• Convierte entre sal y sodio.',
'PINCH PLUS\nLa suscripción incluye búsqueda y registro de alimentos con FatSecret, tendencias y calendario de cuatro semanas, alimentos personalizados ilimitados, exportación CSV y widget. Los precios y las ofertas de bienvenida aplicables se muestran antes de comprar. La suscripción se renueva automáticamente salvo que la canceles en los ajustes de tu cuenta de Apple.',
'Los resultados reflejan lo que registras; no incluyen comidas sin registrar. Datos alimentarios de FatSecret, cuando estén disponibles. Pinch no ofrece asesoramiento médico. Consulta con un profesional sanitario qué objetivo es adecuado para ti.'
],'Condiciones de uso','Privacidad'),
'sv':entry('Natrium & salt: Pinch','Din dagliga matdagbok','saltintag,kost,måltid,näring,logg,påminnelse,vanor,saltfattig,budget','sv-SE',[
'Ditt natrium, dag för dag. Pinch hjälper dig att logga måltider och se hur mycket som återstår av din dagliga natriumbudget.',
'DIN DAG I EN ÖVERBLICK\n• Ange ett dagsmål och logga mängder i milligram.\n• Hitta favoriter och mat som du ofta loggar.\n• Jämför livsmedel med din återstående budget.\n• Välj frivilliga måltidspåminnelser.\n• Se veckotrender och sviter av loggade dagar.\n• Omvandla mellan salt och natrium.',
'PINCH PLUS\nEn prenumeration ger matsökning och loggning via FatSecret, fyraveckorstrender och kalender, obegränsat antal egna livsmedel, CSV-export och widgeten. Priser och eventuella introduktionserbjudanden visas före köp. Prenumerationen förnyas automatiskt om du inte säger upp den i inställningarna för ditt Apple-konto.',
'Resultaten bygger på det du loggar; oregistrerade måltider ingår inte. Livsmedelsdata från FatSecret där de finns tillgängliga. Pinch ger inte medicinsk rådgivning. Fråga vårdpersonal vilket natriummål som passar dig.'
],'Användarvillkor','Integritetspolicy'),
'zh-Hans':entry('Pinch 钠摄入与盐分记录','饮食日记与每日用量管理','减盐,低钠,食物,营养,摄取量,提醒,习惯,餐食','zh-Hans',[
'每天摄入多少钠，一目了然。用Pinch记录食物，查看距离每日钠摄入目标还剩多少毫克。',
'轻松记录每一天\n• 设置每日目标，按毫克输入摄入量。\n• 快速找到收藏和经常记录的食物。\n• 将食物的钠含量与今日剩余额度比较。\n• 自主选择是否开启用餐提醒。\n• 查看每周趋势和连续记录天数。\n• 换算盐和钠的含量。',
'PINCH PLUS\n订阅后可使用FatSecret食物搜索与记录、四周趋势与日历、无限自定义食物、CSV导出和小组件。购买前，应用会显示当前价格及你符合条件的首次订阅优惠。除非在Apple账户设置中取消，否则订阅将自动续订。',
'统计仅依据你记录的食物，不包括未记录的餐食。食物数据由FatSecret在可用范围内提供。Pinch用于个人记录，不提供医疗诊断或治疗。请向医疗专业人士咨询适合你的钠摄入目标。'
],'使用条款','隐私政策'),
'ms':entry('Jejak Natrium: Pinch','Catatan garam harian','makanan,pemakanan,diari,hidangan,pengambilan,peringatan,tabiat,diet','ms-MY',[
'Natrium anda, hari demi hari. Pinch membantu anda merekod hidangan dan melihat baki dalam had natrium harian anda.',
'HARI ANDA SEPINTAS LALU\n• Tetapkan sasaran dan masukkan jumlah dalam miligram.\n• Cari makanan kegemaran dan yang kerap direkod.\n• Bandingkan makanan dengan baki had harian.\n• Pilih peringatan waktu makan jika anda mahu.\n• Semak trend mingguan dan rentetan hari yang direkod.\n• Tukar antara jumlah garam dan natrium.',
'PINCH PLUS\nLangganan membuka carian dan rekod makanan FatSecret, trend dan kalendar empat minggu, makanan tersuai tanpa had, eksport CSV dan widget. Harga serta tawaran pengenalan yang layak dipaparkan sebelum pembelian. Langganan diperbaharui secara automatik melainkan dibatalkan dalam tetapan Akaun Apple anda.',
'Keputusan berdasarkan makanan yang anda rekod sahaja. Data makanan disediakan oleh FatSecret jika tersedia. Pinch bukan nasihat, diagnosis atau rawatan perubatan. Tanya profesional kesihatan tentang sasaran natrium yang sesuai untuk anda.'
],'Terma Penggunaan','Dasar Privasi'),
'hi':entry('Pinch: सोडियम डायरी','रोज़ के नमक का हिसाब','भोजन,पोषण,आहार,याद,मिलीग्राम','hi-IN',[
'हर दिन के सोडियम पर नज़र रखें। Pinch में भोजन दर्ज करें और देखें कि आपके रोज़ के लक्ष्य में कितने मिलीग्राम बाकी हैं।',
'रोज़ का हिसाब आसान बनाएं\n• दैनिक लक्ष्य तय करें और मात्रा मिलीग्राम में दर्ज करें।\n• पसंदीदा और बार-बार दर्ज किए गए खाद्य पदार्थ खोजें।\n• भोजन की मात्रा की तुलना आज की बची हुई सीमा से करें।\n• चाहें तो भोजन के समय याद दिलाने वाले संदेश चुनें।\n• साप्ताहिक रुझान और लगातार दर्ज किए गए दिन देखें।\n• नमक और सोडियम की मात्रा का रूपांतरण करें।',
'PINCH PLUS\nसदस्यता में FatSecret से भोजन खोजना और दर्ज करना, चार सप्ताह के रुझान और कैलेंडर, असीमित कस्टम खाद्य पदार्थ, CSV एक्सपोर्ट और विजेट शामिल हैं। खरीदने से पहले कीमत और पात्र परिचयात्मक ऑफ़र दिखाए जाते हैं। Apple खाते की सेटिंग में रद्द न करने पर सदस्यता अपने आप नवीनीकृत होती है।',
'आंकड़े केवल दर्ज किए गए भोजन पर आधारित हैं। उपलब्ध खाद्य डेटा FatSecret से मिलता है। Pinch चिकित्सा सलाह, निदान या उपचार नहीं देता। अपने लिए सही सोडियम लक्ष्य के बारे में योग्य स्वास्थ्य विशेषज्ञ से पूछें।'
],'उपयोग की शर्तें','गोपनीयता नीति'),
'ta-IN':entry('Pinch: சோடியம் பதிவு','தினசரி உப்பு கணக்கு','உணவு,ஊட்டச்சத்து,பழக்கம்','ta-IN',[
'உங்கள் தினசரி சோடியம் அளவை அறியுங்கள். Pinch-இல் உணவைப் பதிவு செய்து, உங்கள் தினசரி இலக்கில் எத்தனை மில்லிகிராம் மீதம் உள்ளது என்பதைப் பாருங்கள்.',
'எளிய தினசரிப் பதிவு\n• தினசரி இலக்கை அமைத்து, அளவுகளை மில்லிகிராமில் உள்ளிடுங்கள்.\n• பிடித்த மற்றும் அடிக்கடி பதிவு செய்யும் உணவுகளைக் கண்டறியுங்கள்.\n• உணவின் அளவை இன்றைய மீதமுள்ள வரம்புடன் ஒப்பிடுங்கள்.\n• விரும்பினால் உணவு நேர நினைவூட்டல்களைத் தேர்ந்தெடுங்கள்.\n• வாராந்திரப் போக்குகளையும் தொடர்ந்து பதிவு செய்த நாட்களையும் பாருங்கள்.\n• உப்பு மற்றும் சோடியம் அளவுகளை மாற்றிக் கணக்கிடுங்கள்.',
'PINCH PLUS\nசந்தாவில் FatSecret உணவுத் தேடல் மற்றும் பதிவு, நான்கு வாரப் போக்குகள் மற்றும் நாள்காட்டி, வரம்பற்ற தனிப்பயன் உணவுகள், CSV ஏற்றுமதி மற்றும் விட்ஜெட் கிடைக்கும். வாங்குவதற்கு முன் விலையும் தகுதியான அறிமுகச் சலுகையும் காட்டப்படும். Apple கணக்கு அமைப்புகளில் ரத்து செய்யாவிட்டால் சந்தா தானாகப் புதுப்பிக்கப்படும்.',
'கணக்குகள் நீங்கள் பதிவு செய்த உணவுகளை மட்டுமே அடிப்படையாகக் கொண்டவை. கிடைக்கக்கூடிய உணவுத் தரவை FatSecret வழங்குகிறது. Pinch மருத்துவ ஆலோசனையோ சிகிச்சையோ வழங்காது. உங்களுக்கான சோடியம் இலக்கைப் பற்றி தகுதியான சுகாதார நிபுணரிடம் கேளுங்கள்.'
],'பயன்பாட்டு விதிமுறைகள்','தனியுரிமைக் கொள்கை'),
'te-IN':entry('Pinch: సోడియం డైరీ','రోజువారీ ఉప్పు లెక్క','ఆహారం,పోషణ,అలవాటు','te-IN',[
'మీ రోజువారీ సోడియం మోతాదును తెలుసుకోండి. Pinchలో భోజనాన్ని నమోదు చేసి, మీ రోజువారీ లక్ష్యంలో ఎన్ని మిల్లీగ్రాములు మిగిలాయో చూడండి.',
'రోజువారీ నమోదు సులభంగా\n• రోజువారీ లక్ష్యాన్ని నిర్ణయించి, మోతాదులను మిల్లీగ్రాముల్లో నమోదు చేయండి.\n• ఇష్టమైన, తరచుగా నమోదు చేసే ఆహారాలను కనుగొనండి.\n• ఆహారంలోని మోతాదును ఈ రోజు మిగిలిన పరిమితితో పోల్చండి.\n• కావాలంటే భోజన సమయపు రిమైండర్‌లను ఎంచుకోండి.\n• వారపు ధోరణులు, వరుసగా నమోదు చేసిన రోజులను చూడండి.\n• ఉప్పు, సోడియం మోతాదులను మార్చి లెక్కించండి.',
'PINCH PLUS\nసబ్‌స్క్రిప్షన్‌తో FatSecret ఆహార శోధన, నమోదు, నాలుగు వారాల ధోరణులు, క్యాలెండర్, అపరిమిత కస్టమ్ ఆహారాలు, CSV ఎగుమతి, విడ్జెట్ లభిస్తాయి. కొనుగోలుకు ముందు ధర, మీకు వర్తించే ప్రారంభ ఆఫర్ చూపబడతాయి. Apple ఖాతా సెట్టింగ్‌లలో రద్దు చేయకపోతే సబ్‌స్క్రిప్షన్ స్వయంచాలకంగా పునరుద్ధరించబడుతుంది.',
'లెక్కలు మీరు నమోదు చేసిన ఆహారంపై మాత్రమే ఆధారపడతాయి. అందుబాటులో ఉన్న ఆహార డేటాను FatSecret అందిస్తుంది. Pinch వైద్య సలహా లేదా చికిత్స అందించదు. మీకు సరైన సోడియం లక్ష్యం గురించి అర్హత గల ఆరోగ్య నిపుణుడిని అడగండి.'
],'వినియోగ నిబంధనలు','గోప్యతా విధానం')
};
for(const [locale,c] of Object.entries(copy)){
 for(const k of ['name','subtitle'])if([...c[k]].length>30)throw Error(locale+' '+k+' too long');
 if(c.description.length>4000||Buffer.byteLength(c.keywords)>100||[...c.keywords].length>100)throw Error(locale+' exceeds metadata limits');
}
