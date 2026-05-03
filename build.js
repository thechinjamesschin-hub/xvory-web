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

    const JavaScriptObfuscator = require('javascript-obfuscator');
    const obfuscationResult = JavaScriptObfuscator.obfuscate(result.code, {
        compact: true,
        controlFlowFlattening: true,
        controlFlowFlatteningThreshold: 0.75,
        deadCodeInjection: true,
        deadCodeInjectionThreshold: 0.4,
        debugProtection: true,
        debugProtectionInterval: 50,
        disableConsoleOutput: true,
        identifierNamesGenerator: 'hexadecimal',
        log: false,
        numbersToExpressions: true,
        renameGlobals: false,
        selfDefending: true,
        simplify: true,
        splitStrings: true,
        splitStringsChunkLength: 10,
        stringArray: true,
        stringArrayCallsTransform: true,
        stringArrayCallsTransformThreshold: 0.5,
        stringArrayEncoding: ['base64'],
        stringArrayIndexShift: true,
        stringArrayRotate: true,
        stringArrayShuffle: true,
        stringArrayWrappersCount: 1,
        stringArrayWrappersChainedCalls: true,
        stringArrayWrappersParametersMaxCount: 2,
        stringArrayWrappersType: 'variable',
        stringArrayThreshold: 0.75,
        unicodeEscapeSequence: false
    });

    fs.writeFileSync(outPath, obfuscationResult.getObfuscatedCode(), 'utf8');

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
