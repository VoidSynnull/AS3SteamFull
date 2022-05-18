package game.data.specialAbility.character.objects
{
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.specialAbility.character.objects.FlowerGrow;
	import game.systems.specialAbility.character.objects.FlowerGrowSystem;
	
	public class Daisy
	{
		private var flowerGrow:FlowerGrowSystem;
		
		public function init(group:Group, objectEntity:Entity):void
		{
			// Add the Flower Sytem if it's not there already
			if( !group.getSystem( FlowerGrowSystem ) )
			{
				flowerGrow = new FlowerGrowSystem();
				group.addSystem( flowerGrow );
			}
			
			objectEntity.add(new FlowerGrow);
		}
	}
}