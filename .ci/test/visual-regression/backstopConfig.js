// Stash dev URL, removing any trailing slash
const devURL = process.env.DEV_SITE_URL.replace(/\/$/, "");

// Stash multidev URL, removing any trailing slash
const multidevURL = process.env.MULTIDEV_SITE_URL.replace(/\/$/, "");

const pathsToTest = {
    'Homepage': '/',
    'Hello World': '/hello-world/',
}

let scenariosToTest = [];

for (let [key, value] of Object.entries(pathsToTest)) {
    scenariosToTest.push({
        label: key,
        url: multidevURL + value,
        referenceUrl: devURL + value,
        hideSelectors: [],
        removeSelectors: [],
        selectorExpansion: true,
        selectors: [
            'document',
        ],
        readyEvent: null,
        delay: 1500,
        misMatchThreshold: 0.1
    })
}

module.exports = {
    id: 'test',
    viewports: [{
            name: 'phone',
            width: 320,
            height: 480
        },
        {
            name: 'tablet',
            width: 1024,
            height: 768
        },
        {
            "name": "desktop",
            "width": 1920,
            "height": 1080
        }
    ],
    scenarios: scenariosToTest,
    paths: {
        bitmaps_reference: 'backstop_data/bitmaps_reference',
        bitmaps_test: 'backstop_data/bitmaps_test',
        html_report: 'backstop_data/html_report',
        ci_report: 'backstop_data/ci_report'
    },
    report: ['browser', 'CI'],
    debug: false,
    engine: 'puppeteer',
    engineOptions: {
        args: ['--no-sandbox']
    },
    asyncCaptureLimit: 5,
    asyncCompareLimit: 50,
    debug: false,
    debugWindow: false
};
