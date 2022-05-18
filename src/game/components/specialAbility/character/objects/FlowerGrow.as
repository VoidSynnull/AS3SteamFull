package game.components.specialAbility.character.objects
{
	import flash.display.Graphics;
	import flash.display.Shape;
	
	import ash.core.Component;

	
	
	public class FlowerGrow extends Component
	{
		public var vine:Shape;
		public var g:Graphics;
		public var r:Number = 5;
		public var turn:Number;
		public var angle:Number = -Math.PI/2;
		public var nx:Number = 0;
		public var ny:Number = 0;
		public var count:Number = 0;
		public var wait:Number = 0;
		public var maxWait:Number;
		public var lineWidth:Number;
		public var headAdded:Boolean;
		
		
		
		public function FlowerGrow()
		{
			turn = Math.random()*0.4 - 0.2;
			maxWait = Math.random()*10 + 6;
			lineWidth = Math.random()*2 + 2;
		}
	}
}