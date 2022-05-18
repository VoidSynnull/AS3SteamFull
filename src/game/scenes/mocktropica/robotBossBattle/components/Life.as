package game.scenes.mocktropica.robotBossBattle.components {

	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;

	public class Life extends Component {

		public var onDie:Signal;

		public var alive:Boolean;
		public var _hittable:Boolean;
		public var resetting:Boolean;

		/**
		 * Reset time before it can be hit again.
		 */
		public var hitResetTime:int = 3;
		public var hitResetTimer:Number;

		public var life:int;

		public function Life( startLife:int=100 ) {

			this._hittable = true;
			this.resetting = false;
			this.alive = true;

			this.life = startLife;
			this.onDie = new Signal( Entity );

		} //

		public function hit( loseAmt:int=1 ):void {

			this.life -= loseAmt;
			if ( this.hitResetTime > 0 ) {
				this.hitResetTimer = this.hitResetTime;
				this.resetting = true;
			}

		} //

		public function waitReset():void {

			this.hitResetTime = this.hitResetTimer;
			this.resetting = true;

		} //

		public function set hittable( b:Boolean ):void {
			this._hittable = b;
		} //

		public function get hittable():Boolean {
			return ( this.alive && this._hittable && !resetting );
		}

	} // End Life

} // End package