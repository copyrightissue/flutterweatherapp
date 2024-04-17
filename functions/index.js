/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {randomUUID} = require("crypto");
const functions = require("firebase-functions");
const axios = require("axios");

// const axios = require("axios");
// const params = {
//   access_key: process.env.WeatherStackKey,
//   query: "New York",
// };
const firebaseConfig = {
  apiKey: "AIzaSyA7Ifgh_kQmOZla1QC4kObdLkQqcQk7v44",
  authDomain: "test-12fa0.firebaseapp.com",
  databaseURL: "https://test-12fa0-default-rtdb.firebaseio.com",
  projectId: "test-12fa0",
  storageBucket: "test-12fa0.appspot.com",
  messagingSenderId: "344443641492",
  appId: "1:344443641492:web:651c3b30fbc469d3ed5e81",
  measurementId: "G-19XY9V4E8R",
};
//
const admin = require("firebase-admin");
admin.initializeApp(firebaseConfig);
//
const db = admin.firestore();
exports.scheduledWeatherFetch = functions.pubsub.schedule(
    "every 3 hours").onRun(async () => {
  const apiKey = functions.config().someservice.key;
  const cities = ["Missoula"];// add more cities here TODO: way of adding list of cities? expand database?

  const db = admin.firestore();

  for (const city of cities) {
    const url = `https://api.openweathermap.org/data/2.5/forecast?q=${city}&appid=${apiKey}&units=imperial`;

    try {
      const response = await axios.get(url);
      const weatherData = response.data;

      const cityRef = db.collection("weather").doc(city);
      await cityRef.set({
        ...weatherData, // Adds a server timestamp for the last update
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Weather data for ${city} updated successfully.`);
    } catch (error) {
      console.error(`Failed to fetch weather data for ${city}:`, error);
      throw new functions.https.HttpsError(
          "internal", `Failed to fetch weather data: ${error}`);
    }
  }
});
//
// const docRef = db.collection("Sites").doc("NewYork");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.pubsub = functions
//     .runWith({timeoutSeconds: 60, memory: "1GB"})
//     .pubsub
//     .schedule("every 1 hours")
//     .onRun(async (context) => {
//       await axios.get("http://api.weatherstack.com/current", {params})
//
//           .then((response) => {
//             const apiResponse = response.data;
//
//             // eslint-disable-next-line no-undef
//             docRef.set({
//
//               current: apiResponse,
//
//             });
//           }).catch((error) => {
//             console.log(error);
//           });
//       logger.info("running pubsub " + new Date().toISOString(),
//           {structuredData: true});
//       return null;
//     });
const labRef = db.collection("lab").doc("test");

exports.readLab = onRequest({timeoutSeconds: 15, cors: true, maxInstances: 10},
    (request, response) => {
      labRef.get().then((doc)=> {
        if (doc.exists) {
          response.send(doc.data());
        } else {
          logger.info("NO such document", {structuredData: true});
        }
      });
    });


exports.helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});

exports.flashBriefing = onRequest({
  timeoutSeconds: 15, cors: true, maxInstances: 10},
(request, response) => {
  logger.info("Flash Briefing requested!", {structuredData: true});
  response.set("Content-Type", "application/json").json(
      [
        {
          "uid": randomUUID(),
          "updateDate": new Date().toISOString(),
          "titleText": "What kind of test will I do today?",
          "mainText": "The quick brown fox jumped.",
          "streamUrl": null,
          "redirectionUrl": "https://example.com",
        },
      ],

  );
});
