
const SecureStore = {
    set: (k, v) => localStorage.setItem(k, btoa(encodeURIComponent(JSON.stringify(v)))),
    get: (k) => {
        try {
            const v = localStorage.getItem(k);
            return v ? JSON.parse(decodeURIComponent(atob(v))) : null;
        } catch (e) { return null; }
    },
    remove: (k) => localStorage.removeItem(k)
};
window.turnstileLoginId = null;
window.turnstileRegisterId = null;



document.addEventListener('DOMContentLoaded', () => {

    let savedConfigs = [];
    let activeConfigId = null;
    let editor = null;
    let editingConfigId = null;

    const loginScreen = document.getElementById('login-screen');
    const dashboardScreen = document.getElementById('dashboard-screen');

    const loginUsername = document.getElementById('login-username');
    const loginPassword = document.getElementById('login-password');
    const staySignedIn = document.getElementById('stay-signed-in');
    const loginBtn = document.getElementById('login-btn');
    const loginError = document.getElementById('login-error');

    const regUsername = document.getElementById('reg-username');
    const regPassword = document.getElementById('reg-password');
    const regLicense = document.getElementById('reg-license');
    const registerBtn = document.getElementById('register-btn');
    const registerError = document.getElementById('register-error');

    const tabs = document.querySelectorAll('.nav-links li');
    const tabContents = document.querySelectorAll('.tab-content');
    const pageTitle = document.getElementById('page-title');

    const maskedKey = document.getElementById('masked-key');
    const toggleKeyBtn = document.getElementById('toggle-key-btn');
    const copyKeyBtn = document.getElementById('copy-key-btn');

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

    const logoutBtn = document.getElementById('logout-btn');
    const editorStatus = document.getElementById('editor-status');
    const clearEditorBtn = document.getElementById('clear-editor-btn');

    const setActiveBtn = document.getElementById('set-active-btn') || document.getElementById('global-set-btn');
    const setActiveModal = document.getElementById('set-active-modal');
    const activeModalClose = document.getElementById('active-modal-close');
    const activeModalCancel = document.getElementById('active-modal-cancel');
    const activeModalConfirm = document.getElementById('active-modal-confirm');
    const activeConfigListModal = document.getElementById('active-config-list-modal');

    const logoutModal = document.getElementById('logout-modal');
    const logoutModalCancel = document.getElementById('logout-modal-cancel');
    const logoutModalConfirm = document.getElementById('logout-modal-confirm');
    const logoutModalClose = document.getElementById('logout-modal-close');

    const deleteModal = document.getElementById('delete-modal');
    const deleteModalCancel = document.getElementById('delete-modal-cancel');
    const deleteModalConfirm = document.getElementById('delete-modal-confirm');
    const deleteModalClose = document.getElementById('delete-modal-close');
    const deleteConfigName = document.getElementById('delete-config-name');
    let configToDelete = null;

    let selectedConfigToActive = null;

    const userProfileBtn = document.getElementById('user-profile-btn');
    const profileImg = document.getElementById('profile-img');
    const settingsPfpPreview = document.getElementById('settings-pfp-preview');
    const settingsPfpUrl = document.getElementById('settings-pfp-url');
    const savePfpBtn = document.getElementById('save-pfp-btn');
    const pfpMsg = document.getElementById('pfp-msg');

    const settingsNewUsername = document.getElementById('settings-new-username');
    const settingsUsernamePassword = document.getElementById('settings-username-password');
    const saveUsernameBtn = document.getElementById('save-username-btn');
    const usernameMsg = document.getElementById('username-msg');
    const usernameCooldownHint = document.getElementById('username-cooldown-hint');

    const settingsCurrentPw = document.getElementById('settings-current-pw');
    const settingsNewPw = document.getElementById('settings-new-pw');
    const settingsConfirmPw = document.getElementById('settings-confirm-pw');
    const savePasswordBtn = document.getElementById('save-password-btn');
    const passwordMsg = document.getElementById('password-msg');

    if (userProfileBtn) {
        userProfileBtn.addEventListener('click', () => {
            const settingsNav = document.getElementById('nav-settings');
            if (settingsNav) settingsNav.click();
        });
    }

    const pfpUploadWrapper = document.getElementById('pfp-upload-wrapper');
    const pfpFileInput = document.getElementById('pfp-file-input');

    if (pfpUploadWrapper && pfpFileInput) {
        pfpUploadWrapper.addEventListener('click', () => {
            pfpFileInput.click();
        });

        pfpFileInput.addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (!file) return;

            if (!file.type.startsWith('image/')) {
                showToast('Please select an image file', 'error');
                return;
            }

            if (file.size > 2 * 1024 * 1024) {
                showToast('Image must be under 2MB', 'error');
                return;
            }

            const reader = new FileReader();
            reader.onload = (ev) => {
                const base64 = ev.target.result;
                if (settingsPfpPreview) settingsPfpPreview.src = base64;
                if (settingsPfpUrl) settingsPfpUrl.value = base64;
            };
            reader.readAsDataURL(file);
        });
    }

    if (settingsPfpUrl) {
        settingsPfpUrl.addEventListener('input', () => {
            const url = settingsPfpUrl.value.trim();
            if (url && settingsPfpPreview) settingsPfpPreview.src = url;
        });
    }

    if (savePfpBtn) {
        savePfpBtn.addEventListener('click', () => {
            const auth = SecureStore.get('xvory-session');
            if (!auth) return;
            const newPfp = settingsPfpUrl ? settingsPfpUrl.value.trim() : '';

            savePfpBtn.disabled = true;
            savePfpBtn.querySelector('span').textContent = 'Saving...';

            fetch('/api/settings', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username: auth.username, token: auth.token, pfp: newPfp })
            })
                .then(r => r.json())
                .then(data => {
                    savePfpBtn.disabled = false;
                    savePfpBtn.querySelector('span').textContent = 'Save Avatar';
                    if (data.success) {
                        if (pfpMsg) { pfpMsg.textContent = 'Avatar saved!'; pfpMsg.className = 'settings-msg success'; }
                        if (profileImg) profileImg.src = data.user.pfp || `https://ui-avatars.com/api/?name=${data.user.username}&background=random`;
                        showToast('Avatar updated!');
                    } else {
                        if (pfpMsg) { pfpMsg.textContent = data.message; pfpMsg.className = 'settings-msg error'; }
                    }
                })
                .catch(() => {
                    savePfpBtn.disabled = false;
                    savePfpBtn.querySelector('span').textContent = 'Save Avatar';
                    if (pfpMsg) { pfpMsg.textContent = 'Connection error'; pfpMsg.className = 'settings-msg error'; }
                });
        });
    }

    if (saveUsernameBtn) {
        saveUsernameBtn.addEventListener('click', () => {
            const auth = SecureStore.get('xvory-session');
            if (!auth) return;
            const newUser = settingsNewUsername ? settingsNewUsername.value.trim() : '';
            const pw = settingsUsernamePassword ? settingsUsernamePassword.value : '';

            if (!newUser || !pw) {
                if (usernameMsg) { usernameMsg.textContent = 'Please fill all fields'; usernameMsg.className = 'settings-msg error'; }
                return;
            }

            saveUsernameBtn.disabled = true;
            saveUsernameBtn.querySelector('span').textContent = 'Updating...';

            fetch('/api/change-username', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username: auth.username, password: pw, newUsername: newUser })
            })
                .then(r => r.json())
                .then(data => {
                    saveUsernameBtn.disabled = false;
                    saveUsernameBtn.querySelector('span').textContent = 'Update Username';
                    if (data.success) {
                        if (usernameMsg) { usernameMsg.textContent = data.message; usernameMsg.className = 'settings-msg success'; }
                        auth.username = data.user.username;
                        SecureStore.set('xvory-auth', auth);
                        const accountUsername = document.getElementById('account-username');
                        if (accountUsername) accountUsername.textContent = data.user.username;
                        if (settingsNewUsername) settingsNewUsername.value = '';
                        if (settingsUsernamePassword) settingsUsernamePassword.value = '';
                        showToast('Username changed!');
                    } else {
                        if (usernameMsg) { usernameMsg.textContent = data.message; usernameMsg.className = 'settings-msg error'; }
                    }
                })
                .catch(() => {
                    saveUsernameBtn.disabled = false;
                    saveUsernameBtn.querySelector('span').textContent = 'Update Username';
                    if (usernameMsg) { usernameMsg.textContent = 'Connection error'; usernameMsg.className = 'settings-msg error'; }
                });
        });
    }

    if (savePasswordBtn) {
        savePasswordBtn.addEventListener('click', () => {
            const auth = SecureStore.get('xvory-session');
            if (!auth) return;
            const currentPw = settingsCurrentPw ? settingsCurrentPw.value : '';
            const newPw = settingsNewPw ? settingsNewPw.value : '';
            const confirmPw = settingsConfirmPw ? settingsConfirmPw.value : '';

            if (!currentPw || !newPw || !confirmPw) {
                if (passwordMsg) { passwordMsg.textContent = 'Please fill all fields'; passwordMsg.className = 'settings-msg error'; }
                return;
            }

            if (newPw !== confirmPw) {
                if (passwordMsg) { passwordMsg.textContent = 'New passwords do not match'; passwordMsg.className = 'settings-msg error'; }
                return;
            }

            savePasswordBtn.disabled = true;
            savePasswordBtn.querySelector('span').textContent = 'Updating...';

            fetch('/api/change-password', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username: auth.username, currentPassword: currentPw, newPassword: newPw, confirmPassword: confirmPw })
            })
                .then(r => r.json())
                .then(data => {
                    savePasswordBtn.disabled = false;
                    savePasswordBtn.querySelector('span').textContent = 'Update Password';
                    if (data.success) {
                        if (passwordMsg) { passwordMsg.textContent = data.message; passwordMsg.className = 'settings-msg success'; }
                        auth.password = newPw;
                        SecureStore.set('xvory-auth', auth);
                        if (settingsCurrentPw) settingsCurrentPw.value = '';
                        if (settingsNewPw) settingsNewPw.value = '';
                        if (settingsConfirmPw) settingsConfirmPw.value = '';
                        showToast('Password changed!');
                    } else {
                        if (passwordMsg) { passwordMsg.textContent = data.message; passwordMsg.className = 'settings-msg error'; }
                    }
                })
                .catch(() => {
                    savePasswordBtn.disabled = false;
                    savePasswordBtn.querySelector('span').textContent = 'Update Password';
                    if (passwordMsg) { passwordMsg.textContent = 'Connection error'; passwordMsg.className = 'settings-msg error'; }
                });
        });
    }

    function showToast(message, type = 'success') {
        const toast = document.getElementById('toast');
        toast.textContent = message;
        toast.className = 'toast ' + type + ' show';
        setTimeout(() => { toast.classList.remove('show'); }, 3000);
    }

    function maskKey(key) {
        if (!key || key.length <= 4) return '••••••••';
        const visibleStart = Math.min(3, Math.floor(key.length / 4));
        const visibleEnd = Math.min(3, Math.floor(key.length / 4));
        const maskedLength = key.length - visibleStart - visibleEnd;
        return key.substring(0, visibleStart) + '•'.repeat(maskedLength) + key.substring(key.length - visibleEnd);
    }

    function initEditor() {
        if (!editor) {
            const editorEl = document.getElementById('lua-editor');
            if (!editorEl) return;

            editor = CodeMirror.fromTextArea(editorEl, {
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

            const savedSession = SecureStore.get('xvory-editor-session');
            if (savedSession) {
                editor.setValue(savedSession);
            }

            let autoUpdateTimer = null;
            editor.on('change', () => {
                updateEditorStatus();
                SecureStore.set('xvory-editor-session', editor.getValue());

                const autoUpdateCb = document.getElementById('auto-update-cb');
                if (autoUpdateCb && autoUpdateCb.checked && editingConfigId) {
                    clearTimeout(autoUpdateTimer);
                    autoUpdateTimer = setTimeout(() => {
                        updateConfig(editingConfigId, null, editor.getValue(), true);
                    }, 800);
                }
            });
            updateEditorStatus();
        }
    }

    function updateEditorStatus() {
        if (!editorStatus || !editor) return;
        const lines = editor.lineCount();
        const chars = editor.getValue().length;
        const sizeStr = chars > 1024 ? `${(chars / 1024).toFixed(1)} KB` : `${chars} B`;

        if (editingConfigId) {
            const cfg = savedConfigs.find(c => c.id === editingConfigId);
            editorStatus.innerHTML = `<span style="color: #5d9cec;">Editing: ${cfg ? cfg.name : 'Unknown'}</span> <span style="opacity: 0.5;">·</span> ${lines} lines`;
            if (saveBtn) saveBtn.querySelector('span').textContent = 'Update';
        } else {
            editorStatus.innerHTML = `${lines} lines <span style="opacity: 0.5;">·</span> ${sizeStr}`;
            if (saveBtn) saveBtn.querySelector('span').textContent = 'Save';
        }
    }

    function fetchConfigs() {
        fetch('/api/configs')
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    savedConfigs = data.configs;
                    activeConfigId = data.activeConfigId;
                    renderConfigs();
                    updateStats();

                    const activeCfg = savedConfigs.find(c => c.id === activeConfigId);
                    if (activeConfigName && activeCfg) {
                        activeConfigName.textContent = activeCfg.name;
                        activeConfigName.classList.add('has-config');
                    } else if (activeConfigName) {
                        activeConfigName.textContent = 'None selected';
                        activeConfigName.classList.remove('has-config');
                    }
                }
            })
            .catch(err => console.error('Error fetching configs:', err));
    }

    function updateStats() {
        if (configCount) configCount.textContent = savedConfigs.length;
        if (configBadge) configBadge.textContent = savedConfigs.length;
    }

    const savedAuth = SecureStore.get('xvory-auth');
    if (savedAuth) {
        try {
            const auth = JSON.parse(savedAuth);
            doAutoLogin(auth.username, auth.password);
        } catch (e) {
            loginScreen.classList.add('active');
        }
    } else {
        loginScreen.classList.add('active');
    }

    const authTabs = document.querySelectorAll('.auth-tab');
    authTabs.forEach(tab => {
        tab.addEventListener('click', () => {
            authTabs.forEach(t => {
                t.classList.remove('active');
                t.style.borderBottomColor = 'transparent';
                t.style.color = '#888';
            });
            tab.classList.add('active');
            tab.style.borderBottomColor = '#ffffff';
            tab.style.color = 'white';

            document.getElementById('form-login').style.display = 'none';
            document.getElementById('form-register').style.display = 'none';
            document.getElementById(tab.dataset.target).style.display = 'block';

            if (window.turnstile) {
                if (tab.dataset.target === 'form-register' && window.turnstileRegisterId !== null) {
                    window.turnstile.reset(window.turnstileRegisterId);
                } else if (tab.dataset.target === 'form-login' && window.turnstileLoginId !== null) {
                    window.turnstile.reset(window.turnstileLoginId);
                }
            }
        });
    });

    function shakeField(field) {
        if (!field) return;
        const wrapper = field.closest('.auth-field') || field.parentElement;
        if (wrapper) {
            wrapper.classList.add('field-error');
            field.classList.add('input-error');
            setTimeout(() => {
                wrapper.classList.remove('field-error');
                field.classList.remove('input-error');
            }, 2000);
        }
    }

    function validateFields(fields) {
        let valid = true;
        fields.forEach(f => {
            if (f && !f.value.trim()) {
                shakeField(f);
                valid = false;
            }
        });
        return valid;
    }

    function doLogin() {
        const username = loginUsername.value.trim();
        const password = loginPassword.value.trim();

        if (!validateFields([loginUsername, loginPassword])) {
            loginError.textContent = "Please fill in all fields";
            return;
        }

        const cfToken = window.cfLoginToken || null;

        loginBtn.disabled = true;
        loginBtn.querySelector('span').textContent = 'Logging in...';

        fetch('/api/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password, cfToken })
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    loginScreen.classList.remove('active');
                    dashboardScreen.classList.add('active');

                    const accountUsername = document.getElementById('account-username');
                    if (accountUsername) accountUsername.textContent = username;

                    if (profileImg) {
                        const pfpSrc = data.user.pfp || `https://ui-avatars.com/api/?name=${username}&background=random`;
                        profileImg.src = pfpSrc;
                        if (settingsPfpPreview) settingsPfpPreview.src = pfpSrc;
                    }

                    const tierBadge = document.getElementById('tier-badge');
                    if (tierBadge) {
                        if (data.user.role === 'Admin') {
                            tierBadge.textContent = 'Admin';
                            tierBadge.style.background = 'rgba(239, 68, 68, 0.2)';
                            tierBadge.style.color = '#ef4444';
                        } else {
                            tierBadge.textContent = 'User';
                            tierBadge.style.background = 'rgba(93, 156, 236, 0.2)';
                            tierBadge.style.color = '#5d9cec';
                        }
                    }

                    initEditor();
                    fetchConfigs();

                    SecureStore.set('xvory-session', { username, token: data.token });
                    if (!staySignedIn || staySignedIn.checked) {
                        SecureStore.set('xvory-auth', { username, password });
                    } else {
                        SecureStore.remove('xvory-auth');
                    }

                    showToast('Authenticated successfully');
                } else {
                    loginError.textContent = data.message;
                    loginBtn.disabled = false;
                    loginBtn.querySelector('span').textContent = 'Login';
                    if (window.turnstile && window.turnstileLoginId !== null) {
                        window.turnstile.reset(window.turnstileLoginId);
                    }
                    window.cfLoginToken = null;
                }
            })
            .catch(err => {
                loginError.textContent = "Server connection failed";
                loginBtn.disabled = false;
                loginBtn.querySelector('span').textContent = 'Login';
                if (window.turnstile && window.turnstileLoginId !== null) {
                    window.turnstile.reset(window.turnstileLoginId);
                }
                window.cfLoginToken = null;
            });
    }

    function doAutoLogin(username, password) {
        fetch('/api/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    dashboardScreen.classList.add('active');
                    const accountUsername = document.getElementById('account-username');
                    if (accountUsername) accountUsername.textContent = username;

                    if (profileImg) {
                        const pfpSrc = data.user.pfp || `https://ui-avatars.com/api/?name=${username}&background=random`;
                        profileImg.src = pfpSrc;
                        if (settingsPfpPreview) settingsPfpPreview.src = pfpSrc;
                    }

                    SecureStore.set('xvory-session', { username, token: data.token });

                    const tierBadge = document.getElementById('tier-badge');
                    if (tierBadge) {
                        if (data.user.role === 'Admin') {
                            tierBadge.textContent = 'Admin';
                            tierBadge.style.background = 'rgba(239, 68, 68, 0.2)';
                            tierBadge.style.color = '#ef4444';
                        } else {
                            tierBadge.textContent = 'User';
                            tierBadge.style.background = 'rgba(93, 156, 236, 0.2)';
                            tierBadge.style.color = '#5d9cec';
                        }
                    }

                    initEditor();
                    fetchConfigs();
                    showToast('Welcome back, ' + username);
                } else {
                    SecureStore.remove('xvory-session');
                    loginScreen.classList.add('active');
                }
            })
            .catch(err => {
                loginScreen.classList.add('active');
            });
    }

    function doRegister() {
        const username = regUsername.value.trim();
        const password = regPassword.value.trim();
        const license = regLicense.value.trim();

        if (!validateFields([regUsername, regPassword, regLicense])) {
            registerError.textContent = "Please fill in all fields";
            return;
        }

        const cfToken = window.cfRegisterToken || null;

        registerBtn.disabled = true;
        registerBtn.querySelector('span').textContent = 'Registering...';

        fetch('/api/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password, license, cfToken })
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    showToast('Registered successfully! Please login.');
                    authTabs[0].click();
                    loginUsername.value = username;
                    loginPassword.value = '';
                    registerBtn.disabled = false;
                    registerBtn.querySelector('span').textContent = 'Register';
                } else {
                    registerError.textContent = data.message;
                    registerBtn.disabled = false;
                    registerBtn.querySelector('span').textContent = 'Register';
                    if (window.turnstile && window.turnstileRegisterId !== null) {
                        window.turnstile.reset(window.turnstileRegisterId);
                    }
                    window.cfRegisterToken = null;
                }
            })
            .catch(err => {
                registerError.textContent = "Server connection failed";
                registerBtn.disabled = false;
                registerBtn.querySelector('span').textContent = 'Register';
                if (window.turnstile && window.turnstileRegisterId !== null) {
                    window.turnstile.reset(window.turnstileRegisterId);
                }
                window.cfRegisterToken = null;
            });
    }

    if (loginBtn) loginBtn.addEventListener('click', doLogin);
    if (loginPassword) loginPassword.addEventListener('keydown', (e) => { if (e.key === 'Enter') doLogin(); });

    if (registerBtn) registerBtn.addEventListener('click', doRegister);
    if (regLicense) regLicense.addEventListener('keydown', (e) => { if (e.key === 'Enter') doRegister(); });

    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            tabs.forEach(t => t.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));
            tab.classList.add('active');
            const target = tab.dataset.tab;
            document.getElementById(`tab-${target}`).classList.add('active');
            pageTitle.textContent = target === 'dashboard' ? 'Dashboard' : target === 'config' ? 'Config Editor' : 'Settings';
            if (target === 'config' && editor) setTimeout(() => editor.refresh(), 10);
        });
    });

    if (copyKeyBtn) {
        copyKeyBtn.addEventListener('click', () => {
            if (maskedKey.dataset.key) {
                navigator.clipboard.writeText(maskedKey.dataset.key);
                showToast('Key copied to clipboard');
            }
        });
    }

    if (toggleKeyBtn) {
        let keyRevealed = false;
        let keyHideTimer = null;
        toggleKeyBtn.addEventListener('click', () => {
            const eyeIcon = document.getElementById('eye-icon');
            if (keyRevealed) {
                maskedKey.textContent = '••••••••••••';
                maskedKey.classList.remove('key-revealed');
                eyeIcon.innerHTML = '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>';
                keyRevealed = false;
                clearTimeout(keyHideTimer);
                return;
            }
            const auth = SecureStore.get('xvory-session');
            if (!auth) { showToast('Session expired', 'error'); return; }
            maskedKey.textContent = 'Loading...';
            fetch('/api/get-key', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username: auth.username, token: auth.token })
            })
                .then(r => r.json())
                .then(data => {
                    if (data.success) {
                        maskedKey.textContent = data.key;
                        maskedKey.classList.add('key-revealed');
                        eyeIcon.innerHTML = '<path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/>';
                        keyRevealed = true;
                        keyHideTimer = setTimeout(() => {
                            maskedKey.textContent = '••••••••••••';
                            maskedKey.classList.remove('key-revealed');
                            eyeIcon.innerHTML = '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>';
                            keyRevealed = false;
                        }, 10000);
                    } else {
                        maskedKey.textContent = '••••••••••••';
                        showToast('Could not retrieve key', 'error');
                    }
                })
                .catch(() => {
                    maskedKey.textContent = '••••••••••••';
                    showToast('Connection error', 'error');
                });
        });
    }

    if (setActiveBtn) {
        setActiveBtn.addEventListener('click', () => {
            setActiveModal.classList.add('active');
            renderActiveModalConfigs();
        });
    }

    function closeActiveModal() {
        setActiveModal.classList.remove('active');
        selectedConfigToActive = null;
    }

    if (activeModalClose) activeModalClose.addEventListener('click', closeActiveModal);
    if (activeModalCancel) activeModalCancel.addEventListener('click', closeActiveModal);
    if (activeModalConfirm) {
        activeModalConfirm.addEventListener('click', () => {
            if (selectedConfigToActive) {
                if (selectedConfigToActive === activeConfigId) {
                    showToast('This config is already active', 'error');
                    closeActiveModal();
                    return;
                }
                setActiveConfig(selectedConfigToActive);
                closeActiveModal();
            } else {
                showToast('Please select a config', 'error');
            }
        });
    }

    function renderActiveModalConfigs() {
        if (!activeConfigListModal) return;
        activeConfigListModal.innerHTML = '';
        if (savedConfigs.length === 0) {
            activeConfigListModal.innerHTML = '<p style="text-align:center; color:#888; padding:20px;">No configs saved yet</p>';
            return;
        }
        savedConfigs.forEach(config => {
            const item = document.createElement('div');
            item.className = 'active-modal-item';
            const isSelected = selectedConfigToActive === config.id;

            item.style.padding = '12px 15px';
            item.style.margin = '5px 0';
            item.style.borderRadius = '12px';
            item.style.cursor = 'pointer';
            item.style.background = isSelected ? 'rgba(255, 255, 255, 0.15)' : 'rgba(255, 255, 255, 0.03)';
            item.style.border = isSelected ? '1px solid #ffffff' : '1px solid transparent';

            item.innerHTML = `
                <div style="display:flex; justify-content:space-between; align-items:center;">
                    <span style="font-weight:600; color:#fff;">${config.name}</span>
                    ${config.id === activeConfigId ? '<span style="font-size:10px; color:#fff;">[ACTIVE]</span>' : ''}
                </div>
            `;

            item.addEventListener('click', () => {
                selectedConfigToActive = config.id;
                renderActiveModalConfigs();
            });
            activeConfigListModal.appendChild(item);
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
                    showToast(`"${cfg.name}" is now active`);
                }
            });
    }

    if (logoutBtn) {
        logoutBtn.onclick = () => {
            logoutModal.classList.add('active');
        };
    }

    if (logoutModalCancel) logoutModalCancel.onclick = () => logoutModal.classList.remove('active');
    if (logoutModalClose) logoutModalClose.onclick = () => logoutModal.classList.remove('active');
    if (logoutModalConfirm) {
        logoutModalConfirm.onclick = () => {
            SecureStore.remove('xvory-session');
            window.location.reload();
        };
    }

    function openDeleteModal(config) {
        configToDelete = config;
        deleteConfigName.textContent = config.name;
        deleteModal.classList.add('active');
    }

    if (deleteModalCancel) deleteModalCancel.onclick = () => deleteModal.classList.remove('active');
    if (deleteModalClose) deleteModalClose.onclick = () => deleteModal.classList.remove('active');
    if (deleteModalConfirm) {
        deleteModalConfirm.onclick = () => {
            if (configToDelete) {
                fetch(`/api/configs/${configToDelete.id}`, { method: 'DELETE' })
                    .then(res => res.json())
                    .then(() => {
                        savedConfigs = savedConfigs.filter(c => c.id !== configToDelete.id);
                        renderConfigs();
                        updateStats();
                        deleteModal.classList.remove('active');
                        showToast(`Deleted ${configToDelete.name}`);
                    });
            }
        };
    }

    saveBtn.addEventListener('click', () => {
        if (editingConfigId) {
            updateConfig(editingConfigId, null, editor.getValue());
        } else {
            saveModal.classList.add('active');
            configNameInput.value = '';
            configNameInput.focus();
        }
    });

    modalCancelBtn.addEventListener('click', () => saveModal.classList.remove('active'));
    if (modalCloseBtn) modalCloseBtn.addEventListener('click', () => saveModal.classList.remove('active'));

    modalOkBtn.addEventListener('click', () => {
        const name = configNameInput.value.trim();
        const script = editor.getValue();
        if (!name) return showToast('Enter a name', 'error');

        fetch('/api/configs', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, script })
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    savedConfigs.push(data.config);
                    renderConfigs();
                    updateStats();
                    saveModal.classList.remove('active');
                    showToast(`Saved ${name}`);
                }
            });
    });

    function renderConfigs() {
        if (!configList) return;
        configList.innerHTML = '';
        if (savedConfigs.length === 0) {
            configList.innerHTML = '<div style="text-align:center; padding:40px; color:#555;">No configs</div>';
            return;
        }

        savedConfigs.forEach(config => {
            const el = document.createElement('div');
            el.className = 'config-item';
            if (activeConfigId === config.id) el.classList.add('is-active');
            if (editingConfigId === config.id) el.classList.add('editing');

            el.innerHTML = `
                <div class="config-info">
                    <div class="name">${config.name}</div>
                    ${activeConfigId === config.id ? '<span class="config-active-badge">Active</span>' : ''}
                </div>
                <div class="config-actions">
                    <button class="btn-action edit-btn" title="Edit">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 113 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                    </button>
                    <button class="btn-action delete-btn" title="Delete">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>
                    </button>
                </div>
            `;

            el.querySelector('.edit-btn').onclick = () => {
                editingConfigId = config.id;
                editor.setValue(config.script);
                document.getElementById('nav-config').click();
                renderConfigs();
            };

            el.querySelector('.delete-btn').onclick = () => {
                openDeleteModal(config);
            };

            configList.appendChild(el);
        });
    }

    function updateConfig(id, name, script, silent = false) {
        fetch(`/api/configs/${id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ script })
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    const idx = savedConfigs.findIndex(c => c.id === id);
                    savedConfigs[idx] = data.config;
                    updateEditorStatus();
                    renderConfigs();
                    if (!silent) showToast('Updated successfully');
                }
            });
    }

    if (clearEditorBtn) {
        clearEditorBtn.addEventListener('click', () => {
            if (editor) editor.setValue('');
            editingConfigId = null;
            updateEditorStatus();
            renderConfigs();
            showToast('Editor cleared', 'info');
        });
    }

    document.querySelectorAll('.eye-toggle').forEach(btn => {
        btn.addEventListener('click', () => {
            const targetId = btn.dataset.target;
            const input = document.getElementById(targetId);
            if (!input) return;
            if (input.type === 'password') {
                input.type = 'text';
                btn.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>';
            } else {
                input.type = 'password';
                btn.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';
            }
        });
    });
});
