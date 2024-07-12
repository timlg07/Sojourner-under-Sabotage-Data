const save = require('../utils/save');
/** @type {Array<{eventType: string, timestamp: number, user: string, data: any}>} */
const data = require('../data.pretty.json');

const events = ['ComponentDestroyedEvent', 'MutatedComponentTestsFailedEvent'];
const destroyedOrAlarm = data.filter(item => events.includes(item.eventType)).reduce((acc, item) => {
    if (!acc[item.user]) {
        acc[item.user] = {};
    }
    acc[item.user][item.data.componentName] = item.eventType === 'ComponentDestroyedEvent' ? 'destroyed' : 'alarm';
    return acc;
}, {});

save('../destroyedOrAlarm.json', destroyedOrAlarm);

const destroyedOrAlarmPerComponent = Object.values(destroyedOrAlarm).reduce((acc, item) => {
    Object.entries(item).forEach(([component, status]) => {
        if (!acc[component]) {
            acc[component] = {destroyed: 0, alarm: 0};
        }
        acc[component][status]++;
    });
    return acc;
}, {});

save('../destroyedOrAlarmPerComponent.json', destroyedOrAlarmPerComponent);
