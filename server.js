require('dotenv').config();

const express = require("express");
const axios = require("axios");

const app = express();
app.use(express.json());

const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;

// TEST ENDPOINT
app.get("/", (req, res) => {
  res.send("Yer Radarı API çalışıyor 🚀");
});

// RESOLVE ENDPOINT
app.post("/resolve", async (req, res) => {
  try {
    const text = req.body.text || "";

    console.log("======================================");
    console.log("📥 GELEN VERİ:");
    console.log(text);

    // URL bul
    const urlMatch = text.match(/https?:\/\/[^\s]+/);
    const shortUrl = urlMatch ? urlMatch[0] : null;

    if (!shortUrl) {
      return res.status(400).json({
        error: "Paylaşılan metinde URL bulunamadı"
      });
    }

    console.log("🔗 KISA URL:", shortUrl);

    // Redirect çöz
    let finalUrl = shortUrl;

    try {
      const response = await axios.get(shortUrl, {
        maxRedirects: 10,
        validateStatus: () => true,
        headers: {
          "User-Agent": "Mozilla/5.0"
        }
      });

      if (response.request?.res?.responseUrl) {
        finalUrl = response.request.res.responseUrl;
      }
    } catch (e) {
      console.log("⚠️ Redirect çözülemedi:", e.message);
    }

    console.log("🌍 FINAL URL:", finalUrl);

    // URL içinde koordinat ara
    const coordRegex =
      /@(-?\d+\.\d+),(-?\d+\.\d+)|!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)/;

    const match = finalUrl.match(coordRegex);

    if (match) {
      const lat = parseFloat(match[1] || match[3]);
      const lng = parseFloat(match[2] || match[4]);

      console.log("✅ URL'DEN KOORDİNAT:", lat, lng);

      return res.json({
        lat,
        lng,
        name: "Paylaşılan Konum",   // Flutter'ın beklediği alan
        source: "url"
      });
    }

    console.log("❌ URL içinde koordinat bulunamadı.");

    // İşletme adını FINAL URL'den çıkar
    let placeName = null;

    const placeMatch = finalUrl.match(/\/place\/([^\/]+)/);

    if (placeMatch && placeMatch[1]) {
      placeName = decodeURIComponent(placeMatch[1])
        .replace(/\+/g, " ")
        .trim();

      console.log("🏢 URL'DEN PLACE NAME:", placeName);
    }

    // Eğer URL'den çıkarılamazsa, gelen metinden dene
    if (!placeName) {
      const lines = text
        .split("\n")
        .map(line => line.trim())
        .filter(line => line.length > 0);

      for (const line of lines) {
        if (!line.includes("http")) {
          placeName = line;
          break;
        }
      }
    }

    if (!placeName) {
      return res.status(400).json({
        error: "İşletme adı bulunamadı"
      });
    }

    console.log("🏢 PLACE NAME:", placeName);

    // Google Places API
    const placesResponse = await axios.get(
      "https://maps.googleapis.com/maps/api/place/findplacefromtext/json",
      {
        params: {
          input: placeName,
          inputtype: "textquery",
          fields: "geometry,name",
          key: GOOGLE_API_KEY
        }
      }
    );

    const candidate = placesResponse.data.candidates?.[0];

    if (!candidate) {
      return res.status(404).json({
        error: "Google Places API işletmeyi bulamadı",
        placeName
      });
    }

    const lat = candidate.geometry.location.lat;
    const lng = candidate.geometry.location.lng;

    console.log("✅ PLACES API KOORDİNAT:", lat, lng);

    return res.json({
      lat,
      lng,
      name: candidate.name,   // Flutter'ın beklediği alan
      source: "places_api"
    });

  } catch (err) {
    console.error("🔥 SUNUCU HATASI:", err.message);

    if (err.response?.data) {
      console.error(JSON.stringify(err.response.data, null, 2));
    }

    return res.status(500).json({
      error: err.message
    });
  }
});

// Render için zorunlu PORT kullanımı
const PORT = process.env.PORT || 3000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server running on port ${PORT}`);
});