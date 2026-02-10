import asyncio
import websockets
import os # YENİ: İşletim sistemi ayarlarını okumak için

oyuncular = []
hazir_olanlar = []
secimler = {}

async def sunucu(websocket):
    print("YENİ OYUNCU BAĞLANDI!")
    oyuncular.append(websocket)
    try:
        oyuncu_no = len(oyuncular)
        await websocket.send(f"SEN_OYUNCU_{oyuncu_no}")
        
        async for mesaj in websocket:
            if isinstance(mesaj, bytes): mesaj = mesaj.decode('utf-8')

            if mesaj == "BEN_HAZIRIM":
                if websocket not in hazir_olanlar: hazir_olanlar.append(websocket)
                if len(hazir_olanlar) == 2:
                    print("Herkes hazır!")
                    for o in oyuncular: await o.send("HERKES_HAZIR_BASLA")
                    hazir_olanlar.clear(); secimler.clear()

            elif mesaj.startswith("CHAT:"):
                gercek_mesaj = mesaj.split(":", 1)[1]
                gonderen = f"Oyuncu {oyuncu_no}"
                for o in oyuncular: await o.send(f"MSG:{gonderen}:{gercek_mesaj}")
                    
            elif mesaj in ["DOST", "IHANET"]:
                secimler[websocket] = mesaj
                if len(secimler) == 2:
                    o1, o2 = oyuncular[0], oyuncular[1]
                    sonuc = f"SONUC:{secimler[o1]}:{secimler[o2]}"
                    for o in oyuncular: await o.send(sonuc)
                    secimler.clear()
                
    except Exception as e:
        print(f"Hata: {e}")
    finally:
        if websocket in oyuncular: oyuncular.remove(websocket)
        if websocket in hazir_olanlar: hazir_olanlar.remove(websocket)
        if websocket in secimler: del secimler[websocket]
        for o in oyuncular: await o.send("RAKIP_AYRILDI")

async def baslat():
    # --- BURASI DEĞİŞTİ ---
    # Render'ın bize verdiği PORT'u alıyoruz. Yoksa 8765 kullan.
    port = int(os.environ.get("PORT", 8765))
    # "localhost" yerine "0.0.0.0" yazıyoruz ki dışarıya açılsın.
    async with websockets.serve(sunucu, "0.0.0.0", port):
        print(f"SUNUCU {port} PORTUNDA BAŞLADI!")
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(baslat())