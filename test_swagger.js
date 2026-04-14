const https = require('https');

function fetch(url, options) {
    return new Promise((resolve, reject) => {
        const req = https.request(url, options || {}, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                resolve({
                    status: res.statusCode,
                    data
                });
            });
        });
        req.setTimeout(5000, () => req.destroy(new Error("Timeout")));
        req.on('error', reject);
        if (options && options.body) req.write(options.body);
        req.end();
    });
}

async function testApi() {
    try {
        console.log("Fetching swagger-json...");
        const urls = [
            "https://api-demo.intranet.ikenas.com/api-docs-json",
            "https://api-demo.intranet.ikenas.com/api/swagger.json",
            "https://api-demo.intranet.ikenas.com/swagger.json",
            "https://api-demo.intranet.ikenas.com/api-docs/swagger.json"
        ];
        
        for (let url of urls) {
            try {
                const res = await fetch(url + "?format=json");
                if (res.status === 200 && res.data.includes("swagger")) {
                    console.log("Found at:", url);
                    const swagger = JSON.parse(res.data);
                    
                    const paths = Object.keys(swagger.paths).filter(p => p.includes('justify') || p.includes('attendances'));
                    console.log("\nRelevant Paths:");
                    for (let p of paths) {
                        console.log("Path:", p);
                        if (swagger.paths[p].put) {
                            console.log("  PUT params:", JSON.stringify(swagger.paths[p].put.parameters, null, 2));
                        }
                        if (swagger.paths[p].post) {
                            console.log("  POST params:", JSON.stringify(swagger.paths[p].post.parameters, null, 2));
                        }
                    }
                    return;
                }
            } catch (e) {
                console.log("Failed", url, e.message);
            }
        }
    } catch (e) {
        console.error(e);
    }
}

testApi();
