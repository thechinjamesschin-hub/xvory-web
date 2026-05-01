const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const https = require('https');
const querystring = require('querystring');

const app = express();
const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'data.json');

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(express.static(path.join(__dirname, 'public')));

// --- Persistent Storage ---
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

// Load saved data on startup
loadData();

// --- Helper: get active config object ---
function getActiveConfig() {
    if (!activeConfigId) return null;
    return configs.find(c => c.id === activeConfigId) || null;
}

// --- Routes ---
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
        return res.status(400).json({ success: false, message: "Username, password, license, and verification token are required" });
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

    const newUser = { username, password, license, role: license === "xvory-admin" ? "Admin" : "User" };
    users.push(newUser);
    saveData();
    res.json({ success: true, message: "Registered successfully" });
});

app.post('/api/login', async (req, res) => {
    const { username, password, cfToken } = req.body;

    // Auto-login (saved from localStorage) doesn't have cfToken, so we can make cfToken optional for login
    // BUT since we want to protect the login form, if they use the form, they MUST send cfToken.
    // If cfToken is provided, verify it.
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
        res.json({ success: true, message: "Login successful", user: { username: user.username, role: user.role } });
    } else {
        res.status(401).json({ success: false, message: "Invalid username or password" });
    }
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

// Edit/update a config
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

// Delete a config
app.delete('/api/configs/:id', (req, res) => {
    const { id } = req.params;
    const index = configs.findIndex(c => c.id === id);

    if (index === -1) {
        return res.status(404).json({ success: false, message: "Config not found" });
    }

    const deleted = configs.splice(index, 1)[0];

    // Clear active config if it was deleted
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
        res.send(active.script);
    } else {
        res.status(404).send("-- No active configuration set by Xvory Dashboard");
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Xvory server running on port ${PORT}`);
});