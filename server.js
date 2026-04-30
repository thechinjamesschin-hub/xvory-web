const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

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

function loadData() {
    try {
        if (fs.existsSync(DATA_FILE)) {
            const raw = fs.readFileSync(DATA_FILE, 'utf8');
            const data = JSON.parse(raw);
            configs = data.configs || [];
            activeConfigId = data.activeConfigId || null;
            console.log(`Loaded ${configs.length} configs from disk. Active: ${activeConfigId || 'none'}`);
        }
    } catch (err) {
        console.error('Error loading data:', err.message);
        configs = [];
        activeConfigId = null;
    }
}

function saveData() {
    try {
        const data = JSON.stringify({ configs, activeConfigId }, null, 2);
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

const VALID_KEY = "xvory-admin";

app.post('/api/verify', (req, res) => {
    const { key } = req.body;
    if (key === VALID_KEY) {
        res.json({ success: true, message: "Valid Key" });
    } else {
        res.status(401).json({ success: false, message: "Invalid Key" });
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