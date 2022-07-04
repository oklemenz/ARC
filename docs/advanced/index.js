jQuery(document).ready(function () {
    var b = {};
    jQuery(window).keydown(function (e) {
        b[e.which] = true;
    });
    jQuery(window).keyup(function (e) {
        b[e.which] = false;
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

    constructor(pane) {
        this.isPlayerControlled = true;
        // Range(0..1)
        this.cgHeight = 0.55;
        // Range(0..2)
        this.inertiaScale = 1;
        this.brakePower = 12000;
        this.eBrakePower = 4800; // 5000
        // Range(0..1)
        this.weightTransfer = 0.24; // 0.35
        // Range(0..1)
        this.maxSteerAngle = 0.797; // 0.75
        // Range(0..20)
        this.cornerStiffnessFront = 5.0;
        // Range(0..20)
        this.cornerStiffnessRear = 5.2;
        // Range(0..20)
        this.airResistance = 2.5;
        // Range(0..20)
        this.rollingResistance = 8.0;
        // Range(0..1)
        this.eBrakeGripRatioFront = 0.9;
        // Range(0..5)
        this.totalTireGripFront = 2.5;
        // Range(0..1)
        this.eBrakeGripRatioRear = 0.4;
        // Range(0..5)
        this.totalTireGripRear = 2.5;
        // Range(0..5)
        this.steerSpeed = 2.5;
        // Range(0..5)
        this.steerAdjustSpeed = 1;
        // Range(0..1000)
        this.speedSteerCorrection = 295; // 300
        // Range(0..20)    
        this.speedTurningStability = 11.8; // 10
        // Range(0..10)    
        this.axleDistanceCorrection = 1.7; // 2
       
        this.axleFrontPos = { x: 0, y: 0.86 };
        this.tireFrontLeftPos = { x: -0.64, y: 0.861 };
        this.tireFrontRightPos = { x: 0.64, y: 0.861 };
        this.axleRearPos = { x: 0, y: -0.865 };
        this.tireRearLeftPos = { x: -0.64, y: -0.865 };
        this.tireRearRightPos = { x: 0.64, y: -0.865 };

        this.speedFactor = 15;
        this.rotationFactor = 40;

        this.inertia = 1;
        this.wheelBase = 1;
        this.trackWidth = 1;

        // Private vars
        this.headingAngle = 0;
        this.absoluteVelocity = 0;
        this.angularVelocity = 0;
        this.steerDirection = 0;
        this.steerAngle = 0;

        this.direction = '';
        this.wheelRotation = 0;
        this.distance = 0;

        this.velocity = { x: 0, y: 0 };
        this.acceleration = { x: 0, y: 0 };
        this.localVelocity = { x: 0, y: 0 };
        this.localAcceleration = { x: 0, y: 0 };
        this.centerOfGravity = { x: 0, y: -0.231 };

        this.steer = 0;
        this.throttle = 0;
        this.brake = 0;
        this.eBrake = 0;

        this.activeBrake = 0;
        this.activeThrottle = 0;
        
        this.frontWheelDrive = false;
        this.rearWheelDrive = true;

        this.invertY = -1;
        this.rotateY = 1;

        this.frame = 0;

        log("");
		log("########################################");
		log("# NEW START");
		log("########################################");
		log("");

        this.physics = {
            object: jQuery("#car"),
            mass: 1500, // Mass
            velocity: { x: 0, y: 0 },
            position: { // Current position
                x: jQuery("#car").position().left,
                y: jQuery("#car").position().top
            },
            originPosition: { // Current position
                x: jQuery("#car").position().left,
                y: jQuery("#car").position().top
            },
            rotation: 0, // Current rotation
            angularVelocity: 0, // Rotation velocity
            linearDrag: 0.1, // Slow down velocity
            angularDrag: 0.5, // Slow down angularVelocity
            gravity: -9.81
        };

        this.axleFront = new Axle(jQuery("#axleFront"), {
            x: 0,
            y: jQuery("#car").height() / 2 - jQuery("#axleFront")[0].offsetTop - jQuery("#axleFront").height() / 2
        });
        this.axleRear = new Axle(jQuery("#axleRear"), {
            x: 0,
            y: jQuery("#car").height() / 2 - jQuery("#axleRear")[0].offsetTop - jQuery("#axleRear").height() / 2
        });
        this.axleFront.physics.position = this.axleFrontPos;
        this.axleFront.tireLeft.physics.position = this.tireFrontLeftPos;
        this.axleFront.tireRight.physics.position = this.tireFrontRightPos;
        this.axleRear.physics.position = this.axleRearPos;
        this.axleRear.tireLeft.physics.position = this.tireRearLeftPos;
        this.axleRear.tireRight.physics.position = this.tireRearRightPos;

        this.engine = new Engine(jQuery("#engine"));

        this.axleFront.distanceToCG = Math.abs(this.centerOfGravity.y - this.axleFront.physics.position.y);
        log("axleFront.distanceToCG", this.axleFront.distanceToCG);
        this.axleRear.distanceToCG = Math.abs(this.centerOfGravity.y - this.axleRear.physics.position.y);
        log("axleRear.distanceToCG", this.axleRear.distanceToCG);
        this.axleFront.distanceToCG *= this.axleDistanceCorrection;
        log("axleFront.distanceToCG", this.axleRear.distanceToCG);
        this.axleRear.distanceToCG *= this.axleDistanceCorrection;
        log("axleRear.distanceToCG", this.axleRear.distanceToCG);

        this.wheelBase = this.axleFront.distanceToCG + this.axleRear.distanceToCG;
        log("wheelBase", this.wheelBase);
        this.inertia = this.physics.mass * this.inertiaScale;
        log("inertia", this.inertia);

        this.headingAngle = this.physics.rotation + this.invertY * this.rotateY * Math.PI / 2;
        log("headingAngle", this.headingAngle);

        this.axleFront.init(this, this.wheelBase);
        this.axleRear.init(this, this.wheelBase);

        this.trackWidth = Math.abs(this.axleRear.tireLeft.physics.position.x - this.axleRear.tireRight.physics.position.x);
        log("trackWidth", this.trackWidth);
    }

    speedKilometersPerHour() {
        return Math.mag2(this.physics.velocity) * 18 / 5;
    }

    update(buttons, dt) {

        log("");
		log("########################################");
		log("# START FRAME " + this.frame);
		log("########################################");
		log("");

        // Update from rigidbody to retain collision responses
        this.velocity = this.physics.velocity;
        log2("velocity", this.velocity);
        log("rotation", this.physics.rotation);
        log("rotation (deg)", this.physics.rotation * Math.rad2Deg);
        this.headingAngle = this.physics.rotation + this.invertY * this.rotateY * Math.PI / 2;
        log("headingAngle", this.headingAngle);

        var sin = Math.sin(this.headingAngle);
        log("sin", sin);
        var cos = Math.cos(this.headingAngle);
        log("cos", cos);

        // Get local velocity
        this.localVelocity.x = cos * this.velocity.x + sin * this.velocity.y;
        log("localVelocity.x", this.localVelocity.x);
        this.localVelocity.y = cos * this.velocity.y - sin * this.velocity.x;
        log("localVelocity.y", this.localVelocity.y);

        if (this.localVelocity.x > 0) {
            this.direction = 'forwards';
        } else if (this.localVelocity.x < 0) {
            this.direction = 'backwards';
        } else {
            this.direction = '';
        }
        log("direction", this.direction);

        // Weight transfer
        var transferX = this.weightTransfer * this.localAcceleration.x * this.cgHeight / this.wheelBase;
        log("transferX", transferX);
        var transferY = this.weightTransfer * this.localAcceleration.y * this.cgHeight / this.trackWidth * 20; // exagerate the weight transfer on the y-axis
        log("transferY", transferY);

        // Weight on each axle
        var weightFront = this.physics.mass * (this.axleFront.weightRatio * -this.physics.gravity - transferX);
        log("weightFront", weightFront);
        var weightRear = this.physics.mass * (this.axleRear.weightRatio * -this.physics.gravity + transferX);
        log("weightRear", weightRear);

        // Weight on each tire
        this.axleFront.tireLeft.activeWeight = weightFront - transferY;
        log("axleFront.tireLeft.activeWeight", this.axleFront.tireLeft.activeWeight);
        this.axleFront.tireRight.activeWeight = weightFront + transferY;
        log("axleFront.tireRight.activeWeight", this.axleFront.tireRight.activeWeight);
        this.axleRear.tireLeft.activeWeight = weightRear - transferY;
        log("axleRear.tireLeft.activeWeight", this.axleRear.tireLeft.activeWeight);
        this.axleRear.tireRight.activeWeight = weightRear + transferY;
        log("axleRear.tireRight.activeWeight", this.axleRear.tireRight.activeWeight);

        // Velocity of each tire
        this.axleFront.tireLeft.angularVelocity = this.axleFront.distanceToCG * this.angularVelocity;
        log("axleFront.tireLeft.angularVelocity", this.axleFront.tireLeft.angularVelocity);
        this.axleFront.tireRight.angularVelocity = this.axleFront.distanceToCG * this.angularVelocity;
        log("axleFront.tireRight.angularVelocity", this.axleFront.tireRight.angularVelocity);
        this.axleRear.tireLeft.angularVelocity = -this.axleRear.distanceToCG * this.angularVelocity;
        log("axleRear.tireLeft.angularVelocity", this.axleRear.tireLeft.angularVelocity);
        this.axleRear.tireRight.angularVelocity = -this.axleRear.distanceToCG * this.angularVelocity;
        log("axleRear.tireRight.angularVelocity", this.axleRear.tireRight.angularVelocity);

        // Slip angle
        this.axleFront.slipAngle = Math.atan2(this.localVelocity.y + this.axleFront.angularVelocity(), Math.abs(this.localVelocity.x)) - Math.sign(this.localVelocity.x) * this.steerAngle;
        log("axleFront.slipAngle", this.axleFront.slipAngle);
        this.axleRear.slipAngle = Math.atan2(this.localVelocity.y + this.axleRear.angularVelocity(), Math.abs(this.localVelocity.x));
        log("axleRear.slipAngle", this.axleRear.slipAngle);

        // Brake and Throttle power
        this.activeBrake = Math.min(this.brake * this.brakePower + this.eBrake * this.eBrakePower, this.brakePower);
        log("activeBrake", this.activeBrake);
        this.activeThrottle = (this.throttle * this.engine.torque(this)) * (this.engine.gearRatio() * this.engine.effectiveGearRatio());
        log("activeThrottle", this.activeThrottle);

        // Torque of each tire (front wheel drive)
        if (this.frontWheelDrive) {
            this.axleFront.tireLeft.torque = this.activeThrottle / this.axleFront.tireLeft.radius;
            log("axleFront.tireLeft.torque", this.axleFront.tireLeft.torque);
            this.axleFront.tireRight.torque = this.activeThrottle / this.axleFront.tireRight.radius;
            log("axleFront.tireRight.torque", this.axleFront.tireRight.torque);
        }

        // Torque of each tire (rear wheel drive)
        if (this.rearWheelDrive) {
            this.axleRear.tireLeft.torque = this.activeThrottle / this.axleRear.tireLeft.radius;
            log("axleRear.tireLeft.torque", this.axleRear.tireLeft.torque);
            this.axleRear.tireRight.torque = this.activeThrottle / this.axleRear.tireRight.radius;
            log("axleRear.tireRight.torque", this.axleRear.tireRight.torque);
        }

        // Grip and Friction of each tire
        this.axleFront.tireLeft.grip = this.totalTireGripFront * (1.0 - this.eBrake * (1.0 - this.eBrakeGripRatioFront));
        log("axleFront.tireLeft.grip", this.axleFront.tireLeft.grip);
        this.axleFront.tireRight.grip = this.totalTireGripFront * (1.0 - this.eBrake * (1.0 - this.eBrakeGripRatioFront));
        log("axleFront.tireRight.grip", this.axleFront.tireRight.grip);
        this.axleRear.tireLeft.grip = this.totalTireGripRear * (1.0 - this.eBrake * (1.0 - this.eBrakeGripRatioRear));
        log("axleRear.tireLeft.grip", this.axleRear.tireLeft.grip);
        this.axleRear.tireRight.grip = this.totalTireGripRear * (1.0 - this.eBrake * (1.0 - this.eBrakeGripRatioRear));
        log("axleRear.tireRight.grip", this.axleRear.tireRight.grip);

        this.axleFront.tireLeft.frictionForce = Math.clamp(-this.cornerStiffnessFront * this.axleFront.slipAngle, -this.axleFront.tireLeft.grip, this.axleFront.tireLeft.grip) * this.axleFront.tireLeft.activeWeight;
        log("axleFront.tireLeft.frictionForce", this.axleFront.tireLeft.frictionForce);
        this.axleFront.tireRight.frictionForce = Math.clamp(-this.cornerStiffnessFront * this.axleFront.slipAngle, -this.axleFront.tireRight.grip, this.axleFront.tireRight.grip) * this.axleFront.tireRight.activeWeight;
        log("axleFront.tireRight.frictionForce", this.axleFront.tireRight.frictionForce);
        this.axleRear.tireLeft.frictionForce = Math.clamp(-this.cornerStiffnessRear * this.axleRear.slipAngle, -this.axleRear.tireLeft.grip, this.axleRear.tireLeft.grip) * this.axleRear.tireLeft.activeWeight;
        log("axleRear.tireLeft.frictionForce", this.axleRear.tireLeft.frictionForce);
        this.axleRear.tireRight.frictionForce = Math.clamp(-this.cornerStiffnessRear * this.axleRear.slipAngle, -this.axleRear.tireRight.grip, this.axleRear.tireRight.grip) * this.axleRear.tireRight.activeWeight;
        log("axleRear.tireRight.frictionForce", this.axleRear.tireRight.frictionForce);

        // Forces
        var torque = 0;
        if (this.frontWheelDrive && this.rearWheelDrive) {
            torque = (this.axleFront.torque() + this.axleRear.torque()) / 2;
        } else if (this.frontWheelDrive) {
            torque = this.axleFront.torque();
        } else if (this.rearWheelDrive) {
            torque = this.axleRear.torque();
        }

        var tractionForceX = torque - this.activeBrake * Math.sign(this.localVelocity.x);
        log("tractionForceX", tractionForceX);
        var tractionForceY = 0;

        var dragForceX = -this.rollingResistance * this.localVelocity.x - this.airResistance * this.localVelocity.x * Math.abs(this.localVelocity.x);
        log("dragForceX", dragForceX);
        var dragForceY = -this.rollingResistance * this.localVelocity.y - this.airResistance * this.localVelocity.y * Math.abs(this.localVelocity.y);
        log("dragForceY", dragForceY);

        var totalForceX = dragForceX + tractionForceX;
        log("totalForceX", totalForceX);
        var totalForceY = dragForceY + tractionForceY + Math.cos(this.steerAngle) * this.axleFront.frictionForce() + this.axleRear.frictionForce();
        log("totalForceY", totalForceY);

        // Adjust Y force so it levels out the car heading at high speeds
        log("this.speedTurningStability", this.speedTurningStability);
        if (this.absoluteVelocity > 10) {
            totalForceY *= (this.absoluteVelocity + 1) / (21 - this.speedTurningStability);
        }
        log("totalForceY", totalForceY);

        // If we are not pressing gas, add artificial drag - helps with simulation stability
        if (this.throttle === 0) {
            this.velocity = Math.lerp2(this.velocity, { x: 0, y: 0 }, 0.005);
        }
        log2("velocity", this.velocity);

        // Acceleration
        this.localAcceleration.x = totalForceX / this.physics.mass;
        log("localAcceleration.x", this.localAcceleration.x);
        this.localAcceleration.y = totalForceY / this.physics.mass;
        log("localAcceleration.y", this.localAcceleration.y);

        this.acceleration.x = cos * this.localAcceleration.x - sin * this.localAcceleration.y;
        log("acceleration.x", this.acceleration.x);
        this.acceleration.y = sin * this.localAcceleration.x + cos * this.localAcceleration.y;
        log("acceleration.y", this.acceleration.y);

        // Velocity and speed
        this.velocity.x += this.acceleration.x * dt;
        log("velocity.x", this.velocity.x);
        this.velocity.y += this.acceleration.y * dt;
        log("velocity.y", this.velocity.y);

        this.absoluteVelocity = Math.mag2(this.velocity);
        log("absoluteVelocity", this.absoluteVelocity);

        // Angular torque of car
        var angularTorque = (this.axleFront.frictionForce() * this.axleFront.distanceToCG) - (this.axleRear.frictionForce() * this.axleRear.distanceToCG);
        log("angularTorque", angularTorque);
        // Car will drift away at low speeds
        if (this.absoluteVelocity < 0.5 && this.activeThrottle === 0) {
            this.localAcceleration = { x: 0, y: 0 };
            this.absoluteVelocity = 0;
            this.velocity = { x: 0, y: 0 };
            angularTorque = 0;
            this.angularVelocity = 0;
            this.acceleration = { x: 0, y: 0 };
            //this.physics.angularVelocity = 0;
        }
        var angularAcceleration = angularTorque / this.inertia;
        log("angularAcceleration", angularAcceleration);

        // Update 
        this.angularVelocity += angularAcceleration * dt;
        log("angularVelocity", this.angularVelocity);

        log("this.speedKilometersPerHour()", this.speedKilometersPerHour());
        // Simulation likes to calculate high angular velocity at very low speeds - adjust for this
        if (this.absoluteVelocity < 1 && Math.abs(this.steerAngle) < 0.05) {
            this.angularVelocity = 0;
        } else if (this.speedKilometersPerHour() < 0.75) {
            this.angularVelocity = 0;
        }
        log("angularVelocity", this.angularVelocity);

        var rotationalSpeed = Math.sign(this.localVelocity.x) * Math.mag2(this.physics.velocity) / this.axleFront.tireLeft.radius / this.rotationFactor;

        // Rotational Velocity of each tire
        this.axleFront.tireLeft.rotationalSpeed = rotationalSpeed;
        log("axleFront.tireLeft.rotationalSpeed", this.axleFront.tireLeft.rotationalSpeed);
        this.axleFront.tireRight.rotationalSpeed = rotationalSpeed;
        log("axleFront.tireRight.rotationalSpeed", this.axleFront.tireRight.rotationalSpeed);
        this.axleRear.tireLeft.rotationalSpeed = rotationalSpeed;
        log("axleRear.tireLeft.rotationalSpeed", this.axleRear.tireLeft.rotationalSpeed);
        this.axleRear.tireRight.rotationalSpeed = rotationalSpeed;
        log("axleRear.tireRight.rotationalSpeed", this.axleRear.tireRight.rotationalSpeed);

        // Simulate Wheel Rotation
        this.wheelRotation += rotationalSpeed;

        this.headingAngle += this.angularVelocity * dt;
        log("headingAngle", this.headingAngle);

        //this.velocity = Math.lerp2(this.velocity, { x: 0, y: 0 }, this.physics.linearDrag / 5);
        //this.angularVelocity = Math.lerp(this.angularVelocity, 0, this.physics.angularDrag / 5);
        
        this.physics.velocity = this.velocity;
        log2("velocity", this.velocity);
        this.physics.position = Math.add2(this.physics.position, Math.mul2s(this.physics.velocity, dt * this.speedFactor));
        log2("position", Math.sub2(this.physics.position, this.physics.originPosition));
        this.physics.rotation = this.headingAngle - this.invertY * this.rotateY * Math.PI / 2;
        log("rotation", this.physics.rotation);
        log("rotation (deg)", this.physics.rotation * Math.rad2Deg);

        this.distance = Math.mag2(Math.sub2(this.physics.position, this.physics.originPosition));
        log("distance", this.distance);

        log("");
		log("########################################");
		log("# END FRAME " + this.frame);
		log("########################################");
		log("");

        this.frame++;

        if (this.frame === 1) {
            //debugger;
        }   

        this.updateControl(buttons, dt);
    }

    updateControl(buttons, dt) {
        if (this.isPlayerControlled) {
            this.throttle = 0;
            this.brake = 0;
            this.eBrake = 0;
            this.steer = 0;

            // Up
            if (buttons[38]) {
                this.throttle = 1;
            }
            // Down
            if (buttons[40]) {
                // this.brake = 0;
                this.throttle = -1;
            }
            // Space
            if (buttons[32]) {
                this.eBrake = 1;
            }
            // Left
            if (buttons[37]) {
                this.steer = 1;
            }
            // Right
            if (buttons[39]) {
                this.steer = -1;
            }
            // A
            if (buttons[65]) {
                this.engine.shiftUp();
            }
            // Z
            if (buttons[90]) {
                this.engine.shiftDown();
            }

            // Apply filters to our steer direction
            this.steerDirection = this.smoothSteering(this.invertY * this.steer, dt);
            log("steerDirection", this.steerDirection);
            this.steerDirection = this.speedAdjustedSteering(this.steerDirection);
            log("steerDirection", this.steerDirection);

            // Calculate the current angle the tires are pointing
            this.steerAngle = this.steerDirection * this.maxSteerAngle;
            log("steerAngle", this.steerAngle);

            // Set front axle tires rotation
            this.axleFront.tireLeft.physics.rotation = this.invertY * -this.steerAngle;
            this.axleFront.tireRight.physics.rotation = this.invertY * -this.steerAngle;
        }

        // Calculate weight center of four tires
        // This is just to draw that red dot over the car to indicate what tires have the most weight
        var pos = { x: 0, y: 0 };
        if (Math.mag2(this.localAcceleration) > 1) {

            var wfl = Math.max(0, (this.axleFront.tireLeft.activeWeight - this.axleFront.tireLeft.restingWeight));
            var wfr = Math.max(0, (this.axleFront.tireRight.activeWeight - this.axleFront.tireRight.restingWeight));
            var wrl = Math.max(0, (this.axleRear.tireLeft.activeWeight - this.axleRear.tireLeft.restingWeight));
            var wrr = Math.max(0, (this.axleRear.tireRight.activeWeight - this.axleRear.tireRight.restingWeight));

            pos = Math.add2(Math.add2(Math.add2(
                Math.mul2s(this.axleFront.tireLeft.physics.position, wfl), Math.mul2s(this.axleFront.tireRight.physics.position, wfr)),
                Math.mul2s(this.axleRear.tireLeft.physics.position, wrl)), Math.mul2s(this.axleRear.tireRight.physics.position, wrr));

            var weightTotal = wfl + wfr + wrl + wrr;

            if (weightTotal > 0) {
                pos = Math.div2s(pos, weightTotal);
                pos = Math.norm2(pos);
                pos.x = Math.clamp(pos.x, -0.6, 0.6);
            } else {
                pos = { x: 0, y: 0 };
            }
        }

        // Update the "Center Of Gravity" dot to indicate the weight shift
        this.centerOfGravity = Math.lerp2(this.centerOfGravity, pos, 0.1);
        log2("centerOfGravity", this.centerOfGravity);

        // Skidmarks
        if ((Math.abs(this.localAcceleration.y) > 18 || this.eBrake === 1) && this.absoluteVelocity > 0) {
            if (this.frontWheelDrive && this.rearWheelDrive) {
                this.axleFront.tireLeft.setTrailActive(true);
                this.axleFront.tireRight.setTrailActive(true);
                this.axleRear.tireLeft.setTrailActive(true);
                this.axleRear.tireRight.setTrailActive(true);
            } else if (this.frontWheelDrive) {
                this.axleFront.tireLeft.setTrailActive(true);
                this.axleFront.tireRight.setTrailActive(true);
            } else if (this.rearWheelDrive) {
                this.axleRear.tireLeft.setTrailActive(true);
                this.axleRear.tireRight.setTrailActive(true);
            }
        } else {
            this.axleFront.tireLeft.setTrailActive(false);
            this.axleFront.tireRight.setTrailActive(false);
            this.axleRear.tireLeft.setTrailActive(false);
            this.axleRear.tireRight.setTrailActive(false);
        }

        // Automatic transmission
        this.engine.updateAutomaticTransmission(this);
    }

    smoothSteering(steerInput, dt) {
        var steer = 0;

        if (Math.abs(steerInput) > 0.001) {
            steer = Math.clamp(this.steerDirection + steerInput * dt * this.steerSpeed, -1.0, 1.0);
        } else {
            if (this.steerDirection > 0) {
                steer = Math.max(this.steerDirection - dt * this.steerAdjustSpeed, 0);
            } else if (this.steerDirection < 0) {
                steer = Math.min(this.steerDirection + dt * this.steerAdjustSpeed, 0);
            }
        }

        return steer;
    }

    speedAdjustedSteering(steerInput) {
        var activeVelocity = Math.min(this.absoluteVelocity, 250.0);
        var steer = steerInput * (1.0 - (activeVelocity / this.speedSteerCorrection));
        return steer;
    }

    draw() {
        this.physics.object.css({
            left: this.physics.position.x,
            top: this.physics.position.y,
            transform: "rotate(" + this.physics.rotation + "rad)"
        });
        this.axleFront.tireLeft.physics.object.css({
            transform: "rotate(" + this.axleFront.tireLeft.physics.rotation + "rad)"
        });
        this.axleFront.tireRight.physics.object.css({
            transform: "rotate(" + this.axleFront.tireRight.physics.rotation + "rad)"
        });
        jQuery("#wheel").css({
            transform: "rotate(" + this.wheelRotation + "rad)"
        });

        jQuery("#speed").html(Math.round10(this.speedKilometersPerHour()));
        jQuery("#rpm").html(Math.round10(this.engine.rpm(this)));
        jQuery("#gear").html(this.engine.currentGear + 1);
        jQuery("#localAcceleration").html(Math.toString2(Math.round2(this.localAcceleration)));
        jQuery("#acceleration").html(Math.toString2(Math.round2(this.acceleration)));
        jQuery("#localVelocity").html(Math.toString2(Math.round2(this.localVelocity)));
        jQuery("#velocity").html(Math.toString2(Math.round2(this.velocity)));
        jQuery("#steerAngle").html(Math.round10(this.steerAngle));
        jQuery("#throttle").html(this.throttle);
        jQuery("#brake").html(this.eBrake);

        jQuery("#headingAngle").html(Math.round10(this.headingAngle));
        jQuery("#angularVelocity").html(Math.round10(this.angularVelocity));

        jQuery("#tireFLWeight").html(Math.round10(this.axleFront.tireLeft.activeWeight));
        jQuery("#tireFRWeight").html(Math.round10(this.axleFront.tireRight.activeWeight));
        jQuery("#tireRLWeight").html(Math.round10(this.axleRear.tireLeft.activeWeight));
        jQuery("#tireRRWeight").html(Math.round10(this.axleRear.tireRight.activeWeight));

        jQuery("#tireFLFriction").html(Math.round10(this.axleFront.tireLeft.frictionForce));
        jQuery("#tireFRFriction").html(Math.round10(this.axleFront.tireRight.frictionForce));
        jQuery("#tireRLFriction").html(Math.round10(this.axleRear.tireLeft.frictionForce));
        jQuery("#tireRRFriction").html(Math.round10(this.axleRear.tireRight.frictionForce));

        jQuery("#tireFLGrip").html(Math.round10(this.axleFront.tireLeft.grip));
        jQuery("#tireFRGrip").html(Math.round10(this.axleFront.tireRight.grip));
        jQuery("#tireRLGrip").html(Math.round10(this.axleRear.tireLeft.grip));
        jQuery("#tireRRGrip").html(Math.round10(this.axleRear.tireRight.grip));

        jQuery("#axleFSlipAngle").html(Math.round10(this.axleFront.slipAngle));
        jQuery("#axleRSlipAngle").html(Math.round10(this.axleRear.slipAngle));

        jQuery("#axleFTorque").html(Math.round10(this.axleFront.torque()));
        jQuery("#axleRTorque").html(Math.round10(this.axleRear.torque()));

        jQuery("#axleFLeftTrail").html(this.axleFront.tireLeft.trailActive);
        jQuery("#axleFRightTrail").html(this.axleFront.tireRight.trailActive);
        jQuery("#axleRLeftTrail").html(this.axleRear.tireLeft.trailActive);
        jQuery("#axleRRightTrail").html(this.axleRear.tireRight.trailActive);

        jQuery("#tireFLRotation").html(Math.round10(this.axleFront.tireLeft.rotationalSpeed));
        jQuery("#tireFRRotation").html(Math.round10(this.axleFront.tireRight.rotationalSpeed));
        jQuery("#tireRLRotation").html(Math.round10(this.axleRear.tireLeft.rotationalSpeed));
        jQuery("#tireRRRotation").html(Math.round10(this.axleRear.tireRight.rotationalSpeed));

        jQuery("#direction").html(this.direction);
        jQuery("#distance").html(Math.round10(this.distance));
        jQuery("#rotation").html(Math.round10(this.wheelRotation));
        jQuery("#centerOfGravity").html(Math.toString2(Math.round2(this.centerOfGravity)));
    }
}

class Axle {

    constructor(object, position) {
        this.distanceToCG = 0;
        this.weightRatio = 0;
        this.slipAngle = 0;

        this.tireLeft = new Tire(object.find(".tireLeft").first(), {
            x: -object.width() / 2,
            y: position.y
        });
        this.tireRight = new Tire(object.find(".tireRight").first(), {
            x: object.width() / 2,
            y: position.y
        });

        this.physics = {
            object: object,
            position: position,
        };
    }

    init(car, wheelBase) {
        // Weight distribution on each axle and tire
        this.weightRatio = this.distanceToCG / wheelBase;

        // Calculate resting weight of each Tire
        var weight = car.physics.mass * (this.weightRatio * -car.physics.gravity);
        this.tireLeft.restingWeight = weight;
        this.tireRight.restingWeight = weight;
    }

    frictionForce() {
        return (this.tireLeft.frictionForce + this.tireRight.frictionForce) / 2;
    }

    angularVelocity() {
        return Math.min(this.tireLeft.angularVelocity + this.tireRight.angularVelocity);
    }

    torque() {
        return (this.tireLeft.torque + this.tireRight.torque) / 2;
    }
}

class Tire {

    constructor(object, position) {
        this.restingWeight = 0;
        this.activeWeight = 0;
        this.grip = 0;
        this.frictionForce = 0;
        this.angularVelocity = 0;
        this.rotationalSpeed = 0;
        this.torque = 0;

        this.radius = 0.5;
        this.trailDuration = 5;
        this.trailActive = false;

        this.physics = {
            object: object,
            position: position,
            rotation: 0
        };
    }

    setTrailActive(active) {
        if (active && !this.trailActive) {
            // Start Particle System
        } else if (!active && this.trailActive) {
            // Stop Particle System
        }
        this.trailActive = active;
    }
}

class Engine {

    constructor(object) {
        this.torqueCurve = [50, 150, 200, 350, 400, 300, 150, 100]; // [100, 280, 325, 420, 460, 340, 300, 100]; 
        this.gearRatios = [14, 10, 8.5, 7, 6, 5, 4.2]; // [5.8, 4.5, 3.74, 2.8, 1.6, 0.79, 4.2];
        this.currentGear = 0;

        this.physics = {
            object: object
        };
    }

    gearRatio() {
        return this.gearRatios[this.currentGear];
    }

    effectiveGearRatio() {
        return this.gearRatios[this.gearRatios.length - 1];
    }

    shiftUp() {
        this.currentGear++;
    }

    shiftDown() {
        this.currentGear--;
    }

    torque(car) {
        return this.torqueRPM(this.rpm(car));
    }

    rpm(car) {
        return Math.mag2(car.physics.velocity) / (Math.PI * 2 / 60) * (this.gearRatio() * this.effectiveGearRatio());
    }

    torqueRPM(rpm) {
        if (rpm < 1000) {
            return Math.lerp(this.torqueCurve[0], this.torqueCurve[1], rpm / 1000);
        } else if (rpm < 2000) {
            return Math.lerp(this.torqueCurve[1], this.torqueCurve[2], (rpm - 1000) / 1000);
        } else if (rpm < 3000) {
            return Math.lerp(this.torqueCurve[2], this.torqueCurve[3], (rpm - 2000) / 1000);
        } else if (rpm < 4000) {
            return Math.lerp(this.torqueCurve[3], this.torqueCurve[4], (rpm - 3000) / 1000);
        } else if (rpm < 5000) {
            return Math.lerp(this.torqueCurve[4], this.torqueCurve[5], (rpm - 4000) / 1000);
        } else if (rpm < 6000) {
            return Math.lerp(this.torqueCurve[5], this.torqueCurve[6], (rpm - 5000) / 1000);
        } else if (rpm < 7000) {
            return Math.lerp(this.torqueCurve[6], this.torqueCurve[7], (rpm - 6000) / 1000);
        } else {
            return this.torqueCurve[6];
        }
    }

    updateAutomaticTransmission(car) {
        var rpm = this.rpm(car);
        if (rpm > 6200) {
            if (this.currentGear < 5) {
                this.currentGear++;
            }
        } else if (rpm < 2000) {
            if (this.currentGear > 0) {
                this.currentGear--;
            }
        }
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

function round(value) {
    return Math.round(value * 1000) / 1000;
}

function log(text, value) {
    if (value === undefined) {
        console.log(text);
    } else {
        console.log(`${text}: ${round(value)}`);
    }
}

function log2(text, value) {
    console.log(`${text}: (${round(value.x)}, ${round(value.y)})`);
}