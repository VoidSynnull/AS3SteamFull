package game.creators.render
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.components.render.Light;
	import game.components.render.LightOverlay;
	import game.components.render.LightRange;
	import game.systems.render.LightRangeSystem;
	import game.systems.render.LightSystem;

	public class LightCreator
	{
		public function LightCreator()
		{
		}
		
		public function addSimpleLight(entity:Entity, 
									   radius:Number = 200, 
									   lightAlpha:Number = 0, 
									   gradient:Boolean = true, 
									   sourceColor:uint = 0x000000, 
									   useRange:Boolean = false, maxRange:Number = NaN, minRange:Number = NaN, horizontalRange:Boolean = false):void
		{
			var color:uint = 0x000000;
			var darkAlpha:Number = .9;
			var lightOverlayEntity:Entity = entity.group.getEntityById("lightOverlay");
			var lightOverlay:LightOverlay;
			
			if(lightOverlayEntity != null)
			{
				lightOverlay = lightOverlayEntity.get(LightOverlay);
				
				if(lightOverlay != null)
				{
					color = lightOverlay.color;
					darkAlpha = lightOverlay.darkAlpha;
				}
			}
			
			addLight(entity, radius, darkAlpha, lightAlpha, gradient, color, sourceColor, useRange, maxRange, minRange, horizontalRange);
		}
		
		public function addLight(entity:Entity, 
								 radius:Number = 200, 
								 darkAlpha:Number = .9, lightAlpha:Number = 0, 
								 gradient:Boolean = true, 
								 color:uint = 0x000000, sourceColor:uint = 0x000000, 
								 useRange:Boolean = false, maxRange:Number = NaN, minRange:Number = NaN, horizontalRange:Boolean = false):void
		{
			if(useRange)
			{
				darkAlpha *= 2;
				radius *= 2;
				lightAlpha *= 2;
				
				if(isNaN(minRange))
				{
					minRange = 0;
				}
				
				if(isNaN(maxRange))
				{
					if(entity.group != null)
					{
						if(entity.group is Scene)
						{
							if(horizontalRange)
							{
								maxRange = Scene(entity.group).sceneData.cameraLimits.right;
							}
							else
							{
								maxRange = Scene(entity.group).sceneData.cameraLimits.bottom;
							}
						}
					}
				}
				
				entity.add(new LightRange(minRange, maxRange, radius, darkAlpha, lightAlpha, horizontalRange));
			}
			
			entity.add(new Light(radius, darkAlpha, lightAlpha, gradient, sourceColor, color));
		}
		
		public function setupLight(group:Group = null, container:DisplayObjectContainer = null, darkAlpha:Number = .9, useRange:Boolean = false, color:uint = 0x000000):Entity
		{
			var lightOverlayEntity:Entity = group.getEntityById("lightOverlay");
			
			if(lightOverlayEntity == null)
			{
				group.addSystem(new LightSystem());
				
				var lightOverlay:Sprite = new Sprite();
				container.addChildAt(lightOverlay, 0);
				lightOverlay.mouseEnabled = false;
				lightOverlay.mouseChildren = false;
				lightOverlay.graphics.clear();
				lightOverlay.graphics.beginFill(color, darkAlpha);
				lightOverlay.graphics.drawRect(0, 0, group.shellApi.viewportWidth, group.shellApi.viewportHeight);
				
				var display:Display = new Display(lightOverlay);
				display.isStatic = true;
				
				lightOverlayEntity = new Entity();
				lightOverlayEntity.add(new Spatial());
				lightOverlayEntity.add(display);
				lightOverlayEntity.add(new Id("lightOverlay"));
				lightOverlayEntity.add(new LightOverlay(darkAlpha, color));
				
				group.addEntity(lightOverlayEntity);
				
				if(useRange)
				{
					group.addSystem(new LightRangeSystem());
				}
			}
			
			return lightOverlayEntity;
		}
	}
}