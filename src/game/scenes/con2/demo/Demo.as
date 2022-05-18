package game.scenes.con2.demo
{
	import com.greensock.easing.Bounce;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.hit.Zone;
	import game.components.motion.ShakeMotion;
	import game.components.motion.TargetSpatial;
	import game.components.motion.WaveMotion;
	import game.components.render.DynamicWire;
	import game.components.scene.SceneInteraction;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.BigStomp;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.specialAbility.character.AddBalloon;
	import game.scene.template.PhotoGroup;
	import game.scenes.con2.shared.Poptropicon2Scene;
	import game.scenes.con2.shared.popups.CardDeck;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.render.DynamicWireSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Demo extends Poptropicon2Scene
	{
		public function Demo()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con2/demo/";
			
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
			addSystem(new WaveMotionSystem());
			addSystem(new DynamicWireSystem());
			addSystem(new ShakeMotionSystem());
			
			shellApi.eventTriggered.add(onEventTriggered);
			
			setupDealerDialog();
			setupCans();
			setupBalloons();
			setupBoard();
			
			super.loaded();
		}

		override public function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			var dealerDialog:Dialog;
			if( event == "check_if_played" )
			{
				dealerDialog = getEntityById( "dealer" ).get( Dialog );
				if( !shellApi.checkEvent(_events.STARTER_DECK) )
				{
					dealerDialog.sayById( "give_starter" );
				}
				else
				{
					dealerDialog.sayById( "dealer_teach" );
				}
			}

			if( event == "give_deck" )
			{
				dealerDialog = getEntityById( "dealer" ).get( Dialog );
				super.addCardToDeck(_events.CARD_DECK, Command.create( dealerDialog.sayById, "dealer_teach" ) );
				shellApi.completeEvent(_events.STARTER_DECK);
				
				// NOTE :: shouldn't have to do this, but the expert's dialogue isn't updating
				var expertDialog:Dialog = getEntityById( "expert" ).get( Dialog );
				expertDialog.current = expertDialog.getDialog( "starter_deck" );
			}
			
			if( event == "open_deck" )
			{
				var cardDeckPopup:CardDeck = new CardDeck( super.overlayContainer );
				cardDeckPopup.removed.addOnce( onForcedDeckClosed );
				super.addChildGroup( cardDeckPopup );
			}
			
			super.onEventTriggered(event, save, init, removeEvent);
		}
		
		private function setupDealerDialog():void
		{
			var dealer:Entity = super.getEntityById("dealer");
			var dialog:Dialog = dealer.get( Dialog );
			if( !shellApi.checkEvent(_events.STARTER_DECK) )
			{	
				dialog.current = dialog.getDialog( "new_player" );
			}
			else
			{
				dialog.current = dialog.getDialog( "starter_deck" );
			}
		}
		
		private function setupCans():void
		{
			for(var i:int = 1; i <= NUM_CANS; i++)
			{
				var can:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["can" + i]);
				can = TimelineUtils.convertClip(_hitContainer["can" + i], this, can);
				InteractionCreator.addToEntity(can, [InteractionCreator.CLICK]);
				can.get(Interaction).click.add(clickedCan);
				ToolTipCreator.addToEntity(can);
			}
		}
		
		private function setupBalloons():void
		{
			for(var i:int = 1; i <= NUM_BALLOONS; i++)
			{
				var balloon:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["balloon" + i]);
				InteractionCreator.addToEntity(balloon, [InteractionCreator.CLICK]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.validCharStates = new <String>[CharacterState.STAND];
				sceneInteraction.minTargetDelta = new Point(25, 200);
				sceneInteraction.offsetY += 350;
				
				balloon.add(sceneInteraction);
				ToolTipCreator.addToEntity(balloon);
				
				var rad:Number = 0;
				if(i % 2 == 0)
					rad = Math.PI/2;
				
				var waveMotion:WaveMotion = new WaveMotion();
				waveMotion.add(new WaveMotionData("y", 2, .03, "sin", rad));
				waveMotion.add(new WaveMotionData("x", 5, .05, "sin", rad));
				waveMotion.add(new WaveMotionData("rotation", 8, .01, "sin", rad));
				balloon.add(waveMotion);
				balloon.add(new SpatialAddition());
				
				var end:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["balloonEnd" + i]);
				var targetSpatial:TargetSpatial = new TargetSpatial(balloon.get(Spatial));
				targetSpatial.addition = balloon.get(SpatialAddition);
				end.add(targetSpatial);
				end.add(new DynamicWire(210, STRING_COLOR, 0, 3, 0));
				
				sceneInteraction.reached.add(Command.create(clickedBalloon, end));
			}
		}
		
		private function setupBoard():void
		{
			var board:Entity = EntityUtils.createMovingEntity(this, _hitContainer["board"]);
			board.add(new SpatialAddition()); // for shake motion
			var interaction:Interaction = InteractionCreator.addToEntity(board, [InteractionCreator.CLICK]);
			interaction.click.add(boardClicked);
			ToolTipCreator.addToEntity(board);
			
			if(this.checkHasCard(_events.DIRT_CLAUDE))
			{
				for(var i:int = 1; i <= NUM_NOTES; i++)
					_hitContainer.removeChild(_hitContainer["note" + i]);
				
				removeEntity(getEntityById("markerZone"));
				_hitContainer.removeChild(_hitContainer["marker"]);
				_hitContainer.removeChild(_hitContainer["card"]);
			}
			else
			{
				for(var j:int = 1; j <= NUM_NOTES; j++)
						postIts.push(EntityUtils.createMovingEntity(this, _hitContainer["note" + j]));
				
				var marker:Entity = EntityUtils.createMovingEntity(this, _hitContainer["marker"]);
				var markerZone:Entity = getEntityById("markerZone");
				Zone(markerZone.get(Zone)).inside.add(Command.create(markerDrop, marker, board));
			}
		}
		
		private function clickedCan(can:Entity):void
		{
			shellApi.triggerEvent("soda_fizzle");
			can.get(Timeline).gotoAndPlay("fizzle");
		}
		
		private function markerDrop(zoneId:String, playerId:String, marker:Entity, board:Entity):void
		{
			if(player.get(Motion).velocity.y == 0)
			{
				var zoneEntity:Entity = getEntityById(zoneId);
				zoneEntity.get(Zone).inside.removeAll();
				removeEntity(zoneEntity, true);
				
				board.add(new ShakeMotion(new RectangleZone(-2, -2, 2, 2)));
				SceneUtil.addTimedEvent(this, new TimedEvent(.25, 1, Command.create(stopBoardMoveMarker, board, marker)));				
			}
		}
		
		private function boardClicked(board:Entity):void
		{
			CharUtils.setAnim(player, BigStomp);
			CharUtils.getTimeline(player).handleLabel("sumoStomp", Command.create(hitBoard, board));
		}
		
		private function hitBoard(board:Entity):void
		{
			board.add(new ShakeMotion(new RectangleZone(-2, -2, 2, 2)));
			SceneUtil.addTimedEvent(this, new TimedEvent(.35, 1, Command.create(stopBoardShake, board)));	
			shellApi.triggerEvent("shake_board");
		}
		
		private function stopBoardMoveMarker(board:Entity, marker:Entity):void
		{
			board.remove(ShakeMotion);
			var markerMotion:Motion = marker.get(Motion);
			TweenUtils.globalTo(this, marker.get(Spatial), 1, {y:390, rotation:180, ease:Bounce.easeOut});
			SceneUtil.addTimedEvent(this, new TimedEvent(.4, 2, markerLanded));
		}
		
		private function markerLanded():void
		{
			shellApi.triggerEvent("marker_fell");
		}
		
		private function stopBoardShake(board:Entity):void
		{
			board.remove(ShakeMotion);
			
			if(postIts.length > 0)
			{
				var currentNote:Entity = postIts[0];
				postIts.shift();
				currentNote.get(Motion).acceleration.y = 120;
				TweenUtils.globalTo(this, currentNote.get(Display), 1, {alpha:0, onComplete:postItGone, onCompleteParams:[currentNote]}, "noteFall", .5);
				shellApi.triggerEvent("paper_fall");
				if(postIts.length == 0)
				{
					EntityUtils.removeInteraction(board);					
					
					var card:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["card"]);
					InteractionCreator.addToEntity(card, [InteractionCreator.CLICK]);
					ToolTipCreator.addToEntity(card);
					
					var sceneInteraction:SceneInteraction = new SceneInteraction();
					sceneInteraction.reached.addOnce(getCard);
					card.add(sceneInteraction);
				}
			}
		}
		
		private function getCard(player:Entity, card:Entity):void
		{
			this.addCardToDeck(_events.DIRT_CLAUDE);
			removeEntity(card);
		}
		
		private function postItGone(postIt:Entity):void
		{
			removeEntity(postIt, true);
		}
		
		private function clickedBalloon(player:Entity, balloon:Entity, string:Entity):void
		{
			var control:SpecialAbilityControl = player.get(SpecialAbilityControl);
			if(control)
			{
				control.removeSpecialByClass(AddBalloon);
			}
			
			shellApi.triggerEvent("grab_balloon");
			
			/*var data:SpecialAbilityData = new SpecialAbilityData(AddBalloon);
			data.triggerable = false;
			data.params.addParam("file", "scenes/con2/shared/balloon.swf");
			data.params.addParam("stringColor", STRING_COLOR);
			data.params.addParam("stringThickness", 3);
			data.params.addParam("gravityDampening", -1400);
			data.params.addParam("knotX", 3);
			data.params.addParam("rate", .075);
			data.params.addParam("clickable", true);
			data.addValidIsland("con2");			
			shellApi.specialAbilityManager.addSpecialAbility(this.player, data, true);*/
			
			shellApi.specialAbilityManager.addSpecialAbilityById(this.player, "balloon_con2", true);
			

			removeEntity(balloon);
			removeEntity(string);
		}
		
		////////////////////////////////////////// CARD GAME //////////////////////////////////////////
		public function testCard():void
		{
			this.cardGameComplete( "expert", "omegon", true );
		}
		
		override protected function cardGameComplete(opponentId:String, reward:String, won:Boolean, onCardReceived:Function = null, lockInput:Boolean = false):void
		{
			var method:Function;
			if( opponentId == "expert" )
			{
				var dialog:Dialog = getEntityById( "expert" ).get( Dialog );
				if( won )
				{
					method = Command.create( snapPhoto, _events.OMEGON_BODY_PHOTO, wonOmegon);
				}
				else
				{
					dialog.sayById( "won" );
				}
				
				super.cardGameComplete( opponentId, reward, won, method, true );
			}
			else if( opponentId == "dealer" )
			{
				method = explainDeck;
				super.cardGameComplete( opponentId, reward, won, method, true );
			}	
		}
		
		private function explainDeck():void
		{ 
			var dialog:Dialog = getEntityById( "dealer" ).get( Dialog );
			dialog.sayById( "won_card" );
		}
		
		private function onForcedDeckClosed( ...args ):void
		{
			super.returnControls();
			var dialog:Dialog = getEntityById( "dealer" ).get( Dialog );
			dialog.sayById( "deck_closed"  );
		}
		
		private function wonOmegon( ...args ):void
		{
			super.returnControls();
			var dialog:Dialog = getEntityById( "expert" ).get( Dialog );
			dialog.sayById( "lost" );
			dialog.current = dialog.getDialog(_events.OMEGON_BODY_PHOTO );
		}
		
		private var _playing:Boolean = false;
		private const NUM_CANS:int = 2;
		private const NUM_BALLOONS:int = 2;
		private const NUM_NOTES:int = 4;
		private const STRING_COLOR:uint = 0x223D5C;
		
		private var postIts:Vector.<Entity> = new Vector.<Entity>();
	}
}