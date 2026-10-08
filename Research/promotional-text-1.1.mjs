const en='One meal at a time, make sense of your sodium. Log foods, keep favorites close and see your daily total—with gentle reminders when you want them.';
const fr='Un repas à la fois, voyez plus clair dans votre sodium. Notez vos aliments, gardez vos favoris à portée de main et choisissez vos rappels, à votre rythme.';
export const promotionalText={
  'en-US':en,
  'en-GB':en.replace('favorites','favourites'),
  'en-AU':en.replace('favorites','favourites'),
  'en-CA':en.replace('favorites','favourites'),
  'fr-FR':fr,
  'fr-CA':fr,
  'de-DE':'Mahlzeit für Mahlzeit mehr Überblick: Natrium erfassen, Favoriten griffbereit halten und deine Tagesmenge sehen. Sanfte Erinnerungen, wenn du sie möchtest.',
  'nl-NL':'Meer inzicht in je natrium, maaltijd voor maaltijd. Log voeding, bewaar favorieten en bekijk je dagtotaal. Vriendelijke herinneringen, alleen als jij dat wilt.',
  'it':'Un pasto alla volta, fai chiarezza sul sodio. Registra gli alimenti, salva i preferiti e guarda il totale giornaliero. Promemoria gentili, se li desideri.',
  'es-ES':'Tu sodio, comida a comida. Registra alimentos, guarda favoritos y consulta tu total diario. Recordatorios suaves cuando tú quieras, a tu propio ritmo.',
  'sv':'Få koll på natrium, en måltid i taget. Logga mat, spara favoriter och se dagens total. Vänliga påminnelser när du vill, i din egen takt.',
  'ja':'一食ずつ記録して、今日のナトリウムを見えるように。食べたものやお気に入りを残し、一日の合計を確認。リマインダーは必要なときだけ。自分のペースで始めましょう。',
  'zh-Hans':'从每一餐开始，看清一天的钠摄入。记录食物、收藏常吃的餐食，随时查看每日总量。温和的用餐提醒，由你选择是否开启。按自己的节奏，慢慢来。',
  'ms':'Kenali pengambilan natrium anda, satu hidangan pada satu masa. Catat makanan, simpan kegemaran dan lihat jumlah harian. Peringatan lembut apabila anda mahu.',
  'ta-IN':'ஒவ்வொரு உணவிலிருந்தும் தொடங்குங்கள். சோடியத்தைப் பதிவு செய்யுங்கள், பிடித்த உணவுகளைச் சேமியுங்கள். உங்கள் நாளைத் தெளிவாகப் பாருங்கள்.',
  'hi':'एक भोजन से शुरुआत करें। सोडियम दर्ज करें, पसंदीदा भोजन सहेजें और दिन का कुल हिसाब देखें। हल्के रिमाइंडर, जब आप चाहें। अपनी गति से आगे बढ़ें।',
  'te-IN':'ఒక్కో భోజనంతో మొదలుపెట్టండి. సోడియాన్ని నమోదు చేయండి, ఇష్టమైన ఆహారాలను సేవ్ చేసి రోజువారీ మొత్తం చూడండి. మీకు కావాలంటేనే భోజన రిమైండర్లు.'
};
for(const [locale,value] of Object.entries(promotionalText)) {
  if(!value.trim()||value.length>170)throw Error(`${locale}: ${value.length} characters exceeds promotional-text limit`);
}
