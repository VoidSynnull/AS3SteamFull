package game.scenes.timmy.alley
{	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Npc;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.hit.Zone;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.AnimationData;
	import game.data.animation.AnimationSequence;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.PointItem;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.timmy.TimmyScene;
	import game.scenes.timmy.alley.popup.BowlingPopup;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.SetDirectionAction;
	import game.systems.actionChain.actions.SetSpatialAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.motion.ProximitySystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	
	public class Alley extends TimmyScene
	{
		private var vendingMachine:Entity;
		private var vendingMachineTL:Timeline;
		
//		private var _arcadeSequence:BitmapSequence;
//		private var _vendingSequence:BitmapSequence;
		
		private const MEOW_SOUND:String = SoundManager.EFFECTS_PATH + "cat_meow_01.mp3";
		private const COIN_SOUND:String = SoundManager.EFFECTS_PATH + "cut_lock_01.mp3";
		private const VEND_SOUND:String = SoundManager.EFFECTS_PATH + "medium_mechanical_movement_01.mp3";
		private const DROP_SOUND:String = SoundManager.EFFECTS_PATH + "ls_metal_shelf_01.mp3";
		
		private var arcade:Entity;
		private var desk:Entity;
		private var clerk:Entity;
		private var crispin:Entity;
		private var blockZone:Entity;
		private var handbookPage:Entity;
		
		public function Alley()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/timmy/alley/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
//		override public function destroy():void
//		{
////			if( _arcadeSequence )
////			{
////				_arcadeSequence.destroy();
////				_arcadeSequence 			=	null;
////			}
//			if( _vendingSequence )
//			{
//				_vendingSequence.destroy();
//				_vendingSequence 			=	null;
//			}
//			
//			super.destroy();
//		}
		
		override protected function addBaseSystems():void
		{
			addSystem( new TriggerHitSystem());
			super.addBaseSystems();
		}
		
		// all assets ready
		override public function loaded():void
		{	
			shellApi.eventTriggered.add(eventTriggered);
			
			setupEntities();
			
			setupVendingMachine();
			
			setupDesk();
			
			super.loaded();
		}
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if(event == _events.USE_CHANGE){
				moveToVending();
			}
			else if(event == _events.USE_MONEY){
				moveToVendingFail();
			}
			else if(event == _events.USE_BONBONS  && shellApi.checkEvent( _events.TOTAL_FOLLOWING )){
				useBonBons();
				super.eventTriggered( event, makeCurrent, init, removeEvent );
			}
			else if(event == _events.CALL_TOTAL){
				resetBlocker();
				super.eventTriggered( event, makeCurrent, init, removeEvent );
			}
			else if(event == "lets_bowl"){
				startBowlingGame();
			}else{
				super.eventTriggered( event, makeCurrent, init, removeEvent );
			}
		}
		
		private function resetBlocker():void
		{
			var z:Zone = blockZone.get(Zone);
			z.entered.removeAll();
			z.entered.add(blockAlley);
		}
		
		private function moveToVendingFail():void
		{
			CharUtils.moveToTarget(player, 561, 644, true, useCash, new Point(30,100));
		}
		
		private function moveToVending():void
		{
			CharUtils.moveToTarget(player, 561, 644, true, useChange, new Point(30,100));
		}
		
		private function useCash(...p):void
		{
			positionTotal(false);
			Dialog(player.get(Dialog)).sayById("nochange");
		}
		
		private function useChange(...p):void
		{
			positionTotal(false);
			var sceneInter:SceneInteraction = vendingMachine.get(SceneInteraction);	
			sceneInter.reached.removeAll();
			sceneInter.reached.add(vendingComment3);
			
			var actions:ActionChain =  new ActionChain(this);
			actions.lockInput = true;
			actions.lockPosition = true;
			
			actions.addAction(new SetSpatialAction(player, new Point(561, 644)));
			actions.addAction(new SetDirectionAction(player, false));
			actions.addAction(new AnimationAction(player, PointItem,"pointing"));
			actions.addAction(new AudioAction(vendingMachine, COIN_SOUND));		
			actions.addAction(new RemoveItemAction(_events.CHANGE,"vendingMachine")).noWait = true;
			actions.addAction(new WaitAction(0.8));	
			actions.addAction(new AudioAction(vendingMachine, VEND_SOUND));
			actions.addAction(new TimelineAction(vendingMachine, "purchased", "buyEnd"));
			actions.addAction(new AudioAction(vendingMachine, DROP_SOUND));
			actions.addAction(new WaitAction(0.1));
			actions.addAction(new TimelineAction(vendingMachine, "drop"));
			actions.addAction(new MoveAction(player, new Point(516,571),new Point(30,100)));
			actions.addAction(new SetSpatialAction(player, new Point(516,644)));
			actions.addAction(new SetDirectionAction(player, false));
			actions.addAction(new AnimationAction(player, Place));
			actions.addAction(new GetItemAction(_events.CAT)).noWait = true;
			actions.addAction(new TimelineAction(vendingMachine, "empty"));
			actions.addAction(new GetItemAction(_events.BONBONS));
			actions.addAction(new TalkAction(player, "bonbons"));
			actions.addAction(new CallFunctionAction(takePhoto));
			
			actions.execute();
		}
		
		private function takePhoto( ...p ):void
		{
			this.shellApi.takePhoto( "19045" );
		}
		
		private function setupEntities():void
		{
			addSystem(new ProximitySystem());
			var clip:MovieClip = _hitContainer["arcade"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
			{
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
				
	//			arcade									=	EntityUtils.createMovingTimelineEntity( this, clip, null, false );

	//			_arcadeSequence 			=	BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 0.1 );
	//			arcade = BitmapTimelineCreator.createBitmapTimeline( clip, true, true, _arcadeSequence, PerformanceUtils.defaultBitmapQuality + 0.1 );
	//			Timeline(arcade.get(Timeline)).play();
	//			addEntity(arcade);
			}
			//else{
			arcade = EntityUtils.createMovingTimelineEntity( this, clip, null, true );
			//}
			var inter:Interaction = InteractionCreator.addToEntity(arcade,[InteractionCreator.CLICK]);
			inter.click.add(aracadeComment);
			ToolTipCreator.addToEntity(arcade);
			
			clip = _hitContainer["desk"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality + 0.1);
			}
			// chars
			desk = EntityUtils.createSpatialEntity(this, clip);
			Npc( getEntityById( "total" ).get( Npc )).ignoreDepth = true;
			
			clerk = getEntityById("clerk");
			Display(clerk.get(Display)).moveToBack();
			Npc( clerk.get( Npc )).ignoreDepth = true;
			
			crispin = getEntityById("crispin");
			Display(crispin.get(Display)).moveToBack();
			Npc( crispin.get( Npc )).ignoreDepth = true;
			
			blockZone = getEntityById("blockZone");
			if(!shellApi.checkItemEvent(_events.CAR_KEY)){
				var zone:Zone =  blockZone.get(Zone);
				zone.entered.add(blockAlley);
			}
			
			// page
			if(!shellApi.checkEvent(_events.GOT_DETECTIVE_LOG_PAGE + "8") && shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "7")){
				handbookPage = EntityUtils.createSpatialEntity(this, _hitContainer["handbookPage"]);
				InteractionCreator.addToEntity(handbookPage,[InteractionCreator.CLICK]);
				var sceneInt:SceneInteraction = new SceneInteraction();
				handbookPage.add(sceneInt);
				var prox:Proximity = new Proximity(130,player.get(Spatial));
				prox.entered.addOnce(getPage);
				handbookPage.add(prox);
				ToolTipCreator.addToEntity(handbookPage);
			}
			else{
				_hitContainer.removeChild(_hitContainer["handbookPage"]);
			}
		}
		
		private function aracadeComment(...p):void
		{
			Dialog(player.get(Dialog)).sayById("arcade");
		}
		
		private function getPage(...p):void
		{
			removeEntity(handbookPage);
			shellApi.completeEvent(_events.GOT_DETECTIVE_LOG_PAGE + "8");
			showDetectivePage( 8 );
		}
		
		private function blockAlley(...p):void
		{
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			actions.lockPosition = true;
			actions.addAction(new MoveAction(player,new Point(650,663),new Point(60, 100),NaN,true));
			actions.addAction(new WaitAction(0.2));
			actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,true)));
			actions.addAction(new CallFunctionAction(Command.create(positionTotal,true)));
			actions.addAction(new WaitAction(0.4));
			actions.addAction(new TalkAction(clerk,"block"));
			actions.addAction(new WaitAction(0.4));
			actions.addAction(new TalkAction(player,"sneak"));

			actions.execute();
		}
		
		private function setupVendingMachine():void
		{
			var clip:MovieClip 				=	_hitContainer[ "vendingMachine" ];
			if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH )
			{
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
		//		_vendingSequence 			=	BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 1.0 );
		//		vendingMachine = BitmapTimelineCreator.createBitmapTimeline( clip, true, true, _vendingSequence, PerformanceUtils.defaultBitmapQuality + 1.0 );
		//		addEntity(vendingMachine);
			}
		//	else
		//	{
			vendingMachine = EntityUtils.createMovingTimelineEntity( this, clip );
		//	}
			var inter:Interaction = InteractionCreator.addToEntity(vendingMachine,[InteractionCreator.CLICK]);
			var sceneInter:SceneInteraction = new SceneInteraction();
			sceneInter.offsetY = 100;
			vendingMachine.add(sceneInter);
			ToolTipCreator.addToEntity(vendingMachine);	
			// return change if sometihng went wrong
			if(shellApi.checkItemEvent(_events.CHANGE) && !shellApi.checkItemEvent(_events.CAT)){
				shellApi.getItem(_events.CHANGE);
			}
			vendingMachineTL = Timeline(vendingMachine.get(Timeline));
			if(shellApi.checkEvent(_events.GOT_DETECTIVE_LOG_PAGE + "6") && !shellApi.checkItemEvent(_events.CAT)){
				vendingMachineTL.gotoAndPlay("trapped");
				vendingMachineTL.handleLabel("meow", meow, false);
				sceneInter.reached.add(vendingComment1);
			}
			else if(shellApi.checkItemEvent(_events.CAT)){
				vendingMachineTL.gotoAndStop("empty");
				sceneInter.reached.add(vendingComment3);
			}
			else{
				vendingMachineTL.gotoAndStop("empty");
				sceneInter.reached.add(vendingComment2);
			}
		}
		
		private function meow(...p):void
		{
			AudioUtils.playSoundFromEntity(vendingMachine, MEOW_SOUND, 600, 0.2, 1.2, Quadratic.easeInOut);
		}
		
		private function vendingComment1(...p):void
		{
			Dialog(player.get(Dialog)).sayById("cat");
		}		
		
		private function vendingComment2(...p):void
		{
			Dialog(player.get(Dialog)).sayById("candy");
		}	
		
		private function vendingComment3(...p):void
		{
			Dialog(player.get(Dialog)).sayById("empty");
		}
		
		private function startBowlingGame():void
		{
			// popup
			var bowlingPoopup:BowlingPopup = addChildGroup(new BowlingPopup(overlayContainer)) as BowlingPopup;
			bowlingPoopup.completeSignal.addOnce(bowlingFinish);
		}
		
		private function bowlingFinish(winner:Boolean, score:Number):void
		{
			// sucess; give key. fail; taunt and try again	
			var dialog:Dialog = crispin.get(Dialog);
			if(winner){
				if(shellApi.checkItemEvent(_events.CAR_KEY)){
					if(score == 40){
						dialog.sayById("lose_perfect2");
					}else{
						dialog.sayById("lose2");
					}
				}
				else{
					if(score == 40){
						dialog.sayById("lose_perfect");
					}else{
						dialog.sayById("lose");
					}
				}
			}					
			else{
				dialog.sayById("fail");
			}
		}
		
		private function useBonBons(...p):void
		{				
			SceneUtil.addTimedEvent(this, new TimedEvent(0.8,1,Command.create(Dialog(clerk.get(Dialog)).sayById,"dance")));
			Zone(blockZone.get(Zone)).entered.removeAll();
		}
		
		public function setAnimSequence(entity:Entity, animations:Vector.<Class>, delays:Vector.<Number>, loop:Boolean = false):void
		{
			var animControl:AnimationControl = entity.get(AnimationControl);
			var animEntity:Entity = animControl.getEntityAt();
			var animSequencer:AnimationSequencer = animEntity.get(AnimationSequencer);
			
			if(!animSequencer)
			{
				animSequencer = new AnimationSequencer();
				animEntity.add(animSequencer);
			}
			var sequence:AnimationSequence = new AnimationSequence();
			for (var i:int = 0; i < animations.length; i++) 
			{
				sequence.add(new AnimationData(animations[i], delays[i]));
			}
			sequence.loop = loop;
			animSequencer.currentSequence = sequence;
			animSequencer.start = true;
		}
		
		// Layer total/player correctly
		
		private function setupDesk():void
		{
			addTriggerHit( getEntityById( "floor" ), layerAboveTotal );
			addTriggerHit( getEntityById( "carpet" ), layerAboveTotal );
			addTriggerHit( getEntityById( "wood" ), layerAboveTotal );
			addTriggerHit( getEntityById( "bounce" ), layerUnderTotal );
			addTriggerHit( getEntityById( "counter" ), layerUnderTotal );
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