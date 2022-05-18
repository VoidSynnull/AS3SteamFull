package game.scenes.virusHunter.condoInterior.creators {

	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.scenes.virusHunter.condoInterior.components.Fountain;
	import game.scenes.virusHunter.condoInterior.components.SimpleUpdater;

	public class FountainCreator {
		
		public function FountainCreator() {
		} //

		// baseClip is the clip that contains the water effect.
		public function createFountain( fountClip:Sprite, fountClick:MovieClip, droplet:MovieClip ):Entity {
		
			var e:Entity = new Entity();

			var interaction:Interaction = new Interaction();
			InteractionCreator.addToComponent( fountClick,
				[ InteractionCreator.DOWN, InteractionCreator.UP ], interaction );
			fountClick.mouseEnabled = true;

			//var interaction:Interaction = InteractionCreator.addToEntity( e, [ InteractionCreator.DOWN, InteractionCreator.UP ],
				//fountClick );

			var fountain:Fountain = new Fountain( fountClip, e, droplet );

			interaction.down.add( fountain.turnOn );
			interaction.up.add( fountain.turnOff );

			var updater:SimpleUpdater = new SimpleUpdater( fountain.update );

			e.add( interaction )
				.add( updater )
				//.add( new Display( fountClick ) )
				.add( fountain );

			return e;

		} // createFountain()

	} // End FountainCreator

} // End package