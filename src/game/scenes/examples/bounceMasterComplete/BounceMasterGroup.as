package game.scenes.examples.bounceMasterComplete
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.scenes.examples.bounceMaster.components.BounceMasterGameState;
	import game.scenes.examples.bounceMaster.systems.BounceMasterGameSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.ProximityHitSystem;
	
	import org.osflash.signals.Signal;
	
	public class BounceMasterGroup extends Group
	{
		public function BounceMasterGroup()
		{
			super();
		}
		
		public function setupGroup(group:Group, container:DisplayObjectContainer, hud:DisplayObjectContainer, width:Number, height:Number):void
		{
			_creator = new BounceMasterCreator();
			
			super.addSystem(new ProximityHitSystem(), SystemPriorities.checkCollisions);
			//super.addSystem(new BounceMasterGameSystem(this, container, _creator, width, height), SystemPriorities.resolveCollisions);
			
			var gameStateEntity:Entity = _creator.createGameState(hud, STATE_ID)
			this.gameOver = BounceMasterGameState(gameStateEntity.get(BounceMasterGameState)).gameOver;
			super.addEntity(gameStateEntity);
		}
		
		public function startGame():void
		{
			var gameStateEntity:Entity = super.getEntityById(STATE_ID);
			BounceMasterGameState(gameStateEntity.get(BounceMasterGameState)).gameActive = true;
		}
		
		public function createCatcher(clip:MovieClip, followSpatial:Spatial):void
		{
			super.addEntity(_creator.createCatcher(clip, followSpatial));
		}
		
		public function addCatcher(entity:Entity, hitWidth:Number = 100, hitHeight:Number = 50):void
		{
			_creator.makeCatcher(entity, hitWidth, hitHeight);
		}
		
		private const STATE_ID:String = "BounceMasterGameState";
		private var _creator:BounceMasterCreator;
		public var gameOver:Signal;
	}
}