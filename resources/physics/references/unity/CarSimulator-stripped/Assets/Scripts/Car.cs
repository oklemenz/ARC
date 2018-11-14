using UnityEngine;
using System.Collections.Generic;

public class Car : MonoBehaviour {

	[SerializeField]
	bool IsPlayerControlled = false;

	[SerializeField]
	[Range(0f, 1f)]
	float CGHeight = 0.55f;

	[SerializeField]
	[Range(0f, 2f)]
	float InertiaScale = 1f;

	[SerializeField]
	float BrakePower = 12000;

	[SerializeField]
	float EBrakePower = 5000;

	[SerializeField]
	[Range(0f, 1f)]
	float WeightTransfer = 0.35f;

	[SerializeField]
	[Range(0f, 1f)]
	float MaxSteerAngle = 0.75f;

	[SerializeField]
	[Range(0f, 20f)]
	float CornerStiffnessFront = 5.0f;

	[SerializeField]
	[Range(0f, 20f)]
	float CornerStiffnessRear = 5.2f;

	[SerializeField]
	[Range(0f, 20f)]
	float AirResistance = 2.5f;

	[SerializeField]
	[Range(0f, 20f)]
	float RollingResistance = 8.0f;

	[SerializeField]
	[Range(0f, 1f)]
	float EBrakeGripRatioFront = 0.9f;

	[SerializeField]
	[Range(0f, 5f)]
	float TotalTireGripFront = 2.5f;

	[SerializeField]
	[Range(0f, 1f)]
	float EBrakeGripRatioRear = 0.4f;

	[SerializeField]
	[Range(0f, 5f)]
	float TotalTireGripRear = 2.5f;

	[SerializeField]
	[Range(0f, 5f)]
	float SteerSpeed = 2.5f;

	[SerializeField]
	[Range(0f, 5f)]
	float SteerAdjustSpeed = 1f;

	[SerializeField]
	[Range(0f, 1000f)]
	float SpeedSteerCorrection = 300f;

	[SerializeField]
	[Range(0f, 20f)]
	float SpeedTurningStability = 10f;

	[SerializeField]
	[Range(0f, 10f)]
	float AxleDistanceCorrection = 2f;

	public float SpeedKilometersPerHour {
		get {
			return Velocity.magnitude * 18f / 5f;
		}
	}

	public float mass = 1500;

	// Variables that get initialized via code
	float Inertia = 1;
	float WheelBase = 1;
	float TrackWidth = 1;

	// Private vars
	float HeadingAngle;
	float AbsoluteVelocity;
	float AngularVelocity;
	float SteerDirection;
	float SteerAngle;

	public Vector2 Velocity;
	Vector2 Acceleration;
	Vector2 LocalVelocity;
	Vector2 LocalAcceleration;

	float Throttle;
	float Brake;
	float EBrake;

	Rigidbody2D Rigidbody2D;

	Axle AxleFront;
	Axle AxleRear;
	Engine Engine;

	GameObject CenterOfGravity;
	GameObject CameraView;

	int frame = 0;

	float round(float value) {
		return Mathf.Round (value * 1000) / 1000;
	}

	void log(string text) {
		System.Console.WriteLine(text);
	}

	void log(string text, float value) {
		System.Console.WriteLine(text + ": " + round(value));
	}

	void log(string text, Vector2 value) {
		System.Console.WriteLine(text + ": (" + round(value.x) + ", " + round(value.y) + ")");
	}

	void Awake() {

		CameraView = GameObject.Find ("CameraView").gameObject;

		Rigidbody2D = GetComponent<Rigidbody2D> ();
		CenterOfGravity = transform.Find ("CenterOfGravity").gameObject;

		AxleFront = transform.Find ("AxleFront").GetComponent<Axle>();
		AxleRear = transform.Find ("AxleRear").GetComponent<Axle>();

		Engine = transform.Find ("Engine").GetComponent<Engine>();

		Init ();
	}

	void Init() {

		log("");
		log("########################################");
		log("# NEW START");
		log("########################################");
		log("");

		Velocity = Vector2.zero;
		AbsoluteVelocity = 0;

		// Dimensions
		AxleFront.DistanceToCG = Mathf.Abs(CenterOfGravity.transform.position.y - AxleFront.transform.Find("Axle").transform.position.y);
		log("AxleFront.DistanceToCG", AxleFront.DistanceToCG);
		AxleRear.DistanceToCG = Mathf.Abs(CenterOfGravity.transform.position.y - AxleRear.transform.Find("Axle").transform.position.y);
		log("AxleRear.DistanceToCG", AxleRear.DistanceToCG);
		// Extend the calculations past actual car dimensions for better simulation
		AxleFront.DistanceToCG *= AxleDistanceCorrection;
		log("AxleFront.DistanceToCG", AxleFront.DistanceToCG);
		AxleRear.DistanceToCG *= AxleDistanceCorrection;
		log("AxleRear.DistanceToCG", AxleRear.DistanceToCG);
			
		WheelBase = AxleFront.DistanceToCG + AxleRear.DistanceToCG;
		log("WheelBase", WheelBase);
		Inertia = this.mass * InertiaScale;
		log("Inertia", Inertia);

		// Set starting angle of car
		Rigidbody2D.rotation = transform.rotation.eulerAngles.z;
		log("Rotation", Rigidbody2D.rotation);
		HeadingAngle = (Rigidbody2D.rotation + 90) * Mathf.Deg2Rad;
		log("HeadingAngle", HeadingAngle);
	}

	void Start() {
		
		AxleFront.Init (this, WheelBase);
		AxleRear.Init (this, WheelBase);

		TrackWidth = Mathf.Abs (AxleRear.TireLeft.transform.position.x - AxleRear.TireRight.transform.position.x);
		log("TrackWidth", TrackWidth);
	}

	void UpdateControl() {

		if (IsPlayerControlled) {

			// Handle Input
			Throttle = 0;
			Brake = 0;
			EBrake = 0;

			if (Input.GetKey (KeyCode.UpArrow)) {
				Throttle = 1;
			} else if (Input.GetKey (KeyCode.DownArrow)) { 
				//Brake = 1;
				Throttle = -1;
			} 
			if(Input.GetKey(KeyCode.Space))	{
				EBrake = 1;
			}

			float steerInput = 0;
			if(Input.GetKey(KeyCode.LeftArrow))	{
				steerInput = 1;
			}
			else if(Input.GetKey(KeyCode.RightArrow)) {
				steerInput = -1;
			}

			if (Input.GetKeyDown (KeyCode.A)) {
				Engine.ShiftUp();
			} else if (Input.GetKeyDown (KeyCode.Z)) {
				Engine.ShiftDown();
			}

			// TODO: Remove Auto Control
			Throttle = 1;
			steerInput = 1;

			// Apply filters to our steer direction
			SteerDirection = SmoothSteering (steerInput);
			log("SteerDirection", SteerDirection);
			SteerDirection = SpeedAdjustedSteering (SteerDirection);
			log("SteerDirection", SteerDirection);

			// Calculate the current angle the tires are pointing
			SteerAngle = SteerDirection * MaxSteerAngle;
			log("SteerAngle", SteerAngle);

			// Set front axle tires rotation
			AxleFront.TireRight.transform.localRotation = Quaternion.Euler(0, 0, Mathf.Rad2Deg * SteerAngle);
			AxleFront.TireLeft.transform.localRotation = Quaternion.Euler(0, 0, Mathf.Rad2Deg * SteerAngle);
		}			


		// Calculate weight center of four tires
		// This is just to draw that red dot over the car to indicate what tires have the most weight
		/*Vector2 pos = Vector2.zero;
		if (LocalAcceleration.magnitude > 1f) {

			float wfl = Mathf.Max (0, (AxleFront.TireLeft.ActiveWeight - AxleFront.TireLeft.RestingWeight));
			float wfr = Mathf.Max (0, (AxleFront.TireRight.ActiveWeight - AxleFront.TireRight.RestingWeight));
			float wrl = Mathf.Max (0, (AxleRear.TireLeft.ActiveWeight - AxleRear.TireLeft.RestingWeight));
			float wrr = Mathf.Max (0, (AxleRear.TireRight.ActiveWeight - AxleRear.TireRight.RestingWeight));

			pos = (AxleFront.TireLeft.transform.localPosition) * wfl +
				(AxleFront.TireRight.transform.localPosition) * wfr +
			    (AxleRear.TireLeft.transform.localPosition) * wrl +
				(AxleRear.TireRight.transform.localPosition) * wrr;
		
			float weightTotal = wfl + wfr + wrl + wrr;

			if (weightTotal > 0) {
				pos /= weightTotal;
				pos.Normalize ();
				pos.x = Mathf.Clamp (pos.x, -0.6f, 0.6f);
			} else {
				pos = Vector2.zero;
			}
		}

		// Update the "Center Of Gravity" dot to indicate the weight shift
		CenterOfGravity.transform.localPosition = Vector2.Lerp (CenterOfGravity.transform.localPosition, pos, 0.1f);

		// Skidmarks
		if (Mathf.Abs (LocalAcceleration.y) > 18 || EBrake == 1) {
			AxleRear.TireRight.SetTrailActive (true);
			AxleRear.TireLeft.SetTrailActive (true);
		} else {
			AxleRear.TireRight.SetTrailActive (false);
			AxleRear.TireLeft.SetTrailActive (false);
		}*/

		// Automatic transmission
		Engine.UpdateAutomaticTransmission (this);

        // Update camera
        if (IsPlayerControlled)
        {
            CameraView.transform.position = this.transform.position;
        }
	}
			
	void FixedUpdate() {

		log("");
		log("########################################");
		log("# START FRAME " + frame);
		log("########################################");
		log("");

		// Update from rigidbody to retain collision responses
		//Velocity = Rigidbody2D.velocity;
		log("Velocity", Velocity);
		log("Rotation", Rigidbody2D.rotation);
		HeadingAngle = (Rigidbody2D.rotation + 90) * Mathf.Deg2Rad;
		log("HeadingAngle", HeadingAngle);

		float sin = Mathf.Sin(HeadingAngle);
		log("sin", sin);
		float cos = Mathf.Cos(HeadingAngle);
		log("cos", cos);

		// Get local velocity
		LocalVelocity.x = cos * Velocity.x + sin * Velocity.y;
		log("LocalVelocity.x", LocalVelocity.x);
		LocalVelocity.y = cos * Velocity.y - sin * Velocity.x;
		log("LocalVelocity.y", LocalVelocity.y);

		// Weight transfer
		float transferX = WeightTransfer * LocalAcceleration.x * CGHeight / WheelBase;
		log("transferX", transferX);
		float transferY = WeightTransfer * LocalAcceleration.y * CGHeight / TrackWidth * 20;		//exagerate the weight transfer on the y-axis
		log("transferY", transferY);

		// Weight on each axle
		float weightFront = this.mass * (AxleFront.WeightRatio * -Physics2D.gravity.y - transferX);
		log("weightFront", weightFront);
		float weightRear = this.mass * (AxleRear.WeightRatio * -Physics2D.gravity.y + transferX);
		log("weightRear", weightRear);

		// Weight on each tire
		AxleFront.TireLeft.ActiveWeight = weightFront - transferY;
		log("AxleFront.TireLeft.ActiveWeight", AxleFront.TireLeft.ActiveWeight);
		AxleFront.TireRight.ActiveWeight = weightFront + transferY;
		log("AxleFront.TireRight.ActiveWeight", AxleFront.TireRight.ActiveWeight);
		AxleRear.TireLeft.ActiveWeight = weightRear - transferY;
		log("AxleRear.TireLeft.ActiveWeight", AxleRear.TireLeft.ActiveWeight);
		AxleRear.TireRight.ActiveWeight = weightRear + transferY;
		log("AxleRear.TireRight.ActiveWeight", AxleRear.TireRight.ActiveWeight);
			
		// Velocity of each tire
		AxleFront.TireLeft.AngularVelocity = AxleFront.DistanceToCG * AngularVelocity;
		log("AxleFront.TireLeft.AngularVelocity", AxleFront.TireLeft.AngularVelocity);
		AxleFront.TireRight.AngularVelocity = AxleFront.DistanceToCG * AngularVelocity;
		log("AxleFront.TireRight.AngularVelocity", AxleFront.TireRight.AngularVelocity);
		AxleRear.TireLeft.AngularVelocity = -AxleRear.DistanceToCG * AngularVelocity;
		log("AxleRear.TireLeft.AngularVelocity", AxleRear.TireLeft.AngularVelocity);
		AxleRear.TireRight.AngularVelocity = -AxleRear.DistanceToCG *  AngularVelocity;
		log("AxleRear.TireRight.AngularVelocity", AxleRear.TireRight.AngularVelocity);

		// Slip angle
		AxleFront.SlipAngle = Mathf.Atan2(LocalVelocity.y + AxleFront.AngularVelocity, Mathf.Abs(LocalVelocity.x)) - Mathf.Sign(LocalVelocity.x) * SteerAngle;
		log("AxleFront.SlipAngle", AxleFront.SlipAngle);
		AxleRear.SlipAngle = Mathf.Atan2(LocalVelocity.y + AxleRear.AngularVelocity,  Mathf.Abs(LocalVelocity.x));
		log("AxleRear.SlipAngle", AxleRear.SlipAngle);

		// Brake and Throttle power
		float activeBrake = Mathf.Min(Brake * BrakePower + EBrake * EBrakePower, BrakePower);
		log("activeBrake", activeBrake);
		float activeThrottle = (Throttle * Engine.GetTorque (this)) * (Engine.GearRatio * Engine.EffectiveGearRatio);
		log("activeThrottle", activeThrottle);

		// Torque of each tire (rear wheel drive)
		AxleRear.TireLeft.Torque = activeThrottle / AxleRear.TireLeft.Radius;
		log("AxleRear.TireLeft.Torque", AxleRear.TireLeft.Torque);
		AxleRear.TireRight.Torque = activeThrottle / AxleRear.TireRight.Radius;
		log("AxleRear.TireRight.Torque", AxleRear.TireRight.Torque);

		// Grip and Friction of each tire
		AxleFront.TireLeft.Grip = TotalTireGripFront * (1.0f - EBrake * (1.0f - EBrakeGripRatioFront));
		log("AxleFront.TireLeft.Grip", AxleFront.TireLeft.Grip);
		AxleFront.TireRight.Grip = TotalTireGripFront * (1.0f - EBrake * (1.0f - EBrakeGripRatioFront));
		log("AxleFront.TireRight.Grip", AxleFront.TireRight.Grip);
		AxleRear.TireLeft.Grip = TotalTireGripRear * (1.0f - EBrake * (1.0f - EBrakeGripRatioRear));
		log("AxleRear.TireLeft.Grip", AxleRear.TireLeft.Grip);
		AxleRear.TireRight.Grip = TotalTireGripRear * (1.0f - EBrake * (1.0f - EBrakeGripRatioRear));
		log("AxleRear.TireRight.Grip", AxleRear.TireRight.Grip);

		AxleFront.TireLeft.FrictionForce = Mathf.Clamp(-CornerStiffnessFront * AxleFront.SlipAngle, -AxleFront.TireLeft.Grip, AxleFront.TireLeft.Grip) * AxleFront.TireLeft.ActiveWeight;
		log("AxleFront.TireLeft.FrictionForce", AxleFront.TireLeft.FrictionForce);
		AxleFront.TireRight.FrictionForce = Mathf.Clamp(-CornerStiffnessFront * AxleFront.SlipAngle, -AxleFront.TireRight.Grip, AxleFront.TireRight.Grip) * AxleFront.TireRight.ActiveWeight;
		log("AxleFront.TireRight.FrictionForce", AxleFront.TireRight.FrictionForce);
		AxleRear.TireLeft.FrictionForce = Mathf.Clamp(-CornerStiffnessRear * AxleRear.SlipAngle, -AxleRear.TireLeft.Grip, AxleRear.TireLeft.Grip) * AxleRear.TireLeft.ActiveWeight;
		log("AxleRear.TireLeft.FrictionForce", AxleRear.TireLeft.FrictionForce);
		AxleRear.TireRight.FrictionForce = Mathf.Clamp(-CornerStiffnessRear * AxleRear.SlipAngle, -AxleRear.TireRight.Grip, AxleRear.TireRight.Grip) * AxleRear.TireRight.ActiveWeight;
		log("AxleRear.TireRight.FrictionForce", AxleRear.TireRight.FrictionForce);

	 	// Forces
		float tractionForceX = AxleRear.Torque - activeBrake * Mathf.Sign(LocalVelocity.x);
		log("tractionForceX", tractionForceX);
		float tractionForceY = 0;

		float dragForceX = -RollingResistance * LocalVelocity.x - AirResistance * LocalVelocity.x * Mathf.Abs(LocalVelocity.x);
		log("dragForceX", dragForceX);
		float dragForceY = -RollingResistance * LocalVelocity.y - AirResistance * LocalVelocity.y * Mathf.Abs(LocalVelocity.y);
		log("dragForceY", dragForceY);

		float totalForceX = dragForceX + tractionForceX;
		log("totalForceX", totalForceX);
		float totalForceY = dragForceY + tractionForceY + Mathf.Cos (SteerAngle) * AxleFront.FrictionForce + AxleRear.FrictionForce;
		log("totalForceY", totalForceY);

		log ("SpeedTurningStability", SpeedTurningStability);
		//adjust Y force so it levels out the car heading at high speeds
		if (AbsoluteVelocity > 10) {
			totalForceY *= (AbsoluteVelocity + 1) / (21f - SpeedTurningStability);
		}
		log("totalForceY", totalForceY);

		// If we are not pressing gas, add artificial drag - helps with simulation stability
		if (Throttle == 0) {
			Velocity = Vector2.Lerp (Velocity, Vector2.zero, 0.005f);
		}
		log("Velocity", Velocity);
	
		// Acceleration
		LocalAcceleration.x = totalForceX / this.mass;
		log("LocalAcceleration.x", LocalAcceleration.x);
		LocalAcceleration.y = totalForceY / this.mass;
		log("LocalAcceleration.y", LocalAcceleration.y);

		Acceleration.x = cos * LocalAcceleration.x - sin * LocalAcceleration.y;
		log("Acceleration.x", Acceleration.x);
		Acceleration.y = sin * LocalAcceleration.x + cos * LocalAcceleration.y;
		log("Acceleration.y", Acceleration.y);

		// Velocity and speed
		Velocity.x += Acceleration.x * Time.deltaTime;
		log("Velocity.x", Velocity.x);
		Velocity.y += Acceleration.y * Time.deltaTime;
		log("Velocity.y", Velocity.y);

		AbsoluteVelocity = Velocity.magnitude;
		log("AbsoluteVelocity", AbsoluteVelocity);

		// Angular torque of car
		float angularTorque = (AxleFront.FrictionForce * AxleFront.DistanceToCG) - (AxleRear.FrictionForce * AxleRear.DistanceToCG);
		log("angularTorque", angularTorque);

		// Car will drift away at low speeds
		if (AbsoluteVelocity < 0.5f && activeThrottle == 0)
		{
			LocalAcceleration = Vector2.zero;
			AbsoluteVelocity = 0;
			Velocity = Vector2.zero;
			angularTorque = 0;
			AngularVelocity = 0;
			Acceleration = Vector2.zero;
			//Rigidbody2D.angularVelocity = 0;
		}

		var angularAcceleration = angularTorque / Inertia;
		log("angularAcceleration", angularAcceleration);

		// Update 
		AngularVelocity += angularAcceleration * Time.deltaTime;
		log("AngularVelocity", AngularVelocity);

		log("SpeedKilometersPerHour", SpeedKilometersPerHour);
		// Simulation likes to calculate high angular velocity at very low speeds - adjust for this
		if (AbsoluteVelocity < 1 && Mathf.Abs (SteerAngle) < 0.05f) {
			AngularVelocity = 0;
		} else if (SpeedKilometersPerHour < 0.75f) {
			AngularVelocity = 0;
		}
		log("AngularVelocity", AngularVelocity);

		HeadingAngle += AngularVelocity * Time.deltaTime;
		log("HeadingAngle", HeadingAngle);
		Rigidbody2D.position += Velocity * Time.deltaTime; 
		log("Rigidbody2D.position", Rigidbody2D.position);
		Rigidbody2D.rotation = (Mathf.Rad2Deg * HeadingAngle - 90);
		log("Rigidbody2D.rotation", Rigidbody2D.rotation);

		//Rigidbody2D.velocity = Velocity;
		//Rigidbody2D.MoveRotation (Mathf.Rad2Deg * HeadingAngle - 90);

		log("");
		log("########################################");
		log("# END FRAME " + frame);
		log("########################################");
		log("");

		frame++;
		if (frame == 5) {
			Debug.Break ();
		}

		UpdateControl ();
	}

	float SmoothSteering(float steerInput) {

		float steer = 0;

		if(Mathf.Abs(steerInput) > 0.001f) {
			log ("DT: ", Time.deltaTime);
			steer = Mathf.Clamp(SteerDirection + steerInput * Time.deltaTime * SteerSpeed, -1.0f, 1.0f); 
		}
		else
		{
			if (SteerDirection > 0) {
				steer = Mathf.Max(SteerDirection - Time.deltaTime * SteerAdjustSpeed, 0);
			}
			else if (SteerDirection < 0) {
				steer = Mathf.Min(SteerDirection + Time.deltaTime * SteerAdjustSpeed, 0);
			}
		}

		return steer;
	}

	float SpeedAdjustedSteering(float steerInput) {
		float activeVelocity = Mathf.Min(AbsoluteVelocity, 250.0f);
		float steer = steerInput * (1.0f - (AbsoluteVelocity / SpeedSteerCorrection));
		return steer;
	}

	void OnGUI (){
        if (IsPlayerControlled)
        {
            GUI.Label(new Rect(5, 5, 300, 20), "Speed: " + SpeedKilometersPerHour.ToString());
            GUI.Label(new Rect(5, 25, 300, 20), "RPM: " + Engine.GetRPM(this).ToString());
            GUI.Label(new Rect(5, 45, 300, 20), "Gear: " + (Engine.CurrentGear + 1).ToString());
            GUI.Label(new Rect(5, 65, 300, 20), "LocalAcceleration: " + LocalAcceleration.ToString());
            GUI.Label(new Rect(5, 85, 300, 20), "Acceleration: " + Acceleration.ToString());
            GUI.Label(new Rect(5, 105, 300, 20), "LocalVelocity: " + LocalVelocity.ToString());
            GUI.Label(new Rect(5, 125, 300, 20), "Velocity: " + Velocity.ToString());
            GUI.Label(new Rect(5, 145, 300, 20), "SteerAngle: " + SteerAngle.ToString());
            GUI.Label(new Rect(5, 165, 300, 20), "Throttle: " + Throttle.ToString());
            GUI.Label(new Rect(5, 185, 300, 20), "Brake: " + Brake.ToString());

            GUI.Label(new Rect(5, 205, 300, 20), "HeadingAngle: " + HeadingAngle.ToString());
            GUI.Label(new Rect(5, 225, 300, 20), "AngularVelocity: " + AngularVelocity.ToString());

            GUI.Label(new Rect(5, 245, 300, 20), "TireFL Weight: " + AxleFront.TireLeft.ActiveWeight.ToString());
            GUI.Label(new Rect(5, 265, 300, 20), "TireFR Weight: " + AxleFront.TireRight.ActiveWeight.ToString());
            GUI.Label(new Rect(5, 285, 300, 20), "TireRL Weight: " + AxleRear.TireLeft.ActiveWeight.ToString());
            GUI.Label(new Rect(5, 305, 300, 20), "TireRR Weight: " + AxleRear.TireRight.ActiveWeight.ToString());

            GUI.Label(new Rect(5, 325, 300, 20), "TireFL Friction: " + AxleFront.TireLeft.FrictionForce.ToString());
            GUI.Label(new Rect(5, 345, 300, 20), "TireFR Friction: " + AxleFront.TireRight.FrictionForce.ToString());
            GUI.Label(new Rect(5, 365, 300, 20), "TireRL Friction: " + AxleRear.TireLeft.FrictionForce.ToString());
            GUI.Label(new Rect(5, 385, 300, 20), "TireRR Friction: " + AxleRear.TireRight.FrictionForce.ToString());

            GUI.Label(new Rect(5, 405, 300, 20), "TireFL Grip: " + AxleFront.TireLeft.Grip.ToString());
            GUI.Label(new Rect(5, 425, 300, 20), "TireFR Grip: " + AxleFront.TireRight.Grip.ToString());
            GUI.Label(new Rect(5, 445, 300, 20), "TireRL Grip: " + AxleRear.TireLeft.Grip.ToString());
            GUI.Label(new Rect(5, 465, 300, 20), "TireRR Grip: " + AxleRear.TireRight.Grip.ToString());

            GUI.Label(new Rect(5, 485, 300, 20), "AxleF SlipAngle: " + AxleFront.SlipAngle.ToString());
            GUI.Label(new Rect(5, 505, 300, 20), "AxleR SlipAngle: " + AxleRear.SlipAngle.ToString());

            GUI.Label(new Rect(5, 525, 300, 20), "AxleF Torque: " + AxleFront.Torque.ToString());
            GUI.Label(new Rect(5, 545, 300, 20), "AxleR Torque: " + AxleRear.Torque.ToString());

			GUI.Label(new Rect(5, 565, 300, 20), "AxleR Rotation: " + AxleFront.TireLeft.transform.localRotation.ToString());
        }
	}

}
