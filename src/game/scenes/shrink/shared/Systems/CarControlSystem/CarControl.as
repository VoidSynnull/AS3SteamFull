package game.scenes.shrink.shared.Systems.CarControlSystem
{
	
	import ash.core.Component;
	
	import engine.components.Motion;
	
	import game.components.input.Input;
	
	public class CarControl extends Component
	{
		public var input:Input;
		public var acceleration:Number;
		public var inCar:Boolean;
		public var playerMotion:Motion;
		public var maxSpeed:Number;
		public var moving:Boolean;
		
		public function CarControl(playerMotion:Motion = null, input:Input = null, acceleration:Number = 10, maxSpeed:Number = 500)
		{
			inCar = moving = false;
			this.input = input;
			this.playerMotion = playerMotion;
			this.acceleration = acceleration;
			this.maxSpeed = maxSpeed;
		}
	}
}