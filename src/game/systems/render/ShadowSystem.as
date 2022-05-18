package game.systems.render
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	
	import game.components.motion.FollowTarget;
	import game.components.render.Shadow;
	import game.nodes.render.ShadowNode;
	import game.systems.GameSystem;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PointUtils;
	
	public class ShadowSystem extends GameSystem
	{
		public function ShadowSystem()
		{
			super(ShadowNode, updateNode,addNode, removeNode);
		}
		
		private function addNode(node:ShadowNode):void
		{
			var group:DisplayGroup = node.entity.group as DisplayGroup;
			
			var matrixBlack:Array = [0,0,0,0,0];//r
			matrixBlack = matrixBlack.concat([0,0,0,0,0]);//g
			matrixBlack = matrixBlack.concat([0,0,0,0,0]);//b
			matrixBlack = matrixBlack.concat([0,0,0,1,0]);//a
			node.display.displayObject.filters = [new ColorMatrixFilter(matrixBlack)];
			
			var sprite:Sprite = BitmapUtils.createBitmapSprite(node.display.displayObject,node.shadow.quality);
			node.display.displayObject.filters = [];
			
			node.shadow.shadow = EntityUtils.createSpatialEntity(group, sprite, node.display.container);
			node.shadow.source = new FollowTarget(node.spatial,1);
			node.shadow.source.offset = new Point(node.shadow.offSetX, node.shadow.offSetY);
			node.shadow.source.properties = new <String>["x","y","rotation"];
			node.shadow.display = node.shadow.shadow.get(Display);
			node.shadow.spatial = node.shadow.shadow.get(Spatial);
			node.shadow.shadow.add(node.shadow.source);
			DisplayUtils.moveToOverUnder(node.shadow.display.displayObject, node.display.displayObject, false);
		}
		
		private function removeNode(node:ShadowNode):void
		{
			var bitmap:Bitmap = node.shadow.display.displayObject.getChildAt(0);
			bitmap.bitmapData.dispose();
			node.entity.group.removeEntity(node.shadow.shadow);
			node.shadow.shadow = null;
			node.shadow.spatial = null;
			node.shadow.display = null;
			node.shadow.source = null;
		}
		
		private function updateNode(node:ShadowNode, time:Number):void
		{
			if(node.timeline)
			{
				if(node.timeline.playing)
					updateShadowImage(node);
			}
			
			var shadow:Shadow = node.shadow;
			
			var difference:Number = shadow.maxAlpha - shadow.minAlpha;
			
			var offset:Point = new Point(shadow.offSetX, shadow.offSetY);
			if(node.lightSource)
				offset = offset.add(new Point(node.lightSource.target.x - shadow.source.target.x, node.lightSource.target.y - shadow.source.target.y));
			
			shadow.source.offset = PointUtils.times(offset, shadow.minAlpha + difference * shadow.median);
			
			shadow.display.alpha = 1- (shadow.minAlpha + difference * shadow.median);
			
			var scale:Number = shadow.scaleGrowth * shadow.median;
			
			shadow.spatial.scaleX = node.spatial.scaleX > 0?node.spatial.scaleX + scale:node.spatial.scaleX - scale;
			shadow.spatial.scaleY = node.spatial.scaleY > 0?node.spatial.scaleY + scale:node.spatial.scaleY - scale;
		}
		
		private function updateShadowImage(node:ShadowNode):void
		{
			var bitmap:Bitmap = node.shadow.display.displayObject.getChildAt(0);
			bitmap.bitmapData.dispose();
			
			var matrixBlack:Array = [0,0,0,0,0];//r
			matrixBlack = matrixBlack.concat([0,0,0,0,0]);//g
			matrixBlack = matrixBlack.concat([0,0,0,0,0]);//b
			matrixBlack = matrixBlack.concat([0,0,0,1,0]);//a
			node.display.displayObject.filters = [new ColorMatrixFilter(matrixBlack)];
			
			bitmap.bitmapData = BitmapUtils.createBitmapData(node.display.displayObject, node.shadow.quality);
			node.display.displayObject.filters = [];
		}
	}
}