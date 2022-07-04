jQuery(document).ready(function () {
    var b = {};
    jQuery(window).keydown(function (event) {
        b[event.which] = true;
    });
    jQuery(window).keyup(function (event) {
        b[event.which] = false;
    });

    var car = new Car();
   
    var dt = Date.now();
    var frame = () => {
        var dtn = Date.now();
        if (dtn - dt > 0) {
            car.update(b, (dtn - dt) / 1000);
            dt = dtn;
            car.draw();
        }
        requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
});

class Car {
    
    constructor() {
        this.car = jQuery("#car");
        this.aftl = jQuery("#axleFrontTireLeft");
        this.aftr = jQuery("#axleFrontTireRight");
        this.artl = jQuery("#axleRearTireLeft");
        this.artr = jQuery("#axleRearTireRight");

        this.isPlayerControlled = true;

        this.velocitySpeed = 0.02;
        this.velocitySpeedBrake = 0.01;
        this.velocitySpeedDamping = 0.004;
        this.velocityMax = 0.4;
        this.steerAngleSpeed = 0.01;
        this.steerAngleSpeedDamping = 0.02;
        this.driftDampening = 0.2;
        this.steerAngleMax = 35 * Math.PI / 180;
        this.wheelBase = 100; //Math.abs(this.artl.offset().top - this.aftl.offset().top);
        this.wheelRadius = 0.5;
        this.speedFactor = 50;
        this.rotationFactor = 0.6;

        this.frontWheelDrive = true;
        this.rearWheelDrive = true;
    
        this.invertY = 1;
        this.rotateY = 1;

        this.position = {
            x: this.car.position().left,
            y: this.car.position().top
        };
        this.originPosition = {
            x: this.position.x,
            y: this.position.y,
        }
        this.velocity = 0;
        this.steerAngle = 0;
        this.headingAngle = 0;
        this.rotationAngle = 0;
        this.localVelocity = { x: 0, y: 0 };
        this.velocity2 = { x: 0, y: 0 };
        
        this.steer = 0;
        this.throttle = 0;
        this.eBrake = 0;
        this.direction = '';
        this.wheelRotation = 0;
        this.rotationalSpeed = 0;
        this.distance = 0;
        
        this.axleFrontTireLeftTrailActive = false;
        this.axleFrontTireRightTrailActive = false;
        this.axleRearTireLeftTrailActive = false;
        this.axleRearTireRightTrailActive = false;
    }

    speedKilometersPerHour() {
        return Math.mag2(this.velocity2) * 18 / 5 * this.speedFactor;
    }

    update(buttons, dt) {
        var dtms = dt * 1000;

        // Steering
        if (this.steer === 1) {
            this.steerAngle = this.steerAngle + this.steerAngleSpeed * this.steer;
            this.steerAngle = Math.min(this.steerAngle, this.steerAngleMax);
        } else if (this.steer === -1) {
            this.steerAngle = this.steerAngle + this.steerAngleSpeed * this.steer;
            this.steerAngle = Math.max(this.steerAngle, -this.steerAngleMax);
        }
        // Accelerating
        if (this.throttle === 1) {
            this.velocity = this.velocity + this.velocitySpeed * this.throttle;
            this.velocity = Math.min(this.velocity, this.velocityMax);
        } else if (this.throttle === -1) {
            this.velocity = this.velocity + this.velocitySpeed * this.throttle;
            this.velocity = Math.max(this.velocity, -this.velocityMax);
        }
        // Brake
        if (this.eBrake === 1) {
            if (this.velocity > 0) {
                this.velocity = this.velocity - this.velocitySpeedBrake;
                this.velocity = Math.max(this.velocity, 0);
            } else {
                this.velocity = this.velocity + this.velocitySpeedBrake;
                this.velocity = Math.min(this.velocity, 0);    
            }
        }
        // Center
        if (this.steer === 0) {
            if (this.steerAngle > 0) {
                this.steerAngle = this.steerAngle - this.steerAngleSpeedDamping;
                this.steerAngle = Math.max(this.steerAngle, 0);
            } else {
                this.steerAngle = this.steerAngle + this.steerAngleSpeedDamping;
                this.steerAngle = Math.min(this.steerAngle, 0);    
            }
        }
        // Friction
        if (this.throttle === 0) {
            if (this.velocity > 0) {
                this.velocity = this.velocity - this.velocitySpeedDamping;
                this.velocity = Math.max(this.velocity, 0);
            } else {
                this.velocity = this.velocity + this.velocitySpeedDamping;
                this.velocity = Math.min(this.velocity, 0);    
            }
        }

        this.headingAngle = this.rotationAngle - this.invertY * this.rotateY * Math.PI / 2;
        var cos = Math.cos(this.headingAngle);
        var sin = Math.sin(this.headingAngle);
        var frontWheel = {
            x: this.position.x + this.wheelBase / 2 * cos,
            y: this.position.y + this.wheelBase / 2 * sin
        };
        var backWheel = {
            x: this.position.x - this.wheelBase / 2 * cos,
            y: this.position.y - this.wheelBase / 2 * sin
        };
        frontWheel = {
            x: frontWheel.x + this.velocity * dtms * Math.cos(this.headingAngle + this.steerAngle),
            y: frontWheel.y + this.velocity * dtms * Math.sin(this.headingAngle + this.steerAngle)
        };
        backWheel = {
            x: backWheel.x + this.velocity * dtms * cos,
            y: backWheel.y + this.velocity * dtms * sin,
        };
        this.position = {
            x: (frontWheel.x + backWheel.x) / 2,
            y: (frontWheel.y + backWheel.y) / 2
        };
        this.headingAngle = Math.atan2(frontWheel.y - backWheel.y, frontWheel.x - backWheel.x);
        this.headingAngle = this.headingAngle + (this.steerAngle * (this.velocity / this.velocityMax) * this.driftDampening); // Drift
        this.rotationAngle = this.headingAngle + this.invertY * this.rotateY * Math.PI / 2;

        this.velocity2 = {
            x: this.velocity * cos,
            y: this.velocity * sin
        };
        this.localVelocity.x = cos * this.velocity2.x + sin * this.velocity2.y;
        this.localVelocity.y = cos * this.velocity2.y - sin * this.velocity2.x;
        if (this.localVelocity.x > 0) {
            this.direction = 'forwards';
        } else if (this.localVelocity.x < 0) {
            this.direction = 'backwards';
        } else {
            this.direction = '';
        }

        this.rotationalSpeed = Math.sign(this.localVelocity.x) * Math.mag2(this.velocity2) / this.wheelRadius / this.rotationFactor;
        this.wheelRotation += this.rotationalSpeed;
        this.distance = Math.mag2(Math.sub2(this.position, this.originPosition));

        // Skidmarks
        if (this.eBrake === 1 && this.velocity !== 0) {
            if (this.frontWheelDrive && this.rearWheelDrive) {
                this.axleFrontTireLeftTrailActive = true;
                this.axleFrontTireRightTrailActive = true;
                this.axleRearTireLeftTrailActive = true;
                this.axleRearTireRightTrailActive = true;
            } else if (this.frontWheelDrive) {
                this.axleFrontTireLeftTrailActive = true;
                this.axleFrontTireRightTrailActive = true;
            } else if (this.rearWheelDrive) {
                this.axleRearTireLeftTrailActive = true;
                this.axleRearTireRightTrailActive = true;
            }
        } else {
            this.axleFrontTireLeftTrailActive = false;
            this.axleFrontTireRightTrailActive = false;
            this.axleRearTireLeftTrailActive = false;
            this.axleRearTireRightTrailActive = false;
        }

        this.updateControl(buttons, dt);
    }

    updateControl(buttons, dt) {
        if (this.isPlayerControlled) {
            this.steer = 0;;
            this.throttle = 0;
            this.eBrake = 0;
            // Left
            if (buttons[37]) {
                this.steer = -1;
            }
            // Right
            if (buttons[39]) {
                this.steer = 1;
            }
            // Up
            if (buttons[38]) {
                this.throttle = 1;
            }
            // Down
            if (buttons[40]) {
                this.throttle = -1;
            }
            // Space
            if (buttons[32]) {
                this.eBrake = 1;
            }
        }
    }

    draw() {
        this.car.css({
            left: this.position.x,
            top: this.position.y,
            transform: "rotate("  + this.rotationAngle + "rad)"
        });
        this.aftl.css({
            transform: "rotate("  + this.steerAngle + "rad)"
        });
        this.aftr.css({
            transform: "rotate("  + this.steerAngle + "rad)"
        });
        jQuery("#wheel").css({
            transform: "rotate(" + this.wheelRotation + "rad)"
        });

        jQuery("#speed").html(Math.round10(this.speedKilometersPerHour()));
        jQuery("#localVelocity").html(Math.toString2(Math.round2(this.localVelocity)));
        jQuery("#velocity").html(Math.toString2(Math.round2(this.velocity2)));
        jQuery("#steerAngle").html(Math.round10(this.steerAngle));
        jQuery("#throttle").html(this.throttle);
        jQuery("#brake").html(this.eBrake);
        jQuery("#headingAngle").html(Math.round10(this.headingAngle));
        jQuery("#axleFLeftTrail").html(this.axleFrontTireLeftTrailActive);
        jQuery("#axleFRightTrail").html(this.axleFrontTireRightTrailActive);
        jQuery("#axleRLeftTrail").html(this.axleRearTireLeftTrailActive);
        jQuery("#axleRRightTrail").html(this.axleRearTireRightTrailActive);
        jQuery("#rotation").html(Math.round10(this.rotationalSpeed));
        jQuery("#direction").html(this.direction);
        jQuery("#distance").html(Math.round10(this.distance));
        jQuery("#wheelRotation").html(Math.round10(this.wheelRotation));
    }
}

Math.deg2Rad = Math.PI / 180;
Math.rad2Deg = 180 / Math.PI;

Math.round10 = (v) => {
    return Math.round(v * 100) / 100;
}

Math.sign = (v) => {
    return v >= 0 ? 1 : -1;
};

Math.lerp = (a, b, n) => {
    return (1 - n) * a + n * b;
};

Math.clamp = (val, min, max) => {
    return Math.min(Math.max(min, val), max);
};

Math.round2 = (v) => {
    return {
        x: Math.round10(v.x),
        y: Math.round10(v.y)
    };
}

Math.mag2 = (v) => {
    return Math.sqrt(v.x * v.x + v.y * v.y);
};

Math.norm2 = (v) => {
    var mag = Math.mag2(v);
    return {
        x: v.x / mag,
        y: v.y / mag
    };
};

Math.lerp2 = (a, b, n) => {
    return {
        x: Math.lerp(a.x, b.x, n),
        y: Math.lerp(a.y, b.y, n),
    };
};

Math.add2 = (v1, v2) => {
    return {
        x: v1.x + v2.x,
        y: v1.y + v2.y,
    };
}

Math.sub2 = (v1, v2) => {
    return {
        x: v1.x - v2.x,
        y: v1.y - v2.y,
    };
}

Math.mul2 = (v1, v2) => {
    return {
        x: v1.x * v2.x,
        y: v1.y * v2.y,
    };
}

Math.div2 = (v1, v2) => {
    return {
        x: v1.x / v2.x,
        y: v1.y / v2.y,
    };
}

Math.add2s = (v, s) => {
    return {
        x: v.x + s,
        y: v.y + s
    };
}

Math.sub2s = (v, s) => {
    return {
        x: v.x - s,
        y: v.y - s
    };
}

Math.mul2s = (v, s) => {
    return {
        x: v.x * s,
        y: v.y * s
    };
}

Math.div2s = (v, s) => {
    return {
        x: v.x / s,
        y: v.y / s
    };
}

Math.toString2 = (v) => {
    return `(${v.x}, ${v.y})`;
}