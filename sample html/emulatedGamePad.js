/**
 * EmulatedGamePad.js - Virtual gamepad controller for web games
 * Inspired by joy.js (https://github.com/bobboteck/JoyStick)
 */

// Core utility functions
const createElement = (tag, prop) => Object.assign(document.createElement(tag), prop);
const TAU = Math.PI * 2;
const normalize = (rad) => rad - TAU * Math.floor(rad / TAU);

// Controller State interface
class ControllerState {
    constructor() {
        this.isActive = false;
        this.isPressed = false;
        this.value = 0;
        this.angle = 0;
        this.x = 0;
        this.y = 0;
        this.identifier = -1;
    }
}

/**
 * Canvas-based Joystick controller
 */
class CanvasJoystick {
    constructor(options) {
        this.options = Object.assign({
            id: "joystick",
            container: document.body,
            radius: 50,
            backgroundFill: "rgba(100, 100, 100, 0.5)",
            backgroundStroke: "#333333",
            stickFill: "rgba(200, 200, 200, 0.8)",
            stickStroke: "#666666",
            lineWidth: 2,
            autoReturn: true,  // We'll override this for the right joystick
            deadZone: 0.1, 
            onMove: null,
            onStart: null,
            onEnd: null,
            followTouch: true,
            returnToBase: true, // We'll override this for the right joystick
            surroundingButtons: [], // New property for surrounding buttons
            stickReturnsToCenter: true // New property to control stick centering
        }, options);

        this.container = typeof this.options.container === 'string' 
            ? document.querySelector(this.options.container)
            : this.options.container;
            
        this.state = new ControllerState();
        this.initialX = 0; // Add tracking for initial touch position
        this.initialY = 0;
        this.setupCanvas();
        this.setupEvents();
    }

    setupCanvas() {
        this.pixelRatio = window.devicePixelRatio || 1;
        const padding = this.options.radius * 0.4;
        this.canvas = document.createElement('canvas');
        this.canvas.id = this.options.id;
        const cssWidth = this.options.radius * 2;
        const cssHeight = this.options.radius * 2;
        this.canvas.style.width = `${cssWidth}px`;
        this.canvas.style.height = `${cssHeight}px`;
        this.canvas.width = Math.round((cssWidth + padding * 2) * this.pixelRatio);
        this.canvas.height = Math.round((cssHeight + padding * 2) * this.pixelRatio);
        this.canvas.style.touchAction = 'none';
        this.canvas.style.msTouchAction = 'none';
        this.canvas.style.userSelect = 'none';
        this.canvas.style.webkitUserSelect = 'none';
        this.canvas.style.position = 'absolute';
        this.canvas.style.zIndex = '100';
        this.container.appendChild(this.canvas);
        this.context = this.canvas.getContext('2d');
        this.context.scale(this.pixelRatio, this.pixelRatio);
        this.centerX = cssWidth / 2 + padding;
        this.centerY = cssHeight / 2 + padding;
        this.movedX = this.centerX;
        this.movedY = this.centerY;
        this.baseX = parseFloat(this.canvas.style.left) || 0;
        this.baseY = parseFloat(this.canvas.style.top) || 0;
        this.canvas.style.marginLeft = `-${padding}px`;
        this.canvas.style.marginTop = `-${padding}px`;
        this.maxDistance = this.options.radius * 0.7;
        this.draw();
    }

    setupEvents() {
        this.touchId = null;
        this.isPressed = false;
        this.canvas.addEventListener('touchstart', this.onTouchStart.bind(this), { passive: false });
        if (this.options.followTouch) {
            this.container.addEventListener('touchstart', this.onContainerTouchStart.bind(this), { passive: false });
        }
        document.addEventListener('touchmove', this.onTouchMove.bind(this), { passive: false });
        document.addEventListener('touchend', this.onTouchEnd.bind(this), { passive: false });
        document.addEventListener('touchcancel', this.onTouchEnd.bind(this), { passive: false });
        this.canvas.addEventListener('mousedown', this.onMouseDown.bind(this), { passive: false });
        if (this.options.followTouch) {
            this.container.addEventListener('mousedown', this.onContainerMouseDown.bind(this), { passive: false });
        }
        document.addEventListener('mousemove', this.onMouseMove.bind(this), { passive: false });
        document.addEventListener('mouseup', this.onMouseUp.bind(this), { passive: false });
    }

    onContainerTouchStart(event) {
        if (this.touchId !== null || event.target === this.canvas) return;
        
        const touch = event.touches[0];
        const rect = this.container.getBoundingClientRect();
        const x = touch.clientX - rect.left;
        const y = touch.clientY - rect.top;
        
        // Check if touch is within any surrounding buttons - don't move joystick if it is
        if (this.options.surroundingButtons && this.options.surroundingButtons.length > 0) {
            // Don't move joystick if touch is on a button
            if (this.isTouchWithinButtons(x, y)) {
                return;
            }
        }
        
        this.moveJoystickBase(x, y);
        this.onTouchStart(event);
    }
    
    onContainerMouseDown(event) {
        if (this.isPressed || event.target === this.canvas) return;
        const rect = this.container.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;
        
        // Check if click is within any surrounding buttons - don't move joystick if it is
        if (this.options.surroundingButtons && this.options.surroundingButtons.length > 0) {
            // Don't move joystick if click is on a button
            if (this.isTouchWithinButtons(x, y)) {
                return;
            }
        }
        
        this.moveJoystickBase(x, y);
        this.onMouseDown(event);
    }
    
    moveJoystickBase(x, y) {
        // Get the important dimensions
        const radius = this.options.radius;
        const padding = radius * 0.4;
        
        // Calculate buffer to keep joystick fully visible within container
        const buffer = radius;
        const maxX = this.container.clientWidth - buffer;
        const maxY = this.container.clientHeight - buffer;
        
        // Ensure x,y are within bounds
        x = Math.max(buffer, Math.min(x, maxX));
        y = Math.max(buffer, Math.min(y, maxY));
        var half = radius/2 + padding/4;
        // IMPORTANT FIX: Use exactly the same positioning logic as setPosition
        // The issue was that we weren't using string px values consistently
        this.canvas.style.left = `${x - half}px`;
        this.canvas.style.top = `${y - half}px`;
        
        // Store the actual position for reference (needs to be the same format)
        this.originalPosition = { 
            left: `${x - half}px`, 
            top: `${y - half}px` 
        };
        
        // Update internal position tracking
        this.baseX = x - radius;  // Store numeric value without px
        this.baseY = y - radius;  // Store numeric value without px
        
        // Reset stick to center of joystick
        this.movedX = this.centerX;
        this.movedY = this.centerY;
        this.draw();

        // Reset initial position for movement calculation
        this.initialX = 0;
        this.initialY = 0;

        // Also update surrounding buttons to be centered on the same tap point
        if (this.options.surroundingButtons && this.options.surroundingButtons.length > 0) {
            this.updateSurroundingButtonPositions(x, y);
        }
    }

    isTouchWithinButtons(x, y) {
        if (!this.options.surroundingButtons) return false;
        
        for (const button of this.options.surroundingButtons) {
            // Get button position and dimensions
            const left = parseFloat(button.canvas.style.left) || 0;
            const top = parseFloat(button.canvas.style.top) || 0;
            const width = parseFloat(button.canvas.style.width) || 0;
            const height = parseFloat(button.canvas.style.height) || 0;
            
            // Check if point is within button (accounting for circular shape)
            const centerX = left + width / 2;
            const centerY = top + height / 2;
            const distance = Math.sqrt(Math.pow(x - centerX, 2) + Math.pow(y - centerY, 2));
            
            // If distance is less than button radius, touch is within button
            if (distance <= button.options.radius) {
                return true;
            }
        }
        
        return false;
    }

    updateSurroundingButtonPositions(centerX, centerY) {
        // If this is the right joystick, use our special layout function
        if (this.options.id === "right-joystick" && this.options.surroundingButtons.length > 0) {
            // Find the VirtualGamepadUI instance
            let ui = null;
            for (let prop in window) {
                if (window[prop] instanceof VirtualGamepadUI) {
                    ui = window[prop];
                    break;
                }
            }
            
            if (ui) {
                ui.positionButtonsAroundJoystick(this.options.surroundingButtons, centerX, centerY, this.options.radius * 1.2);
                return;
            }
        }
        
        // For other joysticks, use the original positioning logic
        const angles = [
            Math.PI * 0.5,   // North (top)
            Math.PI * 0.0,   // East (right)
            Math.PI * 1.5,   // South (bottom)
            Math.PI * 1.0    // West (left)
        ];
        
        const buttonDistance = this.options.radius * 2;
        
        // Use the minimum between array length and angles length
        const count = Math.min(this.options.surroundingButtons.length, angles.length);
        
        for (let i = 0; i < count; i++) {
            const button = this.options.surroundingButtons[i];
            const angle = angles[i];
            const buttonX = centerX + buttonDistance * Math.cos(angle);
            const buttonY = centerY + buttonDistance * Math.sin(angle);
            
            // Position the button, centering it at the calculated position
            button.setPosition(
                `${buttonX - button.options.radius}px`, 
                `${buttonY - button.options.radius}px`
            );
        }
    }

    draw() {
        this.context.clearRect(0, 0, this.canvas.width / this.pixelRatio, this.canvas.height / this.pixelRatio);
        this.context.imageSmoothingEnabled = true;
        this.context.imageSmoothingQuality = 'high';
        this.context.beginPath();
        this.context.arc(this.centerX, this.centerY, this.options.radius - this.options.lineWidth, 0, TAU, false);
        this.context.fillStyle = this.options.backgroundFill;
        this.context.fill();
        this.context.lineWidth = this.options.lineWidth;
        this.context.strokeStyle = this.options.backgroundStroke;
        this.context.stroke();
        const innerRadius = this.options.radius * 0.4;
        this.context.beginPath();
        this.context.arc(this.movedX, this.movedY, innerRadius, 0, TAU, false);
        this.context.fillStyle = this.options.stickFill;
        this.context.fill();
        this.context.lineWidth = this.options.lineWidth;
        this.context.strokeStyle = this.options.stickStroke;
        this.context.stroke();
    }

    onTouchStart(event) {
        event.preventDefault();
        if (this.touchId !== null) return;
        const touch = event.targetTouches[0];
        this.touchId = touch.identifier;
        this.isPressed = true;
        
        // Record the initial touch position for relative movement calculation
        const rect = this.canvas.getBoundingClientRect();
        this.initialX = touch.clientX - rect.left;
        this.initialY = touch.clientY - rect.top;
        
        this.state.isActive = true;
        this.state.isPressed = true;
        this.state.identifier = this.touchId;
        if (this.options.onStart) {
            this.options.onStart(this.state);
        }
    }

    onTouchMove(event) {
        if (!this.isPressed) return;
        let touchFound = false;
        let touch;
        for (let i = 0; i < event.changedTouches.length; i++) {
            if (event.changedTouches[i].identifier === this.touchId) {
                touchFound = true;
                touch = event.changedTouches[i];
                break;
            }
        }
        if (!touchFound) return;
        event.preventDefault();
        const rect = this.canvas.getBoundingClientRect();
        const x = touch.clientX - rect.left;
        const y = touch.clientY - rect.top;
        this.updateJoystickPosition(x, y);
    }

    onTouchEnd(event) {
        let touchFound = false;
        for (let i = 0; i < event.changedTouches.length; i++) {
            if (event.changedTouches[i].identifier === this.touchId) {
                touchFound = true;
                break;
            }
        }
        if (!touchFound) return;
        this.touchId = null;
        this.isPressed = false;
        
        // Explicitly reset initial position tracking
        this.initialX = 0;
        this.initialY = 0;
        
        this.resetJoystick();
    }

    onMouseDown(event) {
        event.preventDefault();
        this.isPressed = true;
        
        // Record the initial mouse position for relative movement calculation
        const rect = this.canvas.getBoundingClientRect();
        this.initialX = event.clientX - rect.left;
        this.initialY = event.clientY - rect.top;
        
        this.state.isActive = true;
        this.state.isPressed = true;
        this.state.identifier = 1;
        if (this.options.onStart) {
            this.options.onStart(this.state);
        }
    }

    onMouseMove(event) {
        if (!this.isPressed) return;
        event.preventDefault();
        const rect = this.canvas.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;
        this.updateJoystickPosition(x, y);
    }

    onMouseUp(event) {
        if (!this.isPressed) return;
        this.isPressed = false;
        
        // Explicitly reset initial position tracking
        this.initialX = 0;
        this.initialY = 0;
        
        this.resetJoystick();
    }

    updateJoystickPosition(x, y) {
        let deltaX, deltaY;
        
        // If we have an initial position, use it as the reference point
        if (this.initialX !== 0 || this.initialY !== 0) {
            deltaX = x - this.initialX;
            deltaY = y - this.initialY;
        } else {
            // Fall back to center-based calculation if no initial position
            deltaX = x - this.centerX;
            deltaY = y - this.centerY;
        }
        
        const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
        const angle = Math.atan2(deltaY, deltaX);
        
        if (distance < this.maxDistance * this.options.deadZone) {
            if (!this.options.autoReturn) {
                return;
            }
        }
        
        let limitedDistance;
        if (distance > this.maxDistance) {
            limitedDistance = this.maxDistance;
        } else {
            limitedDistance = distance;
        }
        
        // Calculate visual position of the stick (centered on the joystick)
        this.movedX = this.centerX + limitedDistance * Math.cos(angle);
        this.movedY = this.centerY + limitedDistance * Math.sin(angle);
        
        // Calculate normalized control values (-1 to 1)
        this.state.x = limitedDistance * Math.cos(angle) / this.maxDistance;
        this.state.y = limitedDistance * Math.sin(angle) / this.maxDistance;
        this.state.angle = angle;
        this.state.value = limitedDistance / this.maxDistance;
        
        this.draw();
        
        if (this.options.onMove) {
            this.options.onMove(this.state);
        }
    }

    resetJoystick() {
        // Determine if the stick should return to center
        const shouldReturnToCenter = this.options.stickReturnsToCenter !== false;
        
        // For right joystick, don't return to base position, but DO reset the stick to center
        const shouldReturnToBase = this.options.id === "right-joystick" ? false : 
                                  (this.options.followTouch && this.options.returnToBase);
        
        // Always reset the stick to center position (visual element)
        if (shouldReturnToCenter) {
            this.movedX = this.centerX;
            this.movedY = this.centerY;
            
            // Reset initial touch tracking to prevent drift on next touch
            this.initialX = 0;
            this.initialY = 0;
            
            this.state.x = 0;
            this.state.y = 0;
            this.state.angle = 0;
            this.state.value = 0;
            this.state.isActive = false;
            this.state.isPressed = false;
            
            this.draw();
        }
        
        // Return the entire joystick to its original position if needed
        if (shouldReturnToBase) {
            this.canvas.style.transition = 'left 0.2s ease, top 0.2s ease';
            if (this.originalPosition) {
                this.canvas.style.left = this.originalPosition.left;
                this.canvas.style.top = this.originalPosition.top;
            }
            setTimeout(() => {
                this.canvas.style.transition = '';
            }, 200);
        }
        
        if (this.options.onEnd) {
            this.options.onEnd(this.state);
        }
    }

    setPosition(left, top) {
        this.canvas.style.left = left;
        this.canvas.style.top = top;
        this.originalPosition = { left, top };
    }

    destroy() {
        this.canvas.removeEventListener('touchstart', this.onTouchStart);
        if (this.options.followTouch) {
            this.container.removeEventListener('touchstart', this.onContainerTouchStart);
            this.container.removeEventListener('mousedown', this.onContainerMouseDown);
        }
        document.removeEventListener('touchmove', this.onTouchMove);
        document.removeEventListener('touchend', this.onTouchEnd);
        document.removeEventListener('touchcancel', this.onTouchEnd);
        this.canvas.removeEventListener('mousedown', this.onMouseDown);
        document.removeEventListener('mousemove', this.onMouseMove);
        document.removeEventListener('mouseup', this.onMouseUp);
        this.container.removeChild(this.canvas);
    }
}

/**
 * Canvas-based Button controller
 */
class CanvasButton {
    constructor(options) {
        this.options = Object.assign({
            id: "button",
            container: document.body,
            radius: 40,
            text: "",
            textColor: "#FFFFFF",
            fontSize: 16,
            backgroundFillActive: "rgba(220, 220, 220, 0.8)",
            backgroundFillInactive: "rgba(100, 100, 100, 0.5)",
            backgroundStroke: "#333333",
            lineWidth: 2,
            autoRelease: true,
            releaseTime: 300, // ms for auto-release if enabled
            onPress: null,
            onRelease: null
        }, options);

        this.container = typeof this.options.container === 'string' 
            ? document.querySelector(this.options.container)
            : this.options.container;
            
        this.state = new ControllerState();
        this.setupCanvas();
        this.setupEvents();
    }

    setupCanvas() {
        this.pixelRatio = window.devicePixelRatio || 1;
        this.canvas = document.createElement('canvas');
        this.canvas.id = this.options.id;
        const cssWidth = this.options.radius * 2;
        const cssHeight = this.options.radius * 2;
        this.canvas.style.width = `${cssWidth}px`;
        this.canvas.style.height = `${cssHeight}px`;
        this.canvas.width = Math.round(cssWidth * this.pixelRatio);
        this.canvas.height = Math.round(cssHeight * this.pixelRatio);
        this.canvas.style.touchAction = 'none';
        this.canvas.style.msTouchAction = 'none';
        this.canvas.style.userSelect = 'none';
        this.canvas.style.webkitUserSelect = 'none';
        this.canvas.style.position = 'absolute';
        this.canvas.style.zIndex = '100';
        this.container.appendChild(this.canvas);
        this.context = this.canvas.getContext('2d');
        this.context.scale(this.pixelRatio, this.pixelRatio);
        this.centerX = cssWidth / 2;
        this.centerY = cssHeight / 2;
        this.isActive = false;
        this.draw();
    }

    setupEvents() {
        this.touchId = null;
        this.releaseTimer = null;
        this.canvas.addEventListener('touchstart', this.onTouchStart.bind(this), { passive: false });
        document.addEventListener('touchend', this.onTouchEnd.bind(this), { passive: false });
        document.addEventListener('touchcancel', this.onTouchEnd.bind(this), { passive: false });
        this.canvas.addEventListener('mousedown', this.onMouseDown.bind(this), { passive: false });
        document.addEventListener('mouseup', this.onMouseUp.bind(this), { passive: false });
        this.canvas.addEventListener('contextmenu', (e) => e.preventDefault());
    }

    draw() {
        this.context.clearRect(0, 0, this.canvas.width / this.pixelRatio, this.canvas.height / this.pixelRatio);
        this.context.imageSmoothingEnabled = true;
        this.context.imageSmoothingQuality = 'high';
        this.context.beginPath();
        this.context.arc(this.centerX, this.centerY, this.options.radius - this.options.lineWidth, 0, TAU, false);
        this.context.fillStyle = this.isActive ? this.options.backgroundFillActive : this.options.backgroundFillInactive;
        this.context.fill();
        this.context.lineWidth = this.options.lineWidth;
        this.context.strokeStyle = this.options.backgroundStroke;
        this.context.stroke();
        if (this.options.text) {
            this.context.font = `bold ${this.options.fontSize}px Arial, sans-serif`;
            this.context.fillStyle = this.options.textColor;
            this.context.textAlign = 'center';
            this.context.textBaseline = 'middle';
            this.context.fillText(this.options.text, this.centerX, this.centerY);
        }
    }

    onTouchStart(event) {
        event.preventDefault();
        if (this.touchId !== null) return;
        const touch = event.targetTouches[0];
        this.touchId = touch.identifier;
        this.setActive(true);
        if (this.options.autoRelease) {
            if (this.releaseTimer) {
                clearTimeout(this.releaseTimer);
            }
            this.releaseTimer = setTimeout(() => {
                this.setActive(false);
            }, this.options.releaseTime);
        }
    }

    onTouchEnd(event) {
        let touchFound = false;
        for (let i = 0; i < event.changedTouches.length; i++) {
            if (event.changedTouches[i].identifier === this.touchId) {
                touchFound = true;
                break;
            }
        }
        if (!touchFound) return;
        this.touchId = null;
        this.setActive(false);
    }

    onMouseDown(event) {
        event.preventDefault();
        this.setActive(true);
        if (this.options.autoRelease) {
            if (this.releaseTimer) {
                clearTimeout(this.releaseTimer);
            }
            this.releaseTimer = setTimeout(() => {
                this.setActive(false);
            }, this.options.releaseTime);
        }
    }

    onMouseUp(event) {
        this.setActive(false);
    }

    setActive(active) {
        this.isActive = active;
        this.state.isActive = active;
        this.state.isPressed = active;
        this.state.value = active ? 1 : 0;
        this.draw();
        if (active && this.options.onPress) {
            this.options.onPress(this.state);
        } else if (!active && this.options.onRelease) {
            this.options.onRelease(this.state);
        }
    }

    setPosition(left, top) {
        this.canvas.style.left = left;
        this.canvas.style.top = top;
    }

    destroy() {
        if (this.releaseTimer) {
            clearTimeout(this.releaseTimer);
            this.releaseTimer = null;
        }
        this.canvas.removeEventListener('touchstart', this.onTouchStart);
        document.removeEventListener('touchend', this.onTouchEnd);
        document.removeEventListener('touchcancel', this.onTouchEnd);
        this.canvas.removeEventListener('mousedown', this.onMouseDown);
        document.removeEventListener('mouseup', this.onMouseUp);
        this.container.removeChild(this.canvas);
    }
}

/**
 * EmulatedGamepad class - simulates a standard gamepad
 */
class EmulatedGamepad {
    constructor() {
        this.config = null;
        this.emulatedGamepad = null;
        this.originalGetGamepads = null;
        this.indicesFound = false;
        this.buttonCount = 17;
        this.axisCount = 4;
        this.enabled = false;
    }

    configure(config) {
        this.config = config;
        if (this.enabled) {
            this.disable();
        }
        this.enable();
    }

    enable() {
        if (this.enabled) return;
        console.log("EmulatedGamepad: Injecting emulated gamepad");
        this.emulatedGamepad = {
            id: "EmulatedGamepad virtual controller",
            index: 0,
            connected: true,
            timestamp: 0,
            mapping: "standard",
            axes: [0, 0, 0, 0],
            buttons: new Array(this.buttonCount).fill().map(() => ({pressed: false, touched: false, value: 0}))
        };
        this.indicesFound = false;
        this.originalGetGamepads = navigator.getGamepads;
        const self = this;
        navigator.getGamepads = function() {
            if (!self.config || typeof self.config.buttons === "undefined") {
                return self.originalGetGamepads.apply(navigator);
            }
            const originalGamepads = self.originalGetGamepads.apply(navigator);
            if (!self.indicesFound) {
                const gamepadFound = Array.from(originalGamepads).some(gamepad => gamepad !== null);
                if (gamepadFound) self.findGamepadIndices(originalGamepads);
            }
            for(let i = 0; i < self.buttonCount; i++) {
                if(typeof self.config.buttons[i] === "undefined" || typeof self.config.buttons[i].gamepadIndex === "undefined") continue;
                const selectedConfigButton = self.config.buttons[i];
                const gamepadIndex = selectedConfigButton.gamepadIndex;
                const dstIndex = selectedConfigButton.dstIndex;
                if(selectedConfigButton.dstType) { //Axis
                    const button = self.emulatedGamepad.buttons[i];
                    button.pressed = button.touched = (originalGamepads[gamepadIndex].axes[dstIndex] + selectedConfigButton.offset) !== 0;
                    button.value = Math.min(Math.max((originalGamepads[gamepadIndex].axes[dstIndex] * selectedConfigButton.scale) + selectedConfigButton.offset, -1), 1);
                } else { //Button
                    self.emulatedGamepad.buttons[i] = originalGamepads[gamepadIndex].buttons[dstIndex];
                }
                self.emulatedGamepad.timestamp = originalGamepads[gamepadIndex].timestamp;
            }
            for(let i = 0; i < self.axisCount; i++) {
                if(typeof self.config.axes[i] === "undefined" || typeof self.config.axes[i].gamepadIndex === "undefined") continue;
                const selectedConfigAxis = self.config.axes[i];
                const gamepadIndex = selectedConfigAxis.gamepadIndex;
                self.emulatedGamepad.axes[i] = Math.min(Math.max((originalGamepads[gamepadIndex].axes[selectedConfigAxis.dstIndex] * selectedConfigAxis.scale) + selectedConfigAxis.offset, -1), 1);
                self.emulatedGamepad.timestamp = originalGamepads[gamepadIndex].timestamp;
            }
            return [self.emulatedGamepad, null, null, null];
        };
        this.enabled = true;
    }

    disable() {
        if (!this.enabled) return;
        if (this.originalGetGamepads) {
            navigator.getGamepads = this.originalGetGamepads;
            this.originalGetGamepads = null;
        }
        this.emulatedGamepad = null;
        this.indicesFound = false;
        this.enabled = false;
        console.log("EmulatedGamepad: Disabled emulated gamepad");
    }

    findGamepadIndices(originalGamepads) {
        for(let i = 0; i < this.buttonCount; i++) {
            if(typeof this.config.buttons[i].dstID !== "undefined") {
                for(let gamepadIndex = 0; gamepadIndex < originalGamepads.length; gamepadIndex++) {
                    if(originalGamepads[gamepadIndex] !== null && originalGamepads[gamepadIndex].id === this.config.buttons[i].dstID) {
                        this.config.buttons[i].gamepadIndex = gamepadIndex;
                        break;
                    }
                }
            }
        }
        for(let i = 0; i < this.axisCount; i++) {
            if(typeof this.config.axes[i].dstID !== "undefined") {
                for(let gamepadIndex = 0; gamepadIndex < originalGamepads.length; gamepadIndex++) {
                    if(originalGamepads[gamepadIndex] !== null && originalGamepads[gamepadIndex].id === this.config.axes[i].dstID) {
                        this.config.axes[i].gamepadIndex = gamepadIndex;
                        break;
                    }
                }
            }
        }
        console.log("EmulatedGamepad: Gamepad indices found!");
        this.indicesFound = true;
    }
    
    updateButton(buttonIndex, state) {
        if (!this.enabled || !this.emulatedGamepad) return;
        const button = this.emulatedGamepad.buttons[buttonIndex];
        if (button) {
            button.pressed = button.touched = state.isPressed || state.value > 0;
            button.value = typeof state.value === 'number' ? Math.min(Math.max(state.value, 0), 1) : (state.isPressed ? 1 : 0);
            this.emulatedGamepad.timestamp = Date.now();
        }
    }
    
    updateAxis(axisIndex, value) {
        if (!this.enabled || !this.emulatedGamepad) return;
        if (axisIndex >= 0 && axisIndex < this.axisCount) {
            this.emulatedGamepad.axes[axisIndex] = Math.min(Math.max(value, -1), 1);
            this.emulatedGamepad.timestamp = Date.now();
        }
    }
}

/**
 * VirtualGamepadUI - Main controller class
 */
class VirtualGamepadUI {
    constructor(options = {}) {
        this.emulatedGamepad = new EmulatedGamepad();
        this.controllers = [];
        this.options = Object.assign({
            showOnScreenControls: true,
            buttonConfig: {
                a: { index: 0 },
                b: { index: 1 },
                x: { index: 2 },
                y: { index: 3 },
                menu: { index: 16 }
            },
            joystickConfig: {
                left: { 
                    horizontalAxis: 0,
                    verticalAxis: 1
                },
                right: {
                    horizontalAxis: 2,
                    verticalAxis: 3
                }
            }
        }, options);
        
        this.setupVirtualGamepad();
        
        window.addEventListener('resize', () => {
            if (window.resizeTimeout) {
                clearTimeout(window.resizeTimeout);
            }
            window.resizeTimeout = setTimeout(() => {
                if (this.options.showOnScreenControls) {
                    this.setupVirtualGamepad();
                }
            }, 250);
        });
    }
    
    setupVirtualGamepad() {
        this.controllers.forEach(controller => {
            controller.destroy();
        });
        this.controllers = [];
        
        if (!this.options.showOnScreenControls) {
            return;
        }
        
        const el = (sel) => document.querySelector(sel);
        
        const viewportWidth = window.innerWidth;
        const viewportHeight = window.innerHeight;
        
        // Create our container structure
        this.createContainerElements();
        
        const leftContainer = el("#app-left");
        const rightContainer = el("#app-right");
        
        if (!leftContainer || !rightContainer) {
            console.error("Could not find controller containers");
            return;
        }
        
        // Calculate appropriate sizes based on viewport
        const buttonRadius = Math.min(
            Math.max(viewportHeight * 0.04, 20),
            Math.min(viewportWidth, viewportHeight) * 0.05
        );
        
        const joystickRadius = buttonRadius * 2.0;
        
        const self = this;
        
        // Create left joystick
        if (this.options.joystickConfig.left && leftContainer) {
            const leftJoystick = new CanvasJoystick({
                id: "left-joystick",
                container: leftContainer,
                radius: joystickRadius,
                backgroundFill: "rgba(100, 100, 100, 0.5)",
                backgroundStroke: "#333333",
                stickFill: "rgba(255, 255, 255, 0.7)",
                stickStroke: "#666666",
                lineWidth: 2,
                followTouch: false,
                returnToBase: true,
                onMove: (state) => {
                    self.emulatedGamepad.updateAxis(
                        self.options.joystickConfig.left.horizontalAxis, 
                        state.x
                    );
                    self.emulatedGamepad.updateAxis(
                        self.options.joystickConfig.left.verticalAxis, 
                        state.y
                    );
                },
                onEnd: () => {
                    self.emulatedGamepad.updateAxis(
                        self.options.joystickConfig.left.horizontalAxis, 
                        0
                    );
                    self.emulatedGamepad.updateAxis(
                        self.options.joystickConfig.left.verticalAxis, 
                        0
                    );
                }
            });
            
            // Position left joystick relative to its container
            const leftX = leftContainer.clientWidth * 0.25;
            const leftY = leftContainer.clientHeight * 0.7;
            
            // Precisely position the joystick so its visual center is at the desired point
            leftJoystick.setPosition(
                `${leftX - joystickRadius}px`, 
                `${leftY - joystickRadius}px`
            );
            this.controllers.push(leftJoystick);
        }
        
        // Create button instances for the right side 
        const rightButtons = [];
        
        // Create and position right joystick
        let rightJoystick = null;
        if (this.options.joystickConfig.right && rightContainer) {
            rightJoystick = new CanvasJoystick({
                id: "right-joystick",
                container: rightContainer,
                radius: joystickRadius,
                backgroundFill: "rgba(100, 100, 100, 0.5)",
                backgroundStroke: "#333333",
                stickFill: "rgba(255, 255, 255, 0.7)",
                stickStroke: "#666666",
                lineWidth: 2,
                followTouch: false,
                returnToBase: false,
                autoReturn: false,
                stickReturnsToCenter: true,
                surroundingButtons: rightButtons,
                onMove: (state) => {
                    self.emulatedGamepad.updateAxis(
                        self.options.joystickConfig.right.horizontalAxis,
                        state.x
                    );
                    self.emulatedGamepad.updateAxis(
                        self.options.joystickConfig.right.verticalAxis,
                        state.y
                    );
                },
                onEnd: () => {
                    self.emulatedGamepad.updateAxis(
                        self.options.joystickConfig.right.horizontalAxis,
                        0
                    );
                    self.emulatedGamepad.updateAxis(
                        self.options.joystickConfig.right.verticalAxis,
                        0
                    );
                }
            });
            
            // Position right joystick on the right side
            const rightX = rightContainer.clientWidth * 0.5;
            const rightY = rightContainer.clientHeight * 0.7;
            
            // Precisely position the joystick so its visual center is at the desired point
            rightJoystick.setPosition(
                `${rightX - joystickRadius}px`, 
                `${rightY - joystickRadius}px`
            );
            
            this.controllers.push(rightJoystick);
        }
        const forceX = false;
        const forceY = false;
        const forceA = false;
        const forceB = false;
        // Create X button first so it appears on the left side of the right joystick
        if (forceX || this.options.buttonConfig.x) {
            const xButton = new CanvasButton({
                id: "x-button",
                container: rightContainer,
                radius: buttonRadius,
                text: "X",
                backgroundFillActive: "rgba(220, 220, 220, 0.8)",
                backgroundFillInactive: "rgba(100, 100, 100, 0.5)",
                onPress: (state) => {
                    self.emulatedGamepad.updateButton(self.options.buttonConfig.x.index, state);
                },
                onRelease: (state) => {
                    self.emulatedGamepad.updateButton(self.options.buttonConfig.x.index, state);
                },
                autoRelease: true
            });
            rightButtons.push(xButton);
            this.controllers.push(xButton);
        }
        
        // Create ABXY buttons in the right container (X is now included)
        if (forceA ||this.options.buttonConfig.a) {
            const aButton = new CanvasButton({
                id: "a-button",
                container: rightContainer,
                radius: buttonRadius,
                text: "A",
                backgroundFillActive: "rgba(220, 220, 220, 0.8)",
                backgroundFillInactive: "rgba(100, 100, 100, 0.5)",
                onPress: (state) => {
                    self.emulatedGamepad.updateButton(self.options.buttonConfig.a.index, state);
                },
                onRelease: (state) => {
                    self.emulatedGamepad.updateButton(self.options.buttonConfig.a.index, state);
                },
                autoRelease: true
            });
            rightButtons.push(aButton);
            this.controllers.push(aButton);
        }
        
        if (forceB ||this.options.buttonConfig.b) {
            const bButton = new CanvasButton({
                id: "b-button",
                container: rightContainer,
                radius: buttonRadius,
                text: "B",
                backgroundFillActive: "rgba(220, 220, 220, 0.8)",
                backgroundFillInactive: "rgba(100, 100, 100, 0.5)",
                onPress: (state) => {
                    self.emulatedGamepad.updateButton(self.options.buttonConfig.b.index, state);
                },
                onRelease: (state) => {
                    self.emulatedGamepad.updateButton(self.options.buttonConfig.b.index, state);
                },
                autoRelease: true
            });
            rightButtons.push(bButton);
            this.controllers.push(bButton);
        }
        
        if (forceY || this.options.buttonConfig.y) {
            const yButton = new CanvasButton({
                id: "y-button",
                container: rightContainer,
                radius: buttonRadius,
                text: "Y",
                backgroundFillActive: "rgba(220, 220, 220, 0.8)",
                backgroundFillInactive: "rgba(100, 100, 100, 0.5)",
                onPress: (state) => {
                    self.emulatedGamepad.updateButton(self.options.buttonConfig.y.index, state);
                },
                onRelease: (state) => {
                    self.emulatedGamepad.updateButton(self.options.buttonConfig.y.index, state);
                },
                autoRelease: true
            });
            rightButtons.push(yButton);
            this.controllers.push(yButton);
        }
        
        // Position buttons - either around joystick or in corner if no joystick
        if (rightButtons.length > 0) {
            if (rightJoystick) {
                // If we have a joystick, position buttons around it
                const joystickRect = rightJoystick.canvas.getBoundingClientRect();
                const joystickCenter = {
                    x: joystickRect.left + joystickRect.width / 2 - rightContainer.getBoundingClientRect().left,
                    y: joystickRect.top + joystickRect.height / 2 - rightContainer.getBoundingClientRect().top
                };
                
                // Position buttons using the dedicated function
                this.positionButtonsAroundJoystick(rightButtons, joystickCenter.x, joystickCenter.y, joystickRadius * 1.2);
            } else {
                // If no joystick, position buttons in the lower right corner in a diamond pattern
                const cornerX = rightContainer.clientWidth * 0.75; 
                const cornerY = rightContainer.clientHeight * 0.85;
                
                // Use a diamond layout with buttons closer together
                this.positionButtonsInBottomCorner(rightButtons, cornerX, cornerY, buttonRadius * 1.5);
            }
        }
        
        // Add menu button
        if (this.options.buttonConfig.menu) {
            const menuButton = new CanvasButton({
                id: "menu-button",
                container: rightContainer,
                radius: buttonRadius * 0.7,
                text: "☰",
                backgroundFillActive: "rgba(220, 220, 220, 0.8)",
                backgroundFillInactive: "rgba(100, 100, 100, 0.5)",
                onPress: (state) => {
                    self.emulatedGamepad.updateButton(self.options.buttonConfig.menu.index, state);
                },
                onRelease: (state) => {
                    self.emulatedGamepad.updateButton(self.options.buttonConfig.menu.index, state);
                },
                autoRelease: false
            });
            
            // Position menu button at top right of right container
            menuButton.setPosition(
                `${rightContainer.clientWidth - buttonRadius * 2 - 10}px`, 
                '10px'
            );
            this.controllers.push(menuButton);
        }
    }
    
    createContainerElements() {
        // Remove old container if it exists to prevent stacking
        const oldContainer = document.querySelector("#virtual-gamepad-container");
        if (oldContainer) {
            oldContainer.remove();
        }
        
        // Create a fresh container structure
        const mainContainer = document.createElement("div");
        mainContainer.id = "virtual-gamepad-container";
        mainContainer.style.cssText = "position: fixed; bottom: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: 100;";
        
        const leftArea = document.createElement("div");
        leftArea.id = "app-left";
        leftArea.style.cssText = "position: absolute; left: 0; bottom: 0; width: 50%; height: 100%; pointer-events: auto;";
        
        const rightArea = document.createElement("div");
        rightArea.id = "app-right";
        rightArea.style.cssText = "position: absolute; right: 0; bottom: 0; width: 50%; height: 100%; pointer-events: auto;";
        
        mainContainer.appendChild(leftArea);
        mainContainer.appendChild(rightArea);
        
        document.body.appendChild(mainContainer);
    }

    positionButtonsAroundJoystick(buttons, centerX, centerY, distance) {
        if (!buttons || buttons.length === 0) return;
        
        // Find buttons by their ID attribute for consistent positioning
        const buttonMap = {
            "y-button": null,
            "b-button": null,
            "a-button": null,
            "x-button": null
        };
        
        // Map buttons to their IDs
        buttons.forEach(button => {
            if (button.canvas && button.canvas.id && buttonMap.hasOwnProperty(button.canvas.id)) {
                buttonMap[button.canvas.id] = button;
            }
        });
        
        // Define fixed positions for each button type
        const positions = [
            { id: "y-button", angle: Math.PI * 0.5 },  // Top (Y)
            { id: "b-button", angle: Math.PI * 0.0 },  // Right (B)
            { id: "a-button", angle: Math.PI * 1.5 },  // Bottom (A)
            { id: "x-button", angle: Math.PI * 1.0 }   // Left (X)
        ];
        
        // Position each button according to the layout
        positions.forEach(pos => {
            const button = buttonMap[pos.id];
            if (button) {
                const buttonX = centerX + distance * Math.cos(pos.angle);
                const buttonY = centerY + distance * Math.sin(pos.angle);
                
                button.setPosition(
                    `${buttonX - button.options.radius}px`,
                    `${buttonY - button.options.radius}px`
                );
            }
        });
    }

    positionButtonsInBottomCorner(buttons, centerX, centerY, spacing) {
        if (!buttons || buttons.length === 0) return;
        
        // Find buttons by their ID attribute
        const buttonMap = {
            "y-button": null,
            "b-button": null,
            "a-button": null,
            "x-button": null
        };
        
        // Map buttons to their IDs
        buttons.forEach(button => {
            if (button.canvas && button.canvas.id && buttonMap.hasOwnProperty(button.canvas.id)) {
                buttonMap[button.canvas.id] = button;
            }
        });
        
        // Position the buttons in a diamond pattern
        // Define angles for diamond layout (same as around joystick)
        const positions = [
            { id: "y-button", angle: Math.PI * 0.5 },  // Top (Y)
            { id: "b-button", angle: Math.PI * 0.0 },  // Right (B) 
            { id: "a-button", angle: Math.PI * 1.5 },  // Bottom (A)
            { id: "x-button", angle: Math.PI * 1.0 }   // Left (X)
        ];
        
        // Position each button according to the diamond layout
        positions.forEach(pos => {
            const button = buttonMap[pos.id];
            if (button) {
                const buttonX = centerX + spacing * Math.cos(pos.angle);
                const buttonY = centerY + spacing * Math.sin(pos.angle);
                
                button.setPosition(
                    `${buttonX - button.options.radius}px`,
                    `${buttonY - button.options.radius}px`
                );
            }
        });
    }

    configure(options) {
        this.options = Object.assign(this.options, options);

        if (options.emulatedGamepadConfig) {
            this.emulatedGamepad.configure(options.emulatedGamepadConfig);
        }

        if (typeof options.showOnScreenControls !== 'undefined') {
            if (options.showOnScreenControls) {
                this.setupVirtualGamepad();
            } else {
                this.destroy();
            }
        }
    }

    destroy() {
        this.controllers.forEach(controller => {
            controller.destroy();
        });
        this.controllers = [];
        
        this.emulatedGamepad.disable();
    }

    simpleSetup(config) {
        if (config === null) {
            this.configure({ showOnScreenControls: false });
            return;
        }

        const showControls = {
            ls: false,
            rs: false,
            a: false,
            b: false,
            x: false,
            y: false,
            menu: false
        };

        Object.assign(showControls, config);

        const newConfig = {
            showOnScreenControls: true,
            buttonConfig: {},
            joystickConfig: {}
        };

        if (showControls.a) newConfig.buttonConfig.a = { index: 0 };
        if (showControls.b) newConfig.buttonConfig.b = { index: 1 };
        if (showControls.x) newConfig.buttonConfig.x = { index: 2 };
        if (showControls.y) newConfig.buttonConfig.y = { index: 3 };
        if (showControls.menu) newConfig.buttonConfig.menu = { index: 16 };

        if (showControls.ls) {
            newConfig.joystickConfig.left = { 
                horizontalAxis: 0,
                verticalAxis: 1
            };
        }

        if (showControls.rs) {
            newConfig.joystickConfig.right = {
                horizontalAxis: 2,
                verticalAxis: 3
            };
        }

        this.configure({
            ...newConfig,
            emulatedGamepadConfig: {
                buttons: new Array(17).fill().map(() => ({})),
                axes: new Array(4).fill().map(() => ({}))
            }
        });
    }
}
