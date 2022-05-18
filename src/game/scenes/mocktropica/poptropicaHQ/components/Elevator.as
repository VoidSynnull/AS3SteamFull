package game.scenes.mocktropica.poptropicaHQ.components
{
	import ash.core.Component;
	
	import org.as3commons.collections.ArrayList;

	/**
	 * Floor is what floor the elevator is currently on. For Poptropica HQ, this is the first (1) floor to start.
	 * IsMoving is a flag to determine whether the elevator is currently in motion. That way the elevator doesn't
	 * tween to another floor while it's currently moving. 'Cause that's bad news. Floors is a list of y values
	 * for each floor of the building for the elevator to tween to.
	 */
	public class Elevator extends Component
	{
		private var _floor:int;
		private var _isMoving:Boolean;
		private var _floors:ArrayList;
		
		public function Elevator(floor:int)
		{
			this._floor = floor;
			this._isMoving = false;
			this._floors = new ArrayList();
		}
		
		public function get floor():int { return this._floor; }
		public function set floor(floor:int):void { this._floor = floor; }
		
		public function get isMoving():Boolean { return this._isMoving; }
		public function set isMoving(isMoving:Boolean):void { this._isMoving = isMoving; }
		
		public function get floors():ArrayList { return this._floors; }
	}
}