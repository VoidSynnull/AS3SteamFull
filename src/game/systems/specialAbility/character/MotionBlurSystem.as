package game.systems.specialAbility.character
{
	import com.greensock.easing.Quad;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.nodes.specialAbility.character.MotionBlurNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.BitmapUtils;
	import game.util.ColorUtil;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.TweenUtils;
	
	public class MotionBlurSystem extends GameSystem
	{
		public function MotionBlurSystem()
		{
			super(MotionBlurNode, updateNode);
			super._defaultPriority = SystemPriorities.postRender;
		}
		
		public function updateNode(node:MotionBlurNode, time:Number):void
		{
			node.blur.time += time;
			if(node.blur.time > node.blur.rate)
				createBlur(node);
		}
		
		private function createBlur(node:MotionBlurNode):void
		{
			node.blur.time = 0;
			if(node.display.displayObject.width == 0 || !node.display.visible)
				return;
			var blurDisplay:Sprite = BitmapUtils.createBitmapSprite(node.display.displayObject, node.blur.quality);
			if(node.blur.colorize)
				ColorUtil.colorize(blurDisplay, node.blur.color);
			
			var blur:Entity = EntityUtils.createSpatialEntity(node.entity.group, blurDisplay, node.display.container);
			if(!isNaN(node.blur.startAlpha))
				blur.get(Display).alpha = node.blur.startAlpha;
			
			DisplayUtils.moveToOverUnder(blurDisplay, node.display.displayObject, false);
			
			TweenUtils.entityTo(blur, Display,node.blur.lifeTime, {alpha:0, ease:Quad.easeIn,onComplete:Command.create(removeBlur, node.entity.group, blur)});
		}
		
		private function removeBlur(owningGroup:Group, blur:Entity):void
		{
			var display:Display = blur.get(Display);
			var bitmap:Bitmap = display.displayObject.getChildAt(0) as Bitmap;
			bitmap.bitmapData.dispose();
			owningGroup.removeEntity(blur);
		}
	}
}