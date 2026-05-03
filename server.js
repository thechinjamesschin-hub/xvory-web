const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const https = require('https');
const querystring = require('querystring');

const app = express();
const PORT = process.env.PORT || 3000;

// Use /app/data if on Railway (persistent volume), otherwise use local data.json
const DATA_DIR = process.env.RAILWAY_ENVIRONMENT ? '/app/data' : __dirname;
const DATA_FILE = path.join(DATA_DIR, 'data.json');

// Ensure data directory exists if using volume
if (!fs.existsSync(DATA_DIR)) {
    try {
        fs.mkdirSync(DATA_DIR, { recursive: true });
    } catch(e) {
        console.error("Could not create data directory", e);
    }
}

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
const rateLimitStore = {};
const RATE_WINDOW = 15 * 60 * 1000;
const RATE_MAX = 200;
app.use('/api/', (req, res, next) => {
    const ip = req.ip || req.connection.remoteAddress;
    const now = Date.now();
    if (!rateLimitStore[ip] || now - rateLimitStore[ip].start > RATE_WINDOW) {
        rateLimitStore[ip] = { start: now, count: 1 };
    } else {
        rateLimitStore[ip].count++;
    }
    if (rateLimitStore[ip].count > RATE_MAX) {
        return res.status(429).json({ success: false, message: 'Too many requests, try again later.' });
    }
    next();
});
const crypto = require('crypto');
let sessions = {};

app.use((req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Referrer-Policy', 'no-referrer');
    res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
    res.removeHeader('X-Powered-By');

    if (req.path.endsWith('.js') && !req.path.includes('/api/')) {
        res.setHeader('Cache-Control', 'no-store');
        res.setHeader('SourceMap', '');
    }

    if (req.path.endsWith('.map')) {
        return res.status(404).send('Not found');
    }

    next();
});

app.get('/app.js', (req, res) => {
    res.status(404).send('Not found');
});

app.use(express.static(path.join(__dirname, 'public'), {
    setHeaders: (res, filePath) => {
        if (filePath.endsWith('.js')) {
            res.setHeader('Content-Type', 'application/javascript; charset=utf-8');
        }
    }
}));

let configs = [];
let activeConfigId = null;
let users = [];

function loadData() {
    try {
        if (fs.existsSync(DATA_FILE)) {
            const raw = fs.readFileSync(DATA_FILE, 'utf8');
            const data = JSON.parse(raw);
            configs = data.configs || [];
            activeConfigId = data.activeConfigId || null;
            users = data.users || [];
            console.log(`Loaded ${configs.length} configs and ${users.length} users from disk. Active: ${activeConfigId || 'none'}`);
        }
    } catch (err) {
        console.error('Error loading data:', err.message);
        configs = [];
        activeConfigId = null;
        users = [];
    }
}

function saveData() {
    try {
        const data = JSON.stringify({ configs, activeConfigId, users }, null, 2);
        fs.writeFileSync(DATA_FILE, data, 'utf8');
    } catch (err) {
        console.error('Error saving data:', err.message);
    }
}

loadData();

function getActiveConfig() {
    if (!activeConfigId) return null;
    return configs.find(c => c.id === activeConfigId) || null;
}

app.get('/', (req, res) => {
    const indexPath = path.join(__dirname, 'public', 'index.html');
    if (fs.existsSync(indexPath)) {
        res.sendFile(indexPath);
    } else {
        res.status(200).send("<h3>Xvory Server is running!</h3><p>However, the <b>public</b> folder is missing. Please make sure you uploaded the 'public' directory to GitHub.</p>");
    }
});

const VALID_KEYS = ["xvory-admin", "xvory-premium"];
const TURNSTILE_SECRET = "0x4AAAAAADHAYQECG_1N00eyFLy7HRGBzIo";

function verifyTurnstileToken(token) {
    return new Promise((resolve) => {
        if (!token) return resolve(false);

        const postData = querystring.stringify({
            secret: TURNSTILE_SECRET,
            response: token
        });

        const options = {
            hostname: 'challenges.cloudflare.com',
            port: 443,
            path: '/turnstile/v0/siteverify',
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': Buffer.byteLength(postData)
            }
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                try {
                    const outcome = JSON.parse(data);
                    console.log("Turnstile verification outcome:", outcome);
                    resolve(outcome.success === true);
                } catch (e) {
                    console.error("Turnstile parse error:", e.message, "Raw:", data);
                    resolve(false);
                }
            });
        });

        req.on('error', (e) => {
            console.error("Turnstile request error:", e.message);
            resolve(false);
        });

        req.write(postData);
        req.end();
    });
}

app.post('/api/register', async (req, res) => {
    const { username, password, license, cfToken } = req.body;
    if (!username || !password || !license || !cfToken) {
        return res.status(400).json({ success: false, message: "Username, password, license, and verification are required" });
    }

    const isHuman = await verifyTurnstileToken(cfToken);
    if (!isHuman) {
        return res.status(403).json({ success: false, message: "Cloudflare verification failed" });
    }

    if (!VALID_KEYS.includes(license)) {
        return res.status(401).json({ success: false, message: "Invalid License Key" });
    }

    if (users.find(u => u.username === username)) {
        return res.status(400).json({ success: false, message: "Username already exists" });
    }

    const newUser = {
        id: Date.now().toString(),
        username,
        password,
        license,
        role: license === "xvory-admin" ? "Admin" : "User",
        registeredAt: new Date().toISOString(),
        lastLogin: null,
        robloxUsername: "",
        gamePlaceId: "",
        gamePlaceName: ""
    };
    users.push(newUser);
    saveData();
    res.json({ success: true, message: "Registered successfully" });
});

app.post('/api/login', async (req, res) => {
    const { username, password, cfToken } = req.body;

    if (cfToken) {
        const isHuman = await verifyTurnstileToken(cfToken);
        if (!isHuman) {
            return res.status(403).json({ success: false, message: "Cloudflare verification failed" });
        }
    }

    if (!username || !password) {
        return res.status(400).json({ success: false, message: "Username and password are required" });
    }

    const user = users.find(u => u.username === username && u.password === password);
    if (user) {
        user.lastLogin = new Date().toISOString();
        const userConfigCount = configs.filter(c => c.owner === user.username || !c.owner).length;
        const sessionToken = crypto.randomBytes(32).toString('hex');
        sessions[sessionToken] = user.username;
        saveData();
        res.json({
            success: true,
            message: "Login successful",
            token: sessionToken,
            user: {
                id: user.id,
                username: user.username,
                role: user.role,
                license: "HIDDEN",
                pfp: user.pfp,
                registeredAt: user.registeredAt,
                lastLogin: user.lastLogin,
                robloxUsername: user.robloxUsername || "",
                configsSaved: userConfigCount
            }
        });
    } else {
        res.status(401).json({ success: false, message: "Invalid username or password" });
    }
});

app.post('/api/settings', (req, res) => {
    const { username, token, pfp } = req.body;
    if (!token || !sessions[token] || sessions[token] !== username) {
        return res.status(401).json({ success: false, message: "Unauthorized session" });
    }
    const user = users.find(u => u.username === username);
    if (!user) return res.status(401).json({ success: false, message: "Unauthorized" });

    user.pfp = pfp;
    saveData();
    res.json({
        success: true,
        user: {
            id: user.id,
            username: user.username,
            role: user.role,
            license: "HIDDEN",
            pfp: user.pfp,
            lastUsernameChange: user.lastUsernameChange,
            registeredAt: user.registeredAt,
            robloxUsername: user.robloxUsername || ""
        }
    });
});

app.post('/api/change-username', (req, res) => {
    const { username, token, password, newUsername } = req.body;
    if (!token || !sessions[token] || sessions[token] !== username) {
        return res.status(401).json({ success: false, message: "Unauthorized session" });
    }
    const user = users.find(u => u.username === username);
    if (!user) return res.status(401).json({ success: false, message: "Invalid current password" });
    if (user.password !== password) return res.status(401).json({ success: false, message: "Invalid current password" });

    if (!newUsername || newUsername.trim().length < 3) {
        return res.status(400).json({ success: false, message: "Username must be at least 3 characters" });
    }

    if (users.find(u => u.username === newUsername.trim() && u !== user)) {
        return res.status(400).json({ success: false, message: "Username already taken" });
    }

    const SEVEN_DAYS = 7 * 24 * 60 * 60 * 1000;
    if (user.lastUsernameChange) {
        const timeSince = Date.now() - new Date(user.lastUsernameChange).getTime();
        if (timeSince < SEVEN_DAYS) {
            const daysLeft = Math.ceil((SEVEN_DAYS - timeSince) / (24 * 60 * 60 * 1000));
            return res.status(400).json({ success: false, message: `You can change your username again in ${daysLeft} day(s)` });
        }
    }

    user.username = newUsername.trim();
    user.lastUsernameChange = new Date().toISOString();
    saveData();
    res.json({ success: true, message: "Username updated!", user: { username: user.username, role: user.role, license: "HIDDEN", pfp: user.pfp, lastUsernameChange: user.lastUsernameChange } });
});

app.post('/api/change-password', (req, res) => {
    const { username, token, currentPassword, newPassword } = req.body;
    if (!token || !sessions[token] || sessions[token] !== username) {
        return res.status(401).json({ success: false, message: "Unauthorized session" });
    }
    const user = users.find(u => u.username === username);
    if (!user) return res.status(401).json({ success: false, message: "Current password is incorrect" });
    if (user.password !== currentPassword) return res.status(401).json({ success: false, message: "Invalid current password" });

    if (!newPassword || newPassword.length < 4) {
        return res.status(400).json({ success: false, message: "New password must be at least 4 characters" });
    }

    if (newPassword !== confirmPassword) {
        return res.status(400).json({ success: false, message: "New passwords do not match" });
    }

    user.password = newPassword;
    saveData();
    res.json({ success: true, message: "Password updated!" });
});

app.get('/api/configs', (req, res) => {
    res.json({ success: true, configs, activeConfigId });
});

app.post('/api/configs', (req, res) => {
    const { name, script } = req.body;
    if (!name || !script) {
        return res.status(400).json({ success: false, message: "Name and script are required" });
    }

    const newConfig = {
        id: Date.now().toString(),
        name,
        script,
        createdAt: new Date().toISOString()
    };

    configs.push(newConfig);
    saveData();
    res.json({ success: true, config: newConfig });
});

app.put('/api/configs/:id', (req, res) => {
    const { id } = req.params;
    const { name, script } = req.body;
    const index = configs.findIndex(c => c.id === id);

    if (index === -1) {
        return res.status(404).json({ success: false, message: "Config not found" });
    }

    if (name) configs[index].name = name;
    if (script) configs[index].script = script;
    configs[index].updatedAt = new Date().toISOString();

    saveData();
    res.json({ success: true, config: configs[index] });
});

app.delete('/api/configs/:id', (req, res) => {
    const { id } = req.params;
    const index = configs.findIndex(c => c.id === id);

    if (index === -1) {
        return res.status(404).json({ success: false, message: "Config not found" });
    }

    const deleted = configs.splice(index, 1)[0];

    if (activeConfigId === id) {
        activeConfigId = null;
    }

    saveData();
    res.json({ success: true, message: "Config deleted", config: deleted });
});

app.post('/api/active-config', (req, res) => {
    const { id } = req.body;
    const config = configs.find(c => c.id === id);

    if (config) {
        activeConfigId = id;
        saveData();
        res.json({ success: true, message: "Active config set", activeConfig: config });
    } else {
        res.status(404).json({ success: false, message: "Config not found" });
    }
});

app.get('/api/active-config', (req, res) => {
    const active = getActiveConfig();
    if (active) {
        res.set('Content-Type', 'text/plain; charset=utf-8');
        res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
        res.set('Pragma', 'no-cache');
        res.set('Expires', '0');
        res.send(active.script);
    } else {
        res.status(404).send("-- No active configuration set by Xvory Dashboard");
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Xvory server running on port ${PORT}`);
});