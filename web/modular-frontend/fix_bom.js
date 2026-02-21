const fs = require('fs');
const path = require('path');

function removeBOM(dir) {
    if (!fs.existsSync(dir)) return;
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            if (file !== 'node_modules' && file !== '.next') {
                removeBOM(fullPath);
            }
        } else if (file === 'package.json') {
            const content = fs.readFileSync(fullPath, 'utf8');
            let newContent = content.replace(/^\uFEFF/, '');
            // Also explicitly trim any weird leading whitespace just in case
            if (newContent !== content) {
                fs.writeFileSync(fullPath, newContent, 'utf8');
                console.log('Removed BOM from: ' + fullPath);
            }
        }
    }
}

removeBOM('./apps');
removeBOM('./packages');
console.log('BOM removal script finished.');
