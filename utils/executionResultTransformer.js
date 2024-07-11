const executionResultTransformer = {
    /**
     * Transforms the execution result into a coverage object
     *
     * @param {Object} execRes
     * @param {string?} componentName
     * @returns {{totalLines: number, coveredLines: number, fraction: number}}
     */
    execRes2Coverage: (execRes, componentName) => {
        const c = componentName ?? execRes.testClassName.replace('Test', '');
        const extractCurrentCompCoverage = (acc, item) => item[0].includes(c) ? item[1] : acc;
        const coveredLines = Object.entries(execRes.coveredLines).reduce(extractCurrentCompCoverage, {});
        const totalLines = Object.entries(execRes.totalLines).reduce(extractCurrentCompCoverage, {});
        return {coveredLines, totalLines, fraction: coveredLines / totalLines};
    }
}

module.exports = executionResultTransformer;
