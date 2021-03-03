import { execSync } from 'child_process';

export default () => execSync("which google-chrome-stable").toString().slice(0, -1);
