package game.scenes.cavern1.caveEntrance
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.components.hit.Mover;
	
	public class WaterGeyser extends Component
	{
		public var mover:Mover;
		public var moverEntity:Entity;
		public var platform:Entity;
		public var upTime:Number;
		public var downTime:Number;
		public var active:Boolean;
		public var timer:Number;
		public function WaterGeyser(moverEntity:Entity, platform:Entity = null, upTime:Number = 3, downTime:Number = 3, active:Boolean = true)
		{
			this.moverEntity = moverEntity;
			mover = moverEntity.get(Mover);
			this.platform = platform;
			this.upTime = upTime;
			this.downTime = downTime;
			this.active = active;
		}
	}
}