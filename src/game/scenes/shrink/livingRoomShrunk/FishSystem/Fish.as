package game.scenes.shrink.livingRoomShrunk.FishSystem
{
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	import game.components.hit.Zone;
	
	public class Fish extends Component
	{
		public var tank:Rectangle;
		public var state:String = "idle";
		public var speed:Number;
		public var direction:int = 1;
		
		public var food:Spatial;
		public var territory:Zone;
		public var inTerritory:Boolean = false;
		public var intruder:String;
		public var isEating:Boolean = false;
		
		public const ANGRY:String = "angry";
		public const IDLE:String = "idle";
		public const FEEDING:String	= "feeding";
		
		public function Fish(tank:Rectangle, territory:Zone, speed:Number = 200)
		{
			this.tank = tank;
			this.territory = territory;
			this.speed = speed;
			this.territory.inside.add(yoInMyBubble);
			this.territory.exitted.add(itsAllCool);
		}
		
		public function yoInMyBubble(zone:String, intruder:String):void
		{
			inTerritory = true;
			this.intruder = intruder;
		}
		
		public function itsAllCool(...args):void
		{
			inTerritory = false;
		}
		
		public function feast(food:Spatial):void
		{
			this.food = food;
		}
	}
}