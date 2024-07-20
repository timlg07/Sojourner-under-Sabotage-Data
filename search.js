/** @type {Array<{eventType: string, timestamp: number, user: string, data: any}>} */
const data = require('./data.pretty.json');
const save = require('./utils/save');

const searchConfig = {
    username: 'garan358',
    eventTypes: [
        'test-executed', 'ComponentTestsActivatedEvent', 'ComponentTestsExtendedEvent',
        'ComponentDestroyedEvent', 'MutatedComponentTestsFailedEvent'
    ],
    componentName: 'Engine'
}

const searchResults = data.filter(item => {
    if (searchConfig.username && item.user !== searchConfig.username) return false;
    if (searchConfig.eventType && item.eventType !== searchConfig.eventType) return false;
    if (searchConfig.componentName && item.data.componentName !== searchConfig.componentName) return false;
    if (searchConfig.eventTypes && !searchConfig.eventTypes.includes(item.eventType)) return false;
    return true;
}).sort((a, b) => a.timestamp - b.timestamp);

save('searchResult.json', searchResults);
