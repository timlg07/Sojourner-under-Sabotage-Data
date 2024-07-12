const save = require('../utils/save');
const {execRes2Coverage} = require('../utils/executionResultTransformer');
/** @type {Array<{eventType: string, timestamp: number, user: string, data: any}>} */
const data = require('../data.pretty.json');
const isInRange = ({timestamp}, {startTime, endTime}) => timestamp >= startTime && timestamp <= endTime;
const events = ['DebugStartEvent', 'ComponentFixedEvent', 'cut-modified', 'ComponentTestsExtendedEvent', 'test-executed'];// ignore 'test-execution-failed' because there were no fails during debugging
const _attemptsUntilFixed = data
    .filter(item => events.includes(item.eventType))
    .reduce((acc, item) => {
        const c = item.data.componentName;
        if (!acc[item.user]) {
            acc[item.user] = {};
        }
        if (!acc[item.user][c]) {
            acc[item.user][c] = {
                startTime: 0,
                endTime: Number.POSITIVE_INFINITY,
                modifications: [],
                executions: [],
                hiddenTestsAdded: []
            }
        }

        if (item.eventType === 'DebugStartEvent') {
            acc[item.user][c].startTime = item.timestamp;
        }

        if (item.eventType === 'ComponentFixedEvent') {
            acc[item.user][c].endTime = item.timestamp;
        }

        if (item.eventType === 'cut-modified') {
            acc[item.user][c].modifications.push(item);
        }

        if (item.eventType === 'test-executed') {
            // do not add final execution(s) that fixed the component
            if (item.data.executionResult.testStatus === 'FAILED'
                || item.data.executionResult.hiddenTestsPassed === false) {
                acc[item.user][c].executions.push(item);
            }
        }

        if (item.eventType === 'ComponentTestsExtendedEvent') {
            acc[item.user][c].hiddenTestsAdded.push(item);
        }

        return acc;
    }, {});

const prettifyModificationInfo = (mod) => {
    return {
        timestamp: mod.timestamp,
        patch: mod.data.patch
    };
}

const prettifyExecutionInfo = (exec) => {
    return {
        timestamp: exec.timestamp,
        //executionResult: exec.data.executionResult,
        //coverage: execRes2Coverage(exec.data.executionResult),
        //testStatus: exec.data.executionResult.testStatus,
        //hiddenTestsPassed: exec.data.executionResult.hiddenTestsPassed,
    };
}

const prettifyHiddenTestsAddedInfo = (hid) => {
    return {
        timestamp: hid.timestamp,
        hiddenTests: hid.data.addedTestMethodName
    };
}

const removeConsecutiveDuplicates = (eqMap) => {
    return [(acc, item) => {
        if (acc.length === 0 || eqMap(acc[acc.length - 1]) !== eqMap(item)) {
            acc.push(item);
        }
        return acc;
    }, []];
}

const attemptsUntilFixed = Object.entries(_attemptsUntilFixed).reduce((acc, [user, v]) => {
    acc[user] = Object.entries(v).reduce((acc, [c, item]) => {
        if (item.endTime === Number.POSITIVE_INFINITY) {
            acc[c] = 'not fixed';
            return acc;
        }
        acc[c] = {
            deltaTime: item.endTime - item.startTime,
            modifications: item.modifications
                               .filter(m => isInRange(m, item))
                                // removes a total of 4 duplicate modifications:
                               .reduce(...removeConsecutiveDuplicates(({data}) => data.patch))
                               .map(prettifyModificationInfo),
            executions: item.executions
                            .filter(e => isInRange(e, item))
                            .map(prettifyExecutionInfo),
            hiddenTestsAdded: item.hiddenTestsAdded
                                .filter(h => isInRange(h, item))
                                .map(prettifyHiddenTestsAddedInfo)
        };
        return acc;
    }, {});
    return acc;
}, {});

save('../attemptsUntilFixed_detailed.json', attemptsUntilFixed);

const attemptsUntilFixedSummary = Object.entries(attemptsUntilFixed).reduce((acc, [user, v]) => {
    acc[user] = Object.entries(v).reduce((acc, [c, item]) => {
        if (item === 'not fixed') {
            acc[c] = 'not fixed';
            return acc;
        }
        acc[c] = {
            deltaTime: item.deltaTime / 1e3 / 60,
            modifications: item.modifications.length,
            executions: item.executions.length + 1, // add final execution that fixed the component back in
            hiddenTestsAdded: item.hiddenTestsAdded.length
        };
        return acc;
    }, {});
    return acc;
}, {});

save('../attemptsUntilFixed_summary.json', attemptsUntilFixedSummary);
