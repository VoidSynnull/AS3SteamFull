package game.scene.template.topDown.boatScene
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.util.EntityUtils;

	public class WaterEffectsCreator
	{
		public function WaterEffectsCreator()
		{
			
		}
		
		public function createWave(url:String, scene:Scene, container:DisplayObjectContainer):Entity
		{
			var entity:Entity = new Entity();
			entity.add(new Spatial());
			entity.add(new WaterWave(.025));
			
			EntityUtils.loadAndSetToDisplay(container, url, entity, scene);
			
			scene.addEntity(entity);
			
			return(entity);
		}
		
		public function createWaves(url:String, scene:Scene, container:DisplayObjectContainer, total:int):void
		{
			for (var i:int = 0; i < total; i++) 
			{
				createWave(url, scene, container);
			}	
		}
				
		public function addWake(boat:Entity, container:DisplayObjectContainer, url:String, waterRippleScaleX:Number = 1, waterRippleScaleY:Number = 1):Entity
		{
			var boatWake:BoatWake = new BoatWake(container, url);
			boatWake.rippleScaleX = waterRippleScaleX;
			boatWake.rippleScaleY = waterRippleScaleY;
			
			boat.add(boatWake);

			return(boat);
		}
	}
}