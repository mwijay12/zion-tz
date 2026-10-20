import react from '@vitejs/plugin-react'
import { defineConfig, type Plugin } from 'vite'

function churchSyncPlugin(): Plugin {
  let sseClients: any[] = [];
  let storedNotices: any[] = [];
  let storedSermons: any[] = [];
  let storedChoirSongs: any[] = [];
  let storedVisitors: any[] = [];
  let storedPrayers: any[] = [];

  return {
    name: 'church-sync-api',
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        // Enable CORS for Flutter Web & other ports
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

        if (req.method === 'OPTIONS') {
          res.statusCode = 204;
          res.end();
          return;
        }

        const url = req.url?.split('?')[0];

        // 1. SSE Stream for Real-Time Push Notifications
        if (url === '/api/sync/events' && req.method === 'GET') {
          res.writeHead(200, {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          });
          res.write('data: {"type":"CONNECTED","timestamp":' + Date.now() + '}\n\n');
          sseClients.push(res);

          req.on('close', () => {
            sseClients = sseClients.filter(c => c !== res);
          });
          return;
        }

        // 2. Announcements / Notices API
        if (url === '/api/sync/notices') {
          if (req.method === 'GET') {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify(storedNotices));
            return;
          }

          if (req.method === 'POST') {
            let body = '';
            req.on('data', chunk => { body += chunk; });
            req.on('end', () => {
              try {
                const notice = JSON.parse(body);
                storedNotices = [notice, ...storedNotices.filter(n => n.id !== notice.id)];
                
                // Broadcast to all connected SSE clients (mobile apps)
                const ssePayload = JSON.stringify({
                  type: 'NOTICE_ADDED',
                  payload: notice,
                  source: 'web_portal',
                  timestamp: Date.now()
                });
                for (const client of sseClients) {
                  try {
                    client.write(`data: ${ssePayload}\n\n`);
                  } catch (_) {}
                }

                res.setHeader('Content-Type', 'application/json');
                res.end(JSON.stringify({ success: true, notice }));
              } catch (e: any) {
                res.statusCode = 400;
                res.end(JSON.stringify({ error: e.message }));
              }
            });
            return;
          }
        }

        // 3. Sermons Sync API
        if (url === '/api/sync/sermons') {
          if (req.method === 'GET') {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify(storedSermons));
            return;
          }

          if (req.method === 'POST') {
            let body = '';
            req.on('data', chunk => { body += chunk; });
            req.on('end', () => {
              try {
                const sermon = JSON.parse(body);
                storedSermons = [sermon, ...storedSermons.filter(s => s.id !== sermon.id)];

                const ssePayload = JSON.stringify({
                  type: 'SERMON_ADDED',
                  payload: sermon,
                  source: 'web_portal',
                  timestamp: Date.now()
                });
                for (const client of sseClients) {
                  try {
                    client.write(`data: ${ssePayload}\n\n`);
                  } catch (_) {}
                }

                res.setHeader('Content-Type', 'application/json');
                res.end(JSON.stringify({ success: true, sermon }));
              } catch (e: any) {
                res.statusCode = 400;
                res.end(JSON.stringify({ error: e.message }));
              }
            });
            return;
          }
        }

        // 4. Choir Songs Sync API
        if (url === '/api/sync/choir-songs') {
          if (req.method === 'GET') {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify(storedChoirSongs));
            return;
          }

          if (req.method === 'POST') {
            let body = '';
            req.on('data', chunk => { body += chunk; });
            req.on('end', () => {
              try {
                const data = JSON.parse(body);
                if (Array.isArray(data.songs)) {
                  storedChoirSongs = data.songs;
                } else if (data.song) {
                  storedChoirSongs = [data.song, ...storedChoirSongs.filter(s => s.id !== data.song.id)];
                }

                const ssePayload = JSON.stringify({
                  type: 'CHOIR_SONGS_UPDATED',
                  payload: storedChoirSongs,
                  source: 'web_portal',
                  timestamp: Date.now()
                });
                for (const client of sseClients) {
                  try {
                    client.write(`data: ${ssePayload}\n\n`);
                  } catch (_) {}
                }

                res.setHeader('Content-Type', 'application/json');
                res.end(JSON.stringify({ success: true, songs: storedChoirSongs }));
              } catch (e: any) {
                res.statusCode = 400;
                res.end(JSON.stringify({ error: e.message }));
              }
            });
            return;
          }
        }

        // 5. Visitors Registry Sync API (Deacons)
        if (url === '/api/sync/visitors') {
          if (req.method === 'GET') {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify(storedVisitors));
            return;
          }

          if (req.method === 'POST') {
            let body = '';
            req.on('data', chunk => { body += chunk; });
            req.on('end', () => {
              try {
                const visitor = JSON.parse(body);
                storedVisitors = [visitor, ...storedVisitors.filter(v => v.id !== visitor.id)];

                const ssePayload = JSON.stringify({
                  type: 'VISITOR_ADDED',
                  payload: visitor,
                  source: 'sync_api',
                  timestamp: Date.now()
                });
                for (const client of sseClients) {
                  try { client.write(`data: ${ssePayload}\n\n`); } catch (_) {}
                }

                res.setHeader('Content-Type', 'application/json');
                res.end(JSON.stringify({ success: true, visitor }));
              } catch (e: any) {
                res.statusCode = 400;
                res.end(JSON.stringify({ error: e.message }));
              }
            });
            return;
          }
        }

        // 6. War Room Prayer Requests Sync API (Pastors & Believers)
        if (url === '/api/sync/prayers') {
          if (req.method === 'GET') {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify(storedPrayers));
            return;
          }

          if (req.method === 'POST') {
            let body = '';
            req.on('data', chunk => { body += chunk; });
            req.on('end', () => {
              try {
                const prayer = JSON.parse(body);
                storedPrayers = [prayer, ...storedPrayers.filter(p => p.id !== prayer.id)];

                const ssePayload = JSON.stringify({
                  type: 'PRAYER_ADDED',
                  payload: prayer,
                  source: 'sync_api',
                  timestamp: Date.now()
                });
                for (const client of sseClients) {
                  try { client.write(`data: ${ssePayload}\n\n`); } catch (_) {}
                }

                res.setHeader('Content-Type', 'application/json');
                res.end(JSON.stringify({ success: true, prayer }));
              } catch (e: any) {
                res.statusCode = 400;
                res.end(JSON.stringify({ error: e.message }));
              }
            });
            return;
          }
        }

        next();
      });
    }
  };
}

export default defineConfig({
  plugins: [react(), churchSyncPlugin()],
  server: {
    cors: true
  }
})
