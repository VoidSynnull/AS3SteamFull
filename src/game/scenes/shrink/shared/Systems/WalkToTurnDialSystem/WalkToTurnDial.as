package game.scenes.shrink.shared.Systems.WalkToTurnDialSystem
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.hit.EntityIdList;
	
	import org.osflash.signals.Signal;
	
	public class WalkToTurnDial extends Component
	{
		public var value:Number = 0;
		
		public var maxValue:Number;
		public var minValue:Number;
		public var offValue:Number;
		
		public var platform:Entity;
		public var platformSpatial:Spatial;
		public var entityIdList:EntityIdList;
		
		public var valueScale:Number;
		
		public var rotate:Boolean;
		
		public var loop:Boolean;
		
		public var dialOn:Signal;
		public var dialOff:Signal;
		
		public var on:Boolean;
		
		public function WalkToTurnDial(platform:Entity, rotate:Boolean = true, loop:Boolean = true, maxValue:Number = 100, minValue:Number = 0, valueScale:Number = 1, offValue:Number = NaN)
		{
			this.rotate = rotate;
			this.loop = loop;
			this.platform = platform;
			this.valueScale = valueScale;
			this.maxValue = maxValue;
			this.minValue = minValue;
			if(isNaN(offValue))
				offValue = (maxValue + minValue) / 2;
			this.offValue = value = offValue;
			on = false;
			
			dialOn = new Signal();
			dialOff = new Signal();
			
			if(this.platform.get(EntityIdList) == null)
				this.platform.add(new EntityIdList());
			platformSpatial = platform.get(Spatial);
			entityIdList = this.platform.get(EntityIdList);
		}
	}
}