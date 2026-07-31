import { execFileSync } from 'child_process';
import { chmodSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';

function writeExecutable(path: string, contents: string): void {
    writeFileSync(path, contents);
    chmodSync(path, 0o755);
}

describe('source-valgrind-versions.sh', () => {
    let directory: string;

    beforeEach(() => {
        directory = mkdtempSync(join(tmpdir(), 'source-valgrind-versions-'));
    });

    afterEach(() => {
        rmSync(directory, { recursive: true, force: true });
    });

    it('when git succeeds then uses the Sourceware git transport', () => {
        const argumentsFile = join(directory, 'git-arguments');
        writeExecutable(
            join(directory, 'git'),
            `#!/usr/bin/env sh\nprintf '%s\\n' "$*" > "${argumentsFile}"\nprintf 'abc123\\trefs/tags/VALGRIND_3_27_1\\n'\n`
        );

        const output = execFileSync('./scripts/source-valgrind-versions.sh', {
            encoding: 'utf8',
            env: { ...process.env, PATH: `${directory}:${process.env.PATH}` }
        });

        expect(output.trim()).toBe('3.27.1');
        expect(readFileSync(argumentsFile, 'utf8').trim()).toBe(
            'ls-remote git://sourceware.org/git/valgrind.git'
        );
    });

    it('when git repeatedly fails then sleeps between attempts', () => {
        const sleepsFile = join(directory, 'sleeps');
        writeExecutable(join(directory, 'git'), '#!/usr/bin/env sh\necho "HTTP 429" >&2\nexit 1\n');
        writeExecutable(
            join(directory, 'sleep'),
            `#!/usr/bin/env sh\nprintf '%s\\n' "$1" >> "${sleepsFile}"\n`
        );

        expect(() =>
            execFileSync('./scripts/source-valgrind-versions.sh', {
                encoding: 'utf8',
                env: { ...process.env, PATH: `${directory}:${process.env.PATH}` },
                stdio: 'pipe'
            })
        ).toThrow();

        expect(readFileSync(sleepsFile, 'utf8').trim().split('\n')).toHaveLength(4);
    });
});
