// Service worker do app: guarda as telas para abrir rápido. Os dados sempre vêm do Supabase.
// Ao publicar uma versão nova, mude VERSAO para os celulares baixarem as telas novas.
const VERSAO = "espetinho-v1";
const TELAS = ["./", "./index.html", "./config.js", "./manifest.webmanifest", "./icone.svg", "./icone-192.png", "./icone-512.png", "./icone-180.png"];

self.addEventListener("install", (ev) => {
  ev.waitUntil(caches.open(VERSAO).then((c) => c.addAll(TELAS)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", (ev) => {
  ev.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== VERSAO).map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});
// Telas do próprio app: tenta a internet primeiro (pega atualização) e cai no guardado se estiver sem sinal.
self.addEventListener("fetch", (ev) => {
  const url = new URL(ev.request.url);
  if (ev.request.method !== "GET" || url.origin !== location.origin) return;
  ev.respondWith(
    fetch(ev.request).then((r) => {
      const copia = r.clone();
      caches.open(VERSAO).then((c) => c.put(ev.request, copia));
      return r;
    }).catch(() => caches.match(ev.request).then((r) => r || caches.match("./index.html")))
  );
});
