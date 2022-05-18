package game.scenes.shrink.shared.Systems.PressSystem
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.hit.EntityIdList;
	import game.scenes.shrink.shared.Systems.Nodes.HitNode;
	
	import org.osflash.signals.Signal;
	
	public class Press extends Component
	{
		public var upAndDownLimits:Point;
		public var pressVelocity:Number;
		public var releaseVelocity:Number;
		public var give:Number;
		public var pressing:Boolean;
		public var pressed:Signal;
		public var released:Signal;
		public var locked:Boolean;
		public var forceRelease:Boolean;
		public var autoReleaseTime:Number;
		public var time:Number;
		public var autoReleased:Boolean;
		public var atBottom:Boolean;
		public var atTop:Boolean;
		public var hitNode:HitNode;
		public var gave:Boolean;
		
		public function Press(upAndDownLimits:Point = null, platform:Entity = null, pressVelocity:Number = 100, releaseVelocity:Number = 200, locked:Boolean = false, forceRelease:Boolean = false, autoReleaseTime:Number = 3, give:Number = 0)
		{
			this.upAndDownLimits = upAndDownLimits;
			this.pressVelocity = pressVelocity;
			this.releaseVelocity = releaseVelocity;
			this.locked = locked;
			this.forceRelease = forceRelease;
			this.autoReleaseTime = autoReleaseTime;
			this.give = give;
			
			pressed = new Signal(Entity);
			released = new Signal(Entity);
			
			pressing = atBottom = autoReleased = gave = false;
			atTop = true;
			time = 0;
			if(platform.get(EntityIdList) == null)
				platform.add(new EntityIdList());
			
			hitNode = new HitNode();
			hitNode.entity = platform;
			hitNode.idList = platform.get(EntityIdList);
			hitNode.spatial = platform.get(Spatial);
		}
		
		public function setPosition(spatial:Spatial = null, pressed:Boolean = true, locked:Boolean = true):void
		{
			if(pressed)
			{
				spatial.y = upAndDownLimits.y;
				atBottom = true;
				atTop = false;
			}
			else
			{
				spatial.y = upAndDownLimits.x;
				atTop = true;
				atBottom = false;
			}
			this.locked = locked;
		}
	}
}