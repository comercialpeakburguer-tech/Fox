importScripts("https://www.gstatic.com/firebasejs/7.20.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/7.20.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyB5eRG8LECVS7FrqHLkCDa8Q7VyTifIypU",
  authDomain: "foxgo-93552.firebaseapp.com",
  projectId: "foxgo-93552",
  storageBucket: "foxgo-93552.firebasestorage.app",
  messagingSenderId: "1070521264518",
  appId: "1:1070521264518:web:c029770fa75c6794f42407"
  databaseURL: "...",
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});