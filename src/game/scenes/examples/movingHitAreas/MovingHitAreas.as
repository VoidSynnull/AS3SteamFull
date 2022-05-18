package game.scenes.examples.movingHitAreas{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.creators.InteractionCreator;
	
	import game.creators.scene.HitCreator;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.MovingHitData;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	
	public class MovingHitAreas extends PlatformerGameScene
	{
		public function MovingHitAreas()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/movingHitAreas/";
			super.showHits = true;
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			// liquid starts paused...
			var movingLiquid:Entity = super.getEntityById("movingLiquid");
			var motion:Motion = movingLiquid.get(Motion);
			motion.pause = true;
			var interaction:Interaction = InteractionCreator.addToEntity(movingLiquid, [InteractionCreator.DOWN]);
			interaction.down.add(handleLiquidClicked);
			
			// in the xml the sideways mover is set not to loop.  This can be changed at runtime in its click handler.
			var sidewaysMover:Entity = super.getEntityById("sideways");;
			interaction = InteractionCreator.addToEntity(sidewaysMover, [InteractionCreator.DOWN]);
			interaction.down.add(handleSidewaysClicked);
			
			super.loaded();
		}
				
		private function handleLiquidClicked(entity:Entity):void
		{
			var motion:Motion = entity.get(Motion);
			motion.pause = !motion.pause;
		}
		
		private function handleSidewaysClicked(entity:Entity):void
		{
			if(entity.get(Motion).velocity.length == 0)
			{
				var movingHitData:MovingHitData = entity.get(MovingHitData);
				//movingHitData.loop = !movingHitData.loop;
				
				movingHitData.points.reverse();
				movingHitData.pointIndex = 0;
			}
			
		}
		
		override protected function addCollisions(audioGroup:AudioGroup):void
		{			
			createCustomMover();
			
			super.addCollisions(audioGroup);
		}
		
		private function createCustomMover():void
		{
			var hitCreator:HitCreator = new HitCreator();
			hitCreator.showHits = true;
			
			var movingHitData:MovingHitData = new MovingHitData();
			movingHitData.visible = "customMoverArt";  // map this to a 'visible' movieclip in the scene.
			
			var customMover:Entity = hitCreator.createHit(super._hitContainer["customMover"], HitType.MOVING_PLATFORM, movingHitData, this);
			var motion:Motion = customMover.get(Motion);
			motion.friction = new Point(0, 0);
			motion.maxVelocity = new Point(400, 400);
			
			var interaction:Interaction = InteractionCreator.addToEntity(customMover, [InteractionCreator.DOWN]);
			interaction.down.add(handleCustomDown);
		}
		
		private function handleCustomDown(entity:Entity):void
		{
			var motion:Motion = entity.get(Motion);
			
			if(motion.acceleration.x == 0)
			{
				motion.acceleration.x = 100;
				motion.friction.x = 0;
			}
			else
			{
				motion.acceleration.x = 0;
				motion.friction.x = 500;
			}
		}
	}
}