package game.data.specialAbility.store
{
	import com.greensock.easing.Linear;
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.hit.CurrentHit;
	import game.components.motion.Edge;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.ui.card.CharacterContentView;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.TweenUtils;
	
	public class EarthKnight extends SpecialAbility
	{
		private var bitmapData:BitmapData;
		private var asset:MovieClip;
		private var display:Display;
		
		private var motion:Motion;
		private var bounds:MotionBounds;
		private var edge:Edge;
		private var currentHit:CurrentHit;
		
		private var delay:Number = 0;
		private var nextTime:Number;
		private var lastKnownGround:Number;
		private var paths:Array;
		private var assets:Array;
		private var bitmaps:Array;
		private var numAssets:Number = 1;
		private var assetsLoaded:Number  = 0;
		override public function deactivate(node:SpecialAbilityNode):void
		{
			asset = null;
			if(bitmapData)
			{
				bitmapData.dispose();
				bitmapData = null;
			}
			display = null;
			motion = null;
			bounds = null;
			edge = null;
			currentHit = null;
		
			super.deactivate(node);
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			if(_swfPath.indexOf(",",0) != -1)
			{
				
				paths = _swfPath.split(","); 
				numAssets = paths.length;
			}
			
			if(group is CharacterContentView)
				return;
			if(asset == null && paths == null)
				super.loadAsset(_swfPath, Command.create(loadComplete, node));
			else
			{
				assets = new Array();
				bitmaps = new Array();
				for (var i:Number=0;i<paths.length;i++)
				{
					super.loadAsset(paths[i],Command.create(loadCompleteArr, node));
				}
			}
			if(PlatformUtils.isMobileOS)
				_rate /= 2;
		}
		
		private function loadComplete(clip:MovieClip, node:SpecialAbilityNode):void
		{
			if(clip == null)
			{
				deactivate(node);
				return;
			}
			data.isActive = true;
			asset = clip;
			bitmapData = BitmapUtils.createBitmapData(asset, PerformanceUtils.defaultBitmapQuality);
			
			motion = node.entity.get(Motion);
			edge = node.entity.get(Edge);
			currentHit = node.entity.get(CurrentHit);
			bounds = node.entity.get(MotionBounds);
			display = node.entity.get(Display);
			nextTime = 1/_rate + Math.random() * 1/_rate;
		}
		private function loadCompleteArr(clip:MovieClip, node:SpecialAbilityNode):void
		{
			if(clip == null)
			{
				deactivate(node);
				return;
			}
			assets[assetsLoaded] = clip;
			bitmaps[assetsLoaded] = BitmapUtils.createBitmapData(assets[assetsLoaded], PerformanceUtils.defaultBitmapQuality);
			
			assetsLoaded++;
			if(assetsLoaded == numAssets)
				data.isActive = true;
			
			
			motion = node.entity.get(Motion);
			edge = node.entity.get(Edge);
			currentHit = node.entity.get(CurrentHit);
			bounds = node.entity.get(MotionBounds);
			display = node.entity.get(Display);
			nextTime = 1/_rate + Math.random() * 1/_rate;
		}
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if(data.isActive && motion != null && !motion.velocity.equals(new Point()))
			{
				delay += time;
				if(delay > nextTime)
				{
					nextTime = 1/_rate + Math.random() * 1/_rate;
					delay = 0;
					
					var point:Point = GeomUtils.getRandomPointInRectangle(edge.rectangle).add(new Point(motion.x,motion.y));
					if(currentHit)
					{
						if(bounds.bottom)
						{
							lastKnownGround = bounds.box.bottom;
						}
						else if(currentHit.hit)
						{
							lastKnownGround = currentHit.hitY + edge.rectangle.bottom;
						}
						else if(point.y > lastKnownGround)
						{
							lastKnownGround = bounds.box.bottom;
						}
					}
					else
					{
						lastKnownGround = motion.y + edge.rectangle.bottom;
					}
					var sprite:Sprite;
					if(assets != null)
					{	
						var num : int = Math.floor( Math.random() * assets.length )
						sprite = BitmapUtils.createBitmapSprite(assets[num],PerformanceUtils.defaultBitmapQuality, null,true, 0, bitmaps[num]);
					}
					else
						sprite = BitmapUtils.createBitmapSprite(asset,PerformanceUtils.defaultBitmapQuality, null,true, 0, bitmapData);
					sprite.x = point.x;
					sprite.y = point.y;
					display.container.addChild(sprite);
					DisplayUtils.moveToOverUnder(sprite, display.displayObject, false);
					var entity:Entity = EntityUtils.createSpatialEntity(node.entity.group,sprite);
					var spatial:Spatial = entity.get(Spatial);
					spatial.rotation = 360 * Math.random() - 180;
					spatial.scale = Math.floor( Math.random() * _scaleMax ) + _scaleMin;
					var dif:Number = lastKnownGround - point.y;
					if(!dif)
					{
						lastKnownGround = spatial.y + 10;
						dif = 10;
					}
					TweenUtils.entityTo(entity, Spatial, Math.sqrt(dif) / 5, {x:point.x, y:lastKnownGround, rotation:spatial.rotation + 180 * Math.random() - 90, onComplete:Command.create(fadeOut, entity)});
				}
			}
			else
				delay = 0;
		}
		
		private function fadeOut(leaf:Entity):void
		{
			TweenUtils.entityTo(leaf, Display, 3, {alpha:0, ease:Linear.easeNone, onComplete:Command.create(leaf.group.removeEntity, leaf)});
		}
		
		public var _swfPath:String = "specialAbility/objects/leaf_01.swf";
		public var _rate:Number = 1;
		public var _scaleMax:Number = 1;
		public var _scaleMin:Number = 2;
	}
}