package game.scenes.con3.omegon.omegonHand
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.components.hit.Hazard;
	import game.components.hit.Platform;
	import game.components.timeline.Timeline;
	import game.scenes.con3.shared.rayReflect.RayToReflectCollision;
	
	import org.osflash.signals.Signal;
	
	public class OmegonHand extends Component
	{
		//Damaged
		//Repairing
		//Idle
		//Attack
		
		//public var STATE_
		internal var _invalidate:Boolean = false;
		internal var _state:String;
		
		public var isLeft:Boolean = false;
		
		public var hand_platform:Entity;
		public var hand_hazard:Entity;
		public var power_source:Entity;
		public var power_hit:Entity;
		public var laser_arm_left:Entity;
		public var laser_arm_right:Entity;
		
		public var laser_left:Entity;
		public var laser_right:Entity;
		public var laser_control:Entity;
		
		public var removedPlatform:Platform;
		public var removedHazard:Hazard;
		
		public var stateChanged:Signal = new Signal(Entity);
		
		public function OmegonHand()
		{
			
		}
		
		public function get state():String
		{
			return this._state;
		}
		
		public function set state(state:String):void
		{
			this._state = state;
			this._invalidate = true;
		}
		
		public function pulse_hit():void
		{
			if(this.state == "damaged")
			{
				this.state = "pulsed";
			}
		}
		
		public function power_hit_hit(entity:Entity, hitId:String):void
		{
			var timeline:Timeline = power_source.get(Timeline);
			
			var laser:Entity = entity.group.getEntityById(hitId);
			var rayToReflectCollision:RayToReflectCollision = laser.get(RayToReflectCollision);
			
			if(timeline.currentIndex == 0 && rayToReflectCollision && rayToReflectCollision.parent)
			{
				timeline.gotoAndPlay("glow");
				this.state = "damaged";
				
				timeline = laser_left.get(Timeline);
				timeline.gotoAndPlay("off");
				
				timeline = laser_right.get(Timeline);
				timeline.gotoAndPlay("off");
			}
		}
	}
}