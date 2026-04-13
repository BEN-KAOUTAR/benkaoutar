const fs = require('fs');
const content = fs.readFileSync('C:/Users/user/.gemini/antigravity/brain/85360b15-f449-4fe0-bb9e-62a1bb21a897/.system_generated/steps/746/content.md', 'utf-8');
const swaggerJson = content.match(/"paths": \{[\s\S]*\}\s*\}/);
if (swaggerJson) {
  try {
    const jsonStr = "{" + swaggerJson[0];
    const data = JSON.parse(jsonStr);
    
    // Attempt to dump the response schema for GET /news
    const getNews = data.paths['/news'] && data.paths['/news'].get;
    if (getNews) {
        console.log("GET /news exists. Responses:", JSON.stringify(getNews.responses, null, 2));
    }
  } catch(e) {
    console.error("Parse error:", e.message);
  }
}
