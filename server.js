const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
    const indexPath = path.join(__dirname, 'public', 'index.html');
    if (fs.existsSync(indexPath)) {
        res.sendFile(indexPath);
    } else {
        res.status(200).send("<h3>Xvory Server is running!</h3><p>However, the <b>public</b> folder is missing. Please make sure you uploaded the 'public' directory to GitHub.</p>");
    }
});

// Simple in-memory storage for configs
// Format: { id: "config1", name: "My Config", script: "print('hello')" }
let configs = [];
let activeConfig = null;

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
    res.json({ success: true, configs });
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

    // Update activeConfig reference if it was the active one
    if (activeConfig && activeConfig.id === id) {
        activeConfig = configs[index];
    }

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
    if (activeConfig && activeConfig.id === id) {
        activeConfig = null;
    }

    res.json({ success: true, message: "Config deleted", config: deleted });
});

app.post('/api/active-config', (req, res) => {
    const { id } = req.body;
    const config = configs.find(c => c.id === id);

    if (config) {
        activeConfig = config;
        res.json({ success: true, message: "Active config set", activeConfig });
    } else {
        res.status(404).json({ success: false, message: "Config not found" });
    }
});

app.get('/api/active-config', (req, res) => {
    if (activeConfig) {
        res.json({ success: true, script: activeConfig.script, name: activeConfig.name });
    } else {
        res.json({ success: false, message: "No active configuration set" });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Xvory server running on port ${PORT}`);
});