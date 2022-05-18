package game.scenes.mocktropica.cheeseInterior.components {

	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;

	public class CheeseMachine extends Component {

		public var _wheel:Entity;
		public var _indicator:Entity;

		/**
		 * Speed machine is running at as percent of the normal animation speed.
		 */
		public var machineSpeed:Number = 1;

		public var targetSpeed:Number;

		// If true, count down to machine break.
		public var _breakMachine:Boolean = false;

		/**
		 * Timer for controlling machine breakage.
		 */
		public var breakTimer:Number = 0;
		/**
		 * Triggered when the stupid machine finally breaks. onMachineBroken( machine entity )
		 */
		public var onMachineBroken:Signal;

		public function CheeseMachine( wheel:Entity, indicator:Entity ) {

			this._wheel = wheel;
			this._indicator = indicator;

			this.targetSpeed = this.machineSpeed;

			this.onMachineBroken = new Signal( Entity, CheeseMachine );

		} //

		public function breakMachine( breakTime:Number ):void {

			this._breakMachine = true;
			this.breakTimer = breakTime;

		} //

		public function setTargetSpeed( target:Number ):void {
			this.targetSpeed = target;
		}

	} // End CheeseAssemblyLine

} // End package