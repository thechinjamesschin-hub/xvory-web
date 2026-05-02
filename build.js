const { minify } = require('terser');
const fs = require('fs');
const path = require('path');

async function build() {
    const srcPath = path.join(__dirname, 'public', 'app.js');
    const outPath = path.join(__dirname, 'public', 'app.min.js');

    const source = fs.readFileSync(srcPath, 'utf8');

    const result = await minify(source, {
        compress: {
            drop_console: true,
            drop_debugger: false,
            passes: 3,
            dead_code: true,
            collapse_vars: true,
            reduce_vars: true,
            booleans_as_integers: true,
            hoist_funs: true,
            hoist_vars: false,
            join_vars: true,
            sequences: true,
            conditionals: true,
            evaluate: true,
            toplevel: true
        },
        mangle: {
            toplevel: true,
            reserved: ['turnstile', 'CodeMirror', 'onloadTurnstileCallback']
        },
        output: {
            comments: false,
            beautify: false,
            semicolons: true,
            preamble: '/* (c) Xvory 2024-2026 - All Rights Reserved */'
        },
        sourceMap: false
    });

    if (result.error) {
        console.error('Minification error:', result.error);
        process.exit(1);
    }

    fs.writeFileSync(outPath, result.code, 'utf8');

    const origSize = (source.length / 1024).toFixed(1);
    const minSize = (result.code.length / 1024).toFixed(1);
    const ratio = ((1 - result.code.length / source.length) * 100).toFixed(1);
    console.log(`Build complete: ${origSize}KB -> ${minSize}KB (${ratio}% smaller)`);
    console.log(`Output: ${outPath}`);
}

build().catch(err => {
    console.error('Build failed:', err);
    process.exit(1);
});
