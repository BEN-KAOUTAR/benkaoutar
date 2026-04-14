const fs = require('fs'); 
const txt = fs.readFileSync('C:/Users/user/.gemini/antigravity/brain/4f8d1b2d-02f7-4063-813c-e098ff058514/.system_generated/steps/90/content.md', 'utf8'); 

try {
  let jsonStart = txt.indexOf('let options = ');
  if (jsonStart !== -1) {
    let jsonStr = txt.slice(jsonStart + 14);
    jsonStr = jsonStr.substring(0, jsonStr.lastIndexOf('};') + 1);
    
    // It's a JS object, not strict JSON. Let's regex it.
    let pathsMatch = jsonStr.match(/"paths":\s*\{([\s\S]*?)\},\s*"components"/);
    if (pathsMatch) {
      const pathsText = pathsMatch[1];
      const routes = [...pathsText.matchAll(/"(\/[^"]+)"/g)].map(m => m[1]);
      
      const targetRoutes = routes.filter(r => r.toLowerCase().includes('attendance') || r.toLowerCase().includes('justify'));
      console.log('Routes found:');
      console.log(targetRoutes);
    }
  }
} catch(e) {
  console.log(e);
}
