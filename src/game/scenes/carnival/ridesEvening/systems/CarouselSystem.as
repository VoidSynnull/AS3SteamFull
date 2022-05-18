package game.scenes.carnival.ridesEvening.systems 
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.carnival.ridesEvening.nodes.CarouselHorseNode;
	import game.systems.SystemPriorities;
	
	public class CarouselSystem extends System
	{
		private var _carouselHorses:NodeList;
				
		public function CarouselSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_carouselHorses = systemManager.getNodeList( CarouselHorseNode );
		}
		
		override public function update( time:Number ):void
		{
			var horse:CarouselHorseNode;
			
			for(horse = _carouselHorses.head; horse; horse = horse.next) {
				
				var spatial:Spatial = horse.entity.get(Spatial);
				if(horse.carouselHorse.forward){
					if(spatial.x < 4097){
						spatial.x += horse.carouselHorse.speed;
					}else{
						spatial.x = 3289;
					}
				}else{
					if(spatial.x > 3330){
						spatial.x -= horse.carouselHorse.speed;
					}else{
						spatial.x = 4120;
					}
				}
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( CarouselHorseNode );
			_carouselHorses = null;
		}
	}
}




