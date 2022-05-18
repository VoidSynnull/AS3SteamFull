package game.scenes.deepDive3.shared.drone.states
{
	import game.components.entity.Sleep;

	public class DroneSleepState extends DroneState
	{
		public function DroneSleepState()
		{
			super.type = "sleep";
		}
		
		override public function start():void
		{
			this._node.entity.add(new Sleep());
			node.drone.stateChange.dispatch(super.type);
		}
		
		override public function update(time:Number):void
		{
			//trace("sleep");
		}
	}
}