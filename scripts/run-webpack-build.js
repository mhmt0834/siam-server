'use strict';

const path = require('path');

process.env.NODE_ENV = 'production';

const projectRoot = process.cwd();
const webpack = require(path.join(projectRoot, 'node_modules', 'webpack'));
const config = require(path.join(projectRoot, 'webpack.config.js'));

config.mode = 'production';

webpack(config, (error, stats) => {
    if (error) {
        console.error(error.stack || error.message || error);
        process.exitCode = 1;
        return;
    }

    const output = stats.toString({
        all: false,
        colors: Boolean(process.stdout.isTTY),
        errors: true,
        warnings: true,
        timings: true
    });
    if (output) {
        console.log(output);
    }

    if (stats.hasErrors()) {
        process.exitCode = 1;
        return;
    }

    const warningCount = stats.compilation && stats.compilation.warnings
        ? stats.compilation.warnings.length
        : 0;
    if (warningCount > 0) {
        console.log(`Build completed with ${warningCount} warning(s).`);
    }
});
