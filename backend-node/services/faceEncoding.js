import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export async function generateFaceEncoding(imagePath) {
  return new Promise((resolve, reject) => {
    const pythonScript = join(__dirname, '..', '..', 'mini_pc_client', 'generate_encoding.py');

    if (!fs.existsSync(pythonScript)) {
      return reject(new Error('Face encoding script not found'));
    }

    const python = spawn('python', [pythonScript, imagePath]);

    let output = '';
    let errorOutput = '';

    python.stdout.on('data', (data) => {
      output += data.toString();
    });

    python.stderr.on('data', (data) => {
      errorOutput += data.toString();
    });

    python.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`Failed to generate encoding: ${errorOutput}`));
        return;
      }

      try {
        const encoding = JSON.parse(output.trim());
        resolve(encoding);
      } catch (err) {
        reject(new Error('Invalid encoding output'));
      }
    });

    setTimeout(() => {
      python.kill();
      reject(new Error('Face encoding generation timeout'));
    }, 30000);
  });
}
