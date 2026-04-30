document.addEventListener('DOMContentLoaded', () => {
    // --- State ---
    let savedConfigs = [];
    let activeConfigId = null;
    let editor = null;
    let editingConfigId = null; // Track if we're editing an existing config

    // --- DOM Elements ---
    const loginScreen = document.getElementById('login-screen');
    const dashboardScreen = document.getElementById('dashboard-screen');
    const keyInput = document.getElementById('key-input');
    const loginBtn = document.getElementById('login-btn');
    const loginError = document.getElementById('login-error');

    const tabs = document.querySelectorAll('.nav-links li');
    const tabContents = document.querySelectorAll('.tab-content');
    const pageTitle = document.getElementById('page-title');

    const maskedKey = document.getElementById('masked-key');
    const toggleKeyBtn = document.getElementById('toggle-key-btn');

    const saveBtn = document.getElementById('save-btn');
    const configList = document.getElementById('config-list');
    const configBadge = document.getElementById('config-badge');
    const configCount = document.getElementById('config-count');
    const activeConfigName = document.getElementById('active-config-name');

    const saveModal = document.getElementById('save-modal');
    const modalCancelBtn = document.getElementById('modal-cancel-btn');
    const modalOkBtn = document.getElementById('modal-ok-btn');
    const modalCloseBtn = document.getElementById('modal-close-btn');
    const configNameInput = document.getElementById('config-name-input');
    const modalTitle = document.getElementById('modal-title');
    const modalSaveLabel = document.getElementById('modal-save-label');

    const logoutBtn = document.getElementById('logout-btn');
    const editorStatus = document.getElementById('editor-status');
    const clearEditorBtn = document.getElementById('clear-editor-btn');

    // --- Toast Notification ---
    function showToast(message, type = 'success') {
        const toast = document.getElementById('toast');
        toast.textContent = message;
        toast.className = 'toast ' + type + ' show';
        setTimeout(() => { toast.classList.remove('show'); }, 3000);
    }

    // --- Key Masking Helper ---
    function maskKey(key) {
        if (!key || key.length <= 4) return '••••••••';
        const visibleStart = Math.min(3, Math.floor(key.length / 4));
        const visibleEnd = Math.min(3, Math.floor(key.length / 4));
        const maskedLength = key.length - visibleStart - visibleEnd;
        return key.substring(0, visibleStart) + '•'.repeat(maskedLength) + key.substring(key.length - visibleEnd);
    }

    // --- Initialization ---
    function initEditor() {
        if (!editor) {
            editor = CodeMirror.fromTextArea(document.getElementById('lua-editor'), {
                mode: 'lua',
                theme: 'xvory',
                lineNumbers: true,
                autoCloseBrackets: true,
                matchBrackets: true,
                indentUnit: 4,
                tabSize: 4,
                lineWrapping: false,
                styleActiveLine: true
            });

            // Track editor changes for status
            editor.on('change', () => {
                updateEditorStatus();
            });
        }
    }

    function updateEditorStatus() {
        if (!editorStatus) return;
        const lines = editor.lineCount();
        const chars = editor.getValue().length;
        const sizeStr = chars > 1024 ? `${(chars / 1024).toFixed(1)} KB` : `${chars} B`;
        
        if (editingConfigId) {
            const cfg = savedConfigs.find(c => c.id === editingConfigId);
            editorStatus.innerHTML = `<span class="status-editing">✏️ Editing: ${cfg ? cfg.name : 'Unknown'}</span> · ${lines} lines · ${sizeStr}`;
        } else {
            editorStatus.textContent = `${lines} lines · ${sizeStr}`;
        }
    }

    function fetchConfigs() {
        fetch('/api/configs')
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    savedConfigs = data.configs;
                    if (data.activeConfigId) {
                        activeConfigId = data.activeConfigId;
                        const activeCfg = savedConfigs.find(c => c.id === activeConfigId);
                        if (activeConfigName && activeCfg) {
                            activeConfigName.textContent = activeCfg.name;
                            activeConfigName.classList.add('has-config');
                        }
                    }
                    renderConfigs();
                    updateStats();
                }
            })
            .catch(err => console.error("Error fetching configs", err));
    }

    function updateStats() {
        if (configCount) configCount.textContent = savedConfigs.length;
        if (configBadge) configBadge.textContent = savedConfigs.length;
    }

    // --- Login Logic ---
    loginBtn.addEventListener('click', doLogin);
    keyInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') doLogin();
    });

    function doLogin() {
        const key = keyInput.value.trim();
        if (!key) {
            loginError.textContent = "Please enter a key";
            return;
        }

        loginBtn.disabled = true;
        loginBtn.querySelector('span').textContent = 'Authenticating...';

        fetch('/api/verify', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ key })
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    loginScreen.classList.remove('active');
                    dashboardScreen.classList.add('active');
                    maskedKey.dataset.key = key;
                    maskedKey.textContent = maskKey(key);
                    initEditor();
                    fetchConfigs();
                    showToast('Authenticated successfully');
                } else {
                    loginError.textContent = data.message;
                    loginBtn.disabled = false;
                    loginBtn.querySelector('span').textContent = 'Authenticate';
                }
            })
            .catch(err => {
                loginError.textContent = "Server connection failed";
                loginBtn.disabled = false;
                loginBtn.querySelector('span').textContent = 'Authenticate';
                console.error(err);
            });
    }

    // --- Tab Navigation ---
    const tabTitles = { dashboard: 'Dashboard', config: 'Config Editor' };

    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            tabs.forEach(t => t.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));

            tab.classList.add('active');
            const target = tab.dataset.tab;
            document.getElementById(`tab-${target}`).classList.add('active');
            pageTitle.textContent = tabTitles[target] || target;

            if (target === 'config' && editor) {
                setTimeout(() => editor.refresh(), 10);
            }
        });
    });

    // --- Dashboard Logic ---
    let keyVisible = false;
    toggleKeyBtn.addEventListener('click', () => {
        keyVisible = !keyVisible;
        const eyeIcon = document.getElementById('eye-icon');
        if (keyVisible) {
            maskedKey.textContent = maskedKey.dataset.key;
            maskedKey.classList.add('key-revealed');
            // Switch to "eye off" icon
            eyeIcon.innerHTML = '<path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/>';
        } else {
            maskedKey.textContent = maskKey(maskedKey.dataset.key);
            maskedKey.classList.remove('key-revealed');
            // Switch to "eye" icon
            eyeIcon.innerHTML = '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>';
        }
    });

    // --- Logout ---
    if (logoutBtn) {
        logoutBtn.addEventListener('click', () => {
            dashboardScreen.classList.remove('active');
            loginScreen.classList.add('active');
            keyInput.value = '';
            loginError.textContent = '';
            loginBtn.disabled = false;
            loginBtn.querySelector('span').textContent = 'Authenticate';
            keyVisible = false;
            maskedKey.textContent = '••••••••••••';
            maskedKey.classList.remove('key-revealed');
            editingConfigId = null;
        });
    }

    // --- Clear Editor ---
    if (clearEditorBtn) {
        clearEditorBtn.addEventListener('click', () => {
            if (editor) {
                editor.setValue('');
                editingConfigId = null;
                updateEditorStatus();
                showToast('Editor cleared');
            }
        });
    }

    // --- Config Logic ---
    saveBtn.addEventListener('click', () => {
        if (editingConfigId) {
            // If we're editing, skip the modal and update directly
            const script = editor.getValue();
            if (!script) {
                showToast('Config script is empty', 'error');
                return;
            }
            updateConfig(editingConfigId, null, script);
        } else {
            // New config — show modal for name
            saveModal.classList.add('active');
            configNameInput.value = '';
            configNameInput.focus();
            if (modalTitle) modalTitle.textContent = 'Save Configuration';
            if (modalSaveLabel) modalSaveLabel.textContent = 'Save';
        }
    });

    function closeModal() {
        saveModal.classList.remove('active');
        configNameInput.value = '';
    }

    modalCancelBtn.addEventListener('click', closeModal);
    if (modalCloseBtn) modalCloseBtn.addEventListener('click', closeModal);

    // Close modal on backdrop click
    saveModal.addEventListener('click', (e) => {
        if (e.target === saveModal) closeModal();
    });

    // Close modal on Escape
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && saveModal.classList.contains('active')) {
            closeModal();
        }
    });

    modalOkBtn.addEventListener('click', () => {
        const name = configNameInput.value.trim();
        const script = editor.getValue();

        if (!name) {
            showToast('Please enter a config name', 'error');
            return;
        }
        if (!script) {
            showToast('Config script is empty', 'error');
            return;
        }

        // Disable button to prevent double-clicks
        modalOkBtn.disabled = true;
        modalOkBtn.querySelector('span').textContent = 'Saving...';

        fetch('/api/configs', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, script })
        })
            .then(res => {
                if (!res.ok) throw new Error(`Server error: ${res.status}`);
                return res.json();
            })
            .then(data => {
                if (data.success) {
                    savedConfigs.push(data.config);
                    renderConfigs();
                    updateStats();
                    closeModal();
                    showToast(`Config "${name}" saved successfully`);
                }
            })
            .catch(err => {
                showToast('Failed to save config — check if your script is too large', 'error');
                console.error(err);
            })
            .finally(() => {
                modalOkBtn.disabled = false;
                if (modalSaveLabel) modalSaveLabel.textContent = 'Save';
            });
    });

    configNameInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') modalOkBtn.click();
    });

    // --- Update Config (Edit) ---
    function updateConfig(id, name, script) {
        const payload = {};
        if (name) payload.name = name;
        if (script) payload.script = script;

        fetch(`/api/configs/${id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        })
            .then(res => {
                if (!res.ok) throw new Error(`Server error: ${res.status}`);
                return res.json();
            })
            .then(data => {
                if (data.success) {
                    const index = savedConfigs.findIndex(c => c.id === id);
                    if (index !== -1) {
                        savedConfigs[index] = data.config;
                    }
                    renderConfigs();
                    showToast(`Config "${data.config.name}" updated successfully`);
                }
            })
            .catch(err => {
                showToast('Failed to update config', 'error');
                console.error(err);
            });
    }

    // --- Delete Config ---
    function deleteConfig(id) {
        fetch(`/api/configs/${id}`, {
            method: 'DELETE'
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    savedConfigs = savedConfigs.filter(c => c.id !== id);
                    if (editingConfigId === id) {
                        editingConfigId = null;
                        updateEditorStatus();
                    }
                    if (activeConfigId === id) {
                        activeConfigId = null;
                        if (activeConfigName) {
                            activeConfigName.textContent = 'None selected';
                            activeConfigName.classList.remove('has-config');
                        }
                    }
                    renderConfigs();
                    updateStats();
                    showToast(`Config deleted`);
                }
            })
            .catch(err => {
                showToast('Failed to delete config', 'error');
                console.error(err);
            });
    }

    function setActiveConfig(id) {
        fetch('/api/active-config', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id })
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    activeConfigId = id;
                    renderConfigs();
                    const cfg = savedConfigs.find(c => c.id === id);
                    if (activeConfigName && cfg) {
                        activeConfigName.textContent = cfg.name;
                        activeConfigName.classList.add('has-config');
                    }
                    showToast(`"${data.activeConfig.name}" is now active`);
                }
            });
    }

    function renderConfigs() {
        configList.innerHTML = '';

        if (savedConfigs.length === 0) {
            configList.innerHTML = `
                <div class="empty-configs">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                        <path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/>
                    </svg>
                    <p>No configs saved yet</p>
                    <span class="empty-hint">Write some code and hit Save to get started</span>
                </div>`;
            return;
        }

        savedConfigs.forEach(config => {
            const el = document.createElement('div');
            el.className = 'config-item';
            if (editingConfigId === config.id) el.classList.add('editing');
            if (activeConfigId === config.id) el.classList.add('is-active');

            // Config info section
            const infoEl = document.createElement('div');
            infoEl.className = 'config-info';

            const nameEl = document.createElement('div');
            nameEl.className = 'name';
            nameEl.textContent = config.name;
            nameEl.title = config.name;

            const metaEl = document.createElement('div');
            metaEl.className = 'config-meta';
            const scriptSize = config.script ? config.script.length : 0;
            const sizeStr = scriptSize > 1024 ? `${(scriptSize / 1024).toFixed(1)} KB` : `${scriptSize} B`;
            metaEl.textContent = sizeStr;

            infoEl.appendChild(nameEl);
            infoEl.appendChild(metaEl);

            // Actions section
            const actions = document.createElement('div');
            actions.className = 'actions';

            // Edit button
            const editBtn = document.createElement('button');
            editBtn.className = 'btn-action edit-btn';
            editBtn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>`;
            editBtn.title = 'Edit this config';
            editBtn.onclick = () => {
                editor.setValue(config.script);
                editingConfigId = config.id;
                updateEditorStatus();
                renderConfigs();

                // Switch to config tab
                tabs.forEach(t => t.classList.remove('active'));
                tabContents.forEach(c => c.classList.remove('active'));
                document.querySelector('[data-tab="config"]').classList.add('active');
                document.getElementById('tab-config').classList.add('active');
                pageTitle.textContent = 'Config Editor';
                setTimeout(() => editor.refresh(), 10);

                showToast(`Editing "${config.name}"`);
            };

            // Load button
            const loadBtn = document.createElement('button');
            loadBtn.className = 'btn-action load-btn';
            loadBtn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>`;
            loadBtn.title = 'Load into editor';
            loadBtn.onclick = () => {
                editor.setValue(config.script);
                editingConfigId = null;
                updateEditorStatus();
                renderConfigs();
                showToast(`Loaded "${config.name}"`);
            };

            // Set active button
            const setBtn = document.createElement('button');
            const isActive = activeConfigId === config.id;
            setBtn.className = 'btn-action' + (isActive ? ' active-config' : ' set-btn');
            setBtn.innerHTML = isActive
                ? `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>`
                : `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="8" y1="12" x2="16" y2="12"/></svg>`;
            setBtn.title = isActive ? 'Currently active' : 'Set as active';

            setBtn.onclick = () => {
                if (activeConfigId !== config.id) {
                    setActiveConfig(config.id);
                }
            };

            // Delete button
            const delBtn = document.createElement('button');
            delBtn.className = 'btn-action delete-btn';
            delBtn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>`;
            delBtn.title = 'Delete this config';
            delBtn.onclick = () => {
                if (confirm(`Delete "${config.name}"?`)) {
                    deleteConfig(config.id);
                }
            };

            actions.appendChild(editBtn);
            actions.appendChild(loadBtn);
            actions.appendChild(setBtn);
            actions.appendChild(delBtn);

            el.appendChild(infoEl);
            el.appendChild(actions);

            configList.appendChild(el);
        });
    }
});
