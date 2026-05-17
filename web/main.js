/**
 * Pong Wars — Zig + WASM
 * Automated territory battle between two bouncing balls.
 */

const consoleOutput = document.getElementById("console-output");
const loadingOverlay = document.getElementById("loading-overlay");
const fpsCounter = document.getElementById("fps-counter");
const statusText = document.getElementById("status-text");

function log(msg, type = "info") {
    const prefix = type === "error" ? "[ERR]" : ">";
    const line = document.createElement("p");
    line.className = `log-line ${type === 'error' ? 'text-pink' : ''}`;
    line.innerText = `${prefix} ${msg}`;
    consoleOutput.appendChild(line);
    consoleOutput.scrollTop = consoleOutput.scrollHeight;
}

async function initApp() {
    log("Fetching pong-wars.wasm bytes...");

    try {
        const canvas = document.getElementById("pong-canvas");
        const ctx = canvas.getContext("2d", { alpha: false });

        const width = 800;
        const height = 600;

        log("Connecting WebAssembly runtime...");
        const response = await fetch("pong-wars.wasm");
        if (!response.ok) {
            throw new Error(`Failed to fetch WebAssembly binary: ${response.statusText}`);
        }

        const buffer = await response.arrayBuffer();
        log("Compiling freestanding binary...");
        const module = await WebAssembly.compile(buffer);

        log("Instantiating memory segment...");
        const instance = await WebAssembly.instantiate(module, { env: {} });

        log("Wasm binary successfully linked.");

        instance.exports.init();
        log("Pong Wars engine ONLINE.");

        const memory = instance.exports.memory;
        const bufferPtr = instance.exports.get_buffer_ptr();

        log(`Buffer base address resolved: 0x${bufferPtr.toString(16)}`);

        const pixelData = new Uint8ClampedArray(
            memory.buffer,
            bufferPtr,
            width * height * 4
        );

        const imageData = new ImageData(pixelData, width, height);

        loadingOverlay.classList.add("hidden");
        statusText.innerText = "TWO BALLS // NO PADDLES // PURE TERRITORY";
        log("Territory battle loop started.");

        let lastTime = performance.now();
        let frameCount = 0;
        let fpsTimer = 0;

        function renderLoop(currentTime) {
            const realDt = (currentTime - lastTime) / 1000.0;
            lastTime = currentTime;

            frameCount++;
            fpsTimer += realDt;
            if (fpsTimer >= 0.5) {
                const currentFps = Math.round(frameCount / fpsTimer);
                fpsCounter.innerText = `${currentFps} FPS`;
                frameCount = 0;
                fpsTimer = 0;
            }

            instance.exports.update(currentTime);
            ctx.putImageData(imageData, 0, 0);
            requestAnimationFrame(renderLoop);
        }

        requestAnimationFrame(renderLoop);

    } catch (err) {
        log(`CRITICAL BOOT ERROR: ${err.message}`, "error");
        statusText.innerText = "KERNEL PANIC";
        statusText.style.color = "#f857a6";
        document.querySelector(".status-indicator").style.backgroundColor = "#f857a6";
        document.querySelector(".status-indicator").style.boxShadow = "0 0 10px #f857a6";
        console.error(err);
    }
}

window.addEventListener("DOMContentLoaded", initApp);
