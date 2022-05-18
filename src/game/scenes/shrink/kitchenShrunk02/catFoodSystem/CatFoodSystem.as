package game.scenes.shrink.kitchenShrunk02.catFoodSystem
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	
	public class CatFoodSystem extends GameSystem
	{
		public function CatFoodSystem()
		{
			super(CatFoodNode, updateNode);
		}
		
		public function updateNode(node:CatFoodNode, time:Number):void
		{
			if(!node.catFood.filling || node.catFood.data.length == 0)
				return;
			
			if(node.catFood.stacks < node.catFood.maxStacks)
				++node.catFood.stacks;
			
			var width:Number = node.catFood.stackWidth;
			var height:Number = node.catFood.stackHeight * node.catFood.stacks;
			
			var kibbleData:BitmapData = node.catFood.data[0];
			
			var kibbles:uint = Math.floor( width * node.catFood.stackHeight / kibbleData.width / kibbleData.height * node.catFood.density);
			
			trace(kibbles);
			
			for(var i:int = 0; i < kibbles; i++)
			{
				var kibbleNum:uint = Math.floor(Math.random() * node.catFood.data.length);
				kibbleData = node.catFood.data[kibbleNum];
				var bitmap:Bitmap = new Bitmap(kibbleData);
				bitmap.x = Math.random() * width - (bitmap.width / 2) - (width / 2);
				bitmap.y = Math.random() * - height - (bitmap.height / 2);
				EntityUtils.createSpatialEntity(node.entity.group, bitmap, node.display.displayObject);
			}
			
			node.catFood.filling = false;
		}
	}
}