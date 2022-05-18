package game.scenes.arab1.shared.components
{
	import ash.core.Component;
	
	import game.components.hit.Hazard;
	import game.components.hit.Zone;
		
	public class SandScorpion extends Component
	{
		public var enabled:Boolean = true;
		public var hidden:Boolean = true;
	
		//public var range:Number = 200;
		public var speed:Number = 80;
		
		public var delay:Number = 1.2;
		public var scale:Number = 1;
		
		public var hazard:Hazard;
		public var zone:Zone;
		
		public var direction:String = "right";
		
		override public function destroy():void{
			hazard = null;
			zone = null;
			super.destroy();
		}
	}
}