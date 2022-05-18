package game.scenes.timmy.mansion
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Npc;
	import game.components.entity.character.Skin;
	import game.components.entity.character.Talk;
	import game.components.motion.MotionTarget;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.ItemGroup;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.timmy.TimmyScene;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class Mansion extends TimmyScene
	{
		private var nose:Entity;
		private var bingo:Entity;
		private var timmy:Entity;
		private var shearsItem:Entity;
		private var readyForWagon:Boolean = false;
		private var ball:Entity;
		private var box:Entity;
		private var wagonClick:Entity;
		private var wagonClickInteraction:Interaction;
		
		private var _noseSequence:BitmapSequence;
		
		public function Mansion()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/timmy/mansion/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override public function destroy():void
		{
			if( _noseSequence )
			{
				_noseSequence.destroy();
				_noseSequence 		=	null;
			}
			
			super.destroy();
		}
		
		override protected function addBaseSystems():void
		{
			addSystem( new TriggerHitSystem());
			super.addBaseSystems();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			bingo = this.getEntityById("bingo");
			DisplayUtils.moveToBack( bingo.get(Display).displayObject);
			Npc( bingo.get( Npc )).ignoreDepth = true;
			Npc( _total.get( Npc )).ignoreDepth = true;
			
			addSystem( new TriggerHitSystem());
			
			setupElephant();
			setupShears();
			setupWagonClick();
			
			if(this.getEntityById("box")) {
				box = this.getEntityById("box");
				box.get(Spatial).rotation = -3;
				_hitContainer.addChild(_hitContainer["ear"]);
				var sceneInteraction:SceneInteraction = box.get(SceneInteraction);
				sceneInteraction.approach = false;
				sceneInteraction.triggered.add(this.onBoxClicked);
				DisplayUtils.moveToBack(box.get(Display).displayObject);
				if(shellApi.checkEvent(_events.KNOCKED_BOX_DOWN)) {
					box.get(Spatial).x = 1850;
					box.get(Spatial).y = 1000;
					
					sceneInteraction.approach = true;
				}
				if( shellApi.checkEvent( "gotItem_" + _events.BOX)) {
					this.removeEntity(box);
				}
			} 
			
			if( shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "9" ) && !shellApi.checkEvent( "gotItem_" + _events.WAGON)) {
				bingo.get(Spatial).x = 1100;
				bingo.get(Spatial).y = 960;
				CharUtils.setDirection(bingo, true);
				Dialog(bingo.get(Dialog)).setCurrentById("wagon");
				readyForWagon = true;
			}
			
			if(this.getEntityById("wagon")) {
				DisplayUtils.moveToBack( this.getEntityById("wagon").get(Display).displayObject);
				DisplayUtils.moveToBack(nose.get(Display).displayObject);
			}
			
			if(shellApi.checkEvent( "gotItem_" + _events.WAGON)) {
				wagonClick.get(Display).visible = false;
				this.removeEntity(wagonClick);
			}
			
			if( shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "2" )) {
				
				if( shellApi.checkEvent(_events.KNOCKED_BOX_DOWN) || shellApi.checkEvent( "gotItem_" + _events.BOX)) {
					if(this.getEntityById("timmy")) {
						timmy = this.getEntityById("timmy");
						this.removeEntity(timmy);
					}
				} else {
					if(this.getEntityById("timmy")) {
						timmy = this.getEntityById("timmy");
						DisplayUtils.moveToBack( timmy.get(Display).displayObject);
						timmy.get(Npc).ignoreDepth = true;
						var display:Display = timmy.get( Display );
						display.displayObject[ "shorts" ].alpha = 0;
						display.displayObject[ "shirt_garbage" ].alpha = 0;
						display.displayObject[ "head_garbage" ].alpha = 0;
						Dialog(timmy.get(Dialog)).allowOverwrite = true;
					}
				}	
			}
			
			setupLadder();
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( event == "finish_nose" ) {
				super.shellApi.camera.target = player.get(Spatial);
				Dialog(bingo.get(Dialog)).setCurrentById("look");
			} else if( event == _events.USE_BONBONS && shellApi.checkEvent( _events.TOTAL_FOLLOWING )) {
				getWagon();
			} else if( event == _events.USE_BEACH_BALL ) {
				if(!shellApi.checkEvent(_events.KNOCKED_BOX_DOWN) && shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "2" )) {
					SceneUtil.lockInput(this, true);
					var targX:Number = timmy.get(Spatial).x - 100;
					CharUtils.moveToTarget(player, targX, 1060, false, talkBall);
				} else {
					Dialog(player.get(Dialog)).sayById("cant_use_beach_ball");
				}
			} else if(event == "throw_to_timmy"){
				var hand:Entity = Skin( player.get( Skin )).getSkinPartEntity( "hand1" );
				var handDisplay:Display = hand.get( Display );
				
				ball = EntityUtils.createSpatialEntity(this, _hitContainer["ball"], handDisplay.displayObject);
				ball.get(Spatial).x = 0;
				ball.get(Spatial).y = 0;
				ball.get(Spatial).scaleX = -2.4;
				ball.get(Spatial).scaleY = 2.4;
				ball.get(Spatial).rotation = 0;
				DisplayObject(ball.get(Display).displayObject).parent.setChildIndex(ball.get(Display).displayObject, 0);
				CharUtils.moveToTarget(player, 1638, 1060, false, jump);
		//	} else if(event == "gotItem_" + _events.WAGON && !shellApi.checkItemEvent( _events.WAGON )){
		//		Dialog(player.get(Dialog)).sayById("got_wagon");
			} else if( event == "use_pole" ) {
				Dialog(player.get(Dialog)).sayById("pole");
			} 
		}
		
		private function talkBall(entity:Entity):void {
			CharUtils.setDirection(player, true);
			Dialog(player.get(Dialog)).sayById("beach_ball");
		}
		
		private function onBoxClicked(player:Entity, portrait:Entity):void {
			if( !shellApi.checkEvent( _events.KNOCKED_BOX_DOWN ))
			{
				Dialog(player.get(Dialog)).sayById("cant_reach");
			}
		}
		
		private function setDistracted():void {
			Dialog(bingo.get(Dialog)).setCurrentById("look_at_that");
			Dialog(bingo.get(Dialog)).sayById("look_at_that");
		}
		
		private function jump(entity:Entity):void {
			CharUtils.setDirection(player, true);
			player.get(MotionTarget).targetX = player.get(Spatial).x;
			player.get(MotionTarget).targetY = player.get(Spatial).y - 400;
			
			CharUtils.setState(player, CharacterState.JUMP);
			SceneUtil.addTimedEvent(this, new TimedEvent(.5, 1, throwBall, true));
		}
		
		private function throwBall():void {
			_hitContainer.addChild(ball.get(Display).displayObject);
			ball.get(Spatial).x = player.get(Spatial).x + 30;
			ball.get(Spatial).y = player.get(Spatial).y - 30;
			ball.get(Spatial).scaleX = 1;
			ball.get(Spatial).scaleY = 1;
			var targX:Number = timmy.get(Spatial).x;
			var targY:Number = timmy.get(Spatial).y - 100;
			TweenUtils.globalTo(this, ball.get(Spatial), 0.2, {x:targX, y:targY, rotation:100, ease:Linear.easeNone, onComplete:moveBallToBox}, "ball_timmy");
			this.shellApi.completeEvent(_events.KNOCKED_BOX_DOWN);
			shellApi.removeItem(_events.BEACH_BALL);
			var sceneInteraction:SceneInteraction = box.get(SceneInteraction);
			sceneInteraction.approach = true;
			sceneInteraction.triggered.remove(this.onBoxClicked);
			Dialog(timmy.get(Dialog)).allowOverwrite = true;
			Dialog(timmy.get(Dialog)).setCurrentById("got_box");
			SceneUtil.lockInput(this, false);
		}
		
		private function moveBallToBox():void {
			CharUtils.setDirection( timmy, false );
			var timeline:Timeline 	=	timmy.get( Timeline );
			timeline.gotoAndPlay( "hit" );
			TweenUtils.globalTo(this, ball.get(Spatial), 0.35, {x:1991, y:580, rotation:100, ease:Linear.easeNone, onComplete:moveBallDown}, "ball_up");
		}
		
		private function moveBallDown():void {
			var boxupX:Number = box.get(Spatial).x - 20;
			var boxupY:Number = box.get(Spatial).y - 20;
			TweenUtils.globalTo(this, ball.get(Spatial), .5, {x:2275, y:1050, rotation:"100", ease:Linear.easeNone, onComplete:bounce}, "ball_down");
			TweenUtils.globalTo(this, box.get(Spatial), .15, {x:boxupX, y:boxupY, ease:Sine.easeInOut, onComplete:moveBoxDown}, "box_up");
			TweenUtils.globalTo(this, box.get(Spatial), .85, {rotation:"-360", ease:Sine.easeInOut}, "box_rot");
			this.shellApi.triggerEvent("hit_box");
		}
		
		private function moveBoxDown():void {
			TweenUtils.globalTo(this, box.get(Spatial), 0.7, {x:1850, y:1000, ease:Sine.easeIn, onComplete:boxImpact}, "box_down");
		}
		
		private function bounce():void {
			TweenUtils.globalTo(this, ball.get(Spatial), 2, {x:2791, y:700, rotation:"100", ease:Sine.easeOut, onComplete:removeBall}, "ball_bounce");
			TweenUtils.globalTo(this, ball.get(Spatial), .5, {y:"-300", repeat:3, yoyo:true}, "ball_bouncey");
			
		}
		
		private function removeBall():void {
			this.removeEntity(ball);
			Dialog(timmy.get(Dialog)).sayById("got_box");
		}
		
		private function boxImpact():void {
			this.shellApi.triggerEvent("box_fall");
		}
		
		public function getWagon():void {
			if(this.getEntityById("wagon")) {
				this.getEntityById("wagon").get(Spatial).x = wagonClick.get(Spatial).x;
				this.getEntityById("wagon").get(Spatial).y = wagonClick.get(Spatial).y;
				wagonClick.get(Display).visible = false;
				this.removeEntity(wagonClick);
			}
			Dialog(bingo.get(Dialog)).faceSpeaker = false;
			
			Talk(bingo.get(Talk)).mouthDefaultLabel = "distracted";
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, setDistracted, true));
		}
		
		private function setupElephant():void {
			var clip:MovieClip 				=	_hitContainer[ "nose2" ];
			_noseSequence 					=	BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 1.0 );
			
			nose = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			BitmapTimelineCreator.convertToBitmapTimeline( nose, clip, true, _noseSequence, PerformanceUtils.defaultBitmapQuality + 1.0 ); 
			
			clip 							=	_hitContainer[ "nose1" ];
			super.convertContainer( clip );
			DisplayUtils.moveToBack( clip );
			
			if(!shellApi.checkEvent(_events.NOSE_FELL_OFF)) {	
				nose.get(Timeline).gotoAndStop("start");
				nose.get(Display).visible = false;
				
				var triggerPlatform:Entity = getEntityById( "triggerPlat" );
				var triggerHit:TriggerHit = new TriggerHit( null, new <String>[ "player" ]);
				triggerHit.triggered = new Signal();
				triggerHit.triggered.addOnce( prepareElephant );
				triggerPlatform.add( triggerHit );
			} else {
				_hitContainer["nose1"].visible = false;
				nose.get(Timeline).gotoAndStop("end");
				Dialog(bingo.get(Dialog)).setCurrentById("look");
			}
		}
		
		private function prepareElephant():void {
			super.shellApi.camera.target = bingo.get(Spatial);
			SceneUtil.addTimedEvent(this, new TimedEvent(.25, 1, runElephant, true));
			shellApi.completeEvent(_events.NOSE_FELL_OFF);
		}
		
		private function runElephant():void {
			nose.get(Display).visible = true;
			_hitContainer["nose1"].visible = false;
			nose.get(Timeline).gotoAndPlay("start");
			
			Dialog(bingo.get(Dialog)).complete.remove(resetClipping);
			bingo.get(Talk).mouthDefaultLabel = "idle";
			Dialog(bingo.get(Dialog)).faceSpeaker = false;
			Dialog(bingo.get(Dialog)).allowOverwrite = true;
			Dialog(bingo.get(Dialog)).sayById("no");
			
			CharUtils.setDirection(bingo, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(.25, 1, runBingoShock, true));
			this.shellApi.triggerEvent("break_branch");
		}
		
		private function runBingoShock():void {
			bingo.get(Timeline).gotoAndPlay("shock");
			Timeline(bingo.get(Timeline)).handleLabel( "shearshit", placeShears );
		}
		
		private function placeShears():void {
			shearsItem.get(Spatial).x = bingo.get(Spatial).x + 35;
			shearsItem.get(Spatial).y = bingo.get(Spatial).y + 78;
			shearsItem.get(Spatial).scale = 0.9;
		}
		
		private function setupShears():void {
			shearsItem = this.getEntityById("gardening_shears");
			if(shearsItem){
				if(!this.shellApi.checkEvent(_events.NOSE_FELL_OFF)){
					shearsItem.get(Spatial).y += 500;
				}
			}
			
			if(!shellApi.checkEvent(_events.NOSE_FELL_OFF)) {	
				var dialog:Dialog =	bingo.get( Dialog );
				dialog.complete.add( resetClipping );	
				bingo.get(Talk).mouthDefaultLabel = "start_clip";
			} else {
				CharUtils.setDirection(bingo, true);
				bingo.get(Timeline).gotoAndPlay("idle");
			}
			
			trace(bingo.getAll());
		}
		
		private function resetClipping(dialogData:DialogData):void {
			//bingo.get(Timeline).gotoAndPlay("start_clip");
			EntityUtils.getChildById(bingo, "mouth").get(Timeline).gotoAndPlay("idle");
			CharUtils.setDirection(bingo, true);
		}
		
		private function setupWagonClick():void {
			wagonClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["wagonClick"]), this);
			wagonClick.remove(Timeline);
			wagonClickInteraction = wagonClick.get(Interaction);
			wagonClickInteraction.downNative.add( Command.create( moveToWagon ));
			//wagonClick.get(Display).alpha = 0;
		}
		
		private function moveToWagon(event:Event):void {
			CharUtils.moveToTarget(player, 1020, 1060, false, atWagon);
		}
		
		private function atWagon(entity:Entity):void {
			if( !shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "9" )) {
				Dialog(bingo.get(Dialog)).sayById("mitts");
			} else {
				Dialog(player.get(Dialog)).sayById("this_wagon");
			}
		}
		
		// ADDED 9-14-2015 to make player always appear correctly placed in regards to Total
		private function setupLadder():void
		{	
			addTriggerHit( getEntityById( "ladder" ), layerUnderTotal );
			addTriggerHit( getEntityById( "floor" ), layerAboveTotal );
		}
		
		private function addTriggerHit( hitEntity:Entity, handler:Function ):void
		{
			var triggerHit:TriggerHit 						=	new TriggerHit( null, new <String>[ "player" ]);
			triggerHit.triggered 							=	new Signal();
			triggerHit.offTriggered							=	new Signal();
			triggerHit.triggered.add( handler );
			
			hitEntity.add( triggerHit );
		}		
		
		private function layerUnderTotal():void
		{
			DisplayUtils.moveToOverUnder( Display( player.get( Display )).displayObject, Display( _total.get( Display )).displayObject, false );
		}
		
		private function layerAboveTotal():void
		{
			DisplayUtils.moveToOverUnder( Display( player.get( Display )).displayObject, Display( _total.get( Display )).displayObject, true );
		}
	}
}