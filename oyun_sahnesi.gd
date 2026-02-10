extends Node2D

# --- PUAN DEĞİŞKENLERİ ---
var benim_puanim = 0
var rakip_puani = 0

# --- SAYAÇ DEĞİŞKENLERİ ---
var kalan_sure = 60
var sure_isliyor = false

# --- RESİMLER ---
var ampul_sonuk = preload("res://Assets/Sprites/ampul_sonuk.png")
var ampul_yesil = preload("res://Assets/Sprites/ampul_yesil.png")
var ampul_kirmizi = preload("res://Assets/Sprites/ampul_kirmizi.png")

# --- İNTERNET DEĞİŞKENLERİ ---
var socket = WebSocketPeer.new()
var sunucu_adresi = "ws://127.0.0.1:8765"
var benim_numaram = 0 
var tur_sayisi = 1 

func _ready():
	print("Sunucuya bağlanılıyor...")
	socket.connect_to_url(sunucu_adresi)
	
	skorlari_guncelle()
	butonlari_kilitle(true)
	
	if has_node("Lbl_Durum"):
		$Lbl_Durum.text = "RAKİP ARANIYOR..."
		
	gizle_panel()

func _process(delta):
	socket.poll()
	var durum = socket.get_ready_state()
	
	if durum == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			var mesaj = socket.get_packet().get_string_from_utf8()
			mesaj_yonet(mesaj)

# --- SUNUCU MESAJLARI ---
func mesaj_yonet(gelen_veri):
	# 1. Numara ataması
	if gelen_veri.begins_with("SEN_OYUNCU_"):
		benim_numaram = int(gelen_veri.split("_")[2])
		print("Ben Oyuncu " + str(benim_numaram) + " oldum!")
		yeni_tur_baslat() 

	# 2. HERKES HAZIR!
	elif gelen_veri == "HERKES_HAZIR_BASLA":
		oyunu_sifirla()
		yeni_tur_baslat()

	# 3. RAKİP KAÇTI
	elif gelen_veri == "RAKIP_AYRILDI":
		if has_node("Lbl_Durum"): $Lbl_Durum.text = "RAKİP KAÇTI!"
		if has_node("GeriSayim"): $GeriSayim.stop()
		sohbete_ekle("SİSTEM", "Rakip oyundan ayrıldı.")
		butonlari_kilitle(true)
		
	# 4. SONUÇ GELDİ (DÜZELTİLEN KISIM BURASI)
	elif gelen_veri.begins_with("SONUC:"):
		if has_node("GeriSayim"): $GeriSayim.stop()
		if has_node("Lbl_Sure"): $Lbl_Sure.text = ""
		
		var parcalar = gelen_veri.split(":")
		var sunucu_p1_karari = parcalar[1] # Sunucudaki 1. kişinin kararı
		var sunucu_p2_karari = parcalar[2] # Sunucudaki 2. kişinin kararı
		
		var rakip_ne_yapti = ""
		var ben_ne_yaptim = ""
		
		# KİM KİMDİR KONTROLÜ
		if benim_numaram == 1:
			ben_ne_yaptim = sunucu_p1_karari
			rakip_ne_yapti = sunucu_p2_karari
		else:
			ben_ne_yaptim = sunucu_p2_karari
			rakip_ne_yapti = sunucu_p1_karari
		
		# Artık doğru sıralamayla ışıkları yakabiliriz
		sonuc_isiklarini_yak(rakip_ne_yapti, ben_ne_yaptim)
		
		tur_sayisi += 1
		
		await get_tree().create_timer(2.0).timeout
		yeni_tur_baslat()
	
	# 5. Sohbet
	elif gelen_veri.begins_with("MSG:"):
		var parcalar = gelen_veri.split(":", true, 2)
		sohbete_ekle(parcalar[1], parcalar[2])

# --- OYUN AKIŞI ---
func yeni_tur_baslat():
	if tur_sayisi > 5:
		oyunu_bitir()
		return

	kalan_sure = 60
	sure_isliyor = true
	if has_node("Lbl_Sure"): $Lbl_Sure.text = str(kalan_sure)
	if has_node("GeriSayim"): $GeriSayim.start()
	
	butonlari_kilitle(false)
	if has_node("Lbl_Durum"): $Lbl_Durum.text = "SEÇİMİNİ YAP!"
	
	if has_node("Btn_Dost"): $Btn_Dost.modulate.a = 1.0
	if has_node("Btn_Ihanet"): $Btn_Ihanet.modulate.a = 1.0

func oyunu_sifirla():
	tur_sayisi = 1
	benim_puanim = 0
	rakip_puani = 0
	skorlari_guncelle()
	gizle_panel()
	for i in range(1, 11):
		ampul_boya(i, "SONUK")

func _on_geri_sayim_timeout():
	if not sure_isliyor: return
	kalan_sure -= 1
	if has_node("Lbl_Sure"): 
		$Lbl_Sure.text = str(kalan_sure)
		if kalan_sure <= 3: $Lbl_Sure.modulate = Color.RED
		else: $Lbl_Sure.modulate = Color.YELLOW
	if kalan_sure <= 0: otomatik_oyna()

func otomatik_oyna():
	var rastgele = ["DOST", "IHANET"].pick_random()
	if rastgele == "DOST": _on_btn_dost_pressed()
	else: _on_btn_ihanet_pressed()

# --- IŞIKLAR VE PUANLAR ---
func sonuc_isiklarini_yak(rakip_karar, benim_karar):
	# İlk parametre her zaman RAKİP, ikinci her zaman BEN olacak şekilde ayarladık
	
	ampul_boya(tur_sayisi, rakip_karar)
	ampul_boya(tur_sayisi + 5, benim_karar)
	
	if rakip_karar == "DOST" and benim_karar == "DOST":
		rakip_puani += 3
		benim_puanim += 3
	elif rakip_karar == "IHANET" and benim_karar == "IHANET":
		rakip_puani += 1
		benim_puanim += 1
	elif rakip_karar == "DOST" and benim_karar == "IHANET":
		benim_puanim += 5
	elif rakip_karar == "IHANET" and benim_karar == "DOST":
		rakip_puani += 5

	skorlari_guncelle()

func ampul_boya(no, karar):
	if no > 10: return
	var yol = "Ampuller/Ampul_" + str(no)
	if has_node(yol):
		var ampul = get_node(yol)
		if karar == "DOST": ampul.texture = ampul_yesil
		elif karar == "IHANET": ampul.texture = ampul_kirmizi
		else: ampul.texture = ampul_sonuk

func skorlari_guncelle():
	if has_node("Lbl_Skor_Ben"):
		$Lbl_Skor_Ben.text = str(benim_puanim)
		$Lbl_Skor_Rakip.text = str(rakip_puani)

func _on_btn_dost_pressed():
	if not sure_isliyor: return 
	oyuncu_basti("DOST")

func _on_btn_ihanet_pressed():
	if not sure_isliyor: return
	oyuncu_basti("IHANET")

func oyuncu_basti(karar):
	sure_isliyor = false 
	sunucuya_gonder(karar)
	butonlari_kilitle(true)
	if has_node("Lbl_Durum"):
		$Lbl_Durum.text = "RAKİP BEKLENİYOR..."
		$Lbl_Durum.modulate = Color.GREEN_YELLOW
	if has_node("Btn_Dost"): $Btn_Dost.modulate.a = 0.5
	if has_node("Btn_Ihanet"): $Btn_Ihanet.modulate.a = 0.5

func sunucuya_gonder(txt):
	socket.put_packet(txt.to_utf8_buffer())

func butonlari_kilitle(durum):
	if has_node("Btn_Dost"):
		$Btn_Dost.disabled = durum
		$Btn_Ihanet.disabled = durum

func _on_input_mesaj_text_submitted(new_text):
	if new_text.strip_edges() == "": return
	sunucuya_gonder("CHAT:" + new_text)
	if has_node("SohbetPaneli/Input_Mesaj"): $SohbetPaneli/Input_Mesaj.text = ""

func sohbete_ekle(kim, mesaj):
	var renk = "red" 
	if str(benim_numaram) in kim: renk = "green"; kim = "BEN"
	var formatli = "[color=" + renk + "]" + kim + ":[/color] " + mesaj + "\n"
	if has_node("SohbetPaneli/Lbl_Mesajlar"): $SohbetPaneli/Lbl_Mesajlar.append_text(formatli)

# --- OYUN SONU VE YENİDEN BAŞLATMA ---

func oyunu_bitir():
	var panel = null
	var etiket = null
	
	if has_node("CanvasLayer/Panel_Bitis"):
		panel = get_node("CanvasLayer/Panel_Bitis")
		etiket = get_node("CanvasLayer/Panel_Bitis/Lbl_Sonuc")
	elif has_node("Panel_Bitis"):
		panel = get_node("Panel_Bitis")
		etiket = get_node("Panel_Bitis/Lbl_Sonuc")
	
	if panel:
		panel.show()
		# --- SONUÇ KONTROLÜ ---
		if benim_puanim > rakip_puani:
			etiket.text = "KAZANDIN!\nTEBRİKLER"
			etiket.modulate = Color.GREEN
		elif benim_puanim < rakip_puani:
			etiket.text = "KAYBETTİN...\nDAHA DİKKATLİ OL"
			etiket.modulate = Color.RED
		else:
			etiket.text = "BERABERE!\nDOSTLUK KAZANDI"
			etiket.modulate = Color.YELLOW
	
	if has_node("CanvasLayer/Panel_Bitis/Btn_Tekrar"):
		var btn = get_node("CanvasLayer/Panel_Bitis/Btn_Tekrar")
		btn.text = "TEKRAR OYNA"
		btn.disabled = false

func gizle_panel():
	if has_node("CanvasLayer/Panel_Bitis"): $CanvasLayer/Panel_Bitis.hide()
	elif has_node("Panel_Bitis"): $Panel_Bitis.hide()

func _on_btn_tekrar_pressed():
	sunucuya_gonder("BEN_HAZIRIM")
	if has_node("CanvasLayer/Panel_Bitis/Btn_Tekrar"):
		var btn = get_node("CanvasLayer/Panel_Bitis/Btn_Tekrar")
		btn.text = "RAKİP BEKLENİYOR..."
		btn.disabled = true

func _on_btn_cikis_pressed():
	socket.close()
	get_tree().quit()
