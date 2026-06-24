import { spawn } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let mlProcess = null;

export function startMLService() {
  // Bỏ qua việc tự spawn Python process nếu sử dụng service ML ngoài (như trong Docker)
  if (process.env.ML_SERVICE_URL || process.env.SKIP_ML_SPAWN === 'true') {
    console.log(`🤖 [ML Manager] ML Python Service is running externally at: ${process.env.ML_SERVICE_URL || 'Configured URL'}. Skipping local spawn.`);
    return;
  }

  const rootDir = path.join(__dirname, '../../');
  const appPyPath = path.join(rootDir, 'ml/app.py');
  
  // Determine Python path (check local venv first)
  let pythonPath = 'python';
  const venvPythonWindows = path.join(rootDir, 'venv/Scripts/python.exe');
  const venvPythonUnix = path.join(rootDir, 'venv/bin/python');
  
  if (fs.existsSync(venvPythonWindows)) {
    pythonPath = venvPythonWindows;
  } else if (fs.existsSync(venvPythonUnix)) {
    pythonPath = venvPythonUnix;
  }
  
  console.log(`🤖 [ML Manager] Starting ML Python Service using: ${pythonPath}`);
  
  mlProcess = spawn(pythonPath, [appPyPath], {
    cwd: rootDir,
    stdio: 'inherit', // Pipe python stdout/stderr directly to Node console for debug logs
    detached: false
  });
  
  mlProcess.on('error', (err) => {
    console.error('❌ [ML Manager] Failed to start ML Python Service:', err.message);
  });
  
  mlProcess.on('close', (code) => {
    console.log(`🤖 [ML Manager] ML Python Service stopped with code ${code}`);
  });
  
  // Kill child process when parent Node process exits
  process.on('exit', () => {
    if (mlProcess) {
      mlProcess.kill();
    }
  });
  
  // Handle Ctrl+C or kill signals to ensure child process dies
  const signals = ['SIGINT', 'SIGTERM', 'SIGQUIT'];
  signals.forEach(sig => {
    process.on(sig, () => {
      if (mlProcess) {
        mlProcess.kill();
      }
      process.exit();
    });
  });
}
