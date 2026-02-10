import asyncio
import websockets

oyuncular = []
secimler = {}
hazir_olanlar = [] # Tekrar oynamak isteyenleri burada tutacağız

async def sunucu(websocket):
    print("YENİ OYUNCU BAĞLANDI!")
    oyuncular.append(websocket)
    
    try:
        oyuncu_no = len(oyuncular)
        await websocket.send(f"SEN_OYUNCU_{oyuncu_no}")
        
        async for mesaj in websocket:
            if isinstance(mesaj, bytes):
                mesaj = mesaj.decode('utf-8')

            # --- 1. OYUNCU "TEKRAR OYNA" DEDİ ---
            if mesaj == "BEN_HAZIRIM":
                if websocket not in hazir_olanlar:
                    hazir_olanlar.append(websocket)
                
                # Eğer odadaki herkes (2 kişi) hazırsa:
                if len(hazir_olanlar) == 2:
                    print("Herkes hazır! Yeni oyun başlıyor...")
                    msg = "HERKES_HAZIR_BASLA"
                    for o in oyuncular:
                        await o.send(msg)
                    # Listeyi temizle ki sonraki tur yine kullanabilelim
                    hazir_olanlar.clear()
                    secimler.clear() # Önceki seçimleri de sil

            # --- 2. SOHBET MESAJI ---
            elif mesaj.startswith("CHAT:"):
                gercek_mesaj = mesaj.split(":", 1)[1]
                gonderen_kim = f"Oyuncu {oyuncu_no}"
                formatli_mesaj = f"MSG:{gonderen_kim}:{gercek_mesaj}"
                for o in oyuncular:
                    await o.send(formatli_mesaj)
                    
            # --- 3. OYUN HAMLESİ ---
            elif mesaj in ["DOST", "IHANET"]:
                print(f"Oyuncu {oyuncu_no} hamlesi: {mesaj}")
                secimler[websocket] = mesaj
                
                if len(secimler) == 2:
                    o1 = oyuncular[0]
                    o2 = oyuncular[1]
                    sonuc = f"SONUC:{secimler[o1]}:{secimler[o2]}"
                    for o in oyuncular:
                        await o.send(sonuc)
                    secimler.clear()
                
    except Exception as e:
        print(f"Hata veya Ayrılma: {e}")
    finally:
        # Oyuncu düşerse veya çıkarsa
        if websocket in oyuncular:
            oyuncular.remove(websocket)
        if websocket in hazir_olanlar:
            hazir_olanlar.remove(websocket)
        if websocket in secimler:
            del secimler[websocket]
        
        # Kalan oyuncuya haber ver (Oyun iptal)
        for o in oyuncular:
            await o.send("RAKIP_AYRILDI")

async def baslat():
    async with websockets.serve(sunucu, "localhost", 8765):
        print("SENKRON SUNUCU HAZIR!")
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(baslat())