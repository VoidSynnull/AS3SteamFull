package game.data.specialAbility.store
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.group.DisplayGroup;
	
	import game.components.entity.Sleep;
	import game.components.motion.FollowTarget;
	import game.components.motion.WaveMotion;
	import game.components.render.DisplayFilter;
	import game.data.WaveMotionData;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.render.DisplayFilterSystem;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class AtomPower extends SpecialAbility
	{
		private var ballsEntity:Entity;
		private var atomicField:Entity;
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				this.data.isActive = true;
				
				this.group.addSystem(new DisplayFilterSystem());
				this.group.addSystem(new WaveMotionSystem());
				this.group.addSystem(new FollowTargetSystem());
				
				var filter:DisplayFilter = new DisplayFilter();
				filter.inflate.setTo(10, 10);
				filter.filters.push(new GlowFilter(0x00ff00, 1, 100, 100, 0.8, 1, true));
				filter.filters.push(new GlowFilter(0x00ff00, 1, 20, 20, 1));
				filter.filters.push(new GlowFilter(0xffff00, 1, 6, 6, 4, 1, true));
				node.entity.add(filter);
				
				var display:DisplayObjectContainer = Display(node.entity.get(Display)).displayObject;
				
				var ballsSprite:Sprite = new Sprite();
				ballsSprite.mouseChildren = false;
				ballsSprite.mouseEnabled = false;
				ballsEntity = EntityUtils.createSpatialEntity(node.entity.group, ballsSprite, display.parent);
				
				var playerSpatial:Spatial = node.entity.get(Spatial);
				var followTarget:FollowTarget = new FollowTarget();
				followTarget.target = playerSpatial;
				followTarget.rate = 1;
				ballsEntity.add(followTarget);
				
				for(var index:uint = 1; index <= 3; ++index)
				{
					var shape:Shape = new Shape();
					ballsSprite.addChild(shape);
					shape.graphics.beginFill(0x66FF00);
					shape.graphics.drawCircle(0, 0, 7);
					shape.graphics.endFill();
					
					var bounds:Rectangle = shape.getBounds(shape);
					bounds.inflate(20, 20);
					
					var sprite:Sprite = DisplayGroup(node.entity.group).createBitmapSprite(shape, 1, bounds);
					sprite.mouseChildren = false;
					sprite.mouseEnabled = false;
					
					var bitmap:Bitmap = sprite.getChildAt(0) as Bitmap;
					var bitmapData:BitmapData = bitmap.bitmapData;
					bitmapData.applyFilter(bitmapData, bitmapData.rect, new Point(), new GlowFilter(0x00ff00, 1, 100, 100, 0.8, 1, true));
					bitmapData.applyFilter(bitmapData, bitmapData.rect, new Point(), new GlowFilter(0x00ff00, 1, 20, 20, 1));
					bitmapData.applyFilter(bitmapData, bitmapData.rect, new Point(), new GlowFilter(0xffff00, 1, 6, 6, 4, 1, true));
					bitmapData.applyFilter(bitmapData, bitmapData.rect, new Point(), new BlurFilter(3, 3, 3));
					
					var ball:Entity = EntityUtils.createSpatialEntity(node.entity.group, sprite, ballsSprite);
					ball.add(new SpatialAddition());
					ball.add(new Id("ball" + index));
					ball.add(new Sleep());
					EntityUtils.addParentChild(ball, ballsEntity);
					
					var wave:WaveMotion = new WaveMotion();
					var radians:Number = (index / 3) * (Math.PI * 2);
					var rate:Number = 2 + (index * 2);
					wave.add(new WaveMotionData("x", 70 * Math.cos(radians), rate, "sin", radians, true));
					wave.add(new WaveMotionData("y", 70 * Math.sin(radians), rate, "sin", radians, true));
					wave.add(new WaveMotionData("scaleX", 0.3, 2, "sin", 0, true));
					wave.add(new WaveMotionData("scaleY", 0.3, 2, "sin", 0, true));
					ball.add(wave);
				}
				
				// make effect not clickable if on card
				if (entity.get(Id).id == "cardDummy")
				{
					display.parent.parent.parent.mouseEnabled = false;
					display.parent.parent.parent.mouseChildren = false;
				}

				this.shellApi.loadFile(this.shellApi.assetPrefix + "specialAbility/objects/atomicField.swf", atomicFieldLoaded);
			}
		}
		
		private function atomicFieldLoaded(clip:MovieClip):void
		{
			if(this.data.isActive)
			{
				if(clip)
				{
					var container:DisplayObjectContainer = Display(this.entity.get(Display)).displayObject.parent;
					container.addChild(clip);
					
					atomicField = EntityUtils.createSpatialEntity(this.group, clip);
					TimelineUtils.convertClip(clip, this.group, atomicField);
					atomicField.remove(Sleep);
					var playerSpatial:Spatial = super.entity.get(Spatial);
					var followTarget:FollowTarget = new FollowTarget();
					followTarget.target = playerSpatial;
					followTarget.rate = 1;
					followTarget.offset = new Point(0, -10);
					atomicField.add(followTarget);
				}
			}
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			for(var index:uint = 1; index <= 3; ++index)
			{
				var ball:Entity = EntityUtils.getChildById(ballsEntity, "ball" + index);
				if(ball)
				{
					var wave:WaveMotion = ball.get(WaveMotion);
					if(wave)
					{
						var magnitude:Number;
						
						var dataX:WaveMotionData = wave.dataForProperty("x");
						var dataY:WaveMotionData = wave.dataForProperty("y");
						
						var radians:Number = Math.atan2(dataY.magnitude, dataX.magnitude);
						radians += time;
						
						dataX.magnitude = 70 * Math.cos(radians);
						dataY.magnitude = 70 * Math.sin(radians);
					}
				}
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			node.entity.remove(DisplayFilter);
			super.group.removeEntity(ballsEntity);
			super.group.removeEntity(atomicField);
			
			ballsEntity = null;
			atomicField = null;
		}
	}
}