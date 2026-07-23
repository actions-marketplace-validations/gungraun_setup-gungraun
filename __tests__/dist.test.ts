import * as fs from 'fs';

describe('distribution bundle', () => {
    it('when the action is built then @actions/github is bundled', () => {
        const bundle = fs.readFileSync('dist/index.js', 'utf8');

        expect(bundle).not.toContain("Cannot find module '@actions/github'");
    });
});
