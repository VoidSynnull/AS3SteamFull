package game.scenes.arab3.palaceExterior
{
	import com.greensock.easing.Back;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.entity.character.Npc;
	import game.components.hit.Platform;
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Cough;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Soar;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.ItemGroup;
	import game.scenes.arab3.Arab3Scene;
	import game.scenes.arab3.shared.DivinationTarget;
	import game.scenes.arab3.shared.SmokePuffGroup;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TriggerEventAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	import game.util.Utils;
	
	public class PalaceExterior extends Arab3Scene
	{
		private var chest:Entity;
		private var chestClick:Entity;
		private var chestClickInteraction:Interaction;
		private var chestTalk:Entity;
		private var chestOpened:Boolean = false;
		
		private var camel:Entity;
		private var guard:Entity;
		private var guardXLeft:Number = 1000;
		private var guardXRight:Number = 2000;
		private var runR:Boolean = false;
		private var camelPlat:Entity;
		private var camelRun:TimedEvent;
		
		private var genie:Entity;
		private var genieHide:Entity;
		private var _smokePuffGroup:SmokePuffGroup;
		private var genietimer:TimedEvent;
		
		private const POOF_SOUND:String = SoundManager.EFFECTS_PATH + "poof_02.mp3";
		private const FOUND:String = SoundManager.MUSIC_PATH + "genie_found.mp3";
		
		private var _lidSequence:BitmapSequence;
		private var _lockedEyeSequence:BitmapSequence;
		private var _openEyeSequence:BitmapSequence;
		
		public function PalaceExterior()
		{
			super();
		}
		
		override protected function addBaseSystems():void
		{
			addSystem( new ThresholdSystem());
			super.addBaseSystems();
		}
		
		override public function init( container:DisplayObjectContainer=null ):void
		{
			super.groupPrefix = "scenes/arab3/palaceExterior/";
			super.init( container );
		}
		
		override public function destroy():void
		{
			if( camelRun )
			{
				camelRun.stop();
				camelRun = null;
			}
			super.destroy();
		}
		override public function smokeReady():void
		{
			super.smokeReady();	
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
			this.guard = this.getEntityById("guard2");
			this.genie = getEntityById("genie");
			
			if(shellApi.checkEvent(_events.GENIE_IN_PALACE)){
				guard.get(Spatial).x = guardXLeft;
				Dialog(guard.get(Dialog)).setCurrentById("disaster");
				setUpCamel();
				
				_smokePuffGroup = addChildGroup(new SmokePuffGroup()) as SmokePuffGroup;
				_smokePuffGroup.initJinnSmoke(this, _hitContainer, 0);
				setupGenieHiding();
				
				if (shellApi.checkEvent(_events.CAMEL_CHASE_STARTED)) {
					Dialog(guard.get(Dialog)).setCurrentById("running");
					startBackAndForth();
				}
				
			} else {
				genieHide = EntityUtils.createMovingTimelineEntity(this, _hitContainer["genieHide"]);
				Timeline(genieHide.get(Timeline)).gotoAndStop("start");
				removeEntity(genie);
				
				if (shellApi.checkEvent(_events.CAMEL_CHASE_STARTED)) {
					guard.get(Spatial).x = guardXLeft;
					Dialog(guard.get(Dialog)).setCurrentById("running");
					setUpCamel();
					startBackAndForth();
				} else {
					camelPlat = this.getEntityById("camelPlat");
					camelPlat.get(Spatial).x = -100;
				}	
			}
			setupChest();
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			var timeline:Timeline = chest.get( Timeline );
			var dialog:Dialog = chestTalk.get( Dialog );
			
			if( event == _events.USE_SKELETON_KEY ) {
				if(!this.shellApi.checkEvent(_events.CHEST_OPENED)) {
					var dest:Destination = CharUtils.moveToTarget(player, 1464, 1280, false, waitToOpenChest);
					dest.ignorePlatformTarget = true;
				} else {
					Dialog(player.get(Dialog)).sayById("no_use_key");
				}
			} else if( event == "getLamp" ) {
				
				timeline.gotoAndPlay( "opentalk" );
				dialog.complete.addOnce( endChestTalking );
				//				var xPos:Number = chest.get(Spatial).x;
				//				var destination:Destination = CharUtils.moveToTarget(player, xPos, 1280, false, pickUpLamp);
				//				destination.ignorePlatformTarget = true;
			} else if( event == "faceCamel" ) {
				Dialog(guard.get(Dialog)).faceSpeaker = false;
				CharUtils.setDirection(guard, false);
			} else if( event == "runFromCamel" ) {
				runRight();
				Dialog(guard.get(Dialog)).setCurrentById("running");
				Dialog(guard.get(Dialog)).faceSpeaker = true;
				this.shellApi.completeEvent(_events.CAMEL_CHASE_STARTED);
			}
			else if( event == "chest_animate" )
			{
				timeline.gotoAndPlay( "opentalk" );
				dialog.complete.addOnce( endChestTalking );
			}
		}
		
		private function waitToOpenChest(entity:Entity):void {
			SceneUtil.lockInput(this, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 1, useKey));
			var lookData:LookData = new LookData();
			lookData.applyAspect( new LookAspectData( SkinUtils.ITEM, "an_key" ) );
			SkinUtils.applyLook( player, lookData, false );
		}
		
		private function useKey():void {
			CharUtils.setDirection(player, false);
			CharUtils.setAnim(player, PointItem);
			player.get(Timeline).handleLabel("pointing", openChest, false);
		}
		
		private function openChest():void {
			SceneUtil.lockInput(this, false);
			var lookData:LookData = new LookData();
			lookData.applyAspect( new LookAspectData( SkinUtils.ITEM, "empty" ) );
			SkinUtils.applyLook( player, lookData, false );
			
			this.shellApi.completeEvent(_events.CHEST_OPENED);
			removeEntity( getEntityById( "lockedEye" ));
			chest.get(Timeline).gotoAndPlay("open");
			chestOpened = true;
			Dialog(chestTalk.get(Dialog)).setCurrentById("masterOfCoin");
		}
		
		//Find Genie Game
		private function setupGenieHiding():void
		{
			Display(genie.get(Display)).visible = false;
			ToolTipCreator.removeFromEntity(genie);
			genieHide = EntityUtils.createMovingTimelineEntity(this, _hitContainer["genieHide"]);
			
			var inter:Interaction = InteractionCreator.addToEntity(genieHide, [InteractionCreator.CLICK]);
			inter.click.add(clickedBarrel);
			ToolTipCreator.addToEntity(genieHide);
			geniePeek();
			Timeline(genieHide.get(Timeline)).handleLabel("peeking", hidePuff, false);
			var divination:DivinationTarget = new DivinationTarget();
			divination.response.addOnce(hitGenie);
			genie.add(divination);	
			
			// not there	
			//	Timeline(genieHide.get(Timeline)).gotoAndStop("start");
			//	removeEntity(genie);
			//}
		}	
		
		private function clickedBarrel(...p):void
		{
			Dialog(player.get(Dialog)).sayById("click_barrel");
		}
		
		private function hidePuff():void
		{
			//_smokePuffGroup.poofAt(genieHide, 0.2);
		}
		
		private function geniePeek(...p):void
		{
			Timeline(genieHide.get(Timeline)).gotoAndPlay("start");
			Timeline(genieHide.get(Timeline)).handleLabel("end", geniePeekDelay);
		}
		
		private function geniePeekDelay():void
		{
			genietimer = SceneUtil.addTimedEvent(this, new TimedEvent(4.0,1,geniePeek));
		}		
		
		private function hitGenie(bomb:Entity):void
		{
			var spatial:Spatial = player.get( Spatial );
			var destination:Destination = CharUtils.moveToTarget( player, 2350, 1250, true, genieAppears );
		}
		
		private function genieAppears( player:Entity ):void
		{
			CharUtils.setDirection( player, false );
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput=true;
			actions.addAction(new WaitAction(0.9));
			actions.addAction(new CallFunctionAction(showGenie));
			actions.addAction(new WaitAction(0.3));
			actions.addAction(new AnimationAction(genie, Cough, "", 50, true));
			actions.addAction(new TalkAction(genie, "royalPain"));
			actions.addAction(new CallFunctionAction(genieFlysAway));
			actions.addAction(new PanAction(genie));
			actions.addAction(new WaitAction(1.0));
			actions.addAction(new PanAction(player));
			actions.addAction(new TriggerEventAction(_events.GENIE_IN_DESERT,true));
			actions.execute();
			shellApi.removeEvent(_events.GENIE_IN_PALACE);
		}
		
		private function showGenie():void
		{
			AudioUtils.play(this, FOUND,1.2,false,null,null,1.2);
			AudioUtils.playSoundFromEntity(genie, POOF_SOUND, 600, 0.2);
			EntityUtils.positionByEntity(genie,genieHide);
			//genie.get(Spatial).y -= 100;
			_smokePuffGroup.poofAt(genie,0.6);
			genie.get(Display).visible = true;
			Timeline(genieHide.get(Timeline)).gotoAndStop("start");
			if(genietimer){
				genietimer.stop();
			}
			super.addGenieWaveMotion(genie);
		}
		
		private function genieFlysAway():void
		{
			TweenUtils.entityTo(genie, Spatial, 2.0, {x:2700, y:700, ease:Back.easeIn});
			CharUtils.setAnim(genie, Soar);
			CharUtils.setDirection(genie, true);
			Platform( camelPlat.get( Platform )).stickToPlatforms = false;
		}
		//END FIND GENIE GAME
		
		private function setUpCamel():void
		{
			var camelClip:MovieClip = super.getAsset( "camel.swf") as MovieClip; 
			camelClip.mouseEnabled = camelClip.mouseChildren = false;
			camel = TimelineUtils.convertAllClips(camelClip, null, this);
			camel.add(new Spatial(camelClip.x, camelClip.y)).add(new Display(camelClip, _hitContainer));
			
			guard.get(Npc).ignoreDepth = true;
			DisplayUtils.moveToBack(guard.get(Display).displayObject);
			DisplayUtils.moveToOverUnder(camelClip, EntityUtils.getDisplayObject(guard), false);
			if(chest) {
				DisplayUtils.moveToBack(chest.get(Display).displayObject);
			}
			
			Sleep( camel.get( Sleep )).ignoreOffscreenSleep = true;
			Sleep( guard.get( Sleep )).ignoreOffscreenSleep = true;
			
			camelPlat = this.getEntityById("camelPlat");
			var platform:Platform = camelPlat.get( Platform );
			platform.stickToPlatforms = true;
			camelPlat.add( new Threshold( "x" ));
			
			var spatial:Spatial = camelPlat.get( Spatial );
			spatial.x = guard.get( Spatial ).x - 170;
			spatial.y = guard.get( Spatial ).y - 100;
			camelPlat.get(Display).alpha = 0;
			
			Dialog(this.getEntityById("guard1").get(Dialog)).setCurrentById("funny");
			
			var followTarget:FollowTarget = new FollowTarget( camelPlat.get( Spatial ));
			followTarget.offset = new Point( 0, 20 );
			camel.add( followTarget );
			
			camel.get(Spatial).x = guardXLeft - 170;
		}
		
		private function startBackAndForth():void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(5, 1, runRight));
		}
		
		private function runRight(event:Event=null):void
		{
			CharUtils.moveToTarget(guard, guardXRight, 1280, false, finishRun, new Point(5, 150));
			camelRun = new TimedEvent(1, 1, runCamelRight);
			SceneUtil.addTimedEvent(this, camelRun );
		}
		
		private function runCamelRight():void
		{
			var camelXtarg:Number = guardXRight + 160;
			Motion( camelPlat.get( Motion )).velocity.x = 800;
			
			var threshold:Threshold = camelPlat.get( Threshold );
			threshold.operator = ">=";
			threshold.threshold = camelXtarg;
			//		threshold._firstCheck = true;
			threshold.entered.addOnce( finishCamelRun );
			
			//		TweenUtils.globalTo(this,camelPlat.get(Spatial),2,{x:camelXtarg, delay:0.5, ease:Sine.easeInOut, onComplete:finishCamelRun},"camel_run");
			camel.get(Timeline).gotoAndPlay("run");
			SceneUtil.addTimedEvent(this, new TimedEvent(5, 1, runLeft));
			runR = true;
		}
		
		private function runLeft(event:Event=null):void
		{
			CharUtils.moveToTarget(guard, guardXLeft, 1280, false, finishRun, new Point(5, 150));
			camelRun = new TimedEvent(1, 1, runCamelLeft)
			SceneUtil.addTimedEvent(this, camelRun );
		}
		
		private function runCamelLeft():void
		{
			var camelXtarg:Number = guardXLeft - 160;
			Motion( camelPlat.get( Motion )).velocity.x = -800;
			
			var threshold:Threshold = camelPlat.get( Threshold );
			threshold.operator = "<=";
			threshold.threshold = camelXtarg;
			//		threshold._firstCheck = true;
			threshold.entered.addOnce( finishCamelRun );
			
			//	TweenUtils.globalTo(this,camelPlat.get(Spatial),2,{x:camelXtarg, delay:0.5, ease:Sine.easeInOut, onComplete:finishCamelRun},"camel_run");
			camel.get(Timeline).gotoAndPlay("run");
			SceneUtil.addTimedEvent(this, new TimedEvent(5, 1, runRight));
			runR = false;
		}
		
		private function finishRun(entity:Entity):void
		{
			if(runR) {
				CharUtils.setDirection(guard, false);
			} else {
				CharUtils.setDirection(guard, true);
			}
			var num:Number = Utils.randInRange(1,10);
			if(num < 7){
				CharUtils.setAnim(guard, Grief);
			}
		}
		
		private function finishCamelRun( ...args ):void
		{
			if(runR) {
				camel.get(Spatial).scaleX = -1;
			} else {
				camel.get(Spatial).scaleX = 1;
			}
			
			Threshold( camelPlat.get( Threshold ))._firstCheck = true;
			Motion( camelPlat.get( Motion )).velocity.x = 0;
			camel.get(Timeline).gotoAndPlay("lick");
		}
		
		private function setupChest():void
		{
			var clip:MovieClip = _hitContainer[ "chest" ];
			//*** For some reason, converting them this way (following three lines) is causing the screen to fail to load occasionally. Switched back to "convertAllClips" for now.
			//super.convertContainer( clip[ "openeye" ], PerformanceUtils.defaultBitmapQuality );
			//super.convertContainer( clip[ "lockedeye" ], PerformanceUtils.defaultBitmapQuality );
			//super.convertContainer( clip[ "lid" ], PerformanceUtils.defaultBitmapQuality );
			
			//chest = EntityUtils.createSpatialEntity( this, clip, _hitContainer);
			//TimelineUtils.convertClip( clip, this, chest ); //convertAllClips( clip, chest, this );//
			chest = TimelineUtils.convertAllClips( clip, chest, this );
			chest.add(new Spatial(clip.x, clip.y));
			
			if(!shellApi.checkEvent(_events.CHEST_OPENED)) {
				chest.get(Timeline).gotoAndPlay("idle");
				//chest.get(Timeline).gotoAndStop(0);
			} else {
				if (this.shellApi.checkItemEvent(_events.GOLDEN_LAMP)) {
					chest.get(Timeline).gotoAndStop("opentalk2");
				} else {
					chest.get(Timeline).gotoAndStop("opentalk");
				}
				chestOpened = true;
			}
			
			chestClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["chestClick"]), this);
			chestClick.remove(Timeline);
			chestClickInteraction = chestClick.get(Interaction);
			chestClickInteraction.downNative.add( clickChest );
			chestClick.get(Display).alpha = 0;
			
		}
		
		private function clickChest(event:Event):void {
			var destination:Destination = CharUtils.moveToTarget(player, 1563, 1280, false, startChestTalk);
			destination.ignorePlatformTarget = true;
		}
		
		private function startChestTalk(entity:Entity):void {
			CharUtils.setDirection(player, false);
			var dialog:Dialog = chestTalk.get( Dialog );
			var timeline:Timeline = chest.get( Timeline );
			
			if( shellApi.checkEvent(GameEvent.GOT_ITEM + _events.GOLDEN_LAMP)) 
			{
				timeline.gotoAndPlay( "opentalk2" );
				dialog.sayById("gotLamp");
			} 
			else if(!chestOpened) 
			{
				SceneUtil.lockInput(this, true);
				timeline.gotoAndPlay( "closedtalk" );
				dialog.sayById("letMeOut");
			} 
			else 
			{
				dialog.sayById("masterOfCoin");
			}
			dialog.complete.addOnce( endChestTalking );
		}
		
		private function endChestTalking( dialogData:DialogData ):void
		{
			var timeline:Timeline = chest.get( Timeline );
			if( dialogData.id == "letMeOut" )
			{
				if( !shellApi.checkEvent( _events.CHEST_OPENED ))
				{
					timeline.gotoAndPlay( "idle" );
				}
				else
				{
					timeline.gotoAndStop( "opentalk" );
				}
				Dialog( player.get( Dialog )).sayById( "yipes" );
				Dialog( player.get( Dialog )).complete.addOnce( nextStatement );
			}
			if( dialogData.id == "iWish" || dialogData.id == "not_muffled" )
			{
				SceneUtil.lockInput( this, false );
				if( !shellApi.checkEvent( _events.CHEST_OPENED ))
				{
					timeline.gotoAndPlay( "idle" );
				}
				else
				{
					timeline.gotoAndStop( "opentalk" );
				}
			}
			else if( dialogData.triggerEvent && dialogData.triggerEvent.args[ 0 ] == "getLamp" )
			{
				
				SceneUtil.addTimedEvent(this, new TimedEvent(0.2, 1, moveToChestPosition));
				
				timeline.gotoAndStop( "opentalk" );
			}
			else if( dialogData.id.indexOf( "answer" ) >= 0 )
			{
				timeline.gotoAndStop( "opentalk" );			
			}
			else if( dialogData.id == "gotLamp" )
			{
				timeline.gotoAndStop( "opentalk2" );				
			}
		}
		
		private function moveToChestPosition():void
		{
			var xPos:Number = chest.get(Spatial).x;
			var destination:Destination = CharUtils.moveToTarget( player, xPos, 1280, true, pickUpLamp );
		}
		
		private function pickUpLamp(entity:Entity):void {
			CharUtils.setAnim(player, PointItem);
			player.get(Timeline).handleLabel("pointing", getLamp, false);
		}
		
		private function getLamp(entity:Entity=null):void {
			shellApi.getItem(_events.GOLDEN_LAMP, null, true );
			chest.get(Timeline).gotoAndStop("opened2");
		}
		
		private function nextStatement( dialogData:DialogData ):void
		{
			var dialog:Dialog = chestTalk.get( Dialog );
			if( !shellApi.checkEvent( _events.CHEST_OPENED ))
			{
				dialog.sayById( "iWish" );
				Timeline( chest.get( Timeline )).gotoAndPlay( "closedtalk" );
			}
			else
			{
				dialog.sayById( "not_muffled" );		
				Timeline( chest.get( Timeline )).gotoAndPlay( "opentalk" );		
			}
			
			dialog.complete.addOnce( endChestTalking );
		}
		
		private function setupCustomDialog():void
		{
			chestTalk = new Entity();
			var dialog:Dialog = new Dialog()
			dialog.faceSpeaker = false;     // the display will turn towards the player if true.
			dialog.dialogPositionPercents = new Point(0, 1);  // set the percent of the bounds that the dialog is offset.  The current arts will cause it to be offset 0% on x axis and 100% on y (66px).
			
			chestTalk.add(dialog);
			chestTalk.add(new Id("chestTalk"));
			chestTalk.add(new Spatial());
			chestTalk.add(new Display(_hitContainer["chestTalk"]));
			chestTalk.add(new Edge(33, 66, 33, 0));   //set the distance from the characters registration point.
			chestTalk.add(new Character());           //allows this entity to get picked up by the characterInteractionSystem for dialog on click
			chestTalk.get(Display).alpha = 0;
			
			//		dialog.start.add(this.talkStart);
			//		dialog.complete.add(this.talkStop);
			
			super.addEntity(chestTalk);		
		}
		
		override protected function addCharacterDialog(container:Sprite):void
		{
			// custom dialog entity MUST be added here so that dialog from the xml gets assigned to it.
			setupCustomDialog();
			super.addCharacterDialog(container);
		}
	}
}