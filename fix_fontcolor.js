const fs = require('fs');
const path = require('path');

function processFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  let modified = false;

  // Step 1: Revert all fontColor([$r('...')]) to fontColor($r('...'))
  let newContent = content.replace(/\.fontColor\(\[\$r\('([^']+)'\)\]\)/g, ".fontColor($r('$1'))");

  // Step 2: For SymbolGlyph, change fontColor(...) back to fontColor([...])
  const lines = newContent.split('\n');
  let inSymbolGlyph = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.includes('SymbolGlyph(')) {
      inSymbolGlyph = true;
    }
    if (inSymbolGlyph) {
      if (line.trim().startsWith('SymbolGlyph(') ||
          line.trim().startsWith('.fontSize(') ||
          line.trim().startsWith('.fontColor(') ||
          line.trim().startsWith('.opacity(') ||
          line.trim().startsWith('.margin(') ||
          line.trim().startsWith('.onClick(')) {
        // still in chain
      } else if (line.trim() !== '' && !line.trim().startsWith('.')) {
        inSymbolGlyph = false;
      }

      if (line.trim().startsWith('.fontColor(') && !line.includes('.fontColor([')) {
        const match = line.match(/\.fontColor\(([^[\n]+)\)/);
        if (match) {
          lines[i] = line.replace('.fontColor(' + match[1] + ')', '.fontColor([' + match[1].trim() + '])');
          modified = true;
        }
      }
    }
  }

  newContent = lines.join('\n');

  if (newContent !== content || modified) {
    fs.writeFileSync(filePath, newContent, 'utf8');
    console.log('Fixed:', filePath);
  }
}

function walk(dir) {
  for (const entry of fs.readdirSync(dir)) {
    const fullPath = path.join(dir, entry);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      walk(fullPath);
    } else if (fullPath.endsWith('.ets')) {
      processFile(fullPath);
    }
  }
}

walk('./entry/src/main/ets');
