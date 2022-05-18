package game.data.specialAbility.store
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.Scene;
	
	import game.components.specialAbility.Sparks;
	import game.data.animation.entity.character.Salute;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.backlot.sunriseStreet.Systems.EarthquakeSystem;
	import game.scenes.backlot.sunriseStreet.components.Earthquake;
	import game.systems.specialAbility.character.SparksSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	public class LightningStaff extends SpecialAbility
	{
		private var LINE_THICKNESS:Number = 7;
		private var LINE_ALPHA:Number = 100;
		private var TOTAL_GENERATIONS:Number = 10;
		private var DEGRADE_RATE:Number = .75;
		
		private var SIZE_FACTOR:Number = 250;
		private var X_OFFSET_MIN:Number = -.5 * SIZE_FACTOR;
		private var X_OFFSET_MAX:Number = .5 * SIZE_FACTOR;
		private var Y_OFFSET_MIN:Number = .5 * SIZE_FACTOR;
		private var Y_OFFSET_MAX:Number = SIZE_FACTOR;
		
		private var MIN_CHILDREN:Number = 1;
		private var MAX_CHILDREN:Number = 2;
		
		private var FILTER_QUALITY:Number = 1;
		private var GLOW_OFFSET:Number = 17;
		private var GLOW_STRENGTH:Number = 7;
		
		private var elapsedTime:Number = 0;
		private var nextBoltTime:Number = 0;
		
		private var numBolts:int = 0;
		private var maxBolts:int = 8;
		
		private var cameraShake:Entity;
		
		public function LightningStaff()
		{
			super();
		}
		
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			
			node.entity.group.addSystem(new SparksSystem());
			node.entity.group.addSystem(new EarthquakeSystem());
			
			/*
			var display:Display = item.get(Display);
			var displayObject:DisplayObjectContainer = display.displayObject;
			var staff:DisplayObjectContainer = displayObject.getChildByName("staff") as DisplayObjectContainer;
			*/
			var item:Entity = CharUtils.getPart(node.entity, CharUtils.ITEM);
			
			var display:Display = item.get(Display);
			var container:DisplayObjectContainer = display.displayObject.getChildByName("sparks");
			var entity:Entity = EntityUtils.createSpatialEntity(node.entity.group, container);
			var sparks:Sparks = new Sparks();
			sparks.bounds.setTo(-40, -140, 80, 280);
			entity.add(sparks);
			entity.add(new Id("sparks"));
			
			EntityUtils.addParentChild(entity, item);
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			if(!this.data.isActive)
			{
				this.data.isActive = true;
				
				numBolts = 0;
				nextBoltTime = Utils.randNumInRange(0.5, 1);
				
				var bitmap:Bitmap = new Bitmap(new BitmapData(this.shellApi.viewportWidth, this.shellApi.viewportHeight, true, 0x88000000));
				this.shellApi.currentScene.overlayContainer.addChildAt(bitmap, 0);
				var entity:Entity = EntityUtils.createSpatialEntity(node.entity.group, bitmap);
				var display:Display = entity.get(Display);
				display.alpha = 0;
				var tween:Tween = new Tween();
				tween.to(display, 1, {alpha:1});
				tween.to(display, 1, {alpha:0, delay:8, onComplete:node.entity.group.removeEntity, onCompleteParams:[entity]});
				entity.add(tween);
				
				SceneUtil.lockInput(node.entity.group, true);
				CharUtils.setAnim(node.entity, Salute);
				
				var spatial:Spatial = node.entity.get(Spatial);
				var shape:Shape = new Shape();
				shape.x = spatial.x;
				shape.y = spatial.y;
				cameraShake = EntityUtils.createSpatialEntity(group, shape, node.entity.get(Display).container);
				cameraShake.add(new Earthquake(spatial,new Point(1,10),5,20)).add(new Id("cameraShake"));
				SceneUtil.setCameraTarget(Scene(super.group), cameraShake);
			}
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			elapsedTime += time;
			
			if(elapsedTime >= nextBoltTime)
			{
				elapsedTime = 0;
				nextBoltTime = Utils.randNumInRange(0.5, 1);
				
				var container:DisplayObjectContainer = this.shellApi.currentScene.overlayContainer;
				
				var sprite:Sprite = new Sprite();
				sprite.mouseChildren = false;
				sprite.mouseEnabled = false;
				sprite.x = Utils.randNumInRange(0, this.shellApi.viewportWidth);
				container.addChildAt(sprite, 0);
				
				createInternal(sprite, 0, 0, 0.5);
				
				var bounds:Rectangle = sprite.getBounds(sprite.parent);
				var bitmap:Bitmap = BitmapUtils.createBitmap(sprite);
				bitmap.x = bounds.left;
				bitmap.y = bounds.top;
				container.addChildAt(bitmap, 0);
				container.removeChild(sprite);
				
				var lightning:Entity = EntityUtils.createSpatialEntity(node.entity.group, bitmap);
				
				var tween:Tween = new Tween();
				tween.to(lightning.get(Display), 0.3, {delay:0.21, alpha:0, onComplete:this.destroyLightningBolt, onCompleteParams:[lightning]});
				lightning.add(tween);
				
				++numBolts;
				
				if(numBolts >= maxBolts)
				{
					this.data.isActive = false;
					SceneUtil.lockInput(node.entity.group, false);
					SceneUtil.setCameraTarget(Scene(node.entity.group), node.entity);
					cameraShake.group.removeEntity(cameraShake);
				}
			}
		}
		
		private function destroyLightningBolt(lightning:Entity):void
		{
			var display:Display = lightning.get(Display);
			var bitmap:Bitmap = display.displayObject;
			bitmap.bitmapData.dispose();
			lightning.group.removeEntity(lightning);
		}
		
		private function createInternal(container:Sprite, x:Number, y:Number, generation:Number):void
		{
			var bolt:Shape = container.addChild(new Shape()) as Shape;
			var prevDegrade:Number = (TOTAL_GENERATIONS - generation - 1) / TOTAL_GENERATIONS;
			var degrade:Number = (TOTAL_GENERATIONS - generation) / TOTAL_GENERATIONS;
			
			var stepDegrade:Number = (prevDegrade + degrade) * .5;
			
			var targetX:Number = x + Utils.randNumInRange(X_OFFSET_MIN * degrade, X_OFFSET_MAX * degrade);
			var targetY:Number = y + Utils.randNumInRange(Y_OFFSET_MIN * degrade, Y_OFFSET_MAX * degrade);
			var boltGlow:GlowFilter = new GlowFilter(0xFFFFFF, LINE_ALPHA * degrade, GLOW_OFFSET * degrade, GLOW_OFFSET * degrade, GLOW_STRENGTH * degrade, FILTER_QUALITY, false, false);
			
			var initPoint:Point = new Point(x, y);
			var targetPoint:Point = new Point(targetX, targetY);
			
			var midPoint:Point = Point.interpolate(initPoint, targetPoint, .5);
			
			//trace("degrade : " + degrade);
			var graphics:Graphics = bolt.graphics;
			graphics.lineStyle(LINE_THICKNESS * degrade, 0xFFFFFF, LINE_ALPHA * degrade);
			graphics.moveTo(x, y);
			graphics.lineTo(midPoint.x, midPoint.y);
			
			graphics.lineStyle(LINE_THICKNESS * stepDegrade, 0xFFFFFF, LINE_ALPHA * stepDegrade);
			graphics.moveTo(midPoint.x, midPoint.y);
			graphics.lineTo(targetX, targetY);
			
			bolt.filters = [boltGlow];
			
			if(targetY >= this.shellApi.viewportHeight)
			{
				return;
			}
			
			if (generation < TOTAL_GENERATIONS)
			{				
				// chance for no children increases as generations increase
				var total:Number = Utils.randNumInRange(MIN_CHILDREN * degrade, MAX_CHILDREN * degrade);
				
				for (var n:Number = 0; n < total; n++)
				{
					createInternal(container, targetX, targetY, generation + 1);
				}
			}
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			var item:Entity = CharUtils.getPart(node.entity, CharUtils.ITEM);
			if(item)
			{
				var entity:Entity = EntityUtils.getChildById(item, "sparks");
				if(entity)
				{
					entity.group.removeEntity(entity);
				}
				
			}
			
			super.deactivate(node);
		}
	}
}