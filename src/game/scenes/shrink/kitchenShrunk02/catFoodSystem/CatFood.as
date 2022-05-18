package game.scenes.shrink.kitchenShrunk02.catFoodSystem
{
	import ash.core.Component;
	
	public class CatFood extends Component
	{
		public var stackHeight:Number;
		public var stackWidth:Number;
		public var density:Number;
		public var stacks:uint;
		public var maxStacks:uint;
		public var data:Array;//bitmapdata
		public var filling:Boolean;
		
		public function CatFood(data:Array = null, density:Number = 5, stackHeight:Number = 30, stackWidth:Number = 150, maxStacks:uint = 3)
		{
			if(data == null)
				data = [];
			this.data = data;
			this.density = density;
			this.stackHeight = stackHeight;
			this.stackWidth = stackWidth;
			this.maxStacks = maxStacks;
			
			stacks = 0;
			filling = false;
		}
	}
}