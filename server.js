require('dotenv').config();

const express = require("express");
const axios = require("axios");

const app = express();

app.use(express.json());

const GOOGLE_API_KEY =
  process.env.GOOGLE_API_KEY;

// TEST
app.get("/", (req, res) => {
  res.send("Yer Radarı API çalışıyor 🚀");
});

// RESOLVE
app.post("/resolve", async (req, res) => {

  try {

    const text =
      req.body.text || "";

    console.log("=================================");
    console.log("📥 GELEN VERİ:");
    console.log(text);

    // URL BUL
    const urlMatch =
      text.match(/https?:\/\/[^\s]+/);

    const shortUrl =
      urlMatch ? urlMatch[0] : null;

    if (!shortUrl) {

      return res.status(400).json({
        error:
          "Paylaşılan metinde URL bulunamadı"
      });
    }

    console.log("🔗 KISA URL:", shortUrl);

    // REDIRECT ÇÖZ
    let finalUrl = shortUrl;

    try {

      const redirectResponse =
        await axios.get(shortUrl, {

          maxRedirects: 10,

          validateStatus: () => true,

          headers: {
            "User-Agent":
              "Mozilla/5.0"
          }
        });

      if (
        redirectResponse.request?.res
          ?.responseUrl
      ) {

        finalUrl =
          redirectResponse.request
            .res.responseUrl;
      }

    } catch (e) {

      console.log(
        "⚠️ Redirect çözülemedi:",
        e.message
      );
    }

    console.log("🌍 FINAL URL:");
    console.log(finalUrl);

    // PLACE NAME ÇIKAR
    let placeName = null;

    const placeMatch =
      finalUrl.match(/\/place\/([^\/]+)/);

    if (
      placeMatch &&
      placeMatch[1]
    ) {

      placeName =
        decodeURIComponent(
          placeMatch[1]
        )
          .replace(/\+/g, " ")
          .trim();
    }

    // METİNDEN AL
    if (!placeName) {

      const lines = text
        .split("\n")
        .map(line => line.trim())
        .filter(
          line => line.length > 0
        );

      for (const line of lines) {

        if (
          !line.includes("http")
        ) {

          placeName = line;
          break;
        }
      }
    }

    if (!placeName) {

      return res.status(400).json({
        error:
          "Yer adı bulunamadı"
      });
    }

    console.log(
      "🏢 PLACE NAME:",
      placeName
    );

    // GOOGLE PLACES API
    const placesResponse =
      await axios.get(
        "https://maps.googleapis.com/maps/api/place/findplacefromtext/json",
        {
          params: {

            input: placeName,

            inputtype:
              "textquery",

            fields:
              "name,geometry,types,formatted_address",

            language: "tr",

            key: GOOGLE_API_KEY
          }
        }
      );

    const candidate =
      placesResponse.data
        .candidates?.[0];

    if (!candidate) {

      return res.status(404).json({
        error:
          "Google Places API yer bulamadı"
      });
    }

    const lat =
      candidate.geometry
        .location.lat;

    const lng =
      candidate.geometry
        .location.lng;

    const types =
      candidate.types || [];

    const fullAddress =
      candidate.formatted_address || "";

    console.log(
      "📍 FULL ADDRESS:",
      fullAddress
    );

    // ŞEHİR / İLÇE AYIKLA
    let city = "";
    let district = "";

    const addressParts =
      fullAddress
        .split(",")
        .map(x => x.trim());

    if (
      addressParts.length >= 2
    ) {

      district =
        addressParts[
          addressParts.length - 2
        ];

      city =
        addressParts[
          addressParts.length - 1
        ];
    }

    console.log(
      "🏙️ CITY:",
      city
    );

    console.log(
      "🏘️ DISTRICT:",
      district
    );

    console.log(
      "🏷️ TYPES:",
      types
    );

    return res.json({

      lat,
      lng,

      name:
        candidate.name,

      city,
      district,

      types,

      address:
        fullAddress
    });

  } catch (err) {

    console.error(
      "🔥 SERVER ERROR:"
    );

    console.error(err.message);

    if (err.response?.data) {

      console.error(
        JSON.stringify(
          err.response.data,
          null,
          2
        )
      );
    }

    return res.status(500).json({

      error:
        err.message
    });
  }
});

// PORT
const PORT =
  process.env.PORT || 3000;

app.listen(
  PORT,
  "0.0.0.0",
  () => {

    console.log(
      `🚀 Server running on port ${PORT}`
    );
  }
);