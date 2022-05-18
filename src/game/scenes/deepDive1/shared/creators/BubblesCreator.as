package game.scenes.deepDive1.shared.creators
{
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.scenes.deepDive1.shared.components.Bubbles;
	import game.scenes.deepDive1.shared.systems.BubblesSystem;
	import game.systems.SystemPriorities;

	public class BubblesCreator
	{
		
		public function BubblesCreator($group:Group, $player:Entity, $container:Sprite = null)
		{
			_group = $group;
			_player = $player;
			
			if($container == null){
				
			}

			_container = $container;
		}
		
		public function CreateBubbleField($amount:int = 100, $width:Number = 500, $height:Number = 500, $debug:Boolean = false, $offsetX:Number = 0, $offsetY:Number = 0):Entity{
			
			var bubbles:Entity = new Entity();
			bubbles.add(new Bubbles($amount,_container,$width,$height, _player, $debug, $offsetX, $offsetY)); // physics code is in the Bubbles component
			bubbles.add(new Sleep());
			
			// add bubbles entity
			_group.addEntity(bubbles);
			
			// add bubbles system
			_group.addSystem(new BubblesSystem(), SystemPriorities.render);
			
			return bubbles;
		}
		
		private var _player:Entity;
		private var _group:Group;
		private var _container:Sprite;
		
	}
}