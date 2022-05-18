package game.data.specialAbility.store
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Camera;
	import engine.components.Display;
	
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.BitmapUtils;
	
	public class SilentTreatment extends SpecialAbility
	{
		private var sepiaFilter:ColorMatrixFilter = new ColorMatrixFilter(new Array(0.216138216228495,0.669330768683011,0.114531015088494,0, 0,0.215763737712201,0.726603635387892,0.057632626899907,0,0,0.172068030845656,0.736518791069203,0.0914131780851403,0,0,0,0,0,1,0));
		
		public function SilentTreatment()
		{
			super();
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			this.setActive(true);
			
			var camera:Entity = node.entity.group.getEntityById("camera");
			Display(camera.get(Display)).alpha = 0;
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			var camera:Entity = node.entity.group.getEntityById("camera");
			//camera.get(Display).alpha = 0;
			var cam:Camera = camera.get(Camera);
			var bounds:Rectangle =  new Rectangle(-cam.viewport.width/2, -cam.viewport.height/2, cam.viewport.width, cam.viewport.height);
			
			var bitmap:Bitmap = shellApi.currentScene.overlayContainer.getChildByName("treatment") as Bitmap;
			if(!bitmap)
			{
				bitmap = new Bitmap();
				bitmap.name = "treatment";
				bitmap.bitmapData = new BitmapData(bounds.width, bounds.height, true, 0);
				shellApi.currentScene.overlayContainer.addChildAt(bitmap, 0);
			}
			
			bitmap.bitmapData.dispose();
			bitmap.bitmapData = BitmapUtils.createBitmapData(this.shellApi.currentScene.groupContainer, 1, bounds);
			bitmap.bitmapData.applyFilter(bitmap.bitmapData, bitmap.bitmapData.rect, new Point(), sepiaFilter);
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			this.setActive(false);
			if(shellApi.currentScene.overlayContainer)
			{
				var bitmap:Bitmap = shellApi.currentScene.overlayContainer.getChildByName("treatment") as Bitmap;
				if(bitmap)
				{
					bitmap.bitmapData.dispose();
					this.shellApi.currentScene.overlayContainer.removeChild(bitmap);
				}
			}
			var camera:Entity = node.entity.group.getEntityById("camera");
			Display(camera.get(Display)).alpha = 1;
		}
	}
}