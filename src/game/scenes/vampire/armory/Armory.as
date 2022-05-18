package game.scenes.vampire.armory{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.Destination;
	import game.components.scene.SceneInteraction;
	import game.components.hit.Door;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Crowbar;
	import game.scenes.vampire.VampireEvents;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class Armory extends PlatformerGameScene
	{
		public function Armory()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/vampire/armory/";
			
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
			super.loaded();
			
			setupBoards();
		}
		// need to attach prying the dooor to watering the plant
		private function setupBoards():void
		{
			var windowDoor:Entity = super.getEntityById("windowDoor");
			var windowDoorInteraction:SceneInteraction = windowDoor.get(SceneInteraction);
			var windowDoorInt:Interaction = windowDoor.get(Interaction);
			windowDoorInteraction.offsetX = 0;
			//Spatial(sewerDoor.get(Spatial)).x += 60;
			
			if ( super.shellApi.checkEvent(vampireEvents.BOARDS_OPENED) )
			{
				super._hitContainer["boards_mc"].visible = false;
			}
			else
			{
				boards = EntityUtils.createMovingEntity( this, super._hitContainer["boards_mc"] );
				boards.add( new Id( "boards_mc" ));
				var audioGroup:AudioGroup = super.getGroupById("audioGroup") as AudioGroup;
				audioGroup.addAudioToEntity(boards);
				
				// Remove standard door listeners and add custum listener, offset door target
				BoardsClicked = windowDoorInt.click;
				windowDoorInt.click = new Signal();
				windowDoorInt.click.add(doorReached);
			}
		}
		
		private function doorReached(door:Entity):void
		{			
			var doorSpatial:Spatial = door.get(Spatial);
			/*
			if(!super.shellApi.checkEvent(events.GOT_ITEM + events.CROWBAR))
			{
				super.shellApi.triggerEvent(events.BOARDS_ATTEMPT_OPEN);
			}
			else 
			*/
			if (!super.shellApi.checkEvent(vampireEvents.BOARDS_OPENED))
			{
				var path:Vector.<Point> = new Vector.<Point>;
				path.push( new Point( 368, 676 ));
				CharUtils.followPath( super.shellApi.player, path, openBoards, false, false, new Point( 25, 25 ) ).setDirectionOnReached( CharUtils.DIRECTION_RIGHT );
			}
			else
			{
				Door(door.get(Door)).open = true;
			}
		}
		
		public function openBoards( character:Entity = null ):void
		{
			CharUtils.setState( super.player, CharacterState.STAND );
			SceneUtil.lockInput(this, true, false);
			CharUtils.lockControls(super.player, true, true);
			CharUtils.getTimeline( super.player ).labelReached.add( onCrowbarLabels );	// listen for trigger & end
			CharUtils.setAnim( super.player, Crowbar );									// play crowbar aniamtion
		}
		
		public function onCrowbarLabels( label:String ):void
		{
			if ( label == Animation.LABEL_BEGINNING )
			{
				super.shellApi.triggerEvent( vampireEvents.BOARDS_OPENING );
			}
			else if ( label == Animation.LABEL_TRIGGER )// open crate
			{
				var motion:Motion = boards.get( Motion );
				motion.velocity.x += 250;
				motion.acceleration.y = 750;
				super.shellApi.triggerEvent( vampireEvents.BOARDS_OPENED );
				
				motion.friction = new Point( 1.5, 0 );
			}
			else if ( label == Animation.LABEL_ENDING )	
			{
				super.shellApi.completeEvent( vampireEvents.BOARDS_OPENED );
				//super.shellApi.loadScene(Sewer);
			}
		}
		
		private var boards:Entity;
		private var vampireEvents:VampireEvents;
		private var BoardsClicked:Signal;
	}
}